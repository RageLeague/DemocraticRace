function DebugShowAllMettleUpgrades()
    local all_grafts = GraftCollection(function(graft_def) return graft_def.type == GRAFT_TYPE.METTLE_UPGRADE end)
    -- DBG(all_grafts)
    local total = 0
    for i, def in ipairs(all_grafts.items) do
        print(loc.format("{1} requires {2} mettle total", def.id, table.sum(def.upgrade_costs or {})))
        total = total + table.sum(def.upgrade_costs or {})
    end
    print(loc.format("Require {1} to unlock all mettle upgrades", total))
end