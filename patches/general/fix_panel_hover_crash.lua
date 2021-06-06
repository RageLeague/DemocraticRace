local patch_id = "FIX_PANEL_HOVER_CRASH"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Widget.NegotiationPanel.AddDamagePreviewArrow
function Widget.NegotiationPanel:AddDamagePreviewArrow(source, target, arrow_idx, ...)
    local res = old_fn(self, source, target, arrow_idx, ...)
    return res or arrow_idx
end