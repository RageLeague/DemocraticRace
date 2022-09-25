local patch_id = "CHARACTER_OFFSET"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local paperdoll = require "paperdoll_util"

local old_fn = paperdoll.SetCharacterData

paperdoll.SetCharacterData = function(anim_model, char, combat, scale, ...)
    local result = old_fn(anim_model, char, combat, scale, ...)
    if char and char.character_offset then
        anim_model:SetPos(table.unpack(char.character_offset))
    end
    return result
end
