local patch_id = "GAME_RESET_TRIGGER"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_reset_fn = Game.Clear
function Game:Clear(...)
    local res = old_reset_fn(self, ...)
    Content.InvokeModAPI( "OnGameReset" )
    return res
end
