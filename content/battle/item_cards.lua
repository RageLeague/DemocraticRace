local battle_defs = require "battle/battle_defs"
local CARD_FLAGS = battle_defs.CARD_FLAGS
local BATTLE_EVENT = battle_defs.EVENT

local attacks =
{

}

for i, id, data in sorted_pairs(attacks) do
    data.series = CARD_SERIES.GENERAL
    data.item_tags = (data.item_tags or 0) | ITEM_TAGS.COMBAT
    data.flags = (data.flags or 0) | CARD_FLAGS.ITEM
    Content.AddBattleCard( id, data )
end
