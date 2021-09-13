local patch_id = "CALC_DELTA_MODIFIER_EVENT"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local negotiation_defs = require "negotiation/negotiation_defs"
local EVENT = ExtendEnum(negotiation_defs.EVENT, {
    "CALC_DELTA_MODIFIER",
})

local old_fn = Negotiation.Negotiator.DeltaModifier

function Negotiation.Negotiator:DeltaModifier( modifier, delta, card )
    if not self.engine.delta_modifier_accumulator then
        self.engine.delta_modifier_accumulator = CardEngine.ScalarAccumulator( self.engine, EVENT.CALC_DELTA_MODIFIER )
    end
    local new_delta, details = self.engine.delta_modifier_accumulator:CalculateValue( delta, self, modifier, card)
    return old_fn(self, modifier, new_delta, card)
end
