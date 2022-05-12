local patch_id = "SCRATCH_FORMAT_FIX"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = ConvoStateGraph.SubstituteFormatter

function ConvoStateGraph:SubstituteFormatter(text, rest)
    local result = old_fn(self, text, rest)
    if result == nil and self.enc then
        local scratch = self.enc.scratch[text]
        if scratch then
            return scratch
        end
    end
    return result
end
