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
        OPT_HIRE = "Hire {agent} as a bodyguard",
        OPT_HIRE_TT = "{agent} will become a party member and will help you in negotiation and combat.",

        DIALOG_HIRE = [[
            player:
                Want to earn some quick cash? Just follow me and protect me.
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
        if who and DemocracyUtil.RandomBystanderCondition(who) and TheGame:GetGameState():GetCaravan():HasHireling() == false and TheGame:GetGameState():IsHiringAvailable() then
            local cost = 60 + 30 * who:GetCombatStrength()
            cxt:Opt("OPT_HIRE")
                :PostText("OPT_HIRE_TT")
                :IsHubOption(true)
                :ReqRelationship( RELATIONSHIP.DISLIKED )
                :PreIcon( global_images.hire )
                -- :ReqCondition( not bribe_params.disable, bribe_params.disable_reason )
                :Dialog("DIALOG_HIRE")
                :DeliverMoney( cost )
                :Fn(function() 
                    who:Recruit( PARTY_MEMBER_TYPE.HIRED )
                    -- who:AddAspectStacks("bribed", 2)
                end)
        
        end
    end)