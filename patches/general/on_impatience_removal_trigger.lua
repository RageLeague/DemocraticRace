local patch_id = "ON_IMPATIENCE_REMOVAL_TRIGGER"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT

Content.GetNegotiationModifier("IMPATIENCE").OnSetStacks = function( self, old_stacks )
    local delta = self.stacks - math.max( 1, old_stacks )
    if delta < 0 then
        self.current_level = math.max(0, self.current_level + delta)
    end
end