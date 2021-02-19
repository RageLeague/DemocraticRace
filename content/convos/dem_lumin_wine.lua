Convo("DEM_LUMIN_WINE")
    :Priority(CONVO_PRIORITY_HIGH)
    :Loc{
        OPT_BUY = "Buy {1#card}",
        DIALOG_BUY_LUMIN_WINE = [[
            player:
                [p] Can I buy some Lumin Wine?
            agent:
                !permit
                It's yours, my friend.
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
