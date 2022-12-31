local patch_id = "SECRET_INTEL_LOSE_EFFECT"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Content.GetNegotiationModifier("secret_intel").OnBounty

Content.GetNegotiationModifier("secret_intel").OnBounty = function(self, ...)
    local result = old_fn(self, ...)
    if self.negotiator:IsPlayer() then
        self.engine.secret_intel_destroyed = true
    end
end
