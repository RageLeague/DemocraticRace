loc.wealth_name = function(renown)
    return DemocracyUtil.GetWealthString(renown)
end
loc.wealth_name_list = function(list)
    local t = {}
    for i, renown in pairs( list ) do
        table.insert( t, loc.format( "{1#wealth_name}", renown ))
    end
    return loc.format( "{1#listing}", t )
end

loc.angrify = function(str)
    return str:gsub("[" .. LOC"PUNCTUATION.PERIOD" .. "]", LOC"PUNCTUATION.EXCLAMATION")
end