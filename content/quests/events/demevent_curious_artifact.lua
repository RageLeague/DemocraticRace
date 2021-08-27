local FOLLOW_QUEST

local CURIO_CARD = "curious_curio"

local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}

QDEF:AddConvo()
    :ConfrontState("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * [P] You stumbled across a curious looking object.
                * It has the most curious design.
                * Should you take it?
            ]],
            OPT_TAKE = "Take it",
            TT_TAKE = "Gain {1#card_list}",
            DIALOG_TAKE = [[
                * [p] Finders keepers.
                * You don't understand it much, but you can hopefully ask someone else about it.
            ]],
            OPT_LEAVE = "Leave it",
            DIALOG_LEAVE = [[
                * [P] It doesn't look like something you want to touch, so you leave it alone.
            ]],
        }
        :Fn(function(cxt)
            cxt.quest:Complete()
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_TAKE")
                :PostText("TT_TAKE", {CURIO_CARD})
                :PostCard( CURIO_CARD )
                :Dialog("DIALOG_TAKE")
                :Fn(function(cxt)
                    local cards = cxt:GainCards{CURIO_CARD}
                    if cards[1] then
                        local follow_quest = cxt.quest:SpawnFollowQuest(FOLLOW_QUEST.id)
                        if follow_quest then
                            cards[1].userdata.linked_quest = follow_quest
                            follow_quest.param.artifact_card = cards[1]
                        end
                    end
                end)
                :Travel()

            cxt:Opt("OPT_LEAVE")
                :Dialog("DIALOG_LEAVE")
                :Travel()
        end)

FOLLOW_QUEST = QDEF:AddFollowup({
    events =
    {
        card_removed = function(quest, card)
            if quest.param.artifact_card and quest.param.artifact_card == card then
                if quest:IsActive() then
                    quest:Complete()
                end
            end
        end,
    }
})
:AddObjective{
    id = "ask",
    state = QSTATUS.ACTIVE,
    title = "Ask about the artifact",
    desc = "Perhaps people who often deal with artifacts can tell you all about it.",
}
:AddOpinionEvents{
    donated_artifact =
    {
        delta = OPINION_DELTAS.LIKE,
        txt = "Donated an artifact to the cult",
    },
}

FOLLOW_QUEST:AddConvo()
    :Loc{
        OPT_ASK = "Ask {agent} to identify {1#card}",
        OPT_SHOW = "Show {agent} {1#card}",
        DIALOG_ASK = [[
            player:
                Can you take a look at this?
            agent:
            {royal_relic?
                [p] It's decorative.
            }
            {mesmerizing_charm?
                [p] It looks cool.
            }
            {intimidating_blaster?
                [p] It's an ancient weapon.
            }
        ]],
    }
    :Hub(function(cxt, who)
        if who and (who:GetFactionID() == "CULT_OF_HESH" or who:GetFactionID() == "SPARK_BARONS") and not AgentUtil.HasPlotArmour(who) then
            if not cxt.quest.param.artifact_card then
                cxt.quest:Complete()
                return
            end
            cxt:Opt(cxt.quest.param.artifact_card.hatch and "OPT_ASK" or "OPT_SHOW", cxt.quest.param.artifact_card)
                :Fn(function(cxt)
                    if cxt.quest.param.artifact_card.hatch then
                        local chosen = table.arraypick(cxt.quest.param.artifact_card.available_hatch)
                        local card = cxt.player.negotiator:LearnCard( chosen )
                        local card_to_remove = cxt.quest.param.artifact_card
                        cxt.quest.param.artifact_card = card
                        card.userdata.linked_quest = cxt.quest
                        cxt.player.negotiator:RemoveCard(card_to_remove)
                    end
                    cxt.enc.scratch[cxt.quest.param.artifact_card.id] = true
                    cxt:Dialog("DIALOG_ASK")
                    cxt.enc.scratch[cxt.quest.param.artifact_card.id] = false
                    if who:GetFactionID() == "CULT_OF_HESH" then
                        cxt:GoTo("STATE_CULT_ACQUIRE")
                    elseif cxt.quest.param.artifact_card.practical then
                        cxt:GoTo("STATE_BARON_ACQUIRE")
                    else
                        cxt:GoTo("STATE_BARON_DECORATION")
                    end
                end)
        end
    end)
    :State("STATE_CULT_ACQUIRE")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    [p] The cult would be taking that for preserving artifacts.
            ]],
            OPT_ACCEPT = "Accept the deal",
            DIALOG_ACCEPT = [[
                player:
                    [p] Here you go.
                agent:
                    Hesh thank you for your service.
            ]],
            OPT_REJECT = "Reject the deal",
            DIALOG_REJECT = [[
                player:
                    [p] I'm having second thoughts on this.
                agent:
                    Understandable. My offer is still here if you want.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_ACCEPT")
                :Dialog("DIALOG_ACCEPT")
                :ReceiveOpinion("donated_artifact")
                :Fn(function(cxt)
                    cxt.player.negotiator:RemoveCard(cxt.quest.param.artifact_card)
                end)
                :CompleteQuest()
                :DoneConvo()

            cxt:Opt("OPT_REJECT")
                :Dialog("DIALOG_REJECT")
        end)
    :State("STATE_BARON_ACQUIRE")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    [p] We could use this tech.
                    I'll take it off you for some money.
            ]],
            OPT_ACCEPT = "Accept the deal",
            DIALOG_ACCEPT = [[
                player:
                    [p] You've got yourself a deal.
                agent:
                    Excellent.
            ]],
            OPT_REJECT = "Reject the deal",
            DIALOG_REJECT = [[
                player:
                    [p] I'm having second thoughts on this.
                agent:
                    Understandable. My offer is still here if you want.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_ACCEPT")
                :Dialog("DIALOG_ACCEPT")
                :ReceiveMoney(Util.GetCardPrice(cxt.quest.param.artifact_card.id))
                :Fn(function(cxt)
                    cxt.player.negotiator:RemoveCard(cxt.quest.param.artifact_card)
                end)
                :CompleteQuest()
                :DoneConvo()

            cxt:Opt("OPT_REJECT")
                :Dialog("DIALOG_REJECT")
        end)
    :State("STATE_BARON_DECORATION")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    [p] It's basically decoration.
                    You can keep it.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Complete()

            StateGraphUtil.AddEndOption(cxt)
        end)
