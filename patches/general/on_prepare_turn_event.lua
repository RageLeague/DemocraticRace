local patch_id = "ON_PREPARE_TURN_EVENT"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = ExtendEnum(negotiation_defs.EVENT, {
    "ON_PREPARE_TURN",
})

local old_fn = Negotiation.Negotiator.PrepareTurn

function Negotiation.Negotiator:PrepareTurn(...)
    local res = old_fn(self, ...)
    self.engine:BroadcastEvent( EVENT.ON_PREPARE_TURN, self )
    return res
end
