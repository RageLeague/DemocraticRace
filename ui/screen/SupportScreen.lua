-- require "ui/widgets/installed_grafts"
-- require "ui/widgets/segmentedbar"
-- require "ui/widgets/radialprogress"
-- require "ui/widgets/radialprogress"
-- require "ui/screens/upgradegraftpopup"

local SupportScreen = class( "DemocracyClass.Screen.SupportScreen", Widget.Screen )

local PANEL_W = RES_X * 0.95
local PANEL_H = RES_Y * 0.70
local PANEL_PADDING = 8
local CONTAINER_W = RES_X * 0.75
local CONTAINER_H = PANEL_H - PANEL_PADDING*2
local GRAFT_SLOT_SIZE = 110
local DETAILS_W = RES_X*0.6

SUPPORT_SCREEN_MODE, SUPPORT_SCREEN_MODE_NAME = MakeEnumValues{ "DEFAULT", "RELATIVE_GENERAL", "RELATIVE_CURRENT", "RELATIVE_GOAL" }
SUPPORT_SCREEN_MODE_SIZE = 4

local function CycleScreenMode(mode)
    mode = mode + 1
    if mode > SUPPORT_SCREEN_MODE_SIZE then
        mode = SUPPORT_SCREEN_MODE.DEFAULT
    end
    return mode
end

SupportScreen.IS_NAV_SCREEN = true

SupportScreen.CONTROL_MAP = {
    {
        hint = function(self, left, right)
            table.insert(left, LOC"UI.CONTROLS.NAV")
        end
    },
    {
        control = Controls.Digital.MENU_CANCEL,
        fn = function(self)
            -- AUDIO:PlayEvent( "event:/ui/grafts_menu/close" )
            -- self:FadeOut()
            self:OnClickClose()
            return true
        end,
        hint = function(self, left, right)
            table.insert(right, loc.format(LOC"UI.CONTROLS.CLOSE", Controls.Digital.MENU_CANCEL))
        end
    },
    {
        control = Controls.Digital.SKIP,
        fn = function(self)
            -- AUDIO:PlayEvent( "event:/ui/grafts_menu/close" )
            -- self:FadeOut()
            self:OnModeSwitch()
            return true
        end,
        hint = function(self, left, right)
            table.insert(right, loc.format(LOC"DEMOCRACY.CONTROLS.SWITCH_MODE", Controls.Digital.SKIP))
        end
    },
}


function SupportScreen:init( owner, on_end_fn )
    SupportScreen._base.init( self )

    self:SetupUnderlay( true )
    self:SetAnchors( "center", "center" )

    self.support_screen_mode = SUPPORT_SCREEN_MODE.DEFAULT

    -- self.locked = locked

    -- Start assembling our screen
    -- Get the screen size
    local screen_w, screen_h = TheGame:FE():GetScreenDims()
    self.screen_w = math.ceil( screen_w / TheGame:FE():GetBaseWidgetScale() )
    self.screen_h = math.ceil( screen_h / TheGame:FE():GetBaseWidgetScale() )

    -- Setup the grid
    self.grid = self:AddChild( Widget.Image( engine.asset.Texture( "UI/grid.tex" ) ) )
    self.grid:SetTintColour( UICOLOURS.GRAFT )
    self.grid:SetTintAlpha( 0.8 )
    local target_w = self.screen_w*1.1
    local g_w, g_h = self.grid:GetSize();
    local target_h = target_w/g_w*g_h; -- Scale the grid to match the width, mantaining aspect ratio
    self.grid:SetSize( target_w, target_h )
    self.grid:SetPos( nil, -self.screen_h/2 + target_h/2 )

    -- Setup character anim display
    self.owner = owner or TheGame:GetGameState():GetPlayerAgent()
    self.character = self:AddChild( Widget.AnimatedCharacter() )
        :SetScale( 1, 1 )
        :Refresh( self.owner )
    self.character:SetHoverOutlineColour( UICOLOURS.GRAFT )
    self.character_animation_done = true
    self.character.anim:SetAnimDoneFn( function() self.character_animation_done = true end )
    self.character:SetClickFn( function()
        if self.character_animation_done then
            self.character_animation_done = false
            self.character:Emote( "neutral_notepad", true )
        end
    end )
    self.character:SetAutoLoopEnabled( false )
    self.character:Emote( "neutral_notepad", true )
    self.character:SetPos( -RES_X*0.35, -350 )

    -- Our scroll container
    self.scroll = self:AddChild( Widget.ScrollPanel() )
        :SetVirtualMargin( 0 )
        :SetVirtualTopMargin( SPACING.M1*4 )
        :SetVirtualBottomMargin( SPACING.M1*4 )
        :SetScrollBarOuterMargin( 0 )
        :ShowBar( SCROLLBAR.NEVER )
        :SetSize( DETAILS_W+SPACING.M1*4, self.height )
    self.content = self.scroll:AddScrollChild( Widget() )

    -- Show text info
    -- self.text_content = self.content:AddChild(Widget())
    self.title = self.content:AddChild( Widget.Label("title", FONT_SIZE.SCREEN_TITLE ) )
        :SetText( loc.upper( LOC"DEMOCRACY.SUPPORT_SCREEN.TITLE" ) )
        :SetGlyphColour( UICOLOURS.GRAFT )
        :SetAutoSize(DETAILS_W)
        :LeftAlign()
        :SetWordWrap(true)
        :Bloom(0.15)

        -- :SetShown(false)
    self.subtitle = self.content:AddChild( Widget.Label("title", FONT_SIZE.BODY_TEXT ) )
        :SetText( LOC"DEMOCRACY.SUPPORT_SCREEN.DESC" )
        :SetGlyphColour( UICOLOURS.GRAFT )
        :SetAutoSize(DETAILS_W)
        :LeftAlign()
        :SetWordWrap(true)
        :SetTintAlpha( 0.8 )
        :Bloom(0.1)

        -- :SetShown(false)
    local content_width = DETAILS_W -- / TheGame:FE():GetBaseWidgetScale()
    self.general_support = self.content:AddChild(DemocracyClass.Widget.GeneralSupportEntryList())
        :SetWidth(content_width)

    self.faction_support = self.content:AddChild(DemocracyClass.Widget.FactionSupportEntryList())
        :SetWidth(content_width)

    self.wealth_support = self.content:AddChild(DemocracyClass.Widget.WealthSupportEntryList())
        :SetWidth(content_width)

    self.issue_trackers = self.content:AddChild(DemocracyClass.Widget.StancesEntryList())
        :SetWidth(content_width)

    -- if self.issue_trackers.widget_list[1] then
    --     self.issue_trackers.widget_list[1]:SetFocusDir("up",self.wealth_support.widget_list[4], true)
    -- end


    -- self.test_track = self.content:AddChild(DemocracyClass.Widget.PoliticalIssueTrack()
    --     :SetIssue("SECURITY")
    --     :AddAgent(TheGame:GetGameState():GetPlayerAgent()))
    --     :AddAgent(TheGame:GetGameState():GetMainQuest():GetCastMember("candidate_admiralty"))
    --     :AddAgent(TheGame:GetGameState():GetMainQuest():GetCastMember("candidate_spree"))
    --     :AddAgent(TheGame:GetGameState():GetMainQuest():GetCastMember("candidate_baron"))
    --     :AddAgent(TheGame:GetGameState():GetMainQuest():GetCastMember("candidate_rise"))
    --     :AddAgent(TheGame:GetGameState():GetMainQuest():GetCastMember("candidate_cult"))
    --     :AddAgent(TheGame:GetGameState():GetMainQuest():GetCastMember("candidate_jakes"))
    -- Back button
    self.bottom_left = self:AddChild( Widget() ):SetAnchors( "left", "bottom" )
    self.close_button = self.bottom_left:AddChild( Widget.IconButton( LOC"UI.OVERLAYS.CLOSE",
        function()
            self:OnClickClose()
        end ) )
    self.close_button:SetIcon( global_images.close )
    self.close_button:LayoutBounds( "left", "above", 60, 60 )

    self.mode_button = self.bottom_left:AddChild( Widget.IconButton( LOC"DEMOCRACY.SUPPORT_SCREEN.SWITCH_MODE",
        function()
            self:OnModeSwitch()
        end ) )
    self.mode_button:SetIcon( global_images.close )
    self.mode_button:LayoutBounds( "after", "center", self.close_button )
        :Offset(SPACING.M1, 0)

    self.on_end_fn = on_end_fn

    self:Refresh()

    print("Testloal", self.wealth_support.widget_list[1]:GetFocusDir("down"))
    print("Testloal", self.wealth_support.widget_list[4]:GetFocusDir("down"))
end

function SupportScreen:HandleControlDown(control, device)
    if control:Has( Controls.Digital.SCROLL_DOWN ) then
        self.scroll:ScrollDown()
        return true
    elseif control:Has( Controls.Digital.SCROLL_UP ) then
        self.scroll:ScrollUp()
        return true
    end
end

function SupportScreen:OnClickClose()
    AUDIO:PlayEvent( SoundEvents.card_select_screen_close )

    self:Close()
end

function SupportScreen:OnModeSwitch()
    self.support_screen_mode = CycleScreenMode(self.support_screen_mode)
    self:Refresh(self.support_screen_mode)
end

function SupportScreen:Close()
    if self:IsOnStack() then
        self:FadeOut()
    end
end

function SupportScreen:Refresh(new_mode)
    -- Update tab counts
    -- local installed_grafts, max_grafts
    -- installed_grafts, max_grafts = self.graft_widgets[GRAFT_TYPE.COMBAT]:GetGraftCount()
    -- installed_grafts, max_grafts = self.graft_widgets[GRAFT_TYPE.NEGOTIATION]:GetGraftCount()

    -- -- Show grafts
    -- self.graft_widgets[GRAFT_TYPE.COMBAT]:Refresh():Layout()
    -- self.graft_widgets[GRAFT_TYPE.NEGOTIATION]:Refresh():Layout()
    self.general_support:Refresh(new_mode)
    self.faction_support:Refresh(new_mode)
    self.wealth_support:Refresh(new_mode)
    self.issue_trackers:Refresh()

    local mode_name = SUPPORT_SCREEN_MODE_NAME[self.support_screen_mode]

    self.mode_button:SetToolTip(loc.format(
        LOC"DEMOCRACY.SUPPORT_SCREEN.SWITCH_MODE_TT",
        LOC("DEMOCRACY.SUPPORT_SCREEN.MODE."..mode_name.."_TITLE"),
        LOC("DEMOCRACY.SUPPORT_SCREEN.MODE."..mode_name.."_DESC"),
        Controls.Digital.SKIP
    ))

    self:Layout()
end

function SupportScreen:OnControlModeChange( cm, device_id )
    SupportScreen._base.OnControlModeChange( self, cm, device_id )

    if cm == CONTROL_MODE.MOUSE_KEYBOARD then
        self.bottom_left:Show()
        self.scroll:ShowBar( SCROLLBAR.IF_NEEDED )
    end
    if cm == CONTROL_MODE.TOUCH then
        self.bottom_left:Show()
        self.scroll:ShowBar( SCROLLBAR.NEVER )
    end
    if cm == CONTROL_MODE.GAMEPAD then
        self.bottom_left:Hide()
        self.scroll:ShowBar( SCROLLBAR.NEVER )

        local first = self:GetDefaultFocus()
        if first then first:SetFocus() end
    end
end

function SupportScreen:OnScreenModeChange( sm )
    SupportScreen._base.OnScreenModeChange( self, sm )

    local content_w = DETAILS_W
    if sm == SCREEN_MODE.MONITOR then
    elseif sm == SCREEN_MODE.TV then
        content_w = content_w * 0.9
    elseif sm == SCREEN_MODE.SMALL then
        content_w = content_w * 0.8
    end

    self.title:SetAutoSize(content_w)
    self.subtitle:SetAutoSize(content_w)

    self.general_support:SetWidth(content_w)
    self.faction_support:SetWidth(content_w)
    self.wealth_support:SetWidth(content_w)
    self.issue_trackers:SetWidth(content_w)
    -- self.graft_widgets[GRAFT_TYPE.COMBAT]:SetWidth( (content_w-SPACING.M1)/2 )
    -- self.graft_widgets[GRAFT_TYPE.NEGOTIATION]:SetWidth( (content_w-SPACING.M1)/2 )

    self.content:SetLayoutScale( LAYOUT_SCALE[sm] )
    self.bottom_left:SetLayoutScale( LAYOUT_SCALE[sm] )

    self:Layout()
end

function SupportScreen:GetDefaultFocus()
    return (self.general_support and self.general_support:GetDefaultFocus())
        or (self.faction_support and self.faction_support:GetDefaultFocus())
        or (self.wealth_support and self.wealth_support:GetDefaultFocus())
        or (self.issue_trackers and self.issue_trackers:GetDefaultFocus())
        or self.close_button
end


function SupportScreen:RefreshStreamerMode()
    self.bottom_left:SetPos( 0, 0 )
    if GetStreamerMode() == 1 then
        -- Nudge the left side widgets
        self.bottom_left:SetPos( 360, 0 )
    end
end

function SupportScreen:OnOpen()
    SupportScreen._base.OnOpen( self )

    -- Refresh control mode display
    self:OnControlModeChange( TheGame:FE():GetControlMode(), TheGame:FE():GetControlDeviceID() )
    self:OnScreenModeChange( TheGame:FE():GetScreenMode() )

    self.screen_loop = AUDIO:CreateEventInstance("event:/ui/grafts_menu/open")
    self.screen_loop:Start()

    local anim_duration = 0.7
    local horizontal_movement = 90

end

function SupportScreen:OnClose()
    SupportScreen._base.OnClose( self )

    if self.on_end_fn then
        self.on_end_fn( self )
    end

    self.screen_loop:Stop()
    self.screen_loop:Release()
    self.screen_loop = nil
end

function SupportScreen:Layout()

    -- self.text_content:SetPos( 0, 0 )
    self.title:SetPos(0, 0)
    self.subtitle:LayoutBounds( "left", "below", self.title )
        :Offset( 0, SPACING.TITLE_DESC )
    self.general_support:LayoutBounds("left", "below", self.subtitle)
        :Offset( 0, -SPACING.M1 )
    self.faction_support:LayoutBounds("left", "below", self.general_support)
        :Offset( 0, SPACING.M1 )
    self.wealth_support:LayoutBounds("left", "below", self.faction_support)
        :Offset( 0, SPACING.M1 )
    self.issue_trackers:LayoutBounds("left", "below", self.wealth_support)
        :Offset( 0, SPACING.M1 )

    if self.test_track then
        self.test_track:LayoutBounds("left", "below", self.wealth_support)
            :Offset( 0, SPACING.M1 )
    end
    -- self.graft_widgets[GRAFT_TYPE.NEGOTIATION]:LayoutBounds( "left", "below", self.text_content ):Offset( 0, -30 )
    -- self.graft_widgets[GRAFT_TYPE.COMBAT]:LayoutBounds( "after", "top", self.graft_widgets[GRAFT_TYPE.NEGOTIATION] ):Offset( SPACING.M1, 0 )

    -- Get MainOverlay's top bar height
    local overlay = TheGame:FE():FindScreen( Screen.MainOverlay )
    local overlay_topbar_height = overlay and overlay:GetTopBarHeight() or 0

    -- Calculate scroll panel size
    local left_offset = RES_X*0.15 -- How much the grid should cross to the left of the screen center
    local left_padding = 100 -- How much space should there be between the left edge of the scroll area and the first graft (allows space for glow/scaling without clipping)
    local left_screen_padding = 15
    -- self.scroll:SetLeftPadding( left_padding )
    self.content:LayoutBounds( "left", "top", 0, 0 )
    self.scroll:SetSize( self.screen_w/2 + left_offset + left_padding, self.screen_h - overlay_topbar_height )
        :SetPos( self.screen_w/4 - left_offset/2 - left_padding/2 - left_screen_padding, -overlay_topbar_height/2 )
        :RefreshView()
    return self
end
