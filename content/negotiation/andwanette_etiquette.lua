local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT

local TRIGGER_BASE =
{
    hidden = true,
    alt_desc = "something bad happens",
}
local TRIGGERS =
{
    ETIQUETTE_TRIGGER_CARDS =
    {
        desc = "Whenever you play {1} {1*card|cards} this turn, {2}. Reset count when triggered.",
    },
    ETIQUETTE_TRIGGER_MATCHING =
    {
        desc = "Whenever you play {1} {1*card|cards} of the same type in a row, {2}.",
    },
    ETIQUETTE_TRIGGER_DESTROY_ARGUMENT =
    {
        desc = "Whenever you destroy one of {1}'s arguments, {2}.",
    },
    ETIQUETTE_TRIGGER_COMPOSURE_TARGET =
    {
        desc = "Whenever you use a card to attack an argument with at least {1} {COMPOSURE}, {2}.",
    },
    ETIQUETTE_TRIGGER_CARD_DRAW =
    {
        desc = "Whenever you draw {1} or more cards this turn, {2}. Reset count when triggered.",
    },
    ETIQUETTE_TRIGGER_CARD_LEFT =
    {
        desc = "At the end of your turn, for every {1*card|{1} cards} left in your hand, {2}.",
    },
}
for id, def in pairs( TRIGGERS ) do
    Content.AddNegotiationModifier( id, table.extend(TRIGGER_BASE)(def) )
end

local EFFECT_BASE =
{
    hidden = true,
}
local EFFECTS =
{
    ETIQUETTE_EFFECT_BONUS_DAMAGE =
    {
        desc = "{1}'s attacks deal {2} bonus damage",
    },
    ETIQUETTE_EFFECT_FLAT_DAMAGE =
    {
        desc = "<b>Etiquette</> deal {2} damage to a random opponent argument",
    },
    ETIQUETTE_EFFECT_DISCARD =
    {
        desc = "discard {1*a card|{1} cards}",
    },
    ETIQUETTE_EFFECT_DESTROY_ARGUMENT =
    {
        desc = "destroy one of your non-core arguments",
    },
    ETIQUETTE_EFFECT_FLUSTER =
    {
        desc = "{INCEPT} {1} {FLUSTERED}",
    },
}
for id, def in pairs( EFFECTS ) do
    Content.AddNegotiationModifier( id, table.extend(EFFECT_BASE)(def) )
end

Content.AddNegotiationModifier("ETIQUETTE", {
    name = "Etiquette",
    desc = "At the beginning of your turn, the rule text for <b>Etiquette</> changes.",

    modifier_type = MODIFIER_TYPE.CORE,
})
