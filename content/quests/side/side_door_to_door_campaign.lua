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
    end,
    on_start = function(quest)
        -- quest:Activate("go_to_junction")
    end,

    on_complete = function( quest )
        local support = DemocracyUtil.GetBaseRallySupport(quest:GetDifficulty()) - 4
        local count = quest.param.convinced_count or 0
        if count > 2 then
            support = support + 2 + count
        else
            support = support + 2 * count
        end
        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", support, "COMPLETED_QUEST")
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
        return true
    end,
}

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
        OPT_SPREE_TENT = "The Spree camps",
        OPT_SPARK_BARON_RESIDENCE = "The Spark Baron residences",
        OPT_PEARL_RICH_HOUSE = "The wealthy districts",
        OPT_PEARL_POOR_HOUSE = "The poor districts",
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            -- cxt.quest:Activate("go_to_junction")
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
