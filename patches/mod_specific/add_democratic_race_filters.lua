local function FilterDemocraticRace(card_def)
    if card_def.is_democratic_race then
        return DemocracyUtil.GetModSetting("enable_custom_items") or DemocracyUtil.IsDemocracyCampaign()
    end
    return true
end

local old_battle_collection = BattleCardCollection.AllLocalItems
function BattleCardCollection.AllLocalItems(...)
    return old_battle_collection(...):Filter(FilterDemocraticRace)
end

local old_negotiation_collection = NegotiationCardCollection.AllLocalItems
function NegotiationCardCollection.AllLocalItems(...)
    return old_negotiation_collection(...):Filter(FilterDemocraticRace)
end
