local patch_id = "CUSTOM_BAD_NICKNAMES"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

function CharacterDef:GetLocalizedBadNickName( agent )
    local result = nil
    if self.bad_nickname then
        result = loc.format( LOC(self:GetLocBadNickNameKey()), agent )
    end
    return result
end

function CharacterDef:GetLocBadNickNameKey()
    return self:GetLocPrefix() .. ".BAD_NICKNAME"
end

local old_char_harvest = CharacterDef.HarvestStrings
function CharacterDef:HarvestStrings(t, ...)
    local result = old_char_harvest(self, t, ...)
    if self.bad_nickname then
        t[self:GetLocBadNickNameKey()] = self.bad_nickname
    end
    return result
end

function CharacterSkin:GetLocalizedBadNickName( agent )
    return self.bad_nickname and loc.format( LOC(self:GetLocBadNickNameKey()), agent )
end

function CharacterSkin:GetLocBadNickNameKey()
    return self:GetLocPrefix() .. ".BAD_NICKNAME"
end

local old_skin_harvest = CharacterSkin.HarvestStrings
function CharacterSkin:HarvestStrings(t, ...)
    local result = old_skin_harvest(self, t, ...)
    if self.bad_nickname then
        t[self:GetLocBadNickNameKey()] = self.bad_nickname
    end
    return result
end

local function DefaultFn(agent, nickname)
    if nickname then
        return loc.format(nickname, agent)
    end
    if agent:GetFactionID() == "ADMIRALTY" then
        return LOC"GENERIC_BAD_NICKNAMES.ADMIRALTY"
    end
    return LOC"GENERIC_BAD_NICKNAMES.DEFAULT"
end

local old_loc_table = Agent.GenerateLocTable
function Agent:GenerateLocTable(...)
    local result = old_loc_table(self, ...)

    local bad_nickname = (self.skin_def and self.skin_def:GetLocalizedBadNickName( self )) or self.agent_def:GetLocalizedBadNickName( self )
    local generating_fn = self.bad_nickname_fn or DefaultFn
    bad_nickname = generating_fn(self, bad_nickname)

    self.loc_table.bad_nickname = bad_nickname

    self:BroadcastEvent( "loc_changed", self )
    return result
end

function Agent:GetBadNickName()
    if self.loc_table == nil then
        self:GenerateLocTable()
    end
    return self.loc_table.bad_nickname
end

Content.AddStringTable(patch_id .. "_STRINGS", {
    GENERIC_BAD_NICKNAMES =
    {
        DEFAULT = "Scumbag",
        ADMIRALTY = "Switch",
    },
})
