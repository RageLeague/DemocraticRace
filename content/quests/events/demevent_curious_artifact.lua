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
                end)
                :Travel()

            cxt:Opt("OPT_LEAVE")
                :Dialog("DIALOG_LEAVE")
                :Travel()
        end)