local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    cooldown = EVENT_COOLDOWN.LONG,
}
--------------------------------------------------------------------

QDEF:AddConvo()
    :Confront(function(cxt, who)
        return "STATE_FOUND_TOTEM"
    end)

        :State("STATE_FOUND_TOTEM")
        :Loc{
            DIALOG_INTRO = [[
                * Sitting conspicuously by the side of the road, you notice an old shrine. It doesn't look Heshian.
            ]],

            OPT_OFFER = "Make an offering",
            TT_OFFER = "Remove a chosen negotiation card.",
            DIALOG_OFFER = [[
                player:
                    !left
                    !give
                    $miscNostalgic
                    You need this more than I do, clearly.
                * You don't know who the shrine is for, but you leave your offering in a groove on the worn-down pedestal and return to the road.

            ]],

            OPT_MEDITATE = "Meditate by the shrine",
            TT_MEDITATE = "Upgrade a chosen negotiation card.",
            DIALOG_MEDITATE = [[
                player:
                    !left
                * You place a hand on the worn pedestal and take a moment to reflect on the here and now.
                player:
                    !sigh
                    $miscNostalgic
                    Guess even old gods die eventually, huh?
                * Surprisingly the notion brings you comfort. You spend the rest of your walk mulling it over.
            ]],

            OPT_SKIP = "Leave the shrine",
            DIALOG_SKIP = [[
                {player_sal?
                    * You were sent to the derricks to mine lumin in Hesh's name. It's hard to imagine any religion is worth your time.
                }
                {not player_sal and pro_religious_policy?
                    * There is room for only one god in your heart, and whatever this is, it is not it.
                }
                {not player_sal and not pro_religious_policy?
                    * You've seen how the Cult of Hesh operates. It's hard to imagine any religion is worth your time.
                }
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                if cxt.location:HasTag("forest") then
                    cxt.location:SetPlax("EXT_ForestShrine_01")
                else
                    cxt.location:SetPlax("EXT_RoadShrine_01")
                end
                cxt:Dialog( "DIALOG_INTRO" )
            end

            cxt:Opt("OPT_OFFER")
                :PreIcon( global_images.removenegotiation )
                :PostText( "TT_OFFER" )
                :Fn( function( cxt )
                    cxt:Wait()
                    AgentUtil.RemoveNegotiationCard( cxt.player, function( card )
                        cxt.enc:ResumeEncounter( card )
                    end)

                    local card = cxt.enc:YieldEncounter()
                    if card then
                        cxt:Dialog("DIALOG_OFFER")
                        cxt.quest:Complete()
                        local leave_opt = StateGraphUtil.AddLeaveLocation(cxt)
                        leave_opt:Fn(function( cxt ) cxt.location:SetPlax(nil) end)
                    end
                end )

            cxt:Opt("OPT_MEDITATE")
                :PostText( "TT_MEDITATE" )
                :PreIcon( global_images.upgradenegotiation )
                :Fn( function( cxt )
                    cxt:Wait()
                    AgentUtil.UpgradeNegotiationCard( function( card )
                        cxt.enc:ResumeEncounter( card )
                    end )

                    local card = cxt.enc:YieldEncounter()
                    if card then
                        cxt:Dialog("DIALOG_MEDITATE")
                        cxt.quest:Complete()
                        local leave_opt = StateGraphUtil.AddLeaveLocation(cxt)
                        leave_opt:Fn(function( cxt ) cxt.location:SetPlax(nil) end)
                    end
                end )

            cxt:Opt("OPT_SKIP")
                :PreIcon( global_images.close )
                :Dialog("DIALOG_SKIP")
                :Fn(function()
                    cxt.quest:Complete()
                    local leave_opt = StateGraphUtil.AddLeaveLocation(cxt)
                    leave_opt:Fn(function( cxt ) cxt.location:SetPlax(nil) end)
                end)
        end)

