local SupportEntryList = class( "DemocracyClass.Widget.SupportEntryList", Widget )

function SupportEntryList:init(widget_list, max_width, entry_per_row)
    SupportEntryList._base.init(self)
    self.max_width = max_width or 1200
    
    self.spacing = 10

    self.entry_per_row = entry_per_row or 3
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

function SupportEntryList:GetDefaultFocus()
    return self.widget_list and self.widget_list[1]
end

function SupportEntryList:Refresh(...)
    for i, widget in ipairs(self.widget_list) do
        if widget.Refresh then
            widget:Refresh(...)
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
        -- print(widget, "offset by", self.spacing * #row + self.entry_width * (#row - 1), totalheight)
        widget:LayoutBounds("left","top", self.hitbox):Offset(self.spacing * #row + self.entry_width * (#row - 1), -totalheight)
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
            local selector = Selector()
            selector:FromAllAgents()
            selector:Where(function(agent)
                return agent:GetFactionID() == id
            end)
            selector:Where(DemocracyUtil.CanVote)
            if selector:Pick() then
                table.insert(faction_list, id)
            end
        end
    end
    local widget_list = {}
    for i, id in ipairs(faction_list) do
        table.insert(widget_list, DemocracyClass.Widget.FactionSupportEntry(id))
    end
    FactionSupportEntryList._base.init(self, widget_list, max_width)
end

local WealthSupportEntryList = class( "DemocracyClass.Widget.WealthSupportEntryList", SupportEntryList )

function WealthSupportEntryList:init(max_width)

    local widget_list = {}
    for i = 1, DemocracyConstants.wealth_levels do
        table.insert(widget_list, DemocracyClass.Widget.WealthSupportEntry(i))
    end
    WealthSupportEntryList._base.init(self, widget_list, max_width)
end

local GeneralSupportEntryList = class( "DemocracyClass.Widget.GeneralSupportEntryList", SupportEntryList )

function GeneralSupportEntryList:init(max_width)

    local widget_list = {DemocracyClass.Widget.GeneralSupportEntry(), DemocracyClass.Widget.SupportExpectationEntry()}
    GeneralSupportEntryList._base.init(self, widget_list, max_width, 2)
end

local StancesEntryList = class( "DemocracyClass.Widget.StancesEntryList", SupportEntryList )

function StancesEntryList:init(max_width)

    local widget_list = {}
    for i, id, data in sorted_pairs(TheGame:GetGameState():GetMainQuest().param.stances) do
        local widget = DemocracyClass.Widget.PoliticalIssueTrack(max_width)
            :SetIssue(id)
            :AddAgent(TheGame:GetGameState():GetPlayerAgent())
        
        for i, agent in ipairs(DemocracyUtil.GetStanceIntel()) do
            widget:AddAgent(agent)
        end

        table.insert(widget_list,widget)
    end
    StancesEntryList._base.init(self, widget_list, max_width, 1)
end