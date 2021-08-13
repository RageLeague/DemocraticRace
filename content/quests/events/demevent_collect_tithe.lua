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
                }
                {paid_all?
                    [p] That's not enough.
                }
                    Now pay up!
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

        }
        :Fn(function(cxt)

        end)