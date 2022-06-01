-- These represents voters that totally exists
-- They just... go to a different school. In a different continent.
-- Can't spawn them in for real for gameplay reasons.
local PhantomAgent = class("DemocracyClass.PhantomAgent")

function PhantomAgent:init(id, faction, renown)
    if faction == nil then
        -- Assume that this is created using ID
        local def = Content.GetCharacterDef( id )
        assert(def, id .. " is not a valid def")
        return PhantomAgent.init(self, id, def.faction_id, def.renown or 1)
    end
    self.id = id
    self.faction_id = faction
    self.renown = renown
end

PhantomAgent.GetFactionID = Agent.GetFactionID
PhantomAgent.GetFaction = Agent.GetFaction

function PhantomAgent:GetRenown()
    return self.renown
end
function PhantomAgent:GetRelationship()
    return RELATIONSHIP.NEUTRAL
end
function PhantomAgent:__tostring()
    return string.format("{*%s*}", self.id or (self.faction .. "_" .. self.renown) )
end
