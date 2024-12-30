
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
    -- on_start = function(quest)
    --     quest:Activate("go_to_junction")
    -- end,
    on_destroy = function( quest )
        if quest:GetCastMember("junction") then
            TheGame:GetGameState():MarkLocationForDeletion(quest:GetCastMember("junction"))
        end
        for i, agent in ipairs( quest.param.crowd or {} ) do
            agent:RemoveAspect("bribed")
        end
    end,
    on_complete = function( quest )
        local support = DemocracyUtil.GetBaseRallySupport(quest:GetDifficulty()) - 4
        support = support + 2 * (quest.param.debated_people or 0)
        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", support, "COMPLETED_QUEST")
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
            cxt.quest.param.total_debate_count = cxt.quest.param.total_debate_count or math.ceil(math.sqrt(math.random(4, 25)))
            if cxt.quest.param.debated_people >= cxt.quest.param.total_debate_count then
                return "STATE_ARREST"
            else
                return "STATE_DEBATE"
            end
        end
    end)
    :State("STATE_DEBATE")
        :Quips{
            {
                tags = "enlightened",
                "I... Huh. That's certainly a way to look at it.",
                "That was very enlightening.",
                "I never thought of that way.",
            },
            {
                tags = "good_impasse",
                [[
                    You did raise some good points.
                    Sadly, those points are not good enough.
                ]],
                [[
                    agent:
                        That was quite a debate.
                    player:
                        Does that mean you're convinced?
                    agent:
                        Well, no. That just means I had a lot of fun.
                ]],
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
            DIALOG_CONFRONT_ENEMY = [[
                * Now that {agent} brought {agent.self} to you, perhaps you can use this public opportunity to ruin {agent.hisher} life.
                * If you do that, though, it will cause a significant disruption that you can't debate anymore.
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
            DIALOG_DEBATE_IMPASSE_GOOD = [[
                * You debated for a long time, and soon {agent} ran out of interest.
                agent:
                    %good_impasse
                player:
                    !shrug
                    Whatever. A win's a win.
                    No hard feelings, right?
                agent:
                    Sure.
                    !exit
                * You didn't fully convince {agent}, but you still won. And {agent} wasn't annoyed.
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
                * There is only one thing left to do...
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
                * Your plan is exposed, as {agent} betrays you.
                * There is only one thing left to do...
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
            OPT_KEEP_GOING = "Keep going",
            TT_KEEP_GOING = "You can do more debates, potentially boosting your popularity; however, you can also run into trouble.",
            DIALOG_KEEP_GOING = [[
                player:
                    I'm here to debate people, not fall back like a coward.
                    Bring it on!
            ]],


            OPT_PATROL = "Attempt to arrest {debater} with nearby Admiralty patrol...",
            OPT_DENOUNCE = "Publicly denounce {debater}'s character..."
        }
        -- :SetLooping(true)
        :Fn(function(cxt)
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

            if DemocracyUtil.PunishTargetCondition(cxt:GetAgent()) then
                cxt:Dialog("DIALOG_CONFRONT_ENEMY")
                if cxt:GetAgent():GetFactionID() ~= "ADMIRALTY" then
                    cxt:Opt("OPT_PATROL")
                        :GoTo("STATE_ARREST_TARGET")
                end
                for _, agent in cxt.location:Agents() do
                    if table.arrayfind(cxt.quest.param.crowd, agent) and agent ~= cxt.quest:GetCastMember("debater") then
                        cxt:Opt("OPT_DENOUNCE")
                            :GoTo("STATE_DENOUNCE_TARGET")
                        break
                    end
                end
            end
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
                        local core = minigame:GetOpponentNegotiator():FindCoreArgument()
                        local resolve_left = core and core:GetResolve()
                        if minigame.impasse and resolve_left then
                            if cxt:GetAgent():HasAspect("bribed") then
                                cxt:Dialog("DIALOG_DEBATE_IMPASSE_BRIBED")
                            elseif resolve_left <= 10 then
                                -- instead of random, we now have a scale.
                                -- if opponent resolve is 10 or less when impasse, they will enjoy the debate.
                                -- otherwise, you suck, and deserve a dislike
                                -- might adjust the value later
                                cxt:Dialog("DIALOG_DEBATE_IMPASSE_GOOD")
                            else
                                cxt:Dialog("DIALOG_DEBATE_IMPASSE")
                                cxt.quest:GetCastMember("debater"):OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("reach_impasse"))
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
                                :Fn(function(cxt)
                                    cxt:End()
                                end)
                        else
                            cxt:Opt("OPT_KEEP_GOING")
                                :Fn(function(cxt)
                                    cxt:End()
                                end)
                        end
                        -- cxt:GoTo("STATE_PICK_SIDE")
                    end,
                    on_fail = function(cxt)
                        if cxt:GetAgent():HasAspect("bribed") then
                            cxt:Dialog("DIALOG_DEBATE_LOST_BRIBED")
                            if cxt:GetAgent():GetRelationship() < RELATIONSHIP.NEUTRAL then
                                cxt.quest:GetCastMember("debater"):OpinionEvent(OPINION.BETRAYED)
                                DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2)
                                cxt:GoTo("STATE_FAIL")
                            else
                                DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -1)
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
                                        :Fn(function(cxt)
                                            cxt:End()
                                        end)
                                else
                                    cxt:Opt("OPT_KEEP_GOING")
                                        :Fn(function(cxt)
                                            cxt:End()
                                        end)
                                end
                            end
                        else
                            cxt:Dialog("DIALOG_DEBATE_LOST")
                            -- if math.random() < 0.5 then
                            cxt.quest:GetCastMember("debater"):OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("lost_debate"))
                            -- end
                            cxt:GoTo("STATE_FAIL")
                        end
                    end,
                }
        end)
    :State("STATE_FAIL")
        :Loc{
            DIALOG_ACCEPT_FAILURE = [[
                * Nothing else for you to do except leaving the scene, utterly humiliated.
                * This failure will be remembered by the public for a long time.
            ]],
            OPT_PATROL = "Attempt to arrest {debater} with nearby Admiralty patrol...",
            OPT_DENOUNCE = "Publicly denounce {debater}'s character..."
        }
        :Fn(function(cxt)
            if cxt:GetAgent():GetFactionID() ~= "ADMIRALTY" then
                cxt:Opt("OPT_PATROL")
                    :GoTo("STATE_ARREST_TARGET")
            end
            for _, agent in cxt.location:Agents() do
                if table.arrayfind(cxt.quest.param.crowd, agent) and agent ~= cxt.quest:GetCastMember("debater") then
                    cxt:Opt("OPT_DENOUNCE")
                        :GoTo("STATE_DENOUNCE_TARGET")
                    break
                end
            end
            cxt:Opt("OPT_ACCEPT_FAILURE")
                :FailQuest()
                :DoneConvo()
        end)
    :State("STATE_ARREST_TARGET")
        :Loc{
            DIALOG_ARREST = [[
                * You turned your attention to a nearby Admiralty patrol.
                patrol:
                    !right
                player:
                    !left
                    Good day, officer!
                patrol:
                {bad_relation?
                    !humoring
                    Well, look at that.
                    I thought you hated the Admiralty? What changed your tone?
                player:
                    !crossed
                    I'm just here to remind you to do your job, that is all.
                    'Cause, {debater} over here is causing a lot of trouble, and it is your job to deal with it.
                }
                {not bad_relation?
                    What seems to be the problem, good citizen?
                player:
                    {debater} over here is causing a lot of trouble. You should probably deal with {debater.himher}.
                }
                debater:
                    !right
                    !angry_accuse
                    Hey! What are you doing there?
                patrol:
                    !right
                    !dubious
                    Is that a fact?
            ]],
            OPT_CONVINCE = "Convince {patrol} that {debater} is causing troubles",
            DIALOG_CONVINCE = [[
                player:
                    !agree
                    It's true!
                patrol:
                    Tell me the full story then.
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                patrol:
                    Alright, I heard enough.
                    That's more evidence than the higher-ups care about.
                debater:
                    !left
                    !scared
                patrol:
                    !angry
                    {debater}, you are arrested for disrupting public order.
                    !fight
                    You are coming with me!
                debater:
                    {player.HeShe}'s lying!
                    {player} is just mad {player.heshe} can't win a debate!
                    Don't listen to {player.himher}!
                patrol:
                    Tell that to the judge hearing your case that totally exists.
                player:
                    !left
                debater:
                    !right
                    !angry_accuse
                    You despicable scum!
                    Can't win a legitimate debate so you decide to put me in jail?
                    !spit
                    That is low, even for you.
                player:
                    !humoring
                    Save your breath, {debater}.
                    After all, everything you say can and will be used against you in the trial that you are totally going to get.
                debater:
                    !exit
                * {patrol} takes {debater} away.
                * The rest of the crowd quickly leave, not wanting to get caught up with this mess.
                * Well, it's a win in your book.
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                patrol:
                    It seems to me that you can't win a debate against {debater}.
                    Now that's not an arrestable offense, is it?
                player:
                    But...
                patrol:
                    Next time, tell me when people make <i>actual</> troubles, and not when your feelings are hurt.
                    !exit
                * {patrol} leaves.
                debater:
                    !right
                    !angry_accuse
                    You despicable scum!
                    Can't win a legitimate debate so you decide to try and arrest me?
                    !spit
                    That is low, even for you.
                    I think everyone here agrees that you are just a coward, hiding in your shell the moment you face any trouble.
                * With that utter humiliation, there is nothing left for you to do but leave.
                * This failure will be remembered by the public for a long time.
            ]],
        }
        :Fn(function(cxt)
            local patrol = AgentUtil.GetFreeAgent("ADMIRALTY_PATROL_LEADER")
            cxt:ReassignCastMember("patrol", patrol)

            cxt:Dialog("DIALOG_ARREST")

            cxt:Opt("OPT_CONVINCE")
                :Dialog("DIALOG_CONVINCE")
                :UpdatePoliticalStance("SECURITY", 1)
                :DeltaSupport(-1)
                :Negotiation{
                    target_agent = cxt:GetCastMember("patrol"),
                    hinders = {"debater"},
                }
                    :OnSuccess()
                        :Dialog("DIALOG_CONVINCE_SUCCESS")
                        :Fn(function(cxt)
                            local debater = cxt:GetCastMember("debater")
                            debater:GainAspect("stripped_influence", 5)
                            debater:OpinionEvent(OPINION.SOLD_OUT_TO_ADMIRALTY)
                            debater:Retire()
                            DemocracyUtil.DeltaGameplayStats("ARRESTED_PEOPLE_TIMES", 1)
                            cxt.quest.param.debated_people = cxt.quest.param.debated_people + 1
                        end)
                        :CompleteQuest()
                        :Travel()
                    :OnFailure()
                        :Dialog("DIALOG_CONVINCE_FAILURE")
                        :ReceiveOpinion(OPINION.SOLD_OUT_TO_ADMIRALTY)
                        :FailQuest()
                        :Travel()
        end)
    :State("STATE_DENOUNCE_TARGET")
        :Loc{
            DIALOG_DENOUNCE = [[
                * If you can't win a debate, there is nothing like a little ad hominem to shift the debate in your favor.
                player:
                    !left
                    Do you guys know what kind of person {debater} is?
                    {debater.HeShe} might seems like a reasonable person, but you don't know what is behind this facade.
                debater:
                    !surprised
                    Huh?
            ]],
            OPT_CONVINCE = "Convince the crowd",
            DIALOG_CONVINCE = [[
                player:
                    Let me tell you what kind of person {debater} truly is...
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                * [p] You convinced everyone how bad of a person {debater} is.
                * Now everyone is mad at {debater.himher}.
                * Under the chaos of a riot, you leave the scene.
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                * [p] You fail to convince the crowd.
                * You lost the debate, now {debater} is mad at you.
                * With that, you leave dishonorably.
            ]],
            NEGOTIATION_REASON = "Improve the crowd's opinion to at least <b>Sympathetic</>",
        }
        :Fn(function(cxt)
            local leader
            for _, agent in cxt.location:Agents() do
                if table.arrayfind(cxt.quest.param.crowd, agent) and agent ~= cxt.quest:GetCastMember("debater") then
                    leader = agent
                    break
                end
            end
            assert(leader, "Leader not found")
            cxt:ReassignCastMember("crowd", leader)
            cxt:Dialog("DIALOG_DENOUNCE")
            local function SuccessFn(cxt)
                cxt:Dialog("DIALOG_CONVINCE_SUCCESS")
                local debater = cxt:GetCastMember("debater")
                debater:GainAspect("stripped_influence", 3)
                debater:OpinionEvent(OPINION.PUBLICLY_DENOUNCE)
                cxt.quest.param.debated_people = cxt.quest.param.debated_people + 1
                cxt.quest:Complete()
                StateGraphUtil.AddLeaveLocation(cxt)
            end
            local function FailureFn(cxt)
                cxt:Dialog("DIALOG_CONVINCE_FAILURE")
                local debater = cxt:GetCastMember("debater")
                debater:OpinionEvent(OPINION.PUBLICLY_DENOUNCE)
                cxt.quest:Fail()
                StateGraphUtil.AddLeaveLocation(cxt)
            end
            cxt:Opt("OPT_CONVINCE")
                :Dialog("DIALOG_CONVINCE")
                :Negotiation{
                    target_agent = cxt:GetCastMember("crowd"),
                    hinders = {"debater"},
                    reason_fn = function(minigame)
                        return loc.format(cxt:GetLocString("NEGOTIATION_REASON") )
                    end,
                    on_start_negotiation = function(minigame)
                        minigame:GetOpponentNegotiator():CreateModifier("CROWD_OPINION", 5)
                        -- minigame:GetOpponentNegotiator():CreateModifier("INSTIGATE_CROWD", 1)
                    end,
                    on_success = function(cxt,minigame)
                        local opinion = minigame:GetOpponentNegotiator():FindModifier("CROWD_OPINION")
                        local stage = opinion and opinion:GetStage() - 1 or 0
                        if stage >= 3 then
                            SuccessFn(cxt)
                        else
                            FailureFn(cxt)
                        end
                    end,
                    on_fail = function(cxt,minigame)
                        FailureFn(cxt)
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
            OPT_ACCEPT = "Come to the station with {agent}",
            DIALOG_ACCEPT = [[
                player:
                    Fine, I'll come.
                agent:
                    Yeah, that's right.
            ]],
        }
        :Fn(function(cxt)
            cxt.enc.scratch.opfor = CreateCombatParty("ADMIRALTY_PATROL", cxt.quest:GetRank() + 1, cxt.location, true)
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
                    cooldown = 0,
                    on_success = function(cxt)
                        cxt:Dialog("DIALOG_CONVINCE_WIN")
                        cxt.quest:Complete()
                        ConvoUtil.GiveQuestRewards(cxt)
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_CONVINCE_LOSE")

                        cxt:Opt("OPT_RESIST_ARREST")
                            :Dialog("DIALOG_RESIST_ARREST")
                            :Battle{
                                on_win = function(cxt)
                                    cxt.player:Remember("ASSAULTED_ADMIRALTY", cxt:GetAgent())
                                    cxt:Dialog("DIALOG_RESIST_ARREST_SUCCESS")
                                    cxt.quest.param.poor_performance = true
                                    cxt.quest:Complete()
                                    ConvoUtil.GiveQuestRewards(cxt)
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                end,
                                on_runaway = function(cxt, battle)
                                    cxt.player:Remember("ASSAULTED_ADMIRALTY", cxt:GetAgent())
                                    cxt:Dialog("DIALOG_RESIST_ARREST_RUNAWAY")
                                    cxt.quest.param.poor_performance = true
                                    cxt.quest:Complete()
                                    ConvoUtil.GiveQuestRewards(cxt)
                                    StateGraphUtil.DoRunAwayEffects( cxt, battle, true )
                                end,
                            }
                        cxt:Opt("OPT_ACCEPT")
                            :Dialog("DIALOG_ACCEPT")
                            :Fn(function(cxt)
                                local flags = {
                                    disrupting_peace = true,
                                }
                                DemocracyUtil.DoEnding(cxt, "arrested", flags)
                            end)
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
            cxt.quest:Activate("go_to_junction")
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
