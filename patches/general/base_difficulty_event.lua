local patch_id = "BASE_DIFFICULTY_EVENT"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = GameState.SetDifficulty
function GameState:SetDifficulty(diff, ...)
    local old_diff = self.current_difficulty
    old_fn(self, diff, ...)
    TheGame:BroadcastEvent( "base_difficulty_change", diff, old_diff)
    return self
end