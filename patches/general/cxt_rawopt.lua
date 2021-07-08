local patch_id = "CXT_RAWOPT"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

function ConvoStateGraph:RawOpt(txt, id, ...)
    txt = self.enc:LocFormat( txt, ... )
    local opt = ConvoOption( txt )
    self.encounter:AddOption( opt )

    opt.loc_id = id
    
    if self.quest and #self.enc.hub_stack == 1 and self.enc.hub_stack[1].hub_state == HUB_STATE.HUB then
        opt:SetQuestMark()
    end

    return opt
end
function ConvoStateGraph:RawDialog(txt, id, ...)
    if id then
        self.fresh_dialog = not TheGame:GetGameState():HasDialogMemory(id)
        TheGame:GetGameState():RememberDialog(id)
    end
    txt = self.enc:LocFormat( txt, ... )
    self.fresh_dialog = nil

    self.enc:Dialog(txt)
end
function ConvoOption:RawDialog(txt, id, ...)
    self:PushHandler( self.hub.RawDialog, self.hub, txt, id, ...)
    return self
end