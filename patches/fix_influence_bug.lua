local patch_id = "FIX_INFLUENCE_BUG"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT


local def = Content.GetNegotiationModifier("INFLUENCE").event_handlers
local old_fn = def[EVENT.CALC_PERSUASION]
def[EVENT.CALC_PERSUASION] = function( self, source, ... )
    if source and source.negotiator == self.negotiator then
        old_fn(self, source, ...)
    end
end