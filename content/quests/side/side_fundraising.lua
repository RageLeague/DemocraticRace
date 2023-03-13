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

local CROWD_BEHAVIOR = {
    OnInit = function( self, difficulty )
        -- self.bog_boil = self:AddCard("bog_boil")
        self:SetPattern( self.BasicCycle )
        local modifier = self.negotiator:AddModifier("SELL_MERCH_CROWD")
        modifier.agents = shallowcopy(self.agents)
        modifier:InitModifiers()
    end,
    agents = {},
    -- ignored_agents = {},

    -- Duplicated from Bandits. Needs revision
    BasicCycle = function( self, turns )
        local scaling = 1.5

        local adv_scale = GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_RESOLVE_DAMAGE )
        if adv_scale then
            scaling = scaling * adv_scale
        end
        local VARIANCE = 0.2
        scaling = scaling * ((math.random() - 0.5) * 2 * VARIANCE + 1)

        -- Double attack every 2 rounds; Single attack otherwise.
        if self.difficulty >= 4 and turns % 2 == 0 then
            self:ChooseNumbers( 3, 2 + math.random(-1,1), scaling * 0.6 )
        elseif turns % 2 == 0 then
            self:ChooseNumbers( 2, 1 + math.random(-1,1), scaling * 0.8 )
        else
            self:ChooseNumbers( 1, 1 + math.random(-1,1), scaling )
        end
        -- if turns % 3 == 0 then
        -- 	self:ChooseCard(self.bog_boil)
        -- end
    end,
}

local QDEF = QuestDef.Define
{
    title = "Fundraising",
    desc = "Sell merchandise to your supporters to raise funds for your campaign!",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/roadside_preaching.png"),

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
        -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 4 * #quest.param.convinced_people, "COMPLETED_QUEST")
    end,
    on_fail = function(quest)
        -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2 * #quest.param.crowd, "FAILED_QUEST")
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
    desc = "Go to {junction#location} to sell your merch there.",
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
    id = "sell_merch",
    title = "Sell merch",
    desc = "Convince as many people as possible to buy your merch to raise money for your campaign!"
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
    annoyed_by_sellout = {
        delta = OPINION_DELTAS.OPINION_DOWN,
        txt = "Annoyed by your sellout.",
    },
}

QDEF:AddConvo("go_to_junction")

    :Confront(function(cxt)
        if cxt.location == cxt.quest:GetCastMember("junction") then
            return "STATE_INTRO"
        end
    end)
    :State("STATE_INTRO")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You find a crossroads and set up your stand.
            ]],
            OPT_SELL = "Sell merchandise!",
            REASON_SELL = "Sell your merchandise to as many people as you can!",

            DIALOG_GOT_FUNDS = [[
                * [p] You raised {1#money}.
                {not poor_performance?
                    * Well done!
                }
                {poor_performance?
                    * Could be better. Could be worse.
                }
            ]],
            DIALOG_NO_FUNDS = [[
                * [p] You raised no money at all.
                * How is that possible?
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

            local BEHAVIOR = shallowcopy(CROWD_BEHAVIOR)
            BEHAVIOR.agents = cxt.quest.param.crowd
            cxt:GetAgent():SetTempNegotiationBehaviour(BEHAVIOR)

            local postProcessingFn = function(cxt, minigame)
                local core = minigame:GetOpponentNegotiator():FindCoreArgument()
                cxt.quest.param.unconvinced_people = core and core.ignored_agents or {}

                for i, agent in ipairs(cxt.quest.param.unconvinced_people) do
                    agent:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("annoyed_by_sellout"))
                end
                cxt.quest.param.funds = minigame:GetPlayerNegotiator():GetModifierStacks( "SECURED_FUNDS" )
                if cxt.quest.param.funds > 0 then
                    cxt.quest.param.poor_performance = cxt.quest.param.funds < 20 + 10 * cxt.quest:GetRank()
                    cxt:Dialog("DIALOG_GOT_FUNDS", #cxt.quest.param.funds)
                    cxt.quest:Complete()
                    ConvoUtil.GiveQuestRewards(cxt)
                else
                    cxt:Dialog("DIALOG_NO_FUNDS")
                    cxt.quest:Fail()
                end
            end

            cxt:Opt("OPT_SELL")
                :Negotiation{
                    flags = NEGOTIATION_FLAGS.NO_CORE_RESOLVE | NEGOTIATION_FLAGS.NO_BYSTANDERS,
                    reason_fn = function(minigame)
                        return cxt:GetLocString("REASON_SELL")
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
            agent:
                [p] Wanna sell some merch?
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
                [p] Nah.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")

        end)
