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
        ):Pick(1) )
        table.arrayadd( cards, NegotiationCardCollection.AllRewardableCards(
            function(cd) return cd.rarity ~= CARD_RARITY.COMMON end
        ):Pick(1) )
        table.arrayadd( cards, NegotiationCardCollection.AllRewardableCards(
            function(cd) return CheckBits(cd.flags, card_type) and cd.rarity == CARD_RARITY.COMMON end
        ):Pick(1) )

        local player_negotiator = TheGame:GetGameState():GetPlayerAgent().negotiator
        local has_signature = player_negotiator and player_negotiator:FindCard(function(card)
            return card.advisor == signature_id
        end)

        if signature_id then
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
    AddShopItems(stock, 1, {"business_card", "business_card", "paperweight", "havarian_thesaurus"})
    -- there's not nearly enough items to make this shop work
    AddShopItems(stock, 2, {"rise_manifesto", "rise_manifesto"})
end

CARD_SHOP_DEFS.PARTY_SUPPLY_SHOP = function(stock)
    -- A common item
    AddShopItems(stock, 2, {"business_card", "hip_flask", "liquid_courage", "party_spirit", "gift_packaging", "pearl_grey"})
    -- Uncommon or higher
    AddShopItems(stock, 1, {"brain_gills", "pleasant_perfume", "mask_of_anonymity", "mask_of_intimidation", "mesmerizing_charm", "royal_relic", "curious_curio"})
end

CARD_SHOP_DEFS.BARON_HQ_SHOP_DEMOCRACY = function(stock)
    -- A report
    AddShopItems(stock, 2, {"business_card", "business_card", "spark_baron_permit", "spark_baron_permit", "work_report", "work_report", "research_report", "research_report", "executive_report"})
    -- Weapon...?
    AddShopItems(stock, 1, {"intimidating_blaster", "sequencer_negotiation", "paperweight", "robodex", "nano_lattice", "oshnu_glue", "targeting_core"})
end

local old_ad_def = CARD_SHOP_DEFS.ADMIRALTY_CLERK_SHOP

CARD_SHOP_DEFS.ADMIRALTY_CLERK_SHOP = function(stock)
    if DemocracyUtil.IsDemocracyCampaign() then
        -- General negotiation
        AddShopItems(stock, 2, {"business_card", "business_card", "paperweight", "havarian_thesaurus", "vroc_whistle_negotiation"})
        -- Admiralty special
        AddShopItems(stock, 2, {"admiralty_intel", "admiralty_intel", "admiralty_orders", "admiralty_orders", "admiralty_requisition_negotiation", "admiralty_requisition_negotiation"})
        -- Random weapon just because
        AddShopItems(stock, 1, {"lumin_grenade", "shrapnel_grenade"})
    else
        old_ad_def(stock)
    end
end
