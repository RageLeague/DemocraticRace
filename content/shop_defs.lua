local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS

-- Generate a shop that sells 6 negotiation cards. At least 3 common(one guaranteed to be of
-- chosen type), 1 uncommon, and 1 uncommon or up of the chosen type
local function GenerateCardShop(card_type, signature_id)
    return function(stock) 
        local NUM_STOCK = 6
        local cards = {}
        table.arrayadd( cards, NegotiationCardCollection.AllRewardableCards(
            function(cd) return cd.rarity == CARD_RARITY.COMMON end
        ):Pick(2) )
        table.arrayadd( cards, NegotiationCardCollection.AllRewardableCards(
            function(cd) return cd.rarity == CARD_RARITY.UNCOMMON end
        ):Pick(1) )
        table.arrayadd( cards, NegotiationCardCollection.AllRewardableCards(
            function(cd) return CheckBits(cd.flags, card_type) and cd.rarity == CARD_RARITY.COMMON end
        ):Pick(1) )
        
        local player_negotiator = TheGame:GetGameState():GetPlayerAgent().negotiator
        local has_signature = player_negotiator and player_negotiator:FindCard(function(card)
            return card.advisor == signature_id
        end)

        if signature_id and not has_signature and math.random() < 0.5 then
            table.arrayadd( cards, NegotiationCardCollection(
                function(cd) 
                    return cd.advisor == signature_id and not CheckBits(cd.flags, CARD_FLAGS.UPGRADED)
                end
            ):Pick(1) )
        else
            table.arrayadd( cards, NegotiationCardCollection.AllRewardableCards(
                function(cd) return CheckBits(cd.flags, card_type) and cd.rarity ~= CARD_RARITY.COMMON end
            ):Pick(1) )
        end
        local remaining_num = math.max(0, NUM_STOCK - #cards)
        if remaining_num > 0 then
            table.arrayadd( cards, NegotiationCardCollection.AllRewardableCards(
                function(cd)
                    for k,v in pairs(cards) do
                        if v.id == cd.id then
                            return false
                        end
                    end
                    return true
                end
            ):Pick(remaining_num) )
        end
    
        for i, card in ipairs(cards) do
            AddCardToShop(stock, card.id)            
        end
    end
end

CARD_SHOP_DEFS.RACE_DIPLOMACY_CARD_SHOP = GenerateCardShop(CARD_FLAGS.DIPLOMACY, "ADVISOR_DIPLOMACY")
CARD_SHOP_DEFS.RACE_MANIPULATE_CARD_SHOP = GenerateCardShop(CARD_FLAGS.MANIPULATE, "ADVISOR_MANIPULATE")
CARD_SHOP_DEFS.RACE_HOSTILE_CARD_SHOP = GenerateCardShop(CARD_FLAGS.HOSTILE, "ADVISOR_HOSTILE")

CARD_SHOP_DEFS.RISE_PROPAGANDA_SHOP = function(stock)
    -- there's not nearly enough items to make this shop work
    AddShopItems(stock, 2, {"rise_manifesto", "rise_manifesto"})
end