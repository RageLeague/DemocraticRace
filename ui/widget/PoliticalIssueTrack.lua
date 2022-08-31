local assets = {
    gradient = engine.asset.Texture("UI/compendium_graft_gradient.tex"),
    bg = engine.asset.Texture("UI/compendium_graft_bg.tex"),
    white = engine.asset.Texture( "images/white.tex" ),
    glow = engine.asset.Texture( "UI/grifts_progress_glow.tex" ),
    track = engine.asset.Texture( "DEMOCRATICRACE:assets/ui/opinion_track.png" ),
    -- arrrow = engine.asset.Texture( "UI/grifts_progress_arrow.tex" ),
    complete = engine.asset.Texture("UI/compendium_grift_complete.tex"),
}

local OUTLINE_SIZE = 3

local STANCE_INDICES = { -2, -1.5, -1, 0, 1, 1.5, 2 }

local PoliticalIssueTrack = class( "DemocracyClass.Widget.PoliticalIssueTrack", Widget.Clickable )

function PoliticalIssueTrack:init(max_width, max_height, spacing)
    PoliticalIssueTrack._base.init( self )

    self.widget_w = max_width or 1200
    self.widget_h = max_height or 180

    self.spacing = spacing or 5

    self.icon_size = 40
    self.portrait_offset = 40

    self.hitbox = self:AddChild( Widget.SolidBox( 100, 100, 0xffff0030 ) )
        :SetTintAlpha( 0 )

    self.background = self:AddChild( Widget.Panel( engine.asset.Texture("UI/left_border_frame_faint.tex" ) ) )
        :SetBloom( 0.15 )

    self.opinion_track = self:AddChild( Widget() )
        -- :SetTintColour(0x00ff00ff)

    self.opinion_outline_rect = self.opinion_track:AddChild( Widget.SolidBox( 100, 100, UICOLOURS.BLACK ) )

    self.opinion_track_rect = self.opinion_track:AddChild( Widget.Image( assets.white ) )
        :Bloom( 0.15 )
        :SetTintColour(0xff0000ff)
    self.opinion_track_secondary = self.opinion_track:AddChild( Widget.Image( assets.track ) )
        :Bloom( 0.15 )
        :SetTintColour(0x0000ffff)

    self.issue_title = self:AddChild(Widget.Label("body", 48 ):LeftAlign())

    self.stance_icons = {}

    self.agent_portraits = {}

    for _, i in ipairs(STANCE_INDICES) do
        self.stance_icons[i + 3] = self:AddChild(DemocracyClass.Widget.StanceIcon(self.icon_size):SetDefaultIcon(i))
        if i >= -1 and math.round(i) == i then
            self.stance_icons[i + 3]:SetFocusDir("left", self.stance_icons[i + 2], true)
        end
    end

    self:SetOnClickFn(function()
        -- if not table.arraycontains(self.stance_icons, TheGame:FE():GetFocusWidget()) then
        self.stance_icons[1]:SetFocus()
        -- end
    end)

    self:Refresh()
end

function PoliticalIssueTrack:SetSize(w, h)
    self.widget_w = w or self.widget_w
    self.widget_h = h or self.widget_h
    self:Refresh()
    return self
end
function PoliticalIssueTrack:SetWidth(w)
    return self:SetSize(w)
end
function PoliticalIssueTrack:SetHeight(h)
    return self:SetSize(nil, h)
end
function PoliticalIssueTrack:GetSize()
    return self.hitbox:GetSize()
end

function PoliticalIssueTrack:AddAgent(agent)
    if agent then
        for i, widget in ipairs(self.agent_portraits) do
            if widget.agent == agent then
                return self
            end
        end
        table.insert(self.agent_portraits, self:AddChild(Widget.TrackedAgentPortrait(agent)))
        self:Refresh()
    end
    return self
end

function PoliticalIssueTrack:Refresh()

    self.track_w = self.widget_w - SPACING.M1*2
    self.track_w_inner = self.track_w - OUTLINE_SIZE*2
    self.track_h = 15

    self.text_w = self.widget_w - SPACING.M1 * 2

    self.hitbox:SetSize(self.widget_w, self.widget_h)
    self.background:SetSize(self.widget_w, self.widget_h)

    self.opinion_outline_rect:SetSize(self.track_w, self.track_h)
    self.opinion_track_rect:SetSize(self.track_w_inner, self.track_h - OUTLINE_SIZE*2)
    self.opinion_track_secondary:SetSize(self.track_w_inner, self.track_h - OUTLINE_SIZE*2)

    if self.issue then
        self.issue_title:SetText(self.issue:GetLocalizedName())
            :SetAutoSize( self.text_w )
    end
    -- self.opinion_track_glow:SetSize(self.opinion_w_inner, self.opinion_h - OUTLINE_SIZE*2)
    self:Layout()
    return self
end

function PoliticalIssueTrack:SetIssue(issue)
    if type(issue) == "string" then
        issue = DemocracyConstants.issue_data[issue]
    end
    assert(issue == nil or is_instance(issue, DemocracyClass.IssueLocDef), "Not an issue")
    self.issue = issue

    if self.issue then
        self:SetToolTipClass(Widget.TooltipCodex)
        self:SetToolTip(self.issue)
        self:ShowToolTipOnFocus()
        for i = -2, 2 do
            self.stance_icons[i + 3]:SetStance(self.issue.stances[i], i)
        end
    end

    self:Refresh()
    return self
end
function PoliticalIssueTrack:Layout()
    -- self.hitbox:LayoutBounds("center", "center", self)
    -- self.background:LayoutBounds("center", "center", self.hitbox)

    self.opinion_track:LayoutBounds("center", "bottom", self.hitbox):Offset(0, self.icon_size + 2 * self.spacing)
    self.issue_title:LayoutBounds("left", "top", self.hitbox):Offset(SPACING.M1, -self.spacing)
    for i, icon in pairs(self.stance_icons) do
        local percent_align = (i - 1) / 4
        icon:LayoutBounds("center", "bottom", self.hitbox):Offset(math.round((self.track_w - self.icon_size) * (percent_align - .5)), self.spacing)
    end

    if self.issue then
        local stance_groupings = {}
        for _, i in ipairs(STANCE_INDICES) do
            stance_groupings[i + 3] = {}
        end
        local player_special_index
        for i, widget in ipairs(self.agent_portraits) do
            local stance = self.issue:GetAgentStanceIndex(widget.agent) or 0
            if widget.agent:IsPlayer() and DemocracyUtil.GetStanceChangeFreebie(self.issue) then
                widget:SetToolTip(loc.format(LOC"DEMOCRACY.SUPPORT_SCREEN.CURRENT_STANCE_LOOSE", widget.agent, self.issue.stances[stance]))
                if stance > 0 then
                    player_special_index = 4.5
                elseif stance < 0 then
                    player_special_index = 1.5
                end
            else
                widget:SetToolTip(loc.format(LOC"DEMOCRACY.SUPPORT_SCREEN.CURRENT_STANCE", widget.agent, self.issue.stances[stance]))
            end
            if not (widget.agent:IsPlayer() and player_special_index) then
                table.insert(stance_groupings[stance + 3], widget)
            else
                table.insert(stance_groupings[player_special_index], widget)
            end
        end
        local barx, bary = self.stance_icons[1]:TransformFromWidget(self.opinion_track)
        for i, group in pairs(stance_groupings) do
            if #group > 0 then
                for j, widget in ipairs(group) do
                    local offset = j - ((#group + 1) / 2)
                    if i == 1 then
                        offset = j - 1
                    elseif i == 5 then
                        offset = j - #group
                    end
                    widget:LayoutBounds("center","above", self.stance_icons[i]):Offset(math.round(offset * self.portrait_offset), bary - 15)
                end
            end
        end
    end
    return self
end

function PoliticalIssueTrack:UpdateImage()
    if self.hover or self.focus then
        self.background:SetTexture( engine.asset.Texture( "UI/left_border_frame_faint_border.tex" ) )
            :MoveTo( 6, 0, 0.2, easing.outQuad )
    else
        self.background:SetTexture( engine.asset.Texture( "UI/left_border_frame_faint.tex" ) )
            :MoveTo( 0, 0, 0.2, easing.outQuad )
    end
end

function PoliticalIssueTrack:OnGainFocus()
    PoliticalIssueTrack._base.OnGainFocus(self)
    self:UpdateImage()
end

function PoliticalIssueTrack:OnLoseFocus()
    PoliticalIssueTrack._base.OnLoseFocus(self)
    self:UpdateImage()
end

function PoliticalIssueTrack:OnGainHover()
    PoliticalIssueTrack._base.OnGainHover(self)
    self:UpdateImage()
end

function PoliticalIssueTrack:OnLoseHover()
    PoliticalIssueTrack._base.OnLoseHover(self)
    self:UpdateImage()
end
