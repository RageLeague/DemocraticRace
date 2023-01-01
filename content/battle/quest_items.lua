local battle_defs = require "battle/battle_defs"
local CARD_FLAGS = battle_defs.CARD_FLAGS
local BATTLE_EVENT = battle_defs.EVENT

local attacks =
{
    -- See https://forums.kleientertainment.com/forums/topic/81405-mushroom-farming-or-farmer-characters-in-the-future/
    dole_loaves =
    {
        name = "Dole Loaves",
        anim = "taunt",
        flavour = "Made from 'high quality' spollop, these are definitely some of the food ever.",
        desc = "{HEAL {1}}.",
        icon = "DEMOCRATICRACE:assets/cards/dole_loaves.png",
        anims = { "anim/grog_beer_glass2.zip"},
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.heal_amount )
        end,

        cost = 1,
        target_type = TARGET_TYPE.FRIENDLY_OR_SELF,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.SKILL | CARD_FLAGS.REPLENISH,
        rarity = CARD_RARITY.UNIQUE,

        max_charges = 4,
        heal_amount = 4,

        OnPostResolve = function( self, battle, attack )
            self.target:HealHealth( self.heal_amount, self )
        end,
    },
    dole_loaves_plus =
    {
        name = "Improved Dole Loaves",
        flavour = "Compared to regular dole loaves, these ones have some garlic butter on top.",
        desc = "{HEAL {1}}. If the target is the player, also restore {2} resolve.",
        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.heal_amount, self.resolve_amount )
        end,

        resolve_amount = 2,

        OnPostResolve = function( self, battle, attack )
            self.target:HealHealth( self.heal_amount, self )
            if self.target.agent and self.target.agent:IsPlayer() then
                TheGame:GetGameState():GetCaravan():DeltaResolve( self.resolve_amount )
            end
        end,
    },
}

for i, id, data in sorted_pairs(attacks) do
    data.series = "GENERAL"
    data.item_tags = (data.item_tags or 0) | ITEM_TAGS.COMBAT
    assert( data.flags == nil or CheckBits( data.flags, CARD_FLAGS.ITEM))
    Content.AddBattleCard( id, data )
end
