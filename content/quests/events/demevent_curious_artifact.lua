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
                player:
                    !left
                * It's the odd glint that caught you off guard, flickering in the middle of the mud.
                * A small bit of investigation, and you uncover a small trinket.
            ]],
            OPT_TAKE = "Take it",
            TT_TAKE = "Gain {1#card_list}",
            DIALOG_TAKE = [[
                player:
                    !take
                * Fortune favors the bold, or the one with the weirdest tchotchkes.
                * It might be more valuable than the untrained eye can tell, but only someone who dabbles in this kind of research could tell.
            ]],
            OPT_LEAVE = "Leave it",
            DIALOG_LEAVE = [[
                * You unceremoniously drop it back into the muck and continue on.
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
                !give
                Can you take a look at this?
            agent:
                !take
                Sure. Let me take a look-see.
                !question
                ...
            {royal_relic?
                Oh. It appears this one's a bit out of fashion.
            player:
                Excuse me?
            agent:
                !placate
                It's nothing personal. It's just a bit of jewelry worn more by the middle class than the nobles.
                !question
                Although the age on it is authentic, I'll give you that.
            }
            {mesmerizing_charm?
                A superstitious sort, aren't we?
            player:
                Superstitious?
            agent:
                It's a talisman of some sort. If I remember my notes right, this one was meant to be noticed "above all else".
            player:
                And above all else means...what?
            agent:
                !shrug
                Above the riff-raff, I suppose. It's eyecatching, if nothing else.
            }
            {intimidating_blaster?
                It's a small firearm.
                Pocket sized, really. I can't figure out how they fit the skull decal on it as well.
            player:
                Skull?
            agent:
                Yes, right around here. It's a bit smudged, but if you can notice the-
            player:
                Ah, now I see it.
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
                    If you found this, it may have washed up at your feet by Hesh's command.
                    If one truly appreciates this gift, it would be through donation to the Cult.
            ]],
            OPT_ACCEPT = "Donate the Artifact",
            DIALOG_ACCEPT = [[
                player:
                    !give
                    Don't know how I can appreciate it if I'm giving it for free, but here.
                agent:
                    !take
                    It's a small token, but I'm sure Hesh will favor you someday, in exchange for this.
            ]],
            OPT_REJECT = "Reject the deal",
            DIALOG_REJECT = [[
                player:
                    I'm not really prepared for nothing from something as a trade.
                agent:
                    !hesh_greeting
                    Hesh may differ, but he does not interfere. If you wish to donate it at anytime, I will help.
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
                :UpdatePoliticalStance("RELIGIOUS_POLICY", 2)
                :CompleteQuest()
                :DoneConvo()

            cxt:Opt("OPT_REJECT")
                :Dialog("DIALOG_REJECT")
        end)
    :State("STATE_BARON_ACQUIRE")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    I'd give that bit of tech a fair bit of value.
                    Tell you what? Market price for that doo-dad, right here.
            ]],
            OPT_ACCEPT = "Accept the deal",
            DIALOG_ACCEPT = [[
                player:
                    !give
                    If you put it to better use than I can, I'll take those shills off your hands.
                agent:
                    !take
                    I'm sure we'll find a way to weaponize it.
            ]],
            OPT_REJECT = "Reject the deal",
            DIALOG_REJECT = [[
                player:
                    I think I'll test it out a little, see if it's worth that market value.
                agent:
                    !placate
                    Hey friend, no skin off my nose. If you ever want to pawn it off, though, I'll always be here.
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
                :UpdatePoliticalStance("RELIGIOUS_POLICY", -2)
                :CompleteQuest()
                :DoneConvo()

            cxt:Opt("OPT_REJECT")
                :Dialog("DIALOG_REJECT")
        end)
    :State("STATE_BARON_DECORATION")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    It's pretty, but I don't think the barons would find much use from it.
                    You can keep it. I think the cult might care about it, though more under a "preserve all artifacts" doctrine.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Complete()

            StateGraphUtil.AddEndOption(cxt)
        end)
