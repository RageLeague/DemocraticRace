local function CanFeed(agent, quest)
    return not (AgentUtil.IsInHiding(agent) or agent:IsRetired() or agent:IsInPlayerParty()
        or AgentUtil.HasPlotArmour(agent) or not agent:IsSentient())
        and not agent:HasQuestMembership()
        and not (quest.param.gifted_people and table.arraycontains(quest.param.gifted_people, agent))
        and not (quest.param.rejected_people and table.arraycontains(quest.param.rejected_people, agent))
end

local QDEF = QuestDef.Define{
    title = "Dole out",
    desc = "Give Bread to the poor to gain support.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/dole_out.png"),

    qtype = QTYPE.SIDE,
    rank = {2, 5},
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"RALLY_JOB"},
    reward_mod = 0,

    on_start = function(quest)
        quest:Activate("dole_out_three")
        quest:Activate("buy_loaves")
        quest:Activate("time_countdown")
        quest:Activate("request_funds")
    end,

    on_complete = function(quest)
        -- if quest.param.poor_performance then
        --     DemocracyUtil.DeltaGeneralSupport(2 * #quest.param.posted_location, "POOR_QUEST")
        -- else
        local score = 3 * (quest.param.gifted_people and #quest.param.gifted_people or 0)
        DemocracyUtil.DeltaGeneralSupport(score, "COMPLETED_QUEST")
        -- end
    end,

    precondition = function(quest)
        return TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor")
    end,
}
:AddObjective{
    id = "go_to_advisor",
    title = "Wait for the votes to roll in",
    desc = "You've run out of time. Time to check in with your advisor.",
    mark = {"primary_advisor"},

    on_activate = function(quest)
        if quest:IsActive("request_funds") then
            quest:Cancel("request_funds")
        end
    end,
}
:AddObjective{
    id = "buy_loaves",
    title = "Purchase some dole loaves",
    desc = "{dealer} can sell you some dole loaves, given that you can pay.",
    mark = {"dealer"},
}
:AddObjective{
    id = "dole_out_three",
    title = "Feed some people",
    mark = function(quest, t, in_location)
        if in_location then
            local location = TheGame:GetGameState():GetPlayerAgent():GetLocation()
            for i, agent in location:Agents() do
                if CanFeed(agent, quest) then
                    table.insert(t, agent)
                end
            end
        else
            DemocracyUtil.AddUnlockedLocationMarks(t)
        end
    end,
}
:AddObjective{
    id = "request_funds",
    title = "(Optional) Request additional funds",
    desc = "If you don't have enough money to buy the loaves, you can ask your advisor for some.",
    mark = {"primary_advisor"},
}
:AddFreeTimeObjective{
    desc = "Use this time to find people to feed with your dole loaves.",
    action_multiplier = 1.5,
    on_complete = function(quest)
        if quest:IsActive("dole_out_three") then
            quest:Complete("dole_out_three")
        end
        if quest:IsActive("buy_loaves") then
            quest:Complete("buy_loaves")
        end
        quest:Activate("go_to_advisor")
    end,
}
:AddLocationCast{
    cast_id = "dealer_workplace",
    cast_fn = function(quest, t)
        table.insert( t, TheGame:GetGameState():GetLocation("MURDER_BAY_HARBOUR"))
        table.insert( t, TheGame:GetGameState():GetLocation("GB_CAFFY"))
    end,
    on_assign = function(quest, location)
        quest:AssignCastMember("dealer")
    end,
}
:AddCast{
    cast_id = "dealer",
    when = QWHEN.MANUAL,
    no_validation = true,
    cast_fn = function(quest, t)
        table.insert( t, quest:GetCastMember("dealer_workplace"):GetProprietor())
    end,
}
:AddOpinionEvents{
    politic = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Changed political opinion for them.",
    },
    paid = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Gave them money and bread.",
    },
    peeved = {
        delta = OPINION_DELTAS.BAD,
        txt = "Called a populist.",
    },
    political_waffle = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Agreed with them on all the big issues.",
    },
    political_angry = {
        delta = OPINION_DELTAS.BAD,
        txt = "Let them call you a straw man.",
    },
}
-- Added true to make primary advisor mandatory.
-- Otherwise the game will softlock.
-- Fair enough.
DemocracyUtil.AddPrimaryAdvisor(QDEF, true)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
            {has_primary_advisor?
                agent:
                    Here's an idea for what you can do.
                    You gift out people dole loaves.
                player:
                    You think this is going to help gather support?
                agent:
                    Yeah.
                    Plenty of people only care about what is in front of them, and if you give them something to eat, they will just support you.
            }
        ]],
    }
    :State("START")
    :Fn(function(cxt)
        cxt:Dialog("DIALOG_INTRO")
    end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.ACCEPTED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !thought
                Well you make a sound case.
                Where am I getting them, anyway?
                I can't help but notice that you have nothing on you.
            agent:
                I know some people who are willing to bulk sell them to you.
                You can visit them to buy some loaves.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
           cxt:Dialog("DIALOG_INTRO")
        end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.DECLINED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !thought
                I don't know. People are going to be suspicious of random handouts.
                That also just sounds like bribing the voter base.
            agent:
                !crossed
                There is never any rules saying you can't, is there?
                You are just giving yourself arbitrary disadvantages.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
QDEF:AddConvo("dole_out_three")
    :Loc{
        DIALOG_SATISFIES_CONDITIONS = [[
            player:
                Hey there, friend. I have something to give you.
            * You hand them some of the bread.
        ]],
        OPT_GIVE_BREAD = "Give bread",
        REQ_HAVE_BREAD = "You don't have any dole loaves",

        SELECT_TITLE = "Select a card",
        SELECT_DESC = "Choose a dole loaf to gift to this person, consuming 1 use on it.",
    }
    :Hub(function(cxt, who)
        if who and CanFeed(who, cxt.quest) then
            cxt.quest.param.gifted_people = cxt.quest.param.gifted_people or {}
            cxt.quest.param.rejected_people = cxt.quest.param.rejected_people or {}
            local cards = {}
            for i, card in ipairs(cxt.player.battler.cards.cards) do
                print(card.id)
                if card.id == "dole_loaves" then
                    table.insert(cards, card)
                end
            end
            cxt:Opt("OPT_GIVE_BREAD")
                :ReqCondition(#cards > 0, "REQ_HAVE_BREAD")
                :SetQuestMark()
                :RequireFreeTimeAction(1, true)
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
                        cxt.quest:DefFn("DeltaActions", -1)

                        cxt:Dialog("DIALOG_SATISFIES_CONDITIONS")

                        card:ConsumeCharge()
                        if card:IsSpent() then
                            cxt.player.battler:RemoveCard( card )
                        end
                        -- Wumpus; Huh. Didn't know Weighted Pick was an option for the code. That shrank a lot of the code bloat that I had...hopefully I keep that in mind when the need arises.
                        local weight = {
                            STATE_PANHANDLER = 1,
                            STATE_GRATEFUL = 3,
                            STATE_UNGRATEFUL = who:GetRenown() * who:GetRenown(),
                            STATE_POLITICAL = 1,
                        }
                        if who:GetFactionID() == "RISE" then
                            weight.STATE_POLITICAL = weight.STATE_POLITICAL + 1
                        end
                        local state = weightedpick(weight)
                        cxt:GoTo(state)
                    end

                end)
        end
    end)
    :State("STATE_PANHANDLER")
        :Loc{
            DIALOG_PAN_HANDLE = [[
                agent:
                    Ah, some of this...
                player:
                    Is something the matter?
                agent:
                    Just...I've been eating this for the past...how long?
                    Wish I could have something else...
            ]],
            OPT_GIVE = "Give them some Shills",
            DIALOG_GIVE = [[
                player:
                    Well, let them never say I'm not benevolent.
                    !give
                agent:
                    !take
                    Oh wow! This is more than I make in a week!
                    Thanks, {player}!
            ]],
            OPT_NO_MONEY = "Give them the bread...then a wide berth",
            DIALOG_NO_MONEY = [[
                player:
                    My sympathies, I have been in the same position as you before.
                agent:
                    I mean...it's fine, it's fine. Thank you for the food, regardless.
            ]],
        }
        :Fn(function(cxt)

            cxt:Dialog("DIALOG_PAN_HANDLE")
            table.insert(cxt.quest.param.gifted_people, cxt:GetAgent())
            cxt:Opt("OPT_GIVE")
                :Dialog("DIALOG_GIVE")
                :DeliverMoney(100)
                :ReceiveOpinion("paid")
                :DoneConvo()
                    -- :CompleteQuest("feed_pan")
            cxt:Opt("OPT_NO_MONEY")
                :Dialog("DIALOG_NO_MONEY")
                :DoneConvo()
                -- :CompleteQuest("feed_pan")
        end)
    --Wumpus; I have probably gotten needlessly fancy with this section. At least compared to the others.
    :State("STATE_POLITICAL")
        :Loc{
            DIALOG_POLITICAL = [[
                    agent:
                    Some of the poor man's food, sure I'll take it.
                    Though...I wish people would not have to rely on the admiralty's food like this.
                    !question
                    Are you in support of a UBI? So this kind of thing doesn't have to happen anymore?
            ]],
            OPT_AGREE = "Agree to {agent.hisher} ideas.",
            DIALOG_AGREE = [[
                player:
                    Viva la Rise, am I right?
                agent:
                    !happy
                    Right you are!
                    It's been so long since I met a like-minded politician since Kalandra.
                    And what about the working conditions of those who need it!
                    We're told to work, work, work and barely make it out with our equipment and plunder.
            ]],

            OPT_DISAGREE = "Respectfully disagree with their opinions.",
            DIALOG_DISAGREE = [[
                player:
                    I don't think my opinion matters here.
                agent:
                    What's so wrong about agreeing with this?
                    Are you saying welfare is bad? Hm?
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_POLITICAL")
            table.insert(cxt.quest.param.gifted_people, cxt:GetAgent())

            cxt:Opt("OPT_AGREE")
                :UpdatePoliticalStance("FISCAL_POLICY", 2, false, true)
                :ReceiveOpinion("politic")
                :Dialog("DIALOG_AGREE")
                :GoTo("STATE_AGREE")
            cxt:Opt("OPT_DISAGREE")
                :Dialog("DIALOG_DISAGREE")
                :GoTo("STATE_DISAGREE")
        end)
    :State("STATE_AGREE")
        :Loc{
            OPT_AGREE_2 = "Agree to their second stance.",
            DIALOG_AGREE_2 = [[
                player:
                    It makes no sense to have people work, work, work like they do now.
                agent:
                    Thank you!
            ]],
            OPT_DISAGREE_2 = "Tell them you don't agree with the second stance.",
            DIALOG_DISAGREE_2 = [[
                player:
                    Now, now. Let's not get ahead of ourselves.
                agent:
                    Why? Why are you deflecting this issue?
                    Is it because you HATE labor laws? Do you WANT people to be treated like bog muck?
            ]],
        }
        :Fn(function(cxt)
            cxt:Opt("OPT_AGREE_2")
                :UpdatePoliticalStance("LABOR_LAW", 2, false, true)--random stance. might change once I get a minute to look.
                :ReceiveOpinion("political_waffle")
                :Dialog("DIALOG_AGREE_2")
                -- :CompleteQuest("feed_politic")
                :Fn(function(cxt)
                    table.insert(cxt.quest.param.gifted_people, cxt:GetAgent())
                end)
                :DoneConvo()
            cxt:Opt("OPT_DISAGREE_2")
                :Dialog("DIALOG_DISAGREE_2")
                :GoTo("STATE_DISAGREE_2")
        end)

    :State("STATE_DISAGREE")
        :Loc{
            OPT_CALM_DOWN = "Tell them how wrong they are.",
            DIALOG_CALM_DOWN = [[
                player:
                    !crossed
                    Now that isn't what I meant by it and you know it.
            ]],
            DIALOG_CALM_DOWN_SUCCESS = [[
                player:
                    Do my actions not demonstrate my beliefs?
                    I came to you to help you the people of Havaria who need help.
                agent:
                    I guess that's true.
                    Pardon, I'm not great at taking rejection for my ideas.
                player:
                    Well, follow the debates. People'll talk all day long about different ideas.
                agent:
                    Can't. I got to get to my next shift.
                player:
                    Well good luck for you, and enjoy the bread.
            ]],
            DIALOG_CALM_DOWN_FAIL = [[
                agent:
                    Oh, I get it.
                    You're just trying to butter up the Rise so we'd lay down our arms.
                    You're working with the Barons, aren't you?
                player:
                    No, No, you've got it all-
                agent:
                    Get out of my face, you filthy capitalist. You'll profit no longer from this mere worker.
            ]],
            OPT_IGNORE = "Ignore their complaints",
            DIALOG_IGNORE = [[
                * You put on the best poker face you can manage.
                * It doesn't help.
                agent:
                    What? Not going to defend yourself?
                    Try to excuse yourself from hearing the truth?
            ]],
        }
        :Fn(function(cxt)
            cxt:Opt("OPT_CALM_DOWN")
                :Dialog("DIALOG_CALM_DOWN")
                :Negotiation{
                    on_success = function(cxt)
                        cxt:Dialog("DIALOG_CALM_DOWN_SUCCESS")
                        -- cxt.quest:Complete("feed_politic")
                        StateGraphUtil.AddEndOption(cxt)
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_CALM_DOWN_FAIL")
                        cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("political_angry"))
                        StateGraphUtil.AddEndOption(cxt)
                    end
                }
            cxt:Opt("OPT_IGNORE")
                :Dialog("DIALOG_IGNORE")
                :ReceiveOpinion("political_angry")
                -- :CompleteQuest("feed_politic")
                :DoneConvo()
        end)
    :State("STATE_DISAGREE_2")
        :Loc{
            OPT_CALM_DOWN_2 = "Elaborate on how wrong they are.",
            DIALOG_CALM_DOWN_2 = [[
                * You start telling them exactly how wrong they are, to put it bluntly.
            ]],
            DIALOG_CALM_DOWN_2_SUCCESS = [[
                player:
                    How do you think elections are won?
                agent:
                    !angry_accuse
                    With strong morals and vigor!
                player:
                    And look at how much the Rise has gotten done with just "strong morals" and "vigor".
                    My opinions are not made public because I wish to reach office, and that requires the support of the enemy as well.
                agent:
                    !question
                    So...You're trying to use guile?
                player:
                    !point
                    Yes! And if you go around telling people not to vote for your allies-
                agent:
                    !placate
                    The point was made a while ago. Didn't realize I was talking to an Ally.
                    If that's what you want, I suppose. But I will have my eye on you.
            ]],
            DIALOG_CALM_DOWN_2_FAIL = [[
                player:
                    I can't exactly change the business practices of an entire corporation.
                agent:
                    !angry_shrug
                    Of course you can! You would be the president!
                    Emphasis on the "would", because I am certainly not voting for <i>you</> now!
            ]],
            OPT_IGNORE_2 = "Ignore their complaints.",
            DIALOG_IGNORE_2 = [[
                player:
                    !crossed
                    You are jumping to conclusions quite quickly.
                agent:
                    Am I? Or am I pointing out your hypocrisy to the voters?
                    * You turn your heel and walk away.
            ]],
        }
        :Fn(function(cxt)
            cxt:Opt("OPT_CALM_DOWN_2")
                :Dialog("DIALOG_CALM_DOWN_2")
                :Negotiation{
                    on_success = function(cxt)
                        cxt:Dialog("DIALOG_CALM_DOWN_2_SUCCESS")
                        -- cxt.quest:Complete("feed_politic")
                        StateGraphUtil.AddEndOption(cxt)
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_CALM_DOWN_2_FAIL")
                        cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("political_angry"))
                        StateGraphUtil.AddEndOption(cxt)
                    end
                }
            cxt:Opt("OPT_IGNORE_2")
                :Dialog("DIALOG_IGNORE_2")
                :ReceiveOpinion("political_angry")
                :DoneConvo()
        end)
    :State("STATE_UNGRATEFUL")
        :Loc{
            DIALOG_UNGRATE = [[
                agent:
                    !crossed
                    Do you believe I can't afford my own food?
                    I'll have you know I don't stand for this kind of pandering.
            ]],
            OPT_CONVINCE = "Try to calm them down",
            DIALOG_CONVINCE = [[
                player:
                    !placate
                    Hey, I am just trying to do some good deeds here.
                    There is no need to be rude about it.
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                agent:
                    !sigh
                    Fine. I guess I overreacted a bit.
                    I am sure you mean well.
                player:
                    See? Isn't this better for both of us?
            ]],
            DIALOG_CONVINCE_FAIL = [[
                agent:
                    !crossed
                    It's not like I want to be rude.
                    It's just that you see yourself as superior to everyone else around you.
                    Making empty gestures doesn't change that.
                    !angry_accuse
                    I hate people who make empty gestures to make themselves feel superior.
            ]],
            OPT_IGNORE = "Ignore their complaints",
            DIALOG_IGNORE = [[
                player:
                    !crossed
                    Fine. If you don't want to take the bread, then suit yourself.
                agent:
                    !angry_accuse
                    This is what I'm talking about.
                    Typical political pandering.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_UNGRATE")
            cxt:Opt("OPT_CONVINCE")
                :Dialog("DIALOG_CONVINCE")
                :Negotiation{
                    on_start_negotiation = function(minigame)
                        minigame.opponent_negotiator:CreateModifier( "SHORT_TEMPERED" )
                    end,
                    on_success = function(cxt)
                        cxt:Dialog("DIALOG_CONVINCE_SUCCESS")
                        -- cxt.quest:Complete("feed_ungrate")
                        table.insert(cxt.quest.param.gifted_people, cxt:GetAgent())
                        StateGraphUtil.AddEndOption(cxt)
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_CONVINCE_FAIL")
                        -- cxt:ReceiveOpinion("peeved")
                        cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("peeved"))
                        table.insert(cxt.quest.param.rejected_people, cxt:GetAgent())
                        StateGraphUtil.AddEndOption(cxt)
                    end,
                }
            cxt:Opt("OPT_IGNORE")
                :Dialog("DIALOG_IGNORE")
                :ReceiveOpinion("peeved")
                :Fn(function(cxt)
                    table.insert(cxt.quest.param.rejected_people, cxt:GetAgent())
                end)
                :DoneConvo()
            end)
    :State("STATE_GRATEFUL")
        :Loc{
            DIALOG_GRATE = [[
                %gift_bread
            ]],
        }
        :Quips{
            {
                tags = "gift_bread",
                [[
                    player:
                        !permit
                        Hey there. You want some bread?
                    agent:
                        !take
                        Thanks. I needed that.
                ]],
                [[
                    player:
                        !permit
                        I'm giving away free bread to the people. You want some?
                    agent:
                        !take
                        Sure. I don't see why not.
                        !happy
                        Thanks!
                ]],
                [[
                    player:
                        !permit
                        Do you want some free bread?
                    agent:
                        !take
                        Can't say no to some free bread.
                        !happy
                        Thanks!
                    player:
                        !happy
                        That's the spirit!
                ]],
                [[
                    player:
                        !permit
                        You look like you need some bread. Want some?
                    agent:
                        !take
                        There is never enough bread for everyone.
                        !happy
                        I'll happily take some. Thanks!
                ]],
            },
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_GRATE")
            table.insert(cxt.quest.param.gifted_people, cxt:GetAgent())
            StateGraphUtil.AddEndOption(cxt)
        end)
QDEF:AddConvo("dole_out_three", "primary_advisor")
    :Loc{
        OPT_END_EARLY = "Finish quest early",
        DIALOG_END_EARLY = [[
            player:
                I'm done.
            agent:
                Wait, really?
                But there's still plenty of time!
            player:
                Nothing else I can do.
            agent:
                Suit yourself, I guess.
        ]],
    }
    :Hub(function(cxt, who)
        cxt:Opt("OPT_END_EARLY")
            :SetQuestMark(cxt.quest)
            :Dialog("DIALOG_END_EARLY")
            :Fn(function(cxt)
                cxt.quest:Complete("time_countdown")
            end)
    end)
QDEF:AddConvo("request_funds", "primary_advisor")
    :Loc{
        OPT_ASK_MONEY = "Ask for funds for buying the loaves",
        DIALOG_ASK_MONEY = [[
            player:
                I'm a bit short on cash, {primary_advisor}.
            agent:
                !crossed
                Is that my problem?
            player:
                !permit
                It's just... You asked me to buy it from the supplier.
                Can't exactly do that without money, can I?
        ]],
        DIALOG_ASK_MONEY_SUCCESS = [[
            agent:
                !give
                Hmph. Take a few shills.
                !sigh
                What will you do without me.
        ]],
        DIALOG_ASK_MONEY_FAILURE = [[
            agent:
                !crossed
                You have campaign funds specifically for this purpose.
                If you don't have the money, it's entirely your fault.
        ]],
    }
    :Hub(function(cxt, who)
        cxt:BasicNegotiation("ASK_MONEY", {

        })
            :OnSuccess()
                :ReceiveMoney(80)
                :Fn(function(cxt)
                    cxt.quest:Complete("request_funds")
                end)
            :OnFailure()
                :Fn(function(cxt)
                    cxt.quest:Fail("request_funds")
                end)
    end)
QDEF:AddConvo("go_to_advisor", "primary_advisor")
    :Loc{
        OPT_TALK_PROGRESS = "Talk about your progress",
        DIALOG_TALK_PROGRESS = [[
            agent:
                So? How did you do?
        ]],
        DIALOG_NO_GIFT = [[
            player:
                Well...I kind of got scoffed at when I tried.
            agent:
                !question
                Tried? Or did you just putz around and waste all of our time?
            player:
                Er...it's more complicated than that.
            agent:
                No. No it's not.
        ]],
        DIALOG_ONE_GIFT = [[
            player:
                [p] I gifted about one person.
            agent:
                You might as well not do that.
        ]],
        DIALOG_FEW_GIFT = [[
            player:
                [p] I gifted {1} people.
            agent:
                [p] Not great, but not bad either.
        ]],
        DIALOG_MORE_GIFT = [[
            player:
                [p] I gifted {1} people.
            agent:
                [p] You did good.
        ]],
    }
    --This final part is where the issue lies.
    :Hub(function(cxt)
        cxt:Opt("OPT_TALK_PROGRESS")
            :SetQuestMark()
            :Dialog("DIALOG_TALK_PROGRESS")
            :Fn(function(cxt)
                local count = #cxt.quest.param.gifted_people
                if count == 0 then
                    cxt:Dialog("DIALOG_NO_GIFT", count)
                    cxt.quest:Fail()
                elseif count == 1 then
                    cxt:Dialog("DIALOG_ONE_GIFT", count)
                    cxt.quest:Fail()
                elseif count <= 3 then
                    cxt:Dialog("DIALOG_FEW_GIFT", count)
                    cxt.quest.param.poor_performance = true
                    cxt.quest:Complete()
                    ConvoUtil.GiveQuestRewards(cxt)
                else
                    cxt:Dialog("DIALOG_MORE_GIFT", count)
                    cxt.quest:Complete()
                    ConvoUtil.GiveQuestRewards(cxt)
                end
            end)
            :DoneConvo()
    end)
QDEF:AddConvo("buy_loaves", "dealer")
    :Loc{
        OPT_BUY = "Buy loaves",
        DIALOG_BUY = [[
            player:
                I will buy a bundle.
            agent:
                Good choice.
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_BUY")
            :SetQuestMark()
            :Dialog("DIALOG_BUY")
            :PostCard("dole_loaves")
            :DeliverMoney(80)
            :GainCards{"dole_loaves"}
            :Fn(function(cxt) cxt.quest.param.bought_at_least_one = true end)
    end)
    :AttractState("STATE_ATTRACT")
        :Loc{
            DIALOG_INTRO = [[
                {first_time?
                player:
                    I heard you sell dole loaves.
                    Can I have some?
                agent:
                    Sure... As long as you can pay.
                }
                {not first_time?
                    {bought_at_least_one?
                        agent:
                            Are you coming back to buy some more?
                    }
                    {not bought_at_least_one?
                        agent:
                            So? Have you made up your mind?
                    }
                }
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
