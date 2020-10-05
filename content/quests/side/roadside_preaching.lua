
local LOCATION_DEF =
{
    id = "POPULOUS_JUNCTION",
    name = "Populous Junction",
    desc = "A junction which many people crosses by. Good place for any sort of political activity.",
    -- icon = engine.asset.Texture("icons/quests/at_the_crossroad.tex"),
    map_tags = {"slum"},
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
        local modifier = self.negotiator:AddModifier("PREACH_CROWD")
        modifier.agents = shallowcopy(self.agents)
        modifier:InitModifiers()
    end,
    agents = {},

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
    title = "Roadside Preaching",
    desc = "Preach on the roadside. You might convince people to join your ideology!",

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
        quest:Activate("go_to_junction")
    end,
    -- icon = engine.asset.Texture("icons/quests/bounty_hunt.tex"),

    on_destroy = function( quest )
        if quest:GetCastMember("junction") then
            TheGame:GetGameState():MarkLocationForDeletion(quest:GetCastMember("junction"))
        end
        for i, agent in ipairs( quest.param.crowd ) do
            agent:RemoveAspect("bribed")
        end
    end,
    on_complete = function( quest )
        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 6 * #quest.param.convinced_people)
    end,
    on_fail = function(quest)
        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2 * #quest.param.crowd)
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
        delta = OPINION_DELTAS.DIMINISH,
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
                * [p] you arrived at the junction and start preaching
            ]],
            OPT_PREACH = "Preach!",
            REASON_PREACH = "Convince as many people as you can to join your side!",
            
            DIALOG_CONVINCED_PEOPLE = [[
                * You have enlightened {1} {1*person|people} with your ideology.
                * {1:Not great, but that's something.|An acceptable amount.|Well done!}
            ]],
            DIALOG_UNCONVINCED_PEOPLE = [[
                * After a long time, you haven't convinced even a single person with your ideology.
                * Clearly that was a failure.
            ]],
        }
        :Fn(function(cxt)
            local interested_people = 4 + cxt.quest:GetRank() * 2
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
            cxt:GetAgent().temp_negotiation_behaviour = CROWD_BEHAVIOR
            CROWD_BEHAVIOR.agents = cxt.quest.param.crowd

            local postProcessingFn = function(cxt, minigame)
                cxt.quest.param.convinced_people = {}
                cxt.quest.param.unconvinced_people = {}

                local undestroyedPeople = {}
                
                for i, modifier in minigame:GetPlayerNegotiator():Modifiers() do
                    if modifier.id == "PREACH_TARGET_INTERESTED" and modifier.target_agent then
                        table.insert( cxt.quest.param.convinced_people, modifier.target_agent )
                    end
                end
                for i, modifier in minigame:GetOpponentNegotiator():Modifiers() do
                    if modifier.id == "PREACH_TARGET_INTEREST" and modifier.target_agent then
                        table.insert( undestroyedPeople, modifier.target_agent )
                    end
                end
                for i, agent in ipairs(minigame:GetOpponentNegotiator():FindCoreArgument().agents) do
                    table.insert( undestroyedPeople, agent )
                end
                
                for i, agent in ipairs(cxt.quest.param.crowd) do
                    if not agent:HasAspect("bribed") and not table.arraycontains(cxt.quest.param.convinced_people, agent) and not table.arraycontains(undestroyedPeople, agent) then
                        table.insert(cxt.quest.param.unconvinced_people, agent)
                    end
                end

                for i, agent in ipairs(cxt.quest.param.convinced_people) do
                    -- cxt:Dialog("DIALOG_CONVINCED_PEOPLE", agent)
                    agent:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("convinced_political_idea"))
                end
                for i, agent in ipairs(cxt.quest.param.unconvinced_people) do
                    -- cxt:Dialog("DIALOG_UNCONVINCED_PEOPLE", agent)
                    if math.random() < 0.3 then
                        agent:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("annoyed_by_preach"))
                    end
                end
                if #cxt.quest.param.convinced_people > 0 then
                    cxt:Dialog("DIALOG_CONVINCED_PEOPLE", #cxt.quest.param.convinced_people)
                    if #cxt.quest.param.convinced_people == 1 then
                        cxt.quest.param.poor_performance = true
                    end
                    cxt.quest:Complete()
                    ConvoUtil.GiveQuestRewards(cxt)
                else
                    cxt:Dialog("DIALOG_UNCONVINCED_PEOPLE")
                    cxt.quest:Fail()
                end
            end

            cxt:Opt("OPT_PREACH")
                :Negotiation{
                    flags = NEGOTIATION_FLAGS.NO_CORE_RESOLVE | NEGOTIATION_FLAGS.NO_BYSTANDERS,
                    reason_fn = function(minigame)
                        return cxt:GetLocString("REASON_PREACH")
                    end,
                    on_start_negotiation = function(minigame)
                        -- for _, agent in ipairs(cxt.quest.param.crowd) do
                        --     local modifier = minigame.opponent_negotiator:CreateModifier("PREACH_TARGET_INTEREST")
                        --     if modifier and modifier.SetAgent then
                        --         modifier:SetAgent(agent)
                        --     end
                        -- end
                    end,
                    on_success = postProcessingFn,
                    on_fail = postProcessingFn,
                }
            -- cxt.quest.param.debated_people = 0
            -- cxt.quest.param.crowd = {}
            -- cxt:GoTo("STATE_DEBATE")
            -- cxt.quest:Complete()
            -- ConvoUtil.GiveQuestRewards(cxt)
        end)

QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
                [p] maybe i should preach
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
                [p] cool cool
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            
        end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.DECLINED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
                [p] nah
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)