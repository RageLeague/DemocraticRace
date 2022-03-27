function DemocracyUtil.AddDemocracyNegotiationBehaviour(id, additional_data)
    assert(type(additional_data.OnInitDemocracy) == "function", "Behaviour must have OnInitDemocracy as an init function")

    local char_data = Content.GetCharacterDef( id )
    char_data.negotiation_data = char_data.negotiation_data or {}
    char_data.negotiation_data.behaviour = char_data.negotiation_data.behaviour or {}

    for id, entry in pairs(additional_data) do
        char_data.negotiation_data.behaviour[id] = entry
    end

    local old_init = char_data.negotiation_data.behaviour.OnInit

    char_data.negotiation_data.behaviour.OnInit = function(...)
        if DemocracyUtil.IsDemocracyCampaign() then
            return char_data.negotiation_data.behaviour.OnInitDemocracy(...)
        else
            return old_init(...)
        end
    end
end
