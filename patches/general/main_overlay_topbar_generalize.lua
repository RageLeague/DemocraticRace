local patch_id = "MAIN_OVERLAY_TOPBAR_GENERALIZE"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local NAV_SCREENS = { Screen.FeedbackScreen, Screen.NegotiationDeck, Screen.BattleDeck, Screen.GraftCollectionScreen, Screen.CoinScreen, Screen.BlasterScreen, Screen.MutatorsScreen, Screen.RelationshipScreen, Screen.BoonsBanesScreen, Screen.PauseMenu, Screen.PerkScreen }

for i, class in ipairs(NAV_SCREENS) do
    class.IS_NAV_SCREEN = true
end

local MainOverlayTopBar = Widget.MainOverlayTopBar

local old_navigate_to = MainOverlayTopBar.NavigateTo
function MainOverlayTopBar:NavigateTo(screen, ...)
    local old_top_screen = TheGame:FE():GetTopScreen()
    local top_screen = old_navigate_to(self, screen, ...)
    -- This happens if the old screen is already processed, so we don't do extra things here
    if old_top_screen ~= top_screen then
        if old_top_screen._class.IS_NAV_SCREEN and old_top_screen:IsOnStack() then
            old_top_screen:FadeOut()
        end
        return top_screen
    end
    if top_screen._class ~= screen._class and screen._class then
        -- We're going to a different nav screen
        if top_screen and top_screen._class.IS_NAV_SCREEN then
            -- Close the old screen
            top_screen:FadeOut()
        end

        TheGame:GetMusic():PlayNavMusic()
        top_screen = screen( ... )
        TheGame:FE():InsertScreen( top_screen )
    end
    return top_screen
end
