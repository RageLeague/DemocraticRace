local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT
local function PlainDescFn(self, fmt_str)
    return fmt_str
end
local CARDS = {
    advisor_diplomacy_relatable =
    {
        name = "Relatable",
        desc = "Gain bonus damage equal to half your {INFLUENCE}, rounded up.\nGain {1} {INFLUENCE}.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, AutoUpgradeText(self, "influence_gain"))
        end,
        flavour = "'Being relatable to your target is important to gain their trust, remember that. That's why you should use hip languages around others.'",
        icon = "DEMOCRATICRACE:assets/cards/relatable.png",

        advisor = "ADVISOR_DIPLOMACY",
        flags = CARD_FLAGS.DIPLOMACY,
        cost = 1,

        min_persuasion = 1,
        max_persuasion = 1,

        influence_gain = 1,

        OnPostResolve = function( self, minigame )
            self.negotiator:AddModifier( "INFLUENCE", self.influence_gain, self )
        end,

        event_priorities =
        {
            [ EVENT.CALC_PERSUASION ] = EVENT_PRIORITY_ADDITIVE,
        },

        event_handlers =
        {
            [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion )
                if source == self then
                    local stacks = self.negotiator:GetModifierStacks("INFLUENCE")
                    if stacks > 0 then
                        persuasion:AddPersuasion(math.ceil(stacks / 2), math.ceil(stacks / 2), self)
                    end
                end
            end,
        },
    },
    advisor_diplomacy_relatable_plus =
    {
        name = "Tall Relatable",

        min_persuasion = 1,
        max_persuasion = 4,
    },
    advisor_diplomacy_relatable_plus2 =
    {
        name = "Boosted Relatable",
        influence_gain = 2,
    },
    advisor_diplomacy_virtue_signal =
    {
        name = "Virtue Signal",
        desc = "If you have {1} or more {2}, instead destroy the target if it is an argument or bounty.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, AutoUpgradeText(self, "modifier_threshold", true),
                AutoUpgradeText(self, "req_argument_id", false, function(x) return "{" .. x .. "}" end))
        end,
        flavour = "'Look at me, I am doing good things by gifting people with money. Now vote for me.'\n'What? You don't? Then I guess you must hate the poor.'",
        icon = "DEMOCRATICRACE:assets/cards/virtue_signal.png",

        advisor = "ADVISOR_DIPLOMACY",
        flags = CARD_FLAGS.DIPLOMACY,
        cost = 1,

        min_persuasion = 2,
        max_persuasion = 3,

        modifier_threshold = 5,
        req_argument_id = "INFLUENCE",

        PreReq = function( self, minigame )
            return self.negotiator:GetModifierStacks(self.req_argument_id) >= self.modifier_threshold
        end,

        OnPostResolve = function( self, minigame, targets )
            if self:PreReq(minigame) then
                for i, target in ipairs(targets) do
                    if (target.modifier_type == MODIFIER_TYPE.ARGUMENT or target.modifier_type == MODIFIER_TYPE.BOUNTY) then
                        target.negotiator:DestroyModifier(target, self)
                    end
                end
            end
            -- self.negotiator:AddModifier( "INFLUENCE", self.influence_gain, self )
        end,

        event_priorities =
        {
            [ EVENT.CALC_PERSUASION ] = EVENT_PRIORITY_CLAMP + 100,
        },

        event_handlers =
        {
            [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion, minigame, target )
                if source == self then
                    if self:PreReq(minigame) and target and (target.modifier_type == MODIFIER_TYPE.ARGUMENT or target.modifier_type == MODIFIER_TYPE.BOUNTY) then
                        persuasion:ModifyPersuasion(0, 0, self )
                    end
                end
            end,
        }
    },
    advisor_diplomacy_virtue_signal_plus =
    {
        name = "Pale Virtue Signal",
        modifier_threshold = 3,
    },
    advisor_diplomacy_virtue_signal_plus2 =
    {
        name = "Twisted Virtue Signal",
        req_argument_id = "DOMINANCE",
    },
    advisor_diplomacy_smiling_daggers =
    {
        name = "Smiling Daggers",
        desc = "This card deals 1 bonus damage for every 2 {DOMINANCE} you have.",
        flavour = "'What a nice thing you got there. Would it be a shame if something were to happen to it.'",
        icon = "DEMOCRATICRACE:assets/cards/smiling_daggers.png",

        advisor = "ADVISOR_DIPLOMACY",
        flags = CARD_FLAGS.DIPLOMACY,
        cost = 1,

        min_persuasion = 1,
        max_persuasion = 4,

        bonus_count = 2,
        event_priorities =
        {
            [ EVENT.CALC_PERSUASION ] = EVENT_PRIORITY_ADDITIVE,
        },

        event_handlers =
        {
            [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion )
                if source == self then
                    local stacks = self.negotiator:GetModifierStacks("DOMINANCE")
                    if stacks > 0 then
                        persuasion:AddPersuasion(math.floor(stacks / self.bonus_count), math.floor(stacks / self.bonus_count), self)
                    end
                end
            end,
        },
    },
    advisor_diplomacy_smiling_daggers_plus =
    {
        name = "Tall Smiling Daggers",
        max_persuasion = 7,
    },
    advisor_diplomacy_smiling_daggers_plus2 =
    {
        name = "Enhanced Smiling Daggers",
        desc = "This card deals 1 bonus damage for every <#UPGRADE>{DOMINANCE}</> you have.",
        bonus_count = 1,
    },
    advisor_diplomacy_hive_mind =
    {
        name = "Hive Mind",
        desc = "{advisor_diplomacy_hive_mind|}Create: At the end of your turn, deal damage equal to the number of arguments, bounties, and inceptions you have to a random opponent argument.",
        flavour = "Great minds think alike.",
        icon = "DEMOCRATICRACE:assets/cards/hive_mind.png",

        advisor = "ADVISOR_DIPLOMACY",
        flags = CARD_FLAGS.DIPLOMACY | CARD_FLAGS.EXPEND,
        cost = 1,

        argument_id = "advisor_diplomacy_hive_mind",

        OnPostResolve = function(self, minigame, targets)
            self.negotiator:CreateModifier(self.argument_id, 1, self)
        end,
        modifier =
        {
            desc = "At the end of your turn, deal damage equal to the number of arguments, bounties, and inceptions you have to a random opponent argument.",
            icon = "DEMOCRATICRACE:assets/modifiers/hive_mind.png",
            modifier_type = MODIFIER_TYPE.ARGUMENT,
            max_resolve = 5,

            min_persuasion = 0,
            max_persuasion = 0,

            target_enemy = TARGET_ANY_RESOLVE,

            no_damage_tt = true,

            CalculateDamage = function(self)
                local count = 0
                for i, mod in self.negotiator:Modifiers() do
                    if mod.modifier_type == MODIFIER_TYPE.ARGUMENT or
                        mod.modifier_type == MODIFIER_TYPE.BOUNTY or
                        mod.modifier_type == MODIFIER_TYPE.INCEPTION then

                        count = count + 1
                    end
                end
                return count
            end,
            OnEndTurn = function(self, minigame)
                self:ApplyPersuasion()
            end,
            event_handlers =
            {
                [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion, minigame, target )
                    if source == self then
                        local damage = self:CalculateDamage()
                        persuasion:AddPersuasion( damage, damage, self )
                    end
                end,
                [ EVENT.MODIFIER_ADDED ] = function( self, modifier, source )
                    self:NotifyChanged()
                end,
                [ EVENT.MODIFIER_ADDED ] = function( self, modifier, source )
                    self:NotifyChanged()
                end,
            },
        },
    },
    advisor_diplomacy_hive_mind_plus =
    {
        name = "Wide Hive Mind",
        desc = "{advisor_diplomacy_hive_mind_plus|}Create: At the end of your turn, deal damage equal to the number of arguments, bounties, and inceptions <#UPGRADE>anyone has</> to a random opponent argument.",
        argument_id = "advisor_diplomacy_hive_mind_plus",
        modifier =
        {
            desc = "At the end of your turn, deal damage equal to the number of arguments, bounties, and inceptions anyone has to a random opponent argument.",
            CalculateDamage = function(self)
                local count = 0
                for i, mod in self.negotiator:Modifiers() do
                    if mod.modifier_type == MODIFIER_TYPE.ARGUMENT or
                        mod.modifier_type == MODIFIER_TYPE.BOUNTY or
                        mod.modifier_type == MODIFIER_TYPE.INCEPTION then

                        count = count + 1
                    end
                end
                for i, mod in self.anti_negotiator:Modifiers() do
                    if mod.modifier_type == MODIFIER_TYPE.ARGUMENT or
                        mod.modifier_type == MODIFIER_TYPE.BOUNTY or
                        mod.modifier_type == MODIFIER_TYPE.INCEPTION then

                        count = count + 1
                    end
                end
                return count
            end,
        },
    },
    advisor_diplomacy_hive_mind_plus2 =
    {
        name = "Enduring Hive Mind",
        flags = CARD_FLAGS.DIPLOMACY,
    },
    advisor_diplomacy_underdog =
    {
        name = "Underdog",
        desc = "Gain +{1} damage for each argument your opponent has and for each bounty and inception you have.",
        flavour = "'They oppose me because they don't want you to know the truth!'",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, AutoUpgradeText(self, "damage_bonus"))
        end,
        icon = "DEMOCRATICRACE:assets/cards/underdog.png",

        advisor = "ADVISOR_DIPLOMACY",
        flags = CARD_FLAGS.DIPLOMACY,
        cost = 1,

        min_persuasion = 2,
        max_persuasion = 3,

        damage_bonus = 1,

        event_priorities =
        {
            [ EVENT.CALC_PERSUASION ] = EVENT_PRIORITY_ADDITIVE,
        },
        event_handlers =
        {
            [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion )
                if source == self then
                    local count = 0
                    for i, mod in self.negotiator:Modifiers() do
                        if mod.modifier_type == MODIFIER_TYPE.BOUNTY or mod.modifier_type == MODIFIER_TYPE.INCEPTION then
                            count = count + 1
                        end
                    end
                    for i, mod in self.anti_negotiator:Modifiers() do
                        if mod.modifier_type == MODIFIER_TYPE.ARGUMENT then
                            count = count + 1
                        end
                    end
                    persuasion:AddPersuasion(count * self.damage_bonus, count * self.damage_bonus, self)
                end
            end,
        }
    },
    advisor_diplomacy_underdog_plus =
    {
        name = "Tall Underdog",

        max_persuasion = 6,
    },
    advisor_diplomacy_underdog_plus2 =
    {
        name = "Enhanced Underdog",
        damage_bonus = 2,
    },
    advisor_manipulate_straw_army =
    {
        name = "Straw Army",
        desc = "{INCEPT} {1} separate {straw_man} arguments.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, AutoUpgradeText(self, "strawman_count"))
        end,
        flavour = "'You know the straw man argument, the one that the Barons likes to use? We're better than that.'",
        icon = "DEMOCRATICRACE:assets/cards/straw_army.png",

        advisor = "ADVISOR_MANIPULATE",
        flags = CARD_FLAGS.MANIPULATE,
        cost = 2,

        strawman_count = 3,

        OnPostResolve = function( self, minigame )
            for i = 1, self.strawman_count do
                self.anti_negotiator:CreateModifier( "straw_man", 1, self )
            end
        end,
    },
    advisor_manipulate_straw_army_plus =
    {
        name = "Boosted Straw Army",
        strawman_count = 5,
    },
    advisor_manipulate_straw_army_plus2 =
    {
        name = "Initial Straw Army",
        flags = CARD_FLAGS.MANIPULATE | CARD_FLAGS.AMBUSH,
    },
    advisor_manipulate_gaslighting =
    {
        name = "Gaslighting",
        desc = "Remove target argument or bounty you control. Until the beginning of your next turn, "
            .. "all opponent sources that are targeting it deal no damage.",
        flavour = "'I have no idea what you're talking about. You must be crazy.'",
        icon = "DEMOCRATICRACE:assets/cards/gaslighting.png",

        advisor = "ADVISOR_MANIPULATE",
        flags = CARD_FLAGS.MANIPULATE,
        cost = 1,

        target_self = TARGET_FLAG.ARGUMENT | TARGET_FLAG.BOUNTY,
        modifier =
        {
            hidden = true,

            event_priorities =
            {
                [ EVENT.CALC_PERSUASION ] = EVENT_PRIORITY_CLAMP + 100,
            },

            event_handlers =
            {
                [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion )
                    if self.affected_sources and table.arraycontains(self.affected_sources, source) then
                        persuasion:ModifyPersuasion(0, 0, self)
                    end
                end,

                [ EVENT.BEGIN_TURN ] = function( self, minigame, negotiator )
                    if negotiator == self.negotiator then
                        self.negotiator:RemoveModifier( self )
                    end
                end,
            }
        },
        OnPostResolve = function( self, minigame, targets )
            for i, target in ipairs(targets) do
                local sources = {}
                if minigame:IsBeingTargettedBy( target, self.anti_negotiator, sources ) then
                    local mod = self.negotiator:CreateModifier( "advisor_manipulate_gaslighting", 1, self )
                    mod.affected_sources = sources
                end
                target.negotiator:RemoveModifier( target )
                if self.PostProcess then
                    self:PostProcess(target, sources)
                end
            end
        end,
    },

    advisor_manipulate_gaslighting_plus =
    {
        name = "Doubtful Gaslighting",
        alt_desc = "<#UPGRADE>{INCEPT} {DOUBT} equal to the number of sources affected.</>",
        desc_fn = function(self, fmt_str)
            return fmt_str .. "\n" .. (self.def or self):GetLocalizedString("ALT_DESC")
        end,
        PostProcess = function(self, target, sources)
            if sources and #sources > 0 then
                self.anti_negotiator:InceptModifier("DOUBT", #sources , self )
            end
        end,
    },
    advisor_manipulate_gaslighting_plus2 =
    {
        name = "Visionary Gaslighting",
        alt_desc = "<#UPGRADE>Draw cards equal to the number of sources affected.</>",
        desc_fn = function(self, fmt_str)
            return fmt_str .. "\n" .. (self.def or self):GetLocalizedString("ALT_DESC")
        end,
        PostProcess = function(self, target, sources)
            if sources and #sources > 0 then
                self.engine:DrawCards(#sources)
            end
        end,
    },
    advisor_manipulate_moreef_defense =
    {
        name = "Moreef Defense",
        desc = "Create {1} separate {advisor_manipulate_moreef_defense}.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, AutoUpgradeText(self, "argument_count"))
        end,
        flavour = "'If Sweet Moreef doesn't live in Rentoria, you must acquit.'",
        icon = "DEMOCRATICRACE:assets/cards/moreef_defense.png",

        advisor = "ADVISOR_MANIPULATE",
        flags = CARD_FLAGS.MANIPULATE,
        cost = 1,

        argument_count = 2,

        OnPostResolve = function(self, minigame, targets)
            local new_args = {}
            for i = 1, self.argument_count do
                table.insert(new_args, self.negotiator:CreateModifier("advisor_manipulate_moreef_defense", 1, self))
            end
            if self.PostProcess then
                self:PostProcess(new_args, minigame)
            end
        end,
        modifier = {
            name = "Moreef Defense",
            desc = "Why does this argument have no special abilities? It doesn't make any sense!",
            desc_fn = PlainDescFn,
            icon = "DEMOCRATICRACE:assets/modifiers/moreef_defense.png",
            modifier_type = MODIFIER_TYPE.ARGUMENT,

            max_resolve = 6,
            OnSetStacks = function( self, old_stacks )
                local delta = self.stacks - math.max( 1, old_stacks )
                self:ModifyResolve( delta * 6 )
            end,
        },
    },
    advisor_manipulate_moreef_defense_plus =
    {
        name = "Boosted Moreef Defense",
        argument_count = 3,
    },
    advisor_manipulate_moreef_defense_plus2 =
    {
        name = "Distracting Moreef Defense",
        desc = "Create {1} separate {advisor_manipulate_moreef_defense}. <#UPGRADE>Force all opponent intents to target an argument created this way.</>",

        PostProcess = function(self, new_args, minigame)
            local target = new_args[1]
            if target and target:IsApplied() then
                for i,intent in ipairs(minigame:GetOtherNegotiator(self.negotiator):GetIntents()) do
                    if intent.target then
                        intent.target = target
                    end
                end
                for i,argument in minigame:GetOtherNegotiator(self.negotiator):Modifiers() do
                    if argument.target then
                        argument.target = target
                    end
                end
            end
        end,
    },
    advisor_manipulate_rapid_speaker =
    {
        name = "Rapid Speaker",
        desc = "Attack {1} times.",
        alt_desc = "{BLIND}.",
        desc_fn = function(self, fmt_str)
            if self.target_mod == TARGET_MOD.RANDOM1 then
                return loc.format((self.def or self):GetLocalizedString("ALT_DESC") .. "\n" .. fmt_str, AutoUpgradeText(self, "attack_count"))
            end
            return loc.format(fmt_str, AutoUpgradeText(self, "attack_count"))
        end,
        flavour = "'Imagine, hypothetically, bear with me...'\n'Oh, no. Here we go again.'",
        icon = "DEMOCRATICRACE:assets/cards/rapid_speaker.png",

        advisor = "ADVISOR_MANIPULATE",
        flags = CARD_FLAGS.MANIPULATE,
        cost = 1,

        min_persuasion = 1,
        max_persuasion = 1,

        attack_count = 4,
        target_mod = TARGET_MOD.RANDOM1,
        OnPostResolve = function( self, minigame, targets )
            for i=2, self.attack_count do
                minigame:ApplyPersuasion(self)
            end
        end,
    },
    advisor_manipulate_rapid_speaker_plus =
    {
        name = "Focused Rapid Speaker",
        target_mod = TARGET_MOD.SINGLE,
    },
    advisor_manipulate_rapid_speaker_plus2 =
    {
        name = "Very Rapid Speaker",
        attack_count = 6,
    },
    advisor_manipulate_projection =
    {
        name = "Projection",
        desc = "{1} a card from your {2}. {INCEPT} {3} {FLUSTERED} if it's a Diplomacy card, {4} {DOUBT} if it's a Manipulate card, and {5} {VULNERABILITY} if it's a Hostility card.",
        flavour = "'You try to argue with me, but deep down, you know that I'm right.'",
        icon = "DEMOCRATICRACE:assets/cards/projection.png",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str,
                AutoUpgradeText(self, "improvise_count", false, function(x)
                    if x > 3 then
                        return "{IMPROVISE_PLUS}"
                    else
                        return "{IMPROVISE}"
                    end
                end),
                AutoUpgradeText(self, "change_to_discard", false, function(x)
                    if x then
                        return string.lower(LOC"UI.CARDS.DISCARDS_DECK_DIALOG_TITLE")
                    else
                        return string.lower(LOC "UI.CARDS.DRAW_DECK_DIALOG_TITLE")
                    end
                end),
                AutoUpgradeText(self, "fluster_count"),
                AutoUpgradeText(self, "doubt_count"),
                AutoUpgradeText(self, "vulnerability_count")
            )
        end,

        advisor = "ADVISOR_MANIPULATE",
        flags = CARD_FLAGS.MANIPULATE,
        cost = 1,

        improvise_count = 3,
        change_to_discard = false,

        fluster_count = 1,
        doubt_count = 2,
        vulnerability_count = 1,

        OnPostResolve = function(self, minigame, targets)
            if minigame:GetDrawDeck():CountCards() == 0 and not self.change_to_discard then
                minigame:ShuffleDiscardToDraw()
            end
            local candidates = self.change_to_discard and minigame:GetDiscardDeck().cards or minigame:GetDrawDeck().cards
            local cards = minigame:ImproviseCards( table.multipick(candidates, self.improvise_count), 1, nil, "ad_lib", nil, self )
            for i, card in ipairs(cards) do
                if CheckBits(card.flags, CARD_FLAGS.DIPLOMACY ) then
                    self.anti_negotiator:DeltaModifier("FLUSTERED", self.fluster_count, self)
                end
                if CheckBits(card.flags, CARD_FLAGS.MANIPULATE ) then
                    self.anti_negotiator:DeltaModifier("DOUBT", self.doubt_count, self)
                end
                if CheckBits(card.flags, CARD_FLAGS.HOSTILE ) then
                    self.anti_negotiator:DeltaModifier("VULNERABILITY", self.vulnerability_count, self)
                end
            end
        end,
    },
    advisor_manipulate_projection_plus =
    {
        name = "Wide Projection",
        improvise_count = 5,
    },
    advisor_manipulate_projection_plus2 =
    {
        name = "Twisted Projection",
        improvise_count = 5,
        change_to_discard = true,
    },

    advisor_hostile_talk_over =
    {
        name = "Talk Over",
        desc = "Prevent the next source of damage dealt to any of your arguments.",

        flavour = "The best way to win is to not giving the opponent the chance to speak.",

        icon = "DEMOCRATICRACE:assets/cards/talk_over.png",

        advisor = "ADVISOR_HOSTILE",
        flags = CARD_FLAGS.HOSTILE | CARD_FLAGS.EXPEND,
        cost = 1,

        count = 1,
        -- card_draw = 0,

        OnPostResolve = function( self, minigame, targets )
            self.negotiator:AddModifier("advisor_hostile_talk_over", self.count, self)
            -- if self.card_draw and self.card_draw > 0 then
            --     minigame:DrawCards( self.card_draw )
            -- end
        end,

        modifier =
        {
            icon = "DEMOCRATICRACE:assets/modifiers/talk_over.png",
            modifier_type = MODIFIER_TYPE.PERMANENT,
            event_handlers =
            {
                [ EVENT.ATTACK_RESOLVE ] = function( self, source, target, damage, params, defended )
                    if target.negotiator == self.negotiator then
                        -- if is_instance( source, Negotiation.Modifier ) then
                        --     source:AttackResolve(damage, self)
                        -- else
                        --     source.negotiator:AttackResolve(damage, self)
                        -- end
                        target.composure = target.composure + damage
                        self.negotiator:DeltaModifier(self, -1, self)
                    end
                end,

                -- [ EVENT.BEGIN_PLAYER_TURN ] = function( self, minigame )
                --     self.negotiator:RemoveModifier(self.id, self.stacks)
                -- end
            },
        },
    },
    advisor_hostile_talk_over_plus = {
        name = "Sticky Talk Over",
        flags = CARD_FLAGS.HOSTILE | CARD_FLAGS.STICKY | CARD_FLAGS.EXPEND,
    },
    advisor_hostile_talk_over_plus2 = {
        name = "Boosted Talk Over",
        desc = "Prevent the next <#UPGRADE>three sources</> of damage dealt to any of your arguments.",
        count = 3,
        cost = 2,
    },
    advisor_hostile_ivory_tower =
    {
        name = "Ivory Tower",
        desc = "Create: At the end of your turn, apply {1} {COMPOSURE} to all your arguments. Gain 1 bonus resolve for every {2#money} you have.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, AutoUpgradeText(self, "count"), self.money_divisor)
        end,
        flavour = "'Your opinion would've matter a lot more if you aren't poor.'",
        icon = "DEMOCRATICRACE:assets/cards/ivory_tower.png",

        advisor = "ADVISOR_HOSTILE",
        flags = CARD_FLAGS.HOSTILE,
        cost = 1,

        count = 2,
        money_divisor = 50,

        modifier =
        {
            icon = "DEMOCRATICRACE:assets/modifiers/ivory_tower.png",
            modifier_type = MODIFIER_TYPE.ARGUMENT,
            max_resolve = 1,
            desc = "This argument has 1 bonus resolve for every {2#money} you have. At the end of your turn, apply {1} composure to all your arguments.",
            desc_fn = function(self, fmt_str)
                return loc.format(fmt_str, self.stacks or 1, self.money_divisor)
            end,

            money_divisor = 50,
            OnInit = function(self)
                self:ModifyResolve(math.floor(self.engine:GetMoney() / self.money_divisor), self)
            end,
            OnEndTurn = function(self, minigame)
                local targets = minigame:CollectAlliedTargets(self.negotiator)
                for i,target in ipairs(targets) do
                    target:DeltaComposure(self.stacks or 1, self)
                end
            end,
        },
        OnPostResolve = function( self, minigame, targets )
            self.negotiator:CreateModifier("advisor_hostile_ivory_tower", self.count)
            -- if self.card_draw and self.card_draw > 0 then
            --     minigame:DrawCards( self.card_draw )
            -- end
        end,
    },
    advisor_hostile_ivory_tower_plus =
    {
        name = "Stone Ivory Tower",
        count = 3,
    },
    advisor_hostile_ivory_tower_plus2 =
    {
        name = "Initial Ivory Tower",
        flags = CARD_FLAGS.HOSTILE | CARD_FLAGS.AMBUSH,
    },
    advisor_hostile_duckspeak =
    {
        name = "Duckspeak",
        desc = "Choose a card from your hand that costs X. Create a {advisor_hostile_duckspeak} and {IMPRINT} that card onto it.",
        flavour = "'You keep saying that. I don't think you know what it means.'\n'Who cares? You know I'm right.'",
        icon = "DEMOCRATICRACE:assets/cards/duckspeak.png",

        loc_strings =
        {
            CHOOSE_IMPRINT = "Choose a card to <b>Imprint</>",
        },

        advisor = "ADVISOR_HOSTILE",
        flags = CARD_FLAGS.HOSTILE | CARD_FLAGS.EXPEND | CARD_FLAGS.VARIABLE_COST,
        cost = 0,

        OnPostResolve = function( self, minigame, targets )
            local chosen_card = minigame:ChooseCard(
                function(card)
                    if card:IsFlagged(CARD_FLAGS.VARIABLE_COST) then
                        return false
                    end
                    if minigame:CalculateActionCost(card) > minigame:GetActionCount() then
                        return false
                    end
                    return true
                end,
                self.def:GetLocalizedString("CHOOSE_IMPRINT")
            )

            if chosen_card then
                minigame:ModifyActionCount(-minigame:CalculateActionCost(chosen_card))

                local mod = Negotiation.Modifier( "advisor_hostile_duckspeak", self.negotiator )
                mod.imprinted_card = chosen_card
                self.negotiator:CreateModifier( mod )

                chosen_card:RemoveCard()

                self.engine:BroadcastEvent( EVENT.CARD_STOLEN, chosen_card, mod )
            end

        end,

        modifier = {
            desc = "At the end of your turn, play the card imprinted for free.\n\nIf the imprinted card moves to anywhere other than the discard, remove this argument and return the imprinted card to play.\n\nWhen this argument is removed, return the imprinted card to your discard.",
            desc_fn = function(self, fmt_str, minigame, widget)
                if widget and widget.PostCard and self.imprinted_card then
                    widget:PostCard( self.imprinted_card.id, self.imprinted_card, minigame )
                end
                return fmt_str
            end,
            icon = "DEMOCRATICRACE:assets/modifiers/duckspeak.png",

            modifier_type = MODIFIER_TYPE.ARGUMENT,
            max_resolve = 3,

            OnEndTurn = function(self, minigame)
                if self.imprinted_card then
                    self.imprinted_card.show_dealt = false
                    minigame.discard_deck:InsertCard( self.imprinted_card )
                    minigame:PlayCard(self.imprinted_card)
                    if self.imprinted_card.deck == minigame.discard_deck then
                        self.imprinted_card:RemoveCard()
                    else
                        self.negotiator:RemoveModifier(self)
                    end
                else
                    self.negotiator:RemoveModifier(self)
                end
            end,
            OnUnapply = function ( self )
                if self.imprinted_card and not self.imprinted_card.deck and self.engine then
                    self.engine.discard_deck:InsertCard(self.imprinted_card)
                end
            end,
        },
    },
    advisor_hostile_duckspeak_plus =
    {
        name = "Initial Duckspeak",
        flags = CARD_FLAGS.HOSTILE | CARD_FLAGS.EXPEND | CARD_FLAGS.VARIABLE_COST | CARD_FLAGS.AMBUSH,
    },
    advisor_hostile_duckspeak_plus2 =
    {
        name = "Enduring Duckspeak",
        flags = CARD_FLAGS.HOSTILE | CARD_FLAGS.VARIABLE_COST,
    },
    advisor_hostile_whataboutism =
    {
        name = "Whataboutism",
        desc = "Gain {1} {advisor_hostile_whataboutism}.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, AutoUpgradeText(self, "gain_count"))
        end,
        flavour = "'You claim that exploiting my workers is bad, but have you considered the violent act of the Rise ten years ago?'",
        icon = "DEMOCRATICRACE:assets/cards/whataboutism.png",

        advisor = "ADVISOR_HOSTILE",
        flags = CARD_FLAGS.HOSTILE | CARD_FLAGS.EXPEND,
        cost = 1,

        gain_count = 2,

        OnPostResolve = function(self)
            self.negotiator:AddModifier("advisor_hostile_whataboutism", self.gain_count, self)
        end,
        modifier =
        {

            desc = "Whenever one of your arguments is destroyed, deal {1} damage to a random opponent argument.\n\nWhen an opponent argument is destroyed, gain 1 stacks.",
            alt_desc = "Whenever one of your arguments is destroyed, deal damage equal to the number of stacks of this argument to a random opponent argument.\n\nWhen an opponent argument is destroyed, gain 1 stacks.",
            desc_fn = function(self, fmt_str)
                if not self.stacks then
                    return loc.format((self.def or self):GetLocalizedString("ALT_DESC"))
                end
                return loc.format(fmt_str, self.stacks)
            end,
            icon = "DEMOCRATICRACE:assets/modifiers/whataboutism.png",

            modifier_type = MODIFIER_TYPE.ARGUMENT,
            max_resolve = 4,

            event_handlers =
            {
                [ EVENT.MODIFIER_REMOVED ] = function( self, modifier, source )
                    if modifier.stacks > 0 then
                        if modifier.negotiator == self.negotiator then
                            self.target_enemy = TARGET_ANY_RESOLVE
                            self.engine:ApplyPersuasion( self, nil, self.stacks, self.stacks )
                            self.target_enemy = nil
                        else
                            self.negotiator:AddModifier(self, 1, self)
                        end
                    end
                end,
            },
        },
    },
    advisor_hostile_whataboutism_plus =
    {
        name = "Enduring Whataboutism",
        flags = CARD_FLAGS.HOSTILE,
    },
    advisor_hostile_whataboutism_plus2 =
    {
        name = "Initial Whataboutism",
        flags = CARD_FLAGS.HOSTILE | CARD_FLAGS.EXPEND | CARD_FLAGS.AMBUSH,
    },
    advisor_hostile_incoherent_rambling =
    {
        name = "Incoherent Rambling",
        desc = "Attack twice.\nGain {1} {VULNERABILITY}",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, AutoUpgradeText(self, "gain_stacks", true))
        end,
        flavour = "'Why say a few words when a lot do the trick?'",
        icon = "DEMOCRATICRACE:assets/cards/incoherent_rambling.png",

        advisor = "ADVISOR_HOSTILE",
        flags = CARD_FLAGS.HOSTILE,
        cost = 1,

        min_persuasion = 3,
        max_persuasion = 3,

        gain_stacks = 2,

        OnPostResolve = function( self, minigame, targets )
            minigame:ApplyPersuasion(self)
            self.negotiator:DeltaModifier("VULNERABILITY", self.gain_stacks, self)
        end,
    },
    advisor_hostile_incoherent_rambling_plus =
    {
        name = "Boosted Incoherent Rambling",
        min_persuasion = 4,
        max_persuasion = 4,
    },
    advisor_hostile_incoherent_rambling_plus2 =
    {
        name = "Slightly Incoherent Rambling",
        gain_stacks = 1,
    },
}

for i, id, def in sorted_pairs( CARDS ) do
    if not def.series then
        def.series = CARD_SERIES.GENERAL
    end
    if not def.rarity then
        def.rarity = CARD_RARITY.UNIQUE
    end
    if not def.shop_price then
        def.shop_price = 210
    end
    Content.AddNegotiationCard( id, def )
end
