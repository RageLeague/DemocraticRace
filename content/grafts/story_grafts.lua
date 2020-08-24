local fun = require "util/fun"
local negotiation_defs = require "negotiation/negotiation_defs"
local EVENT = negotiation_defs.EVENT

local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT

------------------------------------------------------------------------------------------------

-- Determines the support level change when an agent's relationship changes.
-- The general support changes by this amount, while the faction and wealth support changes by double this amount.
local DELTA_SUPPORT = {
    [RELATIONSHIP.LOVED] = 8,
    [RELATIONSHIP.LIKED] = 3,
    [RELATIONSHIP.NEUTRAL] = 0,
    [RELATIONSHIP.DISLIKED] = -3,
    [RELATIONSHIP.HATED] = -8,
}
-- Determines the support level change when an agent is killed.
local DEATH_DELTA = -5

-- Determines the support level change when an agent is killed in an isolated scenario.
-- Still reduce support, but people won't know for sure it's you.
-- Still need to work on provoke kill, though.
local ISOLATED_DEATH_DELTA = -2

local GRAFTS =
{
    relation_support_tracker =
    {
        hidden = true,
        event_handlers =
        {
            [ "agent_relationship_changed" ] = function( self, agent, old_rel, new_rel )
                local support_delta = DELTA_SUPPORT[new_rel] - DELTA_SUPPORT[old_rel]
                if support_delta ~= 0 then
                    local ignore = true
                    TheGame:GetGameState():GetMainQuest():DefFn("DeltaGeneralSupport", support_delta, ignore)
                    TheGame:GetGameState():GetMainQuest():DefFn("DeltaFactionSupportAgent", support_delta * 2, agent, ignore)
                    TheGame:GetGameState():GetMainQuest():DefFn("DeltaWealthSupportAgent", support_delta * 2, agent, ignore)
                    TheGame:GetGameState():LogNotification( NOTIFY.DELTA_AGENT_SUPPORT, support_delta, agent ) 
                end
                -- if new_rel == RELATIONSHIP.LOVED and old_rel ~= RELATIONSHIP.LOVED then
                --     TheGame:GetGameState():GetCaravan():DeltaMaxResolve(1)
                -- end
            end,
            [ "resolve_battle" ] = function( self, battle, primary_enemy, repercussions )
                for i, fighter in battle:AllFighters() do
                    local agent = fighter.agent
                    if agent:IsSentient() and agent:IsDead() and fighter:GetKiller() and fighter:GetKiller():IsPlayer() then
                        local support_delta = CheckBits( battle:GetScenario():GetFlags(), BATTLE_FLAGS.ISOLATED ) and ISOLATED_DEATH_DELTA or DEATH_DELTA
                        local ignore = true
                        TheGame:GetGameState():GetMainQuest():DefFn("DeltaGeneralSupport", support_delta, ignore)
                        TheGame:GetGameState():GetMainQuest():DefFn("DeltaFactionSupportAgent", support_delta * 2, agent, ignore)
                        TheGame:GetGameState():GetMainQuest():DefFn("DeltaWealthSupportAgent", support_delta * 2, agent, ignore)
                        TheGame:GetGameState():LogNotification( NOTIFY.DELTA_AGENT_SUPPORT, support_delta, agent )
                    end
                end
            end,
        }
    },
}


---------------------------------------------------------------------------------------------

for id, graft in pairs( GRAFTS ) do
    Content.AddStoryGraft( id, graft )
end
