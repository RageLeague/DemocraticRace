local QDEF = QuestDef.Define
{
    title = "Never Meet Your Heroes",
    desc = "Manufacture a scandal for one of your political opponents. Show their supporters who they are really supporting.",

    qtype = QTYPE.SIDE,
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"RALLY_JOB"},
    reward_mod = 0,
    extra_reward = false,

    on_init = function(quest)

    end,
    on_start = function(quest)
        quest:Activate("spread_rumor")
        quest:Activate("time_countdown")
    end,

    on_destroy = function( quest )

    end,
    on_complete = function( quest )

    end,
    on_fail = function(quest)

    end,
    precondition = function(quest)
        return TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor") --and TheGame:GetGameState():GetMainQuest().param.day >= 2
    end,
    GenerateRumor = function(quest)
        local chosen = math.random(1,5)
        return quest:GetLocalizedStr("RUMOR_" .. chosen)
    end,
}
:AddCast{
    cast_id = "target",
    when = QWHEN.MANUAL,
}
:Loc{
    RUMOR_1 = "{target} is suspicious.",
    RUMOR_2 = "{target} hunts baby yotes for fun.",
    RUMOR_3 = "{target} supports Rentoria's invasion against Havaria.",
    RUMOR_4 = "{target}'s parents bought {target}'s way into a position of power.",
    RUMOR_5 = "{target} wants to meddle with the election.",
}
:AddObjective{
    id = "spread_rumor",
    title = "Spread the rumor",
    desc = "Spread your rumor about {target} through different factions to increase the credibility of your claim.",
}
:AddFreeTimeObjective{
    desc = "Use this time to spread your rumor.",
    action_multiplier = 1.5,
    on_complete = function(quest)
        quest:Complete("spread_rumor")
    end,
}
DemocracyUtil.AddPrimaryAdvisor(QDEF, true)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
            primary_advisor:
                There are two ways to win an election:
                One, you gather support and increase your votes.
                Two, you bring your opponent down so they get less votes.
            player:
                That sounds good and all, but how could I possibly do that?
            primary_advisor:
                It's simple. Tell the voter base something that your opponent doesn't want them to know. Something that can bring down their reputation.
            player:
                You have something in mind?
            primary_advisor:
                !shrug
                Not really. But you can easily make this up.
            {not can_manipulate_truth?
                It doesn't have to be true. It just has to be plausible enough to bring down the opponent's popularity.
            }
            {can_manipulate_truth?
                After all, facts are subjective.
                Tell the world what they want to believe, and it will become the truth.
            }
                Which one of your opponents to target is up to you.
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
                !shrug
                You know what? I'm down for a little defamation.
            primary_advisor:
                Great! Who do you want to target today?
        ]],
        OPT_TARGET = "Target {1#agent}",
        DIALOG_TARGET = [[
            player:
                I would say {target}.
            primary_advisor:
                !shrug
                If you say so.
                Now, if we want to defame {target}, we need to show the people what kind of person {target} truly is.
                What kind of horrible misdeeds they have done in the past, or what kind of personality traits that are less than desireable.
                !thought
                Something that {target} doesn't want the world to know.
                You have something in mind, don't you?
                If you do, write your thoughts down.
        ]],
        DIALOG_TARGET_PST = [[
            * {agent} carefully reads what you've just wrote.
            {advisor_diplomacy?
            agent:
                !give
            * Then, {agent} hands the note back to you.
            agent:
                Wow, that was certainly a cringe thing for {target} to do, huh?
                You are going to be so based revealing this information to the world.
            }
            {not advisor_diplomacy?
            agent:
                !sigh
            * Then, {agent.heshe} gives up.
            agent:
                Man, you really need to work on your handwriting.
                I don't think whatever you wrote is even Havarian.
            player:
                !crossed
                Hey! That's uncalled for.
            agent:
                !sigh
                I'm sure whatever you wrote is at least a good enough rumor to hopefully sow doubts in the voter base.
            }
        ]],
        DIALOG_TARGET_PST_NO_ENTRY = [[
            * {agent} carefully reads what you've just wrote.
            agent:
                !dubious
                Can't think of anything, huh?
                Okay, how about this:
                {1}
            player:
                !neutral_burp
                Ooh, I like this one!
        ]],
        DIALOG_TARGET_PST_2 = [[
            agent:
                !point
                Now go and tell everyone about it.
                Make sure to tell people from different backgrounds about it, so this story becomes more believable.
                And make sure to keep your stories straight.
        ]],

        POPUP_TITLE = "Make a scandal!",
        POPUP_SUBTITLE = "Write something down that might be condemning to {target}!",
    }
    :State("START")
        :Fn(function(cxt)
            cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
            cxt:Dialog("DIALOG_INTRO")

            for i, id, data in sorted_pairs(DemocracyConstants.opposition_data) do
                local opponent = TheGame:GetGameState():GetMainQuest():GetCastMember(data.cast_id)
                if opponent and not opponent:IsRetired() then
                    cxt:Opt("OPT_TARGET", opponent)
                        :Fn(function(cxt)
                            cxt.quest:AssignCastMember("target", opponent)
                        end)
                        :Dialog("DIALOG_TARGET")
                        :Fn(function(cxt)
                            local screen = Screen.EditStringPopup( cxt:GetLocString( "POPUP_TITLE" ),
                                loc.format( cxt:GetLocString( "POPUP_SUBTITLE" ) ),
                                "",
                                function( val )
                                    cxt.enc:ResumeEncounter( val )
                                end )
                            screen.inputbox.lines = 3
                            screen.inputbox:SetSize(720)
                            TheGame:FE():PushScreen(screen)

                            local val = cxt.encounter:YieldEncounter()

                            if val and val ~= "" then
                                cxt.quest.param.rumor = val
                                cxt:Dialog("DIALOG_TARGET_PST")
                            else
                                cxt.quest.param.rumor = cxt.quest:DefFn("GenerateRumor")
                                cxt:Dialog("DIALOG_TARGET_PST_NO_ENTRY", cxt.quest.param.rumor)
                            end
                            cxt:Dialog("DIALOG_TARGET_PST_2")
                        end)
                end
            end

        end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.DECLINED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !crossed
                That sounds extremely dirty.
            primary_advisor:
                !handwave
                Please, you are a grifter.
                You should know the virtue of pursuing your goal using any means necessary.
                !sigh
                Nevertheless, I cannot force you if you don't want to do it.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
QDEF:AddConvo("spread_rumor")
    :Quips{
        {
            tags = "need_convincing",
            [[
                !hips
                Big if true. That is a BIG if, though.
            ]],
            [[
                !thought
                I find this hard to believe. Please enlighten me on this topic.
            ]],
            [[
                !dubious
                Wait, is that supposed to be a bad thing? Can you elaborate on that?
            ]],
            [[
                {is_supporter?
                    !angry_accuse
                    You're lying! You can't just say things without proof!
                }
                {not is_supporter?
                    !crossed
                    I'll admit I don't like {target} that much, but what you are saying sounds way over the top.
                }
            ]],
            [[
                !crossed
                And people die when they are killed. What's your point?
            ]],
            [[
                !dubious
                Is that true? Tell me more about it.
            ]],
        },
    }
    :Loc{
        OPT_CONVINCE = "Convince {agent} that your rumor about {target} is true",
        TT_CONVINCE = "The more people you convince, the bigger the story gets, and the bigger the holes in your story gets.",
        DIALOG_CONVINCE = [[
            {is_supporter?
            player:
                You support {target}, right?
            agent:
                So what? Are you trying to convince me otherwise?
            player:
                I wonder if you still hold the same view after I show you what kind of a person {target} truly is.
            }
            {not is_supporter?
            player:
                You know {target} is running for president, right?
                !sigh
                It's a real shame that this terrible person is still allowed to run.
            agent:
                What do you mean?
            }
            player:
                {1}
            agent:
                %need_convincing
        ]],
        DIALOG_CONVINCE = [[
            player:
                Yep. This is true enough.
            agent:
            {is_supporter?
                !spit
                Hesh dammit- To think I ever supported you.
            }
            {not is_supporter?
                !thought
                This information... The consequences for this would be huge.
                And certainly bad for {target}.
            }
                Thanks for showing me what kind of person {target} truly is.
            * One more person now believes your little rumor.
            * And this person can spread this rumor further, to even more people.
            * This is how your rumor gains traction, to bring down {target}'s reputation.
        ]],
        DIALOG_CONVINCE_FAILURE = [[
            agent:
                Wait a second!
                !angry_accuse
                There is a contradiction in what you just said!
                Just what are you trying to pull?
            player:
                Well, uh...
            agent:
            {not is_supporter?
                And here I though you finally found some dirt on {target}.
                It turns out just to be more baseless rumor.
            }
            {is_supporter?
                Hearing you out was a mistake. I knew I should trust {target} more than you.
            }
            * Oops, the holes in your story gets exposed.
            {first_fail?
                * Not to worry. As long as you convince enough people of your story, it will make {agent} look like the fool here.
                * You have one more chance of making it right. Don't screw this up.
            }
            {not first_fail?
                * People are going to catch on, and your rumor will dissipate.
                * This does not look good for you.
            }
        ]],
    }
    :Fn(function(cxt)
        if cxt:GetAgent() and not cxt:GetAgent():IsCastInQuest(cxt.quest) then
            cxt:Opt("OPT_CONVINCE")
                :PostText("TT_CONVINCE")
                :Dialog("DIALOG_CONVINCE")
                :Negotiation{}
        end
    end)
