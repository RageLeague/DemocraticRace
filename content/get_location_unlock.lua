local FACTION_LOCATION_UNLOCK = {
    GRIFTER = {
        "GROG_N_DOG",
        "ADMIRALTY_BARRACKS",
        "MURDERBAY_LUMIN_DOCKS",
        "MURDERBAY_NOODLE_SHOP",
        "MURDER_BAY_HARBOUR",
        "LIGHTHOUSE",
        -- "MARKET_STALL",
        "GROG_N_DOG",
        "MURDER_BAY_CHEMIST",
        "NEWDELTREE_OUTFITTERS",
        "SPREE_INN",
        "GRAND_THEATER",
    },
    -- FEUD_CITIZEN = {"GROG_N_DOG", "MURDERBAY_NOODLE_SHOP"}
}
local function GetLocationUnlockForAgent(agent)
    local result = {}
    local faction = agent:GetFaction()
    if FACTION_LOCATION_UNLOCK[faction.id] then
        result = table.merge(result, FACTION_LOCATION_UNLOCK[faction.id])
    else
        result = table.merge(result, FACTION_LOCATION_UNLOCK.GRIFTER)
    end
    return result
end
return {
    FACTION_LOCATION_UNLOCK = FACTION_LOCATION_UNLOCK,
    GetLocationUnlockForAgent = GetLocationUnlockForAgent,
}