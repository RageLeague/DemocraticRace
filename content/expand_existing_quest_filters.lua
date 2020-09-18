-- This file dubiously allow existing events to show up in the new quest.
-- Only allow events that can be resolved without combat to show up. 
-- We only want to fight if absolutely necessary.

-- Don't add events that you need to take stance on. They should be rewritten so that you
-- will take stances if you picked certain options.
local QUEST_IDS = {
    -- Sal's events
    "EVENT_DODGY_SCAVENGER",
    "FORAGING_CHEMIST",
    "MORTAL_COIL",
    "REVENGE_KILLED_FRIEND",
    "THE_TOTEM",
    "WANDERING_CHEF",

    -- Rook's events
    "EVENT_FANTASTIC_TRAINER",
    "EVENT_FOUND_A_ROBOT",
    "EVENT_LOAN_SHARK",
    "EVENT_LOAN_SHARK_REPAY",
}