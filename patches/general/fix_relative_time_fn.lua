local patch_id = "FIX_RELATIVE_TIME_FN"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

loc.relative_time = function( n )
    local phase = TheGame:GetGameState() and TheGame:GetGameState():GetDayPhase() or DAY_PHASE.NIGHT
    if n == 0 then
        return LOC"LOCMACROS.RELTIME.NOW"
    elseif n == 1 then
        return phase == DAY_PHASE.NIGHT and LOC"LOCMACROS.RELTIME.IN_MORNING" or LOC"LOCMACROS.RELTIME.TONIGHT"
    elseif n == 2 then
        return phase == DAY_PHASE.NIGHT and LOC"LOCMACROS.RELTIME.TOMORROW_NIGHT" or LOC"LOCMACROS.RELTIME.TOMORROW_MORNING"
    elseif n == 3 and phase == DAY_PHASE.DAY then
        return LOC"LOCMACROS.RELTIME.TOMORROW_NIGHT"
    end
    if phase == DAY_PHASE.NIGHT then
        n = n + 1
    end
    return loc.format( LOC"LOCMACROS.RELTIME.IN_DAYS", math.floor( n/2 ) )
end
