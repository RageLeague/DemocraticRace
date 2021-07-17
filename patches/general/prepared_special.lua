local patch_id = "PREPARED_SPECIAL"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Negotiation.Card.IsPrepared

function Negotiation.Card:IsPrepared()
    return self.special_prepared or old_fn(self)
end