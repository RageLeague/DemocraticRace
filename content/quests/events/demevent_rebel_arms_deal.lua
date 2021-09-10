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
                * You would think trying to sell contraband requires you be quiet. Hush Hush. Generally not try to draw attention.
                * Either the Jake is new at the job or the Professional Rabble Rouser wants {jakes.hisher} manager.
                jakes:
                    !right
                rise:
                    !left
                    Are you against Democracy itself? We need the weaponry to protect our revolution!
                jakes:
                    Democracy isn't going to pay the customs fees! This is still a capitalist society, and you still need to pay!
                rise:
                    !spit
                    Bah! That's just bougeroise rhetoric.
                jakes:
                    !angryshrug
                    Bougeroise? I'm just as poor as the lot of you. Should <i>I<\> starve just so your little revolution has a few more playthings?
                rise:
                    This isn't a game, {jake}. This is real life, and real sacrifice needs to be made for real change!
                * You have a sneaking suspicion the next logical step for this conflict would involve someone getting shot.  
            ]],
            OPT_LEAVE = "Leave them figure this out themselves",
            DIALOG_LEAVE = [[
                * You pace a bit faster.
                * The last sound you hear of their squabble is the discharge of a lumin blaster.
            ]],
            OPT_CONVINCE_PAY = "Convince {rise} to pay up",
            DIALOG_CONVINCE_PAY = [[
                rise:
                    !right
                player:
                    !left
                    This is unorderly and you know it.
            ]],
            DIALOG_CONVINCE_PAY_SUCCESS = [[
                player:
                    Well now, I never knew the Rise started hiring from Spree.
                rise:
                    !taken_aback
                    Spree?
                player:
                    Well, this appears to be the Spree's general MO. 
                    I bet you have an entire crew just waiting for their chance, just like-
                rise:
                    !placate
                    Alright, alright, I get the memo and then some.
                {no_money?
                * {rise} hands {jakes} a paltry sum of bills, who keeps a firm hand on top of the merchandise.
                * What {jakes} returns to {rise} isn't a box of weapons, but an irritated glare.
                jakes:
                    !left
                    This doesn't even cover half of the cost. What kind of scam are you pulling on me?
                rise:
                    !placate
                    Well, look. We hoped that you'd be willing to trade-
                jakes:
                    "We"? Whose this "We" in this?
                    How accurate was that Grifter about you being a former Spree?
                rise:
                    !palm
                    Look, I just don't have the cash on hand.
                }
                {not no_money?
                jakes:
                    !right
                rise:
                    !left
                    !give
                * {rise} coughs out a wad of shills larger than some bounties you've bagged and placed it in {jake}'s hand.
                jakes:
                    !take
                    Now why couldn't we have started with this, hm?
                rise:
                    Because for a second I thought you Jakes could care about something bigger than yourselves.
                    !exit
                jakes:
                    Ha! No bigger business than contraband.
                player:
                    !left
                jakes:
                    Say, thank you {player}. Getting hassled like that doesn't get any easier with the job.
                player:
                    Just gets louder, doesn't it.
                jakes:
                    !chuckle
                    Yeah, but anyone smart enough to play this game has a strong arm.
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
            SIT_MOD_NO_DONATE = "That's not how business works.",
            DIALOG_CONVINCE_DONATE = [[
                jakes:
                    !right
                player:
                    !left
                    You know, I shifted some contraband once as a Grifter. Believe me, favors with others goes a long way.
            ]],
            DIALOG_CONVINCE_DONATE_SUCCESS = [[
                player:
                    Don't know if you're aware, but this is a democractic Havaria now.
                    !over_there
                    And these guys? They've got "Democracy" tattooed across their foreheads.
                rise:
                    It's true, actually! I have a big tattoo that says-
                jakes:
                    !flinch
                    Ah, alright, I get it.
                rise:
                    !right
                jakes:
                    !point
                    You. What's your name again?
                rise:
                    !salute
                    {rise}, {jakes.honorific}.
                jakes:
                    Right, right. Listen, the next time I need a favor from the Rise, i'm gonna name drop you.
                    And if I don't get what i'm asking for, i'll be cutting a few of your strings, got it?
                rise:
                    Er, yes. In the calmer sense of the phrase.
                jakes:
                    !crossed
                    I guess we have a deal, then.
                * With that barbed experience, {jakes} slides a few boxes of weaponry into the hands of {rise} before stomping away.
                rise:
                    Not how I would've liked the deal to go by, but the weapons seem good.
            ]],
            DIALOG_CONVINCE_DONATE_FAILURE = [[
                jakes:
                    Well, the problem is all those weapons cost a lot more than any quick favors can pay for.
                    So unless these Rise favors comes in cash or debit, i'm going to retract from the deal.
            ]],
            OPT_CONVINCE_CALL_OFF = "Convince {rise} to call off the deal",
            DIALOG_CONVINCE_CALL_OFF = [[
                rise:
                    !right
                player:
                    !left
                    This the one hassling your haggle?
                rise:
                    Yeah! All I want are some authentic weaponry and a bit of enthusiasm for the cause.
                player:
                    Well, stick-in-the-mud here might leave you barking up the wrong tree.
            ]],
            DIALOG_CONVINCE_CALL_OFF_SUCCESS = [[
                player:
                    I could list off several other smugglers who'll charge you a dime on the dollar {jakes} is charging you.
                rise:
                    Really? 
                player:
                    For sure! And that oughta lead to a competitive price from {jakes} later on, if you still want to use {jakes.himher}.
                rise:
                    You make a bit of sense, yeah.
                    Well, I guess I can go see some of these other options
                    !exit
                * With that, {rise} walks off, leaving {jakes} in a state of irritation and awe.
                jakes:
                    Now what was that all about, scaring off good business?
                player:
                    Ah, calm down. Do you really think they'll be chasing their tails for those "other options" for long?
                jakes:
                    Who did you refer them to, exactly?
                player:
                    A nobody. They'll be lucky if they could mug the weapon off of this "esteemed weapons dealer".
                    The Rise'll be eating out of the palm of your hand soon enough.
            ]],
            DIALOG_CONVINCE_CALL_OFF_FAILURE = [[
                player:
                    We don't need weapons anymore. You can put them down, because we're entering a democracy now.
                rise:
                    Well, I guess that-
                jakes:
                    !point
                    Wait, you guys need to protect Democracy or something.
            ]],
            OPT_ARREST = "Confront them about dealing with contraband...",
            DIALOG_ARREST = [[
                jakes:
                    !right
                player:
                    !left
                * You tut into the middle of them with a gait you learned from watching out for admiralty patrols back in your bounty hunting days.
                * Ironic the same trick works on the correct side of the law as well.
                player:
                    Big box of weapons you got there, {jakes}.
                jakes:
                    Yeah it is. And this schlep's trying to get them for pennies on the dollar.
                {high_admiralty_support?
                player:
                    Hm. I happen to know a few people who'd want these going through the proper customs.
                jakes:
                    Hey, I paid my customs fees! The admiralty got their cut of this deal already.
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
                cxt.quest.param.high_admiralty_support = DemocracyUtil.GetFactionEndorsement("ADMIRALTY") > RELATIONSHIP.NEUTRAL

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
                        :Dialog("DIALOG_CONVINCE_DONATE_FAILURE")
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

            if not cxt.quest.param.did_confront then
                cxt:Opt("OPT_ARREST")
                    :Dialog("DIALOG_ARREST")
                    :GoTo("STATE_ARREST")
            end

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
                    !sigh
                    The Rise really are in dire straits, I see.
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
    :State("STATE_ARREST")
        :Loc{
            DIALOG_BACK = [[
                player:
                {tried_intimidate?
                    I'm just kidding, of course.
                jakes:
                    Your terrible sense of humor is not appreciated.
                }
                {not tried_intimidate?
                    I'm just saying. You don't want the wrong person to see you do this stuff.
                jakes:
                    Tell me something I didn't know already.
                }
            ]],
            OPT_INTIMIDATE = "Intimidate them",
            DIALOG_INTIMIDATE = [[
                player:
                    Well, you see. The Admiralty just called.
                    They want just a bit bigger of a cut.
            ]],
            DIALOG_INTIMIDATE_SUCCESS = [[
                player:
                    It's a few days in the bin, nothing you can't handle.
                    And who knows? Maybe you and {rise} will get a bit closer that way.
                jakes:
                    You're right on one thing, Switch. It'll be a few days in the bin for me. Got the contacts to get out.
                    !over_there
                    You though. Maybe this'll teach you some manners on how to conduct business.
                rise:
                    But...but the elect-
                player:
                    The election is specifcally so we don't need radicals like you with weapons like those.
            ]],
            DIALOG_INTIMIDATE_FAILURE = [[
                jakes:
                    [p] Yeah? What are you going to do about it?
                    Your whining doesn't give you power to arrest people, you know?
                * {jakes.HeShe}'s right, you know.
            ]],
            OPT_ARREST = "Arrest them with force",
            DIALOG_ARREST = [[
                {tried_intimidate?
                    * You brandish your weapon with a gleam.
                player:
                    !sigh
                    Criminals. Can't live with them, can't live without them.
                rise:
                    !right
                    You're the real criminal here! Viva la Rise!
                }
                {not tried_intimidate?
                    [p] You are both under arrest!
                jakes:
                    Oh we are doing this, huh?
                }
            ]],
            DIALOG_ARREST_WIN = [[
                {jakes_dead?
                    {rise_dead?
                        * [p] Knowing that you killed two criminals makes you proud.
                        * Their friends are not going to like you, and it puts the legitimacy of your campaign into question.
                        * You left the scene.
                    }
                    {not rise_dead?
                        rise:
                            !right
                            !injured
                        * {rise} scrambles for the boxes, prying one open with the deftness of a safe cracker.
                        *{rise.HisHer} awareness, however, could use some work. You grab {rise.hisher} arms before clapping {agent.hisher} fists in a pair of restraints.
                        rise:
                            So i'm leading a life of Martyrdom, now? It'll be a great way to go out, y'know.
                        player:
                            Reason it out however you want. If it helps you sleep tonight, hey, i'm fine with you babbling into thin air.
                            But just remember you signed up for this.
                        * It doesn't take long for the next Admiralty Patrol to round the corner. You shove {rise} into the hands of an oncoming guard before treking right behind them.
                    }
                }
                {not jakes_dead?
                    {rise_dead?
                        jakes:
                            !injured
                            [p] You bastard!
                            Look at what you've done!
                        player:
                            This one resisted arrest.
                            It's not my fault.
                            Come quietly or you will suffer the same fate.
                        * You send the jakes to the nearest Admiralty patrol.
                    }
                    {not rise_dead?
                        jakes:
                            !injured
                        player:
                            It's going to be a long night behind bars for you this evening.
                        * {jakes} casts an ire filled glance at {rise}.
                        rise:
                            !left
                        jakes:
                            Yeah, same goes for you. You're going to remember this and pass on what happens when you make business difficult to the rest of your friends.
                        rise:
                            But-but I planned-
                        player:
                            "Plans rarely survive contact with the enemy". Did you know that quote, or did you not know how to read the fine print before tonight?
                        * With both your prisoners in tow, the orbitting Admiralty Patrol that passes these parts quickly becomes two criminals fuller.
                    }
                }
            ]],
            OPT_USE_BODYGUARD = "Let a bodyguard arrest them...",
            DIALOG_USE_BODYGUARD = [[
                player:
                    [p] Well, you see...
                * You gesture {guard}?
                jakes:
                    What? Where did that switch came from?
                guard:
                    !left
                    You are really unobservant, are you?
                    Anyway, you are coming with me!
                * {guard} took them away.
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest.param.did_confront = true
            end

            local function DoArrest(cxt, hate_target)
                if cxt:GetCastMember("rise"):IsAlive() then
                    cxt:GetCastMember("rise"):GainAspect("stripped_influence", 5)
                    cxt:GetCastMember("rise"):OpinionEvent(OPINION.SOLD_OUT_TO_ADMIRALTY, nil, hate_target)
                    cxt:GetCastMember("rise"):Retire()
                end
                if cxt:GetCastMember("jakes"):IsAlive() then
                    cxt:GetCastMember("jakes"):GainAspect("stripped_influence", 5)
                    cxt:GetCastMember("jakes"):OpinionEvent(OPINION.SOLD_OUT_TO_ADMIRALTY, nil, hate_target)
                    cxt:GetCastMember("jakes"):Retire()
                end
                DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 10)
                DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 10, "ADMIRALTY")
            end

            cxt:Opt("OPT_INTIMIDATE")
                :Dialog("DIALOG_INTIMIDATE")
                :UpdatePoliticalStance("SECURITY", 2)
                :Negotiation{
                    target_agent = cxt:GetCastMember("jakes"),
                    flags = NEGOTIATION_FLAGS.ALLY_SCARE | NEGOTIATION_FLAGS.INTIMIDATION,
                    fight_allies = {cxt:GetCastMember("rise")},
                }
                    :OnSuccess()
                        :Dialog("DIALOG_INTIMIDATE_SUCCESS")
                        :Fn(function(cxt)
                            DoArrest(cxt)
                        end)
                        :Travel()
                    :OnFailure()
                        :Dialog("DIALOG_INTIMIDATE_FAILURE")
                        :Fn(function(cxt)
                            cxt.quest.param.tried_intimidate = true
                        end)

            cxt:Opt("OPT_ARREST")
                :UpdatePoliticalStance("SECURITY", 2)
                :Dialog("DIALOG_ARREST")
                :Battle{
                    enemies = {cxt:GetCastMember("jakes"), cxt:GetCastMember("rise")},
                }
                    :OnWin()
                        :Fn(function(cxt)
                            cxt.quest.param.jakes_dead = cxt:GetCastMember("jakes"):IsDead()
                            cxt.quest.param.rise_dead = cxt:GetCastMember("rise"):IsDead()
                            cxt:Dialog("DIALOG_ARREST_WIN")
                            DoArrest(cxt)
                        end)
                        :Travel()

            DemocracyUtil.AddBodyguardOpt(cxt, function(cxt, agent)
                cxt:ReassignCastMember("guard", agent)
                cxt:Dialog("DIALOG_USE_BODYGUARD")
                agent:Dismiss()
                DoArrest(cxt, agent)
                StateGraphUtil.AddLeaveLocation(cxt)
            end, nil, function(agent) return agent:GetFactionID() == "ADMIRALTY" end)

            cxt:Opt("OPT_BACK_BUTTON")
                :Dialog("DIALOG_BACK")
                :Pop()
                :MakeUnder()
        end)
