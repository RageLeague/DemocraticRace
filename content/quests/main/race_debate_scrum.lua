local QUESTION_COUNT = 3

local QDEF = QuestDef.Define
{
    title = "Debate Scrum",
    desc = "You are invited to the presidential debate with other candidates. Impress the audience with your debate skills.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/debate_scrum.png"),

    qtype = QTYPE.STORY,
    collect_agent_locations = function(quest, t)
        if quest:IsActive("report_to_advisor") then
            table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('home')})
        else
            table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('backroom'), role = CHARACTER_ROLES.VISITOR})
        end
        table.insert(t, { agent = quest:GetCastMember("host"), location = quest:GetCastMember('theater'), role = CHARACTER_ROLES.PROPRIETOR})
        for id, data in pairs(DemocracyConstants.opposition_data) do
            table.insert(t, { agent = quest:GetCastMember(id), location = quest:GetCastMember('theater'), role = CHARACTER_ROLES.VISITOR})
        end
    end,
    on_start = function(quest)
        local questions = {}
        local weightings = {}
        for id, data in pairs(DemocracyConstants.issue_data) do
            weightings[id] = data.importance
        end
        for i = 1, QUESTION_COUNT do
            local chosen = weightedpick(weightings)
            table.insert(questions, chosen)
            weightings[chosen] = nil
        end
        quest.param.questions = questions

        quest.param.candidates = {}
        for id, data in pairs(DemocracyConstants.opposition_data) do
            if quest:GetCastMember(data.cast_id) then
                table.insert(quest.param.candidates, quest:GetCastMember(data.cast_id))
            end
        end
        quest.param.popularity = {}
    end,
    -- on_complete = function(quest)
    --     if quest:GetCastMember("primary_advisor") then
    --         quest:GetCastMember("primary_advisor"):GetBrain():SendToWork()
    --     end
    -- end,
    on_destroy = function(quest)
        quest:GetCastMember("primary_advisor"):GetBrain():SendToWork()
    end,
    events =
    {
        get_free_location_marks = function(quest, free_quest, locations)
            table.arrayremove(locations, quest:GetCastMember("theater"))
        end,
    },
}
:AddCast{
    cast_id = "host",
    cast_fn = function(quest, t)
        if quest:GetCastMember("theater"):GetProprietor() then
            table.insert(t, quest:GetCastMember("theater"):GetProprietor())
        end
    end,
    when = QWHEN.MANUAL,
    events =
    {
        agent_retired = function( quest, agent )
            -- if quest:IsActive( "get_snail" ) then
                -- If noodle chef died before we even got the snail, cast someone new.
                quest:UnassignCastMember( "host" )
                quest:AssignCastMember( "host" )
            -- end
        end,
    },
}
:AddCastFallback{
    cast_fn = function(quest, t)
        quest:GetCastMember("theater"):GetWorkPosition("host"):TryHire()
        if quest:GetCastMember("theater"):GetProprietor() then
            table.insert(t, quest:GetCastMember("theater"):GetProprietor())
        end
    end,
}
:AddCast{
    cast_id = "audience",
    when = QWHEN.MANUAL,
    condition = function(agent, quest)
        return not table.arraycontains(quest.param.audience or {}, agent)
    end,
    score_fn = function(agent, quest)
        if agent:HasAspect( "bribed" ) then
            return 100
        end
        local sc = agent:GetRenown() * 2
        if agent:GetRelationship() ~= RELATIONSHIP.NEUTRAL then
            sc = sc + 5
        end
        return math.random(sc, 20)
    end,
    on_assign = function(quest, agent)
        if not quest.param.audience then
            quest.param.audience = {}
        end
        table.insert(quest.param.audience, agent)
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent() )
    end,
}
:AddLocationCast{
    cast_id = "theater",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GRAND_THEATER"))
    end,
    on_assign = function(quest, location)
        -- quest:SpawnTempLocation("BACKROOM", "backroom")
        quest:AssignCastMember("host")
    end,
    no_validation = true,
}
:AddLocationCast{
    cast_id = "backroom",
    no_validation = true,
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GRAND_THEATER.backroom"))
    end,
    -- on_assign = function(quest, location)

    --     -- print(location)
    --     -- print(quest:GetCastMember("theater"))
    --     -- print(quest:GetCastMember("theater"):GetMapPos())
    --     -- location:SetMapPos( quest:GetCastMember("theater"):GetMapPos() )
    -- end,
    -- when = QWHEN.MANUAL,
}
:AddObjective{
    id = "go_to_debate",
    title = "Go to the debate",
    desc = "Meet up with {primary_advisor} at the Grand Theater.",
    mark = {"backroom"},
    state = QSTATUS.ACTIVE,
}
:AddObjective{
    id = "do_debate",
    title = "Do the debate",
    desc = "Try to stand out, but not in a bad way.",
    mark = {"theater"},
    -- state = QSTATUS.ACTIVE,
    events = {
        resolve_negotiation = function(quest, minigame, repercussions)
            if repercussions then
                local core = minigame:GetPlayerNegotiator():FindCoreArgument()
                if core and core.candidate_agent then
                    repercussions.resolve = 0
                end
            end
        end,
    },
    on_complete = function(quest)
        quest:Activate("report_to_advisor")
        quest:Activate("talk_to_candidates")
    end,
}
:AddObjective{
    id = "report_to_advisor",
    -- title = "Return to your advisor",
    -- desc = "Talk to your advisor about how you did today.",
    -- mark = {"primary_advisor"},
    on_activate = function(quest)
        if quest.param.parent_quest then
            -- I don't like this being too coupled with day 3, but it's the best we got
            quest.param.parent_quest:Complete("do_debate")
        end
    end,
    events = {
        quests_changed = function(quest, event_quest)
            if event_quest and event_quest == quest.param.parent_quest then
                if event_quest:IsDone("do_summary") then
                    quest:Complete()
                end
            end
        end,
    },
}
:AddObjective{
    id = "talk_to_candidates",
    title = "(Optional) Talk to other candidates",
    desc = "Other candidates might be interested in an alliance if you've cooperated with them a lot during the debate. Use this opportunity to hopefully form an alliance",
    mark = function(quest, t, in_location)
        -- print("workplace mark evaluated")
        -- print(DemocracyUtil.IsFreeTimeActive())
        if in_location then
            -- table.insert(t, quest:GetCastMember("foreman"))
            for i, agent in ipairs(quest.param.candidates or {}) do
                if not table.arraycontains(quest.param.post_debate_chat or {}, agent) then
                    table.insert(t, agent)
                end
            end
        else
            table.insert(t, quest:GetCastMember("theater"))
        end
    end,-- {"theater"},
}

DemocracyUtil.AddPrimaryAdvisor(QDEF, true)
DemocracyUtil.AddHomeCasts(QDEF)
-- DemocracyUtil.AddOppositionCast(QDEF)

for id, data in pairs(DemocracyConstants.opposition_data) do
    QDEF:AddCast{
        cast_id = data.cast_id,
        no_validation = true,
        optional = true,
        cast_fn = function(quest, t)
            local agent = TheGame:GetGameState():GetMainQuest():GetCastMember(data.cast_id)
            if agent then
                table.insert(t, agent)
            end
        end,
    }
end

local function ProcessMinigame(minigame, win_minigame, cxt)
    local data = {
        won_game = win_minigame,
        ally_survivors = {},
        opponent_survivors = {},
        mvp_score = 0,
        mvp = {},
        valuable_players = {},
        score_agent_pairs = {},
        win_margin = 0,
    }
    if data.won_game then
        for i, modifier in minigame:GetPlayerNegotiator():Modifiers() do
            if modifier.modifier_type == MODIFIER_TYPE.CORE and modifier:GetResolve() then
                if modifier.candidate_agent then
                    table.insert_unique(data.ally_survivors, modifier.candidate_agent)
                else
                    table.insert_unique(data.ally_survivors, TheGame:GetGameState():GetPlayerAgent())
                end
                local res, max_res = modifier:GetResolve()
                data.win_margin = data.win_margin + 0.2 + (res / max_res)
            end
        end
    else
        for i, modifier in minigame:GetOpponentNegotiator():Modifiers() do
            if modifier.modifier_type == MODIFIER_TYPE.CORE and modifier:GetResolve() then
                if modifier.candidate_agent then
                    table.insert_unique(data.ally_survivors, modifier.candidate_agent)
                end
                local res, max_res = modifier:GetResolve()
                data.win_margin = data.win_margin + 0.2 + (res / max_res)
            end
        end
    end
    local opponent_core = minigame:GetOpponentNegotiator():FindCoreArgument()
    table.insert(data.score_agent_pairs, {agent = TheGame:GetGameState():GetPlayerAgent(), score = opponent_core.player_score})
    for id, val in pairs(opponent_core.scores) do
        table.insert(data.score_agent_pairs, {agent = val.modifier.candidate_agent, score = val.score})
    end
    table.stable_sort(data.score_agent_pairs, function(a,b)
        return a.score > b.score
    end)
    if #data.score_agent_pairs > 0 then
        data.mvp_score = data.score_agent_pairs[1].score
        -- Guess what? We need this to not divide by 0.
        if data.mvp_score > 0 then
            for i, val in ipairs(data.score_agent_pairs) do
                if val.score / data.mvp_score >= 0.9 then
                    table.insert(data.mvp, val.agent)
                elseif val.score / data.mvp_score >= 0.6 then
                    table.insert(data.valuable_players, val.agent)
                end
            end
        end
    end

    local METRIC_DATA =
    {
        player_data = TheGame:GetGameState():GetPlayerState(),
        result = win_minigame and "WIN" or "LOSE",
        topic = cxt.quest.param.topic,
        player_mvp = table.arraycontains(data.mvp, TheGame:GetGameState():GetPlayerAgent()),
    }
    DemocracyUtil.SendMetricsData("DAY_3_BOSS_END", METRIC_DATA)

    return data
end
local function CreateDebateOption(cxt, helpers, hinders, topic, stance)
    cxt:Opt("OPT_SIDE", topic .. "_" .. stance)
        :UpdatePoliticalStance(topic, stance, false)
        :Dialog("DIALOG_SIDE")
        :Fn(function(cxt)
            local METRIC_DATA =
            {
                player_data = TheGame:GetGameState():GetPlayerState(),
                allies = {},
                opponents = {},
                topic = topic,
                stance = stance,
            }

            cxt.quest.param.allies = helpers
            cxt.quest.param.opponents = hinders
            for i, agent in ipairs(helpers) do
                cxt.quest.param.candidate_opinion[agent:GetID()] = (cxt.quest.param.candidate_opinion[agent:GetID()] or 0) + 1
                table.insert(METRIC_DATA.allies, agent:GetContentID())
            end
            for i, agent in ipairs(hinders) do
                cxt.quest.param.candidate_opinion[agent:GetID()] = (cxt.quest.param.candidate_opinion[agent:GetID()] or 0) - 1
                table.insert(METRIC_DATA.opponents, agent:GetContentID())
            end

            DemocracyUtil.SendMetricsData("DAY_3_BOSS_START", METRIC_DATA)
            TheGame:SetTempMusicOverride("DEMOCRATICRACE|event:/democratic_race/music/negotiation/debate_scrum", cxt.enc)
        end)
        :Negotiation{
            flags = NEGOTIATION_FLAGS.NO_BYSTANDERS | NEGOTIATION_FLAGS.WORDSMITH | NEGOTIATION_FLAGS.NO_CORE_RESOLVE | NEGOTIATION_FLAGS.NO_LOOT,
            helpers = helpers,
            hinders = hinders,
            suppressed = cxt.quest.param.party_pets,
            reason_fn = function(minigame)
                local core = minigame:GetOpponentNegotiator():FindCoreArgument()
                local total_amt = core.player_score or 0
                return loc.format(cxt:GetLocString("REASON_TXT"), total_amt )
            end,
            on_start_negotiation = function(minigame)
                for i, card in ipairs(minigame.start_params.helper_cards) do
                    if DemocracyUtil.GetOppositionData(card.owner) then
                        minigame.start_params.helper_cards[i] = Negotiation.Card("debater_negotiation_support", card.owner)
                    end
                end
                for i, card in ipairs(minigame.start_params.hinder_cards) do
                    if DemocracyUtil.GetOppositionData(card.owner) then
                        minigame.start_params.hinder_cards[i] = Negotiation.Card("debater_negotiation_hinder", card.owner)
                    end
                end
                -- Expand on the slot limits, as there's way too many modifiers for the max 13
                minigame:GetPlayerNegotiator().max_modifiers = 17
                minigame:GetOpponentNegotiator().max_modifiers = 17
                if cxt.quest.param.fatigued then
                    minigame.player_negotiator:AddModifier("FATIGUED")
                end
            end,
            on_success = function(cxt, minigame)
                cxt.quest.param.debate_result = ProcessMinigame(minigame, true, cxt)
                cxt.quest.param.winner_pov = topic .. "_" .. stance
                cxt:GoTo("STATE_DEBATE_SUMMARY")
            end,
            on_fail = function(cxt, minigame)
                cxt.quest.param.debate_result = ProcessMinigame(minigame, false, cxt)
                cxt.quest.param.winner_pov = topic .. "_" .. (-stance)
                cxt:GoTo("STATE_DEBATE_SUMMARY")
            end,
        }
end
local function DeltaPopularity(table, agent, delta)
    table[agent:GetID()] = (table[agent:GetID()] or 0) + delta
end
QDEF:AddConvo("go_to_debate")
    :Confront(function(cxt)
        if cxt:GetCastMember("primary_advisor") and cxt.location == cxt.quest:GetCastMember("backroom") then
            return "STATE_CONFRONT"
        end
        if cxt.location == cxt.quest:GetCastMember("theater") then
            return "STATE_THEATER"
        end
    end)
    :State("STATE_THEATER")
        :Loc{
            DIALOG_INTRO = [[
                * You arrived at the Grand Theater.
                * Looks like the debate hasn't started yet.
                * You quickly walk into the backroom to meet up with {primary_advisor}.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt:Opt("OPT_LEAVE_LOCATION")
                :Fn(function(cxt)
                    cxt.quest.param.enter_from_theater = true
                    cxt.encounter:DoLocationTransition(cxt.quest:GetCastMember("backroom"))
                end)
                :MakeUnder()
        end)
    :State("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You arrive at the grand theater backroom, where {agent} awaits you.
                player:
                    !left
                agent:
                    !right
                    Are you ready for tonight's debate?
                player:
                    Are we ever ready?
                agent:
                    Good point.
                    Anyway, whether you're ready or not, time to go.
                    Good luck.
                {has_pet?
                    And leave your {pet.species} here. You can't bring it into the venue.
                }
            ]],
            OPT_ASK_GOAL = "Ask about the goal of the debate",
            DIALOG_ASK_GOAL = [[
                player:
                    What is my goal in this debate?
                {depressed?
                agent:
                    You don't need me to tell you about your goal.
                    A useless fool like myself wouldn't know the goal of someone like you.
                player:
                    !crossed
                    I am not sure I should feel flattered or concerned.
                agent:
                    !placate
                    Do not concern yourself with a loser like me.
                }
                {not depressed?
                agent:
                    Your goal, of course, is to win as many debates as possible.
                    But there is like seven of you up there, and the audience will not remember you all.
                    So your actual goal is to stand out and impress the audience.
                player:
                    !dubious
                    And how do I do that?
                agent:
                    Making crucial arguments, dismantling opponent's arguments, defending your arguments, do whatever you can to make the crowd see that you are the true debate master.
                {advisor_manipulate?
                    FACTS and LOGIC are your friends here, {player}. Use them wisely.
                }
                    !cruel
                    You might even want to sabotage your ally's argument to make yours seem more impressive.
                }
            ]],
            OPT_ASK_FORMAT = "Ask about the debate format",
            DIALOG_ASK_FORMAT = [[
                player:
                    What does the debate format look like?
                {depressed?
                agent:
                    !scared_shrug
                    How would I know? I'm a loser who doesn't even know anything.
                player:
                    !bashful
                    That's... Not very helpful.
                agent:
                    !sigh
                    As expected. After all, I am completely useless.
                }
                {not depressed?
                    agent:
                        There will be three rounds of debates.
                        In each round, the interviewer will ask a political question, and you need to take a side.
                    {advisor_diplomacy?
                        Pick a based opinion, and show the opponent how cringe their opinions are!
                    }
                    {advisor_manipulate?
                        !eureka
                        Use FACTS and LOGIC to win the debate against your opponents!
                    }
                    {advisor_hostile?
                        Show the world that nobody knows debate better than you!
                        {not accept_limits and not depressed?
                            Except me, of course. 'Cause nobody knows debate better than me.
                            !point
                            Including you.
                        }
                    }
                    player:
                        What if I don't have enough energy to debate? Or I simply don't have a strong opinion on a topic?
                    agent:
                        You can always choose to stay out.
                        But remember: You are here to stand out to the audience.
                        If you don't participate in the debate, you will not stand out.
                }
            ]],
            OPT_ASK_PET = "Ask about pet policy",
            DIALOG_ASK_PET = [[
                player:
                    !crossed
                    {pet} has a name, you know. And {pet} is a {pet.heshe}.
                agent:
                    !point
                    Doesn't matter. You can't bring {pet.himher} into the venue either way.
                player:
                    Why? Why are pets not allowed?
                agent:
                    !point
                    Think about it.
                    Imagine doing an interview, and the audience just see {pet.a_desc} on the stage.
                    That would certainly cause chaos, and they can't have that.
                    !permit
                    Think about it. If you are allowed to bring a pet, then every candidate is allowed to.
                    And there's like seven of you up there.
                    Just Oolo alone would bring an oshnu with way too many guns attached to it.
                    Is that what you want? Bringing a battle oshnu to a place that is supposed to host a peaceful debate?
                player:
                    !thought
                    Not gonna lie, I kinda want to see that.
                agent:
                    !crossed
                    That's supposed to be a rhetorical question.
                    !handwave
                    Either way, {pet} isn't going to help you on the stage.
                ** Your pets will still be in your party, but will not help you in the upcoming negotiation.
            ]],
            DIALOG_LEAVE = [[
                player:
                    Alright, I'm ready.
                    Moment of truth, here I go.
                {has_pet?
                agent:
                    I will take care of your {pet.species} for you.
                }
                agent:
                    Good luck.
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
                DemocracyUtil.PopulateTheater(cxt.quest, cxt.quest:GetCastMember("theater"), 8)
                cxt.quest.param.party_pets = TheGame:GetGameState():GetCaravan():GetPets()
                if cxt.quest.param.party_pets and #cxt.quest.param.party_pets > 0 then
                    cxt.enc.scratch.has_pet = true
                    cxt:ReassignCastMember("pet", cxt.quest.param.party_pets[1])
                end
                cxt:Dialog("DIALOG_INTRO")
                cxt.quest:Complete("go_to_debate")
                cxt.quest:Activate("do_debate")
            end
            cxt:Question("OPT_ASK_GOAL", "DIALOG_ASK_GOAL")
            cxt:Question("OPT_ASK_FORMAT", "DIALOG_ASK_FORMAT")
            if cxt.enc.scratch.has_pet then
                cxt:Question("OPT_ASK_PET", "DIALOG_ASK_PET")
            end
            cxt:Opt("OPT_LEAVE_LOCATION")
                :Dialog("DIALOG_LEAVE")
                :Fn(function(cxt)
                    cxt.encounter:DoLocationTransition(cxt.quest:GetCastMember("theater"))
                end)
                :Pop()
                :MakeUnder()
        end)
QDEF:AddConvo("do_debate")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt.location == cxt.quest:GetCastMember("theater") end)
        :Loc{
            DIALOG_INTRO = [[
                * You walked into the theater.
                * It is full of people.
                agent:
                    !right
                * You wait for the host to introduce the candidates.
                * After introducing six the other candidate, an amount so large that we don't even bother to write it out, the host finally calls you in.
                agent:
                    [p] And finally, we have {player}!
                player:
                    !left
                    Yo.
                agent:
                    Why do we have all the candidates gathered here today?
                    Why, it is to have a debate, of course!
                    We have plenty of questions to ask each candidates today, and they have debate out which is the best.
                    Hopefully this helps you determine which candidate is the most competent.
            ]],
        }
        :Fn(function(cxt)
            if not cxt.quest.param.popularity then
                cxt.quest.param.popularity = {}
            end
            if not cxt.quest.param.candidate_opinion then
                cxt.quest.param.candidate_opinion = {}
            end
            if #cxt.quest.param.questions < QUESTION_COUNT then
                cxt:GoTo("STATE_QUESTION")
                return
            end
            for i, agent in cxt.location:Agents() do
                if agent:GetRoleAtLocation( cxt.location ) == CHARACTER_ROLES.PATRON then
                    if agent:GetRelationship() > RELATIONSHIP.NEUTRAL then
                        DeltaPopularity(cxt.quest.param.popularity, cxt.player, 1)
                    end
                    for id, data in pairs(DemocracyConstants.opposition_data) do
                        if cxt:GetCastMember(data.cast_id) and agent:GetFactionID() == data.main_supporter then
                            DeltaPopularity(cxt.quest.param.popularity, cxt:GetCastMember(data.cast_id), 1)
                        end
                    end
                end
            end
            cxt:TalkTo(cxt:GetCastMember("host"))
            cxt:Dialog("DIALOG_INTRO")
            cxt:GoTo("STATE_QUESTION")
        end)
    :State("STATE_QUESTION")
        :Quips{
            {
                tags = "debate_question",
                [[
                    agent:
                        Many people in Havaria are very concerned about {topic#pol_issue}.
                        What do you think about that?
                ]],
                [[
                    agent:
                        A big concern in Havaria is about {topic#pol_issue}.
                        What is your opinion on this topic?
                ]],
                [[
                    agent:
                        Many Havarian citizens ask the question,
                        What is the best approach to {topic#pol_issue}?
                ]],
                [[
                    agent:
                        There are a lot of ways to approach {topic#pol_issue}.
                        In your opinion, what is the best way?
                ]],
            },
        }
        :Loc{
            OPT_SIDE = "Argue for {1#pol_stance}",
            DIALOG_SIDE = [[
                player:
                    !left
                    This is my answer!
                * A debate is about to go down!
            ]],
            REASON_TXT = "Impress the audience with your slick negotiation skills! (You have {1} {1*point|points})",
            OPT_SIT_OUT = "Skip the debate and observe the opponents",
            TT_SIT_OUT = "You will not be able to debate and stand out, but you will restore some resolve, and you will start the next negotiation without fatigue.",
        }
        :Fn(function(cxt)
            if not cxt.quest.param.questions or #cxt.quest.param.questions == 0 then
                -- Go to end state.
                cxt:GoTo("STATE_END")
                return
            end
            cxt.quest.param.topic = cxt.quest.param.questions[1]
            table.remove(cxt.quest.param.questions, 1)

            local neg_helper, neg_hinder, pos_helper, pos_hinder = {}, {}, {}, {}
            local neg_neut, pos_neut = {}, {}
            for i, agent in ipairs(cxt.quest.param.candidates) do
                local issue = DemocracyConstants.issue_data[cxt.quest.param.topic]

                -- The default index of a person.
                local stance_index = issue:GetAgentStanceIndex(agent)
                -- How much a person's opinion will shift in your favor
                local shift = 0
                if agent:GetRelationship() > RELATIONSHIP.NEUTRAL then
                    shift = 1
                elseif agent:GetRelationship() < RELATIONSHIP.NEUTRAL then
                    shift = -1
                end
                if stance_index < shift then
                    table.insert(neg_helper, agent)
                elseif stance_index > shift then
                    table.insert(neg_hinder, agent)
                else
                    if shift == 0 then
                        table.insert(neg_neut, agent)
                    end
                end

                if stance_index < -shift then
                    table.insert(pos_hinder, agent)
                elseif stance_index > -shift then
                    table.insert(pos_helper, agent)
                else
                    if shift == 0 then
                        table.insert(pos_neut, agent)
                    end
                end
            end
            while #neg_neut > 0 and #neg_helper >= #neg_hinder do
                local idx = math.random(#neg_neut)
                table.insert(neg_hinder, neg_neut[idx])
                table.remove(neg_neut, idx)
            end
            while #pos_neut > 0 and #pos_helper >= #pos_hinder do
                local idx = math.random(#pos_neut)
                table.insert(pos_hinder, pos_neut[idx])
                table.remove(pos_neut, idx)
            end

            cxt:TalkTo(cxt:GetCastMember("host"))
            cxt:GetAgent():SetTempNegotiationBehaviour(DemocracyUtil.BEHAVIOURS.DEBATE_SCRUM_HOST)
            cxt:Quip(cxt:GetAgent(), "debate_question", string.lower(cxt.quest.param.topic))
            CreateDebateOption(cxt, neg_helper, neg_hinder, cxt.quest.param.topic, -1)
            CreateDebateOption(cxt, pos_helper, pos_hinder, cxt.quest.param.topic, 1)
            cxt:Opt("OPT_SIT_OUT")
                :PostText("TT_SIT_OUT")
                :Fn(function(cxt)
                    local METRIC_DATA =
                    {
                        player_data = TheGame:GetGameState():GetPlayerState(),
                        topic = cxt.quest.param.topic,
                        stance = 0,
                    }

                    DemocracyUtil.SendMetricsData("DAY_3_BOSS_START", METRIC_DATA)
                end)
                :GoTo("STATE_AUTO_DEBATE")
        end)
    :State("STATE_AUTO_DEBATE")
        :Quips{
            {
                tags = "debate_mvp",
                [[
                    * The debate goes on for a long time, but there is one person who shines above others.
                    * With {agent}'s wits and cunning, {agent.heshe} is able to convince the other team to shut up.
                ]],
            },
            {
                tags = "debate_mvp, admiralty",
                [[
                    * You noticed how {agent} plants evidence every turn, and {agent.hisher} allies always use that planted evidence to be more convincing.
                    * Eventually, the opponent just gives up seeing how {agent} just makes up evidence on the fly and everyone just believes that.
                ]],
            },
            {
                tags = "debate_mvp, bandits",
                [[
                    * The debate drags on for a long time, but the longer the debate goes on, the more {agent} becomes impatient.
                    * {agent.HeShe} quickly ends the debate with {agent.hisher} aggressive method.
                ]],
            },
            {
                tags = "debate_mvp, spark_barons",
                [[
                    * You doubt it at first, but {agent} has a way with {agent.hisher} words.
                    * {agent.HeShe} uses many straw man arguments, and uses FACTS and LOGIC and DESTROYS the opposition.
                    * Couple with the fact that {agent.heshe} prevents the opponent from using certain tactics unless they expose themselves, {agent.heshe} quickly becomes a force to be reckoned with.
                    * In the end, {agent.hisher} side won, surprising everyone.
                ]],
            },
            {
                tags = "debate_mvp, rise",
                [[
                    * During the debate, it is clear that {agent} is an inspirational talker.
                    * {agent} is able to use {agent.hisher} words and make the opponent forget what they are saying, and quickly, this becomes out of hand.
                    * The opponent will sometimes spend a turn during virtually nothing, and it is no wonder they lost in the end.
                    * It is clear who the MVP is, despite the fact that during so when you're involved doesn't make {agent.himher} such.
                    * Funny how that works.
                ]],
            },
            {
                tags = "debate_mvp, cult_of_hesh",
                [[
                    * {agent} is able to quickly maintain dominance.
                    * {agent.HeShe} creates a Wrath of Hesh argument on the first turn, and ever since then, it does so much work.
                    * And worst of all, WHY AREN'T THE OPPONENTS TARGETING IT?
                    * IT IS CLEARLY THE MOST DETRIMENTAL ARGUMENT, YET YOU ARE NOT TARGETING IT!
                    * WHAT ARE YOU DOING FOR HESH SAKE?
                    * And yeah, {agent} won, surprising no one.
                ]],
            },
            {
                tags = "debate_mvp, jakes",
                [[
                    * During the debate, one person uses an unconventional tactics to stand out.
                    * The opponents underestimate {agent}, so {agent.heshe} uses this opportunity to act.
                    * With {agent.hisher} double edge, it makes the opponent's tactics less useful.
                    * Eventually, {agent} won in the long term.
                ]],
            },
            {
                -- Can't figure out how to have "or" relation for tags, so just copy and paste
                tags = "debate_mvp, andwanette",
                [[
                    * During the debate, one person uses an unconventional tactics to stand out.
                    * The opponents underestimate {agent}, so {agent.heshe} uses this opportunity to act.
                    * With {agent.hisher} double edge, it makes the opponent's tactics less useful.
                    * Eventually, {agent} won in the long term.
                ]],
            },
        }
        :Loc{
            DIALOG_INTRO = [[
                player:
                    Nah, I think I'll just sit this one out.
                agent:
                    Okay, then.
                * You decide to skip this question and let the others debate.
                * And you observe the behaviour of others.
            ]],
            DIALOG_POST = [[
                * This observation is very insightful(hopefully), and you are now more prepared for the next debate!
            ]],
            OPT_CONTINUE = "Continue",
            OPT_REVIEW = "Review popularity",
            DIALOG_REVIEW = [[
                * Currently, the most popular candidates are: {1#agent_list}, in that order.
            ]],
            -- DIALOG_REVIEW_PERSON = [[
            --     * {1#agent} has a popularity of {2}.
            -- ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                local neg, pos = {}, {}
                for i, agent in ipairs(cxt.quest.param.candidates) do
                    local issue = DemocracyConstants.issue_data[cxt.quest.param.topic]

                    -- The default index of a person.
                    local stance_index = issue:GetAgentStanceIndex(agent)
                    -- How much a person's opinion will shift in your favor
                    if stance_index < 0 then
                        table.insert(neg, agent)
                    elseif stance_index > 0 then
                        table.insert(pos, agent)
                    end
                end
                local winners
                if math.random(#neg + #pos) <= #neg then
                    winners = neg
                else
                    winners = pos
                end
                local mvp = table.arraypick(winners)
                for i, agent in ipairs(winners) do
                    DeltaPopularity(cxt.quest.param.popularity, agent, 7)
                end
                DeltaPopularity(cxt.quest.param.popularity, mvp, 5)

                cxt:Dialog("DIALOG_INTRO")

                cxt:TalkTo(mvp)
                cxt:Quip( mvp, "debate_mvp")

                cxt:Dialog("DIALOG_POST")
                ConvoUtil.DoResolveDelta(cxt, 15)
                cxt.quest.param.fatigued = false
                DoAutoSave()
            end
            cxt:Opt("OPT_CONTINUE")
                :GoTo("STATE_QUESTION")
            cxt:Opt("OPT_REVIEW")
                -- :Dialog("DIALOG_REVIEW")
                :Fn(function(cxt)
                    local ranking = shallowcopy(cxt.quest.param.candidates)
                    table.insert(ranking, 1, cxt.player)
                    table.stable_sort(ranking, function(a,b)
                        return (cxt.quest.param.popularity[a:GetID()] or 0) > (cxt.quest.param.popularity[b:GetID()] or 0)
                    end)
                    cxt:Dialog("DIALOG_REVIEW", ranking)
                    -- for id, val in pairs(cxt.quest.param.popularity) do
                    --     cxt:Dialog("DIALOG_REVIEW_PERSON", TheGame:GetGameState():GetAgent(id), val)
                    -- end
                end)
        end)
    :State("STATE_DEBATE_SUMMARY")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    That was an excellent debate!
                    Each candidate voiced their opinion on the matter, and a lot of very interested points are raised.
            ]],
            DIALOG_WIN_LANDSLIDE = [[
                agent:
                    Although, without a doubt, the candidates that support {winner_pov#pol_stance} won by a landslide.
            ]],
            DIALOG_WIN_NORMAL = [[
                agent:
                    It was quite an interesting debate, but ultimately, the candidates that support {winner_pov#pol_stance} won.
            ]],
            DIALOG_WIN_CLOSE = [[
                agent:
                    Both sides pull up a good fight, but in the end, the candidates that support {winner_pov#pol_stance} won by a tiny margin.
            ]],
            DIALOG_WINNER_MVP = [[
                agent:
                    It is undeniable that {1#agent_list} that {2*contributes|contribute} the most to the debate.
                    Thanks to {2*{3.hisher}|their} effort, {2*{3.hisher}|their} side is able to win the debate.
            ]],
            DIALOG_LOSER_MVP = [[
                agent:
                    Although, we can all agree that {1#agent_list} put out a good fight there.
                    {2*{3.HisHer}|Their} {2*effort is|efforts are} very valiant, although {2*it|they} didn't work out in the end.
            ]],
            DIALOG_OTHER_OF_NOTE = [[
                agent:
                    Other candidates, like {1#agent_list}, also did well in this debate, although not as well as those previously mentioned.
            ]],
            DIALOG_END = [[
                agent:
                    Well done, everyone!
                    Anyway, let's move on.
            ]],
            OPT_CONTINUE = "Continue",
            OPT_REVIEW = "Review popularity",
            DIALOG_REVIEW = [[
                * Currently, the most popular candidates are: {1#agent_list}, in that order.
            ]],
            -- DIALOG_REVIEW_PERSON = [[
            --     * {1#agent} has a popularity of {2}.
            -- ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt:Dialog("DIALOG_INTRO")
                local winner_delta = 0
                if cxt.quest.param.debate_result.win_margin <= 0.5 then
                    cxt:Dialog("DIALOG_WIN_CLOSE")
                    winner_delta = 3
                elseif cxt.quest.param.debate_result.win_margin <= 2 then
                    cxt:Dialog("DIALOG_WIN_NORMAL")
                    winner_delta = 5
                else
                    cxt:Dialog("DIALOG_WIN_LANDSLIDE")
                    winner_delta = 8
                end
                for i, agent in ipairs(cxt.quest.param.debate_result.won_game and
                    cxt.quest.param.allies or cxt.quest.param.opponents) do

                    DeltaPopularity(cxt.quest.param.popularity, agent, winner_delta)
                end
                if cxt.quest.param.debate_result.won_game then
                    DeltaPopularity(cxt.quest.param.popularity, cxt.player, winner_delta)
                end
                for i, agent in ipairs(cxt.quest.param.debate_result.ally_survivors) do
                    DeltaPopularity(cxt.quest.param.popularity, agent, 2)
                end
                for i, agent in ipairs(cxt.quest.param.debate_result.opponent_survivors) do
                    DeltaPopularity(cxt.quest.param.popularity, agent, 2)
                end
                local winner_mvps = {}
                local loser_mvps = {}
                for i, agent in ipairs(cxt.quest.param.debate_result.mvp) do
                    if agent:IsPlayer() or table.arraycontains(cxt.quest.param.allies, agent) then
                        if cxt.quest.param.debate_result.won_game then
                            table.insert(winner_mvps, agent)
                        else
                            table.insert(loser_mvps, agent)
                        end
                    elseif table.arraycontains(cxt.quest.param.opponents, agent) then
                        if cxt.quest.param.debate_result.won_game then
                            table.insert(loser_mvps, agent)
                        else
                            table.insert(winner_mvps, agent)
                        end
                    end
                end
                if #winner_mvps > 0 then
                    cxt:Dialog("DIALOG_WINNER_MVP", winner_mvps, #winner_mvps, winner_mvps[1])
                    for i, agent in ipairs(winner_mvps) do
                        DeltaPopularity(cxt.quest.param.popularity, agent, 5)
                    end
                end
                if #loser_mvps > 0 then
                    cxt:Dialog("DIALOG_LOSER_MVP", loser_mvps, #loser_mvps, loser_mvps[1])
                    for i, agent in ipairs(loser_mvps) do
                        DeltaPopularity(cxt.quest.param.popularity, agent, 5)
                    end
                end
                if #cxt.quest.param.debate_result.valuable_players > 0 then
                    cxt:Dialog("DIALOG_OTHER_OF_NOTE", cxt.quest.param.debate_result.valuable_players)
                    for i, agent in ipairs(cxt.quest.param.debate_result.valuable_players) do
                        DeltaPopularity(cxt.quest.param.popularity, agent, 3)
                    end
                end
                cxt:Dialog("DIALOG_END")
                cxt.quest.param.fatigued = true
                DoAutoSave()
            end
            -- DBG(cxt.quest.param.popularity)
            cxt:Opt("OPT_CONTINUE")
                :GoTo("STATE_QUESTION")
            cxt:Opt("OPT_REVIEW")
                -- :Dialog("DIALOG_REVIEW")
                :Fn(function(cxt)
                    local ranking = shallowcopy(cxt.quest.param.candidates)
                    table.insert(ranking, 1, cxt.player)
                    table.stable_sort(ranking, function(a,b)
                        return (cxt.quest.param.popularity[a:GetID()] or 0) > (cxt.quest.param.popularity[b:GetID()] or 0)
                    end)
                    cxt:Dialog("DIALOG_REVIEW", ranking)
                    -- for id, val in pairs(cxt.quest.param.popularity) do
                    --     cxt:Dialog("DIALOG_REVIEW_PERSON", TheGame:GetGameState():GetAgent(id), val)
                    -- end
                end)
        end)
    :State("STATE_END")
        :Loc{
            DIALOG_END = [[
                agent:
                    !right
                    That is all, folks!
                * Wow, that was a handful. If you are a shroke or a kradeshi.
                * For anyone else, ehh...
                * Anyway, let's see how you do!
            ]],
            DIALOG_CHEER = [[
                {player_winner?
                    * Oh wow! You are really popular!
                    * Everyone just cheers you on!
                    |
                    * Oh wow! You are not really popular!
                    * Everyone cheers on {1#agent} instead!
                    * How are you ever going to recover?
                }
            ]],
            DIALOG_FRIEND_LOST = [[
                * {1#agent_list} {2*looks|look} at you with disappointment.
                * It is clear that your opinions displayed during the debate disappointed {2*{3.himher}|them}.
            ]],
        }
        :Fn(function(cxt)
            cxt:TalkTo(cxt:GetCastMember("host"))
            cxt:Dialog("DIALOG_END")
            cxt.quest.param.popularity_rankings = shallowcopy(cxt.quest.param.candidates)
            table.insert(cxt.quest.param.popularity_rankings, 1, cxt.player)
            table.stable_sort(cxt.quest.param.popularity_rankings, function(a,b)
                return (cxt.quest.param.popularity[a:GetID()] or 0) > (cxt.quest.param.popularity[b:GetID()] or 0)
            end)
            cxt.quest.param.winner = cxt.quest.param.popularity_rankings[1]
            cxt.quest.param.player_winner = cxt.quest.param.winner and cxt.quest.param.winner:IsPlayer()
            for i, agent in ipairs(cxt.quest.param.popularity_rankings) do
                if agent:IsPlayer() then
                    cxt.quest.param.player_rank = i
                else
                    if i >= 3 then
                        DemocracyUtil.TryMainQuestFn("DeltaOppositionSupport", DemocracyUtil.GetOppositionID(agent), 30 - i * 10)
                    end
                end
            end
            if not cxt.quest.param.player_rank then
                cxt.quest.param.player_rank = #cxt.quest.param.popularity_rankings + 1
            end
            if cxt.quest.param.player_rank == 1 then
                cxt.quest.param.good_debate = true
            elseif cxt.quest.param.player_rank > 2 then
                cxt.quest.param.bad_debate = true
            end


            if cxt.quest.param.parent_quest then
                cxt.quest.param.parent_quest.param.did_debate_scrum = true
                cxt.quest.param.parent_quest.param.good_debate = cxt.quest.param.good_debate
                cxt.quest.param.parent_quest.param.bad_debate = cxt.quest.param.bad_debate
                cxt.quest.param.parent_quest.param.popularity_rankings = cxt.quest.param.popularity_rankings
            end

            cxt:Dialog("DIALOG_CHEER", cxt.quest.param.popularity_rankings[1])

            local betrayed_friends = {}
            for id, delta in pairs(cxt.quest.param.candidate_opinion) do
                if delta <= -1 then
                    local agent = TheGame:GetGameState():GetAgent(id)
                    if agent:GetRelationship() >= RELATIONSHIP.LIKED or DemocracyUtil.GetAlliance(agent) then
                        table.insert(betrayed_friends, agent)
                        agent:OpinionEvent(OPINION.DISLIKE_IDEOLOGY)
                    end
                end
            end
            if #betrayed_friends > 0 then
                cxt:Dialog("DIALOG_FRIEND_LOST", betrayed_friends, #betrayed_friends, betrayed_friends[1])
            end
            cxt.quest.param.betrayed_friends = betrayed_friends

            cxt.quest:Complete("do_debate")

            local your_score = cxt.quest.param.popularity[cxt.player:GetID()] or 0
            local main_quest = TheGame:GetGameState():GetMainQuest()
            local support_offset = {3, -3, -12}
            if cxt.quest.param.player_rank <= #support_offset then
                local support = DemocracyUtil.GetBaseRallySupport(TheGame:GetGameState():GetCurrentBaseDifficulty() + 1) + support_offset[cxt.quest.param.player_rank]
                DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", support, "COMPLETED_QUEST_MAIN")
            end
            main_quest.param.good_debate_scrum = not cxt.quest.param.bad_debate
            if main_quest then
                main_quest.param.debate_scrum_result = cxt.quest.param.popularity_rankings
            end

            local METRIC_DATA =
            {
                player_score = your_score,
                ranking = cxt.quest.param.player_rank,
                popularity = {},
                player_data = TheGame:GetGameState():GetPlayerState(),
            }
            for id, data in pairs(cxt.quest.param.popularity) do
                local agent = TheGame:GetGameState():GetAgent(id)
                if agent then
                    METRIC_DATA.popularity[agent:GetContentID()] = data
                end
            end
            DemocracyUtil.SendMetricsData("DAY_3_BOSS_SUMMARY", METRIC_DATA)

            StateGraphUtil.AddEndOption(cxt)
        end)
-- QDEF:AddConvo("report_to_advisor", "primary_advisor")
--     :ConfrontState("STATE_CONFRONT")
--     :Loc{
--         DIALOG_REVIEW = [[
--             agent:
--                 You are back.
--             player:
--                 Yeah.
--             agent:
--             {good_debate?
--                 !clap
--                 I have to say, that was quite impressive.
--                 Everyone has their eyes on you!
--                 Well done!
--             }
--             {bad_debate?
--                 !sigh
--                 Are you sure you tried?
--             player:
--                 I mean, yeah?
--             agent:
--                 Well the results doesn't reflect that way.
--                 Nobody in the crowd remembers you.
--             }
--             {not good_debate and not bad_debate?
--                 That was not that great, but certainly not the worse.
--                 I hoped you can do better than that.
--             player:
--                 It's way too hard to be first at everything at life.
--                 So I'd settle for second place.
--             agent:
--                 {advisor_hostile?
--                     That's why you are less successful than I am, huh?
--                     But whatever, I don't care.
--                     |
--                     !shrug
--                     Fair enough.
--                 }
--             }
--             agent:
--                 Anyway, we can talk more later during the summaries.
--         ]],
--     }
--     :Fn(function(cxt)
--         cxt:Dialog("DIALOG_REVIEW")

--         cxt.quest:Complete()
--         StateGraphUtil.AddEndOption(cxt)
--     end)
QDEF:AddConvo("talk_to_candidates")
    :AttractState("STATE_CHAT", function(cxt)
        cxt.quest.param.post_debate_chat = cxt.quest.param.post_debate_chat or {}
        if not DemocracyUtil.GetOppositionData(cxt:GetAgent()) then
            return false
        end
        return not table.arraycontains(cxt.quest.param.post_debate_chat, cxt:GetAgent())
    end)
        :Loc{
            DIALOG_OPPOSE = [[
                agent:
                    !sigh
                    I can't believe you betrayed my trust like that!
                    I thought we share the same ideology!
                    Guess I was wrong.
            ]],
            DIALOG_GENERAL = [[
                agent:
                {good_debate?
                    {political_ally?
                        !clap
                        Well done, {player}! I knew you had it in you.
                        Clearly, I made the right choice by allying with you.
                    player:
                        Great, thanks.
                    }
                    {not political_ally?
                        !clap
                        Wow! Impressive trick you pulled here.
                        Now I have to be careful.
                    player:
                        Oh wow, thanks.
                    }
                }
                {not good_debate and not bad_debate?
                    {liked?
                        !happy
                        You did pretty good today.
                    player:
                        Thanks. Not as good as you, though.
                    agent:
                        Don't be too modest here.
                    }
                    {not liked?
                        That was a nice debate!
                    player:
                        Thanks.
                    }
                }
                {bad_debate?
                    {liked?
                        What's up?
                    player:
                        Didn't do so well today.
                    agent:
                        Don't be so hard on yourself. I'm sure you will recover.
                    }
                    {not liked?
                        What a great debate that was!
                    player:
                        Is it really?
                    agent:
                        Not really.
                        I'm just saying that to be polite.
                    }
                }
            ]],
            DIALOG_SUPPORT = [[
                agent:
                {disliked?
                    Perhaps I judged you too harshly.
                }
                {liked or political_ally?
                    I know I could count on you!
                }
                {not disliked and not liked and not political_ally?
                    Maybe we are more alike than we thought.
                }
            ]],
            OPT_APOLOGIZE = "Apologize",
            DIALOG_APOLOGIZE = [[
                player:
                    [p] Look, I'm sorry that I stood against you tonight.
                    I promise I will not do that again.
                agent:
                    Is that so?
            ]],
            DIALOG_APOLOGIZE_SUCCESS = [[
                agent:
                    [p] You know what? Because you asked so nicely, I'll forgive you.
                    Not worth it worrying about such a small problem.
            ]],
            DIALOG_APOLOGIZE_FAILURE = [[
                agent:
                    [p] I think I heard more than enough of your excuses.
                    We're done here.
            ]],
            OPT_IGNORE_CONCERN = "Ignore {agent}'s concern",
            DIALOG_IGNORE_CONCERN = [[
                player:
                    [p] I did what I had to do.
                agent:
                    That's fair, I guess.
                    But since you're not willing to help me, I'm not willing to help you.
            ]],
            OPT_ALLIANCE = "Use this opportunity to talk about potential alliance",
            DIALOG_ALLIANCE_TALK_INTRO = [[
                player:
                    [p] I say you and me, we make a great team.
                    How about this: we make an alliance for this upcoming election.
            ]],
        }
        :Fn(function(cxt)
            local who = cxt:GetAgent()
            table.insert(cxt.quest.param.post_debate_chat, who)
            local opposition_data = DemocracyUtil.GetOppositionData(who)
            if table.arraycontains(cxt.quest.param.betrayed_friends or {}, who) then
                cxt:Dialog("DIALOG_OPPOSE")
                cxt:Opt("OPT_APOLOGIZE")
                    :Dialog("DIALOG_APOLOGIZE")
                    :UpdatePoliticalStance(opposition_data.platform, DemocracyUtil.GetAgentStanceIndex(opposition_data.platform, who))
                    :Negotiation{

                    }:OnSuccess()
                        :Dialog("DIALOG_APOLOGIZE_SUCCESS")
                        :Fn(function(cxt)
                            if who:GetRelationship() < RELATIONSHIP.NEUTRAL then
                                who:OpinionEvent(OPINION.RECONCILED_GRUDGE)
                            end
                            table.arrayremove(cxt.quest.param.betrayed_friends, who)
                            -- TODO: Actually do something about not reconciling with the ally you betrayed
                        end)
                    :OnFailure()
                        :Dialog("DIALOG_APOLOGIZE_FAILURE")
                cxt:Opt("OPT_IGNORE_CONCERN")
                    :Dialog("DIALOG_IGNORE_CONCERN")
            elseif cxt.quest.param.candidate_opinion and (cxt.quest.param.candidate_opinion[who:GetID()] or 0) >= 2 then
                cxt:Dialog("DIALOG_SUPPORT")
                if who:GetRelationship() < RELATIONSHIP.NEUTRAL then
                    who:OpinionEvent(OPINION.SHARE_IDEOLOGY)
                elseif who:GetRelationship() == RELATIONSHIP.NEUTRAL then
                    -- Special alliance talk.
                    cxt:Opt("OPT_ALLIANCE")
                        :Fn(function(cxt)
                            DemocracyUtil.DoAllianceConvo(cxt, who, nil, 15)
                        end)

                    StateGraphUtil.AddEndOption(cxt)
                end
            else
                cxt:Dialog("DIALOG_GENERAL")
            end
        end)
