local patch_id = "MORE_AGENT_QUIP_TAGS"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Agent.FillOutQuipTags
function Agent:FillOutQuipTags(tags)
    old_fn(self, tags)
    if TheGame:GetGameState() then
        for id, quest in TheGame:GetGameState():ActiveQuests() do
            if quest:GetQuestDef().fill_out_quip_tags then
                quest:DefFn("fill_out_quip_tags", tags, self)
            end
        end
    end
end

local old_enc_fn = Encounter.LookupQuip

function Encounter:LookupQuip( agent, ... )
    local tags = {...}
    -- No agent because if there is an agent, the case is already covered.
    if TheGame:GetGameState() and not agent then
        for id, quest in TheGame:GetGameState():ActiveQuests() do
            if quest:GetQuestDef().fill_out_quip_tags then
                quest:DefFn("fill_out_quip_tags", tags, agent)
            end
        end
    end
    return old_enc_fn(self, agent, table.unpack(tags))
end
