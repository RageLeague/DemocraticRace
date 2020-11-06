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
                    Looks like you have company.
                opposition:
                    !right
                    Hello there. I heard that you're running for president.
                player:
                    Yeah, you got it. That's me.
                opposition:
                    It just so happens that I'm also running for president.
                primary_advisor:
                    !right
                    It's not just {opposition}.
                    There are many other candidates who are running for president.
                    And they have been doing a lot of work to gain their support.
                    You think this is going to be easy? Think again.
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
                [p] hello, i'm {player}.
                nice to meet you.
            agent:
                nice to meet you too.
            player:
                i heard you're running for president, yes?
            agent:
                that's right.
                %opposition_intro idea_monologue {opposition_id}
            player:
                good talk.
            agent:
                do you agree with my platform?
        ]],
        OPT_AGREE = "Agree",
        DIALOG_AGREE = [[
            player:
                I have to say that I sympathize with your cause.
            agent:
                I'm glad we can come to an agreement.
            player:
                That said, we're still opponents.
                I'll beat you in this democratic race!
            agent:
                Funny, 'cause I was about to say the same thing.
        ]],
        OPT_DISAGREE = "Disagree",
        DIALOG_DISAGREE = [[
            player:
                With all due respect, I can't say that I agree with your idea.
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
                [p] anyway, nice to meet you.
                if you have some questions, just ask.
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
                    {not (agreed or diagreed)?
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
                [p] beeeeeeeep
            agent:
                boop
                now laugh.
            player:
                !chuckle
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
        "Ask about Oolo",
        [[
            player:
                [p] what's her deal?
            agent:
                Security for all.
                lalala.
        ]],
        nil,
        nil,
        "Ask about Nadan",
        [[
            player:
                [p] what's his deal?
            agent:
                independence.
                lalala.
        ]],
        nil,
        nil,
        "Ask about Fellemo",
        [[
            player:
                [p] what's his deal?
            agent:
                low tax.
                lalala.
        ]],
        nil,
        nil,
        "Ask about Kalandra",
        [[
            player:
                [p] what's her deal?
            agent:
                unions.
                lalala.
        ]],
        nil,
        nil,
        "Ask about Vixmali",
        [[
            player:
                [p] what's his deal?
            agent:
                idk
        ]],
        nil,
        nil,
        "Ask about Andwanette",
        [[
            player:
                [p] what's his deal?
            agent:
                legalize everything
        ]],
        function()end,
    })