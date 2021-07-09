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
            if relationship == RELATIONSHIP.LIKED then
                t.SOCIALIZE = (t.SOCIALIZE or 1)
            end
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
local QDEF = QuestDef.Define{
    title = "Free Time Event",
    desc = "You have free time! Spend this time at your favorite location!",
    -- icon = engine.asset.Texture("icons/quests/oppo_battle_aftermath.tex"),
    icon = function(self, obj)

    end,
    qtype = QTYPE.STORY,--QTYPE.OPPORTUNITY,
    act_filter = DemocracyUtil.DemocracyActFilter,
    -- on_init = function(quest)
    --     quest.param.free_time_actions = DemocracyUtil.GetBaseFreeTimeActions()
    -- end,
    -- events =
    -- {
    --     resolve_negotiation = function(quest, minigame)
    --         for i, modifier in minigame:GetPlayerNegotiator():Modifiers() do
    --             if modifier.id == "NO_PLAY_FROM_HAND" then
    --                 return
    --             end
    --         end
    --         quest:DefFn("DeltaActions", -1)
    --     end,
    --     resolve_battle = function(quest, battle)
    --         quest:DefFn("DeltaActions", -2)
    --     end,
    --     caravan_move_location = function(quest, location)
    --         if location:HasTag("road") then
    --             quest:DefFn("DeltaActions", -1)
    --         end
    --     end,
    -- },
    -- DeltaActions = function(quest, delta)
    --     quest.param.free_time_actions = quest.param.free_time_actions + delta
    --     print("New action count: "..quest.param.free_time_actions)
    --     if quest.param.free_time_actions <= 0 then
    --         quest:Complete()
    --     end
    --     quest:NotifyChanged()
    -- end
}
-- :AddObjective{
--     id = "action_tracker",
--     title = "You have {1} {1*action|actions} left",
--     title_fn = function(quest, str)
--         return loc.format(str, quest.param.free_time_actions or 0)
--     end,
--     desc = "You can choose to visit a location during your free time.",

--     state = QSTATUS.ACTIVE,
--     mark = function(quest, t, in_location)
--         DemocracyUtil.AddUnlockedLocationMarks(t)
--     end,
--     -- terminal = true,
-- }
:AddFreeTimeObjective{
    id = "action_tracker",
    state = QSTATUS.ACTIVE,
    on_complete = function(quest)
        quest:Complete()
    end,
}
:AddCast{
    cast_id = "friend",
    when = QWHEN.MANUAL,
    no_validation = true,
}

local convo = QDEF:AddConvo()
    -- :Confront(function(cxt)
    --     if cxt.quest.param.free_time_actions <= 0 then
    --         cxt.quest:Complete()
    --     end
    -- end)
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
        if cxt.quest.param.free_time_actions ~= nil and who
            and who:GetRelationship() > RELATIONSHIP.NEUTRAL then

            local action_cost = 3
            -- print("lo yes!")
            cxt:Opt("OPT_SOCIALIZE", who)
                :PreIcon(global_images.like)
                :PostText("TT_SOCIALIZE")
                :IsHubOption( true )
                -- :ReqCondition(cxt.quest.param.free_time_actions >= action_cost, "REQ_MUST_HAVE_FREE_TIME")
                :ReqCondition(not who:HasMemoryFromToday("OFFERED_BOON"), "REQ_NOT_SOCIALIZED")
                :RequireFreeTimeAction(action_cost)
                :Fn(function(cxt)
                    -- cxt.quest:DefFn("DeltaActions", -action_cost)
                    cxt:GetAgent():Remember("OFFERED_BOON")
                    cxt:Dialog("DIALOG_SOCIALIZE")
                    -- Don't spawn request for oppositions, because there might be issues with them dying.
                    if who:GetRelationship() == RELATIONSHIP.LIKED and not DemocracyUtil.HasRequestQuest(who)
                        and not DemocracyUtil.GetOppositionData(who) and math.random() < 0.5 then

                        -- Try spawning a request quest
                        local request_quest = DemocracyUtil.SpawnRequestQuest(who)
                        if request_quest then
                            cxt.enc.scratch.request_quest = request_quest
                            cxt:GoTo("STATE_REQUEST")
                            return
                        end
                    end
                    local chosen_boon = PickBoonForAgent(who) or "SOCIALIZE"

                    if chosen_boon == "SOCIALIZE" and AgentUtil.HasPlotArmour(cxt:GetAgent()) then
                        -- we want to be able to socialize with plot armor characters, but we don't want them
                        -- to love us if we socialize.
                        chosen_boon = "SOCIALIZE_NO_LOVE"
                    end

                    if cxt.quest:GetCastMember("friend") then
                        cxt.quest:UnassignCastMember("friend")
                        -- for some reason unassign will not actually unassign if quests are completed
                        -- so we added this.
                        cxt.quest.cast.friend = nil
                    end
                    -- DBG(cxt.quest:GetCastMember("friend"))
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

        end

    end)
    :State("STATE_REQUEST")
        :Loc{
            DIALOG_REJECT = [[
                player:
                    [p] Yeah, sorry I couldn't help.
                    Glad you let me know, though.
            ]],
        }
        :Fn(function(cxt)
            cxt:PlayQuestConvo(cxt.enc.scratch.request_quest, QUEST_CONVO_HOOK.INTRO)
            DemocracyUtil.PresentRequestQuest(cxt, cxt.enc.scratch.request_quest, function(cxt,quest)
                cxt:PlayQuestConvo(quest, QUEST_CONVO_HOOK.ACCEPTED)
                StateGraphUtil.AddEndOption(cxt)
            end, function(cxt, quest)
                cxt:Dialog("DIALOG_REJECT")
                ConvoUtil.DoResolveDelta(cxt, 5)
                StateGraphUtil.AddEndOption(cxt)
            end)
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