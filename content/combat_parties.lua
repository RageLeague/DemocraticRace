local PT_RANGES = {
    [1] = {1, 2},
    [2] = {3, 4},
    [3] = {5, 6},
    [4] = {7, 8},
    [5] = {9, 12},
}

local COUNT_RANGES = {
    [1] = {1,2},
    [2] = {2,3},
    [3] = {2,3},
    [4] = {3,4},
    [5] = {4,4},
}


local function TeamExists(found_teams, team)
    for k,v in ipairs(found_teams) do
        if shallowcompare(team, v) then
            return true
        end
    end

    return false
end

local function CheckTeam(team, count_min, count_max, pt_min, pt_max)

    if #team > count_max or #team < count_min then
        return
    end
    local pts = 0
    for k,v in ipairs(team) do
        local def = Content.GetCharacterDef(v)
        pts = pts + def.combat_strength

    end

    if pts < pt_min or pts > pt_max then
        return false
    end

    return true
end


local function FindValidTeams(defs, count_min, count_max, pt_min, pt_max, found_teams, filter, diff, team, is_backup)

    team = team or {}
    table.sort(team)
    if #team > 0 and CheckTeam(team, count_min, count_max, pt_min, pt_max) and not TeamExists(found_teams, team) and (filter == nil or filter(team, diff, is_backup)) then
        table.insert(found_teams, team)
    end

    if #team + 1 <= count_max then
        for k,def in ipairs(defs) do
            local new_team = shallowcopy(team)
            table.insert(new_team, def)
            FindValidTeams(defs, count_min, count_max, pt_min, pt_max, found_teams, filter, diff, new_team, is_backup)
        end
    end
end

local function IsDefSentient( def )
    return def.species == nil
end



local function PickTeams(defs, filter, difficulty, leader)

    difficulty = math.max(1, difficulty)

    local pt_min, pt_max = table.unpack( PT_RANGES[math.min(#PT_RANGES, difficulty)])
    local count_min, count_max  = table.unpack ( COUNT_RANGES[math.min(#COUNT_RANGES, difficulty)] )

    if leader then
        pt_min = math.max(0, pt_min - leader:GetCombatStrength())
        pt_max = math.max(0, pt_max - leader:GetCombatStrength())
        count_min = math.max(0, count_min -1)
        count_max = math.max(0, count_max -1)
    end

    local found_teams = {}


    FindValidTeams(defs, count_min, count_max, pt_min, pt_max, found_teams, filter, difficulty, nil, leader ~= nil)
    for k,v in pairs(found_teams) do
        table.sort(v, function(a,b)
            if IsDefSentient(Content.GetCharacterDef(a)) == IsDefSentient(Content.GetCharacterDef(b)) then
                return Content.GetCharacterDef(a).renown > Content.GetCharacterDef(b).renown
            else
                return IsDefSentient(Content.GetCharacterDef(a))
            end
        end )
    end
    return found_teams
end

local laborers_defs = {"RISE_REBEL", "RISE_RADICAL", "RISE_PAMPHLETEER", "LABORER", "HEAVY_LABORER"}
local laborers_filter = function(team, diff)
    local counts = {}
    for k,v in pairs(team) do
        counts[v] = counts[v] and counts[v] + 1 or 1
    end
    if (counts["RISE_REBEL"] or 0) + (counts["RISE_RADICAL"] or 0) + (counts["RISE_PAMPHLETEER"] or 0) > #team / 2 then
        return false
    end
    return true
end

local GENERATORS =
{
    DEMOCRACY_LABORERS = function(difficulty_level)
        local candidates = PickTeams(laborers_defs, laborers_filter, difficulty_level)
        if #candidates > 0 then
            return table.arraypick(candidates)
        end
        return {"BOGGER_CULTIVATOR"}
    end,
}

for id, generator in pairs(GENERATORS) do
    AddCombatPartyDef(id, generator)
end