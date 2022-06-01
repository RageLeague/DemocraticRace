Convo("DEBUG_ENDING_TEST")
    :Loc{
        OPT_TEST = "[Debug] Test Convo"
    }
    :Hub(function(cxt)
        if TheGame:GetLocalSettings().DEBUG then
            local RESOLVE = {60, 90, 110, 130}
            local resolve_required = RESOLVE[GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY )] + 20
            cxt:Opt("OPT_TEST")
                :Negotiation{
                    flags = NEGOTIATION_FLAGS.WORDSMITH,
                    enemy_resolve_required = resolve_required,
                    difficulty = 5,
                }
            -- cxt:Opt("OPT_TEST")
            --     :Fn(function(cxt)
            --         local q = QuestUtil.SpawnQuest("RACE_TEST_QUEST")
            --         cxt:PlayQuestConvo(q, QUEST_CONVO_HOOK.INTRO)
            --     end)
        end
    end)
