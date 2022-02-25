local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}
:AddDefCast("priest", "PRIEST")
:AddOpinionEvents{
    refused_vaccine =
    {
        delta = OPINION_DELTAS.DIMINISH,
        txt = "Refused to take the vaccine",
    },
}

QDEF:AddConvo()
    :ConfrontState("CONF")
        :Loc{
            DIALOG_INTRO = [[
                * You find a priest sitting by the side of the road, organizing an assortment of vials, syringes, and medical supplies.
                player:
                    !left
                agent:
                    !right
                    !hesh_greeting
                    Greetings, {player}. I have grave news to tell you.
                player:
                    !question
                agent:
                    A new type of plague has gone around Pearl-on-the-Foam, infecting those who walk through the shallows.
                    But you're in luck! We have prepared a vaccine to this infection!
                    Simply allow me to give it to you, and I promise you will be painlessly inoculated against this new plague.
            ]],
            OPT_ASK_INFESTATION = "Ask about the infestation",
            DIALOG_ASK_INFESTATION = [[
                player:
                    How did the Squeaky Clean Pearl get this infestation?
                agent:
                    Well, with the new election system, we had signed a truce deal allowing most willing to vote into the Pearl.
                    !overthere
                    Unfortunately, that opened Hesh's flood gates for a breed of heretics we normally kept in Grout Bog.
                    !flinch
                    These, er, <i>people<\> brought their own ideas, and those ideas brought sickness to Hesh's Pious.
                player:
                    !question
                    Is this infection as bad as you're doomsaying it to be?
                agent:
                    Hesh's wrath is harsh to those unfit for consumption.
                    Should you be infected without proper treatment, your death will be slow, and your soul damned.
                player:
                    Let's focus on the harsh and painful death part first.
                agent:
                    That's what most people care about more, short-sighted though it may be.
            ]],
            OPT_ASK_VACCINE = "Ask about the vaccine",
            DIALOG_ASK_VACCINE = [[
                player:
                    So what's in all those vials that you'd be stabbing me with?
                agent:
                    Uncouthly put, {player}. I assure you, this is a completely safe preventative measure.
                    You may feel some minor aches and I wouldn't recommend you exert yourself.
                    But that is just your body crafting it's shield of faith against this heretical poison.
                    !hesh_greeting
                    You'll shrug away the pains quickly, and your soul will be prepared for consumption by Hesh, as all who walk in the shallows deserve.
            ]],
            OPT_ACCEPT = "Accept the vaccine",
            DIALOG_ACCEPT = [[
                player:
                    It better be as painless as you make it sound like.
                agent:
                    A small prick, just through the skin. You won't feel a thing during the procedure.
                    Now if you just show me your arm...
                player:
                    !exit
                * ...
            ]],
            DIALOG_ACCEPT_PST = [[
                player:
                    !left
                    !injured
                    "Painless", I believe I can quote you as.
                    "Painless" is not anything close to what that felt like.
                agent:
                    !angry_accuse
                    Bite your tongue. Whatever you feel now is leagues better than the eternal damnation at the hands of Hesh itself.
                    It will take it's toll, yes, but your body and soul will be fit for consumption.
                player:
                    And how long will I be paying the fare for this mistake?
                agent:
                    !hesh_greeting
                    As long as you keep fighting it.
                    !exit
                * You roll your sleeve back up and trudge on, feeling a noticeable limp, but also a notable strength you can't quite place.
            ]],
            OPT_CONVINCE = "Question {agent} about the source of the vaccine",
            DIALOG_CONVINCE = [[
                player:
                    !crossed
                    Pardon if a strange cocktail of chemicals being injected into me puts me on edge.
                    I'd like to know what you put into this thing if you're going to give it to me.
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                agent:
                    If it will help prevent the disease from spreading...
                    Very well. We hadn't made the vaccine as quickly as we tell people.
                    !bashful
                    It was...supplied to us.
                player:
                    !question
                    Supplied from where?
                agent:
                    The Spark Barons had prepared an inoculative agent against it, although they hadn't made it particularly consumer friendly.
                    !over_there
                    But we had no choice. We had to protect the pious masses, so we "acquired" some and helped as many as we could.
                player:
                    And I'm assuming that "many as you could" is your voters?
                agent:
                    They were...the most receptive to the vaccine. They understood the importance of preparing the soul for consumption, you see.
            ]],
            --I was going to use this bit but felt it was a bit too upfront or just mean spirited
            --[[
            player:
                    Oddly generous for the Cult to turn heel on their MO like that.
                    Are you sure it's not just to keep the Cult vote safe?
                agent:
                    Blashphemer! We are more charitable than you make us out to be, hence why we wish to vaccinate and help those who walk in the shallows.
                player:
                    So that's a yes?
            ]]
            DIALOG_CONVINCE_NO_INTEL = [[
                agent:
                    Surely you know of Hesh's miracles?
                    We have derived this from a sacred formula passed down by priests for generations to combat illness of all kinds!
                player:
                    !point
                    It can't be a cure-all. You would've cured a lot more things with it if you had some magic salt-water disease killer.
                agent:
                    !hesh_greeting
                    Ah, as the Waterlogged Tomes decreed, it was to be kept secret from the public, as it could eventually cause the heretics to destroy it.
                player:
                    !question
                    Heretics wouldn't have any reason to destroy it, though.
                agent:
                    !angry_accuse
                    Someone who questions the Waterlogged Tomes! Have you no shame?
                player:
                    My shame's perfectly intact, but fine. Don't tell me how it works, then.
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                agent:
                    Well, it's a mixture of Salt Water, Lumin, some grains of sand and a whole heaping lot of "none of your business".
                player:
                    !crossed
                    I believe this is my business if you're going to inject something into my veins.
                agent:
                    And I believe in Hesh, and it's wrath will come down on you if you keep questioning this.
                player:
                    Ah, fine. Forget I asked.
            ]],
            OPT_REFUSE = "Refuse the vaccine",
            DIALOG_REFUSE = [[
                {asked_info?
                    player:
                        !hips
                        I don't think I'll be getting shot up with this vaccine you called "not consumer-friendly".
                    agent:
                        !angry_accuse
                        Do you wish for eternal damnation?
                    player:
                        Tough words for the Priest using deemed heretical tools to do holy work.
                    agent:
                        It's out of necces-
                    player:
                        Necessity to keep the voter base alive. Necessity to keep <i>your<\> voter base alive.
                    agent:
                        !point
                        I-
                        !sigh
                        I guess you're right. These are the tools of the enemies we're using.
                        Still, I wish you luck in not being infected.
                        !exit
                }
                {not asked_info?
                    player:
                        Put yourself in an official clinic instead of a side road and I'd do it.
                        But I'm not going to take the vaccine from a random priest.
                    agent:
                        And risk eternal damnation? What if you become infected?
                    player:
                        !shrug
                        Mind over matter, what can I say?
                    agent:
                        !angry
                        You'd better watch yourself, Grifter. Wouldn't want to go out at night without a scarf.
                        And not just because of the cold.
                        !exit
                }
                * {agent} leaves, leaving you contemplating if you made the right decision.
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                cxt:TalkTo(cxt:GetCastMember("priest"))
                cxt:Dialog("DIALOG_INTRO")
            end
            cxt:QST("ASK_INFESTATION")
            cxt:QST("ASK_VACCINE")

            if cxt.enc.scratch.asked_questions["OPT_ASK_VACCINE"] then
                cxt:Opt("OPT_CONVINCE")
                    :Dialog("DIALOG_CONVINCE")
                    :Negotiation{
                        on_start_negotiation = function(minigame)
                            -- for i = 1, 3 do
                            minigame:GetOpponentNegotiator():CreateModifier( "secret_intel", 1 )
                            -- end
                        end,
                        on_success = function(cxt, minigame)
                            local count = minigame:GetPlayerNegotiator():GetModifierStacks( "secret_intel" )
                            if count > 0 then
                                cxt:Dialog("DIALOG_CONVINCE_SUCCESS")
                                cxt.quest.param.asked_info = true
                            else
                                cxt:Dialog("DIALOG_CONVINCE_NO_INTEL")
                            end
                        end,
                        on_fail = function(cxt, minigame)
                            cxt:Dialog("DIALOG_CONVINCE_FAILURE")
                        end,
                    }
            end

            local current_health, max_health = TheGame:GetGameState():GetPlayerAgent():GetHealth()

            cxt:Opt("OPT_ACCEPT")
                :Dialog("DIALOG_ACCEPT")
                :DeltaHealth(math.max(-3, 1 - current_health))
                :Dialog("DIALOG_ACCEPT_PST")
                :Fn(function(cxt)
                    -- Gain a special perk or something
                    cxt.player.graft_owner:AddGraft( GraftInstance("perk_vaccinated") )

                    -- Unlocks vaccinated perk for future runs
                    TheGame:GetGameProfile():UnlockPerkWithoutPaying("perk_vaccinated")
                end)
                :Travel()
            if not cxt.quest.param.asked_info then
                cxt:Opt("OPT_REFUSE")
                    :Dialog("DIALOG_REFUSE")
                    :UpdatePoliticalStance("RELIGIOUS_POLICY", -2)
                    :ReceiveOpinion("refused_vaccine")
                    :Travel()
            else
                cxt:Opt("OPT_REFUSE")
                    :Dialog("DIALOG_REFUSE")
                    -- :UpdatePoliticalStance("RELIGIOUS_POLICY", -2)
                    -- :ReceiveOpinion("refused_vaccine")
                    :Travel()
            end
        end)
