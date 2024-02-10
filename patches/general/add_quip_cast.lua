local patch_id = "ADD_QUIP_CAST"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Encounter.SayQuip

function Encounter:SayQuip(agent, ...)
    self.active_hub:ReassignCastMember( "quipper", agent )
    return old_fn(self, agent, ...)
end
