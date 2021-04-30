local patch_id = "ADD_FIRING_EVENT"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = WorkPosition.Fire
function WorkPosition:Fire()
    local fired_agent = self.agent
    old_fn(self)
    TheGame:BroadcastEvent( "agent_fired", fired_agent )
end