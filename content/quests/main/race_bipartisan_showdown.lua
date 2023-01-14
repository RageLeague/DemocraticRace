local QDEF = QuestDef.Define
{
    title = "Bipartisan Showdown",
    desc = "The big debate between two prominent candidates is happening. Time to defeat your opposition in the debate.",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/interview.png"),

    qtype = QTYPE.STORY,
    collect_agent_locations = function(quest, t)
        table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('backroom'), role = CHARACTER_ROLES.VISITOR})
        table.insert(t, { agent = quest:GetCastMember("host"), location = quest:GetCastMember('theater')})
    end,

    on_destroy = function(quest)
        quest:GetCastMember("primary_advisor"):GetBrain():SendToWork()
        if quest.param.parent_quest then
            quest.param.parent_quest.param.did_final_debate = true
        end
    end,

    postcondition = function(quest)
        local parent_quest = quest.param.parent_quest
        if parent_quest and parent_quest.param.vote_result then
            local has_primary = false
            local result = shallowcopy(parent_quest.param.vote_result)
            for i = #result, 1, -1 do
                -- Filter out the ones dropped out of the race
                if not result[i][1]:IsPlayer() and not DemocracyUtil.TryMainQuestFn("IsCandidateInRace", result[i][1]) then
                    table.remove(result, i)
                end
            end
            if result[1] and result[1][1] then
                if result[1][1] ~= TheGame:GetGameState():GetPlayerAgent() then
                    has_primary = true
                    quest:AssignCastMember("opponent", result[1][1])
                end
            end
            if result[2] and result[2][1] then
                if result[2][1] ~= TheGame:GetGameState():GetPlayerAgent() then
                    if not has_primary then
                        has_primary = true
                        quest:AssignCastMember("opponent", result[2][1])
                    else
                        quest:AssignCastMember("secondary_opponent", result[2][1])
                    end
                end
            end
            quest.param.previous_bad_debate = parent_quest.param.low_player_votes
            return true
        end
        -- This is used as a fallback in case the new system fails, or if the parent quest does not have enough info.
        if parent_quest then
            quest.param.previous_bad_debate = parent_quest.param.previous_bad_debate
        end
        local valid_candidates = DemocracyUtil.GetAllOppositions()
        table.sort(valid_candidates, function(a,b) return DemocracyUtil.GetOppositionViability(a) > DemocracyUtil.GetOppositionViability(a) end)

        if #valid_candidates == 0 then
            -- How did you even get to this point?
        else
            quest:AssignCastMember("opponent", TheGame:GetGameState():GetMainQuest():GetCastMember(valid_candidates[1]))
            if #valid_candidates >= 2 and quest.param.previous_bad_debate then
                quest:AssignCastMember("secondary_opponent", TheGame:GetGameState():GetMainQuest():GetCastMember(valid_candidates[2]))
            end
        end
        return true
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
}
:AddCast{
    cast_id = "opponent",
    no_validation = true,
    optional = true,
    when = QWHEN.MANUAL,
}
:AddCast{
    cast_id = "secondary_opponent",
    optional = true,
    no_validation = true,
    when = QWHEN.MANUAL,
}
:AddObjective{
    id = "go_to_debate",
    title = "Go to interview",
    desc = "Meet up with {primary_advisor} at the Grand Theater.",
    mark = {"backroom"},
    state = QSTATUS.ACTIVE,
}
:AddObjective{
    id = "do_debate",
    title = "Do the debate",
    desc = "Defeat {opponent} in the debate.",
    mark = {"theater"},
    -- state = QSTATUS.ACTIVE,
    events = {
    },
    on_complete = function(quest)
    end,
}
:AddObjective{
    id = "do_debate_double",
    title = "Do the debate",
    desc = "Defeat both {opponent} and {secondary_opponent} in the debate.",
    mark = {"theater"},
    -- state = QSTATUS.ACTIVE,
    events = {
    },
    on_complete = function(quest)
    end,
}
:AddOpinionEvents{
    interrupted_event =
    {
        delta = OPINION_DELTAS.DIMINISH,
        txt = "Rudely interrupted their event",
    },
}
DemocracyUtil.AddPrimaryAdvisor(QDEF, true)
DemocracyUtil.AddHomeCasts(QDEF)

QDEF:AddConvo("go_to_debate")
    :Confront(function(cxt)
        if cxt:GetCastMember("primary_advisor") and cxt.location == cxt.quest:GetCastMember("backroom") then
            if not cxt.quest:GetCastMember("opponent") then
                return "STATE_NO_OPPONENT"
            elseif cxt.quest:GetCastMember("secondary_opponent") then
                return "STATE_TWO_OPPONENT"
            else
                return "STATE_CONFRONT"
            end
        end
        if cxt.location == cxt.quest:GetCastMember("theater") then
            return "STATE_THEATER"
        end
    end)
    :State("STATE_THEATER")
        :Loc{
            DIALOG_INTRO = [[
                * You arrived at the Grand Theater.
                * Looks like the interview hasn't started yet.
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
    :State("STATE_NO_OPPONENT")
        :Loc{
            DIALOG_INTRO = [[
                {not enter_from_theater?
                    * You arrive at the Grand Theater, and are ushered into a back room. You barely make it into the room before you're ambushed by {primary_advisor}.
                }
                {enter_from_theater?
                    * Just as you begin to look for {primary_advisor}, looks like {primary_advisor.heshe} found you first.
                }
                player:
                    !left
                primary_advisor:
                    !right
                    [p] So apparently there are no opponents.
                    That is pretty impressive, actually, what you did.
                    But now there is no debate, since there are no opponents.
                    So I guess we are done here.
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
                cxt.quest:Complete()
            end
            StateGraphUtil.AddLeaveLocation(cxt)
        end)
    :State("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                {not enter_from_theater?
                    * You arrive at the Grand Theater, and are ushered into a back room. You barely make it into the room before you're ambushed by {primary_advisor}.
                }
                {enter_from_theater?
                    * Just as you begin to look for {primary_advisor}, looks like {primary_advisor.heshe} found you first.
                }
                player:
                    !left
                primary_advisor:
                    !right
                    [p] Your opponent is {opponent}.
            ]],
            OPT_ASK_INTERVIEW = "Q1",
            DIALOG_ASK_INTERVIEW = [[
                player:
                    [p] Beep.
            ]],
            OPT_ASK_AUDIENCE = "Q2",
            DIALOG_ASK_AUDIENCE = [[
                player:
                    [p] Boop.
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
                    Imagine doing a debate, and the audience just see {pet.a_desc} on the stage.
                    That would certainly cause chaos, and they can't have that.
                player:
                    ...
                agent:
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
                DemocracyUtil.PopulateTheater(cxt.quest, cxt.quest:GetCastMember("theater"), 8)
                cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
                cxt.quest.param.party_pets = TheGame:GetGameState():GetCaravan():GetPets()
                if cxt.quest.param.party_pets and #cxt.quest.param.party_pets > 0 then
                    cxt.enc.scratch.has_pet = true
                    cxt:ReassignCastMember("pet", cxt.quest.param.party_pets[1])
                end
                cxt:Dialog("DIALOG_INTRO")
                cxt.quest:Complete("go_to_debate")
                cxt.quest:Activate("do_debate")
            end
            cxt:Question("OPT_ASK_INTERVIEW", "DIALOG_ASK_INTERVIEW")
            cxt:Question("OPT_ASK_AUDIENCE", "DIALOG_ASK_AUDIENCE")
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
    :State("STATE_TWO_OPPONENT")
        :Loc{
            DIALOG_INTRO = [[
                {not enter_from_theater?
                    * You arrive at the Grand Theater, and are ushered into a back room. You barely make it into the room before you're ambushed by {primary_advisor}.
                }
                {enter_from_theater?
                    * Just as you begin to look for {primary_advisor}, looks like {primary_advisor.heshe} found you first.
                }
                player:
                    !left
                primary_advisor:
                    !right
                    [p] {opponent} and {secondary_opponent} are on the stage.
                    We aren't invited, that's why we are here to crash the party.
            ]],
            OPT_ASK_INTERVIEW = "Q1",
            DIALOG_ASK_INTERVIEW = [[
                player:
                    [p] Beep.
            ]],
            OPT_ASK_AUDIENCE = "Q2",
            DIALOG_ASK_AUDIENCE = [[
                player:
                    [p] Boop.
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
                    Imagine doing a debate, and the audience just see {pet.a_desc} on the stage.
                    That would certainly cause chaos, and they can't have that.
                player:
                    ...
                agent:
                    [p] Besides, us crashing into the debate was already highly unorthodox.
                    We don't want to cause more trouble.
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
                DemocracyUtil.PopulateTheater(cxt.quest, cxt.quest:GetCastMember("theater"), 8)
                cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
                cxt.quest.param.party_pets = TheGame:GetGameState():GetCaravan():GetPets()
                if cxt.quest.param.party_pets and #cxt.quest.param.party_pets > 0 then
                    cxt.enc.scratch.has_pet = true
                    cxt:ReassignCastMember("pet", cxt.quest.param.party_pets[1])
                end
                cxt:Dialog("DIALOG_INTRO")
                cxt.quest:Complete("go_to_debate")
                cxt.quest:Activate("do_debate_double")
            end
            cxt:Question("OPT_ASK_INTERVIEW", "DIALOG_ASK_INTERVIEW")
            cxt:Question("OPT_ASK_AUDIENCE", "DIALOG_ASK_AUDIENCE")
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
                * [p] You see your opponent.
                player:
                    !left
                opponent:
                    !right
                * You have some choice of words with {opponent}.
                opponent:
                    %pre_dual_argument
                * They hate you, and now it's time for you to debate.
            ]],
            OPT_DEBATE = "Debate!",
            DIALOG_DEBATE_SUCCESS = [[
                * [p] Cool, you won the debate.
                * But in truth, in the end, nobody won.
                * Nobody learned anything about you or your opponent other than you can argue well.
            ]],
            DIALOG_DEBATE_FAILURE = [[
                * [p] You get very agitated and break down on the stand.
                * You lose!
            ]],
        }
        :Fn(function(cxt)
            cxt:TalkTo("opponent")
            cxt:Dialog("DIALOG_INTRO")
            cxt:GetCastMember("opponent"):OpinionEvent(OPINION.DISLIKE_IDEOLOGY_II)
            local RESOLVE = {60, 90, 110, 130}
            local resolve_required = DemocracyUtil.CalculateBossScale(RESOLVE)

            cxt:Opt("OPT_DEBATE")
                :Negotiation{
                    suppressed = cxt.quest.param.party_pets,
                    difficulty = 5,
                    flags = NEGOTIATION_FLAGS.WORDSMITH,
                    enemy_resolve_required = resolve_required,
                    on_start_negotiation = function(minigame)
                    end,
                }:OnSuccess()
                    :Dialog("DIALOG_DEBATE_SUCCESS")
                    :CompleteQuest()
                    :DoneConvo()
                :OnFailure()
                    :Dialog("DIALOG_DEBATE_FAILURE")
                    :Fn(function(cxt)
                        DemocracyUtil.AddAutofail(cxt, false)
                    end)
        end)
QDEF:AddConvo("do_debate_double")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt.location == cxt.quest:GetCastMember("theater") end)
        :Loc{
            DIALOG_INTRO = [[
                * [p] You see your opponents.
                secondary_opponent:
                    !left
                opponent:
                    !right
                * Looks like the debate is about to start.
                * You object, surprising everyone.
                * The host is pretty annoyed you disrupted the debate.
                * But this isn't about the host, it's about the two candidates who took your spotlight.
            ]],
            OPT_DEBATE = "Debate {1#agent}",
            DIALOG_DEBATE = [[
                player:
                    !left
                opponent:
                    !right
                * [p] You address {opponent}.
                * {opponent} hates you.
                * {secondary_opponent} gets annoyed of you for taking {secondary_opponent.hisher} spotlight, so {secondary_opponent.heshe} heckles you!
            ]],
            DIALOG_DEBATE_SUCCESS = [[
                * [p] Cool, you won the debate.
                * But in truth, in the end, nobody won.
                * Nobody learned anything about you or your opponent other than you can argue well.
            ]],
            DIALOG_DEBATE_FAILURE = [[
                * [p] You get very agitated and break down on the stand.
                * You lose!
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")

            cxt:GetCastMember("host"):OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("interrupted_event"))

            local function CreateDebateOption(opponent, other_opponent)

                local RESOLVE = {60, 90, 110, 130}
                local resolve_required = DemocracyUtil.CalculateBossScale(RESOLVE)

                cxt:Opt("OPT_DEBATE", opponent)
                    :Fn(function(cxt)
                        cxt.quest:UnassignCastMember("opponent")
                        cxt.quest:UnassignCastMember("secondary_opponent")
                        cxt.quest:AssignCastMember("opponent", opponent)
                        cxt.quest:AssignCastMember("secondary_opponent", other_opponent)

                        cxt:TalkTo("opponent")
                    end)
                    :Dialog("DIALOG_DEBATE")
                    :ReceiveOpinion(OPINION.DISLIKE_IDEOLOGY_II, nil, opponent)
                    :Negotiation{
                        target_agent = opponent,
                        hinders = { other_opponent },
                        suppressed = cxt.quest.param.party_pets,
                        difficulty = 5,
                        flags = NEGOTIATION_FLAGS.WORDSMITH,
                        enemy_resolve_required = resolve_required,
                        on_start_negotiation = function(minigame)
                            for i, card in ipairs(minigame.start_params.hinder_cards) do
                                if DemocracyUtil.GetOppositionData(card.owner) then
                                    minigame.start_params.hinder_cards[i] = Negotiation.Card("faction_negotiation_hinder", card.owner)
                                end
                            end
                        end,
                    }:OnSuccess()
                        :Dialog("DIALOG_DEBATE_SUCCESS")
                        :CompleteQuest()
                        :DoneConvo()
                    :OnFailure()
                        :Dialog("DIALOG_DEBATE_FAILURE")
                        :Fn(function(cxt)
                            DemocracyUtil.AddAutofail(cxt, false)
                        end)
            end

            CreateDebateOption(cxt:GetCastMember("opponent"), cxt:GetCastMember("secondary_opponent"))
            CreateDebateOption(cxt:GetCastMember("secondary_opponent"), cxt:GetCastMember("opponent"))
        end)
