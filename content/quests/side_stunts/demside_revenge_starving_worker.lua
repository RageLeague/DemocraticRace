local QDEF = QuestDef.Define
{
    title = "A Worker's Revenge",
    desc = "Make things right for {worker} by dealing with {foreman}, who wrongfully fired {worker.himher}.",

    qtype = QTYPE.SIDE,
}
:AddDefCastSpawn("foreman", "FOREMAN")
:AddDefCastSpawn("worker", "LABORER")
