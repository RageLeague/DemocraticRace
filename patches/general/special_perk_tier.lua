local patch_id = "SPECIAL_PERK_TIER"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

PERK_TIER_UNLOCK_THRESH[6] = 0
PERK_TIER_EQUIP_LIMITS[6] = 1

function GameProfile:UnlockPerkWithoutPaying(id)
    local perk_unlocks = self:GetSetting( "perk_unlocks" )

    if not perk_unlocks[id] then
        perk_unlocks[id] = true
        self:SaveSettings()
        return true
    end
    return false
end
