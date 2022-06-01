-- Example: dem_test_day(2)

local DECK_BY_DAY =
{
    [2] = "DEMOCRATICRACE:content/experiment_decks/experiments_day_1",
    [3] = "DEMOCRATICRACE:content/experiment_decks/experiments_day_2",
    [4] = "DEMOCRATICRACE:content/experiment_decks/experiments_day_3",
}
function dem_test_day(day)
    local DECK_ID = DECK_BY_DAY[day] or "DEMOCRATICRACE:content/experiment_decks/experiments_day_1"
    local DECKS = require (DECK_ID)
    local deck_idx = math.random(#DECKS)
    local deck = DECKS[deck_idx]
    local qdef = Content.GetQuestDef( "DEMOCRATIC_RACE_MAIN" )
    qdef:IsolatedTest({start_on_day = day}, 3, deck, 0)
end

function dem_test_request(agent)
    return DemocracyUtil.SpawnRequestQuest(agent, nil, {debug_test = true})
end
