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
QDEF:AddConvo()
    :ConfrontState("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You are interrupted by some guy in the Cult.
                player:
                    !left
                agent:
                    !right
                    Yo, you haven't been paying your tithe for about eleven years.
                    Pay up or face the wrath of Hesh.
            ]],
            OPT_PAY = "Pay the tithe".
            DIALOG_PAY = [[
                player:
                    [p] Alright, here is your tithe.
                agent:
                    Wow, that was easy.
            ]],
            OPT_CONVINCE_EXEMPT = "Convince {agent} to leave you alone",
            DIALOG_CONVINCE_EXEMPT = [[
                player:
                {not paid_all?
                    [p] You see, I am exempt.
                agent:
                    You what?
                }
                {paid_all?
                    [p] Come on I already give you everything.
                }
            ]],
            DIALOG_CONVINCE_EXEMPT_SUCCESS = [[
                agent:
                {not paid_all?
                    [p] If you say so.
                    Too lazy to bother to check.
                }
                {paid_all?
                    [p] You are right this convo is pointless.
                }
                    Have a nice day.
            ]],
            DIALOG_CONVINCE_EXEMPT_FAILURE = [[
                agent:
                {not paid_all?
                    [p] Nah, everyone pays tithes.
                    Now pay up!
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
                player:
                    [p] Here, this is all I have.
                    I physically can't give you more.
                agent:
                    Yeah that's not enough.
                    Seems we will teach you a lesson here.
            ]],

            SIT_MOD_BAD = "You have evaded paying tithes for a ridiculously long time",
            SIT_MOD_PARTIAL = "You paid partial tithes",
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                cxt.enc.scratch.opfor = CreateCombatParty("ADMIRALTY_PATROL", cxt.quest:GetRank() + 1, cxt.location, true)
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
                    * [p] Well, I guess you are exempt after all.
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