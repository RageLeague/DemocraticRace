local function GetELO(agent)
    return agent:CalculateProperty("CHESS_ELO", function(agent)
        return math.round(900 + 100 * (agent:GetRenown() - agent:GetCombatStrength()) + 10 * (agent:GetRenown() ^ 2) + math.random(0, 200))
    end)
end
-- Calculate the chance of A winning given eloa and elob, using the elo system.
local function GetWinChance(eloa, elob)
    return 1 / (1 + 10 ^ ((elob - eloa) / 400))
end

local DEPRESSION_BEHAVIOUR =
{
    OnInit = function( self, difficulty )
        local modifier = self.negotiator:AddModifier("PESSIMIST")

        if self.negotiator:FindCoreArgument() and self.negotiator:FindCoreArgument():GetResolve() then
            self.negotiator:FindCoreArgument():ModifyResolve(-math.floor(0.7 * self.negotiator:FindCoreArgument():GetResolve()), self)
        end
        -- self.negotiator:CreateModifier("RESTORE_RESOLVE_GOAL", 1, self)

        self.self_loathe = self:AddArgument("SELF_LOATHE")

        self.negotiator:AddModifier("ENCOURAGEMENT")

        local cards = {}
        for i = 1, 3 do
            table.insert(cards, Negotiation.Card( "console_opponent", self.engine:GetPlayer() ))
        end
        self.engine:InceptCards( cards, self )

        self:SetPattern( self.BasicCycle )
    end,

	BasicCycle = function( self, turns )
        if turns == 1 or math.random() < 0.5 then
            self:ChooseCard(self.self_loathe)
        else
            self:ChooseGrowingNumbers( 1, -1 )
        end
		if turns % 3 == 0 then
            self:ChooseGrowingNumbers( 3, 0 )
        else
            self:ChooseGrowingNumbers( 2, 1 )
        end
	end,
}

local GOOD_PLAYER_THRESHOLD = 1000

local FOLLOW_UP

local QDEF = QuestDef.Define
{
    title = "Battle of Wits",
    desc = "To prove that nobody is smarter than {giver}, {giver} asks you to find someone who can defeat {giver.himher} in a battle of Grout Bog Flip 'Em.",
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
            quest:GetCastMember("giver"):OpinionEvent(OPINION.DID_LOYALTY_QUEST)
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 10, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, 4, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 3, "COMPLETED_QUEST")
        elseif quest.param.sub_optimal then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 5, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 4, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 3, "COMPLETED_QUEST")
        elseif quest.param.poor_performance then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2, "POOR_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 4, "POOR_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 2, 3, "POOR_QUEST")
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
        return agent:GetContentID() == "ADVISOR_HOSTILE" or (DemocracyUtil.GetWealth(agent) >= 3 and not agent:HasTag("advisor"))
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
    desc = "Find someone who can potentially beat {giver} in Grout Bog Flip 'Em.",
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
        {advisor_hostile?
            Nobody knows more than me.
        player:
            !crossed
            I think you've said that enough. What do you possibly want me to do?
        agent:
            In order to prove this, I want you to find someone who can beat me at Grout Bog Flip 'Em.
        player:
            The what?
            !dubious
            Is that what they call the game where you flip a coin and guess heads or snails?
        agent:
            !crossed
            That is a gross oversimplification, and frankly I'm insulted that you think so little of this game.
            It is the ultimate battle of wits and test of talents.
        player:
            !shrug
            If you say so.
        }
        {not advisor_hostile?
		    Do you know how to win 5 points in an opening gambit with just a single coin flip?
        * You open your mouth to tell him that's an illegal move, but your stopped expression is all {giver} needs to continue.
        agent:
            Of course you don't! Because no one's better at the game than me.
            To prove it, run along and find me a good player when you find the time.
        }
    ]],
    --on accept
    [[
        player:
            How am I supposed to find someone good at Grout Bog Flip 'Em?
        agent:
            !hips
            Well, you're a talkative sort. I'm sure you'll find someone if you just bustle up and ask.
    ]])

QDEF:AddConvo("find_challenger")
    :Loc{
        OPT_ASK = "Ask {agent} to play Grout Bog Flip 'Em with {giver}",
        DIALOG_ASK = [[
            player:
                I've got a sucker, {giver}, just ready to give up his shills to whoever plays him. Want in?
        		You play Grout Bog Flip 'Em. I've got someone who wants to play, if you're interested.
            agent:
                Why should I bother playing against {giver}?
            {good_player?
                I have plenty of other things needs to be doing, and I don't want to spend it playing this game against a random guy for no reason.
                |
                Are you trying to humiliate me? I don't play Grout Bog Flip 'Em, and I will surely lose playing it.
            }
        ]],
        OPT_CONVINCE = "Convince {agent} to play",
        DIALOG_CONVINCE = [[
            player:
                Okay, just bear with me for a sec.
        ]],
        DIALOG_CONVINCE_SUCCESS = [[
            agent:
                You know what? It's probably easier just to play against {giver} than arguing with you and waste my time.
                I'll meet up with {giver} and play.
            player:
                Thank you for your cooperation.
            * You now have a challenger. Go meet up {giver} at {giver.hisher} house and spectate the match.
        ]],
        DIALOG_CONVINCE_FAILURE = [[
            agent:
                Okay, so no reason then?
            player:
                When you put it that way...
            agent:
                Yeah, I agree. This would be a complete waste of my time.
            * Looks like {agent} is unwilling to play. Perhaps you could find another person, or perhaps you could badger {agent.himher} later.
        ]],
        SIT_MOD = "Bad at Grout Bog Flip 'Em",
    }
    :Hub(function(cxt, who)
        if who and not AgentUtil.HasPlotArmour(who) then
            if cxt.quest.param.failed_challengers and table.arraycontains(cxt.quest.param.failed_challengers, who) then
                return
            end
            local ELO = GetELO(who)
            cxt.enc.scratch.good_player = ELO >= GOOD_PLAYER_THRESHOLD
            cxt:Opt("OPT_ASK")
                :SetQuestMark()
                :Dialog("DIALOG_ASK")
                :LoopingFn(function(cxt)
                    cxt:BasicNegotiation("CONVINCE", {
                        situation_modifiers = (not cxt.enc.scratch.good_player) and
                            {{value = 10, text = cxt:GetLocString("SIT_MOD")}}
                            or nil,
                    })
                        :OnSuccess()
                            :Fn(function(cxt)
                                cxt.quest:AssignCastMember("challenger", who)
                            end)
                            :DoneConvo()
                    StateGraphUtil.AddBackButton(cxt)
                end)
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
                    You got someone to play? Great!
                    But I guess they're not here, yet, huh?
                player:
                    Yeah, I guess so.
                agent:
                    !shrug
                    We can wait. In the mean time, what do you want to talk about?
            ]],
            DIALOG_INTRO_CHALLENGER_NO_GIVER = [[
                agent:
                    Where's {giver}?
                    I was promised a game.
                player:
                    {giver.HeShe}'s not here yet.
                agent:
                    !dubious
                    {giver.HeShe} organized this game and {giver.heshe} doesn't even show up?
                    Oh well, we can wait.
                    $miscAnnoyed
                    Not like I have anything else I need to do, <i>{player}</>.
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
                * The room fills with a tense silence as {challenger} and {giver} sit down at the table.
                player:
                    !left
                giver:
                    !right
                    Ah, {player}. You've got some mighty fine timing.
                {good_player?
                    !crossed
                    I need you to stand watch and make sure {challenger} isn't up to any shenanigans.
                challenger:
                    !left
                    !angry_accuse
                    Shenanigans? Are you implying I'm a cheat?
                giver:
                    !placate
                    Not a cheat, per se. Just...in the spirit of fairness, yes?
                challenger:
                    !crossed
                    Alright. Then how about {player} makes sure you aren't up to anything underhanded.
                giver:
                    {player.heshe} will see to it that no funny business occurs.
                    From <i>either</> of us.
                }
                {not good_player?
                    I need you to explain why you brought this simpleton to the board.
                challenger:
                !left
                    Hey! I at least know how to play!
                giver:
                    A child knows how to play as well. An adult knows how to win.
                    I, of course, belong to neither of those brackets.
                    !hips
                    <i>I</> dominate this game.
                challenger:
                    !fight
                    Oh it's on!
                }
                * You seat yourself across from the table, just as the first few moves are made, calculated, and occasionally blundered.
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
                * The game slouches on, and your crude understanding of the rules, along with just eyeing {challenger.hisher} wallet tells you that {challenger.heshe}'s losing desperately.
                challenger:
                    !left
                    I double the ante.
                giver:
                    !right
                    Triple. You have to go all in.
                challenger:
                    !scared
                    Wait, what?!
                giver:
                    !coin_toss
                * A coin flips through the air, and {challenger} looks at with fear one can only muster when knee deep into a game.
                giver:
                    I win.
                challenger:
                    !angry_accuse
                    Wait, whoa! I know you fudged the scoring bracket somewhere along the lines!
                giver:
                    !hips
                    You can hand-inspect it, if you'd like. I made no such adjustments.
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
                    Obviously, this means that no one can beat you.
                    Nobody knows Grout Bog Flip 'Em better than you, after all.
                giver:
                    !crossed
                    Yeah, I am sure that is the reason, go on.
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                giver:
                    Of course nobody knows Grout Bog Flip 'Em better than me.
                    Tell me something I don't know.
                player:
                    Then in that case, nobody can beat you at it, since nobody knows it better than you.
                giver:
                    You do have a point there.
                    Well, it turns out that this experiment is well worth it.
                    It has proven, once and for all, that my intellect is superior to all.
                    And I have you to thank for helping me realize that.
                    You truly are a great friend, {player}.
                player:
                    !bashful
                    You're... welcome? I guess?
                * Now {giver} is as arrogant as ever, thanks to you.
                * But, perhaps this is for the best. For you, anyway.
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                giver:
                    !angry_accuse
                    You think I don't know what you are doing?
                    Trying to say things I like to hear so I can ignore your incompetence?
                    Guess what? Nobody knows how grifters like you work better than me.
                    And your insincerity is shown right on your face.
                player:
                    !bashful
                    Ah, Hesh. Was it that obvious?
                giver:
                    Yes!
                {advisor?
                    !handwave
                    Just... Work on your campaign.
                    {not disliked?
                        That seems like what you are good for, anyway.
                    }
                    {disliked?
                        You are already behind, so try not to screw the campaign up as well.
                    }
                }
                {not advisor?
                    !angry_accuse
                    Now get out of here. Go work on your campaign or whatever.
                }
            ]],

            OPT_BRUSH_OFF = "Brush off {agent}'s concern",
            DIALOG_BRUSH_OFF = [[
                player:
                    Strange how these people conveniently lose to you, huh?
                    !shrug
                    It's probably a coincidence, and you shouldn't worry about it too hard.
                giver:
                    !hips
                    What a statement, coming from someone totally competent at their job.
                player:
                    !salute
                    Why, thank you very much!
                giver:
                    !angry_accuse
                    That was sarcasm, you clown!
                {advisor?
                    !handwave
                    Just... Work on your campaign.
                    {not disliked?
                        That seems like what you are good for, anyway.
                    }
                    {disliked?
                        You are already behind, so try not to screw the campaign up as well.
                    }
                }
                {not advisor?
                    !angry_accuse
                    Now get out of here. Go work on your campaign or whatever.
                }
            ]],

            SIT_MOD = "You are clearly making a mockery of {agent} with these terrible players",
        }
        :Fn(function(cxt)
            cxt:TalkTo(cxt:GetCastMember("giver"))
            if type (cxt.quest.param.failed_challengers) ~= "table" then
                cxt.quest.param.failed_challengers = {}
            end
            table.insert(cxt.quest.param.failed_challengers, cxt:GetCastMember("challenger"))
            if not cxt.enc.scratch.good_player then
                cxt.quest.param.bad_challengers = (cxt.quest.param.bad_challengers or 0) + 1
            end
            cxt.enc.scratch.impatient = #cxt.quest.param.failed_challengers >= 3
            cxt:Dialog("DIALOG_INTRO")
            if cxt.enc.scratch.impatient then
                cxt.quest:UnassignCastMember("challenger")

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
                cxt.quest:Cancel("go_to_game")
                cxt.quest:Activate("find_challenger")
                StateGraphUtil.AddEndOption(cxt)
            end
        end)
    :State("STATE_LOSE")
        :Loc{
            DIALOG_INTRO = [[
                * The game drones on, but just when your eyes start to flap shut from boredom, you hear quite possibly the loudest stack of shills hit the table.
                challenger:
                    !left
                giver:
                    !right
                    !angry
                    All in.
                challenger:
                    Your loss.
                    !coin_toss
                * In a matter of seconds after the coin lands on the table, a bellow of anger erupts from {giver}.
                challenger:
                    Hey, hey! I win the whole kit!
                * {giver} steams with anger, but quickly {giver.heshe} regains some composure as {giver.heshe} sits straighter in {giver.hisher} chair.
                giver:
                    Well, it seems I have been outsmarted...
                    !angry_accuse
                    By a cheater!
                challenger:
                    Whoa, you lost and you know it.
                giver:
                    Silence, lesser player. You should have lost, fair and square, it is only natural to assume you are a cheat.
                    {player}. Please, <i>escort</> {challenger} away from the table.
                    !throatcut
                    A cheater such has {challenger.himher} shall not be tolerated in this house.
            ]],

            OPT_ATTACK = "Attack {challenger}, as requested",

            DIALOG_ATTACK = [[
                challenger:
                    !right
                    !scared
                player:
                    !left
                    Finally, some normal grifter work.
            ]],

            DIALOG_ATTACK_WIN = [[
                {dead?
                    * {giver} gives one last mean spirited kick to the stomach of {agent}'s body before facing you.
                    giver:
                        !right
                        Well, that was certainly vindicating.
                    player:
                        For you, maybe.
                    giver:
                        Well, regardless of how you feel, I am indebted for your aid in the test of my mental faculties against others.
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
                agent:
                    !right
                player:
                    !left
                    [p] WTF, {agent}?
            ]],
            DIALOG_CALM_SUCCESS = [[
                player:
                    [p] Is it how your treat your guests?
                agent:
                    Guess not.
                challenger:
                    !left
                agent:
                    You can go now.
                challenger:
                    !exit
                * {challenger} left.
                player:
                    !left
                {advisor_hostile?
                agent:
                    Did I just lose? Fair and square?
                player:
                    !shrug
                    From what I can tell, seems like it.
                agent:
                    !scared
                    But... I can't lose.
                    The Trunoomiel family didn't come this far by losing.
                    So... Why...?
                    I... Need to think.
                player:
                    Okay...?
                * You left {agent} alone to contemplate {agent.hisher} life choices.
                }
                {not advisor_hostile?
                agent:
                    Well, seems like I lost fair and square.
                player:
                    From what I can tell, seems like it.
                agent:
                    Well, you did what I asked you to, so that's good.
                    Now, what I would do with this information, on the other hand, is another thing.
                    Anyway, thank you for all your troubles.
                player:
                    You are welcome.
                * You did what you are asked to do and resolved the situation peacefully! That's good.
                }
            ]],
            DIALOG_CALM_FAILURE = [[
                agent:
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

            SIT_MOD = "{giver} doesn't like losing!",
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            local hireling = TheGame:GetGameState():GetCaravan():GetHireling()
            cxt:Opt("OPT_ATTACK")
                :Fn(function(cxt)
                    cxt:TalkTo(cxt:GetCastMember("challenger"))
                end)
                :Dialog("DIALOG_ATTACK")
                :Battle{
                    enemies = {"challenger"},
                    on_win = function(cxt)
                        cxt:Dialog("DIALOG_ATTACK_WIN")
                        if cxt:GetAgent():IsDead() then
                        else
                            cxt.quest.param.sub_optimal = true
                        end
                        cxt.quest:Complete()
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
            cxt:Opt("OPT_CALM")
                :Fn(function(cxt)
                    cxt:TalkTo(cxt:GetCastMember("giver"))
                end)
                :Dialog("DIALOG_CALM")
                :Negotiation{
                    target_agent = cxt:GetCastMember("giver"),
                    helpers = {"challenger"},
                    -- Some special effect for this negotiation.
                    -- For this negotiation, giver will gain a permanent argument that increases stacks when you play hostile cards.
                    -- It decreases stacks each turn or by playing diplomacy.
                    -- If it reaches a certain threshold, you insta-lose.
                    situation_modifiers =
                    {
                        { value = 10, text = cxt:GetLocString("SIT_MOD") }
                    },

                    on_start_negotiation = function(minigame)
                        minigame.opponent_negotiator:CreateModifier( "SHORT_TEMPERED" )
                    end,
                }
                :OnSuccess()
                    :Dialog("DIALOG_CALM_SUCCESS")
                    :Fn(function(cxt)
                        -- Spawn a followup.
                        if cxt:GetCastMember("giver"):GetContentID() == "ADVISOR_HOSTILE" then
                            cxt.quest:SpawnFollowQuest(FOLLOW_UP.id)
                            cxt.quest:Cancel()
                        else
                            cxt.quest:Complete()
                            ConvoUtil.GiveQuestRewards(cxt)
                        end
                        StateGraphUtil.AddEndOption(cxt)
                    end)
                    -- :CancelQuest()
                    -- :DoneConvo()
                :OnFailure()
                    :Dialog("DIALOG_CALM_FAILURE")
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
                        if cxt:GetCastMember("giver"):IsAlive() then
                            cxt.quest:Fail()
                            cxt.quest:SpawnFollowQuest(FOLLOW_UP.id)
                        end
                        StateGraphUtil.AddEndOption(cxt)
                    end,
                }
        end)

FOLLOW_UP = QDEF:AddFollowup({
    events =
    {
        base_difficulty_change = function(quest, new_diff, old_diff)
            quest:SetRank(new_diff)
        end,
        agent_location_changed = function(quest, agent, old_loc, new_loc)
            if agent == TheGame:GetGameState():GetPlayerAgent() and new_loc and new_loc:HasTag("tavern")
                and quest:IsActive("comfort") then
                local giver = quest:GetCastMember("giver")
                if not giver then
                    return
                end
                if (giver:InLimbo() or giver:GetLocation() == giver:GetHomeLocation()) and not AgentUtil.IsInHiding(giver) then
                    giver:GetBrain():SendToPatronize(new_loc)
                end
            end
        end,
    }
})

FOLLOW_UP:GetCast("challenger").unimportant = true
-- FOLLOW_UP:GetCast("giver").provider = true
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
        -- on_activate = function(quest)
        --     quest:GetCastMember("giver"):Retire()
        -- end,
        is_in_hiding = function(quest, agent)
            return agent == quest:GetCastMember("giver")
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
        DIALOG_COMFORT_WIN = [[
            agent:
                [p] Everything to you is about winning, isn't it?
            player:
                That's what you taught me.
            agent:
                Well you don't have to talk to a loser like me.
        ]],
        DIALOG_COMFORT_FAILURE = [[
            agent:
                [p] Say no more.
        ]],
    }
    :Hub(function(cxt)
        if not cxt.quest.param.tried_comfort then
            cxt:Opt("OPT_COMFORT")
                :Dialog("DIALOG_COMFORT")
                :Fn(function(cxt)
                    cxt:GetAgent():SetTempNegotiationBehaviour(DEPRESSION_BEHAVIOUR)
                end)
                :Negotiation{
                    -- This will be a special negotiation.
                    -- giver will start at low resolve, and you must bring their resolve to full to actually win the negotiation.
                    -- Winning negotiation without bringing up resolve, like using damage or oolo's requisition, has bad effect.

                    -- Opponent will have attacks targeting their own core.
                    -- Opponent will be given special bounties that will increase resolve or give composure.
                    -- You can also gift composure to opponent core via special action.
                    on_success = function(cxt, minigame)
                        local core = minigame:GetOpponentNegotiator():FindCoreArgument()
                        local resolve_left = core and core:GetResolve()
                        if resolve_left > (minigame.start_params.enemy_resolve_required
                            or MiniGame.GetPersuasionRequired( minigame:GetDifficulty() )) then

                            -- We win legit
                            cxt:Dialog("DIALOG_COMFORT_SUCCESS")
                            cxt.quest:Complete()
                            QDEF.on_complete(cxt.quest)
                            -- This will probably change dronumph's narcissist personality a little, as he accepts that there
                            -- are always people better than him, but that should not be a cause for his depression.
                            cxt:GetAgent():Remember("ACCEPT_LIMITS")
                            StateGraphUtil.AddEndOption(cxt)
                        else
                            cxt:Dialog("DIALOG_COMFORT_WIN")
                            cxt.quest.param.tried_comfort = true
                        end
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_COMFORT_FAILURE")
                        cxt.quest.param.tried_comfort = true
                    end,
                }
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


FOLLOW_UP:AddConvo("finale")
    :ConfrontState("STATE_CONF", function(cxt) return cxt.location == cxt:GetCastMember("giver_home") end)
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
            cxt.quest:GetCastMember("giver"):Retire()
            StateGraphUtil.AddEndOption(cxt)
        end)
