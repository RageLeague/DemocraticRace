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
        event_handlers = {
            [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion, minigame, target )
                if target == self then
                    persuasion:AddPersuasion( 1, 1, self )
                end
            end,
        },
    },
    PROP_PO_SUPERFICIAL =
    {
        name = "Superficial",
        desc = "Cards played by this argument has 1 less max damage.",
        event_handlers = {
            [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion, minigame, target )
                if is_instance( source, Negotiation.Card ) and source.play_source == self then
                    persuasion:AddPersuasion(0, -1, self)
                end
            end,
        },
    },
    PROP_PO_INSPIRING =
    {
        name = "Inspiring",
        desc = "This argument plays 1 more card at the beginning of each turn.",
        play_per_turn_mod = 1,
    },
    PROP_PO_THOUGHT_PROVOKING =
    {
        name = "Thought-Provoking",
        -- desc = "When a manipulate card is played by this argument, {INCEPT} 1 Doubt. (You don't have an explanation for Doubt here, because Klei forgot to nil check)",
        desc = "When a manipulate card is played by this argument, {INCEPT} 1 {DOUBT}.",
        event_handlers = {
            [ EVENT.POST_RESOLVE ] = function(self, minigame, card)
                print("Compare source...")
                print(card.play_source)
                print(self)
                if CheckBits(card.flags, CARD_FLAGS.MANIPULATE) and card.play_source == self then
                    self.anti_negotiator:DeltaModifier( "DOUBT", 1, self )
                end
            end,
        },
    }
}
for id, data in pairs(FEATURES) do
	local def = NegotiationFeatureDef(id, data)
	Content.AddNegotiationCardFeature(id, def)
end

Content.AddNegotiationModifier( "PROPAGANDA_POSTER_MODIFIER", {
    name = "Propaganda Poster",
    --Wumpus; I saw the issue to clarify the argument's description. What's commented is the old description. I don't know if it's clearer, but it's more concise at least.
    desc = "{{1}}, {IMPRINT}\nAt the start of your turn, this argument plays {2} cards in this list, in order.\nWhen it plays all cards in the list, remove a random card from the list and restart the order.\nIf there are no more cards in this list when it tries to play a card, remove this argument.",
    --desc = "{{1}}, {IMPRINT}\nAt the beginning of each turn, play {2} cards from the imprinted cards in order.\nIf it reaches the end of the list and a card is to be played, remove a random card from the imprinted list and restart from the beginning.\nIf this argument tries to play a card, but no card remains on the imprinted list, remove this argument.",
    alt_desc = "Imprinted cards:\n{1}",
    desc_fn = function( self, fmt_str, minigame, widget )
        if widget and widget.PostCard then
            -- if self.cards_played then
            --     for i, card in ipairs( self.cards_played ) do
            --         widget:PostCard( card.id, card, minigame )
            --     end
            -- end
        end
        local rval = loc.format( fmt_str, self.propaganda_mod, self.play_per_turn )
        if self.imprints then
            local res = ""
            for i, card in ipairs(self.imprints) do
                local card_id, card_data
                if type(card) == "string" then
                    card_id, card_data = card, {}
                else
                    card_id, card_data = card[1], card[2]
                end
                if i == self.pointer then
                    local carddef = Content.GetNegotiationCard( card_id )
                    res = res .. loc.format("<#BONUS>{1}</>\n", carddef:GetLocalizedName())
                else
                    res = res .. loc.format("{1#card}\n", card_id)
                end
            end
            rval = rval .. "\n" .. loc.format((self.def or self):GetLocalizedString("ALT_DESC"), res)
        end
        return rval
    end,

    icon = "DEMOCRATICRACE:assets/modifiers/propaganda_poster_modifier.png",

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
            return
        end
        self.pointer = self.pointer or 1

        -- play card
        local card_info = self.imprints[self.pointer]
        if card_info then
            local card_id, card_data
            if type(card_info) == "string" then
                card_id, card_data = card_info, {}
            else
                card_id, card_data = card_info[1], shallowcopy(card_info[2])
            end
            local card = Negotiation.Card(card_id, self.owner, card_data)
            card.userdata.xp = nil
            card.show_dealt = false
            card.special_prepared = true
            card.play_source = self
            card:SetFlags( CARD_FLAGS.CONSUME )

            -- So this is kinda weird, but we need the card to be registered to a deck.
            self.engine.trash_deck:InsertCard( card )
            -- for some reason check prepared is on widget update. so we're doing it this way lul.
            if card.PreReq then
                card:PreReq(self.engine)
            end

            -- print(card:IsPrepared())

            self.engine:PlayCard(card)
            -- card:RemoveCard()
            -- self.engine:DealCard( card )
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
        self:NotifyChanged()
    end,
    OnEndTurn = function( self, minigame )
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
            else
                self.event_handlers = BASE_HANDLERS
            end
            self.play_per_turn_mod = FEATURES[propaganda_mod] and FEATURES[propaganda_mod].play_per_turn_mod

            for id, fn in pairs(self.event_handlers) do
                local priority = self.event_priorities and self.event_priorities[ id ]
                self.engine:ListenForEvent(id, self, self.OnNegotiationEvent, priority )
            end
        end

        if max_resolve then
            self.max_resolve = max_resolve
            self.resolve = max_resolve
        end
        self:NotifyChanged()
    end,
    event_handlers = BASE_HANDLERS,
} )

local POOR_ART = {"PROP_PO_MESSY", "PROP_PO_SUPERFICIAL"}
local GOOD_ART = {"PROP_PO_INSPIRING", "PROP_PO_THOUGHT_PROVOKING"}

local DEFENSIVE_CARDS = {
    "deflection",
    "deflection",
    "deflection",
    "deflection",
    "deflection",
    "bewilder",
    "bewilder",
    "bewilder",
    "bewilder",
    "bewilder",
    "keep_cool",
    "back_pedal",
    "improvise_bait",
    "improvise_bait",
    "improvise_bait",
    "calm",
    "prattle",
    "improvise_gruff",
    "improvise_gruff",
    "improvise_gruff",
    "improvise_withdrawn",
    "improvise_withdrawn",
    "improvise_withdrawn",
    "improvise_wide_composure",
    "improvise_wide_composure",
    "improvise_wide_composure",
    "hard_facts",
    "entrapment",
    "even_footing",
    "fall_guy",
    "fall_guy",
    "fixate",
    "scapegoat",
    "amnesty",
}
local GENERAL_CARD = {
    "improvise_vulnerability",
    "seeds_of_doubt",
    "improvise_vulnerability",
    "seeds_of_doubt",

    "drain_resolve",
    "instigate",
    "insistence",
    "goon",
    "boiler",
    "hot_air",

}
local GENERAL_GOOD_CARD = {
    "heated",
    "good_impression",
    "exploit_weakness",
    "slick",
    "escalate",
    "level_playing_field",
}
local SYNERGY_CARDS = {
    -- diplomacy synergy
    {
        basics = {
            "fast_talk",
        },
        basics_synergy = {

            "improvise_diplomacy",
            "inspiration",
        },
        basics_good = {
            "flatter",
            "compliment",
        },
        drafts = {

            "final_favor",
            "praise",
            "decency",
            "setup",
            "plead",
            "intrigue",
            "intrigue",
            "magnetic_charm",
            "aplomb",
            "swift_rebuttal",
            "subtlety",
            "build_rapport",
            "build_rapport",
            "airtight",
            "rapid_fire",
            "appeal_to_reason",
        },
    },
    -- hostile synergy
    {
        basics = {
            "threaten",
            "bully",

        },
        basics_synergy = {
            "improvise_hostile",
            "mean",
        },
        basics_good = {
            "obtuse",
        },
        drafts = {
            "menacing_air",
            "oppress",
            "oppress",
            "tantrum",
            "rant",
            "brute",
            "veiled_anger",
            "browbeat",
            "domineer",
            "low_blow",
            "bellow",
            "heavy_handed",
            "overbear",
            "tyrannize",
            "bluster",
            "barrage",
            "degrade",
            "chase",
            "crass",
            "crass",
            "crass",
            "double_entendre",
            "domain",
        },

    },
    -- renown synergy?
    {
        basics = {
            "brag",
            "name_drop",
        },
        drafts = {
            "standing",
            "stool_pigeon",
            "immunity",
            "contacts",
            "contacts",
            "influencer",
            "influencer",
            "networker",
            "high_places",
            "executive",
            "who",
            "associates",
            "associates",
            "networked",
            "rescind",
            "dominion",
            "save_face",
            "incredulous",
            "consolidate",
        },
    },
}
local function GetCardOrUpgrades(card_id, chance_for_upgrades)

    if chance_for_upgrades and math.random() < chance_for_upgrades then
        local carddef = Content.GetNegotiationCard(card_id)
        if carddef.upgrade_ids and #carddef.upgrade_ids then
            return table.arraypick(carddef.upgrade_ids)
        end
    end
    return card_id
end
local function GenerateRandomPosterContent()
    local count = math.random(6, 12)
    local defense_idx = math.random(2, 4)
    local main_synergy = table.arraypick(SYNERGY_CARDS)
    local upgrade_chance = 0.5
    local contents = {}
    for i = 1, count do
        local synergy = math.random() < 0.75 and main_synergy or table.arraypick(SYNERGY_CARDS)
        if i == defense_idx then
            table.insert(contents, GetCardOrUpgrades(table.arraypick(DEFENSIVE_CARDS), upgrade_chance))
            defense_idx = defense_idx + math.random(2, 4)
        elseif math.random() < 0.7 then
            if synergy.basics and math.random() < 0.5 then
                if synergy.basics_synergy and math.random() < 0.3 then
                    if synergy.basics_good and math.random() < upgrade_chance then
                        table.insert(contents, GetCardOrUpgrades(table.arraypick(synergy.basics_good), upgrade_chance))
                    else
                        table.insert(contents, GetCardOrUpgrades(table.arraypick(synergy.basics_synergy), upgrade_chance))
                    end
                else
                    table.insert(contents, GetCardOrUpgrades(table.arraypick(synergy.basics), upgrade_chance))
                end
            else
                table.insert(contents, GetCardOrUpgrades(table.arraypick(synergy.drafts), upgrade_chance))
            end
        else
            if math.random() < upgrade_chance then
                table.insert(contents, GetCardOrUpgrades(table.arraypick(GENERAL_GOOD_CARD), upgrade_chance))
            else
                table.insert(contents, GetCardOrUpgrades(table.arraypick(GENERAL_CARD), upgrade_chance))
            end
        end
    end

    return contents
end
function DemocracyUtil.GeneratePropagandaPoster(poster_card, poster_mod)
    if type(poster_mod) == "table" then
        poster_mod = table.arraypick(poster_mod)
    elseif poster_mod == true then
        -- If true, pick a random from good art
        poster_mod = table.arraypick(GOOD_ART)
    elseif poster_mod == false then
        -- If false, pick a random from poor art
        poster_mod = table.arraypick(POOR_ART)
    else
        -- If nil, use mediocre
        poster_mod = "PROP_PO_MEDIOCRE"
    end
    if not poster_card then
        poster_card = GenerateRandomPosterContent()
    end
    assert(type(poster_mod) == "string", "Invalid type for poster_mod")

    local card = Negotiation.Card( "propaganda_poster", TheGame:GetGameState():GetPlayerAgent(), {
        imprints = poster_card,
        prop_mod = poster_mod,
    } )

    return card
end
