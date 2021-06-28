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

        OPT_QUERY_STANCE = "[Debug] Query Stance",
        OPT_ASK_ABOUT_STANCE = "Get stance for {1#pol_issue}",
        DIALOG_ASK_ABOUT_STANCE = [[
            * {agent}'s stance on {1#pol_issue} is {2#pol_stance}.
        ]],
    }
    :Hub(function(cxt)
        -- cxt:BasicNegotiation("TALK")
        -- cxt:Opt("OPT_QUERY_STANCE")
        --     :LoopingFn(function(cxt)
        --         for id, issue in pairs(DemocracyConstants.issue_data) do
        --             cxt:Opt("OPT_ASK_ABOUT_STANCE", issue)
        --                 :Dialog("DIALOG_ASK_ABOUT_STANCE", issue, issue:GetAgentStance(cxt:GetAgent()))
        --         end
        --         StateGraphUtil.AddBackButton(cxt)
        --     end)
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