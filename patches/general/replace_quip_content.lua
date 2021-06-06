local patch_id = "REPLACE_QUIP_CONTENT"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = ConvoStateGraph.Quip

function ConvoStateGraph:Quip(agent, ...)
    local quip_tags = {...}
    local param = {
        tags = quip_tags,
        override_quip = false,
    }
    TheGame:BroadcastEvent( "on_say_quip", self, agent, param )
    if not param.override_quip then
        return old_fn(self, agent, table.unpack(param.tags))
    end
    return true
end