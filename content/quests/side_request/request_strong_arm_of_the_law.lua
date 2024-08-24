local QDEF = QuestDef.Define
{
    title = "Strong Arm of the Law",
    desc = "Investigate {target} for wrongdoing and/or eliminate {target.himher}.",
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

    on_start = function(quest)
        quest:Activate("find_evidence")
        -- quest:Activate("acquire_contraband")
        quest:Activate("punish_target")
    end,

    on_complete = function(quest)
        local giver = quest:GetCastMember("giver")
        if not (quest.param.sub_optimal or quest.param.poor_performance) then
            giver:OpinionEvent(OPINION.DID_LOYALTY_QUEST)
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 4, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 5, "ADMIRALTY", "COMPLETED_QUEST_REQUEST")
        elseif quest.param.sub_optimal then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 3, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 8, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 4, "ADMIRALTY", "COMPLETED_QUEST_REQUEST")
        elseif quest.param.poor_performance then
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 3, "ADMIRALTY", "COMPLETED_QUEST_REQUEST")
        end
    end,
}
:AddCast{
    cast_id = "giver",
    no_validation = true,
    provider = true,
    unimportant = true,
    condition = function(agent, quest)
        return not agent:HasTag("curated_request_quest") and agent:GetFactionID() == "ADMIRALTY"
    end,
}
:AddCast{
    -- when = QWHEN.MANUAL,
    cast_id = "target",
    no_validation = true,
    unimportant = true,
    condition = function(agent, quest)
        if not agent:IsSentient() then
            return false, "Don't be mean to the dog :( (or oshnu, mech, whatever)"
        end
        if not agent:GetFaction():IsLawful() and agent:GetFactionID() ~= "RISE" then
            return false, "Wrong faction"
        end
        if DemocracyUtil.GetWealth(agent) <= 2 then
            return false, "Not enough influence"
        end
        return not AgentUtil.HasPlotArmour(agent)
    end,
    on_assign = function(quest, agent)
    end,
    events = {
        agent_retired = function(quest, agent)
            if quest:IsActive("punish_target") then
                if agent:IsDead() then
                    quest.param.target_dead = true
                else
                    quest.param.target_retired = true
                end
                quest:Activate("report_success")
            end
        end,
        aspects_changed = function( quest, agent, added, aspect )

        end
    }
}
:AddObjective{
    id = "find_evidence",
    title = "Find evidence",
    desc = "Find any evidence of {target}'s wrongdoing.",
    mark = function(quest, t, in_location)
        if in_location or DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("target"))
        end
    end,
}
:AddObjective{
    id = "acquire_contraband",
    title = "(Optional) Acquire contraband",
    desc = "If you can't find real evidence, you can always pin a crime on {target} by planting contraband on {target.himher}.",
}
:AddObjective{
    id = "punish_target",
    title = "Eliminate target",
    desc = "Alternatively, you can remove {target} from the picture without going through due process.",
    combat_targets = {"target"},
    mark = function(quest, t, in_location)
        if in_location or DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("target"))
        end
    end,
}
:AddObjective{
    id = "report_success",
    title = "Report to {giver}",
    desc = "The situation with {target} has been resolved. Report your results.",
    on_activate = function(quest)
        local sides = {"find_evidence", "acquire_contraband", "punish_target"}
        for i, id in ipairs(sides) do
            if quest:IsActive(id) then
                quest:Complete(id)
            end
        end
    end,
}

QDEF:AddIntro(
    --attract spiel
    [[
        agent:
            [p] {target} has been a thorn on our side for quite a while now.
            We wish to get {target.himher} out of the picture, but we can't do anything about {target.himher} without a just cause.
            Perhaps... you can be of assistance. Help us find anything that can be used against {target.himher}.
            Or, if something unfortunate were to happen to {target}, well... The Admiralty can't be faulted, now can we?
    ]],

    --on accept
    [[
        player:
            [p] That can be done.
        agent:
            Excellent!
    ]])

QDEF:AddConvo("find_evidence", "giver")
    :Loc{
        OPT_ASK_CONTRABAND = "Ask about evidence",
        DIALOG_ASK_CONTRABAND = [[
            {not asked_contraband?
                player:
                    [p] What are some potential evidence of wrong doing that I can find?
                agent:
                    The easiest one is probably contraband.
                    Generally speaking, this include illicit substances like stimulants, or things that a person should generally not have.
                    Here is a list.
            }
            {asked_contraband?
                player:
                    [p] Remind me of what to look for again?
                agent:
                    Here is a list of contraband.
            }
        ]],
        DIALOG_ASK_CONTRABAND_PST = [[
            {not asked_contraband?
                agent:
                    [p] Certain dangerous weapons are also considered contraband, but you can't easily slip them in.
                player:
                    Slip them in? What do you mean-
                agent:
                    !give
                    This is what I meant.
            }
            {asked_contraband?
                agent:
                    [p] Hopefully you can find something like that on {target}.
                    Or "find" it on {target.himher}. Whatever works for you.
            }
        ]],
        DIALOG_ASK_CONTRABAND_PST_GIFT = [[
            player:
                Oh. <i>Oh.</>
                I see what you want me to do.
        ]],
        VIEW_TITLE = "Contraband list",
        VIEW_DESC = "This is a list of contraband according to the Admiralty.",
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_ASK_CONTRABAND")
            :Dialog("DIALOG_ASK_CONTRABAND")
            :Fn(function(cxt)
                local cards = {}
                for i, id in ipairs(DemocracyUtil.CONTRABAND_CARDS) do
                    local card = Negotiation.Card(id)
                    card.features = card.features or {}
                    card.features.DEM_CONTRABAND = 1
                    table.insert(cards, card)
                end
                cxt:Wait()
                DemocracyUtil.InsertSelectCardScreen(
                    cards,
                    cxt:GetLocString("VIEW_TITLE"),
                    cxt:GetLocString("VIEW_DESC"),
                    Widget.NegotiationCard,
                    function(card)
                        cxt.enc:ResumeEncounter()
                    end
                )
                cxt.enc:YieldEncounter()
                cxt:Dialog("DIALOG_ASK_CONTRABAND_PST")
                if not cxt.quest.param.asked_contraband then
                    cxt.quest.param.asked_contraband = true
                    cxt:GainCards{"gift_packaging"}
                    cxt:Dialog("DIALOG_ASK_CONTRABAND_PST_GIFT")
                    if cxt.quest:IsInactive("acquire_contraband") then
                        cxt.quest:Activate("acquire_contraband")
                    end
                end
            end)
    end)

QDEF:AddConvo("find_evidence", "target")
    :Loc{
        OPT_PROBE_EVIDENCE = "Probe for evidence",
        DIALOG_PROBE_EVIDENCE = [[
            {not met?
                player:
                    [p] So, random stranger, how are you doing on this fine {day?day|night}?
            }
            {met?
                player:
                    [p] So, {target}, how are you doing on this fine {day?day|night}?
            }
        ]],
        DIALOG_PROBE_EVIDENCE_SUCCESS = [[
            {planted_evidence?
                * [p] You planted evidence of {target}'s wrongdoing.
            }
            {not planted_evidence?
                * [p] You found evidence of {target}'s wrongdoing.
            }
        ]],
        DIALOG_PROBE_EVIDENCE_NO_RESULT = [[
            * [p] You tried to get evidence, but to no avail.
        ]],
        DIALOG_PROBE_EVIDENCE_FAILURE = [[
            * [p] You fail to discover anything definitive.
        ]],
        DIALOG_PROBE_EVIDENCE_DISCOVERED = [[
            agent:
                [p] Hey! You ain't getting anything out of me!
        ]],
    }
    :Hub(function(cxt)
        if not cxt.quest.param.probe_discovered then
            cxt:Opt("OPT_PROBE_EVIDENCE")
                :Dialog("DIALOG_PROBE_EVIDENCE")
                :Negotiation{
                    on_start_negotiation = function(minigame)
                        minigame:GetOpponentNegotiator():CreateModifier("DEM_PROBE_EVIDENCE")
                        minigame:GetPlayerNegotiator():CreateModifier("DEM_CONTRABAND_TRACKER")
                    end,
                    on_success = function(cxt, minigame)
                        local count = minigame:GetPlayerNegotiator():GetModifierStacks( "secret_intel" )
                        cxt.enc.scratch.planted_evidence = minigame.planted_evidence
                        if count > 0 then
                            cxt:Dialog("DIALOG_PROBE_EVIDENCE_SUCCESS")
                            cxt.quest.param.found_evidence = true
                            cxt.quest:Activate("report_success")
                        else
                            cxt:Dialog("DIALOG_PROBE_EVIDENCE_NO_RESULT")
                        end
                    end,
                    on_fail = function(cxt, minigame)
                        if minigame.secret_intel_destroyed then
                            cxt:Dialog("DIALOG_PROBE_EVIDENCE_DISCOVERED")
                            cxt.quest.param.probe_discovered = true
                        else
                            cxt:Dialog("DIALOG_PROBE_EVIDENCE_FAILURE")
                        end
                    end,
                }
        end
    end)

QDEF:AddConvo("report_success", "giver")
    :Loc{
        OPT_TELL_NEWS = "Tell {agent} about what you did",
        DIALOG_TELL_NEWS = [[
            {target_dead?
                player:
                    [p] {target} is dead.
                agent:
                    Such a shame. {target} had a bright future in front of {target.himher}.
                    Though, that is something we have no hands in.
                    I'm not going to ask any more questions. I'm just glad that it happened.
            }
            {target_retired?
                player:
                    [p] {target} is out of the picture.
                agent:
                    Excellent work.
            }
            {not (target_dead or target_retired) and found_evidence?
                player:
                    [p] I have proof of {target}'s wrongdoing.
                agent:
                    Excellent. That's something that we can work off of.
            }
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_TELL_NEWS")
            :SetQuestMark(cxt.quest)
            :Dialog("DIALOG_TELL_NEWS")
            :CompleteQuest()
    end)
