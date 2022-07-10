local patch_id = "CUSTOM_PLAYER_MUSIC_EVENT"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

-- I stole this code from Newbiespud's Arint Mod.
-- You should check it out if you haven't.

Game.SetTempMusicOverride = function(self, event_name, enc)
    self.temp_music_event = event_name
    self.temp_music_enc = enc
end

local old_player_music = Game.LookupPlayerMusic

Game.LookupPlayerMusic = function(self, id)
    if self.temp_music_event then
        local current_enc = TheGame:GetGameState():GetCaravan():GetCurrentEncounter()
        local recorded_enc = self.temp_music_enc
        self.temp_music_enc = nil
        if recorded_enc == nil or current_enc == recorded_enc then
            local music_to_return = self.temp_music_event
            self.temp_music_event = nil
            return music_to_return
        else
            self.temp_music_event = nil
        end
    end
    return old_player_music(self, id)
end
