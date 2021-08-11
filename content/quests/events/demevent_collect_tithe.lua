local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    precondition = function(quest)
        local canspawn = false

        if DemocracyUtil.GetFactionEndorsement("CULT_OF_HESH") < RELATIONSHIP.NEUTRAL then
            quest.param.unpopular = true
            canspawn = true
        end

        return canspawn
    end,
}
QDEF:AddConvo()
    :ConfrontState("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You are interrupted by some guy in the Cult.
                player:
                    !left
                agent:
                    !right
                    Yo, you haven't been paying your tithe for about eleven years.
                    Pay up or face the wrath of Hesh.
            ]],
        }
        :Fn(function(cxt)

        end)