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
local function PickLocationUnlockForAgent(agent, unlock_type)
    if not TheGame:GetGameState():GetMainQuest().param.unlocked_locations then
        return
    end
    local all_locations = unlocks.GetLocationUnlockForAgent(agent, unlock_type)
    local location = weightedpick(all_locations)
    return location
    -- comment this part out because we want to test whether having duplicate unlock works or not.
    -- while #all_locations > 0 do
    --     local location = weightedpick(all_locations)
        
    --     if table.arraycontains(TheGame:GetGameState():GetMainQuest().param.unlocked_locations, location) then
    --         all_locations[location] = nil
    --     else
    --         return location
    --     end
    -- end
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
        -- for i, id in ipairs(TheGame:GetGameState():GetMainQuest().param.unlocked_locations) do
        --     table.insert(t, TheGame:GetGameState():GetLocation(id))
        -- end
        DemocracyUtil.AddUnlockedLocationMarks(t)
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

        OPT_ASK_ABOUT_LOCATION = "Ask for a place to visit...",

        OPT_BAR = "Ask for a restaurant or bar",
        DIALOG_BAR = [[
            player:
                You know a good bar I can visit? Or a restaurant?
        ]],
        OPT_SHOP = "Ask for a shop",
        DIALOG_SHOP = [[
            player:
                You know a good shop I can visit?
        ]],
        OPT_ENTERTAINMENT = "Ask for a place of entertainment",
        DIALOG_ENTERTAINMENT = [[
            player:
                You know a fun place to visit?
        ]],
        OPT_WORK = "Ask for a workplace",
        DIALOG_WORK = [[
            player:
                You know any workplaces?
        ]],
        OPT_OFFICE = "Ask for an office",
        DIALOG_OFFICE = [[
            player:
                You know any offices?
        ]],
        OPT_ANY = "Ask for any location",
        DIALOG_ANY = [[
            player:
                You know any good place I can visit?
        ]],

        DIALOG_ALREADY_UNLOCKED = [[
            agent:
                Have you heard of {loc_to_unlock#location}?
            player:
                Unfortunately, I have.
            agent:
                Oh. I see.
            player:
                Well, thanks anyway.
        ]],

        DIALOG_NO_MORE_LEFT = [[
            agent:
                Unfortunately, I know nothing of the sort.
                I'm sorry.
            player:
                Well, thanks anyway.
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
                :ReqCondition(not who:HasMemoryFromToday("OFFERED_BOON"), "REQ_NOT_SOCIALIZED")
                :RequireFreeTimeAction(action_cost)
                :Fn(function(cxt)
                    -- cxt.quest:DefFn("DeltaActions", -action_cost)
                    cxt:GetAgent():Remember("OFFERED_BOON")
                    cxt:Dialog("DIALOG_SOCIALIZE")
                    local chosen_boon = PickBoonForAgent(who) or "SOCIALIZE"
                    
                    if chosen_boon == "SOCIALIZE" and AgentUtil.HasPlotArmour(cxt:GetAgent()) then
                        -- we want to be able to socialize with plot armor characters, but we don't want them
                        -- to love us if we socialize.
                        chosen_boon = "SOCIALIZE_NO_LOVE"
                    end

                    if cxt.quest:GetCastMember("friend") then
                        cxt.quest:UnassignCastMember("friend")
                    end
                    cxt.quest:AssignCastMember("friend", who)
                    
                    local service = BOON_SERVICES[chosen_boon]
                    if service.on_init then
                        service.on_init(cxt.quest)
                    end
                    cxt:GoTo(chosen_boon)
                        
                    -- end
                    -- doboon(cxt, chosen_boon)
                    -- if unlock_location then
                    --     if math.random() < 0.9 then
                    --         cxt.quest.param.loc_to_unlock = unlock_location
                    --         cxt:GoTo("STATE_UNLOCK_LOCATION")
                    --     else
                    --         doboon(cxt, chosen_boon)
                    --     end
                    -- else
                    --     print("no more locations to unlock!")
                    --     doboon(cxt, chosen_boon)
                    -- end
                    
                end)
            cxt:Opt("OPT_ASK_ABOUT_LOCATION")
                :ReqCondition(not who:HasMemoryFromToday("OFFERED_BOON"), "REQ_NOT_SOCIALIZED")
                :LoopingFn(function(cxt)
                    local function AddLocationOption(opt_id, unlock_type, preicon)
                        if who:HasMemory("ASKED_OPT_" .. opt_id) then
                            return
                        end
                        local opt = cxt:Opt("OPT_"..opt_id)
                            :RequireFreeTimeAction(2)
                            :Dialog("DIALOG_"..opt_id)
                        if preicon then
                            opt:PreIcon(preicon)
                        end
                        opt:Fn(function(cxt)
                            who:Remember("ASKED_OPT_" .. opt_id)
                            cxt.quest.param.loc_to_unlock = PickLocationUnlockForAgent(who, unlock_type)
                            
                            if cxt.quest.param.loc_to_unlock then
                                if DemocracyUtil.LocationUnlocked(cxt.quest.param.loc_to_unlock) then
                                    cxt:Dialog("DIALOG_ALREADY_UNLOCKED")
                                else
                                    cxt:GetAgent():Remember("OFFERED_BOON")
                                    local unlock_location = TheGame:GetGameState():GetLocation(cxt.quest.param.loc_to_unlock)
                                    local location_tags = unlock_location:FillOutQuipTags()
                                    location_tags = table.map(location_tags, function(str) return "unlock_" .. str end)
                                    -- TheGame:GetDebug():CreatePanel(DebugTable(location_tags))

                                    cxt.quest.param.prop = unlock_location:GetProprietor()

                                    cxt:Quip(cxt:GetAgent(), "unlock_location", cxt.player:GetContentID(), table.unpack(location_tags))
                                    DemocracyUtil.DoLocationUnlock(cxt, cxt.quest.param.loc_to_unlock)
                                    -- cxt:Opt("OPT_NEW_LOCATION",TheGame:GetGameState():GetLocation(cxt.quest.param.loc_to_unlock))
                                    --     :Fn(function(cxt)
                                    --         table.insert(TheGame:GetGameState():GetMainQuest().param.unlocked_locations, cxt.quest.param.loc_to_unlock)
                                    --     end)
                                    StateGraphUtil.AddEndOption(cxt)
                                end
                            else
                                cxt:Dialog("DIALOG_NO_MORE_LEFT")
                            end
                        end)
                    end
                    local TYPE = unlocks.UNLOCK_TYPE
                    AddLocationOption("BAR", TYPE.BAR)
                    AddLocationOption("SHOP", TYPE.SHOP)
                    AddLocationOption("ENTERTAINMENT", TYPE.ENTERTAINMENT)
                    AddLocationOption("WORK", TYPE.WORK)
                    AddLocationOption("OFFICE", TYPE.OFFICE)
                    AddLocationOption("ANY", nil)
                    StateGraphUtil.AddBackButton(cxt)
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
-- convo:State("STATE_UNLOCK_LOCATION")
--     :Loc{
--         -- OPT_NEW_LOCATION = "Unlock new location: {1#location}",
--         -- TT_NEW_LOCATION = "You can now visit this location during your free time.",
--     }
--     :Fn(function(cxt)
        
--     end)