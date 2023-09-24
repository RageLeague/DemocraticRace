local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    cooldown = EVENT_COOLDOWN.LONG,
    icon = engine.asset.Texture("icons/quests/event_loan_shark.tex"),
    precondition = function(quest)
        return TheGame:GetGameState():GetPlayerAgent():GetMoney() <= 200
    end,
}

--------------------------------------------------------------------

QDEF:AddConvo()
    :ConfrontState("CONF", function(cxt) return cxt.location:HasTag("in_transit") end)
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
            * You are approached by a merchant wearing expensive clothing.
            agent:
                !right
                Why hello, dear grifter.
                You look like you could use some money.
            player:
                I do find myself low on funds, currently.
            agent:
                I'm prepared to offer you a loan. Just a little something to get you back on your feet.
                My terms are quite reasonable!
        ]],

        OPT_TAKE_OFFER = "Take {1} now, and agree to pay back {3} tomorrow ({2#percent} interest)",
        DIALOG_TAKE_OFFER = [[
            player:
                I can agree to those terms.
            agent:
                Excellent!
                !give
                Take the money, and use it follow your dreams!
                Just be ready to pay it back when I come calling tomorrow, or I'll be forced to resort to... regrettable methods to recover my losses.
                !exit
        ]],

        OPT_NEGOTIATE_BETTER_RATE = "Negotiate for a better rate ({1#percent})",
        DIALOG_NEGOTIATE_BETTER_RATE = [[
            player:
                I'm interested, but I'll need a better rate.
        ]],
        DIALOG_WON_BETTER_RATE = [[
            agent:
                Just for you, I can offer better terms. Let's say... {1#percent}.
        ]],
        DIALOG_LOST_BETTER_RATE = [[
            agent:
                My terms are my terms, grifter. You may take them, or go starve in a gutter, for all I care.
        ]],

        OPT_DECLINE = "Decline the offer",
        DIALOG_DECLINE = [[
            player:
                I'm doing just fine on my own, thank you.
            agent:
                That's a shame. I truly hope you don't live to regret this decision.
                !exit
            * {agent} leaves.
        ]]
    }
    :Fn(function(cxt)

        cxt.quest:Complete()

        cxt.quest.param.lender = AgentUtil.GetFreeAgent("WEALTHY_MERCHANT", function(agent) return agent:GetRelationship() == RELATIONSHIP.NEUTRAL and not AgentUtil.HasJob(agent) end)
        -- cxt.quest.param.goons = CreateCombatBackup(cxt.quest.param.lender, "MERCENARY_BACKUP", cxt.quest:GetRank()+1 )

        cxt:TalkTo(cxt.quest.param.lender)
        local OFFER_1 = 250
        local OFFER_2 = 500

        local GOOD_RATE = .25
        local BAD_RATE = .5
        cxt.quest.param.rate = BAD_RATE

        cxt:Dialog("DIALOG_INTRO")

        cxt:RunLoop(function(cxt)

            local PAYBACK_1 = math.floor( OFFER_1*(1+cxt.quest.param.rate) )
            local PAYBACK_2 = math.floor( OFFER_2*(1+cxt.quest.param.rate) )

            cxt:Opt("OPT_NEGOTIATE_BETTER_RATE", GOOD_RATE)
                :Dialog("DIALOG_NEGOTIATE_BETTER_RATE")
                :Negotiation{}
                    :OnSuccess()
                        :Dialog("DIALOG_WON_BETTER_RATE", GOOD_RATE)
                        :Fn(function() cxt.quest.param.rate = GOOD_RATE end)
                    :OnFailure()
                        :Dialog("DIALOG_LOST_BETTER_RATE")

            cxt:Opt("OPT_TAKE_OFFER", OFFER_1, cxt.quest.param.rate, PAYBACK_1)
                :Dialog("DIALOG_TAKE_OFFER")
                :ReceiveMoney(OFFER_1, {no_scale = true})
                :Fn(function() QuestUtil.SpawnQuest("DEMEVENT_LOAN_SHARK_REPAY", {cast = {lender = cxt:GetAgent() },parameters = { amt_owed = PAYBACK_1 } }) end)
                :Travel()

            cxt:Opt("OPT_TAKE_OFFER", OFFER_2, cxt.quest.param.rate, PAYBACK_2)
                :Dialog("DIALOG_TAKE_OFFER")
                :ReceiveMoney(OFFER_2, {no_scale = true})
                :Fn(function() QuestUtil.SpawnQuest("DEMEVENT_LOAN_SHARK_REPAY", {cast = {lender = cxt:GetAgent() },parameters = { amt_owed = PAYBACK_2 } }) end)
                :Travel()

            cxt:Opt("OPT_DECLINE")
                :Dialog("DIALOG_DECLINE")
                :Travel()
        end)
    end)
