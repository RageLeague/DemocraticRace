local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}
:AddCast{
    cast_id = "merchant",
    condition = function(agent, quest)
        return DemocracyUtil.GetWealth(agent) >= 3
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( table.arraypick{"WEALTHY_MERCHANT", "SPARK_BARON_TASKMASTER", "PRIEST"}) )
    end,
}

QDEF:AddConvo()
    :ConfrontState("CONF")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You are stopped by a person.
                player:
                    !left
                merchant:
                    !right
                    Yo, I heard you are running a campaign.
                    So I would like to provide some funds for you.
                player:
                    What's the catch?
                merchant:
                    The catch is that you must support my position.
            ]],
            OPT_ACCEPT = "Accept",
            DIALOG_ACCEPT = [[
                player:
                    [p] I wouldn't turn away free money.
                merchant:
                    Excellent! That's the sort of stuff I like to see.
            ]],
            OPT_DECLINE = "Decline",
            DIALOG_DECLINE = [[
                player:
                    [p] Nah I don't think I will take it.
                merchant:
                    I thought you are shrewd.
            ]],
            OPT_ASK_FOR_MORE = "Ask for more money",
            DIALOG_ASK_FOR_MORE = [[
                player:
                    [p] I am frankly insulted to think that you can bribe me with this little money.
                    How much are you willing to offer, hmm?
            ]],
            DIALOG_ASK_FOR_MORE_SUCCESS = [[
                merchant:
                    [p] Ah, of course.
                    Here, how does {1#money} sound?
            ]],
            DIALOG_ASK_FOR_MORE_FAILURE = [[
                merchant:
                    [p] You get {1#money} exactly.
                    No more, no less.
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest.param.lobby_money = 100
                local weightings = {}
                for id, data in pairs(DemocracyConstants.issue_data) do
                    weightings[id] = data.importance
                end
                local chosen = weightedpick(weightings)
            end
        end)