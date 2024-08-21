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
        -- quest:Activate("punish_target")
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
