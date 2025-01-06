local patch_id = "FIX_ATTACK_RESOLVE"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Negotiation.Modifier.AttackResolve

function Negotiation.Modifier:AttackResolve(delta, source, param, ...)
    return old_fn(self, delta, source, param or {}, ...)
end
