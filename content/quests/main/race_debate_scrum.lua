local HOST_BEHAVIOUR =
{
    OnInit = function( self, difficulty )
        self.negotiator:AddModifier("DEBATE_SCRUM_TRACKER")
    end,
    Cycle = function(self, turns)
    end,
}

local QDEF = QuestDef.Define
{
    title = "Debate Scrum",
    desc = "You are invited to the presidential debate with other candidates. Impress the audience with your debate skills.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/interview.png"),

    qtype = QTYPE.STORY,
    collect_agent_locations = function(quest, t)
        -- if quest:IsActive("return_to_advisor") then
        --     table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('home')})
        -- else
        table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('backroom'), role = CHARACTER_ROLES.VISITOR})
        -- end
        table.insert(t, { agent = quest:GetCastMember("host"), location = quest:GetCastMember('theater')})
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
        for i = 1, 5 do
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
        if quest.param.parent_quest then
            quest.param.parent_quest.param.did_debate_scrum = true
        end
    end,
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
}

DemocracyUtil.AddPrimaryAdvisor(QDEF, true)
DemocracyUtil.AddHomeCasts(QDEF)
DemocracyUtil.AddOppositionCast(QDEF)
local function ProcessMinigame(minigame, win_minigame)
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
                local res, maxres = modifier:GetResolve()
                data.win_margin = data.win_margin + 0.2 + (res / maxres)
            end
        end
    else
        for i, modifier in minigame:GetOpponentNegotiator():Modifiers() do
            if modifier.modifier_type == MODIFIER_TYPE.CORE and modifier:GetResolve() then
                if modifier.candidate_agent then
                    table.insert_unique(data.ally_survivors, modifier.candidate_agent)
                end
                local res, maxres = modifier:GetResolve()
                data.win_margin = data.win_margin + 0.2 + (res / maxres)
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
                if val.score / data.mvp_score >= 0.95 then
                    table.insert(data.mvp, val.agent)
                elseif val.score / data.mvp_score >= 0.75 then
                    table.insert(data.valuable_players, val.agent)
                end
            end
        end
    end
    return data
end
local function CreateDebateOption(cxt, helpers, hinders, topic, stance)
    cxt:Opt("OPT_SIDE", topic .. "_" .. stance)
        :UpdatePoliticalStance(topic, stance, false)
        :Dialog("DIALOG_SIDE")
        :Fn(function(cxt)
            cxt.quest.param.allies = helpers
            cxt.quest.param.opponents = hinders
        end)
        :Negotiation{
            flags = NEGOTIATION_FLAGS.NO_BYSTANDERS | NEGOTIATION_FLAGS.WORDSMITH | NEGOTIATION_FLAGS.NO_CORE_RESOLVE,
            helpers = helpers,
            hinders = hinders,
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
            end,
            on_success = function(cxt, minigame)
                cxt.quest.param.debate_result = ProcessMinigame(minigame, true)
                cxt.quest.param.winner_pov = topic .. "_" .. stance
                cxt:GoTo("STATE_DEBATE_SUMMARY")
            end,
            on_fail = function(cxt, minigame)
                cxt.quest.param.debate_result = ProcessMinigame(minigame, false)
                cxt.quest.param.winner_pov = topic .. "_" .. (-stance)
                cxt:GoTo("STATE_DEBATE_SUMMARY")
            end,
        }
end
local function DeltaPopularity(table, agent, delta)
    table[agent:GetID()] = (table[agent:GetID()] or 0) + delta
end
QDEF:AddConvo("go_to_debate")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt.location == cxt.quest:GetCastMember("backroom") end)
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
            ]],
        }
        :Fn(function(cxt)
            cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
            DemocracyUtil.PopulateTheater(cxt.quest, cxt.quest:GetCastMember("theater"), 8)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Complete("go_to_debate")
            cxt.quest:Activate("do_debate")
            cxt:Opt("OPT_LEAVE_LOCATION")
                :Fn(function(cxt)
                    cxt.encounter:DoLocationTransition(cxt.quest:GetCastMember("theater"))
                end)
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
                    This is my answer!
                * A debate is about to go down!
            ]],
            REASON_TXT = "Impress the audience with your slick negotiation skills! (You have {1} {1*point|points})",
        }
        :Fn(function(cxt)
            if not cxt.quest.param.questions or #cxt.quest.param.questions == 0 then
                -- Go to end state.
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
            cxt:GetAgent():SetTempNegotiationBehaviour(HOST_BEHAVIOUR)
            cxt:Quip(cxt:GetAgent(), "debate_question")
            CreateDebateOption(cxt, neg_helper, neg_hinder, cxt.quest.param.topic, -1)
            CreateDebateOption(cxt, pos_helper, pos_hinder, cxt.quest.param.topic, 1)
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
                * Current popularity standing:
            ]],
            DIALOG_REVIEW_PERSON = [[
                * {1#agent} has a popularity of {2}.
            ]],
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
            end
            DBG(cxt.quest.param.popularity)
            cxt:Opt("OPT_CONTINUE")
                :GoTo("STATE_QUESTION")
            cxt:Opt("OPT_REVIEW")
                :Dialog("DIALOG_REVIEW")
                :Fn(function(cxt)
                    for id, val in pairs(cxt.quest.param.popularity) do
                        cxt:Dialog("DIALOG_REVIEW_PERSON", TheGame:GetGameState():GetAgent(id), val)
                    end
                end)
        end)