local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT

local SURVIVAL_TURNS = 12

local QDEF = QuestDef.Define
{
    title = "Final Steps",
    desc = "Review the progress you've made today with {primary_advisor}, and go to sleep.",

    qtype = QTYPE.STORY,
}
:AddCast{
    cast_id = "primary_advisor",
    -- when = QWHEN.MANUAL,
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor"))
    end,
    no_validation = true,
    on_assign = function(quest,agent)
        quest:AssignCastMember("home")
    end,
}
:AddCast{
    cast_id = "assassin",
    cast_fn = function(quest, t)
        local boss_def = TheGame:GetGameProfile():GetNoStreakRandom("SAL_DAY_2_BOSS_PICK", {"JAKES_ASSASSIN", "JAKES_ASSASSIN2"}, 2)
        local assassin = quest:CreateSkinnedAgent( boss_def )

        table.insert(t, assassin)
    end,
    on_assign = function(quest, agent)
        agent.in_hiding = true
    end,
    no_validation = true,
}
:AddDefCast("dispatcher","ADMIRALTY_CLERK")

:AddDefCast( "responder", "ADMIRALTY_PATROL_LEADER" )

:AddObjective{
    id = "meet_advisor",
    title = "Meet up with {primary_advisor}",
    desc = "Review the progress you've made today with {primary_advisor}, and plan for your next move.",
    mark = {"primary_advisor"},
    state = QSTATUS.ACTIVE,
}
:AddObjective{
    id = "go_to_sleep",
    title = "Go to sleep",
    desc = "Aren't you tired? Go to sleep.",
    mark = {"primary_advisor"},
}
DemocracyUtil.AddHomeCasts(QDEF)
QDEF:AddConvo("meet_advisor", "primary_advisor")
    :AttractState("STATE_TALK")
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
                agent:
                    !right
                    [p] nice work today
                player:
                    thx
                agent:
                    !give
                    here's your pay.
            ]],
            DIALOG_INTRO_LOW_SUPPORT = [[
                player:
                    !left
                agent:
                    !right
                    [p] i have low expectations for you, but i was still surprised about how bad you did.
                    i'm done with you.
                player:
                    oh come on!
            ]],
            DIALOG_INTRO_PST = [[
                agent:
                    go to bed when you're ready.
            ]]
        }
        :Fn(function(cxt)
            if DemocracyUtil.TryMainQuestFn("GetGeneralSupport") >= 10 then
                local money = DemocracyUtil.TryMainQuestFn("CalculateFunding")
                
                cxt:Dialog("DIALOG_INTRO")
                cxt.enc:GainMoney(money)
                cxt:Dialog("DIALOG_INTRO_PST")
                cxt.quest:Complete("meet_advisor")
                cxt.quest:Activate("go_to_sleep")
            else
                cxt:Dialog("DIALOG_INTRO_LOW_SUPPORT")
                cxt:Opt("OPT_ACCEPT_FAILURE")
                    :Fn(function(cxt)
                        TheGame:Lose()
                    end)
            end
        end)
QDEF:AddConvo("go_to_sleep", "primary_advisor")
    :Loc{
        OPT_GO_TO_SLEEP = "Go to sleep",
        DIALOG_GO_TO_SLEEP = [[
            agent:
                [p] there's totally not a boss today.
            player:
                why would there be bosses? we don't fight in this campaign.
            agent:
                yeah, right.
                !exit
            player:
                !exit
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_GO_TO_SLEEP")
            :PreIcon(global_images.sleep)
            :Dialog("DIALOG_GO_TO_SLEEP")
            :GoTo("STATE_ASSASSINATION")
    end)
    :State("STATE_ASSASSINATION")
        :Loc{
            DIALOG_INTRO = [[
                * [p] you're about to go to sleep and you found an assassin.
                player:
                    !left
                agent:
                    !right
                    'sup, dog?
                player:
                    ah hesh.
            ]],
            OPT_DISTRACT = "Distract {agent}",
            TT_DISTRACT = "Distract {agent} until you can call for help.\n"..
                "After calling for help, survive long enough for the responders to arrive.",

            GOAL_CALL_HELP = "(1/3) Call for help",
            GOAL_MAINTAIN_CONNECTION = "(2/3) Describe your current situation to the dispacher ({1}/{2})",
            GOAL_AWAIT_RESCUE = "(3/3) Await rescue (In {1} {1*turn|turns})",

            DIALOG_HELP_ARRIVE = [[
                * [p] the help arrives.
                responder:
                    !left
                    what's going on?
                agent:
                    !exit
                * seeing the admiralty, {agent} fled the scene.
                responder:
                    oh no you dont!
                    !exit
                * {responder} runs after {agent}
            ]],
            DIALOG_FIGHT_PHRASE = [[
                agent:
                    [p] that's enough. i'm tired with you
                    let's finish this
                {help_called?
                    * you hope that you will survive long enough for help to arrive
                }
                {not help_called?
                    * you didn't have time to call for help! oh no!
                }
            ]],

            DIALOG_PST_FIGHT_SURRENDER = [[
                agent:
                    !exit
                * [p] {agent} ran away before you can finish {agent.himher} off.
                player:
                    !left
                    hesh damn it!
                {help_called?
                    * it is not long before the responders arrive.
                    responder:
                        !right
                        what's going on?
                    player:
                        an assassin tried to kill me, but {agent.heshe} got away.
                    responder:
                        understandable, have a nice day.
                }
            ]],
            DIALOG_PST_FIGHT_DEAD = [[
                * [p] {agent} lies dead.
                * {responder} arrive, seeing a dead body.
                player:
                    !left
                responder:
                    !right
                    what's going on?
                player:
                    self defense
                responder:
                    understandable, have a nice day.
            ]],
            OPT_DEFEND_SELF = "Defend yourself!"
        }
        :Fn(function(cxt)
            local location = cxt.quest:GetCastMember("player_room")
            cxt.encounter:DoLocationTransition( location )
            TheGame:GetGameState():GetPlayerAgent():MoveToLocation( location )
            cxt.enc:GetScreen():ClearHistory()
            cxt.enc:GetScreen():SetBlur(false)

            local assassin = cxt.quest:GetCastMember("assassin")
            assassin.in_hiding = false
            assassin:MoveToLocation(cxt.location)
            cxt.enc:SetPrimaryCast(assassin)
            cxt:Dialog("DIALOG_INTRO")

            -- cxt.quest.param.call_time = 3
            cxt.quest.param.help_called = false
            cxt.quest.param.help_arrive_time = SURVIVAL_TURNS

            cxt:Opt("OPT_DISTRACT")
                :PostText("TT_DISTRACT")
                :Negotiation{
                    flags = NEGOTIATION_FLAGS.NO_CORE_RESOLVE,
                    reason_fn = function(minigame)
                        local help_inst = minigame.player_negotiator:FindModifier("HELP_UNDERWAY")
                        local call_inst = minigame.player_negotiator:FindModifier("CONNECTED_LINE")
                        if help_inst then
                            return loc.format(cxt:GetLocString("GOAL_AWAIT_RESCUE"), help_inst.turns_left )
                        elseif call_inst then
                            return loc.format(cxt:GetLocString("GOAL_MAINTAIN_CONNECTION"), call_inst.stacks, call_inst.calls_required )
                        end
                        return cxt:GetLocString("GOAL_CALL_HELP")
                    end,
                    on_start_negotiation = function(minigame)
                        minigame.opponent_negotiator:CreateModifier( "DISTRACTION_ENTERTAINMENT" )
                        minigame.opponent_negotiator:CreateModifier( "DISTRACTION_GUILTY_CONSCIENCE" )
                        minigame.opponent_negotiator:CreateModifier( "DISTRACTION_CONFUSION" )

                        local card = Negotiation.Card( "assassin_fight_call_for_help", minigame.player_negotiator.agent )
                        card.show_dealt = true
                        card:TransferCard(minigame:GetDrawDeck())
                    end,
                    on_success = function(cxt, minigame)
                        cxt:Dialog("DIALOG_HELP_ARRIVE")
                        cxt.quest:GetCastMember("assassin"):MoveToLimbo()
                        cxt:GoTo("STATE_RESUME_SLEEP")
                    end,
                    on_fail = function(cxt, minigame)
                        local help_inst = minigame.player_negotiator:FindModifier("HELP_UNDERWAY")
                        cxt.quest.param.help_called = help_inst and true or false
                        if help_inst then
                            cxt.quest.param.help_arrive_time = help_inst.turns_left
                        else
                            cxt.quest.param.help_arrive_time = 99
                        end

                        cxt:Dialog("DIALOG_FIGHT_PHRASE")
                        local battle_def = {
                            flags = BATTLE_FLAGS.SELF_DEFENCE | BATTLE_FLAGS.NO_FLEE | BATTLE_FLAGS.BOSS_FIGHT,
                            -- survival_turns = cxt.quest.param.help_arrive_time + 3,
                            on_start_battle = function(battle)
                                local fighter = battle:GetFighterForAgent(cxt:GetAgent())
                                fighter.can_surrender = false
                            end,
                            on_win = function(cxt, minigame)
                                local survival_turns = minigame.scenario:GetSurvivalTurns()
                                cxt.quest.param.help_arrive_time = survival_turns and (survival_turns - minigame.turns + 1 ) or 99
                                cxt.quest.param.help_arrived = cxt.quest.param.help_arrive_time <= 0
                                cxt.quest.param.assassin_dead = cxt:GetAgent():IsDead()

                                if cxt.quest.param.assassin_dead then
                                    cxt:Dialog("DIALOG_PST_FIGHT_DEAD")
                                elseif cxt.quest.param.help_arrived then
                                    cxt:Dialog("DIALOG_HELP_ARRIVE")
                                else
                                    cxt:Dialog("DIALOG_PST_FIGHT_SURRENDER")
                                end
                                if not cxt.quest.param.assassin_dead then
                                    cxt.quest:GetCastMember("assassin"):MoveToLimbo()
                                end
                                cxt.quest:GetCastMember("responder"):MoveToLimbo()
                                cxt:GoTo("STATE_RESUME_SLEEP")
                            end,
                        }
                        if cxt.quest.param.help_called then
                            battle_def.flags = battle_def.flags | BATTLE_FLAGS.SURVIVAL
                            battle_def.survival_turns = cxt.quest.param.help_arrive_time * 2
                        end
                        cxt:Opt("OPT_DEFEND_SELF")
                            :Battle(battle_def)
                    end,
                }
        end)
    :State("STATE_RESUME_SLEEP")
        :Loc{
            DIALOG_SLEEP_INTRO = [[
                * After a long day, nothing left to do but sleep.
                * It's not like there's going to be two assassinations per day, right?
            ]],
            OPT_SLEEP = "Sleep",
            DIALOG_WAKE = [[
                * What do you know, you're not dead!
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_SLEEP_INTRO")
            cxt:Opt("OPT_SLEEP")
                :PreIcon(global_images.sleep)
                :Fn(function(cxt) 
                    -- local grog = cxt.location
                    -- cxt.encounter:DoLocationTransition( cxt.quest:GetCastMember("player_room") )
                    -- grog:SetPlax()
                    ConvoUtil.DoSleep(cxt, "DIALOG_WAKE")
                    
                    cxt.quest:Complete()

                    cxt:Opt("OPT_LEAVE")
                        :MakeUnder()
                        :Fn(function() 
                            cxt.encounter:DoLocationTransition( cxt.quest:GetCastMember("home") )
                            cxt:End()
                        end)

                end)
        end)