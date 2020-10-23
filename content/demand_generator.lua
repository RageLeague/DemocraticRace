local negotiation_defs = require "negotiation/negotiation_defs"
local EVENT = negotiation_defs.EVENT
-- Content.AddStringTable("DEMOCRACY_DEMAND", {
--     CONVO_COMMON = {
--         DEMAND_STRING = {
--             DIALOG_ACCEPT_MONEY = [[
--                 player:
--                     !give
--                     Here's your money, as part of our deal.
--                 agent:
--                     !take
--                     I'll take it.
--             ]],
--             DIALOG_TAKE_STANCE = [[
--                 player:
--                     Fine, I'll make a public statement agreeing with you.
--                 agent:
--                     Every step helps.
--             ]],
--             -- OPT_TAKE_STANCE = "Take the stance <i>{1#pol_stance}</> on <b>{2#pol_issue}</>.",
--         },
--     },
-- })
local DEMANDS = {
    demand_money = {
        name = "Demand Money",
        title = "pay {1#money}",
        title_fn = function(self, fmt_str, data)
            return loc.format(fmt_str, data and data.stacks or 0)
        end,

        desc = "At the start of {1}'s turn, remove {2#percent} of stacks on this argument.\nWhen destroyed by the player, remove {3#money} from {1}'s demand.",
        alt_desc = "At the start of {1}'s turn, remove {2#percent} of stacks on this argument.\nWhen destroyed by the player, remove shills equal to the number of stacks on this argument from {1}'s demand.",
        desc_fn = function(self, fmt_str)
            local owner = Negotiation.Modifier.GetOwnerName(self)
            if self.stacks then
                return loc.format(fmt_str, owner, self.remove_ratio, self.stacks)
            else
                return loc.format(self.def and self.def:GetLocalizedString( "ALT_DESC" ) or self:GetLocalizedString( "ALT_DESC" ), owner, self.remove_ratio)
            end
        end,


        modifier_type = MODIFIER_TYPE.BOUNTY,
        -- this indicates that this demand can appear in anyone's demands
        common_demand = true,
        -- this indicates that this demand is material(something that actually exists) rather than
        -- abstract(something that is only an idea, like promises or taking stances)
        material_demand = true,

        OnInit = function( self, source )
            self:SetResolve( 1 + math.round(self.stacks / 5) )
            AUDIO:PlayEvent("event:/sfx/battle/cards/neg/create_argument/bonus")
        end,

        max_stacks = 999,
        remove_ratio = 0.3,
        event_handlers =
        {

            [ EVENT.END_PLAYER_TURN ] = function( self, minigame )
                self.negotiator:DeltaModifier(self, -math.ceil( self.stacks*self.remove_ratio))
                AUDIO:PlayEvent("event:/sfx/battle/cards/neg/bonus_tick_down")
            end

        },
        
        OnBounty = function( self, card )
            local demand_list = self.engine.demand_list
            local demand_data = self.demand_data
            if demand_list then
                local money_entry
                for i, entry in ipairs(demand_list) do
                    if entry.id == self.id then
                        money_entry = entry
                        break
                    end
                end
                if money_entry then
                    money_entry.stacks = (money_entry.stacks or 0) - self.stacks
                    if money_entry.stacks <= 0 then
                        table.arrayremove(demand_list, money_entry)
                    end
                end
            end
            if demand_data then
                demand_data.stacks = (demand_data.stacks or 0) - self.stacks
                if demand_data.stacks <= 0 then
                    demand_data.resolved = true
                end
            end
            DemocracyUtil.CheckHeavyHanded(self, card, self.engine)
        end,
        GenerateDemand = function(self, pts, data) -- takes in pts for points allocated to this demand
            local rank = data and data.rank or TheGame:GetGameState():GetCurrentBaseDifficulty()
            local min_pts = 30 + 10 * rank
            local max_pts = math.min(self.max_stacks, pts, 60 + 30 * rank)
            if max_pts <= min_pts then
                -- return two values:
                -- first value, pts spent on this demand
                -- second value, a table showing the demands, with an id equal to the demand id, and a stacks
                -- indicating the stacks, along with potentially any other things
                return max_pts, {id = self.id, stacks = max_pts}
            end
            local pts_spent = math.round(math.randomGauss(min_pts, max_pts))

            if pts_spent + min_pts > pts and pts_spent + min_pts <= math.min(self.max_stacks, 60 + 30 * rank) then
                pts_spent = pts
            end
            return pts_spent, {id = self.id, stacks = pts_spent}
        end,
        ParseDemandList = function(self, data, t)
            -- print("you called?!")
            local money_entry
            for i, vals in ipairs(t) do
                print(vals.id, self.id)
                if vals.id == self.id then
                    money_entry = vals
                    print("found money")
                    break
                end
            end
            if money_entry then
                money_entry.stacks = (money_entry.stacks or 0) + (data.stacks or 0)
            else
                table.insert(t, shallowcopy(data))
            end
        end,
        GenerateConvoOption = function(self, cxt, opt, data, demand_modifiers)
            opt:PreIcon( global_images.giving )
                -- :Dialog("DEMAND_STRING.DIALOG_ACCEPT_MONEY")
                :DeliverMoney(data.stacks, {no_scale = true})
                :Fn(function(cxt)
                    data.resolved = true
                    for i, modifier in ipairs(demand_modifiers) do
                        if modifier.id == self.id then
                            modifier.resolved = true
                        end
                    end
                end)
        end,
    },
    demand_instant_stance = {
        name = "Demand Stance Taking",
        title = "take the stance {1#pol_stance} on {2#pol_issue}",
        title_fn = function(self, fmt_str, data)
            local issue = DemocracyConstants.issue_data[data.issue_id]
            if issue then
                return loc.format(fmt_str, issue:GetStance(data.stance), issue)
            end
            return fmt_str
        end,

        desc = "This modifier will remove itself after {1} {1*turn|turns}.\nWhen destroyed by the player, {2} will stop demanding you from taking this stance.",
        alt_desc = "<#HILITE>({1#pol_stance} on {2#pol_issue})</>",
        desc_fn = function(self, fmt_str)
            local rval = loc.format(fmt_str, self.stacks or 4, Negotiation.Modifier.GetOwnerName(self))
            if self.issue and self.stance then
                rval = rval .. "\n" .. loc.format( (self.def or self):GetLocalizedString("ALT_DESC"), self.stance, self.issue )
            end
            return rval
        end,

        modifier_type = MODIFIER_TYPE.BOUNTY,
        common_demand = true,

        event_handlers =
        {

            [ EVENT.END_PLAYER_TURN ] = function( self, minigame )
                self.negotiator:DeltaModifier(self, -1)
                AUDIO:PlayEvent("event:/sfx/battle/cards/neg/bonus_tick_down")
            end

        },

        OnInit = function( self, source )
            self:SetResolve( 10 + 5 * self.engine:GetDifficulty() )
            AUDIO:PlayEvent("event:/sfx/battle/cards/neg/create_argument/bonus")
        end,
        ApplyData = function(self, data)
            self.issue = DemocracyConstants.issue_data[data.issue_id]
            self.stance = self.issue:GetStance(data.stance)
            self:NotifyChanged()
        end,
        max_demand_use = 2,
        
        OnBounty = function( self, card )
            local demand_list = self.engine.demand_list
            local demand_data = self.demand_data
            if demand_list then
                local money_entry
                for i, entry in ipairs(demand_list) do
                    if entry.id == self.id and entry.issue_id == demand_data.issue_id then
                        money_entry = entry
                        break
                    end
                end
                if money_entry then
                    table.arrayremove(demand_list, money_entry)
                    demand_data.resolved = true
                end
            end
            DemocracyUtil.CheckHeavyHanded(self, card, self.engine)
        end,
        
        GenerateDemand = function(self, pts, data) -- takes in pts for points allocated to this demand
            local rank = data and data.rank or TheGame:GetGameState():GetCurrentBaseDifficulty()
            local issue_id, stance = data.force_issue, data.force_stance
            local available_issues = DemocracyUtil.CollectIssueImportance(data.agent)--copykeys(DemocracyConstants.issue_data)
            local player_stance = issue_id and DemocracyUtil.TryMainQuestFn("GetStance", issue_id)
            if data.used_issues then
                for i, id in ipairs(data.used_issues) do
                    available_issues[id] = nil
                end
            end
            while not issue_id do
                if #copykeys(available_issues) <= 0 then
                    return
                end
                issue_id = weightedpick(available_issues)
                available_issues[issue_id] = nil
                player_stance = DemocracyUtil.TryMainQuestFn("GetStance", issue_id)
                if data.agent then
                    stance = DemocracyConstants.issue_data[issue_id]:GetAgentStanceIndex(data.agent)
                else
                    stance = math.random(-2, 2)
                end

                if stance == 0 or (player_stance and stance == player_stance) then
                    issue_id = nil
                end
            end
            if not stance then
                if data.agent then
                    stance = DemocracyConstants.issue_data[issue_id]:GetAgentStanceIndex(data.agent)
                else
                    stance = math.random(-2, 2)
                end
            end
            if stance == 0 or (player_stance and stance == player_stance) then
                return
            end

            local delta = player_stance and math.abs(player_stance - stance)

            local cost = 20 * (rank - 1) + DemocracyConstants.issue_data[issue_id]:GetImportance(data.agent) * 8
            if delta then
                cost = cost + 15 * (delta - 1)
            end
            if cost <= pts then
                data.used_issues = data.used_issues or {}
                table.insert(data.used_issues, issue_id)
                return cost, {id = self.id, stacks = math.random(3,5), issue_id = issue_id, stance = stance}
            end
        end,
        ParseDemandList = function(self, data, t)
            table.insert(t, shallowcopy(data))
        end,
        GenerateConvoOption = function(self, cxt, opt, data, demand_modifiers)
            opt:PreIcon( global_images.order )
                -- :Dialog("DEMAND_STRING.DIALOG_ACCEPT_MONEY")
                :UpdatePoliticalStance(data.issue_id, data.stance, true, true)
                :Fn(function(cxt)
                    data.resolved = true
                    for i, modifier in ipairs(demand_modifiers) do
                        if modifier.id == self.id and modifier.issue_id == data.issue_id and modifier.stance == data.stance then
                            modifier.resolved = true
                        end
                    end
                end)
        end,
    },
    demand_favor = {
        name = "Demand Favor",
        title = "call for a favor",

        desc = "This modifier will remove itself after {1} {1*turn|turns}.\nWhen destroyed by the player, {2} will stop demanding you from calling in a favor(reducing your relationship with them).",

        desc_fn = function(self, fmt_str)
            local rval = loc.format(fmt_str, self.stacks or 4, Negotiation.Modifier.GetOwnerName(self))
            return rval
        end,

        modifier_type = MODIFIER_TYPE.BOUNTY,
        common_demand = true,

        event_handlers =
        {

            [ EVENT.END_PLAYER_TURN ] = function( self, minigame )
                self.negotiator:DeltaModifier(self, -1)
                AUDIO:PlayEvent("event:/sfx/battle/cards/neg/bonus_tick_down")
            end

        },

        OnInit = function( self, source )
            self:SetResolve( 10 + 5 * self.engine:GetDifficulty() )
            AUDIO:PlayEvent("event:/sfx/battle/cards/neg/create_argument/bonus")
        end,
        -- ApplyData = function(self, data)
        --     self.issue = DemocracyConstants.issue_data[data.issue_id]
        --     self.stance = self.issue:GetStance(data.stance)
        --     self:NotifyChanged()
        -- end,
        max_demand_use = 1,
        
        OnBounty = function( self, card )
            local demand_list = self.engine.demand_list
            local demand_data = self.demand_data
            if demand_list then
                local money_entry
                for i, entry in ipairs(demand_list) do
                    if entry.id == self.id then
                        money_entry = entry
                        break
                    end
                end
                if money_entry then
                    table.arrayremove(demand_list, money_entry)
                    demand_data.resolved = true
                end
            end
            DemocracyUtil.CheckHeavyHanded(self, card, self.engine)
        end,
        
        GenerateDemand = function(self, pts, data) -- takes in pts for points allocated to this demand
            if not (data.agent and data.agent:GetRelationship() > RELATIONSHIP.NEUTRAL) then
                print("Require friendly relationship")
                return
            end
            local cost = 100
            if pts >= cost then
                return cost, {id = self.id}
            end
        end,
        ParseDemandList = function(self, data, t)
            table.insert(t, shallowcopy(data))
        end,
        GenerateConvoOption = function(self, cxt, opt, data, demand_modifiers)
            opt:PreIcon( global_images.order )
                -- :Dialog("DEMAND_STRING.DIALOG_ACCEPT_MONEY")
                :ReceiveOpinion(OPINION.CALL_IN_FAVOUR)
                :Fn(function(cxt)
                    data.resolved = true
                    for i, modifier in ipairs(demand_modifiers) do
                        if modifier.id == self.id then
                            modifier.resolved = true
                            return
                        end
                    end
                end)
        end,
    },
}
local COMMON_DEMANDS = {}
local function AddDemandModifier(id, data)
    data.id = id
    if data.common_demand then
        table.insert(COMMON_DEMANDS, id)
        print("Added common demand " .. id)
    end
    Content.AddNegotiationModifier(id, data)

end
for id, data in pairs(DEMANDS) do
    AddDemandModifier(id, data)
end

local function GenerateDemands(pts, agent, rank, _params)
    local variance, additional_demands, forced_demands, blocked_demands = 
        _params.variance, _params.additional_demands,
        _params.forced_demands, _params.blocked_demands
    if _params.auto_scale then
        pts = CalculatePayment(agent, pts)
    end
    local available_demands = table.merge(COMMON_DEMANDS, additional_demands or {})
    local demand_uses = {}
    local demands = {}
    local params = {
        rank = rank or TheGame:GetGameState():GetCurrentBaseDifficulty(), 
        agent = agent,
        used_issues = {},
    }
    local ratio = math.randomGauss(1 - (variance or 0.2), 1 + (variance or 0.2))
    local pts_left = math.round(pts * ratio)
    local function GenerateOneDemand(info)
        local id
        if type(info) == "string" then
            id = info
        elseif type(info) == "table" then
            if info.id then id = info.id end
        end
        assert(id, "id required")
        if not table.arraycontains(available_demands, id) then
            return
        end
        if blocked_demands and table.arraycontains(blocked_demands, id) then
            table.arrayremove(available_demands, id)
            return
        end
        local modifier = Content.GetNegotiationModifier(id)
        local generator_params = shallowcopy(params)
        if type(info) == "table" then
            generator_params = table.extend(generator_params)(info)
        end
        local cost, demand_table = modifier:GenerateDemand(pts_left, generator_params)
        if cost then
            pts_left = pts_left - cost
            demand_table.value = cost
            table.insert(demands, demand_table)
            if modifier.max_demand_use then
                demand_uses[id] = (demand_uses[id] or 0) + 1
                if demand_uses[id] >= modifier.max_demand_use then
                    table.arrayremove(available_demands, id)
                end
            end
        else
            table.arrayremove(available_demands, id) -- invalid. Remove
            -- Note: The money one always returns something at the end
        end
    end
    for i, id in ipairs(forced_demands or {}) do
        GenerateOneDemand(id)
    end
    while pts_left > 0 do -- if the points left is less than 10, there's barely any meaning to run another generation.
        assert(#available_demands > 0,loc.format( "Run out of demands before running out of points to allocate the demands({1} pts left)", pts_left))
        local selected_demand = table.arraypick(available_demands)
        GenerateOneDemand(selected_demand)
    end
    return demands
end
local function ParseDemandList(demand_list)
    local l = {}
    for i, data in ipairs(demand_list) do
        local modifier = Content.GetNegotiationModifier(data.id)
        -- print("hello")
        if modifier.ParseDemandList then
            -- print("hi")
            modifier:ParseDemandList(data, l)
        else
            table.insert(l, shallowcopy(data))
        end
    end
    return l
end

local function GenerateDemandList(...)
    local demands = GenerateDemands(...)
    local demand_list = ParseDemandList(demands)
    return demands, demand_list
end

function ConvoOption:DemandNegotiation(data)
    local params = shallowcopy(data)
    local demand_modifiers = data.demand_modifiers
    local demand_list = data.demand_list
    -- local old_init_fn = data.on_start_negotiation
    params.on_start_negotiation = function(minigame)
        minigame.demand_list = demand_list
        if demand_modifiers then
            for i, modifier_data in ipairs(demand_modifiers) do
                if not modifier_data.resolved then
                    local modifier = minigame.opponent_negotiator:CreateModifier(modifier_data.id, modifier_data.stacks)
                    -- modifier.demand_list = demand_list
                    modifier.demand_data = modifier_data
                    if modifier.ApplyData then
                        modifier:ApplyData(modifier_data)
                    end
                end
            end
        end
        if data.on_start_negotiation then
            data.on_start_negotiation(minigame)
        end
    end
    self:Negotiation(params)
end

return {
    AddDemandModifier = AddDemandModifier,
    GenerateDemands = GenerateDemands,
    ParseDemandList = ParseDemandList,
    GenerateDemandList = GenerateDemandList,
}