local WEALTHY_PATRON_DEFS = {
    BANDIT_RAIDER = 0.5,
    BANDIT_CAPTAIN = 0.5,

    ZEALOT = 0.5,
    PRIEST = 1,

    FOREMAN = 1,
    BARTENDER = 0.5,

    JAKES_SMUGGLER = 1,

    PEARLIE = 1,
    WEALTHY_MERCHANT = 1,

    ADMIRALTY_PATROL_LEADER = 0.5,
    ADMIRALTY_CLERK = 1,

    RISE_RADICAL = 0.5,
    RISE_PAMPHLETEER = 1,

    SPARK_BARON_PROFESSIONAL = 0.75,
    SPARK_BARON_TASKMASTER = 0.75,
}

local faction_weights =
{
    [RELATIONSHIP.HATED] = 0,
    [RELATIONSHIP.DISLIKED] = .5,
    [RELATIONSHIP.NEUTRAL] = 1,
    [RELATIONSHIP.LIKED] = 1.25,
    [RELATIONSHIP.LOVED] = 1.5,
}

local function GetGeneratePatronFunction(patron_defs)
    return function(location)
        local candidates = {}
        for def_id, base_w in pairs(patron_defs) do
            local w = base_w

            local def = Content.GetCharacterDef(def_id)
            w = w * (faction_weights[TheGame:GetGameState():GetFaction(location:GetFactionID()):GetFactionRelationship( def.faction_id )] or 1)
            if w > 0 then
                candidates[def_id] = w
            end

        end
        if next(candidates) then

            local def = weightedpick(candidates)
            TheGame:GetGameState():AddSkinnedAgent(def):GetBrain():SendToPatronize(location)
        end
    end
end

Content.AddLocationContent{
    id = "DIPL_PRES_OFFICE",
    name = "X-E Æ-42",
    show_agents = true,
    plax = "INT_SB_Res_1",
    desc = "It's just a random room in the Spark Baron Headquarters. The name is made up by the room owner because it sounded hip.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/locations/location_bb51b.png"),

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
    name = "Critical Point Havaria",
    show_agents = true,
    plax = "INT_RichHouse_1",
    desc = "The last bastion of critical thinking in Havaria. At least, that's what the owner claims.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/locations/location_cph.png"),

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
    name = "The Crimson Tower",
    show_agents = true,
    plax = "INT_Dem_Hostile_Office",
    desc = "A lone tower sits on top of a hill. Deliberately chosen by the owner to show off their superiority.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/locations/location_ct.png"),

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
            plax = "INT_Neutral_Bar_Backroom",
            desc = "At least it's dry.",
        }
    },
}
Content.AddLocationContent{
    id = "GRAND_THEATER",
    name = "The Grand Theater",
    show_agents = true,
    plax = "INT_AuctionHouse_01",
    desc = "A place where significant events are held frequently.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/locations/location_grand_theater.png"),

    map_tags = {"city"},
    indoors = true,

    faction_id = "NEUTRAL",

    work = {
        host = CreateLabourJob(  PHASE_MASK_ALL, "Host", CHARACTER_ROLES.PROPRIETOR, {"PRIEST", "WEALTHY_MERCHANT"} ),
    },

    patron_data = {
        patron_generator = GetGeneratePatronFunction(WEALTHY_PATRON_DEFS),
        num_patrons =
        {
            [DAY_PHASE.DAY] = 3,
            [DAY_PHASE.NIGHT] = 7,
        },
    },

    sublocations = {
        backroom = {
            name = "Grand Theater Back Room",
            plax = "INT_Auction_Backroom_1",
            map_tags = {"city"},
            indoors = true,
        },
    }
}
Content.GetLocationContent("PEARL_PARK").entry_scenario = "DEMOCRACY_PARK_ENTRY"
-- Content.GetLocationContent("GB_NEUTRAL_BAR").faction_id = "NEUTRAL"
