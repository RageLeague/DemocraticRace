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
                * Sike, that's not happening. There's an assassin in this room, whom you couldn't pretend not to hear.
                player:
                    !left
                    !angry_accuse
                    Alright. Show yourself. No reason to pretend you're still hidden.
                agent:
                    !right
                    Ugh. Fine.
                * {agent.HeShe} reveals {agent.himher}self.
                agent:
                    You're the new politician in the election?
                player:
                    Got it in one.
                agent:
                    Someone very powerful decided you we're a threat to their bottom line.
                    !fight
                    I assume you won't go without a scuffle.
                player:
                    !fight
                    Contract killing, eh?
                    I used to do that for a living. Of course, that was before I became a politician.
                    Anyway, you wanna dance? Let's dance.
                * Just as you prepare your weapon, something just occurred to you.
                player:
                    !scared
                * You have fought very few, if any, battle since you decide to run for president.
                * This assassin might've been easy before, but that was before you hung up your weapons.
                * You need backup. Luckily, you can, but it'll take time.
                player:
                    !point
                    Alright, Alright. Surely you can give me the right to my last words.
                agent:
                    !crossed
                    I suppose, but make them quick.
                * You need to call for help and distract {agent} until help arrives!
            ]],
            OPT_DISTRACT = "Distract {agent}",
            TT_DISTRACT = "Distract {agent} until you can call for help.\n"..
                "After calling for help, keep {agent.himher} occupied through negotiation or combat until help arrives!",

            GOAL_CALL_HELP = "(1/3) Call for help",
            GOAL_MAINTAIN_CONNECTION = "(2/3) Describe your current situation to the dispatcher ({1}/{2})",
            GOAL_AWAIT_RESCUE = "(3/3) Await rescue (Negotiate for {1} {1*turn|turns} or battle for {2} {2*turn|turns})",

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
                    What's going on?
                    !fight
                    Freeze! Under the authority of the Admiralty, you're under arrest for breaking and entering!
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
                    You're getting sloppy, {player}.
                    Sooner or later I'll have your head.
                player:
                    !hips
                    $happyCocky
                    If only it were that simple for you.
                    But I'm afraid our time is going to be cut short.
                * As if on cue, the Admiralty responder enters your room.
                responder:
                    !left
                    What's going on?
                    !fight
                    Freeze! Under the authority of the Admiralty, you're under arrest for attempted murder!
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
                player:
                    And I bequeath my-
                agent:
                    Hesh, shut up! This is the 6th time you've said that.
                    If I knew bagging a politician came with a recited memoir, I'd have asked for extra.
                    !throatcut
                    Let's finish this.
                player:
                    !fight
                {help_called?
                    * You called for help, but couldn't stall long enough for them to arrive.
                    * You hope that you can survive long enough to see the help arrive.
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
                    I see you...shook off the rust quite well.
                    You got me dead to rights here.
                player:
                    You put up a good fight. I'll give you that much.
                    Tell me, who sent you.
                agent:
                    You'll have to forgive me, but I can't disclose that.
                    How about this? You let me go, and I'll give you this graft.
                player:
                    !left
                    Deal. You did what you had to do, following with the contract. I respect that.
                    Now scarper off before I change my mind.
                    !exit
                * {agent} ran away, leaving you tired and hurt.
                {help_called?
                    * It is not long before the responders arrive.
                    responder:
                        !right
                        What's going on?
                    player:
                        An assassin tried to kill me, but {agent.heshe} got away before you can get here.
                    responder:
                        !facepalm
                        I hate it when that happens.
                        Of course someone will try to assassinate a candidate.
                        Why would my job be any easier?
                    player:
                        Uh... Aren't you going to chase after {agent.himher}?
                    responder:
                        Oh, yes. Of course. Good night and good luck.
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
                        By the-
                        !angry
                        What did you do?
                    * I have to say, the way the scene is set up, it does look like you killed {agent}.
                        {not responder_liked?
                            player:
                                I had a...bit of a scuffle with {agent}. It got slightly out of hand.
                            responder:
                                A likely story. In fact, it's likely true.
                                You broke into {primary_advisor}'s office and killed {agent} in cold blood!
                                I'm taking you to the station for questioning.
                        }
                        {responder_liked?
                            player:
                                {agent} and I got into a fight because they came to kill me.
                                You got to believe me! They came at me first.
                            responder:
                                !thought
                                Well, standard procedure says I have to take you to be badgered and questioned in an Admiralty office.
                                !permit
                                But you seem to be innocent, considering this guy came with a massive weapon like that.
                                Plus it saves me the paperwork.
                            player:
                                !surprised
                                Really?
                            responder:
                                Don't be so surprised.
                                I'm getting rid of this body.
                                Here. For your troubles.
                            * {responder.HeShe} hands you a graft found on the body.
                                !exit
                        }
                }
                {not help_called?
                    * The air stills as their body hits the floor.
                    * You clean up the scene, and while you're at it, you pick the body's pockets.
                    * Out of all the worthless junk {agent.heshe} carries, you find a whole graft!
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

            TheGame:FE():FindScreen( Screen.ConversationScreen ).character_music = nil
            TheGame:GetMusic():StopCharacterMusic()

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
                            return loc.format(cxt:GetLocString("GOAL_AWAIT_RESCUE"), help_inst.stacks, help_inst.stacks * 2 )
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

                        local METRIC_DATA =
                        {
                            boss = cxt:GetAgent():GetContentID(),
                            player_data = TheGame:GetGameState():GetPlayerState(),
                        }

                        DemocracyUtil.SendMetricsData("DAY_1_BOSS_START", METRIC_DATA)
                    end,
                    on_success = function(cxt, minigame)
                        local METRIC_DATA =
                        {
                            boss = cxt:GetAgent():GetContentID(),
                            result = "WIN_NEGOTIATION",
                            player_data = TheGame:GetGameState():GetPlayerState(),
                        }
                        DemocracyUtil.SendMetricsData("DAY_1_BOSS_END", METRIC_DATA)

                        cxt:Dialog("DIALOG_HELP_ARRIVE")
                        cxt.quest:GetCastMember("assassin"):MoveToLimbo()
                        DemocracyUtil.GiveBossRewards(cxt)
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

                        local METRIC_DATA =
                        {
                            boss = cxt:GetAgent():GetContentID(),
                            result = "LOSE_NEGOTIATION",
                            time_left = cxt.quest.param.help_arrive_time,
                            player_data = TheGame:GetGameState():GetPlayerState(),
                        }
                        DemocracyUtil.SendMetricsData("DAY_1_BOSS_END", METRIC_DATA)

                        cxt:Dialog("DIALOG_FIGHT_PHRASE")
                        local battle_def = {
                            flags = BATTLE_FLAGS.SELF_DEFENCE | BATTLE_FLAGS.NO_FLEE | BATTLE_FLAGS.BOSS_FIGHT,
                            -- survival_turns = cxt.quest.param.help_arrive_time + 3,
                            on_start_battle = function(battle)
                                local fighter = battle:GetFighterForAgent(cxt:GetAgent())
                                -- fighter.can_surrender = false
                            end,
                            on_win = function(cxt, minigame)
                                local survival_turns = minigame.scenario:GetSurvivalTurns()
                                cxt.quest.param.help_arrive_time = survival_turns and (survival_turns - minigame.turns + 1 ) or 99
                                cxt.quest.param.help_arrived = cxt.quest.param.help_arrive_time <= 0
                                cxt.quest.param.assassin_dead = cxt:GetAgent():IsDead()
                                cxt.quest.param.responder_liked = cxt:GetCastMember("responder"):GetRelationship() > RELATIONSHIP.NEUTRAL

                                local METRIC_DATA =
                                {
                                    boss = cxt:GetAgent():GetContentID(),
                                    result = "WIN_FIGHT",
                                    player_data = TheGame:GetGameState():GetPlayerState(),
                                }
                                DemocracyUtil.SendMetricsData("DAY_1_BOSS_END", METRIC_DATA)
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
                                DemocracyUtil.GiveBossRewards(cxt)
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
                    DemocracyUtil.GiveBossRewards(cxt)
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
                        DemocracyUtil.GiveBossRewards(cxt)
                    end)
                    :GoTo("STATE_RESUME_SLEEP")
            cxt:Opt("OPT_ACCEPT_ARREST")
                :Dialog("DIALOG_ACCEPT_ARREST")
                :Fn(function(cxt)
                    local flags = {
                        suspicion_of_murder = true,
                    }
                    DemocracyUtil.DoEnding(cxt, "arrested", flags)
                end)
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
