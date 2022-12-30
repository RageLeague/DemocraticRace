Content.AddCharacterDef
(
    CharacterDef("DEM_MUTANT_BOG_MONSTER",
    {
        base_def = "DRUSK_1",
        name = "Bog Mutant",
        shorttitle = "",
        -- head = "head_female_guard_corporal",
        build = "drusk_01",
        title = "Shambling Abomination",
        gender = GENDER.UNDISCLOSED,
        species = SPECIES.BEAST,
        death_item = "dem_random_rare_parasite",

        loc_strings =
        {
            TWIN_BOSS_PREVIEW_NAMES = "Bog Mutant",
            TWIN_BOSS_PREVIEW_TITLE = "Shambling Abomination",
        },

        fight_data =
        {
            MAX_HEALTH = 120,
            MAX_MORALE = MAX_MORALE_LOOKUP.IMMUNE,
            status_widget_dx = 0.5,
            status_widget_dy = -0.95,

            anim_mapping =
            {
                splat = "splort",
            },

            behaviour =
            {
                OnActivate = function( self )
                    self.attacks = self:MakePicker()
                        :AddID( "drusk_01_splort", 1 )
                        :AddID( "drusk_02_attack1", 1 )
                        :AddID( "drusk_01_stab", 2 )
                        :AddID( "drusk_01_taunt", 2 )
                    self:SetPattern( self.Cycle )
                end,

                Cycle = function( self )
                    self.attacks:ChooseCard()
                end,

            }
        },
    })
)

Content.GetCharacterDef("DEM_MUTANT_BOG_MONSTER"):InheritBaseDef()
