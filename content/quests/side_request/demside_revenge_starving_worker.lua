local QDEF = QuestDef.Define
{
    title = "A Worker's Revenge",
    desc = "Make things right for {worker} by dealing with {foreman}, who wrongfully fired {worker.himher}.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/revenge_starving_worker.png"),

    qtype = QTYPE.SIDE,

    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"REQUEST_JOB"},
    reward_mod = 0,
    can_flush = false,

    events = {
        base_difficulty_change = function(quest, new_diff, old_diff)
            quest:SetRank(new_diff)
        end,
    },

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
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 10, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, 1, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 2, "COMPLETED_QUEST")
        elseif quest.param.sub_optimal then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 5, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 8, 1, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 2, "COMPLETED_QUEST")
        elseif quest.param.poor_performance then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2, "POOR_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 1, "POOR_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 2, "POOR_QUEST")
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
    condition = function(agent, quest)
        return not AgentUtil.HasPlotArmour(agent) and agent:GetBrain():GetWorkPosition() == nil and ((agent:GetFactionID() == "FEUD_CITIZEN" and agent:GetRenown() <= 2)
            or (agent:GetFactionID() == "RISE" and agent:GetRenown() <= 3))
    end,
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
-- adding this as an objective means that the strike will cancel if the quest is completed, which makes little sense.
-- but adding another quest would be too much work.
:AddObjective{
    id = "await_strike",
    title = "Await the strike",
    desc = "The strike happens {1#relative_time}. {2#agent_list} will be there. Be prepared.",
    desc_fn = function(quest, str)
        return loc.format(str, (quest.param.strike_time or 0) - Now(), quest.param.strike_people or {})
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
:AddOpinionEvents{

    helped_get_better_rights = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Helped them get better rights",
    },
}
-- We can use this on request quests, because there's no reject dialogs.
QDEF:AddIntro(
    --attract spiel
    [[
        player:
            You don't look so good.
        agent:
            You don't say.
            I got fired by {foreman}.
            Something about "expressing dissent opinions".
            !angry_shrug
            Can you believe it?
        player:
            That doesn't sound good.
        agent:
            It isn't.
            Can you do something about {foreman}?
            Make sure {foreman} stop doing what {foreman.heshe}'s doing to other workers.
    ]],

    --on accept
    [[
        player:
            I don't like it when foremans abuse their power and oppress the working class.
            I'll see what I can do.
        agent:
            Thank you.
            I used to work at {workplace#location}. You can find {foreman} there during work time.
            Just... Try not to kill {foreman}.
            If you do, then people will start suspecting me for murder, as I have a motive.
            And that wouldn't be good for your campaign, I presume.
    ]])
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
                        I compensated {foreman.himher} so that {foreman.heshe} doesn't need to push all the stress onto the workers.
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
            {organize_strike?
            player:
                I organized a strike.
                With so many people striking, {foreman} has no choice but to accept our demands.
            agent:
                Of course!
                Why did I never think of that?
            player:
                I don't know, actually.
                Probably because as a politician, I am more influential.
            agent:
                Anyway, that's great!
                Thanks for your help, {player}. I'm truly grateful.
            }
            {DEMEVENT_STARVING_WORKER_gave_nothing?
            agent:
                And I am sorry for calling you a politician with empty promises the other day.
                It is clear that you are unlike the others. You truly care about the people.
            player:
                Don't worry about it. This is what I do.
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
                    So about {worker}...
                agent:
                    What do you want?
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
                I got a lead on that worker. Turns out {worker.heshe} passes out some of those pamphlets as a side gig.
                They we're probably churning up a revolution at this very worksite! I had to nip the problem in the bud, otherwise the mob'd have my head!
            }
            {rush_quota?
                Look, don't tell this to no one, but we we're actually one of the laxer worksites this side of the sea.
                The higher ups looked at my record and didn't like it too much. Told me to step it up, lest I want to work as a janitor in Palketti.
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
                If you champion my ideas AND give me some money, I'll clean up my act.
            player:
                Okay, and what's the price to do so?
            agent:
                You need {demand_list#demand_list}. Got it?
        }
        {not first_time?
            player:
                You sure you can't do it for free?
            agent:
                No. {demand_list#demand_list}?
                Non-negotiable... until you negotiate.
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
                            cxt:GetAgent():OpinionEvent(OPINION.APPROVE)
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
QDEF:AddConvo("organize_strike")
    :Loc{
        OPT_STRIKE = "Ask {agent} to strike for {worker}",
        MOD_WORKING = "Don't want to lose their job.",
        DIALOG_STRIKE = [[
            player:
                {foreman} treats {foreman.hisher} workers badly.
                Wanna strike?
            agent:
                Why should I care?
        ]],
        DIALOG_STRIKE_SUCCESS = [[
            player:
                Don't you care about your rights?
            agent:
                I do, actually.
                So, when are we striking?
            player:
            {not strike_time?
                !forgetful
                Uh...
                !bashful
                Haven't decided yet.
                Let me think...
            }
        ]],
        DIALOG_STRIKE_FAILURE = [[
            player:
                It's the right thing to do.
            agent:
                It's the wrong thing to do if I lose my job and can't feed my family.
                Sorry, {player}. Not everyone cares about your self-righteousness.
        ]],
        OPT_SET_TIME = "Schedule the strike {1#relative_time}",
        DIALOG_SET_TIME = [[
            player:
                The strike happens {1#relative_time}.
            agent:
                Sounds good.
        ]],
    }
    :Hub(function(cxt, who)
        -- if who then
        --     print("Talking to:", who)
        --     print("Renown:", who:GetRenown())
        --     print("Is Striking:", (cxt.quest.param.strike_people and table.arraycontains(cxt.quest.param.strike_people, who)))
        --     print("Faction ID:", who:GetFactionID(), (who:GetFactionID() == "FEUD_CITIZEN" or who:GetFactionID() == "RISE"))
        --     print("Is cast:", who == cxt:GetCastMember("worker"))
        -- end
        -- print(who and who:GetRenown() <= 1 and not (cxt.quest.param.strike_people and table.arraycontains(cxt.quest.param.strike_people, who)))
        -- print(who and who:GetRenown() <= 1 and not (cxt.quest.param.strike_people and table.arraycontains(cxt.quest.param.strike_people, who))
        -- and (who:GetFactionID() == "FEUD_CITIZEN" or who:GetFactionID() == "RISE"))
        if who and not AgentUtil.HasPlotArmour(who) and not (cxt.quest.param.strike_people and table.arraycontains(cxt.quest.param.strike_people, who))
            and ((who:GetFactionID() == "FEUD_CITIZEN" and who:GetRenown() <= 1) or who:GetFactionID() == "RISE") and
            who ~= cxt:GetCastMember("worker") and
            who:GetBrain():GetWorkPosition() then
                -- print("Satisfy all conditions")
            local helpers = {}
            for i, striker in ipairs(cxt.quest.param.strike_people or {}) do
                if cxt.location == striker:GetLocation() then
                    table.insert(helpers, striker)
                end
            end
            local sit_mod = {}
            if who:GetBrain():IsOnDuty() then
                table.insert(sit_mod, {value = 5 * (cxt.quest:GetRank() + 2), text = cxt:GetLocString("MOD_WORKING")})
            end
            cxt:BasicNegotiation("STRIKE", {
                helpers = helpers,
                hinders = {cxt.location == cxt:GetCastMember("foreman"):GetLocation() and cxt:GetCastMember("foreman")},
                situation_modifiers = sit_mod,
            }):OnSuccess()
                :Fn(function(cxt)
                    local function pst(cxt)
                        local delta = cxt.quest.param.strike_time - Now()
                        cxt:Dialog("DIALOG_SET_TIME", delta)
                        if not cxt.quest.param.strike_people then
                            cxt.quest.param.strike_people = {}
                        end
                        table.insert(cxt.quest.param.strike_people, who)
                        StateGraphUtil.AddEndOption(cxt)
                    end
                    if cxt.quest.param.strike_time then
                        pst(cxt)
                    else
                        -- local phase = TheGame:GetGameState() and TheGame:GetGameState():GetDayPhase() or DAY_PHASE.NIGHT
                        local start_time = 2 * math.floor(Now()/2) + 2
                        local end_time = TheGame:GetGameState():GetMainQuest():GetQuestDef().max_day
                        if end_time then
                            end_time = math.min(end_time * 2 - 1, start_time + 6)
                        else
                            -- just in case in endless, we still have something.
                            end_time = start_time + 6
                        end

                        for t = start_time, end_time, 2 do
                            cxt:Opt("OPT_SET_TIME", t - Now())
                                :Fn(function(cxt)
                                    cxt.quest.param.strike_time = t
                                    cxt.quest:Activate("await_strike")
                                end)
                                :Fn(pst)
                        end
                    end
                end)
        end
    end)
QDEF:AddConvo("await_strike")
    :TravelConfront("STATE_STRIKE", function(cxt)
        return TheGame:GetGameState():CanSpawnTravelEvent() and Now() >= (cxt.quest.param.strike_time or 0)
    end)
        :Loc{
            DIALOG_NO_STRIKER = [[
                * It is supposed to be the time of the strike.
                * But no one's here.
                * Clearly that was a failure.
            ]],
            DIALOG_ONE_STRIKER = [[
                * [p] You met {agent}, who's supposed to be one of the people that is striking.
                player:
                    !left
                agent:
                    !right
                    !angry
                    I'm so mad!
                    You said there's going to be a strike, but I didn't realize I'm the only person.
                    Naturally, I got fired.
                player:
                    !placate
                    I can explain-
                agent:
                    Don't care.
                    I'm now angry.
            ]],
            DIALOG_LOW_STRIKERS = [[
                * [p] You arrived at the place where people are supposed to strike.
                * Instead of a protest, you see a few angry workers.
                player:
                    !left
                agent:
                    !right
                    !angry
                    I'm so mad!
                    You said there's going to be a strike, but clearly there's not nearly enough people for that to work.
                    Naturally, we got fired.
                player:
                    !placate
                    I can explain-
                agent:
                    Don't care.
                    I'm now angry.
            ]],
            DIALOG_PROTEST = [[
                * You arrive at the location of the strike.
                foreman:
                    !right
            ]],
            DIALOG_PROTEST_SUCCESS = [[
                foreman:
                    !placate
                    Okay, you made your point.
                    I'll comply with what you said.
                    Can you please go back to work now?
                agent:
                    !left
                    Are you actually complying?
                foreman:
                    Well, yes.
                    Clearly I shouldn't mess with the working class.
                agent:
                    That's right.
                foreman:
                    !exit
                * {foreman} leaves.
            ]],
            DIALOG_PROTEST_SUCCESS_PST = [[
                player:
                    !left
                agent:
                    !right
                    Thanks for the help.
                    We couldn't have done it without you.
            ]],
            DIALOG_BUST = [[
                foreman:
                    Alright, that's enough.
                    Go back to work.
                    Or else.
                * Oh no! The protest is in trouble!
            ]],
        }
        :Quips{
            {
                tags = "protest_chant",
                "Better working conditions!",
                "More worker rights!",
                "End worker exploitations!",
            },
        }
        :Fn(function(cxt)
            cxt.quest:Complete("await_strike")
            if not cxt.quest.param.strike_people then
                cxt.quest.param.strike_people = {}
            end
            local available_people = {}
            local strike_score = 0
            for i, agent in ipairs(cxt.quest.param.strike_people) do
                if not agent:IsRetired() then
                    -- check if not retired because lots can happen in between.
                    table.insert(available_people, agent)
                    local agent_workplace = agent:GetBrain():GetWorkplace()
                    local foreman_workplace = cxt:GetCastMember("foreman"):GetBrain() and cxt:GetCastMember("foreman"):GetBrain():GetWorkplace()
                    if agent_workplace and agent_workplace == foreman_workplace then
                        strike_score = strike_score + 2
                    else
                        strike_score = strike_score + 1
                    end
                end
            end
            if strike_score == 0 then
                cxt:Dialog("DIALOG_NO_STRIKER")
                cxt.quest:Fail("organize_strike")
                StateGraphUtil.AddLeaveLocation(cxt)
            else
                local function fireall()
                    for i,agent in ipairs(available_people) do
                        if agent:GetBrain():GetWorkPosition() then
                            agent:GetBrain():GetWorkPosition():Fire()
                        end
                        agent:OpinionEvent(OPINION.GOT_FIRED)
                        local fire_stacks = math.random(0, 4)
                        if fire_stacks > 0 then
                            agent:GainAspect("stripped_influence", fire_stacks)
                        end
                    end
                end
                local function successfn()
                    cxt:Dialog("DIALOG_PROTEST_SUCCESS_PST")
                    for i, agent in ipairs(available_people) do
                        agent:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("helped_get_better_rights"))
                    end
                    cxt.quest:Complete("organize_strike")
                    StateGraphUtil.AddLeaveLocation(cxt)
                end
                cxt:TalkTo(available_people[1])
                if #available_people == 1 then
                    cxt:Dialog("DIALOG_ONE_STRIKER")
                    cxt.quest:Fail("organize_strike")
                    fireall()
                    StateGraphUtil.AddLeaveLocation(cxt)
                elseif strike_score >= math.random(3,5) then
                    cxt:Dialog("DIALOG_PROTEST")
                    for i, agent in ipairs(available_people) do
                        cxt.enc:PresentAgent( agent, SIDE.LEFT )
                        cxt:Quip(agent, "protest_chant")
                    end
                    cxt:Dialog("DIALOG_PROTEST_SUCCESS")

                    successfn()
                else
                    cxt:Dialog("DIALOG_LOW_STRIKERS")
                    cxt.quest:Fail("organize_strike")
                    fireall()
                    StateGraphUtil.AddLeaveLocation(cxt)
                end
            end
        end)
