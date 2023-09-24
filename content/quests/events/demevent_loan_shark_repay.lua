local QDEF = QuestDef.Define
{
    title = "Loan Repayment",
    icon = engine.asset.Texture("icons/quests/event_loan_shark_repay.tex"),
    qtype = QTYPE.STORY,
    on_init = function(quest)
        quest.param.time_due = Now() + 2
    end,
}

:AddCast{
    cast_id = "lender",
    no_validation = true,
    events =
    {
        agent_retired = function( quest, agent )
            quest:Cancel()
        end,
        aspects_changed = function( quest, agent, added, aspect )
            if added then
                if is_instance( aspect, Aspect.StrippedInfluence ) then
                    quest:Cancel()
                end
            end

        end,
    }

}

:AddObjective{
    id = "repay",
    state = QSTATUS.ACTIVE,
    title = "You owe {lender} {1#money} (due {2#relative_time})",
    combat_targets = {"lender"},
    title_fn = function(quest, str)
        return loc.format(str, quest.param.amt_owed or 0, (quest.param.time_due or 0)- Now())
    end,

    is_in_hiding = function(quest, agent)
        return agent == quest:GetCastMember("lender")
    end,
}


--------------------------------------------------------------------




QDEF:AddConvo("repay")
    :ConfrontState("CONF", function(cxt)

        if Now() < cxt.quest.param.time_due then
            return false
        end

        if ConvoUtil.CanInterruptTravel(cxt) then
            if cxt.quest.param.ignore_times == nil then
                cxt.quest.param.ignore_times = math.random(1, 4)
            end

            if cxt.quest.param.ignore_times <= 0 then
                return true
            else
                cxt.quest.param.ignore_times = cxt.quest.param.ignore_times - 1
                return false
            end

        end

    end)
        :Loc{
            DIALOG_INTRO_EXTENDED = [[
                player:
                    !left
                * {lender} finds you again.
                agent:
                    !right
                    !crossed
                    Your extension is over. I will be taking my money back now.
                ]],
            DIALOG_INTRO = [[
                player:
                    !left
                * {lender} approaches you.
                agent:
                    !right
                    Hello again, grifter!
                    It is time for you to repay your debt.
            ]],

            OPT_PAY_DEBT = "Pay your debt",
            DIALOG_PAY_DEBT = [[
                player:
                    Here you go. It's all there.
                    !give
                agent:
                    !take
                    Five, six, seven...
                    Yes, you are correct.
                    !happy
                    It has been a pleasure doing business with you!
                    !exit
            ]],
            OPT_ASK_FOR_EXTENSION = "Ask for more time",
            DIALOG_ASK_FOR_EXTENSION = [[
                player:
                    I need a little more time.
            ]],
            DIALOG_GOT_EXTENSION = [[
                agent:
                    Ok. I'm going to find you again, very soon, and you are going to have my money, and another {1#money} for wasting my time.
                    !point
                    Do not test my patience again.
                    !exit
            ]],
            DIALOG_NO_EXTENSION = [[
                agent:
                    No. You agreed to pay me now. You will pay me now, or there will be consequences.
            ]],

            OPT_REFUSE_TO_PAY = "Refuse to pay",
            DIALOG_REFUSE_TO_PAY = [[
                player:
                    I'm not paying you back!
                agent:
                    A pity.
            ]],


            OPT_SAY_YOU_CANT_PAY = "Tell {agent} you don't have the money",
            DIALOG_SAY_YOU_CANT_PAY = [[
                player:
                    I would pay you if I could, but I don't have the money right now.
            ]],
            DIALOG_NO_OFFER = [[
                agent:
                    Oh. I'm sorry.
                    That's really too bad.
                    I really wanted that money back. Now I'm going to have to have you killed instead.
                    !sigh
                    Cost of doing business, I suppose.

            ]],
            DIALOG_OFFER_TO_TAKE_GRAFTS = [[
                agent:
                    In that case, I will give you two options.
                    The first option, is that I will repossess some grafts. Let's say... {1#graft_list}.
                    The second option, is that I will have you killed, and then sell your body for oshnu feed.
                    You decide.
            ]],
            OPT_GIVE_ALL_GRAFTS = "Give up the grafts",
            TT_GIVE_UP_GRAFTS = "You will lose: {1#graft_list}",
            DIALOG_GIVE_ALL_GRAFTS = [[
                player:
                    Take the grafts.
                agent:
                    Very well.
                player:
                    !exit
                * {agent} directs {agent.hisher} goons to remove the grafts.
                * It is an excruciating process.
            ]],
            DIALOG_GIVE_ALL_GRAFTS_2 = [[
                player:
                    !left
                    !injured
                agent:
                    !happy
                    A pleasure doing business with you.
                    !exit
            ]],
            OPT_DEFEND = "Defend yourself",
            DIALOG_DEFEND = [[
                player:
                    !fight
                    I'm not afraid of you!
            ]],
            DIALOG_WON_FIGHT_AGENT_DEAD = [[
                * {agent} is dead, and so is your debt.
            ]],
            DIALOG_WON_FIGHT_AGENT_SPARED = [[
                agent:
                    !injured
                player:
                    So does that cover it?
                agent:
                    !spit
                player:
                    Good enough.
                agent:
                    !exit
            ]],

        }
        :Fn(function(cxt)
            cxt.quest:GetCastMember("lender"):MoveToLocation(cxt.location)
            cxt.quest.param.goons = CreateCombatBackup(cxt.quest:GetCastMember("lender"), "MERCENARY_BACKUP", cxt.quest:GetRank()+1 )
            cxt:TalkTo(cxt.quest:GetCastMember("lender"))
            cxt:Dialog(cxt.quest.param.had_extension and "DIALOG_INTRO_EXTENDED" or "DIALOG_INTRO")

            local candidates = {}
            for k,v in ipairs(cxt.player.graft_owner:GetGrafts( GRAFT_TYPE.COMBAT )) do
                table.insert(candidates, v)
            end
            for k,v in ipairs(cxt.player.graft_owner:GetGrafts( GRAFT_TYPE.NEGOTIATION )) do
                table.insert(candidates, v)
            end
            table.shuffle(candidates)

            cxt.enc.scratch.grafts = {}
            for k = 1, math.min(#candidates, 4) do
                table.insert(cxt.enc.scratch.grafts, candidates[k])
            end
            cxt:RunLoop(function(cxt)

                cxt:Opt("OPT_PAY_DEBT")
                    :DeliverMoney(cxt.quest.param.amt_owed, {no_scale= true})
                    :Dialog("DIALOG_PAY_DEBT")
                    :CompleteQuest()
                    :Travel()

                if cxt.caravan:GetMoney() < cxt.quest.param.amt_owed then

                    cxt:Opt("OPT_SAY_YOU_CANT_PAY")
                        :Dialog("DIALOG_SAY_YOU_CANT_PAY")
                        :Fn(function()
                            local current_health = cxt.player:GetHealth()
                            local do_offer =#cxt.enc.scratch.grafts >= 2

                            cxt:Dialog(do_offer and "DIALOG_OFFER_TO_TAKE_GRAFTS" or "DIALOG_NO_OFFER", cxt.enc.scratch.grafts)
                            if do_offer then
                                cxt:Opt("OPT_GIVE_ALL_GRAFTS")
                                    :PostText("TT_GIVE_UP_GRAFTS", cxt.enc.scratch.grafts)
                                    :Dialog("DIALOG_GIVE_ALL_GRAFTS")
                                    :Fn( function(cxt)
                                        for k, v in ipairs(cxt.enc.scratch.grafts) do
                                            cxt.player.graft_owner:RemoveGraft(v)
                                        end
                                    end)
                                    :DeltaHealth(-math.floor(current_health*.5))
                                    :Dialog("DIALOG_GIVE_ALL_GRAFTS_2")
                                    :CompleteQuest()
                                    :Travel()
                            end

                            cxt:Opt("OPT_DEFEND")
                                :Dialog("DIALOG_DEFEND")
                                :Battle{flags = BATTLE_FLAGS.SELF_DEFENCE, no_oppo_limit = true}
                                    :OnWin()
                                        :CompleteQuest()
                                        :Dialog(cxt:GetAgent():IsDead() and "DIALOG_WON_FIGHT_AGENT_DEAD" or "DIALOG_WON_FIGHT_AGENT_SPARED")
                                        :Travel()
                        end)
                end

                if not cxt.quest.param.had_extension then
                    local extra = math.round( (cxt.quest.param.amt_owed) * .2 )
                    cxt:Opt("OPT_ASK_FOR_EXTENSION")
                        :Dialog("DIALOG_ASK_FOR_EXTENSION")
                        :Negotiation{}
                            :OnSuccess()
                                :Dialog("DIALOG_GOT_EXTENSION", extra)
                                :Fn(function()
                                    cxt.quest.param.had_extension = true
                                    cxt.quest.param.time_due = Now() + 1
                                    cxt.quest.param.amt_owed = cxt.quest.param.amt_owed + extra
                                    cxt.quest:NotifyChanged()
                                end)
                                :Travel()

                            :OnFailure()
                                :Dialog("DIALOG_NO_EXTENSION")
                end

                cxt:Opt("OPT_REFUSE_TO_PAY")
                    :Dialog("DIALOG_REFUSE_TO_PAY")
                    :Battle{flags = BATTLE_FLAGS.SELF_DEFENCE, no_oppo_limit = true}
                        :OnWin()
                            :CompleteQuest()
                            :Dialog(cxt:GetAgent():IsDead() and "DIALOG_WON_FIGHT_AGENT_DEAD" or "DIALOG_WON_FIGHT_AGENT_SPARED")
                            :Travel()


            end)


        end)
