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
    if not self.minigame.delta_modifier_accumulator then
        self.minigame.delta_modifier_accumulator = CardEngine.ScalarAccumulator( self.minigame, EVENT.CALC_DELTA_MODIFIER )
    end
    local new_delta, details = self.minigame.delta_modifier_accumulator:CalculateValue( delta, self, modifier, card)
    return old_fn(self, modifier, new_delta, card)
end
