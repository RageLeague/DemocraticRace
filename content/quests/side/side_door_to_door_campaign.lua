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
        quest.param.total_visit_count = math.ceil(math.sqrt(math.random(4, 25)))
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
    PATROL_TYPES = {
        BASIC_DORM = "ADMIRALTY_PATROL",
        PEARL_RICH_HOUSE = "ADMIRALTY_PATROL",
        PEARL_POOR_HOUSE = "ADMIRALTY_PATROL",
        SPREE_TENT = "BANDIT_PATROL",
        SPARK_BARON_RESIDENCE = "SPARK_BARON_PATROL",
    },
    FALLBACKS = {
        BASIC_DORM = {"ADMIRALTY_CLERK", "ADMIRALTY_GOON", "ADMIRALTY_GUARD"},
        PEARL_RICH_HOUSE = {"WEALTHY_MERCHANT", "PRIEST"},
        PEARL_POOR_HOUSE = {"LABORER", "PEARLIE", "HEAVY_LABORER"},
        SPREE_TENT = {"BANDIT_GOON", "BANDIT_GOON2", "BANDIT_RAIDER"},
        SPARK_BARON_RESIDENCE = {"SPARK_BARON_GOON", "SPARK_BARON_TASKMASTER"},
    }
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
            if agent:GetBrain().home_location:GetContentID() ~= quest.param.home_type then
                return false, "Invalid home type"
            end
            for i, other in ipairs(quest.param.visited_people) do
                if other:GetBrain():GetHome() == agent:GetBrain():GetHome() then
                    return false, "Already visited"
                end
            end
        else
            local location_id = TheGame:GetGameState():GetWorldRegion():GetContent().home_generator(agent)
            if location_id ~= quest.param.home_type then
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
:AddCastFallback{
    cast_fn = function(quest, t)
        local defs = quest:GetQuestDef().FALLBACKS[quest.param.home_type] or {"LABORER"}
        table.insert( t, quest:CreateSkinnedAgent(table.arraypick(defs)) )
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
                if table.arraycontains(quest.param.convinced_people, agent) then
                    return
                end
            end
            for _, agent in location:Agents() do
                if not table.arraycontains(quest.param.visited_people, agent) then
                    table.insert(t, agent)
                end
            end
        end
    end,
}

QDEF:AddConvo("go_to_neighbourhood")
    :ConfrontState("STATE_CONF", function(cxt) return cxt.location == cxt.quest:GetCastMember("homeowner"):GetHomeLocation() end)
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

        OPT_CONVINCE = "Convince {agent} of your ideology",
        DIALOG_CONVINCE = [[
            player:
                [p] Here's why you should vote for me.
        ]],
        DIALOG_CONVINCE_SUCCESS = [[
            agent:
                [p] You're right!
        ]],
        DIALOG_CONVINCE_FAILURE = [[
            agent:
                [p] Get out of here!
        ]],
    }
    :Hub_Location( function(cxt)
        cxt:Opt("OPT_NEXT")
            :Fn(function(cxt)
                UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_NEXT" ,nil,nil,cxt.quest)
            end)
        if cxt.quest.param.convinced_people >= 1 then
            cxt:Opt("OPT_DONE")
                :Fn(function(cxt)
                    UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_DONE" ,nil,nil,cxt.quest)
                end)
        end
    end)
    :Hub(function(cxt, who)
        if not who then
            return
        end
        for i, agent in ipairs(cxt.quest.param.visited_people) do
            if who:GetHomeLocation() == agent:GetHomeLocation() then
                return
            end
        end
        for i, agent in ipairs(cxt.quest.param.convinced_people) do
            if who:GetHomeLocation() == agent:GetHomeLocation() then
                return
            end
        end
    end)
    :State("STATE_NEXT")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You decided to go to the next door to find people.
            ]],
            DIALOG_PATROL = [[
                * [p] But not all is well as you run into a group of people!
                player:
                    !left
                agent:
                    !right
                    !angry
                * They are pissed at you.
            ]],
            OPT_BRIBE = "Bribe {agent}",
            DIALOG_BRIBE = [[
                player:
                    [p] You never saw me.
                agent:
                    Of course.
                * You are able to get out of trouble.
            ]],
            OPT_CONVINCE = "Convince {agent} to let you leave",
            DIALOG_CONVINCE = [[
                player:
                    !placate
                    Look, I mean no harm.
                    Just let me go, okay?
                agent:
                    And why would I let you do that?
            ]],
            DIALOG_CONVINCE_WIN = [[
                player:
                    !exit
                * [p] You leave before {agent} changes {agent.hisher} mind.
            ]],
            DIALOG_CONVINCE_LOSE = [[
                agent:
                    !fight
                    [p] That's enough.
                    You're going down!
            ]],
            OPT_RESIST = "Defend yourself!",
            DIALOG_RESIST = [[
                player:
                    !fight
                    [p] No.
            ]],
            DIALOG_RESIST_SUCCESS = [[
                * Good job. You might still be free, but your reputation will suffer.
            ]],
            DIALOG_RESIST_RUNAWAY = [[
                left:
                    !exit
                right:
                    !exit
                * You ran away from the scene.
                * It might seem cowardly, but you did what you came here to do.
                * And that's good enough for you.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            table.insert_unique(cxt.quest.param.visited_people, cxt:GetCastMember("homeowner"))
            if #cxt.quest.param.visited_people < cxt.quest.param.total_visit_count then
                cxt.quest:UnassignCastMember("homeowner")
                cxt.quest:AssignCastMember("homeowner")
                cxt:Opt("OPT_LEAVE_LOCATION")
                    :Fn(function(cxt)
                        cxt.encounter:DoLocationTransition(cxt.quest:GetCastMember("homeowner"):GetHomeLocation())
                    end)
                    :MakeUnder()
            else
                cxt.enc.scratch.opfor = CreateCombatParty(cxt.quest.param.home_type and cxt.quest:GetQuestDef().PATROL_TYPES[cxt.quest.param.home_type] or "ADMIRALTY_PATROL", cxt.quest:GetRank(), cxt.location, true)
                cxt.enc:SetPrimaryCast(cxt.enc.scratch.opfor[1])
                cxt:Dialog("DIALOG_PATROL")
                cxt:Opt("OPT_BRIBE")
                    :Dialog("DIALOG_BRIBE")
                    :DeliverMoney(50 * cxt.quest:GetRank())
                    :CompleteQuest()
                    :Travel()
                cxt:Opt("OPT_CONVINCE")
                    :Dialog("DIALOG_CONVINCE")
                    :Negotiation{
                        cooldown = 0,
                        on_success = function(cxt)
                            cxt:Dialog("DIALOG_CONVINCE_WIN")
                            cxt.quest:Complete()
                            ConvoUtil.GiveQuestRewards(cxt)
                            StateGraphUtil.AddLeaveLocation(cxt)
                        end,
                        on_fail = function(cxt)
                            cxt:Dialog("DIALOG_CONVINCE_LOSE")

                            cxt:Opt("OPT_RESIST")
                                :Dialog("DIALOG_RESIST")
                                :Battle{
                                    flags = BATTLE_FLAGS.SELF_DEFENCE,
                                    on_win = function(cxt)
                                        cxt:Dialog("DIALOG_RESIST_SUCCESS")
                                        cxt.quest.param.poor_performance = true
                                        cxt.quest:Complete()
                                        ConvoUtil.GiveQuestRewards(cxt)
                                        StateGraphUtil.AddLeaveLocation(cxt)
                                    end,
                                    on_runaway = function(cxt, battle)
                                        cxt:Dialog("DIALOG_RESIST_RUNAWAY")
                                        cxt.quest.param.poor_performance = true
                                        cxt.quest:Complete()
                                        ConvoUtil.GiveQuestRewards(cxt)
                                        StateGraphUtil.DoRunAwayEffects( cxt, battle, true )
                                    end,
                                }
                        end,
                    }
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
        DIALOG_PEARL_POOR_HOUSE = [[
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
                    :DoneConvo()
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
