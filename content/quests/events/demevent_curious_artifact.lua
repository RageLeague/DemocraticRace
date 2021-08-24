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
                quest:Cancel()
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

FOLLOW_QUEST:AddConvo()
    :Loc{
        OPT_ASK = "Ask {agent} to identify {1#card}",
        DIALOG_ASK = [[
            player:
                What is this?
            agent:
            {royal_relic?
                [p] It's decorative.
            }
            {mesmerizing_charm?
                [p] It looks cool.
            }
        ]],
    }
    :Hub(function(cxt)

    end)
    :State("STATE_CULT_ACQUIRE")
        :Loc{

        }
    :State("STATE_BARON_ACQUIRE")
        :Loc{

        }
    :State("STATE_BARON_DECORATION")
        :Loc{

        }
