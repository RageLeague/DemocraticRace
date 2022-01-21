local function FilterDemocraticRace(card_def)
    if card_def.is_democratic_race then
        return DemocracyUtil.GetModSetting("enable_custom_items") or DemocracyUtil.IsDemocracyCampaign()
    end
    return true
end

local old_battle_local = BattleCardCollection.AllLocalItems
function BattleCardCollection.AllLocalItems(...)
    return old_battle_local(...):Filter(FilterDemocraticRace)
end

local old_negotiation_local = NegotiationCardCollection.AllLocalItems
function NegotiationCardCollection.AllLocalItems(...)
    return old_negotiation_local(...):Filter(FilterDemocraticRace)
end

local old_battle_all = BattleCardCollection.AllItems
function BattleCardCollection.AllItems(...)
    return old_battle_all(...):Filter(FilterDemocraticRace)
end

local old_negotiation_all = NegotiationCardCollection.AllItems
function NegotiationCardCollection.AllItems(...)
    return old_negotiation_all(...):Filter(FilterDemocraticRace)
end
