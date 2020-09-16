-- Defines the advisors and their character alias.
local ADVISOR_IDS = {
    -- Elon Musk personality
    -- or maybe the personification of reddit, haven't decided yet.
    advisor_diplomacy = "ENDO",
    -- Ben Sharpiro personality
    advisor_manipulate = "PLOCKA",
    -- Donald Trump personality
    advisor_hostile = "RAKE",
}
-- Defines the home for the advisors
local ADVISOR_HOME = {
    advisor_diplomacy = "DIPL_PRES_OFFICE",
    advisor_manipulate = "MANI_PRES_OFFICE",
    advisor_hostile = "HOST_PRES_OFFICE",
}
-- Add the three advisors as casts in a quest.
-- qdef: the quest to add the advisors
local function AddAdvisors(qdef)
    for id, val in pairs(ADVISOR_IDS) do
        qdef:AddCastByAlias{
            cast_id = id,
            alias = val,
            on_assign = function(quest, agent)
                local location = TheGame:GetGameState():GetLocation(ADVISOR_HOME[id])
                if agent:GetBrain():GetWorkPosition() == nil and location then
                    AgentUtil.TakeJob(agent, location, "advisor")
                    agent:GetBrain():SetHome(location)
                end
            end,
            no_validation = true,
        }
    end
end
-- Add the home location to the quest. Typically done when you need to go home.
local function AddHomeCasts(qdef)
    qdef:AddLocationCast{
        cast_id = "home",
        when = QWHEN.MANUAL,
        cast_fn = function(quest, t)
            table.insert(t, quest:GetCastMember("primary_advisor"):GetHomeLocation())
        end,
        on_assign = function(quest,agent)
            if quest:GetCastMember("player_room") == nil then
                quest:AssignCastMember("player_room")
            end
        end,
        no_validation = true,
    }
    :AddLocationCast{
        cast_id = "player_room",
        when = QWHEN.MANUAL,
        cast_fn = function(quest, t)
            table.insert(t, TheGame:GetGameState():GetLocation(quest:GetCastMember("home").content_id .. ".inn_room"))
        end,
        no_validation = true,
    }
end

-- Add an optional primary advisor to the quest. might change the dialog of side quests.
local function AddPrimaryAdvisor(qdef, mandatory)
    qdef:AddCast{
        cast_id = "primary_advisor",
        optional = not mandatory,
        cast_fn = function(quest, t)
            local agent = TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor")
            if agent then
                table.insert(t, agent)
            end
        end,
        on_assign = function(quest, agent)
            quest.param.has_primary_advisor = true
            if quest:GetQuestDef():GetCast("home") then
                quest:AssignCastMember("home")
            end
        end,
        no_validation = true,
    }
    if mandatory then
        -- for debugging purpose to not crash game
        qdef:AddCastFallback{
            cast_fn = function( quest, t )
        
                local alias = "ENDO"
        
                local agent = TheGame:GetGameState():GetAgentOrMemento( alias )
                if agent == nil then
                    local def = Content.GetCharacterDef( alias )
                    local content_id, skin_table
                    if def then
                        content_id = def.id
                        local skins = Content.GetAllCharacterSkins( content_id )
                        if skins and #skins == 1 then
                            -- If there's a singular skin, use it automatically.
                            skin_table = skins[1]
                        end
        
                    else
                        content_id, skin_table = Content.GetCharacterSkinByAlias( alias )
                        if not TheGame:GetGameState():IsSkinAvailable( skin_table.uuid ) then
                            content_id, skin_table = nil, nil
                        end
                    end
                    if content_id then
                        agent = Agent( content_id, skin_table )
                    end
                end
                if not agent:IsRetired() then
                    table.insert( t, agent )
                end
            end,
            no_validation = true,
            on_assign = function(quest, agent)
                quest.param.has_primary_advisor = true
                if quest:GetQuestDef():GetCast("home") then
                    quest:AssignCastMember("home")
                end
            end,
        }
    end
end

-- Start the free time event. spawn the opportunity and change the actions
local function StartFreeTime(actions)
    local quest = QuestUtil.SpawnQuest("FREE_TIME_EVENT")
    if quest and actions then
        quest.param.free_time_actions = actions
    end
end
local function EndFreeTime()
    TheGame:GetGameState():ClearOpportunities()
end
local SUPPORT_DELTA = {
    [RELATIONSHIP.HATED] = -60,
    [RELATIONSHIP.DISLIKED] = -30,
    [RELATIONSHIP.NEUTRAL] = 0,
    [RELATIONSHIP.LIKED] = 30,
    [RELATIONSHIP.LOVED] = 60,
}

-- Calculate the score for an agent's support. Used as score_fn in agent casts.
-- Has a built-in randomizer. Generally speaking, an agent that likes you more, whose
-- faction supports you more, and whose wealth class supports you more, will be more 
-- likely to be casted.
local function SupportScore(agent)
    return DemocracyUtil.TryMainQuestFn("GetSupportForAgent", agent)
        + SUPPORT_DELTA[agent:GetRelationship()] + (math.random() * 30) -15
end

-- The opposite of SupportScore
local function OppositionScore(agent)
    return -SupportScore(agent)
end

-- Check if an agent is a valid random bystander.
-- A valid bystander should be non-retired, not in hiding, not in player party, is sentient, doesn't
-- have plot armor, and isn't on duty.
local function RandomBystanderCondition(agent)
    return not (AgentUtil.IsInHiding(agent) or agent:IsRetired() or agent:IsInPlayerParty()
        or AgentUtil.HasPlotArmour(agent) or not agent:IsSentient())
        and not (agent:GetBrain() and agent:GetBrain():IsOnDuty())
        and not agent:HasQuestMembership()
end

-- Do the convo for unlocking a location.
local function DoLocationUnlock(cxt, id)
    if not table.arraycontains(TheGame:GetGameState():GetMainQuest().param.unlocked_locations, id) then
        cxt:Opt("OPT_UNLOCK_NEW_LOCATION",TheGame:GetGameState():GetLocation(id))
            :PostText("TT_UNLOCK_NEW_LOCATION")
            :Fn(function(cxt)
                table.insert(TheGame:GetGameState():GetMainQuest().param.unlocked_locations, id)
            end)
    else
        print("Location already unlocked: "..id)
    end
end

-- Get wealth based on renown.
local function GetWealth(renown)
    renown = renown or 1
    return clamp(renown, 1, DemocracyConstants.wealth_levels)
end
local function GetWealthString(renown)
    return LOC(DemocracyConstants.wealth_string[GetWealth(renown)])
end
local function GetWealthIcon(renown)
    return DemocracyConstants.wealth_icon[GetWealth(renown)]
end
local function GetWealthColor(renown)
    return DemocracyConstants.wealth_color[GetWealth(renown)]
end

-- Add the cast for each opposition candidates, defined in opposition_candidates.lua
local function AddOppositionCast(qdef)
    for _, data in pairs(DemocracyConstants.opposition_data) do
        if data.character and data.character ~= "" then
            qdef:AddCastByAlias{
                cast_id = data.cast_id,
                alias = data.character,
                no_validation = true,
                on_assign = function(quest, agent)
                    AgentUtil.PutAgentInWorld(agent)
                end,
            }
        end
    end
end

local function TryMainQuestFn(id, ...)
    local arguments = {...}
    local ok, result = xpcall(function(...) return TheGame:GetGameState():GetMainQuest():DefFn(id, ...) end, generic_error, ...)
        -- print(loc.format("Call main quest fn: {1} (params: {2#listing})", id, arguments))
    print(ok, id, ...)
    print(result)
    return result
end

local function DebugSupportScreen()
    TheGame:FE():InsertScreen( DemocracyClass.Screen.SupportScreen() )
end

-- Param can be:
-- false: ignore stuff
-- true: not ignore
-- function: something to run after the debug bypass option
local function AddDebugBypass(cxt, param)
    if param == false then
        return
    end

    local option = cxt:Opt("OPT_DEBUG_BYPASS_HARD_CHECK")
        :PostText("TT_DEBUG_BYPASS_HARD_CHECK")
        :Fn(function()
            TheGame:GetGameState():GetOptions().is_custom_mode = true
        end)
    if type( param ) == "function" then option:Fn(param) end

    return option
end
local function AddAutofail(cxt, param)
    cxt:Opt("OPT_ACCEPT_FAILURE")
        :Fn(function(cxt)
            cxt:Wait()
            -- cxt.enc:YieldEncounter()
            TheGame:Lose()
        end)
    return AddDebugBypass(cxt, (TheGame:GetLocalSettings().DEBUG or false) and param)
end

local function DetermineSupportTarget(target)
    local support_type
    if type(target) == "string" then
        -- faction, probably convert.
        target = TheGame:GetGameState():GetFaction(target)
    end
    if type(target) == "number" then
        support_type = "WEALTH"
    elseif is_instance(target, Faction) then
        support_type = "FACTION"
    else
        support_type = "GENERAL"
    end
    return support_type, target
end
local function IsDemocracyCampaign(act_id)
    return string.find(act_id, "DEMOCRATIC_RACE")
end
local function DemocracyActFilter(self, act_id)
    return IsDemocracyCampaign(act_id)
end

local function PresentRequestQuest(cxt, quest, accept_fn, decline_fn, objective_id)
    local accepted = cxt.encounter:ShowJobOffer(quest, objective_id)

    if accepted then
        quest:Activate()
        TheGame:GetGameState():AddActiveQuest( quest )
        if objective_id then
            quest:SetObjectiveState( objective_id, QSTATUS.ACTIVE )
        end
        if accept_fn then
            accept_fn(cxt, quest)
        end
    else
        if decline_fn then
            decline_fn(cxt, quest)
        end
    end
    -- local quest = QuestUtil.SpawnInactiveQuest(quest_id, spawn_override)
    -- StateGraphUtil.PresentQuestOffer(
    --     cxt, quest, objective_id, 
    --     function(cxt)
    --         cxt:PlayQuestConvo(quest, QUEST_CONVO_HOOK.ACCEPTED)
    --         if accept_fn then
    --             accept_fn(cxt,quest)
    --         end
    --     end,
    --     decline_fn or function() end, false)
end
--

function ConvoOption:DeltaSupport(amt, target, ignore_notification)
    self:Fn(function()
        TryMainQuestFn("DeltaSupport", amt, target, ignore_notification)
    end)
    return self
end
return {
    ADVISOR_IDS = ADVISOR_IDS,
    ADVISOR_HOME = ADVISOR_HOME,
    AddAdvisors = AddAdvisors,
    AddHomeCasts = AddHomeCasts,
    AddPrimaryAdvisor = AddPrimaryAdvisor,
    StartFreeTime = StartFreeTime,
    EndFreeTime = EndFreeTime,
    SupportScore = SupportScore,
    OppositionScore = OppositionScore,
    RandomBystanderCondition = RandomBystanderCondition,
    DoLocationUnlock = DoLocationUnlock,
    GetWealth = GetWealth,
    GetWealthString = GetWealthString,
    GetWealthIcon = GetWealthIcon,
    AddOppositionCast = AddOppositionCast,
    GetWealthColor = GetWealthColor,
    TryMainQuestFn = TryMainQuestFn,
    DebugSupportScreen = DebugSupportScreen,
    AddDebugBypass = AddDebugBypass,
    AddAutofail = AddAutofail,
    DetermineSupportTarget = DetermineSupportTarget,
    IsDemocracyCampaign = IsDemocracyCampaign,
    DemocracyActFilter= DemocracyActFilter,
    PresentRequestQuest = PresentRequestQuest,
}