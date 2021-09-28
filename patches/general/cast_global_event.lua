local patch_id = "CAST_GLOBAL_EVENT"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = QuestState.OnGlobalEvent

function QuestState:OnGlobalEvent(event_name, ...)
    old_fn(self, event_name, ...)
    for i, cast_def in ipairs(self:GetQuestDef():GetCastDefs()) do
        if cast_def.global_events then
            -- DBG(cast_def.global_events)
            -- print("Cast", cast_def.cast_id, "of quest", self:GetContentID(), "has global event defined")
        end
        if cast_def.global_events and cast_def.global_events[event_name] then
            -- print("Found global event:", event_name, "for:", cast_def.cast_id)
            self:RunScriptHandler( cast_def.global_events[event_name], ... )
            return
        end

    end
end

local old_listen_event = QuestState.ListenForEvents
function QuestState:ListenForEvents()
    old_listen_event(self)
    -- print(self:GetContentID(), "listens for more events")
    for i, cast_def in ipairs(self:GetQuestDef():GetCastDefs()) do
        if cast_def.global_events then
            for event_name, fn in pairs(cast_def.global_events) do
                TheGame:GetEvents():ListenForEvent( event_name, self )
                print("I am listening for", event_name)
            end
        end
    end
end
