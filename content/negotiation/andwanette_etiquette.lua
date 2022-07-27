local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT

local EFFECT_BASE =
{
    hidden = true,
}
local EFFECTS =
{
    ETIQUETTE_EFFECT_BONUS_DAMAGE =
    {
        desc = "{1}'s attacks deal {2} bonus damage while this rule is in effect",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:GetOwnerName(), self.damage_bonus)
        end,

        damage_bonus = 2,
        damage_scale = {2, 3, 3, 4},

        OnInit = function(self)
            self.damage_bonus = DemocracyUtil.CalculateBossScale(self.damage_scale)
        end,

        OnEffectTriggered = function(self)
            self.triggered_count = (self.triggered_count or 0) + 1
        end,

        event_priorities =
        {
            [ EVENT.CALC_PERSUASION ] = EVENT_PRIORITY_ADDITIVE,
        },

        event_handlers =
        {
            [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion, minigame, target )
                if source.negotiator == self.negotiator and self.triggered_count then
                    persuasion:ModifyPersuasion(self.damage_bonus * self.triggered_count, self.damage_bonus * self.triggered_count, self)
                end
            end,
        },
    },
    ETIQUETTE_EFFECT_FLAT_DAMAGE =
    {
        desc = "<b>Etiquette</> deal {1} damage to a random opponent argument",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.damage_bonus)
        end,

        damage_bonus = 5,
        damage_scale = {3, 5, 5, 8},

        OnInit = function(self)
            self.damage_bonus = DemocracyUtil.CalculateBossScale(self.damage_scale)
        end,

        target_enemy = TARGET_ANY_RESOLVE,

        OnEffectTriggered = function(self)
            local source = self.linked_core or self
            local targets = self.engine:CollectAllTargets(self)
            local target = table.arraypick( targets )
            if target then
                self.engine:ApplyPersuasion( source, target, self.damage_bonus, self.damage_bonus )
            end
        end,
    },
    ETIQUETTE_EFFECT_DISCARD =
    {
        desc = "discard {1*a card|{1} cards}",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.discard_count)
        end,

        discard_count = 1,
        discard_scale = {1, 1, 1, 2},

        OnInit = function(self)
            self.discard_count = DemocracyUtil.CalculateBossScale(self.discard_scale)
        end,

        OnEffectTriggered = function(self)
            for i = 1, self.discard_count do
                local card = self.engine:GetHandDeck():PeekRandom()
                if card then
                    self.engine:DiscardCard( card )
                end
            end
        end,
    },
    ETIQUETTE_EFFECT_DESTROY_ARGUMENT =
    {
        desc = "destroy one of your non-core arguments",
        target_enemy = TARGET_FLAG.ARGUMENT | TARGET_FLAG.BOUNTY,

        OnEffectTriggered = function(self)
            local source = self.linked_core or self
            local targets = self.engine:CollectAllTargets(self)
            local target = table.arraypick( targets )
            if target then
                self.anti_negotiator:DestroyModifier( target, source )
            end
        end,
    },
    ETIQUETTE_EFFECT_FLUSTER =
    {
        desc = "{INCEPT} {1} {FLUSTERED}",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.flustered_count)
        end,

        flustered_count = 1,
        flustered_scale = {1, 1, 1, 2},

        OnInit = function(self)
            self.flustered_count = DemocracyUtil.CalculateBossScale(self.flustered_scale)
        end,

        OnEffectTriggered = function(self)
            local source = self.linked_core or self
            self.anti_negotiator:InceptModifier("FLUSTERED", self.flustered_count, source)
        end,
    },
    ETIQUETTE_EFFECT_RESTORE_RESOLVE =
    {
        desc = "<b>Etiquette</> gains {1} resolve",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.heal_count)
        end,

        heal_count = 8,
        heal_scale = {6, 8, 8, 10},

        OnInit = function(self)
            self.heal_count = DemocracyUtil.CalculateBossScale(self.heal_scale)
        end,

        OnEffectTriggered = function(self)
            local source = self.linked_core or self
            if self.linked_core then
                self.linked_core:ModifyResolve(self.heal_count, source)
            end
        end,
    },
    ETIQUETTE_EFFECT_SHIELD =
    {
        desc = "{SHIELDED|Shield} a random unshielded argument {1} has until the start of {1}'s turn",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:GetOwnerName())
        end,
        loc_strings =
        {
            SHELL_DEFENSE_DESC = "{SHIELDED}. This argument is shielded until the start of {1}'s turn!",
        },

        target_self = TARGET_ANY_RESOLVE,

        OnEffectTriggered = function(self)
            local source = self.linked_core or self
            local targets = self.engine:CollectAllTargets(self)
            while #targets > 0 do
                local target = table.arraypick( targets )
                table.arrayremove(targets, target)
                if target and not target:GetShieldStatus() then
                    self.shielded_arguments = self.shielded_arguments or {}
                    table.insert(self.shielded_arguments, target)
                    target:SetShieldStatus( true, loc.format(self.def:GetLocalizedString("SHELL_DEFENSE_DESC"), self:GetOwnerName()) )
                    return
                end
            end
        end,

        ClearShields = function(self)
            if self.shielded_arguments then
                for i, target in ipairs(self.shielded_arguments) do
                    if target:IsApplied() then
                        target:SetShieldStatus(false)
                    end
                end
            end
            self.shielded_arguments = nil
        end,

        OnBeginTurn = function(self)
            self:ClearShields()
        end,

        OnUnapply = function(self)
            self:ClearShields()
        end,
    },
}
for id, def in pairs( EFFECTS ) do
    Content.AddNegotiationModifier( id, table.extend(EFFECT_BASE)(def) )
end

local TRIGGER_BASE =
{
    hidden = true,
    alt_desc = "something bad happens",
    GetEffectDesc = function(self, ...)
        if self.linked_effect then
            local effect = self.linked_effect
            local desc
            if effect.def then
                desc = effect.def:GetLocalizedDesc()
            end

            if effect.desc_fn then
                desc = effect:desc_fn(desc, ...)
            elseif desc == nil then
                desc = effect.desc
            end
            return desc
        end
        return (self.def or self):GetLocalizedString("ALT_DESC")
    end,
    GenerateEffect = function(self)
        if self.linked_effect then
            return
        end
        local choices = copykeys(EFFECTS)
        while #choices > 0 do
            local chosen = table.arraypick(choices)
            table.arrayremove(choices, chosen)
            local modifier_def = Content.GetNegotiationModifier(chosen)
            if modifier_def and (not modifier_def.spawn_condition or modifier_def:spawn_condition(self.engine, self)) then
                self.linked_effect = self.negotiator:CreateModifier( chosen, 1, self )
                self.linked_effect.linked_core = self.linked_core
                return
            end
        end
        print("Fail to generate effect")
    end,
    OnApply = function(self)
        self:GenerateEffect()
    end,
    UnlinkEffect = function(self)
        if not self.linked_effect then
            return
        end
        self.negotiator:RemoveModifier(self.linked_effect, nil, self)
        self.linked_effect = nil
    end,
    OnUnapply = function(self)
        self:UnlinkEffect()
    end,
    TriggerEffect = function(self)
        if self.linked_effect and self.linked_effect.OnEffectTriggered then
            self.linked_effect:OnEffectTriggered()
        end
        if self.linked_core then
            self.linked_core:NotifyTriggered()
        end
    end,
}
local TRIGGERS =
{
    ETIQUETTE_TRIGGER_CARDS =
    {
        desc = "Whenever you play {1} {1*card|cards} this turn, {2}. Reset count when triggered.",
        loc_strings =
        {
            CARDS_REMAINING = "({1} {1*card|cards} remaining)",
        },
        desc_fn = function(self, fmt_str, ...)
            if self.cards_played then
                return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...)) .. "\n\n" .. loc.format((self.def or self):GetLocalizedString("CARDS_REMAINING"), self.card_count - self.cards_played)
            end
            return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...))
        end,

        card_count = 6,
        card_scale = {6, 6, 4, 4},

        OnInit = function(self)
            self.card_count = DemocracyUtil.CalculateBossScale(self.card_scale)
        end,

        event_handlers =
        {
            [ EVENT.POST_RESOLVE ] = function( self, minigame, card )
                if card.negotiator == self.anti_negotiator then
                    self.cards_played = (self.cards_played or 0) + 1
                    if self.cards_played >= self.card_count then
                        self.cards_played = 0
                        self:TriggerEffect()
                    end
                end
            end,
        },
    },
    ETIQUETTE_TRIGGER_MATCHING =
    {
        desc = "Whenever you play {1} {1*card|cards} of the same type in a row, {2}. Reset count when triggered.",
        loc_strings =
        {
            CARDS_REMAINING = "({1} {2} {1*card|cards} remaining)",
        },
        desc_fn = function(self, fmt_str, ...)
            if self.cards_played then
                return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...)) .. "\n\n" .. loc.format((self.def or self):GetLocalizedString("CARDS_REMAINING"), self.card_count - self.cards_played, GetCardTypeString( self.chained_type ))
            end
            return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...))
        end,

        card_count = 3,
        card_scale = {3, 3, 2, 2},

        OnInit = function(self)
            self.card_count = DemocracyUtil.CalculateBossScale(self.card_scale)
        end,

        event_handlers =
        {
            [ EVENT.POST_RESOLVE ] = function( self, minigame, card )
                if card.negotiator == self.anti_negotiator then
                    local card_type = GetCardType( card )
                    if self.chained_type == card_type then
                        self.cards_played = (self.cards_played or 0) + 1
                        if self.cards_played >= self.card_count then
                            self.cards_played = 0
                            self:TriggerEffect()
                        end
                    else
                        self.chained_type = card_type
                        self.cards_played = 1
                    end
                end
            end,
        },
    },
    ETIQUETTE_TRIGGER_DESTROY_ARGUMENT =
    {
        desc = "Whenever you destroy one of {1}'s arguments, {2}.",
        desc_fn = function(self, fmt_str, ...)
            return loc.format(fmt_str, self:GetOwnerName(), self:GetEffectDesc(...))
        end,

        event_handlers =
        {
            [ EVENT.MODIFIER_REMOVED ] = function( self, modifier, card )
                if modifier.negotiator == self.negotiator and card and card.negotiator == self.anti_negotiator and modifier.resolve and modifier.stacks > 0 then
                    self:TriggerEffect()
                end
            end,
        },
    },
    ETIQUETTE_TRIGGER_CARD_DRAW =
    {
        desc = "Whenever you draw {1} cards this turn after the initial draw, {2}.{1*| Reset count when triggered.}",
        loc_strings =
        {
            CARDS_REMAINING = "({1} {1*card|cards} remaining)",
        },
        desc_fn = function(self, fmt_str, ...)
            if self.cards_played then
                return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...)) .. "\n\n" .. loc.format((self.def or self):GetLocalizedString("CARDS_REMAINING"), self.card_count - self.cards_played)
            end
            return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...))
        end,

        card_count = 2,
        card_scale = {4, 4, 3, 3},

        OnInit = function(self)
            self.card_count = DemocracyUtil.CalculateBossScale(self.card_scale)
        end,

        event_handlers =
        {
            [ EVENT.DRAW_CARD ] = function( self, minigame, card, start_of_turn )
                if card.negotiator == self.anti_negotiator and not start_of_turn then
                    self.cards_played = (self.cards_played or 0) + 1
                    if self.cards_played >= self.card_count then
                        self.cards_played = 0
                        self:TriggerEffect()
                    end
                end
            end,
        },
    },
    ETIQUETTE_TRIGGER_CARD_LEFT =
    {
        desc = "At the end of your turn, for every {1*card|{1} cards} left in your hand, {2}.",
        desc_fn = function(self, fmt_str, ...)
            return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...))
        end,

        card_count = 3,
        card_scale = {3, 3, 2, 2},

        OnInit = function(self)
            self.card_count = DemocracyUtil.CalculateBossScale(self.card_scale)
        end,

        event_handlers =
        {
            [ EVENT.END_PLAYER_TURN ] = function( self, minigame )
                local count = 0
                for i, card in minigame:GetHandDeck():Cards() do
                    count = count + 1
                end
                local trigger_count = math.floor(count / self.card_count)
                for i = 1, trigger_count do
                    self:TriggerEffect()
                end
            end
        },
    },
    ETIQUETTE_TRIGGER_DIPLOMACY =
    {
        desc = "Whenever you play {1} Diplomacy {1*card|cards} this turn, {2}. Reset count when triggered.",
        loc_strings =
        {
            CARDS_REMAINING = "({1} {1*card|cards} remaining)",
        },
        desc_fn = function(self, fmt_str, ...)
            if self.cards_played then
                return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...)) .. "\n\n" .. loc.format((self.def or self):GetLocalizedString("CARDS_REMAINING"), self.card_count - self.cards_played)
            end
            return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...))
        end,

        card_count = 3,
        card_scale = {3, 3, 2, 2},

        required_type = CARD_FLAGS.DIPLOMACY,

        OnInit = function(self)
            self.card_count = DemocracyUtil.CalculateBossScale(self.card_scale)
        end,

        event_handlers =
        {
            [ EVENT.POST_RESOLVE ] = function( self, minigame, card )
                if card.negotiator == self.anti_negotiator and CheckBits( card.flags, self.required_type ) then
                    self.cards_played = (self.cards_played or 0) + 1
                    if self.cards_played >= self.card_count then
                        self.cards_played = 0
                        self:TriggerEffect()
                    end
                end
            end,
        },
    },
    ETIQUETTE_TRIGGER_MANIPULATE =
    {
        desc = "Whenever you play {1} Manipulate {1*card|cards} this turn, {2}. Reset count when triggered.",
        loc_strings =
        {
            CARDS_REMAINING = "({1} {1*card|cards} remaining)",
        },
        desc_fn = function(self, fmt_str, ...)
            if self.cards_played then
                return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...)) .. "\n\n" .. loc.format((self.def or self):GetLocalizedString("CARDS_REMAINING"), self.card_count - self.cards_played)
            end
            return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...))
        end,

        card_count = 3,
        card_scale = {3, 3, 2, 2},

        required_type = CARD_FLAGS.MANIPULATE,

        OnInit = function(self)
            self.card_count = DemocracyUtil.CalculateBossScale(self.card_scale)
        end,

        event_handlers =
        {
            [ EVENT.POST_RESOLVE ] = function( self, minigame, card )
                if card.negotiator == self.anti_negotiator and CheckBits( card.flags, self.required_type ) then
                    self.cards_played = (self.cards_played or 0) + 1
                    if self.cards_played >= self.card_count then
                        self.cards_played = 0
                        self:TriggerEffect()
                    end
                end
            end,
        },
    },
    ETIQUETTE_TRIGGER_HOSTILE =
    {
        desc = "Whenever you play {1} Hostility {1*card|cards} this turn, {2}. Reset count when triggered.",
        loc_strings =
        {
            CARDS_REMAINING = "({1} {1*card|cards} remaining)",
        },
        desc_fn = function(self, fmt_str, ...)
            if self.cards_played then
                return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...)) .. "\n\n" .. loc.format((self.def or self):GetLocalizedString("CARDS_REMAINING"), self.card_count - self.cards_played)
            end
            return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...))
        end,

        card_count = 3,
        card_scale = {3, 3, 2, 2},

        required_type = CARD_FLAGS.HOSTILE,

        OnInit = function(self)
            self.card_count = DemocracyUtil.CalculateBossScale(self.card_scale)
        end,

        event_handlers =
        {
            [ EVENT.POST_RESOLVE ] = function( self, minigame, card )
                if card.negotiator == self.anti_negotiator and CheckBits( card.flags, self.required_type ) then
                    self.cards_played = (self.cards_played or 0) + 1
                    if self.cards_played >= self.card_count then
                        self.cards_played = 0
                        self:TriggerEffect()
                    end
                end
            end,
        },
    },
    ETIQUETTE_TRIGGER_ITEM =
    {
        desc = "Whenever you play {1} Item {1*card|cards} this turn, {2}.{1*| Reset count when triggered.}",
        loc_strings =
        {
            CARDS_REMAINING = "({1} {1*card|cards} remaining)",
        },
        desc_fn = function(self, fmt_str, ...)
            if self.cards_played then
                return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...)) .. "\n\n" .. loc.format((self.def or self):GetLocalizedString("CARDS_REMAINING"), self.card_count - self.cards_played)
            end
            return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...))
        end,

        card_count = 2,
        card_scale = {2, 2, 1, 1},

        required_type = CARD_FLAGS.ITEM,

        OnInit = function(self)
            self.card_count = DemocracyUtil.CalculateBossScale(self.card_scale)
        end,

        event_handlers =
        {
            [ EVENT.POST_RESOLVE ] = function( self, minigame, card )
                if card.negotiator == self.anti_negotiator and CheckBits( card.flags, self.required_type ) then
                    self.cards_played = (self.cards_played or 0) + 1
                    if self.cards_played >= self.card_count then
                        self.cards_played = 0
                        self:TriggerEffect()
                    end
                end
            end,
        },
    },
    ETIQUETTE_TRIGGER_FOCUS_ATTACK =
    {
        desc = "Whenever you use cards to attack the same argument {1} times in a row, {2}. Reset count when triggered.",
        loc_strings =
        {
            CARDS_REMAINING = "({1} {1*attack|attacks} targeting {2} remaining)",
        },
        desc_fn = function(self, fmt_str, ...)
            if self.cards_played and self.tracked_argument then
                return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...)) .. "\n\n" .. loc.format((self.def or self):GetLocalizedString("CARDS_REMAINING"), self.card_count - self.cards_played, self.tracked_argument:GetName())
            end
            return loc.format(fmt_str, self.card_count, self:GetEffectDesc(...))
        end,

        card_count = 4,
        card_scale = {4, 4, 3, 3},

        OnInit = function(self)
            self.card_count = DemocracyUtil.CalculateBossScale(self.card_scale)
        end,

        event_handlers =
        {
            [ EVENT.ATTACK_RESOLVE ] = function( self, source, target, damage, params, defended )
                if source and source.negotiator == self.anti_negotiator and is_instance( source, Negotiation.Card ) then
                    if target and target == self.tracked_argument then
                        self.cards_played = (self.cards_played or 0) + 1
                        if self.cards_played >= self.card_count then
                            self.cards_played = nil
                            self.tracked_argument = nil
                            self:TriggerEffect()
                        end
                    else
                        self.cards_played = 1
                        self.tracked_argument = target
                    end
                end
            end,
            [ EVENT.MODIFIER_REMOVED ] = function( self, modifier, source )
                if self.tracked_argument and modifier == self.tracked_argument then
                    self.cards_played = nil
                    self.tracked_argument = nil
                end
            end,
        },
    },
}
for id, def in pairs( TRIGGERS ) do
    Content.AddNegotiationModifier( id, table.extend(TRIGGER_BASE)(def) )
end

Content.AddNegotiationModifier("ETIQUETTE", {
    name = "Etiquette",
    desc = "At the beginning of your turn, the rule text for <b>Etiquette</> changes.",
    desc_fn = function(self, fmt_str, ...)
        if self.linked_effect then
            return fmt_str .. "\n\n" .. self:GetEffectDesc(...)
        end
        return fmt_str
    end,
    icon = "DEMOCRATICRACE:assets/modifiers/etiquette.png",

    modifier_type = MODIFIER_TYPE.CORE,
    GetEffectDesc = function(self, ...)
        if self.linked_effect then
            local effect = self.linked_effect
            local desc
            if effect.def then
                desc = effect.def:GetLocalizedDesc()
            end

            if effect.desc_fn then
                desc = effect:desc_fn(desc, ...)
            elseif desc == nil then
                desc = effect.desc
            end
            return desc
        end
    end,
    GenerateEffect = function(self)
        if self.linked_effect then
            return
        end
        local choices = copykeys(TRIGGERS)
        while #choices > 0 do
            local chosen = table.arraypick(choices)
            table.arrayremove(choices, chosen)
            local modifier_def = Content.GetNegotiationModifier(chosen)
            if modifier_def and (not modifier_def.spawn_condition or modifier_def:spawn_condition(self.engine, self)) then
                self.linked_effect = self.negotiator:CreateModifier( chosen, 1, self )
                self.linked_effect.linked_core = self
                return
            end
        end
        print("Fail to generate effect")
    end,
    UnlinkEffect = function(self)
        if not self.linked_effect then
            return
        end
        self.negotiator:RemoveModifier(self.linked_effect, nil, self)
        self.linked_effect = nil
    end,
    OnUnapply = function(self)
        self:UnlinkEffect()
    end,
    event_handlers =
    {
        [ EVENT.BEGIN_PLAYER_TURN ] = function ( self, minigame )
            self:UnlinkEffect()
            self:GenerateEffect()
            self:NotifyTriggered()
        end,
    },
})

-- Expose effects and conditions so other things can access it. Not that it matters that much
return {
    EFFECTS = EFFECTS,
    TRIGGERS = TRIGGERS
}
