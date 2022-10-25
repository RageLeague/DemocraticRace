local battle_defs = require "battle/battle_defs"
local CARD_FLAGS = battle_defs.CARD_FLAGS
local BATTLE_EVENT = battle_defs.EVENT

local attacks =
{
    dem_parasite_extraction =
    {
        name = "Parasite Extraction",
        desc = "If the target is at {1#percent} health or less, remove 1 {DISEASED} from the target when this card does unmitigated damage.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.health_threshold)
        end,
        anim = "melee_item",
        anims = { "anim/weapon_melee_knife_seemli.zip"},

        cost = 1,

        rarity = CARD_RARITY.UNIQUE,
        flags = CARD_FLAGS.MELEE | CARD_FLAGS.REPLENISH,

        min_damage = 2,
        max_damage = 4,

        health_threshold = 0.8,

        PreReq = function( self, battle, target )
            return target and target:GetHealthPercent() <= self.health_threshold
        end,

        OnPreResolve = function( self, battle, attack )
            self.valid_targets = {}
            for i, hit in attack:Hits() do
                if self:PreReq(battle, hit.target) then
                    table.insert_unique(self.valid_targets, hit.target)
                end
            end
        end,
        OnPostResolve = function( self, battle, attack )
            for i, hit in attack:Hits() do
                if hit.damage_dealt and hit.damage_dealt > 0 and table.arraycontains(self.valid_targets, hit.target) then
                    hit.target:RemoveCondition( "DISEASED", 1, self )
                end
            end
            self.valid_targets = nil
        end,
    },
}

for i, id, data in sorted_pairs(attacks) do
    data.series = "GENERAL"
    Content.AddBattleCard( id, data )
end
