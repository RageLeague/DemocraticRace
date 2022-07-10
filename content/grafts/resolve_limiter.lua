local fun = require "util/fun"
local negotiation_defs = require "negotiation/negotiation_defs"
local EVENT = negotiation_defs.EVENT

local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT

local GRAFTS =
{
    democracy_resolve_limiter =
    {
        -- hidden = true,
        name = "Agonizing Injury",
        desc = "Your max resolve in negotiation is limited by the proportion of health you have.",
        img = "DEMOCRATICRACE:assets/grafts/democracy_resolve_limiter.png",
        negotiation_modifier =
        {
            hidden = true,
            loc_strings =
            {
                DIALOG1 = [[
                    player:
                        !left
                        !wince
                        Ow! It hurts!
                ]],
                DIALOG2 = [[
                    player:
                        !left
                        !wince
                        Ah! The pain makes me unable to focus!
                ]],
                DIALOG3 = [[
                    player:
                        !left
                        !wince
                        This is not good!
                ]],
            },
            event_handlers =
            {
                [ EVENT.BEGIN_NEGOTIATION ] = function( self, minigame )
                    local core = self.negotiator:FindCoreArgument()
                    local health_proportion = TheGame:GetGameState():GetPlayerAgent().health:GetPercent()
                    assert(core, "Core not found")
                    if core and health_proportion < 1 then
                        self.engine:BroadcastEvent( EVENT.CUSTOM, self.OnQuipHurt, self )
                        core.max_resolve = math.max(1, math.floor(core.max_resolve * health_proportion))
                        core.resolve = math.min(core.resolve, core.max_resolve)
                        core:ModifyResolve(0)
                    end
                end,
            },

            OnQuipHurt = function( panel, self )
                local dialogid = table.arraypick{ "DIALOG1", "DIALOG2", "DIALOG3" }
                local txt = loc.format( self.def:GetLocalizedString( dialogid ), self.enemy )
                panel:Dialog( txt )
            end,
        },
    },
}


---------------------------------------------------------------------------------------------

for id, graft in pairs( GRAFTS ) do
    graft.is_bane = true
    Content.AddSocialGraft( id, graft )
    -- Content.AddStoryGraft( id, graft )
end
