local patch_id = "LOCATION_DELETION_CHANGE"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Location.UpdateLocation

function Location:UpdateLocation(...)
    self.patron_capacity = nil
    if self.quest_membership and (next(self.quest_membership) ~= nil) then
        return
    end
    return old_fn(self, ...)
end
