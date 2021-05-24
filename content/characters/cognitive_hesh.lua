-- Want to make Hesh its own gender and let it have a bunch of pronouns specifically for Hesh,
-- but there would be just too much work for very little effect.

Content.AddCharacterDef
(
    CharacterDef("COGNITIVE_HESH",
    {
        base_def = "MONSTER",
        name = "Hesh of the Dark",
        title = "Transgenus Deity",
        -- Can't figure this out.
        build = "luminthian",
        head = "head_luminari",

        gender = GENDER.UNDISCLOSED, -- GENDER.UNDISCLOSED,

        combat_strength = 3,
        boss = true,

        unique = true,
        
        death_money = 0,

        negotiation_data =
        {
            behaviour =
            {
                OnInit = function( self, difficulty )
                    --self.negotiator:AddModifier( "GRIFTER" )
                end,
            }
        },
    })
)

Content.GetCharacterDef("COGNITIVE_HESH"):InheritBaseDef()