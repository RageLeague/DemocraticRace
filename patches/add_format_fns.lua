loc.wealth_name = function(renown)
    return DemocracyUtil.GetWealthString(renown)
end
loc.wealth_name_list = function(list)
    local t = {}
    for i, renown in pairs( list ) do
        table.insert( t, loc.format( "{1#wealth_name}", renown ))
    end
    return loc.format( "{1#listing}", t )
end

loc.pol_issue = function(issue)
    if type(issue) == "string" then
        if not DemocracyConstants.issue_data[issue] then return issue end
        issue = DemocracyConstants.issue_data[issue]
    end
    if issue and issue.GetLocalizedName then
        return string.format("<!pol_issue_%s>%s</>", loc.tolower(issue.id), issue:GetLocalizedName()) 
    end
    return tostring(issue)
end

loc.pol_stance = function(stance)
    if type(stance) == "string" then
        local st_issue, st_stance = stance:match("([_%w]+)_([%-%d]+)")
        st_stance = tonumber(st_stance)
        if st_issue and st_stance then
            local issue_data = DemocracyConstants.issue_data[loc.toupper(st_issue)]
            if issue_data and issue_data.stances[st_stance] then
                stance = issue_data.stances[st_stance]
            end
        end
    end
    -- can't really autoconvert, since stances aren't really tracked by id.
    if stance and stance.GetLocalizedName then 
        return string.format("<!pol_stance_%s>%s</>", loc.tolower(stance.id), stance:GetLocalizedName()) 
    end
    return tostring(stance)
end

loc.one_demand = function(data)
    if type(data) == "table" and data.id then
        local modifier = Content.GetNegotiationModifier(data.id)
        if modifier then
            local localized_title = modifier:GetLocalizedTitle()
            if modifier.title_fn then
                localized_title = modifier:title_fn(localized_title, data)
            end
            return localized_title
        end
    end
    return tostring(data)
end

loc.demand_list = function(list)
    local t = {}
    for i, demand in pairs( list ) do
        table.insert( t, loc.format( "{1#one_demand}", demand ))
    end
    if #t <= 0 then
        return LOC"MISC.DO_NOTHING"
    end
    return loc.format( "{1#listing}", t )
end