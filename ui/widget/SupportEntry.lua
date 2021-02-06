local SupportEntry = class( "DemocracyClass.Widget.SupportEntry", Widget )

function SupportEntry:init(icon_size, max_width)
    SupportEntry._base.init( self )

    self.spacing = 5

    -- self.max_width = max_width or 400
    self.icon_size = icon_size or 72
    
    self:SetWidth(max_width or 400, true)
    -- self.text_width = self.max_width - self.icon_size - self.spacing * 3 -- - 10 - SPACING.M1*2

    self.hitbox = self:AddChild( Widget.SolidBox( 100, 100, 0xffff0030 ) )
        :SetTintAlpha( 0 )

    self.background = self:AddChild( Widget.Panel( engine.asset.Texture("UI/left_border_frame_faint.tex" ) ) )
        :SetBloom( 0.15 )

    self.icon = self:AddChild(Widget.Image())
        :SetSize(self.icon_size, self.icon_size)
        :SetBloom(0.1)
        -- :SetTexture(icon)
        -- :SetShown(icon ~= nil)
        -- :LayoutBounds("left", "center", 0, 0)
    -- self.details = self:AddChild(Widget())
        --:SetSize(self.text_width, self.icon_size)

    self.text = self:AddChild( Widget.Label("body", 50 ))
        :SetGlyphColour( UICOLOURS.SUBTITLE )
        :SetTintAlpha( 0.8 )
        :Bloom(0.05)
        :SetAutoSize( self.text_width )
        :LeftAlign()
        -- :LayoutBounds("left", "center", 144, 0)
    
    self:Refresh()
end

function SupportEntry:SetIcon(icon)
    self.icon:SetTexture(icon)
    return self
end

function SupportEntry:SetText(text)
    self.text:SetText(text)
        :SetAutoSize( self.text_width )
    self:Layout()
    return self
end
function SupportEntry:SetWidth(width, no_refresh)
    self.max_width = width
    self.text_width = self.max_width - self.icon_size - self.spacing * 3
    if not no_refresh then
        self:Refresh()
    end
    return self
end

function SupportEntry:SetTextWidth(width, no_refresh)
    self.text_width = width
    self.max_width = self.text_width + self.icon_size + self.spacing * 3
    if not no_refresh then
        self:Refresh()
    end
    return self
end

function SupportEntry:GetSize()
    return self.hitbox:GetSize()
end
-- Just so things don't break
function SupportEntry:Refresh()
    local sizew, sizeh = self.icon:GetSize()

    self.text:SetFontSize(50)
    
    local textw, texth = self.text:GetSize()

    -- self.text:SetSize(textw, texth)
    -- self.text:TryFitToRegion(30,50)
    if textw > self.text_width then
        self.text:SetFontSize(math.min(50, 50 * self.text_width / textw))
    end
    
    self.hitbox:SetSize(self.max_width, sizeh + self.spacing * 2)
    self.background:SetSize(self.max_width, sizeh + self.spacing * 2)

    return self:Layout()
end

function SupportEntry:Layout()
    

    self.icon:LayoutBounds("left", "top"):Offset(self.spacing, -self.spacing)
    -- self.details:LayoutBounds("after","center")--:SetAutoSize( self.text_width ):LayoutBounds("after", "center")
    -- print(self.text.text)
    self.text:LayoutBounds("after","center", self.icon):Offset(self.spacing, 0)
    return self
end

function SupportEntry:SetColour(color)
    self.background:SetTintColour( color )
    self.text:SetGlyphColour( color )
    return self
end


local FactionSupportEntry = class( "DemocracyClass.Widget.FactionSupportEntry", DemocracyClass.Widget.SupportEntry )

function FactionSupportEntry:init(faction, icon_size, max_width)
    FactionSupportEntry._base.init(self, icon_size, max_width)

    if type(faction) == "string" then
        self.faction = TheGame:GetGameState():GetFaction(faction)
    else
        self.faction = faction
    end
    assert(is_instance(self.faction, Faction), loc.format("Not a faction:{1}", self.faction))
    self:Refresh()
end

function FactionSupportEntry:Refresh()
    if self.faction then
        self:SetIcon(self.faction:GetIcon())
        self:SetText(
            loc.format(LOC"DEMOCRACY.SUPPORT_ENTRY.FACTION_SUPPORT", 
                self.faction, 
                DemocracyUtil.TryMainQuestFn("GetFactionSupport", self.faction.id)
            )
        )
        if self.faction:GetColour() then
            self:SetColour(self.faction:GetColour())
        end
    end
    return FactionSupportEntry._base.Refresh(self)
end

local WealthSupportEntry = class( "DemocracyClass.Widget.WealthSupportEntry", DemocracyClass.Widget.SupportEntry )

function WealthSupportEntry:init(renown, icon_size, max_width)
    WealthSupportEntry._base.init(self, icon_size, max_width)

    self.renown = renown or 1

    self:Refresh()
end

function WealthSupportEntry:Refresh()
    self:SetIcon(DemocracyUtil.GetWealthIcon(self.renown))
    self:SetText(
        loc.format(LOC"DEMOCRACY.SUPPORT_ENTRY.WEALTH_SUPPORT", 
            self.renown, 
            DemocracyUtil.TryMainQuestFn("GetWealthSupport", self.renown)
        )
    )
    self:SetColour(DemocracyUtil.GetWealthColor(self.renown))
    -- if self.faction:GetColour() then
    --     self:SetColour(self.faction:GetColour())
    -- end
    return WealthSupportEntry._base.Refresh(self)
end

local GeneralSupportEntry = class( "DemocracyClass.Widget.GeneralSupportEntry", DemocracyClass.Widget.SupportEntry )

function GeneralSupportEntry:init(icon_size, max_width)
    GeneralSupportEntry._base.init(self, icon_size, max_width)

    -- self.renown = renown or 1

    self:Refresh()
end

function GeneralSupportEntry:Refresh()
    self:SetIcon(DemocracyConstants.icons.support)
    self:SetText(
        loc.format(LOC"DEMOCRACY.SUPPORT_ENTRY.GENERAL_SUPPORT", 
            DemocracyUtil.TryMainQuestFn("GetGeneralSupport")
        )
    )
    self:SetColour(0x00cc00ff)
    -- if self.faction:GetColour() then
    --     self:SetColour(self.faction:GetColour())
    -- end
    return GeneralSupportEntry._base.Refresh(self)
end

local SupportExpectationEntry = class( "DemocracyClass.Widget.SupportExpectationEntry", DemocracyClass.Widget.SupportEntry )

function SupportExpectationEntry:init(icon_size, max_width)
    SupportExpectationEntry._base.init(self, icon_size, max_width)

    -- self.renown = renown or 1

    self:Refresh()
end

function SupportExpectationEntry:Refresh()
    self:SetIcon(DemocracyConstants.icons.support)
    self:SetText(
        loc.format(LOC"DEMOCRACY.SUPPORT_ENTRY.SUPPORT_EXPECTATION", 
            DemocracyUtil.TryMainQuestFn("GetCurrentExpectation"),
            DemocracyUtil.TryMainQuestFn("GetDayEndExpectation")
        )
    )
    self:SetColour(0x00ccccff)
    -- if self.faction:GetColour() then
    --     self:SetColour(self.faction:GetColour())
    -- end
    return SupportExpectationEntry._base.Refresh(self)
end