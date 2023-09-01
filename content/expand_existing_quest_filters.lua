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
    "ANIMAL_CONTROL",
    -- Yeah this doesn't work as you get to fight a monster
    -- "EVENT_SAL_GETS_AN_ENVELOPE",
    "PET_RESCUE",
    "PET_SELLER",

    -- Rook's events
    "EVENT_FANTASTIC_TRAINER",
    "EVENT_FOUND_A_ROBOT",
    "EVENT_LOAN_SHARK",
    "EVENT_LOAN_SHARK_REPAY",
    -- "EVENT_DEEP_BOGGER_01",
    "EVENT_FILTHY_GRAFT",
    "EVENT_FOUND_BY_LUMICYTE",
    -- This doesn't help
    -- "EVENT_HESHIAN_MEDITATION",
    "EVENT_ROOK_POINTS_A_FINGER",
    "EVENT_SCRAP_COLLECTOR",

    -- Smith's events
    "EVENT_UNATTENDED_BAG_OF_MONEY",
    "EVENT_BREAK_IT_DOWN",
    -- "EVENT_DRUNKEN_MASTER",
    -- "EVENT_MERCHANT_STARTUP",
    "EVENT_STUBBORN_OSHNU",
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
