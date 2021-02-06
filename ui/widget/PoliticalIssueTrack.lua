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

local PoliticalIssueTrack = class( "DemocracyClass.Widget.PoliticalIssueTrack", Widget )

function PoliticalIssueTrack:init(max_width, max_height, spacing)
    PoliticalIssueTrack._base.init( self )

    self.widget_w = max_width or 1200
    self.widget_h = max_height or 120

    self.spacing = spacing or 5

    self.icon_size = 40

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

    self.issue_title = self:AddChild(Widget.Label("body", 36 ):LeftAlign())

    self.stance_icons = {}

    for i = -2, 2 do
        table.insert(self.stance_icons, self:AddChild(DemocracyClass.Widget.StanceIcon(self.icon_size):SetDefaultIcon(i)))
    end

    self:Refresh()
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
        for i = -2, 2 do
            self.stance_icons[i + 3]:SetStance(self.issue.stances[i], i)
        end
    end

    self:Refresh()
    return self
end
function PoliticalIssueTrack:Layout()
    self.hitbox:LayoutBounds("center", "center", self)
    self.background:LayoutBounds("center", "center", self)

    self.opinion_track:LayoutBounds("center", "center", self.hitbox)
    self.issue_title:LayoutBounds("left", "top", self.hitbox):Offset(SPACING.M1, -self.spacing)
    for i, icon in ipairs(self.stance_icons) do
        local percent_align = (i - 1) / (#self.stance_icons - 1)
        icon:LayoutBounds("center", "bottom", self.hitbox):Offset(math.round((self.track_w - self.icon_size) * (percent_align - .5)), self.spacing)
    end
end