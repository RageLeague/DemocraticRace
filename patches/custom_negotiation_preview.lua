local patch_id = "CUSTOM_NEGOTIATION_PREVIEW"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local NegotiationSlot = Widget.NegotiationSlot
local old_preview_fn = NegotiationSlot.CreateDamagePreview

local assets =
{
    attack = engine.asset.Texture( "UI/fightscreen_damagepreview.tex" ),
}

function NegotiationSlot:CreateDamagePreviewLabel(source, min_delta, max_delta )
    if not max_delta then
        max_delta = min_delta
    end
    local w = Widget()

    -- Preview bg
    local img = Widget.Image( assets.attack, 54, 54 )
    img:Bloom( 0.1 )
    w:AddChild( img )
    w.img = img
    w.source = source

    local label = Widget.Label( "title", 24 ):EnableOutline( true ):SetGlyphColour( UICOLOURS.WHITE )
    -- local min_delta, max_delta = self.minigame:PreviewPersuasion( source )

    if min_delta ~= max_delta then
        label:SetText( loc.format( "{1}-{2}", min_delta, max_delta ))
    else
        label:SetText( tostring( max_delta ))
    end
    w:AddChild( label ):LayoutBounds("center","center", img ):Offset( 0, 2 )
    w:SetToolTip( loc.format( LOC"UI.NEGOTIATION_PANEL.DAMAGE_RECEIVED_TOOLTIP", max_delta, source.owner:GetName() ) )

    self.damage_preview_root:AddChild( w ):LayoutBounds( "after", "center" ):Offset( -10, 0 )
    table.insert( self.damage_previews, w )
    print("Preview Damage", source, min_delta, max_delta)
end
function NegotiationSlot:CreateDamagePreview( source )
    -- old_preview_fn(self, source)
    -- print("Stuff")
    -- print(source)
    print(source._classname)
    if source.CustomDamagePreview then
        -- print("Has custom preview")
        source:CustomDamagePreview(self.minigame, self, self.modifier)
    else
        old_preview_fn(self, source)
    end
end