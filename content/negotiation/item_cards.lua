local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT
local RESULT = negotiation_defs.RESULT

local CARDS = {
    -- A hatch card for an event
    curious_curio =
    {
        name = "Curious Curio",
        flavour = "'One of those baubles you can't tell the value of without a professional's eye. Brute Force does work as well.'",
        desc = "Draw a card.",
        icon = "DEMOCRATICRACE:assets/cards/curious_curio.png",

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
        flavour = "'A gleaming relic, yes, but not a particularly valuable one.'",
        desc = "Gain {1} {RENOWN}.\nDraw a card.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.renown_stacks)
        end,
        icon = "DEMOCRATICRACE:assets/cards/royal_relic.png",

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
        flavour = "'An old knick-knack the Vagrants wore when they needed to be the center of attention.'",
        desc = "Force all enemy intents and arguments to target it.\nDraw a card.",
        icon = "DEMOCRATICRACE:assets/cards/mesmerizing_charm.png",

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
        flavour = "'A weak firearm, used more for self-defense than active violence. Whoever you point this at may not know that, though.'",
        desc = "{INCEPT} {1} {intimidated}.\nDraw a card.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.intimidated_stack)
        end,
        icon = "DEMOCRATICRACE:assets/cards/intimidating_blaster.png",

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
        flavour = "I'll just keep that here for now.",
        icon = "DEMOCRATICRACE:assets/cards/paperweight.png",

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
        icon = "DEMOCRATICRACE:assets/cards/gift_packaging.png",

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
        icon = "DEMOCRATICRACE:assets/cards/havarian_thesaurus.png",

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
        icon = "DEMOCRATICRACE:assets/cards/business_card.png",

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

        OnPostResolve = function( self, minigame, targets )
            self.negotiator:AddModifier("RENOWN", self.userdata.stacks or 1, self)
        end,
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
        battle_counterpart = "vroc_whistle",

        goon_count = 2,

        OnPostResolve = function( self, minigame, targets )
            for i=1, self.goon_count do
                self.negotiator:CreateModifier("goon", 1, self)
            end
        end,
    },
    spicy_noodles_negotiation =
    {
        name = "Spicy Noodles",
        desc = "Gain {1} {DOMINANCE}. Draw a card.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.condition_count)
        end,

        flavour = "'Establish dominance to your opponent by taking on the heat!'",
        icon = "battle/spicy_noodles.tex",

        cost = 0,
        item_tags = ITEM_TAGS.SUPPORT,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.AMBUSH | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNIQUE,

        max_charges = 2,
        battle_counterpart = "spicy_noodles",

        condition_count = 2,

        OnPostResolve = function( self, minigame, targets )
            self.negotiator:AddModifier("DOMINANCE", self.condition_count, self)
            minigame:DrawCards(1)
        end,
    },
    hearty_noodles_negotiation =
    {
        name = "Hearty Noodles",
        desc = "Gain {1} {1*action|actions}. Draw a card.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.card_count)
        end,

        flavour = "'Stupendous flavours and toothsome noodles at a great price!'",
        icon = "battle/hearty_noodles.tex",

        cost = 1,
        item_tags = ITEM_TAGS.SUPPORT,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.AMBUSH | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNIQUE,

        max_charges = 2,
        battle_counterpart = "hearty_noodles",

        card_count = 2,

        OnPostResolve = function( self, minigame, targets )
            minigame:ModifyActionCount(2)
            minigame:DrawCards(1)
        end,
    },
    pleasant_perfume =
    {
        name = "Pleasant Perfume",
        desc = "{pleasant_perfume|}Gain: Whenever you would gain {INFLUENCE} or {RENOWN}, gain 1 additional stack.",
        icon = "DEMOCRATICRACE:assets/cards/pleasant_perfume.png",

        cost = 1,
        item_tags = ITEM_TAGS.SUPPORT,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNCOMMON,

        max_charges = 3,

        OnPostResolve = function( self, minigame, targets )
            self.negotiator:AddModifier( self.id, 1, self )
        end,

        modifier =
        {
            desc = "Whenever you would gain {INFLUENCE} or {RENOWN}, gain <#HILITE>{1}</> additional {1*stack|stacks}.",
            desc_fn = function(self, fmt_str)
                return loc.format(fmt_str, self.stacks or 1)
            end,

            modifier_type = MODIFIER_TYPE.ARGUMENT,
            max_resolve = 6,

            event_priorities =
            {
                [ EVENT.CALC_DELTA_MODIFIER ] = EVENT_PRIORITY_ADDITIVE,
            },

            event_handlers =
            {
                [ EVENT.CALC_DELTA_MODIFIER ] = function( self, acc, negotiator, modifier, source )
                    if negotiator == self.negotiator and acc.value > 0 then
                        if type(modifier) == "string" and (modifier == "RENOWN" or modifier == "INFLUENCE") then
                        elseif type(modifier) == "table" and (modifier.id == "RENOWN" or modifier.id == "INFLUENCE") then
                        else
                            return
                        end
                        acc:AddValue(1, self)
                    end
                end,
            },
        },
    },
    mask_of_anonymity =
    {
        name = "Mask of Anonymity",
        desc = "Remove all inceptions you control.\nWhile in your hand, you cannot gain inceptions.",
        icon = "DEMOCRATICRACE:assets/cards/mask_of_anonymity.png",

        cost = 1,
        item_tags = ITEM_TAGS.SUPPORT,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNCOMMON,

        OnPostResolve = function( self, minigame, targets )
            local to_remove = {}
            for i, mod in self.negotiator:ModifierSlots() do
                if mod.modifier_type == MODIFIER_TYPE.INCEPTION then
                    table.insert(to_remove, mod)
                end
            end
            for i, mod in ipairs(to_remove) do
                mod:GetNegotiator():RemoveModifier(mod, nil, self)
            end
        end,

        event_priorities =
        {
            [ EVENT.CALC_DELTA_MODIFIER ] = EVENT_PRIORITY_SETTOR,
        },

        event_handlers =
        {
            [ EVENT.CALC_DELTA_MODIFIER ] = function( self, acc, negotiator, modifier, source )
                if negotiator == self.negotiator and acc.value > 0 then
                    if type(modifier) == "string" and Content.GetNegotiationModifier( modifier ).modifier_type == MODIFIER_TYPE.INCEPTION then
                    elseif type(modifier) == "table" and modifier.modifier_type == MODIFIER_TYPE.INCEPTION then
                    else
                        return
                    end
                    acc:ClearValue(self)
                end
            end,
        },
    },
    mask_of_intimidation =
    {
        name = "Mask of Intimidation",
        desc = "Remove all {DOMINANCE} you control and {INCEPT} that much {intimidated}.\nWhile in your hand, when you gain {DOMINANCE}, {INCEPT} that much {intimidated}.",
        icon = "DEMOCRATICRACE:assets/cards/mask_of_intimidation.png",

        cost = 1,
        item_tags = ITEM_TAGS.SUPPORT,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNCOMMON,

        OnPostResolve = function( self, minigame, targets )
            local count = self.negotiator:GetModifierStacks("DOMINANCE")
            self.negotiator:RemoveModifier("DOMINANCE", count, self)
            self.anti_negotiator:InceptModifier( "intimidated", count, self )
        end,

        event_handlers =
        {
            [ EVENT.MODIFIER_ADDED ] = function( self, modifier, source )
                if modifier.id == "DOMINANCE" then
                    self.anti_negotiator:InceptModifier( "intimidated", modifier.stacks, self )
                end
            end,

            [ EVENT.MODIFIER_CHANGED ] = function( self, modifier, delta, clone )
                if delta and delta > 0 and modifier.id == "DOMINANCE" then
                    self.anti_negotiator:InceptModifier( "intimidated", delta, self )
                end
            end,
        },
    },
    index_card =
    {
        name = "Index Card",
        desc = "Restore {1} resolve to a non-core argument.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.resolve_heal)
        end,
        icon = "DEMOCRATICRACE:assets/cards/index_card.png",

        cost = 0,
        item_tags = ITEM_TAGS.SUPPORT,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.REPLENISH,
        rarity = CARD_RARITY.COMMON,

        max_charges = 3,
        target_self = ClearBits(TARGET_ANY_RESOLVE, TARGET_FLAG.CORE),

        resolve_heal = 4,

        OnPostResolve = function( self, minigame, targets )
            for i, target in ipairs(targets) do
                target:RestoreResolve(self.resolve_heal, self)
            end
        end,
    },
    party_spirit =
    {
        name = "Party Spirit",
        desc = "If you control target argument, restore {1} resolve to it and add a {drunk_player} to your draw. Otherwise, deal {2} damage to it and incept {DRUNK}.",
        -- desc = "Target friendly: Restore {1} resolve and add a {drunk_player} to your draw.\nTarget opponent: Deal {2} damage and incept {DRUNK}.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.heal_amount, self.damage_amount)
        end,
        icon = "DEMOCRATICRACE:assets/cards/party_spirit.png",

        cost = 1,
        item_tags = ITEM_TAGS.SUPPORT,
        flags = CARD_FLAGS.ITEM,
        rarity = CARD_RARITY.COMMON,

        max_charges = 2,
        target_self = TARGET_ANY_RESOLVE,
        target_enemy = TARGET_ANY_RESOLVE,

        heal_amount = 4,
        damage_amount = 4,

        OnPostResolve = function( self, minigame, targets )
            local friendly_targets = 0
            for i, target in ipairs(targets) do
                if target.negotiator == self.negotiator then
                    target:RestoreResolve(self.heal_amount, self)
                    friendly_targets = friendly_targets + 1
                else
                    minigame:ApplyPersuasion(self, target, self.damage_amount, self.damage_amount)
                    target.negotiator:CreateModifier("DRUNK", 1, self)
                end
            end
            local cards = {}
            for i = 1, friendly_targets do
                table.insert( cards, Negotiation.Card( "drunk_player", self.engine:GetPlayer() ))
            end
            self.engine:DealCards( cards )
        end,
    },
    pearl_grey =
    {
        name = "Pearl Grey",
        desc = "Create 1 {stoic}",
        icon = "DEMOCRATICRACE:assets/cards/pearl_grey.png",

        cost = 0,
        item_tags = ITEM_TAGS.SUPPORT,
        flags = CARD_FLAGS.ITEM,
        rarity = CARD_RARITY.COMMON,

        max_charges = 2,

        OnPostResolve = function( self, minigame, targets )
            self.negotiator:CreateModifier("stoic", 1, self)
        end,
    },
    -- Report cycle
    work_report =
    {
        name = "Work Report",
        desc = "Insert a {baffled} into your draw pile.",
        flavour = "Minor commotion occurred today at Worksite B. A worker was seen having weird tendrils growing out of his arm, causing minor panic at the worksite.",
        icon = "DEMOCRATICRACE:assets/cards/work_report.png",

        cost = 1,
        item_tags = ITEM_TAGS.SUPPORT,
        flags = CARD_FLAGS.ITEM,
        rarity = CARD_RARITY.COMMON,

        max_charges = 1,

        min_persuasion = 9,
        max_persuasion = 12,
        target_enemy = TARGET_ANY_RESOLVE,

        OnPostResolve = function( self, minigame, targets )
            local cards = {}
            for i = 1, 1 do
                table.insert( cards, Negotiation.Card( "baffled", self.engine:GetPlayer() ))
            end
            self.engine:DealCards( cards )
        end,
    },
    research_report =
    {
        name = "Research Report",
        desc = "If this attack destroys an argument, gain {SMARTS {1}}.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.smarts_bonus)
        end,
        flavour = "After the preliminary test, we have found strong evidence supporting the hypothesis that the chance of the experimental group contracting the parasitic infestation has decreased compared to the control group.",
        icon = "DEMOCRATICRACE:assets/cards/research_report.png",

        cost = 1,
        item_tags = ITEM_TAGS.SUPPORT,
        flags = CARD_FLAGS.ITEM,
        rarity = CARD_RARITY.UNCOMMON,

        max_charges = 1,

        min_persuasion = 6,
        max_persuasion = 9,
        target_enemy = TARGET_ANY_RESOLVE,

        smarts_bonus = 2,

        event_handlers =
        {
            [ EVENT.MODIFIER_REMOVED ] = function( self, modifier, card )
                if card == self then
                    self.negotiator:AddModifier( "SMARTS", self.smarts_bonus, self )
                end
            end,
        },
    },
    executive_report =
    {
        name = "Executive Report",
        desc = "Targets all opponent argument.",
        flavour = "Effective immediately, any Spark Baron who discovers an effective solution to control the infestation shall be rewarded with 2800 shills and a promotion.",
        icon = "DEMOCRATICRACE:assets/cards/executive_report.png",

        cost = 1,
        item_tags = ITEM_TAGS.SUPPORT,
        flags = CARD_FLAGS.ITEM,
        rarity = CARD_RARITY.RARE,

        max_charges = 1,

        min_persuasion = 4,
        max_persuasion = 6,
        target_enemy = TARGET_ANY_RESOLVE,
        target_mod = TARGET_MOD.TEAM,
    },
    neural_disrupter_negotiation =
    {
        name = "Neural Disrupter",
        desc = "Remove target intent.",
        flavour = "Neural disrupters replace a person's thoughts with sparkly lights for a limited time - wait a second.",
        icon = "DEMOCRATICRACE:assets/cards/neural_disrupter_negotiation.png",

        cost = 1,
        item_tags = ITEM_TAGS.SUPPORT,
        flags = CARD_FLAGS.ITEM,
        rarity = CARD_RARITY.UNCOMMON,

        max_charges = 2,

        target_enemy = TARGET_FLAG.INTENT,

        OnPostResolve = function( self, minigame, targets )
            for i, target in ipairs(targets) do
                target.negotiator:DismissIntent(target)
            end
        end,
    },

    -- These cards are the negotiation counterpart of existing battle cards
    sequencer_negotiation =
    {
        name = "Sequencer",
        flavour = "'Universal energy my friend, that's what the blue is all about.'",
        desc = "Restore all uses to an item card in your hand.",
        icon = "battle/sequencer.tex",

        item_tags = ITEM_TAGS.UTILITY,
        rarity = CARD_RARITY.UNCOMMON,

        cost = 1,
        max_charges = 3,

        battle_counterpart = "sequencer",

        flags = CARD_FLAGS.REPLENISH | CARD_FLAGS.EXPEND,

        GetCardsOwnedBySelf = function(self)
            -- if self.negotiator:IsPlayer() and self.engine then
            --     return table.merge( self.engine.hand_deck.cards, self.engine.discard_deck.cards, self.engine.draw_deck.cards )
            -- end
            return self.engine:GetHandDeck()
        end,

        CanPlayCard = function( self, card, engine, target )
            if not self:GetCardsOwnedBySelf() then
                return false, CARD_PLAY_REASONS.NO_VALID_TARGETS
            end
            for i, card in ipairs(self:GetCardsOwnedBySelf().cards) do
                if card:IsPartiallySpent() then
                    return true
                end
            end
            return false, CARD_PLAY_REASONS.NO_VALID_TARGETS
        end,

        OnPostResolve = function( self, minigame, targets )
            local card = minigame:ChooseCardsFromTable( self:GetCardsOwnedBySelf(), 1, 1, Negotiation.Card.IsPartiallySpent, LOC "CARD_ENGINE.CHOOSE_SPENT_CARD", self )[1]
            if card then
                local original_deck = card.deck
                -- card:TransferCard(minigame.trash_deck)
                -- minigame:GetTrashDeck():InsertCard( card )
                card:RestoreCharges()
                -- card.show_dealt = false
                -- minigame:DealCard( card, original_deck )
                -- card:TransferCard(original_deck)
                -- card:NotifyChanged()
            end
        end,
    },
    speed_tonic_negotiation =
    {
        name = "Speed Tonic",
        desc = "2 random cards in hand cost 0 until played.",
        flavour = "'Who needs sleep?'",
        icon = "battle/speed_tonic.tex",

        cost = 1,
        max_charges = 1,
        flags = CARD_FLAGS.REPLENISH,

        item_tags = ITEM_TAGS.CHEMICAL,
        rarity = CARD_RARITY.COMMON,

        battle_counterpart = "speed_tonic",

        OnPostResolve = function( self, minigame, targets )
            local hand = minigame:GetHandDeck()

            local freebies = {}
            for i = 1, 2 do
                local freebie_card = hand:PeekRandom( function( x )
                    local cost = minigame:CalculateActionCost( x )
                    return x ~= self and table.find( freebies, x ) == nil and cost > 0
                end )
                if freebie_card then
                    table.insert(freebies, freebie_card)
                    freebie_card.flags = SetBits( freebie_card.flags, CARD_FLAGS.FREEBIE )
                end
            end
        end,
    },

    vial_of_slurry_negotiation =
    {
        name = "Vial of Slurry",
        desc = "Gain an action.",
        flavour = "'I love this stuff! I can just keep on drinking!'",
        icon = "battle/vial_of_slurry.tex",

        item_tags = ITEM_TAGS.CHEMICAL | ITEM_TAGS.ILLICIT,
        rarity = CARD_RARITY.UNCOMMON,
        flags = CARD_FLAGS.REPLENISH,

        cost = 0,
        max_charges = 3,

        battle_counterpart = "vial_of_slurry",

        OnPostResolve = function( self, minigame, targets )
            minigame:ModifyActionCount( 1 )
        end,
    },

    admiralty_requisition_negotiation =
    {
        name = "Admiralty Requisition",
        flavour = "'Hey I'm just the messenger.'",
        desc = "Draw 3 cards.",
        icon = "battle/admiralty_requisition.tex",

        cost = 0,
        max_charges = 1,

        rarity = CARD_RARITY.UNCOMMON,
        item_tags = ITEM_TAGS.UTILITY | ITEM_TAGS.ADMIRALTY,

        battle_counterpart = "admiralty_requisition",

        OnPostResolve = function( self, minigame, targets )
            minigame:DrawCards( 3 )
        end,
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
