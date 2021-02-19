local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}
:AddConvo()
    :Loc{
        OPT_ALLIANCE = "Talk about alliance",
        TT_ALLIANCE = "{agent} <i>might</> be a potential ally for your campaign. Forming allies drastically improves your chance at winning the election.\n{agent} will only consider alliance if your support among {agent.hisher} faction is high enough.",
    }
    :Hub(function(cxt, who)
        if who and DemocracyUtil.GetOppositionData(who) and who:GetRelationship() == RELATIONSHIP.NEUTRAL then
            cxt:Opt("OPT_ALLIANCE")
                :PreIcon(global_images.like)
                :PostText("TT_ALLIANCE")
                :Fn(function(cxt)
                    DemocracyUtil.DoAllianceConvo(cxt, who)
                end)
        end
    end)