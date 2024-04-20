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

    on_start = function(quest)
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
    on_assign = function(quest, agent)

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
