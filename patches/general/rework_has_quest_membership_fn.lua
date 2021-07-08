local patch_id = "REWORK_HAS_QUEST_MEMBERSHIP_FN"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Agent.HasQuestMembership

function Agent:HasQuestMembership()
    if not old_fn(self) then return false end

    for i, quest in ipairs(self.quest_membership) do
        local cast_id = quest:IsCastMember( self )
        local cast = cast_id and quest:GetQuestDef():GetCast(cast_id)
        if cast and not cast.unimportant then
            return true
        end
    end
    return false
end