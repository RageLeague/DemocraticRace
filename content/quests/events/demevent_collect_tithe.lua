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
                    Your records must be wrong. I was told that I was exempt from the next round of tithes?
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
                    Vix gave me an exemption 
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
                agent:
                {not paid_all?
                    No one is exempt from tithes to hesh!
                    Pay for protection from Hesh's wrath.
                }
                {paid_all?
                    [p] That's not enough.
                    Looks like I'm gonna teach you a lesson!
                }
            ]],
            OPT_NO_PAY = "Refuse to pay",
            DIALOG_NO_PAY = [[
                player:
                    [p] I'm not going to pay!
                agent:
                    I'm just going to beat it out of you!
            ]],
            OPT_PAY_ALL = "Pay all you have",
            DIALOG_PAY_ALL = [[
                * You turn your pockets inside out, and scour every place you've kept money on your person.
                player:
                    !give
                * But you already know it's not enough, {agent} snatches it out of your hands, but the counting is more of a courtesy.
                agent:
                    !angry
                    Hesh grows tired each day of those who fail to pay their tithes.
                    Each day, it's sea grows deeper, and only those who actively walk in the shallows are to survive.
            ]],

            SIT_MOD_BAD = "You have evaded paying tithes for a ridiculously long time",
            SIT_MOD_PARTIAL = "You paid partial tithes",
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
                    [p] Let's dance!
            ]],
            DIALOG_DEFEND_WIN = [[
                {dead?
                    * It's a take from the poor, give to the rich world around here.
                    * However, by the rustling of your hands through the newly dead's pockets, it can sometimes be the other way around.
                }
                {not dead?
                    player:
                        [p] Well? Do you still want my tithe?
                    agent:
                        Fine! You can keep your money.
                        Know this: you made a grave enemy.
                    player:
                        Sure.
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
