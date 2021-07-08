local patch_id = "REWORK_AGENT_BROADCAST"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local oldfn = Agent.MoveToLocation

Agent.MoveToLocation = function(self, location)
    local old_loc = self.location
    oldfn(self, location)
    TheGame:BroadcastEvent("agent_location_changed", self, old_loc, self.location)
end