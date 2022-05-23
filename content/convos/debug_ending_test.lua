Convo("DEBUG_ENDING_TEST")
    :Loc{
        OPT_TEST = "[Debug] Test Convo"
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_TEST")
            :Negotiation{
                flags = NEGOTIATION_FLAGS.WORDSMITH,
            }
        -- cxt:Opt("OPT_TEST")
        --     :Fn(function(cxt)
        --         local q = QuestUtil.SpawnQuest("RACE_TEST_QUEST")
        --         cxt:PlayQuestConvo(q, QUEST_CONVO_HOOK.INTRO)
        --     end)

    end)
