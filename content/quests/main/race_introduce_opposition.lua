-- local character_map = {
--     [DemocracyConstants.opposition_data.candidate_admiralty.character] = "admiralty",
--     [DemocracyConstants.opposition_data.candidate_rise.character] = "rise",
--     [DemocracyConstants.opposition_data.candidate_baron.character] = "baron",

-- }
local available_opposition = {}
for i, data in pairs(DemocracyConstants.opposition_data) do
    if data.character then
        table.insert(available_opposition, data.character)
    end
end
local QDEF = QuestDef.Define
{
    title = "Opinions and Oppositions",
    desc = "Discuss the oppositions with your advisor",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/meet_opposition.png"),

    qtype = QTYPE.STORY,
    collect_agent_locations = function(quest, t)
        table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('home')})
        table.insert(t, { agent = quest:GetCastMember("opposition"), location = quest:GetCastMember('home'), role = CHARACTER_ROLES.VISITOR})
    end,
    on_complete = function(quest)
        if quest:GetCastMember("primary_advisor") then
            quest:GetCastMember("primary_advisor"):GetBrain():SendToWork()
        end
        if quest:GetCastMember("opposition") then
            quest:GetCastMember("opposition"):MoveToLimbo()
        end
    end,
    -- on_start = function(quest)

    -- end,
    on_post_load = function(quest)
        if quest:IsInactive("meet_opposition") then
            quest:Activate("meet_opposition")
        end
    end,
}
:AddObjective{
    id = "discuss_plan",
    title = "Discuss plan with {primary_advisor}",
    mark = {"primary_advisor"},
}
:AddObjective{
    id = "meet_opposition",
    title = "Acquaint with {opposition}",
    mark = {"opposition"},
    state = QSTATUS.ACTIVE,
}
:AddCast{
    cast_id = "opposition",
    cast_fn = function(quest, t)
        local all_candidates = DemocracyUtil.GetAllOppositions()
        if #all_candidates == 0 then
            -- If you get to that point you deserve a prize
            -- Or a softlock, which is what you are going to get
        else
            local chosen = table.arraypick(all_candidates)
            table.insert(t, DemocracyUtil.GetMainQuestCast(chosen))
        end
    end,
    no_validation = true,
    on_assign = function(quest, agent)
        -- if character_map[agent:GetContentID()] then
        --     quest.param[character_map[agent:GetContentID()]] = true
        -- else
        --     quest.param.missing_id = true
        -- end
        for id, data in pairs(DemocracyConstants.opposition_data) do
            if data.character == agent:GetContentID() then
                quest.param.opposition_id = id
                local opposition_data = DemocracyConstants.opposition_data[quest.param.opposition_id]
                if opposition_data then
                    quest.param.oppo_issue = opposition_data.platform
                        -- cxt.quest.param.oppo_stance = cxt.quest.param.oppo_issue.stances[stances]
                    if quest.param.oppo_issue then
                        quest.param.stance_index = opposition_data.stances[quest.param.oppo_issue]
                        if quest.param.oppo_issue and quest.param.stance_index then
                            quest.param.oppo_stance = quest.param.oppo_issue .. "_" .. quest.param.stance_index
                        end
                    end

                    if opposition_data.workplace then
                        quest.param.oppo_location = opposition_data.workplace
                    end
                end
                break
            end
        end
    end,
}
DemocracyUtil.AddPrimaryAdvisor(QDEF)
DemocracyUtil.AddHomeCasts(QDEF)

local function ShowStancesTutorial()
    local screen = TheGame:FE():GetTopScreen()
    TheGame:GetGameProfile():SetHasSeenMessage("democracy_tutorial_stances")
    TheGame:FE():InsertScreen( Screen.YesNoPopup(LOC"DEMOCRACY.TUTORIAL.TUTORIAL_STANCES_TITLE", LOC"DEMOCRACY.TUTORIAL.TUTORIAL_STANCES_BODY", nil, nil, LOC"UI.NEGOTIATION_PANEL.TUTORIAL_NO" ))
        :SetFn(function(v)
            if v == Screen.YesNoPopup.YES then
                local coro = screen:StartCoroutine(function()
                    local advance = false
                    TheGame:FE():PushScreen( Screen.SlideshowScreen( "democracy_tutorial_stances", function() advance = true end ):SetAutoAdvance(false) )
                    while not advance do
                        coroutine.yield()
                    end
                end )
            end
        end)
end

QDEF:AddConvo("meet_opposition", "opposition")
    :Loc{
        DIALOG_GREET_PST = [[
            agent:
                Anyway, nice to meet you.
                If you have some questions, just ask.
        ]],
        DIALOG_QUESTION = [[
            player:
                I have some questions for you...
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_ASK_ABOUT")
            :IsHubOption(true)
            :Dialog("DIALOG_QUESTION")
            :GoTo("STATE_QUESTIONS")
    end)
    :AttractState("STATE_ATTRACT", function(cxt) return not cxt.quest.param.greeted end)
        :Quips{
            {
                tags = "oppo_greeting",
                [[
                    * You walk up to {agent}.
                    * {agent} extends a hand to greet you.
                    agent:
                        !right
                        Hello there. My name is {agent}. You may have heard of me already down the grapevine.
                    player:
                        {player}. Charmed to meet you, {agent.honorific}.
                        So I believe we should introduce ourselves a little bit better.
                        If you're going to win, surely you've nothing to hide from your opponents.
                    agent:
                        Nothing I couldn't tell you about me that the public doesn't already.
                        Ask away.
                ]],
            },
            {
                tags = "oppo_greeting, met",
                [[
                    * You walk up to {agent}.
                    * {agent} looks around the office, observing.
                    agent:
                        !right
                        So, this is your campaign office, huh?
                        A pretty nice place, if I do say so myself.
                    player:
                        Ah, {agent}. Fancy seeing you here.
                        Last time we meet, we haven't properly talked about the campaign yet.
                        Do you mind if I ask you some questions?
                    agent:
                        Of course, ask away.
                ]],
            },
            {
                tags = "oppo_greeting, player_sal, kalandra",
                [[
                    * You walk up to {agent}.
                    * {agent} looks at you in shock.
                    agent:
                        !right
                        !surprised
                        {player}?
                    * Even though you haven't seen each other for ten years, you can still recognize {agent.himher} clearly.
                    player:
                        Prindo, is that you?
                        !happy
                        How long has it been? Ten years?
                    agent:
                        !agree
                        Too long to keep track of.
                    player:
                        Anyway, we can catch up later.
                        Right now, there are a few things I'd like to know about your campaign.
                    agent:
                        Don't worry. Ask ahead.
                ]],
            },
            {
                tags = "oppo_greeting, player_arint, spark_contact",
                [[
                    * You walk up to {agent}.
                    * {agent} looks at you in dismay.
                    agent:
                        !right
                        Oh, {player}. You followed me, after all.
                        !crossed
                        Didn't I say I can do this by myself?
                        Why did you show up now, all of a sudden?
                    player:
                        I'm not here to help you win, per se.
                        I am running for president as well, so that the Barons don't put all their eggs in one basket.
                        This way, even if one of us loses the election, the other person can still win.
                    agent:
                        !sigh
                        I suppose that is a fair arrangement.
                    player:
                        Anyway, if you don't mind, I'd like to ask some questions. To see if you have a plan.
                    agent:
                        !agree
                        Oh, I sure do have a plan, alright. Just go ahead and ask.
                ]],
            },
            {
                tags = "oppo_greeting, player_rook, spark_contact",
                [[
                    * You walk up to {agent}.
                    * {agent} seems glad to see you.
                    agent:
                        !right
                        !happy
                        Didn't expect to see you here, old chum!
                    player:
                        !crossed
                        I will have you know that I am running for president, so me being here is completely expected.
                    agent:
                        You will need more than stealth and espionage if you want to win the election.
                        !chuckle
                        But I guess, in that aspect, we are in the same boat.
                    player:
                        Speaking of which, there are some questions I'd like to ask you about your campaign.
                    agent:
                        Of course, go ahead and ask.
                ]],
            },
            {
                tags = "oppo_greeting, player_smith, vixmalli",
                [[
                    * You walk up to {agent}.
                    * {agent} looks at you in disbelief.
                    agent:
                        !right
                        What are you doing here? Shouldn't you be drinking in some rundown bar or something?
                    player:
                        !angry_accuse
                        Hey! I will have you know that I am running for president!
                    agent:
                        !agree
                        If you are speaking the truth, then perhaps it's finally time for you to do something useful.
                        Of course, I am not going to make it easier for you.
                        I actually want to win.
                    player:
                        If you're going to win, surely you've nothing to hide from your opponents.
                        There are some questions I'd like to ask of you.
                    agent:
                        !shrug
                        Eh, what's the harm? Sure.
                ]],
            },
        }
        :Loc{
            DIALOG_GREET = [[
                agent:
                    %oppo_greeting
                player:
                    Why are you running as a candidate for the election? What is your goal?
                agent:
                    !agree
                    I'm glad you asked.
                * {agent} clears {agent.hisher} throat loudly.
                    %opposition_intro idea_monologue {opposition_id}
                player:
                {not spark_contact?
                    I must say, I'm stunned by your rhetoric.
                agent:
                    !happy
                    I bet you are!
                }
                {spark_contact?
                    Wow, that... definitely is one of the speeches I've ever heard.
                agent:
                    !happy
                    I'm glad you liked it.
                }
                agent:
                    !permit
                    What say you? Do you agree with me on this matter?
                player:
                    ...
                    !placate
                    Wait, hold on. Am I suppose to give my opinion here?
                agent:
                    !wink
                    I mean, you don't <i>have to</>, but I would <i>really</> like to hear about your opinion on this matter.
            ]],
            OPT_AGREE = "Agree",
            DIALOG_AGREE = [[
                {(player_sal and kalandra)?
                    player:
                        Of course.
                        !spit
                        I'm never going to forget what they did to my parents. What they did to me.
                    agent:
                        !agree
                        I see you still got the fighting spirit inside you.
                        !permit
                        Well, you're in luck. The upcoming election will change everything.
                        !sigh
                        A shame that only one of us can win the election.
                    player:
                        !permit
                        Don't worry. I would be happy if either one of us win.
                    agent:
                        !agree
                        My thoughts exactly.
                }
                {(player_rook and spark_contact)?
                    player:
                        !thought
                        I have to say, for such a... stellar performance, I find myself agreeing with you.
                    agent:
                        !happy
                        That's the spirit, old chum!
                        !handwring
                        So what's the plan? A couple cups of booze and some finger foods back at HQ?
                    player:
                        Well, I hate to miss out on that, but I've got to do more work campaigning.
                    agent:
                        !sigh
                        Ah, that's truly a shame.
                        Oh well, maybe another time.
                }
                {(player_smith and vixmalli)?
                    player:
                        !happy
                        Hope you don't mind there being <i>two</> Heshians on the ballot, there.
                    agent:
                        Really? You believe in enforcing Hesh's will?
                        !angry
                        Or are you just trying to take my voter base?
                    player:
                        !shrug
                        Eh, make what you will. I'm just telling you how I think.
                    agent:
                        !palm
                        Still, it seems like you have finally waken up and found purpose in your life.
                }
                {(player_arint and spark_contact)?
                    player:
                        I do have to say that your opinion is agreeable to me.
                    agent:
                        !crossed
                        You don't need to patronize me.
                        Like I said, I am running the campaign all by myself, and I don't need your approval or help.
                    player:
                        !sigh
                        There's no convincing you otherwise, is there?
                    agent:
                        Nope.
                }
                {not (player_arint and spark_contact) or (player_smith and vixmalli) or (player_rook and spark_contact) or (player_sal and kalandra)?
                    player:
                        Believe me, friend. I'm a firm believer in your ideology.
                    agent:
                        Ah-ha, my dear {player}. We are finding so much in common already!
                        A shame, though. Only one of us is going to win the election, and I don't intend on holding back.
                    player:
                        Of course.
                        I wouldn't expect anything else.
                }
            ]],
            OPT_DISAGREE = "Disagree",
            DIALOG_DISAGREE = [[
                {(player_sal and kalandra)?
                    player:
                        !bashful
                        Well, I hate to say this, but I can't agree.
                        No matter what we try to do, we can't change how the world works.
                    agent:
                        !sigh
                        I see that you have lost the fire in your eyes.
                        Can't fault you for that, though. Life hits us all hard.
                        !permit
                        But if Havaria is going to change, there is no better time than now, during the election.
                    * It's true. No matter what happens during the election, Havaria will change forever.
                    * The best thing for you to do is to make sure that when that happens, you are the one in charge.
                    player:
                        !bashful
                        Thanks for the kind words. I will think about it.
                }
                {(player_rook and spark_contact)?
                    player:
                        Ah, it seems our views have drifted apart.
                    agent:
                        !shrug
                        It is what it is, old sport. No hard feelings.
                        Course, doesn't mean I can support you, what with you being the enemy and all.
                    player:
                        !wink
                        That's the thing with enemies. You remember the academy, right?
                    agent:
                        !chuckle
                        Oh ho ho! Smart, old sport. We'll see each other on the debate floor then?
                    player:
                        !nudge_nudge
                        If you make it, of course.
                }
                {(player_smith and vixmalli)?
                    player:
                        !crossed
                        Well, I'm sure you'll be so happy to know I don't believe in that stuff!
                    agent:
                        !disappoint
                        Why am I surprised? You are always a drunk child, with no purpose or calling.
                        !angry_point
                        Well, I hope you remember who wrote half of your essays to get you through school.
                    player:
                        !angry_shrug
                        Hey! Mullifee helped too, you can't take all the credit for that.
                    agent:
                        !crossed
                        Hmph. Hope she's willing to help write your speeches too.
                    * She isn't. That's your <i>advisor's</> job.
                }
                {(player_arint and spark_contact)?
                    player:
                        With all due respect, {agent.gender:sir|ma'am|manager}, I'm afraid that is not going to work.
                    agent:
                        !crossed
                        Hmph. Doesn't matter. I don't need your approval.
                    player:
                        !dubious
                        Then why did you ask me for my opinion in the first place?
                    agent:
                        !shrug
                        Well, I want to know your opinion on the matter, of course.
                        And I see now that we are going to face each other eventually.
                }
                {not (player_arint and spark_contact) or (player_smith and vixmalli) or (player_rook and spark_contact) or (player_sal and kalandra)?
                    player:
                        I can't say I do.
                    agent:
                        A shame. We could've been great allies.
                    player:
                        But aren't we political opponents, though?
                    agent:
                        Yeah, you're right.
                        Well, good luck with your campaign, and may the best candidate win.
                }
            ]],
            OPT_IGNORE = "Remain silent on this issue",
            DIALOG_IGNORE = [[
                player:
                    I don't want to make any statement regarding this issue.
                agent:
                    !crossed
                    {player}, this is an important issue that Havaria faces!
                    You can't stand aside forever while Havaria suffers from it!
                    !sigh
                    But fine. If you don't want to answer, I can't exactly force you to.
            ]],
            OPT_ASK_ABOUT = "Ask {primary_advisor} about stance taking",
            DIALOG_ASK_ABOUT = [[
                player:
                    Excuse me for a moment.
                agent:
                    Of course.
                * You turn to {primary_advisor}
                primary_advisor:
                    !right
                player:
                    !cagey
                    Wait, what should I say?
                    I feel like I am compelled to take a side here, and I don't know the consequences of doing that.
                primary_advisor:
                    {not advisor_manipulate?
                        !shrug
                        Well, as a politician, you will often face dilemma like this where you are compelled to take a side.
                    }
                    {advisor_manipulate?
                        !shrug
                        Well, logically speaking, politics is the resolution of conflicts.
                        Naturally, when conflicts like this arise, you are usually compelled to take a side.
                    }
                    Regardless of which side you pick, it's important for you to know what it entails.
                    {not advisor_hostile?
                        !give
                        Here's a brief explanation on what taking a stance means.
                    }
                    {advisor_hostile?
                        !permit
                        Well, I'm an expert at taking stances. Here's what you should know.
                    }
            ]],
            DIALOG_ASK_ABOUT_PST = [[
                primary_advisor:
                    Remember, while I may have personal opinions on some topics, it's ultimately your campaign, and your decisions to make.
                    I will support you, regardless of what stances you take.
                    !cruel
                {not advisor_diplomacy?
                    As long as you take the right ones, of course.
                }
                {advisor_diplomacy?
                    As long as it's based, of course.
                }
                player:
                    !sigh
                    Of course.
                agent:
                    !right
                    So? What do you think?
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt:Dialog("DIALOG_GREET")
                cxt.quest.param.greeted = true
            end
            if not cxt.quest.param.asked_stance then
                cxt:Opt("OPT_ASK_ABOUT")
                    :Dialog("DIALOG_ASK_ABOUT")
                    :Fn(function(cxt)
                        cxt:Wait()
                        cxt.quest.param.asked_stance = true
                        TheGame:GetGameProfile():AcquireUnlock("DONE_STANCE_QUESTION")
                        ShowStancesTutorial()
                    end)
                    :Dialog("DIALOG_ASK_ABOUT_PST")
            end
            if TheGame:GetGameProfile():HasUnlock("DONE_STANCE_QUESTION") then
                cxt:Opt("OPT_AGREE")
                    :Dialog("DIALOG_AGREE")
                    :UpdatePoliticalStance(cxt.quest.param.oppo_issue, cxt.quest.param.stance_index)
                    :Fn(function(cxt)
                        cxt.quest.param.agreed = true
                        cxt:Dialog("DIALOG_GREET_PST")
                        cxt.quest:Activate("discuss_plan")
                    end)
                    :Pop()
                cxt:Opt("OPT_DISAGREE")
                    :Dialog("DIALOG_DISAGREE")
                    :UpdatePoliticalStance(cxt.quest.param.oppo_issue, -cxt.quest.param.stance_index)
                    :Fn(function(cxt)
                        cxt.quest.param.disagreed = true
                        cxt:Dialog("DIALOG_GREET_PST")
                        cxt.quest:Activate("discuss_plan")
                    end)
                    :Pop()
                cxt:Opt("OPT_IGNORE")
                    :Dialog("DIALOG_IGNORE")
                    :Fn(function(cxt)
                        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport",
                            -1)
                        cxt:Dialog("DIALOG_GREET_PST")
                        cxt.quest:Activate("discuss_plan")
                    end)
                    :Pop()
            end
        end)
    :AskAboutHubConditions("STATE_QUESTIONS",
    {
        ---------------------------------------
        -- Each question is represented by 4 arguments in this table.
        -- 1st arg: Precondition, a function that returns true if this question should show up.
        -- 2nd arg: The question title.
        -- 3rd arg: The dialog to display.
        -- 4th arg: Any post-processing function that happens.
        -- Note: The last item should always be non-null, even if it's an empty function
        ---------------------------------------

        nil,
        "Ask about {agent}'s goal",
        [[
            player:
                What do you plan to do if you become president?
            agent:
                I plan to improving the current state of Havaria by doing the things I promised to do.
                As I already told you my goal.
                I strongly believe that {oppo_stance#pol_stance} can improve Havarian lives significantly.
            player:
                Are you sure that isn't a ruse to get more power?
            {kalandra?
                agent:
                    The power, ultimately, belongs to the people.
                    I am simply representing the will of the people, that's all.
                player:
                    !handwave
                    Sure, sure. That's what they all say.
            }
            {andwanette?
                agent:
                    !handwave
                    Oh please, darling. There's no class in that line of thinking.
                    Power and influence? That's not my style.
                player:
                    !dubious
                    Somehow I find that hard to believe.
            }
            {murder_bay_admiralty_contact?
                agent:
                    Don't be a fool, {player}. Everyone wants power.
                    I just want to make my job more interesting.
                    And if Havarians feel safer because of my actions? Then that's just added bonus.
                player:
                    Well, I appreciate the straightforwardness at least.
            }
            {not (kalandra or andwanette or murder_bay_admiralty_contact)?
                agent:
                    !placate
                    I assure you, the power is just a mean to an end.
                    Ultimately, the goal is make Havaria better than before.
                player:
                    Right.
                    !happy
                    Totally.
            }
        ]],
        nil,

        nil,
        "Ask about {agent}'s plan",
        [[
            player:
                How do you plan to become elected? How are you going to gather the voters?
            {andwanette?
                agent:
                    !handwave
                    It's simple, darling.
                    When in doubt, people will vote for the candidate that they recognize.
                    !permit
                    Given that I am a huge celebrity already in the Pearl, many people will vote for me simply because they are a huge fan.
                player:
                    !dubious
                    This sounds less of an election and more of a popularity contest.
                agent:
                    !handwave
                    Oh please, darling. That's how <i>all</> elections work.
            }
            {spark_contact?
                agent:
                    It's easy.
                    People don't like paying taxes. I promised them that I will reduce their taxes.
                    Naturally, people will vote for me to reduce their taxes so they get more money in their pockets.
                player:
                    Surely it can't be that easy.
                {agreed?
                    player:
                        I mean, I agree with your stance, but surely that can't be enough to win the votes?
                    agent:
                        Come on, {player}. Who actually wants to pay taxes?
                        Even the Rise don't.
                    player:
                        I can see your point.
                }
                {not agreed?
                    player:
                        I mean, you can't run a country without money? How are you going to get those without taxes?
                    agent:
                        Well, they don't need to know that.
                        What they do know is that I promised to cut their taxes, and I am going to do exactly that.
                    player:
                        That's... kind of devious.
                }
            }
            {kalandra?
                agent:
                    !hips
                    Of course I have a plan.
                    Why do you think I pushed so hard for an election in the first place?
                player:
                    !surprised
                    Wait, the election was your idea?
                agent:
                    !shrug
                    Well, not necessarily. But I am a huge advocate for it.
                    A huge reason is that the laborers outnumber our oppressors by a lot.
                    If I can get all the laborers by my side in the election, the revolution will surely succeed.
                {player_sal?
                    player:
                        Isn't that what our parents said ten years ago?
                        Before, well, you know.
                    agent:
                        But this time, it's going to be different.
                        Democracy is a way to give the people a voice, and I will make sure their voices get heard.
                }
                {not player_sal?
                    player:
                        Yeah, but how are you confident that every laborer has the same opinion?
                        Most laborers I talk to don't seem like the revolutionary type.
                    agent:
                        They don't seem like it because they fear of speaking out against the establishment.
                        But with the election, they can freely express their true feeling without fear of retaliation.
                }
            }
            {murder_bay_bandit_contact?
                player:
                    I mean, how are you going to convince the voters to vote for the leader of Spree?
                agent:
                    If they know what's good for them, they will vote for the person who promises them full Havaria independence.
                    Even if that person is the Scourge of Murder Bay {agent.self}.
                player:
                    Ah.
            }
            {not (andwanette or spark_contact or kalandra or murder_bay_bandit_contact)?
                agent:
                    Why do you think I will answer that question?
                player:
                    !bashful
                    I don't know? Just trying to start a conversation, that's all.
                agent:
                    !crossed
                    By asking for my campaign strategy? When we both know that we are opponents in the election.
                {agreed?
                    And us agreeing on one particular topic doesn't change that.
                }
                    No. I'm not going to give you free information so you can use it against me.
                player:
                {(player_smith and vixmalli)?
                    !sigh
                    You never change, Vix.
                }
                {not (player_smith and vixmalli)?
                    !placate
                    Geez. I get your point.
                }
            }
        ]],
        nil,

        nil,
        "Ask where to find {agent}",
        [[
            player:
                If I want to find you, where should I go?
            agent:
            {agreed?
                Since we have similar goals, I guess I'll tell you.
                You can find me at {oppo_location#location}. That's where my base is.
                The people there may or may not like you, I can't make any promises.
                If you want to talk about potential alliance, meet me there.
            player:
                That sounds very reassuring.
            }
            {not agreed?
                If you ever change your mind about your political position, you can find me at {oppo_location#location}.
                There, we can discuss our potential alliance.
                !crossed
                Provided you can prove yourself first, of course.
            player:
                !handwave
                Yeah, what else is new?
            }
        ]],
        function(cxt)
            local learn_location = true-- ((cxt:GetAgent():GetRelationship() > RELATIONSHIP.NEUTRAL) or cxt.quest.param.agreed) and not (cxt:GetAgent():GetRelationship() < RELATIONSHIP.NEUTRAL)
            if learn_location then
                DemocracyUtil.DoLocationUnlock(cxt, cxt.quest.param.oppo_location)
            end
        end,
    })
QDEF:AddConvo("meet_opposition", "primary_advisor")
    :Loc{
        OPT_DONE_QUEST = "Finish Up",
        DIALOG_DONE_QUEST = [[
            player:
                [p] I'm done with intel gathering.
            agent:
                Time for you to do some work.
            {no_assassin?
            player:
                [p] I'm a big shot now. What if there are assassins coming after me?
            agent:
                If you want to feel safer, hire a bodyguard or something.
            }
            {not no_assassin and billed_baron_response?
            agent:
                [p] By the way, why do I have a bill for Baron response?
            player:
                I'm sorry for looking for help when I am being attacked by assassins, okay?
            agent:
                That is not very cash money of you.
                Hire your own bodyguard. Don't make me pay for your problems.
            }
            {not no_assassin and not billed_baron_response?
            player:
                [p] The world seems a bit dangerous for me now.
            agent:
                I guess you're pretty shaken from the yesterday's assassination, huh?
                If you want to feel safer, hire a bodyguard or something.
            }
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_ASK_ABOUT")
            :IsHubOption(true)
            -- :Dialog("DIALOG_QUESTION")
            :GoTo("STATE_QUESTIONS")
        cxt:Opt("OPT_DONE_QUEST")
            :SetQuestMark( cxt.quest )
            :Fn(function(cxt)
                cxt.quest.param.billed_baron_response = cxt:GetAgent():HasMemory("BILLED_BARON_RESPONSE")
                cxt.quest.param.no_assassin = TheGame:GetGameState():GetMainQuest() and TheGame:GetGameState():GetMainQuest().param.no_assassin
            end)
            :Dialog("DIALOG_DONE_QUEST")
            :Fn(function(cxt)
                QuestUtil.SpawnQuest("CAMPAIGN_BODYGUARD")
            end)
            :CompleteQuest()
            :DoneConvo()
    end)
    :AttractState("STATE_ATTRACT", function(cxt) return not cxt.quest.param.talked_to_advisor end)
        :Loc{
            DIALOG_INTRO = [[
                {not greeted?
                    agent:
                        If you haven't talked to {opposition} already, you should probably do so.
                        You might gain some insights as to what other candidates are up to.
                }
                {greeted?
                    agent:
                        So you talked to {opposition}. What do you make of {opposition.himher}?
                    player:
                        {opposition.HeShe} is an interesting character, certainly.
                    {agreed?
                        We have a lot of similarities in terms of ideology. We could probably get along.
                    agent:
                        !agree
                    {advisor_diplomacy?
                        It's good that you found a fellow candidate who you can vibe with.
                        But remember, no matter how based they seem, you are still political opponents.
                    }
                    {not advisor_diplomacy?
                        Glad you found a potential ally so quickly.
                        But remember, you are still political opponents, so don't get to attached to {opposition.himher}.
                    }
                        !permit
                        Eventually, only one of you can become the president, and it should be you.
                    player:
                        !hips
                        I wouldn't have it any other way.
                    agent:
                        Still, it is good to find an ally if you can. You can't win this election alone.
                        You can ask {opposition} about potential alliances.
                        Or go ask around and see if you can find other candidates with similar ideologies. That might be a start.
                    }
                    {disagreed?
                        We have some ideological differences, but we might still get along.
                    agent:
                        !thought
                        Hmm... If this keeps up, you two might eventually clash against each other.
                        And you can't do this all by yourself, even with my help.
                        If you want to win, you will need allies.
                        Go ask around and see if you can find candidates with similar ideologies. That might be a start.
                    }
                    {not (agreed or disagreed)?
                    agent:
                        You don't sound so sure.
                    player:
                        I don't know what to make of {opposition.himher}.
                    agent:
                        Don't worry about it. You can make up your mind after you interacted with the candidates more.
                        But just remember: if you want to win the election, you will need allies.
                        Go ask around and see if you can find candidates with similar ideologies. That might be a start.
                    }
                    ** You can now talk to other candidates with similar interests and form an alliance!
                }
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            if cxt.quest.param.greeted and not cxt.quest.param.talked_to_advisor then
                QuestUtil.SpawnQuest("CAMPAIGN_NEGOTIATE_ALLIANCES")
            end
            cxt.quest.param.talked_to_advisor = true
        end)

    :AskAboutHubConditions("STATE_QUESTIONS",
    {
        nil,
        "Ask about oppositions",
        [[
            player:
                I didn't know there are so many strong opponents also running for leadership! What should we do about them?
            agent:
                !shrug
                Right now? There's not much you can do in particular.
            {advisor_manipulate?
                Logically speaking, focusing on your campaign and standing out will improve the chance of people voting for you.
                But hypothetically, if you know everything about your opponents.
                Their platforms, their ideals, and their strategies.
                Then, wouldn't you agree that when you finally face one of them during a debate, you will stand a better chance?
            player:
                !shrug
                I guess so?
            }
            {advisor_diplomacy?
                As long as you stay based and appeal to the people, you can win this.
                Meanwhile, you should learn more about your fellow candidates.
                You never know when the personal info of one of your opponents will come in handy during a debate.
            player:
                !dubious
                That's one way to go about it.
            }
            {not (advisor_manipulate or advisor_diplomacy)?
                You should keep gathering support.
                On the other hand, you should learn more about your opponent.
                That way, when you eventually faces them in a debate, you will know what to say.
            player:
                !agree
                Sounds like a plan.
            }
            agent:
                You can talk to {opposition} right now and see what you can learn about {opposition.himher}.
            {advisor_hostile?
                Of course, nobody knows more about your opponents better than me, so you should ask me about them.
            }
            {not advisor_hostile?
                If you want me to give a summary of your opponents, though, you can ask me.
            }
        ]],
        nil,

        nil,
        "Ask about candidates...",
        [[
            player:
                I have some questions regarding the other candidates...
        ]],
        function(cxt)
            -- A hack to allow you to ask again. Not really elegant
            for optdata, _ in pairs(cxt.enc.scratch.STATE_QUESTIONS_HISTORY) do
                if optdata.opt_id == "OPT_2" then
                    cxt.enc.scratch.STATE_QUESTIONS_HISTORY[optdata] = nil
                end
            end
            for id, data in pairs(DemocracyConstants.opposition_data) do
                cxt.enc.scratch[id .. "_met"] = DemocracyUtil.GetMainQuestCast(id) and DemocracyUtil.GetMainQuestCast(id):KnowsPlayer()
            end
            cxt:GoTo("STATE_OPPOSITION_QUESTIONS")
        end,
    })
    :AskAboutHubConditions("STATE_OPPOSITION_QUESTIONS",
    {
        nil,
        "Ask about the Admiralty candidate",
        [[
            {not candidate_admiralty_met?
                player:
                    !interest
                    I'm assuming the Admiralty is definitely running?
                agent:
                    !agree
                    Of course.
                    !permit
                    Their candidate is Oolo Ollowano, an officer from Murder Bay.
            }
            {candidate_admiralty_met?
                player:
                    !interest
                    Oolo must be the candidate for the Admiralty, right?
                agent:
                    !agree
                    That's right.
            }
            player:
                !thought
                Why is Oolo running for president?
            {player_smith?
                !crossed
                More importantly, why isn't Mullifee running?
            agent:
                !shrug
                No idea. You need to ask her personally, probably.
                Probably they figured that the Admiralty only needs one candidate, and it's Oolo.
            player:
                !sigh
                It's such a shame, though. Mullifee would probably be a great candidate.
            agent:
                !handwave
                Anyway, you know how the Admiralty is.
            }
            {not player_smith?
            agent:
                !handwave
                You know how the Admiralty is.
            }
                They want to completely control Havaria by themselves, instead of the quasi-legal status they have currently.
                As such, they are pushing really hard on <!pol_stance_security_2>Universal Security</>, where every person is protected by the Admiralty.
                !point
                Whether you like it or not.
            player:
                !thought
                That sounds really sketchy, but I can see the appeal to some people.
            {advisor_diplomacy?
            agent:
                Although... From the looks of things, Oolo seems to have a particular interest in fighting against crime in Havaria, even more so than your standard political reason.
                !shrug
                Maybe she is interested in more than just a simple power grab?
                I can respect such based behaviour, even though I don't agree with what she is doing.
            }
        ]],
        nil,
        nil,
        "Ask about the Spree candidate",
        [[
            player:
                !interest
                Do people really want a Spree to become the president?
            agent:
                !shrug
                Well, half of the population is probably some sort of criminal, and the other half is another sort of criminal, but less blatant.
            {advisor_manipulate?
                Besides, logically speaking, the background of the candidate should matter less than the platform they run on.
            player:
                !agree
                Fair point.
            }
            {advisor_diplomacy?
                Besides, if the candidate is based, being a criminal lord would just add to the basedness factor.
            player:
                !dubious
                You've lost me.
            }
            {not (advisor_manipulate or advisor_diplomacy)?
                As long as the platform is sound, who cares if the candidate is a Spree?
            player:
                !agree
                Fair point.
            }
            agent:
                Anyway, Nadan Undar, the leader, is their candidate.
                He promises <!pol_stance_independence_2>full independence of Havaria</> from the Deltrean empire.
            player:
                !palm
                Ugh. I know I'm supposed to be a politician and all, but geopolitics makes my head hurt.
            agent:
            {advisor_diplomacy?
                Well, the Havarians are fed up with Deltrean overreach.
                Havaria is the land of the free, after all, and it doesn't need the cringe Deltrean rule.
            player:
                !dubious
                Since when is Havaria the land of the free?
            }
            {advisor_manipulate?
                !sigh
                Logically speaking, the people who supports him make no sense.
                Having Deltrean control Havaria removes the legal gray area that causes criminals to become rampant.
                If you are not a criminal, why would you support Havarian independence?
                {pro_security?
                    player:
                        !permit
                        You said so yourself, didn't you?
                        Everyone in Havaria is some sort of criminal or the other.
                    agent:
                        !thought
                        That's... true.
                }
                {not pro_security?
                    player:
                        !crossed
                        Okay, I see why some people would like Havaria to be independent.
                }
            }
            {advisor_hostile?
                Well, nobody knows more about geopolitics more than me.
                Which is why you should avoid it entirely. It's boring as Hesh.
            player:
                !interest
                That's... unexpected of you.
            }
        ]],
        nil,
        nil,
        "Ask about the Spark Baron candidate",
        [[
            {player_arint?
                player:
                    !interest
                    I'm assuming that Fellemo is running.
                    Is there anyone else from the Spark Baron running as well?
                agent:
                    !shrug
                    As far as I am aware, other than you and him, there is no one else from the Spark Baron running.
                    Seems you already know Fellemo, huh?
                player:
                    !sigh
                    All too well.
            }
            {not player_arint and candidate_baron_met?
                player:
                    !interest
                    I'm assuming that Fellemo is the one running for the Barons, right?
                agent:
                    !agree
                    That's right.
            }
            {not player_arint and not candidate_baron_met?
                player:
                    !interest
                    There must be someone from the Spark Barons running, right?
                agent:
                    !agree
                    There sure is.
                    Their candidate is Lellyn Fellemo, a retired Admiralty solider, who now is a regional officer managing Grout Bog.
                    {advisor_diplomacy?
                        A based guy, I tell you.
                    * A great non-answer from {agent}. Classic.
                    }
                    {not advisor_diplomacy?
                            !cagey
                            Although... if I'm honest, I am not sure if he is really a capable candidate.
                        player:
                        {player_rook?
                            !happy
                            That's what he wants you to think.
                        agent:
                            !dubious
                            Is he now?
                        }
                        {not player_rook?
                            !shrug
                            I don't know. I don't think anyone can get this far by being incompetent.
                        agent:
                            !thought
                            Good point.
                        }
                    }
            }
            player:
                What's Fellemo's angle, then?
            agent:
                He wants a <!pol_stance_fiscal_policy_-2>Laissez Faire</> approach to the economy.
                !permit
                Generally speaking, he wants to cut taxes, and basically do nothing else.
                !point
                That's by design, of course. He thinks the government should stay out of people's lives.
            {anti_fiscal_policy?
                player:
                    !agree
                    I agree. Taxation is theft.
                agent:
                {advisor_manipulate?
                    !crossed
                    Logically speaking, everything needs money to function, even the government.
                    Without taxes, the government will need something else.
                }
                {not advisor_manipulate?
                    !shrug
                    Well, the government needs some ways to make money, if not by taxes.
                }
            }
            {not anti_fiscal_policy?
                player:
                    How does he plan to pay for the government's expenses if he plans to cut taxes?
                agent:
                    !shrug
                    No idea.
            }
        ]],
        nil,
        nil,
        "Ask about the Rise candidate",
        [[
            {not candidate_rise_met?
                player:
                    !interest
                    Is there anyone representing the Rise?
                agent:
                    !agree
                    Of course. Prindo Kalandra, a foreman, is representing them.
                {player_sal?
                    player:
                        !happy
                        A foreman? Glad to know that Prindo is doing so well for herself.
                    agent:
                        !dubious
                        You two are on a first name basis?
                    player:
                        !dubious
                        Uh... yeah? Is that not normal, somehow?
                    agent:
                        !shrug
                        I mean, for some reason, everyone refers to her by last name only, even though everyone else is referred to by first name.
                    {spark_barons?
                        !point
                        Well... Except Fellemo as well, I guess.
                    }
                }
            }
            {candidate_rise_met?
                {not player_sal?
                    player:
                        !interest
                        Kalandra is representing the Rise, correct?
                    agent:
                        !agree
                        That's right.
                }
                {player_sal?
                    player:
                        Please tell me that Prindo is running for the Rise, right?
                    agent:
                        !dubious
                        Uh... I guess, yeah?
                    player:
                        !dubious
                        What do you mean? You seems unsure.
                    agent:
                        It's just... It's a bit weird hearing Prindo Kalandra being referred to by first name only.
                        !thought
                        Actually, the real weird thing here is that people refer to everyone else by first name, but not her, for some reason.
                    {spark_barons?
                        !point
                        And Fellemo. Him too.
                    }
                }
            }
            player:
                And I'm assuming the Rise runs on a <!pol_stance_labor_law_1>pro-worker</> platform?
            agent:
                !spit
                Pretty much.
                It would be very popular among the workers, no doubt.
                But to anyone else? Nah.
            player:
                Sounds like you don't like that.
            agent:
                Of course not.
            {advisor_diplomacy?
                That is cringe.
                |
                That's bad for business.
            }
                Imagine if workers can just slack off, and no one can lay a finger on them.
                But, of course, I don't care what you believe as long as you can win.
        ]],
        nil,
        nil,
        "Ask about the Cult candidate",
        [[
            {not candidate_cult_met?
                player:
                    So who's representing the Cult of Hesh?
                agent:
                    It's Vixmalli Banquod.
                {player_smith?
                    He's a member of one of the most prestigious-
                player:
                    Yeah, I know who he is.
                    !thought
                    Damn it, Vix. You are not going to make it easy for me, huh?
                    Anyway, what does he want?
                }
                {not player_smith?
                    He's a member of one of the most prestigious families in Havaria.
                    He basically bought his way to the top of the Cult's hierarchy.
                player:
                    Well, that sounds good and all, but what does he want?
                }
            }
            {candidate_cult_met?
                {not player_smith?
                    player:
                        Is Vixmalli representing the Cult of Hesh?
                    agent:
                        !agree
                        That's right.
                }
                {player_smith?
                    player:
                        Is Vix representing the Cult of Hesh?
                    agent:
                        !dubious
                        Vixmalli? Yeah.
                }
                {advisor_manipulate?
                    agent:
                        !sigh
                        A shame, though. I can think of a better candidate than him.
                }
                player:
                    Well, what does he want?
            }
            {not advisor_manipulate?
                agent:
                    !shrug
                    It's the Cult. They always want more power.
                    !spit
                    Which is why his entire platform is based on promoting <!pol_stance_religious_policy_2>Heshian values</>.
                player:
                    !dubious
                    Really? That's it? And he think people are going to vote for him because of that?
                agent:
                    !shrug
                {advisor_diplomacy?
                    Well, half of the population is cringe like that.
                    Believing a giant jellyfish that might not even be real, and doing what the Cult tells them to do just because they say so.
                }
                {not advisor_diplomacy?
                    Well, half of the population is Heshian anyway.
                    {advisor_hostile?
                        !thumb
                        Believe me, nobody knows cults better than me, and they would rather let a cult tell them what to do than think for themselves.
                        * Somehow, you feel like {agent}'s statement comes from personal experience.
                    }
                }
            }
            {advisor_manipulate?
                agent:
                    !permit
                    Well, as a Heshian, logically speaking, he wants to <!pol_stance_religious_policy_2>exercise Hesh's will</>.
                    That usually means implementing policies that the Cult likes, of course.
                player:
                    !dubious
                    Really? That's it? And he think people are going to vote for him because of that?
                agent:
                    !shrug
                    You know how it is. Half of Havarian population believes in the Heshian faith.
                    Logically speaking, some of them will vote purely based on what they see as Hesh's will.
                    Given that Vixmalli claims to exercise Hesh's will, we can logically conclude that a sizable population will vote for him because of this.
                player:
                    !dubious
                    That sounds awfully objective and reasonable. Are you sure you are a Heshian priest?
                {not liked?
                    agent:
                        !angry
                        I <i>am</> a Heshian priest! Do you not see my title?
                    * Well, {agent}'s title does say "{agent.identity}". I think that settles it.
                    agent:
                        !neutral
                }
                {liked?
                    agent:
                        Everyone has a different way of showing faith, and it doesn't change the fact that I am a priest.
                        !crossed
                        I thought you would know better, {player}.
                    player:
                        !placate
                        Look, I didn't mean to offend you, alright? If my remark upsets you, then I apologize.
                    agent:
                        !sigh
                        It's fine. I get those comments a lot, and I won't hold it against you.
                }
            }
        ]],
        nil,
        nil,
        "Ask about the Jakes candidate",
        [[
            player:
                I'm assuming the Jakes has someone that represents them?
            agent:
                Actually, no.
                The Jakes is a worker union. They don't have a hierarchy like other factions, so they don't have a particular candidate.
                However, there is a candidate trying to levy support from the Jakes in particular.
                Her name's Andwanette. Big character in the foam before, but now she's got a fire in her belly to take it to new heights.
            {candidate_jakes_met?
                player:
                    Andwanette? I thought she isn't affiliated with any particular faction?
                agent:
                    She isn't, but she is indeed trying to appeal to the Jakes with her platform.
            }
            player:
                So what are her actual viewpoints, or is she just waffling to the Jakes?
            agent:
                She's a merchant who deals in back-alley goods. She wants to put those goods on a market that isn't the black market.
                Expect her to lean towards <!pol_stance_substance_regulation_-2>removing lots of existing regulations</>.
                !shrug
            {advisor_hostile or advisor_diplomacy?
                Can't say I exactly disagree with her on that. Just don't believe she'll make it, is all.
                |
                The fact of the matter is, while people might agree with her ideas, her lack in political experience may be her downfall.
            }
            player:
                Fair enough.
        ]],
        function()end,
    })
