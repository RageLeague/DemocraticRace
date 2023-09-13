local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,

    locations =
    {
        GB_CAFFY = "CAFETERIA",
        MURDERBAY_NOODLE_SHOP = "HEARTY_RESTAURANT",
        GROG_N_DOG = "BAR",
        SPREE_INN = "BAR",
        GB_NEUTRAL_BAR = "BAR",
        MOREEF_BAR = "BAR",
        PEARL_FANCY_EATS = "FANCY_RESTAURANT",
        MURDER_BAY_CHEMIST = "HEALER",
    },

    heal_info =
    {
        CAFETERIA = {
            cost = 20,
            heal = 10,
            cards = { "gassy" },
            tags = { "food", "cafeteria" },
            not_bloated = true,
        },
        BAR = {
            cost = 40,
            heal = 30,
            cards = { "gassy", "bloated" },
            -- can_share = true,
            tags = { "food", "bar" },
            not_bloated = true,
        },
        HEARTY_RESTAURANT = {
            cost = 40,
            heal = 20,
            resolve = 5,
            cards = { "gassy", "bloated" },
            can_share = true,
            tags = { "food", "restaurant" },
            not_bloated = true,
        },
        FANCY_RESTAURANT = {
            cost = 100,
            heal = 30,
            resolve = 15,
            cards = {},
            can_share = true,
            tags = { "food", "restaurant", "fancy" },
            not_bloated = true,
        },
        HEALER = {
            cost = 30,
            heal = 30,
            cards = { "dem_lightheaded", "drunk" },
            tags = { "healer" },
        },
    },

    events =
    {
        base_difficulty_change = function(quest, new_diff, old_diff)
            quest:SetRank(new_diff)
        end,
    },
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}

QDEF:AddConvo()
    :Loc{
        OPT_SHARE_MEAL = "Share a meal with {agent}",
        DIALOG_SHARE_MEAL = [[
            * You order food for you both.
            * {agent} greedily accepts.
            player:
                !cheers
            agent:
                !cheers
                %shared_a_meal
        ]],

        OPT_HEAL_CAFETERIA = "Buy some rations",
        OPT_HEAL_BAR = "Buy a meal",
        OPT_HEAL_HEARTY_RESTAURANT = "Buy a hearty meal",
        OPT_HEAL_FANCY_RESTAURANT = "Buy a fancy meal",
        OPT_HEAL_HEALER = "Ask for healing",
    }
    :Hub(function(cxt, who)
        if not who then
            return
        end
        local quest_def = cxt.quest:GetQuestDef()
        local loc_type = cxt.location and cxt.location:GetContentID() and quest_def.locations[cxt.location:GetContentID()]
        if not loc_type then
            return
        end
        if not cxt.location:GetProprietor() then
            return
        end
        local eat_effects = {
            cards = shallowcopy(quest_def.heal_info[loc_type].cards),
            health_gain = quest_def.heal_info[loc_type].heal,
            resolve_gain = quest_def.heal_info[loc_type].resolve,
        }
        TheGame:GetEvents():BroadcastEvent( "do_eat", eat_effects )
        local function DoEat(self, cost_multiplier)
            cost_multiplier = cost_multiplier or 1
            local cost = quest_def.heal_info[loc_type].cost
            self:PostText("OPT_FORCE_GAIN_CARDS", eat_effects.cards )
            for i, card_id in ipairs( eat_effects.cards ) do
                self:PostCard( card_id, true )
            end
            if eat_effects.resolve_gain and eat_effects.resolve_gain > 0 then
                self:DeltaResolve( eat_effects.resolve_gain )
            end
            if eat_effects.health_gain and eat_effects.health_gain > 0 then
                self:DeltaHealth( eat_effects.health_gain, true )
            end
            if cost and (cost * cost_multiplier) > 0 then
                self:DeliverMoney( cost * cost_multiplier, {is_shop = true}, self.hub.location:GetProprietor() )
            end

            if quest_def.heal_info[loc_type].not_bloated then
                local num_bloat = TheGame:GetGameState():GetPlayerAgent().battler:GetCardCount("bloated")
                self:ReqCondition(num_bloat < 3, "REQ_TOO_FULL", "bloated")
            end

            self:Fn( function( cxt )
                if #eat_effects.cards > 0 then
                    cxt:ForceTakeCards( eat_effects.cards )
                end
                TheGame:GetEvents():BroadcastEvent( "did_eat", eat_effects )
            end )
        end
        if AgentUtil.IsProprietor(who) then
            local opt = cxt:Opt("OPT_HEAL_" .. loc_type)
                :Quip( who, "request_healing", table.unpack(quest_def.heal_info[loc_type].tags))
            DoEat(opt, 1)
            opt:Quip( who, "request_healing_pst", table.unpack(quest_def.heal_info[loc_type].tags))
        elseif who:GetBrain():IsPatronizing() then
            local rel = who:GetRelationship()
            if rel == RELATIONSHIP.NEUTRAL or rel == RELATIONSHIP.DISLIKED then
                local opt = cxt:Opt("OPT_SHARE_MEAL")
                    :RequireFreeTimeAction(1)
                    :Dialog("DIALOG_SHARE_MEAL")
                DoEat(opt, 2)
                opt:ReceiveOpinion( OPINION.SHARED_A_MEAL )
                opt:Fn(function(cxt)
                    if who.health then
                        who.health:Delta(eat_effects.health_gain)
                    end
                end)
            end
        end
    end)
