Convo("DEBUG_ENDING_TEST")
    :Loc{
        OPT_TEST = "[Debug] Generate poster",

        OPT_TALK = "[Debug] Negotiate for no reason",
        DIALOG_TALK = [[
            agent:
                I'm lonely.
                Cheer me up.
        ]],
        DIALOG_TALK_SUCCESS = [[
            agent:
                Thanks.
                I'm cheered up now.
        ]],
        DIALOG_TALK_FAILURE = [[
            agent:
                Oh no, it didn't work.
        ]],
    }
    :Hub(function(cxt)
        cxt:BasicNegotiation("TALK")
            -- :SetQuestMark(cxt.quest)
            -- :OnSuccess()
            --     :CompleteQuest()
            --     :DoneConvo()
        -- cxt:Opt("OPT_TEST")
        --     :Fn(function(cxt)
        --         local card = DemocracyUtil.GeneratePropagandaPoster(nil, false)
        --         cxt.player.negotiator:AddCard(card)
        --         -- DemocracyUtil.DoEnding(cxt, "arrested")
        --     end)
        
    end)