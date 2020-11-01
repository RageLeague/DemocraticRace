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
        -- this is a fallback if an opinion isn't assigned already
        local op_reason = quest:GetCastMember("worker").social_connections:GetRelationshipReason(quest:GetCastMember("foreman"))
        if not( op_reason and op_reason.id == OPINION.GOT_FIRED.id ) then
            quest:GetCastMember("worker"):OpinionEvent(OPINION.GOT_FIRED, nil, quest:GetCastMember("foreman"))
        end
    end,
    on_start = function(quest)
        quest:Activate("take_your_heart")
        quest:Activate("punish_foreman")
        quest:Activate("organize_strike")
        quest:Activate("visit_workplace")
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
    unimportant = true,
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
    events = {
        agent_retired = function(quest, agent)
            if agent:IsDead() then
                quest.param.foreman_dead = true
                quest.param.sub_optimal = true
            else
                quest.param.foreman_retired = true
            end
            quest:Complete("punish_foreman")
            -- if quest:IsActive("punish_foreman") then
                
            -- end
        end,
        aspects_changed = function( quest, agent, added, aspect )
            if added then 
                -- if is_instance( aspect, Aspect.Intimidated ) then
                --     quest.param.beat_up = true
                --     quest:Complete("punish_foreman")
                -- end
                if is_instance( aspect, Aspect.StrippedInfluence ) then
                    quest.param.stripped_influence = true
                    if agent:HasMemory("GOT_FIRED_FROM_JOB") then
                        quest.param.fired_from_job = true
                    end
                    quest:Complete("punish_foreman")
                end
            end

        end
    }
}
:AddCast{
    cast_id = "worker",
    no_validation = true,
    provider = true,
    unimportant = true,
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( "LABORER" ) )
    end,
}
:AddObjective{
    id = "visit_workplace",
    title = "Visit the workplace",
    desc = "{foreman} works at {workplace#location}. If you want to find {foreman.himher}, you should look here.",
    mark = function(quest, t, in_location)
        -- print("workplace mark evaluated")
        -- print(DemocracyUtil.IsFreeTimeActive())
        if in_location then
            table.insert(t, quest:GetCastMember("foreman"))
        end
        if DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("workplace"))
            -- print("inserted workplace")
        end
    end,
}
:AddObjective{
    id = "take_your_heart",
    title = "Change {foreman}'s heart",
    desc = "Find {foreman} and convince {foreman.himher} to change {foreman.hisher} behaviour.",
    on_complete = function(quest)
        quest.param.take_your_heart = true
        quest:Activate("tell_news")
    end,
}
:AddObjective{
    id = "punish_foreman",
    title = "Punish {foreman}",
    desc = "Find a way to punish {foreman} with concrete consequences.",
    combat_targets = {"foreman"},
    on_complete = function(quest)
        quest.param.punish_foreman = true
        quest:Activate("tell_news")
    end,
    events = {
        resolve_battle = function(quest, battle, primary_enemy, repercussions )
            if battle.result == BATTLE_RESULT.WON then
                if battle:GetEnemyTeam():GetFighterForAgent(quest:GetCastMember("foreman")) then
                    quest.param.beat_up_primary = primary_enemy == quest:GetCastMember("foreman")
                end
                quest.param.beat_up = true
            end
        end,
    },
}
:AddObjective{
    id = "organize_strike",
    title = "Organize a strike",
    desc = "Organize a strike at {foreman}'s workplace.",
    on_complete = function(quest)
        quest.param.organize_strike = true
        quest:Activate("tell_news")
    end,
}
:AddObjective{
    id = "tell_news",
    title = "Tell {worker} about the news.",
    desc = "When you have time to find {worker}, tell {worker.himher} about what you did.",
    on_activate = function(quest)
        local methods = {"take_your_heart", "punish_foreman", "organize_strike", "visit_workplace"}
        for i, id in ipairs(methods) do
            if quest:IsComplete(id) then
                -- quest.param["completed_" .. id] = true
            else
                quest:Cancel(id)
            end
        end
    end,
    mark = function(quest, t, in_location)
        if in_location or DemocracyUtil.IsFreeTimeActive() then
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
            {punish_foreman?
                {foreman_dead?
                    player:
                        {foreman}'s dead.
                        Which I <i>may or may not</> have anything to do with it.
                    agent:
                        !sign
                        I was hoping that this didn't happen.
                        People are going to ask a lot of questions, and I'm sure if I'll like them.
                    player:
                        Well, at least you don't have to worry about {foreman} anymore.
                    agent:
                        That's true, at least.
                }
                {not foreman_dead and foreman_retired?
                    player:
                        !throatcut
                        I, ah, "retired" {foreman}, if you get what I mean.
                    agent:
                        !scared
                        Oh, no. Is {foreman.heshe} dead?
                    player:
                        What? No. {foreman.HeShe} simply get discharged.
                        {foreman.HeShe}'s never going to come back to bother you anymore.
                    agent:
                        !dubious
                        And why is that different from death?
                    player:
                        You get to live with the conscience that you never kill {foreman}.
                    agent:
                        !happy
                        That makes it way better!
                        Thanks, {player}!
                    player:
                        !happy
                        You're welcome.
                }
                {not foreman_dead and beat_up?
                    player:
                        I beat {foreman.himher} up.
                    agent:
                        That seems a bit aggressive. Did you make sure {foreman.heshe} got the message?
                    player:
                        Yeah, definitely.
                    agent:
                        $scaredFearful
                        You didn't kill {foreman.himher}, right?
                    player:
                        !handwave
                        Nah.
                    agent:
                        Well, in that case, everything worked out fine.
                        Thank you for what you did for me.
                        I am truly grateful.
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
                Now that's sensitive information. I don't think I'm allowed to disclose that.
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
                Look, your ways aren't going to last long term.
            agent:
                You know, maybe you're right.
                Maybe I should be a bit better...
            player:
                Wait really? I thought that'd taken a bit more effort...
            agent:
                Hesh's salty embrace, you fell for that?
                Look, how 'bout this.
                If you Champion my ideas AND give me some money, i'll clean up my act.
            player:
                Okay, and what's the price to do so?
            agent:
                {demand_list#demand_list}. Got it?
        }
        {not first_time?
            player:
                You sure you can't do it for free?
            agent:
                No.{demand_list#demand_list}?
                Non-Negotiable...okay maybe a bit negotiable.
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

                local opt = cxt:Opt("OPT_DEMAND")
                    :LoopingFn(function(cxt)
                        if cxt:FirstLoop() then
                            if not cxt.quest.param.demands then
                                local rawcost = TheGame:GetGameState():GetCurrentBaseDifficulty() * 80 + 120
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
                if cxt.quest.param.probed_info then
                    opt:PostText("TT_INFO_PROBED")
                end

                StateGraphUtil.AddBackButton(cxt)
                    :Dialog("DIALOG_BACK")
            end)
    end)
QDEF:AddConvo("punish_foreman")
    :Priority(CONVO_PRIORITY_LOW)
    :Confront(function(cxt)
        if cxt.quest.param.beat_up and not cxt.quest:GetCastMember("foreman"):IsDead()
            and cxt.quest:GetCastMember("foreman"):GetLocation() == cxt.location then
            
            return "STATE_BEAT_UP"
        end
    end)
    :State("STATE_BEAT_UP")
        :Loc{
            DIALOG_FOLLOWUP = [[
                {beat_up_primary?
                    foreman:
                        !right
                        !injured
                    player:
                        !left
                        !angry
                        By the way, {foreman}.
                }
                {not beat_up_primary?
                    player:
                        !left
                        !angry
                        I'm not done yet.
                        !angry_accuse
                        {foreman}!
                    foreman:
                        !right
                        !injured
                        What?
                    player:
                }
                    Maybe start treating your workers better.
                    You don't want to be the enemy of the people.
                    !cruel
                    Consider this a warning.
                foreman:
                    I guess {worker} is still mad that I fired {worker.himher}, huh?
                {make_example?
                    !angry_accuse
                    That rebellious rat.
                    Perhaps firing {worker.himher} isn't enough.
                player:
                    !angry
                    I would be careful of what I'm saying if I were you, {foreman}.
                    The tables have turned, in case you haven't noticed.
                }
                {rush_quota?
                    !angry_shrug
                    What am I supposed to do? <i>Not</> giving {worker.himher} extra work?
                    The higher ups will kill me if I don't report any progress.
                player:
                    !crossed
                    The <i>Rise</> will kill you if you treat the workers badly.
                    But I'm not the Rise, so I have no intention of killing you.
                }
                foreman:
                    I get your point.
                    I'll leave you and {worker} alone.
                    But I won't forget this.
                    !exit
            ]],
        }
        :Fn(function(cxt)
            cxt.quest:Complete("punish_foreman")
            -- just in case. you did get info from the foreman.
            cxt.quest.param.probed_info = true
            cxt:Dialog("DIALOG_FOLLOWUP")
        end)
