local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}
:AddCast{
    cast_id = "supporter",
    condition = function(agent, quest)
        return agent:GetRelationship() >= RELATIONSHIP.NEUTRAL and agent:GetRelationship() < RELATIONSHIP.LOVED
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent()
    end,
}
