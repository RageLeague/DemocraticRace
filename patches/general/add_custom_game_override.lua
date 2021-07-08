local patch_id = "ADD_CUSTOM_GAME_OVERRIDE"
if not rawget(_G, patch_id) then
    rawset(_G, patch_id, true)
    print("Loaded patch:"..patch_id)
    local old_fn = GameState.IsCustomMode
    GameState.IsCustomMode = function(self)
        return old_fn(self) or self.options.is_custom_mode
    end
end