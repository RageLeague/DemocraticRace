-- Outline:
-- The defendant is accused of stealing something valuable from the plaintiff.
-- Potential evidence:
--   * Witness saw accused leaving the estate.
--     * If innocent, either witness misremembered or witness fabricated testimony
--   * Accused left earrings behind.
--     * If innocent, someone stole the earings from the accused.
-- You can forge or find alibi, replace evidence, or "deal" with witness/plaintiff/prosecutor before the trial.

local QDEF = QuestDef.Define
{
    title = "Better Call {1}",
    title_fn = function(quest, str)
        local name
        if TheGame:GetGameState() and TheGame:GetGameState():GetPlayerAgent() then
            name = TheGame:GetGameState():GetPlayerAgent():GetName()
        else
            name = LOC(Content.GetCharacterDef("SAL"):GetLocNameKey())
        end
        return loc.format(str, name)
    end,
    desc = "Represent {giver} in a court of law.",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/battle_of_wits.png"),

    qtype = QTYPE.SIDE,

    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"REQUEST_JOB"},
    reward_mod = 0,
    can_flush = false,
    cooldown = EVENT_COOLDOWN.LONG,

    events = {
        base_difficulty_change = function(quest, new_diff, old_diff)
            quest:SetRank(new_diff)
        end,
        quests_changed = function(quest, event_quest)

        end
    },
    precondition = function(quest)
        local current_time = Now()
        local max_time = 2 * 4
        local wait_period = 2
        if current_time + wait_period > max_time then
            return false
        end
        quest.param.trial_time = math.random(current_time + wait_period, max_time)
        return true
    end,

    postcondition = function(quest)
        -- Whether the accused is actually guilty of the crime
        quest.param.actually_guilty = math.random() < 0.3

        -- Must have at least witness or evidence. Otherwise no case.
        while not quest.param.have_witness and not quest.param.have_evidence do
            quest.param.have_witness = math.random() < 0.65
            quest.param.have_evidence = math.random() < 0.65
        end

        if quest.param.have_witness then
            quest:AssignCastMember("witness")
        end

        if not quest.param.actually_guilty then
            quest.param.have_alibi = math.random() < 0.3
        end

        return true
    end,

    on_start = function(quest)
        quest:Activate("prepare_trial")
        quest:Activate("talk_to_defendant")
    end,

    on_complete = function(quest)
        local giver = quest:GetCastMember("giver")
        if not (quest.param.sub_optimal or quest.param.poor_performance) then
            giver:OpinionEvent(OPINION.DID_LOYALTY_QUEST)
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 4, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 5, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
        elseif quest.param.sub_optimal then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 3, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 8, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 4, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
        elseif quest.param.poor_performance then
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 3, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
        end
    end,

    AddEvidenceList = function(quest, evidence)
        quest.param.evidence_list = quest.param.evidence_list or {}
        table.insert_unique(quest.param.evidence_list, evidence)
    end,
    HasEvidence = function(quest, evidence)
        quest.param.evidence_list = quest.param.evidence_list or {}
        return table.arraycontains(quest.param.evidence_list, evidence)
    end,
}
:AddCast{
    cast_id = "giver",
    no_validation = true,
    provider = true,
    unimportant = true,
    condition = function(agent, quest)
        if agent:HasTag("curated_request_quest") then
            return false
        end
        if DemocracyUtil.GetWealth(agent) > 2 then
            return false
        end
        if agent:GetFactionID() == "ADMIRALTY" then
            return false
        end
        if agent:GetFaction():IsLawful() or agent:GetFactionID() == "RISE" then
            return true
        end
        return false
    end,
}
:AddCast{
    cast_id = "plaintiff",
    condition = function(agent, quest)
        return agent:GetFaction():IsLawful() and DemocracyUtil.GetWealth(agent) >= 3
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( "WEALTHY_MERCHANT" ) )
    end,
}
:AddDefCast("prosecutor", "ADMIRALTY_INVESTIGATOR")
:AddCast{
    cast_id = "witness",
    when = QWHEN.MANUAL,
    condition = function(agent, quest)
        return agent:GetFaction():IsLawful()
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( "WEALTHY_MERCHANT" ) )
    end,
}
:AddObjective{
    id = "prepare_trial",
    title = "Prepare for the trial ({1#relative_time})",
    title_fn = function(quest, str)
        return loc.format(str, (quest.param.trial_time or 0) - Now())
    end,
    desc = "Make enough preparations before the trial begins.",
}
:AddObjective{
    id = "talk_to_defendant",
    title = "Talk to {giver}, the defendant",
    desc = "Talk to {giver} to learn more about the case.",
    mark = function(quest, t, in_location)
        if in_location or DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("giver"))
        end
    end,
}
:AddObjective{
    id = "talk_to_plaintiff",
    title = "Talk to {plaintiff}, the plaintiff",
    desc = "Talk to {plaintiff} to learn more about the case.",
    mark = function(quest, t, in_location)
        if in_location or DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("plaintiff"))
        end
    end,
}
:AddObjective{
    id = "talk_to_prosecutor",
    title = "Talk to {prosecutor}, the prosecutor",
    desc = "Talk to {prosecutor} to learn more about the case.",
    mark = function(quest, t, in_location)
        if in_location or DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("prosecutor"))
        end
    end,
}
:AddObjective{
    id = "talk_to_witness",
    title = "Talk to {witness}, the witness",
    desc = "Talk to {witness} to learn more about the case.",
    mark = function(quest, t, in_location)
        if in_location or DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("witness"))
        end
    end,
}

QDEF:AddConvo("talk_to_defendant", "giver")
    :Loc{
        OPT_ASK = "Ask about the case",
        DIALOG_ASK = [[
            player:
                I would like to learn about the case.
            agent:
                What would you like to know?
        ]],
        OPT_FORGE_ALIBI = "Ask {agent} to falsify an alibi",
        DIALOG_FORGE_ALIBI = [[
            player:
                [p] Why don't you falsify an alibi?
            agent:
                What? But that's perjury!
        ]],
        DIALOG_FORGE_ALIBI_SUCCESS = [[
            player:
                [p] As long as you don't get caught.
                Besides, just keep your story straight, and have someone back it up.
                It's better than getting convicted.
            agent:
                If you say so.
        ]],
        DIALOG_FORGE_ALIBI_FAILURE = [[
            agent:
                [p] I thought you are a lawyer?
                That was terrible advice. I'm not doing it.
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_ASK")
            :SetQuestMark()
            :Dialog("DIALOG_ASK")
            :GoTo("STATE_QUESTIONS")

        if cxt.quest.param.asked_defendant_alibi and not cxt.quest.param.have_alibi and not cxt.quest.param.try_forge_alibi then
            cxt:BasicNegotiation("FORGE_ALIBI")
                :OnSuccess()
                    :Fn(function(cxt)
                        cxt.quest.param.try_forge_alibi = true
                        cxt.quest:DefFn("AddEvidenceList", "forged_alibi")
                    end)
                :OnFailure()
                    :Fn(function(cxt)
                        cxt.quest.param.try_forge_alibi = true
                    end)
        end
    end)
    :State("STATE_QUESTIONS")
        :Loc{
            OPT_SUMMARY = "Ask for a summary of the case",
            DIALOG_SUMMARY = [[
                player:
                    [p] What are you accused of?
                agent:
                    Apparently stealing {plaintiff}'s expensive jewelry.
                    Honestly, I didn't do it!
                    I mean, that's what they all say, but I genuinely didn't do it.
            ]],
            OPT_ALIBI = "Ask about Saturday afternoon",
            DIALOG_ALIBI = [[
                player:
                    [p] Turns out, the accusation against you is that you stole the jewelry at Saturday afternoon.
                agent:
                    But I didn't!
                player:
                    Do you happen to have an alibi during that time? That would certainly help.
                {have_alibi?
                    agent:
                        Actually, I do.
                        I was working the entire afternoon.
                        You can easily verify it by talking to everyone at the worksite.
                    player:
                        That is perfect, thanks.
                    *** {agent} has an airtight alibi when the crime occurred.
                }
                {not have_alibi?
                    agent:
                        No, I don't.
                    player:
                        Ahh... We will figure something out.
                }
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            cxt:Question("OPT_SUMMARY", "DIALOG_SUMMARY", function()
                if cxt.quest:IsInactive("talk_to_plaintiff") then
                    cxt.quest:Activate("talk_to_plaintiff")
                end
            end)
            if cxt.quest:DefFn("HasEvidence", "plaintiff_summary") then
                cxt:Question("OPT_ALIBI", "DIALOG_ALIBI", function()
                    if cxt.quest.param.have_alibi then
                        cxt.quest:AddEvidenceList("airtight_alibi")
                    end
                    cxt.quest.param.asked_defendant_alibi = true
                end)
            end
            StateGraphUtil.AddBackButton(cxt)
        end)

QDEF:AddConvo("talk_to_plaintiff", "plaintiff")
    :Loc{
        OPT_ASK = "Ask for information about the case",
        DIALOG_ASK = [[
            {first_time?
                player:
                    You are the one accusing {giver} of theft?
                {not liked?
                    agent:
                        So I am. What's it to you?
                    player:
                        It just so happens that I am representing {giver.himher} in court.
                    agent:
                        Oh, great. You are helping that leech.
                    player:
                        You haven't proved that in court yet.
                        Which is exactly why I am here. To learn about the case.
                }
                {liked?
                    agent:
                        So I am. What about it?
                    player:
                        It just so happens that I am representing {giver.himher} in court.
                    agent:
                        Why? Why are you representing that leech, {player}?
                    player:
                        Well, everyone deserves representation.
                        Besides, you haven't proved that in court yet.
                        Which is exactly why I am here. To learn about the case.
                }
            }
            {not first_time?
                player:
                    Let's talk about the case once more.
            }
        ]],
        DIALOG_ASK_SUCCESS = [[
            agent:
                Fine. You can ask {info_count} {info_count*question|questions}.
                What do you wish to know?
        ]],
        DIALOG_ASK_FAILURE = [[
            agent:
                No. I'm not obligated to tell you anything.
                This conversation is over.
        ]],
    }
    :Hub(function(cxt)
        cxt.quest.param.plaintiff_questions_asked = cxt.quest.param.plaintiff_questions_asked or {}
        if #cxt.quest.param.plaintiff_questions_asked < 3 then
            cxt:Opt("OPT_ASK")
                :SetQuestMark()
                :Dialog("DIALOG_ASK")
                :Negotiation{
                    on_start_negotiation = function(minigame)
                        local count = 3 - #cxt.quest.param.plaintiff_questions_asked - 1
                        for i = 1, count do
                            minigame:GetOpponentNegotiator():CreateModifier( "secret_intel", 1 )
                        end
                    end,
                    on_success = function(cxt, minigame)
                        local count = minigame:GetPlayerNegotiator():GetModifierStacks( "secret_intel" )
                        cxt.enc.scratch.info_count = count + 1
                        cxt:Dialog("DIALOG_ASK_SUCCESS")
                        cxt:GoTo("STATE_QUESTIONS")
                    end,
                    on_fail = function(cxt, minigame)
                        cxt:Dialog("DIALOG_ASK_FAILURE")
                        -- cxt.quest:Fail("talk_to_plaintiff")
                    end,
                }
        end
    end)
    :State("STATE_QUESTIONS")
        :Loc{
            OPT_SUMMARY = "Ask for a summary of the case",
            DIALOG_SUMMARY = [[
                player:
                    [p] Tell me what happened.
                agent:
                    I planned to go to a party Saturday night.
                    Turns out I can't find my expensive jewelry!
                    I'm sure that I had it the previous day, and I stayed at home during the morning, so {giver} must have stolen it during the afternoon.
                *** According to {agent}, the theft happened at Saturday afternoon.
            ]],
            OPT_EVIDENCE = "Ask for evidence",
            DIALOG_EVIDENCE = [[
                player:
                {not (asked_plaintiff_witness and not have_witness)?
                    [p] Do you have evidence proving {giver} has stolen your jewelry?
                }
                {asked_plaintiff_witness and not have_witness?
                    [p] You mentioned that you have decisive evidence against {giver}?
                }
                {have_evidence?
                    agent:
                        As a matter of fact, I do.
                        A piece of earring, left behind by {giver}.
                        If you want to take a look, {prosecutor} has the evidence.
                }
                {not have_evidence?
                    agent:
                        {prosecutor} is trying to find decisive evidence against {giver}.
                        You can talk to {prosecutor.himher} about it.
                    player:
                        The keyword here is "trying".
                        Sounds like your accusation against my client has no basis.
                    agent:
                        That's not true.
                        We have witness testimony that proves {giver}'s guilt.
                }
            ]],
            OPT_WITNESS = "Ask for witness",
            DIALOG_WITNESS = [[
                player:
                {not (asked_plaintiff_evidence and not have_evidence)?
                    [p] Do you have witnesses that saw {giver} stealing your jewelry?
                }
                {asked_plaintiff_evidence and not have_evidence?
                    [p] You mentioned that you have witness testimony against {giver}?
                }
                {have_witness?
                    agent:
                        As a matter of fact, I do.
                        {witness} saw {giver} stealing the jewelry.
                        Go ask {witness} about it, if you are curious.
                }
                {not have_witness?
                    agent:
                        Unfortunately, I do not.
                    player:
                        Sounds like your accusation against my client has no basis.
                    agent:
                        That's not true.
                        We have decisive evidence that proves {giver}'s guilt.
                }
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt.enc.scratch.info_count <= 0 then
                cxt:Pop()
                return
            end
            if not table.arraycontains(cxt.quest.param.plaintiff_questions_asked, "summary") then
                cxt:Question("OPT_SUMMARY", "DIALOG_SUMMARY", function()
                    table.insert_unique(cxt.quest.param.plaintiff_questions_asked, "summary")
                    cxt.enc.scratch.info_count = cxt.enc.scratch.info_count - 1
                    cxt.quest:DefFn("AddEvidenceList", "plaintiff_summary")
                end)
            end
            if not table.arraycontains(cxt.quest.param.plaintiff_questions_asked, "evidence") then
                cxt:Question("OPT_EVIDENCE", "DIALOG_EVIDENCE", function()
                    table.insert_unique(cxt.quest.param.plaintiff_questions_asked, "evidence")
                    cxt.enc.scratch.info_count = cxt.enc.scratch.info_count - 1
                    cxt.quest:Activate("talk_to_prosecutor")
                    if cxt.quest.param.have_evidence then
                        cxt.quest:DefFn("AddEvidenceList", "plaintiff_evidence")
                    end
                end)
            end
            if not table.arraycontains(cxt.quest.param.plaintiff_questions_asked, "witness") then
                cxt:Question("OPT_WITNESS", "DIALOG_WITNESS", function()
                    table.insert_unique(cxt.quest.param.plaintiff_questions_asked, "witness")
                    cxt.enc.scratch.info_count = cxt.enc.scratch.info_count - 1
                    if cxt.quest.param.have_witness then
                        cxt.quest:Activate("talk_to_witness")
                        cxt.quest:DefFn("AddEvidenceList", "plaintiff_witness")
                    end
                end)
            end
            StateGraphUtil.AddBackButton(cxt)
        end)

QDEF:AddConvo("talk_to_witness", "witness")
    :Loc{
        OPT_CAST_DOUBT = "Cast doubt on {agent}'s testimony",
        DIALOG_CAST_DOUBT = [[
            player:
                [p] Are you certain your memory isn't faulty?
        ]],
        DIALOG_CAST_DOUBT_SUCCESS = [[
            agent:
                [p] I suppose I can't say for certain that it's {giver}.
        ]],
        DIALOG_CAST_DOUBT_FAILURE = [[
            agent:
                [p] I know what I saw.
        ]],

        OPT_INTIMIDATE = "Intimidate {agent} to prevent {agent.himher} from testifying",
        DIALOG_INTIMIDATE = [[
            player:
                [p] Here's what's going to happen.
                You are not going to testify. If you know what's good for you.
        ]],
        DIALOG_INTIMIDATE_SUCCESS = [[
            agent:
                [p] Fine, fine! It's too much trouble anyway.
        ]],
        DIALOG_INTIMIDATE_FAILURE = [[
            agent:
                [p] No! You can't scare me!
        ]],

        OPT_BRIBE = "Bribe {agent} to prevent {agent.himher} from testifying",
        DIALOG_BRIBE = [[
            player:
                [p] How much do you get compensated for your effort of testifying?
            agent:
                Nothing, in fact.
            player:
                How about a counteroffer? A bit for your effort to... not put in any effort.
            agent:
                Now we're talking.
                I love getting paid for doing nothing.
        ]],
    }
    :Hub(function(cxt)
        if not cxt.quest.param.tried_cast_doubt_witness then
            cxt:BasicNegotiation("CAST_DOUBT")
                :OnSuccess()
                    :CompleteQuest("talk_to_witness")
                    :Fn(function(cxt)
                        cxt.quest:DefFn("AddEvidenceList", "doubtful_testimony")
                    end)
                :OnFailure()
                    :Fn(function(cxt)
                        cxt.quest.param.tried_cast_doubt_witness = true
                    end)
        end
        if not cxt.quest.param.tried_intimidate_witness then
            cxt:BasicNegotiation("INTIMIDATE", { flags = NEGOTIATION_FLAGS.INTIMIDATION })
                :OnSuccess()
                    :CompleteQuest("talk_to_witness")
                    :Fn(function(cxt)
                        cxt.quest.param.witness_unavailable = true
                        cxt.quest.param.witness_intimidated = true
                    end)
                :OnFailure()
                    :Fn(function(cxt)
                        cxt.quest.param.tried_intimidate_witness = true
                    end)
        end
        local bribe_cost = 100
        cxt:Opt("OPT_BRIBE")
            :DeliverMoney( bribe_cost )
            :Dialog("DIALOG_BRIBE")
            :CompleteQuest("talk_to_witness")
            :Fn(function(cxt)
                cxt.quest.param.witness_unavailable = true
                cxt.quest.param.witness_bribed = true
            end)
    end)
    :AttractState("STATE_ATTRACT", function(cxt) return not cxt.quest.param.talked_to_witness end)
    :Loc{
        DIALOG_INTRO = [[
            player:
                [p] You are a witness to the theft case, yes?
            agent:
                Yes.
                I'm telling you! {giver} did it!
                I saw it with my own eyes! {giver} leaving {plaintiff}'s estate at the time of the theft!
            *** {agent} saw {giver} leaving {plaintiff}'s estate at the time of the theft.
        ]],
    }
    :Fn(function(cxt)
        cxt:Dialog("DIALOG_INTRO")
        cxt.quest.param.talked_to_witness = true
    end)
