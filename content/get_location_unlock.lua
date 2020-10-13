local FACTION_LOCATION_UNLOCK = {
    GRIFTER = shallowcopy(Content.GetWorldRegion("democracy_pearl").locations),
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