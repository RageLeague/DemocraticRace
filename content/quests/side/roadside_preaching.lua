
local LOCATION_DEF =
{
    id = "POPULOUS_JUNCTION",
    name = "Populous Junction",
    desc = "A junction which many people crosses by. Good place for any sort of political activity.",
    -- icon = engine.asset.Texture("icons/quests/at_the_crossroad.tex"),
    map_tags = {"intersection"},
    plax = "EXT_door_slums1",
    indoors = false,
}
if not Content.GetLocationContent(LOCATION_DEF.id) then
    Content.AddLocationContent(LOCATION_DEF)
end

local QDEF = QuestDef.Define
{
    title = "Roadside Preaching",
    desc = "Preach on the roadside. You might convince people to join your ideology!",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/roadside_preaching.png"),

    qtype = QTYPE.SIDE,
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"RALLY_JOB"},
    reward_mod = 0,
    extra_reward = false,

    on_init = function(quest)
        -- quest.param.debated_people = 0
        quest.param.crowd = {}
        quest.param.convinced_people = {}
        quest.param.unconvinced_people = {}
    end,
    on_start = function(quest)
        -- quest:Activate("go_to_junction")
    end,
    -- icon = engine.asset.Texture("icons/quests/bounty_hunt.tex"),

    on_destroy = function( quest )
        if quest:GetCastMember("junction") then
            TheGame:GetGameState():MarkLocationForDeletion(quest:GetCastMember("junction"))
        end
        for i, agent in ipairs( quest.param.crowd or {} ) do
            agent:RemoveAspect("bribed")
        end
    end,
    on_complete = function( quest )
        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 4 * #quest.param.convinced_people, "COMPLETED_QUEST")
    end,
    on_fail = function(quest)
        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2 * #quest.param.crowd, "FAILED_QUEST")
    end,
}
:AddLocationCast{
    cast_id = "junction",
    when = QWHEN.MANUAL,
    no_validation = true,
}
:AddObjective{
    id = "go_to_junction",
    title = "Go to {junction#location}",
    desc = "Go to {junction#location} to preach there.",
    mark = { "junction" },
    state = QSTATUS.ACTIVE,

    on_activate = function( quest)
        local location = Location( LOCATION_DEF.id )
        assert(location)
        TheGame:GetGameState():AddLocation(location)
        quest:AssignCastMember("junction", location )
    end,
}
:AddObjective{
    id = "preach",
    title = "Preach",
    desc = "Start preaching until you can convert significant amount of people."
}
:AddCast{
    cast_id = "crowd",
    when = QWHEN.MANUAL,
    no_validation = true,
    condition = function(agent, quest)
        return DemocracyUtil.RandomBystanderCondition(agent) and not table.arraycontains(quest.param.crowd, agent)
    end,
    score_fn = function(agent, quest)
        return math.random() * 60 + (agent:HasAspect("bribed") and 45 or 0)
    end,
    -- score_fn = score_fn,
}
:AddOpinionEvents{
    convinced_political_idea =
    {
        delta = OPINION_DELTAS.LIKE,
        txt = "Enlightened them with your ideology.",
    },
    annoyed_by_preach = {
        delta = OPINION_DELTAS.OPINION_DOWN,
        txt = "Annoyed by your preaching.",
    },
}
DemocracyUtil.AddPrimaryAdvisor(QDEF)

QDEF:AddConvo("go_to_junction")

    :Confront(function(cxt)
        if cxt.location == cxt.quest:GetCastMember("junction") then
            return "STATE_INTRO"
        end
    end)
    :State("STATE_INTRO")
        :Loc{
            DIALOG_INTRO = [[
                * You find a crossroads, busy with activity and rushing passer-bys.
                * You begin to preach to those who would listen. A few gather around you.
            ]],
            OPT_PREACH = "Preach!",
            REASON_PREACH = "Convince as many people as you can to join your side!",

            DIALOG_CONVINCED_PEOPLE = [[
                * You count about {1} {1*person|people} staying close, cheering on your beliefs.
                * {1:Not great, but that's something.|That's a good start.|Well done!}
            ]],
            DIALOG_UNCONVINCED_PEOPLE = [[
                player:
                    Hear ye, Hear ye! I bring free thoughts on the-
                    Wait...where are you going?
                * The crowd around you disperses. It's clear you haven't enticed them further than the initial interest.
                * With their leave, you leave as well. You wonder if you simply needed a better technique.
            ]],
        }
        :Fn(function(cxt)
            local interested_people = 5 + cxt.quest:GetRank()
            for i = 1, interested_people do
                cxt.quest:AssignCastMember("crowd")
                cxt.quest:GetCastMember("crowd"):MoveToLocation(cxt.location)
                table.insert(cxt.quest.param.crowd, cxt.quest:GetCastMember("crowd"))
                cxt.quest:UnassignCastMember("crowd")
            end
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Complete("go_to_junction")
            cxt.quest:Activate("preach")
            cxt.enc:SetPrimaryCast(cxt.quest.param.crowd[1])

            local BEHAVIOR = shallowcopy(DemocracyUtil.BEHAVIOURS.PREACH_CROWD)
            BEHAVIOR.agents = cxt.quest.param.crowd
            cxt:GetAgent():SetTempNegotiationBehaviour(BEHAVIOR)

            local postProcessingFn = function(cxt, minigame)
                local core = minigame:GetOpponentNegotiator():FindCoreArgument()
                cxt.quest.param.convinced_people = {}
                cxt.quest.param.unconvinced_people = core and core.ignored_agents or {}

                for i, modifier in minigame:GetPlayerNegotiator():Modifiers() do
                    if modifier.id == "PREACH_TARGET_INTERESTED" and modifier.target_agent then
                        table.insert( cxt.quest.param.convinced_people, modifier.target_agent )
                    end
                end

                for i, agent in ipairs(cxt.quest.param.convinced_people) do
                    agent:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("convinced_political_idea"))
                end
                for i, agent in ipairs(cxt.quest.param.unconvinced_people) do
                    agent:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("annoyed_by_preach"))
                end
                if #cxt.quest.param.convinced_people > 0 then
                    cxt:Dialog("DIALOG_CONVINCED_PEOPLE", #cxt.quest.param.convinced_people)
                    if #cxt.quest.param.convinced_people == 1 then
                        cxt.quest.param.poor_performance = true
                    end
                    cxt.quest:Complete()
                    ConvoUtil.GiveQuestRewards(cxt)
                    StateGraphUtil.AddEndOption(cxt)
                else
                    cxt:Dialog("DIALOG_UNCONVINCED_PEOPLE")
                    cxt.quest:Fail()
                    StateGraphUtil.AddEndOption(cxt)
                end
            end

            cxt:Opt("OPT_PREACH")
                :Negotiation{
                    flags = NEGOTIATION_FLAGS.NO_CORE_RESOLVE | NEGOTIATION_FLAGS.NO_BYSTANDERS,
                    reason_fn = function(minigame)
                        return cxt:GetLocString("REASON_PREACH")
                    end,
                    on_start_negotiation = function(minigame)
                    end,
                    on_success = postProcessingFn,
                    on_fail = postProcessingFn,
                    finish_negotiation_anytime = true,
                    cooldown = 0,
                }
        end)

QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
            {not has_primary_advisor?
                What's the classic way of getting ideologies out into the world?
                A good workday's worth of political soapboxing!
                Who knows? Might even rally some support!
            }
            {has_primary_advisor?
            agent:
                I think we should get back to the roots of campaigning.
                You're going to stand out in a populous crossroads and preach to the passer-bys.
                You'll need to reel the listeners in before they can get annoyed, but it should be a slam dunk.
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
                !left
                Might be worth a shot.
            {not has_primary_advisor?
                Think I know where to hit the trail to start preaching.
            }
            {has_primary_advisor?
            agent:
                Good.
                Now, there is a junction where many people visits. You should go there and start preaching.
            }
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Activate("go_to_junction")
        end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.DECLINED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
                Y'know what? Maybe it'll be a bit too much work for too little reward.
            {not has_primary_advisor?
                What else could I do...
            }
            {has_primary_advisor?
            agent:
                Back to the drawing board. Let's see what else we could do...
            }
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")

        end)
