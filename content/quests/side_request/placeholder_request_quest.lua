local QDEF = QuestDef.Define
{
    title = "Placeholder Request Quest",
    desc = "Win a negotiation against the giver to complete the quest.",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/revenge_starving_worker.png"),

    qtype = QTYPE.SIDE,

    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"REQUEST_JOB", "manual_spawn"},
    reward_mod = 0,
    can_flush = false,
    on_start = function(quest)
        quest:Activate("talk")
    end,

    on_complete = function(quest)
        if not (quest.param.sub_optimal or quest.param.poor_performance) then
            quest:GetProvider():OpinionEvent(OPINION.DID_LOYALTY_QUEST)
            -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 10, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, 1, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 2, "COMPLETED_QUEST")
        elseif quest.param.sub_optimal then
            -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 5, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 8, 1, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 2, "COMPLETED_QUEST")
        elseif quest.param.poor_performance then
            -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2, "POOR_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 1, "POOR_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 2, "POOR_QUEST")
        end
    end,
}

:AddCast{
    cast_id = "giver",
    no_validation = true,
    provider = true,
    unimportant = true,
    -- cast_fn = function(quest, t)
    --     table.insert( t, quest:CreateSkinnedAgent( "LABORER" ) )
    -- end,
}
:AddObjective{
    id = "talk",
    title = "Talk to {giver}.",
    desc = "Exactly like how it sounds.",
    mark = {"giver"},
}
QDEF:AddConvo("talk", "giver")
    :Loc{
        OPT_TALK = "Chat",
        DIALOG_TALK = [[
            agent:
                I'm lonely.
                Cheer me up.
        ]],
        DIALOG_TALK_SUCCESS = [[
            agent:
                Thanks.
                I'm cheered up now.
        ]],
        DIALOG_TALK_FAILURE = [[
            agent:
                Oh no, it didn't work.
        ]],
    }
    :Hub(function(cxt)
        cxt:BasicNegotiation("TALK")
            -- :SetQuestMark(cxt.quest)
            :OnSuccess()
                :CompleteQuest()
                :DoneConvo()
    end)