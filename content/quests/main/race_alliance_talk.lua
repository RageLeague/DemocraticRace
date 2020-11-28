local QDEF = QuestDef.Define
{
    title = "Opinions and Oppositions",
    desc = "Discuss the oppositions with your advisor",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/meet_opposition.png"),

    qtype = QTYPE.STORY,
    collect_agent_locations = function(quest, t)
        table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.VISITOR})
        table.insert(t, { agent = quest:GetCastMember("potential_ally"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.VISITOR})
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
        -- quest:Activate("discuss_plan")
        quest:Activate("make_decision")
    end,
}
:AddObjective{
    id = "make_decision",
    title = "Make a decision",
    desc = "Decide whether you should ally with {potential_ally} or not.",
    mark = {"primary_advisor", "potential_ally"},
}
:AddCast{
    cast_id = "potential_ally",
    cast_fn = function(quest, t)
        local best_characters = {}
        local best_score = RELATIONSHIP.LIKED
        for id, data in pairs(DemocracyConstants.opposition_data) do
            local main_faction = data.main_supporter or "FEUD_CITIZEN"
            local val = DemocracyUtil.GetVoterIntentionIndex{faction = main_faction}
            local endorsement = DemocracyUtil.GetEndorsement(val)
            if endorsement >= best_score then
                local agent = TheGame:GetGameState():GetAgentByAlias(data.character)
                if endorsement > best_score then
                    best_score = endorsement
                    best_characters = {}
                end
                
                table.insert(best_characters, agent)
            end
        end
        for i, agent in ipairs(best_characters) do
            table.insert(t, agent)
        end
    end,
    no_validation = true,
}
DemocracyUtil.AddPrimaryAdvisor(QDEF)

QDEF:AddConvo("go_to_bar")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt.location == cxt.quest:GetCastMember("noodle_shop") end)
        :Loc{
            DIALOG_INTRO = [[
                * [p] you arrived at the shop.
                player:
                    !left
                primary_advisor:
                    !right
                    Looks like you got company.
                    Again.
                potential_ally:
                    !right
                    'Sup.
                    Our platforms are very similar to each other.
                    Perhaps it's a good time to strike an alliance?
                primary_advisor:
                    !right
                    I'll leave you to it.
            ]],
        }
        :Fn(function(cxt)

            cxt.quest:Complete("go_to_bar")
            cxt:Dialog("DIALOG_INTRO")
        end)
QDEF:AddConvo("make_decision", "primary_advisor")
    :Loc{
        DIALOG_ASK = [[
            player:
                I need some guidance...
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_ASK_ABOUT")
            :Dialog("DIALOG_ASK")
    end)
    :AskAboutHubConditions("STATE_QUESTIONS", 
    {
        nil,
        "Ask about alliance",
        [[
            player:
                So what does it mean to be "allied".
            agent:
                It means that they will help you, and you will help them.
                You guys have a lot in common, and if you can work together, you will get more votes than other candidates.
            player:
                That sounds pretty good.
            agent:
                There's a catch, though.
                If you deviate too much from their ideology, they might end their alliance with you.
                So... Don't do that.
        ]],
        nil,
        nil,
        "Ask about benefits of alliance",
        [[
            player:
                Why should I ally with other candidates?
            agent:
                Are you familiar with our voting system?
            player:
                Can't say I have, no.
            agent:
                You're running for president, and you aren't even familiar with our voting system? Unbelievable.
                It's called First Past The Post.
            player:
                And what exactly does that mean?
            agent:
                It means that each person gets to vote once, for their favorite candidate.
            {advisor_manipulate?
                But logically speaking, if there are more than two candidates, it is not a good idea.
                Let's say, hypothetically, you support the Cult's candidate.
                So naturally, you will vote for the Cult, right?
                But, let's say, hypothetically, the Cult is not that popular, and the Admiralty is the next best candidate.
                And let's say, hypothetically, you don't want the Rise to win, right?
                If you vote for the Cult, the Admiralty won't have enough votes to win the election, and the Rise wins. No one is happy.
                But if you vote for the Admiralty, they will get enough votes to win.
                You won't get exactly what you want, but it's better than the alternative, so logically, you must vote the Cult.
            *** Okay this is the end of wall of text. I promise.
            player:
                Those are a lot of words. But I think I get it.
                So, if I ally with someone, votes that should have go to them are likely to go to me!
            agent:
                Exactly.
            }
            {advisor_diplomacy?
                But that's what a normie would do.
                Someone with a galaxy brain, however, would vote for the candidate they like that will most likely win.
                It maximizes the chance of them getting a desired outcome.
            player:
                Oh, so if I ally with someone, voters are more likely to vote for me because of this?
            agent:
                That's right.
                But hey, that's just a theory, a <i>Game</> Theory.
            * Seriously, that's what it is, and not just a reference to some YouTube channel.
            }
            {advisor_hostile?
                But you see, if someone does that, they are wrong.
                Nobody knows how the voting system works better than me.
            player:
                You still haven't answered my question.
            agent:
                Oh, yes. Here's the explanation.
                It is not about voting someone you like the most, it's about voting for someone who are most likely to win.
                Look at my fellow Jarackles there, eager to vote for someone who represent them the most.
                But you don't represent anyone. You're here to <i>win</>.
                And people prefer that than someone who will make drastic changes against them. 
            player:
                I see.
                So, if I ally with someone, votes that should have go to them are likely to go to me!
            agent:
                Exactly.
            }
        ]],
        function()end,
    })
    :AttractState("STATE_ATTRACT")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    [p] Have you decided?
                player:
                    I'm still thinking...
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)