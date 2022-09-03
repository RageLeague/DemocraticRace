local patch_id = "FIX_QUIP_ENTRY_DUPLICATION"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_key_fn = QuipDatabase.GetLocKey
function QuipDatabase:GetLocKey( entry, index, ... )
    if entry.additional_key then
        return string.format( "%s.%s.%d.%d", self.loc_prefix, table.concat( entry.tags, "." ), entry.additional_key, index )
    end
    return old_key_fn(self, entry, index, ...)
end

local old_add_fn = QuipDatabase.AddLines
function QuipDatabase:AddLines( lines, ... )
    local result = old_add_fn(self, lines, ...)
    local seen_keys = {}
    for i, entry in ipairs( self.db ) do
        local key = self:GetLocKey( entry, 1 )
        while seen_keys[key] do
            entry.additional_key = (entry.additional_key or 0) + 1
            key = self:GetLocKey( entry, 1 )
        end
        seen_keys[key] = true
    end
    return result
end
