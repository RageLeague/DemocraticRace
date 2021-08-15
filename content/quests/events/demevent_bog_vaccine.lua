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
                * [p] You are interrupted by a priest.
                player:
                    !left
                agent:
                    !right
                    Stop right there!
                    There is a bog infestation in the Pearl, and all citizens of the Pearl must get vaccinated against it.
            ]],
            OPT_ASK_INFESTATION = "Ask about the infestation",
            DIALOG_ASK_INFESTATION = [[
                player:
                    How did the bog parasites get in the Pearl?
                agent:
                    As part of the truce deal, every heretic is allowed in the Pearl apparently.
                    And some boggers brought their filth into the Pearl.
                    We plan to stop the infestation at its root before it becomes an epidemic.
                player:
                    What are the consequences of catching the parasite?
                agent:
                    It would be a disgrace to Hesh itself.
                    And you will probably die horribly. But that is less important than the insult to Hesh.
            ]],
            OPT_ASK_VACCINE = "Ask about the vaccine",
            DIALOG_ASK_VACCINE = [[
                player:
                    What is this vaccine you speak of?
                agent:
                    It is a preemptive measure to the bog infestation.
                    Once you are innoculated, you are guaranteed to never get infected by the parasite.
                    It is 100% reliable.
                    Although it has a temporary side effect that won't be pleasant.
                    But that is a small price to pay for salvation.
            ]],
            OPT_ACCEPT = "Accept the vaccine",
            DIALOG_ACCEPT = [[
                player:
                    [p] Alright, let me have it.
                agent:
                    Hesh thank you for your cooperation.
                * You roll up your sleeve and let the priest innoculate you.
                * The process is kind of painful.
            ]],
            DIALOG_ACCEPT_PST = [[
                player:
                    Ow.
                agent:
                    Don't be such a crybaby. It's nothing compared to the eternal damnation if you refuse.
                    Anyway, just take some rest, and try not to work yourself too hard.
                    You should be immune to bog parasites very soon.
                    Anyway, see you!
                    !exit
                * The priest leaves you be.
            ]],
            OPT_CONVINCE = "Question {agent} about the source of the vaccine",
            DIALOG_CONVINCE = [[
                player:
                    [p] Where did you find the vaccine?
                agent:
                    Excuse me?
                player:
                    This infestation wasn't in the pearl for long, but there is already a vaccine for it.
                    Surely you don't find that suspicious?
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                agent:
                    [p] Will you shut up if I tell you?
                player:
                    Let's hear it.
                agent:
                    !sigh
                    When we found out about the infestation, the cult starts to panic.
                    Then, one of us noted that the Barons have worked in the bog for a long time, and surely they have a solution.
                    So we "acquired" the vaccine from them.
                player:
                    Uh huh.
                agent:
                    Anyway, where it comes from doesn't matter.
                    What matters is that you take the vaccine, lest you get infected by the bog.
            ]],
            DIALOG_CONVINCE_NO_INTEL = [[
                agent:
                    [p] Hesh has an unnatural ability to find a solution to deal with the threat.
                    Is it that hard to believe?
                player:
                    Well...
                agent:
                    There you have it.
                    That is the answer to where this vaccine comes from.
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                player:
                    [p] Look, I'm just asking the questions.
                agent:
                    Do you doubt Hesh's ability to produce a countermeasure to its threat quickly?
                player:
                    Well, I-
                agent:
                    I suggest you ask no further if you don't wish to insult Hesh itself.
            ]],
            OPT_REFUSE = "Refuse the vaccine",
            DIALOG_REFUSE = [[
                {asked_info?
                    player:
                        [p] You call yourself a priest, yet you use the tools of the spark.
                        Have you no honor? No faith in the Cult?
                    agent:
                        I- I assure you, my faith perfectly fine.
                    player:
                        Then you should know not to inject the heretic's product into someone's body.
                    agent:
                        Alright then. Have it your way.
                        Just be careful not to get infected by the bog.
                        !exit
                }
                {not asked_info?
                    player:
                        [p] I am not going to take the vaccine!
                        You have no right to force it upon me!
                    agent:
                        You and your rights!
                        You are willing to risk eternal damnation to defend it?
                        Fine, have it your way then.
                        Watch your back, grifter.
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

            if cxt.enc.scratch.asked_questions["ASK_VACCINE"] then
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