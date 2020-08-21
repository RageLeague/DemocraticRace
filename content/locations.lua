
Content.AddLocationContent{
    id = "DIPL_PRES_OFFICE",
    name = "\"The Way\" Campaign Office",
    show_agents = true,
    plax = "INT_RichHouse_1",
    desc = "Do you know \"The Way\"? You do now.",
    icon = engine.asset.Texture("UI/location_grogndog.tex"),

    -- faction_id = "JAKES",
    exterior_loc = "BUILDING_EXTERIOR",
    -- tags = {"tavern"},
    map_tags = {"city"},
    -- flags = LOCFLAGS.HOME,
    indoors = true,

    work = {
        advisor = CreateClosedJob(  PHASE_MASK_ALL, "Advisor", CHARACTER_ROLES.VENDOR, "RACE_DIPLOMACY_CARD_SHOP"),
    },

    sublocations = 
    {
        inn_room = 
        {
            id = "DIPL_OFFICE_ROOM",
            show_player = true,
            show_agents = true,
            indoors = true,
            tags = {"player_room"},
            -- scene_scale = 1.2,
            name = "Office room",
            plax = "INT_SMITHBAR_BACKROOM",
            desc = "At least it's dry.",
        }
    },
}
Content.AddLocationContent{
    id = "MANI_PRES_OFFICE",
    name = "\"F&L\" Campaign Office",
    show_agents = true,
    plax = "INT_RichHouse_1",
    desc = "Destroying the opponent with F&L!",
    icon = engine.asset.Texture("UI/location_grogndog.tex"),

    -- faction_id = "JAKES",
    exterior_loc = "BUILDING_EXTERIOR",
    -- tags = {"tavern"},
    map_tags = {"city"},
    -- flags = LOCFLAGS.HOME,
    indoors = true,

    work = {
        advisor = CreateClosedJob(  PHASE_MASK_ALL, "Advisor", CHARACTER_ROLES.VENDOR, "RACE_MANIPULATE_CARD_SHOP"),
    },

    sublocations = 
    {
        inn_room = 
        {
            id = "MANI_OFFICE_ROOM",
            show_player = true,
            show_agents = true,
            indoors = true,
            tags = {"player_room"},
            -- scene_scale = 1.2,
            name = "Office room",
            plax = "INT_SMITHBAR_BACKROOM",
            desc = "At least it's dry.",
        }
    },
}
Content.AddLocationContent{
    id = "HOST_PRES_OFFICE",
    name = "\"Joker\" Campaign Office",
    show_agents = true,
    plax = "INT_RichHouse_1",
    desc = "You know, the trump card. 'cause of Trump. Get it?",
    icon = engine.asset.Texture("UI/location_grogndog.tex"),

    -- faction_id = "JAKES",
    exterior_loc = "BUILDING_EXTERIOR",
    -- tags = {"tavern"},
    map_tags = {"city"},
    -- flags = LOCFLAGS.HOME,
    indoors = true,

    work = {
        advisor = CreateClosedJob(  PHASE_MASK_ALL, "Advisor", CHARACTER_ROLES.VENDOR, "RACE_HOSTILE_CARD_SHOP"),
    },

    sublocations = 
    {
        inn_room = 
        {
            id = "HOST_OFFICE_ROOM",
            show_player = true,
            show_agents = true,
            indoors = true,
            tags = {"player_room"},
            -- scene_scale = 1.2,
            name = "Office room",
            plax = "INT_SMITHBAR_BACKROOM",
            desc = "At least it's dry.",
        }
    },
}
