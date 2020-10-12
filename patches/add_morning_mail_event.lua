local patch_id = "ADD_MORNING_MAIL_EVENT"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local oldfn = ConvoUtil.DoMorningMail

function ConvoUtil.DoMorningMail(cxt)
    oldfn(cxt)

    TheGame:BroadcastEvent( "morning_mail", cxt ) 
end