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
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.HATCH,

        rarity = CARD_RARITY.UNCOMMON,

        available_hatch = {"royal_relic", "mesmerizing_charm", "intimidating_blaster"},

        is_artifact = true,
        -- shop_price = 80,

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
        flags = CARD_FLAGS.ITEM,
        rarity = CARD_RARITY.RARE,

        is_artifact = true,
        -- shop_price = 135,

        renown_stacks = 3,

        OnPostResolve = function( self, minigame )
            self.negotiator:AddModifier("RENOWN", self.renown_stacks, self)
            minigame:DrawCards( 1 )
        end,
    },
    mesmerizing_charm =
    {
        name = "Mesmerizing Charm",
        flavour = "'Wow this charm is really mesmerizing!'",
        desc = "Force all enemy intents and arguments to target it.\nDraw a card.",

        cost = 1,
        flags = CARD_FLAGS.ITEM,
        rarity = CARD_RARITY.RARE,
        target_self = TARGET_ANY_RESOLVE,

        is_artifact = true,
        -- shop_price = 135,

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

            minigame:DrawCards( 1 )
        end
    },
    intimidating_blaster =
    {
        name = "Intimidating Blaster",
        flavour = "'I have no idea how to use this, but I can test it on you if you'd like.'",
        desc = "{INCEPT} {1} {intimidated}.\nDraw a card.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.intimidated_stack)
        end,

        cost = 1,
        flags = CARD_FLAGS.ITEM,
        rarity = CARD_RARITY.RARE,

        is_artifact = true,
        practical = true,
        -- shop_price = 150,

        intimidated_stack = 3,

        OnPostResolve = function( self, minigame )
            self.anti_negotiator:AddModifier("intimidated", self.intimidated_stack, self )
            minigame:DrawCards( 1 )
        end,
    },
    paperweight =
    {
        name = "Paperweight",
        desc = "Choose a card in your hand and give it {STICKY} for the rest of this negotiation.",

        cost = 0,
        item_tags = ITEM_TAGS.UTILITY,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.EXPEND | CARD_FLAGS.STICKY,
        rarity = CARD_RARITY.UNCOMMON,

        max_charges = 2,

        loc_strings =
        {
            CHOOSE_STICKY = "Choose a card and give it <b>Sticky</>"
        },

        OnPostResolve = function( self, minigame, targets )
            local chosen_card = minigame:ChooseCard( nil, self.def:GetLocalizedString("CHOOSE_STICKY") )
            if chosen_card then
                chosen_card:SetFlags(CARD_FLAGS.STICKY)
            end
        end,
    },
    gift_packaging =
    {
        name = "Gift Packaging",
        desc = "{IMPROVISE} a card from the draw pile and let the opponent {APPROPRIATED|appropriate} it.",
        flavour = "'I have something for you!'",

        cost = 1,
        item_tags = ITEM_TAGS.UTILITY,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.EXPEND | CARD_FLAGS.REPLENISH,
        rarity = CARD_RARITY.COMMON,

        max_charges = 3,

        pool_size = 3,

        OnPostResolve = function( self, minigame, targets )
            if minigame:GetDrawDeck():CountCards() == 0 then
                minigame:ShuffleDiscardToDraw()
            end

            local cards = table.multipick(minigame:GetDrawDeck().cards, self.pool_size)
            local improvised = minigame:ImproviseCards( cards, self.num_cards, nil, "ad_lib", nil, self )

            -- Do card appropriation
            local approp
            if #improvised <= 0 then
                return
            elseif #improvised > 1 then
                approp = self.anti_negotiator:CreateModifier("APPROPRIATED_plus", 1, self )
            else
                approp = self.anti_negotiator:CreateModifier("APPROPRIATED", 1, self )
            end
            for i, card in ipairs( improvised ) do
                if approp:IsApplied() then -- veryify that it still exists
                    print( self.anti_negotiator, "appropriated", card, "from", card.deck )
                    approp:AppropriateCard( card )
                end
            end
        end,
    },
    havarian_thesaurus =
    {
        name = "Havarian Thesaurus",
        desc = "For the rest of the turn, for each other unique card played, gain 1 {SMARTS}.",

        cost = 1,
        item_tags = ITEM_TAGS.UTILITY,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.RARE,

        max_charges = 3,

        OnPostResolve = function( self, minigame, targets )
            self.negotiator:AddModifier( self.id, 1, self )
        end,

        modifier =
        {
            alt_desc = "(Cards played: {1#comma_listing})",
            desc_fn = function(self, fmt_str)
                if self.cards_played and #self.cards_played > 0 then
                    local txt = {}
                    for i, card in ipairs(self.cards_played) do
                        table.insert(txt, loc.format("{1#card}", card))
                    end
                    return fmt_str .. "\n\n" .. loc.format((self.def or self):GetLocalizedString("ALT_DESC"), txt)
                end
                return fmt_str
            end,

            modifier_type = MODIFIER_TYPE.PERMANENT,

            OnInit = function(self)
                if not self.cards_played then
                    self.cards_played = {}
                end
            end,

            OnEndTurn = function( self, minigame )
                self.negotiator:RemoveModifier( self )
            end,

            event_handlers =
            {
                [ EVENT.POST_RESOLVE ] = function( self, minigame, card )
                    if not self.cards_played then
                        self.cards_played = {}
                    end
                    if card.id ~= self.id and not table.arraycontains(self.cards_played, card.id) then
                        table.insert(self.cards_played, card.id)
                        self.negotiator:AddModifier( "SMARTS", 1, self )
                    end
                end,
            },
        },
    },
    business_card =
    {
        name = "Business Card",
        desc = "Gain {1} {RENOWN}.\n{STACKING}: Increase the stacks gained by 1.",

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.userdata and self.userdata.stacks or 1)
        end,

        cost = 0,
        item_tags = ITEM_TAGS.UTILITY,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.COMMON,

        PostLoad = function( self, game_state )
            self._base.PostLoad( self, game_state )
            if self.userdata and self.userdata.stacks ~= nil then
                self:SetStacks( self.userdata.stacks )
            end
        end,

        SetStacks = function( self, stacks )
            self.userdata.stacks = math.min( 99, stacks or 1 )
        end,

        global_event_handlers =
        {
            [ "card_added" ] = function( self, card )
                if card.id == self.id and card ~= self then
                    self:SetStacks( (self.userdata.stacks or 1) + (card.userdata.stacks or 1) )
                    self.owner.negotiator:RemoveCard(card)
                end
            end,
        },
    },
    vroc_whistle_negotiation =
    {
        name = "Vroc Whistle",
        desc = "Create {1} separate {goon}.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.goon_count)
        end,

        flavour = "'Wait, hold on. I thought this is used to summon vrocs.'",
        icon = "battle/vroc_whistle.tex",

        cost = 0,
        item_tags = ITEM_TAGS.SUPPORT,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.REPLENISH,
        rarity = CARD_RARITY.RARE,

        max_charges = 3,

        goon_count = 2,

        OnPostResolve = function( self, minigame, targets )
            for i=1, self.goon_count do
                self.negotiator:CreateModifier("goon", 1, self)
            end
        end,
    },
    pleasant_perfume =
    {
        name = "Pleasant Perfume",
        desc = "Create: If you would gain one or more stacks of {INFLUENCE} or {RENOWN}, gain that much stacks plus 1 instead.",

        cost = 1,
        item_tags = ITEM_TAGS.SUPPORT,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.REPLENISH,
        rarity = CARD_RARITY.UNCOMMON,
    },
}
for i, id, def in sorted_pairs( CARDS ) do
    def.item_tags = (def.item_tags or 0) | ITEM_TAGS.NEGOTIATION
    def.flags = (def.flags or 0) | CARD_FLAGS.ITEM
    def.rarity = def.rarity or CARD_RARITY.UNIQUE
    def.series = def.series or CARD_SERIES.GENERAL

    if def.is_democratic_race == nil then
        def.is_democratic_race = true
    end

    Content.AddNegotiationCard( id, def )
end