local chars =
{
    CharacterDef("ADVISOR_DIPLOMACY",
    {
        base_def = "SPARK_BARON_TASKMASTER",
        bio = "Aellon is not sure what the word \"based\" means as an adjective, but it sounds hip and cool to him, and that's good enough for him to use it everywhere.",
        name = "Aellon",
        nickname = "*The Based",

        loved_bio = "To this day, Aellon still hasn't figured out what \"based\" means as an adjective, but he would describe it as an adjective that applies to you.",
        hated_bio = "While Aellon doesn't know what \"based\" means as an adjective, he certainly figured out the meaning of the word \"cringe\", and you won't like it.",

        tags = {"advisor", "advisor_diplomacy"},
        gender = "MALE",
        species = "HUMAN",

        theme_music = "DEMOCRATICRACE|event:/democratic_race/music/story/aellon_theme",

        build = "male_clust_trademaster",
        head = "head_male_shopkeep_002",

        hair_colour = 0xB55239FF,
        skin_colour = 0xF0B8A0FF,

        -- renown = 4,

        -- social_boons = table.empty,
            negotiation_data =
            {
                behaviour =
                {
                    OnInit = function( self )
                        local core = self.negotiator:AddModifier("RELATABLE")
						if GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ARGUMENT_PLUS ) then
							core.num_cards = 3
							core.count = 3
						end
                        self:SetPattern( self.BasicCycle )
                    end,
                    --this can be tweaked later, but for now I just copied it from dronumph because I am wumpus, and I don't understand half of this.
                    BasicCycle = function( self, turns )

                        if (turns-1) % 3 == 0 then
                            -- Double attack.
                            self:ChooseGrowingNumbers( 2, 0 )

                        else
                            -- Single attack.
                            self:ChooseGrowingNumbers( 1, 1 )
                        end
                    end,
                }
            },
    }),
    CharacterDef("ADVISOR_MANIPULATE",
    {
        base_def = "PRIEST",
        -- bio = "Your first mistake is listening to Benni. Your second mistake is believing in her.",
        bio = "Benni is different from other kra'deshi. No, it isn't because she has five fingers on each hand, but it is because she can convince you otherwise. Probably.",
        name = "Benni",
        -- title = "Priest",

        loved_bio = "Facts don't care about your feelings, but Benni does.",
        hated_bio = "Benni's facts and logic cannot predict your shear incompetence. Then again, her facts and logic works better as hindsights.",

        tags = {"advisor", "advisor_manipulate"},
        gender = "FEMALE",
        species = "KRADESHI",

        theme_music = "DEMOCRATICRACE|event:/democratic_race/music/story/benni_theme",
        -- theme_music = "event:/democratic_race/music/story/benni_theme",

        build = "female_benni_build",
        head = "head_female_kradeshi_13",

        skin_colour = 0xBEC867FF,

        -- renown = 4,

        -- social_boons = table.empty,
            negotiation_data =
            {
                behaviour =
                {
                    OnInit = function( self )
                        self.negotiator:AddModifier("LOGICAL")
                        self.facts = self:AddArgument( "FACTS" )
                        self.flawed_logic = self:AddArgument( "FLAWED_LOGIC" )
                        self:SetPattern( self.BasicCycle )
                    end,
                    BasicCycle = function( self, turns )

                        if (turns-1) % 3 == 0 then
                            -- Double attack.
                            self:ChooseGrowingNumbers( 2, 0, 1 )

                        else
                            -- Single attack.
                            self:ChooseGrowingNumbers( 1, 1, 1 )
                        end

                        if turns % 3 == 0 then
                            self:ChooseCard( self.flawed_logic )
                        end

                        if turns % 2 == 0 then
                            self:ChooseCard( self.facts )
                        end
                    end,
                }
            },
    }),
    CharacterDef("ADVISOR_HOSTILE",
    {
        base_def = "WEALTHY_MERCHANT",
        bio = "Dronumph thinks very highly of himself, which is totally understandable. You should've seen how many zeros are in his net worth, all of which are leading.",
        name = "Dronumph",

        loved_bio = "It's no doubt that Dronumph loves himself the most. There's no way to chance that due to his narcissistic nature. You however, comes quite close.",
        hated_bio = "Dronumph used to believe that he is the best at everything. Now, he learnt his mistake: his ability to recognize talent is certainly troubling, considering that he somehow trusted <b>you</>.",

        tags = {"advisor", "advisor_hostile"},
        gender = "MALE",
        species = "JARACKLE",

        theme_music = "DEMOCRATICRACE|event:/democratic_race/music/story/dronumph_theme",

        build = "male_phicket",
        head = "head_male_jarackle_bandit_02",

        -- Dronumph now has a new tan color
        skin_colour = 0xF9C771FF,--0xB8A792FF,

        -- renown = 4,

        -- We'll work on a proper negotiation later.
        negotiation_data =
        {
            behaviour =
            {
            --bandit, but decently stronger and can restore resolve by the barrel-full
                OnInit = function( self )
                    self.no_filter = self:AddArgument( "NO_FILTER" )
                    -- self.attacks = self:MakePicker()
                    -- self.brag = self:AddArgument( "BRAG" )
                    self.fragile_ego = self:AddArgument( "FRAGILE_EGO" )
                    self.negotiator:AddModifier("NARCISSISM")
                    self:SetPattern( self.BasicCycle )
                    -- if self.difficulty <= 2 then

                    -- else
                    --     self:SetPattern( self.Cycle )
                    -- end


                end,
                BasicCycle = function( self, turns )

                    if (turns-1) % 3 == 0 then
                        -- Double attack.
                        self:ChooseGrowingNumbers( 2, 0 )

                    else
                        -- Single attack.
                        self:ChooseGrowingNumbers( 1, 1 )
                    end
                    if turns % 5 == 2 then
                        -- self:ChooseCard( self.no_filter )
                    end
                    if turns % 3 == 0 then
                        self:ChooseCard( self.fragile_ego )
                    end
                end,
                -- Cycle = function( self, turns )
                --     -- Starting turn 3, "Buff" every 3 turns.
                --     if turns % 3 == 0 then
                --         self:ChooseCard( self.brag )
                --     end

                --     -- Double attack every 2 rounds; Single attack otherwise.
                --     if self.difficulty >= 4 and turns % 2 == 0 then
                --         self:ChooseGrowingNumbers( 3, -1 )
                --     elseif turns % 2 == 0 then
                --         self:ChooseGrowingNumbers( 2, 1 )
                --     else
                --         self:ChooseGrowingNumbers( 1, 3 )
                --     end

                --     -- No filter every 5 turns if it doesn't exist.
                --     -- NOTE: Added last so it doesn't immediately apply to current attacks
                --     if (turns - 1) % 5 == 0 and not self.negotiator:FindModifier( "NO_FILTER" ) then
                --         self:ChooseCard( self.no_filter )
                --     end

                --     -- Brag every 5 turns, starting turn 2, if doesn't exist.
                --     if self.BRAG > 0 then
                --         if (turns + 3) % 5 == 0 and not self.negotiator:FindModifier( "BRAG" ) then
                --             self:ChooseCard( self.brag )
                --         end
                --     end
                --     if turns % 3 == 0 and self.negotiator:GetModifierStacks( "FRAGILE_EGO" ) == 0 then
                --         self:ChooseCard( self.fragile_ego )
                --     end
                -- end,
            }
        --First turn, then every 4 turns code without it already existing code.
        --if (turns - 1) % 4 == 0 and not self.negotiator:FindModifier( "brag" ) then
            --self:ChooseCard( self.brag )
        },
        -- social_boons = table.empty,
    }),
}
for _, def in pairs(chars) do
    def.alias = def.id
    def.unique = true
    Content.AddCharacterDef( def )
    -- character_def:InheritBaseDef()
    Content.GetCharacterDef(def.id):InheritBaseDef()
end
