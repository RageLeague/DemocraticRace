local negotiation_defs = require "negotiation/negotiation_defs"
local CARD_FLAGS = negotiation_defs.CARD_FLAGS
local EVENT = negotiation_defs.EVENT

local SURVIVAL_TURNS = 12

local QDEF = QuestDef.Define
{
    title = "Final Steps",
    desc = "Review the progress you've made today with {primary_advisor}, and go to sleep.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/summary.png"),

    qtype = QTYPE.STORY,

    events = {
        resolve_negotiation = function( quest, minigame, repercussions )
            if repercussions and CheckBits( minigame:GetFlags(), NEGOTIATION_FLAGS.WORDSMITH ) then
                -- DBG(repercussions)
                repercussions.loot.is_boss_fight = true
            end
        end,
        do_sleep = function( quest, player, sleep_data )
            if quest.param.dead_body then
                sleep_data.resolve_gain = math.round(sleep_data.resolve_gain * 0.5)
            end
        end,
    }
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

-- :AddObjective{
--     id = "meet_advisor",
--     title = "Meet up with {primary_advisor}",
--     desc = "Review the progress you've made today with {primary_advisor}, and plan for your next move.",
--     mark = {"primary_advisor"},
--     state = QSTATUS.ACTIVE,
-- }
:AddObjective{
    id = "go_to_sleep",
    title = "Go to sleep",
    desc = "When you've done all you need to do, it's time to go to sleep.",
    mark = {"primary_advisor"},
    state = QSTATUS.ACTIVE,
}
DemocracyUtil.AddHomeCasts(QDEF)
-- QDEF:AddConvo("meet_advisor", "primary_advisor")
--     :AttractState("STATE_TALK")
--         :Loc{
--             DIALOG_INTRO = [[
--                 player:
--                     !left
--                 agent:
--                     !right
--                     [p] nice work today
--                 player:
--                     thx
--                 agent:
--                     !give
--                     here's your pay.
--                     do your free time or whatever.
--             ]],
--             DIALOG_INTRO_LOW_SUPPORT = [[
--                 player:
--                     !left
--                 agent:
--                     !right
--                     [p] i have low expectations for you, but i was still surprised about how bad you did.
--                     i'm done with you.
--                 player:
--                     oh come on!
--             ]],
--             DIALOG_INTRO_PST = [[
--                 agent:
--                     go to bed when you're ready.
--             ]]
--         }
--         :Fn(function(cxt)
--             if DemocracyUtil.TryMainQuestFn("GetGeneralSupport") >= 10 then
--                 cxt:Dialog("DIALOG_INTRO")

--                 local money = DemocracyUtil.TryMainQuestFn("CalculateFunding")
--                 cxt.enc:GainMoney(money)
--                 cxt:Dialog("DIALOG_INTRO_PST")
--                 cxt.quest:Complete("meet_advisor")
--                 cxt.quest:Activate("go_to_sleep")
--                 DemocracyUtil.StartFreeTime()
--             else
--                 cxt:Dialog("DIALOG_INTRO_LOW_SUPPORT")
--                 DemocracyUtil.AddAutofail(cxt, function(cxt)
--                     cxt.quest:Complete("meet_advisor")
--                     cxt.quest:Activate("go_to_sleep")
--                     DemocracyUtil.StartFreeTime()
--                 end)
--             end
--         end)
QDEF:AddConvo("go_to_sleep", "primary_advisor")
    :Loc{
        OPT_GO_TO_SLEEP = "Go to sleep",
        DIALOG_GO_TO_SLEEP = [[
            player:
                I'm ready to go to bed.
            agent:
                Well, if that's the case, it's time for me to leave. Good night.
            player:
                That's it?
                I was hoping for a little more.
            agent:
                Little more of what?
            player:
                I don't know.
                Bosses, or some other challenges?
            agent:
                !dubious
                ...
            player:
                No?
                !handwave
                Just- Forget I said anything.
            agent:
                Good night.
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
                * You are about to go to sleep when you sense something is wrong.
                player:
                    !left
                * Your grifter instinct tells you that someone is hiding in this room, probably wants to assassinate you.
                player:
                    !angry_accuse
                    Who's there?
                agent:
                    !right
                    !surprised
                    How did you see me? I was so well hidden.
                player:
                    I didn't. But thanks for letting me know you're here.
                agent:
                    Oh.
                    !fight
                    Well, no matter. Time to die.
                player:
                    !fight
                    Here I thought there wouldn't be any boss fights today.
                * Just as you prepare your weapon, something just occured to you.
                player:
                    !scared
                * You have fought very few, if any, battle since you decide to run for president.
                * Your skills are getting rusty. There is no way you would win a straight fight against a day 2 boss on Sal's campaign.
                * Looks like you have to find another way.
                player:
                    !point
                    Look behind you!
                agent:
                    !cagey
                    Wait, what?
                * You need to call for help and distract {agent} until help arrives!
            ]],
            OPT_DISTRACT = "Distract {agent}",
            TT_DISTRACT = "Distract {agent} until you can call for help.\n"..
                "After calling for help, survive long enough for the responders to arrive.",

            GOAL_CALL_HELP = "(1/3) Call for help",
            GOAL_MAINTAIN_CONNECTION = "(2/3) Describe your current situation to the dispacher ({1}/{2})",
            GOAL_AWAIT_RESCUE = "(3/3) Await rescue (In {1} {1*turn|turns})",

            DIALOG_HELP_ARRIVE = [[
                agent:
                    !dubious
                    You know you're just delaying the inevitable, right?
                    !throatcut
                    Time for you to go to sleep, forever!
                player:
                    !hips
                    $happyCocky
                    On the contrary, I think it's time for you to surrender.
                agent:
                    Oh yeah? Why should I?
                player:
                    Because, you see.
                    You're under arrest.
                * As if on cue, the Admiralty responder enters your room.
                responder:
                    !left
                    !fight
                    What's going on?
                agent:
                    !surprised
                    Oh, Hesh.
                    !reach_weapon
                    Time to bounce!
                    !exit
                * {agent} fled the scene. How typical.
                * {agent.HeShe} dropped something while scrambling to get away.
                responder:
                    !fight
                    Oh no you don't!
                    !exit
                * {responder} runs after {agent}.
                * Finally, after a long day, you're all by yourself, safe from assassinations.
                * Except this cool graft that {agent} dropped!
                player:
                    !left
                    Sweet!
            ]],
            DIALOG_HELP_ARRIVE_FIGHT = [[
                player:
                    !fight
                agent:
                    !fight
                    You are quite resilient, for a politician with little combat experience.
                    Frankly, I don't think that's gonna save you.
                player:
                    !hips
                    $happyCocky
                    Jokes on you, that's enough for me to survive and you to be arrested.
                * As if on cue, the Admiralty responder enters your room.
                responder:
                    !left
                    !fight
                    What's going on?
                agent:
                    !surprised
                    Oh, Hesh.
                    !reach_weapon
                    Time to bounce!
                    !exit
                * {agent} fled the scene. How typical.
                * {agent.HeShe} dropped something while scrambling to get away.
                responder:
                    !fight
                    Oh no you don't!
                    !exit
                * {responder} runs after {agent}.
                * Finally, after a long day, you're all by yourself, safe from assassinations.
                * Except this cool graft that {agent} dropped!
                player:
                    !left
                    Sweet!
            ]],

            DIALOG_FIGHT_PHRASE = [[
                agent:
                    That's enough. I'm tired with you.
                    !throatcut
                    Time for you to go to sleep, forever!
                player:
                    !fight
                {help_called?
                    * You hope that you will survive long enough for help to arrive.
                }
                {not help_called?
                    * You didn't have time to call for help! Guess you have to settle things the old fashioned way.
                }
            ]],

            DIALOG_PST_FIGHT_SURRENDER = [[
                agent:
                    !injured
                player:
                    !fight
                    Had enough?
                agent:
                    Okay, I have to admit. I severely underestimated you.
                    You somehow can pull it off, despite being significantly underprepared.
                player:
                    So you know that I'm running for president.
                    Tell me, who sent you.
                agent:
                    I'll tell you, if you can catch me!
                    !exit
                * {agent} ran away. Now why didn't you secure {agent.himher} so that this doesn't happen?
                player:
                    !left
                    Hesh damn it!
                {help_called?
                    * It is not long before the responders arrive.
                    responder:
                        !right
                        What's going on?
                    player:
                        An assassin tried to kill me, but {agent.heshe} got away.
                    responder:
                        !facepalm
                        I hate it when that happens.
                        Of course someone will try to assassinate a candidate.
                        Why would my job be any easier?
                    player:
                        Uh... Aren't you going to chase after {agent.himher}?
                    responder:
                        Oh, yes. Of course.
                        !exit
                }
                * Finally, after a long day, you're all by yourself, safe from assassinations.
                * Except this cool graft that {agent} dropped!
                player:
                    !left
                    Sweet!
            ]],
            DIALOG_PST_FIGHT_DEAD = [[
                * {agent} lies dead.
                {help_called?
                    * {responder} arrives a few minutes layer, and sees a dead body.
                    player:
                        !left
                    responder:
                        !right
                        What happened here?
                        !angry
                        What did you do?
                    * I have to say, the way the scene is set up, it does look like you killed {agent}.
                        {not responder_liked?
                            player:
                                This person tries to assassinate me, so I took {agent.himher} out.
                            responder:
                                What are you doing late at night in an office?
                                And it isn't even your office! It belongs to {primary_advisor}!
                                I'm taking you to the station for questioning.
                        }
                        {responder_liked?
                            player:
                                This person tries to assassinate me, so I took {agent.himher} out.
                                It's self defense.
                            responder:
                                !thought
                                Now normally I won't believe in you, considering this scene looks very incriminating.
                                !permit
                                But you look like a trustable character, and this guy here... doesn't.
                                So I'm just going to take your word for it.
                            player:
                                !surprised
                                Really?
                            responder:
                                Don't be so surprised.
                                I'm getting rid of this body.
                            player:
                                !point
                                Wait, before you go, can I have that graft?
                            responder:
                                !shrug
                                I mean, sure?
                                Anyway, see you later!
                                !exit
                        }
                }
                {not help_called?
                    * There is no one nearby. Now you're stuck with a dead body for the rest of the night.
                    * Hey, at least you got a graft from {agent}'s dead body, so that counts for something.
                }
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
                    flags = NEGOTIATION_FLAGS.NO_CORE_RESOLVE | NEGOTIATION_FLAGS.WORDSMITH, -- this is the boss
                    reason_fn = function(minigame)
                        local help_inst = minigame.player_negotiator:FindModifier("HELP_UNDERWAY")
                        local call_inst = minigame.player_negotiator:FindModifier("CONNECTED_LINE")
                        if help_inst then
                            return loc.format(cxt:GetLocString("GOAL_AWAIT_RESCUE"), help_inst.stacks )
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

                        minigame.help_turns = SURVIVAL_TURNS
                    end,
                    on_success = function(cxt, minigame)
                        cxt:Dialog("DIALOG_HELP_ARRIVE")
                        cxt.quest:GetCastMember("assassin"):MoveToLimbo()
                        cxt:GoTo("STATE_RESUME_SLEEP")
                    end,
                    on_fail = function(cxt, minigame)
                        local help_inst = minigame.player_negotiator:FindModifier("HELP_UNDERWAY")
                        cxt.quest.param.help_called = help_inst and true
                        if help_inst then
                            cxt.quest.param.help_arrive_time = help_inst.stacks
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
                                cxt.quest.param.responder_liked = cxt:GetCastMember("responder"):GetRelationship() > RELATIONSHIP.NEUTRAL
                                if cxt.quest.param.assassin_dead then
                                    cxt:Dialog("DIALOG_PST_FIGHT_DEAD")
                                    if cxt.quest.param.help_called then
                                        if not cxt.quest.param.responder_liked then
                                            cxt:GoTo("STATE_ARREST")
                                            return
                                        end
                                    else
                                        cxt.quest.param.dead_body = true
                                    end
                                elseif cxt.quest.param.help_arrived then
                                    cxt:Dialog("DIALOG_HELP_ARRIVE_FIGHT")
                                else
                                    cxt:Dialog("DIALOG_PST_FIGHT_SURRENDER")
                                end
                                if not cxt.quest.param.assassin_dead then
                                    cxt.quest:GetCastMember("assassin"):MoveToLimbo()
                                end
                                cxt.quest:GetCastMember("responder"):MoveToLimbo()
                                if cxt.quest.param.help_called then
                                    cxt.player:Remember("SAVED_BY_ADMIRALTY", cxt.quest:GetCastMember("responder"))
                                end
                                ConvoUtil.GiveBossRewards(cxt)
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
    :State("STATE_ARREST")
        :Loc{
            OPT_EXPLAIN = "Explain the situation",
            DIALOG_EXPLAIN = [[
                player:
                    I swear, it isn't what it looks like.
                agent:
                    That's what they all say.
                    !clap
                    Go on. Let's here it! What makes you innocent?
            ]],
            DIALOG_EXPLAIN_SUCCESS = [[
                player:
                    I'm new to this town, see?
                    {primary_advisor} agreed to let me stay here for the night.
                    You can immediately check with {primary_advisor} to see if I'm telling the truth.
                agent:
                    Okay, then.
                * {agent} calls {primary_advisor}.
                agent:
                    This is {agent} of the Admiralty.
                    I have a suspicious individual here. {player.HeShe} claims that you allowed {player.himher} to stay in your office for the night.
                    Is that true?
                    ...
                    Is that so?
                    Well then.
                    Sorry to bother you.
                * {agent} hangs up.
                agent:
                    In that case, I guess you're telling the truth.
                    I'm disposing this body. Have a good night.
                    !exit
                * Phew! That could've been way worse.
            ]],
            DIALOG_EXPLAIN_FAILURE = [[
                * The more you try to explain yourself, the more you seem guilty.
                * It's almost as if your tongue is tied.
                agent:
                    That's it, I've heard enough.
                    You can talk more when you're in the station.
            ]],
            OPT_RESIST_ARREST = "Resist arrest",
            DIALOG_RESIST_ARREST = [[
                player:
                    !fight
                    You're not taking me in alive!
            ]],
            DIALOG_RESIST_ARREST_WIN = [[
                {dead?
                    * Another body added to the collection.
                    * You're having a corpse party tonight!
                }
                {not dead?
                agent:
                    !injured
                player:
                    !angry
                    I'm not coming.
                    Final offer.
                agent:
                    You have plenty of energy left for someone who fought of a supposed assassin.
                    Fine. I'll leave.
                    Just you know, assaulting an officer on duty is a crime.
                player:
                    Don't know, don't care.
                agent:
                    !exit
                }
                * This aggression will surely not go unnoticed.
            ]],
            OPT_ACCEPT_ARREST = "Accept arrest",
            DIALOG_ACCEPT_ARREST = [[
                player:
                    Fine, I'm coming.
                    It's going to be clear that I'm innocent, anyway.
                agent:
                    Yeah, sure.
            ]],
        }
        :RunLoopingFn(function(cxt)
            if cxt:FirstLoop() then
                cxt:TalkTo(cxt:GetCastMember("responder"))
                cxt.player:Remember("ACCUSED_BY_ADMIRALTY", cxt.quest:GetCastMember("responder"))
            end

            cxt:BasicNegotiation("EXPLAIN")
                :OnSuccess()
                :Fn(function(cxt)
                    cxt.quest:GetCastMember("responder"):MoveToLimbo()
                    ConvoUtil.GiveBossRewards(cxt)
                end)
                :GoTo("STATE_RESUME_SLEEP")
            
            cxt:Opt("OPT_RESIST_ARREST")
                :Dialog("DIALOG_RESIST_ARREST")
                :Battle{}
                :OnWin()
                    :Dialog("DIALOG_RESIST_ARREST_WIN")
                    :Fn(function(cxt)
                        cxt.quest.param.dead_body = true
                        cxt.player:Remember("ASSAULTED_ADMIRALTY", cxt.quest:GetCastMember("responder"))
                        ConvoUtil.GiveBossRewards(cxt)
                    end)
                    :GoTo("STATE_RESUME_SLEEP")
            cxt:Opt("OPT_ACCEPT_ARREST")
                :Dialog("DIALOG_ACCEPT_ARREST")
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
            if cxt.quest.param.dead_body then
                cxt.location:Remember("HAS_DEAD_BODY",
                    {cxt:GetCastMember("assassin"):IsDead() and cxt:GetCastMember("assassin") or nil, 
                    cxt:GetCastMember("responder"):IsDead() and cxt:GetCastMember("responder") or nil})
            end

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