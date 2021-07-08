local old_fn = UIHelpers.ItemTooltips

function UIHelpers.ItemTooltips( widget, tag, text, ... )
    if tag then
        local issue = tag:match( "pol_issue_([_%w]+)" )
        if issue and DemocracyConstants.issue_data[loc.toupper(issue)] then
            widget:SetToolTipClass(Widget.TooltipCodex)
            widget:SetToolTip(DemocracyConstants.issue_data[loc.toupper(issue)])
            return
        end

        local st_issue, st_stance = tag:match("pol_stance_([_%w]+)_([%-%d]+)")
        st_stance = tonumber(st_stance)
        
        if st_issue and st_stance then
            local issue_data = DemocracyConstants.issue_data[loc.toupper(st_issue)]
            if issue_data and issue_data.stances[st_stance] then
                widget:SetToolTipClass(Widget.TooltipCodex)
                widget:SetToolTip(issue_data.stances[st_stance])
                return
            end
        end
    end
    old_fn( widget, tag, text, ... )
end