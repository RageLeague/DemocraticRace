

AddNotification("DELTA_GENERAL_SUPPORT",{
    sfx = SoundEvents.notification_relationship_new,
    img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, delta, current )
        local addendum = delta >= 0 and "INCREASE" or "DECREASE"

        notification.banner_txt = loc.format(LOC("DEMOCRACY.NOTIFICATION.GENERAL_SUPPORT.TITLE_"..addendum), math.abs(delta))
        notification.details = loc.format(LOC("DEMOCRACY.NOTIFICATION.GENERAL_SUPPORT.DETAIL_"..addendum), current)

    end,
})
AddNotification("DELTA_FACTION_SUPPORT",{
    sfx = SoundEvents.notification_relationship_new,
    -- img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, delta, current, faction )
        local addendum = delta >= 0 and "INCREASE" or "DECREASE"
        
        notification.banner_txt = loc.format(LOC("DEMOCRACY.NOTIFICATION.FACTION_SUPPORT.TITLE_"..addendum), math.abs(delta), faction)
        notification.details = loc.format(LOC("DEMOCRACY.NOTIFICATION.FACTION_SUPPORT.DETAIL_"..addendum), current, faction)
        
        notification.img = faction:GetIcon()
    end,
})
AddNotification("DELTA_WEALTH_SUPPORT",{
    sfx = SoundEvents.notification_relationship_new,
    -- img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, delta, current, wealth )
        local addendum = delta >= 0 and "INCREASE" or "DECREASE"

        notification.banner_txt = loc.format(LOC("DEMOCRACY.NOTIFICATION.WEALTH_SUPPORT.TITLE_"..addendum), math.abs(delta), wealth )
        notification.details = loc.format(LOC("DEMOCRACY.NOTIFICATION.WEALTH_SUPPORT.DETAIL_"..addendum), current, wealth)
        
        notification.img = DemocracyUtil.GetWealthIcon(wealth)
    end,
})
AddNotification("DELTA_AGENT_SUPPORT",{
    sfx = SoundEvents.notification_relationship_new,
    -- img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, delta, agent )
        local mainquest = TheGame:GetGameState():GetMainQuest()
        local addendum = delta >= 0 and "INCREASE" or "DECREASE"

        notification.banner_txt = loc.format(LOC("DEMOCRACY.NOTIFICATION.AGENT_SUPPORT.TITLE_"..addendum), math.abs(delta), agent)
        notification.details = loc.format(LOC("DEMOCRACY.NOTIFICATION.AGENT_SUPPORT.DETAIL_"..addendum), math.abs(delta),
            mainquest:DefFn("GetGeneralSupport"), agent:GetFaction(), agent:GetRenown())
        
        notification.img = agent
    end,
})