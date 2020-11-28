local function MultiStat(vals, stats)
    local res = 0
    for i, id in ipairs(vals) do
        if stats:GetStat(id) and stats:GetStat(id) > 0 then
            res = res + 1
        end
    end
    return res
end
local GRIFTS = {
    GriftDef{ 
        id = "gained_general_support_1",
        next_id = "gained_general_support_2",
        name = "Gain {1} General Support",
        count = 100,
        perk_points = 1,
        progress = function( self, stats )
            return stats:GetStat( "gained_general_support" ), self.count
        end
    },
    GriftDef{ 
        id = "gained_general_support_2",
        next_id = "gained_general_support_3",
        name = "Gain {1} General Support",
        count = 750,
        perk_points = 3,
        progress = function( self, stats )
            return stats:GetStat( "gained_general_support" ), self.count
        end
    },
    GriftDef{ 
        id = "gained_general_support_3",
        -- next_id = "gained_general_support_3",
        name = "Gain {1} General Support",
        count = 3000,
        perk_points = 5,
        progress = function( self, stats )
            return stats:GetStat( "gained_general_support" ), self.count
        end
    },

    GriftDef{ 
        id = "complete_request_quest_1",
        next_id = "complete_request_quest_2",
        name = "Complete {1} Request {1*Quest|Quests}",
        count = 1,
        perk_points = 1,
        progress = function( self, stats )
            return stats:GetStat( "completed_request_quest" ), self.count
        end
    },
    GriftDef{ 
        id = "complete_request_quest_2",
        next_id = "complete_request_quest_3",
        name = "Complete {1} Request {1*Quest|Quests}",
        count = 5,
        perk_points = 3,
        progress = function( self, stats )
            return stats:GetStat( "completed_request_quest" ), self.count
        end
    },
    GriftDef{ 
        id = "complete_request_quest_3",
        -- next_id = "complete_request_quest_2",
        name = "Complete {1} Request {1*Quest|Quests}",
        count = 20,
        perk_points = 5,
        progress = function( self, stats )
            return stats:GetStat( "completed_request_quest" ), self.count
        end
    },
    GriftDef{ 
        id = "democracy_day_1",
        next_id = "democracy_day_2",
        name = "Survive Day 1 In The Democratic Race",
        perk_points = 1,
        progress = function( self, stats )
            return MultiStat({"democracy_day_1"}, stats), 1
        end
    },
    GriftDef{ 
        id = "democracy_day_2",
        -- next_id = "complete_request_quest_2",
        name = "Survive Day 2 In The Democratic Race(End of Alpha)",
        perk_points = 1,
        progress = function( self, stats )
            return MultiStat({"democracy_day_1", "democracy_day_2"}, stats), 2
        end
    },
}

for i, def in pairs( GRIFTS ) do
    Content.AddGrift( def )
end
