local function GetReason(txt)
    return LOC("DEMOCRACY.DELTA_SUPPORT_REASON." .. txt)
end

AddNotification("DEM_DELTA_GENERAL_SUPPORT",{
    sfx = SoundEvents.notification_relationship_new,
    img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, delta, current, reason )
        if type(reason) ~= "string" then
            reason = delta >= 0 and "DEFAULT_UP" or "DEFAULT_DOWN"
        end
        current = current or DemocracyUtil.TryMainQuestFn("GetGeneralSupport")
        local addendum = delta >= 0 and "INCREASE" or "DECREASE"

        notification.banner_txt = loc.format(LOC("DEMOCRACY.NOTIFICATION.GENERAL_SUPPORT.TITLE_"..addendum), math.abs(delta))
        notification.details = loc.format(LOC("DEMOCRACY.NOTIFICATION.GENERAL_SUPPORT.DETAIL_"..addendum), current, GetReason(reason))

    end,
})
AddNotification("DEM_DELTA_FACTION_SUPPORT",{
    sfx = SoundEvents.notification_relationship_new,
    -- img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, delta, current, faction, reason )
        if type(reason) ~= "string" then
            reason = delta >= 0 and "DEFAULT_UP" or "DEFAULT_DOWN"
        end
        local addendum = delta >= 0 and "INCREASE" or "DECREASE"
        current = current or DemocracyUtil.TryMainQuestFn("GetFactionSupport", faction)

        notification.banner_txt = loc.format(LOC("DEMOCRACY.NOTIFICATION.FACTION_SUPPORT.TITLE_"..addendum), math.abs(delta), faction)
        notification.details = loc.format(LOC("DEMOCRACY.NOTIFICATION.FACTION_SUPPORT.DETAIL_"..addendum), current, faction, GetReason(reason))

        notification.img = faction:GetIcon()
    end,
})
AddNotification("DEM_DELTA_WEALTH_SUPPORT",{
    sfx = SoundEvents.notification_relationship_new,
    -- img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, delta, current, wealth, reason )
        if type(reason) ~= "string" then
            reason = delta >= 0 and "DEFAULT_UP" or "DEFAULT_DOWN"
        end
        local addendum = delta >= 0 and "INCREASE" or "DECREASE"
        current = current or DemocracyUtil.TryMainQuestFn("GetWealthSupport", wealth)
        notification.banner_txt = loc.format(LOC("DEMOCRACY.NOTIFICATION.WEALTH_SUPPORT.TITLE_"..addendum), math.abs(delta), wealth )
        notification.details = loc.format(LOC("DEMOCRACY.NOTIFICATION.WEALTH_SUPPORT.DETAIL_"..addendum), current, wealth, GetReason(reason))

        notification.img = DemocracyUtil.GetWealthIcon(wealth)
    end,
})
AddNotification("DEM_DELTA_AGENT_SUPPORT",{
    sfx = SoundEvents.notification_relationship_new,
    -- img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, general_delta, additional_delta, agent, reason )
        if type(reason) ~= "string" then
            reason = additional_delta >= 0 and "DEFAULT_UP" or "DEFAULT_DOWN"
        end

        local mainquest = TheGame:GetGameState():GetMainQuest()
        local addendum = additional_delta >= 0 and "INCREASE" or "DECREASE"

        notification.banner_txt = loc.format(LOC("DEMOCRACY.NOTIFICATION.AGENT_SUPPORT.TITLE_"..addendum), agent)
        notification.details = loc.format(LOC("DEMOCRACY.NOTIFICATION.AGENT_SUPPORT.DETAIL_"..addendum), math.abs(general_delta), math.abs(additional_delta), GetReason(reason), agent:GetFaction(), agent)

        notification.img = agent
    end,
})
AddNotification("DEM_DELTA_GROUP_FACTION_SUPPORT", {
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
            return NOTIFY.DEM_DELTA_FACTION_SUPPORT.FormatNotification(self, notification, group_deltas[solokey], nil, solokey)
        end
        if #liked + #disliked == 0 then
            return NOTIFY.DEM_DELTA_GENERAL_SUPPORT.FormatNotification(self, notification, 0)
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
AddNotification("DEM_DELTA_GROUP_WEALTH_SUPPORT", {
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
            return NOTIFY.DEM_DELTA_WEALTH_SUPPORT.FormatNotification(self, notification, group_deltas[solokey], nil, solokey)
        end
        if #liked + #disliked == 0 then
            return NOTIFY.DEM_DELTA_GENERAL_SUPPORT.FormatNotification(self, notification, 0)
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

AddNotification("DEM_UPDATE_STANCE", {
    sfx = SoundEvents.notification_relationship_new,
    img = DemocracyConstants.icons.support,
    FormatNotification = function( self, notification, issue, stance, strict )
        notification.banner_txt = LOC"DEMOCRACY.NOTIFICATION.UPDATE_STANCE.TITLE"
        if type(issue) == "string" then
            issue = DemocracyConstants.issue_data[issue]
        end
        if type(stance) == "number" and issue then
            stance = issue.stances[stance]
        end
        notification.details = loc.format(LOC("DEMOCRACY.NOTIFICATION.UPDATE_STANCE."
            .. (strict and "DETAIL_STRICT" or "DETAIL_LOOSE")), issue, stance)
    end,
})

AddNotification("DEM_TIME_PASSED", {
    sfx = SoundEvents.notification_aspect_gained,
    -- Yoink the grog's icon
    img = engine.asset.Texture("UI/location_grogndog.tex"),
    FormatNotification = function( self, notification, quest, delta, newvalue, reason )
        print("new value:", newvalue)
        notification.banner_txt = loc.format(LOC"DEMOCRACY.NOTIFICATION.TIME_PASSED.TITLE", delta)
        if newvalue and newvalue > 0 then
            notification.details = loc.format(LOC"DEMOCRACY.NOTIFICATION.TIME_PASSED.DETAIL", delta, LOC("DEMOCRACY.NOTIFICATION.TIME_PASSED.REASON." .. (reason or "ACTION")), newvalue)
        else
            notification.details = loc.format(LOC"DEMOCRACY.NOTIFICATION.TIME_PASSED.DETAIL_NO_FREE", delta, LOC("DEMOCRACY.NOTIFICATION.TIME_PASSED.REASON." .. (reason or "ACTION")))
        end
        notification.img = quest:GetIcon() or notification.img
    end,
})
