local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT
local RESULT = negotiation_defs.RESULT

local CARDS = {
    assassin_fight_call_for_help =
    {
        name = "Call For Help",
        desc = "Attempt to call for help and ask someone to deal with the assassin.",
        icon = "DEMOCRATICRACE:assets/cards/call_for_help.png",

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
    -- this is too boring.
    -- assassin_fight_describe_information =
    -- {
    --     name = "Describe Situation",
    --     desc = "Discribe your current situation to the dispacher.\nIncrease the stacks of <b>Connected Line</> by 1.",
    --     cost = 1,
    --     -- min_persuasion = 1,
    --     -- max_persuasion = 3,
    --     flags = CARD_FLAGS.DIPLOMACY | CARD_FLAGS.STICKY,
    --     rarity = CARD_RARITY.UNIQUE,
    --     deck_handlers = ALL_DECKS,

    --     OnPostResolve = function( self, minigame, targets )
    --         if self.negotiator:GetModifierStacks( "CONNECTED_LINE" ) > 0 then
    --             self.negotiator:AddModifier("CONNECTED_LINE", 1)
    --         else
    --             minigame:ExpendCard(self)
    --         end
    --     end,
    --     event_handlers =
    --     {
    --         [ EVENT.CARD_MOVED ] = function( self, card, source_deck, source_idx, target_deck, target_idx )
    --             if card == self and target_deck and target_deck:GetDeckType() ~= DECK_TYPE.IN_HAND then
    --                 self.show_dealt = true
    --                 if self.negotiator:GetModifierStacks( "CONNECTED_LINE" ) > 0 then
    --                     local has_card = false
    --                     for k,v in pairs(self.engine:GetHandDeck().cards) do
    --                         if v.id == self.id and v ~= self then
    --                             has_card = true
    --                         end
    --                     end
    --                     if not has_card then
    --                         self:TransferCard(self.engine.hand_deck)
    --                     else
    --                         self:TransferCard(self.engine.trash_deck)
    --                     end
    --                 else
    --                     self:TransferCard(self.engine.trash_deck)
    --                 end
    --             end
    --         end,
    --     },
    -- },
    address_question =
    {
        name = "Address Question",
        desc = "Target a question argument. Resolve the effect based on the question being addressed. "..
            "Remove the argument afterwards.\nIf this card leaves the hand, {EXPEND} it.",
        flavour = "'Here is what I think about this topic...'",
        loc_strings = {
            NOT_A_QUESTION = "Target is not a question",
        },
        icon = "negotiation/decency.tex",
        cost = 1,
        flags = CARD_FLAGS.DIPLOMACY,
        rarity = CARD_RARITY.UNIQUE,
        target_enemy = TARGET_FLAG.ARGUMENT | TARGET_FLAG.BOUNTY,
        deck_handlers = ALL_DECKS,
        event_handlers =
        {
            [ EVENT.CARD_MOVED ] = function( self, card, source_deck, source_idx, target_deck, target_idx )
                if card == self and target_deck and target_deck:GetDeckType() ~= DECK_TYPE.IN_HAND then
                    self:TransferCard(self.engine.trash_deck)
                end
            end,
        },
        CanTarget = function(self, target)
            if is_instance( target, Negotiation.Modifier ) and target.AddressQuestion then
                return true
            end
            return false, self.def:GetLocalizedString("NOT_A_QUESTION")
        end,
        OnPostResolve = function( self, minigame, targets )
            for i, target in ipairs(targets) do
                if is_instance( target, Negotiation.Modifier ) and target.AddressQuestion then
                    target:AddressQuestion()
                    target:GetNegotiator():RemoveModifier( target )
                end
            end
        end,
    },
    question_answer =
    {
        name = "Question answer",
        name_fn = function(self, fmt_str)
            if self.issue_data and self.stance then
                return self.issue_data.stances[self.stance]:GetLocalizedName()
            end
            return loc.format(fmt_str)
        end,
        desc = "This is a place that describes the answer to a question.",
        desc_fn = function(self, fmt_str)
            if self.issue_data and self.stance then
                if CheckBits( self.flags, CARD_FLAGS.HOSTILE ) then
                    -- there's no need to localize the following because it's only identifiers
                    return "{CHANGING_STANCE}\n" .. self.issue_data.stances[self.stance]:GetLocalizedDesc()
                else
                    return self.issue_data.stances[self.stance]:GetLocalizedDesc()
                end
            end
            return loc.format(fmt_str)
        end,
        flavour = "Here's what I think...",
        loc_strings = {
            ISSUE_DESC = "About <b>{1}</>:\n{2}",
        },
        flavour_fn = function(self, fmt_str)
            if self.issue_data then
                return loc.format(self.def:GetLocalizedString("ISSUE_DESC"), self.issue_data.name, self.issue_data.desc)
            end
            return loc.format(fmt_str)
        end,

        icon = "negotiation/decency.tex",
        -- hide_in_cardex = true,
        manual_desc = true,

        cost = 0,
        flags = CARD_FLAGS.UNPLAYABLE | CARD_FLAGS.DIPLOMACY,
        rarity = CARD_RARITY.UNIQUE,

        UpdateIssue = function(self, issue_data, stance)
            self.issue_data = issue_data
            self.stance = stance

            local old_stance = DemocracyUtil.TryMainQuestFn("GetStance", issue_data )

            if old_stance and self.stance ~= old_stance then
                self.flags = ClearBits( self.flags, CARD_FLAGS.DIPLOMACY )
                self.flags = SetBits( self.flags, CARD_FLAGS.HOSTILE )
            end

            self:NotifyChanged()
        end,
    },

    contemporary_question_card =
    {

        flags = CARD_FLAGS.SPECIAL | CARD_FLAGS.OPPONENT,
        cost = 0,
        stacks = 1,
        rarity = CARD_RARITY.UNIQUE,

        series = CARD_SERIES.NPC,

        CanPlayCard = function( self, card, engine, target )
            if card == self then
                if not table.arraycontains(self.negotiator.behaviour.available_issues, self.issue_data) then
                    self.issue_data = nil
                end
                if self.issue_data then
                    return true
                else
                    self:TrySelectIssue()
                    return self.issue_data ~= nil
                end
            end
            return true
        end,
        TrySelectIssue = function(self)
            if self.negotiator and self.negotiator.behaviour.available_issues then
                self.issue_data = table.arraypick(self.negotiator.behaviour.available_issues)
            end
        end,

        OnPostResolve = function( self, engine, targets )
            local modifier = Negotiation.Modifier("CONTEMPORARY_QUESTION", self.negotiator, self.stacks)
            if modifier then
                modifier:SetIssue(self.issue_data)
            end
            if self.issue_data and self.negotiator.behaviour.available_issues then
                table.arrayremove(self.negotiator.behaviour.available_issues, self.issue_data)
                self.issue_data = nil
            end

            self.negotiator:CreateModifier(modifier, nil, self)
        end,
    },

    propaganda_poster =
    {
        name = "Propaganda Poster",
        desc = "{IMPRINT}\nCreate a {{1}} Propaganda Poster with the cards imprinted on this card.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.userdata.prop_mod or "PROP_PO_MEDIOCRE")
        end,

        flavour = "Imprinted Cards:\n{1}",
        flavour_fn = function( self, fmt_str )
            if self == nil then
                return ""
            else
                if self.userdata.imprints then
                    local res = ""
                    for i, card in ipairs(self.userdata.imprints) do
                        res = res .. loc.format("{1#card}\n", card)
                    end
                    return loc.format(fmt_str, res)
                end
                return ""
            end
        end,
        icon = "DEMOCRATICRACE:assets/cards/propaganda_poster.png",

        cost = 3,
        max_charges = 3,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNIQUE,
        OnPostResolve = function( self, minigame, targets )
            local propaganda_mod = Negotiation.Modifier("PROPAGANDA_POSTER_MODIFIER", self.negotiator)
            propaganda_mod:SetData(self.userdata.imprints, self.userdata.prop_mod)
            self.negotiator:CreateModifier(propaganda_mod)
        end,
    },

    debater_negotiation_support =
    {
        quips =
        {
            {
                [[
                    {player} is in the right here.
                ]],
                [[
                    I must agree with {player} here.
                ]],
                [[
                    Let's take them down, {player}.
                ]],
                [[
                    !point
                    %confront_argument
                ]],
            },
            {
                tags = "liked",
                [[
                    I believe in {player}.
                ]],
                [[
                    If {player} thinks it's correct, so do I.
                ]],
            },
            {
                tags = "disliked",
                [[
                    Even {player} sees my way.
                ]],
                [[
                    It pains me to say this, but {player} is right.
                ]],
            },
            {
                tags = "player_rook, spark_contact",
                [[
                    Just like the old times, eh?
                ]],
                [[
                    Let's take them down, Captain!
                ]],
            },
        },
        name = "Debater Support",
        show_dealt = false,
        quip = "support",
        rarity = CARD_RARITY.UNIQUE,
        flags = CARD_FLAGS.BYSTANDER,
        OnPostResolve = function( self )
            local mini_negotiator_id = "ADMIRALTY_MINI_NEGOTIATOR"
            local opposition_data = DemocracyUtil.GetOppositionData(self.owner)
            if opposition_data and opposition_data.mini_negotiator then
                mini_negotiator_id = opposition_data.mini_negotiator
            end

            local mod = Negotiation.Modifier( mini_negotiator_id, self.negotiator )
            mod.candidate_agent = self.owner
            self.negotiator:CreateModifier( mod )

            self.engine:BroadcastEvent(EVENT.CUSTOM, function(panel)
                panel.last_ev_time = nil
                panel.speedup_factor = nil
                panel:RefreshCardSpeed()
            end)
        end,
    },
    debater_negotiation_hinder =
    {
        quips =
        {
            {
                [[
                    I must respectfully disagree, {player}.
                ]],
                [[
                    !hips
                    What nonsense is that?
                ]],
                [[
                    !point
                    %rebuttal
                ]],
                [[
                    !point
                    %confront_argument
                ]],
            },
            {
                tags = "liked",
                [[
                    Nothing personal, {player}.
                ]],
                [[
                    I thought we see eye to eye on things, {player}.
                ]],
                [[
                    I can't believe this is how you really think, {player}.
                ]],
            },
            {
                tags = "disliked",
                [[
                    Any words coming out of your mouth are automatically wrong.
                ]],
                [[
                    Heh. Of course you would believe that.
                ]],
            },
        },
        name = "Debater Hinder",
        show_dealt = false,
        rarity = CARD_RARITY.UNIQUE,
        flags = CARD_FLAGS.BYSTANDER,
        OnPostResolve = function( self )
            local mini_negotiator_id = "ADMIRALTY_MINI_NEGOTIATOR"
            local opposition_data = DemocracyUtil.GetOppositionData(self.owner)
            if opposition_data and opposition_data.mini_negotiator then
                mini_negotiator_id = opposition_data.mini_negotiator
            end

            local mod = Negotiation.Modifier( mini_negotiator_id, self.negotiator )
            mod.candidate_agent = self.owner
            self.negotiator:CreateModifier( mod )

            self.engine:BroadcastEvent(EVENT.CUSTOM, function(panel)
                panel.last_ev_time = nil
                panel.speedup_factor = nil
                panel:RefreshCardSpeed()
            end)
        end,
    },
    faction_negotiation_hinder =
    {
        quips =
        {
            {
                [[
                    This is no place for a grifter like you!
                ]],
                [[
                    This is our debate! Not yours!
                ]],
                [[
                    Come to steal my glory, {player}?
                ]],
                [[
                    Hey! You are not supposed to be here!
                ]],
            },
            {
                tags = "liked",
                [[
                    What are you doing, {player}? You should let me handle this?
                ]],
                [[
                    Why are you doing this to me, {player}?
                ]],
            },
            {
                tags = "disliked",
                [[
                    Make a nuisance of yourself somewhere else, {player}.
                ]],
            },
        },
        name = "Faction Hinder",
        show_dealt = false,
        rarity = CARD_RARITY.UNIQUE,
        flags = CARD_FLAGS.BYSTANDER,
        resolve_scale = {20, 25, 30, 35},
        OnPostResolve = function( self )
            local core_id = "POWER_ABUSE"
            local opposition_data = DemocracyUtil.GetOppositionData(self.owner)
            if opposition_data and opposition_data.faction_core then
                core_id = opposition_data.faction_core
            end
            local mod = Negotiation.Modifier( core_id, self.negotiator )
            self.negotiator:CreateModifier( mod )
            mod:SetResolve(DemocracyUtil.CalculateBossScale(self.resolve_scale))
        end,
    },
    appeal_to_crowd_quest =
    {
        name = "Appeal to the Crowd",
        desc = "Gain 1 {CROWD_OPINION}, up to 5 maximum.",
        icon = "negotiation/improvise_compliment.tex",

        cost = 1,
        flags = CARD_FLAGS.DIPLOMACY,
        rarity = CARD_RARITY.UNIQUE,

        CanPlayCard = function( self, card, engine, target )
            return engine:GetOpponentNegotiator():GetModifierStacks("CROWD_OPINION") < 5
        end,

        OnPostResolve = function( self, minigame, targets )
            if minigame:GetOpponentNegotiator():GetModifierStacks("CROWD_OPINION") < 5 then
                minigame:GetOpponentNegotiator():AddModifier("CROWD_OPINION", 1, self)
            end
        end,
    },
    promote_product_quest =
    {
        name = "Promote Product",
        desc = "{1} asks you to promote their product.\nWhen played, create a {promote_product_quest}. The opponent gains 1 {IMPATIENCE}.",
        alt_desc = "Your sponsor",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.userdata and self.userdata.linked_quest and self.userdata.linked_quest:GetProvider() and self.userdata.linked_quest:GetProvider():GetName() or (self.def or self):GetLocalizedString("ALT_DESC"))
        end,

        flavour = "'It sounds like you need this... sideways... eight. Yeah! You need sideways eight in your life!'",
        icon = "DEMOCRATICRACE:assets/cards/promote_product.png",

        cost = 1,
        flags = CARD_FLAGS.MANIPULATE | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNIQUE,

        OnPostResolve = function(self, minigame, targets)
            local mod = Negotiation.Modifier("promote_product_quest", self.negotiator)
            mod.linked_quest = self.userdata.linked_quest
            mod.return_card = self
            self.negotiator:CreateModifier(mod)
            self.anti_negotiator:DeltaModifier("IMPATIENCE", 1, self)
        end,

        modifier = {
            desc = "When this argument is destroyed, return {promote_product_quest} to your draw pile.\n\nIf you win the negotiation while having this argument, each person present will be advertised of {1}'s product!",
            alt_desc = "your sponsor",

            desc_fn = function(self, fmt_str)
                return loc.format(fmt_str, self.linked_quest and self.linked_quest:GetProvider():GetName() or (self.def or self):GetLocalizedString("ALT_DESC"))
            end,
            icon = "DEMOCRATICRACE:assets/modifiers/promote_product.png",

            modifier_type = MODIFIER_TYPE.ARGUMENT,
            max_resolve = 5,
            OnUnapply = function( self, minigame )
                if self.return_card then
                    self.return_card:TransferCard(minigame:GetDrawDeck())
                end
            end,

            event_handlers =
            {
                [ EVENT.END_NEGOTIATION ] = function(self, minigame)
                    if self.linked_quest and minigame:GetResult() == RESULT.WIN then
                        local count = 0
                        if TheGame:GetGameState():GetPlayerAgent():GetLocation() then
                            for i, agent in TheGame:GetGameState():GetPlayerAgent():GetLocation():Agents() do
                                if agent:IsSentient() and not agent:IsPlayer() then
                                    count = count + 1
                                end
                            end
                        end
                        count = math.max(1, count)
                        local quest = self.linked_quest
                        quest.param.people_advertised = quest.param.people_advertised + count
                        quest:DefFn("VerifyCount")
                        -- if quest.param.people_advertised >= 25 then
                        --     quest:Complete("sell")
                        -- end
                    end
                end,
            },
        },
    },
    console_opponent =
    {
        name = "Console",
        desc = "Apply {1} {COMPOSURE}, then transfer all composure on that argument to your opponent's core argument.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:CalculateComposureText( self.composure_base ))
        end,
        icon = "negotiation/empathy.tex",

        cost = 1,
        flags = CARD_FLAGS.DIPLOMACY | CARD_FLAGS.REPLENISH,
        rarity = CARD_RARITY.UNIQUE,

        composure_base = 2,

        target_self = TARGET_ANY_RESOLVE,

        OnPostResolve = function( self, minigame, targets )
            for i, target in ipairs(targets) do
                target:DeltaComposure( self.composure_base, self )

                local delta = target.composure
                if self.anti_negotiator:FindCoreArgument() then
                    self.anti_negotiator:FindCoreArgument():DeltaComposure(delta, self)
                    target:DeltaComposure(-delta, self)
                end
            end
        end,
    },
    -- I just grabbed lumin burn.
    status_fracturing_mind =
    {
        name = "Fracturing Mind",
        desc = "A random argument you control takes {1} damage.",
        alt_desc = "If this card is in your hand at the end of the turn, divide it into 2.",

        flavour = "Knowledge is a gift that keeps on giving.",

        icon = "DEMOCRATICRACE:assets/cards/fracturing_mind.png",

        desc_fn = function(self, fmt_str)
            if (self.userdata and self.userdata.count or 0) > 1 then
                return loc.format(fmt_str, self.userdata.count ) .. "\n" .. (self.def or self):GetLocalizedString("ALT_DESC")
            else
                return loc.format(fmt_str, self.userdata and self.userdata.count or 1)
            end
        end,

        cost = 1,
        flags =  CARD_FLAGS.STATUS | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNIQUE,

        target_self = TARGET_ANY_RESOLVE,
        target_mod = TARGET_MOD.RANDOM1,

        on_init = function( self )
            self.userdata.count = 4
        end,

        OnPostResolve = function( self, minigame, targets )
            for i, target in ipairs(targets) do
                target:AttackResolve(self.userdata.count or 1, self)
            end
        end,

        event_handlers =
        {
            [ EVENT.END_PLAYER_TURN ] = function( self, minigame )
                local new_amt = math.floor(self.userdata.count / 2)
                if new_amt > 0 then
                    self:NotifyChanged()
                    minigame:ExpendCard(self)
                    local cards = {}
                    for k = 1, 2 do
                        local incepted_card = Negotiation.Card( "status_fracturing_mind", self.owner)
                        incepted_card.userdata.count = new_amt
                        incepted_card.flags = self.flags
                        table.insert(cards, incepted_card )
                    end
                    minigame:DealCards( cards, minigame:GetDiscardDeck() )

                end
            end,
        },
    },
    ai_fracture_mind =
    {
        name = "Fracture Mind",
        desc = "Adds {1} {status_fracturing_mind} {1*card|cards} to your draw pile.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self.count )
        end,

        cost = 1,
        flags = CARD_FLAGS.OPPONENT,
        rarity = CARD_RARITY.UNIQUE,

        count = 1,

        OnPostResolve  = function( self, minigame )
            local cards = {}
            for i = 1, self.count do
                local card = Negotiation.Card( "status_fracturing_mind", minigame:GetPlayer() )
                card.flags = card.flags | CARD_FLAGS.REPLENISH
                table.insert( cards, card )
            end
            minigame:InceptCards( cards, self )
        end,
    },
    quest_any_card_bonus =
    {
        name = "Mystery Card Bonus",
        desc = "What card bonus will you get? It's a mystery.",

        icon = "negotiation/negotiation_wild.tex",

        flags = CARD_FLAGS.MANIPULATE | CARD_FLAGS.UNPLAYABLE,
        rarity = CARD_RARITY.UNIQUE,
        manual_desc = true,

        hide_in_cardex = true
    },
    ai_appropriate_card =
    {
        name = "Appropriate",

        cost = 1,
        flags = CARD_FLAGS.OPPONENT,
        rarity = CARD_RARITY.UNIQUE,

        count = 1,

        MIN_TO_LEAVE = 5,

        GetStealCount = function( self )
            return GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ARGUMENT_PLUS ) and 2 or 1
        end,

        CanPlayCard = function( self, card, engine, target )
            if card == self then
                local MAX_STOLEN = 3 * self:GetStealCount()
                local MIN_TO_LEAVE = self.MIN_TO_LEAVE

                local num_stolen = 0
                for i,modifier in self.negotiator:ModifierSlots() do
                    if modifier.id == "APPROPRIATED" then
                        num_stolen = num_stolen + modifier:GetStolenCount()
                    end
                end
                if num_stolen < MAX_STOLEN then
                    local cards = self.engine:GetAllPlayerCards(function(card) return not CheckBits( card.flags, CARD_FLAGS.STATUS ) end)
                    if #cards > MIN_TO_LEAVE then
                        return true
                    end
                end
            end
        end,

        OnPostResolve  = function( self, minigame )
            local cards = self.engine:GetAllPlayerCards(function(card) return not CheckBits( card.flags, CARD_FLAGS.STATUS ) end)
            local count = math.min( #cards - self.MIN_TO_LEAVE, self:GetStealCount() )
            cards = table.multipick(cards, count)
            local approp
            if count > 1 then
                approp = self.negotiator:CreateModifier("APPROPRIATED_plus", 1, self )
            else
                approp = self.negotiator:CreateModifier("APPROPRIATED", 1, self )
            end
            for i, card in ipairs( cards ) do
                if approp:IsApplied() then -- verify that it still exists
                    print( self.negotiator, "appropriated", card, "from", card.deck )
                    approp:AppropriateCard( card )
                end
            end
        end,
    },
    supporting_rumor =
    {
        name = "Supporting Rumor",
        flavour = "'The word on the streets is...'",
        desc = "At the end of your turn, gain 3 {RENOWN}.",
        icon = "DEMOCRATICRACE:assets/cards/supporting_rumor.png",
        flags = CARD_FLAGS.MANIPULATE | CARD_FLAGS.UNPLAYABLE | CARD_FLAGS.REPLENISH,
        rarity = CARD_RARITY.UNIQUE,
        cost = 0,

        event_handlers =
        {
            [ EVENT.END_PLAYER_TURN ] = function( self, minigame )
                self:NotifyTriggeredPre()
                self.negotiator:AddModifier("RENOWN", 3, self )
                self:NotifyTriggeredPost()
            end
        },
    },
    conflicting_rumor =
    {
        name = "Conflicting Rumor",
        flavour = "'But what I heard is...'",
        desc = "At the end of your turn, lose 3 {RENOWN}.",
        icon = "DEMOCRATICRACE:assets/cards/conflicting_rumor.png",
        flags = CARD_FLAGS.MANIPULATE | CARD_FLAGS.UNPLAYABLE | CARD_FLAGS.REPLENISH,
        rarity = CARD_RARITY.UNIQUE,
        cost = 0,

        event_handlers =
        {
            [ EVENT.END_PLAYER_TURN ] = function( self, minigame )
                self:NotifyTriggeredPre()
                self.negotiator:RemoveModifier("RENOWN", 3, self )
                self:NotifyTriggeredPost()
            end
        },
    },
    oolo_planted_evidence_wordsmith =
    {
        name = "Plant Evidence",

        cost = 1,
        flags = CARD_FLAGS.OPPONENT,
        rarity = CARD_RARITY.UNIQUE,

        base_incept = { 1, 3, 3, 5 },

        OnPostResolve = function( self, minigame )
            local incept_count = DemocracyUtil.CalculateBossScale(self.base_incept) + minigame:GetDifficulty()
            self.anti_negotiator:CreateModifier( "PLANTED_EVIDENCE", incept_count, self )
        end,
    },
}
for i, id, def in sorted_pairs( CARDS ) do
    if not def.series then
        def.series = CARD_SERIES.GENERAL
    end
    Content.AddNegotiationCard( id, def )
end

local FEATURES = {
    CHANGING_STANCE =
    {
        name = "Changing Stance",
        desc = "You have already taken a stance on this issue. Changing it may make people think you're hypocritical, and you might lose support!",
    },
    IMPRINT =
    {
        name = "Imprint",
        desc = "Some cards are imprinted on this object through special means, and they will affect the behaviour of this object.",
    },
}
for id, data in pairs(FEATURES) do
    local def = NegotiationFeatureDef(id, data)
    Content.AddNegotiationCardFeature(id, def)
end
