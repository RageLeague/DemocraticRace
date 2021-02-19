local patch_id = "CUSTOM_MODIFIER_PREPARE_TURN"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)
local old_fn = Negotiation.Modifier.PrepareTurn
function Negotiation.Modifier:PrepareTurn()
    old_fn(self)
    if self.OnPrepareTurn then
        self:OnPrepareTurn()
    end
end