local QDEF = QuestDef.Define
{
    title = "Potential Alliances",
    desc = "Talk about potential alliance with your advisor.",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/meet_opposition.png"),

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
    title = "Visit the noodle shop",
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
            local val, reason = DemocracyUtil.GetAlliancePotential(id)
            quest:Trace("[%s] Val=%d, Reason=%s", id, val, reason)
            if val then
                local endorsement = DemocracyUtil.GetEndorsement(val)
                if endorsement >= best_score then
                    
                    if endorsement > best_score then
                        best_score = endorsement
                        best_characters = {}
                    end
                    
                    table.insert(best_characters, data)
                end
            end
        end
        if #best_characters > 0 then
            local data = table.arraypick(best_characters)
            local agent = TheGame:GetGameState():GetMainQuest():GetCastMember(data.cast_id)
            table.insert(t, agent)
            quest.param.ally_work_pos = data.workplace
            quest.param.ally_platform = data.platform

            if quest.param.ally_platform then
                quest.param.stance_index = data.stances[quest.param.ally_platform]
                if quest.param.ally_platform and quest.param.stance_index then
                    quest.param.ally_stance = quest.param.ally_platform .. "_" .. quest.param.stance_index
                end
            end
        end
    end,
    no_validation = true,
}
DemocracyUtil.AddPrimaryAdvisor(QDEF)

QDEF:AddConvo("go_to_bar")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt:GetCastMember("primary_advisor") and cxt.location == cxt.quest:GetCastMember("noodle_shop") end)
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
QDEF:AddConvo("make_decision", "potential_ally")
    :AttractState("STATE_ATTRACT")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    [p] Have you decided?
            ]],
            OPT_ACCEPT = "Accept",

            DIALOG_ACCEPT = [[
                player:
                    [p] You know what, I agree.
                    If we can work together, we will surely win!
                agent:
                    Excellent! That's the kind of stuff I like to hear!
                * You've agreed to ally with {agent}.
                agent:
                    Feel free to visit me at {ally_work_pos#location}.
                player:
                    Thanks.
            ]],
            OPT_DECLINE = "Decline",

            DIALOG_DECLINE = [[
                player:
                    [p] While that is a great offer, I have to decline, unfortunately.
                    Sorry if I offended you, but I want to keep my options open.
                agent:
                    I see.
                    It is a real shame.
                    Well, if you ever change your mind, visit me at {ally_work_pos#location}.
                player:
                    I'll keep that in mind, thanks.
            ]],
            DIALOG_THINK = [[
                player:
                    I haven't decided yet.
                agent:
                    Don't take too long!
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_ACCEPT")
                :PreIcon(global_images.accept)
                :Dialog("DIALOG_ACCEPT")
                :ReceiveOpinion(OPINION.ALLIED_WITH)
                :UpdatePoliticalStance(cxt.quest.param.ally_platform, cxt.quest.param.stance_index)
                :Fn(function(cxt)
                    cxt.quest.param.allied = true
                    DemocracyUtil.DoLocationUnlock(cxt, cxt.quest.param.ally_work_pos)
                end)
                :GoTo("STATE_POST_DECISION")

            cxt:Opt("OPT_DECLINE")
                :PreIcon(global_images.reject)
                :Dialog("DIALOG_DECLINE")
                :Fn(function(cxt)
                    DemocracyUtil.DoLocationUnlock(cxt, cxt.quest.param.ally_work_pos)
                end)
                :GoTo("STATE_POST_DECISION")

            cxt:Opt("OPT_DONE")
                -- :SetSFX( SoundEvents.leave_conversation )
                :Dialog("DIALOG_THINK")
                :Fn(function(cxt) cxt:End() end)
                :MakeUnder()
        end)
    :State("STATE_POST_DECISION")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    !right
                * Your advisor comes to you.
                agent:
                {allied?
                    So you decided to ally with {potential_ally}?
                    Good for you.
                player:
                    I think it is the best course of action right now.
                agent:
                    I think so too.
                    Just beware that other candidates might not like this, and will never ally with you.
                player:
                    Well, let's see what happens.
                }
                {not allied?
                    So you decided to not ally with {potential_ally}?
                player:
                    I'm looking into more options before I make a decision.
                agent:
                    Perhaps that is the correct decision.
                    You can always find {potential_ally} later, although it will take up some of your time.
                player:
                    True.
                }
                agent:
                    Anyway, when you're done, meet me back at my office.
                    We've got plenty to do.
            ]],
        }
        :Fn(function(cxt)
            cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
            cxt:Dialog("DIALOG_INTRO")

            cxt.quest:Complete()
            StateGraphUtil.AddEndOption(cxt)
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
            :SetQuestMark(cxt.quest)
            :Dialog("DIALOG_ASK")
            :GoTo("STATE_QUESTIONS")
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
                Also, enemies of your ally will not form an alliance with you, so choose your ally carefully.
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
                agent:
                    Take your time. It's not an easy decision.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)