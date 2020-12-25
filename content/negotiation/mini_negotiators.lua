local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT

local ARGUMENT_CREATER =
{
    desc = "Create {2} {{1}}",
    desc_fn = function(self, fmt_str)
        return loc.format(fmt_str, self.argument_to_create or self.userdata.argument_to_create,
            self.stacks_to_create or self.userdata.stacks_to_create or 1)
    end,
    OnPostResolve = function( self, battle, attack)
        local modifier = self.negotiator:CreateModifier( self.argument_to_create or self.userdata.argument_to_create, 
            self.stacks_to_create or self.userdata.stacks_to_create or 1, self )
        modifier.real_owner = self.real_owner
    end,
}
local ARGUMENT_INCEPTER =
{
    desc = "{INCEPT} {2} {{1}}",
    desc_fn = function(self, fmt_str)
        return loc.format(fmt_str, self.argument_to_create or self.userdata.argument_to_create,
            self.stacks_to_create or self.userdata.stacks_to_create or 1)
    end,
    OnPostResolve = function( self, battle, attack)
        local modifier = self.anti_negotiator:CreateModifier( self.argument_to_create or self.userdata.argument_to_create, 
            self.stacks_to_create or self.userdata.stacks_to_create or 1, self )
        modifier.real_owner = self.real_owner
    end,
}
local MINI_NEGOTIATOR_CARDS =
{
    mn_influence_damage =
    {
        name = "Ethos",
        flags = CARD_FLAGS.DIPLOMACY,
        min_persuasion = 1,
        max_persuasion = 4,
    },
    mn_manipulate_damage =
    {
        name = "Logos",
        flags = CARD_FLAGS.MANIPULATE,
        min_persuasion = 3,
        max_persuasion = 3,
    },
    mn_hostile_damage =
    {
        name = "Pathos",
        flags = CARD_FLAGS.HOSTILE,
        min_persuasion = 2,
        max_persuasion = 3,
    },
    mn_composure =
    {
        name = "Tangent",
        flags = CARD_FLAGS.MANIPULATE,
        target_self = TARGET_ANY_RESOLVE,
        features =
        {
            COMPOSURE = 5,
        },
    },
    mn_interrogate = table.extend(ARGUMENT_CREATER){
        name = "Interrogate",
        flags = CARD_FLAGS.MANIPULATE,
        argument_to_create = "INTERROGATE",
    },
    mn_kingpin = table.extend(ARGUMENT_CREATER){
        name = "Kingpin",
        flags = CARD_FLAGS.HOSTILE,
        argument_to_create = "KINGPIN",
    },
    mn_strawman = table.extend(ARGUMENT_INCEPTER){
        name = "Straw Man",
        flags = CARD_FLAGS.MANIPULATE,
        argument_to_create = "straw_man",
    },
}
for i, id, def in sorted_pairs( MINI_NEGOTIATOR_CARDS ) do
    if not def.cost then
        def.cost = 1
    end
    if not def.series then
        def.series = CARD_SERIES.NPC
    end
    if not def.rarity then
        def.rarity = CARD_RARITY.UNIQUE
    end
    -- if not def.shop_price then
    --     def.shop_price = 250
    -- end
    Content.AddNegotiationCard( id, def )
end

local MINI_NEGOTIATOR =
{
    name = "Candidate",
    desc = "At the end of your turn, <b>{1.fullname}</> acts and plays {2} cards.\nThis argument takes double damage from other candidates.",
    -- loc_strings = {
    --     ADMIRALTY_BONUS = "Then, if the opponent has no {PLANTED_EVIDENCE}, {INCEPT} one.",
    --     SPREE_BONUS = "{1.name}'s cards deals 1 bonus damage for every 2 turns passed.",
    --     BARON_BONUS = "Then, appropriate an opponent card.",
    --     RISE_BONUS = "Then, a random negotiator loses 1 action for their next turn.",
    --     CULT_BONUS = "When any argument on {1.name}'s team gets destroyed, all other arguments gain 2 resolve.",
    --     JAKES_BONUS = "Whenever {1.name}'s cards deal damage, they gain resolve equal to resolve loss. If no resolve is lost, they take 3 damage.",
    -- },
    desc_fn = function(self, fmt_str, minigame, widget)
        -- if self.special and (self.def or self).loc_strings[self.special .. "_BONUS"] then
        --     fmt_str = fmt_str .. "\n" .. (self.def or self):GetLocalizedString(self.special .. "_BONUS")
        -- end
        if widget and widget.PostCard and self.prepared_cards then
            for i, card in ipairs( self.prepared_cards) do
                widget:PostCard( card.id, card, minigame )
            end
        end
        local res = loc.format(fmt_str, self.candidate_agent and self.candidate_agent:LocTable(),self.cards_played)
        return res
    end,
    modifier_type = MODIFIER_TYPE.CORE,

    cards_played = 3,
    max_stacks = 1,

    available_cards = {},
    prepared_cards = {},
    OnInit = function(self)
        self.prepared_cards = {}
        self.available_cards = {}
        if self.available_cards_def then
            for i, data in ipairs(self.available_cards_def) do
                local card = Negotiation.Card(data[1], self.negotiator.agent, data[2])
                card.real_owner = self
                table.insert(self.available_cards, card)
            end
        end
        self:PrepareCards()
    end,
    OnEndTurn = function( self, minigame )
        -- if self.target_enemy then
        --     self:ApplyPersuasion()
        -- end
        for i, card in ipairs(self.prepared_cards) do
            card.show_dealt = false
            self.engine.trash_deck:InsertCard( card )
            self.engine:PlayCard(card)
            card:RemoveCard()
        end
        self:PrepareCards()
    end,
    PrepareCards = function(self)
        table.clear(self.prepared_cards)
        local cards = table.multipick( self.available_cards, math.min(#self.available_cards, self.cards_played) )
        -- table.shuffle(cards)
        for i, card in ipairs(cards) do
            table.insert(self.prepared_cards, card)
        end
    end,

    no_damage_tt = true,
    -- icon = engine.asset.Texture("negotiation/modifiers/voice_of_the_people.tex"),

    target_enemy = TARGET_ANY_RESOLVE,

    -- SetCandidate = function(self, candidate_agent, available_cards, special)
    --     self.candidate_agent = candidate_agent
    --     self.available_cards = shallowcopy(available_cards)
    --     self.special = special

    --     self:NotifyChanged()
    -- end,
}
Content.AddNegotiationModifier("ADMIRALTY_MINI_NEGOTIATOR",
table.extend(MINI_NEGOTIATOR){
    available_cards_def = 
    {
        {"mn_influence_damage"}, 
        {"mn_interrogate"}, 
        {"mn_manipulate_damage"}, 
        {"mn_manipulate_damage"}, 
        {"mn_hostile_damage"},
    },
})

