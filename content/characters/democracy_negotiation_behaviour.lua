function DemocracyUtil.AddDemocracyNegotiationBehaviour(id, additional_data)
    assert(type(additional_data.OnInitDemocracy) == "function", "Behaviour must have OnInitDemocracy as an init function")

    local char_data = Content.GetCharacterDef( id )
    char_data.negotiation_data = char_data.negotiation_data or {}
    char_data.negotiation_data.behaviour = char_data.negotiation_data.behaviour or {}

    for id, entry in pairs(additional_data) do
        char_data.negotiation_data.behaviour[id] = entry
    end

    local old_init = char_data.negotiation_data.behaviour.OnInit

    char_data.negotiation_data.behaviour.OnInit = function(self, ...)
        if DemocracyUtil.IsDemocracyCampaign() then
            return char_data.negotiation_data.behaviour.OnInitDemocracy(self, old_init, ...)
        else
            return old_init(self, ...)
        end
    end
end

local NEW_BEHAVIOURS = {
    VIXMALLI =
    {
        -- Use standard priest negotiation
        OnInitDemocracy = function(self, old_init, ...)
            local res = Content.GetCharacterDef( "PRIEST" ).negotiation_data.behaviour.OnInit(self, ...)
            self:SetPattern( self.DemocracyDefaultCycle )
            return res
        end,

        DemocracyDefaultCycle = function(self, ...)
            return Content.GetCharacterDef( "PRIEST" ).negotiation_data.behaviour.Cycle(self, ...)
        end,
    },
    HESH_AUCTIONEER =
    {
        OnInitDemocracy = function(self, old_init, difficulty)
            local relationship_delta = self.agent and (self.agent:GetRelationship() - RELATIONSHIP.NEUTRAL) or 0
            self:SetPattern( self.DemocracyBasicCycle )
            local modifier = self.negotiator:AddModifier("INTERVIEWER")
            -- modifier.agents = shallowcopy(self.agents)
            -- modifier:InitModifiers()
            self.cont_question_card = self:AddCard("contemporary_question_card")
            self.cont_question_card.stacks = 3 - (GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ARGUMENT_PLUS ) and 1 or 0)

            self.modifier_picker = self:MakePicker()

            local _, card = self.modifier_picker:AddArgument("LOADED_QUESTION", 2 + math.max(0, -relationship_delta))
            card.stacks = 3 - (GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ARGUMENT_PLUS ) and 1 or 0)
            local _, card = self.modifier_picker:AddArgument("PLEASANT_QUESTION", 2 + math.max(0, relationship_delta))
            card.stacks = 3 - (GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ARGUMENT_PLUS ) and 1 or 0)
            local _, card = self.modifier_picker:AddArgument("GENERIC_QUESTION", 4)
            card.stacks = 3 - (GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ARGUMENT_PLUS ) and 1 or 0)

            if not self.params then self.params = {} end
            self.params.questions_answered = 0
            self.available_issues = copyvalues(DemocracyConstants.issue_data)
        end,
        DemocracyBasicCycle = function( self, turns )
            -- Double attack every 2 rounds; Single attack otherwise.
            if self.difficulty >= 4 and turns % 2 == 0 then
                self:ChooseGrowingNumbers( 3, -1 )
            elseif turns % 2 == 0 then
                self:ChooseGrowingNumbers( 2, 0 )
            else
                self:ChooseGrowingNumbers( 1, 1 )
            end
            -- if turns == 1 then
            --     self:ChooseGrowingNumbers( 1, 2 )
            -- end
            local question_count = 0
            for i, data in self.negotiator:Modifiers() do
                if data.AddressQuestion then
                    question_count = question_count + 1
                end
            end
            local additional_questions
            if turns % 3 == 1 then
                self:ChooseCard(self.cont_question_card)
                additional_questions = 0
            else
                additional_questions = 1
            end
            additional_questions = math.min(additional_questions + math.floor((self.difficulty - 1 + (turns % 2)) / 2), 3)
            self.modifier_picker:ChooseCards(additional_questions)
        end,
    },
    MURDER_BAY_ADMIRALTY_CONTACT =
    {
        OnInitDemocracy = function(self, old_init, ...)
            return old_init(self, ...)
        end,
    },
    SPARK_CONTACT =
    {
        WAIVERS_STACKS = {1, 2, 2, 3},
        OnInitDemocracy = function(self, old_init, ...)
            if self.engine and CheckBits(self.engine:GetFlags(), NEGOTIATION_FLAGS.WORDSMITH) then
                local boss_scale = GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY ) or 2

                self.negotiator:AddModifier("FELLEMO_SLIPPERY")

                self.waivers = self:AddArgument( "WAIVERS" )
                self.waivers.stacks = self.WAIVERS_STACKS[clamp(boss_scale, 1, #self.WAIVERS_STACKS)]

                self.exploitation = self:AddArgument( "EXPLOITATION" )

                self.attacks = self:MakePicker()
                self.attacks:AddID( "straw_man", 1 )
                self.attacks:AddID( "ai_appropriate_card", 1 )

                self:SetPattern( self.DemocracyBossCycle )
                return
            end
            return old_init(self, ...)
        end,
        DemocracyBossCycle = function( self, turns )
            if turns % 4 == 1 then
                self:ChooseGrowingNumbers( 2, 0, 0.8 )
            elseif turns % 4 == 3 then
                self:ChooseGrowingNumbers( 3, 0, 0.7 )
            else
                self:ChooseGrowingNumbers( 1, -1 )
            end

            if turns % 4 == 1 then
                self:ChooseCard(self.waivers)
            end
            if turns % 2 == 0 then
                local stacks = self.negotiator:GetModifierInstances( "EXPLOITATION" )
                if stacks == 0 then
                    self:ChooseCard(self.exploitation)
                end
            end

            self.attacks:ChooseCard()
        end,
    },
    KALANDRA =
    {
        OnInitDemocracy = function(self, old_init, ...)
            return old_init(self, ...)
        end,
    },
    ANDWANETTE =
    {
        OnInitDemocracy = function(self, old_init, ...)
            return old_init(self, ...)
        end,
    },
}

for id, data in pairs(NEW_BEHAVIOURS) do
    DemocracyUtil.AddDemocracyNegotiationBehaviour(id, data)
end
