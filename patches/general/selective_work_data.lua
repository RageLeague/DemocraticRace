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
