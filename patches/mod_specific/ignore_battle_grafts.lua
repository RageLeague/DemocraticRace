local old_graft = GraftCollection.Rewardable

function GraftCollection.Rewardable(...)
    local collection = old_graft(...)
    if DemocracyUtil.IsDemocracyCampaign() then
        collection:Filter(function(graft_def)
            -- we already filtered grafts that is not combat or negotiation, so we only need to filter the combat grafts out.
            -- make it compatible with Cross Character Campaign, where coins are also awarded as grafts.
            return graft_def.type ~= GRAFT_TYPE.COMBAT
        end)
    end
    return collection
end
