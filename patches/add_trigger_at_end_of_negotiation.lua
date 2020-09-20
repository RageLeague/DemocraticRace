local patch_id = "ADD_TRIGGER_AT_END_OF_NEGOTIATION"
if not rawget(_G, patch_id) then
    rawset(_G, patch_id, true)
    local old_fn = Encounter.RunNegotiation
    Encounter.RunNegotiation = function(self, minigame, no_loot)
        local result = old_fn(self, minigame, no_loot)
        TheGame:BroadcastEvent( "resolve_negotiation", minigame )
        return result
    end
end