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
    "THE_TOTEM", -- TODO: Change the text to be less Sal-centric
    "WANDERING_CHEF",
    "ANIMAL_CONTROL", -- TODO: Rework this to account for mech pets, as well as tie in with certain political stances
    "PET_RESCUE",
    "PET_SELLER",

    -- Rook's events
    "EVENT_FANTASTIC_TRAINER",
    "EVENT_FOUND_A_ROBOT",
    "EVENT_FILTHY_GRAFT",
    "EVENT_FOUND_BY_LUMICYTE", -- TODO: Add political stances to some options
    "EVENT_ROOK_POINTS_A_FINGER", -- TODO: Add political stances to some options
    "EVENT_SCRAP_COLLECTOR",

    -- Smith's events
    "EVENT_UNATTENDED_BAG_OF_MONEY", -- TODO: Add political stances to some options
    "EVENT_BREAK_IT_DOWN", -- TODO: Add political stances to some options
    "EVENT_STUBBORN_OSHNU", -- TODO: Add political stances to some options
}

for i, id in ipairs(QUEST_IDS) do
    local ok, message = AppendActFilterToQuest(id, DemocracyUtil.DemocracyActFilter)
    -- if ok then
    --     print("Successfully replace " .. id .. ": " .. message)
    -- else
    --     print("Fail to replace " .. id .. ": " .. message)
    -- end
end

local qdef = Content.GetQuestDef( "EVENT_FIRST_METTLE" )

local old_cond = qdef.precondition

qdef.precondition = function(...)
    if DemocracyUtil.IsDemocracyCampaign() then
        return false, "Democracy campaign does not spawn first mettle quest"
    end
    return old_cond(...)
end
