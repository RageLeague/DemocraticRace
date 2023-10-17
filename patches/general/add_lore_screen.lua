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
    if self.loved_bio then
        unlocks.loved_bio = self.loved_bio
    end
    if self.hated_bio then
        unlocks.hated_bio = self.hated_bio
    end
    if self.killed_bio then
        unlocks.killed_bio = self.killed_bio
    end
    if self.drank_bio then
        unlocks.drank_bio = self.drank_bio
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
