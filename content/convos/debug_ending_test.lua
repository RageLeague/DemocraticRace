Convo("DEBUG_ENDING_TEST")
    :Loc{
        OPT_TEST = "[Debug] Generate poster",
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_TEST")
            :Fn(function(cxt)
                local card = DemocracyUtil.GeneratePropagandaPoster(nil, true)
                cxt.player.negotiator:AddCard(card)
                -- DemocracyUtil.DoEnding(cxt, "arrested")
            end)
        
    end)