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
    on_complete = function(quest)
        if not (quest.param.sub_optimal or quest.param.poor_performance) then
            quest:GetProvider():OpinionEvent(OPINION.DID_LOYALTY_QUEST)
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 10)
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, 1)
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 2)
        elseif quest.param.sub_optimal then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 5)
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 8, 1)
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 2)
        elseif quest.param.poor_performance then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2)
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 1)
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 2)
        end
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
    on_complete = function(quest)
        quest:Activate("tell_news")
    end,
}
:AddObjective{
    id = "punish_foreman",
    title = "Punish {foreman}",
    desc = "Find a way to punish {foreman} with concrete consequences.",
    on_complete = function(quest)
        quest:Activate("tell_news")
    end,
}
:AddObjective{
    id = "organize_strike",
    title = "Organize a strike",
    desc = "Organize a strike at {foreman}'s workplace.",
    on_complete = function(quest)
        quest:Activate("tell_news")
    end,
}
:AddObjective{
    id = "destroy_reputation",
    title = "Destroy {foreman}'s reputation.",
    desc = "Find a way to publicly destroy {foreman}'s reputation.",
    on_complete = function(quest)
        quest:Activate("tell_news")
    end,
}
:AddObjective{
    id = "tell_news",
    title = "Tell {worker} about the news.",
    desc = "When you have time to find {worker}, tell {worker.himher} about what you did.",
    on_activate = function(quest)
        local methods = {"take_your_heart", "punish_foreman", "organize_strike", "destroy_reputation"}
        for i, id in ipairs(methods) do
            if quest:IsComplete(id) then
                quest.param["completed_" .. id] = true
            else
                quest:Cancel(id)
            end
        end
    end,
    mark = function(quest, t, in_location)
        if DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("worker"))
        end
    end,
}
QDEF:AddConvo("tell_news", "worker")
    :Loc{
        OPT_TELL_NEWS = "Tell {agent} about what you did",
        DIALOG_TELL_NEWS = [[
            player:
                Good news! I brought you justice!
            agent:
                Really? What did you do?
            {take_your_heart?
                player:
                    I convinced {foreman} to change {foreman.hisher} ways.
                agent:
                    But, how?
                {not (probed_info and rush_quota)?
                    player:
                        I just provided {foreman.himher} what {foreman.heshe} wants, and {foreman.heshe} promised to change {foreman.hisher} treatment of workers.
                    agent:
                        !angry
                        You're <i>rewarding</> that despot for what {foreman.heshe}'s done?
                        ...
                        !sigh
                        Still, you made {foreman.himher} change, and I'm grateful for that.
                }
                {probed_info and rush_quota?
                    player:
                        Turns out {foreman.heshe}'s just trying to meet the quota because the higher ups demands it.
                        I compensated {forman.himher} so that {foreman.heshe} doesn't need to push all the stress onto the workers.
                    agent:
                        I see that {foreman} is merely another victim of this corrupt system.
                        Thanks for helping us out, {player}. I'm truly grateful.
                }
            }
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_TELL_NEWS")
            :SetQuestMark(cxt.quest)
            :Dialog("DIALOG_TELL_NEWS")
            :CompleteQuest()
    end)
QDEF:AddConvo("take_your_heart", "foreman")
    :Loc{
        OPT_CONFRONT = "Confront {agent} about the firing of {worker}",
        DIALOG_CONFRONT = [[
            {first_time?
                agent:
                    what's it to you?
                    Oh! Your one of those up n' coming politicians I heard of?
                    Come to see the system at work?
                player:
                    Why yes. I'm here to ask you about one of your business decisions.
                agent:
                    Ask away. I have nothing to hide.
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
                Now that's sensitive information. By corporate law, i'm not allowed to disclose that.
        ]],
        DIALOG_PROBE_SUCCESS = [[
            agent:
                Fine, I guess I have to tell you.
            {make_example?
                I got a lead on that Worker. Turns out {worker.heshe} passes out some of those pamphlets as a side gig.
                They we're probably churning up a revolution at this very worksite! I had to nip the problem in the bud, otherwise the mob'd have my head!
            }
            {rush_quota?
                Look, don't tell this to no one, but we we're actually one of the laxer worksites this side of the sea.
                The Higher Ups looked at my record and didn't like it too much. Told me to step it up, lest I want to work as a janitor in Palketti.
                So I raised the stakes, and {worker} got upset at that. Started shirking duties for days, instead hanging out with {worker.hisher} buddies.
                I had to show a little tough love. I hope they'll realize how easy this job was and come back after long enough.
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
        OPT_DEMAND = "Ask {agent} to change {agent.hisher} ways",
        TT_INFO_PROBED = "<#BONUS>Info probed. -25% demand.</>",
        DIALOG_DEMAND = [[
        {first_time?
            player:
                [p] can you change your ways?
            agent:
                why should i do it for free?
                !thought
                hmm... i'll tell you what, if you can {demand_list#demand_list}, then i'll change my ways.
            player:
                hmm... i'll think about that.
        }
        {not first_time?
            player:
                [p] so, about that deal...
            agent:
                didn't i tell you to {demand_list#demand_list}?
            player:
                right...
        }
        ]],
        DIALOG_MET_DEMAND = [[
            agent:
                [p] Wow, you actually delivered?
                Okay, now I'll agree to treat the workers better.
            {not (probed_info and rush_quota)?
                You give me what I want, I'll give you what you want.
            }
            {probed_info and rush_quota?
                No need to push my workers too hard now that your payment relieve some of my financial stress.
            }
            player:
                And I assume you're actually going to deliver?
            agent:
                Sure.
            * Now you can tell {worker} about the great news!
        ]],
        
        DIALOG_BACK = [[
            player:
                Never mind.
        ]],
    }
    :Hub(function(cxt)
        -- local test_table = DemocracyUtil.GenerateDemands(100, nil, 1)
        -- TheGame:GetDebug():CreatePanel(DebugTable(test_table))
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

                cxt:Opt("OPT_DEMAND")
                    :LoopingFn(function(cxt)
                        if cxt:FirstLoop() then
                            if not cxt.quest.param.demands then
                                local rawcost = cxt.quest:GetRank() * 80 + 120
                                if cxt.quest.param.probed_info then
                                    rawcost = math.round(rawcost * 0.75)
                                end
                                local cost, reasons = CalculatePayment(cxt.quest:GetCastMember("foreman"), rawcost)
                                cxt.quest.param.demands = DemocracyUtil.GenerateDemands(cost, cxt.quest:GetCastMember("foreman"))
                                cxt.quest.param.demand_list = DemocracyUtil.ParseDemandList(cxt.quest.param.demands)
                            end
                            cxt:Dialog("DIALOG_DEMAND")
                        end

                        -- cxt:Opt("OPT_NEGOTIATE_TERMS")
                        local payed_all = DemocracyUtil.AddDemandConvo(cxt, cxt.quest.param.demand_list, cxt.quest.param.demands)
                        if payed_all then
                            cxt:Dialog("DIALOG_MET_DEMAND")
                            cxt.quest:Complete("take_your_heart")
                            StateGraphUtil.AddEndOption(cxt)
                        else
                            StateGraphUtil.AddBackButton(cxt)
                                :Dialog("DIALOG_BACK")
                        end
                    end)

                StateGraphUtil.AddBackButton(cxt)
                    :Dialog("DIALOG_BACK")
            end)
    end)
