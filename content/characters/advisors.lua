local chars =
{
    CharacterDef("ADVISOR_DIPLOMACY",
    {
        base_def = "SPARK_BARON_TASKMASTER",
        bio = "Aellon is not sure what the word \"based\" means as an adjective, but it sounds hip and cool to him, and that's good enough for him to use it everywhere.",
        name = "Aellon",
        nickname = "*The Based",

        loved_bio = "He doesn't see eye to eye with a lot of people in Havaria. Not a lot of people understand him. Not a lot of people understand his ambition. For the people who do understand, though, he call these people \"based\".",
        hated_bio = "There are many people whose lives have been ruined by Aellon. Some people, like Kyrtus and Azta, are perceived by him as \"cringe\" for wronging him. Others are perceived by him as \"beta\" for being too easy to be taken advantage of. It's hard to tell which category you would fall under, but the outcome stays the same.",

        tags = {"advisor", "advisor_diplomacy", "curated_request_quest"},
        gender = "MALE",
        species = "HUMAN",

        theme_music = "DEMOCRATICRACE|event:/democratic_race/music/story/aellon_theme",

        build = "male_clust_trademaster",
        head = "head_male_shopkeep_002",

        hair_colour = 0xB55239FF,
        skin_colour = 0xF0B8A0FF,

        lore_unlocks =
        {
            foreigner_lore = "...LORE_FOREIGNER",
        },

        loc_strings =
        {
            LORE_FOREIGNER = "It is entirely possible that Aellon is not Havarian. After all, \"Aellon\" is not a Havarian name. If he is not from Havaria, where does Aellon come from? He is not willing to share, in any case.",
        },

        -- social_boons = table.empty,
        negotiation_data =
        {
            behaviour =
            {
                OnInit = function( self )
                    local core = self.negotiator:AddModifier("FELLOW_GRIFTER")

                    if GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ARGUMENT_PLUS ) then
                        core.num_cards = 4
                        core.count = 4
                    end
                    self:SetPattern( self.BasicCycle )
                end,
                --this can be tweaked later, but for now I just copied it from dronumph because I am wumpus, and I don't understand half of this.
                BasicCycle = function( self, turns )

                    if (turns-1) % 3 == 0 then
                        -- Double attack.
                        self:ChooseGrowingNumbers( 3, 0, 0.75 )

                    elseif (turns-2) % 3 == 0 then
                        -- Single attack.
                        self:ChooseGrowingNumbers( 1, 0 )
                        self:ChooseComposure( 1, 1 + self.difficulty, 1 + self.difficulty )
                    else
                        self:ChooseGrowingNumbers( 2, 0 )
                    end
                end,
            }
        },
    }),
    CharacterDef("ADVISOR_MANIPULATE",
    {
        base_def = "PRIEST",
        -- bio = "Your first mistake is listening to Benni. Your second mistake is believing in her.",
        bio = "Benni is perhaps one of the most level-headed person in the Cult of Hesh. Anyone who knows anything about how the Cult works knows that this is a very low bar.",
        name = "Benni",
        -- title = "Priest",

        loved_bio = "People thought Benni is cold and uncaring of anyone's feelings, like how facts don't care about one's feelings. The truth is, Benni does care. She just doesn't show it well.",
        hated_bio = "Benni has no respect for those who completely disregard logical reasoning. Which is funny, because her rhetorics only really works on these people.",

        tags = {"advisor", "advisor_manipulate", "curated_request_quest"},
        gender = "FEMALE",
        species = "KRADESHI",

        theme_music = "DEMOCRATICRACE|event:/democratic_race/music/story/benni_theme",
        -- theme_music = "event:/democratic_race/music/story/benni_theme",

        build = "female_benni_build",
        head = "head_female_kradeshi_13",

        skin_colour = 0xBEC867FF,

        lore_unlocks =
        {
            heshian_fear_lore = "...LORE_HESHIAN_FEAR",
            heshian_fear_lore_2 = "...LORE_HESHIAN_FEAR_2",
            ace_lore = "...LORE_ACE",
            ace_lore_2 = "...LORE_ACE_2",
            loss_lore = "...LORE_LOSS",
            husband_lore = "...LORE_HUSBAND",
            facts_lore = "...LORE_FACTS",
            facts_lore_2 = "...LORE_FACTS_2",
            facts_lore_3 = "...LORE_FACTS_3",
            logic_lore = "...LORE_LOGIC",
            logic_lore_2 = "...LORE_LOGIC_2",
        },

        loc_strings =
        {
            LORE_ACE = "Benni enjoys a nice dole loaf with a nice spread of garlic butter on top. It really makes the bland dole loaf taste ten times better.",
            LORE_ACE_2 = "On an unrelated note, Benni is asexual.",
            LORE_HESHIAN_FEAR = "Like any good Heshian, Benni's faith comes from her genuine fear of Hesh. However, while others revere Hesh because of such fear, Benni seek to understand the fear.",
            LORE_HESHIAN_FEAR_2 = "Perhaps it is due to this difference in how she expresses her faith that she is alienated by the other Heshians. That, or maybe it's because of her atypical mannerism that many find pretentious.",
            LORE_LOSS = "While she does want to understand the nature of Hesh, she doesn't want to see anyone getting hurt while doing so. Benni has already lost Ascle this way, and she is not about to lose another person that she cares about.",
            LORE_HUSBAND = "Benni has a husband, everyone. A husband who is a doctor. That is what she lets everyone believe. Why have we never seen him? Well... He's in another city! Doing surgeries on people! And he is very busy!",
            LORE_FACTS = "\"Facts don't care about your feelings.\" That is something Benni likes to say. It is supposed to help her get over the news of the passing of her friend and crush, but instead, it just cause her to sink further and further into denial.",
            LORE_FACTS_2 = "When she is suggested that what are considered \"facts\" can be relative, she is elated. If what is considered \"factual\" depends on a person's believe, then, maybe, if she believes hard enough, maybe Ascle is still alive out there, somewhere.",
            LORE_FACTS_3 = "Of course, if \"facts\" are relative, even if her candidate loses the election in reality, if she can convince enough people to believe in an \"alternative fact\" that it is them who actually won the election, they might as well actually win the election in reality.",
            LORE_LOGIC = "Benni's \"logical reasoning\" does sounds reasonable, as long as you don't think too hard. Still, you would be surprised at how many people are convinced and indoctrinated by her surface level logical rhetorics.",
            LORE_LOGIC_2 = "You would think that her \"logical rhetorics\" would be undesirable for the Cult of Hesh, but the opposite is true. It shouldn't come across as a surprise, though. After all, her rhetorics attracts gullible people under the pretense of logical reasoning, and the Cult loves no one more than gullible people.",
        },

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
                    else
                        self:ChooseComposure( 1, 1 + math.ceil(self.difficulty / 2), 2 + math.ceil(self.difficulty / 2) )
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

        loved_bio = "It's no doubt that Dronumph loves himself the most. There's no way to chance that due to his narcissistic nature. Though, there are some people that Dronumph tolerates, or even respects.",
        hated_bio = "Many people don't actually like Dronumph, but they placate him so that they can benefit from it. His family is a prideful one, after all, and they have a tendency to take extreme actions against those who committed the slightest transgression against them.",

        tags = {"advisor", "advisor_hostile", "curated_request_quest"},
        gender = "MALE",
        species = "JARACKLE",

        theme_music = "DEMOCRATICRACE|event:/democratic_race/music/story/dronumph_theme",

        build = "male_phicket",
        head = "head_male_jarackle_bandit_02",

        skin_colour = 0xF9C771FF,--0xB8A792FF,

        lore_unlocks =
        {
            inferiority_lore = "...LORE_INFERIORITY",
        },

        loc_strings =
        {
            LORE_INFERIORITY = "As a child of the renowned Trunoomiel family, Dronumph has been bombarded with impossible expectations right from his birth, not just from his family, but from himself. He always seeks to prove himself to be superior to others at every given opportunity, to the point of being potentially self destructive.",
        },

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
