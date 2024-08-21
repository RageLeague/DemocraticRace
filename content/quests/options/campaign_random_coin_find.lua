local function FindCoinGrafts( number, rarity )
    local owner = TheGame:GetGameState():GetPlayerAgent()
    local collection = GraftCollection.RewardableCoin(owner):Rarity(rarity)
    local grafts = collection:Generate(number)

    if grafts then
        for k,graft in ipairs(grafts) do
            TheGame:GetGameProfile():SetSeenGraft( graft.id )
        end
    end

    return grafts
end

local COIN_RARITY = {
    CARD_RARITY.RARE,
    CARD_RARITY.UNCOMMON,
    CARD_RARITY.COMMON,
}
local RATES = {
    [CARD_RARITY.RARE] = 2000,
    [CARD_RARITY.UNCOMMON] = 600,
    [CARD_RARITY.COMMON] = 150,
}

local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,

    events =
    {
        player_money_change = function(quest, old_money, new_money)
            local delta = new_money - old_money
            local current_coin = TheGame:GetGameState():GetPlayerAgent():GetAspect("graft_owner"):GetGrafts( GRAFT_TYPE.COIN )[1]
            if not current_coin then
                quest:Cancel()
                return
            end
            if current_coin and delta > 0 then
                if not quest.param.candidate_coins then
                    quest.param.candidate_coins = {}
                end

                for i, rarity in ipairs(COIN_RARITY) do
                    local coin_count = 0
                    local temp_coins = delta
                    while temp_coins > 0 do
                        temp_coins = temp_coins - math.random(1, RATES[rarity])
                        if coin_count < 2 and temp_coins >= 0 then
                            coin_count = coin_count + 1
                        end
                    end
                    local coin_grafts = FindCoinGrafts( coin_count, rarity )
                    quest.param.candidate_coins = table.merge(quest.param.candidate_coins, coin_grafts)

                    delta = delta - coin_count
                end
            end
        end,
    },
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}

QDEF:AddConvo()
    :Priority(CONVO_PRIORITY_LOWEST)
    :ConfrontState("STATE_CONFRONT", function(cxt)
            return not cxt.location:HasTag("in_transit") and cxt.quest.param.candidate_coins and #cxt.quest.param.candidate_coins > 0
        end)
        :Loc{
            DIALOG_INTRO = [[
                * You look through the coins you got.
                * Sweet! There {1*is a limited edition coin|are several unique coins}.
                * You can replace your current coin with one of them.
            ]],
            OPT_REPLACE = "Replace your {1#graft} with {2#graft}",
            DIALOG_REPLACE = [[
                player:
                    !left
                    Yes! Now my deck won't suck!
                    Hopefully.
            ]],
            OPT_SKIP = "Skip",
            DIALOG_SKIP = [[
                player:
                    !left
                    I think I'm happy with my current coin.
            ]],
            OPT_STOP = "Stop looking for random coins",
            DIALOG_STOP = [[
                * You decided that there is no further point in finding more random coins, so you stopped looking for them.
            ]],
        }
        :Fn(function(cxt)
            local current_coin = cxt.player:GetAspect("graft_owner"):GetGrafts( GRAFT_TYPE.COIN )[1]
            table.sort(cxt.quest.param.candidate_coins, function(a, b)
                return CARD_RARITY_ORDINALS[a:GetRarity()] > CARD_RARITY_ORDINALS[b:GetRarity()]
            end)
            cxt:Dialog("DIALOG_INTRO", #cxt.quest.param.candidate_coins)
            -- DBG(cxt.quest.param.candidate_coins)
            for i = 1, math.min(#cxt.quest.param.candidate_coins, 5) do
                local coin = cxt.quest.param.candidate_coins[i]
                cxt:Opt("OPT_REPLACE", current_coin, coin)
                    :PreIcon(global_images.card_rarity_icons[coin:GetRarity()])
                    :Fn(function(cxt)
                        cxt.player.graft_owner:ReplaceGraft( current_coin, coin )
                    end)
                    :Dialog("DIALOG_REPLACE")
                    :DoneConvo()
            end
            cxt:Opt("OPT_STOP")
                :Dialog("DIALOG_STOP")
                :CancelQuest()
                :DoneConvo()
            cxt:Opt("OPT_SKIP")
                :MakeUnder()
                :Dialog("DIALOG_SKIP")
                :DoneConvo()
            cxt.quest.param.candidate_coins = nil
        end)
