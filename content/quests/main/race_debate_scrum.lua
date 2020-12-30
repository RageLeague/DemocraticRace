local QDEF = QuestDef.Define
{
    title = "Debate Scrum",
    desc = "You are invited to the presidential debate with other candidates. Impress the audience with your debate skills.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/interview.png"),

    qtype = QTYPE.STORY,
    collect_agent_locations = function(quest, t)
        -- if quest:IsActive("return_to_advisor") then
        --     table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('home')})
        -- else
        table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('backroom'), role = CHARACTER_ROLES.VISITOR})
        -- end
        table.insert(t, { agent = quest:GetCastMember("host"), location = quest:GetCastMember('theater')})
        for id, data in pairs(DemocracyConstants.opposition_data) do 
            table.insert(t, { agent = quest:GetCastMember(id), location = quest:GetCastMember('theater'), role = CHARACTER_ROLES.VISITOR})
        end
    end,
    on_start = function(quest)
        local questions = {}
        local weightings = {}
        for id, data in pairs(DemocracyConstants.issue_data) do
            weightings[id] = data.importance
        end
        for i = 1, 5 do
            local chosen = weightedpick(weightings)
            table.insert(questions, chosen)
            weightings[chosen] = nil
        end
        quest.param.questions = questions

        quest.param.candidates = {}
        for id, data in pairs(DemocracyConstants.opposition_data) do
            if quest:GetCastMember(data.cast_id) then
                table.insert(quest.param.candidates, quest:GetCastMember(data.cast_id))
            end
        end
    end,
    -- on_complete = function(quest)
    --     if quest:GetCastMember("primary_advisor") then
    --         quest:GetCastMember("primary_advisor"):GetBrain():SendToWork()
    --     end
    -- end,
    on_destroy = function(quest)
        quest:GetCastMember("primary_advisor"):GetBrain():SendToWork()
        if quest.param.parent_quest then
            quest.param.parent_quest.param.did_debate_scrum = true
        end
    end,
}
:AddCast{
    cast_id = "host",
    cast_fn = function(quest, t) 
        if quest:GetCastMember("theater"):GetProprietor() then
            table.insert(t, quest:GetCastMember("theater"):GetProprietor())
        end
    end,
    when = QWHEN.MANUAL,
    events = 
    {
        agent_retired = function( quest, agent )
            -- if quest:IsActive( "get_snail" ) then
                -- If noodle chef died before we even got the snail, cast someone new.
                quest:UnassignCastMember( "host" )
                quest:AssignCastMember( "host" )
            -- end
        end,
    },
}
:AddCastFallback{
    cast_fn = function(quest, t)
        quest:GetCastMember("theater"):GetWorkPosition("host"):TryHire()
        if quest:GetCastMember("theater"):GetProprietor() then
            table.insert(t, quest:GetCastMember("theater"):GetProprietor())
        end
    end,
}
:AddCast{
    cast_id = "audience",
    when = QWHEN.MANUAL,
    condition = function(agent, quest)
        return not table.arraycontains(quest.param.audience or {}, agent)
    end,
    score_fn = function(agent, quest)
        if agent:HasAspect( "bribed" ) then
            return 100
        end
        local sc = agent:GetRenown() * 2
        if agent:GetRelationship() ~= RELATIONSHIP.NEUTRAL then
            sc = sc + 5
        end
        return math.random(sc, 20)
    end,
    on_assign = function(quest, agent)
        if not quest.param.audience then
            quest.param.audience = {}
        end
        table.insert(quest.param.audience, agent)
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent() )
    end,
}
:AddLocationCast{
    cast_id = "theater",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GRAND_THEATER"))
    end,
    on_assign = function(quest, location)
        -- quest:SpawnTempLocation("BACKROOM", "backroom")
        quest:AssignCastMember("host")
    end,
    no_validation = true,
}
:AddLocationCast{
    cast_id = "backroom",
    no_validation = true,
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GRAND_THEATER.backroom"))
    end,
    -- on_assign = function(quest, location)

    --     -- print(location)
    --     -- print(quest:GetCastMember("theater"))
    --     -- print(quest:GetCastMember("theater"):GetMapPos())
    --     -- location:SetMapPos( quest:GetCastMember("theater"):GetMapPos() )
    -- end,
    -- when = QWHEN.MANUAL,
}
:AddObjective{
    id = "go_to_debate",
    title = "Go to the debate",
    desc = "Meet up with {primary_advisor} at the Grand Theater.",
    mark = {"backroom"},
    state = QSTATUS.ACTIVE,
}
:AddObjective{
    id = "do_debate",
    title = "Do the debate",
    desc = "Try to stand out, but not in a bad way.",
    mark = {"theater"},
    -- state = QSTATUS.ACTIVE,
}

DemocracyUtil.AddPrimaryAdvisor(QDEF, true)
DemocracyUtil.AddHomeCasts(QDEF)
DemocracyUtil.AddOppositionCast(QDEF)

local function CreateDebateOption(cxt, helpers, hinders, topic, stance)
    cxt:Opt("OPT_SIDE", topic .. "_" .. stance)
        :UpdatePoliticalStance(topic, stance, false)
        :Dialog("DIALOG_SIDE")
        :Negotiation{
            flags = NEGOTIATION_FLAGS.NO_BYSTANDERS,
            helpers = helpers,
            hinders = hinders,
        }
end

QDEF:AddConvo("go_to_debate")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt.location == cxt.quest:GetCastMember("backroom") end)
        :Loc{
            DIALOG_INTRO = [[
                * [p] You arrive at the grand theater backroom, where {agent} awaits you.
                player:
                    !left
                agent:
                    !right
                    Are you ready for tonight's debate?
                player:
                    Are we ever ready?
                agent:
                    Good point.
                    Anyway, whether you're ready or not, time to go.
                    Good luck.
            ]],
        }
        :Fn(function(cxt)
            cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
            DemocracyUtil.PopulateTheater(cxt.quest, cxt.quest:GetCastMember("theater"), 8)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Complete("go_to_debate")
            cxt.quest:Activate("do_debate")
            cxt:Opt("OPT_LEAVE_LOCATION")
                :Fn(function(cxt)
                    cxt.encounter:DoLocationTransition(cxt.quest:GetCastMember("theater"))
                end)
                :MakeUnder()
        end)
QDEF:AddConvo("do_debate")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt.location == cxt.quest:GetCastMember("theater") end)
    :Loc{
        DIALOG_INTRO = [[
            * You walked into the theater.
            * It is full of people.
            agent:
                !right
            * You wait for the host to introduce the candidates.
            * After introducing six the other candidate, an amount so large that we don't even bother to write it out, the host finally calls you in.
            agent:
                [p] And finally, we have {player}!
            player:
                !left
                Yo.
            agent:
                Why do we have all the candidates gathered here today?
                Why, it is to have a debate, of course!
                We have plenty of questions to ask each candidates today, and they have debate out which is the best.
                Hopefully this helps you determine which candidate is the most competent.
        ]],
    }
    :Fn(function(cxt)
        cxt:TalkTo(cxt:GetCastMember("host"))
        cxt:Dialog("DIALOG_INTRO")
        cxt:GoTo("STATE_QUESTION")
    end)
    :State("STATE_QUESTION")
        :Quips{
            {
                tags = "debate_question",
                [[
                    agent:
                        Many people in Havaria are very concerned about {topic#pol_issue}.
                        What do you think about that?
                ]],
                [[
                    agent:
                        A big concern in Havaria is about {topic#pol_issue}.
                        What is your opinion on this topic?
                ]],
                [[
                    agent:
                        Many Havarian citizens ask the question,
                        What is the best approach to {topic#pol_issue}?
                ]],
                [[
                    agent:
                        There are a lot of ways to approach {topic#pol_issue}.
                        In your opinion, what is the best way?
                ]],
            },
        }
        :Loc{
            OPT_SIDE = "Argue for {1#pol_stance}",
            DIALOG_SIDE = [[
                player:
                    This is my answer!
                * A debate is about to go down!
            ]],
        }
        :Fn(function(cxt)
            if not cxt.quest.param.questions or #cxt.quest.param.questions == 0 then
                -- Go to end state.
            end
            cxt.quest.param.topic = cxt.quest.param.questions[1]
            table.remove(cxt.quest.param.questions, 1)

            local neg_helper, neg_hinder, pos_helper, pos_hinder = {}, {}, {}, {}
            for i, agent in ipairs(cxt.quest.param.candidates) do
                local issue = DemocracyConstants.issue_data[cxt.quest.param.topic]

                -- The default index of a person.
                local stance_index = issue:GetAgentStanceIndex(agent)
                -- How much a person's opinion will shift in your favor
                local shift = 0
                if agent:GetRelationship() > RELATIONSHIP.NEUTRAL then
                    shift = 1
                elseif agent:GetRelationship() < RELATIONSHIP.NEUTRAL then
                    shift = -1
                end
                if stance_index < shift then
                    table.insert(neg_helper, agent)
                elseif stance_index > shift then
                    table.insert(neg_hinder, agent)
                end

                if stance_index < -shift then
                    table.insert(pos_hinder, agent)
                elseif stance_index > -shift then
                    table.insert(pos_helper, agent)
                end
            end

            cxt:TalkTo(cxt:GetCastMember("host"))
            cxt:Quip(cxt:GetAgent(), "debate_question")
            CreateDebateOption(cxt, neg_helper, neg_hinder, cxt.quest.param.topic, -2)
            CreateDebateOption(cxt, pos_helper, pos_hinder, cxt.quest.param.topic, 2)
        end)