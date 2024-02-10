local patch_id = "DIALOG_BROADCASTS"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Encounter.Emote

function Encounter:Emote(agent, emote, ...)
    local command = string.match(emote, "^<(.+)>$")
    if command then
        agent = self:UpdateCurrentSpeaker( agent )
        print(command)
        TheGame:BroadcastEvent( "dialog_event_broadcast", agent, table.unpack(command:split(";")) )
    else
        return old_fn(self, agent, emote, ...)
    end
end
