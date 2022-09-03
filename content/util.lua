-- local url_lib = require "lib/url"

local function url_escape(s)
    return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02x", string.byte(c))
    end))
end

local DemocracyUtil = class("DemocracyUtil")

local MODID = CURRENT_MOD_ID
-- if access an invalid val, look for the main quest and return a val if you can
getmetatable(DemocracyUtil).__index = function(self, k)
    if TheGame:GetGameState() and TheGame:GetGameState():GetMainQuest() then
        local quest = TheGame:GetGameState():GetMainQuest():GetQuestDef()
        -- print(quest)
        if quest and quest[k] and type(quest[k]) == "function" then
            return function(...)
                return DemocracyUtil.TryMainQuestFn(k, ...)
            end
        end
    end
end

-- Defines the advisors and their character alias.
DemocracyUtil.ADVISOR_IDS = {
    -- Elon Musk personality
    -- or maybe the personification of reddit, haven't decided yet.
    advisor_diplomacy = "ADVISOR_DIPLOMACY",
    -- Ben Sharpiro personality
    advisor_manipulate = "ADVISOR_MANIPULATE",
    -- Donald Trump personality
    advisor_hostile = "ADVISOR_HOSTILE",
}
-- Defines the home for the advisors
DemocracyUtil.ADVISOR_HOME = {
    advisor_diplomacy = "DIPL_PRES_OFFICE",
    advisor_manipulate = "MANI_PRES_OFFICE",
    advisor_hostile = "HOST_PRES_OFFICE",
}
-- Add the three advisors as casts in a quest.
-- qdef: the quest to add the advisors
function DemocracyUtil.AddAdvisors(qdef)
    for id, val in pairs(DemocracyUtil.ADVISOR_IDS) do
        qdef:AddCastByAlias{
            cast_id = id,
            alias = val,
            on_assign = function(quest, agent)
                local location = TheGame:GetGameState():GetLocation(DemocracyUtil.ADVISOR_HOME[id])
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
function DemocracyUtil.AddHomeCasts(qdef)
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
function DemocracyUtil.AddPrimaryAdvisor(qdef, mandatory)
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
        global_events = {
            primary_advisor_changed = function(quest, old_advisor, new_advisor, change_reason)
                if quest:GetCastMember("primary_advisor") then
                    quest:UnassignCastMember("primary_advisor")
                end
                if quest:GetQuestDef():GetCast("home") and quest:GetCastMember("home") then
                    quest:UnassignCastMember("home")
                end
                if quest:GetQuestDef():GetCast("player_room") and quest:GetCastMember("home") then
                    quest:UnassignCastMember("player_room")
                end
                if new_advisor then
                    quest:AssignCastMember("primary_advisor", new_advisor)
                else
                    quest.param.has_primary_advisor = false
                end
            end,
        },
        no_validation = true,
    }
    if mandatory then
        -- for debugging purpose to not crash game
        qdef:AddCastFallback{
            cast_fn = function( quest, t )

                local alias = "ADVISOR_DIPLOMACY"

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
function DemocracyUtil.GetBaseFreeTimeActions()
    return 8 -- might later be affected by other factors.
end
-- Start the free time event. spawn the opportunity and change the actions
function DemocracyUtil.StartFreeTime(actions)
    local quest = QuestUtil.SpawnQuest("FREE_TIME_EVENT")
    if quest and actions then
        quest.param.free_time_actions = math.round(actions * DemocracyUtil.GetBaseFreeTimeActions())
        quest:NotifyChanged()
    end
    return quest
end

function DemocracyUtil.GetFreeTimeQuests(exact)
    if exact then
        return TheGame:GetGameState():GetActiveQuestWithContentID("FREE_TIME_EVENT")
    end
    local result = {}
    for i, quest in TheGame:GetGameState():ActiveQuests() do
        local objective_id = quest:GetQuestDef().free_time_objective_id
        if objective_id and quest:IsActive(objective_id) then
            table.insert(result, quest)
        end
    end
    return result
end

function DemocracyUtil.EndFreeTime(exact)
    -- TheGame:GetGameState():ClearOpportunities()
    local events = DemocracyUtil.GetFreeTimeQuests(exact)
    for i, event in ipairs(events) do
        print("End quest: " .. tostring(event))
        event:Complete()
    end
end
function DemocracyUtil.IsFreeTimeActive(exact)
    return #(DemocracyUtil.GetFreeTimeQuests(exact)) > 0
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
function DemocracyUtil.SupportScore(agent)
    return DemocracyUtil.TryMainQuestFn("GetSupportForAgent", agent)
        + SUPPORT_DELTA[agent:GetRelationship()] + math.random(-100, 100)
end

-- The opposite of SupportScore
function DemocracyUtil.OppositionScore(agent)
    return -DemocracyUtil.SupportScore(agent)
end

-- Check if an agent is a valid random bystander.
-- A valid bystander should be non-retired, not in hiding, not in player party, is sentient, doesn't
-- have plot armor, and isn't on duty.
function DemocracyUtil.RandomBystanderCondition(agent)
    return not (AgentUtil.IsInHiding(agent) or agent:IsRetired() or agent:IsInPlayerParty()
        or AgentUtil.HasPlotArmour(agent) or not agent:IsSentient())
        and not (agent:GetBrain() and agent:GetBrain():GetWorkPosition() and agent:GetBrain():GetWorkPosition():ShouldBeWorking())
        and not agent:HasQuestMembership()
        -- Kick the auctioneer out of random bystander, as his negotiation behaviour is wack
        -- Don't worry guys, it's no longer wack anymore
        -- and agent:GetContentID() ~= "HESH_AUCTIONEER"
end

function DemocracyUtil.CanVote(agent)
    -- non-citizens can't vote
    -- for casting purposes, player can't vote.
    return agent and not agent:IsPlayer() and not agent:IsRetired()
        and agent:IsSentient() and agent:GetFactionID() ~= "RENTORIAN" and agent:GetFactionID() ~= "DELTREAN"
end

-- Do the convo for unlocking a location.
function DemocracyUtil.DoLocationUnlock(cxt, id)
    if type(id) ~= "string" then
        id = id:GetContentID()
    end
    if id and not table.arraycontains(TheGame:GetGameState():GetMainQuest().param.unlocked_locations, id) then
        cxt:RunLoop(function(cxt)
            cxt:Opt("OPT_UNLOCK_NEW_LOCATION",TheGame:GetGameState():GetLocation(id))
                :PostText("TT_UNLOCK_NEW_LOCATION")
                :Fn(function(cxt)
                    table.insert(TheGame:GetGameState():GetMainQuest().param.unlocked_locations, id)
                end)
                :Pop()
            cxt:Opt("OPT_SKIP_BONUS")
                :MakeUnder()
                :Pop()
        end)
    else
        print("Location already unlocked: "..id)
    end
end
function DemocracyUtil.LocationUnlocked(id)
    if not TheGame:GetGameState():GetMainQuest().param.unlocked_locations then
        return false
    end
    return table.arraycontains(TheGame:GetGameState():GetMainQuest().param.unlocked_locations, id)
end

-- Get wealth based on renown.
function DemocracyUtil.GetWealth(renown)
    if type(renown) == "table" then
        renown = renown:GetRenown() -- + (renown:HasTag("wealthy") and 1 or 0)
    end
    renown = renown or 1
    return clamp(math.floor(renown), 1, DemocracyConstants.wealth_levels)
end
function DemocracyUtil.GetWealthString(renown)
    return LOC(DemocracyConstants.wealth_string[DemocracyUtil.GetWealth(renown)])
end
function DemocracyUtil.GetWealthIcon(renown)
    return DemocracyConstants.wealth_icon[DemocracyUtil.GetWealth(renown)]
end
function DemocracyUtil.GetWealthColor(renown)
    return DemocracyConstants.wealth_color[DemocracyUtil.GetWealth(renown)]
end

-- Add the cast for each opposition candidates, defined in opposition_candidates.lua
function DemocracyUtil.AddOppositionCast(qdef)
    for _, data in pairs(DemocracyConstants.opposition_data) do
        if data.character and data.character ~= "" then
            qdef:AddCastByAlias{
                cast_id = data.cast_id,
                alias = data.character,
                no_validation = true,
                optional = true,
                on_assign = function(quest, agent)
                    if agent:GetContentID() == "KALANDRA" then
                        -- just because lol.
                        agent:SetBuildOverride("female_foreman_kalandra_build")
                    end
                    if data.workplace then
                        local location = TheGame:GetGameState():GetLocation(data.workplace)
                        if location then
                            -- if not location.location_data.work.opposition_candidate then
                            --     location.location_data.work.opposition_candidate = CreateClosedJob( PHASE_MASK_ALL, "Candidate", CHARACTER_ROLES.CONTACT )
                            --     location:AddWorkPosition("opposition_candidate")
                            -- end
                            local work_position
                            for id, data in location:WorkPositions() do
                                if data:GetRole() == CHARACTER_ROLES.CONTACT then
                                    work_position = id
                                    break
                                end
                            end
                            if agent:GetBrain():GetWorkPosition() == nil and work_position then
                                AgentUtil.TakeJob(agent, location, work_position)
                                -- agent:GetBrain():SetHome(location)
                            end
                        end
                    end
                    AgentUtil.PutAgentInWorld(agent)
                end,
            }
        end
    end
end

function DemocracyUtil.TryMainQuestFn(id, ...)
    local arguments = {...}
    local ok, result = xpcall(function(...) return TheGame:GetGameState():GetMainQuest():DefFn(id, ...) end, generic_error, ...)
        -- print(loc.format("Call main quest fn: {1} (params: {2#listing})", id, arguments))
    -- print(ok, id, ...)
    -- print(result)
    if not ok then
        print(result)
    end
    return result
end

function DemocracyUtil.DebugSupportScreen()
    TheGame:FE():InsertScreen( DemocracyClass.Screen.SupportScreen() )
end

-- Param can be:
-- false: ignore stuff
-- true: not ignore
-- function: something to run after the debug bypass option
function DemocracyUtil.AddDebugBypass(cxt, param)
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
function DemocracyUtil.AddAutofail(cxt, param)
    cxt:Opt("OPT_ACCEPT_FAILURE")
        :Fn(function(cxt)
            cxt:Wait()
            -- cxt.enc:YieldEncounter()
            TheGame:Lose()
        end)
    return DemocracyUtil.AddDebugBypass(cxt, (TheGame:GetLocalSettings().DEBUG or false) and param)
end

function DemocracyUtil.DetermineSupportTarget(target)
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
function DemocracyUtil.ToFactionID(a)
    if is_instance(a, Faction) then
        return a:GetID()
    elseif is_instance(a, Agent) then
        return a:GetFactionID()
    end
    return a
end
function DemocracyUtil.IsDemocracyCampaign(act_id)
    if not act_id then
        act_id = TheGame:GetGameState():GetCurrentActID()
    end
    if not act_id then
        return false
    end
    return string.find(act_id, "DEMOCRATIC_RACE")
end
function DemocracyUtil.DemocracyActFilter(self, act_id)
    return DemocracyUtil.IsDemocracyCampaign(act_id)
end

function DemocracyUtil.PresentRequestQuest(cxt, quest, accept_fn, decline_fn, objective_id)
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

function DemocracyUtil.CollectIssueImportance(agent)
    local t = {}
    for id, data in pairs(DemocracyConstants.issue_data) do
        t[id] = data:GetImportance(agent)
        if t[id] <= 0 then
            t[id] = nil
        end
    end
    return t
end

function DemocracyUtil.CheckHeavyHanded(modifier, card, minigame)
    -- destroying an argument without dropping resolve down to zero can only be done thru heavy handed
    if modifier.resolve and modifier.resolve > 0 then
        if card and card.id then
            print("uh oh, stinky")
            minigame.nuke_card = minigame.nuke_card or {}
            table.insert(minigame.nuke_card, card.id)
            return true
        end
    end
    return false
end

-- returns true if all demands are met. false if not, and also add options to negotiate
function DemocracyUtil.AddDemandConvo(cxt, demand_list, demand_modifiers, haggle_condition)
    local has_unresolved_demand = false
    for i, demand_data in ipairs(demand_list) do
        if not demand_data.resolved then
            has_unresolved_demand = true
        end
    end
    if not has_unresolved_demand then return true end
    -- this is done so that for each convo state so that an agent can only be negotiated once. Ever
    -- if you have to do more than one demand convo for a particular state, something's wrong with you.
    local ask_demand_param_id = "ASKED_DEMAND_" .. cxt:GetContentID() .. "_" .. cxt:GetStateID()
    if not cxt:GetAgent():HasMemory(ask_demand_param_id) and haggle_condition ~= false then
        local new_demands = deepcopy(demand_list)
        local original_demands = deepcopy(demand_list)
        local opt = cxt:Opt("OPT_NEGOTIATE_TERMS")
            :PostText("TT_NEGOTIATE_TERMS")
            :Dialog("DIALOG_NEGOTIATE_TERMS")
        if type(haggle_condition) == "function" then
            haggle_condition(opt)
        end
        opt:DemandNegotiation{
            demand_modifiers = demand_modifiers,
            demand_list = new_demands,
            cooldown = 0xffffff, -- you're not getting another negotiation
            on_success = function(cxt, minigame)
                table.clear(demand_list)
                for i, data in ipairs(new_demands) do
                    if not data.resolved then
                        table.insert(demand_list, data)
                    end
                end
                local diff = table_diff(demand_list, original_demands)
                -- if diff then
                --     TheGame:GetDebug():CreatePanel(DebugTable(diff))
                -- else
                --     print("no change lul")
                -- end
                if #demand_list <= 0 then
                    if minigame.nuke_card then
                        cxt:Dialog("DIALOG_NEGOTIATE_TERMS_CHEATER_FACE", type(minigame.nuke_card) == "table" and minigame.nuke_card[1] or minigame.nuke_card)
                        cxt:GetAgent():OpinionEvent(OPINION.USED_HEAVY_HANDED)
                    else
                        cxt:Dialog("DIALOG_NEGOTIATE_TERMS_PERFECT_SUCCESS")
                    end
                elseif not diff then
                    cxt:Dialog("DIALOG_NEGOTIATE_TERMS_NO_REDUCTION", demand_list)
                else
                    if minigame.nuke_card then
                        cxt:Dialog("DIALOG_NEGOTIATE_TERMS_CHEATER_FACE", type(minigame.nuke_card) == "table" and minigame.nuke_card[1] or minigame.nuke_card)
                        cxt:GetAgent():OpinionEvent(OPINION.USED_HEAVY_HANDED)
                    end
                    cxt:Dialog("DIALOG_NEGOTIATE_TERMS_SUCCESS", demand_list)
                end

                cxt:GetAgent():Remember(ask_demand_param_id)
            end,
            on_fail = function(cxt)
                cxt:Dialog("DIALOG_NEGOTIATE_TERMS_FAIL")
                cxt:GetAgent():Remember(ask_demand_param_id)
            end,
        }
    end
    for i, demand_data in ipairs(demand_list) do
        if not demand_data.resolved then
            -- this is done because it bypasses the hard check for convo_common when directly using cxt:Opt
            -- instead of taking an id, it takes the actual, localized string using our handy function
            local opt = cxt:RawOpt(loc.cap(loc.format("{1#one_demand}", demand_data)), demand_data.id)
            -- ConvoOption()
            -- cxt.enc:AddOption(opt)

            -- they have seperate secondary tags because i want to make the tagscores different for complying and accepting

            local modifier = Content.GetNegotiationModifier(demand_data.id)
            opt:Quip(cxt.enc:GetPlayer(), "meet_demand", demand_data.id, modifier.material_demand and "material_demand" or "abstract_demand")
                :Quip(cxt:GetAgent(), "accept_demand", demand_data.id, modifier.material_demand and "material_demand" or "abstract_demand")
            if modifier.GenerateConvoOption then
                modifier:GenerateConvoOption(cxt, opt, demand_data, demand_modifiers)
            end
        end
    end
    -- returns whether all demands are resolved.
    return false
end

function DemocracyUtil.IsWorkplace(location)
    return location:GetWorkPosition("foreman") -- all production workplaces has this tag
end

function DemocracyUtil.PunishTargetCondition(agent)
    if agent:IsRetired() or not agent:IsSentient() then
        return false
    end
    local reasons = {}
    if not AgentUtil.HasPlotArmour(agent) and agent:GetRelationship() == RELATIONSHIP.HATED then
        table.insert(reasons, LOC"DEMOCRACY.PUNISH_TARGET_REASON.HATRED")
    end
    if AgentUtil.IsCombatTarget(agent) then
        table.insert(reasons, LOC"DEMOCRACY.PUNISH_TARGET_REASON.QUEST_REQ")
    end
    return #reasons > 0, reasons
end

function DemocracyUtil.GetAllPunishmentTargets()
    local selector = Selector()
    selector:FromAllAgents()
    selector:Where(DemocracyUtil.PunishTargetCondition)

    return selector.candidates
end

function DemocracyUtil.GetOppositionID(agent)
    if not agent then
        return nil
    end
    for id, data in pairs(DemocracyConstants.opposition_data) do
        if data.character and data.character == agent:GetContentID() then
            return id
        end
    end
    return nil
end
function DemocracyUtil.GetOppositionData(agent)
    local opid = DemocracyUtil.GetOppositionID(agent)
    if opid then return DemocracyConstants.opposition_data[opid] end
    return nil
end
function DemocracyUtil.DoSentientPromotion(agent, promotion_def)
    if type(promotion_def) == "string" then
        promotion_def = Content.GetCharacterDef(promotion_def)
    end

    TheGame:GetGameState():GetPlayerAgent().graft_owner:RemoveSocialGraft(agent)

    agent:ReinitializeAgent( promotion_def )

    TheGame:GetGameState():GetPlayerAgent().graft_owner:AddSocialGraft(agent, agent:GetRelationship())
end

function DemocracyUtil.AddUnlockedLocationMarks(t, condition)
    for i, id in ipairs(TheGame:GetGameState():GetMainQuest().param.unlocked_locations) do
        local location = TheGame:GetGameState():GetLocation(id)
        if not condition or condition(location) then
            table.insert(t, location)
        end
    end
end
function DemocracyUtil.DoAlphaMessage()
    if TheGame:GetLocalSettings().ROBOTICS then
        engine.inst:Quit()
        return
    end

    local player = TheGame:GetGameState() and TheGame:GetGameState():GetPlayerAgent()
    -- local rook = player and player:GetContentID() == "ROOK"

    local img = engine.asset.Texture( "large/smith_end_screen.tex" )
    local popup = Screen.WIPpopup(
        LOC"DEMOCRACY.WIP_SCREEN.TITLE",
        LOC"DEMOCRACY.WIP_SCREEN.BODY",
        LOC"DEMOCRACY.WIP_SCREEN.BUTTON", img, function()
            TheGame:Win( GAMEOVER.ALPHA_VICTORY )
            TheGame:AddGameplayStat( "democracy_day_2", 1 )
        end )
    TheGame:FE():PushScreen(popup)
    popup:Layout()
end
function DemocracyUtil.InsertSelectCardScreen(cards, title, desc, class, on_select)
    local card_selected
    local function OnSelectCard(screen, widget, card)
        if card then
            screen:ShowRemoval(widget)
            AUDIO:PlayEvent("event:/ui/select_cards/remove_card")
            card_selected = card
            -- on_select(card)
            -- cxt.enc:ResumeEncounter( card )
        else
            -- on_select()
        end
    end
    local function OnEndFn(screen)
        if on_select then
            on_select(card_selected)
        end
    end

    local screen = Screen.DeckScreen( cards, OnSelectCard, class or Widget.NegotiationCard, OnEndFn )
    screen:SetMusicEvent( TheGame:LookupPlayerMusic( "deck_music" ))
    screen:SetTitles( title, desc )
    TheGame:FE():InsertScreen( screen )
    return screen
end
function DemocracyUtil.DebugSurveyVoterStances(issue_id, params)
    local issue = issue_id
    if type(issue) == "string" then
        issue = DemocracyConstants.issue_data[issue_id]
    end
    if not params then
        params = {}
    end
    assert(issue, "nil issue: " .. tostring(issue_id))
    local survey_result = {
        issue = issue,
        [-2] = {},
        [-1] = {},
        [0] = {},
        [1] = {},
        [2] = {},
        nonvoter = {},
        count = 0,
        params = params,
    }
    for i, agent in TheGame:GetGameState():Agents() do
        local cond = true
        if params.faction and agent:GetFactionID() ~= params.faction then
            cond = false
        end
        if params.renown and agent:GetRenown() ~= params.renown then
            cond = false
        end
        if params.content_id and agent:GetContentID() ~= params.content_id then
            cond = false
        end
        if cond then
            if DemocracyUtil.CanVote(agent) then
                local stance = issue:GetAgentStanceIndex(agent)
                assert( stance, "invalid stance for " .. tostring(agent))
                if not survey_result[stance] then
                    survey_result[stance] = {}
                end
                table.insert(survey_result[stance], agent)
            else
                table.insert(survey_result.nonvoter, agent)
            end
            survey_result.count = survey_result.count + 1
        end
    end
    DBG(survey_result)
    return survey_result
end

function DemocracyUtil.PresentJobChoice(cxt, quest_options, additional_opt, on_picked_fn)
    for k,v in ipairs(quest_options) do
        v:SetHideInOverlay(true)
    end

    if #quest_options > 0 then
        cxt:RunLoopingFn( function(cxt)
            for k,job in ipairs(quest_options) do

                cxt:QuestOpt( job )
                    :ShowQuestAsInactive()
                    :Fn(function(cxt)
                        StateGraphUtil.PresentQuestOffer(cxt, job, nil,
                            function()

                                for k,v in pairs(quest_options) do
                                    if v ~= job then
                                        v:Cancel()
                                    end
                                end
                                cxt:PlayQuestConvo(job, QUEST_CONVO_HOOK.ACCEPTED)
                                cxt:Pop()
                                job:SetHideInOverlay(false)
                                if on_picked_fn then
                                    on_picked_fn(cxt, quest_options, job)
                                end
                                cxt.quest.param.job_pool = nil
                            end,
                            function()
                                if not cxt:PlayQuestConvo(job, QUEST_CONVO_HOOK.DECLINED) then
                                    cxt:Quip( cxt:GetAgent(), "job_decline")
                                end
                            end,
                            #quest_options == 1)
                    end)
            end

            if additional_opt then
                -- StateGraphUtil.AddBackButton(cxt)
                additional_opt(cxt)
            end
        end )
    end
end

function DemocracyUtil.PopulateTheater(quest, location, num_patrons, cast_id)
    num_patrons = num_patrons or 8
    cast_id = cast_id or "audience"

    LocationUtil.SendPatronsAway( location )
    for i = 1, num_patrons do
        if quest:GetCastMember(cast_id) then
            quest:UnassignCastMember(cast_id)
        end
        quest:AssignCastMember(cast_id)
        quest:GetCastMember(cast_id):GetBrain():SendToPatronize(location)
    end
end

function DemocracyUtil.GetBossGrafts(num_boss, num_total, owner)
    local used_graft_ids = {}
    local grafts = {}
    owner = owner or TheGame:GetGameState():GetPlayerAgent()

    for k = 1, num_total do

        local collection
        if k <= num_boss then
            local rarity = CARD_RARITY.BOSS
            collection = GraftCollection.BossGrafts(owner, function(graft_def)
                return table.arrayfind(used_graft_ids, graft_def.id) == nil
            end):Rarity(rarity):Filter(function(graft_def)
                return graft_def.type ~= GRAFT_TYPE.COMBAT
            end)
        else
            local prob = GRAFT_DROP_RARITY[4]
            local rarity = weighted_arraypick(prob)
            collection = GraftCollection.Rewardable(owner, function(graft_def)
                return table.arrayfind(used_graft_ids, graft_def.id) == nil
            end):Rarity(rarity)
        end
        local graft = collection:Generate(1)[1]

        if graft then
            table.insert(grafts, graft)
            table.insert(used_graft_ids, graft.id)
        end
    end
    table.shuffle(grafts)
    return grafts
end
function DemocracyUtil.GiveBossRewards(cxt)
    cxt:Run(function()
        cxt.enc:WaitOnLine()

        local grafts = DemocracyUtil.GetBossGrafts(2, TheGame:GetGameState():GetGraftDraftDetails().count)
        if #grafts > 0 then
            cxt:Opt("OPT_GET_GRAFT")
                :PreIcon( global_images.receiving )
                :Fn(function()
                    local popup = Screen.PickGraftScreen(grafts, false, function(...) cxt.enc:ResumeEncounter(...) end)
                    TheGame:FE():InsertScreen( popup )
                    local chosen_graft = cxt.enc:YieldEncounter()
                    if chosen_graft then
                        cxt:Dialog("DIALOG_PLAYER_INSTALL_GRAFT", chosen_graft)
                        return chosen_graft
                    end
                end)
        end
    end)
end

-- A person's voter intention is a value indicating how likely they will vote for you.
-- This is based on Gaussian distribution. A G(0,100) offset will be added to this value to add randomness.
function DemocracyUtil.GetVoterIntentionIndex(data)
    local faction, wealth
    if data.agent then
        faction = data.agent:GetFactionID()
        wealth = DemocracyUtil.GetWealth(data.agent)
    end
    if data.faction then
        faction = type(data.faction) == "string" and data.faction or data.faction.id
    end
    if data.wealth then
        wealth = DemocracyUtil.GetWealth(data.wealth)
    end

    -- Here, we cap the index from the general support, so that high general support can only get you so far.
    -- You need to work on other types of support to win a voter
    local voter_index = 0

    local delta = DemocracyUtil.TryMainQuestFn("GetGeneralSupport") - DemocracyUtil.TryMainQuestFn("GetCurrentExpectation")
    voter_index = voter_index + delta

    if faction then
        voter_index = voter_index + (TheGame:GetGameState():GetMainQuest().param.faction_support[faction] or 0)
    end
    if wealth then
        voter_index = voter_index + (TheGame:GetGameState():GetMainQuest().param.wealth_support[wealth] or 0)
    end
    return voter_index
end

function DemocracyUtil.GetEndorsement(index)
    -- I know this looks like yanderedev's code, but I'm lazy today.
    -- Also this runs at O(1) time, so it doesn't really matter that much.
    -- And this reuses the relationship array. It's kinda redundant having another enum with the same elements
    -- representing similar things.
    if index >= 50 then
        return RELATIONSHIP.LOVED
    elseif index >= 20 then
        return RELATIONSHIP.LIKED
    elseif index > -20 then
        return RELATIONSHIP.NEUTRAL
    elseif index > -50 then
        return RELATIONSHIP.DISLIKED
    else
        return RELATIONSHIP.HATED
    end
end
function DemocracyUtil.GetFactionEndorsement(faction)
    return DemocracyUtil.GetEndorsement(DemocracyUtil.GetVoterIntentionIndex{faction = faction})
end
function DemocracyUtil.GetWealthEndorsement(wealth)
    return DemocracyUtil.GetEndorsement(DemocracyUtil.GetVoterIntentionIndex{wealth = wealth})
end
function DemocracyUtil.GetAgentEndorsement(agent)
    return DemocracyUtil.GetEndorsement(DemocracyUtil.GetVoterIntentionIndex{agent = agent})
end
function DemocracyUtil.GetAllOppositions(include_dropped_out)
    local t = {}
    for id, data in pairs(DemocracyConstants.opposition_data) do
        if include_dropped_out or DemocracyUtil.IsCandidateInRace(data.cast_id) then
            table.insert(t, data.cast_id)
        end
    end
    return t
end
function DemocracyUtil.GetOppositionVoterSupport(agent, opponent_id, base_support)
    if type(opponent_id) == "table" then
        opponent_id = DemocracyUtil.GetOppositionID(opponent_id)
    end
    local support = (base_support or DemocracyUtil.GetCurrentExpectation()) + DemocracyUtil.GetOppositionSupport(opponent_id)
    local opposition_data = DemocracyConstants.opposition_data[opponent_id]
    if opposition_data then
        if opposition_data.faction_support and opposition_data.faction_support[agent:GetFactionID()] then
            support = support + 4 * opposition_data.faction_support[agent:GetFactionID()]
        end
        if opposition_data.wealth_support and opposition_data.wealth_support[DemocracyUtil.GetWealth(agent)] then
            support = support + 4 * opposition_data.wealth_support[DemocracyUtil.GetWealth(agent)]
        end
    end
    return support
end
function DemocracyUtil.SimulateVoterChoice(agent, param)
    local choice_table = {}
    local loved_person = nil
    param = param or {}
    local available_opponents = param.available_opponents
    local score_bias = param.score_bias or function(x) return x end
    -- Will always vote a loved person, and will never vote a hated person
    if agent:GetRelationship() > RELATIONSHIP.HATED then
        local score = DemocracyUtil.GetSupportForAgent(agent) + SUPPORT_DELTA[agent:GetRelationship()] + DemocracyUtil.RandomGauss(0, 100)
        score = score_bias(score, TheGame:GetGameState():GetPlayerAgent())
        table.insert(choice_table, { TheGame:GetGameState():GetPlayerAgent(), score })
        if agent:GetRelationship() >= RELATIONSHIP.LOVED then
            loved_person = TheGame:GetGameState():GetPlayerAgent()
        end
    end
    for i, id in ipairs(available_opponents or DemocracyUtil.GetAllOppositions()) do
        local opponent = TheGame:GetGameState():GetMainQuest():GetCastMember(id)
        if agent:GetRelationship(opponent) > RELATIONSHIP.HATED then
            local score = DemocracyUtil.GetOppositionVoterSupport(agent, id) + SUPPORT_DELTA[agent:GetRelationship(opponent)] + DemocracyUtil.RandomGauss(0, 100)
            score = score_bias(score, opponent)
            table.insert(choice_table, { opponent, score })
            if agent:GetRelationship(opponent) >= RELATIONSHIP.LOVED then
                if loved_person then
                    return false, "CONFLICTING_LOVED" -- If love two candidates somehow, don't vote
                else
                    loved_person = opponent
                end
            end
        end
    end
    if loved_person then
        return loved_person, "LOVED_VOTE"
    end
    table.sort(choice_table, function(a, b) return a[2] > b[2] end)
    if #choice_table == 0 then
        return false, "NO_GOOD_CHOICES" -- No choice at all
    elseif #choice_table == 1 then
        return choice_table[1][1], "SINGLE_CANDIDATE" -- Lmao one candidate
    elseif choice_table[1][2] - choice_table[#choice_table][2] <= 80 then
        return false, "VOTER_APATHY" -- Voter apathy
    else
        return choice_table[1][1], "VOTE_CASTED"
    end
end
function DemocracyUtil.SimulateVoting(param, include_phantoms)
    local result = {}
    for i, agent in TheGame:GetGameState():Agents() do
        if DemocracyUtil.CanVote(agent) then
            result[agent] = DemocracyUtil.SimulateVoterChoice(agent, param)
        end
    end
    if include_phantoms then
        -- Also add phantom votes
        for i, id in ipairs(TheGame:GetGameState().region:GetContent().population) do
            local phantom_agent = DemocracyClass.PhantomAgent(id)
            for i = 1, 6 - phantom_agent:GetRenown() do
                local agent = DemocracyClass.PhantomAgent(id)
                print(agent)
                result[agent] = DemocracyUtil.SimulateVoterChoice(agent, param)
            end
        end
    end
    return result
end
function DemocracyUtil.SummarizeVotes(voting_results)
    local result = {
        vote_count = {},
        raw_data = voting_results,
    }
    for agent, vote in pairs(voting_results) do
        result.vote_count[vote] = (result.vote_count[vote] or 0) + 1
    end
    return result
end
function DemocracyUtil.DBGVoting(param, include_phantoms)
    DBG(DemocracyUtil.SummarizeVotes(DemocracyUtil.SimulateVoting(param, include_phantoms)))
end
function DemocracyUtil.CalculatePartyStrength(members)
    if is_instance(members, Party) then
        members = members:GetMembers()
    end
    local score = 0
    for i, agent in ipairs(members) do
        score = score + agent:GetCombatStrength()
    end
    return score
end
function DemocracyUtil.GetAlliancePotential(candidate_id)
    local oppositions =  DemocracyConstants.opposition_data
    local candidate_data = oppositions[candidate_id]
    assert(candidate_data, "Invalid candidate_id:" .. candidate_id)
    local score = DemocracyUtil.GetVoterIntentionIndex({faction = candidate_data.main_supporter})
    local target_candidate = TheGame:GetGameState():GetMainQuest():GetCastMember(candidate_data.cast_id)
    for id, data in pairs(oppositions) do
        if id ~= candidate_id then
            local candidate = TheGame:GetGameState():GetMainQuest():GetCastMember(data.cast_id)
            if candidate then
                local rel_with_player = math.max(candidate:GetRelationship(), DemocracyUtil.TryMainQuestFn("GetAlliance", candidate) and RELATIONSHIP.LIKED or RELATIONSHIP.HATED)
                local faction_rel = target_candidate:GetRelationship(candidate)
                -- Positive when friend with friend, enemy of enemy
                -- Negative when enemy of friend, friend of enemy
                local fof = (rel_with_player - RELATIONSHIP.NEUTRAL) * (faction_rel - RELATIONSHIP.NEUTRAL)
                if fof <= -2 then
                    -- This happens when you are liked with hated, loved with disliked,
                    -- disliked of loved(never happens unless somehow a faction has more than 1 candidates)
                    -- or hated of liked
                    return nil, candidate
                elseif fof == -1 then
                    score = score - 25
                else
                    score = score + 10 * fof
                end
            end
        end
    end
    return score
end
function QuestDef:GetProviderCast()
    for i, cast_def in ipairs( self.cast ) do
        if cast_def.provider then
            return cast_def
        end
    end
end
function DemocracyUtil.SpawnRequestQuest(agent, allow_placeholder, spawn_param)
    if not spawn_param then
        spawn_param = {}
    end
    local potential_jobs = {}
    for id, def in pairs( Content.GetAllQuests() ) do
        if def.qtype == QTYPE.SIDE and def:HasTag("REQUEST_JOB") and (not def:HasTag("manual_spawn")) then
            table.insert(potential_jobs, def)
        end
    end
    table.shuffle(potential_jobs)
    -- table.insert(potential_jobs, Content.GetQuestDef( "PLACEHOLDER_REQUEST_QUEST" ))
    -- DBG(potential_jobs)
    for i, def in ipairs(potential_jobs) do
        local provider_cast = def:GetProviderCast()
        local params = deepcopy(spawn_param)

        if provider_cast then
            if not params.cast then
                params.cast = {}
            end
            params.cast[provider_cast.cast_id] = agent
            local spawned_quest = QuestUtil.SpawnInactiveQuest(def.id, params)
            if spawned_quest then
                -- DBG(spawned_quest)
                if params.debug_test then
                    TheGame:GetGameState():AddActiveQuest( spawned_quest )
                    spawned_quest:Activate()
                end
                return spawned_quest
            end
        end
    end
    if allow_placeholder then
        local spawned_quest = QuestUtil.SpawnInactiveQuest("PLACEHOLDER_REQUEST_QUEST", params)
        if spawned_quest then
            -- DBG(spawned_quest)
            if params.debug_test then
                TheGame:GetGameState():AddActiveQuest( spawned_quest )
                spawned_quest:Activate()
            end
            return spawned_quest
        end
    end
    return nil
    -- assert(false, loc.format("No request quest spawned for {1#agent}", agent))
end
function DemocracyUtil.HasRequestQuest(agent)
    return agent:HasMemory("ISSUED_REQUEST_QUEST")
    -- for k,quest in TheGame:GetGameState():ActiveQuests() do
    --     if quest:GetProvider() == agent then
    --         return true
    --     end
    -- end
    -- return false
end
function DemocracyUtil.DebugSetRandomDeck(seed)
    local DECKS = require "content/quests/experiments/sal_day_4_decks"
    if seed then
        math.randomseed(seed)
    end
    local deck_idx = math.random(#DECKS)
    local deck = DECKS[deck_idx]
    TheGame:GetGameState():SetDecks(deck)
end
function DemocracyUtil.DoAllianceConvo(cxt, ally, post_fn, potential_offset)
    post_fn = post_fn or function(cxt) StateGraphUtil.AddEndOption(cxt) end
    potential_offset = potential_offset or 0
    local candidate_data = DemocracyUtil.GetOppositionData(ally)
    cxt:Dialog("DIALOG_ALLIANCE_TALK_INTRO")
    if not candidate_data then
        cxt:Dialog("DIALOG_ALLIANCE_TALK_INVALID")
    else
        local potential, problem_agent = DemocracyUtil.GetAlliancePotential(candidate_data.cast_id)
        local platform = candidate_data.platform
        local oppo_main_stance = candidate_data.stances[platform]
        local player_main_stance = DemocracyUtil.GetStance(platform) or 0
        cxt.enc.scratch.opposite_spectrum = oppo_main_stance * player_main_stance <= -2
        if potential and DemocracyUtil.GetEndorsement(potential + potential_offset) >= RELATIONSHIP.LOVED then
            cxt:Dialog("DIALOG_ALLIANCE_TALK_UNCONDITIONAL")
            if cxt.enc.scratch.opposite_spectrum then
                cxt:Opt("OPT_ALLIANCE_TALK_AGREE_STANCE")
                    :Dialog("DIALOG_ALLIANCE_TALK_AGREE_STANCE")
                    :UpdatePoliticalStance(platform, oppo_main_stance)
                    -- :ReceiveOpinion(OPINION.ALLIED_WITH, nil, ally)
                    :Fn(function(cxt)
                        DemocracyUtil.TryMainQuestFn("SetAlliance", ally)
                        post_fn(cxt, true)
                    end)
                    -- :DoneConvo()

            else
                cxt:Opt("OPT_ALLIANCE_TALK_ACCEPT")
                    :Dialog("DIALOG_ALLIANCE_TALK_ACCEPT")
                    -- :UpdatePoliticalStance(platform, oppo_main_stance)
                    -- :ReceiveOpinion(OPINION.ALLIED_WITH, nil, ally)
                    :Fn(function(cxt)
                        DemocracyUtil.TryMainQuestFn("SetAlliance", ally)
                        post_fn(cxt, true)
                    end)
                    -- :DoneConvo()
            end
            cxt:Opt("OPT_ALLIANCE_TALK_REJECT_ALLIANCE")
                :Dialog("DIALOG_ALLIANCE_TALK_REJECT_ALLIANCE")
                :Fn(function()
                    ally:Remember("REJECTED_ALLIANCE")
                    post_fn(cxt, false)
                end)
                -- :DoneConvo()
        elseif potential and DemocracyUtil.GetEndorsement(potential + potential_offset) >= RELATIONSHIP.NEUTRAL then
            potential = potential + potential_offset
            cxt:Dialog("DIALOG_ALLIANCE_TALK_CONDITIONAL", cxt.enc.scratch.opposite_spectrum and (platform .. "_" .. oppo_main_stance) or nil)
            if cxt.enc.scratch.opposite_spectrum then
                cxt:RunLoop(function(cxt)
                    cxt:Opt("OPT_ALLIANCE_TALK_AGREE_STANCE")
                        :Dialog("DIALOG_ALLIANCE_TALK_AGREE_STANCE")
                        :UpdatePoliticalStance(platform, oppo_main_stance)
                        :Pop()
                    cxt:Opt("OPT_ALLIANCE_TALK_REJECT_ALLIANCE")
                        :Dialog("DIALOG_ALLIANCE_TALK_REJECT_ALLIANCE")
                        :Fn(function()
                            ally:Remember("REJECTED_ALLIANCE")
                            post_fn(cxt, false)
                        end)
                        -- :DoneConvo()
                end)
            end
            local demands, demand_list = ally:HasMemoryFromToday("ALLIANCE_DEMANDS"), ally:HasMemoryFromToday("ALLIANCE_DEMAND_LIST")
            if not demands or not demand_list then
                local rawcost = 500 - potential * 6
                demands, demand_list = DemocracyUtil.GenerateDemandList(rawcost, ally, nil, {auto_scale = true})
                ally:Remember("ALLIANCE_DEMANDS", demands)
                ally:Remember("ALLIANCE_DEMAND_LIST", demand_list)
                cxt.enc.scratch.new_demands = true
            end
            cxt:Dialog("DIALOG_ALLIANCE_TALK_DEMANDS", demand_list)
            cxt:RunLoop(function(cxt)
                local done_all = DemocracyUtil.AddDemandConvo(cxt, demand_list, demands)
                if done_all then
                    cxt:Dialog("DIALOG_ALLIANCE_TALK_ACCEPT_CONDITIONAL")
                    -- ally:OpinionEvent(OPINION.ALLIED_WITH)
                    DemocracyUtil.TryMainQuestFn("SetAlliance", ally)
                    -- StateGraphUtil.AddEndOption(cxt)
                    post_fn(cxt, true)
                    return
                end
            -- local demand_list = DemocracyUtil.ParseDemandList(demands)
                cxt:Opt("OPT_ALLIANCE_TALK_REJECT_ALLIANCE")
                    :Dialog("DIALOG_ALLIANCE_TALK_REJECT_ALLIANCE")
                    :Fn(function()
                        ally:Remember("REJECTED_ALLIANCE")
                        post_fn(cxt, false)
                    end)
                    -- :DoneConvo()
            end)
        else
            if problem_agent then
                cxt.enc.scratch.is_problem_ally = math.max(problem_agent:GetRelationship(), DemocracyUtil.TryMainQuestFn("GetAlliance", problem_agent) and RELATIONSHIP.LIKED or RELATIONSHIP.HATED) > RELATIONSHIP.NEUTRAL
                cxt:Dialog("DIALOG_ALLIANCE_TALK_BAD_ALLY", problem_agent)
            else
                cxt:Dialog("DIALOG_ALLIANCE_TALK_REJECT")
            end
            ally:Remember("REJECTED_ALLIANCE")
            -- StateGraphUtil.AddEndOption(cxt)
            post_fn(cxt, false)
        end
    end
end
function DemocracyUtil.GenerateGenericOppositionTable()
    local GENERIC_OPPOSITION = {"GAMBLER", "TEI", "DANGEROUS_STRANGER", "NAND"}
    local player_id = TheGame:GetGameState():GetPlayerAgent():GetContentID()
    if player_id ~= "SAL" then
        table.insert(GENERIC_OPPOSITION, "NPC_SAL")
    end
    -- if player_id ~= "ROOK" then
    --     table.insert(GENERIC_OPPOSITION, "NPC_ROOK")
    -- end
    if player_id ~= "SMITH" then
        local def = Content.GetCharacterDef("NPC_SMITH")
        if def and def.negotiation_data and def.negotiation_data.behaviour and def.negotiation_data.behaviour.Cycle then
            table.insert(GENERIC_OPPOSITION, "NPC_SMITH")
        end
    end
    if player_id ~= "PC_SHEL" then
        table.insert(GENERIC_OPPOSITION, "BRAVE_MERCHANT")
    end
    return GENERIC_OPPOSITION
end
function DemocracyUtil.GetAgentStanceIndex(issue, agent)
    if type(issue) == "string" then
        issue = DemocracyConstants.issue_data[issue]
    end
    return issue:GetAgentStanceIndex(agent)
end
function DemocracyUtil.GetModSetting(id)
    if id then
        local file_settings = TheGame:GetGameState() and TheGame:GetGameState():GetMainQuest() and TheGame:GetGameState():GetMainQuest().param.local_file_settings or {}
        if file_settings[id] ~= nil then
            return file_settings[id]
        end
        return Content.GetModSetting( MODID, id )
    end
end
function DemocracyUtil.GetModData()
    return Content.FindMod(MODID)
end
function DemocracyUtil.GetPerFileSettings()
    local data = {}
    for i, setting in ipairs(DemocracyUtil.GetModData().mod_options) do
        if setting.per_save_file then
            table.insert(data,setting.key)
        end
    end
    return data
end
function DemocracyUtil.GetBodyguards(filter_fn, cxt)
    local candidates = {}
    for i, agent in ipairs(TheGame:GetGameState():GetCaravan():GetParty():GetMembers()) do
        if agent:IsHiredMember() or agent:IsPet() then
            if not cxt.quest or not agent:IsCastInQuest(cxt.quest) then
                if not filter_fn or filter_fn(agent) then
                    table.insert(candidates, agent)
                end
            end
        end
    end
    return candidates
end

function DemocracyUtil.AddBodyguardOpt(cxt, fn, opt_id, filter_fn)
    local candidates = DemocracyUtil.GetBodyguards(filter_fn, cxt)
    if candidates and #candidates > 0 then
        cxt:Opt(opt_id or "OPT_USE_BODYGUARD")
            :LoopingFn(function(cxt)
                for i, agent in ipairs(candidates) do
                    local opt = cxt:Opt("OPT_SELECT_AGENT", agent)
                    fn(opt, agent, agent:IsSentient(), agent:GetSpecies() == SPECIES.MECH)
                end
                StateGraphUtil.AddBackButton(cxt)
            end)
    end
end

-- Choose a random number in a gaussian distribution.
-- Based on the polar form of the Box-Muller transformation.
-- I yoinked it from the game code, but I removed the clamp because it's lame
function DemocracyUtil.RandomGauss( mean, stddev )
    local x1, x2, w
    repeat
        x1 = 2 * math.random() - 1
        x2 = 2 * math.random() - 1
        w = x1 * x1 + x2 * x2
    until w > 1e-10 and w < 1.0 -- This safeguards against undefined log or division

    w = math.sqrt( (-2 * math.log( w ) ) / w )
    local x = (x1 * w)*stddev + mean
    return x
end

-- Choose a random number in an exponential distribution
function DemocracyUtil.RandomExp( mean )
    return - math.log(math.max(math.random(), 1e-3)) * mean
end

function DemocracyUtil.CalculateStrengthRatio(blue, red, blue_bonus, red_bonus)
    local blue_score = (blue:GetCombatStrength() + (blue:IsBoss() and 4 or 0)) * blue.health:GetPercent() + (blue_bonus or 0)
    local red_score = (red:GetCombatStrength() + (red:IsBoss() and 4 or 0)) * red.health:GetPercent() + (red_bonus or 0)
    local ratio = blue_score
    return ratio
end

function DemocracyUtil.SimulateBattle(blue, red, blue_bonus, red_bonus)
    local ratio = DemocracyUtil.CalculateStrengthRatio(blue, red, blue_bonus, red_bonus)
    print("ratio =", ratio)
    print("log(ratio) =", math.log(ratio))
    local gauss_result = DemocracyUtil.RandomGauss(0, math.exp (1))
    print("G(0, 1) =", gauss_result)
    local result =  gauss_result < math.log(ratio)
    if result then
        blue.health:SetPercent(blue.health:GetPercent() * math.random(50, 80) * 0.01)
        red.health:SetPercent(red.health:GetPercent() * math.random(20, 30) * 0.01)
    else
        red.health:SetPercent(red.health:GetPercent() * math.random(50, 80) * 0.01)
        blue.health:SetPercent(blue.health:GetPercent() * math.random(20, 30) * 0.01)
    end
    return result
end

function DemocracyUtil.QuipStance(cxt, agent, stance, ...)
    if type(stance) == "string" then
        local st_issue, st_stance = stance:match("([_%w]+)_([%-%d]+)")
        st_stance = tonumber(st_stance)
        if st_issue and st_stance then
            local issue_data = DemocracyConstants.issue_data[loc.toupper(st_issue)]
            if issue_data and issue_data.stances[st_stance] then
                stance = issue_data.stances[st_stance]
            end
        end
    end
    assert(stance == nil or type(stance) == "table", "Stance must be a table or nil")
    cxt.enc.scratch.stance = stance
    local stance_tags = {}
    if stance then
        if stance.stance_intensity > 0 then
            table.insert(stance_tags, "s_pro_" .. loc.tolower( stance.issue_id ))
        elseif stance.stance_intensity < 0 then
            table.insert(stance_tags, "s_anti_" .. loc.tolower( stance.issue_id ))
        else
            table.insert(stance_tags, "s_no_" .. loc.tolower( stance.issue_id ))
        end
    else
        for id, data in pairs(DemocracyConstants.issue_data) do
            local index = DemocracyUtil.GetAgentStanceIndex(data, agent)
            if index > 0 then
                table.insert(stance_tags, "s_pro_" .. loc.tolower( id ))
            elseif index < 0 then
                table.insert(stance_tags, "s_anti_" .. loc.tolower( id ))
            else
                table.insert(stance_tags, "s_no_" .. loc.tolower( id ))
            end
        end
    end
    local additional_tags = {...}
    cxt:Quip(agent, "stance_quip", table.unpack(table.merge(stance_tags, additional_tags)))
end

function DemocracyUtil.SplitNullable(str, sep)
    local sep, fields = sep or " ", {}
    local pattern = string.format("([^%s]*)[%s]", sep, sep)
    str = str .. sep
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

function DemocracyUtil.LoadCSV(path)
    local file = io.open( path, "r" )
    if file then
        local raw_data = file:read("a")
        local raw_rows = raw_data:split('\n')
        local result = {}
        for i, row in ipairs(raw_rows) do
            local raw_entries = DemocracyUtil.SplitNullable(row, ',')
            table.insert(result, raw_entries)
        end
        return result
    end
end

function DemocracyUtil.CalculateBossScale(boss_scale)
    return boss_scale[clamp(
        GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY ) or 2,
        1,
        #boss_scale)]
end

DemocracyUtil.EXCLUDED_WEAPONS = {
    "makeshift_dagger", "makeshift_dagger_plus"
}

function DemocracyUtil.IsWeapon(card)
    if not is_instance(card, Battle.Card) then
        return false
    end
    if table.arraycontains(DemocracyUtil.EXCLUDED_WEAPONS, card.id) then
        return false
    end
    return card:IsItemCard() and card.min_damage and card.max_damage
end

DemocracyUtil.FIRST_AID_CARDS = {"combat_gauze", "salve", "healing_vapors", "bandage", "triage"}

function DemocracyUtil.IsFirstAid(card)
    if not is_instance(card, Battle.Card) then
        return false
    end
    return table.arraycontains(DemocracyUtil.FIRST_AID_CARDS, card.id)
end

local main_branch_id = 2291214111
local test_branch_id = 2503106782

function DemocracyUtil.DeployMod(experimental)
    if not engine and engine.steam then
        print("Epic bad lol")
        return
    end
    local function ConfirmFunction()
        rawset(_G, "ConfirmUpload", nil)
        local mod_id = experimental and test_branch_id or main_branch_id
        local mod = DemocracyUtil.GetModData()
        mod.workshop_id = mod_id
        local function OnSubmitted(item, msg)
            print( "OnSubmitted", msg, tostr(item))
            if item.workshop_id and item.workshop_id ~= 0 then
                print("Workshop ID:", item.workshop_id)
            end
            if item.lastResult == engine.steam.EResultOK then
                print( msg or "Submit succeeded!")
            else
                -- From the workshop docs:
                -- k_EResultFail (2) - Generic failure.
                -- k_EResultInvalidParam (8) - Either the provided app ID is invalid or doesn't match the consumer app ID of the item or, you have not enabled ISteamUGC for the provided app ID on the Steam Workshop Configuration App Admin page.
                -- The preview file is smaller than 16 bytes.
                -- k_EResultAccessDenied (15) - The user doesn't own a license for the provided app ID.
                -- k_EResultFileNotFound (9) - Failed to get the workshop info for the item or failed to read the preview file.
                -- k_EResultFileNotFound (9) - The provided content folder is not valid. (eg. this workshop_id has previously been deleted)
                -- k_EResultLockingFailed (33) - Failed to aquire UGC Lock.
                -- k_EResultLimitExceeded (25) - The preview image is too large, it must be less than 1 Megabyte; or there is not enough space available on the users Steam Cloud.

                msg = msg or "Submit failed!"
                msg = msg .. string.format( " (error=%s)", tostring(item.lastResult))
                print(msg)
            end
        end
        print("Submitting to workshop:", tostr(mod))
        print("Experimental =", experimental)
        engine.steam:SubmitItem( mod, OnSubmitted )
    end
    print(loc.format("Are you sure? Enter ConfirmUpload() in the console to confirm. (Experimental={1})", experimental and "true" or "false"))
    rawset(_G, "ConfirmUpload", ConfirmFunction)
end

function DemocracyUtil.SendMetricsData(event_id, event_data)
    if TheGame:GetLocalSettings().ROBOTICS then
        return
    end
    if not DemocracyUtil.GetModSetting("enable_metrics_collection") then
        return
    end
    -- Initialize fields
    local payload_fields =
    {
        -- Branch
        ["entry.1174125527"] = "",
        -- Version
        ["entry.1846367179"] = "",
        -- Run ID
        ["entry.1200902253"] = "",
        -- Character
        ["entry.1738061935"] = "",
        -- Prestige
        ["entry.992848941"] = "",
        -- Day Segment
        ["entry.422634254"] = "",
        -- Event ID
        ["entry.169203787"] = event_id or "",
        -- Event Data
        ["entry.541892026"] = type(event_data) == "table" and json.encode( event_data ) or event_data or "",
    }

    -- Set the field for "Branch"
    if MODID == "DemocraticRace" then
        payload_fields["entry.1174125527"] = "GitHub"
    elseif MODID == tostring(main_branch_id) then
        payload_fields["entry.1174125527"] = "SteamMain"
    elseif MODID == tostring(test_branch_id) then
        payload_fields["entry.1174125527"] = "SteamTest"
    else
        payload_fields["entry.1174125527"] = "Other(" .. MODID .. ")"
    end

    -- Set the field for "Version"
    local mod_data = DemocracyUtil.GetModData()
    payload_fields["entry.1846367179"] = mod_data.version

    local game_state = TheGame:GetGameState()
    if game_state then
        -- Set the field for "Day Segment"
        local main_quest = game_state:GetMainQuest()
        if main_quest and main_quest:GetContentID() == "DEMOCRATIC_RACE_MAIN" then
            if main_quest.param.debug_mode then
                return
            end
            payload_fields["entry.422634254"] = (main_quest.param.day or 1) .. "/" .. (main_quest.param.sub_day_progress or 1)
        else
            payload_fields["entry.422634254"] = tostring(game_state.datetime)
        end
        -- Set the field for "Run ID"
        payload_fields["entry.1200902253"] = game_state.uuid
        -- Set the field for "Character"
        payload_fields["entry.1738061935"] = game_state.player_agent and game_state.player_agent:GetContentID()
        -- Set the field for "Prestige"
        -- "Story" or "P0", "P1", ...
        if game_state.options.story_mode then
            payload_fields["entry.992848941"] = "Story"
        else
            payload_fields["entry.992848941"] = "P" .. (game_state.options.advancement_level or 0)
        end
    end

    -- Assemble the URL
    local query_strings = {}
    for id, data in pairs(payload_fields) do
        if data and data ~= "" then
            assert(type(data) == "string")
            table.insert(query_strings, loc.format("{1}={2}", id, url_escape(data)))
        end
    end
    local url = "https://docs.google.com/forms/d/e/1FAIpQLSe3KWUoJQsLqyMAspjQRHowazaXEMR0rxiqKNyFqwwpVB0hWw/formResponse"
    if #query_strings > 0 then
        url = url .. "?"
        for i, query in ipairs(query_strings) do
            if i == 1 then
                url = url .. query
            else
                url = url .. "&" .. query
            end
        end
    end
    -- Actually send the payload
    engine.inst:GetURL(url, nil,
        function( success, code, response )
            print("ID:", event_id)
            print(event_data)
            print("Access Code:", code)
            print("URL:", url)
            if success then
                print("Metric successfully sent")
            end
        end)
end

local demand_generator = require"DEMOCRATICRACE:content/demand_generator"
DemocracyUtil.demand_generator = demand_generator

for id, data in pairs(demand_generator) do
    DemocracyUtil[id] = data
end
--
local endings = require "DEMOCRATICRACE:content/endings"
for id, data in pairs(endings) do
    DemocracyUtil[id] = data
end

function ConvoOption:DeltaSupport(amt, target, ignore_notification)
    self:Fn(function()
        DemocracyUtil.TryMainQuestFn("DeltaSupport", amt, target, ignore_notification)
    end)
    return self
end

function ConvoOption:RequireFreeTimeAction(actions, display_only, optional)
    if actions and not optional then
        self:PostText("TT_FREE_TIME_ACTION_COST", actions)
    end
    if actions and optional then
        self:PostText("TT_FREE_TIME_ACTION_COST_OPTIONAL", actions)
    end
    local freetimeevents = DemocracyUtil.GetFreeTimeQuests()
    -- local q = freetimeevents[1]
    if not optional then
        self:ReqCondition(freetimeevents and #freetimeevents > 0, "REQ_FREE_TIME")
        if freetimeevents and #freetimeevents > 0 and actions then
            local q = freetimeevents[1]
            self:ReqCondition(q.param.free_time_actions >= actions, "REQ_FREE_TIME_ACTIONS")
            if not display_only then
                self:Fn(function(cxt)
                    q:DefFn("DeltaActions", -actions)
                end)
            end
        end
    else
        if freetimeevents and #freetimeevents > 0 and actions then
            local q = freetimeevents[1]
            if not display_only then
                self:Fn(function(cxt)
                    q:DefFn("DeltaActions", -actions)
                end)
            end
        end
    end

    return self
end

function QuestDef:AddFreeTimeObjective( child )
    local new_child = table.extend{
        id = "time_countdown",
        title = "You have {1} {1*action|actions} left",
        title_fn = function(quest, str)
            return loc.format(str, quest.param.free_time_actions or 0)
        end,
        desc = "You can choose to visit a location during your free time.",
        mark = function(quest, t, in_location)
            DemocracyUtil.AddUnlockedLocationMarks(t)
        end,
        on_activate = function(quest)
            local questdef = quest:GetQuestDef()
            local multiplier = questdef:GetObjective(questdef.free_time_objective_id).action_multiplier or 1
            quest.param.free_time_actions = math.round(DemocracyUtil.GetBaseFreeTimeActions() * multiplier)
        end,
        events =
        {
            resolve_negotiation = function(quest, minigame)
                if minigame.start_params.no_free_time_cost then
                    return
                end
                -- Dynamically scale action cost based on turn taken
                -- <= 4: one action
                -- <= 8: two actions
                -- <= 12: three actions
                -- More: What the Hesh are you doing. Also at least 4 actions
                quest:DefFn("DeltaActions", -math.max(math.ceil(minigame:GetTurns() / 4), 1), "NEGOTIATION")
            end,
            resolve_battle = function(quest, battle)
                quest:DefFn("DeltaActions", -math.max(math.ceil(battle:GetTurns() / 4), 1), "BATTLE")
            end,
            caravan_move_location = function(quest, location)
                if location:HasTag("in_transit") then
                    quest:DefFn("DeltaActions", -1, "TRAVEL")
                end
            end,
        },
    }(child)

    self.DeltaActions = function(quest, delta, reason)
        quest.param.free_time_actions = quest.param.free_time_actions + delta
        print("New action count: "..quest.param.free_time_actions)
        if quest.param.free_time_actions <= 0 then
            quest:Complete(new_child.id)
        end
        quest:NotifyChanged()
        TheGame:GetGameState():LogNotification( NOTIFY.DEM_TIME_PASSED, quest, -delta, quest.param.free_time_actions, reason )
    end
    self.free_time_objective_id = new_child.id

    self:AddObjective(new_child)

    return self
end

function AutoUpgradeText(self, field, invert, preprocess)
    -- assert(self[field] ~= nil, "Empty field")
    if not preprocess then
        preprocess = function(x) return x end
    end
    if not self.base_def then
        return preprocess(self[field])
    end
    if not (type(self[field]) == "number" and type(self.base_def[field]) == "number") then
        if self[field] ~= self.base_def[field] then
            return string.format("<#UPGRADE>%s</>", preprocess(self[field]))
        else
            return preprocess(self[field])
        end
    end
    if self[field] ~= self.base_def[field] then
        if (self[field] < self.base_def[field]) ~= (invert and true or false) then
            return string.format("<#DOWNGRADE>%s</>", preprocess(self[field]))
        else
            return string.format("<#UPGRADE>%s</>", preprocess(self[field]))
        end
    else
        return preprocess(self[field])
    end
end
