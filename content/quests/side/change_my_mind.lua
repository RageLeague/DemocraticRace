
local LOCATION_DEF =
{
    id = "POPULOUS_JUNCTION",
    name = "Populous Junction",
    desc = "A junction which many people crosses by. Good place for any sort of political activity.",
    -- icon = engine.asset.Texture("icons/quests/at_the_crossroad.tex"),
    map_tags = {"intersection"},
    plax = "EXT_door_slums1",
    indoors = false,
}
if not Content.GetLocationContent(LOCATION_DEF.id) then
    Content.AddLocationContent(LOCATION_DEF)
end

local MAX_DEBATE_NUM = 3

local cast_fn = function(agent, quest)
    return DemocracyUtil.RandomBystanderCondition(agent)
        and (quest.param.crowd == nil or not table.arrayfind(quest.param.crowd, agent))
        and (agent:GetRelationship() <= RELATIONSHIP.NEUTRAL or agent:HasAspect( "bribed" ))
end
local score_fn = function(agent, quest)
    local score = DemocracyUtil.OppositionScore(agent)
    if agent:HasAspect( "bribed" ) then
        score = score + 90
    end
    return score + math.random() * 120
end

local QDEF = QuestDef.Define
{
    title = "Change My Mind",
    desc = "Set up a booth that opens up debate to those who has doubt with your ideology. You might change their mind instead!",

    qtype = QTYPE.SIDE,
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"RALLY_JOB"},
    reward_mod = 0,
    extra_reward = false,
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/change_my_mind.png"),
    on_init = function(quest)
        quest.param.debated_people = 0
        quest.param.crowd = {}
    end,
    on_start = function(quest)
        quest:Activate("go_to_junction")
    end,
    on_destroy = function( quest )
        if quest:GetCastMember("junction") then
            TheGame:GetGameState():MarkLocationForDeletion(quest:GetCastMember("junction"))
        end
        for i, agent in ipairs( quest.param.crowd ) do
            agent:RemoveAspect("bribed")
        end
    end,
    on_complete = function( quest )
        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 2 * quest.param.debated_people + #quest.param.crowd, "COMPLETED_QUEST")
        -- if quest.param.poor_performance then
        --     DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -5, "POOR_QUEST")
        -- end
    end,
    on_fail = function( quest )
        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2 * quest.param.debated_people - #quest.param.crowd, "FAILED_QUEST")
        -- if quest.param.poor_performance then
        --     DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -5)
        -- end
    end,
}
:AddLocationCast{
    cast_id = "junction",
    when = QWHEN.MANUAL,
    no_validation = true,
}
:AddObjective{
    id = "go_to_junction",
    title = "Go to {junction#location}",
    desc = "Go to {junction#location} to set up a debate booth.",
    mark = { "junction" },
    -- state = QSTATUS.ACTIVE,
    
    on_activate = function( quest)
        local location = Location( LOCATION_DEF.id )
        assert(location)
        TheGame:GetGameState():AddLocation(location)
        quest:AssignCastMember("junction", location )
    end,
}
:AddObjective{
    id = "debate_people",
    title = "Debate people",
    desc = "Await people to come and debate you."
}
:AddCast{
    cast_id = "debater",
    when = QWHEN.MANUAL,
    no_validation = true,
    condition = cast_fn,
    score_fn = score_fn,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent() )
    end,
}
:AddCast{
    cast_id = "crowd",
    when = QWHEN.MANUAL,
    no_validation = true,
    condition = cast_fn,
    score_fn = score_fn,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent() )
    end,
}
:AddOpinionEvents{
    -- convinced_political_idea =  
    -- {
    --     delta = OPINION_DELTAS.LIKE,
    --     txt = "Enlightened them with your ideology",
    -- },
    reach_impasse = {
        delta = OPINION_DELTAS.OPINION_DOWN,
        txt = "Reached an impasse in a debate against them",
    },
    lost_debate = 
    {
        delta = OPINION_DELTAS.BAD,
        txt = "Lost a debate against them",
    },
}
-- QDEF:AddConvo("go_to_junction")
--     :Loc{

--     }
DemocracyUtil.AddPrimaryAdvisor(QDEF)
QDEF:AddConvo("go_to_junction")
    
    :Confront(function(cxt)
        if cxt.location == cxt.quest:GetCastMember("junction") then
            return "STATE_INTRO"
        end
    end)
    :State("STATE_INTRO")
        :Loc{
            DIALOG_INTRO = [[
                * You arrived at the junction and set up the booth.
                * It's a simple booth that states your political opinion, along with huge letters that says "Change My Mind".
                * Hopefully this will attract people's attention.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Complete("go_to_junction")
            cxt.quest:Activate("debate_people")
            -- cxt.quest.param.debated_people = 0
            -- cxt.quest.param.crowd = {}
            -- cxt:GoTo("STATE_DEBATE")
            -- cxt.quest:Complete()
            -- ConvoUtil.GiveQuestRewards(cxt)
        end)
QDEF:AddConvo("debate_people")
    :Confront(function(cxt)
        if cxt.location == cxt.quest:GetCastMember("junction") then
            if math.random() < cxt.quest.param.debated_people * 0.15 - 0.05 then
                return "STATE_ARREST"
            else
                return "STATE_DEBATE"
            end
        end
    end)
    :State("STATE_DEBATE")
        :Quips{
            {
                tags = "rebuttal",
                "Your argument is not sound.",
                "Here's why your claim is wrong.",
                "Your opinion is baseless.",
                "You need to try harder to convince me.",
            },
            {
                tags = "enlightened",
                "I... Huh. That's certainly a way to look at it.",
                "That was very enlightening.",
                "I never thought of that way.",
            },
            {
                tags = "impasse",
                "You are really dense.",
                "What a waste of time.",
                "It's like I'm talking to a brick!",
            },
            {
                tags = "impasse_followup",
                "Don't be a sore loser. Just accept the L.",
                "Well you didn't change my mind, so technically you wasted my time.",
                "Whatever, I still win.",
            },
        }
        :Loc{
            DIALOG_INTEREST = [[
                * People start to get curious about your booth.
                * Some of them look like they want to correct you, but others just stay to see what will happen next.
            ]],
            DIALOG_INTEREST_AGAIN = [[
                * As time passes by, more people stops to see what's going on.
            ]],
            DIALOG_CONFRONT = [[
                * One person shows up and confronts you.
                agent:
                    !right
                    !point
                    %confront_argument
            ]],
            OPT_DEBATE = "Debate!",
            TT_DEBATE = "Win the debate normally to convince {agent}, OR delay long enough for {agent} to concede.\n" ..
                "However, only convincing {agent} before {agent.heshe} gets too impatient can you completely convince {agent.himher}.\n",
            SIT_MOD = "{agent} is here to change your mind, not {agent.hishers}!",
            DIALOG_DEBATE = [[
                player:
                    !left
                    !point
                    %rebuttal
            ]],
            DEBATE_REASON = "Convince {agent}, OR delay long enough for {agent} to concede.",
            DIALOG_DEBATE_WIN = [[
                agent:
                    !dubious
                    %enlightened
                    !greeting
                    Thanks, {player}.
                player:
                    !happy
                    Glad you can see the light, my friend.
                agent:
                    !exit
            ]],
            DIALOG_DEBATE_IMPASSE = [[
                * You debated for a long time, and soon {agent} ran out of interest.
                agent:
                    !angry_shrug
                    %impasse
                    !exit
                player:
                    !point
                    %impasse_followup
                * Well, a win's a win.
                * ...right?
            ]],
            DIALOG_DEBATE_IMPASSE_BRIBED = [[
                * You debated for a long time, and it's clear that the debate isn't going anywhere.
                * It's time for {agent} to uphold {agent.hisher} end of the bargain.
                agent:
                    Oh the woes! I clearly have failed to change your mind!
                    Could it be that my ideology is inferior?
                player:
                    Apparently so.
                agent:
                    It is crystal clear that I need to reconsider my position.
                    For {player}'s ideology is far superior.
                    !hesh_greeting
                    Adieu, adieu.
                    !exit
                * That was overly dramatic, but {agent} did {agent.hisher} job. I guess.
            ]],
            DIALOG_DEBATE_LOST = [[
                * You debated for a long time, and it's clear that you can't win the debate.
                * Nothing else to do but packing up and accept your defeat.
            ]],
            DIALOG_DEBATE_LOST_BRIBED = [[
                * You debated for a long time, and it's clear that you can't win the debate.
                * Why did you pay for a shill, only for you to lose against them?
                * Anyway, time to remind {agent} what {agent.hisher} job is.
                player:
                    {agent}?
                agent:
                    Yeah?
                player:
                    !cruel
                    Should I remind you of the thing?
                {disliked?
                agent:
                    The thing? Yeah, I remember.
                    You're telling me to pretend to support you right?
                    !cruel
                    Well, change of plan, I'm just going to embarrass you in front of everyone here.
                player:
                    !angry
                    What? You bastard!
                    !angry_permit
                    Give me my money back!
                agent:
                    No can do, pal. Finders keepers.
                    !exit
                * {agent} leaves, leaving you contemplating your life decisions.
                }
                {not disliked?
                agent:
                    !eureka
                    The thing? Oh, right.
                * {agent} proceeds to make an argument literally anyone can refute.
                player:
                    !point
                    ...and that's why you're wrong.
                agent:
                    Oh the woes! I clearly have lost this debate!
                    Could it be that my ideology is inferior?
                player:
                    Apparently so.
                agent:
                    It is crystal clear that I need to reconsider my position.
                    For {player}'s ideology is far superior.
                    !hesh_greeting
                    Adieu, adieu.
                    !exit
                * It's clear that no one is fooled by this charade, but at least you can pretend that you're still winning.
                }
            ]],
            DIALOG_MET_QUOTA = [[
                * You have win enough debates to boost your popularity.
                * You can quit while you're ahead, or keep going to gain more support.
            ]],
            OPT_LEAVE = "Leave",
            TT_LEAVE = "This will complete the current quest.",
            DIALOG_LEAVE = [[
                player:
                    !exit
                * You leave before trouble arrives.
            ]],
            OPT_KEEP_GOING = "Continue with the setup",
            TT_KEEP_GOING = "You can do more debates, potentially boosting your popularity; however, you can also run into trouble.",
            DIALOG_KEEP_GOING = [[
                player:
                    I'm here to debate people, not fall back like a coward.
                    Bring it on!
            ]],
        }
        -- :SetLooping(true)
        :Fn(function(cxt)
            print(#(TheGame:GetGameState().agents))
            local interested_people = math.random(
                math.ceil(cxt.quest:GetRank() / 2),
                math.floor(cxt.quest:GetRank() / 2) + 2
            )
            local leaving_people = math.random(
                0,
                math.ceil(cxt.quest:GetRank() / 2)
            )
            for i = 1, leaving_people do
                for _, agent in cxt.location:Agents() do
                    if table.arrayfind(cxt.quest.param.crowd, agent) and agent ~= cxt.quest:GetCastMember("debater") then
                        agent:MoveToLimbo()
                        break
                    end
                end
            end

            for i = 1, interested_people do
                cxt.quest:AssignCastMember("crowd")
                cxt.quest:GetCastMember("crowd"):MoveToLocation(cxt.location)
                table.insert(cxt.quest.param.crowd, cxt.quest:GetCastMember("crowd"))
                cxt.quest:UnassignCastMember("crowd")
            end
            
            
            if cxt.quest.param.debated_people == 0 then
                
                cxt:Dialog("DIALOG_INTEREST")
            else
                cxt:Dialog("DIALOG_INTEREST_AGAIN")
            end

            
            cxt.quest:AssignCastMember("debater")
            cxt.quest:GetCastMember("debater"):MoveToLocation(cxt.location)
            table.insert(cxt.quest.param.crowd, cxt.quest:GetCastMember("debater"))
            cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("debater"))
            cxt:Dialog("DIALOG_CONFRONT")

            cxt:Opt("OPT_DEBATE")
                :PostText("TT_DEBATE")
                :Dialog("DIALOG_DEBATE")
                :Negotiation{
                    -- flags = NEGOTIATION_FLAGS.NO_AUTOFAIL,
                    cooldown = 0,
                    reason_fn = function(minigame) return cxt:GetLocString("DEBATE_REASON") end,
                    
                    situation_modifiers =
                    {
                        { value = 5 * math.ceil(cxt.quest:GetRank()/2), text = cxt:GetLocString("SIT_MOD") }
                    },

                    on_start_negotiation = function(minigame)
                        minigame.player_negotiator:AddModifier("PLAYER_ADVANTAGE", math.max(4, 6 - math.floor(cxt.quest:GetRank() / 2)))
                        if cxt.quest.param.debated_people >= 2 then
                            minigame.player_negotiator:AddModifier("FATIGUED")
                        end
                        minigame.opponent_negotiator:AddModifier("IMPATIENCE", cxt.quest.param.debated_people)
                    end,
                    on_success = function(cxt, minigame) 
                        
                        if minigame.impasse then
                            if cxt:GetAgent():HasAspect("bribed") then
                                cxt:Dialog("DIALOG_DEBATE_IMPASSE_BRIBED")
                            else
                                cxt:Dialog("DIALOG_DEBATE_IMPASSE")
                                cxt.quest:GetCastMember("debater"):OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("reach_impasse"))
                                -- ConvoUtil.DoResolveDelta(cxt, -5)
                            end
                        else
                            cxt:Dialog("DIALOG_DEBATE_WIN")
                            cxt.quest:GetCastMember("debater"):OpinionEvent(OPINION.CONVINCE_SUPPORT)
                        end

                        cxt.quest:GetCastMember("debater"):MoveToLimbo()
                        cxt.quest:UnassignCastMember("debater")
                        cxt.quest.param.debated_people = cxt.quest.param.debated_people + 1
                        if cxt.quest.param.debated_people >= 2 then
                            cxt:Dialog("DIALOG_MET_QUOTA")
                            cxt:Opt("OPT_LEAVE")
                                :PostText("TT_LEAVE")
                                :Dialog("DIALOG_LEAVE")
                                :CompleteQuest()
                                :DoneConvo()
                                -- :Fn(function(cxt) StateGraphUtil.AddLeaveLocation(cxt) end)
                            cxt:Opt("OPT_KEEP_GOING")
                                :PostText("TT_KEEP_GOING")
                                :Dialog("DIALOG_KEEP_GOING")
                        end
                        -- cxt:GoTo("STATE_PICK_SIDE")
                    end,
                    on_fail = function(cxt)
                        if cxt:GetAgent():HasAspect("bribed") then
                            cxt:Dialog("DIALOG_DEBATE_LOST_BRIBED")
                            if cxt:GetAgent():GetRelationship() < RELATIONSHIP.NEUTRAL then
                                cxt.quest:GetCastMember("debater"):OpinionEvent(OPINION.BETRAYED)
                                DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -5)
                                cxt:Opt("OPT_ACCEPT_FAILURE")
                                    :FailQuest()
                            else
                                DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -3)
                            end
                        else
                            cxt:Dialog("DIALOG_DEBATE_LOST")
                            -- Some might take it cooler than others.
                            -- And also otherwise it will be too punishing if you fail.
                            -- However, a disliked person CAN hate you.
                            if math.random() < 0.5 then
                                cxt.quest:GetCastMember("debater"):OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("lost_debate"))
                            end
                            cxt:Opt("OPT_ACCEPT_FAILURE")
                                :FailQuest()
                        end
                    end,
                }
        end)
    :State("STATE_ARREST")
        :Loc{
            DIALOG_CONFRONT = [[
                * It is not before long before the Admiralty arrives.
                player:
                    !left
                agent:
                    !right
                    !angry_accuse
                    Hey you! This is an illegal gathering!
                    You're disrupting the public order!
                    You're coming with me!
            ]],
            OPT_AUTHORIZE = "[{1#graft}] Show your authorized permit",
            DIALOG_AUTHORIZE = [[
                player:
                    !placate
                    No need to be hasty, my friend.
                    !permit
                    {1#agent} authorized this gathering.
                agent:
                    Oh really now?
                    !neutral_notepad
                * {agent} takes a good look at the permit.
                agent:
                    That checks out.
                    Fine, we won't arrest you, but you better disperse soon.
                player:
                    Okay.
                agent:
                    !exit
                * It turns out having connections in the Admiralty is a good thing. Who would've known?
            ]],
            OPT_CONVINCE = "Convince {agent} to let you leave",
            DIALOG_CONVINCE = [[
                player:
                    !placate
                    Look, I mean no harm.
                    Just let me go, okay?
                agent:
                    And why would I let you do that?
            ]],
            DIALOG_CONVINCE_WIN = [[
                player:
                    !handwave
                    Just pretend I was never here, okay?
                    It's such a minor offense that doesn't harm anyone.
                    It's just not worth it to arrest me and escort me to the station.
                agent:
                    !sigh
                    You're right. I hate escort missions. They're so annoying.
                    Just go. Don't let me see you do that again.
                player:
                    Thanks. I'll be going now.
                    !exit
                * You leave before {agent} changes {agent.hisher} mind.
            ]],
            DIALOG_CONVINCE_LOSE = [[
                agent:
                    !fight
                    That's enough.
                    You're coming with me!
            ]],
            OPT_RESIST_ARREST = "Resist Arrest",
            DIALOG_RESIST_ARREST = [[
                player:
                    !fight
                    Why don't you make me?
            ]],
            DIALOG_RESIST_ARREST_SUCCESS = [[
                * Good job. You might still be free, but your reputation will suffer.
            ]],
            DIALOG_RESIST_ARREST_RUNAWAY = [[
                left:
                    !exit
                right:
                    !exit
                * You ran away from the scene.
                * It might seem cowardly, but you did what you came here to do.
                * And that's good enough for you.
            ]],
        }
        :Fn(function(cxt)
            cxt.enc.scratch.opfor = CreateCombatParty("ADMIRALTY_PATROL", cxt.quest:GetRank() + 1, cxt.location)
            cxt.enc:SetPrimaryCast(cxt.enc.scratch.opfor[1])

            cxt:Dialog("DIALOG_CONFRONT")
            local graft = cxt.player.graft_owner:FindGraft(function(graft)
                if graft.id == "authorization" then
                    return not graft:GetDef().OnCooldown( graft )
                end
                return false
            end)
            if graft then
                cxt:Opt("OPT_AUTHORIZE", graft)
                    :Dialog("DIALOG_AUTHORIZE", graft.userdata.agents[1])
                    :Fn(function()
                        graft:GetDef().StartCooldown( graft ) 
                    end)
                    :CompleteQuest()
            end
            cxt:Opt("OPT_CONVINCE")
                :Dialog("DIALOG_CONVINCE")
                :Negotiation{
                    on_success = function(cxt)
                        cxt:Dialog("DIALOG_CONVINCE_WIN")
                        cxt.quest:Complete()
                        ConvoUtil.GiveQuestRewards(cxt)
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_CONVINCE_LOSE")

                        cxt:Opt("OPT_RESIST_ARREST")
                            :Dialog("DIALOG_RESIST_ARREST")
                            :Battle{
                                on_win = function(cxt)
                                    cxt:Dialog("DIALOG_RESIST_ARREST_SUCCESS")
                                    cxt.quest.param.poor_performance = true
                                    cxt.quest:Complete()
                                    ConvoUtil.GiveQuestRewards(cxt)
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                end,
                                on_runaway = function(cxt, battle)
                                    cxt:Dialog("DIALOG_RESIST_ARREST_RUNAWAY")
                                    cxt.quest.param.poor_performance = true
                                    cxt.quest:Complete()
                                    -- you get no quest reward for such hasty exit.
                                    -- don't ask how it works.
                                    StateGraphUtil.DoRunAwayEffects( cxt, battle, true )
                                end,
                            }
                    end,
                }
        end)
-- QDEF:AddConvo("debate_people")
    

QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
                Perhaps a good idea would be to set up a booth that says "change my mind" on it.
            {not has_primary_advisor?
                People might get interested in it and stop by, and I can spread my ideology.
                People might also try and debate me about my ideology.
                I can convince them to join my side.
            }
            {has_primary_advisor?
                primary_advisor:
                    Interesting. It's just like that meme, but this time, it's serious.
                    People might get interested by this premise and stop by.
                player:
                    Then we can use this opportunity to spread our ideology!
                primary_advisor:
                    Just try not to make a fool out of yourself, okay?
            }
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.ACCEPTED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
            {not has_primary_advisor?
                Good idea. I'll go to a junction with many people passing by and set up my booth.
            }
            {has_primary_advisor?
                I think I can handle a few hecklers.
            primary_advisor:
                Very well. Now find a populous junction and set up your booth.
            }
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            -- cxt.quest:Activate("go_to_junction")
        end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.DECLINED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
            {not has_primary_advisor?
                Too risky. I might embarrass myself in front of a huge crowd.
            }
            {has_primary_advisor?
                Good point. I guess we need to find another way.
            }
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)