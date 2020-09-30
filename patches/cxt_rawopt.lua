local patch_id = "CXT_RAWOPT"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

function ConvoStateGraph:RawOpt(txt, id)
    local opt = ConvoOption( txt )
    self.encounter:AddOption( opt )

    opt.loc_id = id
    
    if self.quest and #self.enc.hub_stack == 1 and self.enc.hub_stack[1].hub_state == HUB_STATE.HUB then
        opt:SetQuestMark()
    end

    return opt
end