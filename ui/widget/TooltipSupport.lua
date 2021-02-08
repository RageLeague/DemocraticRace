-- require "ui/widget"
-- require "ui/widgets/panel"
-- require "ui/widgets/label"

local panel_w = 412
local panel_h = 128
local padding = 8
local image_size = panel_h
local text_w = panel_w - image_size
local min_score_width = 172
local line_size = 22

local TooltipSupport = class("DemocracyClass.Widget.TooltipSupport", Widget)

function TooltipSupport:init()
	TooltipSupport._base.init(self)
	self.bg = self:AddChild(Widget.Panel(global_images.tooltipbg))
    self.bg:SetNineSliceBorderScale( 0.5 )

    self.contents = self:AddChild(Widget())

    self.title = Widget.Label("title", 28, "")
        :SetAutoSize( text_w )
        :SetWordWrap( true )
        :LeftAlign()
        :SetGlyphColour(UICOLOURS.BODYTEXT)
        :Bloom(0.1)
    self.text = Widget.Label("tooltip", 22)
        :SetAutoSize( text_w )
        :SetWordWrap( true )
        :LeftAlign()
        :OverrideLineHeight( 18 )
        :SetGlyphColour( UICOLOURS.TOOLTIP_TEXT )
        :Bloom(0.1)

    self.gain_title = Widget.Label("title", 28, "")
        :SetAutoSize( text_w )
        :SetWordWrap( true )
        :LeftAlign()
        :SetGlyphColour(UICOLOURS.BONUS)
        :Bloom(0.1)
    self.gain_desc = Widget()

    self.loss_title = Widget.Label("title", 28, "")
        :SetAutoSize( text_w )
        :SetWordWrap( true )
        :LeftAlign()
        :SetGlyphColour(UICOLOURS.PENALTY)
        :Bloom(0.1)
    self.loss_desc = Widget()

    self.contents:AddChildren{
        self.title,
        self.text,
        self.gain_title,
        self.gain_desc,
        self.loss_title,
        self.loss_desc,
    }
	self:Hide()
end

function TooltipSupport:DoLayout( support_item )
    if type(support_item) ~= "table" then
        return
    end
    support_item.gain_table = support_item.gain_table or {}
    support_item.loss_table = support_item.loss_table or {}
    -- DBG(support_item)
    local sizeX, sizeY = 0, 0;

    local title = support_item.title
    if title then
        self.title:SetText( title ):Show()
        local x, y = self.title:GetSize()
        if x > sizeX then
            sizeX = x
        end
    else
        self.title:Hide()
    end
    if support_item.desc then
        self.text:SetText( support_item.desc ):Show()
        self.text:LayoutBounds( "left", "below" )
            :Offset( 0, 2 )
        local x, y = self.text:GetSize()
        if x > sizeX then
            sizeX = x
        end
    else
        self.text:Hide()
    end

    -- Gain sources
    self.gain_desc:DestroyAllChildren()
    local order = copykeys(support_item.gain_table)
    table.sort(order, function(a,b)
        return support_item.gain_table[a] > support_item.gain_table[b]
            or (support_item.gain_table[a] == support_item.gain_table[b] and a > b)
    end)
    for i, id in ipairs(order) do
        local block = self.gain_desc:AddChild( Widget() )

        block.title = block:AddChild( Widget.Label( "title", line_size, LOC("DEMOCRACY.DELTA_SUPPORT_REASON." .. id)))
            :SetGlyphColour( UICOLOURS.SUBTITLE )
            :SetWordWrap( true )
            :SetAutoSize( text_w )
            :OverrideLineHeight( 18 )
            :LeftAlign()
            :Bloom( 0.08 )

        block.vals = block:AddChild( Widget.Label( "title", line_size, support_item.gain_table[id]) )
            :LayoutBounds( "before", "bottom", block.title )
            :Offset( math.max(min_score_width, sizeX), 0 )
    end
    self.gain_desc:StackChildren( 6 )
    if #order > 0 then
        self.gain_title:Show()
            :SetText(LOC"DEMOCRACY.SUPPORT_SCREEN.GAIN_SOURCE")
            :LayoutBounds("left", "below")
            :Offset(0, -6)
        self.gain_desc:Show():LayoutBounds( "left", "below" )
            :Offset(0, 2)
    else
        self.gain_title:Hide()
        self.gain_desc:Hide()
    end

    -- Loss sources
    self.loss_desc:DestroyAllChildren()
    local order = copykeys(support_item.loss_table)
    table.sort(order, function(a,b)
        return support_item.loss_table[a] > support_item.loss_table[b]
            or (support_item.loss_table[a] == support_item.loss_table[b] and a > b)
    end)
    for i, id in ipairs(order) do
        local block = self.loss_desc:AddChild( Widget() )

        block.title = block:AddChild( Widget.Label( "title", line_size, LOC("DEMOCRACY.DELTA_SUPPORT_REASON." .. id)))
            :SetGlyphColour( UICOLOURS.SUBTITLE )
            :SetWordWrap( true )
            :SetAutoSize( text_w )
            :OverrideLineHeight( 18 )
            :LeftAlign()
            :Bloom( 0.08 )

        block.vals = block:AddChild( Widget.Label( "title", line_size, support_item.loss_table[id]) )
            :LayoutBounds( "before", "bottom", block.title )
            :Offset( math.max(min_score_width, sizeX), 0 )
    end
    self.loss_desc:StackChildren( 6 )
    if #order > 0 then
        self.loss_title:Show()
            :SetText(LOC"DEMOCRACY.SUPPORT_SCREEN.LOSS_SOURCE")
            :LayoutBounds("left", "below")
            :Offset(0, -6)
        self.loss_desc:Show():LayoutBounds( "left", "below" )
            :Offset(0, 2)
    else
        self.loss_title:Hide()
        self.loss_desc:Hide()
    end
    
    
    self.contents:SetRegistration("center", "center")
    self.bg:SizeToWidgets( padding, self.contents )
    
end
