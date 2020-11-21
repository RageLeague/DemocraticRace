local DemocracyUtil = class("DemocracyUtil")


-- if access an invalid val, look for the main quest and return a val if you can
getmetatable(DemocracyUtil).__index = function(self, k)
    if TheGame:GetGameState() and TheGame:GetGameState():GetMainQuest() then
        local quest = TheGame:GetGameState():GetMainQuest():GetQuestDef()
        print(quest)
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
function DemocracyUtil.EndFreeTime()
    -- TheGame:GetGameState():ClearOpportunities()
    local events = TheGame:GetGameState():GetActiveQuestWithContentID( "FREE_TIME_EVENT" )
    for i, event in ipairs(events) do
        print("End quest: " .. tostring(event))
        event:Complete()
    end
end
function DemocracyUtil.IsFreeTimeActive()
    return #(TheGame:GetGameState():GetActiveQuestWithContentID( "FREE_TIME_EVENT" )) > 0
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
        + SUPPORT_DELTA[agent:GetRelationship()] + (math.random() * 30) -15
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
end

function DemocracyUtil.CanVote(agent)
    -- non-citizens can't vote
    -- for casting purposes, player can't vote.
    return agent and not agent:IsPlayer() and not agent:IsRetired() 
        and agent:IsSentient() and agent:GetFactionID() ~= "RENTORIAN"
end

-- Do the convo for unlocking a location.
function DemocracyUtil.DoLocationUnlock(cxt, id)
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
    if is_instance(renown, Agent) then
        renown = renown:GetRenown() + (renown:HasTag("wealthy") and 1 or 0)
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
            local opt = cxt:RawOpt(string.capitalize_sentence(loc.format("{1#one_demand}", demand_data)), demand_data.id)
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
function ConvoOption:RequireFreeTimeAction(actions)
    if actions then
        self:PostText("TT_FREE_TIME_ACTION_COST", actions)
    end
    local freetimeevents = TheGame:GetGameState():GetActiveQuestWithContentID( "FREE_TIME_EVENT" )
    -- local q = freetimeevents[1]
    self:ReqCondition(freetimeevents and #freetimeevents > 0, "REQ_FREE_TIME")
    if freetimeevents and #freetimeevents > 0 and actions then
        local q = freetimeevents[1]
        self:ReqCondition(q.param.free_time_actions >= actions, "REQ_FREE_TIME_ACTIONS")
        self:Fn(function(cxt)
            q:DefFn("DeltaActions", -actions)
        end)
    end

    return self
end
-- return {
--     ADVISOR_IDS = ADVISOR_IDS,
--     ADVISOR_HOME = ADVISOR_HOME,
--     AddAdvisors = AddAdvisors,
--     AddHomeCasts = AddHomeCasts,
--     AddPrimaryAdvisor = AddPrimaryAdvisor,
--     StartFreeTime = StartFreeTime,
--     EndFreeTime = EndFreeTime,
--     IsFreeTimeActive = IsFreeTimeActive,
--     SupportScore = SupportScore,
--     OppositionScore = OppositionScore,
--     RandomBystanderCondition = RandomBystanderCondition,
--     CanVote = CanVote,
--     DoLocationUnlock = DoLocationUnlock,
--     GetWealth = GetWealth,
--     GetWealthString = GetWealthString,
--     GetWealthIcon = GetWealthIcon,
--     AddOppositionCast = AddOppositionCast,
--     GetWealthColor = GetWealthColor,
--     TryMainQuestFn = TryMainQuestFn,
--     DebugSupportScreen = DebugSupportScreen,
--     AddDebugBypass = AddDebugBypass,
--     AddAutofail = AddAutofail,
--     DetermineSupportTarget = DetermineSupportTarget,
--     ToFactionID = ToFactionID,
--     IsDemocracyCampaign = IsDemocracyCampaign,
--     DemocracyActFilter= DemocracyActFilter,
--     PresentRequestQuest = PresentRequestQuest,
--     CollectIssueImportance = CollectIssueImportance,
--     CheckHeavyHanded = CheckHeavyHanded,
--     AddDemandConvo = AddDemandConvo,

--     -- Demand generator stuff
--     demand_generator = demand_generator,
--     AddDemandModifier = demand_generator.AddDemandModifier,
--     GenerateDemands = demand_generator.GenerateDemands,
--     ParseDemandList = demand_generator.ParseDemandList,
-- }