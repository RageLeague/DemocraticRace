local patch_id = "DISABLE_HOME_AUTOCULL"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local oldfn = Location.RemoveRoomOccupant
function Location:RemoveRoomOccupant( agent )
    if table.arraycontains(TheGame:GetGameState():GetWorldRegion():GetContent().locations, self:GetContentID()) then
        table.arrayremove( self.room_occupants, agent )
        -- No autocull
    else
        oldfn(self, agent)
    end
end