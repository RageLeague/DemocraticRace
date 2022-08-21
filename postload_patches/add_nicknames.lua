local NICKNAMES =
{
    SAL = "Icky-Derrick",
    ROOK = "Crooked {1.name}",
    SMITH = "{1.name} Badquod",
    PC_SHEL = "Miss Shills-for-Brains",
}

for id, name in pairs(NICKNAMES) do
    if Content.GetCharacterDef( id ) then
        Content.GetCharacterDef( id ).bad_nickname = name
    end
end
