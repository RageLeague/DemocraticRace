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
                cxt.quest:Complete()

                cxt.quest.param.lobby_money = 100
                local weightings = {}
                for id, data in pairs(DemocracyConstants.issue_data) do
                    weightings[id] = data.importance
                end
                local chosen = weightedpick(weightings)
                cxt.quest.param.chosen_issue = chosen
                cxt.quest.param.chosen_stance = DemocracyConstants.issue_data[chosen]:GetAgentStanceIndex(cxt:GetCastMember("merchant"))

                cxt:Dialog("DIALOG_INTRO")
            end

            local haggle_count = cxt.player.graft_owner:CountGraftsByID( "haggle_badge" )

            if haggle_count > 0 and not cxt.quest.param.haggled_money then
                local won_bonuses = {10}
                cxt:Opt("OPT_ASK_FOR_MORE")
                    :Dialog("DIALOG_ASK_FOR_MORE")
                    :Negotiation{
                        on_start_negotiation = function(minigame)

                            local amounts = {50, 20}

                            for i = 2, haggle_count do
                                table.insert(amount, 60)
                            end

                            for k,amt in ipairs(amounts) do
                                local mod = minigame.opponent_negotiator:CreateModifier( "bonus_payment", amt )
                                mod.result_table = won_bonuses
                            end
                        end,
                        reason_fn = function(minigame)
                            local total_amt = 0
                            for k,v in pairs(won_bonuses) do
                                total_amt = total_amt + v
                            end
                            return loc.format(cxt:GetLocString("NEGOTIATION_REASON"), total_amt )
                        end,

                        enemy_resolve_required = 10 * cxt.quest:GetRank(),
                    }:OnSuccess()
                        :Fn(function(cxt)
                            local total_bonus = 0
                            for k,v in ipairs(won_bonuses) do
                                total_bonus = total_bonus + v
                            end
                            cxt.quest.param.lobby_money = cxt.quest.param.lobby_money + total_bonus
                            cxt.quest.param.haggled_money = true
                        end)
                        :Dialog("DIALOG_ASK_FOR_MORE_SUCCESS")
                    :OnFailure()
                        :Fn(function(cxt)
                            cxt.quest.param.haggled_money = true
                        end)
                        :Dialog("DIALOG_ASK_FOR_MORE_FAILURE")
            end

            cxt:Opt("OPT_ACCEPT")
                :Dialog("DIALOG_ACCEPT")
                :ReceiveMoney(cxt.quest.param.lobby_money)
                :UpdatePoliticalStance(cxt.quest.param.chosen_issue, cxt.quest.param.chosen_stance, true)
                :Travel()

            cxt:Opt("OPT_DECLINE")
                :Dialog("DIALOG_DECLINE")
                :Travel()
        end)
