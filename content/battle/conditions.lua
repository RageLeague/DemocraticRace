local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.EVENT
local CARD_FLAGS = battle_defs.CARD_FLAGS

local conditions =
{
    DEM_PARASITIC_INFECTION =
    {
        name = "Parasitic Infection",
        desc = "You win the battle when {1} has no {DISEASED}.\n\nWhen {DISEASED} on {1} is removed by means other than {dem_parasite_extraction}, gain {DISEASED} equal to the amount removed.\n\nOnce each turn, when a fighter with {WOUND} at the start of the turn attacks {1} with a melee attack, apply {2} {DISEASED}.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self:GetOwnerName(), self.disease_count )
        end,
        icon = "DEMOCRATICRACE:assets/conditions/parasitic_infection.png",

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
                -- if not hit.defended and not hit.evaded and attack.card:IsDamageCard() and attack.attacker == self.owner and hit.target ~= self.owner then
                --     if self.wounded_targets and table.arraycontains(self.wounded_targets, hit.target) then
                --         hit.target:AddCondition("DISEASED", self.disease_count, self)
                --         table.arrayremove(self.wounded_targets, hit.target)
                --     end
                -- end

                if attack.card and attack.card:IsMeleeAttack() and not attack.card:IsFlagged( CARD_FLAGS.SPECIAL ) and attack.attacker ~= self.owner and hit.target == self.owner then
                    if self.wounded_targets and table.arraycontains(self.wounded_targets, attack.attacker) then
                        attack.attacker:AddCondition("DISEASED", self.disease_count, self)
                        table.arrayremove(self.wounded_targets, attack.attacker)
                    end
                end
            end,
            [ BATTLE_EVENT.CONDITION_REMOVED ] = function( self, fighter, condition, stacks, source )
                if self.owner == fighter and condition.id == "DISEASED" then
                    if source and source.id == "dem_parasite_extraction" then
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
    DEM_CORNERED =
    {
        name = "Cornered",
        desc = "While {1} has {RUNNING}, if they suffer health loss, there is a {2#percent} chance that they lose {RUNNING} and gain {EXERT}. Increase this chance by {3#percent} for each point of health loss after {4}.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self:GetOwnerName(), self.base_chance, self.additional_chance, self.chance_threshold )
        end,
        icon = "DEMOCRATICRACE:assets/conditions/cornered.png",

        base_chance = 0.5,
        additional_chance = 0.05,
        chance_threshold = 5,

        ctype = CTYPE.INNATE,

        event_handlers =
        {
            [ BATTLE_EVENT.DELTA_STAT ] = function( self, fighter, stat, delta, value, mitigated  )
                if fighter == self.owner and stat == COMBAT_STAT.HEALTH and delta < 0 then
                    if self.owner:GetConditionStacks("RUNNING") > 0 then
                        local chance = self.base_chance
                        if delta > self.chance_threshold then
                            chance = chance + (delta - self.chance_threshold) * self.additional_chance
                        end
                        print(chance)
                        if math.random() < chance then
                            -- Remove running and gain exert
                            self.owner:RemoveCondition("RUNNING")
                            self.owner:AddCondition( "EXERT", 1, self )
                        end
                    end
                end
            end,
        },
    },
}

for condition_id, t in pairs( conditions ) do
    Content.AddBattleCondition( condition_id, t )
end
