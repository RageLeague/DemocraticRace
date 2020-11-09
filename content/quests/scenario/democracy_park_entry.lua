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
                tags = "stroll_monologue",
                [[
                    * It is not often that you have this much time on your hands, that you can do what you want.
                    * It is quite nice, actually.
                ]],
                [[
                    * This reminds me of your childhood, when there's much less to worry about.
                    * It feels good to not have to worry about anything.
                    * Of course, that doesn't make your problems disappear.
                ]],
                [[
                    * Your mind still hasn't lay off the thoughts of the campaign.
                    * Now you can't just use fists to solve all your problems, the world becomes more complicated.
                    * This is precisely why you need time to gather your thoughts.
                ]],
                [[
                    * There are a lot of questions you have about all this.
                    * Why did everyone decide to resolve who rules over Havaria with democracy all of a sudden?
                    * With the way Havaria is, will a peaceful resolution be achieved?
                    * Those are big questions, that no one knows for sure.
                ]],
                [[
                    * There are no thoughts on your mind.
                    * There doesn't have to be, considering you're here to relax.
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
                * You take a little stroll.
                %stroll_monologue
            ]],

            OPT_MEDITATE = "Meditate",
            TT_MEDITATE = "This will increase your max resolve by <#BONUS>{1}</>",

            DIALOG_MEDITATE = [[
                * You meditate.
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
            end
        end)