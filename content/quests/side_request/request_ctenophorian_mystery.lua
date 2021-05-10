-- This only matters in regards to the desire to find about Hesh's classification.
local HeshBelief = MakeEnum{ "ANTI", "CAUTIOUS", "FANATIC" }
local function GetHeshBelief(agent)
    if agent:GetContentID() == "ADVISOR_MANIPULATE" then
        return HeshBelief.CAUTIOUS
    elseif agent:GetContentID() == "TEI" then
        return HeshBelief.ANTI
    end
    return agent:CalculateProperty("CHESS_ELO", function(agent)
        local omni_hesh_chance = agent:GetRenown() * .15
        if agent:GetFactionID() ~= "CULT_OF_HESH" then
            if agent:GetFactionID() == "ADMIRALTY" then
                omni_hesh_chance = omni_hesh_chance - .15
            elseif agent:GetFactionID() == "FEUD_CITIZEN" then
                omni_hesh_chance = omni_hesh_chance - .25
            elseif agent:GetFactionID() == "SPARK_BARONS" then
                omni_hesh_chance = omni_hesh_chance - .5
            else
                omni_hesh_chance = omni_hesh_chance - .35
            end
        end
        if math.random() < omni_hesh_chance then
            return HeshBelief.ANTI
        end
        if math.random() < 0.35 then
            return HeshBelief.FANATIC
        end
        return HeshBelief.CAUTIOUS
    end) 
end

local QDEF = QuestDef.Define
{
    title = "Ctenophorian Mystery",
    desc = "{giver} is curious about Hesh's true form. {giver.HeShe} wants you to find out what Hesh really is.",
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

    on_start = function(quest)
        quest:Activate("ask_info")
        -- quest.param.people_advertised = 0
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
}
:AddCast{
    cast_id = "giver",
    no_validation = true,
    provider = true,
    unimportant = true,
    condition = function(agent, quest)
        return agent:GetFactionID() == "CULT_OF_HESH"
    end,
}
:AddObjective{
    id = "ask_info",
    title = "Ask about Hesh among the Heshians",
    desc = "Maybe other Heshians knows more about Hesh's true form.",
}
:AddOpinionEvents{
    suspicious = 
    {
        delta = OPINION_DELTAS.DIMINISH,
        txt = "Is suspicious of you",
    },
}

QDEF:AddIntro(
    --attract spiel
    [[
        agent:
            [p] Let's say, that hypothetically, that I want to know whether Hesh is ctenophore or cnidarian.
            And let's say, that hypothetically, I would ask you to help me out.
            Would you agree?
    ]],
    
    --on accept
    [[
        player:
            [p] I have no idea what you just said, but it sounds fun.
        agent:
            Just make sure that the Cult doesn't hear of this.
            They don't enjoy FACTS and LOGIC like I do.
    ]])

QDEF:AddConvo("ask_info")
    :Loc{
        OPT_ASK_HESH = "Ask about Hesh",
    }
    :Hub(function(cxt)
        cxt.quest.param.people_asked = cxt.quest.param.people_asked or {}
        if cxt:GetAgent() and not table.arraycontains(cxt.quest.param.people_asked, cxt:GetAgent())
            and cxt:GetAgent():GetFactionID() == "CULT_OF_HESH" then

            cxt:Opt("OPT_ASK_HESH")
                :Fn(function(cxt)
                    table.insert(cxt.quest.param.people_asked, cxt:GetAgent())
                    local belief = GetHeshBelief(cxt:GetAgent())
                    if belief = HeshBelief.FANATIC then
                        cxt:GoTo("STATE_FANATIC")
                    elseif belief == HeshBelief.ANTI then
                        cxt:GoTo("STATE_ANTI")
                    else
                        cxt:GoTo("STATE_CAUTIOUS")
                    end
                end)
        end
    end)
    :State("STATE_CAUTIOUS")
        :Loc{
            DIALOG_TALK = [[
                player:
                    [p] So about Hesh...
                agent:
                    Careful. You don't know who's listening.
            ]],
            OPT_DROP = "Drop the topic",
            DIALOG_DROP = [[
                player:
                    [p] You are right, I don't.
                agent:
                    Smart choice.
            ]],
            OPT_PROBE = "Probe info",
            DIALOG_PROBE = [[
                player:
                    [p] You think I came here just to choose the back down option?
                agent:
                    Uhh...
            ]],
            DIALOG_PROBE_SUCCESS = [[
                agent:
                    [p] You win.
            ]],
            DIALOG_PROBE_FAILURE = [[
                agent:
                    [p] Yeah I'm not telling you anything.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_TALK")
            cxt:BasicNegotiation("Probe")
                :OnSuccess()
                :GoTo("STATE_SUCCESS")
            cxt:Opt("OPT_DROP")
                :Dialog("DIALOG_DROP")
        end)
    :State("STATE_FANATIC")
        :Loc{
            DIALOG_TALK = [[
                player:
                    [p] So about Hesh...
                agent:
                    I'm glad you're interested.
                    I have a lot to talk about.
                player:
                    Oh no.
            ]],
            OPT_ENDURE = "Endure {agent}'s lecture",
            DIALOG_ENDURE = "",
            DIALOG_ENDURE_SUCCESS = [[
                * It's finally over.
                agent:
                    In conclusion...
            ]],
            DIALOG_ENDURE_FAILURE = [[
                * [p] You passed out before {agent} could finish.
            ]],
            DIALOG_ENDURE_FAILURE_2 = [[
                * ...
                * You woke up when {agent} shakes you violently.
            ]],
            DIALOG_ENDURE_FAILURE_3 = [[
                agent:
                    [p] Come on!
                    Did you hear what I said?
                player:
                    No, I just became more confused.
                agent:
                    Typical.
                    !exit
                * {agent} left, leaving you with 2 less brain cells.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_TALK")
            cxt:BasicNegotiation("ENDURE", {})
                :OnSuccess()
                    :GoTo("STATE_SUCCESS")
                :OnFailure()
                    :FadeOut()
                    :Dialog("DIALOG_ENDURE_FAILURE_2")
                    :FadeIn()
                    :Dialog("DIALOG_ENDURE_FAILURE_3")
                    :Fn(function(cxt)
                        cxt.caravan:DeltaMaxResolve(-2)
                    end)
                    :DoneConvo()
        end)
    :State("STATE_ANTI")
        :Loc{
            DIALOG_TALK = [[
                player:
                    [p] So about Hesh...
                agent:
                {liked?
                    I'm telling you this as a friend, but you really shouldn't be asking this kind of questions around.
                    People in the Cult don't like that.
                }
                {not liked?
                    I am suspicious of you!
                }
            ]],
            OPT_THANK = "Thank {agent} for the heads up",
            DIALOG_THANK = [[
                player:
                    [p] I'm not aware.
                    Thanks.
                agent:
                    You'll welcome.
                    Just promise me you won't ask around this kind of question again.
            ]],
            OPT_BRUSH = "Brush off {agent}'s concern",
            DIALOG_BRUSH = [[
                player:
                    [p] This never works.
                agent:
                    Indeed.
            ]],
            OPT_EXCUSE = "Excuse",
            DIALOG_EXCUSE = [[
                player:
                    [p] Pardon my wudeness.
            ]],
            DIALOG_EXCUSE_SUCCESS = [[
                agent:
                    [p] I get your point.
                    Just promise me you won't ask around this kind of question again.
            ]],
            DIALOG_EXCUSE_FAILURE = [[
                agent:
                    [p] I am sus of you!
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_TALK")
            if cxt:GetAgent():GetRelationship() > RELATIONSHIP.NEUTRAL then
                cxt:Opt("OPT_THANK")
                    :Dialog("DIALOG_THANK")
            else
                cxt:BasicNegotiation("EXCUSE", {})
                    :OnFailure()
                    :ReceiveOpinion("suspicious")
            end
        end)
    :State("STATE_SUCCESS")
        :Loc{
            DIALOG_ANSWER = [[
            agent:
                {1:
                    Hesh is a ctenophore.
                    |
                    Hesh is a cnidarian.
                    |
                    Hesh is not something that us mortals can comprehend.
                }
            player:
                Yeah that definitely make sense and not at all confusing.
            ]],
        }
        :Fn(function(cxt)
            cxt.enc.scratch.hesh_identity = cxt.enc.scratch.hesh_identity or 1
            cxt:Dialog("DIALOG_ANSWER", cxt.enc.scratch.hesh_identity)
            cxt.quest.param.hesh_id = cxt.quest.param.hesh_id or {}
            cxt.quest.param.hesh_id[cxt.enc.scratch.hesh_identity] = cxt.quest.param.hesh_id[cxt.enc.scratch.hesh_identity] + 1
            
            if not cxt.quest.param.spawned_interrupt then
                local candidates = {}
                for i, agent in cxt.location:Agents() do
                    if not agent:IsInPlayerParty() and agent:IsSentient() and agent:GetFactionID() == "CULT_OF_HESH"
                        and GetHeshBelief(agent) == HeshBelief.ANTI then

                        table.insert(candidate, agent)
                    end
                end
                if #candidate > 0 then
                    -- oops, someone who doesn't like your stuff overheard your little heresy.
                    -- a quest will spawn that is baad.
                    cxt.quest.param.spawned_interrupt = true
                    QuestUtil.SpawnQuest("SMITH_STORY_GET_RACING_SNAIL_LATER", {
                        parameters =
                        {
                            overheard = candidates,
                            cultist = cxt:GetAgent(),
                        },
                    })
                end
            end
            StateGraphUtil.AddEndOption(cxt)
        end)

local BAD_EVENT = QuestDef.Define{
    id = "REQUEST_CTENOPHORIAN_MYSTERY_EVENT",
    qtype = QTYPE.STORY,
}
:AddObjective{
    id = "start",
    status = QSTATUS.ACTIVE,
}

BAD_EVENT:AddConvo()
    :TravelConfront("INTERRUPT", function(cxt) return TheGame:GetGameState():CanSpawnTravelEvent() end)
        :Loc{
            DIALOG_INTRO = [[
                * [p] You are interrupted by {agent}.
                agent:
                {liked?
                    I can't believe it.
                    You out of all people are having heretic thoughts.
                }
                {not liked?
                    I heard someone is asking questions that they shouldn't ask.
                }
                player:
                    What do you mean?
                agent:
                {leader_important?
                    {leader} overheard your little talk with {cultist}.
                }
                {not leader_important?
                    I heard your talk with {cultist}.
                }
                    What do you have to say to that?
            ]],
            OPT_GASLIGHT = "Gaslight {agent}",
            DIALOG_GASLIGHT = [[
                player:
                {not leader_important?
                    [p] Pretty sure that wasn't me.
                agent:
                    Oh yeah? Then who did I saw, then?
                }
                {leader_important?
                    [p] Pretty sure {leader} was mistaken.
                agent:
                    Are you seriously doubting {leader}'s cognitive abilities?
                }
            ]],
            DIALOG_GASLIGHT_SUCCESS = [[
                agent:
                    [p] Well, if you insist that is wasn't you, then it probably wasn't.
                    Sorry for the trouble.
                * I can't believe that worked.
            ]],
            DIALOG_GASLIGHT_FAILURE = [[
                agent:
                    [p] Yeah right, who else wears the distinct outfit that you are currently wearing?
                player:
                    Good point.
                    Crap.
                * Uh oh.
            ]],

            OPT_USE_GUARD = "Send your guard to distract",
            DIALOG_USE_GUARD = [[
                player:
                    [p] Go, {guard}!
                * {guard} deals with the Heshians while you tactically retreat.
            ]],

            DIALOG_DEFEND = [[
                player:
                    [p] Easier just to fight.
            ]],
            DIALOG_DEFEND_WIN = [[
                * [p] You win. Now what.
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest.param.overheard = cxt.quest.param.overheard or {}
                local leader
                if #cxt.quest.param.overheard > 0 then
                    leader = table.arraypick(cxt.quest.param.overheard)
                    
                    if AgentUtil.HasPlotArmour(leader) then
                        cxt.enc.scratch.leader_important = true
                    end
                    cxt:ReassignCastMember("leader", leader)
                end
                local opfor
                if leader and not cxt.enc.scratch.leader_important then
                    leader:MoveToLocation(cxt.location)
                    opfor = CreateCombatBackup(leader, "HESH_PATROL", cxt.quest:GetRank())
                else
                    opfor = CreateCombatParty("HESH_PATROL", cxt.quest:GetRank(), cxt.location, true)
                end
                cxt:TalkTo(opfor[1])
                cxt:Dialog("DIALOG_INTRO")
            end
            cxt:BasicNegotiation("GASLIGHT")
                :OnSuccess()
                    :CompleteQuest()
                    :Travel()
        end)