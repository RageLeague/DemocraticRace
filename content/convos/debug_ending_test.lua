Convo("DEBUG_ENDING_TEST")
    :Loc{
        OPT_TEST = "[Debug] Test ending slides",
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_TEST")
            :Fn(function(cxt)
                DemocracyUtil.DoEnding(cxt, "arrested")
            end)
        
    end)