local unlocks = require "DEMOCRATICRACE:content/get_location_unlock"

local function PickBoonForAgent( agent )
    --[[    do 
            local service_id = "SPECIAL_NOODLES"
            local service = BOON_SERVICES[ service_id ]
            if service and (service.can_offer == nil or service.can_offer( agent )) then
                return service_id
            end
            return
        end
    --]]
    local relationship = agent:GetRelationship()
    local services = agent.social_boons or table.empty
    for i = relationship, RELATIONSHIP.HATED, -1 do
        if services[ i ] then
            local t = shallowcopy( services[ i ] )
            while next(t) ~= nil do
                local service_id = weightedpick( t )
                local service = BOON_SERVICES[ service_id ]
                if service and (service.can_offer == nil or service.can_offer( agent )) then
                    return service_id
                else
                    t[ service_id ] = nil -- Junk this one.
                end
            end
        end
    end
end
local function PickLocationUnlockForAgent(agent)
    local all_locations = unlocks.GetLocationUnlockForAgent(agent)
    while #all_locations > 0 do
        local location = table.arraypick(all_locations)
        if not TheGame:GetGameState():GetMainQuest().param.unlocked_locations then
            return
        end
        if table.arraycontains(TheGame:GetGameState():GetMainQuest().param.unlocked_locations, location) then
            table.arrayremove(all_locations, location)
        else
            return location
        end
    end
end
local QDEF = QuestDef.Define{
    title = "Free Time Event",
    desc = "You have free time! Spend this time at your favorite location!",
    -- icon = engine.asset.Texture("icons/quests/oppo_battle_aftermath.tex"),
    icon = function(self, obj)
    
    end,
    qtype = QTYPE.STORY,--QTYPE.OPPORTUNITY,
    act_filter = DemocracyUtil.DemocracyActFilter,
    on_init = function(quest)
        quest.param.free_time_actions = 8
    end,
    events = 
    {
        resolve_negotiation = function(quest, minigame)
            quest:DefFn("DeltaActions", -2)
        end,
        resolve_battle = function(quest, battle)
            quest:DefFn("DeltaActions", -2)
        end,
        caravan_move_location = function(quest, location)
            if location:HasTag("road") then
                quest:DefFn("DeltaActions", -1)
            end
        end,
    },
    DeltaActions = function(quest, delta)
        quest.param.free_time_actions = quest.param.free_time_actions + delta
        print("New action count: "..quest.param.free_time_actions)
        if quest.param.free_time_actions <= 0 then
            quest:Complete()
        end
        quest:NotifyChanged()
    end
}
:AddObjective{
    id = "action_tracker",
    title = "You have {1} {1*action|actions} left",
    title_fn = function(quest, str)
        return loc.format(str, quest.param.free_time_actions or 0)
    end,
    desc = "You can choose to visit a location during your free time.",

    state = QSTATUS.ACTIVE,
    mark = function(quest, t, in_location)
        print("free time mark evaluated")
        for i, id in ipairs(TheGame:GetGameState():GetMainQuest().param.unlocked_locations) do
            table.insert(t, TheGame:GetGameState():GetLocation(id))
        end
    end,
    -- terminal = true,
}
:AddCast{
    cast_id = "friend",
    when = QWHEN.MANUAL,
    no_validation = true,
}

local convo = QDEF:AddConvo()
    :Loc{
        OPT_SOCIALIZE = "Socialize with {1#agent}",
        TT_SOCIALIZE = "Socializing with a friend requires you to spend free time, but will grant the player random benefits or unlock a new location.",
        -- REQ_MUST_HAVE_FREE_TIME = "You are too busy to socialize.",
        REQ_NOT_SOCIALIZED = "You can only socialize with a person once per day.",
        DIALOG_SOCIALIZE = [[
            * You spent some with {agent}.
        ]],
    }
    :Hub(function(cxt, who)
        if cxt.quest.param.free_time_actions ~= nil  and who
            and who:GetRelationship() > RELATIONSHIP.NEUTRAL then
            
            local action_cost = 3
            -- print("lo yes!")
            cxt:Opt("OPT_SOCIALIZE", who)
                :PostText("TT_SOCIALIZE")
                :IsHubOption( true )
                -- :ReqCondition(cxt.quest.param.free_time_actions >= action_cost, "REQ_MUST_HAVE_FREE_TIME")
                :ReqCondition(not who:HasMemory("OFFERED_BOON", GameState:GetDayPhase() == DAY_PHASE.DAY and 1 or 2), "REQ_NOT_SOCIALIZED")
                :RequireFreeTimeAction(action_cost)
                :Fn(function(cxt)
                    -- cxt.quest:DefFn("DeltaActions", -action_cost)
                    cxt:GetAgent():Remember("OFFERED_BOON")
                    cxt:Dialog("DIALOG_SOCIALIZE")
                    local chosen_boon = PickBoonForAgent(who) or "SOCIALIZE"
                    local unlock_location = PickLocationUnlockForAgent(who)
                    local doboon = function(cxt, boon)
                        if cxt.quest:GetCastMember("friend") then
                            cxt.quest:UnassignCastMember("friend")
                        end
                        cxt.quest:AssignCastMember("friend", who)
                        
                        local service = BOON_SERVICES[boon]
                        if service.on_init then
                            service.on_init(cxt.quest)
                        end
                        cxt:GoTo(boon)
                        
                    end
                    if unlock_location then
                        if math.random() < 0.9 then
                            cxt.quest.param.loc_to_unlock = unlock_location
                            cxt:GoTo("STATE_UNLOCK_LOCATION")
                        else
                            doboon(cxt, chosen_boon)
                        end
                    else
                        print("no more locations to unlock!")
                        doboon(cxt, chosen_boon)
                    end
                    
                end)
        end

    end)
for k,v in pairs(BOON_SERVICES) do
    assert(v.fn)
    local state = convo:State(k):Fn(v.fn)
    if v.txt then
        state:Loc(v.txt)
    end
end
convo:State("STATE_UNLOCK_LOCATION")
    :Loc{
        -- OPT_NEW_LOCATION = "Unlock new location: {1#location}",
        -- TT_NEW_LOCATION = "You can now visit this location during your free time.",
    }
    :Fn(function(cxt)
        local unlock_location = TheGame:GetGameState():GetLocation(cxt.quest.param.loc_to_unlock)
        local location_tags = unlock_location:FillOutQuipTags()
        location_tags = table.map(location_tags, function(str) return "unlock_" .. str end)
        TheGame:GetDebug():CreatePanel(DebugTable(location_tags))
        cxt:Quip(cxt:GetAgent(), "unlock_location", cxt.player:GetContentID(), table.unpack(location_tags))
        DemocracyUtil.DoLocationUnlock(cxt, cxt.quest.param.loc_to_unlock)
        -- cxt:Opt("OPT_NEW_LOCATION",TheGame:GetGameState():GetLocation(cxt.quest.param.loc_to_unlock))
        --     :Fn(function(cxt)
        --         table.insert(TheGame:GetGameState():GetMainQuest().param.unlocked_locations, cxt.quest.param.loc_to_unlock)
        --     end)
    end)