local oldfn = QuestState.LookupQuip
function QuestState:LookupQuip(...)
    if not self:GetQuestDef() then
        -- DBG(self)
        print("Error looking up quest:")
        print("Quest id:", self:GetID())
        -- TheGame:GetDebug():CreatePanel( DebugTable( self ) )
        return
    end
    return oldfn(self, ...)
end