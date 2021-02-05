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
        table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.VISITOR})
        table.insert(t, { agent = quest:GetCastMember("opposition"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.VISITOR})
    end,
    on_complete = function(quest)
        if quest:GetCastMember("primary_advisor") then
            quest:GetCastMember("primary_advisor"):GetBrain():SendToWork()
        end
    end,
    -- on_start = function(quest)
        
    -- end,
}
:AddLocationCast{
    cast_id = "noodle_shop",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("MURDERBAY_NOODLE_SHOP"))
    end,
    
}
:AddObjective{
    id = "go_to_bar",
    title = "Visit the Noodle Shop",
    desc = "Visit the noodle shop and talk to your advisor about the upcoming plan.",
    mark = {"noodle_shop"},
    state = QSTATUS.ACTIVE,

    on_complete = function(quest)
        quest:Activate("discuss_plan")
        quest:Activate("meet_opposition")
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
    mark = {"opposition"}
}
:AddCastByAlias{
    cast_id = "opposition",
    alias = available_opposition,
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

QDEF:AddConvo("go_to_bar")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt.location == cxt.quest:GetCastMember("noodle_shop") end)
        :Loc{
            DIALOG_INTRO = [[
                * You arrive at the noodle shop.
                player:
                    !left
                primary_advisor:
                    !right
                    The interview isn't the only thing I set up last night.
                    I set up a meet and greet with another one of the candidates in the Race.
                    You'd do well to gather some intel from them.
                * {opposition} walks up to you and extends a hand.
                opposition:
                    !right
                    Hello there. My name is {opposition}. You may have heard of me already down the grapevine.
                player:
                    {player}. Charmed to meet you, {opposition.sirma'am}.
                opposition:
                    !happy
                    Respectful to their future leader? I like that in a loser.
                primary_advisor:
                    !right
                    Don't pay them any mind. With luck, they'll fall off the weighside when the pressure mounts.
                player:
                    So why am I gathering intel on a loser, then?
                primary_advisor:
                    Well, I said with luck.
                    You're not the only one in the election. Neither are they your only opposition.
                    There's many candidates out there, vying for presidency over Havaria.
                    You'll have to deal with the tug and pull of supporters with these guys.
                    I'll clam up. Go ingratiate yourself to them, see if they'll spill any beans.
            ]],
        }
        :Fn(function(cxt)
            cxt.quest:Complete("go_to_bar")
            cxt:Dialog("DIALOG_INTRO")
            DemocracyUtil.TryMainQuestFn("DoRandomOpposition", 3)
        end)
QDEF:AddConvo("meet_opposition", "opposition")
    :Loc{
        OPT_GREET = "Greet {agent}",
        DIALOG_GREET = [[
            player:
                So I believe we should introduce ourselves a scoche bit better.
                If you're going to win, surely you've nothing to hide from your opponents.
            agent:
                Nothing I couldn't tell you about me that the public doesn't already.
                Ask away.
            player:
                What's your goal in this democratic race? What drives you forward?
            agent:
                I'm glad you asked.
            * {agent} clears {agent.hisher} throat loudly.
                %opposition_intro idea_monologue {opposition_id}
            player:
                I must say, i'm stunned by your rhetoric.
            agent:
                I bet you are!
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
        -- local opposition_data = DemocracyConstants.opposition_data[cxt.quest.param.opposition_id]
        -- if opposition_data and opposition_data.platform then
        --     cxt.quest.param.oppo_issue = DemocracyConstants.issue_data[opposition_data.platform]
        --     if cxt.quest.param.oppo_issue then
        --         local stances = opposition_data.stances[opposition_data.platform]
        --         cxt.quest.param.oppo_stance = cxt.quest.param.oppo_issue.stances[stances]
        --         cxt.quest.param.stance_index = stances
        --     end
        -- end
        if not cxt.quest.param.greeted then
            cxt:Opt("OPT_GREET")
                :Fn(function(cxt)
                    
                end)
                :Dialog("DIALOG_GREET")
                :Fn(function(cxt)
                    -- local opposition_data = DemocracyConstants.opposition_data[cxt.quest.param.opposition_id]
                    -- local platform = opposition_data.platform
                    -- local platform_stance
                    -- if platform then
                    --     platform_stance = opposition_data.stances[platform]
                    -- end
                    cxt:Opt("OPT_AGREE")
                        :Dialog("DIALOG_AGREE")
                        :UpdatePoliticalStance(cxt.quest.param.oppo_issue, cxt.quest.param.stance_index)
                        :Fn(function(cxt)
                            -- DemocracyUtil.TryMainQuestFn("DeltaGroupFactionSupport",
                            --     opposition_data.faction_support, 1)
                            -- DemocracyUtil.TryMainQuestFn("DeltaGroupWealthSupport",
                            --     opposition_data.wealth_support, 1)
                            -- if platform and platform_stance then
                            --     DemocracyUtil.TryMainQuestFn("UpdateStance", platform, platform_stance)
                            -- end
                            cxt.quest.param.greeted = true
                            cxt.quest.param.agreed = true
                            cxt:Dialog("DIALOG_GREET_PST")
                        end)
                    cxt:Opt("OPT_DISAGREE")
                        :Dialog("DIALOG_DISAGREE")
                        :UpdatePoliticalStance(cxt.quest.param.oppo_issue, -cxt.quest.param.stance_index)
                        :Fn(function(cxt)
                            -- DemocracyUtil.TryMainQuestFn("DeltaGroupFactionSupport",
                            --     opposition_data.faction_support, -1)
                            -- DemocracyUtil.TryMainQuestFn("DeltaGroupWealthSupport",
                            --     opposition_data.wealth_support, -1)
                            -- if platform and platform_stance then
                            --     DemocracyUtil.TryMainQuestFn("UpdateStance", )
                            -- end
                            cxt.quest.param.greeted = true
                            cxt.quest.param.disagreed = true
                            cxt:Dialog("DIALOG_GREET_PST")
                        end)
                    cxt:Opt("OPT_IGNORE")
                        :Dialog("DIALOG_IGNORE")
                        :Fn(function(cxt)
                            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport",
                                -1)
                            cxt.quest.param.greeted = true
                            cxt:Dialog("DIALOG_GREET_PST")
                        end)
                end)
        
        else
            cxt:Opt("OPT_ASK_ABOUT")
                :IsHubOption(true)
                :Dialog("DIALOG_QUESTION")
                :GoTo("STATE_QUESTIONS")
        end
    end)
    --
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
            {(agreed or liked) and not disliked?
                Since we have similar, I guess I'll tell you.
                You can find me at {oppo_location#location}. That's where my base is.
                The people there may or may not like you, I can't make any promises.
                If you want to talk about potential alliance, meet me there.
            player:
                That sounds very reassuring.
            }
            {not ((agreed or liked) and not disliked)?
                !angry_shrug
                What? So you can send an assassin to my door?
            player:
                !placate
                That's not what I-
            agent:
                {not disliked?
                    !sigh
                    It's just a precaution, you see.
                    I don't know you, you don't know me. Gotta be careful.
                    It's nothing personal, I assure you.
                }
                {disliked?
                    Better be careful than sorry, you know?
                    It's nothing personal.
                    Nah, who am I kidding, it totally is.
                }
            }
        ]],
        function(cxt)
            local learnlocation = ((cxt:GetAgent():GetRelationship() > RELATIONSHIP.NEUTRAL) or cxt.quest.param.agreed)
                and not (cxt:GetAgent():GetRelationship() < RELATIONSHIP.NEUTRAL)
            if learnlocation then
                DemocracyUtil.DoLocationUnlock(cxt, cxt.quest.param.oppo_location)
            end
        end,
    })
QDEF:AddConvo("meet_opposition", "primary_advisor")
    :Loc{
        OPT_DONE_QUEST = "Finish Up",
        DIALOG_DONE_QUEST = [[
            player:
                [p] i'm done with intel gathering.
            agent:
                good
                remember, there's still an interview coming up.
                you need to prepare for it.
                Go back to my office when you're ready to start working.
                
        ]],
    }
    :AttractState("STATE_ATTRACT", function(cxt) return not cxt.quest.param.talked_to_advisor end)
        :Loc{
            DIALOG_INTRO = [[
                {not greeted?
                    agent:
                        [p] if you haven't talked to {opposition} already, you should probably do so.
                        you might gain some insights as to what other candidates are up to.
                }
                {greeted?
                    agent:
                        [p] so you talked to {opposition}. What do you make of {opposition.himher}?
                    player:
                        {opposition.HeShe}'s fine, i guess.
                    {agreed?
                        we more or less have the same ideology. we could probably get along.
                    agent:
                        glad to hear that.
                        but don't let that fool you. you're still opponents.
                        there can only be one.
                    }
                    {disagreed?
                        we have some ideological differences, but we might still get along.
                    agent:
                        great. now you know how other's think, you need to use that to your advantage.
                    }
                    {not (agreed or disagreed)?
                    agent:
                        you don't sound so sure.
                        oh well.
                    }
                }
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest.param.talked_to_advisor = true
        end)
    :Hub(function(cxt)
        cxt:Opt("OPT_ASK_ABOUT")
            :IsHubOption(true)
            -- :Dialog("DIALOG_QUESTION")
            :GoTo("STATE_QUESTIONS")
        cxt:Opt("OPT_DONE_QUEST")
            :SetQuestMark( cxt.quest )
            :Dialog("DIALOG_DONE_QUEST")
            :CompleteQuest()
            :DoneConvo()
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
                Although the more prestegious people would rather have Havaria be totally annexed.
        ]],
        nil,
        nil,
        "Ask about the Spark Baron candidate",
        [[
            player:
                Someone in the Spark Barons has got to be running.
            agent:
                Of course.
                Their candidate is Lellyn Fellemo, a retired Admiralty solider, who now is a regional officer managing Grout Bog.
                Although I'm not sure how competent he really is.
                Seems like he's in just because his lieutenant really wants the Spark Barons to play a part in this.
            player:
                Uh huh.
            {spark_barons?
                Then why didn't you run, seeing as no one competent in the Spark Barons is running?
            agent:
                !crossed
                ...
                I have my reasons.
            }
            player:
                What's Fellemo's angle, then?
            agent:
                He wants to <!pol_stance_tax_policy_-2>aboilsh taxes</>.
                Of course, many people would want that, especially the Spark Barons.
                They don't want their hard-earned money to go to leeches that is the state.
                But it would mean that the state can't get fundings this way.
            player:
                How does he plan to make Havaria function if he abolish taxes?
            agent:
                No clue.
                State industries, maybe?
                You should ask him about it.
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
        -- haven't figure out whether to use vixmali or the bishop
        [[
            player:
                So what's the cult's candidates clause?
            agent:
            {not cult_of_hesh?
                It's the cult. They always want more power.
                But they dont really have anything that jives with the public voting blocks.
                Well, everything except <!pol_stance_artifact_treatment_2>preserve artifacts</>.
            }
            {cult_of_hesh?
                To <!pol_stance_artifact_treatment_2>preserve artifacts</>, obviously.
            }
                They'll likely just start preaching about Hesh declaring them the president.
                Their supporters are going to be rigidly pro-cult unless you stoop to their level.
                If you do though, watch your back from those who want the artifacts for profit.
        ]],
        nil,
        nil,
        "Ask about the Jakes candidate",
        [[
            player:
                I'm assuming the Jakes has someone that represents them?
            agent:
                Actually, no.
                The Jakes are illegal by nature. It's unlikely they could put anyone important on the world stage and get away with it.
                However, there is a candidate trying to levy support from the Jakes in particular.
                Her name's Andwannette. Big character in the foam before, but now she's got a fire in her belly to take it to new heights.
            player:
                So what are her actual viewpoints, or is she just waffling to the Jakes?
            agent:
                She's a merchant who deals in Back-alley goods. She wants to put those goods on a market that isn't the black market.
                Expect her to lean towards <!pol_stance_substance_regulation_-2>removing lots of existing regulations</>.
                !shrug
                Can't say I exactly disagree with her on that. Just don't believe she'll make it, is all.
            player:
                Fair enough.
                Though I imagine the people in authority won't like it.
        ]],
        function()end,
    })
