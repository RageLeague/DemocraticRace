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
            if self.engine and CheckBits(self.engine:GetFlags(), NEGOTIATION_FLAGS.WORDSMITH) then
                self.negotiator:AddModifier("DEVOTED_MIND")

                self.negotiator:CreateModifier( "INDIFFERENCE_OF_HESH", 1, self )
                self.negotiator:CreateModifier( "INCOMPREHENSIBILITY_OF_HESH", 1, self )
                self.negotiator:CreateModifier( "INSATIABILITY_OF_HESH", 1, self )

                self.desperation = self:AddArgument( "DESPERATION_FOR_FAITH" )

                self.attacks = self:MakePicker()
                self.attacks:AddArgument( "prayer_of_hesh", 1 )
                self.attacks:AddArgument( "wrath_of_hesh", 1 )

                self:SetPattern( self.DemocracyBossCycle )
            else
                local res = Content.GetCharacterDef( "PRIEST" ).negotiation_data.behaviour.OnInit(self, ...)
                self:SetPattern( self.DemocracyDefaultCycle )
                return res
            end
        end,

        DemocracyDefaultCycle = function(self, ...)
            return Content.GetCharacterDef( "PRIEST" ).negotiation_data.behaviour.Cycle(self, ...)
        end,

        DemocracyBossCycle = function(self, turns)
            if self.affected_card then
                for i, card in ipairs(self.affected_card) do
                    card.target_mod = TARGET_MOD.SINGLE
                end
                self.affected_card = nil
            end
            local faith_count = 0
            for i, data in self.negotiator:Modifiers() do
                if data.faith_in_hesh then
                    faith_count = faith_count + 1
                end
            end
            if faith_count == 0 then
                -- Do a mass attack, and create desperation
                self.affected_card = {}
                self:ChooseNumbersFromTotal( 1, 4 )
                for i, card in ipairs(self.prepared_cards) do
                    if card.id == "default" and card.target_enemy then
                        card.target_mod = TARGET_MOD.TEAM
                        card.max_persuasion = card.max_persuasion + 2
                        table.insert(self.affected_card, card)
                    end
                end
                self:ChooseCard(self.desperation)
            else
                -- Do normal attacks
                if turns % 2 == 0 then
                    self:ChooseGrowingNumbers(1, -1)
                    self.attacks:ChooseCard()
                else
                    self:ChooseGrowingNumbers(1, 0)
                    self:ChooseComposure( 1, 3, 7 )
                end
            end
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
            self.cont_question_card.stacks = 3

            self.modifier_picker = self:MakePicker()

            local _, card = self.modifier_picker:AddArgument("LOADED_QUESTION", 2 + math.max(0, -relationship_delta))
            card.stacks = 3
            local _, card = self.modifier_picker:AddArgument("PLEASANT_QUESTION", 2 + math.max(0, relationship_delta))
            card.stacks = 3
            local _, card = self.modifier_picker:AddArgument("GENERIC_QUESTION", 4)
            card.stacks = 3

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
            if self.engine and CheckBits(self.engine:GetFlags(), NEGOTIATION_FLAGS.WORDSMITH) then
                self.has_badge = false
                self.negotiator:AddModifier("OOLO_WORDSMITH_CORE")
                self.unite = self:AddArgument("OOLO_UNITED_FRONT")
                self.badge = self:AddArgument("OOLO_BADGE_FLASH")
                self.plant_evidence = self:AddCard("oolo_planted_evidence_wordsmith")
                self.straw_man = self:AddCard("straw_man")
                self:SetPattern( self.DemoCycle )
                return
            end
            return old_init(self, ...)
        end,
        DemoCycle = function(self, turns)
            if turns % 3 == 0 then
                self:ChooseGrowingNumbers(3, 0, 1)
            else
                self:ChooseGrowingNumbers(2, 0)
            end
            local max_count = ((GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY ) or 2) >= 3) and 2 or 1
            if turns % 2 == 1 then
                local count = self.player_negotiator:GetModifierInstances( "PLANTED_EVIDENCE" )
                if count < max_count then
                    self:ChooseCard(self.plant_evidence)
                else
                    self:ChooseComposure(1, 3, 5)
                end
            else
                local count = self.player_negotiator:GetModifierInstances( "straw_man" )
                if count < max_count then
                    self:ChooseCard(self.straw_man)
                else
                    self:ChooseComposure(1, 3, 5)
                end
            end
            if (turns - 1) % 3 == 0 then
                self:ChooseCard(self.badge)
            end
            if turns % 4 == 2 then
                self:ChooseCard(self.unite)
            end
        end,
    },
    SPARK_CONTACT =
    {
        WAIVERS_STACKS = {1, 2, 3, 4},
        OnInitDemocracy = function(self, old_init, ...)
            if self.engine and CheckBits(self.engine:GetFlags(), NEGOTIATION_FLAGS.WORDSMITH) then
                self.negotiator:AddModifier("FELLEMO_SLIPPERY")

                self.waivers = self:AddArgument( "WAIVERS" )
                self.waivers.stacks = DemocracyUtil.CalculateBossScale(self.WAIVERS_STACKS)

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
                self:ChooseGrowingNumbers( 2, -1 )
            elseif turns % 4 == 3 then
                self:ChooseGrowingNumbers( 3, 0, 0.8 )
            else
                self:ChooseGrowingNumbers( 1, 0 )
            end

            if turns % 4 == 1 then
                self:ChooseCard(self.waivers)
            end
            if turns % 2 == 0 then
                local stacks = self.negotiator:GetModifierInstances( "EXPLOITATION" )
                if stacks < 2 then
                    self:ChooseCard(self.exploitation)
                    self:ChooseComposure( 1, 2, 5 )
                else
                    self:ChooseComposure( 2, 4, 10 )
                end
            end

            self.attacks:ChooseCard()
        end,
    },
    KALANDRA =
    {
        OnInitDemocracy = function(self, old_init, ...)
            if self.engine and CheckBits(self.engine:GetFlags(), NEGOTIATION_FLAGS.WORDSMITH) then
                self.negotiator:AddModifier("SPARK_OF_REVOLUTION")

                self.voice = self:AddArgument( "VOICE_OF_THE_PEOPLE_KALANDRA" )
                self.fury = self:AddArgument( "BURNING_FURY" )
                self.handout = self:AddArgument("RISE_HANDOUT")
                local handout_scale = { 1, 2, 2, 3 }
                self.handout.stacks = DemocracyUtil.CalculateBossScale(handout_scale)

                self:SetPattern( self.DemocracyUnrestCycle )
                return
            end
            return old_init(self, ...)
        end,
        DemocracyUnrestCycle = function( self, turns, ... )
            if self.engine and self.engine.revolution_activated then
                self:SetPattern( self.DemocracyUnrestCycle )
                self:DemocracyRevolutionCycle(turns, ...)
                return
            end
            self:ChooseCard(self.voice)
            if turns % 3 == 1 then
                self:ChooseGrowingNumbers(1, -1)
                self:ChooseCard(self.handout)
            elseif turns % 3 == 2 then
                self:ChooseGrowingNumbers(1, 0)
                self:ChooseComposure(1, 3, 7)
            else
                self:ChooseGrowingNumbers(2, 0)
            end
        end,
        DemocracyRevolutionCycle = function(self, turns)
            self.revolution_turns = (self.revolution_turns or 0) + 1
            if self.revolution_turns % 2 == 1 then
                self:ChooseGrowingNumbers(3, 0, 1.25)
            else
                self:ChooseGrowingNumbers(2, 1)
            end
            local fury_stacks = self.negotiator:GetModifierInstances( "BURNING_FURY" )
            if fury_stacks == 0 then
                if self.skip_fury_turn then
                    self.skip_fury_turn = false
                else
                    self:ChooseCard(self.fury)
                    self.skip_fury_turn = true
                end
            end
        end,
    },
    ANDWANETTE =
    {
        OnInitDemocracy = function(self, old_init, ...)
            if self.engine and CheckBits(self.engine:GetFlags(), NEGOTIATION_FLAGS.WORDSMITH) then
                self.negotiator:AddModifier("ETIQUETTE")

                self.opulence = self:AddArgument( "OPULENCE" )
                self.attacks = self:MakePicker()
                self.attacks:AddArgument( "ploy", 1 )
                self.attacks:AddArgument( "SNARE", 1 )
                self:SetPattern( self.DemocracyBossCycle )
                return
            end
            return old_init(self, ...)
        end,
        DemocracyBossCycle = function( self, turns )
            if turns == 1 then
                self:ChooseCard(self.opulence)
            elseif turns % 2 == 0 then
                self.attacks:ChooseCard()
            end
            if turns % 3 == 1 then
                self:ChooseGrowingNumbers(1, 0)
                self:ChooseComposure(1, 3, 7)
            elseif turns % 3 == 2 then
                self:ChooseGrowingNumbers(1, 2)
            else
                self:ChooseGrowingNumbers(2, -1)
                self:ChooseComposure(1, 2, 5)
            end
        end,
    },
}

for id, data in pairs(NEW_BEHAVIOURS) do
    DemocracyUtil.AddDemocracyNegotiationBehaviour(id, data)
end
