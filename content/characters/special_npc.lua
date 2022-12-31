local chars =
{
    -- CharacterDef("DEM_ADMIRALTY_SPECIAL_AGENT",
	-- {
    --     base_def = "ADMIRALTY_INVESTIGATOR",
    --     bio = "",
    --     name = "???",
    --     title = "Agent",
    --     gender = "MALE",
    --     species = "JARACKLE",

    --     build = "telvin",
    --     head = "head_male_jarackle_28",

    --     skin_colour = 0x856E58FF,
    -- }),

}

for _, def in pairs(chars) do
    def.alias = def.id
    def.unique = true
    Content.AddCharacterDef( def )
    Content.GetCharacterDef(def.id):InheritBaseDef()
end
