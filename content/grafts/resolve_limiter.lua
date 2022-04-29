local fun = require "util/fun"
local negotiation_defs = require "negotiation/negotiation_defs"
local EVENT = negotiation_defs.EVENT

local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT

local GRAFTS =
{
    democracy_resolve_limiter =
    {
        hidden = true,
        desc = "Your max resolve in negotiation is limited by the proportion of health you have.",

        OnStartNegotiation = function( self, minigame )
            local core = minigame:GetPlayerNegotiator():FindCoreArgument()
            local health_proportion = TheGame:GetGameState():GetPlayerAgent().health:GetPercent()
            assert(core, "Core not found")
            if core then
                core.max_resolve = math.max(1, math.floor(core.max_resolve * health_proportion))
                core.resolve = math.min(core.resolve, core.max_resolve)
                core:ModifyResolve(0)
            end
        end,
    },
}


---------------------------------------------------------------------------------------------

for id, graft in pairs( GRAFTS ) do
    Content.AddStoryGraft( id, graft )
end
