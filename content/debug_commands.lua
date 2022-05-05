-- Example: dem_test_day(2)
function dem_test_day(day)
    local DECKS = require "content/quests/experiments/sal_day_1_boss_decks"
    local deck_idx = math.random(#DECKS)
    local deck = DECKS[deck_idx]
    local qdef = Content.GetQuestDef( "DEMOCRATIC_RACE_MAIN" )
    qdef:IsolatedTest({start_on_day = day}, 3, deck, 0)
end
