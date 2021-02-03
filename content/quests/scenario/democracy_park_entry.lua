local QDEF = QuestDef.Define
{
    qtype = QTYPE.SCENARIO, 
}

:AddLocationCast
{
    cast_id = "location",
    on_assign = function(quest) 
        TheGame:GetGameState():GetCaravan():MoveToLocation( quest:GetCastMember("location") )
    end,
}

QDEF:AddConvo()
    :Priority( CONVO_PRIORITY_HIGHEST )
    :Confront(function(cxt, agent)
        if cxt.location == cxt.quest:GetCastMember("location") then 
            -- DBG(cxt.quest)
            return "STATE_CONFRONT"
        end
    end)

    :State("STATE_CONFRONT")
        :SetLooping()
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
                    *** The answer is 3, if you're curious.
                ]],
            },
        }
        :Loc{
            DIALOG_INTRO = [[
                * You arrive at {location#location}.
                * It has a peaceful environment, a perfect place to gather resolve.
                * If you have time, you can spend some time here, take a walk, or meditate.
            ]],
            OPT_STROLL = "Take a stroll",

            DIALOG_STROLL = [[
                * You take a slow walk through the area, taking in the scenery.
                %stroll_monologue
            ]],

            OPT_MEDITATE = "Meditate",
            TT_MEDITATE = "This will increase your max resolve by <#BONUS>{1}</>",

            DIALOG_MEDITATE = [[
                * You sit down and slow your breathing.
                %stroll_monologue
            ]],
        }

        :Fn(function(cxt)
            cxt.quest:Complete()
            if DemocracyUtil.IsDemocracyCampaign() then
                local resolve_restore = 10
                local meditate_cost = 10
                local max_delta = 4
                cxt:Dialog("DIALOG_INTRO")
                if DemocracyUtil.IsFreeTimeActive() then
                    cxt:Opt("OPT_STROLL")
                        :RequireFreeTimeAction(2)
                        :PreIcon( global_images.restoreresolvelittle )
                        :Dialog("DIALOG_STROLL")
                        :DeltaResolve(resolve_restore)
                        :DoneConvo()
                    cxt:Opt("OPT_MEDITATE")
                        :RequireFreeTimeAction(4)
                        :PreIcon( global_images.restoreresolve )
                        :PostText("TT_MEDITATE", max_delta)
                        :Dialog("DIALOG_MEDITATE")
                        :DeltaResolve(-meditate_cost)
                        :Fn(function() TheGame:GetGameState():GetCaravan():UpgradeResolve(max_delta, false, true) end)
                        :DoneConvo()
                end
                StateGraphUtil.AddEndOption(cxt)
            else
                cxt:End()
            end
        end)
