local t = {
    DEBATE_SCRUM_HOST =
    {
        OnInit = function( self, difficulty )
            self.impatience_delay = 3 - math.floor((GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY ) or 1) / 2)
            self.negotiator:AddModifier("DEBATE_SCRUM_TRACKER")
        end,
        Cycle = function(self, turns)
        end,
    },
    INTERVIEWER_BOSS =
    {
        QUESTION_STACKS = {3, 3, 3, 3},
        OnInit = function( self, difficulty )
            local relationship_delta = self.agent and (self.agent:GetRelationship() - RELATIONSHIP.NEUTRAL) or 0
            self:SetPattern( self.BasicCycle )
            local modifier = self.negotiator:AddModifier("INTERVIEWER")
            self.cont_question_card = self:AddCard("contemporary_question_card")
            self.cont_question_card.stacks = DemocracyUtil.CalculateBossScale(self.QUESTION_STACKS)

            self.modifier_picker = self:MakePicker()

            local _, card = self.modifier_picker:AddArgument("LOADED_QUESTION", 2 + math.max(0, -relationship_delta))
            card.stacks = DemocracyUtil.CalculateBossScale(self.QUESTION_STACKS)
            local _, card = self.modifier_picker:AddArgument("PLEASANT_QUESTION", 2 + math.max(0, relationship_delta))
            card.stacks = DemocracyUtil.CalculateBossScale(self.QUESTION_STACKS)
            local _, card = self.modifier_picker:AddArgument("GENERIC_QUESTION", 4)
            card.stacks = DemocracyUtil.CalculateBossScale(self.QUESTION_STACKS)

            if not self.params then self.params = {} end
            self.params.questions_answered = 0
            self.available_issues = copyvalues(DemocracyConstants.issue_data)
        end,
        BasicCycle = function( self, turns )
            -- Double attack every 2 rounds; Single attack otherwise.
            if self.difficulty >= 4 and turns % 2 == 0 then
                self:ChooseGrowingNumbers( 3, -1 )
            elseif turns % 2 == 0 then
                self:ChooseGrowingNumbers( 2, 0 )
            else
                self:ChooseGrowingNumbers( 1, 1 )
            end
            local question_count = 0
            for i, data in self.negotiator:Modifiers() do
                if data.AddressQuestion then
                    question_count = question_count + 1
                end
            end
            if turns % 3 == 1 then
                self:ChooseCard(self.cont_question_card)
                if question_count < 4 then
                    self.modifier_picker:ChooseCards(1)
                end
            else
                self.modifier_picker:ChooseCards(question_count < 4 and 2 or 1)
            end
        end,
    },
    PROPAGANDA_DRAFT =
    {
        OnInit = function( self, difficulty )
            self:SetPattern( self.BasicCycle )
            self.negotiator:AddModifier("POSTER_SIMULATION_ENVIRONMENT")
        end,

        BasicCycle = function( self, turns )
            -- literally does nothing.
        end,
    },
    PREACH_CROWD =
    {
        OnInit = function( self, difficulty )
            -- self.bog_boil = self:AddCard("bog_boil")
            self:SetPattern( self.BasicCycle )
            local modifier = self.negotiator:AddModifier("PREACH_CROWD")
            modifier.agents = shallowcopy(self.agents)
            modifier:InitModifiers()
        end,
        agents = {},
        -- ignored_agents = {},

        BasicCycle = function( self, turns )
            local scaling = 1.5

            local adv_scale = GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_RESOLVE_DAMAGE )
            if adv_scale then
                scaling = scaling * adv_scale
            end
            local VARIANCE = 0.2
            scaling = scaling * ((math.random() - 0.5) * 2 * VARIANCE + 1)

            -- Double attack every 2 rounds; Single attack otherwise.
            if self.difficulty >= 4 and turns % 2 == 0 then
                self:ChooseNumbers( 3, 2 + math.random(-1,1), scaling * 0.6 )
            elseif turns % 2 == 0 then
                self:ChooseNumbers( 2, 1 + math.random(-1,1), scaling * 0.8 )
            else
                self:ChooseNumbers( 1, 1 + math.random(-1,1), scaling )
            end
        end,
    },
    SELL_MERCH_CROWD =
    {
        OnInit = function( self, difficulty )
            -- self.bog_boil = self:AddCard("bog_boil")
            self:SetPattern( self.BasicCycle )
            local modifier = self.negotiator:AddModifier("SELL_MERCH_CROWD")
            modifier.agents = shallowcopy(self.agents)
            modifier:InitModifiers()
        end,
        agents = {},
        -- ignored_agents = {},

        BasicCycle = function( self, turns )
            local scaling = 1.5

            local adv_scale = GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_RESOLVE_DAMAGE )
            if adv_scale then
                scaling = scaling * adv_scale
            end
            local VARIANCE = 0.2
            scaling = scaling * ((math.random() - 0.5) * 2 * VARIANCE + 1)

            -- Double attack every 2 rounds; Single attack otherwise.
            if self.difficulty >= 4 and turns % 2 == 0 then
                self:ChooseNumbers( 3, 2 + math.random(-1,1), scaling * 0.6 )
            elseif turns % 2 == 0 then
                self:ChooseNumbers( 2, 1 + math.random(-1,1), scaling * 0.8 )
            else
                self:ChooseNumbers( 1, 1 + math.random(-1,1), scaling )
            end
        end,
    },
    TEA_BENEFACTOR =
    {
        BENEFACTOR_DEFS = {
            WEALTHY_MERCHANT = "PROPOSITION",
            SPARK_BARON_TASKMASTER = "APPROPRIATOR",
            PRIEST = "ZEAL",
        },
        SIGNATURE_ARGUMENT = {
            WEALTHY_MERCHANT = "TRIBUTE",
            PRIEST = "prayer_of_hesh",
        },
        OnInit = function( self, difficulty )
            -- local modifier
            self.arguments = self:MakePicker()
                :AddArgument( "CAUTIOUS_SPENDER", 1 )

            local _, card = self.arguments:AddArgument( "HOSPITALITY", 1 )
            card.stacks = 1 + math.floor( difficulty / 2 ) + (GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ARGUMENT_PLUS ) and 1 or 0)

            if self.SIGNATURE_ARGUMENT[self.agent:GetContentID()] then
                self.signature = self:AddArgument(self.SIGNATURE_ARGUMENT[self.agent:GetContentID()])
            end

            self:SetPattern( self.BasicCycle )

            self.negotiator:AddModifier(self.BENEFACTOR_DEFS[self.agent:GetContentID()])

        end,
        agents = {},

        BasicCycle = function( self, turns )
            if turns % 3 == 0 then
                self:ChooseGrowingNumbers(2, -1)
            else
                self:ChooseGrowingNumbers(1, 1)
            end

            if turns % 3 == 1 then
                self.arguments:ChooseCard()
            elseif turns % 3 == 2 then
                if self.signature and math.random(0, self.signature_played or 0) == 0 then
                    self:ChooseCard(self.signature)
                    self.signature_played = (self.signature_played or 0) + 1
                end
            end
            if turns % 2 == 0 then
                self:ChooseComposure( 1, self.difficulty, self.difficulty + 2 )
            end

        end,
    },
    DRONUMPH_DEPRESSION =
    {
        OnInit = function( self, difficulty )
            local modifier = self.negotiator:AddModifier("PESSIMIST")

            if self.negotiator:FindCoreArgument() and self.negotiator:FindCoreArgument():GetResolve() then
                self.negotiator:FindCoreArgument():ModifyResolve(-math.floor(0.7 * self.negotiator:FindCoreArgument():GetResolve()), self)
            end
            -- self.negotiator:CreateModifier("RESTORE_RESOLVE_GOAL", 1, self)

            self.self_loathe = self:AddArgument("SELF_LOATHE")

            self.negotiator:AddModifier("ENCOURAGEMENT")

            self:SetPattern( self.BasicCycle )
        end,

        BasicCycle = function( self, turns )
            if turns == 1 or math.random() < 0.5 then
                self:ChooseCard(self.self_loathe)
            else
                self:ChooseGrowingNumbers( 1, -1 )
            end
            if turns % 3 == 0 then
                self:ChooseGrowingNumbers( 3, 0 )
            else
                self:ChooseGrowingNumbers( 2, 1 )
            end

            local candidates = {}
            for i, card in ipairs(self.prepared_cards) do
                if card.id == "default" and card.target_enemy then
                    table.insert(candidates, card)
                end
            end
            if #candidates > 0 then
                local chosen = table.arraypick(candidates)
                chosen.target_self = TARGET_FLAG.CORE
                chosen.target_enemy = nil
            end
        end,
    },
    HESHIAN_FANATIC =
    {
        OnInit = function( self, difficulty )
            local modifier = self.negotiator:AddModifier("ZEAL")
            self.faith = self:AddArgument("FAITH_IN_HESH")
            self.wrath = self:AddArgument( "wrath_of_hesh" )
            self.hesh_arguments = table.shuffle({
                self:AddArgument("STINGING_NETTLE"),
                self:AddArgument("COMB_BEARER")
            })

            self:SetPattern( self.BasicCycle )
        end,

        BasicCycle = function( self, turns )
            self:ChooseGrowingNumbers( 2, 1, 2 )
            self:ChooseComposure( 2, 1, 3 )
            if turns < 4 then
                self:ChooseCard(self.faith)
            else
                self:ChooseCard(self.wrath)
            end
            if (turns - 1) % 2 == 0 then
                if turns < 4 and ((turns - 1) / 2) < #self.hesh_arguments then
                    self:ChooseCard(self.hesh_arguments[1 + ((turns - 1) / 2)])
                end
            end
        end,
    },
    COURT_OF_LAW =
    {
        OnInit = function( self, difficulty )
            local modifier = self.negotiator:AddModifier("DEM_COURT_OF_LAW")

            self.attacks = self:MakePicker()
            self.attacks:AddArgument( "INTERROGATE", 1 )
            self.attacks:AddArgument( "THOROUGH_SEARCH", 1 )

            self.evidence_card = self:AddCard("dem_present_evidence")

            if self.agent:GetContentID() == "ADMIRALTY_INVESTIGATOR" then
                self:SetPattern( self.BasicCycle )
            else
                -- They are defending themselves. The pattern is significantly easier
                self:SetPattern( self.EasyCycle )
            end
        end,

        plaintiff_arguments = {},

        BasicCycle = function( self, turns )
            if turns % 2 == 1 then
                if self.plaintiff_arguments and #self.plaintiff_arguments > 0 then
                    self:ChooseCard(self.evidence_card)
                else
                    self.attacks:ChooseCards(1)
                end
                self:ChooseGrowingNumbers(1, 0)
            else
                if turns < self.engine:GetDifficulty() then
                    self.attacks:ChooseCards(1)
                else
                    self:ChooseComposure( 1, 1 + self.difficulty, 1 + self.difficulty )
                end
                self:ChooseGrowingNumbers(2, -1)
            end
        end,
        EasyCycle = function( self, turns )
            if turns == 2 then
                if self.plaintiff_arguments and #self.plaintiff_arguments > 0 then
                    self:ChooseCard(self.evidence_card)
                else
                    self:ChooseComposure( 1, 1 + self.difficulty, 1 + self.difficulty )
                end
            end
            if turns % 2 == 1 then
                self:ChooseGrowingNumbers(1, 0)
                self:ChooseComposure( 1, 1 + self.difficulty, 1 + self.difficulty )
            else
                self:ChooseGrowingNumbers(2, -1)
            end
        end,

    },
}

DemocracyUtil.BEHAVIOURS = t

return t
