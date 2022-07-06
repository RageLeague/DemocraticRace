local old_refresh = Widget.CardWidget.RefreshSlime

local fervor_overlay = engine.asset.Texture( "DEMOCRATICRACE:assets/ui/fervor_overlay.png")

function Widget.CardWidget:RefreshSlime(...)
    local res = old_refresh(self, ...)
    if is_instance( self.card, Negotiation.Card ) then
        if self.card and self.card.features and (self.card.features.FERVOR or 0) > 0 then
            if not self.fervor_widget then
                local upgrade_idx = table.arrayfind( self.contents.children, self.upgrade_overlay )
                self.fervor_widget = self.contents:AddChild( Widget.Image( fervor_overlay ), upgrade_idx and (upgrade_idx + 1) )
            end
        else
            if self.fervor_widget then
                self.fervor_widget:Remove()
                self.fervor_widget = nil
            end
        end
    end
    return res
end
