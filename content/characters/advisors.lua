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

        renown = 4,

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

        renown = 4,

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

        renown = 4,

        -- We'll work on a proper negotiation later.
        -- negotiation_data = Content.GetCharacterDef("BANDIT_CAPTAIN").negotiation_data,
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
