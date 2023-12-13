local patch_id = "ADD_LORE_SCREEN"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_compendium_init = Screen.PeopleCompendiumDetailsScreen.init

function Screen.PeopleCompendiumDetailsScreen:init(...)
    local result = old_compendium_init(self, ...)
    self.lore_tab = self.navigation:AddTab( Widget.ProgressTab( LOC"UI.CARDCOMPENDIUM.AGENT_LORE_TAB", LOC"UI.CARDCOMPENDIUM.CARD_FILTER_MINIGAME_SUBTITLE", "0%", 0, 0, UICOLOURS.SUBTITLE ) )
    self.navigation:Show()
    return result
end

local old_nav_change = Screen.PeopleCompendiumDetailsScreen.OnNavChange

function Screen.PeopleCompendiumDetailsScreen:OnNavChange( tab, ... )
    local result = old_nav_change(self, tab, ...)
    if tab == self.lore_tab then
        self.social_details_panel:Hide()
        self.lore_details_panel:Show()
    end
    return result
end

local old_refresh = Screen.PeopleCompendiumDetailsScreen.Refresh

function Screen.PeopleCompendiumDetailsScreen:Refresh(agent, ...)
    local result = old_refresh(self, agent, ...)
    local unlocked, unlockable = self.lore_details_panel:GetProgress()
    if unlockable == 0 then
        self.lore_tab:SetSubtitle( LOC"UI.CARDCOMPENDIUM.AGENT_LORE_TAB_NO_UNLOCKS" )
        self.lore_tab:SetValue( "" )
    else
        self.lore_tab:SetSubtitle( LOC"UI.CARDCOMPENDIUM.AGENT_LORE_TAB_SUBTITLE" )
        self.lore_tab:SetProgress( unlocked, unlockable )
    end
    self.lore_tab:SetEnabled( unlockable ~= 0 )
    return result
end

function Agent:GetLoreUnlocks()
    local unlocks = shallowcopy( self.lore_unlocks ) or {}
    local function GetKey(field, key_fn)
        for i = #self.def, 1, -1 do
            if self.def[i][field] then
                return self.def[i][key_fn]
            end
        end
    end
    if self.loved_bio then
        unlocks.loved_bio = GetKey("loved_bio", "GetLocLovedBioKey")(self)
    end
    if self.hated_bio then
        unlocks.hated_bio = GetKey("hated_bio", "GetLocHatedBioKey")(self)
    end
    if self.killed_bio then
        unlocks.killed_bio = GetKey("killed_bio", "GetLocKilledBioKey")(self)
    end
    if self.drank_bio then
        unlocks.drank_bio = GetKey("drank_bio", "GetLocDrankBioKey")(self)
    end

    return unlocks
end

local old_custom_agent_unlock = GameProfile.HasCustomAgentUnlock

function GameProfile:HasCustomAgentUnlock(skin_id, action, ...)
    if TheGame and TheGame:GetLocalSettings().ALL_UNLOCKS then
        return true
    end
    if skin_id ~= nil then
        if action == "loved_bio" then
            return self:HasLovedByAgent( skin_id )
        elseif action == "hated_bio" then
            return self:HasHatedByAgent( skin_id )
        elseif action == "killed_bio" then
            return self:HasKilledAgent( skin_id )
        elseif action == "drank_bio" then
            return self:HasDrankWith( skin_id )
        else
            return old_custom_agent_unlock(self, skin_id, action, ...)
        end
    end
    return false
end

local old_refresh_fn = Widget.AgentDetailsLore.Refresh

function Widget.AgentDetailsLore:Refresh(agent, ...)
    -- Remove old blocks, if any
    self.block_container:DestroyAllChildren()

    -- Reset the count
    self.unlocked = 0
    self.unlockable = 0

    -- Check if there are any lore blocks to show for this agent
    local lore_unlocks = agent:GetLoreUnlocks()

    local actions = copykeys(lore_unlocks)
    local lore_order = agent.lore_unlocks_ordering or {}
    table.sort(actions, function(a, b)
        local a_idx = table.arrayfind(lore_order, a)
        local b_idx = table.arrayfind(lore_order, b)
        if a_idx and b_idx then
            return a_idx < b_idx
        elseif not a_idx and not b_idx then
            return a < b
        else
            return a ~= nil
        end
    end)
    -- Go through them and add them to the list
    for idx, action in ipairs( actions ) do
        local unlock_text = lore_unlocks[action]
        self.unlockable = self.unlockable + 1
        -- Check if this has been done
        local is_unlocked = TheGame:GetGameProfile():HasCustomAgentUnlock( agent:GetUniqueID(), action ) or Screen.Compendium.ShowAllUnlocks()
        if is_unlocked then self.unlocked = self.unlocked + 1 end

        local substr = unlock_text:match("^[.][.][.](.+)$")
        if substr then
            for i = #agent.def, 1, -1 do
                local str_id = agent.def[i]:GetLocPrefix() .. "." .. substr
                if Content.LookupString(str_id) then
                    unlock_text = agent.def[i]:GetLocPrefix() .. "." .. substr
                    break
                end
            end
        end

        self.block_container:AddChild( Widget.AgentLoreBlock( self.block_w, action, LOC(unlock_text), is_unlocked ) )
            :LayoutBounds( "center", "below" )
            :Offset( 0, -10 )
    end

    -- Layout the scroll area
    self.block_container:SetPos( self.block_w/2, 0 )
    self.scroll_root:SetVirtualMargin( 15 )
    self.scroll_root:RefreshView()

    return self
end

function CharacterDef:GetLocLovedBioKey()
    return self:GetLocPrefix() .. ".LOVED_BIO"
end

function CharacterDef:GetLocHatedBioKey()
    return self:GetLocPrefix() .. ".HATED_BIO"
end

function CharacterDef:GetLocKilledBioKey()
    return self:GetLocPrefix() .. ".KILLED_BIO"
end

function CharacterDef:GetLocDrankBioKey()
    return self:GetLocPrefix() .. ".DRANK_BIO"
end

local old_char_def_harvest = CharacterDef.HarvestStrings

function CharacterDef:HarvestStrings(t, ...)
    local result = old_char_def_harvest(self, t, ...)
    if self.loved_bio then
        t[self:GetLocLovedBioKey()] = self.loved_bio
    end
    if self.hated_bio then
        t[self:GetLocHatedBioKey()] = self.hated_bio
    end
    if self.killed_bio then
        t[self:GetLocKilledBioKey()] = self.killed_bio
    end
    if self.drank_bio then
        t[self:GetLocDrankBioKey()] = self.drank_bio
    end
    return result
end

local old_skin_harvest = CharacterSkin.HarvestStrings

function CharacterSkin:HarvestStrings(t, ...)
    local result = old_skin_harvest(self, t, ...)
    if self.loc_strings then
        for key, str in pairs( self.loc_strings ) do
            self:HarvestString( t, key, str )
        end
    end
    return result
end
