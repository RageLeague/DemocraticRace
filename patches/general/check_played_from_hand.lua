local patch_id = "CHECK_PLAYED_FROM_HAND"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local MiniGame = Negotiation.MiniGame

local old_fn = MiniGame.PayCosts

function MiniGame:PayCosts(card, ...)
    if card.owner:IsPlayer() then
        card.paid_cost = true
    end
    old_fn(self, card, ...)
end

local old_play = MiniGame.PlayCard
function MiniGame:PlayCard(card, ...)
    if card.owner:IsPlayer() then
        card.played_from_hand = card.paid_cost or false
        card.paid_cost = nil
    end
    old_play(self, card, ...)
end