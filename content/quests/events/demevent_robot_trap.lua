local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    precondition = function(quest)
        local can_spawn = false

        if DemocracyUtil.GetFactionEndorsement("SPARK_BARONS") < RELATIONSHIP.NEUTRAL then
            quest.param.unpopular = true
            can_spawn = true
        end

        return can_spawn
    end,
}

QDEF:AddConvo()
    :ConfrontState("STATE_CONF")
        :Loc{
            DIALOG_INTRO = [[
                * [p] It is a curious sight, seeing a random automech lying in the middle of the streets.
                * As you approach to investigate, suddenly it whirls into life!
                player:
                    !left
                mech:
                    !right
                    ERROR. ERROR.
                    TARGET ACQUIRED. ENGAGING IN COMBAT.
                player:
                    !scared
                    Oh dear.
            ]],
            OPT_FIX = "Fix the automech's programming",
            DIALOG_FIX = [[
                player:
                    [p] How do I go about doing that?
                    Let's try...
            ]],
            DIALOG_FIX_SUCCESS = [[
                mech:
                    [p] CAUTION! NO TARGET IN SIGHT!
                    ENTERING STANDBY MODE.
                player:
                    !sigh
                    Phew... It worked.
            ]],
            DIALOG_FIX_FAILURE = [[
                mech:
                    [p] TARGET LOCKED ON. FIRING AUTO-CANNON.
                player:
                    Wait wait wait can I try-
                * The mech does not grant you such opportunity.
            ]],
            OPT_DEFEND = "Defend yourself!",
            DIALOG_DEFEND = [[
                player:
                    !fight
                    [p] Acquire this!
            ]],
            DIALOG_DEFEND_WIN = [[
                player:
                    [p] Phew! That was messy.
            ]],
            OPT_ESCAPE = "Escape the automech's barrage",
            DIALOG_ESCAPE = [[
                * [p] Not wanting to deal with a rampaging automech, you escape the scene.
                * You caught a few stray shots while trying to escape.
            ]],
        }
        :Fn(function(cxt)
            cxt.quest:Complete()

            local mech = Agent("SPARK_BARON_AUTOMECH")
            TheGame:GetGameState():AddAgent( mech )
            cxt:ReassignCastMember("mech", mech)
            mech:MoveToLocation(cxt.location)
            cxt.enc:SetPrimaryCast(mech)

            cxt:Dialog("DIALOG_INTRO")

            cxt:BasicNegotiation("FIX", {

            })
                :OnSuccess()
                    :Fn(function(cxt)
                        cxt.enc.scratch.fixed = true
                    end)
                    :GoTo("STATE_TROUBLE")
                :OnFailure()
                    :Fn(function(cxt)
                        cxt:Opt("OPT_DEFEND")
                            :Battle{
                                enemies = { mech },
                                flags = BATTLE_FLAGS.SELF_DEFENCE,
                                advantage = TEAM.RED,
                            }
                            :OnWin()
                                :Dialog("DIALOG_DEFEND_WIN")
                                :GoTo("STATE_TROUBLE")
                    end)

            cxt:Opt("OPT_DEFEND")
                :Dialog("DIALOG_DEFEND")
                :Battle{
                    enemies = { mech },
                    flags = BATTLE_FLAGS.SELF_DEFENCE,
                }
                :OnWin()
                    :Dialog("DIALOG_DEFEND_WIN")
                    :GoTo("STATE_TROUBLE")

            cxt:Opt("OPT_ESCAPE")
                :Dialog("DIALOG_ESCAPE")
                :DeltaHealth(-8)
                :Travel()
        end)
    :State("STATE_TROUBLE")
        :Loc{
            DIALOG_INTRO = [[
                * [p] Just as you are about to leave, Spark Barons approach you from the shadows.
                * Where did they even come from?
                agent:
                    !right
                    [p] Oi!
                {automech_dead?
                    That automech you just destroyed was Spark Baron property! You must pay for damage!
                player:
                    Damage? That automech was attacking me!
                agent:
                    Excuses! If it wasn't for you, it wouldn't be destroyed! Now pay up!
                }
                {not automech_dead?
                    That automech you just accessed without authorization is Spark Baron property! You must pay for damage!
                player:
                    Hey! I just fixed your rampaging automech! You should thank me instead!
                agent:
                    Nonsense! You did access it without authorization, no? Now pay up!
                }
                * You are starting to suspect this was a setup.
            ]],
            OPT_PAY = "Pay for damage",
            DIALOG_PAY = [[
                player:
                    !give
                    [p] Hah... Here's the money.
                agent:
                    Oh, uh. Thanks. Reparation accepted.
                    I guess... be on your way, then.
                * You have a feeling {agent.heshe} didn't expect you to fulfill {agent.hisher} ludicrous demands.
            ]],
            OPT_CONDEMN = "Condemn the Spark Barons' wanton use of automechs",
            DIALOG_CONDEMN = [[
                player:
                    [p] It is <i>you</> who damaged it by using it the way you use it.
            ]],
            DIALOG_CONDEMN_SUCCESS = [[
                player:
                    [p] It is against Hesh's will to create them for your frivolous goals.
                    The precious artifacts that form the core of your "automechs" should be revered! Not used haphazardly like this!
                agent:
                    Ah, blast it, I really don't want to deal with a Heshian today.
                    You know what? Forget it. I'm not going to charge you anything.
                    Just-
                * {agent} left you alone.
            ]],
            DIALOG_CONDEMN_FAILURE = [[
                agent:
                    [p] That's now liability works, you know?
                    You touched it, you {automech_dead?destroyed|damaged} it, and you pay up.
                    We can do this the easy way, or the hard way.
            ]],
            OPT_COURT = "Ask {agent} to take this to a Deltrean court",
            DIALOG_COURT = [[
                player:
                    [p] Pay for damage? Alright.
                    After we determine this in a Deltrean court, that is.
            ]],
            DIALOG_COURT_SUCCESS = [[
                player:
                    [p] You are just going to waste both of our time and money if you go that route.
                    I mean, we could let someone else adjudicate this dispute? I heard the Rise has a tribunal for conflicts like this.
                agent:
                    Haha. Very funny.
                    Fine. Have it your way then.
                    But don't worry. In a few days, when we are in power, expect this fine to be doubled, no, tripled.
                player:
                    Of course, of course.
                * {agent} leaves you alone while documenting the damages done to the robot.
                * For the sake of your wallet, you better win this election!
            ]],
            DIALOG_COURT_FAILURE = [[
                agent:
                    [p] What are you talking about? This is Havaria.
                    Deltree has no say here.
                    You aren't getting away from this one.
            ]],
            OPT_REFUSE = "Refuse to pay",
            DIALOG_REFUSE = [[
                player:
                    [p] This is extortion.
                    I'm not paying.
                agent:
                    Fine, let's to this the hard way, then.
            ]],
            SIT_MOD_LEGAL = "Legal legerdemain",
            SIT_MOD_SECULAR = "Secular mindset",
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest.param.automech_dead = cxt:GetCastMember("mech"):IsDead()
                cxt.enc.scratch.opfor = CreateCombatParty("SPARK_BARON_PATROL", cxt.quest:GetRank() + 1, cxt.location, true)
                cxt:TalkTo(cxt.enc.scratch.opfor[1])
                cxt:Dialog("DIALOG_INTRO")
                cxt.quest.param.payment = cxt.quest.param.automech_dead and 300 or 200
            end

            cxt:Opt("OPT_PAY")
                :Dialog("DIALOG_PAY")
                :DeliverMoney(cxt.quest.param.payment)
                :Travel()

            if not cxt.quest.param.tried_negotiate then
                cxt:Opt("OPT_CONDEMN")
                    :Dialog("DIALOG_CONDEMN")
                    :UpdatePoliticalStance("RELIGIOUS_POLICY", 2)
                    :Fn(function(cxt) cxt.quest.param.tried_negotiate = true end)
                    :Negotiation{
                        flags = NEGOTIATION_FLAGS.INTIMIDATION,
                        situation_modifiers =
                        {
                            { value = 20, text = cxt:GetLocString("SIT_MOD_SECULAR") },
                        },
                    }
                        :OnSuccess()
                            :Dialog("DIALOG_CONDEMN_SUCCESS")
                            :Travel()
                        :OnFailure()
                            :Dialog("DIALOG_CONDEMN_FAILURE")
                cxt:Opt("OPT_COURT")
                    :Dialog("DIALOG_COURT")
                    :UpdatePoliticalStance("INDEPENDENCE", -2)
                    :Fn(function(cxt) cxt.quest.param.tried_negotiate = true end)
                    :Negotiation{
                        situation_modifiers =
                        {
                            { value = 20, text = cxt:GetLocString("SIT_MOD_LEGAL") },
                        },
                    }
                        :OnSuccess()
                            :Dialog("DIALOG_COURT_SUCCESS")
                            :Travel()
                        :OnFailure()
                            :Dialog("DIALOG_COURT_FAILURE")
            end

            cxt:Opt("OPT_REFUSE")
                :Dialog("DIALOG_REFUSE")
                :GoTo("STATE_DEFEND")
        end)
    :State("STATE_DEFEND")
        :Loc{
            OPT_DEFEND = "Defend yourself!",
            DIALOG_DEFEND = [[
                player:
                    !fight
                {not tried_intimidate?
                    I'm warning you now. You're dealing with a Lumin Shark.
                }
                {tried_intimidate?
                    [p] Let me give you a demonstration.
                }
            ]],
            DIALOG_DEFEND_WIN = [[
                {dead?
                    * It's a take from the poor, give to the rich world around here.
                    * However, by the rustling of your hands through the newly dead's pockets, it can sometimes be the other way around.
                }
                {not dead?
                    player:
                        !angry
                        Had enough, or do you want me to pay to hurt you a step further?
                    agent:
                        !injured
                        That...won't be necessary.
                        !angry_accuse
                        But you have not seen Hesh's wrath, not in it's fullest, until today.
                    player:
                        !handwave
                        They always say that, but I'm still here.
                }
            ]],
            OPT_INTIMIDATE = "Scare {agent} away",
            DIALOG_INTIMIDATE = [[
                player:
                    [p] Look at me.
                    I'm scary.
            ]],
            DIALOG_INTIMIDATE_SUCCESS_SOLO = [[
                agent:
                    [p] Oh no I'm scared!
                    !exit
            ]],
            DIALOG_INTIMIDATE_SUCCESS = [[
                * [p] {agent}'s followers ran away.
                agent:
                    I'll win next time!
                    !exit
            ]],
            DIALOG_INTIMIDATE_OUTNUMBER = [[
                * [p] Some of {agent}'s followers ran away.
                agent:
                    !fight
                    No matter. I can still win!
            ]],
            DIALOG_INTIMIDATE_FAILURE = [[
                agent:
                    Wait, this guy isn't that strong.
                {some_ran?
                    Come back, you cowards!
                * The routed followers came back,
                }
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)

            if not cxt.quest.param.tried_intimidate then
                if #cxt.enc.scratch.opfor == 1 then
                    cxt:Opt("OPT_INTIMIDATE")
                        :Dialog("DIALOG_INTIMIDATE")
                        :Negotiation{
                            cooldown = 0,
                            flags = NEGOTIATION_FLAGS.INTIMIDATION,
                        }
                            :OnSuccess()
                                :Dialog("DIALOG_INTIMIDATE_SUCCESS_SOLO")
                                :Travel()
                            :OnFailure()
                                :Dialog("DIALOG_INTIMIDATE_FAILURE")
                                :Fn(function(cxt)
                                    cxt.quest.param.tried_intimidate = true
                                end)
                else
                    local allies = {}
                    for i, ally in ipairs(cxt.enc.scratch.opfor) do
                        if i ~= 1 then
                            table.insert(allies, ally)
                        end
                    end
                    cxt:Opt("OPT_INTIMIDATE")
                        :Dialog("DIALOG_INTIMIDATE")
                        :Negotiation{
                            cooldown = 0,
                            flags = NEGOTIATION_FLAGS.INTIMIDATION | NEGOTIATION_FLAGS.ALLY_SCARE,
                            enemy_resolve_required = 8 + cxt.quest:GetRank() * 10,
                            fight_allies = allies,
                            on_success = function(cxt, minigame)
                                local keep_allies = {}
                                for i, modifier in minigame:GetOpponentNegotiator():Modifiers() do
                                    if modifier.id == "FIGHT_ALLY_SCARE" and modifier.ally_agent then
                                        table.insert( keep_allies, modifier.ally_agent )
                                    end
                                end

                                for k,v in pairs(allies) do
                                    if not table.arrayfind(keep_allies, v) then
                                        v:MoveToLimbo()
                                    end
                                end
                                if #keep_allies == 0 or (DemocracyUtil.CalculatePartyStrength(cxt.player:GetParty()) >= DemocracyUtil.CalculatePartyStrength(cxt:GetAgent():GetParty()) ) then
                                    cxt:Dialog("DIALOG_INTIMIDATE_SUCCESS")
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                else
                                    cxt:Dialog("DIALOG_INTIMIDATE_OUTNUMBER")
                                    cxt.quest.param.tried_intimidate = true
                                end
                            end,
                            on_fail = function(cxt,minigame)
                                cxt.enc.scratch.some_ran = not (minigame:GetOpponentNegotiator():FindCoreArgument() and minigame:GetOpponentNegotiator():FindCoreArgument():GetShieldStatus())
                                cxt:Dialog("DIALOG_INTIMIDATE_FAILURE")
                                cxt.quest.param.tried_intimidate = true
                            end,
                        }
                end
            end
            cxt:Opt("OPT_DEFEND")
                :Dialog("DIALOG_DEFEND")
                :Battle{
                    -- enemies = cxt.quest.param.opfor,
                    flags = BATTLE_FLAGS.SELF_DEFENCE,
                }
                :OnWin()
                    :Dialog("DIALOG_DEFEND_WIN")
                    :Travel()

        end)
