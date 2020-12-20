local chars = 
{
    CharacterDef("ADVISOR_DIPLOMACY",
    {
        base_def = "SPARK_BARON_TASKMASTER",
        bio = "Aellon is not sure what the word \"based\" means as an adjective, but it sounds hip and cool to him, and that's good enough for him to use it everywhere.",
        name = "Aellon",
        nickname = "*The Based",
        tags = {"advisor", "advisor_diplomacy"},
        gender = "MALE",
        species = "HUMAN",

        build = "male_clust_trademaster",
        head = "head_male_shopkeep_002",

        hair_colour = 0xB55239FF,
        skin_colour = 0xF0B8A0FF,

        -- renown = 4,

        -- social_boons = table.empty,
    }),
    CharacterDef("ADVISOR_MANIPULATE",
    {
        base_def = "PRIEST_PROMOTED",
        -- bio = "Your first mistake is listening to Benni. Your second mistake is believing in her.",
        bio = "Benni is different from other kra'deshi. No, it isn't because she has five fingers on each hand, but it is because she can convince you otherwise. Probably.",
        name = "Benni",
        title = "Priest",

        tags = {"advisor", "advisor_manipulate"},
        gender = "FEMALE",
        species = "KRADESHI",

        build = "female_tei_utaro_build",
        head = "head_female_kradeshi_13",

        skin_colour = 0xBEC867FF,

        -- renown = 4,

        -- social_boons = table.empty,
    }),
    CharacterDef("ADVISOR_HOSTILE",
    {
        base_def = "WEALTHY_MERCHANT",
        bio = "Dronumph is very impatient, and prefers solving his problems with fists. It's a good thing that he's legally not allowed to do that first in Democratic Havaria.",
        name = "Dronumph",

        tags = {"advisor", "advisor_hostile"},
        gender = "MALE",
        species = "JARACKLE",

        build = "male_phicket",
        head = "head_male_jarackle_bandit_02",

        skin_colour = 0xB8A792FF,

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
