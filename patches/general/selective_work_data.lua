local patch_id = "SELECTIVE_WORK_DATA"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_work_data = Location.GetWorkData

function Location:GetWorkData( id, ... )
    local oldres = old_work_data(self, id, ...)
    if self.location_data and self.location_data.work and not self.location_data.work_data then
        self.location_data.work_data = self.location_data.work
        self.location_data.work = shallowcopy(self.location_data.work)
    end
    if self.location_data and self.location_data.work_data then
        return self.location_data.work_data[id]
    end
    return oldres
end

local old_populate = Location.PopulateGameState

function Location:PopulateGameState(...)
    if self.location_data and self.location_data.work and not self.location_data.work_data then
        self.location_data.work_data = self.location_data.work
        self.location_data.work = shallowcopy(self.location_data.work)
    end
    print("Broadcasting event... get_work_availability")
    TheGame:BroadcastEvent("get_work_availability", self, self.location_data and self.location_data.work or {})
    return old_populate(self, ...)
end
