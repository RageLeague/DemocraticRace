local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT

local ARGUMENT_CREATOR =
{
    desc = "Create {2} {{1}}.",
    desc_fn = function(self, fmt_str)
        return loc.format(fmt_str, self.argument_to_create or (self.userdata and self.userdata.argument_to_create),
            self.stacks_to_create or (self.userdata and self.userdata.stacks_to_create) or 1)
    end,
    OnPostResolve = function( self, battle, attack)
        local modifier = self.negotiator:CreateModifier( self.argument_to_create or (self.userdata and self.userdata.argument_to_create) or self.id,
            self.stacks_to_create or (self.userdata and self.userdata.stacks_to_create) or 1, self )
        modifier.real_owner = self.real_owner
        -- if modifier.max_resolve then
        --     modifier:ModifyResolve(modifier.max_resolve, self)
        -- end
    end,
}
local ARGUMENT_INCEPTOR =
{
    desc = "{INCEPT} {2} {{1}}.",
    desc_fn = function(self, fmt_str)
        return loc.format(fmt_str, self.argument_to_create or (self.userdata and self.userdata.argument_to_create),
            self.stacks_to_create or (self.userdata and self.userdata.stacks_to_create) or 1)
    end,
    OnPostResolve = function( self, battle, attack)
        local modifier = self.anti_negotiator:CreateModifier( self.argument_to_create or (self.userdata and self.userdata.argument_to_create),
            self.stacks_to_create or (self.userdata and self.userdata.stacks_to_create) or 1, self )
        modifier.real_owner = self.real_owner
    end,
}
local MINI_NEGOTIATOR_CARDS =
{
    mn_influence_damage =
    {
        name = "Ethos",
        icon = "negotiation/build_rapport.tex",
        flags = CARD_FLAGS.DIPLOMACY,
        min_persuasion = 4,
        max_persuasion = 7,
    },
    mn_manipulate_damage =
    {
        name = "Logos",
        desc = "Attack twice.",
        icon = "negotiation/reconsider.tex",
        flags = CARD_FLAGS.MANIPULATE,
        min_persuasion = 3,
        max_persuasion = 3,
        attack_count = 2,
        OnPostResolve = function( self, minigame, targets )
            minigame:ApplyPersuasion(self)
        end
    },
    mn_hostile_damage =
    {
        name = "Pathos",
        icon = "negotiation/bellow.tex",
        flags = CARD_FLAGS.HOSTILE,
        min_persuasion = 3,
        max_persuasion = 8,
    },
    mn_inspire =
    {
        name = "Inspire",
        icon = "negotiation/collected.tex",
        flags = CARD_FLAGS.DIPLOMACY,
        min_persuasion = 2,
        max_persuasion = 4,
        features =
        {
            INFLUENCE = 2,
        },
    },
    mn_dominate =
    {
        name = "Dominate",
        icon = "negotiation/domineer.tex",
        flags = CARD_FLAGS.HOSTILE,
        min_persuasion = 3,
        max_persuasion = 3,
        features =
        {
            DOMINANCE = 2,
        },
    },
    mn_composure =
    {
        name = "Tangent",
        icon = "negotiation/segue.tex",
        flags = CARD_FLAGS.MANIPULATE,
        target_self = TARGET_ANY_RESOLVE,
        features =
        {
            COMPOSURE = 4,
        },
    },
    mn_composure_aoe =
    {
        name = "Defensive",
        desc = "Apply {1} {COMPOSURE} to all your arguments.",
        desc_fn = function(self, fmt_str)
            return loc.format(fmt_str, self.features.COMPOSURE)
        end,
        icon = "negotiation/standing.tex",
        flags = CARD_FLAGS.MANIPULATE,
        target_self = TARGET_ANY_RESOLVE,
        features =
        {
            COMPOSURE = 2,
        },
        target_mod = TARGET_MOD.TEAM,
        auto_target = true,
        manual_desc = true,
    },
    mn_interrogate = table.extend(ARGUMENT_CREATOR){
        name = "Interrogate",
        icon = "negotiation/tyrannize.tex",
        flags = CARD_FLAGS.HOSTILE,
        argument_to_create = "INTERROGATE",
    },
    mn_kingpin = table.extend(ARGUMENT_CREATOR){
        name = "Kingpin",
        icon = "negotiation/roughneck.tex",
        flags = CARD_FLAGS.HOSTILE,
        argument_to_create = "KINGPIN",
        cost = 2,
    },
    mn_all_business = table.extend(ARGUMENT_CREATOR){
        name = "All Business",
        icon = "negotiation/weight.tex",
        flags = CARD_FLAGS.DIPLOMACY,
        argument_to_create = "ALL_BUSINESS_MODDED",
    },
    mn_strawman = table.extend(ARGUMENT_INCEPTOR){
        name = "Straw Man",
        icon = "negotiation/fall_guy.tex",
        flags = CARD_FLAGS.MANIPULATE,
        argument_to_create = "straw_man",
    },
    mn_propaganda = table.extend(ARGUMENT_CREATOR){
        name = "Propaganda Machine",
        icon = "negotiation/propaganda.tex",
        argument_to_create = "mn_propaganda",
        flags = CARD_FLAGS.MANIPULATE,
        modifier = {
            desc = "When the damage of this argument causes resolve loss, add {mn_brainwashed} to the owner's deck.",
            icon = "negotiation/modifiers/brainwash.tex",
            max_stacks = 1,
            target_enemy = TARGET_ANY_RESOLVE,
            modifier_type = MODIFIER_TYPE.ARGUMENT,

            min_persuasion = 3,
            max_persuasion = 3,

            OnBeginTurn = function( self, minigame )
                self:ApplyPersuasion()
            end,
            OnInit = function( self )
                self:SetResolve( 3, MODIFIER_SCALING.MED )
            end,

            event_handlers = {
                [ EVENT.ATTACK_RESOLVE ] = function( self, source, target, damage, params, defended )
                    self.composure_gain = self.composure_gain or 0

                    if source and source == self then
                        if damage > defended then
                            if target.real_owner then
                                if target.real_owner.available_cards then
                                    local incepted_card = Negotiation.Card("mn_brainwashed", target.owner)
                                    table.insert(target.real_owner.available_cards, incepted_card)
                                end
                            elseif target and target:IsPlayerOwner() then
                                local incepted_card = Negotiation.Card("mn_brainwashed", target.owner)
                                self.engine:DealCard( incepted_card, self.engine:GetDrawDeck() )
                            end
                        end
                    end
                end,
            },
        },
    },
    mn_brainwashed =
    {
        name = "Brainwashed",
        icon = "negotiation/baffled.tex",
        flags = CARD_FLAGS.STATUS | CARD_FLAGS.UNPLAYABLE,
        cost = 0,
    },
    mn_prayer = table.extend(ARGUMENT_CREATOR){
        name = "Prayers",
        icon = "negotiation/token_of_hesh.tex",
        flags = CARD_FLAGS.DIPLOMACY,
        argument_to_create = "prayer_of_hesh",
    },
    mn_wrath = table.extend(ARGUMENT_CREATOR){
        name = "Wrath",
        desc = "Create 1 <b>Wrath of Hesh</>.",
        flavour = "Klei fix your Hesh damn description for Wrath of Hesh so that it doesn't break the game when not in a negotiation.",
        icon = "negotiation/inner_rage.tex",
        flags = CARD_FLAGS.HOSTILE,
        argument_to_create = "wrath_of_hesh",
    },
    mn_ploy = table.extend(ARGUMENT_CREATOR){
        name = "Ploy",
        icon = "negotiation/gossip.tex",
        flags = CARD_FLAGS.MANIPULATE,
        argument_to_create = "ploy",
    },
}
for i, id, def in sorted_pairs( MINI_NEGOTIATOR_CARDS ) do
    if not def.cost then
        def.cost = 1
    end
    if not def.series then
        def.series = CARD_SERIES.NPC
    end
    if not def.rarity then
        def.rarity = CARD_RARITY.UNIQUE
    end
    def.EvaluateTargetWeight = function( self, target, targets )
        if self.real_owner and self.real_owner.EvaluateCardTargetWeight then
            return self.real_owner:EvaluateCardTargetWeight(self, target, targets) or 1
        end
        return 1
    end,
    -- if not def.shop_price then
    --     def.shop_price = 250
    -- end
    Content.AddNegotiationCard( id, def )
end

local MINI_NEGOTIATOR =
{
    name = "Candidate",
    desc = "At the end of the turn, <b>{1.fullname}</> acts and plays {2} cards.",
    -- loc_strings = {
    --     ADMIRALTY_BONUS = "Then, if the opponent has no {PLANTED_EVIDENCE}, {INCEPT} one.",
    --     SPREE_BONUS = "{1.name}'s cards deals 1 bonus damage for every 2 turns passed.",
    --     BARON_BONUS = "Then, appropriate an opponent card.",
    --     RISE_BONUS = "Then, a random negotiator loses 1 action for their next turn.",
    --     CULT_BONUS = "When any argument on {1.name}'s team gets destroyed, all other arguments gain 2 resolve.",
    --     JAKES_BONUS = "Whenever {1.name}'s cards deal damage, they gain resolve equal to resolve loss. If no resolve is lost, they take 3 damage.",
    -- },
    desc_fn = function(self, fmt_str, minigame, widget)
        -- if self.special and (self.def or self).loc_strings[self.special .. "_BONUS"] then
        --     fmt_str = fmt_str .. "\n" .. (self.def or self):GetLocalizedString(self.special .. "_BONUS")
        -- end
        if widget and widget.PostCard and self.prepared_cards then
            for i, card in ipairs( self.prepared_cards) do
                widget:PostCard( card.id, card, minigame )
            end
        end
        if self.alt_desc then
            fmt_str = fmt_str .. "\n\n" .. (self.def or self):GetLocalizedString("ALT_DESC")
        end
        local res = loc.format(fmt_str, self.candidate_agent and self.candidate_agent:LocTable(),self.cards_played)
        return res
    end,
    modifier_type = MODIFIER_TYPE.CORE,

    cards_played = 3,
    max_stacks = 1,
    flip_on_opponent_side = true,

    available_cards = {},
    prepared_cards = {},

    OnInit = function(self)
        self.prepared_cards = {}
        self.available_cards = {}
        if self.available_cards_def then
            for i, data in ipairs(self.available_cards_def) do
                local card = Negotiation.Card(data[1], self.negotiator.agent, data[2])
                card.real_owner = self
                card.negotiator = self.negotiator
                -- self.engine:AssignPrimaryTarget(card)
                table.insert(self.available_cards, card)
            end
        end
        self.real_owner = self
        -- self:PrepareCards()
    end,
    resolve_scale = {50, 60, 70, 80},
    OnApply = function(self, minigame)
        if self.negotiator:IsPlayer() then
            self.max_resolve = 30
        else
            self.max_resolve = self.resolve_scale[
                math.min( GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY ) or 2,
                #self.resolve_scale)
            ]
        end
        self.resolve = self.max_resolve
        -- if not self.negotiator:IsPlayer() then
        --     self.engine:BroadcastEvent(EVENT.CUSTOM, function(panel)
        --         local widget = panel:FindSlotWidget(self)
        --         if widget then
        --             DBG(widget)
        --         end
        --     end)
        -- end
    end,
    OnEndTurn = function( self, minigame )
        -- if self.target_enemy then
        --     self:ApplyPersuasion()
        -- end
        self.engine:BroadcastEvent(EVENT.CUSTOM, function(panel)
            panel.last_ev_time = nil
            panel.speedup_factor = nil
            panel:RefreshCardSpeed()
        end)
        for i, card in ipairs(self.prepared_cards) do
            card.show_dealt = false
            self.engine.trash_deck:InsertCard( card )
            self.engine:PlayCard(card)
            card:RemoveCard()
        end

        if self.EndTurnEffect then
            self:EndTurnEffect(minigame)
        end
    end,
    OnPrepareTurn = function(self)
        if self.prepared_cards then
            for i, card in ipairs(self.prepared_cards) do
                self.engine:AssignPrimaryTarget(card)
            end
        end
    end,
    PrepareCards = function(self)
        table.clear(self.prepared_cards)
        local cards = {} -- table.multipick( self.available_cards, math.min(#self.available_cards, self.cards_played) )
        local available_cards = shallowcopy(self.available_cards)
        local actions_left = self.cards_played
        print("Preparing for", self)
        while actions_left > 0 and #available_cards > 0 do
            print("actions_left:", actions_left)
            local chosen = table.arraypick(available_cards)
            if (chosen.cost or 1) <= actions_left then
                table.insert(cards, chosen)
                actions_left = actions_left - (chosen.cost or 1)
                print("Chosen card:",chosen)
            end
            table.arrayremove(available_cards, chosen)
        end
        -- table.shuffle(cards)
        for i, card in ipairs(cards) do
            table.insert(self.prepared_cards, card)
        end
        self.engine:BroadcastEvent( EVENT.INTENTS_CHANGED )
        self:NotifyChanged()
    end,

    no_damage_tt = true,
    -- icon = engine.asset.Texture("negotiation/modifiers/voice_of_the_people.tex"),

    target_enemy = TARGET_ANY_RESOLVE,
    target_mod = TARGET_MOD.CUSTOM,
    min_persuasion = 0,
    max_persuasion = 0, -- for testing purpose only
    target_fn = function(self, minigame, primary_target, targets, source)
        if self.prepared_cards then
            for i, card in ipairs(self.prepared_cards) do
                minigame:AssignPrimaryTarget(card)
                if card.min_persuasion and card.max_persuasion then
                    local card_targets = minigame:CollectTargets(card)
                    for i, target in ipairs(card_targets) do
                        table.insert_unique( targets, target )
                    end
                end
            end
        end
    end,
    CustomDamagePreview = function(self, minigame, slot, target_modifier)
        -- print("Haha", target_modifier)
        print(self)
        if not target_modifier then return end
        if self.prepared_cards then
            for i, card in ipairs(self.prepared_cards) do
                if card.min_persuasion and card.max_persuasion then
                    -- print("Preview card:", card)
                    minigame:AssignPrimaryTarget(card)
                    local card_targets = minigame:CollectTargets(card)
                    for i, target in ipairs(card_targets) do
                        if target:GetUID() == target_modifier:GetUID() then
                            local mindmg, maxdmg = minigame:PreviewPersuasion( card )

                            for i = 1, card.attack_count or 1 do
                                slot:CreateDamagePreviewLabel(self, mindmg, maxdmg)
                            end
                        else
                            -- print(target._classname, target_modifier._classname)
                            -- print(target, "Not equal to target_modifier:", target_modifier)
                        end
                    end
                end
            end
        end
    end,
    CustomPersuasionLabel = function(self)
        if self.engine and self.engine:GetOpponentNegotiator() then
            local opponent_core = self.engine:GetOpponentNegotiator():FindCoreArgument()
            if opponent_core and opponent_core.scores and opponent_core.scores[self:GetUID()] then
                return opponent_core.scores[self:GetUID()].score or 0
            end
        end
        return 0
    end,
    EvaluateCardTargetWeight = function(self, card, target, targets)
        if card.target_enemy then
            local weight = 1
            if target.real_owner and target.real_owner.negotiator == target.negotiator then
                local self_agent = self.candidate_agent
                local target_fac = target.real_owner.candidate_agent and target.real_owner.candidate_agent:GetFactionID() or "NEUTRAL"
                if self_agent and self_agent:GetFactionRelationship(target_fac) < RELATIONSHIP.NEUTRAL then
                    -- Increase weight if hates the other guy
                    weight = weight + (RELATIONSHIP.NEUTRAL - self_agent:GetFactionRelationship(target_fac)) / 2
                end
            end
            if target.modifier_type ~= MODIFIER_TYPE.CORE then
                weight = weight + 0.5
            end
            if target.target_enemy then
                weight = weight + 1.5
            end
            if target.target_mod == TARGET_MOD.TEAM then
                weight = weight + 1.5
            end
            return weight
        end
        return 1
    end,
    -- event_priorities =
    -- {
    --     [ EVENT.CALC_PERSUASION ] = EVENT_PRIORITY_MULTIPLIER,
    -- },
    event_handlers = {
        -- [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion, minigame, target )
        --     if target and target.real_owner == self and source and source..real_owner then
        --         persuasion:ModifyPersuasion( persuasion.min_persuasion, persuasion.max_persuasion, self )
        --     end
        -- end,
        [ EVENT.BEGIN_NEGOTIATION ] = function(self, minigame)
            self:PrepareCards()
        end,
        [ EVENT.BEGIN_TURN ] = function( self, minigame, negotiator )
            if negotiator ~= self.negotiator then
                self:PrepareCards()
            end
        end,
    },

    -- SetCandidate = function(self, candidate_agent, available_cards, special)
    --     self.candidate_agent = candidate_agent
    --     self.available_cards = shallowcopy(available_cards)
    --     self.special = special

    --     self:NotifyChanged()
    -- end,
}
Content.AddNegotiationModifier("ADMIRALTY_MINI_NEGOTIATOR",
table.extend(MINI_NEGOTIATOR){
    name = "Oolo's Power Abuse",
    alt_desc = "Then, if the opponent has no {PLANTED_EVIDENCE_MODDED}, {INCEPT} one.",
    icon = "DEMOCRATICRACE:assets/modifiers/mini_negotiator/admiralty.png",
    available_cards_def =
    {
        {"mn_influence_damage"},
        {"mn_manipulate_damage"},
        {"mn_manipulate_damage"},
        {"mn_hostile_damage"},

        {"mn_composure"},
        {"mn_composure"},
        {"mn_composure_aoe"},

        {"mn_interrogate"},
        -- {"mn_interrogate"},
        -- {"mn_inspire"},
        {"mn_inspire"},
    },
    EndTurnEffect = function(self, minigame)
        local has_argument = self.anti_negotiator:FindModifier( "PLANTED_EVIDENCE_MODDED" )
        if not has_argument then
            local modifier = self.anti_negotiator:InceptModifier("PLANTED_EVIDENCE_MODDED", (self.engine:GetDifficulty() or 1) * 2, self )
            self:NotifyTriggered()
        end
    end,
})

Content.AddNegotiationModifier("SPREE_MINI_NEGOTIATOR",
table.extend(MINI_NEGOTIATOR){
    name = "Nadan's Short Fuse",
    alt_desc = "{1.name}'s cards and arguments deals 1 bonus damage for every 2 turns passed.",
    icon = "DEMOCRATICRACE:assets/modifiers/mini_negotiator/spree.png",
    loc_strings = {
        TOOLTIP = "({1} bonus damage)",
    },
    desc_fn = function(self, ...)
        local res = MINI_NEGOTIATOR.desc_fn(self, ...)
        if self.engine and self.engine.turns then
            res = res .. "\n\n" .. loc.format((self.def or self):GetLocalizedString("TOOLTIP"), math.floor((self.engine.turns - 1) / 2))
        end
        return res
    end,
    available_cards_def =
    {
        -- {"mn_influence_damage"},
        {"mn_influence_damage"},
        {"mn_hostile_damage"},
        {"mn_hostile_damage"},
        {"mn_hostile_damage"},

        {"mn_composure"},
        {"mn_composure"},

        {"mn_kingpin"},
        -- {"mn_kingpin"},
        -- {"mn_ploy"},
        -- {"mn_dominate"},
        {"mn_dominate"},
        {"mn_dominate"},
    },
    event_priorities =
    {
        [ EVENT.CALC_PERSUASION ] = EVENT_PRIORITY_ADDITIVE,
    },
    event_handlers = {
        [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion, minigame, target )
            if source and source.real_owner == self then
                local turns = minigame.turns - 1
                local delta = math.floor(turns / 2)
                if delta > 0 then
                    persuasion:AddPersuasion(delta, delta, self)
                end
            end
        end,
    },
})

Content.AddNegotiationModifier("BARON_MINI_NEGOTIATOR",
table.extend(MINI_NEGOTIATOR){
    name = "Fellemo's Appropriation",
    alt_desc = "Then, appropriate a random opponent's card.",
    icon = "DEMOCRATICRACE:assets/modifiers/mini_negotiator/baron.png",
    available_cards_def =
    {
        -- {"mn_influence_damage"},
        {"mn_influence_damage"},
        {"mn_manipulate_damage"},
        {"mn_manipulate_damage"},
        {"mn_hostile_damage"},

        {"mn_composure"},
        {"mn_composure_aoe"},

        {"mn_all_business"},
        -- {"mn_all_business"},
        -- {"mn_strawman"},
        {"mn_strawman"},
        {"mn_strawman"},
    },
    EndTurnEffect = function(self, minigame)
        local MAX_STOLEN = 3
        local MIN_TO_LEAVE = 5

        local num_stolen = 0
        for i,modifier in self.negotiator:ModifierSlots() do
            if modifier.id == "APPROPRIATED_MODDED" then
                num_stolen = num_stolen + modifier:GetStolenCount()
            end
        end

        if num_stolen < MAX_STOLEN then
            local candidates = {}
            for i, modifier in self.anti_negotiator:ModifierSlots() do
                if modifier.available_cards and #modifier.available_cards > MIN_TO_LEAVE then
                    table.insert(candidates, modifier)
                end
            end
            if self.anti_negotiator:IsPlayer() then
                local cards = self.engine:GetAllPlayerCards(function(card) return not CheckBits( card.flags, CARD_FLAGS.STATUS ) end)

                if #cards > MIN_TO_LEAVE then
                    table.insert(candidates, "PLAYER")
                end
            end
            while #candidates > 0 do
                local chosen = table.arraypick(candidates)
                table.arrayremove(candidates, chosen)
                local count = 1
                if type(chosen) == "table" then
                    local cards = {}
                    for i, card in ipairs(chosen.available_cards) do
                        if not table.arraycontains(chosen.prepared_cards, card) then
                            table.insert(cards, card)
                        end
                    end
                    if #cards > 0 then
                        cards = table.multipick(cards, count)
                        local approp
                        approp = self.negotiator:CreateModifier("APPROPRIATED_MODDED", 1, self )
                        for i, card in ipairs( cards ) do
                            if approp:IsApplied() then -- verify that it still exists
                                print( self.negotiator, "appropriated", card, "from", card.deck )
                                approp:AppropriateCard( card, chosen )
                            end
                        end
                        return

                    end
                else
                    local cards = self.engine:GetAllPlayerCards(function(card) return not CheckBits( card.flags, CARD_FLAGS.STATUS ) end)
                    cards = table.multipick(cards, count)
                    local approp
                    approp = self.negotiator:CreateModifier("APPROPRIATED_MODDED", 1, self )
                    for i, card in ipairs( cards ) do
                        if approp:IsApplied() then -- verify that it still exists
                            print( self.negotiator, "appropriated", card, "from", card.deck )
                            approp:AppropriateCard( card )
                        end
                    end
                    return
                end
                self:NotifyTriggered()
            end
        end
    end,
})

Content.AddNegotiationModifier("RISE_MINI_NEGOTIATOR",
table.extend(MINI_NEGOTIATOR){
    name = "Kalandra's Call to Rise",
    alt_desc = "Then, a random opponent loses 1 action for their next turn.",
    icon = "DEMOCRATICRACE:assets/modifiers/mini_negotiator/rise.png",
    loc_strings = {
        PENALTY_TXT = "-1 Action",
    },
    available_cards_def =
    {
        {"mn_influence_damage"},
        {"mn_influence_damage"},
        {"mn_manipulate_damage"},
        {"mn_hostile_damage"},

        {"mn_composure"},
        {"mn_composure_aoe"},
        {"mn_composure_aoe"},

        {"mn_propaganda"},
        -- {"mn_propaganda"},
        -- {"mn_inspire"},
        {"mn_inspire"},
    },
    EndTurnEffect = function(self, minigame)
        local candidates = {}
        for i, modifier in self.anti_negotiator:ModifierSlots() do
            if modifier.prepared_cards and #modifier.prepared_cards > 0 then
                table.insert(candidates, modifier)
            end
        end
        if self.anti_negotiator:IsPlayer() then
            table.insert(candidates, "PLAYER")
        end
        if #candidates == 0 then
            return
        end
        local chosen = table.arraypick(candidates)
        local function PopupFloater(panel, source_widget)
            local label = panel:AddChild( Widget.Label( "title", 48, (self.def or self):GetLocalizedString("PENALTY_TXT") ):SetBloom( 0.2 ))
            local self_widget = panel:FindSlotWidget(self)
            local sizex, sizey = source_widget:GetSize()
            local screenw, screenh = panel:GetFE():GetScreenDims()

            local sx, sy
            if self_widget then
                sx, sy = panel:TransformFromWidget(self_widget, 0, 0)
            else
                sx, sy = screenw / 2, screenh / 2
            end
            local tx, ty = panel:TransformFromWidget( source_widget, 0, 0 )

            label:SetGlyphColour( UICOLOURS.PENALTY )


            -- label:SetPos( w/2, h/2 )
            label:SetPos( sx, sy )
            label:ScaleTo( 1.0, 1.3, 0.2, easing.outQuad )
            panel:Delay( 0.2 )
            label:ScaleTo( 1.3, 1.0, 0.2, easing.outQuad )
            panel:Delay( 0.5 )

            local duration = 0.3
            label:MoveTo( tx, ty, duration, easing.inQuad )
            -- label:AlphaTo( 0, duration )
            -- label:ScaleTo( 1.0, 0.5, duration, easing.outQuad )
            label:Delay( duration )
            duration = 0.5
            label:AlphaTo(0, duration)
            label:ScaleTo(1.0, 0.5, duration, easing.outQuad)
            label:Delay(duration)
            label:Remove()
        end
        if type(chosen) == "table" then
            table.remove(chosen.prepared_cards, math.random(1, #chosen.prepared_cards))
            self.engine:BroadcastEvent(EVENT.CUSTOM, function(panel)
                PopupFloater(panel, panel:FindSlotWidget( chosen ))
            end)
            chosen:NotifyChanged()
            self:NotifyTriggered()
        else
            self.anti_negotiator:DeltaModifier("FREE_ACTION", -1, self)
            self.engine:BroadcastEvent(EVENT.CUSTOM, function(panel)
                PopupFloater(panel, panel.time_indicator)
            end)
            self:NotifyTriggered()
        end

    end,
})

Content.AddNegotiationModifier("CULT_MINI_NEGOTIATOR",
table.extend(MINI_NEGOTIATOR){
    name = "Vixmalli's Zeal",
    alt_desc = "When any argument on {1.name}'s team gets destroyed, all other arguments gain 1 resolve.",
    icon = "DEMOCRATICRACE:assets/modifiers/mini_negotiator/cult.png",
    available_cards_def =
    {
        -- {"mn_influence_damage"},
        {"mn_influence_damage"},
        -- {"mn_manipulate_damage"},
        {"mn_manipulate_damage"},
        {"mn_manipulate_damage"},

        -- {"mn_composure"},
        {"mn_composure"},
        -- {"mn_composure_aoe"},

        {"mn_wrath"},
        -- {"mn_wrath"},
        -- {"mn_wrath"},
        -- {"mn_prayer"},
        -- {"mn_prayer"},
        {"mn_prayer"},
        {"mn_strawman"},
    },
    event_handlers = {
        -- [ EVENT.CALC_PERSUASION ] = function( self, source, persuasion, minigame, target )
        --     if source and source.real_owner == self then
        --         local turns = minigame.turns - 1
        --         local delta = math.floor(turns / 2)
        --         if delta > 0 then
        --             persuasion:AddPersuasion(delta, delta, self)
        --         end
        --     end
        -- end,
        [ EVENT.MODIFIER_REMOVED ] = function( self, modifier, card )
            print("Event happened")
            if modifier.modifier_type == MODIFIER_TYPE.ARGUMENT and modifier.negotiator == self.negotiator then
                print("Allied modifier removed...")
                for i, mod in self.negotiator:Modifiers() do
                    if mod ~= modifier and mod.modifier_type == MODIFIER_TYPE.ARGUMENT then
                        mod:ModifyResolve( 1, self )
                    end
                end
            end
        end,
    },
})

Content.AddNegotiationModifier("JAKES_MINI_NEGOTIATOR",
table.extend(MINI_NEGOTIATOR){
    name = "Andwanette's Double Edge",
    alt_desc = "Whenever {1.name}'s cards deal damage, they gain resolve equal to resolve loss.",
    icon = "DEMOCRATICRACE:assets/modifiers/mini_negotiator/jakes.png",
    available_cards_def =
    {
        {"mn_influence_damage"},
        {"mn_hostile_damage"},
        {"mn_hostile_damage"},
        {"mn_manipulate_damage"},
        {"mn_manipulate_damage"},

        {"mn_composure"},
        {"mn_composure"},
        {"mn_composure_aoe"},

        {"mn_ploy"},
        -- {"mn_ploy"},
        {"mn_dominate"},
        -- {"mn_strawman"},
    },
    resolve_loss = 3,

    target_self = TARGET_ANY_RESOLVE,

    OnBeginTurn = function( self, minigame )
        self.composure_gain = 0
    end,

    EndTurnEffect = function( self, minigame )
        print(self.composure_gain)
        if self.composure_gain > 0 then
            local targets = {}
            for i, modifier in self.negotiator:ModifierSlots() do
                if modifier:GetResolve() ~= nil then
                    table.insert( targets, {modifier=modifier, count=0} )
                end
            end

            while self.composure_gain > 0 and #targets > 0 do
                for i, target in ipairs(targets) do
                    if self.composure_gain > 0 then
                        target.count = target.count + 1
                        self.composure_gain = self.composure_gain - 1
                    end
                end
            end

            for i, target in ipairs(targets) do
                target.modifier:DeltaComposure( target.count, self)
            end
        end
    end,

    event_handlers =
    {
        [ EVENT.BEGIN_TURN ] = function( self, minigame, negotiator )
            if negotiator == self.negotiator then
                self.active = true
            end
        end,
        [ EVENT.END_TURN ] = function( self, minigame, negotiator )
            if negotiator == self.negotiator then
                self.active = false
            end
        end,
        [ EVENT.ATTACK_RESOLVE ] = function( self, source, target, damage, params, defended )
            self.composure_gain = self.composure_gain or 0

            if self.active and source and source.real_owner == self  then
                if damage > defended then
                    local gain = math.min( target:GetResolve(), damage - defended)
                    self.composure_gain = self.composure_gain + gain
                else
                    -- if self.negotiator:FindCoreArgument():GetShieldStatus() or CheckBits(self.engine:GetFlags(), NEGOTIATION_FLAGS.NO_CORE_RESOLVE) then
                    --     local targets = self.engine:CollectAllTargets(self)
                    --     table.arrayremove( targets, self.negotiator:FindCoreArgument() )
                    --     local edge_target = table.arraypick( targets )
                    --     if edge_target then
                    --         self.engine:ApplyPersuasion( target, edge_target, self.resolve_loss, self.resolve_loss )
                    --     end
                    -- else
                    --     self.engine:ApplyPersuasion( target, self.negotiator, self.resolve_loss, self.resolve_loss )
                    -- end
                end
            end
        end,
    },
})
