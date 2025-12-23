Convo("DEBUG_ENDING_TEST")
    :Loc{
        OPT_TEST = "[Debug] Test Convo",
        DIALOG_TEST = [[
            player:
                Something interesting is going on here.
                !<unlock_agent_info;ADVISOR_MANIPULATE;lore_husband>
        ]],
        OPT_SET_OPINION = "Set opinion of SECURITY to {1}",
    }
    :Hub(function(cxt)
        if TheGame:GetLocalSettings().DEBUG then
            local RESOLVE = {60, 90, 110, 130}
            local resolve_required = DemocracyUtil.CalculateBossScale(RESOLVE) + 20
            -- cxt:Opt("OPT_TEST")
            --     :Negotiation{
            --         flags = NEGOTIATION_FLAGS.WORDSMITH,
            --         enemy_resolve_required = resolve_required,
            --         difficulty = 5,
            --     }
            cxt:Opt("OPT_TEST")
                :Fn(function(cxt)
                    for i = -2, 2 do
                        cxt:Opt("OPT_SET_OPINION")
                            :UpdatePoliticalStance("SECURITY", i)
                    end
                end)
        end
    end)
