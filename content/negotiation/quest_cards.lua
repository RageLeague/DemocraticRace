local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT

local CARDS = {
    assassin_fight_call_for_help = 
    {
        name = "Call For Help",
        desc = "Attempt to call for help and ask someone to deal with the assassin.",
        cost = 1,
        -- min_persuasion = 1,
        -- max_persuasion = 3,
        flags = CARD_FLAGS.DIPLOMACY | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNIQUE,
        init_help_count = 1,

        OnPostResolve = function( self, minigame, targets )
            self.negotiator:AddModifier("CONNECTED_LINE", self.init_help_count)
        end,
        deck_handlers = ALL_DECKS,
        event_handlers =
        {
            [ EVENT.CARD_MOVED ] = function( self, card, source_deck, source_idx, target_deck, target_idx )
                if card == self and target_deck and target_deck:GetDeckType() == DECK_TYPE.TRASH 
                    and self.negotiator:GetModifierStacks( "CONNECTED_LINE" ) <= 0 then
                    self.show_dealt = true
                    self:TransferCard(self.engine.hand_deck)
                end
            end,
        },
    },
    assassin_fight_describe_information = 
    {
        name = "Describe Situation",
        desc = "Discribe your current situation to the dispacher.\nIncrease the stacks of <b>Connected Line</> by 1.",
        cost = 1,
        -- min_persuasion = 1,
        -- max_persuasion = 3,
        flags = CARD_FLAGS.DIPLOMACY | CARD_FLAGS.STICKY,
        rarity = CARD_RARITY.UNIQUE,
        deck_handlers = ALL_DECKS,

        OnPostResolve = function( self, minigame, targets )
            if self.negotiator:GetModifierStacks( "CONNECTED_LINE" ) > 0 then
                self.negotiator:AddModifier("CONNECTED_LINE", 1)
            else
                minigame:ExpendCard(self)
            end
        end,
        event_handlers =
        {
            [ EVENT.CARD_MOVED ] = function( self, card, source_deck, source_idx, target_deck, target_idx )
                if card == self and target_deck and target_deck:GetDeckType() ~= DECK_TYPE.IN_HAND then
                    self.show_dealt = true
                    if self.negotiator:GetModifierStacks( "CONNECTED_LINE" ) > 0 then
                        local has_card = false
                        for k,v in pairs(self.engine:GetHandDeck().cards) do
                            if v.id == self.id and v ~= self then
                                has_card = true
                            end
                        end
                        if not has_card then
                            self:TransferCard(self.engine.hand_deck)
                        else
                            self:TransferCard(self.engine.trash_deck)
                        end
                    else
                        self:TransferCard(self.engine.trash_deck)
                    end
                end
            end,
        },
    },
    address_question = 
    {
        name = "Address Question",
        desc = "Target a question argument. Resolve the effect based on the question being addressed. "..
            "Remove the argument afterwards.\nIf this card leaves the hand, {EXPEND} it.",
        cost = 2,
        flags = CARD_FLAGS.DIPLOMACY,
        rarity = CARD_RARITY.UNIQUE,
        deck_handlers = ALL_DECKS,
        event_handlers =
        {
            [ EVENT.CARD_MOVED ] = function( self, card, source_deck, source_idx, target_deck, target_idx )
                if card == self and target_deck and target_deck:GetDeckType() ~= DECK_TYPE.IN_HAND then
                    self:TransferCard(self.engine.trash_deck)
                end
            end,
        },
    },
}
for id, def in pairs( CARDS ) do
    if not def.series then
        def.series = CARD_SERIES.GENERAL
    end
    Content.AddNegotiationCard( id, def )
end