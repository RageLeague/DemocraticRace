local negotiation_defs = require "negotiation/negotiation_defs"
local EVENT = negotiation_defs.EVENT

local function CreateNewSelfMod(self)
    local newmod = self.negotiator:CreateModifier(self.id, 1, self)
    if newmod then
        newmod.generation = (self.generation or 0) + 1
        if newmod.OnInit then
            newmod:OnInit()
        end
    end
end

local MODIFIERS =
{
    IMPATIENCE_WIN =
    {
        name = "Player Advantage",
        desc = "Win at the beginning of the player's turn if the opponent has {1} or more {IMPATIENCE}.",
        desc_fn = function( self, fmt_str )
            return loc.format(fmt_str, self.impatience_count)
        end,
        modifier_type = MODIFIER_TYPE.PERMANENT,
        impatience_count = 1,
        event_handlers = {
            [ EVENT.BEGIN_PLAYER_TURN ] = function( self, minigame )
                if self.anti_negotiator:GetModifierStacks("IMPATIENCE") >= self.impatience_count then
                    minigame:Win()
                end
                
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
        icon = engine.asset.Texture("negotiation/modifiers/heckler.tex"),
        modifier_type = MODIFIER_TYPE.CORE,
        agents = {},
        CreateTarget = function(self, agent)
            local modifier = self.negotiator:CreateModifier("PREACH_TARGET_INTEREST")
            modifier:SetAgent(agent)
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
                    self:TryCreateNewTarget()
                end
                if #self.agents == 0 and self.negotiator:GetModifierInstances( "PREACH_TARGET_INTEREST" ) == 0 then
                    minigame:Win()
                end
            end,
        },
        InitModifiers = function(self)
            for i = 1, 2 + math.floor(self.engine:GetDifficulty() / 2) do
                self:TryCreateNewTarget()
            end
        end,
    },
    PREACH_TARGET_INTEREST = 
    {
        name = "Potential Interest",
        desc = "<b>{1.fullname}</> might be interested in listening to you if you can convince {1.himher}. "..
            "Destroy this argument to make {1.himher} join your side.\n\n"..
            "<#PENALTY>After {2} turns, this argument removes itself, as <b>{1.name}</> loses interest in you.</>",
        loc_strings = {
            BONUS_LOVED = "<#BONUS><b>{1.name} loves you.</> {3} max resolve.</>",
            BONUS_LIKED = "<#BONUS><b>{1.name} likes you.</> {3} max resolve.</>",
            BONUS_DISLIKED = "<#PENALTY><b>{1.name} dislikes you.</> +{3} max resolve.</>",
            BONUS_HATED = "<#PENALTY><b>{1.name} hates you.</> +{3} max resolve.</>",
            BONUS_BRIBED = "<#BONUS><b>{1.name} is bribed.</> {2} max resolve.</>",
        },
        delta_max_resolve = {
            [RELATIONSHIP.LOVED] = -12,
            [RELATIONSHIP.LIKED] = -6,
            [RELATIONSHIP.DISLIKED] = 6,
            [RELATIONSHIP.HATED] = 12,
        },
        bribe_delta = -6,
        key_maps = {
            [RELATIONSHIP.LOVED] = "BONUS_LOVED",
            [RELATIONSHIP.LIKED] = "BONUS_LIKED",
            [RELATIONSHIP.DISLIKED] = "BONUS_DISLIKED",
            [RELATIONSHIP.HATED] = "BONUS_HATED",
        },
        desc_fn = function( self, fmt_str, minigame, widget )
            if self.target_agent and widget and widget.PostPortrait then
                --local txt = loc.format( "{1#agent} is not ready to fight!", self.ally_agent )
                widget:PostPortrait( self.target_agent )
            end
            local resultstring = ""
            if self.target_agent then
                if self.key_maps[self.target_agent:GetRelationship()] then
                    resultstring = self.def:GetLocalizedString(self.key_maps[self.target_agent:GetRelationship()])
                end
                if self.target_agent:HasAspect("bribed") then
                    resultstring = resultstring .. "\n" .. loc.format(self.def:GetLocalizedString("BONUS_BRIBED"), self.target_agent, self.bribe_delta)
                end
            end
            resultstring = resultstring .. "\n\n" .. fmt_str
            print(resultstring)
            return loc.format(resultstring, self.target_agent and self.target_agent:LocTable(), 
                self.turns_left, self.delta_max_resolve[self.target_agent:GetRelationship()])
            -- else 
            --     return loc.format(fmt_str, self.target_agent and self.target_agent:LocTable(), self.turns_left)
            -- end
            
        end,
        icon = engine.asset.Texture("negotiation/modifiers/voice_of_the_people.tex"),
        target_agent = nil,
        modifier_type = MODIFIER_TYPE.ARGUMENT,
        turns_left = 3,
        is_first_turn = true,
    
        SetAgent = function (self, agent)
            self.target_agent = agent
            self.max_resolve = self.engine:GetDifficulty() * 7 + 8
            if agent:HasAspect("bribed") then
                self.max_resolve = self.max_resolve + self.bribe_delta
            end
            self.max_resolve = math.max(1, self.max_resolve + (self.delta_max_resolve[agent:GetRelationship()] or 0))
          --  self.min_persuasion = 2 + agent:GetRenown()
            --self.max_persuasion = self.min_persuasion + 4
            self:SetResolve(self.max_resolve)
    
            -- if ALLY_IMAGES[agent:GetContentID()] then
            --     self.icon = ALLY_IMAGES[agent:GetContentID()]
            --     self.engine:BroadcastEvent( EVENT.UPDATE_MODIFIER_ICON, self)
            --     self:NotifyTriggered()
            -- end
            self:NotifyChanged()
        end,
        OnBounty = function(self, source)
            if source and source ~= self then
                local modifier = self.anti_negotiator:CreateModifier("PREACH_TARGET_INTERESTED")
                if modifier and modifier.SetAgent then
                    modifier:SetAgent(self.target_agent)
                end
            end
        end,
        event_handlers = {
            [ EVENT.BEGIN_PLAYER_TURN ] = function( self, minigame )
                if not self.is_first_turn then
                    self.turns_left = self.turns_left - 1
                    if self.turns_left <= 0 then
                        self.negotiator:RemoveModifier(self)
                    end
                    self:NotifyChanged()
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
        target_agent = nil,
        modifier_type = MODIFIER_TYPE.BOUNTY,
        SetAgent = function (self, agent)
            self.target_agent = agent
            self.max_resolve = 3
          --  self.min_persuasion = 2 + agent:GetRenown()
            --self.max_persuasion = self.min_persuasion + 4
            self:SetResolve(self.max_resolve)
    
            -- if ALLY_IMAGES[agent:GetContentID()] then
            --     self.icon = ALLY_IMAGES[agent:GetContentID()]
            --     self.engine:BroadcastEvent( EVENT.UPDATE_MODIFIER_ICON, self)
            --     self:NotifyTriggered()
            -- end
            self:NotifyChanged()
        end,
    
    },
    CONNECTED_LINE =
    {
        name = "Connected Line",
        -- Me wall of text
        desc = "Reach {1} stacks for the help to be sent. <#PENALTY>The opponent will also "..
            "gain 1 {IMPATIENCE} when that happens.</>\n\n"..
            "The opponent must target this argument before anything else.\n\n"..
            "<#PENALTY>If this gets destroyed, the opponent gains 1 {IMPATIENCE}, and you need to play "..
            "Call For Help again!</>",
        
        desc_fn = function(self, fmt_str, minigame, widget)
            -- if self.ally_agent and widget and widget.PostPortrait then
            --     --local txt = loc.format( "{1#agent} is not ready to fight!", self.ally_agent )
            --     widget:PostPortrait( self.ally_agent )
            -- end
            return loc.format( fmt_str, self.calls_required )
            -- return loc.format( fmt_str, self.ally_agent and self.ally_agent:LocTable(), self.negotiator and self.negotiator.agent:LocTable() )
        end,

        calls_required = 5,
        modifier_type = MODIFIER_TYPE.ARGUMENT,
        max_resolve = 3,
        max_stacks = 10,

        force_target = true,

        -- OnInit = function(self)
            
        -- end,

        CanPlayCard = function( self, source, engine, target )
            if source:IsAttack() and target:GetNegotiator() == self.negotiator then
                if source.modifier_type == MODIFIER_TYPE.INCEPTION or source:GetNegotiator() ~= self.negotiator then
                    if not target.force_target then
                        return false, loc.format( "Must target <b>{1}</b>", self:GetName() )
                    end
                end
            end

            return true
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
        OnBounty = function(self, source)
            if source ~= self then  
                self.anti_negotiator:AddModifier("IMPATIENCE", 1)

                local card = Negotiation.Card( "assassin_fight_call_for_help", self.engine:GetPlayer() )
                if self.stacks > 1 then
                    card.init_help_count = self.stacks
                end
                self.engine:DealCard(card, self.engine:GetDiscardDeck())
            end

            self:CleanUpCard("assassin_fight_describe_information")
        end,
        event_handlers =
        {
            [ EVENT.MODIFIER_ADDED ] = function ( self, modifier, source )
                if modifier == self and self.engine then
                    if self.negotiator:GetModifierInstances(self.id) > 1 then
                        self.negotiator:RemoveModifier(self)
                        return
                    end
                    local has_card = false
                    for k,v in pairs(self.engine:GetHandDeck().cards) do
                        if v.id == "assassin_fight_describe_information" then
                            has_card = true
                        end
                    end
                    if not has_card then
                        self.engine:InsertCard(Negotiation.Card( "assassin_fight_describe_information", self.engine:GetPlayer() ))
                    end
                end
            end,
            [ EVENT.MODIFIER_CHANGED ] = function( self, modifier, delta, clone )
                if modifier == self and modifier.stacks >= self.calls_required then
                    if self.negotiator:GetModifierStacks("HELP_UNDERWAY") <= 0 then
                        self.negotiator:AddModifier("HELP_UNDERWAY", 1)
                    end
                    
                    self.negotiator:RemoveModifier(self)
                    self.anti_negotiator:AddModifier("IMPATIENCE", 1)
                    self:CleanUpCard("assassin_fight_describe_information")
                end
            end,
        },
    },
    HELP_UNDERWAY = 
    {
        name = "Help Underway!",
        desc = "Distract <b>{1}</> for {2} more turns until the help arrives!",
        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.anti_negotiator and self.anti_negotiator:GetName() or "the opponent",  self.turns_left)
        end,

        max_stacks = 1,
        
        modifier_type = MODIFIER_TYPE.PERMANENT,

        turns_left = rawget(_G, "SURVIVAL_TURNS") or 12,

        event_handlers = {
            [ EVENT.BEGIN_PLAYER_TURN ] = function( self, minigame )
                self.turns_left = self.turns_left - 1
                self:NotifyChanged()
                if self.turns_left <= 0 then
                    minigame:Win()
                end
            end,
        }
    },
    DISTRACTION_ENTERTAINMENT = 
    {
        name = "Distraction: Entertainment",
        desc = "When destroyed, {1} loses 1 {IMPATIENCE} if able and create a copy of this bounty with {2} more starting resolve.",
        
        modifier_type = MODIFIER_TYPE.BOUNTY,
        init_max_resolve = 9,

        bonus_per_generation = 3,

        generation = 0,

        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.negotiator and self.negotiator:GetName() or "the opponent",
                self.bonus_per_generation)
        end,
        OnInit = function(self)
            self:SetResolve(self.init_max_resolve + (self.generation or 0) * self.bonus_per_generation)
        end,
        OnBounty = function(self)
            if self.negotiator:GetModifierStacks("IMPATIENCE") > 0 then
                self.negotiator:RemoveModifier("IMPATIENCE", 1)
            end
            CreateNewSelfMod(self)
        end,
    },
    DISTRACTION_GUILTY_CONSCIENCE = 
    {
        name = "Distraction: Guilty Conscience",
        desc = "When destroyed, remove a random intent and create a copy of this bounty with {2} more starting resolve.",
        
        modifier_type = MODIFIER_TYPE.BOUNTY,
        init_max_resolve = 9,

        bonus_per_generation = 3,

        generation = 0,

        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.negotiator and self.negotiator:GetName() or "the opponent",
                self.bonus_per_generation)
        end,
        OnInit = function(self)
            self:SetResolve(self.init_max_resolve + (self.generation or 0) * self.bonus_per_generation)
        end,
        OnBounty = function(self)

            local intents = self.negotiator:GetIntents()
            if #intents > 0 then
                self.negotiator:DismissIntent(intents[math.random(#intents)])
            end

            CreateNewSelfMod(self)
        end,
    },
    DISTRACTION_CONFUSION = 
    {
        name = "Distraction: Confusion",
        desc = "When destroyed, {1} gain 1 {FLUSTERED} and create a copy of this bounty with {2} more starting resolve.",
        
        modifier_type = MODIFIER_TYPE.BOUNTY,
        init_max_resolve = 9,

        bonus_per_generation = 3,

        generation = 0,

        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.negotiator and self.negotiator:GetName() or "the opponent",
                self.bonus_per_generation)
        end,
        OnInit = function(self)
            self:SetResolve(self.init_max_resolve + (self.generation or 0) * self.bonus_per_generation)
        end,
        OnBounty = function(self)

            self.negotiator:AddModifier("FLUSTERED", 1)

            CreateNewSelfMod(self)
        end,
    },

    LOADED_QUESTION = 
    {
        name = "Loaded Question",
        desc = "When destroyed, the player loses support equal to the remaining splash damage.\n\n"..
        "When {address_question|addressed}, the player loses {2} support.",

        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.damage_amt, self.address_cost)
        end,

        min_persuasion = 2,
        max_persuasion = 2,

        address_cost = 5,

        target_enemy = TARGET_ANY_RESOLVE,

        max_stacks = 1,

        modifier_type = MODIFIER_TYPE.ARGUMENT,

        OnInit = function( self )
            self:SetResolve( 7, MODIFIER_SCALING.HIGH )
        end,

        OnBeginTurn = function( self, minigame )
            self:ApplyPersuasion()
        end,

        OnBounty = function(self)
            local mod = self.negotiator:CreateModifier("LOADED_QUESTION_DEATH_TRIGGER")
            mod.tracked_mod = self
        end,

        AddressQuestion = function(self)
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -self.address_cost)
        end,
    },
    -- Kinda have to do it this way, since removed modifier no longer listens to events that happened because of the removal of self.
    LOADED_QUESTION_DEATH_TRIGGER = 
    {
        name = "Loaded Question(Death Trigger)",
        hidden = true,
        event_handlers = 
        {
            [ EVENT.SPLASH_RESOLVE ] = function( self, modifier, overflow, params )
                if self.tracked_mod and self.tracked_mod == modifier then
                    DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", overflow)
                end
                self.negotiator:RemoveModifier(self)
            end
        },
    },
    CONTEMPORARY_QUESTION = 
    {
        name = "Contemporary Question",
        desc = "The interviewer asks about your opinion on <b>{1}</>.\n\n"..
            "When {address_question|addressed}, the player must state their opinion on this matter.",

        issue_data = nil,

        loc_strings = {
            ISSUE_DEFAULT = "a contemporary issue",
        },
        
        max_stacks = 1,

        desc_fn = function(self, fmt_str)
            return loc.format( fmt_str, self.issue_data and self.issue_data.name or self.def:GetLocalizedString("ISSUE_DEFAULT"))
        end,
        OnInit = function( self )
            self:SetResolve( 30 )
        end,
        min_persuasion = 2,
        max_persuasion = 2,
        modifier_type = MODIFIER_TYPE.ARGUMENT,
        SetIssue = function(self, issue_data)
            self.issue_data = issue_data
        end,
        AddressQuestion = function(self)
            if self.issue_data ~= nil then
                local cards = {}
                for id = -2, 2 do
                    local data = self.issue_data.stances[id]
                    if data then
                        local card = Negotiation.Card( "question_answer", self.owner )
                        card.engine = self.engine
                        card:UpdateIssue(self.issue_data, id)
                        table.insert(cards, card)
                    end
                end
                local pick = self.engine:ChooseCardsFromTable( cards, 1, 1, nil, "Choose an answer" )[1]
                if pick then
                    print(pick.name)
                end
            end
        end,
    },

    INTERVIEWER =
    {
        name = "Interviewer",
        desc = "The owner's arguments takes 1 less damage for every question arguments the owner has(to a minimum of 1).\n\nAt the beginning of the player's turn, add an {address_question} card to the player's hand.",
        alt_desc = "<#UPGRADE>Currently taking {2} less damage.</>",
        desc_fn = function(self, fmt_str )
            if self.negotiator then
                local question_count = 0
                for i, data in self.negotiator:Modifiers() do
                    if data.AddressQuestion then
                        question_count = question_count + 1
                    end
                end
                return loc.format(fmt_str .. "\n\n" .. self.def:GetLocalizedString("ALT_DESC"), self.negotiator:GetName(), question_count)
            else
                return loc.format(fmt_str)
            end
        end,
        -- icon = engine.asset.Texture("negotiation/modifiers/heckler.tex"),
        modifier_type = MODIFIER_TYPE.CORE,
        
        event_priorities =
        {
            [ EVENT.CALC_PERSUASION ] = EVENT_PRIORITY_ADDITIVE,
        },

        event_handlers = {
            [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion, minigame, target )
                if target and target.owner == self.owner then
                    local question_count = 0
                    for i, data in self.negotiator:Modifiers() do
                        if data.AddressQuestion then
                            question_count = question_count + 1
                        end
                    end
                    persuasion:AddPersuasion( - math.min(question_count, persuasion.min_persuasion - 1), - math.min(question_count, persuasion.max_persuasion - 1), self )
                end
            end,
            [ EVENT.BEGIN_PLAYER_TURN ] = function( self, minigame )
                local card = Negotiation.Card( "address_question", minigame:GetPlayer() )
                card.show_dealt = true
                minigame:DealCards( {card}, minigame:GetHandDeck() )
            end,
        },
        InitModifiers = function(self)
            -- for i = 1, 2 + math.floor(self.engine:GetDifficulty() / 2) do
            --     self:TryCreateNewTarget()
            -- end
        end,
    },
}
for id, def in pairs( MODIFIERS ) do
    Content.AddNegotiationModifier( id, def )
end