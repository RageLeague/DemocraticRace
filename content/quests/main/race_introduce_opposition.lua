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
                    What's your goal in the race? What drives you forward?
                agent:
                    I'm glad you asked.
                * {agent} clears {agent.hisher} throat loudly.
                    %opposition_intro idea_monologue {opposition_id}
                player:
                {not spark_contact?
                    I must say, I'm stunned by your rhetoric.
                agent:
                    I bet you are!
                }
                {spark_contact?
                    Wow, that... definitely is one of the speeches I've ever heard.
                agent:
                    I'm glad you liked it.
                }
                agent:
                    !permit
                    What say you? Are you persuaded by my speech?
            ]],
            OPT_AGREE = "Agree",
            DIALOG_AGREE = [[
                player:
                    Believe me, friend. I'm a firm believer in your ideology.
                agent:
                    Ah-ha, my dear {player}. We needn't fight at all in this race.
                player:
                    Now, Now, I still disagree with you on a number of things.
                    You're still going to lose in this Democratic Race!
                agent:
                    Hark! Well, when you falter, know your voters will join me in the end.
            ]],
            OPT_DISAGREE = "Disagree",
            DIALOG_DISAGREE = [[
                player:
                    I can't say I do.
                agent:
                    A shame. We could've been great allies.
                player:
                    But aren't we political opponents, though?
                agent:
                    Yeah, you're right.
                    Well, good luck with your campaign, because I'll beat you.
            ]],
            OPT_IGNORE = "Remain silent on this issue",
            DIALOG_IGNORE = [[
                player:
                    I don't want to make any statement regarding this issue.
                agent:
                    Oh well.
                    Just be warned. You can't deflect the issue forever. Especially on these important issues.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_GREET")
            cxt:Opt("OPT_AGREE")
                :Dialog("DIALOG_AGREE")
                :UpdatePoliticalStance(cxt.quest.param.oppo_issue, cxt.quest.param.stance_index)
                :Fn(function(cxt)
                    cxt.quest.param.greeted = true
                    cxt.quest.param.agreed = true
                    cxt:Dialog("DIALOG_GREET_PST")
                    cxt.quest:Activate("discuss_plan")
                end)
            cxt:Opt("OPT_DISAGREE")
                :Dialog("DIALOG_DISAGREE")
                :UpdatePoliticalStance(cxt.quest.param.oppo_issue, -cxt.quest.param.stance_index)
                :Fn(function(cxt)
                    cxt.quest.param.greeted = true
                    cxt.quest.param.disagreed = true
                    cxt:Dialog("DIALOG_GREET_PST")
                    cxt.quest:Activate("discuss_plan")
                end)
            cxt:Opt("OPT_IGNORE")
                :Dialog("DIALOG_IGNORE")
                :Fn(function(cxt)
                    DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport",
                        -1)
                    cxt.quest.param.greeted = true
                    cxt:Dialog("DIALOG_GREET_PST")
                    cxt.quest:Activate("discuss_plan")
                end)
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
            agent:
                !placate
                I assure you, the power is just a mean to an end.
                Ultimately, the goal is make Havaria better than before.
            player:
                Right.
                !happy
                Totally.
        ]],
        nil,

        nil,
        "Ask about {agent}'s plan",
        [[
            player:
                How do you plan to become elected?
            agent:
                I mean, same as everyone else.
            player:
                Can you give a more detailed answer?
            agent:
                Why should I? You're my opponent.
            player:
                Fair enough.
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
                        Glad you found a potential ally so quickly.
                        But remember, you are still political opponents, so don't get to attached to {opposition.himher}.
                        Eventually, only one of you can become the president, and it should be you.
                    player:
                        !thought
                        ...
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
        "Ask about opposition",
        [[
            player:
                What does it mean for me now that there are these oppositions?
            agent:
                It means that they will also running for president, pulling votes that would otherwise be yours to them.
                Since everyone can only vote one person at a time, more oppositions means less votes for you.
            player:
                What should I do to combat this?
            agent:
                You need to eliminate the oppositions.
            player:
                You want me to kill them?
            agent:
                !placate
                What? Of course not.
            {not advisor_manipulate?
                As the campaign goes on, some people will naturally drop out because they don't have enough support.
                If you can ally with them, their voters will vote for you if their primary candidate drops out.
            }
            {advisor_manipulate?
                Logically speaking, if someone don't have enough support, they have no chance at winning.
                And let's say, hypothetically, that you have similar ideology with said candidate.
                Then, logically, their voters will vote for the next best candidate that is most likely to win.
                It's called Strategic Voting.
            }
            player:
                That sounds like a much better plan.
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
            cxt:GoTo("STATE_OPPOSITION_QUESTIONS")
        end,
    })
    :AskAboutHubConditions("STATE_OPPOSITION_QUESTIONS",
    {
        nil,
        "Ask about the Admiralty candidate",
        [[
            player:
                I'm assuming the Admiralty is surely running?
            agent:
                Of course.
                Their candidate is Oolo Ollowano, an officer from Murder Bay.
            player:
                Why is she running for president?
            agent:
                !handwave
                You know how the Admiralty is.
                They want to maintain control in Havaria.
                As such, they are running on the platform of <!pol_stance_security_2>Universal Security</>, where every person has access to Admiralty protection.
                It will be popular among Civilians and the Admiralty, of course. But it will be very unpopular with people who dislike them or their rivals.
        ]],
        nil,
        nil,
        "Ask about the Spree candidate",
        [[
            player:
                Do people really want a Spree to become the president?
            agent:
                The entire point of the Truce Deal is to allow anyone to run, regardless of their background.
                Anyway, Nadan Undar, the leader, is their candidate.
            player:
                What is he running on?
            agent:
                He's running on <!pol_stance_independence_2>Havarian Independence</>.
                The Spree likes it because they can be more lawless, but it is popular among other voting groups as well.
                People are fed up with Deltree's reach, especially towards the Admiralty for controlling their lives.
                Although the more prestigious people would rather have Havaria be totally annexed.
        ]],
        nil,
        nil,
        "Ask about the Spark Baron candidate",
        [[
            {player_arint?
            player:
                I'm assuming that Fellemo is running.
                Is there anyone else from the Spark Baron running as well?
            agent:
                As far as I am aware, other than you and him, there is no one else from the Spark Baron running.
                Seems you already know Fellemo, huh?
            player:
                !sigh
                All too well.
            }
            {not player_arint?
            player:
                There must be someone from the Spark Barons running, right?
            agent:
                !agree
                There sure is.
                Their candidate is Lellyn Fellemo, a retired Admiralty solider, who now is a regional officer managing Grout Bog.
                !cagey
                Although... if I'm honest, I am not sure if he is really a capable candidate.
                He doesn't seem to have a concrete plan, and he doesn't seem to put a lot of work into the campaign.
            }
            player:
                What's Fellemo's angle, then?
            agent:
                He wants a <!pol_stance_fiscal_policy_-2>Laissez Faire</> approach to the economy.
                Basically, the government leaves the economy alone by removing government services and taxes.
                Of course, many people would want that, especially the Spark Barons.
                They don't want their hard-earned money to go to leeches that is the state.
                But it would mean that the government can't get much funding through taxes.
                And I suppose can't get the help they need from the government, but that is the reality of Havaria.
            player:
                How does he plan to make Havaria function if he abolish taxes?
            agent:
                No clue.
                You should ask him about it.
                Although I doubt you will get a straight answer from him.
        ]],
        nil,
        nil,
        "Ask about the Rise candidate",
        [[
            player:
                Is there anyone representing the Rise?
            agent:
                Of course. Prindo Kalandra is the one representing them.
                In fact, she seems very supportive of the election.
                Perhaps it's her idea in the first place.
            player:
                Sounds good.
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
                He basically bought his way to the top of the Cult's Hierarchy.
            player:
                Well, that sounds good and all, but what does he want?
            }
            {not cult_of_hesh?
                It's the cult. They always want more power.
                But they don't really have anything that jives with the public voting blocks.
                Well, everything except <!pol_stance_religious_policy_2>preserve artifacts</>.
                They'll likely just start preaching about Hesh declaring them the president.
                Their supporters are going to be rigidly pro-cult unless you stoop to their level.
                If you do though, watch your back from those who want the artifacts for profit.
            }
            {cult_of_hesh?
                To <!pol_stance_religious_policy_2>preserve artifacts</>, obviously.
                He's probably going to claim that Hesh itself supports him to be the president.
                You know how it is.
            player:
                What a surprise.
            agent:
                His supporters are probably those who believe in the holiness of those artifacts.
                But you know how it is in Havaria. Some heathens probably wants to sell them for profits.
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
            player:
                So what are her actual viewpoints, or is she just waffling to the Jakes?
            agent:
                She's a merchant who deals in Back-alley goods. She wants to put those goods on a market that isn't the black market.
                Expect her to lean towards <!pol_stance_substance_regulation_-2>removing lots of existing regulations</>.
                !shrug
            {advisor_hostile or advisor_diplomacy?
                Can't say I exactly disagree with her on that. Just don't believe she'll make it, is all.
                |
                The fact of the matter is, while people might agree with her ideas, her lack in political experience may be her downfall.
            }
            player:
                Fair enough.
                Though I imagine the people in authority won't like it.
        ]],
        function()end,
    })
