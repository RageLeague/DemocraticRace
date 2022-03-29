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
                    {player.HeShe} will see to it that no funny business occurs.
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
                {primary_advisor?
                    !handwave
                    Just... Work on your campaign.
                    {not disliked?
                        That seems like what you are good for, anyway.
                    }
                    {disliked?
                        You are already behind, so try not to screw the campaign up as well.
                    }
                }
                {not primary_advisor?
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
                {primary_advisor?
                    !handwave
                    Just... Work on your campaign.
                    {not disliked?
                        That seems like what you are good for, anyway.
                    }
                    {disliked?
                        You are already behind, so try not to screw the campaign up as well.
                    }
                }
                {not primary_advisor?
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
                        Well, regardless of how you feel, thanks for helping me rid the world of this dirty cheater.
                    player:
                        !dubious
                        Out of curiosity, did you really believe that {challenger} cheated?
                    giver:
                        !crossed
                        As I said numerous times before, nobody knows Grout Bog Flip 'Em better than me.
                        How else would you explain that {challenger.heshe} beat me?
                    player:
                        Uh huh.
                    giver:
                        Anyway, thanks for your aid in the test of my mental faculties against others.
                        And helping me out when I needed you the most.
                        For that, I am truly indebted to you.
                    * You feel like it is immoral to just kill people who are better than you at flipping coins.
                    * Then again, if you care about morals, you wouldn't be a grifter.
                    * Besides, getting into {giver}'s good grace is way more valuable.
                }
                {not dead?
                    challenger:
                        !right
                        !injured
                        What else do you want from me?
                    player:
                        Get out of here. Just be glad I let you live.
                    challenger:
                        If this is how you operate, then I'm afraid I don't want anything to do with you.
                        Goodbye.
                        !exit
                    * {challenger} runs away as quickly as possible.
                    * You turn your attention towards {giver}, who doesn't look too pleased with what you did.
                    * Or, rather, what you didn't do.
                    giver:
                        !right
                        !crossed
                        Why didn't you finish {challenger} off?
                        You are just going to let that cheater face get off scot free?
                    player:
                        I send {challenger.himher} a message, didn't I?
                        Besides, I didn't accept your request knowing I need to kill someone.
                    giver:
                        !sigh
                        Fine. It's not technically what I asked you to do.
                        But still! You could have finish what you have started.
                        At least that cheater would think twice before showing {challenger.hisher} face in front of me again.
                }
                giver:
                    Anyway, thanks for helping me rid the world of this dirty cheater.
                player:
                    !dubious
                    Out of curiosity, did you really believe that {challenger} cheated?
                giver:
                    !crossed
                    As I said numerous times before, nobody knows Grout Bog Flip 'Em better than me.
                    How else would you explain that {challenger.heshe} beat me?
                player:
                    Uh huh.
                giver:
                    Anyway, thanks for your aid in the test of my mental faculties against others.
                    And helping me out when I needed you the most.
                    For that, I am truly indebted to you.
                * You feel like it is immoral to just kill people who are better than you at flipping coins.
                * Then again, if you care about morals, you wouldn't be a grifter.
                * Besides, getting into {giver}'s good grace is way more valuable.
            ]],

            OPT_ORDER = "Order a bodyguard to kill {challenger}...",
            DIALOG_ORDER = [[
                challenger:
                    !right
                    !scared
                player:
                    !left
                    !crossed
                    {hired}, kill {challenger.himher}.
                hired:
                    !left
                    Finally, something interesting with this job.
                challenger:
                    !placate
                    Wait, hold on a sec-
                    !exit
                * The deed is done before {challenger.heshe} could finish the sentence.
                player:
                    !left
                giver:
                    !right
                {primary_advisor?
                    Told you hiring a bodyguard is a good idea.
                player:
                    !dubious
                    Was that really "bodyguarding" though?
                giver:
                    Doesn't matter. Don't care.
                }
                {not primary_advisor?
                    Wow, money sure can buy a lot of useful services.
                player:
                    !dubious
                    I have many questions.
                giver:
                    And I am not answering any of them.
                }
                giver:
                    Regardless, I must thank you.
                    For your aid in the test of my mental faculties against others.
                    And helping me out when I needed you the most.
                    For that, I am truly indebted to you.
                * You feel like it is immoral to just kill people who are better than you at flipping coins.
                * Then again, if you care about morals, you wouldn't be a grifter.
                * Besides, getting into {giver}'s good grace is way more valuable.
            ]],
            DIALOG_ORDER_PET = [[
                challenger:
                    !right
                    !scared
                player:
                    !left
                    !crossed
                    {hired}, kill {challenger.himher}.
                hired:
                    !left
                {hireling_mech?
                    TARGET ACQUIRED.
                    COMMENCING EXECUTION.
                }
                {not hireling_mech?
                    !bark
                    Grrr...
                challenger:
                    Uhh... Hey there, little fella?
                    !placate
                    Wait wait wait!
                    !exit
                * You watch as {hired} viciously tears {challenger} apart.
                player:
                    !left
                giver:
                    !right
                    !disgust
                    Yikes. Put that thing on a leash or something.
                player:
                    !shrug
                    Just don't mess with {hired}. It's that easy.
                }
                giver:
                    Regardless, I must thank you.
                    For your aid in the test of my mental faculties against others.
                    And helping me out when I needed you the most.
                    For that, I am truly indebted to you.
                * You feel like it is immoral to just kill people who are better than you at flipping coins.
                * Then again, if you care about morals, you wouldn't be a grifter.
                * Besides, getting into {giver}'s good grace is way more valuable.
            ]],

            OPT_CALM = "Calm {giver} down",
            DIALOG_CALM = [[
                agent:
                    !right
                player:
                    !left
                    !placate
                    Wait, wait, wait. Maybe we should think things a bit through, alright?
            ]],
            DIALOG_CALM_SUCCESS = [[
                player:
                    You invite someone to play Grout Bog Flip 'Em, lost to them, and now you want to kill them?
                    Is this how your treat your guests?
                    Maybe one day, you decide that <i>I</> am a problem, so you send someone to kill me instead!
                agent:
                    !placate
                    Don't say that! You know I would never do that!
                player:
                    Then let {challenger.himher} go. You just have to accept that {challenger.heshe} beat you fair and square.
                agent:
                    !facepalm
                    I- Fine. You do have a point.
                challenger:
                    !left
                agent:
                    !angry_shrug
                    Alright. You win. Happy now?
                challenger:
                    !angry
                    Not exactly, given that I wasted my time playing this game, and you just threatened to kill me.
                    !happy
                    Thanks for the shills, though.
                agent:
                    Get out of here before I change my mind.
                challenger:
                    !exit
                * You watch as {challenger} left run off quickly, not wanting to stay for the fallout.

                {advisor_hostile?
                player:
                    !left
                * This leaves you and {agent}, who looks very devastated by this revelation.
                agent:
                    !scared
                    Did I just lose? Fair and square?
                player:
                    !shrug
                    From what I can tell, seems like it.
                agent:
                    !scared_shrug
                    But... I can't lose.
                    The Trunoomiel family didn't come this far by losing.
                    So... Why...?
                    I... Need to think.
                player:
                    Okay...?
                * You left {agent} alone to contemplate {agent.hisher} life choices.
                }
                {not advisor_hostile?
                player:
                    !left
                * This leaves you and {agent}, who looks a bit sad, but ultimately composed.
                agent:
                    !shrug
                    Well, seems like I lost fair and square.
                player:
                    From what I can tell, seems like it.
                agent:
                    Well, you did what I asked you to, so that's good.
                    !think
                    Now, what I would do with this information, on the other hand, is another thing.
                    Anyway, thank you for all your troubles.
                player:
                    You are welcome.
                * You did what you are asked to do and resolved the situation peacefully! That's good.
                * And it seems like {agent} is happy with your work, which is always a win.
                }
            ]],
            DIALOG_CALM_FAILURE = [[
                agent:
                    !angry
                    You too, {player}?
                {primary_advisor?
                    {disliked?
                        It's not enough that you screw up the campaign, huh?
                        !angry_shrug
                        And now you are siding with {challenger.himher}, this dirty <i>cheater</>?
                    }
                    {not disliked?
                        I've done so much for your campaign, and how do you repay me?
                        !angry_shrug
                        You side with with {challenger.himher}, this dirty <i>cheater</>?
                    }
                }
                {not primary_advisor?
                    You would rather side with {challenger.himher}, this dirty <i>cheater</>, than me?
                }
                challenger:
                    !left
                    !angry_accuse
                    Hey! You lost! Fair and square!
                player:
                    !left
                * {agent} pays {challenger}'s remark no mind.
                agent:
                    !spit
                    Guess I can't rely on a grifter for everything, eh?
                    !fight
                    I have to do it myself!
            ]],

            OPT_REFUSE = "Refuse",

            DIALOG_REFUSE = [[
                player:
                    !left
                    This is not a thing I do anymore.
                    !fight
                    I am no longer just a grifter killing other people for money, and I refuse to do your dirty work for you!
                giver:
                    You talk real high and mighty for a grifter.
                    {primary_advisor?
                        {disliked?
                            It's not enough that you screw up the campaign, huh?
                            !angry_shrug
                            And you can't even do a simple task that I ask for you!
                        }
                        {not disliked?
                            I've done so much for your campaign, and how do you repay me?
                            !angry_shrug
                            When I ask you a simple favor, and you even refused to do that!
                        }
                    }
                    Guess I will have to do it myself!
            ]],

            SIT_MOD = "{giver} doesn't like losing!",
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt:Dialog("DIALOG_INTRO")
            end
            cxt:Opt("OPT_ATTACK")
                :Fn(function(cxt)
                    cxt:TalkTo(cxt:GetCastMember("challenger"))
                end)
                :Dialog("DIALOG_ATTACK")
                :Battle{
                    enemies = {"challenger"},
                    noncombatants = {cxt.quest:GetCastMember("giver")},
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
            DemocracyUtil.AddBodyguardOpt(cxt, function(cxt, hireling)
                cxt:ReassignCastMember("hired", hireling)

                cxt:TalkTo(cxt:GetCastMember("giver"))
                if hireling:IsSentient() then
                    cxt:Dialog("DIALOG_ORDER")
                else
                    if hireling:GetSpecies() == SPECIES.MECH then
                        cxt.enc.scratch.hireling_mech = true
                    end
                    cxt:Dialog("DIALOG_ORDER_PET")
                end

                cxt:GetCastMember("challenger"):Kill()

                cxt.quest:Complete()

                StateGraphUtil.AddEndOption(cxt)
            end, "OPT_ORDER")

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
                    !neutral
                    !shrug
                    If you insist on killing {challenger}, then who am I to stop you?
                    Have fun, or whatever.
                    !exit
                challenger:
                    !left
                    !scared
                giver:
                    !right
                    !cruel
                    This is what happens to people who think they knows better than me.
                challenger:
                    !fight
                    If you refuse to acknowledge you lose, then I will knock some sense into you!
                * You watch as these two fight between themselves.
                * As the fight goes on, it is clear that {challenger} is no match for {giver}.
                * Soon, {giver} finishes {challenger} off.
                player:
                    !left
                * {giver} turns {giver.hisher} attention towards you.
                giver:
                    !right
                    !angry_accuse
                    You did nothing! While I do all the work myself.
                player:
                    Hey, I can't just go around killing people like I used to.
                    What does the public think of a candidate that just kill people that don't disagree with them?
                    !shrug
                    Besides. You ask me to find someone to play against you. You didn't mention killing anyone.
                giver:
                    !thought
                    I will admit that you do have a point.
                    !angry_accuse
                    But still! You could've helped me!
                    But since you refused, don't expect me to do you any favors in the near future!
                * Looks like your indifference has caused someone die and another to be mad at you.
                * Was this really worth it?
            ]],
            OPT_DEFEND = "Defend {challenger}",
            DIALOG_DEFEND = [[
                player:
                    !fight
                    I can't let you do that!
                giver:
                    !fight
                    Fine! You want to die with {challenger}? Suit yourself!
            ]],
            DIALOG_DEFEND_WIN = [[
                {dead?
                    {challenger_dead?
                        * After the dust settles, {giver_home} looks like a battle has taken place rather than a game of Grout Bog Flip 'Em.
                        * It seems like neither {giver} nor {challenger} has won.
                        * You quickly leave the scene, hoping no one mistakes you as the killer for both.
                    }
                    {not challenger_dead?
                        * After the battle, {giver_home} looks like a battle has taken place rather than a game of Grout Bog Flip 'Em.
                        * You look at {challenger} as {challenger.heshe} addresses you.
                        player:
                            !left
                        challenger:
                            !right
                            Holy Hesh, you actually killed {giver.himher}.
                            I really wish it didn't have to come to this, but {giver} paid a huge price for {giver.hisher} arrogance.
                        player:
                            Now what?
                        challenger:
                            I'm going to leave.
                            I already wasted a ton of time trying to play with {giver}, and I have plenty of work to do.
                            Besides, I don't want to stick around for anyone to get the wrong idea.
                        {primary_advisor?
                        player:
                            Yeah, that too.
                            But I am asking what I should do now? {giver} is my advisor for my campaign.
                        challenger:
                            I don't know? Find another one?
                            You really don't want to have {giver} as your advisor, anyway, not with how badly {giver.heshe} can take a loss.
                            I will be leaving now, and good luck finding another advisor.
                            !exit
                        * As {challenger} leave, you quickly leave the scene as well.
                        }
                        {not primary_advisor?
                        player:
                            Same here.
                        * You and {challenger} quickly leave the scene.
                        }
                    }
                }
                {not dead?
                    {challenger_dead?
                        * Even as {giver} is defeated, {giver.heshe} still doesn't seem to want to give up.
                        player:
                            !left
                        giver:
                            !right
                            !injured
                            What gives? You would rather side with that <i>cheater</> than me?
                            Even, so, in the end, nothing has changed! {challenger.HeShe}'s dead anyway!
                        player:
                            !angry_accuse
                            You only accused {challenger.himher} for being a cheater because you lost, fair and square!
                    }
                    {not challenger_dead?
                        * Even as {giver} is defeated, {giver.heshe} still doesn't seem to want to give up.
                        giver:
                            !injured
                            You cheater! Nobody knows Grout Bog Flip 'Em better than me!
                            It is inconceivable!
                        challenger:
                            !left
                            !angry
                        {good_player?
                            !crossed
                            I've played against many players, and I do have to admit, nobody throws a temper tantrum larger than you.
                            You lost, so what? There will always people who are better than you.
                        }
                        {not good_player?
                            !dubious
                            You? Even I can beat you, and I suck at this game!
                            And even if I didn't beat you, there will always be people who are better than you.
                        }
                            But grown ups don't just try to kill other people when they lose at gambling.
                            Let this be a lesson to you.
                            !exit
                        * After some stern talking, {challenger} left, leaving you with {giver}.
                        player:
                            !left
                        giver:
                            !angry_accuse
                            What gives? You would rather side with that <i>cheater</> than me?
                        player:
                            I have to agree with {challenger} here.
                    }
                    player:
                        You have to accept that there are always people who are going to be better than you.
                        And killing people who are better than you doesn't change that!
                        !crossed
                        Sorry, I had to defend {challenger}. I can't allow you to throw a tantrum like that.
                    {advisor_hostile?
                    * It is then that {giver} realized what {giver.hisher} situation is.
                    giver:
                        !scared
                        Oh, Hesh. Did I just lose? Fair and square?
                    player:
                        !shrug
                        From what I can tell, seems like it.
                    agent:
                        !scared_shrug
                        But... I can't lose.
                        The Trunoomiel family didn't come this far by losing.
                        So... Why...?
                        I... Need to think.
                    player:
                        Okay...?
                    * You left {agent} alone to contemplate {agent.hisher} life choices.
                    }
                    {not advisor_hostile?
                    giver:
                        Uh, whatever.
                        But just know this: you betrayed me when I needed you the most.
                        So next time when you need me, expect nothing in return.
                    * You are left alone, contemplating your decisions.
                    * Was defending {challenger} really the right call?
                    }
                }
            ]],
            DIALOG_DEFEND_RUN = [[
                left:
                    !exit
                right:
                    !exit
                * You find an opening and run away.
                {primary_advisor?
                    giver:
                        !right
                        !angry_accuse
                        And don't come back!
                    * Well looks like this advisor is not willing to do more to help you now.
                }
                {not primary_advisor?
                    giver:
                        !right
                        !angry_accuse
                        That's right. Run like a coward.
                    * There is nothing left to do but to keep running away.
                    * You imagine that the next time you meet, {giver} will not be pleased to see you.
                }
            ]],
        }
        :Fn(function(cxt)
            cxt:TalkTo(cxt:GetCastMember("giver"))
            cxt:Opt("OPT_STEP_ASIDE")
                :Dialog("DIALOG_STEP_ASIDE")
                :Fn(function(cxt)
                    cxt.quest.param.poor_performance = true
                    cxt:GetCastMember("challenger"):Kill()
                end)
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
                        if cxt:GetCastMember("giver") == TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor") then
                            DemocracyUtil.UpdateAdvisor(nil, "ADVISOR_REJECTED")
                        end
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                    on_win = function(cxt)
                        cxt:Dialog("DIALOG_DEFEND_WIN")
                        if cxt:GetCastMember("giver"):IsAlive() then
                            cxt.quest:Fail()
                            if cxt:GetCastMember("giver") == TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor") then
                                cxt.quest:SpawnFollowQuest(FOLLOW_UP.id)
                            end
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
                if not giver or giver:IsRetired() then
                    return
                end
                if (giver:InLimbo() or giver:GetLocation() == giver:GetHomeLocation()) and not AgentUtil.IsInHiding(giver) and giver:GetBrain() then
                    giver:GetBrain():SendToPatronize(new_loc)
                end
            end
        end,
    },
    fill_out_quip_tags = function(quest, tags, agent)
        if agent == quest:GetCastMember("giver") then
            table.insert_unique(tags, "depressed")
        end
    end,
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
                Hey, it's alright. Everything is fine.
            agent:
                How could it be alright? I lost!
        ]],
        DIALOG_COMFORT_SUCCESS = [[
            player:
                I know it is hard for you to take in.
                "How could someone beat me, if nobody knows better than me?" is probably what you think, right?
            agent:
                That is true.
                Who am I if I can't beat another player? A loser, and a failure, that is who I am.
            player:
                !placate
                That is not true!
            agent:
                How is that not true? I lost!
            player:
                !shrug
                So what? We all lose sometimes.
                Even the most successful person loses sometimes.
                Losing doesn't make you a failure.
                You are still successful at lots of other things.
                Losing just means that there is room for improvement.
            agent:
                !dubious
                What? What you said doesn't make any sense.
            player:
                A winner doesn't necessarily need to win at everything. That is physically impossible.
                What separates a winner and a failure is not how many things they have won, but what they do when they lose.
                A failure sulk and and gives up when they lose, but a winner use this as an opportunity to improve themselves.
            agent:
                So... You are saying I am not a loser, even though I lost the game, as long as I learn from this mistake?
            player:
                That is indeed what I am saying.
            agent:
                Hmm... That... I am not used to this, but it does sound logical.
                I will give this though a try.
                Thanks for opening my eyes, {player}. I never thought of it that way.
            player:
                Glad I am able to help.
            agent:
                The election is coming up. We need to continue our work and improve ourselves, so we can be winners.
                I will do my best to help you from now on.
        ]],
        DIALOG_COMFORT_WIN = [[
            player:
                !crossed
                Are you going to stay like this forever?
                Are you really going to sulk because you've lost?
                The {agent} I know never admits defeat!
                The {agent} I know will always find a way to win!
            agent:
                !sigh
                Everything to you is about winning, isn't it?
            player:
                Well... I sure don't like losing.
                And neither should you.
            agent:
                The fact of the matter is, I lost that game.
            player:
                You can always win the next one!
            agent:
                That doesn't change what happened, does it?
                I always say that nobody knows more than me.
                But it turns out, there is someone who knows more than me, and probably other people as well.
                So if I am not the best, then who am I?
                A failure. A loser. That's who I am.
            player:
                Well-
            agent:
                Say no more.
                You are a winner, {player}. You always are.
                You don't have to talk to a loser like me.
            * It seems like you have worsened the situation.
            * Perhaps you shouldn't berate {agent}'s resolve until nothing is left?
            * It's too late now. {agent} doesn't even want to talk to you.
        ]],
        DIALOG_COMFORT_FAILURE = [[
            agent:
                !handwave
                I think I've heard enough.
                Nothing you say will change what happened.
                The fact of the matter is, I lost that game.
                I always say that nobody knows more than me.
                But it turns out, there is someone who knows more than me, and probably other people as well.
                So if I am not the best, then who am I?
                A failure. A loser. That's who I am.
            player:
                Hold on, that's not-
            agent:
                Say no more.
                You need a winner to help your campaign, {player}.
                You don't have to talk to a loser like me.
            * It seems like your attempt to brighten {agent}'s mood has worsened the situation.
            * It's too late now. {agent} doesn't even want to talk to you.
        ]],
        NEGOTIATION_REASON = "Comfort {agent}'s spirit!",
    }
    :Hub(function(cxt)
        if not cxt.quest.param.tried_comfort then
            cxt:Opt("OPT_COMFORT")
                :Dialog("DIALOG_COMFORT")
                :Fn(function(cxt)
                    cxt:GetAgent():SetTempNegotiationBehaviour(DEPRESSION_BEHAVIOUR)
                end)
                :Negotiation{
                    reason_fn = function(minigame) return cxt:GetLocString("NEGOTIATION_REASON") end,
                    -- This will be a special negotiation.
                    -- giver will start at low resolve, and you must bring their resolve to full to actually win the negotiation.
                    -- Winning negotiation without bringing up resolve, like using damage or oolo's requisition, has bad effect.

                    -- Opponent will have attacks targeting their own core.
                    -- Opponent will be given special bounties that will increase resolve or give composure.
                    -- You can also gift composure to opponent core via special action.
                    on_success = function(cxt, minigame)
                        -- local core = minigame:GetOpponentNegotiator():FindCoreArgument()
                        -- local resolve_left = core and core:GetResolve()
                        -- if resolve_left > (minigame.start_params.enemy_resolve_required
                        --     or MiniGame.GetPersuasionRequired( minigame:GetDifficulty() )) then

                        if minigame.restored_full_resolve then
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
                    !scared
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
                * You arrive at {giver}'s {advisor?office|home}, but {giver} is nowhere to be seen.
                * On {giver.hisher}, you found a note. It says:
                * "For my entire life, I know myself to be the best."
                * "That nobody knows anything better than me."
                * "Yet, it turns out, that is not true, and I was beaten by someone lower than me."
                * "I was beaten and humiliated, and for that, I have failed."
                * "I am a failure."
                * "And there is only one place for a failure like me."
                * "To whoever read my note, by the time that you are reading this, I have already moved on."
                * "Goodbye."
                * "P.S. To {player}, I could not bear myself to continue help you campaigning."
                * "You want someone who is successful to help you, not someone like me."
                * "Good luck with your campaign."
                * That is the end of the note.
                * You put down the notes, and stood solemnly for a long time.
                * Was it really the right call to convince {giver.himher} that {giver.heshe} lost to someone else, fair and square?
                * Maybe if you let {giver.himher} believe that {challenger.heshe} did cheat, things would turn out differently?
                * The past is irrelevant, now.
                * {giver} is gone.
                * Not dead, per se, because otherwise you can see it in the relationship screen.
                * But still. You can't find {giver}, and you have no idea where {giver.heshe} went.
                * There is nothing else for you to do here, now.
                * There is nothing more you could do.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Cancel()
            cxt.quest:GetCastMember("giver"):Retire()
            StateGraphUtil.AddEndOption(cxt)
        end)
