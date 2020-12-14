local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT

local CARDS = {
    advisor_diplomacy_relatable = 
    {
        name = "Relatable",
        desc = "Gain bonus damage equal to half your {INFLUENCE}, rounded up.\nGain {1} {INFLUENCE}.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, AutoUpgradeText(self, "influence_gain"))
        end,
        flavour = "'Being relatable to your target is important to gain their trust, remember that. That's why you should use hip languages around others.'",
        
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
        }
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
    advisor_manipulate_straw_army = 
    {
        name = "Straw Army",
        desc = "{INCEPT} {1} separate {straw_man} arguments.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, AutoUpgradeText(self, "strawman_count"))
        end,
        flavour = "'You know the straw man arguments, the ones that the Barons likes to use? We're better than that.'",
        
        advisor = "ADVISOR_MANIPULATE",
        flags = CARD_FLAGS.MANIPULATE,
        cost = 2,

        strawman_count = 3,

        OnPostResolve = function( self, minigame )
            for i = 1, self.strawman_count do
                self.anti_negotiator:AddModifier( "straw_man", 1, self )
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
}

for i, id, def in sorted_pairs( CARDS ) do
    if not def.series then
        def.series = CARD_SERIES.GENERAL
    end
    if not def.rarity then
        def.rarity = CARD_RARITY.UNIQUE
    end
    Content.AddNegotiationCard( id, def )
end