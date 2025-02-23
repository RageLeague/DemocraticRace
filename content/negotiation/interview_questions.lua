local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT

local MODIFIERS = {
    LOADED_QUESTION =
    {
        name = "Loaded Question",
        desc = "After {1} {1*turn|turns}, remove itself and deal {2} damage to a random opponent argument.\n\nWhen destroyed, {INCEPT} 1 {DEM_INCRIMINATING_QUESTION} for every {3} splash damage (max {4}).\n\nWhen {address_question|addressed}, {INCEPT} {5} {DEM_INCRIMINATING_QUESTION}.",

        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.stacks, self.random_damage, self.damage_per_stack, self.max_incept, self.address_cost)
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/loaded_question.png",

        random_damage = 5,

        address_cost = 2,

        damage_per_stack = 2,
        stack_scale = {3, 2, 2, 1},

        max_incept = 5,

        target_enemy = TARGET_ANY_RESOLVE,

        modifier_type = MODIFIER_TYPE.ARGUMENT,

        OnInit = function( self )
            self:SetResolve( 4, MODIFIER_SCALING.HIGH )
            if CheckBits(self.engine:GetFlags(), NEGOTIATION_FLAGS.WORDSMITH) then
                self.damage_per_stack = DemocracyUtil.CalculateBossScale(self.stack_scale)
            end
        end,

        OnBeginTurn = function( self, minigame )
            self.negotiator:RemoveModifier( self, 1 )
            if self.stacks == 0 then
                minigame:ApplyPersuasion( self, nil, self.random_damage, self.random_damage )
            end
        end,

        OnBounty = function(self)
            local mod = self.negotiator:CreateModifier("LOADED_QUESTION_DEATH_TRIGGER")
            mod.tracked_mod = self
            mod.damage_per_stack = self.damage_per_stack
        end,

        AddressQuestion = function(self)
            self.anti_negotiator:AddModifier("DEM_INCRIMINATING_QUESTION", self.address_cost, self)
        end,
    },
    -- Kinda have to do it this way, since removed modifier no longer listens to events that happened because of the removal of self.
    LOADED_QUESTION_DEATH_TRIGGER =
    {
        -- name = "Loaded Question(Death Trigger)",
        hidden = true,
        damage_per_stack = 2,
        max_incept = 5,
        event_handlers =
        {
            [ EVENT.SPLASH_RESOLVE ] = function( self, modifier, overflow, params )
                if self.tracked_mod and self.tracked_mod == modifier then
                    print("overflow damage:" .. overflow .. ", deal resolve damage")
                    local incept_count = math.floor(-overflow / self.damage_per_stack)
                    if incept_count > 0 then
                        self.anti_negotiator:AddModifier("DEM_INCRIMINATING_QUESTION", math.min(incept_count, self.max_incept), self)
                    end
                end
                print("triggered lul")
                self.negotiator:RemoveModifier(self)
            end
        },
    },
    DEM_INCRIMINATING_QUESTION =
    {
        name = "Incriminating Question",
        desc = "When destroyed, the player loses support equal to half the number of stacks, rounded up.\n\nWhen {address_question|addressed}, if there are at least 2 stacks, create an {DEM_INCRIMINATING_QUESTION} argument with half the number of stacks, rounded down.",

        icon = "DEMOCRATICRACE:assets/modifiers/loaded_question.png",
        modifier_type = MODIFIER_TYPE.BOUNTY,

        max_resolve = 2,

        OnBounty = function(self)
            local support_dmg = math.ceil(self.stacks / 2)
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -support_dmg)
        end,

        AddressQuestion = function(self)
            if self.stacks >= 2 then
                self.negotiator:CreateModifier(self.id, math.floor(self.stacks / 2), self)
            end
        end,
    },
    GENERIC_QUESTION =
    {
        name = "Generic Question",
        desc = "After {1} {1*turn|turns}, remove itself and deal {2} damage to a random opponent argument.\n\nCan be {address_question|addressed}, but does nothing special.",
        icon = "DEMOCRATICRACE:assets/modifiers/generic_question.png",

        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.stacks, self.random_damage)
        end,

        random_damage = 5,

        target_enemy = TARGET_ANY_RESOLVE,

        modifier_type = MODIFIER_TYPE.ARGUMENT,

        OnInit = function(self)
            self:SetResolve( 4, MODIFIER_SCALING.HIGH )
        end,

        OnBeginTurn = function( self, minigame )
            self.negotiator:RemoveModifier( self, 1 )
            if self.stacks == 0 then
                minigame:ApplyPersuasion( self, nil, self.random_damage, self.random_damage )
            end
        end,
        AddressQuestion = function(self)
            -- does literally nothing. but this is here to let the game know this is a valid question.
        end,
    },
    PLEASANT_QUESTION =
    {
        name = "Pleasant Question",
        desc = "After {1} {1*turn|turns}, remove itself and deal {2} damage to a random opponent argument.\n\nWhen destroyed or {address_question|addressed}, the player gains {3} resolve.",

        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.stacks, self.random_damage, self.resolve_gain)
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/pleasant_question.png",

        random_damage = 5,

        resolve_gain = 2,
        resolve_scale = {5, 4, 3, 2},

        target_enemy = TARGET_ANY_RESOLVE,

        modifier_type = MODIFIER_TYPE.ARGUMENT,

        OnInit = function( self )
            self:SetResolve( 4, MODIFIER_SCALING.HIGH )
            if CheckBits(self.engine:GetFlags(), NEGOTIATION_FLAGS.WORDSMITH) then
                self.resolve_gain = DemocracyUtil.CalculateBossScale(self.resolve_scale)
            end
        end,

        OnBeginTurn = function( self, minigame )
            self.negotiator:RemoveModifier( self, 1 )
            if self.stacks == 0 then
                minigame:ApplyPersuasion( self, nil, self.random_damage, self.random_damage )
            end
        end,

        OnBounty = function(self)
            self.anti_negotiator:RestoreResolve(self.resolve_gain, self)
        end,

        AddressQuestion = function(self)
            self.anti_negotiator:RestoreResolve(self.resolve_gain, self)
        end,
    },
    CONTEMPORARY_QUESTION =
    {
        name = "Contemporary Question",
        desc = "The interviewer asks about your opinion on <b>{1}</>.\n\nAfter {2} {2*turn|turns}, remove itself and deal {3} damage to a random opponent argument.\n\nWhen {address_question|addressed}, the player must state their opinion on this matter.",
        icon = "DEMOCRATICRACE:assets/modifiers/contemporary_question.png",

        issue_data = nil,

        loc_strings = {
            ISSUE_DEFAULT = "a contemporary issue",
            CHOOSE_AN_ANSWER = "Choose An Answer",
        },

        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.issue_data and self.issue_data:GetLocalizedName() or self.def:GetLocalizedString("ISSUE_DEFAULT"), self.stacks, self.random_damage)
        end,
        OnInit = function( self )
            if CheckBits(self.engine:GetFlags(), NEGOTIATION_FLAGS.WORDSMITH) then
                self:SetResolve( 4 + 2 * (GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY ) or 1), MODIFIER_SCALING.HIGH )
            else
                self:SetResolve( 6, MODIFIER_SCALING.HIGH )
            end
        end,
        random_damage = 8,

        target_enemy = TARGET_ANY_RESOLVE,

        modifier_type = MODIFIER_TYPE.ARGUMENT,

        SetIssue = function(self, issue_data)
            self.issue_data = issue_data
            DemocracyUtil.MarkSeenIssue(self.issue_data)
        end,
        AddressQuestion = function(self)
            if self.issue_data ~= nil then
                local cards = {}
                local issue = self.issue_data
                for id = -2, 2 do
                    local data = issue.stances[id]
                    if data then
                        local card = Negotiation.Card( "question_answer", self.owner )
                        card.engine = self.engine
                        card:UpdateIssue(issue, id)
                        table.insert(cards, card)
                    end
                end
                local pick = self.engine:ChooseCardsFromTable( cards, 1, 1, nil, self.def:GetLocalizedString("CHOOSE_AN_ANSWER") )[1]
                if pick then
                    print(pick.name)
                    if pick.stance then
                        DemocracyUtil.TryMainQuestFn("UpdateStance", issue.id, pick.stance, true)
                        -- local stance = issue.stances[pick.stance]
                        -- if stance.faction_support then
                        --     DemocracyUtil.TryMainQuestFn("DeltaGroupFactionSupport", stance.faction_support)
                        -- end
                        -- if stance.wealth_support then
                        --     DemocracyUtil.TryMainQuestFn("DeltaGroupWealthSupport", stance.wealth_support)
                        -- end
                    end
                    self.engine:DealCard(pick, self.engine:GetTrashDeck())
                    print("should be expended")
                end

            end
        end,

        OnBeginTurn = function( self, minigame )
            self.negotiator:RemoveModifier( self, 1 )
            if self.stacks == 0 then
                minigame:ApplyPersuasion( self, nil, self.random_damage, self.random_damage )
            end
        end,
    },
}
for id, def in pairs( MODIFIERS ) do
    Content.AddNegotiationModifier( id, def )
end

local QUESTIONS = {
    "LOADED_QUESTION",
    "CONTEMPORARY_QUESTION",
    "GENERIC_QUESTION",
    "PLEASANT_QUESTION"
}

for i, id in ipairs(QUESTIONS) do
    Content.GetNegotiationCardFeature(id).apply = function( self, engine, card, targets, stacks )
        local modifier
        modifier = card.negotiator:CreateModifier( id, stacks, card )
        return modifier
    end
end
