local StanceIcon = class( "DemocracyClass.Widget.StanceIcon", Widget.Clickable )

local DEFAULT_ICON = {
    [-2] = global_images.relationship_level[RELATIONSHIP.HATED],
    [-1] = global_images.relationship_level[RELATIONSHIP.DISLIKED],
    [0] = global_images.relationship_level[RELATIONSHIP.NEUTRAL],
    [1] = global_images.relationship_level[RELATIONSHIP.LIKED],
    [2] = global_images.relationship_level[RELATIONSHIP.LOVED],
    
}

function StanceIcon:init( size )
    StanceIcon._base.init( self )

    size = size or 40

    self.icon_size = size

    self.icon = self:AddChild( Widget.Image( DEFAULT_ICON[0], size, size ) )
    self.stance = nil

    self:SetOnClickFn(function()
        self:SetFocus()
    end)
end
function StanceIcon:SetIcon(icon)
    self.icon:SetTexture(icon)
    return self
end
function StanceIcon:SetDefaultIcon(idx)
    self:SetIcon(DEFAULT_ICON[idx])
    self:Refresh()
    return self
end

function StanceIcon:SetStance(stance, idx)
    self.stance = stance
    if idx then
        self:SetIcon(DEFAULT_ICON[idx])
    end
    self:Refresh()
    return self
end
function StanceIcon:Refresh()
    if self.stance then
        self:SetToolTipClass(Widget.TooltipCodex)
        self:SetToolTip(self.stance)
        self:ShowToolTipOnFocus()
    end
    return self
end

function StanceIcon:UpdateImage()
    if self.focus then
        self.icon:Bloom(0.15)
    else
        self.icon:Bloom(0)
    end
end

function StanceIcon:OnGainFocus()
    StanceIcon._base.OnGainFocus(self)
    self:UpdateImage()
end

function StanceIcon:OnLoseFocus()
    StanceIcon._base.OnLoseFocus(self)
    self:UpdateImage()
end

function StanceIcon:OnGainHover()
    StanceIcon._base.OnGainHover(self)
    self:UpdateImage()
end

function StanceIcon:OnLoseHover()
    StanceIcon._base.OnLoseHover(self)
    self:UpdateImage()
end
