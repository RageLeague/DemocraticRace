local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}
:AddOpinionEvents{
    help_workers_go_back_to_work =
    {
        delta = OPINION_DELTAS.LIKE,
        txt = "Help their workers get back to work",
    },
    get_better_conditions =
    {
        delta = OPINION_DELTAS.LIKE,
        txt = "Help them get better working conditions",
    },
}

-- Steal the code for food fight because the two events are very similar.
QDEF:AddConvo()
    :ConfrontState("CONF")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You see a bunch of people arguing.
                baron:
                    !right
                    !angry
                    Get back to work!
                worker:
                    !left
                    !angry
                    We will do that when you improve the working condition!
                baron:
                    Don't force me to use force!
                    !exit
                worker:
                    !exit
                * Seems you can extinguish the spark of a riot before it is started.
                * (I didn't came up with this joke. The base game did.)
                player:
                    !left
            ]],
            OPT_TALK_TO_WORKER = "Talk to the lead worker",
            OPT_TALK_TO_BARON = "Talk to the Spark Baron",
            OPT_LEAVE = "Leave before anyone sees you",
            DIALOG_LEAVE = [[
                * You've decided that you have better things to do.
            ]],
        }
        :Fn(function(cxt)
            cxt.quest:Complete()
            cxt.quest.param.barons =  CreateCombatParty("SPARK_BARON_PATROL", cxt.quest:GetRank(), cxt.location, true)

            -- Replace it with something else here
            cxt.quest.param.workers =  CreateCombatParty("DEMOCRACY_LABORERS", cxt.quest:GetRank(), cxt.location, true)

            cxt:ReassignCastMember("worker", cxt.quest.param.workers[1])
            cxt:ReassignCastMember("baron", cxt.quest.param.barons[1])

            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_TALK_TO_WORKER")
                :GoTo("STATE_TALK_TO_WORKER")

            cxt:Opt("OPT_TALK_TO_BARON")
                :GoTo("STATE_TALK_TO_BARON")

            cxt:Opt("OPT_LEAVE")
                :Dialog("DIALOG_LEAVE")
                :Travel()
        end)


    :State("STATE_TALK_TO_WORKER")
        :Loc{
            DIALOG_INTRO_FIRST = [[
                * You turn to the leader of the unhappy laborers.
                player:
                    Hello. What's going on here, if I might ask?
                worker:
                    !right
                    {liked?
                        {player}! Thank Hesh you are here!
                    }
                    This oshnooze has been mistreating us workers for ages! We are striking until working conditions improve.
                    We won't be extorted any more!
            ]],
            DIALOG_INTRO_NOT_FIRST = [[
                worker:
                    !right
                    So? What are you going to do?
            ]],


            --Threaten the workers. Makes the baron happy with you
            OPT_THREATEN = "Threaten {agent} to go back to work",
            DIALOG_THREATEN = [[
                player:
                    If you have a problem with your contract, take it up with your foreman.
                    Now get out of here before I lose my temper.
            ]],
            DIALOG_THREATEN_SUCCESS = [[
                worker:
                    You haven't heard the last of this.
                    You might want be careful walking around the pearl at night, grifter.
                    !exit
                * The workers storm out.
                baron:
                    !right
                    !happy
                    Thanks, pal. You really have to be firm with these scrubs, eh? Give 'em an inch and they'll come take all of your inches.
            ]],
            DIALOG_THREATEN_FAIL = [[
                worker:
                    You don't scare me.
                    I'm tired of being pushed around!
            ]],

            --if you can convince both sides to meet half-way, you can walk away without anyone hating (or liking) you.
            OPT_COMPROMISE = "Convince {worker} to compromise",
            TT_COMPROMISE = "You will have to convince both sides to accept the compromise.",
            DIALOG_COMPROMISE = [[
                player:
                    $miscPersausive
                    I can't promise you everything you're asking for, but what if I could get you a little more?
                    Would you go back to work then?
            ]],
            DIALOG_COMPROMISE_SUCCESS = [[
                player:
                    $miscPersuasive
                    After all, if you can reach an agreement, then the Barons won't be so quick to dismiss your concerns.
                    !overthere
                    Not when you've shown them how reasonable you can be.
                worker:
                    !palm
                    Something <b>is</> better than nothing.
                    And I would like to keep my current job if it means it pays enough.
                    We'll listen to their offer.
            ]],
            DIALOG_COMPROMISE_FAIL = [[
                player:
                    After all, they say "money can't buy happiness".
                worker:
                    !angry_shrug
                    $angryPatienceLost
                    Are you serious?!
                    Clearly the only way we're going to get anything is with a show of force.
                    Step aside, Baron dog, and let us solve our own problems.
            ]],

            OPT_TALK_TO_BARON = "Talk to {baron} instead",
            DIALOG_TALK_TO_BARON = [[
                player:
                    Hold that thought.
            ]],

            OPT_LEAVE = "Leave",
            DIALOG_LEAVE = [[
                player:
                    Well, you guys have fun.
                * You leave them to figure this among themselves.
            ]],

            REQ_READY_TO_COMPROMISE = "{agent} is ready to compromise",
            REQ_COMPROMISE_FAILED = "Compromise is no longer an option",
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.enc:SetPrimaryCast(cxt.quest.param.workers[1])
                cxt:Dialog(not cxt.quest.param.heard_worker_intro and "DIALOG_INTRO_FIRST" or "DIALOG_INTRO_NOT_FIRST")
                cxt.quest.param.heard_worker_intro = true

            end

            cxt:Opt("OPT_THREATEN")
                :Dialog("DIALOG_THREATEN")
                :ReqCondition(not cxt.quest.param.convince_worker_compromise or cxt.quest.param.compromise_failed, "REQ_READY_TO_COMPROMISE" )
                :UpdatePoliticalStance("LABOR_LAW", -2)
                :Negotiation{
                    suppressed = {cxt.quest.param.barons[1] },
                    flags = NEGOTIATION_FLAGS.INTIMIDATION,
                    on_success = function()
                        cxt:Dialog("DIALOG_THREATEN_SUCCESS")
                        for k,v in ipairs(cxt.quest.param.workers) do
                            v:MoveToLimbo()
                        end

                        cxt.quest.param.barons[1]:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("help_workers_go_back_to_work"))


                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                    on_fail = function()
                        cxt:Dialog("DIALOG_THREATEN_FAIL")
                    end,
                }

            cxt:Opt("OPT_COMPROMISE")
                :PostText("TT_COMPROMISE")
                :Dialog("DIALOG_COMPROMISE")
                :ReqCondition(not cxt.quest.param.compromise_failed, "REQ_COMPROMISE_FAILED" )
                :Negotiation{
                    suppressed = {cxt.quest.param.barons[1] },
                    on_success = function()
                        cxt:Dialog("DIALOG_COMPROMISE_SUCCESS")
                        cxt.quest.param.convince_worker_compromise = true
                        if cxt.quest.param.convince_baron_compromise then
                            cxt:GoTo("STATE_COMPROMISE")
                        end
                    end,
                    on_fail = function()
                        cxt:Dialog("DIALOG_COMPROMISE_FAIL")
                        cxt.quest.param.compromise_failed = true
                    end,
                }

            cxt:Opt("OPT_TALK_TO_BARON")
                :Dialog("DIALOG_TALK_TO_BARON")
                :GoTo("STATE_TALK_TO_BARON")

            cxt:Opt("OPT_LEAVE")
                :Dialog("DIALOG_LEAVE")
                :ReceiveOpinion(OPINION.DID_NOT_HELP, cxt.quest.param.workers[1])
                :ReceiveOpinion(OPINION.DID_NOT_HELP, cxt.quest.param.barons[1])
                :Travel()
        end)


    :State("STATE_TALK_TO_BARON")
        :Loc{
            DIALOG_INTRO_FIRST = [[
                * You turn to the leader of the Spark Barons.
                player:
                    Hello. What's going on here, if I might ask?
                baron:
                    !right
                    !sigh
                    $miscRelieved
                {liked?
                    Oh thank the Spark you showed up.
                }
                    These lawless laborers wants to rebel against me.
                    Something about wanting better rights.
                    I need them get back to work.
                    Can you help me do that?
            ]],
            DIALOG_INTRO_NOT_FIRST = [[
                baron:
                    !right
                    Just crack a couple skulls and get them out of here!
                    They're not going to listen to anything else.
            ]],

            OPT_THREATEN = "Threaten {baron} to comply with the workers",
            DIALOG_THREATEN = [[
                player:
                    !angry
                    Just listen to the workers.
                    I can't promise what will happen to you if you don't.
            ]],
            DIALOG_THREATEN_FAIL = [[
                player:
                    !hips
                    What do you think of that?
                baron:
                    You think I'm going to back down now?
                    !cruel
                    We can easily take the laborers. It's up to them to decide if they want to find out.
            ]],
            DIALOG_THREATEN_SUCCESS = [[
                player:
                    !thought
                    $neutralThoughtful
                    What would your supervisor think if a riot happens under your hand?
                baron:
                    !placate
                    Fine. I hear you.
                    I'll comply with the worker's demand.
                    !spit
                    They are still dirt poor anyway.
                worker:
                    !right
                    $neutralThanks
                    Thank you, grifter. It's not often that we get a fair shake here.
            ]],


            OPT_CONVINCE_COMPROMISE = "Convince {baron} to compromise",
            TT_COMPROMISE = "You will have to convince both sides to accept the compromise.",
            DIALOG_CONVINCE_COMPROMISE = [[
                player:
                    Look, they just want better working condition. Is it that hard to ask?
                    You could meet them half-way, couldn't you?
            ]],
            DIALOG_CONVINCE_COMPROMISE_FAIL = [[
                player:
                    Surely you see the benefit in a content workforce.
                baron:
                    !angry
                    $angryPatienceLost
                    Give them an inch, and they'll cut my throat. I'm not negotiating with these rats.
            ]],
            DIALOG_CONVINCE_COMPROMISE_SUCCESS = [[
                player:
                    $miscPersuasive
                    Look, they are just unhappy with the current working condition.
                    !interest
                    Even just improving it a little bit, they will probably be content and go back to work.
                    Way easier than resorting to violence.
                baron:
                    !shrug
                    $neutralResigned
                    Ach, fine. I guess I can listen to what they have to say.
            ]],

            OPT_TALK_TO_WORKER = "Talk to {worker} instead",
            DIALOG_TALK_TO_WORKER = [[
                player:
                    Excuse me.
            ]],

            OPT_LEAVE = "Leave",
            DIALOG_LEAVE = [[
                player:
                    Well, you guys have fun.
                * You leave them to figure this among themselves.
            ]],

            REQ_READY_TO_COMPROMISE = "{baron} is ready to compromise",
            REQ_COMPROMISE_FAILED = "Compromise is no longer an option",
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.enc:SetPrimaryCast(cxt.quest.param.barons[1])
                cxt:Dialog(not cxt.quest.param.heard_baron_intro and "DIALOG_INTRO_FIRST" or "DIALOG_INTRO_NOT_FIRST")
                cxt.quest.param.heard_baron_intro = true
            end

            cxt:Opt("OPT_THREATEN")
                :ReqCondition(not cxt.quest.param.convince_baron_compromise or cxt.quest.param.compromise_failed, "REQ_READY_TO_COMPROMISE" )
                :Dialog("DIALOG_THREATEN")
                :UpdatePoliticalStance("LABOR_LAW", 2)
                :Negotiation{
                    flags = NEGOTIATION_FLAGS.INTIMIDATION,
                    subject = cxt.quest.param.workers[1],
                    on_success = function()
                        cxt:Dialog("DIALOG_THREATEN_SUCCESS")
                        cxt.quest:Complete("deal_with_caffy")
                        cxt.quest.param.workers[1]:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("get_better_conditions"))
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,

                    on_fail = function()
                        cxt:Dialog("DIALOG_THREATEN_FAIL")
                    end,
                }

            cxt:Opt("OPT_CONVINCE_COMPROMISE")
                :Dialog("DIALOG_CONVINCE_COMPROMISE")
                :PostText("TT_COMPROMISE")
                :ReqCondition(not cxt.quest.param.compromise_failed, "REQ_COMPROMISE_FAILED" )
                :Negotiation{
                    subject = cxt.quest.param.workers[1],
                    on_success = function()
                        cxt:Dialog("DIALOG_CONVINCE_COMPROMISE_SUCCESS")
                        cxt.quest.param.convince_baron_compromise = true
                        if cxt.quest.param.convince_worker_compromise then
                            cxt:GoTo("STATE_COMPROMISE")
                        end
                    end,
                    on_fail = function()
                        cxt:Dialog("DIALOG_CONVINCE_COMPROMISE_FAIL")
                        cxt.quest.param.compromise_failed = true
                    end,
                }

            cxt:Opt("OPT_TALK_TO_WORKER")
                :Dialog("DIALOG_TALK_TO_WORKER")
                :GoTo("STATE_TALK_TO_WORKER")

            cxt:Opt("OPT_LEAVE")
                :Dialog("DIALOG_LEAVE")
                :ReceiveOpinion(OPINION.DID_NOT_HELP, cxt.quest.param.workers[1])
                :ReceiveOpinion(OPINION.DID_NOT_HELP, cxt.quest.param.barons[1])
                :Travel()
        end)

    :State("STATE_COMPROMISE")
        :Loc{
            DIALOG_INTRO_WORKER = [[
                player:
                    It's settled, then, isn't it?
                baron:
                    !left
            ]],
            DIALOG_INTRO_BARON = [[
                player:
                    It's settled, then, isn't it?
                worker:
                    !left
            ]],
            DIALOG_INTRO_COMMON = [[
                baron:
                    I talked it over with {player}, and I can listen to what you have to say.
                worker:
                    Alright, this is what we want...
                * You leave them to work out the finer points.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog( cxt:GetCastMember("right") == cxt.quest.param.workers[1] and "DIALOG_INTRO_WORKER" or "DIALOG_INTRO_BARON" )
            cxt:Dialog("DIALOG_INTRO_COMMON")
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 4)
            StateGraphUtil.AddLeaveLocation(cxt)
        end)