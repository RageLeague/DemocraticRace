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

    fill_out_quip_tags = function(quest, tags, agent)
        if quest.param.did_assassination then
            table.insert_unique(tags, "did_assassination")
        end
    end,
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
        local boss_def = TheGame:GetGameProfile():GetNoStreakRandom("SAL_DAY_2_BOSS_PICK", {
            "JAKES_ASSASSIN",
            "JAKES_ASSASSIN2",
            -- Remove hesh boss for now because her wordsmith is kinda too strong.
            -- "HESH_BOSS",
            "MERCENARY_BOSS"
            -- Don't include the rentorian boss because it doesn't make sense for them to be here
        }, 2)
        local assassin = AgentUtil.GetOrSpawnAgentbyAlias(boss_def)
        if assassin and not assassin:IsRetired() then
            table.insert(t, assassin)
        end
    end,
    on_assign = function(quest, agent)
        agent.in_hiding = true
    end,
    no_validation = true,
    optional = true,
}
:AddCast{
    cast_id = "responder",
    cast_fn = function(quest, t)
        local primary_advisor = TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor")
        local responder_def = "ADMIRALTY_PATROL_LEADER"
        if primary_advisor then
            if primary_advisor:GetFactionID() == "SPARK_BARONS" then
                responder_def = "SPARK_BARON_PROFESSIONAL"
                quest.param.baron_responder = true
            elseif primary_advisor:GetFactionID() == "CULT_OF_HESH" then
                responder_def = "LUMINARI"
                quest.param.cult_responder = true
            end
        end
        local choice = AgentUtil.GetFreeAgent(responder_def)
        table.insert(t, choice)
    end,
    no_validation = true,
}

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
            :Fn(function(cxt)
                if not cxt:GetCastMember("assassin") then
                    cxt:GoTo("STATE_NO_ASSASSIN")
                    return
                end
                local first_primary_advisor = TheGame:GetGameState():GetMainQuest() and TheGame:GetGameState():GetMainQuest().param.first_primary_advisor
                if first_primary_advisor and first_primary_advisor ~= cxt:GetCastMember("primary_advisor") then
                    cxt.quest.param.advisor_intervention = true
                    TheGame:GetGameState():GetMainQuest().param.day_1_advisor_intervention = true
                end
                cxt:GoTo("STATE_ASSASSINATION")
            end)
    end)
    :State("STATE_NO_ASSASSIN")
        :Loc{
            DIALOG_INTRO = [[
                * Sike, that's not happening. There's an assassin in this room, whom you couldn't pretend not to hear.
                * Is what you would say normally, given your experience with this kind of situation.
                * But, given your brilliant foresight, you have dispatched the would-be assassin before they become a problem.
                * Now you can rest safely, knowing that you solved a problem before it occurs.
                * You are not getting any boss relics, though.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt:GoTo("STATE_RESUME_SLEEP")
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
                * {agent.HeShe} reveals {agent.self}.
                agent:
                    You're the new politician in the election?
                player:
                    Got it in one.
                {not (player_rook and (hesh_boss or mercenary_boss))?
                agent:
                    Someone very powerful decided you we're a threat to their bottom line.
                    !fight
                    I assume you won't go without a scuffle.
                player:
                    Contract killing, eh?
                    !hips
                    I used to do that for a living. Of course, that was before I became a politician.
                    !fight
                    Anyway, you wanna dance? Let's dance.
                }
                {player_rook?
                    {hesh_boss?
                        agent:
                            Someone very powerful decided you we're a threat to their bottom line.
                            !fight
                            Lucky for me. Time to settle an old score.
                        player:
                            Didn't think you would be the kind to take assassination contracts.
                            !cruel
                            You must fell off pretty hard to stoop this low.
                            !fight
                            Let me end your miserable existence, if you wish to die that much.
                    }
                    {mercenary_boss?
                        agent:
                            Someone very powerful decided you we're a threat to their bottom line.
                            !fight
                            Lucky for me. You should've paid for what you did ages ago.
                        player:
                            !sigh
                            Still, you never learn anything do you?
                            Blaming others for your shortcoming, when you have only yourself to blame.
                            !fight
                            Let's see where your childish tantrum gets you, eh?
                    }
                }
                * Just as you prepare your weapon, something just occurred to you.
                player:
                    !scared
                * You have fought very few, if any, battle since you decide to run for president.
                * This assassin might've been easy before, but that was before you hung up your weapons.
                {not advisor_intervention?
                    * You need backup. Luckily, you can, but it'll take time.
                    * You need to call for help and distract {agent} until help arrives!
                }
                {advisor_intervention?
                    * Just as you start to think about getting backups, the door to your room opens.
                    primary_advisor:
                        !left
                        !scared
                    * You turn around to see {primary_advisor} at the door, startled by the unexpected guest.
                    primary_advisor:
                        What are you doing here in my office?
                    agent:
                        Oh, Hesh, witnesses!
                        Time for you to both die!
                    * That was a rather unexpected turn of event. {primary_advisor} actually appeared!
                    * But {primary_advisor} is not much of a fighter. You need to distract {agent} while {primary_advisor} find actual help!
                }
            ]],
            OPT_DISTRACT = "Distract {agent}",
            TT_DISTRACT = "Distract {agent} until you can call for help.\n"..
                "After calling for help, keep {agent.himher} occupied through negotiation or combat until help arrives!",
            TT_DISTRACT_ADVISOR = "Keep {agent} occupied through negotiation or combat until help arrives!\n\n<#PENALTY>{agent} will start with extra impatience!</>",
            DIALOG_DISTRACT = [[
                {not advisor_intervention?
                player:
                    !point
                    Alright, Alright. Surely you can give me the right to my last words.
                agent:
                    !crossed
                    I suppose, but make them quick.
                }
                {advisor_intervention?
                primary_advisor:
                    !right
                player:
                    !left
                    !point
                    {primary_advisor}, go find someone who can fight.
                    I'll distract {agent.himher}.
                agent:
                    !right
                    !dubious
                    You know I can still hear you, right?
                }
            ]],

            GOAL_CALL_HELP = "(1/3) Call for help",
            GOAL_MAINTAIN_CONNECTION = "(2/3) Describe your current situation to the dispatcher ({1}/{2})",
            GOAL_AWAIT_RESCUE = "(3/3) Await rescue (Negotiate for {1} {1*turn|turns} or battle for {2} {2*turn|turns})",

            DIALOG_HELP_ARRIVE = [[
                {not helped_during_fight?
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
                        Because, you see...
                        You're under arrest.
                }
                {helped_during_fight?
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
                }
                {not baron_responder?
                    * As if on cue, the {cult_responder?Cult patrol|Admiralty responder} enters your room.
                    {advisor_intervention?
                        primary_advisor:
                            !left
                            !angry
                        * {primary_advisor} also comes in.
                        primary_advisor:
                            !angry_accuse
                            That's the one! That is the assassin that break into my office!
                    }
                    {not advisor_intervention?
                        responder:
                            !left
                            What's going on?
                    }
                    responder:
                        !left
                        !fight
                        {not cult_responder?
                            Freeze! Under the authority of the Admiralty, you're under arrest for breaking and entering!
                        }
                        {cult_responder?
                            Heretics! You are trespassing on sacred ground!
                        }
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
                    {not advisor_intervention?
                        * Finally, after a long day, you're all by yourself, safe from assassinations.
                        * Except this cool graft that {agent} dropped!
                        player:
                            !left
                            Sweet!
                    }
                    {advisor_intervention?
                        * You are left alone with {primary_advisor}.
                        player:
                            !left
                        primary_advisor:
                            !right
                            What a day, huh?
                            Someone must've really hated you to send an assassin after you.
                        player:
                            !shrug
                            Eh, I've made a few enemies in the past.
                            Not sure why they decided to send an assassin now, of all times.
                        primary_advisor:
                            !handwave
                            Whatever. At least you are alive.
                        * {primary_advisor} picked up the thing {agent} dropped.
                        primary_advisor:
                            !give
                            Here. You can have this.
                    }
                }
                {baron_responder?
                    * As if on cue, the Baron responder enters your room.
                    {advisor_intervention?
                        primary_advisor:
                            !left
                            !angry
                        * {primary_advisor} also comes in.
                        primary_advisor:
                            !angry_accuse
                            That's the one! That is the assassin that break into my office!
                    }
                    {not advisor_intervention?
                        responder:
                            !left
                            What's going on?
                    }
                    responder:
                        !left
                        !fight
                        You are trespassing on private property! Surrender now!
                    agent:
                        !surprised
                        Oh, Hesh.
                        !reach_weapon
                        Time to bounce!
                        !exit
                    * {agent} fled the scene. How typical.
                    * {agent.HeShe} dropped something while scrambling to get away.
                    * {responder} doesn't seem to care if {agent} is running away, though.
                    * Instead, {responder.heshe} addresses you.
                    player:
                        !left
                    responder:
                        !right
                    {not player_arint?
                        What are you doing here? You are not a Baron.
                    }
                    {player_arint?
                        Lieutenant, what are you doing here? This isn't the Grout Bog.
                    }
                    {not advisor_intervention?
                        player:
                            {primary_advisor} allowed me to stay here.
                        responder:
                            Is that so?
                            Well, in that case, {primary_advisor} will be charged for this response.
                            {primary_advisor.HeShe} should receive a bill for it tomorrow morning.
                            !salute
                            If there is no more issues, I'll be taking my leave.
                            !exit
                        * You are not sure how {primary_advisor} would react to a surprise bill.
                        * But at least you are alive. All by yourself. Safe from assassinations.
                        * Except this cool graft that {agent} dropped!
                        player:
                            !left
                            Sweet!
                    }
                    {advisor_intervention?
                        primary_advisor:
                            !left
                            {not primary_advisor_diplomacy?
                                {player.HeShe}'s with me. I allowed {player.himher} to stay in my office for the night.
                            }
                            {primary_advisor_diplomacy?
                                {player.HeShe}'s a mutual. I allowed {player.himher} to stay in my office for the night.
                            }
                        responder:
                            !shrug
                            If you say so.
                            By the way, this response is not free. You will receive a bill for it tomorrow morning.
                        primary_advisor:
                            {not primary_advisor_diplomacy?
                                !angry_shrug
                                Oh come on! Are you really going to charge me for this?
                            }
                            {primary_advisor_diplomacy?
                                !crossed
                                That is not very cash money of you, {responder}. Only a cringe person like you would do that.
                            }
                        responder:
                            Them's the rules. You should know this.
                            !salute
                            Until then, have a good night.
                            !exit
                        * {responder} exits, leaving you alone with {primary_advisor}.
                        primary_advisor:
                            !right
                        player:
                            !left
                            What was that about a bill?
                        primary_advisor:
                            {not primary_advisor_diplomacy?
                                I wouldn't worry about it. I'll handle it just fine.
                            }
                            {primary_advisor_diplomacy?
                                Don't worry. I am loaded with the bucks.
                            }
                            !hips
                            But man, what a day, huh?
                            Someone must've really hated you to send an assassin after you.
                        player:
                            !shrug
                            Eh, I've made a few enemies in the past.
                            Not sure why they decided to send an assassin now, of all times.
                        primary_advisor:
                            !handwave
                            Whatever. At least you are alive.
                        * {primary_advisor} picked up the thing {agent} dropped.
                        primary_advisor:
                            !give
                            Here. You can have this.
                    }
                }
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
                {not advisor_intervention?
                    {help_called?
                        * You called for help, but couldn't stall long enough for them to arrive.
                        * You hope that you can survive long enough to see the help arrive.
                    }
                    {not help_called?
                        * You didn't have time to call for help! Guess you have to settle things the old fashioned way.
                    }
                }
                {advisor_intervention?
                    * You didn't stall enough time for help to arrive!
                    * You hope that {primary_advisor} can find the help and save you.
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
                    !permit
                    How about this? You let me go, and I'll give you this graft.
                player:
                    !left
                    Deal. You did what you had to do, following with the contract. I respect that.
                    Now scarper off before I change my mind.
                agent:
                    !exit
                * {agent} ran away, leaving you tired and hurt.
                {help_called?
                    * It is not long before the responders arrive.
                    {not advisor_intervention?
                        responder:
                            !right
                            What's going on?
                        player:
                            An assassin tried to kill me, but {agent.heshe} got away before you can get here.
                    }
                    {advisor_intervention?
                        primary_advisor:
                            !right
                        * {primary_advisor} also comes in with {responder.himher}.
                        primary_advisor:
                            !hips
                            Unbelievable! You actually fended the assassin off!
                            {primary_advisor_hostile?
                                Of course, nobody knows how to fight off assassin better than me, but your skills are pretty <i>huge</> too.
                            }
                        responder:
                            !right
                            Wait, what am I here for?
                        primary_advisor:
                            !left
                            Yeah, an assassin tried to kill {player}, but it seems like {agent.heshe} got away.
                    }
                    responder:
                        !palm
                        I hate it when that happens.
                        Of course someone will try to assassinate a candidate.
                        Why would my job be any easier?
                    player:
                        !left
                        Uh... Aren't you going to chase after {agent.himher}?
                    responder:
                    {not baron_responder?
                        Oh, yes. Of course. Good night and good luck.
                        !exit
                        * {responder} leaves, presumably chasing {agent}.
                        {advisor_intervention?
                            * You are left alone with {primary_advisor}.
                        }
                    }
                    {baron_responder?
                        Not really. I get paid to protect Baron property, not arrest people.
                        {not advisor_intervention?
                            responder:
                                Speaking of getting paid, is this {primary_advisor}'s office?
                            player:
                                !dubious
                                Yes...? What about it?
                            responder:
                                Well, in that case, {primary_advisor} will be charged for this response.
                                {primary_advisor.HeShe} should receive a bill for it tomorrow morning.
                                !salute
                                If there are no more issues, I'll be taking my leave.
                                !exit
                            * You are not sure how {primary_advisor} would react to a surprise bill.
                            * But that is not an issue until tomorrow.
                        }
                        {advisor_intervention?
                            primary_advisor:
                                !left
                                Speaking of getting paid, is this your office, {primary_advisor}?
                            player:
                                !dubious
                                Yes...? What about it?
                            responder:
                                By the way, this response is not free. You will receive a bill for it tomorrow morning.
                            primary_advisor:
                                {not primary_advisor_diplomacy?
                                    !angry_shrug
                                    Oh come on! Are you really going to charge me for this?
                                }
                                {primary_advisor_diplomacy?
                                    !crossed
                                    That is not very cash money of you, {responder}. Only a cringe person like you would do that.
                                }
                            responder:
                                Them's the rules. You should know this.
                                !salute
                                Until then, have a good night.
                                !exit
                            * {responder} exits, leaving you alone with {primary_advisor}.
                            primary_advisor:
                                !right
                            player:
                                !left
                                What was that about a bill?
                            primary_advisor:
                                {not primary_advisor_diplomacy?
                                    I wouldn't worry about it. I'll handle it just fine.
                                }
                                {primary_advisor_diplomacy?
                                    Don't worry. I am loaded with the bucks.
                                }
                        }
                    }
                }
                {not advisor_intervention?
                    * Finally, after a long day, you're all by yourself, safe from assassinations.
                    * Except this cool graft that {agent} gave you!
                    player:
                        !left
                        Sweet!
                }
                {advisor_intervention?
                    player:
                        !left
                    primary_advisor:
                        !right
                        What a day, huh?
                        Someone must've really hated you to send an assassin after you.
                    player:
                        !shrug
                        Eh, I've made a few enemies in the past.
                        Not sure why they decided to send an assassin now, of all times.
                    primary_advisor:
                        !handwave
                        Whatever. At least you are alive.
                    * You take a good look at the graft {agent} gave you.
                    * You can probably make good use of this.
                }
            ]],
            DIALOG_PST_FIGHT_DEAD = [[
                * {agent} lies dead.
                {help_called?
                    {not advisor_intervention?
                        * {responder} arrives a few minutes later, and sees a dead body.
                        player:
                            !left
                        responder:
                            !right
                            By the-
                            !angry
                            What did you do?
                        * I have to say, the way the scene is set up, it does look like you murdered {agent}.
                        {not responder_liked?
                            player:
                                I had a...bit of a scuffle with {agent}. It got slightly out of hand.
                            responder:
                                A likely story. In fact, it's likely true.
                                !angry_accuse
                                You broke into {primary_advisor}'s office and killed {agent} in cold blood!
                            {not baron_responder and not cult_responder?
                                !fight
                                I'm taking you to the station for questioning.
                            }
                            {baron_responder?
                                !fight
                                Prepare to die, trespasser!
                            }
                            {cult_responder?
                                !fight
                                This is the end of you, heretic!
                            }
                        }
                        {responder_liked?
                            player:
                                {agent} and I got into a fight because they came to kill me.
                                You got to believe me! They came at me first.
                            {not baron_responder and not cult_responder?
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
                            }
                            {baron_responder?
                            responder:
                                !shrug
                                Sure, I'll take your word for it.
                            player:
                                !surprised
                                Really?
                            responder:
                                I mean, my job is to keep ruffians out of Baron property.
                                I'm not here to play detective. I get paid either way.
                                !point
                                By {primary_advisor}, by the way. {primary_advisor.HeShe} will receive a bill tomorrow morning for this.
                            player:
                                Oh.
                            }
                            {cult_responder?
                            responder:
                                !hesh_greeting
                                ...
                                Very well.
                            player:
                                !surprised
                                Huh?
                            responder:
                                Hesh thinks you are trustworthy. I simply follow its will.
                            player:
                                !shrug
                                If you say so.
                            * You've interacted with Heshians long enough to know not to question them when they claim that they are "following Hesh's will".
                            }
                            responder:
                                I'm getting rid of this body.
                                !give
                                Here. For your troubles.
                            * {responder.HeShe} hands you a graft found on the body.
                                !exit
                        }
                    }
                    {advisor_intervention?
                        * {responder} arrives a few minutes later, along with {primary_advisor}.
                        primary_advisor:
                            !right
                            !hips
                            Unbelievable! You actually killed the assassin!
                            {primary_advisor_hostile?
                                Of course, nobody knows how to fight off assassin better than me, but your skills are pretty <i>huge</> too.
                            }
                        responder:
                            !right
                            Wait, what is going on here, and why is there a dead body in the middle of the room?
                        primary_advisor:
                            !left
                            Yeah, an assassin tried to kill {player}, but it seems like {player} killed {agent.himher} first.
                        responder:
                            Sounds like a classic case of self defense.
                            I'll just take your word for it. I don't get paid to investigate anyway.
                        {baron_responder?
                            Speaking of getting paid, expect a bill for this response tomorrow morning, {primary_advisor}.
                        primary_advisor:
                            !surprised
                            Wait, what?
                        }
                        responder:
                            Anyway, I'm getting rid of this body.
                        player:
                            !left
                        responder:
                            !give
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
            cxt.quest.param.did_assassination = true
            cxt:Dialog("DIALOG_INTRO")

            -- cxt.quest.param.call_time = 3
            cxt.quest.param.help_called = false
            cxt.quest.param.help_arrive_time = SURVIVAL_TURNS

            cxt:Opt("OPT_DISTRACT")
                :PostText(cxt.quest.param.advisor_intervention and "TT_DISTRACT_ADVISOR" or "TT_DISTRACT")
                :Dialog("DIALOG_DISTRACT")
                :Fn(function(cxt)
                    TheGame:SetTempMusicOverride("DEMOCRATICRACE|event:/democratic_race/music/negotiation/assassin", cxt.enc)
                end)
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

                        if not cxt.quest.param.advisor_intervention then
                            local card = Negotiation.Card( "assassin_fight_call_for_help", minigame.player_negotiator.agent )
                            card.show_dealt = true
                            card:TransferCard(minigame:GetDrawDeck())

                            minigame.help_turns = SURVIVAL_TURNS
                        else
                            minigame.help_turns = SURVIVAL_TURNS + 4
                            minigame.player_negotiator:AddModifier("HELP_UNDERWAY", minigame.help_turns)
                            minigame.opponent_negotiator:CreateModifier( "IMPATIENCE", 2 )
                            minigame.opponent_negotiator.behaviour.impatience_delay = 0
                        end

                        local METRIC_DATA =
                        {
                            boss = cxt:GetAgent():GetContentID(),
                            player_data = TheGame:GetGameState():GetPlayerState(),
                            intervention = cxt.quest.param.advisor_intervention,
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
                        if cxt.quest.param.baron_responder and cxt:GetCastMember("primary_advisor") then
                            cxt:GetCastMember("primary_advisor"):Remember("BILLED_BARON_RESPONSE")
                        end
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
                                        if not cxt.quest.param.responder_liked and not cxt.quest.param.advisor_intervention then
                                            cxt:GoTo("STATE_ARREST")
                                            return
                                        end
                                    else
                                        cxt.quest.param.dead_body = true
                                    end
                                elseif cxt.quest.param.help_arrived then
                                    cxt.enc.scratch.helped_during_fight = true
                                    cxt:Dialog("DIALOG_HELP_ARRIVE")
                                else
                                    cxt:Dialog("DIALOG_PST_FIGHT_SURRENDER")
                                end
                                if not cxt.quest.param.assassin_dead then
                                    cxt.quest:GetCastMember("assassin"):MoveToLimbo()
                                end
                                cxt.quest:GetCastMember("responder"):MoveToLimbo()
                                if cxt.quest.param.help_called then
                                    if cxt.quest.param.baron_responder and cxt:GetCastMember("primary_advisor") then
                                        cxt:GetCastMember("primary_advisor"):Remember("BILLED_BARON_RESPONSE")
                                    end
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
                    That sounds like a lot of work, and I don't care enough or get paid enough to deal with this.
                    I'm just going to assume you are telling the truth.
                    I'm disposing this body. Have a good night.
                    !give
                    Here. For your troubles.
                * {responder.HeShe} hands you a graft found on the body.
                {baron_responder?
                agent:
                    !point
                    And tell {primary_advisor} that this response will be billed.
                }
                    !exit
                * Phew! That could've been way worse.
            ]],
            DIALOG_EXPLAIN_FAILURE = [[
                * The more you try to explain yourself, the more you seem guilty.
                * It's almost as if your tongue is tied.
                agent:
                    That's it, I've heard enough.
                {not baron_responder and not cult_responder?
                    You can talk more when you're in the station.
                }
                {baron_responder?
                    Prepare to die, trespasser!
                }
                {cult_responder?
                    Prepare to die, heretic!
                }
            ]],
            OPT_RESIST_ARREST = "Defend yourself!",
            DIALOG_RESIST_ARREST = [[
                player:
                    !fight
                {not baron_responder and not cult_responder?
                    You're not taking me in alive!
                }
                {baron_responder or cult_responder?
                    I thought I'm already over this.
                }
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
                {not baron_responder and not cult_responder?
                    I'm not coming.
                    Final offer.
                }
                {baron_responder or cult_responder?
                    I don't appreciate your baseless accusation against me.
                    Get lost before I change my mind.
                }
                agent:
                    You have plenty of energy left for someone who fought of a supposed assassin.
                    Fine. I'll leave.
                {not baron_responder and not cult_responder?
                    Just you know, assaulting an officer on duty is a crime.
                }
                {baron_responder?
                    Just you know, the Barons will not take lightly of this transgression.
                }
                {cult_responder?
                    Just remember, Hesh never forgets. You best hope it forgives you.
                }
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
                * You are hauled off to an Admiralty holding cell, where you await for interrogation.
                * This is what you get for going down without a fight.
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
                    if cxt.quest.param.baron_responder and cxt:GetCastMember("primary_advisor") then
                        cxt:GetCastMember("primary_advisor"):Remember("BILLED_BARON_RESPONSE")
                    end
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
            if not cxt.quest.param.baron_responder and not cxt.quest.param.cult_responder then
                cxt:Opt("OPT_ACCEPT_ARREST")
                    :Dialog("DIALOG_ACCEPT_ARREST")
                    :Fn(function(cxt)
                        local flags = {
                            suspicion_of_murder = true,
                        }
                        DemocracyUtil.DoEnding(cxt, "arrested", flags)
                    end)
            end
        end)
    :State("STATE_RESUME_SLEEP")
        :Loc{
            DIALOG_SLEEP_INTRO = [[
                {advisor_intervention?
                    player:
                        !left
                    primary_advisor:
                        !right
                        You should get some sleep, {player}.
                    player:
                        Yeah. That was way too much excitement for one night.
                    primary_advisor:
                        Well, have a good night.
                        !exit
                }
                {not advisor_intervention?
                    * After a long day, nothing left to do but sleep.
                    * It's not like there's going to be two assassinations per day, right?
                }
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
            if cxt.quest.param.did_assassination then
                cxt:Dialog("DIALOG_SLEEP_INTRO")
            end
            if not cxt.quest.param.did_assassination and TheGame:GetGameState():GetMainQuest() then
                TheGame:GetGameState():GetMainQuest().param.no_day_1_assassin = true
            end
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
