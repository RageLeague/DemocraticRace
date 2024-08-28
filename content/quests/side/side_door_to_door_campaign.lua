local QDEF = QuestDef.Define
{
    title = "Door-to-door Campaign",
    desc = "Visit a neighbourhood and campaign for support there.",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/roadside_preaching.png"),

    qtype = QTYPE.SIDE,
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"RALLY_JOB"},
    reward_mod = 0,
    extra_reward = false,

    on_init = function(quest)
        quest.param.visited_people = {}
        quest.param.convinced_people = 0
    end,
    on_start = function(quest)
        -- quest:Activate("go_to_junction")
    end,

    on_complete = function( quest )
        local support = DemocracyUtil.GetBaseRallySupport(quest:GetDifficulty()) - 4
        support = support + 2 * (quest.param.convinced_people or 0)
        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", support, "COMPLETED_QUEST")
    end,

    restrict_exit = function(quest, location)
        if quest:IsActive('talk_to_people') then
            return true
        end
        return false
    end,

    HOME_TYPES = {"BASIC_DORM", "SPREE_TENT", "SPARK_BARON_RESIDENCE", "PEARL_RICH_HOUSE", "PEARL_POOR_HOUSE"},
}
:AddCast{
    cast_id = "homeowner",
    when = QWHEN.MANUAL,
    no_validation = true,
    condition = function(agent, quest)
        if not DemocracyUtil.RandomBystanderCondition(agent) then
            return false, "Not a bystander"
        end
        if agent:GetBrain().home_location then
            if agent:GetBrain().home_location:GetContentID() ~= cxt.quest.param.home_type then
                return false, "Invalid home type"
            end
            for i, other in ipairs(quest.param.visited_people) do
                if other:GetBrain():GetHome() == agent:GetBrain():GetHome() then
                    return false, "Already visited"
                end
            end
        else
            local location_id = TheGame:GetGameState():GetWorldRegion():GetContent().home_generator(agent)
            if location_id ~= cxt.quest.param.home_type then
                return false, "Invalid home type"
            end
        end
        if not agent:GetBrain():IsAtHome() and not agent:InLimbo() then
            return false, "Already at somewhere"
        end
        return true
    end,
    on_assign = function(quest, agent)
        agent:GetBrain():MoveToHome()
    end,
}
:AddObjective{
    id = "go_to_neighbourhood",
    title = "Go to the neighbourhood",
    desc = "Go to the neighbourhood of your choice and convince people to be on your side.",
    mark = function(quest, t, in_location)
        table.insert(t, quest:GetCastMember("homeowner"):GetBrain():GetHome())
    end,
    -- state = QSTATUS.ACTIVE,
}
:AddObjective{
    id = "talk_to_people",
    title = "Talk to people",
    desc = "Talk to the people and convince them to join your cause.",
    mark = function(quest, t, in_location)
        if in_location then
            local location = TheGame:GetGameState():GetPlayerAgent():GetLocation()
            for _, agent in location:Agents() do
                if not table.arraycontains(quest.param.visited_people, agent) then
                    table.insert(t, agent)
                end
            end
        end
    end,
}

QDEF:AddConvo("go_to_neighbourhood")
    :ConfrontState("STATE_CONF", function(cxt) return cxt.location == cxt:GetCastMember("homeowner"):GetHome() end)
        :Loc{
            DIALOG_NEIGHBOURHOOD = [[
                * [p] You arrived at the neighbourhood.
                * Time to do work.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_NEIGHBOURHOOD")
            cxt.quest:Complete("go_to_neighbourhood")
            cxt.quest:Activate("talk_to_people")
            StateGraphUtil.AddEndOption(cxt)
        end)

QDEF:AddConvo("talk_to_people")
    :Loc{
        OPT_NEXT = "Go to the next place",
        OPT_DONE = "Finish the campaign",
    }
    :Hub_Location( function(cxt)
        cxt:Opt("OPT_NEXT")
        if cxt.quest.param.convinced_people >= 1 then
            cxt:Opt("OPT_DONE")
                :Fn(function(cxt)
                    UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_DONE" ,nil,nil,cxt.quest)
                end)
        end
    end)
    :State("STATE_DONE")
        :Loc{
            DIALOG_INTRO = [[
                * [p] Are you sure?
            ]],
            OPT_LEAVE_AGAIN = "Leave for real",
            DIALOG_LEAVE_AGAIN = [[
                * [p] You leave the neighbourhood, satisfied with your progress.
                * Hopefully.
            ]],
            OPT_STAY = "Stay for a bit longer",
            DIALOG_STAY = [[
                * [p] You decide to stay a bit longer.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt:Opt("OPT_LEAVE_AGAIN")
                :Dialog("DIALOG_LEAVE_AGAIN")
                :CompleteQuest()
                :Travel()
            cxt:Opt("OPT_STAY")
                :Dialog("DIALOG_STAY")
                :DoneConvo()
        end)

QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
            {not has_primary_advisor?
                [p] I should visit people's homes and campaign directly there.
            }
            {has_primary_advisor?
                agent:
                    !right
                    [p] Maybe you should visit people's homes and campaign directly there.
                    Easy to get their attention this way.
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
                [p] Sure!
                Now where should we go?
        ]],
        OPT_BASIC_DORM = "The Admiralty dormitories",
        DIALOG_BASIC_DORM = [[
            player:
                [p] I want to get the Admiralty on my side.
        ]],
        OPT_SPREE_TENT = "The Spree camps",
        DIALOG_SPREE_TENT = [[
            player:
                [p] I want the criminal underworld to be on my side.
        ]],
        OPT_SPARK_BARON_RESIDENCE = "The Spark Baron residences",
        DIALOG_SPARK_BARON_RESIDENCE = [[
            player:
                [p] I want the Spark Barons to be on my side.
        ]],
        OPT_PEARL_RICH_HOUSE = "The wealthy districts",
        DIALOG_PEARL_RICH_HOUSE = [[
            player:
                [p] I want the wealthy and influential to be on my side.
        ]],
        OPT_PEARL_POOR_HOUSE = "The poor districts",
        DIALOG_SPREE_TENT = [[
            player:
                [p] I want the support of the common folks.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            -- cxt.quest:Activate("go_to_junction")
            local options = table.multipick(cxt.quest:GetQuestDef().HOME_TYPES, 2)
            local function AddLocationOption(cxt, option)
                cxt:Opt("OPT_" .. option)
                    :Dialog("DIALOG_" .. option)
                    :Fn(function(cxt)
                        cxt.quest.param.home_type = option
                        cxt.quest:AssignCastMember("homeowner")
                        cxt.quest:Activate("go_to_neighbourhood")
                    end)
            end
            for i, option in ipairs(options) do
                AddLocationOption(cxt, option)
            end
        end)

QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.DECLINED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                [p] Nah.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
