local QDEF = QuestDef.Define
{
    qtype = QTYPE.SCENARIO,

    on_start = function(quest)
        quest:Activate("wait")
    end,
}
:AddCast{
    cast_id = "hunter",
    events = {
        agent_retired = function(quest, agent)
            quest:Fail()
        end,
    },
}
:AddCast{
    cast_id = "target",
    -- no_validation = true,
    unimportant = true,
    events = {
        agent_retired = function(quest, agent)
            quest:Complete()
        end,
    },
}
:AddDormancyState("wait", "report", false, 3, 10)
:AddObjective{
    id = "report",
    hide_in_overlay = true,
    on_activate = function(quest)
        quest.param.negotiation_grafts = GenerateGrafts(GRAFT_TYPE.NEGOTIATION)
        quest.param.combat_grafts = GenerateGrafts(GRAFT_TYPE.COMBAT)
        quest:GetCastMember("plocka"):MoveToLocation(quest:GetCastMember("home"))
        quest:GetCastMember("plocka"):SetLocationRole(CHARACTER_ROLES.VENDOR)
    end,
}
