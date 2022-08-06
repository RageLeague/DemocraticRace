local NICKNAMES =
{
    SAL = "Recount Dracula",
    ROOK = "Crooked {1.name}",
    SMITH = "Flotsam Banquod",
    PC_SHEL = "Miss Shills-for-Brains",
    PC_ARINT = "Spark Karen",
}

for id, name in pairs(NICKNAMES) do
    Content.GetCharacterDef( id ).bad_nickname = name
end
