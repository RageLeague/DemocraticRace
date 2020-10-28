Convo("IMPROVE_RELATION_DEM")
    :Priority(CONVO_PRIORITY_HIGH)
    :Loc{
        OPT_BUY_DRINK_FOR = "Share a drink with {agent}",
        REQ_TOO_SOON = "You already bought {agent} a drink",
        DIALOG_DRINKS = [[
            * You order drinks for you both.
            * {agent} greedily accepts.
            player:
                !cheers
            agent:
                !cheers
                %had_a_drink
        ]],

        OPT_IMPROVE_RELATIONSHIP = "Try to help your friend (grants {1#graft} if successful)",

        DIALOG_IMPROVE_RELATIONSHIP = [[
            player:
                Anything I can do to help you?
        ]],

        DIALOG_IMPROVE_RELATIONSHIP_HAS_DEMANDS = [[
            agent:
                So, have you decided yet?
        ]],

        DIALOG_IMPROVE_RELATIONSHIP_DEMANDS = [[
            agent:
                !thought
                Hmm...
                If you can {1#demand_list}, then I'll be extremely grateful!
        ]],

        DIALOG_IMPROVE_RELATIONSHIP_PST = [[
            agent:
                !happy
                Thank you, {player}.
                I am grateful for what you did.
                If you need anything, just ask!
        ]],

        DIALOG_BACK = [[
            player:
                I need to think about this.
        ]],

        OPT_CHANGE_DEMAND = "Ask {agent} to change {agent.hisher} conditions",
        TT_CHANGE_DEMAND = "Give up on the current demands and replace them with new ones, in case you can't comply.",

        REQ_ONCE_PER_DAY = "You can only do this once per day",

        DIALOG_CHANGE_DEMAND = [[
            player:
                I don't know if I can help with that.
                Is there anything else I can do?
            agent:
                There's plenty you can do to help.
        ]],
    }
    :Hub(function(cxt, who)
        if who and DemocracyUtil.IsDemocracyCampaign(cxt.act_id) then
            local rel = cxt:GetAgent():GetRelationship()
            if cxt.location and cxt.location:HasTag("tavern") 
                -- can only drink when there's a bartender.
                and cxt.location:GetProprietor()
                and cxt:GetAgent():GetBrain():IsPatronizing() 
                and not AgentUtil.HasPlotArmour(cxt:GetAgent()) then
                
                if rel == RELATIONSHIP.NEUTRAL or rel == RELATIONSHIP.DISLIKED then
                    cxt:Opt("OPT_BUY_DRINK_FOR")
                        :RequireFreeTimeAction(1)
                        :Dialog("DIALOG_DRINKS")
                        :ReceiveOpinion( OPINION.BOUGHT_DRINK )
                        :Fn(function() TheGame:GetGameProfile():SetDrankWith( cxt:GetAgent():GetUniqueID() ) end)
                        :DoDrink( BAR_DRINK_COST * 2, DRINK_RESTORE_RESOLVE_AMOUNT, cxt:GetAgent() )
                end
            end
            
            if rel == RELATIONSHIP.LIKED and not AgentUtil.HasPlotArmour(cxt:GetAgent()) then
                cxt:Opt("OPT_IMPROVE_RELATIONSHIP",  cxt:GetAgent():GetSocialGraft(RELATIONSHIP.LOVED))
                    :PreIcon( global_images.giving )
                    :Dialog("DIALOG_IMPROVE_RELATIONSHIP")
                    :LoopingFn(function(cxt)
                        if not who:HasMemory("IMPROVE_RELATIONSHIP_DEMANDS") then
                            local LOVED_GIFT_COST = 70 * math.max(2, math.max(cxt:GetAgent():GetRenown(), cxt:GetAgent():GetCombatStrength()))
                            local demands = DemocracyUtil.GenerateDemands(LOVED_GIFT_COST, who, nil, {
                                blocked_demands = {"demand_favor"}
                            })
                            local demand_list = DemocracyUtil.ParseDemandList(demands)
                            who:Remember("IMPROVE_RELATIONSHIP_DEMANDS", demands)
                            who:Remember("IMPROVE_RELATIONSHIP_DEMAND_LIST", demand_list)

                            cxt:Dialog("DIALOG_IMPROVE_RELATIONSHIP_DEMANDS", demand_list)
                        else
                            if cxt:FirstLoop() then
                                cxt:Dialog("DIALOG_IMPROVE_RELATIONSHIP_HAS_DEMANDS")
                            end
                        end
                        local demands = who:HasMemory("IMPROVE_RELATIONSHIP_DEMANDS")
                        local demand_list = who:HasMemory("IMPROVE_RELATIONSHIP_DEMAND_LIST")
                        -- if cxt:FirstLoop() then
                            
                        -- end

                        local payed_all = DemocracyUtil.AddDemandConvo(cxt, demand_list, demands, false)
                        if payed_all then
                            cxt:Dialog("DIALOG_IMPROVE_RELATIONSHIP_PST")
                            who:OpinionEvent(OPINION.DEEPENED_RELATIONSHIP)
                            who:Forget("IMPROVE_RELATIONSHIP_DEMANDS")
                            who:Forget("IMPROVE_RELATIONSHIP_DEMAND_LIST")
                            StateGraphUtil.AddEndOption(cxt)
                        else
                            cxt:Opt("OPT_CHANGE_DEMAND")
                                :PostText("TT_CHANGE_DEMAND")
                                :ReqCondition(not who:HasMemoryFromToday("IMPROVE_RELATIONSHIP_RESHUFFLE"), "REQ_ONCE_PER_DAY")
                                :Dialog("DIALOG_CHANGE_DEMAND")
                                :Fn(function(cxt)
                                    who:Forget("IMPROVE_RELATIONSHIP_DEMANDS")
                                    who:Forget("IMPROVE_RELATIONSHIP_DEMAND_LIST")
                                    who:Remember("IMPROVE_RELATIONSHIP_RESHUFFLE")
                                end)
                            StateGraphUtil.AddBackButton(cxt)
                                :Dialog("DIALOG_BACK")
                        end
                    end)
                    -- :DeliverMoney(LOVED_GIFT_COST, {no_scale = true})
                    -- :Quip( cxt:GetAgent(), "gifted" )
                    -- :Quip( cxt:GetAgent(), "gift_received" )
                    -- :ReceiveOpinion( OPINION.DEEPENED_RELATIONSHIP )
            end
        end
    end)
