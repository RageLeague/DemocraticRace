local QDEF = QuestDef.Define
{
    title = "A Worker's Revenge",
    desc = "Make things right for {worker} by dealing with {foreman}, who wrongfully fired {worker.himher}.",

    qtype = QTYPE.SIDE,

    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"REQUEST_JOB"},
    reward_mod = 0,
}
:AddCast{
    cast_id = "foreman",
    no_validation = true,
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( "FOREMAN" ) )
    end,
}
:AddCast{
    cast_id = "worker",
    no_validation = true,
    provider = true,
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( "LABORER" ) )
    end,
}
