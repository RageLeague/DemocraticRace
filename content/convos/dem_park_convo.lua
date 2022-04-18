local resolve_restore = 10
local meditate_cost = 10
local max_delta = 4

Convo("DEM_PARK_CONVO")
    :Priority(CONVO_PRIORITY_LOW)
    :Quips{
        {
            --Wumpus; If this is the correct format for making new quips, maybe I could add some for meditation and some for strolls specifically? That can wait, however.
            tags = "stroll_monologue",
            [[
                * Since you started on your path in life, you've felt time has flown by with nary a break.
                * But now you have a moment of calm, a moment of peace. There's no pressure to perform here, no one to judge.
                * Just you, your thoughts, and the smell of the fresh grass.
            ]],
            [[
                * You feel the fond memories of your childhood drift in and out of your head.
                * it reminds you of a simpler time, a cherished time. One where the world was simple, black and white.
                * Those times couldn't stay though, and soon you return to the present, with a renewed spirit.
            ]],
            [[
                * Even as you clear your mind, your thoughts still lay on your campaign.
                * The world's much different now. You're not able to fight people freely without consequence, as you did before becoming a politician.
                * You needed this small mental vacation for a while now. It's been too long since you could just gather your thoughts.
            ]],
            [[
                * There are a lot of questions you have about all this.
                * Why did everyone decide to resolve who rules over Havaria with democracy all of a sudden?
                * With the way Havaria is, will a peaceful resolution be achieved?
                * Those are big questions, that no one knows for sure.
            ]],
            [[
                * Deep breath in...deep breath out.
                * No thoughts exist in your mind. No stresses, no anxieties, no pains...
                * Just the sounds of nature and your own deep and relaxed breathing.
            ]],
            [[
                * What will you do after you've get elected?
                * That's a good question.
                * If you haven't thought about it before, you should think about it now that you have time.
            ]],
            [[
                * How many different group homomorphism are there from a cyclic group of order 69 to a cyclic group of order 420?
                * I mean, what?
                ** (The answer is 3, if you're curious.)
            ]],
        },
    }
    :Loc{
        OPT_STROLL = "Take a stroll",
        OPT_MEDITATE = "Meditate",
        TT_MEDITATE = "This will increase your max resolve by <#BONUS>{1}</>",
    }
    :Hub_Location(function(cxt)
        if DemocracyUtil.IsDemocracyCampaign() and cxt.location and cxt.location:GetContentID() == "PEARL_PARK" then
            cxt:Opt("OPT_STROLL")
                :RequireFreeTimeAction(2)
                :PreIcon( global_images.restoreresolvelittle )
                :PostText("TT_GAIN_RESOLVE", resolve_restore )
                :Fn( function(cxt)
                    UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_STROLL" ,nil,nil,nil)
                end )

            cxt:Opt("OPT_MEDITATE")
                :RequireFreeTimeAction(4)
                :PreIcon( global_images.restoreresolve )
                :PostText("TT_MEDITATE", max_delta)
                :PostText("TT_LOSE_RESOLVE", meditate_cost )
                :Fn( function(cxt)
                    UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_MEDITATE" ,nil,nil,nil)
                end )
                :Fn(function() TheGame:GetGameState():GetCaravan():UpgradeResolve(max_delta, false, true) end)
        end
    end)
    :State("STATE_STROLL")
        :Loc{
            DIALOG_STROLL = [[
                * You take a slow walk through the area, taking in the scenery.
                %stroll_monologue stroll
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_STROLL")
            ConvoUtil.DoResolveDelta(cxt, resolve_restore)
            StateGraphUtil.AddEndOption(cxt)
        end)

    :State("STATE_MEDITATE")
        :Loc{
            DIALOG_MEDITATE = [[
                * You sit down and slow your breathing.
                %stroll_monologue meditate
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_MEDITATE")
            ConvoUtil.DoResolveDelta(cxt, -meditate_cost)
            StateGraphUtil.AddEndOption(cxt)
        end)
