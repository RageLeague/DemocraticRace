local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS

local conditions =
{
    DEM_PARASITIC_INFECTION =
    {
        name = "Parasitic Infection",
        desc = "You win the battle when {1} has no {DISEASED}. When {DISEASED} on {1} is removed by means other than {dem_incision}, gain {DISEASED} equal to the amount removed.\n\nIf {1} has {DISEASED}, when {1} deals unmitigated damage to another fighter or another fighter attacks {1} with a melee attack, and the fighter has {WOUND}, apply {2} {DISEASED}.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self:GetOwnerName(), self.disease_count )
        end,

        disease_count = 1,
        ctype = CTYPE.INNATE,

        event_handlers =
        {
            [ BATTLE_EVENT.BEGIN_TURN ] = function( self, fighter )
                self.wounded_targets = {}
                for i, active_fighter in self.battle:ActiveFighters() do
                    if active_fighter:HasCondition("WOUND") then
                        table.insert(self.wounded_targets, active_fighter)
                    end
                end
            end,
            [ BATTLE_EVENT.ON_HIT ] = function( self, battle, attack, hit )
                if self.owner:HasCondition("DISEASED") then
                    if not hit.defended and not hit.evaded and attack.card:IsDamageCard() and attack.attacker == self.owner and hit.target ~= self.owner then
                        if self.wounded_targets and table.arraycontains(self.wounded_targets, hit.target) then
                            hit.target:AddCondition("DISEASED", self.disease_count, self)
                        end
                    elseif attack.card and attack.card:IsMeleeAttack() and not attack.card:IsFlagged( CARD_FLAGS.SPECIAL ) and attack.attacker ~= self.owner and hit.target == self.owner then
                        if self.wounded_targets and table.arraycontains(self.wounded_targets, attack.attacker) then
                            attack.attacker:AddCondition("DISEASED", self.disease_count, self)
                        end
                    end
                end
            end,
            [ BATTLE_EVENT.CONDITION_REMOVED ] = function( self, fighter, condition, stacks, source )
                if self.owner == fighter and condition.id == "DISEASED" then
                    if source and source.id == "dem_incision" then
                        if condition.stacks <= 0 then
                            self.battle:Win()
                        end
                    else
                        self.owner:AddCondition("DISEASED", stacks, self)
                    end
                end
            end,
        },
    },
}

for condition_id, t in pairs( conditions ) do
    Content.AddBattleCondition( condition_id, t )
end
