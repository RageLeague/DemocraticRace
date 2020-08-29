

AddNotification("DELTA_GENERAL_SUPPORT",{
    sfx = SoundEvents.notification_relationship_new,
    img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, delta, current )
        
        if delta >= 0 then
            notification.banner_txt = loc.format(LOC"DEMOCRACY.NOTIFICATION.GENERAL_SUPPORT.TITLE_INCREASE", delta)
            notification.details = loc.format(LOC"DEMOCRACY.NOTIFICATION.GENERAL_SUPPORT.TITLE_DECREASE", current)
        else
            notification.banner_txt = loc.format(LOC"DEMOCRACY.NOTIFICATION.GENERAL_SUPPORT.DETAIL_INCREASE", -delta)
            notification.details = loc.format(LOC"DEMOCRACY.NOTIFICATION.GENERAL_SUPPORT.DETAIL_DECREASE", current)
        end
    end,
})
-- AddNotification("DELTA_FACTION_SUPPORT",{
--     sfx = SoundEvents.notification_relationship_new,
--     img = DemocracyConstants.icons.support,
--     FormatNotification = function( self, notification, delta, current, faction )
        
--         if delta >= 0 then
--             notification.banner_txt = loc.format("Gained {1} Support From {2}", delta, faction:GetName())
--             notification.details = loc.format("Your support level from {2} is increased to {1}.", current, faction:GetName())
--         else
--             notification.banner_txt = loc.format("Lost {1} Support From {2}", -delta, faction:GetName())
--             notification.details = loc.format("Your support level from {2} is decreased to {1}.", current, faction:GetName())
--         end
--     end,
-- })
AddNotification("DELTA_FACTION_SUPPORT",{
    sfx = SoundEvents.notification_relationship_new,
    -- img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, delta, current, faction )
        
        if delta >= 0 then
            notification.banner_txt = loc.format("Gained {1} Support From {2#faction}", delta, faction)
            notification.details = loc.format("Your support level from {2#faction} is increased to {1}.", current, faction)
        else
            notification.banner_txt = loc.format("Lost {1} Support From {2#faction}", -delta, faction)
            notification.details = loc.format("Your support level from {2#faction} is decreased to {1}.", current, faction)
        end
        notification.img = faction:GetIcon()
    end,
})
AddNotification("DELTA_WEALTH_SUPPORT",{
    sfx = SoundEvents.notification_relationship_new,
    -- img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, delta, current, wealth )
        
        if delta >= 0 then
            notification.banner_txt = loc.format("Gained {1} Support Among {2}", delta, DemocracyUtil.GetWealthString(wealth) )
            notification.details = loc.format("Your support level among {2} is increased to {1}.", current, DemocracyUtil.GetWealthString(wealth))
        else
            notification.banner_txt = loc.format("Lost {1} Support Among {2}", -delta, DemocracyUtil.GetWealthString(wealth))
            notification.details = loc.format("Your support level among {2} is decreased to {1}.", current, DemocracyUtil.GetWealthString(wealth))
        end
        notification.img = DemocracyUtil.GetWealthIcon(wealth)
    end,
})
AddNotification("DELTA_AGENT_SUPPORT",{
    sfx = SoundEvents.notification_relationship_new,
    -- img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, delta, agent )
        local mainquest = TheGame:GetGameState():GetMainQuest()
        if delta >= 0 then
            notification.banner_txt = loc.format("Gained {1} Support From {2#agent}", delta, agent)
            notification.details = loc.format("General support increased by {1}.(To {2})\n"..
                "Support from {3#faction} and among {4#wealth_name} are increased.\n"..
                "Check your advisor for more info.", delta, mainquest:DefFn("GetGeneralSupport"),
                agent:GetFaction(), agent:GetRenown())
        else
            notification.banner_txt = loc.format("Lost {1} Support From {2#agent}", -delta, agent)
            notification.details = loc.format("General support increased by {1}.(To {2})\n"..
                "Support from {3#faction} and among {4#wealth_name} are decreased.\n"..
                "Check your advisor for more info.", delta, mainquest:DefFn("GetGeneralSupport"),
                agent:GetFaction(), agent:GetRenown())
        end
        notification.img = agent
    end,
})