local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT

local function CreateNewSelfMod(self)
    local newmod = self.negotiator:CreateModifier(self.id, self.stacks, self)
    if newmod then
        newmod.generation = (self.generation or 0) + 1
        newmod.init_max_resolve = self.init_max_resolve
        if newmod.OnInit then
            newmod:OnInit()
        end
    end
end
local function CalculateBonusScale(self)
    if self.bonus_scale and type(self.bonus_scale) == "table" then
        if self.engine and CheckBits(self.engine:GetFlags(), NEGOTIATION_FLAGS.WORDSMITH) then
            return DemocracyUtil.CalculateBossScale(self.bonus_scale)
        else
            return self.bonus_scale[2]
        end
    end
    return self.bonus_per_generation
end
local function MyriadInit(self)
    self.bonus_per_generation = CalculateBonusScale(self)
    if self.generation and self.generation > 0 then
        self.init_max_resolve = self.init_max_resolve + self.bonus_per_generation
    end
    self:SetResolve(self.init_max_resolve, self.resolve_scaling)
end

local MODIFIERS =
{
    PLAYER_ADVANTAGE =
    {
        name = "Limited Time",
        desc = "The player wins after {1} {1*turn|turns}, but will yield a worse result than winning a negotiation normally.",
        icon = "DEMOCRATICRACE:assets/modifiers/player_advantage.png",
        desc_fn = function( self, fmt_str )
            return loc.format(fmt_str, self.stacks or 1)
        end,
        modifier_type = MODIFIER_TYPE.PERMANENT,
        -- win_on_turn = 7,
        event_handlers = {
            [ EVENT.BEGIN_PLAYER_TURN ] = function( self, minigame )
                if minigame.turns > 1 then
                    self.negotiator:RemoveModifier(self, 1)
                    if self.stacks <= 0 then
                        minigame:Win()
                        minigame.impasse = true
                    end
                end
            end,
        },
    },
    SELL_MERCH_CROWD =
    {
        name = "Potential Customers",
        desc = "At the beginning of the player's turn, create a new <b>Potential Customer</> argument({1} left).",
        desc_fn = function(self, fmt_str )

            return loc.format(fmt_str, #self.agents)
        end,
        icon = "negotiation/modifiers/heckler.tex",
        modifier_type = MODIFIER_TYPE.CORE,
        agents = {},
        ignored_agents = {},
        CreateTarget = function(self, agent)
            local modifier = Negotiation.Modifier("SELL_MERCH_TARGET_INTEREST", self.negotiator)
            modifier:SetAgent(agent)
            self.negotiator:CreateModifier(modifier)
        end,
        TryCreateNewTarget = function(self)
            if self.agents and #self.agents > 0 then
                self:CreateTarget(self.agents[1])
                table.remove(self.agents, 1)
                return true
            end
            return false
        end,
        event_priorities =
        {
            [ EVENT.BEGIN_PLAYER_TURN ] = 999,
        },
        event_handlers = {
            [ EVENT.BEGIN_PLAYER_TURN ] = function( self, minigame )
                if minigame.turns > 1 then
                    -- for i = 1, math.floor(self.engine:GetDifficulty() / 3 + 1) do
                        self:TryCreateNewTarget()
                    -- end
                end
                if #self.agents == 0 and self.negotiator:GetModifierInstances( "SELL_MERCH_TARGET_INTEREST" ) == 0 then
                    minigame:Win()
                end
            end,
        },
        InitModifiers = function(self)
            self.ignored_agents = {}
            for i = 1, 2 + math.floor(self.engine:GetDifficulty() / 2) do
                self:TryCreateNewTarget()
            end
        end,
    },
    SELL_MERCH_TARGET_INTEREST =
    {
        name = "Potential Customer",
        desc = "Each turn, this argument attacks an opponent argument or gain resolve.\n\n" ..
            "When this argument is destroyed, gain {2} {SECURED_FUNDS} from {1.fullname}, plus {3} additional stacks for each remaining stack on <b>Potential Customer</>.\n\n" ..
            "Remove a stack at the start of the player's turn. <#PENALTY>When the last stack is removed, if this argument has more than {4} resolve, {1.name} will become annoyed and dislike you.</>",
        loc_strings = {
            BONUS_LOVED = "<#BONUS><b>{1.name} loves you.</> {2} max resolve.</>",
            BONUS_LIKED = "<#BONUS><b>{1.name} likes you.</> {2} max resolve.</>",
            BONUS_DISLIKED = "<#PENALTY><b>{1.name} dislikes you.</> +{2} max resolve.</>",
            BONUS_HATED = "<#PENALTY><b>{1.name} hates you.</> +{2} max resolve.</>",
            BONUS_BRIBED = "<#BONUS><b>{1.name} is bribed.</> {2} max resolve.</>",
        },
        delta_max_resolve = {
            [RELATIONSHIP.LOVED] = -8,
            [RELATIONSHIP.LIKED] = -4,
            [RELATIONSHIP.DISLIKED] = 4,
            [RELATIONSHIP.HATED] = 8,
        },
        bribe_delta = -4,
        key_maps = {
            [RELATIONSHIP.LOVED] = "BONUS_LOVED",
            [RELATIONSHIP.LIKED] = "BONUS_LIKED",
            [RELATIONSHIP.DISLIKED] = "BONUS_DISLIKED",
            [RELATIONSHIP.HATED] = "BONUS_HATED",
        },
        desc_fn = function( self, fmt_str, minigame, widget )
            if self.target_agent and widget and widget.PostPortrait then
                widget:PostPortrait( self.target_agent )
            end
            local result_strings = {}
            if self.target_agent then
                if self.key_maps[self.target_agent:GetRelationship()] then
                    table.insert(result_strings, loc.format(self.def:GetLocalizedString(self.key_maps[self.target_agent:GetRelationship()]), self.target_agent, self.delta_max_resolve[self.target_agent:GetRelationship()]))
                end
                if self.target_agent:HasAspect("bribed") then
                    table.insert(result_strings, loc.format(self.def:GetLocalizedString("BONUS_BRIBED"), self.target_agent, self.bribe_delta))
                end
            end
            table.insert(result_strings, loc.format(fmt_str, self.target_agent and self.target_agent:LocTable(), self.funding_delta, self.additional_delta, self.annoyed_threshold or 12))
            return table.concat(result_strings, "\n")
        end,
        no_damage_tt = true,
        icon = engine.asset.Texture("negotiation/modifiers/voice_of_the_people.tex"),

        target_enemy = TARGET_ANY_RESOLVE,
        composure_gain = 2,
        modifier_type = MODIFIER_TYPE.ARGUMENT,

        funding_delta = 15,
        additional_delta = 5,
        is_first_turn = true,

        SetAgent = function (self, agent)
            local difficulty = self.engine and self.engine:GetDifficulty() or 1
            self.target_agent = agent
            self.max_resolve = difficulty * 5 + 7
            self.annoyed_threshold = self.max_resolve - (difficulty) * 4
            self.annoyed_threshold = math.max(1, self.annoyed_threshold)
            if agent:HasAspect("bribed") then
                self.max_resolve = self.max_resolve + self.bribe_delta
            end
            self.max_resolve = math.max(1, self.max_resolve + (self.delta_max_resolve[agent:GetRelationship()] or 0))
            self:SetResolve(math.max(self.max_resolve, 1))

            self.annoyed_threshold = math.min(self.max_resolve, math.floor((self.max_resolve + self.annoyed_threshold) / 2))

            self.min_persuasion = math.floor((difficulty - 1) / 2)
            self.max_persuasion = 2 + math.floor(difficulty / 2)

            if agent:GetRelationship() > RELATIONSHIP.NEUTRAL then
                self.max_persuasion = self.max_persuasion - 1
            elseif agent:GetRelationship() < RELATIONSHIP.NEUTRAL then
                self.max_persuasion = self.max_persuasion + 1
            end

            if agent:HasAspect("bribed") then
                self.max_persuasion = self.max_persuasion - 1
            end

            -- ensures max_persuasion is greater than min_persuasion
            self.max_persuasion = math.max(self.min_persuasion, self.max_persuasion)

            if agent.negotiation_ally_image then
                self.icon = agent.negotiation_ally_image
                self.engine:BroadcastEvent( EVENT.UPDATE_MODIFIER_ICON, self)
                -- self:NotifyTriggered()
            end
            self.stacks = 3

            self:NotifyChanged()
        end,

        OnBounty = function(self, source)
            if source and source ~= self then
                self.anti_negotiator:DeltaModifier("SECURED_FUNDS", self.funding_delta + self.additional_delta * self.stacks, self)
            end
        end,

        OnEndTurn = function( self, minigame )
            if self.target_enemy then
                self:ApplyPersuasion()
            end
        end,

        event_handlers = {
            [ EVENT.BEGIN_PLAYER_TURN ] = function( self, minigame )
                if not self.is_first_turn then
                    self.negotiator:RemoveModifier(self, 1)
                    -- self.turns_left = self.turns_left - 1
                    if self.stacks <= 0 then
                        local core = self.negotiator:FindCoreArgument()
                        if core and core.ignored_agents then
                            if self.resolve > self.annoyed_threshold then
                                table.insert(core.ignored_agents, self.target_agent)
                            end
                        end
                        -- self.negotiator:RemoveModifier(self)
                    end
                    -- self:NotifyChanged()
                end
                if self.stacks > 0 then
                    self.target_enemy = math.random() < 0.5 and TARGET_ANY_RESOLVE or nil
                    if not self.target_enemy then
                        self:DeltaComposure(self.composure_gain, self)
                    end
                end
            end,
            [ EVENT.END_TURN ] = function( self, minigame, negotiator )
                self.is_first_turn = false
            end,
        },
    },
    PREACH_CROWD =
    {
        name = "Crowd Mentality",
        desc = "At the beginning of the player's turn, create a new <b>Potential Interest</> argument({1} left).",
        desc_fn = function(self, fmt_str )

            return loc.format(fmt_str, #self.agents)
        end,
        icon = "negotiation/modifiers/heckler.tex",
        modifier_type = MODIFIER_TYPE.CORE,
        agents = {},
        ignored_agents = {},
        CreateTarget = function(self, agent)
            local modifier = Negotiation.Modifier("PREACH_TARGET_INTEREST", self.negotiator)
            modifier:SetAgent(agent)
            self.negotiator:CreateModifier(modifier)
        end,
        TryCreateNewTarget = function(self)
            if self.agents and #self.agents > 0 then
                self:CreateTarget(self.agents[1])
                table.remove(self.agents, 1)
                return true
            end
            return false
        end,
        event_priorities =
        {
            [ EVENT.BEGIN_PLAYER_TURN ] = 999,
        },
        event_handlers = {
            [ EVENT.BEGIN_PLAYER_TURN ] = function( self, minigame )
                if minigame.turns > 1 then
                    -- for i = 1, math.floor(self.engine:GetDifficulty() / 3 + 1) do
                        self:TryCreateNewTarget()
                    -- end
                end
                if #self.agents == 0 and self.negotiator:GetModifierInstances( "PREACH_TARGET_INTEREST" ) == 0 then
                    minigame:Win()
                end
            end,
        },
        InitModifiers = function(self)
            self.ignored_agents = {}
            for i = 1, 2 + math.floor(self.engine:GetDifficulty() / 2) do
                self:TryCreateNewTarget()
            end
        end,
    },
    PREACH_TARGET_INTEREST =
    {
        name = "Potential Interest",
        desc = "Each turn, this argument attacks an opponent argument or gain resolve.\n\n" ..
            "Destroy this argument to convince <b>{1.fullname}</> to join your side.\n\n"..
            "Remove a stack at the start of the player's turn. <#PENALTY>When the last stack is removed, if "..
            "this argument has more than {2} resolve, {1.name} will become annoyed and dislike you.</>",
        loc_strings = {
            BONUS_LOVED = "<#BONUS><b>{1.name} loves you.</> {2} max resolve.</>",
            BONUS_LIKED = "<#BONUS><b>{1.name} likes you.</> {2} max resolve.</>",
            BONUS_DISLIKED = "<#PENALTY><b>{1.name} dislikes you.</> +{2} max resolve.</>",
            BONUS_HATED = "<#PENALTY><b>{1.name} hates you.</> +{2} max resolve.</>",
            BONUS_BRIBED = "<#BONUS><b>{1.name} is bribed.</> {2} max resolve.</>",
        },
        delta_max_resolve = {
            [RELATIONSHIP.LOVED] = -8,
            [RELATIONSHIP.LIKED] = -4,
            [RELATIONSHIP.DISLIKED] = 4,
            [RELATIONSHIP.HATED] = 8,
        },
        bribe_delta = -4,
        key_maps = {
            [RELATIONSHIP.LOVED] = "BONUS_LOVED",
            [RELATIONSHIP.LIKED] = "BONUS_LIKED",
            [RELATIONSHIP.DISLIKED] = "BONUS_DISLIKED",
            [RELATIONSHIP.HATED] = "BONUS_HATED",
        },
        desc_fn = function( self, fmt_str, minigame, widget )
            if self.target_agent and widget and widget.PostPortrait then
                widget:PostPortrait( self.target_agent )
            end
            local result_strings = {}
            if self.target_agent then
                if self.key_maps[self.target_agent:GetRelationship()] then
                    table.insert(result_strings, loc.format(self.def:GetLocalizedString(self.key_maps[self.target_agent:GetRelationship()]), self.target_agent, self.delta_max_resolve[self.target_agent:GetRelationship()]))
                end
                if self.target_agent:HasAspect("bribed") then
                    table.insert(result_strings, loc.format(self.def:GetLocalizedString("BONUS_BRIBED"), self.target_agent, self.bribe_delta))
                end
            end
            table.insert(result_strings, loc.format(fmt_str, self.target_agent and self.target_agent:LocTable(), self.annoyed_threshold or 12))
            return table.concat(result_strings, "\n")
        end,
        no_damage_tt = true,
        icon = engine.asset.Texture("negotiation/modifiers/voice_of_the_people.tex"),

        target_enemy = TARGET_ANY_RESOLVE,
        composure_gain = 2,
        modifier_type = MODIFIER_TYPE.ARGUMENT,

        -- turns_left = 3,
        is_first_turn = true,

        SetAgent = function (self, agent)
            local difficulty = self.engine and self.engine:GetDifficulty() or 1
            self.target_agent = agent
            self.max_resolve = difficulty * 5 + 7
            self.annoyed_threshold = self.max_resolve - (difficulty) * 4
            self.annoyed_threshold = math.max(1, self.annoyed_threshold)
            if agent:HasAspect("bribed") then
                self.max_resolve = self.max_resolve + self.bribe_delta
            end
            self.max_resolve = math.max(1, self.max_resolve + (self.delta_max_resolve[agent:GetRelationship()] or 0))
          --  self.min_persuasion = 2 + agent:GetRenown()
            --self.max_persuasion = self.min_persuasion + 4
            self:SetResolve(math.max(self.max_resolve, 1))

            self.annoyed_threshold = math.min(self.max_resolve, math.floor((self.max_resolve + self.annoyed_threshold) / 2))

            self.min_persuasion = math.floor((difficulty - 1) / 2)
            self.max_persuasion = 2 + math.floor(difficulty / 2)

            if agent:GetRelationship() > RELATIONSHIP.NEUTRAL then
                self.max_persuasion = self.max_persuasion - 1
            elseif agent:GetRelationship() < RELATIONSHIP.NEUTRAL then
                self.max_persuasion = self.max_persuasion + 1
            end

            if agent:HasAspect("bribed") then
                self.max_persuasion = self.max_persuasion - 1
            end

            -- ensures max_persuasion is greater than min_persuasion
            self.max_persuasion = math.max(self.min_persuasion, self.max_persuasion)

            if agent.negotiation_ally_image then
                self.icon = agent.negotiation_ally_image
                self.engine:BroadcastEvent( EVENT.UPDATE_MODIFIER_ICON, self)
                -- self:NotifyTriggered()
            end
            self.stacks = 3

            self:NotifyChanged()
        end,

        OnBounty = function(self, source)
            if source and source ~= self then
                local modifier = Negotiation.Modifier( "PREACH_TARGET_INTERESTED", self.anti_negotiator )
                if modifier and modifier.SetAgent then
                    modifier:SetAgent(self.target_agent)
                end
                self.anti_negotiator:CreateModifier( modifier )
            end
        end,

        OnEndTurn = function( self, minigame )
            if self.target_enemy then
                self:ApplyPersuasion()
            end
        end,

        event_handlers = {
            [ EVENT.BEGIN_PLAYER_TURN ] = function( self, minigame )
                if not self.is_first_turn then
                    self.negotiator:RemoveModifier(self, 1)
                    -- self.turns_left = self.turns_left - 1
                    if self.stacks <= 0 then
                        local core = self.negotiator:FindCoreArgument()
                        if core and core.ignored_agents then
                            if self.resolve > self.annoyed_threshold then
                                table.insert(core.ignored_agents, self.target_agent)
                            end
                        end
                        -- self.negotiator:RemoveModifier(self)
                    end
                    -- self:NotifyChanged()
                end
                if self.stacks > 0 then
                    self.target_enemy = math.random() < 0.5 and TARGET_ANY_RESOLVE or nil
                    if not self.target_enemy then
                        self:DeltaComposure(self.composure_gain, self)
                    end
                end
            end,
            [ EVENT.END_TURN ] = function( self, minigame, negotiator )
                self.is_first_turn = false
            end,
        },
    },
    PREACH_TARGET_INTERESTED =
    {
        name = "Interested Target",
        desc = "{1.fullname} is interested in your ideology! Protect this argument until the end of the negotiation.",
        desc_fn = function( self, fmt_str, minigame, widget )
            if self.target_agent and widget and widget.PostPortrait then
                --local txt = loc.format( "{1#agent} is not ready to fight!", self.ally_agent )
                widget:PostPortrait( self.target_agent )
            end
            return loc.format(fmt_str, self.target_agent and self.target_agent:LocTable())
        end,

        target_enemy = TARGET_ANY_RESOLVE,
        modifier_type = MODIFIER_TYPE.BOUNTY,

        icon = engine.asset.Texture("negotiation/modifiers/voice_of_the_people.tex"),

        SetAgent = function (self, agent)
            self.target_agent = agent
            self.max_resolve = 4
          --  self.min_persuasion = 2 + agent:GetRenown()
            --self.max_persuasion = self.min_persuasion + 4
            self:SetResolve(self.max_resolve, MODIFIER_SCALING.LOW)

            self.min_persuasion = 0
            self.max_persuasion = 2

            if agent:GetRelationship() > RELATIONSHIP.NEUTRAL then
                self.max_persuasion = self.max_persuasion + 1
            elseif agent:GetRelationship() < RELATIONSHIP.NEUTRAL then
                self.max_persuasion = self.max_persuasion - 1
            end

            if agent:HasAspect("bribed") then
                self.max_persuasion = self.max_persuasion + 1
            end
            if agent.negotiation_ally_image then
                self.icon = agent.negotiation_ally_image
                self.engine:BroadcastEvent( EVENT.UPDATE_MODIFIER_ICON, self)
                -- self:NotifyTriggered()
            end
            self:NotifyChanged()
        end,
        OnEndTurn = function( self, minigame )
            self:ApplyPersuasion()
        end,
    },
    DEM_HELP_REQUEST_PROGRESS =
    {
        name = "Help Request Progress",
        desc = "You need to describe your current situation enough in order for help to be on your way. Reach {1} stacks for the help to be sent.",
        icon = "negotiation/modifiers/hard_facts.tex",

        modifier_type = MODIFIER_TYPE.PERMANENT,

        calls_required = 6,

        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.calls_required )
        end,

        CleanUpCard = function(self, card_id)
            local to_expend = {}
            for i,card in self.engine:GetHandDeck():Cards() do
                if card.id == card_id then
                    table.insert(to_expend, card)
                end
            end
            for i,card in self.engine:GetDrawDeck():Cards() do
                if card.id == card_id then
                    table.insert(to_expend, card)
                end
            end
            for i,card in self.engine:GetDiscardDeck():Cards() do
                if card.id == card_id then
                    table.insert(to_expend, card)
                end
            end

            if #to_expend > 0 then
                for i,card in ipairs(to_expend) do
                    self.engine:ExpendCard(card)
                end
            end
        end,

        event_handlers = {
            [ EVENT.MODIFIER_CHANGED ] = function( self, modifier, delta, clone )
                if modifier == self and modifier.stacks >= self.calls_required then
                    if self.negotiator:GetModifierStacks("HELP_UNDERWAY") <= 0 then
                        local stacks = 12
                        if self.engine and self.engine.help_turns then
                            stacks = self.engine.help_turns
                        end
                        self.negotiator:AddModifier("HELP_UNDERWAY", stacks)
                    end

                    self.negotiator:RemoveModifier(self.id, math.huge, self)
                    self.negotiator:RemoveModifier("CONNECTED_LINE", self.negotiator:GetModifierStacks("CONNECTED_LINE"), self)
                    self:CleanUpCard("assassin_fight_call_for_help")
                end
            end,
        },
    },
    DEM_HASTENED_IMPATIENCE =
    {
        hidden = true,

        event_handlers =
        {
            [ EVENT.PREPARE_INTENTS ] = function(self, behaviour, prepared_cards)
                if behaviour ~= self.negotiator.behaviour then
                    return
                end
                self.delay = self.delay or 2
                print(loc.format("Getting impatient... Turn {1} delay {2}", self.engine.turns, self.delay))
                self.delay = self.delay - 1
                if self.delay == 0 then
                    self.delay = 1
                    local impatience = behaviour:AddCard("impatience")
                    table.insert(prepared_cards, impatience)
                end
            end,
        }
    },
    -- Prevents player softlocking by exhausting all call for help card while no help is arriving
    DEM_ASSASSIN_SOFTLOCK_PROTECTION =
    {
        hidden = true,

        OnBeginTurn = function(self, minigame)
            if self.negotiator:GetModifierStacks("CONNECTED_LINE") == 0 and self.negotiator:GetModifierStacks("HELP_UNDERWAY") == 0 then
                local card_id = "assassin_fight_call_for_help"
                for i,card in self.engine:GetHandDeck():Cards() do
                    if card.id == card_id then
                        return
                    end
                end
                for i,card in self.engine:GetDrawDeck():Cards() do
                    if card.id == card_id then
                        return
                    end
                end
                for i,card in self.engine:GetDiscardDeck():Cards() do
                    if card.id == card_id then
                        return
                    end
                end

                -- At this point we softlocked ourselves. Give the player a card in draw pile
                local card = Negotiation.Card( "assassin_fight_call_for_help", minigame.player_negotiator.agent )
                card.show_dealt = true
                card:TransferCard(minigame:GetDrawDeck())
            end
        end,
    },
    CONNECTED_LINE =
    {
        name = "Connected Line",
        -- Me wall of text
        desc = "Gain 1 {DEM_HELP_REQUEST_PROGRESS} at the beginning of each turn.\n\n"..
            "If this gets destroyed, the opponent gains 1 {IMPATIENCE}.",

        icon = "DEMOCRATICRACE:assets/modifiers/connected_line.png",

        modifier_type = MODIFIER_TYPE.ARGUMENT,
        max_resolve = 3,
        max_stacks = 10,

        OnApply = function(self)
            local count = self.negotiator:GetModifierStacks("CONNECTED_LINE")
            if count and count ~= 0 then
                TheGame:GetMusic():SetParameter("radio_layer", 1)
            end
        end,

        OnUnapply = function(self)
            local phase_3 = self.negotiator:GetModifierStacks("HELP_UNDERWAY") > 0
            if not phase_3 then
                TheGame:GetMusic():SetParameter("radio_layer", 0)

                -- local card = Negotiation.Card( "assassin_fight_call_for_help", self.engine:GetPlayer() )
                -- if self.stacks > 1 then
                --     card.init_help_count = self.stacks
                -- end
                -- self.engine:DealCard(card, self.engine:GetDiscardDeck())
            end
        end,

        OnBounty = function(self, source)
            if source ~= self then
                self.anti_negotiator:AddModifier("IMPATIENCE", 1)
            end
        end,
        event_handlers =
        {
            [ EVENT.BEGIN_PLAYER_TURN ] = function( self, minigame )
                self.negotiator:AddModifier("DEM_HELP_REQUEST_PROGRESS", 1, self)
            end,
        },
    },
    HELP_UNDERWAY =
    {
        name = "Help Underway!",
        desc = "Distract <b>{1}</> for {2} more turns until the help arrives!\n\n" ..
            "If you lose the negotiation while help is underway, you can still keep {1} occupied " ..
            "through battle, and survive the assassination!",
        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.anti_negotiator and self.anti_negotiator:GetName() or "the opponent",  self.stacks)
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/help_underway.png",

        max_stacks = 20,

        modifier_type = MODIFIER_TYPE.PERMANENT,

        -- turns_left = rawget(_G, "SURVIVAL_TURNS") or 12,
        OnApply = function(self)
            self.engine:BroadcastEvent( EVENT.CUSTOM, function( panel )
                panel:SetMusicPhase(2)
            end )
        end,

        -- In the rare case where you somehow remove the argument prematurely, you don't softlock yourself
        OnUnapply = function( self, minigame )
            if self.stacks > 0 then
                self.negotiator:CreateModifier(self.id, self.stacks, self)
            else
                minigame:Win()
            end
        end,

        event_handlers = {
            [ EVENT.BEGIN_PLAYER_TURN ] = function( self, minigame )
                if self.stacks <= 1 then
                    minigame:Win()
                elseif minigame.turns > 1 then
                    self.negotiator:RemoveModifier(self, 1)
                    self:NotifyChanged()
                    if self.stacks <= 3 then
                        self.engine:BroadcastEvent( EVENT.CUSTOM, function( panel )
                            panel:SetMusicPhase(4)
                        end )
                    end
                end
            end,
        },
    },
    DISTRACTION_ENTERTAINMENT =
    {
        name = "Distraction: Entertainment",
        desc = "{MYRIAD_MODIFIER {2}}.\n\nWhen destroyed, {1} loses 2 {IMPATIENCE} if able.",
        icon = "negotiation/modifiers/card_draw.tex",

        modifier_type = MODIFIER_TYPE.BOUNTY,
        init_max_resolve = 10,

        bonus_per_generation = 2,
        bonus_scale = {2, 2, 3, 4},

        generation = 0,

        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.negotiator and self.negotiator:GetName() or "the opponent",
                CalculateBonusScale(self))
        end,
        OnInit = function(self)
            if (self.generation or 0) == 0 and self.engine:GetDifficulty() > 1 then
                self.init_max_resolve = self.init_max_resolve + 5 * (self.engine:GetDifficulty() - 1)
            end
            MyriadInit(self)
        end,
        OnBounty = function(self)
            if self.negotiator:GetModifierStacks("IMPATIENCE") > 0 then
                self.negotiator:RemoveModifier("IMPATIENCE", 2, self)
            end
            CreateNewSelfMod(self)
        end,
    },
    DISTRACTION_GUILTY_CONSCIENCE =
    {
        name = "Distraction: Guilty Conscience",
        desc = "{MYRIAD_MODIFIER {2}}.\n\nWhen destroyed, remove a random intent and {1} gains 2 {VULNERABILITY}.",
        icon = "negotiation/modifiers/scruple.tex",

        modifier_type = MODIFIER_TYPE.BOUNTY,
        init_max_resolve = 10,

        bonus_per_generation = 2,
        bonus_scale = {2, 2, 3, 4},

        generation = 0,

        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.negotiator and self.negotiator:GetName() or "the opponent",
                CalculateBonusScale(self))
        end,
        OnInit = function(self)
            if (self.generation or 0) == 0 and self.engine:GetDifficulty() > 1 then
                self.init_max_resolve = self.init_max_resolve + 5 * (self.engine:GetDifficulty() - 1)
            end
            MyriadInit(self)
        end,
        OnBounty = function(self)
            local intents = {}
            for i, data in ipairs(self.negotiator:GetIntents()) do
                -- if data.id ~= "impatience" then
                table.insert(intents, data)
                -- end
            end

            if #intents > 0 then
                self.negotiator:DismissIntent(intents[math.random(#intents)])
            end
            self.negotiator:AddModifier("VULNERABILITY", 2)

            CreateNewSelfMod(self)
        end,
    },
    DISTRACTION_CONFUSION =
    {
        name = "Distraction: Confusion",
        desc = "{MYRIAD_MODIFIER {2}}.\n\nWhen destroyed, {1} gain 2 {FLUSTERED}.",
        icon = "negotiation/modifiers/doubt.tex",

        modifier_type = MODIFIER_TYPE.BOUNTY,
        init_max_resolve = 10,

        bonus_per_generation = 2,
        bonus_scale = {2, 2, 3, 4},

        generation = 0,

        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.negotiator and self.negotiator:GetName() or "the opponent",
                CalculateBonusScale(self))
        end,
        OnInit = function(self)
            if (self.generation or 0) == 0 and self.engine:GetDifficulty() > 1 then
                self.init_max_resolve = self.init_max_resolve + 5 * (self.engine:GetDifficulty() - 1)
            end
            MyriadInit(self)
        end,
        OnBounty = function(self)

            self.negotiator:AddModifier("FLUSTERED", 2)

            CreateNewSelfMod(self)
        end,
    },

    INTERVIEWER =
    {
        name = "Interviewer",
        desc = "At the end of {1}'s turn, apply 1 {COMPOSURE} to each of up to {2} random {2*argument|arguments} they control for every question arguments they have.\n\nAt the beginning of the player's turn, add an {address_question} card to the player's hand.",
        desc_fn = function(self, fmt_str )
            return loc.format(fmt_str, self:GetOwnerName(), self.composure_targets)
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/interviewer.png",

        -- icon = engine.asset.Texture("negotiation/modifiers/heckler.tex"),
        modifier_type = MODIFIER_TYPE.CORE,

        composure_targets = 2,

        target_scale = {1, 2, 3, 4},

        OnInit = function( self )
            self.composure_targets = DemocracyUtil.CalculateBossScale(self.target_scale)
        end,

        OnEndTurn = function(self)
            local question_count = 0
            for i, data in self.negotiator:Modifiers() do
                if data.AddressQuestion then
                    question_count = question_count + 1
                end
            end
            -- local targets = {}
            local candidates = self.engine:CollectAlliedTargets(self.negotiator)
            -- for i, modifier in self.negotiator:ModifierSlots() do
            --     if modifier:GetResolve() ~= nil then
            --         table.insert( targets, {modifier=modifier, count=0} )
            --     end
            -- end
            local targets = {}
            for i = 1, self.composure_targets do
                if #candidates > 0 then
                    local chosen = math.random(#candidates)
                    table.insert(targets, candidates[chosen])
                    table.remove(candidates, chosen)
                end
            end
            for i, target in ipairs(targets) do
                target:DeltaComposure( question_count, self)
            end
        end,
        event_handlers = {
            [ EVENT.BEGIN_PLAYER_TURN ] = function( self, minigame )
                local card = Negotiation.Card( "address_question", minigame:GetPlayer() )
                card.show_dealt = false
                minigame:DealCards( {card}, minigame:GetHandDeck() )
            end,
            [ EVENT.MODIFIER_REMOVED ] = function( self, modifier )
                if modifier.AddressQuestion then
                    local behaviour = self.negotiator.behaviour
                    if not behaviour.params then behaviour.params = {} end
                    behaviour.params.questions_answered = (behaviour.params.questions_answered or 0) + 1
                end
            end,
        },
        InitModifiers = function(self)
            -- for i = 1, 2 + math.floor(self.engine:GetDifficulty() / 2) do
            --     self:TryCreateNewTarget()
            -- end
        end,
    },
    SECURED_FUNDS =
    {
        name = "Secured Funds",
        icon = "negotiation/modifiers/frisk.tex",
        desc = "Gain {1} shills if the negotiation is successful.",
        alt_desc = "Gain shills equal to the number of stacks on this argument if the negotiation is successful.",
        desc_fn = function(self, fmt_str)
            if self.stacks then
                return loc.format(fmt_str, self.stacks)
            else
                return loc.format((self.def or self):GetLocalizedString("ALT_DESC"))
            end
        end,

        max_stacks = 999,

        modifier_type = MODIFIER_TYPE.PERMANENT,

        OnUnapply = function( self, minigame )
            if self.stacks > 0 then
                self.negotiator:CreateModifier(self.id, self.stacks, self)
            end
        end,
    },
    INVESTMENT_OPPORTUNITY  =
    {
        name = "Investment Opportunity",
        icon = "negotiation/modifiers/frisk.tex",
        desc = "{MYRIAD_MODIFIER {2}}\n\nWhen destroyed, gain {1} {SECURED_FUNDS}.",
        alt_desc = "{MYRIAD_MODIFIER {1}}\n\nWhen destroyed, gain {SECURED_FUNDS} equal to the number of stacks on this bounty.",

        desc_fn = function(self, fmt_str)
            if self.stacks then
                return loc.format(fmt_str, self.stacks or 1, self.bonus_per_generation)
            else
                return loc.format((self.def or self):GetLocalizedString("ALT_DESC"), self.bonus_per_generation)
            end
        end,

        -- max_resolve = 5,
        -- max_stacks = 1,
        bonus_per_generation = 2,

        modifier_type = MODIFIER_TYPE.BOUNTY,

        OnInit = function(self)
            if not self.init_max_resolve then
                self.init_max_resolve = math.ceil(self.stacks / 2.5)
            else
                self.init_max_resolve = self.init_max_resolve + self.bonus_per_generation
            end
            self:SetResolve(self.init_max_resolve, MODIFIER_SCALING.LOW)
        end,

        OnBounty = function(self, source)
            -- self.negotiator:CreateModifier("CAUTIOUS_SPENDER")
            self.anti_negotiator:AddModifier("SECURED_FUNDS", self.stacks)
            CreateNewSelfMod(self)
        end,
    },
    HOSPITALITY =
    {
        name = "Hospitality",
        icon = "negotiation/modifiers/compromise.tex",
        desc = "Whenever you play a Hostility card, discard a random card.\n\nReduce <b>Hospitality</b> by 1 at the beginning of {1}'s turn.",

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:GetOwnerName() )
        end,

        max_resolve = 5,
        modifier_type = MODIFIER_TYPE.ARGUMENT,

        OnInit = function(self)
            self:SetResolve(self.max_resolve, MODIFIER_SCALING.MED)
        end,

        event_handlers =
        {
            [ EVENT.POST_RESOLVE ] = function( self, minigame, card )
                if card:GetNegotiator() == self.engine:GetPlayerNegotiator() then
                    if minigame:GetTurns() > 0 and card:IsFlagged( CARD_FLAGS.HOSTILE ) then
                        local card = self.engine:GetHandDeck():PeekRandom()
                        self.engine:DiscardCard( card )
                    end
                end
            end,

            [ EVENT.BEGIN_TURN ] = function( self, minigame, negotiator )
                if negotiator == self.negotiator then
                    negotiator:RemoveModifier( self, 1 )
                end
            end,
        },
    },
    CAUTIOUS_SPENDER  =
    {
        name = "Cautious Spender",
        icon = "negotiation/modifiers/obscurity.tex",
        desc = "At the begging of each turn, add {1} resolve to a random {{2}} bounty.",

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.delta_resolve, self.apply_target)
        end,

        max_resolve = 3,
        max_stacks = 1,

        delta_resolve = 2,
        apply_target = "INVESTMENT_OPPORTUNITY",

        modifier_type = MODIFIER_TYPE.ARGUMENT,

        OnInit = function(self)
            self:SetResolve(self.max_resolve, MODIFIER_SCALING.MED)
            self.delta_resolve = self.engine:GetDifficulty() + 1 + (GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ARGUMENT_PLUS ) and 1 or 0)
        end,

        event_handlers =
        {
            [ EVENT.BEGIN_TURN ] = function( self, minigame, negotiator )
                if negotiator == self.negotiator then
                    local candidates = {}
                    for i, modifier in self.negotiator:ModifierSlots() do
                        if modifier.id == self.apply_target then
                            table.insert(candidates, modifier)
                        end
                    end
                    local modifier = table.arraypick(candidates)
                    modifier:ModifyResolve( self.delta_resolve, self )
                    self:NotifyTriggered()
                end
            end
        }
    },

    POSTER_SIMULATION_ENVIRONMENT = {
        name = "Simulation Environment",
        desc = "You are writing a propaganda poster in a simulation environment. This will record cards that you play onto your poster.\n\nYou can end the negotiation at any time if you concede, and you won't suffer any penalties.",
        alt_desc = "(Recorded Cards: {1#comma_listing})",

        desc_fn = function(self, fmt_str)
            if self.cards_played and #self.cards_played > 0 then
                local txt = {}
                for i, card in ipairs(self.cards_played) do
                    table.insert(txt, loc.format("{1#card}", type(card) == "string" and card or card[1]))
                end
                return fmt_str .. "\n\n" .. loc.format((self.def or self):GetLocalizedString("ALT_DESC"), txt)
            end
            return fmt_str
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/simulation_environment.png",


        modifier_type = MODIFIER_TYPE.CORE,
        max_stacks = 1,
        OnInit = function(self)
            if not self.cards_played then
                self.cards_played = {}
            end
        end,
        CanBeRecorded = function(self, card)
            -- we don't want unplayable cards to be recorded. and we also don't want opponent cards to be recorded.
            return self.engine:GetPlayerNegotiator() == card.negotiator and
                not CheckBits( card.flags, CARD_FLAGS.UNPLAYABLE ) and
                not CheckAnyBits( card.flags, CARD_FLAGS.BYSTANDER ) and card.played_from_hand
                and not CheckAnyBits( card.flags, CARD_FLAGS.FLOURISH )
                and card.id ~= "propaganda_poster"
        end,

        CheckAllowRecord = function(self, source)
            if source and source == self.resolve_card then
                self.is_allowed = true
            end
        end,

        event_handlers = {
            [ EVENT.START_RESOLVE ] = function(self, minigame, card)
                if self:CanBeRecorded(card) and not self.resolve_card then
                    self.is_allowed = false
                    -- we only want the card the player directly plays from hand to be recorded.
                    -- "at sorcery speed", so to speak.
                    self.resolve_card = card
                end
            end,
            [ EVENT.END_RESOLVE ] = function(self, minigame, card)
                if self.resolve_card == card then
                    self.resolve_card = nil
                    if self.is_allowed then
                        local card_data = shallowcopy(card.userdata) or {}
                        card_data.xp = nil
                        table.insert(self.cards_played, {card.id, card_data})
                    end
                end
            end,
            [ EVENT.ATTACK_RESOLVE ] = function( self, source, target, damage, params, defended )
                self:CheckAllowRecord(source)
            end,
            [ EVENT.DELTA_RESOLVE ] = function( self, modifier, resolve, max_resolve, delta, source, params )
                self:CheckAllowRecord(source)
            end,
            [ EVENT.DELTA_COMPOSURE ] =  function( self, modifier, new_value, old_value, source, start_of_turn )
                self:CheckAllowRecord(source)
            end,
            [ EVENT.MODIFIER_ADDED ] = function( self, modifier, source )
                self:CheckAllowRecord(source)
            end,
            [ EVENT.MODIFIER_CHANGED ] = function( self, modifier, delta, clone, source )
                self:CheckAllowRecord(source)
            end,
            [ EVENT.MODIFIER_REMOVED ] = function ( self, modifier, source )
                self:CheckAllowRecord(source)
            end,
            [ EVENT.INTENT_REMOVED ] = function( self, card )
                self:CheckAllowRecord(card)
            end,
        },
    },
    SIMULATION_ARGUMENT = {
        name = "Simulation Argument",
        desc = "It literally does nothing. It's just there.",
        icon = "negotiation/modifiers/bidder.tex",
        modifier_type = MODIFIER_TYPE.ARGUMENT,
        max_resolve = 30,
    },
    TIME_CONSTRAINT = {
        name = "Time Is Money",
        desc = "Every 2 turns in this negotiation, you lose a free time action for the current quest.\n\n<#PENALTY>The negotiation will end if you ran out of actions for the quest!</>\n\n({1} actions left on the quest)",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.stacks)
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/time_constraint.png",

        modifier_type = MODIFIER_TYPE.PERMANENT,
        -- max_stacks = 1,
        event_handlers = {
            [ EVENT.END_PLAYER_TURN ] = function ( self, minigame )
                if minigame:GetTurns() % 2 == 0 then
                    self.negotiator:RemoveModifier(self, 1)
                end
                if self.stacks <= 0 then
                    minigame:Lose()
                end
            end,
        },
    },
    ALTERNATIVE_CORE_ARGUMENT = {
        hidden = true,
        event_handlers = {
            [ EVENT.MODIFIER_REMOVED ] = function ( self, modifier )
                if modifier and modifier == self.tracked_modifier then
                    self.engine:Lose()
                end
            end,
        }
    },
    NO_PLAY_FROM_HAND = {
        loc_strings = {
            CANT_PLAY = "Can't play cards from hand",
        },
        hidden = true,
        CanPlayCardModifier = function( self, source, engine, target )

            if self.engine and self.engine:GetHandDeck():HasCard(source) then
                return false, (self.def or self):GetLocalizedString("CANT_PLAY")
            end

            return true
        end,
    },
    NARCISSISM = {
        name = "Narcissism",
        desc = "At the start of {1}'s turn, create {2:a|{2} separate} {PRIDE} {2*argument|arguments}.",
        icon = "DEMOCRATICRACE:assets/modifiers/narcissism.png",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:GetOwnerName(), self:GetPrideCount(self.engine and self.engine:GetDifficulty() or 1))
        end,

        modifier_type = MODIFIER_TYPE.CORE,
        max_stacks = 1,

        num_created = {1,1,2,2,2},
        GetPrideCount = function(self, difficulty)
            return self.num_created[math.min(difficulty, #self.num_created)]
        end,
        event_handlers =
        {
            [ EVENT.END_TURN ] = function ( self, minigame, negotiator )
                if negotiator == self.negotiator then
                    for i = 1, self:GetPrideCount(self.engine and self.engine:GetDifficulty() or 1) do
                        self.negotiator:CreateModifier( "PRIDE", 1, self )
                    end
                end
            end,
        },
    },
    PRIDE = {
        name = "Pride",
        -- Having it heal while having 6 resolve is a bit too much, I think.
        desc = "At the start of {1}'s turn, apply {2} {COMPOSURE} to {1}'s core argument.",
        icon = "DEMOCRATICRACE:assets/modifiers/pride.png",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:GetOwnerName(), self.composure_gain)
        end,
        modifier_type = MODIFIER_TYPE.ARGUMENT,
        max_stacks = 1,
        max_resolve = 2,
        OnInit = function(self)
            self:SetResolve(self.max_resolve, MODIFIER_SCALING.MED)
        end,
        composure_gain = 2,
        OnBeginTurn = function( self, minigame )
            self.negotiator:FindCoreArgument():DeltaComposure( self.composure_gain, self )
        end,
    },
    FRAGILE_EGO = {
        name = "Fragile Ego",
        desc = "Remove all {PRIDE}s and incept that much {VULNERABILITY} when destroyed.",
        icon = "DEMOCRATICRACE:assets/modifiers/fragile_ego.png",
        modifier_type = MODIFIER_TYPE.BOUNTY,
        max_stacks = 1,
        max_resolve = 4,
        OnInit = function(self)
            self:SetResolve(self.max_resolve, MODIFIER_SCALING.MED)
        end,
        OnBounty = function( self )
            local stacks = self.negotiator:GetModifierStacks("PRIDE")
            self.negotiator:RemoveModifier("PRIDE", stacks, self)
            self.negotiator:AddModifier("VULNERABILITY", stacks, self)
        end,
    },
    PLANTED_EVIDENCE_MODDED =
    {
        name = "Planted Evidence",
        desc = "When this argument is destroyed, deal {1} damage to a random core argument on {2}'s side.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self.stacks or 2, self:GetOwnerName() )
        end,

        max_resolve = 1,

        modifier_type = MODIFIER_TYPE.BOUNTY,

        sound = "event:/sfx/battle/cards/neg/create_argument/strawman",
        icon = "negotiation/modifiers/planted_evidence.tex",

        OnBounty = function( self )
            local targets = {}
            for i, modifier in self.negotiator:ModifierSlots() do
                if modifier.modifier_type == MODIFIER_TYPE.CORE and not
                    (modifier:GetShieldStatus()
                    or modifier.max_resolve == nil) then
                    table.insert(targets, modifier)
                end
            end
            local target = table.arraypick(targets)
            self.engine:ApplyPersuasion( self, target, self.stacks, self.stacks )
        end,
    },
    APPROPRIATED_MODDED =
    {
        name = "Appropriated",
        desc = "When this argument is destroyed, all cards are returned to {2}'s hand. {2} gains 2 {VULNERABILITY}.",
        alt_desc = "When this argument is destroyed, all cards are returned to {2.fullname}'s card pool. The opponent gains 2 {VULNERABILITY}.",
        desc_fn = function( self, fmt_str, minigame, widget )
            if widget and widget.PostCard then
                for i, card in ipairs( self.stolen_cards) do
                    widget:PostCard( card.id, card, minigame )
                end
            end
            if self.stolen_from and self.stolen_from.available_cards then
                return loc.format((self.def or self):GetLocalizedString("ALT_DESC"), self:GetOwnerName(),
                    self.stolen_from.candidate_agent and self.stolen_from.candidate_agent:LocTable())
            else
                return loc.format( fmt_str, self:GetOwnerName(), self:GetOpponentName() )
            end
        end,

        max_resolve = 1,
        max_stacks = 1,

        modifier_type = MODIFIER_TYPE.BOUNTY,
        removed_sound = "event:/sfx/battle/cards/neg/appropriator_cardreleased",
        icon = "negotiation/modifiers/appropriated.tex",
        --sound = "event:/sfx/battle/cards/neg/create_argument/strawman",

        OnInit = function( self )
            self.stolen_cards = {}
            self:SetResolve( 1, MODIFIER_SCALING.LOW )
        end,

        GetStolenCount = function( self )
            return #self.stolen_cards
        end,

        AppropriateCard = function( self, card, owner )
            table.insert( self.stolen_cards, card )
            if owner and owner.available_cards then
                table.arrayremove(owner.available_cards, card)
            end
            card:RemoveCard()
            self.stolen_from = owner

            self:NotifyChanged()

            self.engine:BroadcastEvent( EVENT.CARD_STOLEN, card, self )
        end,

        OnBounty = function( self )
            for i, card in ipairs( self.stolen_cards ) do

                if self.stolen_from and self.stolen_from.available_cards then
                    print("Return to the pool of stuff")
                    table.insert(self.stolen_from.available_cards, card)
                else
                    self.engine:BroadcastEvent( EVENT.CUSTOM, function( panel )
                        local slot_widget = panel:FindSlotWidget( self )
                        if slot_widget then
                            local w = panel.cards:CreateCardWidget( card )
                            local x, y = w.parent:TransformFromWidget( slot_widget, 0, 0 )
                            w:SetPos( x, y )
                        end
                    end )
                    card.show_dealt = false
                    self.engine:InsertCard( card )
                end
            end

            self.anti_negotiator:InceptModifier("VULNERABILITY", 2)
        end,
    },
    ALL_BUSINESS_MODDED =
    {
        name = "All Business",
        desc = "At the start of the turn, a random allied argument gains {COMPOSURE {1}} for each Hostility card in all opponents' intent.",
        alt_desc = "A random allied argument gains {COMPOSURE {1}} for each Hostility card the player draw.",
        desc_fn = function( self, fmt_str )
            if self.negotiator and not self.negotiator:IsPlayer() then
                return loc.format( fmt_str .. "\n" .. (self.def or self):GetLocalizedString("ALT_DESC"), self.bonus )
            else
                return loc.format( fmt_str, self.bonus )
            end
        end,

        max_resolve = 1,
        max_stacks = 1,
        bonus = 1,

        sound = "event:/sfx/battle/cards/neg/create_argument/all_business",
        icon = "negotiation/modifiers/all_business.tex",

        OnInit = function( self )
            if self.engine then
                local difficulty = self.engine:GetDifficulty()
                self:SetResolve( 1, MODIFIER_SCALING.MED )
                self.bonus = difficulty
            end
        end,

        event_handlers =
        {
            [ EVENT.BEGIN_TURN ] = function( self, minigame, negotiator )
                if negotiator == self.negotiator then
                    local did_a_thing = false
                    for i, modifier in self.anti_negotiator:ModifierSlots() do
                        if modifier.prepared_cards then
                            for j, card in ipairs(modifier.prepared_cards) do
                                if card:IsFlagged( CARD_FLAGS.HOSTILE ) then
                                    -- self.negotiator:DeltaComposure( self.bonus, self )
                                    local targets = self.engine:CollectAlliedTargets(self.negotiator)
                                    if #targets > 0 then
                                        local target = targets[math.random(#targets)]
                                        target:DeltaComposure(self.bonus, self)
                                        -- self:AddXP(1)
                                        did_a_thing = true
                                    end

                                end
                            end
                        end
                    end
                    if did_a_thing then
                        self:NotifyTriggered()
                    end
                end
            end,
            [ EVENT.DRAW_CARD ] = function( self, engine, card, start_of_turn )
                if card:IsFlagged( CARD_FLAGS.HOSTILE ) and self.negotiator and not self.negotiator:IsPlayer() then
                    -- self.negotiator:DeltaComposure( self.bonus, self )
                    local targets = self.engine:CollectAlliedTargets(self.negotiator)
                    if #targets > 0 then
                        local target = targets[math.random(#targets)]
                        target:DeltaComposure(self.bonus, self)
                        -- self:AddXP(1)
                    end
                    self:NotifyTriggered()
                end
            end,
        },
    },
    DEBATE_SCRUM_TRACKER =
    {
        name = "Debate Host",
        desc = "Defeat ALL opponent negotiators to win this debate!\n\n" ..
            "You cannot play any more cards if your core argument is destroyed, and you lose if your core argument and all your allies' core argument are destroyed.\n\n" ..
            "All splash damage is disabled. Opponents arguments comes in to play with +{1} resolve.\n\n" ..
            "Perform various feats to score points and win the crowd. <#PENALTY>Your allies will also do the same, so score more than your allies to stand out!</>",
        loc_strings = {
            SCORE_DAMAGE = "Damage Dealt",
            SCORE_FULL_BLOCK = "Damage Deflected",
            SCORE_ARGUMENT_DESTROYED = "Argument Refuted",
            SCORE_OPPONENT_DESTROYED = "Opponent Refuted",
            SCORE_ARGUMENT_CREATED = "Argument Created",
            SCORE_ARGUMENT_INCEPTED = "Argument Incepted",
            SCORE_UNDERDOG = "Underdog",
            SCORE_DELTA = "+{1} Pts",
        },
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:GetBonusResolve())
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/debate_scrum_tracker.png",

        modifier_type = MODIFIER_TYPE.CORE,
        max_stacks = 1,

        bonus_resolve = {2, 3, 4, 5},
        GetBonusResolve = function(self)
            if self.engine and CheckBits(self.engine:GetFlags(), NEGOTIATION_FLAGS.WORDSMITH) then
                return DemocracyUtil.CalculateBossScale(self.bonus_resolve)
            end
            return self.bonus_resolve[2]
        end,

        OnInit = function(self)
            self.scores = {}
            self.player_score = 0

            self.score_widgets = {}
            self.player_score_widget = {}

            -- self:DeltaScore(200, nil, "SCORE_DAMAGE")
            -- self:DeltaScore(100, nil, "SCORE_DAMAGE")
        end,

        GetScoreText = function(self, delta, reason, multiplier)
            local res
            if self.loc_strings[reason] then
                res = (self.def or self):GetLocalizedString(reason)
            else
                res = ""
            end
            if res ~= "" then
                res = res .. " "
            end
            if multiplier and multiplier > 1 then
                res = res .. "x" .. multiplier
            end
            if res ~= "" then
                res = res .. " "
            end

            return loc.format( res ..
                (self.def or self):GetLocalizedString("SCORE_DELTA"), delta)
        end,
        DeltaScore = function(self, delta, source, reason)
            local function PopupText(panel, source_widget, deltay, text_color, widget_list)
                if delta == 0 then
                    return
                end
                print(loc.format("{1} gains {2} pts because of {3}", source, delta, reason))
                for i, data in ipairs(widget_list) do
                    if data and data.reason and data.reason == reason then
                        data.score = (data.score or 0) + delta
                        data.multiplier = (data.multiplier or 1) + 1
                        data.label:SetText(self:GetScoreText(data.score, reason, data.multiplier))
                        return
                    end
                end
                local label = panel:AddChild( Widget.Label( "title", 28, self:GetScoreText(delta, reason) ):SetBloom( 0.1 ))
                local insert_index = 1
                while widget_list[insert_index] ~= nil do
                    insert_index = insert_index + 1
                end
                widget_list[insert_index] = {score = delta, multiplier = 1, label = label, reason = reason}
                label:SetGlyphColour( text_color )
                    :SetOutlineColour( 0x000000FF )
                    :EnableOutline( 0.25 )

                local screenw, screenh = panel:GetFE():GetScreenDims()
                local sx, sy
                if source_widget then
                    sx, sy = panel:TransformFromWidget(source_widget, 0, 0)
                else
                    -- LOGWARN("Fail to find minigame objective for some reason")
                    sx, sy = screenw / 2, screenh / 2
                end
                label:AlphaTo(0, 0)
                label:SetPos( sx, sy + (insert_index - 1) * deltay)

                label:MoveTo( sx, sy + insert_index * deltay, 0.2, easing.outQuad )
                label:AlphaTo(1, 0.2)
                -- label:Delay(1)
                local t = 2
                local prev_tick = widget_list[insert_index].multiplier
                while (t > 0) do
                    local dt = coroutine.yield()
                    t = t - dt
                    if widget_list[insert_index].multiplier ~= prev_tick then
                        prev_tick = widget_list[insert_index].multiplier
                        t = 2
                    end
                end

                widget_list[insert_index] = nil

                label:MoveTo( sx, sy + (insert_index + 1) * deltay, 0.2, easing.inQuad )
                label:AlphaTo(0, 0.2)
                label:Delay(0.2)
                label:Remove()

            end
            if type(source) == "number" then
                if self.scores[source] then
                    source = self.scores[source].modifier
                else
                    source = self.engine:FindModifierByUID(source)
                end
            end
            -- Now only cards can score points. Arguments can't other than the core
            if type(source) == "table" and (is_instance(source, Negotiation.Card) or source.candidate_agent) then
                local real_source = source.candidate_agent and source or source.real_owner
                if real_source then
                    -- Give the AI an edge. This way we can get away with lower damage output while
                    -- making the score race still a challenge
                    delta = delta * 2
                    if not self.scores[real_source:GetUID()] then
                        self.scores[real_source:GetUID()] = {modifier = real_source, score = 0}
                    end

                    if not self.score_widgets[real_source:GetUID()] then
                        self.score_widgets[real_source:GetUID()] = {}
                    end
                    self.engine:BroadcastEvent(EVENT.CUSTOM, function(panel)
                        -- panel:RefreshReason()
                        local source_widget = panel:FindSlotWidget( real_source )
                        if source_widget then
                            self.scores[real_source:GetUID()].score = self.scores[real_source:GetUID()].score + delta
                            real_source:NotifyChanged()
                            panel:StartCoroutine(PopupText, panel, source_widget, 32, UICOLOURS.WHITE, self.score_widgets[real_source:GetUID()])
                        end
                    end)
                    return
                end
            end

            if source == "PLAYER" or (is_instance(source, Negotiation.Card) and source.negotiator:IsPlayer()) then

                self.engine:BroadcastEvent(EVENT.CUSTOM, function(panel)
                    panel:RefreshReason()
                    local source_widget = self.engine:GetPlayerNegotiator():FindCoreArgument() and
                        panel:FindSlotWidget( self.engine:GetPlayerNegotiator():FindCoreArgument() ) or nil--panel.main_overlay.minigame_objective
                    self.player_score = self.player_score + delta
                    panel:StartCoroutine(PopupText, panel, source_widget, 32, UICOLOURS.WHITE, self.player_score_widget)
                    panel.player_modifiers:UpdatePersuasionLabels()
                    panel.opponent_modifiers:UpdatePersuasionLabels()
                end)
            end
        end,
        CheckGameOver = function(self)
            for i, mod in self.negotiator:Modifiers() do
                if mod.modifier_type == MODIFIER_TYPE.CORE and mod ~= self then
                    return
                end
            end
            if not self.engine:CheckGameOver() then
                self.engine:Win()
            end
        end,
        event_priorities =
        {
            [ EVENT.ATTACK_RESOLVE ] = 999,
            [ EVENT.CALC_PERSUASION ] = EVENT_PRIORITY_SETTOR,
        },
        event_handlers =
        {
            [ EVENT.START_RESOLVE ] = function(self, minigame, card)
                card.damages_during_play = {}
            end,
            [ EVENT.END_RESOLVE ] = function(self, minigame, card)
                if card.damages_during_play then
                    -- print(loc.format("{1#listing}", card.damages_during_play))
                    local delta_score = 0
                    table.sort(card.damages_during_play, function(a,b) return a > b end)
                    for i, dmg in ipairs(card.damages_during_play) do
                        -- Gains full score for the first two hits.
                        -- Then, exponentially decrease score gained.
                        delta_score = delta_score + math.ceil(dmg / math.max(1, math.pow(2, i - 1)))
                    end
                    if delta_score > 0 then
                        self:DeltaScore(delta_score * 1, card, "SCORE_DAMAGE")
                    end
                end
                card.damages_during_play = nil
            end,
            [ EVENT.ATTACK_RESOLVE ] = function( self, source, target, damage, params, defended )
                if params and params.splashed_modifier then
                    return
                end
                if source.negotiator == target.negotiator then
                    return -- self harm, does nothing.
                end
                if damage > defended then
                    print(loc.format("{1} dealt {3} damage to {2}", source, target, damage - defended))
                    if source.damages_during_play then
                        table.insert(source.damages_during_play, damage - defended)
                        return
                    end
                    -- print(loc.format("{1} dealt damage(real_owner={2})", source, source and source.real_owner))
                    if is_instance(source, Negotiation.Card) then
                        self:DeltaScore((damage - defended) * 1, source, "SCORE_DAMAGE")
                    end
                    -- if target == self.engine:GetPlayerNegotiator():FindCoreArgument() and not target.real_owner then
                    --     local cmp_delta = math.floor((damage - defended) / 2)
                    --     target.composure = target.composure + cmp_delta
                    -- end
                else
                    if target.composure_applier then
                        ----------------------------
                        -- Option 1: Anyone who applied composure share the score gained from deflection.
                        ----------------------------
                        local scorer = {}
                        for id, val in pairs(target.composure_applier) do
                            if val > 0 then
                                table.insert_unique(scorer, id)
                            end
                        end
                        local multiplier = math.max(0.5, 1 - 0.25 * (#scorer - 1))
                        for i, id in ipairs(scorer) do
                            if type(id) == "number" then
                                self:DeltaScore(math.ceil(damage * multiplier), id, "SCORE_FULL_BLOCK")
                            else
                                self:DeltaScore(math.ceil(damage * multiplier), "PLAYER", "SCORE_FULL_BLOCK")
                            end
                        end
                    end
                end
            end,
            [ EVENT.DELTA_COMPOSURE ] =  function( self, modifier, new_value, old_value, source, start_of_turn )
                local delta = new_value - old_value
                if delta > 0 then
                    if not modifier.composure_applier then
                        modifier.composure_applier = {}
                    end
                    if source and source.negotiator == modifier.negotiator then
                        if source.real_owner then
                            modifier.composure_applier[source.real_owner:GetUID()] = (modifier.composure_applier[source.real_owner:GetUID()] or 0) + delta
                            -- Simply register this modifier in case it gets destroyed later.
                            self:DeltaScore(0, modifier, "SCORE_FULL_BLOCK")
                        elseif is_instance(source, Negotiation.Card) and source:IsPlayerOwner() then
                            modifier.composure_applier["PLAYER"] = (modifier.composure_applier["PLAYER"] or 0) + delta
                        end
                    end
                end
                if new_value <= 0 then
                    modifier.composure_applier = nil
                end
            end,
            [ EVENT.MODIFIER_ADDED ] = function ( self, modifier, source )
                if modifier.negotiator == self.negotiator and modifier.modifier_type == MODIFIER_TYPE.ARGUMENT then
                    modifier:ModifyResolve(self:GetBonusResolve(), self)
                end
                if source and source.negotiator == modifier.negotiator and modifier.modifier_type == MODIFIER_TYPE.ARGUMENT then
                    self:DeltaScore(3, source, "SCORE_ARGUMENT_CREATED")
                end
                if source and source.negotiator == modifier.anti_negotiator and
                    (modifier.modifier_type == MODIFIER_TYPE.BOUNTY or modifier.modifier_type == MODIFIER_TYPE.INCEPTION) then

                    self:DeltaScore(3, source, "SCORE_ARGUMENT_INCEPTED")
                end
            end,
            [ EVENT.MODIFIER_REMOVED ] = function( self, modifier, source )
                if source and source.negotiator ~= modifier.negotiator then
                    if modifier.modifier_type == MODIFIER_TYPE.CORE then
                        self:DeltaScore(25, source, "SCORE_OPPONENT_DESTROYED")
                        self:CheckGameOver()
                        if modifier.negotiator == self.negotiator then

                        else
                            print("Check if self game over")
                            for i, mod in self.anti_negotiator:Modifiers() do
                                if mod.modifier_type == MODIFIER_TYPE.CORE and not mod.candidate_agent then
                                    return
                                end
                            end
                            -- only other candidates are left. You can no longer do anything.
                            local minigame = self.engine
                            minigame.hand_deck:TransferCards( minigame.trash_deck )
                            minigame.draw_deck:TransferCards( minigame.trash_deck )
                            minigame.discard_deck:TransferCards( minigame.trash_deck )
                            -- self.resolve_deck:TransferCards( self.trash_deck )
                        end
                    else
                        self:DeltaScore(3, source, "SCORE_ARGUMENT_DESTROYED")
                    end
                elseif modifier.modifier_type == MODIFIER_TYPE.CORE then
                    self:CheckGameOver()
                end
            end,
            [ EVENT.SPLASH_RESOLVE ] = function( self, modifier, overflow, params )
                params.splashed_modifier = nil
            end,
            [ EVENT.BEGIN_TURN ] = function( self, minigame, negotiator )
                self:CheckGameOver()
            end,
            [ EVENT.BEGIN_TURN ] = function( self, minigame, negotiator )
                local player_negotiators = 0
                local opponent_negotiators = 0
                local player_seen
                for i, mod in self.anti_negotiator:Modifiers() do
                    if mod.modifier_type == MODIFIER_TYPE.CORE then
                        if mod.candidate_agent then
                            player_negotiators = player_negotiators + 1
                        else
                            player_seen = true
                        end
                    end
                end
                if player_seen then
                    player_negotiators = player_negotiators + 1
                end
                for i, mod in self.negotiator:Modifiers() do
                    if mod.modifier_type == MODIFIER_TYPE.CORE then
                        if mod.candidate_agent then
                            opponent_negotiators = opponent_negotiators + 1
                        end
                    end
                end
                if negotiator == self.negotiator then
                    if opponent_negotiators < player_negotiators then
                        for i, mod in self.negotiator:Modifiers() do
                            if mod.modifier_type == MODIFIER_TYPE.CORE then
                                if mod.candidate_agent then
                                    self:DeltaScore(10 * (player_negotiators - opponent_negotiators), mod, "SCORE_UNDERDOG")
                                end
                            end
                        end
                    end
                else
                    player_seen = false
                    if player_negotiators < opponent_negotiators then
                        for i, mod in self.anti_negotiator:Modifiers() do
                            if mod.modifier_type == MODIFIER_TYPE.CORE then
                                if mod.candidate_agent then
                                    self:DeltaScore(10 * (opponent_negotiators - player_negotiators), mod, "SCORE_UNDERDOG")
                                elseif not player_seen then
                                    player_seen = true
                                    self:DeltaScore(10 * (opponent_negotiators - player_negotiators), "PLAYER", "SCORE_UNDERDOG")
                                end
                            end
                        end
                    end
                end
            end,
        },
    },
    CROWD_OPINION =
    {
        name = "Crowd Opinion",
        desc = "Whenever {1} creates an argument with an intent, it gains {2} resolve. If that argument is destroyed, gain 1 stack (max {3} {3*stack|stacks}).\n\nWhenever {4}'s argument is destroyed, lose 1 stack (min 1 stack).",
        loc_strings = {
            CURRENT_OPINION = "The crowd's current opinion is {1}.",
            NAME_1 = "<#PENALTY>Hostile</>",
            NAME_2 = "<#PENALTY>Skeptical</>",
            NAME_3 = "Divisive",
            NAME_4 = "<#BONUS>Sympathetic</>",
            NAME_5 = "<#BONUS>Supportive</>",

            BONUS_DMG = "{1} deals 1 bonus damage to {2}.",
        },
        icon = "DEMOCRATICRACE:assets/modifiers/crowd_opinion_1.png",
        icon_levels = {
            "DEMOCRATICRACE:assets/modifiers/crowd_opinion_1.png",
            "DEMOCRATICRACE:assets/modifiers/crowd_opinion_2.png",
            "DEMOCRATICRACE:assets/modifiers/crowd_opinion_3.png",
            "DEMOCRATICRACE:assets/modifiers/crowd_opinion_4.png",
            "DEMOCRATICRACE:assets/modifiers/crowd_opinion_5.png",
        },
        GetStage = function(self)
            return clamp(math.ceil(self.stacks / 2), 1, 5)
        end,
        desc_fn = function(self, fmt_str)
            local desc_lst = {}
            if self.engine and self.stacks then
                table.insert(desc_lst, loc.format((self.def or self):GetLocalizedString("CURRENT_OPINION"), (self.def or self):GetLocalizedString("NAME_" .. self:GetStage())))
                -- if self.stacks < 3 then
                --     table.insert(desc_lst, loc.format((self.def or self):GetLocalizedString("BONUS_DMG"), self:GetOwnerName(), self:GetOpponentName()))
                -- elseif self.stacks > 3 then
                --     table.insert(desc_lst, loc.format((self.def or self):GetLocalizedString("BONUS_DMG"), self:GetOpponentName(), self:GetOwnerName()))
                -- end
            end
            -- table.insert(desc_lst, loc.format(fmt_str, self:GetOwnerName(), "appeal_to_crowd_quest"))
            table.insert(desc_lst, loc.format(fmt_str, self:GetOwnerName(), self.max_stacks or 5))
            return table.concat(desc_lst, "\n")
        end,

        modifier_type = MODIFIER_TYPE.PERMANENT,
        max_stacks = 9,

        max_resolve_gain = 2,

        OnInit = function( self )
            if self.engine then
                self.max_resolve_gain = 1 + (GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_ABILITY_STRENGTH ) or 0) + self.engine:GetDifficulty()
            end
        end,

        OnSetStacks = function(self, old_stacks)
            local new_stacks = self:GetStage()
            -- print(new_stacks)
            -- print("newicon: ", self.icon_levels[new_stacks])
            self.icon = self.icon_levels[new_stacks] and engine.asset.Texture(self.icon_levels[new_stacks]) or self.icon
            self.engine:BroadcastEvent( EVENT.UPDATE_MODIFIER_ICON, self)
        end,

        event_handlers = {
            [ EVENT.MODIFIER_REMOVED ] = function(self, modifier, source)
                if (modifier.modifier_type == MODIFIER_TYPE.ARGUMENT) and modifier.stacks > 0 then
                    print("Modifier destroyed!", modifier)
                    if modifier.negotiator == self.anti_negotiator then
                        if self.stacks > 1 then
                            self.negotiator:RemoveModifier(self, 1, self)
                        end
                    elseif modifier.negotiator == self.negotiator then
                        if self.stacks < self.max_stacks then
                            self.negotiator:AddModifier(self, 1, self)
                        end
                    end
                end
            end,
            [ EVENT.PREPARE_INTENTS ] = function(self, behaviour, prepared_cards)
                if not self.negotiator:IsPlayer() and self.negotiator.prepared_cards then
                    if not self.instigate_card then
                        self.instigate_card = self.negotiator.behaviour:AddArgument("INSTIGATE_CROWD")
                        -- self.instigate_card.stacks = 2
                    end
                    table.insert(prepared_cards, self.instigate_card)
                end
            end,
            [ EVENT.MODIFIER_ADDED ] = function( self, modifier, source )
                if modifier.modifier_type == MODIFIER_TYPE.ARGUMENT and source and is_instance(source, Negotiation.Card) and source.negotiator == self.negotiator then
                    self.engine:PushPostHandler( function()
                        modifier:ModifyResolve(self.max_resolve_gain, self)
                        modifier.created_by_intent = true
                    end )
                end
            end,
        },
    },
    INSTIGATE_CROWD =
    {
        name = "Instigate Crowd",
        desc = "At the start of {1}'s turn, remove a stack. If the last stack is removed, remove 1 stack of {CROWD_OPINION} (min 1 stack).",
        icon = "negotiation/modifiers/influence.tex",

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.stack_trigger)
        end,

        max_resolve = 3,
        stack_trigger = 3,

        modifier_type = MODIFIER_TYPE.ARGUMENT,

        OnInit = function(self)
            self:SetResolve(self.max_resolve, MODIFIER_SCALING.MED)
        end,

        -- OnBounty = function(self)
        --     self.negotiator:AddModifier("CROWD_OPINION", 1, self)
        -- end,

        event_handlers =
        {

            [ EVENT.MODIFIER_CHANGED ] = function( self, modifier, delta, clone, source )
                if modifier == self and delta > 0 and self.stacks >= self.stack_trigger then
                    if self.negotiator:GetModifierStacks("CROWD_OPINION") > 1 then
                        self.negotiator:RemoveModifier("CROWD_OPINION", 1, self)
                        self.negotiator:RemoveModifier(self, self.stacks - 1, self)
                    end
                end
            end,
        },
    },
    FELLOW_GRIFTER = {
        name = "Fellow Grifter",
        desc = "{UPVOTE|}{CONTRARIAN|}{FAKE_NEWS|}Every {1} cards you play causes Aellon to gain an argument based on the type of the last card. ({2} remaining)",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self.num_cards or 5, self.count )
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/fellow_grifter.png",
        modifier_type = MODIFIER_TYPE.CORE,
        max_stacks = 1,
        num_cards = 5,
        count = 5,
        -- icon = "negotiation/modifiers/cool_head.tex",

        event_handlers =
        {
            [ EVENT.POST_RESOLVE ] = function( self, minigame, card )
                if card:GetNegotiator() ~= self.negotiator then
                    self.count = self.count - 1
                    if self.count == 0 then
                        self.count = self.num_cards
                        if card:IsFlagged( CARD_FLAGS.DIPLOMACY ) then
                            self.negotiator:CreateModifier( "UPVOTE", 1, self )
                        elseif card:IsFlagged( CARD_FLAGS.HOSTILE ) then
                            self.negotiator:CreateModifier( "CONTRARIAN", 1, self )
                        else --assuming flagged manipulate
                            self.negotiator:CreateModifier( "FAKE_NEWS", 1, self )
                        end
                    end
                end
            end,
        },
    },
    CONTRARIAN = {
        name = "Contrarian",
        desc = "Created by <b>Fellow Grifter</> when playing Hostility cards.\nWhen the core takes damage, this argument deals that amount of damage to a random argument.",
        icon = "DEMOCRATICRACE:assets/modifiers/contrarian.png",
        modifier_type = MODIFIER_TYPE.ARGUMENT,
        max_resolve = 3,
        -- icon = "negotiation/abrupt_remark.tex",
        event_handlers =
        {
            [ EVENT.ATTACK_RESOLVE ] = function( self, source, target, damage, params, defended )
                if target == self.negotiator:FindCoreArgument() and damage > 0 then
                    self.engine:PushPostHandler( function()
                        self.min_persuasion = damage
                        self.max_persuasion =  damage
                        self.target_enemy = TARGET_ANY_RESOLVE
                        self.engine:AssignPrimaryTarget( self )

                        self:ApplyPersuasion()
                        self.target_enemy = nil
                        self.min_persuasion = nil
                        self.max_persuasion = nil
                    end )
                end
            end,
        },
    },
    UPVOTE = {
        name = "Clout",
        desc = "Created by <b>Fellow Grifter</> when playing Diplomacy cards.\nDeals damage equal to the number of arguments Aellon controls.",
        icon = "DEMOCRATICRACE:assets/modifiers/upvote.png",
        desc_fn = function( self, fmt_str )
            return loc.format(fmt_str, self.max_persuasion)
        end,
        -- icon = "negotiation/modifiers/voice_of_the_people.tex",
        modifier_type = MODIFIER_TYPE.ARGUMENT,
        max_resolve = 3,

        min_persuasion = 1,
        max_persuasion = 1,

        target_enemy = TARGET_ANY_RESOLVE,

        OnInit = function( self )
            self:CalculateDamage(true)
        end,
        OnBeginTurn = function( self, minigame )
            self:ApplyPersuasion()
        end,
        CalculateDamage = function( self, bump_hack ) --On first spawning, it shows the wrong value. So... bump_hack!
            if self.negotiator then
                local count = bump_hack and 1 or 0
                for i, mod in self.negotiator:Modifiers() do
                    count = count + 1
                end
                self.min_persuasion = count
                self.max_persuasion = count
                self.engine:BroadcastEvent( EVENT.CUSTOM, function( panel )
                        panel.opponent_modifiers:UpdatePersuasionLabels()
                    end )
            end
        end,
        event_handlers =
        {
            [ EVENT.MODIFIER_ADDED ] = function( self, modifier, source )
                self:CalculateDamage()
            end,
            [ EVENT.MODIFIER_REMOVED ] = function( self, modifier, source )
                self:CalculateDamage()
            end,
        },
    },
    -- SHAD_BAN = {
    --     name = "Shadow Ban",
    --     max_resolve = 6,
    --     modifier_type = MODIFIER_TYPE.ARGUMENT,
    --     -- icon = "negotiation/modifiers/bidder.tex",
    --     desc = "At the start of {1}'s turn, add {SHIELDED} to a friendly argument.",
    --     desc_fn = function( self, fmt_str )
    --         local bonus = self.bonus or 0
    --         return loc.format( fmt_str, self:GetOwnerName())
    --     end,

    --     ShieldArgument = function( self, target )
    --         if self.last_shield and self.last_shield:IsApplied() then
    --             self.last_shield:SetShieldStatus( nil )
    --         end

    --         if target and target:IsApplied() then
    --             target:SetShieldStatus( true )
    --             self.last_shield = target
    --         end
    --     end,

    --     OnUnapply = function( self )
    --         self:ShieldArgument( nil )
    --     end,

    --     event_handlers =
    --     {
    --         [ EVENT.BEGIN_TURN ] = function( self, minigame, negotiator )
    --             if negotiator == self.negotiator then
    --                 local targets = {}
    --                 for i, modifier in self.negotiator:ModifierSlots() do
    --                     if modifier:GetResolve() ~= nil and not modifier:GetShieldStatus() then
    --                         table.insert( targets, modifier )
    --                     end
    --                 end

    --                 local target = table.arraypick( targets )
    --                 if target then
    --                     self:NotifyTriggered()
    --                     self:ShieldArgument( target )
    --                 end

    --             end
    --         end,
    --     },
    -- },
    FAKE_NEWS = {
        name = "Fake News",
        desc = "Created by <b>Fellow Grifter</> when playing Manipulation cards.\nIntents and target previews are hidden. Intents have a 50% chance to do +1 damage.",
        icon = "DEMOCRATICRACE:assets/modifiers/fake_news.png",
        max_resolve = 3,
        modifier_type = MODIFIER_TYPE.ARGUMENT,

        -- This is the crafty template.
        OnUnapply = function ( self )
            -- Need to trigger reveal for targets.
            self.engine:BroadcastEvent( EVENT.TARGETS_CHANGED )
        end,

        event_priorities =
        {
            [ EVENT.CALC_PERSUASION ] = EVENT_PRIORITY_ADDITIVE,
        },
        event_handlers =
        {
            [ EVENT.CALC_BOOLEAN ] = function( self, acc, key )
                if not self.negotiator:IsPlayer() and self.engine:GetTurns() >= self.turn_applied then
                    if key == "HIDE_INTENT" then
                        acc:ModifyValue( true, self )
                    end
                end
            end,
            [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion )
                if source.owner == self.owner and is_instance( source, Negotiation.Card ) then
                    persuasion:AddPersuasion( 0, 1, self )
                end
            end,
        },
    },
    -- TRENDY = {
    --     name = "Trending",
    --     desc = "When this reaches 5 stacks, Heal all arguments and the core resolve for 5 resolve.",
    --     max_resolve = 10,
    --     resolve_gain = 5,
    --     counter = 5,
    --     modifier_type = MODIFIER_TYPE.ARGUMENT,
    --     --Wumpus; I'm stumped on this one. Ive tried a lot, but either i
    --     event_handlers = {
    --         [ EVENT.POST_RESOLVE ] = function( self, minigame, card )
    --             local targets = self.engine:CollectAlliedTargets(self.negotiator)
    --             if #targets > 0 then
    --                 for i,target in ipairs(targets) do
    --                     if self.stacks >= self.counter then
    --                         target:ModifyResolve(self.resolve_gain, self)
    --                         self.negotiator:RemoveModifier( self )
    --                     end
    --                 end
    --             end
    --         end,
    --     },
    -- },
    LOGICAL = {
        name = "Logical",
        desc = "If {1}'s opponent has no {SMARTS}, {1} deals +{2} damage.",
        desc_fn = function( self, fmt_str )
            return loc.format(fmt_str, self:GetOwnerName(), DemocracyUtil.CalculateBossScale(self.damage_bonus))
        end,
        damage_bonus = { 1, 1, 1, 2 },
        modifier_type = MODIFIER_TYPE.CORE,
        max_stacks = 1,
        icon = "DEMOCRATICRACE:assets/modifiers/logic.png",
        bonus_count = 1,
        --okay this definitely needs to be made better but for now, from what I can tell...it does it's job enough.
        event_handlers =
        {
            [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion, minigame, target )
                if source.negotiator == self.negotiator and self.bonus_count and self.bonus_count > 0 then
                    local bonus = DemocracyUtil.CalculateBossScale(self.damage_bonus)
                    persuasion:AddPersuasion( bonus * self.bonus_count, bonus * self.bonus_count, self )
                end
            end,
            [ EVENT.MODIFIER_ADDED ] = function( self, modifier, source )
                if modifier.owner ~= self.owner then
                    if (modifier.modifier_type == MODIFIER_TYPE.ARGUMENT or modifier.modifier_type == MODIFIER_TYPE.BOUNTY) then
                        if modifier.id == "SMARTS" then
                            self.bonus_count = 0
                        end
                    end
                end
            end,
        },
    },
    FLAWED_LOGIC =
    {
        name = "Flawed Logic",
        modifier_type = MODIFIER_TYPE.BOUNTY,
        desc = "Gives you {1} {SMARTS} and deals {2} damage to {3}'s core argument.",
        desc_fn = function( self, fmt_str )
            return loc.format(fmt_str, self.smarts_amount, self.bounty_resolve, self:GetOwnerName() )
        end,
        max_stacks = 1,
        max_resolve = 3,
        bounty_resolve = 6,
        smarts_amount = 2,
        icon = "DEMOCRATICRACE:assets/modifiers/flawed_logic.png",
        OnBounty = function( self )
            self.anti_negotiator:AddModifier("SMARTS", 2, self)
            self.negotiator:ModifyResolve( -self.bounty_resolve * self.stacks, self )
        end,
    },
    FACTS =
    {
        name = "Facts",
        target_enemy = TARGET_ANY_RESOLVE,
        max_stacks = 1,
        max_resolve = 4,
        modifier_type = MODIFIER_TYPE.ARGUMENT,
        icon = "DEMOCRATICRACE:assets/modifiers/facts.png",
        max_persuasion = 3,
        min_persuasion = 2,
    },
    ENCOURAGEMENT =
    {
        name = "Encouragement",
        desc = "{MYRIAD_MODIFIER {2}}.\n\nWhen destroyed, {1} gains {3} resolve.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:GetOwnerName(), CalculateBonusScale(self), self.resolve_gain)
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/encouragement.png",

        modifier_type = MODIFIER_TYPE.BOUNTY,

        bonus_per_generation = 1,
        init_max_resolve = 3,
        resolve_scaling = MODIFIER_SCALING.LOW,

        resolve_gain = 8,

        OnInit = MyriadInit,

        OnBounty = function(self)
            self.negotiator:ModifyResolve( self.resolve_gain, self )
            CreateNewSelfMod(self)
        end,
    },
    PESSIMIST =
    {
        name = "Pessimist",
        desc = "{1} is feeling down.\n\nAt the beginning of {1}'s turn, if this argument has at least {2} resolve, you win the negotiation!\n\nArguments {1} control removes their composure at the end of their turn instead of at the beginning of their turn.",

        desc_fn = function(self, fmt_str )
            local minigame = self.engine
            return loc.format(fmt_str, self:GetOwnerName(), minigame and minigame.start_params.enemy_resolve_required or MiniGame.GetPersuasionRequired( TheGame:GetGameState():GetCurrentBaseDifficulty() ))
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/pessimist.png",
        modifier_type = MODIFIER_TYPE.CORE,

        OnBeginTurn = function( self, minigame )
            if self.resolve >= (minigame.start_params.enemy_resolve_required or MiniGame.GetPersuasionRequired( minigame:GetDifficulty() )) then
                if not self.engine:CheckGameOver() then
                    self.engine.restored_full_resolve = true
                    self.engine:Win()
                end
                return
            end
            -- local intents = {}
            -- for i, data in ipairs(self.negotiator:GetIntents()) do
            --     if data.min_persuasion and data.max_persuasion then
            --         table.insert(intents, data)
            --     end
            -- end

            -- if #intents > 0 then
            --     local selected_intent = table.arraypick(intents)
            --     self.negotiator:DismissIntent(selected_intent)
            --     minigame:ApplyPersuasion( self, self, selected_intent.min_persuasion or selected_intent.max_persuasion or 0, selected_intent.max_persuasion or 0 )
            -- end
        end,
        OnEndTurn = function( self, minigame )
            for i, modifier in self.negotiator:Modifiers() do
                if modifier.composure then
                    modifier:DeltaComposure(-modifier.composure, self)
                end
            end
        end,

        event_priorities =
        {
            [ EVENT.CALC_COMPOSURE_DECAY ] = EVENT_PRIORITY_SETTOR,
        },

        event_handlers =
        {
            [ EVENT.CALC_COMPOSURE_DECAY ] = function( self, decay, source )
                -- DBG(source)
                if source.negotiator == self.negotiator then
                    print("Same negotiator as self")
                    decay:ClearValue(self)
                end
            end,
        },
    },
    SELF_LOATHE =
    {
        name = "Self-Loathe",
        icon = "DEMOCRATICRACE:assets/modifiers/self_loathe.png",

        modifier_type = MODIFIER_TYPE.ARGUMENT,

        OnInit = function( self )
            self:SetResolve( 1, MODIFIER_SCALING.MED )
            local difficulty = self.engine and self.engine:GetDifficulty() or 1
            self.min_persuasion = 1 + math.ceil(difficulty/2)
            self.max_persuasion = 3 + difficulty
        end,

        target_self = TARGET_FLAG.CORE,

        OnBeginTurn = function( self, minigame )
            if not minigame:CheckGameOver() then
                self:ApplyPersuasion()
            end
        end,
    },
    FANATIC_LECTURE =
    {
        name = "Long Lecture",
        desc = "Survive {1} {1*turn|turns} to win the negotiation.",
        desc_fn = function( self, fmt_str )
            return loc.format(fmt_str, self.stacks or 1)
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/player_advantage.png",
        modifier_type = MODIFIER_TYPE.PERMANENT,
        event_handlers = {
            [ EVENT.BEGIN_PLAYER_TURN ] = function( self, minigame )
                if minigame.turns > 1 then
                    self.negotiator:RemoveModifier(self, 1, self)
                end
            end,
        },
        OnUnapply = function( self, minigame )
            minigame:Win()
            if self.stacks > 0 then
                minigame.ended_prematurely = true
            end
        end,
    },
    SHORT_TEMPERED =
    {
        name = "Short Tempered",
        desc = "Whenever one of {1}'s arguments takes damage from a card, increase the stacks of this by 1. " ..
            "If this reaches {2} stacks, deal {3} damage to the opponent's core argument and reset the stacks to 1.\n\n" ..
            "At the end of {1}'s turn, half the number of stacks on this, rounded up.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:GetOwnerName(), self.threshold, self.explode_damage)
        end,

        modifier_type = MODIFIER_TYPE.PERMANENT,
        icon = "negotiation/modifiers/heated.tex",

        threshold = 8,
        explode_damage = 12,

        OnEndTurn = function( self, minigame )
            self.negotiator:DeltaModifier(self, -math.floor(self.stacks / 2))
        end,
        event_handlers =
        {
            [ EVENT.ATTACK_RESOLVE ] = function( self, source, target, damage, params, defended )
                if target.negotiator == self.negotiator and is_instance( source, Negotiation.Card ) then
                    self.negotiator:AddModifier( self, 1 )
                    if self.stacks >= self.threshold then
                        self.anti_negotiator:AttackResolve( self.explode_damage, self )
                        self:SetStacks(1)
                        self.negotiator:DeltaModifier(self, -self.stacks + 1)
                    end
                end
            end,
        },
    },
    ELDRITCH_EXISTENCE =
    {
        name = "Eldritch Existence",
        desc = "At the end of the player turn, for each card remaining in their hand, target argument takes {1} damage. {status_fracturing_mind} added by {2} also has {REPLENISH}",
        icon = "DEMOCRATICRACE:assets/modifiers/eldritch_existence.png",

        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:GetDamageMultiplier(), self:GetOwnerName())
        end,

        modifier_type = MODIFIER_TYPE.CORE,

        GetDamageMultiplier = function(self)
            return DemocracyUtil.CalculateBossScale(self.multiplier_scale)
        end,

        multiplier_scale = {1, 1, 2, 2},

        target_enemy = TARGET_ANY_RESOLVE,
        min_persuasion = 0,
        max_persuasion = 0,

        no_damage_tt = true,

        UpdateAttack = function(self, minigame)
            local damage = minigame:GetHandDeck():CountCards() * self:GetDamageMultiplier()
            self.min_persuasion = damage
            self.max_persuasion = damage
            self:NotifyChanged()
        end,

        event_handlers = {
            [ EVENT.CARD_MOVED ] = function( self, card, source_deck, source_idx, target_deck, target_idx )
                self:UpdateAttack(self.engine)
            end,
            [ EVENT.END_PLAYER_TURN ] = function ( self, minigame )
                print("triggered")
                if self.anti_negotiator:IsPlayer() then
                    print("is player")
                    -- self.anti_negotiator:AttackResolve(minigame:GetHandDeck():CountCards() * self:GetDamageMultiplier(), self)
                    self:UpdateAttack(minigame)
                    self:ApplyPersuasion()
                end
            end,
        },
    },
    -- This is apparently the literal meaning for "Ctenophora". Makes perfect sense.
    COMB_BEARER =
    {
        name = "Comb Bearer",
        desc = "At the start of the player's turn, after drawing, a random card in their hand costs 1 extra action and gains {STICKY} until this argument is removed.",
        icon = "DEMOCRATICRACE:assets/modifiers/comb_bearer.png",

        modifier_type = MODIFIER_TYPE.ARGUMENT,

        OnInit = function( self )
            self:SetResolve( 6, MODIFIER_SCALING.HIGH )
        end,

        OnApply = function(self)
            self.card_costs = {}
            self.sticky_applied = {}
            local core = self.negotiator:FindCoreArgument()
            if core and core:GetResolve() ~= nil and not core:GetShieldStatus() then
                self.core_shield = true
                self.negotiator:FindCoreArgument():SetShieldStatus(true)
            end
        end,

        CanChoose = function(card)
            return card:IsPlayable() and not card:IsFlagged(CARD_FLAGS.VARIABLE_COST)
        end,

        OnUnapply = function( self )
            for i, card in ipairs(self.sticky_applied or {}) do
                card:ClearFlags(CARD_FLAGS.STICKY)
            end
            if self.core_shield and self.negotiator:FindCoreArgument() then
                self.negotiator:FindCoreArgument():SetShieldStatus(nil)
            end
        end,

        event_priorities =
        {
            [ EVENT.CALC_ACTION_COST ] = EVENT_PRIORITY_ADDITIVE,
        },

        event_handlers =
        {
            [ EVENT.HAND_DRAWN ] = function( self, minigame )
                local card = minigame:GetHandDeck():PeekRandom(self.CanChoose)
                if card then
                    table.insert(self.card_costs, card)
                    if not card:IsFlagged(CARD_FLAGS.STICKY) then
                        table.insert(self.sticky_applied, card)
                        card:SetFlags(CARD_FLAGS.STICKY)
                    end
                    card:NotifyTriggeredPre()
                    self:NotifyTriggered()
                    card:NotifyTriggeredPost()
                end
            end,

            [ EVENT.CALC_ACTION_COST ] = function( self, cost_acc, card, target )
                if table.contains(self.card_costs, card) then
                    local count = 0
                    for i, affected_card in ipairs(self.card_costs) do
                        if affected_card == card then
                            count = count + 1
                        end
                    end
                    cost_acc:AddValue( count, self )
                end
            end,
        },
    },
    -- This is apparently the literal meaning for "Cnidaria". Also makes perfect sense.
    STINGING_NETTLE =
    {
        name = "Stinging Nettle",
        desc = "When this argument gets attacked, this argument deals {1} damage to the core argument of the source's owner.\n\n"
            .. "{2}'s attacks deal {3} more damage to targets with composure.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.retaliate_damage, self:GetOwnerName(), self.sting_bonus)
        end,

        icon = "DEMOCRATICRACE:assets/modifiers/stinging_nettle.png",

        retaliate_damage = 1,
        sting_bonus = 2,

        modifier_type = MODIFIER_TYPE.ARGUMENT,

        OnInit = function( self )
            self:SetResolve( 6, MODIFIER_SCALING.HIGH )
        end,

        OnApply = function(self)
            local core = self.negotiator:FindCoreArgument()
            if core and core:GetResolve() ~= nil and not core:GetShieldStatus() then
                self.core_shield = true
                self.negotiator:FindCoreArgument():SetShieldStatus(true)
            end
        end,

        OnUnapply = function(self)
            if self.core_shield and self.negotiator:FindCoreArgument() then
                self.negotiator:FindCoreArgument():SetShieldStatus(nil)
            end
        end,

        event_priorities =
        {
            [ EVENT.CALC_PERSUASION ] = EVENT_PRIORITY_ADDITIVE,
        },

        event_handlers =
        {
            [ EVENT.ATTACK_RESOLVE ] = function( self, source, target, damage, params, defended )
                if target == self and source.negotiator then
                    source.negotiator:AttackResolve(self.retaliate_damage, self)
                end
            end,

            [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion, minigame, target )
                if self.can_buff and source.negotiator == self.negotiator and
                    target and target.composure and target.composure > 0 then
                    persuasion:AddPersuasion( self.sting_bonus, self.sting_bonus, self )
                end
            end,
            [ EVENT.BEGIN_PLAYER_TURN ] = function( self, minigame )
                self.can_buff = true
            end,
        },
    },
    FELLEMO_SLIPPERY =
    {
        name = "Slippery",
        desc = "For every {1*card|{1} cards} played, one of {2}'s attack intents changes its target.",
        alt_desc = " ({1} {1*card|cards} remaining)",
        desc_fn = function(self, fmt_str)
            if self.change_threshold == 1 then
                return loc.format(fmt_str, self.change_threshold, self:GetOwnerName())
            else
                if self.cards_played then
                    return loc.format(fmt_str, self.change_threshold, self:GetOwnerName()) .. loc.format((self.def or self):GetLocalizedString("ALT_DESC"), self.change_threshold - self.cards_played)
                else
                    return loc.format(fmt_str, self.change_threshold, self:GetOwnerName())
                end
            end
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/slippery.png",

        change_threshold = 3,
        change_threshold_scale = {5, 4, 3, 2},
        -- cards_played = 0,

        modifier_type = MODIFIER_TYPE.CORE,

        OnInit = function( self )
            if self.engine and CheckBits(self.engine:GetFlags(), NEGOTIATION_FLAGS.WORDSMITH) then
                self.change_threshold = DemocracyUtil.CalculateBossScale(self.change_threshold_scale)
            end
            self.cards_played = 0
        end,

        event_handlers =
        {
            [ EVENT.POST_RESOLVE ] = function(self, minigame, card)
                if card.negotiator == self.anti_negotiator then
                    self.cards_played = (self.cards_played or 0) + 1
                    if self.cards_played >= self.change_threshold then
                        self.cards_played = 0
                        local candidates = {}
                        for i, card in ipairs(self.negotiator.prepared_cards) do
                            if card.min_persuasion and card.max_persuasion then
                                table.insert(candidates, card)
                            end
                        end
                        if #candidates > 0 then
                            local chosen = table.arraypick(candidates)
                            chosen.target = nil
                        end
                        self:NotifyTriggered()
                    end
                end
            end,
        },
    },
    WAIVERS =
    {
        name = "Waivers",
        desc = "When {1} creates an argument, remove it and one <b>Waivers</>.\n\nWhen destroyed, {INCEPT} a number of {VULNERABILITY} equal to the number of remaining stacks on this argument.\n\nReduce <b>Waivers</b> by 1 at the beginning of {2}'s turn.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:GetOpponentName(), self:GetOwnerName())
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/waivers.png",

        max_resolve = 4,
        modifier_type = MODIFIER_TYPE.ARGUMENT,

        OnBounty = function(self)
            if self.stacks > 0 then
                -- local cards = {}
                -- for i = 1, self.stacks do
                --     local card = Negotiation.Card( "bad_deal", self.engine:GetPlayer() )
                --     table.insert( cards, card )
                -- end
                -- self.engine:InceptCards( cards, self )
                self.anti_negotiator:InceptModifier("VULNERABILITY", self.stacks, self)
            end
        end,

        OnInit = function(self)
            self:SetResolve(self.max_resolve, MODIFIER_SCALING.LOW)
        end,

        event_handlers =
        {
            [ EVENT.BEGIN_TURN ] = function( self, minigame, negotiator )
                if negotiator == self.negotiator then
                    negotiator:RemoveModifier( self, 1, self )
                end
            end,
            [ EVENT.MODIFIER_ADDED ] = function( self, modifier, source )
                if source and source.negotiator == self.anti_negotiator and modifier.modifier_type == MODIFIER_TYPE.ARGUMENT then
                    modifier.negotiator:RemoveModifier(modifier, modifier.stacks, self)
                    self.negotiator:RemoveModifier( self, 1, self )
                end
            end,
        },
    },
    EXPLOITATION =
    {
        name = "Exploitation",
        desc = "If this argument causes resolve loss and this argument is not destroyed yet, {INCEPT} {1} {VULNERABILITY}.\n\nWhen destroyed, remove half of {2}'s {VULNERABILITY} and deal double that damage to a random argument controlled by {2}.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.vulnerability_count, self:GetOpponentName())
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/exploitation.png",

        modifier_type = MODIFIER_TYPE.ARGUMENT,

        min_persuasion = 1,
        max_persuasion = 3,

        max_persuasion_scale = {2, 3, 4, 5},

        max_resolve = 3,
        max_stacks = 1,

        vulnerability_count = 2,
        vulnerability_scale = {1, 2, 2, 3},

        target_enemy = TARGET_ANY_RESOLVE,

        OnBeginTurn = function( self, minigame )
            self:ApplyPersuasion()
        end,

        OnInit = function( self )
            if self.engine and CheckBits(self.engine:GetFlags(), NEGOTIATION_FLAGS.WORDSMITH) then
                self.max_persuasion = DemocracyUtil.CalculateBossScale(self.max_persuasion_scale)
                self.vulnerability_count = DemocracyUtil.CalculateBossScale(self.vulnerability_scale)
            end
            self:SetResolve(self.max_resolve, MODIFIER_SCALING.LOW)
        end,

        OnBounty = function(self)
            local count = self.anti_negotiator:GetModifierStacks("VULNERABILITY")
            local delta_count = math.ceil(count / 2)
            if delta_count > 0 then
                self.anti_negotiator:DeltaModifier("VULNERABILITY", -delta_count, self)
                self.target = nil
                self.engine:ApplyPersuasion(self, nil, 2 * delta_count, 2 * delta_count)
            end
        end,

        event_handlers =
        {
            [ EVENT.ATTACK_RESOLVE ] = function( self, source, target, damage, params, defended )
                if source == self and damage > defended then
                    self:NotifyTriggered()
                    target.negotiator:AddModifier("VULNERABILITY", self.vulnerability_count, self)
                end
            end,
        },
    },
    DEVOTED_MIND =
    {
        name = "Devoted Mind",
        desc = "Take {1} less damage from {4}'s cards and arguments (excluding splash damage). Increase this amount by {2} for each argument {3} has with {DEVOTION}.",
        desc_fn = function(self, fmt_str)
            local count = self:CalculateDamageReduction()
            return loc.format(fmt_str, count == self.base_reduction and count or loc.format("<#BONUS>{1}</>", count), self.additional_reduction, self:GetOwnerName(), self:GetOpponentName())
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/devoted_mind.png",

        modifier_type = MODIFIER_TYPE.CORE,
        base_reduction = 2,
        base_reduction_scale = { 1, 2, 2, 3 },
        additional_reduction = 1,
        additional_reduction_scale = { 1, 1, 2, 2 },

        OnInit = function(self)
            self.base_reduction = DemocracyUtil.CalculateBossScale(self.base_reduction_scale)
            self.additional_reduction = DemocracyUtil.CalculateBossScale(self.additional_reduction_scale)
        end,

        CalculateDamageReduction = function(self)
            local faith_count = 0
            if self.negotiator then
                for i, data in self.negotiator:Modifiers() do
                    if data.faith_in_hesh then
                        faith_count = faith_count + 1
                    end
                end
            end
            return self.base_reduction + faith_count * self.additional_reduction
        end,

        event_handlers =
        {
            [ EVENT.ATTACK_RESOLVE ] = function( self, source, target, damage, params, defended )
                if target == self and source.negotiator == self.anti_negotiator then
                    target.composure = target.composure + math.min(damage, self:CalculateDamageReduction())
                end
            end,
        },
    },
    INDIFFERENCE_OF_HESH =
    {
        name = "Indifference of Hesh",
        desc = "{DEVOTION}\n\nAt the beginning of {1}'s turn, each other argument {1} has restores {2} resolve.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:GetOwnerName(), self.resolve_count)
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/indifference_of_hesh.png",
        faith_in_hesh = true,

        max_resolve = 20,
        modifier_type = MODIFIER_TYPE.ARGUMENT,

        resolve_count = 4,
        resolve_scale = { 3, 4, 5, 6 },

        OnInit = function(self)
            self.resolve_count = DemocracyUtil.CalculateBossScale(self.resolve_scale)
        end,

        CanPlayCard = function( self, source, engine, target )
            local feature = Content.GetNegotiationCardFeature( "DEVOTION" )
            return feature:CanPlayCardFaith(self, source, target)
        end,

        OnBounty = function(self)
            local feature = Content.GetNegotiationCardFeature( "DEVOTION" )
            feature:DoFaithBounty(self)
        end,

        OnBeginTurn = function(self)
            for i, mod in self.negotiator:Modifiers() do
                if mod ~= self and mod:GetResolve() ~= nil then
                    mod:RestoreResolve(self.resolve_count, self)
                end
            end
        end,
    },
    INCOMPREHENSIBILITY_OF_HESH =
    {
        name = "Incomprehensibility of Hesh",
        desc = "{DEVOTION}\n\nWhen another one of {1}'s arguments is destroyed by {2}, add {3} {status_fracturing_mind} to the draw pile.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:GetOwnerName(), self:GetOpponentName(), self.status_count)
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/incomprehensibility_of_hesh.png",
        faith_in_hesh = true,

        max_resolve = 20,
        modifier_type = MODIFIER_TYPE.ARGUMENT,

        status_count = 1,
        status_count_scale = { 1, 1, 1, 2 },

        OnInit = function(self)
            self.status_count = DemocracyUtil.CalculateBossScale(self.status_count_scale)
        end,

        CanPlayCard = function( self, source, engine, target )
            local feature = Content.GetNegotiationCardFeature( "DEVOTION" )
            return feature:CanPlayCardFaith(self, source, target)
        end,

        OnBounty = function(self)
            local feature = Content.GetNegotiationCardFeature( "DEVOTION" )
            feature:DoFaithBounty(self)
        end,

        event_handlers =
        {
            [ EVENT.MODIFIER_REMOVED ] = function( self, modifier, card )
                if modifier.negotiator == self.negotiator and card and card.negotiator == self.anti_negotiator then
                    local cards = {}
                    for i = 1, self.status_count do
                        local card = Negotiation.Card( "status_fracturing_mind", self.engine:GetPlayer() )
                        table.insert( cards, card )
                    end
                    self.engine:InceptCards( cards, self )
                end
            end,
        },
    },
    INSATIABILITY_OF_HESH =
    {
        name = "Insatiability of Hesh",
        desc = "{DEVOTION}\n\nAttacks an opponent argument at the beginning of {3}'s turn for {1}-{2} damage. Increase this argument's max damage by 1 when any argument is destroyed.",
        desc_fn = function(self, fmt_str)
            local min_persuasion, max_persuasion, details = self.min_persuasion, self.max_persuasion
            if self.engine then
                min_persuasion, max_persuasion, details = self.engine:PreviewPersuasion( self, true )
            end
            return loc.format(fmt_str, min_persuasion, max_persuasion, self:GetOwnerName())
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/insatiability_of_hesh.png",
        faith_in_hesh = true,
        no_damage_tt = true,

        max_resolve = 20,
        modifier_type = MODIFIER_TYPE.ARGUMENT,

        min_persuasion = 2,
        max_persuasion = 3,
        target_enemy = TARGET_ANY_RESOLVE,

        CanPlayCard = function( self, source, engine, target )
            local feature = Content.GetNegotiationCardFeature( "DEVOTION" )
            return feature:CanPlayCardFaith(self, source, target)
        end,

        OnBounty = function(self)
            local feature = Content.GetNegotiationCardFeature( "DEVOTION" )
            feature:DoFaithBounty(self)
        end,

        OnBeginTurn = function( self, minigame )
            self:ApplyPersuasion()
        end,

        event_handlers =
        {
            [ EVENT.MODIFIER_REMOVED ] = function( self, modifier, card )
                if modifier.resolve and modifier.stacks > 0 then
                    self.max_persuasion = self.max_persuasion + 1
                    self:NotifyTriggered()
                end
            end,
        },
    },
    DESPERATION_FOR_FAITH =
    {
        name = "Desperation For Faith",
        desc = "{DEVOTION}\n\nAt the beginning of {1}'s turn, apply {2} {COMPOSURE} to {1}'s core argument.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:GetOwnerName(), self.composure_gain)
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/desperation_for_faith.png",
        faith_in_hesh = true,

        max_resolve = 10,
        modifier_type = MODIFIER_TYPE.ARGUMENT,

        composure_gain = 3,

        CanPlayCard = function( self, source, engine, target )
            local feature = Content.GetNegotiationCardFeature( "DEVOTION" )
            return feature:CanPlayCardFaith(self, source, target)
        end,

        OnBounty = function(self)
            local feature = Content.GetNegotiationCardFeature( "DEVOTION" )
            feature:DoFaithBounty(self)
        end,

        OnBeginTurn = function( self, minigame )
            self.negotiator:FindCoreArgument():DeltaComposure( self.composure_gain, self )
        end,
    },
    VOICE_OF_THE_PEOPLE_KALANDRA =
    {
        name = "Voice of the People",
        desc = "This argument's resolve damage doubles for each stack.",
        icon = "negotiation/modifiers/voice_of_the_people.tex",
        target_enemy = TARGET_ANY_RESOLVE,
        modifier_type = MODIFIER_TYPE.ARGUMENT,

        OnSetStacks = function( self, old_stacks )
            self.min_persuasion = math.floor(math.pow(2, self.stacks))
            self.max_persuasion = self.min_persuasion
        end,

        max_resolve = 4,

        OnInit = function(self)
            self:SetResolve(self.max_resolve, MODIFIER_SCALING.MED)
        end,

        min_persuasion = 2,
        max_persuasion = 2,

        target_enemy = TARGET_ANY_RESOLVE,
        modifier_type = MODIFIER_TYPE.ARGUMENT,

        OnBeginTurn = function(self)
            self:ApplyPersuasion()
        end,
    },
    UNREST_KALANDRA =
    {
        name = "Unrest",
        desc = "The real revolution begins when <b>Unrest</> reaches {1} {1*stack|stacks}.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.revolution_threshold)
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/unrest_kalandra.png",

        revolution_threshold = 2,

        modifier_type = MODIFIER_TYPE.PERMANENT,
    },
    SPARK_OF_REVOLUTION =
    {
        name = "Spark of Revolution",
        desc = "When {1}'s {VOICE_OF_THE_PEOPLE_KALANDRA} argument is destroyed, gain an <b>Unrest</>. The real revolution begins when <b>Unrest</> reaches {2} {2*stack|stacks}.",
        loc_strings =
        {
            name_2 = "Flames of Revolution",
            desc_2 = "When any argument is destroyed, deal {1} damage to every argument. This amount cannot be modified.",
        },
        desc_fn = function(self, fmt_str)
            if not (self.engine and self.engine.revolution_activated) then
                return loc.format(fmt_str, self:GetOwnerName(), self.revolution_threshold)
            else
                return loc.format((self.def or self):GetLocalizedString("DESC_2"), self.damage_amt)
            end
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/spark_of_revolution.png",

        revolution_threshold = 2,
        damage_amt = 1,
        damage_scale = {1, 1, 1, 2},
        modifier_type = MODIFIER_TYPE.CORE,

        target_mod = TARGET_MOD.ALL,

        OnInit = function(self)
            self.damage_amt = DemocracyUtil.CalculateBossScale(self.damage_scale)
        end,

        ActivateRevolution = function(self)
            if self.engine then
                self.engine.revolution_activated = true
            end
            self.custom_name = (self.def or self):GetLocalizedString("NAME_2")
            self.min_persuasion = self.damage_amt
            self.max_persuasion = self.damage_amt
            self.icon = engine.asset.Texture("DEMOCRATICRACE:assets/modifiers/flames_of_revolution.png")
            self.engine:BroadcastEvent( EVENT.UPDATE_MODIFIER_ICON, self)
            self:NotifyChanged()
        end,

        DoAOESequence = function(self)
            if not self.performing_aoe then
                self.performing_aoe = true

                self.target_self = TARGET_ANY_RESOLVE
                self.target_enemy = TARGET_ANY_RESOLVE
                while self.aoe_count > 0 and self:IsApplied() do
                    self.aoe_count = self.aoe_count - 1
                    self:ApplyPersuasion()
                end
                self.target_self = nil
                self.target_enemy = nil

                self.performing_aoe = false
            end
        end,

        event_priorities =
        {
            [ EVENT.CALC_PERSUASION ] = EVENT_PRIORITY_CLAMP,
        },

        event_handlers =
        {
            [ EVENT.MODIFIER_REMOVED ] = function( self, modifier )
                if not (self.engine and self.engine.revolution_activated) then
                    if modifier.id == "VOICE_OF_THE_PEOPLE_KALANDRA" and modifier.stacks > 0 then
                        self.negotiator:AddModifier("UNREST_KALANDRA", 1, self)
                        local count = self.negotiator:GetModifierStacks("UNREST_KALANDRA")
                        if count and count >= self.revolution_threshold then
                            self.negotiator:RemoveModifier("UNREST_KALANDRA", count, self)
                            self:ActivateRevolution()
                        end
                    end
                else
                    if modifier.stacks > 0 then
                        self.aoe_count = (self.aoe_count or 0) + 1
                        self:DoAOESequence()
                    end
                end
            end,
            [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion, minigame, target )
                if source == self then
                    persuasion:ModifyPersuasion(self.damage_amt, self.damage_amt, self)
                end
            end,
        },
    },
    BURNING_FURY =
    {
        name = "Burning Fury",
        desc = "At the start of {1}'s turn, after card draw, {2*a random card|{2} random cards} in {1}'s hand gains {FERVOR}.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:GetOpponentName(), self.burn_count)
        end,
        icon = "DEMOCRATICRACE:assets/modifiers/burning_fury.png",

        modifier_type = MODIFIER_TYPE.ARGUMENT,
        max_resolve = 8,

        burn_count = 1,
        burn_scale = { 1, 1, 2, 2 },
        max_resolve_scale = { 6, 8, 10, 12 },

        max_stacks = 1,

        OnInit = function(self)
            self.burn_count = DemocracyUtil.CalculateBossScale(self.burn_scale)
            self:SetResolve(DemocracyUtil.CalculateBossScale(self.max_resolve_scale))
        end,

        event_handlers =
        {
            [ EVENT.HAND_DRAWN ] = function( self, minigame )
                local options = shallowcopy(minigame:GetHandDeck().cards)
                local i = 0
                local fervor_feature = Content.GetNegotiationCardFeature( "FERVOR" )
                while i < self.burn_count * self.stacks and #options > 0 do
                    local chosen = table.arraypick(options)
                    if chosen then
                        table.arrayremove(options, chosen)
                        if not (chosen.features and (chosen.features.FERVOR or 0) > 0) then
                            fervor_feature:ApplyFervor(chosen, minigame)
                            i = i + 1
                        end
                    end
                end
            end,
        },
    },
    FERVOR_TRACKER =
    {
        hidden = true,

        event_priorities =
        {
            [ EVENT.POST_RESOLVE ] = EVENT_PRIORITY_CLAMP,
        },

        event_handlers =
        {
            [ EVENT.POST_RESOLVE ] = function( self, minigame, card )
                if card.features and (card.features.FERVOR or 0) > 0 then
                    -- Play it again.
                    self.negotiator:RemoveModifier( self, 1 )
                    card:SetFlags( CARD_FLAGS.EXPEND )
                    minigame:PlayCard( card )
                end
            end,
            [ EVENT.END_PLAYER_TURN ] = function( self, minigame )
                for i, card in minigame:GetHandDeck():Cards() do
                    if card.features and (card.features.FERVOR or 0) > 0 then
                        card:NotifyTriggeredPre()
                        minigame:ApplyPersuasion( card, card.negotiator, 3, 3 )
                        card:NotifyTriggeredPost()
                        card.features.FERVOR = nil
                        self.engine:BroadcastEvent( EVENT.CUSTOM, function( panel )
                            card.remove_fervor_display = true
                        end )
                    end
                end
            end,
        },
    },
    OPULENCE =
    {
        name = "Opulence",
        desc = "When <b>Opulence</> or another non-core, non-bounty argument {1} has is destroyed, {2} gains {3#money}.\n\nWhen {2} plays a card, {2} loses {4#money}.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self:GetOwnerName(), self:GetOpponentName(), self.money_bonus, self.money_cost)
        end,
        icon = "negotiation/modifiers/coin_juggler.tex",

        money_bonus = 30,
        money_cost = 5,

        modifier_type = MODIFIER_TYPE.ARGUMENT,
        max_resolve = 4,

        OnInit = function(self)
            self:SetResolve(self.max_resolve, MODIFIER_SCALING.MED)
        end,

        RewardMoney = function(self)
            self.engine:ModifyMoney( self.money_bonus, self )
        end,

        OnBounty = function(self)
            self:RewardMoney()
        end,

        event_handlers =
        {
            [ EVENT.MODIFIER_REMOVED ] = function( self, modifier, card )
                if modifier ~= self and modifier.negotiator == self.negotiator and modifier.modifier_type == MODIFIER_TYPE.ARGUMENT and modifier.stacks > 0 then
                    self:RewardMoney()
                end
            end,
            [ EVENT.POST_RESOLVE ] = function( self, minigame, card )
                if card.negotiator == self.anti_negotiator then
                    self.engine:ModifyMoney( -self.money_cost, self )
                end
            end,
        },
    },
    OOLO_WORDSMITH_CORE =
    {
        name = "Power Player",
        desc = "{1}'s attacks gain +1 damage for each bounty and inception on the opponent.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self:GetOwnerName() )
        end,
        modifier_type = MODIFIER_TYPE.CORE,
        icon = "negotiation/modifiers/deadline.tex",
        CalculateInceptCount = function(self)
            local count = 0
            for i, modifier in self.anti_negotiator:Modifiers() do
                if modifier.modifier_type == MODIFIER_TYPE.INCEPTION or modifier.modifier_type == MODIFIER_TYPE.BOUNTY then
                    count = count + 1
                end
            end
            return count
        end,
        OnBeginTurn = function(self, minigame)
            self.locked_count = self:CalculateInceptCount()
        end,
        OnEndTurn = function(self, minigame)
            self.locked_count = nil
        end,
        event_handlers =
        {
            [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion )
                if source and source.negotiator == self.negotiator then
                    local count = self.locked_count or self:CalculateInceptCount()
                    persuasion:AddPersuasion(count , count , self)
                end
            end
        },
    },

    OOLO_BADGE_FLASH =
    {
        name = "Badge Flash",
        desc = "At the end of {1}'s turn, {INCEPT} {2} {FLUSTERED} and reduce <b>Badge Flash</> by 1.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self:GetOwnerName(), self.flustered_amt )
        end,
        modifier_type = MODIFIER_TYPE.ARGUMENT,
        max_resolve = 2,
        icon = "negotiation/modifiers/fearless.tex",
        flustered_amt = 2,
        OnInit = function(self)
            self:SetResolve(self.max_resolve, MODIFIER_SCALING.MED)
        end,
        OnBeginTurn = function(self, minigame)
            self.can_trigger = true
        end,
        OnEndTurn = function(self, minigame)
            if self.can_trigger then
                self.anti_negotiator:InceptModifier("FLUSTERED", self.flustered_amt, self)
                self.negotiator:RemoveModifier( self, 1, self )
            end
        end,
    },

    OOLO_UNITED_FRONT =
    {
        name = "United Front",
        desc = "At the start of {1}'s turn, increase all of {2}'s inceptions and bounties by 1 stack.",
        desc_fn = function( self, fmt_str )
            return loc.format( fmt_str, self:GetOwnerName(), self:GetOpponentName() )
        end,
        modifier_type = MODIFIER_TYPE.ARGUMENT,
        max_resolve = 2,
        icon = "negotiation/modifiers/wide_influence.tex",

        OnInit = function(self)
            self:SetResolve(self.max_resolve, MODIFIER_SCALING.HIGH)
        end,

        OnBeginTurn = function(self, minigame)
            local player_mods = {}
            for i,modifier in self.anti_negotiator:Modifiers() do
                if modifier.modifier_type == MODIFIER_TYPE.INCEPTION or modifier.modifier_type == MODIFIER_TYPE.BOUNTY then
                    table.insert(player_mods, modifier)
                end
            end
            for i, modifier in ipairs(player_mods) do
                self.anti_negotiator:AddModifier(modifier, 1, self)
            end
        end,
    },
    DEM_STARTLING_DISTRACTION =
    {
        name = "Startling Distraction",
        desc = "{MYRIAD_MODIFIER {2}}.\n\nWhen destroyed, {1} gains {3} {DISTRACTED}.",
        icon = "negotiation/modifiers/dread.tex",

        modifier_type = MODIFIER_TYPE.BOUNTY,
        init_max_resolve = 10,

        bonus_per_generation = 2,

        generation = 0,

        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self:GetOwnerName(), CalculateBonusScale(self), self.stacks or 1)
        end,
        OnInit = function(self)
            if (self.generation or 0) == 0 and self.engine:GetDifficulty() > 1 then
                self.init_max_resolve = self.init_max_resolve + 5 * (self.engine:GetDifficulty() - 1)
            end
            MyriadInit(self)
        end,
        OnBounty = function(self)
            self.negotiator:DeltaModifier("DISTRACTED", self.stacks or 1)
            CreateNewSelfMod(self)
        end,
    },
}
for id, def in pairs( MODIFIERS ) do
    Content.AddNegotiationModifier( id, def )
end
Content.GetNegotiationModifier("FREE_ACTION").min_stacks = -99
local FEATURES = {
    MYRIAD_MODIFIER =
    {
        name = "Myriad",
        desc = "When this bounty is destroyed, create a bounty that is a copy of this bounty with full resolve, except it has an extra starting resolve equal to the number indicated by {MYRIAD_MODIFIER}.",
        loc_strings = {
            NO_GAIN = "When this bounty is destroyed, create a bounty that is a copy of this bounty with full resolve.",
            STACKS = "When this bounty is destroyed, create a bounty that is a copy of this bounty with full resolve, except it has {1} extra starting resolve.",
        },
        desc_fn = function(self, fmt_str, stacks)
            if stacks then
                if stacks ~= 0 then
                    return loc.format(self:GetLocalizedString("STACKS"), stacks)
                else
                    return self:GetLocalizedString("NO_GAIN")
                end
            end
            return fmt_str
        end,
    },
    DEVOTION =
    {
        name = "Devotion",
        desc = "Cannot be targeted by {DOUBT}.\n\nWhen destroyed, gain {1} {DOUBT}. Increase this amount by {2} for each arguments with <b>Devotion</> destroyed.",
        desc_fn = function(self, fmt_str, stacks, engine)
            local delta_count = self:GetDeltaCount(engine)
            if delta_count ~= self.base_count then
                return loc.format(fmt_str, "<#BONUS>" .. delta_count .. "</>", self.delta_count)
            else
                return loc.format(fmt_str, delta_count, self.delta_count)
            end
        end,
        base_count = 3,
        delta_count = 3,

        GetDeltaCount = function(self, engine)
            local destroy_count = engine and engine.faith_in_hesh_destroyed or 0
            return self.base_count + destroy_count * self.delta_count
        end,

        DoFaithBounty = function(self, modifier)
            modifier.negotiator:AddModifier("DOUBT", self:GetDeltaCount(modifier.engine), modifier)
            if modifier.engine then
                modifier.engine.faith_in_hesh_destroyed = (modifier.engine.faith_in_hesh_destroyed or 0) + 1
            end
        end,

        CanPlayCardFaith = function( self, modifier, source, target )
            if source and source.id == "DOUBT" and target == modifier then
                return false
            end

            return true
        end,
    },
    FERVOR =
    {
        name = "Fervor",
        desc = "When this card is played, play it again, then {EXPEND} it.\n\nIf this card is in your hand at the end of your turn, remove <b>Fervor</> and take 3 resolve damage.",
        feature_desc = "{FERVOR}",

        ApplyFervor = function(self, card, minigame)
            if minigame:GetPlayerNegotiator() and minigame:GetPlayerNegotiator():GetModifierInstances( "FERVOR_TRACKER" ) == 0 then
                minigame:GetPlayerNegotiator():CreateModifier("FERVOR_TRACKER")
            end
            card.features = card.features or {}
            card.features.FERVOR = 1
        end,
    },
}
for id, data in pairs(FEATURES) do
    local def = NegotiationFeatureDef(id, data)
    Content.AddNegotiationCardFeature(id, def)
end
