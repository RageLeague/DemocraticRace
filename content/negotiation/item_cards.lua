local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT
local RESULT = negotiation_defs.RESULT

local CARDS = {
    -- A hatch card for an event
    curious_curio =
    {
        name = "Curious Curio",
        flavour = "'I have no idea what it does, but it looks cool.'",
        desc = "Draw a card.",

        cost = 1,
        max_xp = 6,
        hatch = true,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.EXPEND | CARD_FLAGS.HATCH,

        rarity = CARD_RARITY.UNIQUE,

        available_hatch = {"royal_relic", "mesmerizing_charm", "intimidating_blaster"},

        is_artifact = true,

        hatch_fn = function( self, minigame )
            self:TransferCard( minigame.trash_deck )

            local chosen_id = table.arraypick(self.available_hatch)
            local card = self.owner.negotiator:LearnCard( chosen_id )
            if self.userdata.linked_quest then
                card.userdata.linked_quest = self.userdata.linked_quest
                self.userdata.linked_quest.artifact_card = card
            end
            minigame:DealCard( card, minigame:GetHandDeck( ) )

            self:Consume()
        end,

        OnPostResolve = function( self, minigame )
            minigame:DrawCards( 1 )
        end,
    },
    royal_relic =
    {
        name = "Royal Relic",
        flavour = "'This relic used to belong to kradeshi monarchs of old to symbolize their power. It doesn't really do much else.'",
        desc = "Gain {1} {RENOWN}.\nDraw a card.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.renown_stacks)
        end,

        cost = 1,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNIQUE,

        is_artifact = true,

        renown_stacks = 5,

        OnPostResolve = function( self, minigame )
            self.negotiator:AddModifier("RENOWN", self.renown_stacks, self)
            minigame:DrawCards( 1 )
        end,
    },
    mesmerizing_charm =
    {
        name = "Mesmerizing Charm",
        flavour = "'Wow this charm is really mesmerizing!'",
        desc = "Force all enemy intents and arguments to target it.\nIncept 1 {FLUSTERED} and draw a card.",

        cost = 1,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNIQUE,
        target_self = TARGET_ANY_RESOLVE,

        is_artifact = true,

        OnPostResolve = function( self, minigame, targets )
            for i,intent in ipairs(minigame:GetOtherNegotiator(self.negotiator):GetIntents()) do
                if intent.target then
                    intent.target = targets[1]
                end
            end
            for i,argument in minigame:GetOtherNegotiator(self.negotiator):Modifiers() do
                if argument.target then
                    argument.target = targets[1]
                end
            end

            self.anti_negotiator:InceptModifier("FLUSTERED", 1, self)

            minigame:DrawCards( 1 )
        end
    },
    intimidating_blaster =
    {
        name = "Intimidating Blaster",
        flavour = "'I have no idea how to use this, but I can test it on you if you'd like.'",
        desc = "Gain {1} {intimidated}.\nDraw a card.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.intimidated_stack)
        end,

        cost = 1,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNIQUE,

        is_artifact = true,
        practical = true,

        intimidated_stack = 3,

        OnPostResolve = function( self, minigame )
            self.anti_negotiator:AddModifier("intimidated", self.intimidated_stack, self )
            minigame:DrawCards( 1 )
        end,
    },
}
for i, id, def in sorted_pairs( CARDS ) do
    def.item_tags = (def.item_tags or 0) | ITEM_TAGS.NEGOTIATION
    def.flags = (def.flags or 0) | CARD_FLAGS.ITEM
    def.rarity = def.rarity or CARD_RARITY.UNIQUE
    def.series = def.series or CARD_SERIES.GENERAL

    Content.AddNegotiationCard( id, def )
end