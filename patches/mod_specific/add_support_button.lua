local BAR_HEIGHT = 50
local BTN_SIZE = 40


local MainOverlayTopBar = Widget.MainOverlayTopBar

local old_init = MainOverlayTopBar.init

function MainOverlayTopBar:init(main_overlay)
    old_init(self, main_overlay)
    self.btn_dem_support = self.nav_buttons:AddChild( Widget.MainOverlayDeckButton( DemocracyConstants.icons.support, nil, nil, DemocracyConstants.support_color ) )
        :SetSize( BTN_SIZE, BTN_SIZE )
        :SetOnClickFn( function()
            -- Check if we're in one of this button's screens
            print("lmao")
            local top_screen = TheGame:FE():GetTopScreen()
            if self.btn_dem_support:IsInScreen( top_screen._class ) then
                -- Close the screen
                print("lmao")
                top_screen:FadeOut()
            else
                -- If not, navigate to the deck screen
                local screen = self:NavigateTo( DemocracyClass.Screen.SupportScreen )
            --    screen:SetNavLeft( loc.format( LOC "UI.CONTROLS.NAV_NEGOTIATION_DECK", Controls.Digital.GAMEPAD_LT ),
            --         function( screen )
            --             screen:Close()
            --             self.btn_negotiation:Click()
            --         end )
            --     screen:SetNavRight( loc.format( LOC "UI.CONTROLS.NAV_RELATIONSHIPS", Controls.Digital.GAMEPAD_RT ),
            --         function( screen )
            --             screen:Close()
            --             self.relationships_indicator:Click()
            --         end )
            end
        end )
        :AddTargetScreenClass( DemocracyClass.Screen.SupportScreen )
        -- :AddTargetScreenClass( Screen.BattleDeckFiltersSidebar )
        :SetFocusable( true )
        :SetToolTipLayoutFn( function( w, tooltip_widget ) tooltip_widget:LayoutBounds( "right", "below", w ):Offset( 0, -SPACING.M1 ) end )

    self:OnControlModeChange( TheGame:FE():GetControlMode(), TheGame:FE():GetControlDeviceID() )
    self:OnScreenModeChange( TheGame:FE():GetScreenMode() )
end

local old_refresh = MainOverlayTopBar.Refresh
function MainOverlayTopBar:Refresh(...)
    if not DemocracyUtil.IsDemocracyCampaign() then
        self.btn_dem_support:SetEnabled( false )
        self.btn_dem_support:SetShown( false )
    else
        self.btn_dem_support:SetEnabled( true )
        self.btn_dem_support:SetShown( true )
        self.btn_dem_support:RefreshCount( DemocracyUtil.TryMainQuestFn("GetGeneralSupport") )
    end
    return old_refresh(self, ...)
end

local old_navigate_to = MainOverlayTopBar.NavigateTo
function MainOverlayTopBar:NavigateTo(screen, ...)
    local top_screen = old_navigate_to(self, screen, ...)
    if top_screen._class ~= screen._class and screen._class == DemocracyClass.Screen.SupportScreen then
    end
    return top_screen
end
