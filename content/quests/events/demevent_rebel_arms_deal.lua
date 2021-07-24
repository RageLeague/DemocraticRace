local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}
:AddCast{
    cast_id = "rise",
    condition = function(agent, quest)
        return agent:GetFactionID() == "RISE"
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( quest:GetRank() < 3 and "RISE_REBEL" or "RISE_RADICAL") )
    end,
}
:AddCast{
    cast_id = "jakes",
    condition = function(agent, quest)
        return agent:GetFactionID() == "JAKES"
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( quest:GetRank() < 3 and "JAKES_RUNNER" or "JAKES_SMUGGLER") )
    end,
}
:AddOpinionEvents{
    bought_weapons_for_them =
    {
        delta = OPINION_DELTAS.MAJOR_GOOD,
        txt = "Bought weapons for them",
    },
    gifted_them_weapons =
    {
        delta = OPINION_DELTAS.MAJOR_GOOD,
        txt = "Gifted them weapons",
    },
}

QDEF:AddConvo()
    :ConfrontState("CONFRONT", function() return true end)
        :Loc{
            DIALOG_INTRO = [[
                * [p] You encountered two people arguing.
                rise:
                    !left
                jakes:
                    !right
                    No! You can't have those weapons unless you pay for them!
                rise:
                    But this is for the cause!
                jakes:
                    Your cause doesn't pay the bills!
                * Wow, a conflict. Looks like a good time to intervene.
            ]],
            OPT_LEAVE = "Leave them figure this out themselves",
            DIALOG_LEAVE = [[
                * [p] Or not. You do you.
            ]],
            OPT_CONVINCE_PAY = "Convince {rise} to pay up",
            DIALOG_CONVINCE_PAY = [[
                rise:
                    !right
                player:
                    !left
                    [p] Yo, pay the Jake.
            ]],
            DIALOG_CONVINCE_PAY_SUCCESS = [[
                player:
                    [p] Surely you are not actually a Spree?
                rise:
                    Perish the thought!
                    Okay, I will pay.
                {no_money?
                    Actually I won't, because I don't actually have money.
                jakes:
                    !left
                    You serious?
                }
                {not no_money?
                jakes:
                    !right
                rise:
                    !left
                    !give
                    Here you go. Money for your weapons.
                jakes:
                    Glad we can do business.
                rise:
                    !exit
                * {rise} leaves with the weapons.
                player:
                    !left
                jakes:
                    Thank you grifter for helping me conduct the sale.
                }
            ]],
            DIALOG_CONVINCE_PAY_FAILURE = [[
                rise:
                    [p] You are both enemies of the cause!
                    !exit
                * {rise} left, leaving you with {jakes}.
                jakes:
                    !right
                    Great, just as I thought I get a potential customer.
            ]],
            OPT_CONVINCE_DONATE = "Convince {jakes} to donate weapons to the cause",
            SIT_MOD_NO_DONATE = "That's now how business works.",
            DIALOG_CONVINCE_DONATE = [[
                jakes:
                    !right
                player:
                    !left
                    [p] Consider the favors you are going to earn from the Rise.
            ]],
            DIALOG_CONVINCE_DONATE_SUCCESS = [[
                jakes:
                    [p] Wow, didn't realize I'm dealing with two annoying people here.
                    Just take these weapons.
                    I expect you to owe me some favors.
                rise:
                    !left
                    Of course. The Rise helps all its allies.
                player:
                    !left
                rise:
                    !right
                    Thanks you, grifter.
            ]],
            DIALOG_CONVINCE_DONATE_FAILURE = [[
                jakes:
                    [p] This isn't a charity, you know.
                    I'm insulted to think that you think that would work.
            ]],
            OPT_CONVINCE_CALL_OFF = "Convince {rise} to call off the deal",
            DIALOG_CONVINCE_CALL_OFF = [[
                rise:
                    !right
                player:
                    !left
                    [p] You should not do that.
            ]],
            DIALOG_CONVINCE_CALL_OFF_SUCCESS = [[
                player:
                    [p] We literally have the truce deal for this.
                    Just vote, bro.
                    Weapons aren't necessary.
                rise:
                    Oh wow you're right!
                    Imma vote now!
                    !exit
                * {rise} left.
                jakes:
                    !right
                    Well, the freeloader left.
                    Although what you said reminds me how I'm not going to make money of weapons now.
                player:
                    Yeah that might be a problem.
            ]],
            DIALOG_CONVINCE_CALL_OFF_FAILURE = [[
                rise:
                    [p] No! Revolution needs weapons!
                    !left
                jakes:
                    !right
                rise:
                    And we must all work together to overthrow this corrupt system!
                    Wouldn't you agree?
                jakes:
                    Uh, we are back to square one.
                player:
                    !left
                jakes:
                    What are you trying to pull here, grifter?
                    Trying to put me out of business?
            ]],
            OPT_ARREST = "Confront them about dealing with contraband...",
            DIALOG_ARREST = [[
                jakes:
                    !right
                player:
                    !left
                    [p] Say, buddy chum friend pal amigo buddy.
                    Selling weapons seems very illegal, don't you agree?
                jakes:
                {high_admiralty_support?
                    And I suppose our friend of the switches doesn't like it?
                }
                {not high_admiralty_support?
                    Oh yeah? What's it to you?
                }
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()

                if cxt.quest.param.no_money == nil then
                    cxt.quest.param.no_money = math.random() < 0.5
                end

                cxt:Dialog("DIALOG_INTRO")
            end

            cxt:BasicNegotiation("CONVINCE_PAY", {
                target_agent = cxt:GetCastMember("rise"),
                helpers = {"jakes"},
            })
                :OnSuccess()
                    :Fn(function(cxt)
                        if cxt.quest.param.no_money then
                            cxt:GoTo("STATE_PAY")
                        else
                            cxt:GetCastMember("jakes"):OpinionEvent(OPINION.HELP_COMPLETE_DEAL)
                            StateGraphUtil.AddLeaveLocation()
                        end
                    end)

                :OnFailure()
                    :Fn(function(cxt)
                        cxt:GetCastMember("rise"):OpinionEvent(OPINION.DISLIKE_IDEOLOGY)
                        cxt:GetCastMember("rise"):OpinionEvent(OPINION.DISLIKE_IDEOLOGY, nil, cxt:GetCastMember("jakes"))
                    end)
                    :Travel()

            cxt:Opt("OPT_CONVINCE_DONATE")
                :Dialog("DIALOG_CONVINCE_DONATE")
                :UpdatePoliticalStance("LABOR_LAW", 2)
                :Negotiation{
                    target_agent = cxt:GetCastMember("jakes"),
                    helpers = {"rise"},
                    situation_modifiers = {
                        { value = 5 + 5 * cxt.quest:GetRank(), text = cxt:GetLocString("SIT_MOD_NO_DONATE") }
                    },
                }
                    :OnSuccess()
                        :Dialog("DIALOG_CONVINCE_DONATE_SUCCESS")
                        :Fn(function(cxt)
                            cxt:GetCastMember("rise"):OpinionEvent(OPINION.APPROVE)
                            cxt:GetCastMember("rise"):OpinionEvent(OPINION.APPROVE, nil, cxt:GetCastMember("jakes"))
                        end)
                        :Travel()
                    :OnFailure()
                        :Dialog("DIALOG_CONVINCE_PAY_FAILURE")
                        :Fn(function(cxt)
                            cxt:GetCastMember("jakes"):OpinionEvent(OPINION.SUGGEST_UNREASONABLE_REQUEST)
                        end)

            cxt:BasicNegotiation("CONVINCE_CALL_OFF", {
                target_agent = cxt:GetCastMember("rise"),
                hinders = {"jakes"},
            })
                :OnSuccess()
                    :DeltaSupport(10)
                    :Travel()
                :OnFailure()
                    :Fn(function(cxt)
                        cxt:GetCastMember("jakes"):OpinionEvent(OPINION.ATTEMPT_TO_RUIN_BUSINESS)
                    end)

            cxt:Opt("OPT_ARREST")
                :Dialog("DIALOG_ARREST")
                :GoTo("STATE_ARREST")

            cxt:Opt("OPT_LEAVE")
                :Dialog("DIALOG_LEAVE")
                :Travel()
        end)
    :State("STATE_PAY")
        :Loc{
            DIALOG_LEAVE = [[
                player:
                    !left
                rise:
                    !right
                player:
                    [p] Well, maybe before you want to buy weapons, get the money for it.
                rise:
                    I suppose you are right.
                    Now where am I going to find the weapons now?
                    !exit
                * {rise} leaves, leaving you with {jakes}.
                jakes:
                    !right
                    Wow, that was something.
            ]],
            OPT_PAY = "Pay for {rise}",
            DIALOG_PAY = [[
                rise:
                    !right
                player:
                    !left
                    [p] You know what, I'll spot for you.
                rise:
                    Really?
                player:
                    Don't question it.
                jakes:
                    !right
                    Wait, you are letting {rise.heshe} get what {rise.heshe} wants without paying?
                player:
                    !give
                    You get the money either way, right? Don't question it.
                jakes:
                    !take
                    Ah, sure. Thank you for your business.
            ]],
            OPT_DONATE = "Donate some weapons",
            DIALOG_DONATE = [[
                rise:
                    !right
                player:
                    !left
                    [p] Here, have some weapons for your cause.
                    rise:
                    Really?
                player:
                    Don't question it.
                jakes:
                    !right
                    Wait, you are letting {rise.heshe} get what {rise.heshe} wants without paying?
                player:
                    {rise.HeShe} isn't paying anything either way, right? There is no loss to you.
                jakes:
                    I suppose.
            ]],

            SELECT_TITLE = "Select a card",
            SELECT_DESC = "Choose a weapon card to donate to {rise}.",
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt:TalkTo(cxt:GetCastMember("jakes"))
            end

            local cards = {}
            for i, card in ipairs(cxt.player.battler.cards.cards) do
                print(card.id)
                if DemocracyUtil.IsWeapon(card) then
                    table.insert(cards, card)
                end
            end

            cxt:Opt("OPT_PAY")
                :DeliverMoney( 150, { is_shop = true } )
                :Dialog("DIALOG_PAY")
                :ReceiveOpinion("bought_weapons_for_them", nil, "rise")
                :ReceiveOpinion(OPINION.HELP_COMPLETE_DEAL, nil, "jakes")
                :UpdatePoliticalStance("LABOR_LAW", 2)
                :Travel()

            if #cards > 0 then
                cxt:Opt("OPT_DONATE")
                    :ReceiveOpinion("gifted_them_weapons", {only_show = true}, "rise")
                    :ReceiveOpinion(OPINION.RID_ANNOYING_CUSTOMER, {only_show = true}, "jakes")
                    :UpdatePoliticalStance("LABOR_LAW", 2, nil, nil, true)
                    :Fn(function(cxt)
                        cxt:Wait()
                        DemocracyUtil.InsertSelectCardScreen(
                            cards,
                            cxt:GetLocString("SELECT_TITLE"),
                            cxt:GetLocString("SELECT_DESC"),
                            Widget.BattleCard,
                            function(card)
                                cxt.enc:ResumeEncounter( card )
                            end
                        )
                        local card = cxt.enc:YieldEncounter()
                        if card then
                            cxt.player.battler:RemoveCard( card )
                            cxt:Dialog("DIALOG_DONATE")

                            cxt:GetCastMember("rise"):OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("gifted_them_weapons"))
                            cxt:GetCastMember("jakes"):OpinionEvent(OPINION.RID_ANNOYING_CUSTOMER)

                            DemocracyUtil.TryMainQuestFn("UpdateStance", "LABOR_LAW", 2)

                            StateGraphUtil.AddLeaveLocation(cxt)
                        end
                    end)
            end

            cxt:Opt("OPT_LEAVE")
                :MakeUnder()
                :Dialog("DIALOG_LEAVE")
                :ReceiveOpinion(OPINION.RID_ANNOYING_CUSTOMER, nil, "jakes")
                :Travel()
        end)
