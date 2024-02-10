-- UUID magic
local CHAR_ASTAL = Content.GetCharacterSkin("f73e1fb3-1b7b-48a1-b1f8-927c55e7d9a2")
CHAR_ASTAL.alias = "ASTAL"

CHAR_ASTAL.loc_strings = table.extend(CHAR_ASTAL.loc_strings or {}){
    LORE_IDEAL = "Astal sincerely believes that among the Spark Barons and in Havaria in general, people don't care about who someone <i>was</>. Instead, they care only about who someone <i>is</>. This believe is the reason why Astal identifies strongly with the Spark Barons.",
}

CHAR_ASTAL.lore_unlocks = table.extend(CHAR_ASTAL.lore_unlocks or {}){
    lore_ideal = "...LORE_IDEAL",
}

local CHAR_NAND = Content.GetCharacterSkin("11ebfdd0-e82b-4d8d-a690-c36947a9013d")
CHAR_NAND.alias = "NAND"

CHAR_ASTAL.loc_strings = table.extend(CHAR_ASTAL.loc_strings or {}){
    LORE_DEMOCRACY = "Okay. We actually do live in a democracy now. Nand can definitely fulfill his dream of running for leadership... If he finds the courage and self-confidence to do it, that is.",
}

CHAR_ASTAL.lore_unlocks = table.extend(CHAR_ASTAL.lore_unlocks or {}){
    lore_democracy = "...LORE_DEMOCRACY",
}

Content.GetCharacterSkin("a972959f-3f58-4911-82b5-c50387c2af3a").alias = "HIQU"

-- Apparently Vixmalli is not considered "unique" by the game, which causes some issues. This fixes the issue
Content.GetCharacterDef("VIXMALLI").alias = "VIXMALLI"
Content.GetCharacterDef("VIXMALLI").unique = true
