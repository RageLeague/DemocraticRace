Convo("DEM_LUMIN_WINE")
    :Priority(CONVO_PRIORITY_HIGH)
    :Quips{
        {
            tags = "buy_wine",
            [[
                player:
                    !intrigue
                    Got any more of that blue for me?
                agent:
                    !give
                    Haven't run out yet. Have a bottle.
            ]],
            [[
                player:
                    !happy
                    How's another bottle for me? I'll pay!
                agent:
                    !give
                    It's yours my friend, as long as you have enough shills.
            ]],
            [[
                player:
                    !point
                    Top shelf, my bartender, top shelf!
                agent:
                    !give
                    I hear ya, I hear ya. Have some wine.
            ]],
        },
    }
    :Loc{
        OPT_BUY = "Buy {1#card}",
        DIALOG_BUY_LUMIN_WINE = [[
            %buy_wine
        ]],
    }
    :Hub(function(cxt, who)
        if who and DemocracyUtil.IsDemocracyCampaign(cxt.act_id) then
            if cxt.location and cxt.location:GetContentID() == "MOREEF_BAR" and cxt.location:GetProprietor() == who then
                cxt:Opt("OPT_BUY", "lumin_wine")
                    :DeliverMoney( 50, { is_shop = true } )
                    :PreIcon( global_images.drink )
                    :Dialog("DIALOG_BUY_LUMIN_WINE")
                    :Fn( function(cxt)
                        cxt:ForceTakeCards{"lumin_wine"}
                    end)
            end
        end
    end)
