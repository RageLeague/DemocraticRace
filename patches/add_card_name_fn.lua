local patch_id = "ADD_CARD_NAME_FN"
if not rawget(_G, patch_id) then
    rawset(_G, patch_id, true)
    print("Loaded patch:"..patch_id)
    -- print(Negotiation.Negotiator)
    local old_fn = CardEngine.Card.GetName
    CardEngine.Card.GetName = function(self)
        -- print("hijack success")
        if self.def.name_fn then
            -- print("lol")
            return self.def.name_fn(self, old_fn(self))
        end
        return old_fn(self)
    end
    CardEngine.Card.GetTitle = CardEngine.Card.GetName
end