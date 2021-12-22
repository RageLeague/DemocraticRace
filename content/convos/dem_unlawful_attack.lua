Convo("DEM_UNLAWFUL_ATTACK")
    :Loc{
        OPT_ATTACK = "Convince {agent} to attack someone...",
        TT_ATTACK = "The target can potentially die, or they will be left in a bad shape and can't interfere with you for a while.",
        DIALOG_ATTACK = [[
            player:
                Can you attack someone for me?
            agent:
                Who do you plan to attack?
        ]],

        REQ_NO_TARGETS = "There are no targets.",

        OPT_CHOOSE = "Investigate {1#agent}",

        DIALOG_BACK = [[
            player:
                Never mind.
        ]],
    }
    :Hub(function(cxt, who)
        if not DemocracyUtil.IsDemocracyCampaign(cxt.act_id) then
            return
        end

        if who and who:GetFaction():IsUnlawful() and not AgentUtil.HasPlotArmour(who) then
        end
    end)
