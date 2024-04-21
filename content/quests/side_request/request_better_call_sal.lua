-- Outline:
-- The defendant is accused of stealing something valuable from the plaintiff.
-- Potential evidence:
--   * Connection of the accused to the plaintiff.
--     * Circumstance evidence, only affects trial difficulty.
--   * Witness saw accused leaving the estate.
--     * If innocent, either witness misremembered or witness fabricated testimony
--   * Accused left earings behind.
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

        quest.param.have_alibi = math.random() < 0.2
    end,

    on_start = function(quest)
        quest:Activate("prepare_trial")
        quest:Activate("talk_to_accused")
        quest:Activate("talk_to_plaintiff")
        quest:Activate("talk_to_prosecutor")
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
:AddObjective{
    id = "prepare_trial",
    title = "Prepare for the trial ({1#relative_time})",
    title_fn = function(quest, str)
        return loc.format(str, (quest.param.trial_time or 0) - Now())
    end,
    desc = "Make enough preparations before the trial begins.",
}
:AddObjective{
    id = "talk_to_accused",
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
