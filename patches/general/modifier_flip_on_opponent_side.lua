local patch_id = "MODIFIER_FLIP_ON_OTHER_SIDE"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local NegotiationArgument = Widget.NegotiationArgument
local old_fn = NegotiationArgument.CreateModifier

function NegotiationArgument:CreateModifier( ... )
    local res = old_fn(self, ...)
    self.art:SetFlip(self.modifier and self.modifier.flip_on_opponent_side and self.flipped)
    return res
end