local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    precondition = function(quest)
        local canspawn = false

        if DemocracyUtil.GetFactionEndorsement("CULT_OF_HESH") < RELATIONSHIP.NEUTRAL then
            quest.param.unpopular = true
            canspawn = true
        end

        return canspawn
    end,
}
:AddOpinionEvents{
    refused_tithe = {
        delta = OPINION_DELTAS.BAD,
        txt = "Refused to pay the tithe",
    },
}
QDEF:AddConvo()
    :ConfrontState("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * The bright blue of their robes somehow stand out against the neons of the Pearl.
                agent:
                    !hesh_greeting
                    Greetings, {player}. It's been long since you've paid your tithes.
                {player_sal?
                player:
                    !crossed
                    I paid plenty of tithes back on the derricks. 
                agent:
                    Well there's always plenty more work to do for Hesh, so the tithes need to keep flowing.
                }
                {player_rook?
                player:
                    !question
                    Are you sure those tithe records are under a "{player}"?
                agent:
                    As it stands, those records say you've never paid tithes.
                    Always a good time to start paying.
                }
                {player_smith?
                player:
                    !angry_shrug
                    Aw, come on! Vix's schooling fees practically pay for my tithes already!
                agent:
                    This isn't about your family's tithes. This is about <i>your</> personal tithes.
                }
                {not player_sal? and not player_rook? and not player_smith?
                player:
                    !angry_point
                    I've paid all my tithes on time, just like the rest of us.
                agent:
                    Well, that's before you became a politician.
                    But now you have to pay extra if you decide to run for office.
                }
            ]],
            OPT_PAY = "Pay the tithe",
            DIALOG_PAY = [[
                player:
                    !give
                    Here's your ounce of sea salted flesh.
                agent:
                    !hesh_greeting
                    Hesh thanks you. May you walk in the shallows.
            ]],
            OPT_CONVINCE_EXEMPT = "Convince {agent} to leave you alone",
            DIALOG_CONVINCE_EXEMPT = [[
                player:
                {not paid_all?
                    !hips
                    Your records must be wrong. I was told that I was exempt from the next round of tithes.
                agent:
                    The "next round"?
                }
                {paid_all?
                    !bashful
                    Look, that's all i've got. I promise i'll come up with the money next time, okay?
                }
            ]],
            DIALOG_CONVINCE_EXEMPT_SUCCESS = [[
                {not paid_all?
                player:
                    {player_smith?
                        Vix gave me an exemption. Said I could beat the face in of anyone saying otherwise.
                    agent:
                        !question
                        Vix'malli said this specifically?
                    player:
                        !shrug
                        What, d'you need to see the decree?
                        Sure he said trying to refuse a cardinal was worth some sort of punishment.
                    agent:
                        !scared
                        Oh, I would never question Vix'malli. 
                        You...may have a good day, now.
                        * It's hard to live with, but having Vix in your back pocket always helped in these kinds of ruts.
                    }
                    {player_rook?
                        !give
                        ...and my records of all times i've been tithed, timestamped for your convenience, and my-
                    agent:
                        !scared
                        How does someone have so many papers on just their tithes?
                    player:
                        !shrug
                        I'm a thorough person. You'll find my exemptions in there.
                    agent:
                        I...
                        This is too much trouble. You win, {player}.
                    player:
                        Really? I found it was quite simple once you looked-
                    agent:
                        !crossed
                        I am not reading all of this paperwork just to ask you for money.
                        !exit
                    * With that, {agent} is thoroughly scared away.
                    * All of that admiralty training is paying off, evidently.
                    }
                    {not player_smith? and not player_rook?
                        I've donated more than my fair share to the Cult all this time.
                        So I went up to the Bishop and-
                    agent:
                        This is an expemtion from the Bishop?
                    player:
                        !point
                        That's the one. 
                        Heard he liked enforcing these kinds of exemptions a little too much.
                        !nudge_nudge
                        If you get my meaning.
                    agent:
                        !scared
                        Ah...of course.
                        Well, we can take our holy work elsewhere. May you continue walking in the shallows.
                    }
                }
                {paid_all?
                agent:
                    !sigh
                    I suppose hesh does not bless us all with good fortune.
                    Very well. If you need time, we shall take what we already have and leave you be.
                    !exit
                        * As {agent} leaves, you make sure to remember {agent.hisher} face, so you know who to avoid for a very long time.
                }
            ]],
            DIALOG_CONVINCE_EXEMPT_FAILURE = [[
                {not paid_all?
                    {player_smith?
                        player:
                            So I went up to Vix and I said "Hey Vix, what's a brother-
                        agent:
                            !question
                            You're Vix's brother?
                        player:
                            Yeah, the heshian cardinal himself!
                        agent:
                            !think
                            Strange. He said he never gave exemptions to siblings.
                            Especially the "Dissapointment", as he called him.
                        player:
                            Wow. I get he has multiple axes to grind but...
                            But that just stings an extra bit hard.
                    }
                    {player_rook?
                        player:
                            I believe you'll find all of my tithes paid under a different alias.
                            !give
                            But i'm thorough. I've got all of my records right here.
                        agent:
                            !notepad
                            Hrm...looks alright...except
                            You've apparently never paid any tithes when you were called "Coin Flipster"
                        player:
                            !bashful
                            It was...a phase.
                            A different me.
                        agent:
                            That's what an alias is. If you're not paying for {player}'s tithes, how about we start with "Coin Flipster"'s tithes.
                    }
                    {not player_smith? and not player_rook?
                        player:
                            !crossed
                            I had my exemptions notarized by the local priest.
                        agent:
                            ...
                            !question
                            May I see these exemptions?
                        player:
                            !bashful
                            I...uh...left them in my other bag.
                        agent:
                            What a shame. Without proper papers, I can't give you a free pass.
                    }
                {paid_all?
                        player:
                            The work has been light, my advisor-
                        agent:
                            Advisor? How can you pay an advisor and yet not have enough to stave off damnation?
                        player:
                            Well, funny story, I-
                        agent:
                            I've heard enough. If you spent all of your money on booze, maybe you'll understand this lesson.
                            !fight
                            Time to dispense a fraction of Hesh's wrath.
                }
            ]],
            OPT_NO_PAY = "Refuse to pay",
            DIALOG_NO_PAY = [[
                player:
                    ...No.
                agent:
                    !question
                    No?
                player:
                    !shrug
                    No, i'm not going to pay tithes.
                    I don't care what happens with my soul, I care about the now.
                agent:
                    I...see
                    !fight
                    Perhaps i'll just shift the "now" to issues of your soul. 
                    Witness a fraction of Hesh's wrath.
            ]],
            OPT_PAY_ALL = "Pay all you have",
            DIALOG_PAY_ALL = [[
                * You turn your pockets inside out, and scour every place you've kept money on your person.
                player:
                    !give
                * But you already know it's not enough, {agent} snatches it out of your hands, but the counting is more of a courtesy.
                agent:
                    !angry
                    This isn't enough. Why are you attempting to refuse Hesh's will?
            ]],

            SIT_MOD_BAD = "You haven't paid tithes in a very long time",
            SIT_MOD_PARTIAL = "You paid as much as you could",
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                cxt.enc.scratch.opfor = CreateCombatParty("HESH_PATROL", cxt.quest:GetRank() + 1, cxt.location, true)
                cxt:TalkTo(cxt.enc.scratch.opfor[1])
                cxt:Dialog("DIALOG_INTRO")
                cxt.quest.param.tithe = 200
            end
            local cost, modifier = CalculatePayment( cxt:GetAgent(), cxt.quest.param.tithe)
            if not cxt.quest.param.paid_all then
                if cost <= cxt.caravan:GetMoney() then
                    cxt:Opt("OPT_PAY")
                        :Dialog("DIALOG_PAY")
                        :DeliverMoney(cxt.quest.param.tithe)
                        :Travel()
                else
                    cxt:Opt("OPT_PAY_ALL")
                        :Dialog("DIALOG_PAY_ALL")
                        :DeliverMoney(cxt.caravan:GetMoney(), {no_scale = true})
                        :Fn(function(cxt)
                            cxt.quest.param.paid_all = true
                            if cxt.quest.param.tried_negotiate then
                                cxt:GoTo("STATE_DEFEND")
                            end
                        end)
                end
            end
            if not cxt.quest.param.tried_negotiate then
                cxt:BasicNegotiation("CONVINCE_EXEMPT", {
                    situation_modifiers =
                    {
                        { value = 20, text = cxt:GetLocString("SIT_MOD_BAD") },
                        cxt.quest.param.paid_all and { value = -30, text = cxt:GetLocString("SIT_MOD_PARTIAL") } or nil
                    },
                })
                    :OnSuccess()
                        :Travel()
                    :OnFailure()
                        :Fn(function(cxt)
                            cxt.quest.param.tried_negotiate = true
                            if cxt.quest.param.paid_all then
                                cxt:GoTo("STATE_DEFEND")
                            end
                        end)
            end
            if not cxt.quest.param.paid_all then
                cxt:Opt("OPT_NO_PAY")
                    :Dialog("DIALOG_NO_PAY")
                    :UpdatePoliticalStance("RELIGIOUS_POLICY", -2)
                    :GoTo("STATE_DEFEND")
            end
        end)
    :State("STATE_DEFEND")
        :Loc{
            OPT_DEFEND = "Defend yourself!",
            DIALOG_DEFEND = [[
                player:
                    !fight
                    Warnin' you now. You're dealing with a Lumin Shark.
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
                        That...won't be neccesary.
                        !angry_point
                        But you have not seen Hesh's wrath, not in it's fullest, until today.
                    player:
                        !hand_wave
                        They always say that, but i'm still here.
                }
            ]],
        }
        :Fn(function(cxt)
            cxt:Opt("OPT_DEFEND")
                :Dialog("DIALOG_DEFEND")
                :Battle{
                    enemies = cxt.quest.param.opfor,
                    flags = BATTLE_FLAGS.SELF_DEFENCE,
                }
                :OnWin()
                    :Dialog("DIALOG_DEFEND_WIN")
                    :Fn(function(cxt)
                        if cxt:GetAgent():IsAlive() then
                            cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("refused_tithe"))
                        end
                    end)
                    :Travel()
        end)
