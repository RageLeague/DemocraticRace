require "content/worldregion"

local region = {
    name = "Pearl-On-Foam",
    plax = "REGION_DEM_CAPITAL",
    desc = "The largest city in Havaria, now it is a battleground for political campaigns.",

    default_outdoor_location = "MURDER_BAY_ROAD",

    outdoor_locations =
    {
        "MURDER_BAY_SHORE",
        "MURDER_BAY_ROAD",
        "MURDER_BAY_FOREST",
        "MURDER_BAY_CITY",
    },

    locations = {
        -- Murder bay location
        "MURDERBAY_NOODLE_SHOP", -- loc
        "NEWDELTREE_OUTFITTERS", --
        "MURDER_BAY_CHEMIST", --
        "GROG_N_DOG", --
        -- "LIGHTHOUSE",
        "MURDERBAY_LUMIN_DOCKS", --
        "MURDER_BAY_HARBOUR", --
        "SPREE_INN", --
        "ADMIRALTY_BARRACKS", --
        "MARKET_STALL",

        -- grout bog location
        "GB_BARON_HQ", --
        "GB_LABOUR_OFFICE", --
        "GB_NEUTRAL_BAR", --
        "GB_CAFFY", --
        "GB_AUTOMECH_FACTORY",

        -- pearl location
        "MOREEF_BAR", --
        "PEARL_FANCY_EATS", --
        "PEARL_PARTY_STORE", --
        "PEARL_OSHNUDROME", --
        "PEARL_PARK", --
        "PEARL_CULT_COMPOUND", --
        "CONTRACT_CHAPEL", --

        -- unique location for mod
        "DIPL_PRES_OFFICE",
        "MANI_PRES_OFFICE",
        "HOST_PRES_OFFICE",
        "GRAND_THEATER", --
    },

    population = {
        "BANDIT_GOON",
        "BANDIT_GOON2",
        "BANDIT_RAIDER",
        "BANDIT_CAPTAIN",

        "ZEALOT",
        "PRIEST",
        "LUMINARI",
        "LUMINITIATE",

        "LABORER",
        "HEAVY_LABORER",
        "OSHNU_WRANGLER",
        "FOREMAN",
        "BARTENDER",
        "WEALTHY_MERCHANT",
        "POOR_MERCHANT",
        "PEARLIE",

        "JAKES_RUNNER",
        "JAKES_SMUGGLER",
        "JAKES_LIFTER",

        "ADMIRALTY_GOON",
        "ADMIRALTY_GUARD",
        "ADMIRALTY_PATROL_LEADER",
        "ADMIRALTY_CLERK",
        "ADMIRALTY_INVESTIGATOR",

        "RISE_REBEL",
        "RISE_RADICAL",
        "RISE_PAMPHLETEER",
        "RISE_VALET",

        "SPARK_BARON_PROFESSIONAL",
        "SPARK_BARON_TASKMASTER",
        "SPARK_BARON_GOON",
    },

    home_generator = function(agent)

        if agent:GetFactionID() == "ADMIRALTY" then
            return "BASIC_DORM"
        end

        if agent:GetFactionID() == "BANDITS" then
            return "SPREE_TENT"
        end

        if agent:GetFactionID() == "SPARK_BARONS" then
            return "SPARK_BARON_RESIDENCE"
        end

        if DemocracyUtil.GetWealth(agent) >= 3 then
            return "PEARL_RICH_HOUSE"
        end

        return "PEARL_POOR_HOUSE"
    end,
}

Content.AddWorldRegion( WorldRegion.Create("democracy_pearl", region) )