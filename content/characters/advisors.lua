local chars =
{
    CharacterDef("ADVISOR_DIPLOMACY",
    {
        base_def = "SPARK_BARON_TASKMASTER",
        bio = "Aellon is not sure what the word \"based\" means as an adjective, but it sounds hip and cool to him, and that's good enough for him to use it everywhere.",
        name = "Aellon",
        nickname = "*The Based",

        loved_bio = "He doesn't see eye to eye with a lot of people in Havaria. Not a lot of people understand him. Not a lot of people understand his ambition. For the people who do understand, though, he call these people \"based\".",
        hated_bio = "It is quite obvious that Aellon trying to be relatable to you is merely a facade. Once your usefulness runs out, he shows his true colors: cold, impersonal, and will ruin your life.",

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
            lore_foreigner = "...LORE_FOREIGNER",
            lore_competence = "...LORE_COMPETENCE",
            lore_exploitation = "...LORE_EXPLOITATION",
        },

        lore_unlocks_ordering =
        {
            "lore_foreigner",
            "lore_competence",
            "lore_exploitation",
            "hated_bio",
            "loved_bio",
        },

        loc_strings =
        {
            LORE_FOREIGNER = "It is entirely possible that Aellon is not Havarian. After all, \"Aellon\" is not a Havarian name. If he is not from Havaria, where does Aellon come from? He is not willing to share, in any case.",
            LORE_OUTSIDER = "Maybe it's because of this, or perhaps it's because of the strange vocabulary that he uses, people treat him like an outsider. This is despite the fact that he lived in Havaria for at least fifteen years, and despite the fact that he tries to be approachable and relatable.",
            LORE_COMPETENCE = "The story of Aellon is truly an inspiration to many. Starting with nothing under his name, and working his way up the Spark Baron's ranks all because of his ability? That is the dream of many Spark Barons and Spark Baron aspirants.",
            LORE_EXPLOITATION = "Of course, like any Spark Baron, there are countless workers and other barons that he exploited in order to bring him wealth and influences. Though, Aellon consider these people to be \"betas\" for allowing him to exploit them.",
            LORE_TRUST = "Aellon doesn't trust anyone. A generally sound strategy in Havaria, though it seems that Aellon has learned this lesson the hard way.",
            LORE_PARENTAL = "There are two people that Aellon used to consider parental figures. Kyrtus Markov and Azta Heien. They took him in as a Spark Baron when he was facing the biggest change of his life.",
            LORE_KYRTUS = "He felt betrayed by Kyrtus when he tried to steal Aellon's technological inventions as his own. Inventions that Aellon rightfully stolen from the Vagrant. Of course, he got Kyrtus back by ruining his reputation as a Spark Baron and condemning him to the derricks.",
            LORE_AZTA = "He felt betrayed by Azta when she abandoned him, during the time he got betrayed by another person close to him and needed someone he can trust. He tried to contact her, but she never responded. He tried to find her, but he couldn't find her anywhere. Of course, that's because a woman named Azta no longer exists.",
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
            lore_garlic_bread = "...LORE_GARLIC_BREAD",
            lore_alienation = "...LORE_ALIENATION",
            lore_husband = "...LORE_HUSBAND",
            lore_use_in_cult = "...LORE_USE_IN_CULT",
        },

        lore_unlocks_ordering =
        {
            "lore_alienation",
            "lore_husband",
            "lore_use_in_cult",
            "hated_bio",
            "loved_bio",
            "lore_garlic_bread",
        },

        loc_strings =
        {
            LORE_GARLIC_BREAD = "Benni enjoys a nice dole loaf with a nice spread of garlic butter on top. It really makes the bland dole loaf taste ten times better.",
            LORE_ACE = "On an unrelated note, Benni is asexual.",
            LORE_HESHIAN_FEAR = "Like any good Heshian, Benni's faith comes from her genuine fear of Hesh. However, while others revere Hesh because of such fear, Benni seek to understand the fear.",
            LORE_ALIENATION = "Perhaps it is due to this difference in how she expresses her faith that she is alienated by the other Heshians. That, or maybe it's because of her atypical mannerism that many find pretentious.",
            LORE_TEI = "Yet, despite that, there is someone in the Cult that accepts Benni, treats her respectfully, and recognizes her talent and devotion, despite her differences. Tei Utaro. No wonder Benni feels a strong attraction towards her.",
            LORE_LOSS = "While she does want to understand the nature of Hesh, she doesn't want to see anyone getting hurt while doing so. Benni has already lost Clepius this way, and she is not about to lose another person that she cares about.",
            LORE_HUSBAND = "Benni has a husband, everyone. A husband who is a doctor. That is what she lets everyone believe. Why have we never seen him? Well... He's in another city! Doing surgeries on people! And he is very busy!",
            LORE_FACTS = "\"Facts don't care about your feelings.\" That is something Benni likes to say. It is supposed to help her get over the news of the passing of her friend and crush, but instead, it just cause her to sink further and further into denial.",
            LORE_ALT_FACT_HOPE = "When she is suggested that what are considered \"facts\" can be relative, she is elated. If what is considered \"factual\" depends on a person's believe, then, maybe, if she believes hard enough, maybe Clepius is still alive out there, somewhere.",
            LORE_ALT_FACT_ELECTION = "Of course, if \"facts\" are relative, even if her candidate loses the election in reality, if she can convince enough people to believe in an \"alternative fact\" that it is them who actually won the election, they might as well actually win the election in reality.",
            LORE_LOGIC = "Benni's \"logical reasoning\" does sounds reasonable, as long as you don't think too hard. Still, you would be surprised at how many people are convinced and indoctrinated by her surface level logical rhetorics.",
            LORE_USE_IN_CULT = "You would think that her \"logical rhetorics\" would be undesirable for the Cult of Hesh, but the opposite is true. It shouldn't come across as a surprise, though. After all, her rhetorics attracts gullible people under the pretense of logical reasoning, and the Cult loves no one more than gullible people.",
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
            lore_gunter = "...LORE_GUNTER",
            lore_inferiority = "...LORE_INFERIORITY",
            lore_insufferable = "...LORE_INSUFFERABLE",
        },

        lore_unlocks_ordering =
        {
            "lore_gunter",
            "lore_inferiority",
            "lore_insufferable",
            "hated_bio",
            "loved_bio",
        },

        loc_strings =
        {
            LORE_INFERIORITY = "As a child of the renowned Trunoomiel family, Dronumph has been bombarded with impossible expectations right from his birth, not just from his family, but from himself. He always seeks to prove himself to be superior to others at every given opportunity, and can't seem to accept the fact that no one can be superior in everything.",
            LORE_INSUFFERABLE = "Because he constantly tries to prove himself to be superior to everyone and live up to his family name, he is prone to tantrums. People who knows him will pretend to lose to not get on his bad side, even though they think that he is insufferable. Funny how much weight a powerful family name can carry.",
            LORE_GUNTER = "Gunter Trunoomiel is a legend among merchants. Born a jarackle with nothing in his name, he built a massive business empire using purely his abilities and business insight. The type of story that the rich uses to pretend they live in a meritocracy, while the poor uses to give them hope that maybe one day, they can be as successful as him.",
            LORE_UNACCEPTED = "Despite this, people, especially those in power, don't treat Gunter with due respect. Perhaps it's because of his shabby clothing, his lack of high class etiquette, or the uncommon but still present belief that a poor jarackle like him can't possibly become a tycoon. This has taught Gunter, as well as his family, not to trust anyone, because they will never be accepted by others deep down.",
            LORE_GUNTER_DEATH = "Gunter died after an unfortunate surgery accident, ten years ago. It was caused by a number of factors, such as the inexperience and panic of the surgeon, as well as the skepticism and uncooperativeness of Gunter.",
            LORE_TOMOPHOBIA = "The death of his father at the hands of a surgeon caused Dronumph to develop tomophobia, a fear of surgeries. Even when he lost his eye and can easily replace it with the amount of wealth he has, he is not willing to undergo the procedure because of this fear.",
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
