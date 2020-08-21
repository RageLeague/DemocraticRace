local SupportEntryList = class( "DemocracyClass.Widget.SupportEntryList", Widget )

function SupportEntryList:init(widget_list, max_width)
    SupportEntryList._base.init(self)
    self.max_width = max_width or 1200
    
    self.spacing = 10

    self.entry_per_row = 3
    self:UpdateEntryWidth()

    self.hitbox = self:AddChild( Widget.SolidBox( 100, 100, 0xffff0030 ) )
        :SetTintAlpha( 0 )
        :SetSize(self.max_width, 0)

    self.widget_list = widget_list
    for i, widget in ipairs(self.widget_list) do
        self:AddChild(widget)
            :SetWidth(self.entry_width)
    end

    self:Refresh()
end

function SupportEntryList:UpdateEntryWidth()
    self.entry_width = (self.max_width - self.spacing * (self.entry_per_row + 1)) / self.entry_per_row
    return self
end

function SupportEntryList:Refresh()
    for i, widget in ipairs(self.widget_list) do
        if widget.Refresh then
            widget:Refresh()
        end
    end
    self:Layout()
    return self
end

function SupportEntryList:UpdateHitbox()
    local row = {}
    local maxrowheight = 0
    local rows = 0
    local totalheight = self.spacing

    for i, widget in ipairs(self.widget_list) do
        table.insert(row, widget)
        local w, h = widget:GetSize()
        maxrowheight = math.max(h, maxrowheight)
        -- widget:LayoutBounds("left","top", self):Offset(self.spacing * #row + self.entry_width * (#row - 1), -totalheight)
        if #row >= self.entry_per_row then
            totalheight = totalheight + maxrowheight + self.spacing
            rows = rows + 1
            table.clear(row)
            maxrowheight = 0
        end
    end
    if maxrowheight == 0 then
        totalheight = totalheight + self.spacing
    else
        totalheight = totalheight + self.spacing + maxrowheight + self.spacing
    end
    self.hitbox:SetSize(self.max_width, totalheight)
    return self
end

function SupportEntryList:Layout()

    self:UpdateHitbox()

    local row = {}
    local maxrowheight = 0
    local rows = 0
    local totalheight = self.spacing

    for i, widget in ipairs(self.widget_list) do
        table.insert(row, widget)
        local w, h = widget:GetSize()
        maxrowheight = math.max(h, maxrowheight)
        widget:LayoutBounds("left","top", self):Offset(self.spacing * #row + self.entry_width * (#row - 1), -totalheight)
        if #row >= self.entry_per_row then
            totalheight = totalheight + maxrowheight + self.spacing
            rows = rows + 1
            table.clear(row)
            maxrowheight = 0
        end
    end
    -- if maxrowheight == 0 then
    --     totalheight = totalheight + self.spacing
    -- else
    --     totalheight = totalheight + self.spacing + maxrowheight + self.spacing
    -- end
    -- self.hitbox:SetSize(self.max_width, totalheight)
    return self
end
local FactionSupportEntryList = class( "DemocracyClass.Widget.FactionSupportEntryList", SupportEntryList )

function FactionSupportEntryList:init(evergreen_faction, max_width)
    local faction_list = evergreen_faction or {"FEUD_CITIZEN", "ADMIRALTY", "SPARK_BARONS",
        "CULT_OF_HESH", "BANDITS", "JAKES", "RISE"}
    for id, val in pairs(TheGame:GetGameState():GetMainQuest().param.faction_support) do
        if not table.arraycontains(faction_list, id) then
            table.insert(faction_list, id)
        end
    end
    local widget_list = {}
    for i, id in ipairs(faction_list) do
        table.insert(widget_list, DemocracyClass.Widget.FactionSupportEntry(id))
    end
    FactionSupportEntryList._base.init(self, widget_list, max_width)
end


local TitledEntryList = class( "DemocracyClass.Widget.TitledEntryList", Widget )

function TitledEntryList:init(widget, max_width)
    TitledEntryList._base.init(self)

    self.max_width = max_width or 1200
    self.text_content = self:AddChild(Widget())
    self.title = self.text_content:AddChild( Widget.Label("title", FONT_SIZE.SCREEN_TITLE ) )
        -- :SetText( loc.upper( "Support Analysis" ) )
        :SetGlyphColour( UICOLOURS.GRAFT )
        -- :SetAutoSize(DETAILS_W)
        :LeftAlign()
        :SetWordWrap(true)
        :Bloom(0.15)

        :SetShown(false)
    self.subtitle = self.text_content:AddChild( Widget.Label("title", FONT_SIZE.BODY_TEXT ) )
        -- :SetText( "Here describes ways of support lol" )
        :SetGlyphColour( UICOLOURS.GRAFT )
        -- :SetAutoSize(DETAILS_W)
        :LeftAlign()
        :SetWordWrap(true)
        :SetTintAlpha( 0.8 )
        :Bloom(0.1)
    self.content = self:AddChild(widget)
end