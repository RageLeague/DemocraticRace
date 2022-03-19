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
                * You notice the jingling of shills before you notice the person holding them.
                * {merchant}'s clothing is rich—and rich clothing has deep pockets.
                * And the roads are deserted, 'cept for you and your new fri-
                merchant:
                    !right
                    !point
                    I'm going to stop you right there before you try to rob me.
                player:
                    !left
                    What, do you really think I, a professional politician, would resort to petty theft?
                merchant:
                    !crossed
                    ...
                player:
                    ...
                    !hips
                    Alright, what's the deal?
                merchant:
                    The deal you presume I want is something simple.
                    If you publicly support {1#pol_stance} for me, I'll provide you some campaign funds.
            ]],
            OPT_ACCEPT = "Accept",
            DIALOG_ACCEPT = [[
                player:
                    !take
                    You give me money and all I have to do is give you my word. Seems like a great deal!
                merchant:
                    !wink
                    Your word is quite valuable.
            ]],
            OPT_DECLINE = "Decline",
            DIALOG_DECLINE = [[
                player:
                    I've still got some dignity. I'll pass on this.
                merchant:
                    !shrug
                    Well, I guess you just want to let this money fall into your opponent's hands.
                    !exit
                * {merchant} walks away, jingling the large sum of shills in {merchant.hisher} pockets louder just to spite you.
            ]],
            OPT_ASK_FOR_MORE = "Ask for more money",
            DIALOG_ASK_FOR_MORE = [[
                player:
                    Listen, I'm flattered, but you understand the impact this will have on my voting base, correct?
                    I'll need a bit more to help keep my campaign afloat.
            ]],
            DIALOG_ASK_FOR_MORE_SUCCESS = [[
                player:
                    !eureka
                    If I end up losing, this would be a wasted investment. If I have enough money, I'll be able to stay in the race longer.
                merchant:
                    !question
                    A fine point. How about {1#money}?
            ]],
            DIALOG_ASK_FOR_MORE_FAILURE = [[
                merchant:
                    !hips
                    I wouldn't be here if I didn't think you already had a good chance of winning.
                    Your campaign will be fine, regardless of how much money I give you, which I still offer {1#money}.
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

                cxt:Dialog("DIALOG_INTRO", cxt.quest.param.chosen_issue .. "_" .. cxt.quest.param.chosen_stance)
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
