local patch_id = "ADD_LORE_PRELOAD"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_init = CharacterSkin.init
function CharacterSkin:init(...)
    local result = old_init(self, ...)
    self.loved_bio = self.loved_bio and Content.LookupString( self:GetLocLovedBioKey() ) or self.loved_bio
    self.hated_bio = self.hated_bio and Content.LookupString( self:GetLocHatedBioKey() ) or self.hated_bio
    self.killed_bio = self.killed_bio and Content.LookupString( self:GetLocKilledBioKey() ) or self.killed_bio
    self.drank_bio = self.drank_bio and Content.LookupString( self:GetLocDrankBioKey() ) or self.drank_bio
    return result
end
