local patch_id = "UNHIGHLIGHT_CARD_UPGRADE"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)
local old_fn = CardEngine.GenerateCardDesc
function CardEngine.GenerateCardDesc( card, widget, engine, defs, hilight_upgrades, ... )
    local res = old_fn(card, widget, engine, defs, hilight_upgrades, ...)
    if res and not hilight_upgrades then
        res = SanitizeString( res, "<#UPGRADE>" )
        res = SanitizeString( res, "<#DOWNGRADE>" )
    end
    return res
end