local QDEF = QuestDef.Define
{
    title = "Parasite Killer",
    desc = "Bring {escort} to someone that can get rid of {escort.hisher} parasite.",

    qtype = QTYPE.SCENARIO,
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
    on_complete = function(quest)
    end,
}
:AddCast{
    cast_id = "escort",
    no_validation = true,
    events = {
        agent_retired = function(quest, agent)
            quest:Fail()
        end,
        dismissed = function( quest )
            quest:Fail()
            if not quest:GetCastMember("escort"):IsRetired() then
                quest:GetCastMember("escort"):Kill()
            end
        end,
    },
}
