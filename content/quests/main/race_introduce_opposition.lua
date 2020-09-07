local character_map = {
    [DemocracyConstants.opposition_data.candidate_admiralty.character] = "admiralty",
    [DemocracyConstants.opposition_data.candidate_rise.character] = "rise",
    [DemocracyConstants.opposition_data.candidate_baron.character] = "baron",
    
}
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

    qtype = QTYPE.STORY,
    collect_agent_locations = function(quest, t)
        table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.VISITOR})
        table.insert(t, { agent = quest:GetCastMember("opposition"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.VISITOR})
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
        if character_map[agent:GetContentID()] then
            quest.param[character_map[agent:GetContentID()]] = true
        else
            quest.param.missing_id = true
        end
        for id, data in pairs(DemocracyConstants.opposition_data) do
            if data.character == agent:GetContentID() then
                quest.param.opposition_id = id
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
                * you arrive at the noodle shop.
                player:
                    !left
                primary_advisor:
                    !right
                    looks like you have company.
                opposition:
                    !right
                    'sup, {player}.
                player:
                    Hi.
                opposition:
                    I'm also running for president.
                primary_advisor:
                    !right
                    Also there are other people who want to run for president.
                    you think this is going to be easy? think again.
            ]],
        }
        :Fn(function(cxt)
            cxt.quest:Complete("go_to_bar")
            cxt:Dialog("DIALOG_INTRO")
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
            {admiralty?
                Haravia is overrun with criminals, and it's up to me to stop them.
            }
            {baron?
                The Admiralty squeezes the people dry with taxes, so I need to stop them.
            }
            {rise?
                The workers of Havaria has been oppressed for so long. It's my duty to provide them with better rights.
            }
            {missing_id?
                I have a great plan. It's going to be the greatest plan.
            }
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
            ** This exchange causes your support among different factions to change.
            ** Check with your advisor for more details.
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
            ** This exchange causes your support among different factions to change.
            ** Check with your advisor for more details.
            player:
                But aren't we political opponents, though?
            agent:
            {baron or spree or jakes?
                Yeah, you're right.
                Well, good luck with your campaign, because I'll beat you.
            }
            {not (baron or spree or jakes)?
                While that's true, it's probably better if you form an alliance with another politician.
                You never know when you need help from an opponent, right?
            }
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
        if not cxt.quest.param.greeted then
            cxt:Opt("OPT_GREET")
                :Dialog("DIALOG_GREET")
                :Fn(function(cxt)
                    local opposition_data = DemocracyConstants.opposition_data[cxt.quest.param.opposition_id]
                    local platform = opposition_data.platform
                    local platform_stance
                    if platform then
                        platform_stance = opposition_data.stances[platform]
                    end
                    cxt:Opt("OPT_AGREE")
                        :Dialog("DIALOG_AGREE")
                        :Fn(function(cxt)
                            DemocracyUtil.TryMainQuestFn("DeltaGroupFactionSupport",
                                opposition_data.faction_support, 1, true)
                            DemocracyUtil.TryMainQuestFn("DeltaGroupWealthSupport",
                                opposition_data.wealth_support, 1, true)
                            if platform and platform_stance then
                                DemocracyUtil.TryMainQuestFn("UpdateStance", platform, platform_stance)
                            end
                            cxt.quest.param.greeted = true
                            cxt.quest.param.agreed = true
                            cxt:Dialog("DIALOG_GREET_PST")
                        end)
                    cxt:Opt("OPT_DISAGREE")
                        :Dialog("DIALOG_DISAGREE")
                        :Fn(function(cxt)
                            DemocracyUtil.TryMainQuestFn("DeltaGroupFactionSupport",
                                opposition_data.faction_support, -1, true)
                            DemocracyUtil.TryMainQuestFn("DeltaGroupWealthSupport",
                                opposition_data.wealth_support, -1, true)
                            if platform and platform_stance then
                                DemocracyUtil.TryMainQuestFn("UpdateStance", platform, -platform_stance)
                            end
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
                [p] what do you plan to do if you become president?
            agent:
                things.
                that helps people.
                idk.
            player:
                ok...?
        ]],
        nil,

        nil,
        "Ask about {agent}'s plan",
        [[
            player:
                [p] what's your plan?
            agent:
                why should i tell you?
            player:
                fair enough.
        ]],
        nil,

        nil,
        "Ask where to find {agent}",
        [[
            player:
                [p] if i want to find you, where should i go?
            agent:
                here.
            player:
                where?
            agent:
                i don't know, i haven't programmed anything yet.
        ]],
        function()end,
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
            :Dialog("DIALOG_DONE_QUEST")
            :CompleteQuest()
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
        function()end,
    })