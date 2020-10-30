local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT

local BASE_HANDLERS = {

}

local FEATURES = {
    PROP_PO_MEDIOCRE = 
    {
        name = "Mediocre",
        desc = "This argument has no special effects.",
    },
    PROP_PO_MESSY =
    {
        name = "Messy",
        desc = "This argument takes 1 extra damage from any source.",
    },
    PROP_PO_INSPIRING =
    {
        name = "Inspiring",
        desc = "This argument plays 1 more card at the beginning of each turn.",
    },
}
for id, data in pairs(FEATURES) do
	local def = NegotiationFeatureDef(id, data)
	Content.AddNegotiationCardFeature(id, def)
end

Content.AddNegotiationModifier( "PROPAGANDA_POSTER_MODIFIER", {
    name = "Propaganda Poster",
    desc = "{{1}}, {IMPRINT}\nAt the beginning of each turn, play {2} cards from the imprinted cards in order.\nIf it reaches the end of the list and a card is to be played, remove a random card from the imprinted list and restart from the beginning.\nIf this argument tries to play a card, but no card remains on the imprinted list, remove this argument.",
    alt_desc = "Imprinted cards: {1}",
    desc_fn = function( self, fmt_str, minigame, widget )
        if widget and widget.PostCard then
            if self.cards_played then
                for i, card in ipairs( self.cards_played ) do
                    widget:PostCard( card.id, card, minigame )
                end
            end
        end
        local rval = loc.format( fmt_str, self.propaganda_mod, self.play_per_turn )
        return rval
    end,

    modifier_type = MODIFIER_TYPE.ARGUMENT,
    max_resolve = 7,
    propaganda_mod = "PROP_PO_MEDIOCRE",
    play_per_turn = 2,
    GetPlayPerTurn = function(self)
        return self.play_per_turn + (self.play_per_turn_mod or 0)
    end,
    PlayNextCard = function(self)
        if not self.imprints or #self.imprints == 0 then
            self.out_of_cards = true
            self.negotiator:RemoveModifier(self)
        end
        self.pointer = self.pointer or 1
        
        -- play card
        local card_id = self.imprints[self.pointer]
        if card_id then
            local card = Negotiation.Card(card_id, self.owner )
            card:SetFlags( CARD_FLAGS.CONSUME )
            self.engine:PlayCard(card)
            card:RemoveCard()
            table.insert(self.cards_played, card)
        end
        
        -- advance tracker
        self.pointer = self.pointer + 1
        if self.pointer > #self.imprints then
            local to_remove = math.random(1, #self.imprints)
            table.remove(self.imprints, to_remove)
            self.pointer = 1
            AUDIO:PlayEvent(SoundEvents.card_discard_reshuffle)
        end
    end,
    OnBeginTurn = function( self, minigame )
        self.cards_played = {}
        for i = 1, self:GetPlayPerTurn() do
            if not self.turn_unapplied then -- might run into issues if this is not in.
                self:PlayNextCard()
            end
        end
    end,
    SetData = function(self, imprints, propaganda_mod, max_resolve)
        if imprints then
            self.imprints = shallowcopy(imprints)
            self.pointer = 1
        end
        if propaganda_mod then
            self.propaganda_mod = propaganda_mod
            if FEATURES[propaganda_mod] and FEATURES[propaganda_mod].event_handlers then
                self.event_handlers = table.extend(BASE_HANDLERS)(FEATURES[propaganda_mod].event_handlers)
            end
            self.play_per_turn_mod = FEATURES[propaganda_mod] and FEATURES[propaganda_mod].play_per_turn_mod
        end

        if max_resolve then
            self.max_resolve = max_resolve
            self.resolve = max_resolve
        end
    end,
    event_handlers = BASE_HANDLERS,
} )