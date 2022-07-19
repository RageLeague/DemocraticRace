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
        desc = "{1}'s attacks deal {2} bonus damage",
    },
    ETIQUETTE_EFFECT_FLAT_DAMAGE =
    {
        desc = "<b>Etiquette</> deal {1} damage to a random opponent argument",
    },
    ETIQUETTE_EFFECT_DISCARD =
    {
        desc = "discard {1*a card|{1} cards}",
    },
    ETIQUETTE_EFFECT_DESTROY_ARGUMENT =
    {
        desc = "destroy one of your non-core arguments",
    },
    ETIQUETTE_EFFECT_FLUSTER =
    {
        desc = "{INCEPT} {1} {FLUSTERED}",
    },
    ETIQUETTE_EFFECT_RESTORE_RESOLVE =
    {
        desc = "restore {1} resolve to <b>Etiquette</>",
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
            if modifier_def and (not modifier_def.spawn_condition or modifier_def:spawn_condition(self)) then
                self.linked_effect = self.negotiator:CreateModifier( chosen, 1, self )
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
}
local TRIGGERS =
{
    ETIQUETTE_TRIGGER_CARDS =
    {
        desc = "Whenever you play {1} {1*card|cards} this turn, {2}. Reset count when triggered.",
    },
    ETIQUETTE_TRIGGER_MATCHING =
    {
        desc = "Whenever you play {1} {1*card|cards} of the same type in a row, {2}.",
    },
    ETIQUETTE_TRIGGER_DESTROY_ARGUMENT =
    {
        desc = "Whenever you destroy one of {1}'s arguments, {2}.",
    },
    ETIQUETTE_TRIGGER_COMPOSURE_TARGET =
    {
        desc = "Whenever you use a card to attack an argument with at least {1} {COMPOSURE}, {2}.",
    },
    ETIQUETTE_TRIGGER_CARD_DRAW =
    {
        desc = "Whenever you draw {1} or more cards this turn, {2}. Reset count when triggered.",
    },
    ETIQUETTE_TRIGGER_CARD_LEFT =
    {
        desc = "At the end of your turn, for every {1*card|{1} cards} left in your hand, {2}.",
    },
    ETIQUETTE_TRIGGER_DIPLOMACY =
    {
        desc = "Whenever you play {1} Diplomacy {1*card|cards} this turn, {2}. Reset count when triggered.",
    },
    ETIQUETTE_TRIGGER_MANIPULATE =
    {
        desc = "Whenever you play {1} Manipulate {1*card|cards} this turn, {2}. Reset count when triggered.",
    },
    ETIQUETTE_TRIGGER_HOSTILE =
    {
        desc = "Whenever you play {1} Hostile {1*card|cards} this turn, {2}. Reset count when triggered.",
    },
    ETIQUETTE_TRIGGER_ITEM =
    {
        desc = "Whenever you play {1} Item {1*card|cards} this turn, {2}. Reset count when triggered.",
    },
}
for id, def in pairs( TRIGGERS ) do
    Content.AddNegotiationModifier( id, table.extend(TRIGGER_BASE)(def) )
end

Content.AddNegotiationModifier("ETIQUETTE", {
    name = "Etiquette",
    desc = "At the beginning of your turn, the rule text for <b>Etiquette</> changes.",

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
        return (self.def or self):GetLocalizedString("ALT_DESC")
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
            if modifier_def and (not modifier_def.spawn_condition or modifier_def:spawn_condition(self)) then
                self.linked_effect = self.negotiator:CreateModifier( chosen, 1, self )
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
})

-- Expose effects and conditions so other things can access it. Not that it matters that much
return {
    EFFECTS = EFFECTS,
    TRIGGERS = TRIGGERS
}
