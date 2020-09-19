local QDEF = QuestDef.Define
{
    title = "A Worker's Revenge",
    desc = "Make things right for {worker} by dealing with {foreman}, who wrongfully fired {worker.himher}.",

    qtype = QTYPE.SIDE,

    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"REQUEST_JOB"},
    reward_mod = 0,
    on_init = function(quest)
        local motivation = {"make_example", "rush_quota"}
        local id = table.arraypick(motivation)
        quest.param[id] = true
    end,
    on_start = function(quest)
        quest:Activate("take_your_heart")
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

QDEF:AddConvo("take_your_heart", "foreman")
    :Loc{
        OPT_CONFRONT = "Confront {agent} about the firing of {worker}",
        DIALOG_CONFRONT = [[
            {first_time?
                player:
                    [p] so, i heard you fired {worker}, right?
                agent:
                    what's it to you?
                player:
                    you know, just asking a few things.
            }
            {not first_time?
                player:
                    [p] so about {worker}...
                agent:
                    what do you want?
            }
        ]],
        OPT_PROBE = "Probe information",
        DIALOG_PROBE = [[
            player:
                What kind of circumstances leads you to fire {worker}?
            agent:
                What's it to you?
            player:
                You know, just asking...
        ]],
        DIALOG_PROBE_SUCCESS = [[
            agent:
                Fine, I guess I have to tell you.
            {make_example?
                [p] {worker} is too rebellious! I have to make an example out of {worker.himher} so others don't follow {worker.hisher} lead.
            }
            {rush_quota?
                [p] it's not my fault! the higher ups demands progress, so i have to make my workers work harder!
                i have no other choice!
            }
        ]],
        DIALOG_PROBE_NO_INTEL = [[
            agent:
                ...
                [p] is that all?
            player:
                well, yeah.
            agent:
                good talk.
        ]],
        DIALOG_PROBE_FAIL = [[
            agent:
                [p] hey! are you trying to get me say something incriminating?
                get out of my face!
            * welp, you failed on this front. maybe try some other ways
        ]],
        DIALOG_BACK = [[
            player:
                Never mind.
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_CONFRONT")
            :SetQuestMark(cxt.quest)
            :Dialog("DIALOG_CONFRONT")
            :RequireFreeTimeAction()
            :LoopingFn(function(cxt)
                if not cxt.quest.param.probed_info then
                    cxt:Opt("OPT_PROBE")
                        :Dialog("DIALOG_PROBE")
                        :Negotiation{
                            on_start_negotiation = function(minigame)
                                -- for i = 1, 3 do
                                minigame:GetOpponentNegotiator():CreateModifier( "secret_intel", 1 )
                                -- end
                            end,
                            on_success = function(cxt, minigame)
                                local count = minigame:GetPlayerNegotiator():GetModifierStacks( "secret_intel" )
                                if count > 0 then
                                    cxt:Dialog("DIALOG_PROBE_SUCCESS")
                                    cxt.quest.param.probed_info = true
                                else
                                    cxt:Dialog("DIALOG_PROBE_NO_INTEL")
                                end
                            end,
                            on_fail = function(cxt, minigame)
                                cxt:Dialog("DIALOG_PROBE_FAIL")
                                cxt.quest:Fail("take_your_heart")
                            end,
                        }
                end
                StateGraphUtil.AddBackButton(cxt)
                    :Dialog("DIALOG_BACK")
            end)
    end)