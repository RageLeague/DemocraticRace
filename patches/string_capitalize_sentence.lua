local patch_id = "STRING_CAPITALIZE_SENTENCE"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

function string.capitalize_sentence(str)
    return string.upper(str:sub(1,1)) .. str:sub(2)
end