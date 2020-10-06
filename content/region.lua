require "content/worldregion"

local region = {
    name = "Murder Bay",
    plax = "REGION_MURDERBAY1",
    desc = "This is murder bay after a few years of development.",

    default_outdoor_location = "MURDER_BAY_ROAD",

    outdoor_locations = 
    {
        "MURDER_BAY_SHORE",
        "MURDER_BAY_ROAD",
        "MURDER_BAY_FOREST",
        "MURDER_BAY_CITY",
    },

    locations = {
        "MURDERBAY_NOODLE_SHOP",
        "NEWDELTREE_OUTFITTERS",
        "MURDER_BAY_CHEMIST",
        "GROG_N_DOG",
        -- "LIGHTHOUSE",
        "MURDERBAY_LUMIN_DOCKS",
        "MURDER_BAY_HARBOUR",
        "SPREE_INN",
        "ADMIRALTY_BARRACKS",
        "MARKET_STALL",

        "DIPL_PRES_OFFICE",
        "MANI_PRES_OFFICE",
        "HOST_PRES_OFFICE",
        
        "GRAND_THEATER",
        -- "MURDER_BAY_HESH_OUTPOST",
        -- "MURDER_BAY_RISE_OUTPOST",
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
        
        "JAKES_RUNNER",
        "JAKES_SMUGGLER",
        "JAKES_LIFTER",
        
        
        "ADMIRALTY_GOON",
        "ADMIRALTY_GUARD",
        "ADMIRALTY_PATROL_LEADER",
        "ADMIRALTY_CLERK",

        "RISE_REBEL",
        "RISE_RADICAL",
        "RISE_PAMPHLETEER",
        
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

        if agent:HasTag("wealthy") then
            if agent:GetFaction():IsLawful() then
                return "FEUD_DOMICILE_NICE"
            end
        end

        return "FEUD_DOMICILE"
    end,
}

Content.AddWorldRegion( WorldRegion.Create("democracy_murder_bay", region) )