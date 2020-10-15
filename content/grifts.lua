local GRIFTS = {
    GriftDef{ 
        id = "gained_general_support_1",
        next_id = "gained_general_support_2",
        name = "Gain {1} General Support",
        count = 200,
        perk_points = 1,
        progress = function( self, stats )
            return stats:GetStat( "gained_general_support" ), self.count
        end
    },
    GriftDef{ 
        id = "gained_general_support_2",
        next_id = "gained_general_support_3",
        name = "Gain {1} General Support",
        count = 1000,
        perk_points = 3,
        progress = function( self, stats )
            return stats:GetStat( "gained_general_support" ), self.count
        end
    },
    GriftDef{ 
        id = "gained_general_support_3",
        -- next_id = "gained_general_support_3",
        name = "Gain {1} General Support",
        count = 5000,
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
}

for i, def in pairs( GRIFTS ) do
    Content.AddGrift( def )
end
