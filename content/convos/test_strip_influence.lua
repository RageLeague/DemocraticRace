Convo("TEST_STRIP_INFLUENCE")
    :Loc{
        OPT_TEST = "[test] strip {agent}'s influence",
        DIALOG_TEST = [[
            player:
                [p] begone, bane!
            agent:
                oh noes!
        ]]
    }

    :Hub( function(cxt, who)
        if not DemocracyUtil.IsDemocracyCampaign(cxt.act_id) then
            return
        end
        
        if who then
            cxt:Opt("OPT_TEST")
                :Dialog("DIALOG_TEST")
                :Fn(function(cxt)
                    who:GainAspect("stripped_influence")
                end)
        end
    end)
