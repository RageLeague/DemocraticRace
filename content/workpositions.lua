local ADDITIONAL_WORK = {
    GB_LABOUR_OFFICE = {
        head_foreman = CreateClosedJob( PHASE_MASK_ALL, "Head Foreman", CHARACTER_ROLES.CONTACT ),
        rise_seller = CreateMerchantJob( DAY_PHASE.DAY, "Propaganda Master", CHARACTER_ROLES.VENDOR, "RISE_PAMPHLETEER", "RISE_PROPAGANDA_SHOP"),
    },
    PEARL_CULT_COMPOUND = {
        archbishop = CreateClosedJob( PHASE_MASK_ALL, "Archbishop", CHARACTER_ROLES.CONTACT ),
        priest_seller = CreateMerchantJob( DAY_PHASE.DAY, "Head Priest", CHARACTER_ROLES.VENDOR, "PRIEST", "CULT_SHOP_DEMOCRACY"),
    },
    PEARL_PARTY_STORE = {
        coproprietor = CreateClosedJob( PHASE_MASK_ALL, "Co-proprietor", CHARACTER_ROLES.CONTACT ),
        proprietor_democracy = CreateMerchantJob( PHASE_MASK_ALL, "Proprietor", CHARACTER_ROLES.PROPRIETOR, "POOR_MERCHANT", "PARTY_SUPPLY_SHOP"),
    },
    GB_BARON_HQ = {
        baron_seller = CreateMerchantJob( DAY_PHASE.DAY, "Baron Seller", CHARACTER_ROLES.VENDOR, "SPARK_BARON_TASKMASTER", "BARON_HQ_SHOP_DEMOCRACY"),
    },
}

local DISABLED_WORK = {
    PEARL_PARTY_STORE = {
        "proprietor",
    },
}

for id, data in pairs(ADDITIONAL_WORK) do
    local location_data = Content.GetLocationContent(id)
    if not location_data.work then
        location_data.work = {}
    end
    for work_id, work_data in pairs(data) do
        work_data.is_democracy_job = true
        location_data.work[work_id] = work_data
    end
    -- DBG(location_data)
end

for id, data in pairs(ADDITIONAL_WORK) do
    local location_data = Content.GetLocationContent(id)
    if not location_data.work then
        location_data.work = {}
    end
    for i, work_id in ipairs(data) do

        if location_data.work[work_id] then
            location_data.work[work_id].disable_for_democracy = true
        end
    end
    -- DBG(location_data)
end
