-- This only matters in regards to the desire to find about Hesh's classification.
local HeshBelief = MakeEnum{ "ANTI", "CAUTIOUS", "FANATIC" }
local function GetHeshBelief(agent)
    if agent:GetContentID() == "ADVISOR_MANIPULATE" then
        return HeshBelief.CAUTIOUS
    elseif agent:GetContentID() == "TEI" then
        return HeshBelief.ANTI
    end
    return agent:CalculateProperty("HESH_BELIEF", function(agent)
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
    events = {
        on_say_quip = function(quest, cxt, agent, param)
            if table.arraycontains(param.tags, "go_to_sleep") and not param.override_quip then
                local opinion_count = 0
                local asked_people = 0
                for id, val in pairs(quest.param.hesh_id or {}) do
                    opinion_count = opinion_count + 1
                    asked_people = asked_people + val
                end
                if opinion_count >= 2 and asked_people >= 3 then
                    param.override_quip = true
                    cxt:PlayQuestConvo(quest, "HOOK_SLEEP")
                end
            end
        end,
    },
}
:AddObjective{
    id = "tell_result",
    title = "Tell your findings to {giver}",
    desc = "Your dream has given you quite the knowledge about Hesh. {giver} would be quite pleased with this information.",
    mark = {"giver"},
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
            Hypothetically, Hesh could be a ctenophore.
            !think
            But hypothetically, Hesh could also be a cnidarian.
        player:
            What does that have to do with helping you?
        agent:
            Well, this is a paradoxical question.
            It doesn't fit cleanly into my FACTS and LOGIC.
            That's where you come in, as of now.
            Go out, and try to weasel out a straight answer.
    ]],
    
    --on accept
    [[
        player:
            Well, now you've got me a bit curious. Sure, why not?
        agent:
            Well, that "why not" might be your reputation with the cult.
            But just keep an eye out for any eavesdroppers. You never know they're listening until it's too late.
    ]])

QDEF:AddConvo("ask_info")
    :Loc{
        OPT_ASK_HESH = "Ask about Hesh",
    }
    :Hub(function(cxt)
        cxt.quest.param.people_asked = cxt.quest.param.people_asked or {}
        if cxt:GetAgent() and cxt:GetAgent() ~= cxt:GetCastMember("giver") and
            not table.arraycontains(cxt.quest.param.people_asked, cxt:GetAgent())
            and cxt:GetAgent():GetFactionID() == "CULT_OF_HESH" then

            cxt:Opt("OPT_ASK_HESH")
                :Fn(function(cxt)
                    table.insert(cxt.quest.param.people_asked, cxt:GetAgent())
                    local belief = GetHeshBelief(cxt:GetAgent())
                    if belief == HeshBelief.FANATIC then
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
                * The mentioning of Hesh makes {agent} perk up in alert.
                agent:
                    Quiet! That's a sensitive topic and you know it.
            ]],
            OPT_DROP = "Drop the topic",
            DIALOG_DROP = [[
                player:
                    Oh, pardon.
                agent:
                    It's...fine. Hesh forgives the cautious, but will also punish the curious.
                    Do you understand that?
                player:
                    Well enough, {agent}.
            ]],
            OPT_PROBE = "Probe info",
            DIALOG_PROBE = [[
                player:
                    But why is it a sensitive topic? Surely a question like this should be common lore.
                agent:
                    Uhh...
            ]],
            DIALOG_PROBE_SUCCESS = [[
                player:
                    Look, just say your piece quietly, if you think that someone's going to hear you.
                    One straight answer, and i'll drop the subject.
                agent:
                    Fine, if you insist.
            ]],
            DIALOG_PROBE_FAILURE = [[
                agent:
                    It's a sensitive topic because we can't possibly know!
                player:
                    Really? No hashing out the details?
                agent:
                    No! It's a leviathan sized creature that eats us all in the end!
                    Can't exactly break out the yardstick on a creature we can't comprehend.
                player:
                    Alright, alright.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_TALK")
            cxt:BasicNegotiation("PROBE")
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
                    You're one of the politicians, right?
                player:
                    That would be correct, were I talking to you as a politician.
                    But I talk to you as a scholar, instead.
                agent:
                    This is so great! I have so many notes on Hesh from all the snippets of lore i've found.
                    Say...how much time do you have to burn?
            ]],
            OPT_ENDURE = "Endure {agent}'s lecture",
            DIALOG_ENDURE = [[
                player:
                    !sigh
                    As much as you need.
                agent:
                    So it all starts with the symmetry...
            ]],
            DIALOG_ENDURE_SUCCESS = [[
                agent:
                    But, I say, what of the lumin that Hesh supposedly shed in it's birthing?
                    Well, the soulution was obvious once I looked at it like that.
                    In conclusion...
            ]],
            DIALOG_ENDURE_FAILURE = [[
                * As {agent} drones on, {agent.hisher} words start to glaze over.
                * Syllables blur together, becoming a potent white noise, and you barely hear {agent.hisher} notes on tentacle lengths before slumping over, asleep.
            ]],
            DIALOG_ENDURE_FAILURE_2 = [[
                * Your hazy slumber is plagued with the occasional vision of creatures from the abyss
                * Before whatever part of you still congnizant could process it, you slowly wake up to more droning.
            ]],
            DIALOG_ENDURE_FAILURE_3 = [[
                agent:
                  So in conclusion, Hesh is a-
                player:
                  !drunk
                  Hey, wait a minute...Hesh is a wha...?
                agent:
                  !question
                  Did you fall asleep?
                player:
                  Hrm? Yeah...I'm uh, sorry.
                agent:
                  !angry
                  How could you fall asleep? This is the classification of Hesh we're talking about!
                player:
                  Maybe you could make the lecture a bit more entertaining, professor.
                agent:
                  Unbelievable. Unbelievable!
                  !exit
                * {agent} storms off in a huff, leaving you with a few new questions that you slept through the answers to.
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
                    Hesh is not ctenophorian, nor is it cnidarian.
                    Hesh is a multi-faceted being, and to classify it is to waste what precious time we have before being consumed.
                }
            player:
                Yeah that definitely make sense and not at all confusing.
            ]],
        }
        :Fn(function(cxt)
            cxt.enc.scratch.hesh_identity = cxt.enc.scratch.hesh_identity or math.random(1, 3)
            cxt:Dialog("DIALOG_ANSWER", cxt.enc.scratch.hesh_identity)
            cxt.quest.param.hesh_id = cxt.quest.param.hesh_id or {}
            cxt.quest.param.hesh_id[cxt.enc.scratch.hesh_identity] = (cxt.quest.param.hesh_id[cxt.enc.scratch.hesh_identity] or 0) + 1
            
            if not cxt.quest.param.spawned_interrupt then
                local candidates = {}
                for i, agent in cxt.location:Agents() do
                    if not agent:IsInPlayerParty() and agent:IsSentient() and agent:GetFactionID() == "CULT_OF_HESH"
                        and GetHeshBelief(agent) == HeshBelief.ANTI then

                        table.insert(candidates, agent)
                    end
                end
                if #candidates > 0 then
                    -- oops, someone who doesn't like your stuff overheard your little heresy.
                    -- a quest will spawn that is baad.
                    cxt.quest.param.spawned_interrupt = true
                    QuestUtil.SpawnQuest("REQUEST_CTENOPHORIAN_MYSTERY_EVENT", {
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
QDEF:AddConvo("ask_info", nil, "HOOK_SLEEP")
    :State("START")
        :Loc{
            DIALOG_INTRO = [[
                * [p] With all the ridiculous thoughts in your head, you fall into sleep.
                * Plot twist, you dreamt of Hesh itself.
                * Themself? What does Hesh identify themself with?
                * That is precisely the question you are asking.
                * And now, maybe a special negotiation or something.
            ]],
            OPT_UNDERSTAND = "Try to understand Hesh",
            DIALOG_UNDERSTAND = [[
                player:
                    !left
                    [p] I'm gonna convince you now!
            ]],
            DIALOG_UNDERSTAND_SUCCESS = [[
                player:
                    [p] That makes so much sense now!
            ]],
            DIALOG_UNDERSTAND_FAILURE = [[
                player:
                    [p] My brain hurts.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt:TalkTo(TheGame:GetGameState():AddSkinnedAgent("GROUT_MONSTER"))

            cxt:BasicNegotiation("UNDERSTAND")
                :OnSuccess()
                    :CompleteQuest("ask_info")
                    :ActivateQuest("tell_result")
                :OnFailure()
                    :Fn(function(cxt)
                        -- You earn a special card or something.
                        cxt.quest.param.went_crazy = true
                    end)
                    :CompleteQuest("ask_info")
                    :ActivateQuest("tell_result")
        end)
QDEF:AddConvo("tell_result", "giver")
    :AttractState("STATE_ATTRACT")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    [p] So you figured out Hesh's true form?
                player:
                {not went_crazy?
                    Facts, logic, it's all an illusion.
                    The truth is in the eye of the beholder.
                agent:
                    This is very significant and may affect the ending in some way.
                }
                {went_crazy?
                    I saw too much, and I talk crazy.
                agent:
                    Oh no, now I feel bad for you.
                }
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest.Complete()
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
                {leader_absent?
                    {leader} overheard your little talk with {cultist}.
                }
                {not leader_absent?
                    I heard your talk with {cultist}.
                }
                    What do you have to say to that?
            ]],
            OPT_GASLIGHT = "Gaslight {agent}",
            DIALOG_GASLIGHT = [[
                player:
                {not leader_absent?
                    [p] Pretty sure that wasn't me.
                agent:
                    Oh yeah? Then who did I saw, then?
                }
                {leader_absent?
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

            OPT_USE_BODYGUARD = "Send your guard to distract",
            DIALOG_USE_BODYGUARD = [[
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
                    
                    if AgentUtil.HasPlotArmour(leader) or not AgentUtil.CanAct(leader) then
                        cxt.enc.scratch.leader_absent = true
                    end
                    cxt:ReassignCastMember("leader", leader)
                end
                
                if leader and not cxt.enc.scratch.leader_absent then
                    leader:MoveToLocation(cxt.location)
                    cxt.enc.scratch.opfor = CreateCombatBackup(leader, "HESH_PATROL", cxt.quest:GetRank())
                else
                    cxt.enc.scratch.opfor = CreateCombatParty("HESH_PATROL", cxt.quest:GetRank(), cxt.location, true)
                end
                cxt:TalkTo(cxt.enc.scratch.opfor[1])
                cxt:Dialog("DIALOG_INTRO")
            end
            cxt:BasicNegotiation("GASLIGHT")
                :OnSuccess()
                    :CompleteQuest()
                    :Travel()

            DemocracyUtil.AddBodyguardOpt(cxt, function(cxt, agent)
                cxt:ReassignCastMember("guard", agent)
                cxt:Dialog("DIALOG_USE_BODYGUARD")
                if agent:IsPet() then
                    QuestUtil.SpawnQuest("STORY_PET_RETURN", { cast = { pet = agent } })
                end
                agent:Dismiss()
                cxt.quest:Complete()
                StateGraphUtil.AddLeaveLocation(cxt)
            end)

            cxt:Opt("OPT_DEFEND")
                :Dialog("DIALOG_DEFEND")
                :Battle{
                    enemies = cxt.enc.scratch.opfor,
                }
                    :OnWin()
                        :Dialog("DIALOG_DEFEND_WIN")
                        :CompleteQuest()
                        :DoneConvo()
        end)
