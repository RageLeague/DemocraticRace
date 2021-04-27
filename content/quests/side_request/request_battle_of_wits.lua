local function GetELO(agent)
    return agent:CalculateProperty("CHESS_ELO", function(agent)
        return math.round(900 + 150 * (agent:GetRenown() - agent:GetCombatStrength()) + 10 * (agent:GetRenown() ^ 2) + math.random(0, 200))
    end) 
end
-- Calculate the chance of A winning given eloa and elob, using the elo system.
local function GetWinChance(eloa, elob)
    return 1 / (1 + 10 ^ ((elob - eloa) / 400))
end

local GOOD_PLAYER_THRESHOLD = 1000

local FOLLOW_UP

local QDEF = QuestDef.Define
{
    title = "Battle of Wits",
    desc = "To prove that nobody is smarter than {giver}, {giver} asks you to find someone who can defeat {giver.himher} in a battle of Chess(?).",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/revenge_starving_worker.png"),

    qtype = QTYPE.SIDE,

    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"REQUEST_JOB"},
    -- reward_mod = 0,
    can_flush = false,

    events = {
        base_difficulty_change = function(quest, new_diff, old_diff)
            quest:SetRank(new_diff)
        end,
        
    },

    -- collect_agent_locations = function(quest, t)
    --     if quest:GetCastMember("challenger") then
    --         table.insert(t, { agent = quest:GetCastMember("challenger"), location = quest:GetCastMember('giver_home'), role = CHARACTER_ROLES.VISITOR})
    --     end
    --     -- table.insert(t, { agent = quest:GetCastMember("potential_ally"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.VISITOR})
    -- end,
    
    on_start = function(quest)
        quest:Activate("find_challenger")
    end,

    on_complete = function(quest)
        if not (quest.param.sub_optimal or quest.param.poor_performance) then
            quest:GetProvider():OpinionEvent(OPINION.DID_LOYALTY_QUEST)
            -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 10, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, 4, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 3, "COMPLETED_QUEST")
        elseif quest.param.sub_optimal then
            -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 5, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 4, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 3, "COMPLETED_QUEST")
        elseif quest.param.poor_performance then
            -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2, "POOR_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 4, "POOR_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 2, 3, "POOR_QUEST")
        end
    end,
    -- process_fighter = function(quest, fighter)
    --     print(fighter.agent, fighter:GetTeamID())
    --     if fighter.agent == quest:GetCastMember("challenger") and fighter:GetTeamID() == TEAM.RED then
    --         fighter:AddCondition("WANTED_DEAD")
    --     end
    -- end,

}
:AddCast{
    cast_id = "giver",
    no_validation = true,
    provider = true,
    unimportant = true,
    condition = function(agent, quest)
        return agent:GetContentID() == "ADVISOR_HOSTILE" or (DemocracyUtil.GetWealth(agent) >= 4)
    end,
    -- cast_fn = function(quest, t)
    --     table.insert( t, quest:CreateSkinnedAgent( "LABORER" ) )
    -- end,
    on_assign = function(quest, agent)
        quest:AssignCastMember("giver_home")
    end,
}
:AddLocationCast{
    cast_id = "giver_home",
    when = QWHEN.MANUAL,
    cast_fn = function(quest, t)
        table.insert(t, quest:GetCastMember("giver"):GetBrain():GetHome())
    end,
}
:AddCast{
    cast_id = "challenger",
    when = QWHEN.MANUAL,
    no_validation = true,
    on_assign = function(quest, agent)
        quest:Complete("find_challenger")
        quest:Activate("go_to_game")
    end,
    events = {
        agent_retired = function(quest, agent)
            quest:UnassignCastMember("challenger")
            if quest:IsActive("go_to_game") then
                quest:Cancel("go_to_game")
            end
            quest:Activate("find_challenger")
        end,
    },
}
:AddObjective{
    id = "find_challenger",
    title = "Find potential challengers.",
    desc = "Find someone who can potentially beat {giver} in Chess(?).",
}
:AddObjective{
    id = "go_to_game",
    title = "Spectate the game.",
    desc = "Go visit {giver} and watch how the game with {challenger} turns out.",
    mark = function(quest, t, in_location)
        if DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("giver_home"))
        end
    end,
}
:AddObjective{
    id = "wait",
    title = "See what happens.",
    desc = "Surely nothing bad will happen, right?",
}

QDEF:AddIntro(
    --attract spiel
    [[
        agent:
            [p] Nobody knows more than me.
            To prove this, find someone who can beat me at Chess(?).
            You can't, but please try.
    ]],
    
    --on accept
    [[
        player:
            [p] A weird request, but okay...?
    ]])

QDEF:AddConvo("find_challenger")
    :Loc{
        OPT_ASK = "Ask {agent} to play Chess(?) with {giver}",
        DIALOG_ASK = [[
            player:
                [p] Wanna beat {giver} in a game?
            agent:
                Why tho?
            {not good_player?
                I such at chess(?).
            }
        ]],
        DIALOG_ASK_SUCCESS = [[
            agent:
                [p] Good point.
                I'll meet up with {giver} and play.
        ]],
        DIALOG_ASK_FAILURE = [[
            agent:
                [p] Nah, I don't think I will.
        ]],
        SIT_MOD = "Bad at chess(?)",
    }
    :Hub(function(cxt, who)
        if who and not AgentUtil.HasPlotArmour(who) then
            local ELO = GetELO(who)
            cxt.enc.scratch.good_player = ELO >= GOOD_PLAYER_THRESHOLD
            cxt:BasicNegotiation("ASK", {
                situation_modifiers = (not cxt.enc.scratch.good_player) and 
                    {{value = 10, text = cxt:GetLocString("SIT_MOD")}} 
                    or nil,
            })
                :OnSuccess()
                    :Fn(function(cxt)
                        cxt.quest:AssignCastMember("challenger", who)
                    end)
                    :DoneConvo()
        end
    end)
QDEF:AddConvo("go_to_game")
    :Priority(CONVO_PRIORITY_LOW)
    :AttractState("STATE_NO_PLAYER", function(cxt) 
        return cxt.location == cxt:GetCastMember("giver_home") and cxt:GetAgent() and
            (cxt:GetAgent() == cxt:GetCastMember("giver") or cxt:GetAgent() == cxt:GetCastMember("challenger"))
    end)
        :Loc{
            DIALOG_INTRO_GIVER_NO_CHALLENGER = [[
                agent:
                    [p] You got someone to play? Great!
                    But I guess they're not here, yet, huh?
            ]],
            DIALOG_INTRO_CHALLENGER_NO_GIVER = [[
                agent:
                    [p] Where's {giver}?
                player:
                    {giver.HeShe}'s not here yet.
                agent:
                    Oh well, we can wait.
            ]],
        }
        :Fn(function(cxt)
            if cxt:GetCastMember("giver"):GetLocation() ~= cxt.location then
                cxt:Dialog("DIALOG_INTRO_CHALLENGER_NO_GIVER")
            elseif cxt:GetCastMember("challenger"):GetLocation() ~= cxt.location then
                cxt:Dialog("DIALOG_INTRO_GIVER_NO_CHALLENGER")
            end
        end)
    :ConfrontState("STATE_PLAY", function(cxt)
        if cxt.location == cxt:GetCastMember("giver_home") and cxt:GetCastMember("challenger") then
            local rval = true
            if TheGame:GetGameState():GetQuestLocationForAgent(cxt:GetCastMember("giver")) then
                rval = false
            else
                cxt:GetCastMember("giver"):MoveToLocation(cxt:GetCastMember("giver_home"))
            end
            if TheGame:GetGameState():GetQuestLocationForAgent(cxt:GetCastMember("challenger")) then
                rval = false
            else
                cxt:GetCastMember("challenger"):MoveToLocation(cxt:GetCastMember("giver_home"))
            end
            return rval
        end
        return false
    end)
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
                giver:
                    !right
                    [p] Perfect timing!
                    You are just in time for the big show!
                challenger:
                    !left
                giver:
                    So you are the challenger, hmm?
                {good_player?
                    Let's see what you got!
                challenger:
                    I'm not pulling any punches!
                }
                {not good_player?
                    Really, {player}?
                    Who do you think I am? Pairing me with this guy who is clearly bad at chess(?).
                challenger:
                    Well, this guy is going to kick your royal arse.
                }
                player:
                    !left
                giver:
                    Anyway, leave it to us.
            ]],
            OPT_OBSERVE = "Observe the game",
        }
        :Fn(function(cxt)
            local ELO = GetELO(cxt:GetCastMember("challenger"))
            cxt.enc.scratch.good_player = ELO >= GOOD_PLAYER_THRESHOLD
            cxt:Dialog("DIALOG_INTRO")
            cxt:Opt("OPT_OBSERVE")
                :Fn(function(cxt)
                    local odds = GetWinChance(GetELO(cxt:GetCastMember("giver")), GetELO(cxt:GetCastMember("challenger")))
                    if math.random() < odds then
                        cxt:GoTo("STATE_WIN")
                    else
                        cxt:GoTo("STATE_LOSE")
                    end
                end)
        end)
    :State("STATE_WIN")
        :Loc{
            DIALOG_INTRO = [[
                * [p] The game goes on, but clearly {challenger} is no match for {giver}.
                challenger:
                    !left
                    !injured
                giver:
                    !right
                    !happy
                    Haha! You are no match for me!
                challenger:
                    NoooOOOOOO!
                    !exit
                * {challenger} runs away in shame.
                player:
                    !left
                giver:
                    !right
                {good_player?
                    That was a good one.
                    But that's not enough.
                    {not impatient?
                        Go find another guy that can beat me.
                    }
                    {impatient?
                        You have failed me yet again. What do you have to say to that?
                    }
                    |
                    That was rather insulting.
                    To think you'd think so lowly of my skills.
                    {not impatient?
                        Go find someone actually worth my time.
                    }
                    {impatient?
                        I'm starting to think you didn't even try.
                    }
                }
            ]],
            OPT_CONVINCE = "Convince {agent} that no one can beat {agent.himher}",

            DIALOG_CONVINCE = [[
                player:
                    [p] Obviously no one can beat you.
                    You are the best, after all.
                giver:
                    Uh huh.
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                giver:
                    [p] Of course I'm the best.
                    Tell me something I don't know.
                player:
                    Then obviously no one can beat you.
                giver:
                    True.
                    I love you now.
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                giver:
                    [p] I'm egotistical, not stupid.
                    Try harder to fool me next time.
            ]],

            OPT_BRUSH_OFF = "Brush off {agent}'s concern",
            DIALOG_BRUSH_OFF = [[
                player:
                    [p] Don't worry about it.
                giver:
                    Oh, I will.
            ]],

            SIT_MOD = "You are clearly making a mockery of {agent} with these terrible players",
        }
        :Fn(function(cxt)
            cxt:TalkTo(cxt:GetCastMember("giver"))
            cxt.quest.param.failed_challengers = (cxt.quest.param.failed_challengers or 0) + 1
            if not cxt.enc.scratch.good_player then
                cxt.quest.param.bad_challengers = (cxt.quest.param.bad_challengers or 0) + 1
            end
            cxt.enc.scratch.impatient = cxt.quest.param.failed_challengers >= 3
            cxt:Dialog("DIALOG_INTRO")
            if cxt.enc.scratch.impatient then
                cxt:UnassignCastMember("challenger")

                cxt:BasicNegotiation("CONVINCE", {
                    situation_modifiers = (cxt.quest.param.bad_challengers or 0) >= 1 and 
                    {{value = cxt.quest.param.bad_challengers * 10, text = cxt:GetLocString("SIT_MOD")}} 
                    or nil,
                })
                    :OnSuccess()
                        :CompleteQuest()
                        :DoneConvo()
                    :OnFailure()
                        :FailQuest()
                        :DoneConvo()

                cxt:Opt("OPT_BRUSH_OFF")
                    :Dialog("DIALOG_BRUSH_OFF")
                    :FailQuest()
                    :DoneConvo()
            else
                cxt.quest:UnassignCastMember("challenger")
                quest:Cancel("go_to_game")
                quest:Activate("find_challenger")
                StateGraphUtil.AddEndOption(cxt)
            end
        end)
    :State("STATE_LOSE")
        :Loc{
            DIALOG_INTRO = [[
                * [p] The gae goes on, but clearly {giver} is no match for {challenger}.
                challenger:
                    !left
                    !happy
                giver:
                    !right
                    !scared
                    How could I, the great {giver}, loses?
                challenger:
                    Idk, how about you tone down your ego a bit.
                giver:
                    If I am not the best...
                    I'll make sure anyone who's better than me die!
                    {player}! Take care of {challenger.himher}.
                challenger:
                    WTF?
            ]],

            OPT_ATTACK = "Attack {challenger}, as requested",

            DIALOG_ATTACK = [[
                challenger:
                    !right
                    !scared
                player:
                    !left
                    [p] Nothing personnel, kid.
            ]],

            DIALOG_ATTACK_WIN = [[
                {dead?
                    player:
                        !left
                    giver:
                        !right
                        [p] Well, {challenger.heshe}'s dead.
                        Thanks.
                }
                {not dead?
                    player:
                        [p] Get out of here.
                    challenger:
                        !exit
                    * {challenger} runs away.
                    giver:
                        !right
                        Why didn't you finish {challenger} off?
                    player:
                        I'm not a hitman.
                    giver:
                        I'm mad now.
                }
            ]],

            OPT_ORDER = "Order {1#agent} to kill {challenger}",
            DIALOG_ORDER = [[
                challenger:
                    !right
                    !scared
                player:
                    [p] {hired}, kill {challenger.himher}.
                hired:
                    !left
                    As you wish.
                challenger:
                    !exit
                * Oof.
                player:
                    !left
                giver:
                    !right
                    Thx.
            ]],

            OPT_CALM = "Calm {giver} down",
            DIALOG_CALM = [[
                giver:
                    !right
                player:
                    !left
                    [p] WTF, {giver}?
            ]],
            DIALOG_CALM_SUCCESS = [[
                player:
                    [p] Is it how your treat your guests?
                giver:
                    Guess not.
                challenger:
                    !left
                giver:
                    You can go now.
                challenger:
                    !exit
                * {challenger} left.
            ]],
            DIALOG_CALM_FAILURE = [[
                giver:
                    [p] Et tu, {player}?
                    Guess I can't rely on a grifter for everything, eh?
                    I have to do it myself!
            ]],

            OPT_REFUSE = "Refuse",

            DIALOG_REFUSE = [[
                player:
                    !left
                    [p] I refuse.
                giver:
                    Guess I will have to do it myself!
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            local hireling = TheGame:GetGameState():GetCaravan():GetHireling()
            cxt:Opt("OPT_ATTACK")
                :Dialog("DIALOG_ATTACK")
                :Battle{
                    enemies = {"challenger"},
                    on_win = function(cxt)
                        cxt:TalkTo(cxt:GetCastMember("challenger"))
                        cxt:Dialog("DIALOG_ATTACK_WIN")
                        if cxt:GetAgent():IsDead() then
                        else
                            cxt.quest.param.sub_optimal = true
                        end
                        cxt.quest.Complete()
                        ConvoUtil.GiveQuestRewards(cxt)
                        StateGraphUtil.AddEndOption(cxt)
                    end,
                    on_start_battle = function(battle)
                        battle:GetTeam(TEAM.RED):Primary():AddCondition("WANTED_DEAD")
                    end,
                }
            if hireling then
                cxt:Opt("OPT_ORDER", hireling)
                    :Fn(function(cxt)
                        cxt:ReassignCastMember("hired", hireling)
                    end)
                    :Dialog("DIALOG_ORDER")
                    :Fn(function(cxt)
                        cxt:GetCastMember("challenger"):Kill()
                    end)
                    :CompleteQuest()
                    :DoneConvo()
            end
            cxt:BasicNegotiation("CALM", {
                target_agent = cxt:GetCastMember("giver"),
                helpers = {"challenger"},
                -- Some special effect for this negotiation.
            })
                :OnSuccess()
                    :Fn(function(cxt)
                        -- Spawn a followup.
                    end)
                    :CancelQuest()
                    :DoneConvo()
                :OnFailure()
                    :GoTo("STATE_AGGRO")
            cxt:Opt("OPT_REFUSE")
                :Dialog("DIALOG_REFUSE")
                :GoTo("STATE_AGGRO")
        end)
    :State("STATE_AGGRO")
        :Loc{
            OPT_STEP_ASIDE = "Step aside",
            DIALOG_STEP_ASIDE = [[
                player:
                    !left
                    [p] Alright, I'll get out of your way.
                    !exit
                giver:
                    !right
                    !cruel
                * Oof.
                player:
                    !left
                giver:
                    Got my hands dirty, but no matter.
                    You did literally nothing.
                player:
                    Not my job.
                giver:
                    Fair.
            ]],
            OPT_DEFEND = "Defend {challenger}",
            DIALOG_DEFEND = [[
                player:
                    !fight
                    [p] I can't let you do that!
            ]],
            DIALOG_DEFEND_WIN = [[
                {dead?
                    {challenger_dead?
                        * [p] Everyone dies lol.
                    }
                    {not challenger_dead?
                        player:
                            !left
                        challenger:
                            !right
                            [p] Holy Hesh, you actually killed {giver.himher}.
                            Thanks.
                    }
                    {advisor?
                        * Now where will you find another advisor?
                    }
                }
                {not dead?
                    {challenger_dead?
                        player:
                            !left
                        giver:
                            !right
                            !injured
                            [p] Looks like {challenger}'s dead anyway.
                            Well, was it worth it?
                    }
                    {not challenger_dead?
                        giver:
                            !right
                            !injured
                        player:
                            !left
                            [p] So? Have you finally come to your senses?
                            You gotta accept that someone is better than you.
                        giver:
                            Fine, you win this.
                            But I will remember this.
                        * In typical Griftlands fashion, violence solves everything.
                    }
                }
            ]],
            DIALOG_DEFEND_RUN = [[
                {advisor?
                    giver:
                        [p] And don't come back!
                    * Well looks like this advisor is not willing to do more to help you now.
                }
                {not advisor?
                    giver:
                        [p] That's right. Run like a coward.
                    * Oof, that's not good.
                }
            ]],
        }
        :Fn(function(cxt)
            cxt:TalkTo(cxt:GetCastMember("giver"))
            cxt:Opt("OPT_STEP_ASIDE")
                :Dialog("DIALOG_STEP_ASIDE")
                :Fn(function(cxt) cxt.quest.param.poor_performance = true end)
                :CompleteQuest()
                :DoneConvo()
            cxt:Opt("OPT_DEFEND")
                :Dialog("DIALOG_DEFEND")
                :Battle{
                    flags = BATTLE_FLAGS.SELF_DEFENCE,
                    enemies = {"giver"},
                    allies = {"challenger"},
                    on_runaway = function(cxt) 
                        cxt:Dialog("DIALOG_DEFEND_RUN")
                        cxt.quest:Fail()
                        cxt:GetCastMember("giver"):OpinionEvent(OPINION.BETRAYED)
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                    on_win = function(cxt) 
                        cxt:Dialog("DIALOG_DEFEND_WIN")
                        cxt.quest:Fail()
                        StateGraphUtil.AddEndOption(cxt)
                    end,
                }
        end)

FOLLOW_UP = QDEF:AddFollowup()

FOLLOW_UP:GetCast("challenger").unimportant = true
-- FOLLOWUP:GetCast("challenger").optional = true

FOLLOW_UP:AddDormancyState("wait", "comfort", false, 2, 5, true)
    :AddDormancyState("comfort", "finale", true, 6, 12)
    :AddObjective{
        id = "find_opportunity",
        events = {
            caravan_member_event = function(quest, event, agent, old_loc, new_loc)
                if event == "agent_location_changed" and agent == TheGame:GetGameState():GetPlayerAgent() and quest:GetCastMember("giver"):GetLocation() ~= new_loc then
                    quest:Complete("find_opportunity")
                    quest:Activate("finale")
                end
            end,
        },
    }
    :AddObjective{
        id = "finale",
        title = "Visit {giver}",
        desc = "It has been a while since you visited {giver}. Surely nothing bad happened, right?",
        on_activate = function(quest)
            quest:GetCastMember("giver"):Retire()
        end,
        mark = {"giver_home"},
    }

FOLLOW_UP:AddConvo("comfort", "giver")
    :Priority(CONVO_PRIORITY_LOW)
    :Loc{
        OPT_COMFORT = "Comfort {agent}",
        DIALOG_COMFORT = [[
            player:
                [p] Feeling depressed? Just don't be sad.
        ]],
        DIALOG_COMFORT_SUCCESS = [[
            agent:
                [p] Thanks, I'm cured.
        ]],
        DIALOG_COMFORT_FAILURE = [[
            agent:
                [p] Say no more.
        ]],
    }
    :Hub(function(cxt)
        if not cxt.quest.param.tried_comfort then
            cxt:BasicNegotiation("COMFORT", {})
                :OnSuccess()
                    :CompleteQuest()
                    :Fn(function(cxt)
                        QDEF.on_complete(cxt.quest)
                        -- This will probably change dronumph's narcissist personality a little, as he accepts that there
                        -- are always people better than him, but that should not be a cause for his depression.
                        cxt:GetAgent():Remember("ACCEPT_LIMITS")
                    end)
                    :DoneConvo()
                :OnFailure()
                    :Fn(function(cxt)
                        cxt.quest.param.tried_comfort = true
                    end)
        end
    end)
    :AttractState("STATE_ATTRACT")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    If I'm not the best, then who am I?
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
    

FOLLOW_UP:AddConvo("finale", "giver_home")
    :ConfrontState("STATE_CONF")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You arrive at {giver}'s {advisor?office|home}, but {giver} is nowhere to be seen.
                * You found a note. It says:
                * "I have moved to a better place, for if anyone is better than me, my entire purpose is all for nothing."
                * And some other poetic stuff idk.
                * I assure you that this is totally not a suicide note. {giver.HeShe}'s fine.
                * It's just that you will never see {giver.himher} again.
                * They are completely different.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Cancel()
            StateGraphUtil.AddEndOption(cxt)
        end)