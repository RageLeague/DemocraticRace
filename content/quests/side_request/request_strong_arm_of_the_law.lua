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
        quest:Activate("acquire_contraband")
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
            if agent:IsDead() then
                quest.param.target_dead = true
            else
                quest.param.target_retired = true
            end
            quest:Activate("report_result")
        end,
        aspects_changed = function( quest, agent, added, aspect )

        end
    }
}
:AddObjective{
    id = "find_evidence",
    title = "Find evidence",
    desc = "Find any evidence of {target}'s wrongdoing."
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
}
:AddObjective{
    id = "report_result",
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
