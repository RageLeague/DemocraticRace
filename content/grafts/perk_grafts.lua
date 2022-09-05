local negotiation_defs = require "negotiation/negotiation_defs"
local EVENT = negotiation_defs.EVENT

local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT

local PERKS =
{
    perk_vaccinated =
    {
        name = "Vaccinated",
        desc = "When you gain a new parasite card, immediately remove it without health penalty.",
        img = "DEMOCRATICRACE:assets/perks/perk_vaccinated.png",
        tier = 6,

        event_handlers =
        {
            [ "card_added" ] = function( self, card )
                if is_instance(card, Negotiation.Card) then
                    if CheckBits( card.flags, negotiation_defs.CARD_FLAGS.PARASITE ) then
                        card.userdata.removed_safely = true
                        self.owner.negotiator:RemoveCard(card)
                    end
                elseif is_instance(card, Battle.Card) then
                    if CheckBits( card.flags, battle_defs.CARD_FLAGS.PARASITE ) then
                        card.userdata.removed_safely = true
                        self.owner.battler:RemoveCard(card)
                    end
                end
            end,
        },
    }
}

local unlock_per_tier = { 1, 2, 3, 4, 5, math.huge }

for id, graft in pairs( PERKS ) do
    graft.hidden = true
    assert_warning( graft.tier ~= nil, "Missing perk tier: %s", id )
    graft.tier = graft.tier or 1
    graft.unlock_cost = graft.unlock_cost or unlock_per_tier[math.min(graft.tier, #unlock_per_tier)]
    Content.AddPerkGraft( id, graft )
end
