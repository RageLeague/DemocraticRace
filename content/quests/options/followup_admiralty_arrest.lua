-- this is a followup of a convo option. Can't automatically spawn
local QDEF = QuestDef.Define
{
    qtype = QTYPE.FOLLOWUP,
}
:AddCast{
    cast_id = "admiralty",
    no_validation = true,
    unimportant = true,
    cast_fn = function(quest, t)
        -- can't automatically spawn
    end,
    events = {
        agent_retired = function(quest, agent)
            quest:Fail()
        end,
    },
}
:AddCast{
    cast_id = "target",
    no_validation = true,
    unimportant = true,
    cast_fn = function(quest, t)
        -- can't automatically spawn
    end,
    on_assign = function(quest, agent)
        quest.param.target_faction = agent:GetFactionID()
        if agent:GetRenown() + agent:GetCombatStrength() >= math.random(4,7) then
            quest.param.high_bounty = true
        end
        if agent:GetFactionID() == "ADMIRALTY" then
            quest.param.is_ad = true
        end
        if agent:GetFactionID() == "SPARK_BARON" or agent:GetFactionID() == "CULT_OF_HESH" then
            quest.param.rival_faction = true
            
        end
        if agent:GetFaction():IsUnlawful() then
            quest.param.unlawful = true
        end
    end,
    events = {
        agent_retired = function(quest, agent)
            quest:Complete()
        end,
    },
}
:AddObjective{
    id = "wait",
    hide_in_overlay = true,
    state = QSTATUS.ACTIVE,

    events = 
    {
        action_clock_advance = function(quest, location)
            -- if quest.param.dormant_start_time ~= Now() then
            --     quest.param.dormant_timer = (quest.param.dormant_timer or 0) - 1
            --     if quest.param.dormant_timer <= 0 then
                    quest:Complete("wait")
                    if math.random(1, 10) <= quest.param.guilt_score then
                        quest:Activate("action")
                    else
                        quest:Activate("innocent")
                    end
            --     end

            -- end
        end,
    },

    on_activate = function(quest)
        quest.param.dormant_timer = quest.param.investigate_difficulty - math.random(0,3)
        -- if wait_for_next_time then
        quest.param.dormant_start_time = Now()
        -- end
    end,
}
:AddObjective{
    id = "action",
    on_activate = function(quest)
        local score = (quest.param.arrest_difficulty or 5) + math.random(-2,2)
        if score <= 3 then
            quest.param.dominate = true
        elseif score >= 7 then
            quest.param.defeated = true
        else
            quest.param.impasse = true
        end
    end,
}
:AddObjective{
    id = "innocent",
}
:AddOpinionEvents{
    
    wasted_their_time = {
        delta = OPINION_DELTAS.DIMINISH,
        txt = "Wasted their time on a false lead",
    },
    suspects_setup = {
        delta = OPINION_DELTAS.BAD,
        txt = "Suspects you set them up",
    },
    saved_from_arrest = {
        delta = OPINION_DELTAS.MAJOR_GOOD,
        txt = "Saved them from Admiralty arrest",
    },
    helped_arrested_bounty = {
        delta = OPINION_DELTAS.MAJOR_GOOD,
        txt = "Helped them capture a notorious criminal",
    },
    helped_arrested_bounty_interrupted = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Lead them to capture a notorious criminal, but you tried to intervene",
    },
}

QDEF:AddConvo("action")
    :Confront(function(cxt)
        if cxt.location:HasTag("in_transit") and TheGame:GetGameState():CanSpawnTravelEvent() then
            -- if cxt.quest.param.dominate then
                return "STATE_DOMINATE"
            -- elseif cxt.quest.param.defeated then
            --     return "STATE_DEFEATED"
            -- else
            --     return "STATE_IMPASSE"
            -- end
        end
    end)
    
    :State("STATE_DOMINATE")
        :Loc{
            DIALOG_INTRO = [[
                * You see {admiralty} arrested {agent}.
                agent:
                    !right
                    !injured
                admiralty:
                    !left
                    !angry
                agent:
                {is_ad?
                    Why are you doing this?
                    Aren't we both in the Admiralty?
                admiralty:
                    We might both be, but only one is a criminal.
                    I've received a tip that you have been abusing your power for so long. It's time to end this.
                agent:
                    You talk big, but you are in the same boat, aren't you?
                    Abuse of power is literally your core argument.
                }
                {rival_faction?
                    You know we have a truce right?
                    We settle everything peacefully with the election once and for all.
                    Are you going to resume the war?
                admiralty:
                    I don't particularily care.
                    I'm sure the {target_faction#faction} are going to be happy now that I got rid of a criminal for them.
                }
                {unlawful?
                    You will regret this, switch.
                    The {target_faction#faction} will come and save me, and you'll be dead.
                admiralty:
                    I don't think so, criminal scum.
                    They don't care about someone like you.
                }
                {not (is_ad or rival_faction or unlawful)?
                    What did I do to deserve this?
                admiralty:
                    I don't know. Committing crime?
                    If you don't want to get arrested, have you tried not committing any crime?
                }
                admiralty:
                    !angry_accuse
                    Now, are you going to come quiet or not?
                * {agent} sees you.
                player:
                    !left
                agent:
                {not disliked?
                    Please, you have to get me out of here!
                }
                {disliked?
                    !angry
                    Oh, it's you.
                    Are you happy now, seeing me like this?
                }

            ]],

            OPT_TAUNT = "Taunt {target}",
            DIALOG_TAUNT = [[
                {disliked?
                player:
                    !angry
                    Yes. That is exactly how I feel when I asked {admiralty} to investigate you.
                agent:
                    !surprised
                    What? YOU are the one that caused this?
                    !angry_accuse
                    I always have a feeling it is you.
                {unlawful?
                player:
                    How, exactly do you know it's me when you keep engage in illegal activities?
                    Pretty sure you are on someone's bounty list anyway.
                    Eventually, your deeds are going to bite you in the back.
                agent:
                    Oh, they're going to bite your back all right.
                |
                player:
                    So what, Captain Hindsight? What are you going to do about it?
                }
                }
                {not disliked?
                player:
                    !shrug
                    Why should I, when <i>I'm</> the one that asked {admiralty} to investigate you.
                agent:
                    !surprised
                    What? YOU are the one that caused this?
                    Why?
                player:
                    To send a message, of course.
                    !cruel
                    You made way too many enemies because of your action. And actions have consequences.
                agent:
                    Oh, actions have consequences all right.
                }
                agent:
                    I won't forget this.
                    If I ever got out of jail, I <i>will</> find you, and you <i>will</> regret the day you did this.
                admiralty:
                    !left
                    Witness intimidation, that's going to be a few more years, buddy.

            ]],

            OPT_RECONSIDER = "Convince {admiralty} to reconsider",

            DIALOG_RECONSIDER = [[
                admiralty:
                    !right
                player:
                    !left
                    Can you reconsider?
                admiralty:
                    !surprised
                    Wait, what? This isn't part of the plan!
            ]],

            DIALOG_RECONSIDER_SUCCESS = [[
                player:
                {is_ad?
                    It's probably not a good idea to in-fight.
                    You can probably let whatever did slide, right?
                }
                {rival_faction?
                    I've been reconsidering my positions in the last few days.
                    Then I realized now it's not a good time to start a war with the {target_faction#faction}.
                    That's what the election is trying to <i>prevent</>.
                }
                {not (is_ad or rival_faction)?
                    The elections are coming soon, and we don't want to start arresting people now.
                    People will think we are blocking votes or something. That's bad for our reputation.
                }
                admiralty:
                    Fine, you win.
                    You're free to go.
                target:
                    !left
                    What, really?
                admiralty:
                    Just go. Forget this ever happened.
                    I have enough trouble as it is.
                    !exit
                    Stupid grifters and their elections.
                * {admiralty} left.
            ]],

            DIALOG_RECONSIDER_FAILURE = [[
                player:
                    You should probably let {target.himher} go.
                admiralty:
                    Why should I, {player}?
                    You told me to investigate {target} and I did.
                target:
                    !right
                    !surprised
                    You what?
                admiralty:
                    !right
                    This took me way too much time. I'm not going to back away just because you said so.
                    Just, stay out of my way until I bring this scum to the station.
            ]],

            SIT_MOD_BASE = "{admiralty} worked really hard to arrest {target}!",
            SIT_MOD_AD = "{target} is an Admiralty.",
            SIT_MOD_RIVAL = "{target} is a rival faction to the admiralty.",
            SIT_MOD_UNLAWFUL = "{target} is a criminal faction.",
        }
        :Fn(function(cxt)
            local function ArrestFn(cxt)
                cxt.quest:GetCastMember("target"):OpinionEvent(OPINION.SOLD_OUT_TO_ADMIRALTY)
                cxt.quest:GetCastMember("target"):GainAspect("stripped_influence", 5)
                cxt:GoTo("STATE_PROMOTION")
            end
            cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("target"))
            cxt:Dialog("DIALOG_INTRO")
            cxt:Opt("OPT_TAUNT")
                :Dialog("DIALOG_TAUNT")
                :Fn(ArrestFn)
            local sitmod = {
                { value = 10, text = cxt:GetLocString("SIT_MOD_BASE") }
            }
            if cxt.quest.param.is_ad then
                table.insert(sitmod, { value = -10, text = cxt:GetLocString("SIT_MOD_AD") })
            elseif cxt.quest.param.rival_faction then
                table.insert(sitmod, { value = -5, text = cxt:GetLocString("SIT_MOD_RIVAL") })
            elseif cxt.quest.param.unlawful then
                table.insert(sitmod, { value = 10, text = cxt:GetLocString("SIT_MOD_UNLAWFUL") })
            end
            cxt:BasicNegotiation("RECONSIDER", {
                target_agent = cxt.quest:GetCastMember("admiralty"),
                situation_modifiers = sitmod,
                helpers = {"target"},
            }):OnSuccess()
                :Fn(function(cxt)
                    cxt.quest:GetCastMember("admiralty"):OpinionEvent(OPINION.WASTED_TIME)
                    cxt:GoTo("STATE_SAVE_TARGET")
                end)
            :OnFailure()
                :Fn(function(cxt)
                    cxt.quest.param.interrupted = true
                    ArrestFn(cxt)
                end)
        end)
    :State("STATE_PROMOTION")
        :Loc{
            DIALOG_PROMOTION = [[
                agent:
                    This person is quite the notorious criminal.
                    Now I've captured {target.himher}, I'm going to get promoted.
                    It's all thanks to your lead, {player}.
                {interrupted?
                    Even though you tried to interfere in the end.
                    I have no idea what you're thinking.
                }
                ** {agent} will be promoted to an Admiralty Patrol Leader if {agent.heshe} isn't one already.
                player:
                    That's great!
            ]],
            DIALOG_LEAVE = [[
                player:
                    !left
                agent:
                    !right
                    Well, I'm bringing this guy to the station.
            ]],
            DIALOG_LEARN_STATION = [[
                player:
                    Wait, how to you go to the Admiralty Headquarters again?
                agent:
                    Oh, I guess you've never been there before.
                    I'll show you.
                * {agent} describes the directions to the HQ.
            ]],
            DIALOG_END = [[
            agent:
            {interrupted?
                I was quite disappointed with what you did back there.
                Oh well. All's well that Maxwell.
                I mean, ends well.
            }
                See you!
                !exit
            {interrupted?
                That was real weird.
            }
            * You left {agent} to escort {target}.
            * Hopefully you'll never see {target} again.
            ]]
        }
        :Fn(function(cxt)
            cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("admiralty"))
            
            if cxt.quest.param.high_bounty then
                cxt:Dialog("DIALOG_PROMOTION")
                if cxt.quest.param.interrupted then
                    cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("helped_arrested_bounty_interrupted"))
                else
                    cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("helped_arrested_bounty"))
                end
            end

            cxt:Dialog("DIALOG_LEAVE")
            if not DemocracyUtil.LocationUnlocked("ADMIRALTY_BARRACKS") then
                cxt:Dialog("DIALOG_LEARN_STATION")
                DemocracyUtil.DoLocationUnlock(cxt, "ADMIRALTY_BARRACKS")
            end
            cxt:Dialog("DIALOG_END")
            cxt.quest:GetCastMember("target"):Retire()
            cxt.quest:GetCastMember("admiralty"):MoveToLocation(TheGame:GetGameState():GetLocation("ADMIRALTY_BARRACKS"))
            cxt.quest:Complete()
            if cxt.quest.param.high_bounty then
                if cxt.quest:GetCastMember("admiralty"):GetContentID() ~= "ADMIRALTY_PATROL_LEADER" then
                    DemocracyUtil.DoSentientPromotion(cxt.quest:GetCastMember("admiralty"), "ADMIRALTY_PATROL_LEADER")
                else
                    -- do something to patrol leader. Haven't figured out what
                end
            end
            StateGraphUtil.AddLeaveLocation(cxt)
        end)
    :State("STATE_SAVE_TARGET")
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
                agent:
                    !right
                {disliked?
                    Why did you do that?
                    You could've just sat aside and do nothing, yet you chose to save me.
                player:
                    I don't know. Maybe I want to help you, that's all.
                agent:
                    Nah. I don't trust you. There's got to be more to this.
                    Care to explain what is this "plan" that {admiralty} mentioned?
                }
                {not disliked?
                    Thanks, mate.
                    I was in a real pickle there.
                player:
                    I can't just stand around here and do nothing, seeing innocent people getting arrested.
                    {unlawful?
                        "Relatively" innocent, anyway.
                    }
                agent:
                    I would've believed you, if {admiralty} didn't mention a plan, that you are a part of.
                    Care to explain it?
                }
            ]],
            OPT_BRUSH_OFF = "Brush off {agent}'s concern",
            DIALOG_BRUSH_OFF = [[
                player:
                    !handwave
                    Don't worry about it.
                agent:
                    Now worrying is all I care about.
                    !angry_accuse
                    I'm starting to think you set me up!
                    !throatcut
                    Watch your back, grifter.
                    !exit
                * {agent.HeShe} leaves, and so should you.
            ]],
            OPT_EXCUSE = "Make an excuse",
            DIALOG_EXCUSE = [[
                player:
                    There's a simple reason for it.
                agent:
                    Oh yeah?
                    !clap
                    Let's hear it.
            ]],
            DIALOG_EXCUSE_SUCCESS = [[
                agent:
                    You talked a lot, and I think I heard enough.
                    It's probably a blame tactics, anyway.
                player:
                    Sure, let's go with that.
                agent:
                {disliked?
                    Looks like I misjudged you.
                    |
                    Thanks again for saving me.
                }
                    Be seeing you around, {player}.
                    !exit
            ]],
            DIALOG_EXCUSE_FAILURE = [[
                agent:
                    That just sounds like a poor excuse.
                    I don't buy your story.
                    You were trying to set me up, aren't you?
                player:
                    Uhh...
                agent:
                {disliked?
                    I knew you were up to no good.
                    Here I thought you actually did a good thing for once.
                    That would be too ideal, wouldn't it?
                    |
                    Here I thought there's finally good in Havaria.
                    Of course not. Why would there be good in Havaria? That's ridiculous.
                player:
                    Well, you <i>are</> a criminal who committed a crime. I wouldn't exactly call helping you "good".
                agent:
                    So you revealed your true colors, huh?
                }
                    !throatcut
                    Watch your back, grifter.
                    !exit
                * {agent.HeShe} leaves, and so should you.
            ]]
        }
        :Fn(function(cxt)
            cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("target"))
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_BRUSH_OFF")
                :Dialog("DIALOG_BRUSH_OFF")
                :ReceiveOpinion("suspects_setup")
                :CompleteQuest()
                :Travel()

            cxt:BasicNegotiation("EXCUSE")
                :OnSuccess()
                    :ReceiveOpinion("saved_from_arrest")
                    :CompleteQuest()
                    :Travel()
                :OnFailure()
                    :ReceiveOpinion("suspects_setup")
                    :CompleteQuest()
                    :Travel()
        end)

QDEF:AddConvo("innocent", "admiralty")
    :Loc{
        OPT_ASK = "Ask about {agent}",
        DIALOG_ASK = [[
            player:
                Any progress on {target}?
            agent:
                Yeah, so turns out {target} is completely innocent.
                I can't find any dirt on {target.himher}.
                Thanks for letting me follow a false lead, {player}.
            player:
                Hey, that's not my fault!
                How am I supposed to know whether {target} is innocent or not?
                It's supposed to be your job!
            agent:
                With this time, I could've did other meaningful things that can get me promoted!
                Instead, my time is wasted on a wild goose chase.
                Didn't I tell you? Us Admiralty are getting really busy because of the election.
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_ASK")
            :Dialog("DIALOG_ASK")
            :ReceiveOpinion("wasted_their_time")
            :FailQuest()
    end)