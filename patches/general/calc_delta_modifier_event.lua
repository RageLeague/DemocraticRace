local patch_id = "CALC_DELTA_MODIFIER_EVENT"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Negotiation.Negotiator.DeltaModifier

function Negotiation.Negotiator:DeltaModifier( modifier, delta, card )
    old_fn(self, modifier, delta, card)
end
