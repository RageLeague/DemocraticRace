local patch_id = "RESTRICT_CAN_PLAY_CARD"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Negotiation.MiniGame.CanPlayCard

function Negotiation.MiniGame:CanPlayCard( card, target, ... )
    for i, modifier in self:GetPlayerNegotiator():Modifiers() do
        if modifier.CanPlayCardModifier then
            local ok, reason = modifier:CanPlayCardModifier(card, self, target)
            if not ok then
                return false, reason
            end
        end
    end
    for i, modifier in self:GetOpponentNegotiator():Modifiers() do
        if modifier.CanPlayCardModifier then
            local ok, reason = modifier:CanPlayCardModifier(card, self, target)
            if not ok then
                return false, reason
            end
        end
    end
    return old_fn(self, card, target, ...)
end