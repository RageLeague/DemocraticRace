

AddNotification("DELTA_GENERAL_SUPPORT",{
    sfx = SoundEvents.notification_relationship_new,
    img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, delta, current )
        current = current or DemocracyUtil.TryMainQuestFn("GetGeneralSupport")
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
        current = current or DemocracyUtil.TryMainQuestFn("GetFactionSupport", faction)
        
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
        current = current or DemocracyUtil.TryMainQuestFn("GetWealthSupport", wealth)
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
AddNotification("DELTA_GROUP_FACTION_SUPPORT", {
    sfx = SoundEvents.notification_relationship_new,
    img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, group_deltas )
        local liked = {}
        local disliked = {}
        for id, val in pairs(group_deltas) do
            if type(val) == "number" then
                if val > 0 then
                    table.insert(liked, id)
                elseif val < 0 then
                    table.insert(disliked, id)
                end
            end
        end
        table.sort(liked)
        table.sort(disliked)
        if #liked + #disliked == 1 then
            local solokey = #liked > 0 and liked[1] or disliked[1]
            return NOTIFY.DELTA_FACTION_SUPPORT.FormatNotification(self, notification, group_deltas[solokey], nil, solokey)
        end
        if #liked + #disliked == 0 then
            return NOTIFY.DELTA_GENERAL_SUPPORT.FormatNotification(self, notification, 0)
        end
        notification.banner_txt = LOC"DEMOCRACY.NOTIFICATION.GROUP_FACTION_SUPPORT.TITLE"
        if #liked > 0 then
            if #disliked > 0 then
                notification.details = loc.format(LOC"DEMOCRACY.NOTIFICATION.GROUP_FACTION_SUPPORT.DETAIL_BOTH", liked, disliked)
            else
                notification.details = loc.format(LOC"DEMOCRACY.NOTIFICATION.GROUP_FACTION_SUPPORT.DETAIL_INCREASE", liked)
            end
        else
            notification.details = loc.format(LOC"DEMOCRACY.NOTIFICATION.GROUP_FACTION_SUPPORT.DETAIL_DECREASE", disliked)
        end
    end,
})
AddNotification("DELTA_GROUP_WEALTH_SUPPORT", {
    sfx = SoundEvents.notification_relationship_new,
    img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, group_deltas )
        local liked = {}
        local disliked = {}
        for id, val in pairs(group_deltas) do
            if type(val) == "number" then
                if val > 0 then
                    table.insert(liked, id)
                elseif val < 0 then
                    table.insert(disliked, id)
                end
            end
        end
        table.sort(liked)
        table.sort(disliked)
        if #liked + #disliked == 1 then
            local solokey = #liked > 0 and liked[1] or disliked[1]
            return NOTIFY.DELTA_WEALTH_SUPPORT.FormatNotification(self, notification, group_deltas[solokey], nil, solokey)
        end
        if #liked + #disliked == 0 then
            return NOTIFY.DELTA_GENERAL_SUPPORT.FormatNotification(self, notification, 0)
        end
        notification.banner_txt = LOC"DEMOCRACY.NOTIFICATION.GROUP_WEALTH_SUPPORT.TITLE"
        if #liked > 0 then
            if #disliked > 0 then
                notification.details = loc.format(LOC"DEMOCRACY.NOTIFICATION.GROUP_WEALTH_SUPPORT.DETAIL_BOTH", liked, disliked)
            else
                notification.details = loc.format(LOC"DEMOCRACY.NOTIFICATION.GROUP_WEALTH_SUPPORT.DETAIL_INCREASE", liked)
            end
        else
            notification.details = loc.format(LOC"DEMOCRACY.NOTIFICATION.GROUP_WEALTH_SUPPORT.DETAIL_DECREASE", disliked)
        end
    end,
})