-- Want to make Hesh its own gender and let it have a bunch of pronouns specifically for Hesh,
-- but there would be just too much work for very little effect.

-- What the hesh are these all about:
-- https://en.wikipedia.org/wiki/Ctenophora
-- Meaning "Comb Bearer". Common name "Comb Jelly".
-- Eight "comb rows" of fused cilia.
-- https://en.wikipedia.org/wiki/Cnidaria
-- Meaning "Stinging Nettle"
-- Have stinging cells called "cnidocyte"
-- Also: https://en.wikipedia.org/wiki/Phylum#Animals
Content.AddCharacterDef
(
    CharacterDef("COGNITIVE_HESH",
    {
        base_def = "MONSTER",
        name = "Hesh of the Dark",
        title = "Transphylum Deity",
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
                    self.negotiator:AddModifier( "ELDRITCH_EXISTENCE" )
                    self.phylum_args = self:MakePicker()
                        :AddArgument("COMB_BEARER", 1)
                        :AddArgument("STINGING_NETTLE", 1)
                    self.curiosity = self:AddArgument( "CURIOSITY" )

                    self:SetPattern( self.Cycle )
                end,
                Cycle = function( self, turn )
                    local special_count = self.negotiator:GetModifierInstances( "COMB_BEARER" ) + self.negotiator:GetModifierInstances( "STINGING_NETTLE" )
                    if turn % 4 == 2 then
                        self:ChooseCard(self.curiosity)
                        self:ChooseGrowingNumbers( 2, -1 )
                    elseif special_count == 0 then
                        self.phylum_args:ChooseCards( 1 )
                    else
                        if math.random < 0.5 then
                            self:ChooseComposure( 1, 1 + self.difficulty, 1 + self.difficulty )
                        else
                            self:ChooseGrowingNumbers( 1, -1 )
                        end
                    end
                    -- if turn % 2 == 1 then
                    --     self:ChooseGrowingNumbers( 1, -1 )
                    -- else
                    --     self:ChooseGrowingNumbers( 2, -1 )
                    -- end
                end,
            }
        },
    })
)

Content.GetCharacterDef("COGNITIVE_HESH"):InheritBaseDef()