local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}
:AddConvo()
    :Loc{
        OPT_BRIBE = "Pay {agent} to shill for you",
        OPT_BRIBE_TT = "{agent} will more likely to participate in your next rally quest, and will help you/make the negotiation in that quest easier.",

        DIALOG_BRIBE = [[
            player:
                Want to earn some quick cash? Just come to my next rally and show your support for me.
            agent:
                !take
            {disliked?
                I'm just in for the cash.
            }
            {not disliked?
                Sure, sounds like a good deal to me.
            }
        ]],
    }
    :Hub(function(cxt, who)
        if who and DemocracyUtil.RandomBystanderCondition(who) then
            local cost = math.max(30, 15 * who:GetRenown())
            if not who:HasAspect( "bribed" ) then
                cxt:Opt("OPT_BRIBE")
                    :PostText("OPT_BRIBE_TT")
                    :IsHubOption(true)
                    :ReqRelationship( RELATIONSHIP.DISLIKED )
                    -- :ReqCondition( not bribe_params.disable, bribe_params.disable_reason )
                    :Dialog("DIALOG_BRIBE")
                    :DeliverMoney( cost )
                    :Fn(function() 
                        who:AddAspectStacks("bribed", 2)
                    end)
            end
        end
    end)