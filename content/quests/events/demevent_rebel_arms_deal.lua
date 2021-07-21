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
            OPT_LEAVE = "Leave before anyone sees you",
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
                    Actually I won't, because I don't actually have money.
                jakes:
                    !left
                    You serious?
            ]],
            DIALOG_CONVINCE_PAY_FAILURE = [[
                rise:
                    [p] You are both enemies of the cause!
                    !exit
                * {rise} left, leaving you with {jakes}.
                jakes:
                    !right
                player:
                    Should I be worried?
                jakes:
                    I wouldn't. That one is not a threat to me.
                    Same might not be said about you.
                    Anyway, you got rid of the freeloader, so I should be greatful to you.
            ]],
            OPT_CONVINCE_DONATE = "Convince {jakes} to donate weapons to the cause",
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
                    [p] You are both enemies of the cause!
                    !exit
                * {rise} left, leaving you with {jakes}.
                jakes:
                    !right
                    Great! Now I lost a customer.
                    And I probably won't have any soon, now that you remind me of the truce deal.
                player:
                    I didn't make the deal. I merely participate in the system.
                jakes:
                    Oh yeah? Screw you too for ruining my business.
            ]],
            OPT_ARREST = "Ask {guard} to arrest them both for dealing with contrabands",
            DIALOG_ARREST = [[
                guard:
                    !right
                player:
                    !left
                    [p] Look at those guys.
                    Take them to the station, will ya?
                guard:
                    Thought you wouldn't ask.
                    !left
                rise:
                    !right
                guard:
                    Aight, just come with me and we will make this simpler for both of us.
                rise:
                    Dang it!
            ]],
        }