local ALL_LOCATION_UNLOCKS = shallowcopy(Content.GetWorldRegion("democracy_pearl").locations)
-- local FACTION_LOCATION_UNLOCK = {
--     GRIFTER = shallowcopy(Content.GetWorldRegion("democracy_pearl").locations),
--     -- FEUD_CITIZEN = {"GROG_N_DOG", "MURDERBAY_NOODLE_SHOP"}
-- }
local UNLOCK_TYPE = MakeEnum{
    "BAR",
    "SHOP",
    "ENTERTAINMENT",
    "WORK",
    "OFFICE",
}
local CAMPAIGN_OFFICES = {
    "DIPL_PRES_OFFICE",
    "MANI_PRES_OFFICE",
    "HOST_PRES_OFFICE",
}
--TheGame:GetGameState():GetLocation(location_id)
-- let's just hard code, who cares?
local UNLOCK_LOCATIONS = {
    [UNLOCK_TYPE.BAR] = {
        "MURDERBAY_NOODLE_SHOP",
        "GROG_N_DOG",
        "SPREE_INN",
        "GB_NEUTRAL_BAR", --
        "GB_CAFFY",
        "MOREEF_BAR", --
        "PEARL_FANCY_EATS",
    },
    [UNLOCK_TYPE.OFFICE] = {
        "DIPL_PRES_OFFICE",
        "MANI_PRES_OFFICE",
        "HOST_PRES_OFFICE",
        "ADMIRALTY_BARRACKS", --
        "GB_BARON_HQ", --
        "GB_LABOUR_OFFICE",
        "PEARL_CULT_COMPOUND",
        -- "CONTRACT_CHAPEL",
    },
    [UNLOCK_TYPE.SHOP] = {
        "NEWDELTREE_OUTFITTERS", --
        "MURDER_BAY_CHEMIST", --
        "PEARL_PARTY_STORE", --
        "MARKET_STALL",
    },
    [UNLOCK_TYPE.WORK] = {
        "MURDERBAY_LUMIN_DOCKS", --
        "MURDER_BAY_HARBOUR", --
        "GB_AUTOMECH_FACTORY",
    },
    [UNLOCK_TYPE.ENTERTAINMENT] = {
        "PEARL_OSHNUDROME", --
        "PEARL_PARK", --
        "GRAND_THEATER", --
    }
}
local DEFAULT_ICON_FALLBACKS = {
    [UNLOCK_TYPE.BAR] = "UI/location_grogndog.tex",
    [UNLOCK_TYPE.OFFICE] = "UI/location_feuddomicilenice.tex",
    [UNLOCK_TYPE.SHOP] = "UI/location_newdeltreeoutfitters.tex",
    [UNLOCK_TYPE.WORK] = "UI/location_lumindocks.tex",
    [UNLOCK_TYPE.ENTERTAINMENT] = "UI/location_murderbaycity.tex",
}
local FANCY_LOCATIONS = {
    "MOREEF_BAR", --
    "PEARL_FANCY_EATS",
    "GRAND_THEATER", --
    "PEARL_CULT_COMPOUND",
    -- "CONTRACT_CHAPEL",
}
local ILLEGAL_LOCATIONS = {
    "MARKET_STALL",
}
local LAW_FACTIONS = {
    "ADMIRALTY",
    "CULT_OF_HESH",
}
local RELATIONSHIP_SCORES = {
    [RELATIONSHIP.DISLIKED] = -1,
    [RELATIONSHIP.LIKED] = 2,
    [RELATIONSHIP.LOVED] = 3,
}
local locicon = Location.GetIcon
function Location:GetIcon()
    if not self.location_data.icon then
        for id, data in pairs(UNLOCK_LOCATIONS) do
            if table.arraycontains(data, self:GetContentID()) then
                return engine.asset.Texture(DEFAULT_ICON_FALLBACKS[id])
            end
        end
        engine.asset.Texture("UI/location_surprise.tex")
    end
    return locicon(self)
end
local function GetLocationUnlockScore(location, agent, location_type)
    if type(location) == "string" then
        location = TheGame:GetGameState():GetLocation(location)
    end
    if location_type and not table.arraycontains(UNLOCK_LOCATIONS[location_type], location:GetContentID()) then
        return nil
    end
    if agent:GetLocation() == location then
        return nil -- you don't unlock the place you're in.
    end
    local faction_relationship = agent:GetFaction():GetFactionRelationship( location:GetFactionID() )
    if faction_relationship == RELATIONSHIP.HATED then
        if agent:GetBrain():GetWorkplace() ~= location then
            return nil -- you shouldn't know a location that you cannot visit unless you work at it
        end
    end
    if table.arraycontains(ILLEGAL_LOCATIONS, location:GetContentID()) and table.arraycontains(LAW_FACTIONS, agent:GetFactionID()) then
        return nil -- they are called "black market" for a reason
    end
    local score = 2 -- initial weighting
    if location:GetFactionID() == agent:GetFactionID() then
        score = score + 10
    else
        if RELATIONSHIP_SCORES[faction_relationship] then
            score = score + RELATIONSHIP_SCORES[faction_relationship]
        end
    end
    if DemocracyUtil.GetWealth(agent) > 2 then
        if table.arraycontains(FANCY_LOCATIONS, location:GetContentID()) then
            score = score + 2
        end
    else
        if table.arraycontains(FANCY_LOCATIONS, location:GetContentID()) then
            score = score - 2
        end
    end
    if agent:GetBrain():GetWorkplace() == location then
        score = score + 2
    end
    if table.arraycontains(CAMPAIGN_OFFICES, location:GetContentID()) then
        score = score * 0.25
    end
    return score > 0 and score
end
local function GetLocationUnlockForAgent(agent, location_type)
    local result = {}
    local faction = agent:GetFaction()
    local iswealthy = DemocracyUtil.GetWealth(agent) > 2
    if location_type then
        result = shallowcopy(UNLOCK_LOCATIONS[location_type])
    else
        result = shallowcopy(ALL_LOCATION_UNLOCKS)
    end
    local scoretable = {}
    for i, id in ipairs(result) do
        local score = GetLocationUnlockScore(id, agent, location_type)
        if score then
            scoretable[id] = score
        end
    end
    -- if faction:IsLawful() then
    --     -- only really the spree knows about it. and any workers.
    --     if not (agent:GetBrain():GetWorkplace() and agent:GetBrain():GetWorkplace():GetContentID() == "SPREE_INN") then
    --         table.arrayremove(result, "SPREE_INN")
    --     end
    -- end

    -- if FACTION_LOCATION_UNLOCK[faction.id] then
    --     result = table.merge(result, FACTION_LOCATION_UNLOCK[faction.id])
    -- else
    --     result = table.merge(result, FACTION_LOCATION_UNLOCK.GRIFTER)
    -- end
    return scoretable
end
return {
    ALL_LOCATION_UNLOCKS = ALL_LOCATION_UNLOCKS,
    UNLOCK_TYPE = UNLOCK_TYPE,
    UNLOCK_LOCATIONS = UNLOCK_LOCATIONS,
    GetLocationUnlockScore = GetLocationUnlockScore,
    GetLocationUnlockForAgent = GetLocationUnlockForAgent,
}
