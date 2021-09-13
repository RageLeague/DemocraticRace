Convo("DEBUG_ENDING_TEST")
    :Loc{
        OPT_TEST = "[Debug] Get Business card"
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_TEST")
            :GainCards{"business_card"}
    end)