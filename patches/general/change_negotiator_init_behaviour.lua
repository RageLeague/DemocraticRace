--[[
    NEGOTIATOR_ALLOW_TEMP_BEHAVIOUR:
    Addendum to existing negotiatior initialization.
    If an agent has temp_negotiation_behaviour defined, will instead use that behaviour instead of the usual
    behaviour.
    An agent's temp_negotiation_behaviour is cleared once intialized.
    This allows for special scenarios when you want a different behaviour for an agent's usual behaviour
--]]
local patch_id = "NEGOTIATOR_ALLOW_TEMP_BEHAVIOUR"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)
-- print(Negotiation.Negotiator)
local old_init = Negotiation.Negotiator.InitBehaviour
Negotiation.Negotiator.InitBehaviour = function(self)
    if self.agent.temp_negotiation_behaviour then
        local enc = TheGame:GetGameState():GetCaravan():GetCurrentEncounter()
        local temp_enc = self.agent.temp_negotiation_behaviour.current_encounter
        if temp_enc == nil or enc == temp_enc then
            self.behaviour = NegotiationBehaviour( self, self.agent.temp_negotiation_behaviour )
            self.agent.temp_negotiation_behaviour = nil
            return
        else
            self.agent.temp_negotiation_behaviour = nil
        end
        
    end
    return old_init(self)
end

function Agent:SetTempNegotiationBehaviour(data, enc)
    self.temp_negotiation_behaviour = shallowcopy(data)
    -- added an encounter check so that if you exit from current encounter, the temp behaviour won't work
    self.temp_negotiation_behaviour.current_encounter = enc or TheGame:GetGameState():GetCaravan():GetCurrentEncounter()
end