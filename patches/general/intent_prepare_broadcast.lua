local patch_id = "INTENT_PREPARE_BROADCAST"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local negotiation_defs = require "negotiation/negotiation_defs"
local EVENT = ExtendEnum(negotiation_defs.EVENT, {
    "PREPARE_INTENTS",
})

local old_fn = NegotiationBehaviour.RunBehaviour

function NegotiationBehaviour:RunBehaviour(...)
    local result = old_fn(self, ...)

    if not result then
        return result
    end

    self.engine:BroadcastEvent( EVENT.PREPARE_INTENTS, self, result )

    return result
end
