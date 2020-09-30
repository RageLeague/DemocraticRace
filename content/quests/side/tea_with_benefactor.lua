-- don't declare variables that ties to the quest outside of quest defs unless they are constant
-- local main_negotiator
-- local main_negotiator_limiter = 0
local BENEFACTOR_DEFS = {
    WEALTHY_MERCHANT = "PROPOSITION",
    SPARK_BARON_TASKMASTER = "APPROPRIATOR",
    PRIEST = "ZEAL",
}

local LOCATION_DEF =
{
    id = "TEAHOUSE",
    name = "Dallie's Teahouse",
    desc = " [p] A small establishment with delicious tea and high concentration of influencieal individuals.",
    -- icon = engine.asset.Texture("icons/quests/at_the_crossroad.tex"),
    map_tags = {"residence"},
    plax = "INT_RichHouse_1",
    indoors = true,
    show_agents= true,
}
if not Content.GetLocationContent(LOCATION_DEF.id) then
    Content.AddLocationContent(LOCATION_DEF)
end

local score_fn = function(agent, quest)
    local score = DemocracyUtil.OppositionScore(agent)
    if agent:HasAspect( "bribed" ) then
        score = score + 90
    end
    return score + math.random() * 120
end

local BENEFACTOR_BEHAVIOR = {
    OnInit = function( self, difficulty )
        local modifier
        self.etiquette = self:AddArgument( "ETIQUETTE" )
        self:SetPattern( self.BasicCycle )
        -- if main_negotiator == "SPARK_BARON_TASKMASTER" then modifier = self.negotiator:AddModifier("APPROPRIATOR") end
        -- if main_negotiator == "PRIEST" then modifier = self.negotiator:AddModifier("ZEAL") end
        -- if main_negotiator == "WEALTHY_MERCHANT" then modifier = self.negotiator:AddModifier("PROPOSITION") end
        modifier = self.negotiator:AddModifier(BENEFACTOR_DEFS[self.agent:GetContentID()])
        if modifier ~= nil then modifier.agents = shallowcopy(self.agents) end
    end,
    agents = {},

	-- Will probably get unique core argument (POSITION OF POWER) and possibly argument that spawns every x (4) turns
    BasicCycle = function( self, turns )
        -- This will trigger every turn, and we don't want that
        -- local etiquette = self:AddArgument( "ETIQUETTE" )

        -- Also, remove unnecessary checks
        self:ChooseGrowingNumbers( 1, 1 )
        if turns % 3 == 0 then
            self:ChooseCard( self.etiquette )
        end
        if turns % 2 == 0 then
            self:ChooseComposure( 1, 3, 5 )
        end

	end,
}
local QDEF = QuestDef.Define
{
    title = "Tea with a benefactor",
    desc = " [p] An influential citizen has taken interest in your campaign and invited you for a cup of tea. See if you can turn some of that support into cash.",

    qtype = QTYPE.SIDE,
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"RALLY_JOB"},
    reward_mod = 0,
    extra_reward = false,

    on_init = function(quest)
        -- quest.param.debated_people = 0
        -- quest.param.crowd = {}
        -- quest.param.convinced_people = {}
        -- quest.param.unconvinced_people = {}
    end,
    on_start = function(quest)
        quest:Activate("go_to_teahouse")
    end,
    -- icon = engine.asset.Texture("icons/quests/bounty_hunt.tex"),

    on_destroy = function( quest )
        if quest:GetCastMember("teahouse") then
            TheGame:GetGameState():MarkLocationForDeletion(quest:GetCastMember("teahouse"))
        end
        for i, agent in ipairs( quest.param.crowd ) do
            agent:RemoveAspect("bribed")
        end
    end,
    on_complete = function( quest )
        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 4 )
    end,
    on_fail = function(quest)
        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2 )
    end,
}
:AddLocationCast{
    cast_id = "teahouse",
    when = QWHEN.MANUAL,
    no_validation = true,
}
:AddObjective{
    id = "go_to_teahouse",
    title = "Go to {teahouse#location}",
    desc = "Go to {teahouse#location} to meet the benefactor.",
    mark = { "teahouse" },
    state = QSTATUS.ACTIVE,
    
    on_activate = function( quest)
        local location = Location( LOCATION_DEF.id )
        assert(location)
        TheGame:GetGameState():AddLocation(location)
        quest:AssignCastMember("teahouse", location )
    end,
}
:AddObjective{
    id = "secure_funding",
    title = "Secure Funding",
    desc = "Persuade the benefactor into financing your campaign."
}
:AddCast{
    cast_id = "benefactor",
    when = QWHEN.MANUAL,
    no_validation = true,
    condition = function(agent, quest)
        return BENEFACTOR_DEFS[agent:GetContentID()] ~= nil -- might generalize it later
    end,
    -- don't use cast_fn by default if you want to use existing agents.
    -- cast_fn = function(quest, t)

    --     local options = {}
    --     table.insert(options, "WEALTHY_MERCHANT")
    --     table.insert(options, "SPARK_BARON_TASKMASTER")
    --     table.insert(options, "PRIEST")
    
    --     local def = options[math.random(#options)]
    --     table.insert( t, quest:CreateSkinnedAgent( def ) )
 
    --     if main_negotiator_limiter == 0 then
    --         main_negotiator = def
    --         main_negotiator_limiter = 1
    --     end

    -- end,
    score_fn = score_fn,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        local options = copykeys(BENEFACTOR_DEFS)
        local def = table.arraypick(options)
        table.insert( t, quest:CreateSkinnedAgent(def) )
    end,
}
:AddOpinionEvents{
    convinced_benefactor =  
    {
        delta = OPINION_DELTAS.LIKE,
        txt = " [p] Confident in your leadership abilities.",
    },
    disappointed_benefactor = {
        delta = OPINION_DELTAS.DIMINISH,
        txt = " [p] Skeptical about your leadership abilities.",
    },
}
DemocracyUtil.AddPrimaryAdvisor(QDEF)

QDEF:AddConvo("go_to_teahouse")
    
    :Confront(function(cxt)
        if cxt.location == cxt.quest:GetCastMember("teahouse") then
            return "STATE_INTRO"
        end
    end)
    :State("STATE_INTRO")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You arrive at the teahouse looking for the benefactor.
                * [p] One person watches you intensly and points to an empty chair.
            ]],
            OPT_PREACH = "Sit Down",
            REASON_PREACH = "Secure as much shills as you can!",
            
            DIALOG_BENEFACTOR_CONVINCED = [[
                * [p] You have secured additional financial support.
            ]],
            DIALOG_BENEFACTOR_UNCONVINCED = [[
                * [p] You have successfuly snuffed out any interest that may have been there.
            ]],
        }
        :Fn(function(cxt)
            cxt.quest.param.crowd = {}
            local present_people = 3
            for i = 1, present_people do
                cxt.quest:AssignCastMember("benefactor")
                cxt.quest:GetCastMember("benefactor"):MoveToLocation(cxt.location)
                table.insert(cxt.quest.param.crowd, cxt.quest:GetCastMember("benefactor"))
                cxt.quest:UnassignCastMember("benefactor")
            end
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Complete("go_to_teahouse")
            cxt.quest:Activate("secure_funding")
            cxt.enc:SetPrimaryCast(cxt.quest.param.crowd[1])
            cxt:GetAgent().temp_negotiation_behaviour = BENEFACTOR_BEHAVIOR
            BENEFACTOR_BEHAVIOR.agents = cxt.quest.param.crowd

            local postProcessingSuccessFn = function(cxt, minigame)
                cxt.caravan:AddMoney( minigame:GetPlayerNegotiator():GetModifierStacks( "SECURED_INVESTEMENTS" ) )
                cxt.quest.param.crowd[1]:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("convinced_benefactor"))

                cxt:Dialog("DIALOG_BENEFACTOR_CONVINCED")
                cxt.quest.param.good_performance = true
                cxt.quest:Complete()
                ConvoUtil.GiveQuestRewards(cxt)
            end

            local postProcessingFailFn = function(cxt, minigame)
                cxt.quest.param.crowd[1]:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("disappointed_benefactor"))

                cxt.quest.param.good_performance = false
                cxt:Dialog("DIALOG_BENEFACTOR_UNCONVINCED")
                cxt.quest:Fail()
                end

            cxt:Opt("OPT_PREACH")
                :Negotiation{
                    flags = NEGOTIATION_FLAGS.NO_BYSTANDERS,
                    reason_fn = function(minigame)
                        return cxt:GetLocString("REASON_PREACH")
                    end,

                    on_start_negotiation = function(minigame)
                        minigame.opponent_negotiator:CreateModifier("INVESTMENT_OPPORTUNITY")    
                    end,

                    on_success = postProcessingSuccessFn,
                    on_fail = postProcessingFailFn,
                }
        end)

QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
                * [p] A runner brought you a letter along with an invitation.
                * [p] It reads: Meet me in Dallie's Teahouse, I can make it worth your time.
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
                [p] Well, it's worth a shot.
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
                [p] This is clearly a scam.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)