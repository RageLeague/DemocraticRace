local QDEF = QuestDef.Define
{
    title = "A Worker's Revenge",
    desc = "Make things right for {worker} by dealing with {foreman}, who wrongfully fired {worker.himher}.",

    qtype = QTYPE.SIDE,

    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"REQUEST_JOB"},
    reward_mod = 0,

    on_start = function(quest)
        quest:Activate("go_to_junction")
    end,
}
:AddLocationCast{
    when = QWHEN.MANUAL,
    cast_id = "workplace",
    cast_fn = function(quest, t)
        if quest:GetCastMember("foreman"):GetBrain():GetWorkPosition() then
            table.insert( t, quest:GetCastMember("foreman"):GetBrain():GetWorkPosition():GetLocation())
        end
    end,
    -- optional = true,
    on_assign = function(quest,location)
        local old_postition = quest:GetCastMember("foreman"):GetBrain():GetWorkPosition()
        if location:GetWorkPosition("foreman") and location:GetWorkPosition("foreman") ~= old_postition then
            AgentUtil.TakeJob(quest:GetCastMember("foreman"), location, "foreman")
        end
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        local loc_ids = copykeys(quest:GetQuestDef().location_defs)
        local chosen_id = table.arraypick(loc_ids)
        local loc_def = quest:GetQuestDef():GetLocationDef(chosen_id)
        table.insert(t, TheGame:GetGameState():AddLocation(Location(loc_def.id)))
    end,
}
:AddLocationDefs{
    GENERIC_DIG_SITE =
    {
        name = "Dig Site",
        desc = "A dangerous worksite that mines for various minerals.",
        show_agents = true,
        -- indoors = true,
        -- no_exit = true,
        plax = "Ext_Bog_Illegal_Worksite_1",
        tags = {"industry","forest"},
        work = CreateProductionWorkplace( 3, DAY_PHASE.DAY, "FOREMAN", "HEAVY_LABORER", "Foreman", "Digger"),
    },
    GENERIC_SPARK_SITE =
    {
        name = "Spark Extraction Site",
        desc = "A site where the Spark Barons hire workers to extract spark.",
        show_agents = true,
        -- indoors = true,
        -- no_exit = true,
        plax = "EXT_SB_Bog_Worksite_1",
        tags = {"industry","forest"},
        work = CreateProductionWorkplace( 3, DAY_PHASE.DAY, "SPARK_BARON_TASKMASTER", "HEAVY_LABORER", "Spark Overseer", "Spark Miner"),
    },
}
:AddCast{
    cast_id = "foreman",
    no_validation = true,
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( "FOREMAN" ) )
    end,
    on_assign = function(quest, agent)
        -- quest.param.has_primary_advisor = true
        -- if quest:GetQuestDef():GetCast("home") then
        --     quest:AssignCastMember("home")
        -- end
        quest:AssignCastMember("workplace")
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
:AddObjective{
    id = "take_your_heart",
    title = "Change {foreman}'s heart",
    desc = "Find {foreman} and convince {foreman.himher} to change {foreman.hisher} behaviour.",
}
:AddObjective{
    id = "punish_foreman",
    title = "Punish {foreman}",
    desc = "Find a way to punish {foreman} with concrete consequences.",
}
:AddObjective{
    id = "organize_strike",
    title = "Organize a strike",
    desc = "Organize a strike at {foreman}'s workplace.",
}
:AddObjective{
    id = "destroy_reputation",
    title = "Destroy {foreman}'s reputation.",
    desc = "Find a way to publicly destroy {foreman}'s reputation.",
}