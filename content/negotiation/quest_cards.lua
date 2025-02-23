local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT
local RESULT = negotiation_defs.RESULT

local CARDS = {
    assassin_fight_call_for_help =
    {
        name = "Call For Help",
        desc = "Gain 1 {CONNECTED_LINE} if one does not exist. Otherwise, gain 1 {DEM_HELP_REQUEST_PROGRESS}.",
        icon = "DEMOCRATICRACE:assets/cards/call_for_help.png",

        cost = 1,
        -- min_persuasion = 1,
        -- max_persuasion = 3,
        flags = CARD_FLAGS.DIPLOMACY,
        rarity = CARD_RARITY.UNIQUE,

        OnPostResolve = function( self, minigame, targets )
            if self.negotiator:GetModifierStacks("HELP_UNDERWAY") == 0 then
                if self.negotiator:GetModifierInstances("CONNECTED_LINE") > 0 then
                    self.negotiator:AddModifier("DEM_HELP_REQUEST_PROGRESS", 1, self)
                else
                    self.negotiator:AddModifier("CONNECTED_LINE", 1, self)
                end
            end
        end,
        -- deck_handlers = ALL_DECKS,
        -- event_handlers =
        -- {
        --     [ EVENT.CARD_MOVED ] = function( self, card, source_deck, source_idx, target_deck, target_idx )
        --         if card == self and target_deck and target_deck:GetDeckType() == DECK_TYPE.TRASH
        --             and self.negotiator:GetModifierStacks( "CONNECTED_LINE" ) <= 0 then
        --             self.show_dealt = true
        --             self:TransferCard(self.engine.hand_deck)
        --         end
        --     end,
        -- },
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
        target_self = TARGET_FLAG.ARGUMENT | TARGET_FLAG.BOUNTY,
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
                    target.is_addressed = true
                    target:GetNegotiator():RemoveModifier( target, nil, self )
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
        hide_in_cardex = true,
        manual_desc = true,

        cost = 0,
        flags = CARD_FLAGS.UNPLAYABLE | CARD_FLAGS.DIPLOMACY,
        rarity = CARD_RARITY.UNIQUE,

        UpdateIssue = function(self, issue_data, stance)
            self.issue_data = issue_data
            self.stance = stance

            local old_stance = DemocracyUtil.TryMainQuestFn("GetStance", issue_data )

            if old_stance then
                if self.stance == old_stance then
                elseif DemocracyUtil.GetStanceChangeFreebie(self.issue_data) and (self.stance * old_stance > 0) then
                else
                    self.flags = ClearBits( self.flags, CARD_FLAGS.DIPLOMACY )
                    self.flags = SetBits( self.flags, CARD_FLAGS.HOSTILE )
                end
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
                        local card_id = type(card) == "string" and card or card[1]
                        res = res .. loc.format("{1#card}\n", card_id)
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
            self.negotiator:CreateModifier(propaganda_mod, 1, self)
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
    dem_opportunistic_retreat =
    {
        name = "Opportunistic Retreat",
        desc = "Remove {1} {DISTRACTED} from the opponent: One member of your party escapes the scene. You win the negotiation if you escape.",
        alt_desc = "Requires at least {1} <b>Distracted</b>",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.stacks_needed)
        end,
        flavour = "When all else fails, you can always run away.",
        icon = "DEMOCRATICRACE:assets/cards/opportunistic_retreat.png",

        cost = 1,
        flags = CARD_FLAGS.MANIPULATE,
        rarity = CARD_RARITY.UNIQUE,

        stacks_needed = 3,

        PreReq = function( self, minigame )
            return self:CanPlayCard( self, minigame )
        end,

        CanPlayCard = function( self, card, engine, target )
            if self.anti_negotiator:GetModifierStacks("DISTRACTED") < self.stacks_needed then
                return false, loc.format( (self.def or self):GetLocalizedString("ALT_DESC"), self.stacks_needed )
            end
            return true
        end,

        OnPostResolve = function( self, minigame )
            self.anti_negotiator:DeltaModifier("DISTRACTED", -self.stacks_needed, self)
            local cards = {}
            local party = self.owner:GetParty()
            if party then
                for i, member in party:Members() do
                    if not (minigame.escaped_people and table.arraycontains(minigame.escaped_people, member)) then
                        local card = Negotiation.Card( "dem_retreat_target", self.owner )
                        card:SetAgent(member)
                        table.insert(cards, card)
                    end
                end
            end
            local pick = self.engine:ImproviseCards( cards, 1, nil, nil, nil, self )[1]
            if pick then
                table.insert(minigame.escaped_people, pick.retreat_agent)
                self.engine:ExpendCard(pick)
                if pick.retreat_agent == self.owner then
                    minigame:Win()
                end
            end
        end,
    },
    dem_retreat_target =
    {
        name = "Retreat Target",
        name_fn = function(self, fmt_str)
            if self.retreat_agent then
                return self.retreat_agent:GetName()
            end
            return loc.format(fmt_str)
        end,
        desc = "Let <b>{1}</> run away from the scene.",
        alt_desc = "Let a party member run away from the scene.",
        desc_fn = function(self, fmt_str)
            if self.retreat_agent then
                return loc.format(fmt_str, self.retreat_agent:GetFullName())
            end
            return loc.format((self.def or self):GetLocalizedString("ALT_DESC"))
        end,
        icon = "DEMOCRATICRACE:assets/cards/opportunistic_retreat.png",

        -- icon = "negotiation/decency.tex",
        hide_in_cardex = true,
        manual_desc = true,

        cost = 0,
        flags = CARD_FLAGS.UNPLAYABLE | CARD_FLAGS.DIPLOMACY,
        rarity = CARD_RARITY.UNIQUE,

        SetAgent = function(self, agent)
            self.retreat_agent = agent
            self:NotifyChanged()
        end,
    },
    dem_random_rare_parasite =
    {
        name = "Thriving Parasites",
        desc = "Transforms into a random Rare Parasite card when added to your deck.",
        icon = "battle/bog_symbiosis.tex",

        cost = 0,
        flags = CARD_FLAGS.UNPLAYABLE | CARD_FLAGS.STATUS,
        rarity = CARD_RARITY.UNIQUE,
        manual_desc = true,

        global_event_handlers =
        {
            [ "card_added" ] = function( self, card )
                if card == self then
                    local parasites = {}
                    local negotiation_defs = require "negotiation/negotiation_defs"
                    for i, def in ipairs( Content.GetAllNegotiationCards() ) do
                        if CheckBits( def.flags, negotiation_defs.CARD_FLAGS.PARASITE ) then
                            parasites[ def.id ] = def
                        end
                    end

                    local fun = require "util/fun"
                    local new_card_id = fun(parasites)
                            :filter(function(v) return v.rarity == CARD_RARITY.RARE end)
                            :keys()
                            :shuffle()
                            :first()
                    if new_card_id then
                        local card = self.owner.negotiator:LearnCard(new_card_id)
                    end
                    self.owner.negotiator:RemoveCard(card)
                end
            end,
        },
    },
    status_injury_negotiation =
    {
        name = "Injury",
        flavour = "'Ouch.'",
        icon = "battle/status_injury.tex",

        cost = 1,
        flags = CARD_FLAGS.STATUS | CARD_FLAGS.EXPEND,
        rarity = CARD_RARITY.UNIQUE,

        battle_counterpart = "status_injury",
    },
    dem_lightheaded =
    {
        name = "Lightheaded",
        desc = "At the end of your turn, {EXPEND} this card.",
        flavour = "'Can't focus'",
        icon = "battle/status_winded.tex",

        cost = 1,
        flags = CARD_FLAGS.STATUS | CARD_FLAGS.CONSUME | CARD_FLAGS.SLEEP_IT_OFF,
        rarity = CARD_RARITY.UNIQUE,
        event_handlers =
        {
            [ EVENT.END_PLAYER_TURN ] = function( self, minigame )
                minigame:ExpendCard(self)
            end,
        },
    },
    dem_weary_negotiation =
    {
        name = "Weary",
        remove_on_rest = true,
        desc = "When drawn, lose 1 action.",
        flavour = "'I'm so tired.'",
        icon = "battle/weary.tex",

        cost = 1,
        rarity = CARD_RARITY.BASIC,
        flags = CARD_FLAGS.STATUS | CARD_FLAGS.CONSUME | CARD_FLAGS.SLEEP_IT_OFF,

        battle_counterpart = "weary",
        event_handlers =
        {
            [ EVENT.CARD_MOVED ] = function( self, card, source_deck, source_idx, target_deck, target_idx )
                if card == self and target_deck == self.engine:GetHandDeck() and source_deck == self.engine:GetDrawDeck() then
                    self:NotifyTriggeredPre()
                    self.engine:ModifyActionCount( -1 )
                    self:NotifyTriggeredPost()
                end
            end
        },
    },
    dem_incriminating_evidence =
    {
        name = "Incriminating Evidence",
        desc = "{dem_incriminating_evidence 2|}Create: At the start of your turn, {INCEPT} 2 {VULNERABILITY}. Must be targeted before anything else.",
        flavour = "'Can't focus'",
        icon = "DEMOCRATICRACE:assets/cards/incriminating_evidence.png",

        cost = 1,
        flags = CARD_FLAGS.ITEM | CARD_FLAGS.EXPEND,
        item_tags = ITEM_TAGS.ILLICIT,
        rarity = CARD_RARITY.UNIQUE,

        OnPostResolve = function( self, minigame )
            self.negotiator:CreateModifier(self.id, 2, self)
        end,

        modifier = {
            desc = "Create: At the start of your turn, {INCEPT} {1} {VULNERABILITY}. Must be targeted before anything else.",
            icon = "DEMOCRATICRACE:assets/modifiers/incriminating_evidence.png",

            desc_fn = function(self, fmt_str)
                return loc.format(fmt_str, self.stacks or 2)
            end,

            force_target = true,
            max_resolve = 4,

            OnBeginTurn = function( self, minigame )
                self.anti_negotiator:InceptModifier("VULNERABILITY", self.stacks, self)
            end,

            CanPlayCard = function( self, source, engine, target )
                -- Only verify forced targets if you are not targetting yourself
                if source:IsAttack() and target:GetNegotiator() == self.negotiator then
                    if source.modifier_type == MODIFIER_TYPE.INCEPTION or source:GetNegotiator() ~= self.negotiator then
                        if not target.force_target then
                            return false, loc.format( LOC "CONVO_COMMON.MUST_TARGET", self:GetName() )
                        end
                    end
                end

                return true
            end,
        },
    },
    dem_court_objection =
    {
        name = "Objection!",
        desc = "{DEM_COUNTERARGUMENT}",
        alt_desc = "{DEM_COUNTERARGUMENT}, {DEM_PERJURY}",
        icon = "negotiation/ad_lib.tex",

        desc_fn = function(self, fmt_str)
            local argument_id = self.userdata.argument_id
            local result = fmt_str
            if argument_id and self.evidence[argument_id] and self.evidence[argument_id].perjury then
                result = (self.def or self):GetLocalizedString("ALT_DESC")
            end
            if argument_id then
                result = result .. "\n" .. (self.def or self):GetLocalizedString(argument_id:upper())
            end
            return result
        end,

        loc_strings =
        {
            NOT_AN_EVIDENCE = "Target is not an evidence",


            -- The defendant is currently wearing a ring. Either because it's never lost, or you stole it from the prosecutor and gave it back
            DEFENDANT_HAS_RING = "The defendant is currently wearing their ring, so it couldn't possibly be at the crime scene.",
            -- The defendant is wearing a fake ring that they claim to be theirs. You must deliberately forge this evidence
            DEFENDANT_HAS_FALSE_RING = "The defendant is currently wearing \"their ring\", so it couldn't possibly be at the crime scene.",
            -- You casted doubt on the witness testimony
            DOUBTFUL_TESTIMONY = "Even though the witness testified against the defendant, the witness is uncertain whether the person they saw is actually the defendant.",
            -- You asked the defendant about their alibi, and it's airtight
            AIRTIGHT_ALIBI = "The defendant was working at the time of the crime. Everyone at their worksite can attest to the fact.",
            -- The defendant doesn't have an alibi, so you faked one
            FORGED_ALIBI = "The defendant was at a friend's house at the time of the crime. The friend can attest to the \"fact\".",
            -- You heard a description of the ring after asking the defendant about it
            RING_DESC = "The defendant has a wedding ring of an elaborate design, with an engraving of the name of their partner and them.",
            -- The client is not guilty and you asked them about their ring.
            RING_LOSS_TIMELINE = "According to the defendant, they still have their ring, one day after the theft.",
        },

        evidence =
        {
            defendant_has_ring =
            {
                counterargument =
                {
                    evidence_ring_fake = 0.8,
                    evidence_ring_real = 0.4,
                },
            },
            defendant_has_false_ring =
            {
                counterargument =
                {
                    evidence_ring_fake = 0.4,
                    evidence_ring_real = 0.4,
                },
                perjury = true,
            },
            doubtful_testimony =
            {
                counterargument =
                {
                    testimony = 0.6,
                },
            },
            airtight_alibi =
            {
                counterargument =
                {
                    evidence_ring_fake = 0.9,
                    evidence_ring_real = 0.9,
                    testimony = 0.9,
                },
            },
            forged_alibi =
            {
                counterargument =
                {
                    evidence_ring_fake = 0.6,
                    evidence_ring_real = 0.6,
                    testimony = 0.6,
                },
                perjury = true,
            },
            ring_desc =
            {
                counterargument =
                {
                    evidence_ring_fake = 0.6,
                },
            },
            ring_loss_timeline =
            {
                counterargument =
                {
                    evidence_ring_fake = 0.4,
                    evidence_ring_real = 0.4,
                },
            },
        },

        cost = 1,
        flags = CARD_FLAGS.DIPLOMACY,
        rarity = CARD_RARITY.UNIQUE,

        target_enemy = TARGET_FLAG.ARGUMENT,

        on_init = function( self )
            if self.userdata.argument_id then
                if self.evidence[self.userdata.argument_id] and self.evidence[self.userdata.argument_id].perjury then
                    self.flags = ToggleBits(self.flags, CARD_FLAGS.DIPLOMACY | CARD_FLAGS.MANIPULATE)
                end
            end
        end,

        CanTarget = function(self, target)
            if is_instance( target, Negotiation.Modifier ) and target.dem_evidence and target.max_resolve then
                return true
            end
            return false, self.def:GetLocalizedString("NOT_AN_EVIDENCE")
        end,

        OnPostResolve = function( self, minigame, targets )
            local argument_id = self.userdata.argument_id
            if not argument_id then
                return
            end
            for i, target in ipairs(targets) do
                if is_instance( target, Negotiation.Modifier ) and target.dem_evidence and target.max_resolve then
                    local evidence_id = target.evidence_id
                    local resolve_loss = 0
                    if self.evidence[argument_id] and self.evidence[argument_id].counterargument[evidence_id] then
                        resolve_loss = self.evidence[argument_id].counterargument[evidence_id]
                    end

                    if resolve_loss > 0 then
                        local true_loss = math.ceil(target.max_resolve * resolve_loss)
                        true_loss = math.min(true_loss, target.resolve)
                        target:ModifyResolve(-true_loss, self)
                        minigame:ExpendCard(self)
                    else
                        local damage = Content.GetNegotiationCardFeature("DEM_COUNTERARGUMENT").core_damage
                        self.negotiator:AttackResolve(damage, self)
                    end
                end
            end
            if self.evidence[argument_id] and self.evidence[argument_id].perjury then
                self.negotiator:CreateModifier("DEM_FALSE_EVIDENCE", 1, self)
            end
        end,
    },
    dem_present_evidence =
    {
        flags = CARD_FLAGS.SPECIAL | CARD_FLAGS.OPPONENT,
        cost = 0,
        stacks = 1,
        rarity = CARD_RARITY.UNIQUE,

        series = CARD_SERIES.NPC,

        CanPlayCard = function( self, card, engine, target )
            if card == self then
                if not table.arraycontains(self.negotiator.behaviour.plaintiff_arguments, self.argument) then
                    self.argument = nil
                end
                if self.argument then
                    return true
                else
                    self:TrySelectArgument()
                    return self.argument ~= nil
                end
            end
            return true
        end,
        TrySelectArgument = function(self)
            if self.negotiator and self.negotiator.behaviour.plaintiff_arguments then
                self.argument = table.arraypick(self.negotiator.behaviour.plaintiff_arguments)
            end
        end,

        OnPostResolve = function( self, engine, targets )
            local modifier = Negotiation.Modifier("DEM_CONCRETE_EVIDENCE_ARGUMENT", self.negotiator, self.stacks)
            if modifier then
                modifier:SetEvidence(self.argument)
            end
            if self.argument and self.negotiator.behaviour.plaintiff_arguments then
                table.arrayremove(self.negotiator.behaviour.plaintiff_arguments, self.argument)
                self.argument = nil
            end

            self.negotiator:CreateModifier(modifier, nil, self)
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
    DEM_COUNTERARGUMENT =
    {
        name = "Counterargument",
        desc = "Target an {DEM_EVIDENCE} argument. If the counterargument contradicts the argument, the target lose a proportion of resolve depending on the effectiveness of the counterargument and {EXPEND}. Otherwise, you core takes {1} damage.",

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.core_damage)
        end,

        core_damage = 3,
    },
    DEM_PERJURY =
    {
        name = "Perjury",
        desc = "When this card is played, create 1 {DEM_FALSE_EVIDENCE}",
    },
}
for id, data in pairs(FEATURES) do
    local def = NegotiationFeatureDef(id, data)
    Content.AddNegotiationCardFeature(id, def)
end
