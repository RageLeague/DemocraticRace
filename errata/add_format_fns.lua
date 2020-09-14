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
    if issue and issue.GetName then
        return issue:GetName()
    end
    return tostring(issue)
end

loc.pol_stance = function(stance)
    -- can't really autoconvert, since stances aren't really tracked by id.
    return stance and stance.GetName and stance:GetName() or stance
end