local ADDITIONAL_WORK = {
    GB_LABOUR_OFFICE = {
        head_foreman = CreateClosedJob( PHASE_MASK_ALL, "Head Foreman", CHARACTER_ROLES.CONTACT ),
        rise_seller = CreateMerchantJob( PHASE_MASK_ALL, "Propaganda Master", CHARACTER_ROLES.VENDOR, "RISE_PAMPHLETEER", "RISE_PROPAGANDA_SHOP"),
    },
    PEARL_CULT_COMPOUND = {
        archbishop = CreateClosedJob( PHASE_MASK_ALL, "Archbishop", CHARACTER_ROLES.CONTACT ),
    },
    PEARL_PARTY_STORE = {
        coproprietor = CreateClosedJob( PHASE_MASK_ALL, "Co-proprietor", CHARACTER_ROLES.CONTACT ),
    }
}

for id, data in pairs(ADDITIONAL_WORK) do
    local location_data = Content.GetLocationContent(id)
    if not location_data.work then
        location_data.work = {}
    end
    for work_id, work_data in pairs(data) do
        location_data.work[work_id] = work_data
    end
    -- DBG(location_data)
end