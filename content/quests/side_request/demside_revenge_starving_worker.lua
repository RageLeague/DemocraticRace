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
:AddDefCastSpawn("foreman", "FOREMAN")
:AddDefCastSpawn("worker", "LABORER")
