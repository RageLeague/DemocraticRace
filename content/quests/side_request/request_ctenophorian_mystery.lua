-- This only matters in regards to the desire to find about Hesh's classification.
local HeshBelief = MakeEnum{ "ANTI", "CAUTIOUS", "FANATIC", "NOT_KNOW" }

local HESH_CLASSIFICATION = {"ctenophore", "cnidarian", "unclassifiable"}

local QDEF = QuestDef.Define
{
    title = "Ctenophorian Mystery",
    desc = "{giver} is curious about Hesh's true form. {giver.HeShe} wants you to find out what Hesh really is.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/ctenophorian_mystery.png"),

    qtype = QTYPE.SIDE,

    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"REQUEST_JOB"},
    reward_mod = 0,
    can_flush = false,
    cooldown = EVENT_COOLDOWN.LONG,

    events = {
        base_difficulty_change = function(quest, new_diff, old_diff)
            quest:SetRank(new_diff)
        end,

    },

    postcondition = function(quest)
        quest.extra_reward = EXTRA_QUEST_REWARD.FREE_ITEM
        quest.extra_reward_data = "quest_any_card_bonus"
        return true
    end,

    on_start = function(quest)
        quest:Activate("ask_info")
    end,

    on_complete = function(quest)
        if not (quest.param.sub_optimal or quest.param.poor_performance) then
            quest:GetProvider():OpinionEvent(OPINION.DID_LOYALTY_QUEST)
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 10, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, 4, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 5, "CULT_OF_HESH", "COMPLETED_QUEST_REQUEST")
        elseif quest.param.sub_optimal then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 5, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 4, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 3, "CULT_OF_HESH", "COMPLETED_QUEST_REQUEST")
        elseif quest.param.poor_performance then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2, "POOR_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 4, "POOR_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 2, "CULT_OF_HESH", "POOR_QUEST")
        end
    end,

    HeshBelief = HeshBelief,

    CanTalkAboutHesh = function(quest, agent)
        if agent == quest:GetCastMember("giver") then
            return false -- The giver of the quest can't talk about Hesh.
        end
        if agent:GetContentID() == "ADVISOR_MANIPULATE" then
            return false -- Benni can't talk about Hesh.
        end
        if table.arraycontains(quest.param.people_asked or {}, agent) then
            return false -- Already asked
        end
        -- return agent:GetFactionID() == "CULT_OF_HESH" or agent:GetFactionID() == "FEUD_CITIZEN"
        return true
    end,

    FIXED_BELIEF = {
        ADVISOR_MANIPULATE = HeshBelief.NOT_KNOW,
        TEI = HeshBelief.ANTI,
        VIXMALLI = HeshBelief.ANTI,
    },

    GetHeshBelief = function (quest, agent)
        if quest:GetQuestDef().FIXED_BELIEF[agent:GetAlias()] then
            return quest:GetQuestDef().FIXED_BELIEF[agent:GetAlias()]
        end
        return agent:CalculateProperty("HESH_BELIEF", function(agent)
            local omni_hesh_chance = agent:GetRenown() / 8
            local hesh_knowledge = agent:GetRenown() / 8
            if agent:GetFactionID() ~= "CULT_OF_HESH" then
                if agent:GetFactionID() == "ADMIRALTY" then
                    omni_hesh_chance = omni_hesh_chance - .25
                    hesh_knowledge = hesh_knowledge + 0.5
                elseif agent:GetFactionID() == "FEUD_CITIZEN" then
                    omni_hesh_chance = 0
                elseif agent:GetFactionID() == "SPARK_BARONS" then
                    omni_hesh_chance = 0
                    hesh_knowledge = hesh_knowledge + 0.25
                elseif agent:GetFactionID() == "BILEBROKERS" then
                    omni_hesh_chance = 0
                    hesh_knowledge = hesh_knowledge + 0.5
                else
                    omni_hesh_chance = 0
                end
            end
            if math.random() >= hesh_knowledge then
                return HeshBelief.NOT_KNOW
            end
            if math.random() < omni_hesh_chance then
                return HeshBelief.ANTI
            end
            if math.random() < 0.35 then
                return HeshBelief.FANATIC
            end
            return HeshBelief.CAUTIOUS
        end)
    end,

    IncreaseHeshKnowledge = function(quest, belief)
        quest.param.hesh_id = quest.param.hesh_id or {}
        quest.param.hesh_id[belief] = (quest.param.hesh_id[belief] or 0) + 1
        quest.param["hesh_" .. HESH_CLASSIFICATION[belief]] = true
        if not quest:IsActive("is_hesh_" .. HESH_CLASSIFICATION[belief]) then
            quest:Activate("is_hesh_" .. HESH_CLASSIFICATION[belief])
        end
    end,
}
:AddCast{
    cast_id = "giver",
    no_validation = true,
    provider = true,
    unimportant = true,
    condition = function(agent, quest)
        if agent:GetContentID() == "ADVISOR_MANIPULATE" then
            return true
        end
        local advisor = DemocracyUtil.GetMainQuestCast("primary_advisor")
        if advisor and advisor:GetContentID() == "ADVISOR_MANIPULATE" then
            return false
        end
        return not agent:HasTag("curated_request_quest") and (agent:GetFactionID() == "CULT_OF_HESH" or agent:GetFactionID() == "FEUD_CITIZEN") and quest:DefFn("GetHeshBelief", agent) == HeshBelief.NOT_KNOW
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
                if opinion_count >= 2 then
                    param.override_quip = true
                    cxt:PlayQuestConvo(quest, "HOOK_SLEEP")
                end
            end
        end,
    },
    mark = function(quest, t, in_location)
        if in_location and DemocracyUtil.IsFreeTimeActive() then
            for _, agent in TheGame:GetGameState():GetPlayerAgent():GetLocation():Agents() do
                if quest:DefFn("CanTalkAboutHesh", agent) then
                    table.insert(t, agent)
                end
            end
        end
    end,
}
:AddObjective{
    id = "is_hesh_ctenophore",
    title = "Is Hesh a ctenophore?",
    desc = "According to some, Hesh has some \"hair-thingys\" that helps it swim, making it a ctenophore. Is it really the case? The only way to tell is to see for yourself.",
}
:AddObjective{
    id = "is_hesh_cnidarian",
    title = "Is Hesh a cnidarian?",
    desc = "According to some, Hesh has some splinters that helps it catch prey, making it a cnidarian. You don't know for sure if it's actually the case until you see for yourself.",
}
:AddObjective{
    id = "is_hesh_unclassifiable",
    title = "Is Hesh unclassifiable?",
    desc = "According to some, you can't classify Hesh using conventional biology. How is it possible? You have to see for yourself.",
}
:AddObjective{
    id = "tell_result",
    title = "Tell your findings to {giver}",
    desc = "Your dream has given you quite the knowledge about Hesh. {giver} would be quite pleased with this information.",
    mark = {"giver"},
    on_activate = function(quest)
        if quest:IsActive("is_hesh_ctenophore") then
            quest:Cancel("is_hesh_ctenophore")
        end
        if quest:IsActive("is_hesh_cnidarian") then
            quest:Cancel("is_hesh_cnidarian")
        end
        if quest:IsActive("is_hesh_unclassifiable") then
            quest:Cancel("is_hesh_unclassifiable")
        end
    end,
}
:AddObjective{
    id = "bad_event",
}
:AddObjective{
    id = "rat_out_aftermath",
    on_activate = function(quest)
        quest.time_left = math.random(3, 10)
    end,
    events =
    {
        action_clock_advance = function(quest, location)
            quest.time_left = (quest.time_left or 0) - 1
        end,
    },
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
        {advisor_manipulate?
            agent:
                I've been thinking about something for a while now.
            player:
                !interest
                Oh yeah? What is it?
            agent:
                Hesh is truly a great leviathan feared by all.
                !thought
                Yet, we know very little about Hesh.
                Its living environment, its form, or even what kind of jellyfish it is.
                Which, logically leads me to wonder, do we truly fear Hesh for what it is, or do we simply fear the unknown?
            player:
                !dubious
                Uhh... What are you getting at?
            agent:
                You should try study the facts about Hesh. Understand it.
                And tell me your findings when you know something.
        }
        {not advisor_manipulate?
            agent:
                We all worship Hesh.
            {player_sal or player_arint?
            player:
                !crossed
                What do you mean, "we"?
            agent:
                Okay, <i>some</> of us worship Hesh.
            }
                !thought
                But in the end, do we truly understand Hesh?
            player:
                !dubious
                Uhh... What are you getting at?
            agent:
                For instance, what is Hesh?
                What does it look like? What is its living environment? We don't know.
                We don't even know what kind of jellyfish it is.
                !point
                That's where you come in.
                You should try to study Hesh and tell me your findings.
        }
    ]],

    --on accept
    [[
        player:
            !interest
            You got me interested.
            Just one question: where do I start?
        {advisor_manipulate?
            agent:
                Logically speaking, there are so many worshippers of Hesh, there is bound to be someone who knows at least <i>something</>.
                Therefore, you should start by asking around.
        }
        {not advisor_manipulate?
            agent:
                Perhaps you should start asking around.
                With that many Heshians, someone must know at least <i>something</>.
        }
        player:
            And how do I find such "someone"?
        agent:
            !point
            That's for you to find out.
            I would venture that someone from the Cult, especially priests or other important figures, would likely know something about it.
            If you are desperate, you can ask people outside of the Cult, though the likelihood of them knowing anything is very small.
    ]])

QDEF:AddConvo("ask_info")
    :Loc{
        OPT_ASK_HESH = "Ask about Hesh",
    }
    :Quips{
        {
            tags = "asked_hesh_fail",
            [[
                player:
                    Say, you wouldn't happen to know what kind of jellyfish Hesh is?
                agent:
                    !dubious
                    What kind of person just "happens" to know that?
                    Well, even if they do exist, I am not one of these people.
                player:
                    Well, thanks anyway.
                agent:
                    !shrug
                    Maybe you will find better luck asking this question to actual Heshians.
            ]],
            [[
                player:
                    Do you know what kind of jellyfish Hesh is?
                agent:
                    !dubious
                    What do you mean "what kind"? There are different kinds of jellyfish?
                player:
                    !shrug
                    Apparently so. I don't know too much about jellyfish myself, you see.
                    Well, thanks anyway.
                agent:
                    You should ask people who would actually know about jellyfish.
                    Like actual Heshians. Or biologists.
            ]],
            [[
                player:
                    Do you know anything about Hesh and its behaviour?
                agent:
                    !shrug
                    Well, it exists. Probably.
                    It swims in the ocean. Again, probably.
                    {agent_against_hesh?
                        It wraps its slimy tentacles around the people's brains. Most definitely.
                    }
                {not (agent_against_hesh and pro_religious_policy)?
                    player:
                        Great. Nothing I don't already know.
                    agent:
                        !shrug
                        Perhaps you should ask a person who actually know about these stuff next time.
                }
                {agent_against_hesh and pro_religious_policy?
                    player:
                        I am going to ignore that last statement of yours.
                        Actually, make that <i>all</> statements of yours, since you didn't tell me anything I don't already know.
                    agent:
                        !shrug
                        Perhaps next time you should ask someone who <i>actually</> care about that jellyfish than me.
                }
            ]],
        },
        {
            tags = "asked_hesh_fail, disliked",
            [[
                player:
                    Do you know what kind of jellyfish Hesh is?
                agent:
                    !crossed
                    Ha! I'm not telling you that.
                player:
                    !dubious
                    Because you don't like me, or because you don't know about it yourself?
                agent:
                    ...
                    !crossed
                    Like I said, I'm not telling you that.
            ]],
        },
        {
            tags = "asked_hesh_fail, cult_of_hesh",
            [[
                player:
                    Do you know what kind of jellyfish Hesh is?
                agent:
                    !sigh
                    It pains me to admit it, but I don't know.
                    The Cult is very elusive about any details of Hesh.
                player:
                    I... see.
            ]],
        },
    }
    :Hub(function(cxt)
        if cxt:GetAgent() and cxt.quest:DefFn("CanTalkAboutHesh", cxt:GetAgent()) and DemocracyUtil.IsFreeTimeActive() then
            cxt:Opt("OPT_ASK_HESH")
                :SetQuestMark()
                :Fn(function(cxt)
                    local belief = cxt.quest:DefFn("GetHeshBelief", cxt:GetAgent())
                    if belief == HeshBelief.FANATIC then
                        cxt:GoTo("STATE_FANATIC")
                    elseif belief == HeshBelief.ANTI then
                        cxt:GoTo("STATE_ANTI")
                    elseif belief == HeshBelief.CAUTIOUS then
                        cxt:GoTo("STATE_CAUTIOUS")
                    else
                        cxt:GoTo("STATE_NOT_KNOW")
                    end
                end)
        end
    end)
    :State("STATE_NOT_KNOW")
        :Fn(function(cxt)
            local stance_tag
            local other_stance = DemocracyUtil.GetAgentStanceIndex("RELIGIOUS_POLICY", cxt:GetAgent())
            if other_stance < 0 then
                stance_tag = "agent_against_hesh"
            elseif other_stance > 0 then
                stance_tag = "agent_support_hesh"
            end
            cxt:Quip( cxt:GetAgent(), "asked_hesh_fail", "stance_tag")
            cxt.quest.param.people_asked = cxt.quest.param.people_asked or {}
            table.insert(cxt.quest.param.people_asked, cxt:GetAgent())
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
                    It's...fine.
                    {cult_of_hesh?
                        Hesh forgives the cautious, but will also punish the curious.
                    }
                    {not cult_of_hesh?
                        The Cult isn't forgiving to those who are too curious.
                    }
                    Do you understand that?
                player:
                    Well enough, {agent}.
            ]],
            OPT_PROBE = "Convince {agent} to tell you",
            DIALOG_PROBE = [[
                player:
                    But why is it a sensitive topic? Surely a question like this should be common lore.
                agent:
                    Uhh...
            ]],
            DIALOG_PROBE_SUCCESS = [[
                player:
                    Look, just say your piece quietly, if you think that someone's going to hear you.
                    One straight answer, and I'll drop the subject.
                agent:
                    Fine, if you insist.
            ]],
            DIALOG_PROBE_FAILURE = [[
                agent:
                    It's a sensitive topic because we can't possibly know!
                player:
                    Really? No hashing out the details?
                agent:
                    !angry_shrug
                    No! It's a leviathan sized creature that eats us all in the end!
                    Can't exactly break out the yardstick on a creature we can't comprehend.
                player:
                    !placate
                    Alright, alright.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_TALK")
            cxt:BasicNegotiation("PROBE", {
                -- Opponent will have a secret intel bounty.
            })
                :OnSuccess()
                :Fn(function(cxt)
                    cxt.quest.param.people_asked = cxt.quest.param.people_asked or {}
                    table.insert(cxt.quest.param.people_asked, cxt:GetAgent())
                end)
                :GoTo("STATE_SUCCESS")
            cxt:Opt("OPT_DROP")
                :Dialog("DIALOG_DROP")
        end)
    :State("STATE_FANATIC")
        :Loc{
            DIALOG_TALK = [[
                * The mention of Hesh makes {agent} perk up in excitement.
                agent:
                    You're one of the politicians, right?
                player:
                    That would be correct, if I wanted to talk politics.
                    But I want to talk about Hesh right now. Anything you know about Its classification?
                agent:
                    This is so great! I have so many notes on Hesh from all the snippets of lore I've found.
                    !handwring
                    Say...how much time do you have to burn?
                * This sounds like it could take a while.
            ]],
            OPT_DROP = "Drop the topic",
            DIALOG_DROP = [[
                player:
                    !placate
                    You know what? I think I'm good.
                agent:
                    !disappoint
                    Really? But there are so much to talk about!
                player:
                    Maybe another time, then.
            ]],
            OPT_ENDURE = "Endure {agent}'s lecture",
            DIALOG_ENDURE = [[
                player:
                    !sigh
                    As much as you need.
                agent:
                    !happy
                    So it all starts with the symmetry...
            ]],
            DIALOG_ENDURE_SUCCESS = [[
                {ended_prematurely?
                agent:
                    [p] Okay. What the Hesh.
                    You are even confusing me, with how much arguments you are making.
                    I will just skip straight to the point, then.
                }
                {not ended_prematurely?
                agent:
                    But, I say, what of the lumin that Hesh supposedly shed in it's birthing?
                    !eureka
                    Well, the solution was obvious once I looked at it like that.
                    In conclusion...
                }
            ]],
            DIALOG_ENDURE_FAILURE = [[
                * As {agent} drones on, {agent.hisher} words start to glaze over.
                * Syllables blur together, becoming a potent white noise, and you barely hear {agent.hisher} notes on tentacle lengths before slumping over, asleep.
            ]],
            DIALOG_ENDURE_FAILURE_2 = [[
                * Your hazy slumber is plagued with the occasional vision of creatures from the abyss.
                * Before whatever part of you still cognizant could process it, you slowly wake up to more droning.
            ]],
            DIALOG_ENDURE_FAILURE_3 = [[
                agent:
                    So in conclusion, Hesh is a-
                player:
                    !drunk
                    Hey, wait a minute...Hesh is a wha...?
                agent:
                    !dubious
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

            NEGOTIATION_REASON = "Endure {agent}'s lecture",
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_TALK")
            cxt:Opt("OPT_ENDURE")
                :Dialog("DIALOG_ENDURE")
                :Fn(function(cxt)
                    cxt.quest.param.people_asked = cxt.quest.param.people_asked or {}
                    table.insert(cxt.quest.param.people_asked, cxt:GetAgent())

                    cxt:GetAgent():SetTempNegotiationBehaviour(DemocracyUtil.BEHAVIOURS.HESHIAN_FANATIC)
                end)
                :Negotiation{
                    -- This will be a special negotiation.
                    -- Opponent has no core, meaning you can't win by damage.
                    -- You win by surviving a set amount of rounds.
                    flags = NEGOTIATION_FLAGS.NO_CORE_RESOLVE,
                    reason_fn = function(minigame) return cxt:GetLocString("NEGOTIATION_REASON") end,
                    on_start_negotiation = function(minigame)
                        minigame.player_negotiator:AddModifier("FANATIC_LECTURE", 6)
                        minigame.opponent_negotiator:CreateModifier("DISTRACTION_CONFUSION", 1)
                        minigame.opponent_negotiator:CreateModifier("CURIOSITY", 1)
                    end,
                }
                    :OnSuccess()
                        :Fn(function(cxt, minigame)
                            cxt.enc.scratch.ended_prematurely = minigame.ended_prematurely
                        end)
                        :Dialog("DIALOG_ENDURE_SUCCESS")
                        :GoTo("STATE_SUCCESS")
                    :OnFailure()
                        :Dialog("DIALOG_ENDURE_FAILURE")
                        :FadeOut()
                        :Dialog("DIALOG_ENDURE_FAILURE_2")
                        :FadeIn()
                        :Dialog("DIALOG_ENDURE_FAILURE_3")
                        :Fn(function(cxt)
                            cxt.caravan:DeltaMaxResolve(-2)
                        end)
                        :DoneConvo()
            cxt:Opt("OPT_DROP")
                :Dialog("DIALOG_DROP")
        end)
    :State("STATE_ANTI")
        :Loc{
            DIALOG_TALK = [[
                player:
                    Say, I have a question about Hesh's classification.
                agent:
                {liked?
                    !cagey
                    Keep your voice down!
                    Look, I don't know what's gotten in your head to start asking about that, but as friend I should warn you.
                    The Cult does not like people asking those questions.
                }
                {not liked?
                    !cruel
                    Well now. What's got you talking about Hesh's classification?
                    The Cult isn't going to like hearing you talking about <i>that</>.
                }
            ]],
            --They don't let it be spoken about because they don't have an answer, only questions
            OPT_THANK = "Thank {agent} for the heads up",
            DIALOG_THANK = [[
                player:
                    Wasn't aware the Cult didn't want Its lore known.
                    Thanks for the heads up, by the by.
                agent:
                    Well, that's the thing.
                    Hesh is beyond our mortal classification, and our puny minds cannot comprehend It.
                    Any attempt to study it using our mortal understanding will only lead to madness.
                    Plus, that is what a heretical spark baron would do.
                player:
                    !happy
                    Hey, that's more of an answer I was expecting from this.
                agent:
                    !cagey
                    It's an answer to get you to drop the subject. Friend to friend, I'm telling you to put a sock in it.
                player:
                    !placate
                    Alright, alright.
            ]],
            OPT_BRUSH = "Brush off {agent}'s concern",
            DIALOG_BRUSH = [[
                player:
                    [p] This never works.
                agent:
                    Indeed.
            ]],
            OPT_EXCUSE = "Excuse yourself",
            DIALOG_EXCUSE = [[
                player:
                    !placate
                    Oh, pardon me. I wasn't aware <i>that</> was taboo.
            ]],
            DIALOG_EXCUSE_SUCCESS = [[
                player:
                    !overthere
                    I was just a bit curious about <i>that</>. Bit new to cult traditions, y'know.
                agent:
                    !crossed
                    I suppose that's your excuse for not reading the Waterlogged Tomes?
                    It stated clearly in those texts that Hesh is an unidentifiable being.
                player:
                    !bashful
                    Yeah, I must've not gotten to that one yet. Though it's a real page turner, let me tell you.
                agent:
                    !angry
                    Hmph. I'll let this one slide, but swear to your eventual consumption that you'll actually study before you commit heresy again.
                player:
                    !salute
                    You've got my word.
            ]],
            DIALOG_EXCUSE_FAILURE = [[
                player:
                    I was asking this for a friend, you see...
                agent:
                    !dubious
                    ...
                player:
                    !bashful
                    My friend is actually part of the Cult, so I am asking these questions for {giver.himher}...
                agent:
                    !angry
                    This is oshnu dung!
                    A <i>real</> Cult member would know that these questions should not be asked around!
                    Who do you really work for? Maybe one of those spark baron scums?
                player:
                    Well...
                agent:
                    Just be glad there is a ceasefire, because otherwise it's going to be a <i>lot</> worse for you.
                    !angry_accuse
                    Now get out of my face.
            ]],
        }
        :Fn(function(cxt)
            cxt.quest.param.people_asked = cxt.quest.param.people_asked or {}
            table.insert(cxt.quest.param.people_asked, cxt:GetAgent())

            cxt:Dialog("DIALOG_TALK")

            cxt.enc.scratch.hesh_identity = 3
            cxt.quest.param.hesh_id = cxt.quest.param.hesh_id or {}
            if cxt:GetAgent():GetRelationship() > RELATIONSHIP.NEUTRAL then
                cxt:Opt("OPT_THANK")
                    :Dialog("DIALOG_THANK")
                    :Fn(function(cxt)
                        cxt.quest:DefFn("IncreaseHeshKnowledge", cxt.enc.scratch.hesh_identity)
                    end)
            else
                cxt:BasicNegotiation("EXCUSE", {})
                    :OnSuccess()
                        :Fn(function(cxt)
                            cxt.quest:DefFn("IncreaseHeshKnowledge", cxt.enc.scratch.hesh_identity)
                        end)
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
                    {not hesh_ctenophore?
                        player:
                            !surprised
                            It's a what-for?
                        agent:
                            $miscMocking
                            C-te-no-phore.
                            They've got little hair-thingys that they use for swimming.
                    }
                    {hesh_ctenophore?
                        player:
                            !bashful
                            Yeah, that. Remind me what that is again?
                        agent:
                            Well, ctenophores have these little hair-thingys that they use for swimming.
                    }
                player:
                    !dubious
                    Sounds... Cute?
                agent:
                    I assure you, it's anything but cute.
                    Most ctenophores are very capable predators.
                    {cult_of_hesh?
                        !hesh_greeting
                        And Hesh is the most fearful predator of them all.
                    }
                    {hesh_cnidarian?
                        player:
                            !surprised
                            Wait, I've heard that Hesh is another kind of jellyfish from some other people.
                            Cni-something or the other?
                        agent:
                            !thought
                            Ah, yes, some people do believe that Hesh is a cnidarian.
                            !handwave
                            They are, of course, wrong.
                            From the descriptions of Hesh in the Waterlogged Tomes, it is clear that Hesh is a ctenophore.
                        player:
                            I see.
                        |
                        {hesh_unclassifiable?
                            player:
                                !surprised
                                Wait, I was under the impression that they can't be classified using conventional biology?
                                Or so I've heard someone claimed.
                            agent:
                                !thought
                                Ah, yes. The official stance of the Cult.
                                But is that really the case?
                                !shrug
                                Perhaps the Cult is trying to hide their ignorance.
                                !thought
                                Or perhaps they are trying to hide the horrifying truth from the public ear.
                                In either case, the fact of the matter is, Hesh is a ctenophore.
                            player:
                                I see.
                            |
                            player:
                                I'll... Keep that in mind.
                        }
                    }
                    |
                    Hesh is a cnidarian.
                    player:
                        {not hesh_cnidarian?
                            !surprised
                            So Hesh is...a durian?
                        }
                        {hesh_cnidarian?
                            !hips
                            Ah, yes, the durian. I've heard something like that.
                        }
                agent:
                    $miscMocking
                    C-ni-da-rian.
                    They've got these little splinters on them. Used for catching prey.
                player:
                    !wince
                    $scaredFearful
                    Sounds gruesome to be on the wrong end of it.
                    {cult_of_hesh?
                        player:
                            And you worship that thing?
                        agent:
                            !hesh_greeting
                            Hesh consumes all eventually. We simply wish to prevent unnecessary suffering.
                    }
                    {hesh_ctenophore?
                        player:
                            !surprised
                            Wait, I've heard that Hesh is another kind of jellyfish from some other people.
                            Cteno-something or the other?
                        agent:
                            !thought
                            Ah, yes, some people do believe that Hesh is a ctenophore.
                            !handwave
                            They are, of course, wrong.
                            From the descriptions of Hesh in the Waterlogged Tomes, it is clear that Hesh is a cnidarian.
                        player:
                            I see.
                        |
                        {hesh_unclassifiable?
                            player:
                                !surprised
                                Wait, I was under the impression that they can't be classified using conventional biology?
                                Or so I've heard someone claimed.
                            agent:
                                !thought
                                Ah, yes. The official stance of the Cult.
                                But is that really the case?
                                !shrug
                                Perhaps the Cult is trying to hide their ignorance.
                                !thought
                                Or perhaps they are trying to hide the horrifying truth from the public ear.
                                In either case, the fact of the matter is, Hesh is a cnidarian.
                            player:
                                I see.
                            |
                            player:
                                I'll... Keep that in mind.
                        }
                    }
                    |
                    {cult_of_hesh?
                        Hesh is a multi-faceted being, and to classify it is to waste what precious time we have before being consumed.
                    }
                    {not cult_of_hesh?
                        Hesh is a multi-faceted being, and classifying it is simply an impossibility.
                    }
                    {hesh_ctenophore or hesh_cnidarian?
                        {hesh_ctenophore and not hesh_cnidarian?
                            player:
                                !surprised
                                Wait, I've heard people calling Hesh a cteno-something or the other.
                                Isn't that a classification?
                            agent:
                                Ah yes, I do hear that people call Hesh a ctenophore.
                        }
                        {not hesh_ctenophore and hesh_cnidarian?
                            player:
                                !surprised
                                Wait, I've heard people calling Hesh a cni-something or the other.
                                Isn't that a classification?
                            agent:
                                Ah yes, I do hear that people call Hesh a cnidarian.
                        }
                        {hesh_ctenophore and hesh_cnidarian?
                            player:
                                !surprised
                                Wait, I've heard some people calling Hesh a cteno-something or the other.
                                While others calling it a cni-something or the other.
                                Aren't those classifications?
                            agent:
                                Well, ctenophora and cnidaria are indeed both phyla of jellyfish.
                        }
                        agent:
                            But the truth is, there are many aspects of Hesh that overlaps multiple categories, and putting Hesh in one single category is simply not possible because of its nature.
                        player:
                            I... see.
                    }
                    {not (hesh_ctenophore or hesh_cnidarian)?
                        player:
                            Thanks for the answer.
                            $miscMocking
                            You've <i>really</> cleared up my questions about Hesh's identity.
                        agent:
                            !shrug
                            You may feel disappointed by this answer, but it is the truth.
                    }
                }
                * You seem to understand Hesh a bit more from this conversation.
            ]],
        }
        :Fn(function(cxt)
            cxt.enc.scratch.hesh_identity = cxt.enc.scratch.hesh_identity or math.random(1, 3)
            cxt:Dialog("DIALOG_ANSWER", cxt.enc.scratch.hesh_identity)
            cxt.quest:DefFn("IncreaseHeshKnowledge", cxt.enc.scratch.hesh_identity)
            if not cxt.quest.param.spawned_interrupt then
                local candidates = {}
                for i, agent in cxt.location:Agents() do
                    if not agent:IsInPlayerParty() and agent:IsSentient() and agent:GetFactionID() == "CULT_OF_HESH"
                        and cxt.quest:DefFn("GetHeshBelief", cxt:GetAgent()) == HeshBelief.ANTI then

                        table.insert(candidates, agent)
                    end
                end
                if #candidates > 0 then
                    -- oops, someone who doesn't like your stuff overheard your little heresy.
                    -- a quest will spawn that is baad.
                    cxt.quest.param.spawned_interrupt = true
                    -- QuestUtil.SpawnQuest("REQUEST_CTENOPHORIAN_MYSTERY_EVENT", {
                    --     parameters =
                    --     {
                    --         overheard = candidates,
                    --         cultist = cxt:GetAgent(),
                    --     },
                    -- })
                    cxt.quest.param.overheard = cxt.quest.param.overheard or {}
                    for i, agent in ipairs(candidates) do
                        table.insert_unique(cxt.quest.param.overheard, agent)
                    end
                    cxt.quest.param.cultist = cxt.quest.param.cultist or cxt:GetAgent()
                    cxt.quest:Activate("bad_event")
                end
            end
            StateGraphUtil.AddEndOption(cxt)
        end)
QDEF:AddConvo("ask_info", nil, "HOOK_SLEEP")
    :State("START")
        :Loc{
            DIALOG_INTRO = [[
                * Sleep sucks you into it's grasp, and for a moment you feel a weightlessness you've grown accustomed to as the day's stress dissipates.
                * You stumble into a dream, but this dream... it's different.
            ]],
            DIALOG_INTRO_PST = [[
                * Suddenly, you're up to your ankles in saltwater. The water rises, reaching your knees, then your neck.
                * Finally, a percussive force of seawater envelops you, and for a moment the ocean becomes the only thing you can feel.
                agent:
                !right
                * And from the deep blue, a marine creature appears. A... you can't discern. Its face shifts too quickly for you to understand it.
                * But you need to understand it. You must...
            ]],
            --Wumpus;If I can make something up that isn't blaring against canon, there'll be things for the three main characters based on these "weird dreams". gonna look into that.
            OPT_UNDERSTAND = "Try to understand Hesh",
            DIALOG_UNDERSTAND = [[
                * You swim forward, towards the creature, but not too close, afraid of it's might.
                * You concentrate on the creature. Every fiber of your mind invests itself into understanding the thing that lies before you.
                * After an arduous, pained moment, you begin to understand.
            ]],
            DIALOG_UNDERSTAND_SUCCESS = [[
                player:
                    Just... What are you?
                * Then, at that moment, you seem to be able to perfectly understand the creature.
                * The creature starts to speak in an eerily beautiful voice.
                agent:
                    <i>I am Hesh.</>
                player:
                    !surprised
                    Whoa! Did Hesh just talk to me? Am I dreaming?
                agent:
                    <i>Technically, you are dreaming.</>
                    <i>Your body is resting, anticipating the struggle of tomorrow, while your mind wanders, freely conversing with me.</>
                    <i>Dreams are a reflection of reality, after all.</>
                player:
                    There's a lot to take in. I need some time to think.
                agent:
                    <i>Of course, I understand.</>
                    <i>If you want to know anything, you only need to ask.</>
            ]],
            DIALOG_UNDERSTAND_FAILURE = [[
                * Sand.
                * The knowledge feels like it slips out of your hands like sand through a sieve.
                * Sand. The ground closest to Hesh, at the beaches. The closest anyone will ever be to seeing the true Hesh.
                agent:
                    !exit
                * It is the sand of the beach you are confined to, the sand that you cannot go beyond, as the creature of your dreams slips further into the murky blue.
                * Its face still shifts between identities, but you were so close to understanding, if only you could reach beyond the sand, if only you could see, IF ONLY-
                * Yet you cannot, and you are plagued with those thoughts, unable to decipher anything.
            ]],
            DIALOG_NO_INTERFERE = [[
                * Every time you tried to decipher what you have seen, your mind frays further and further.
                * As such, your mind is consumed by Hesh's madness.
            ]],
            OPT_LOSE = "Embrace the madness",
            DIALOG_BENNI_INTERFERE_PRE = [[
                player:
                    !left
                    !scared
                giver:
                    !right
                    !scared
                * Yet just before you get completely consumed by Hesh's madness, you wake up, with {giver} violently shaking you.
            ]],
            DIALOG_BENNI_INTERFERE = [[
                giver:
                    !scared
                    {player}!
                player:
                    !surprised
                    Wha-
                giver:
                    Calm down! Everything is fine!
                player:
                    Hesh- It-
                giver:
                    You are going to be fine!
                    I will not lose another person I care about to Hesh's madness!
                    !exit
                player:
                    !exit
                * After a while, you finally calmed down.
                giver:
                    !right
                player:
                    !left
                    !sigh
                    Okay, I'm fine now.
                giver:
                    !agree
                    That's a relief.
                    Now, forget about the whole Hesh business. Drop the investigation into Hesh's taxonomy.
                    !sigh
                    Sometimes, absolute FACTS and LOGIC is not worth the price we pay.
                    FACTS don't care about your feelings. But I do.
            ]],
            DIALOG_BENNI_INTERFERE_PST = [[
                giver:
                    Now, let's get you back to sleep.
                    !hesh_greeting
                    May you have a pleasant dream.
                    !exit
                player:
                    !exit
                * That night, you didn't have any more dreams, which is quite a relief.
                * Yet, no matter how hard you try, you can never forget your attempt to understand Hesh that almost drives you to madness.
            ]],
            SIT_MOD = "Hard to understand",
        }
        :Fn(function(cxt)
            cxt:TalkTo(TheGame:GetGameState():AddSkinnedAgent("COGNITIVE_HESH"))

            cxt:FadeOut()
            cxt:Dialog("DIALOG_INTRO")
            cxt.location:SetPlax("EXT_SMITH_FINALBOSS1")
            cxt:FadeIn()
            cxt:Dialog("DIALOG_INTRO_PST")

            cxt:BasicNegotiation("UNDERSTAND", {
                situation_modifiers = {
                    { value = cxt.quest:GetRank() * 5 + 10, text = cxt:GetLocString("SIT_MOD") },
                },
            })
                :OnSuccess()
                    :Fn(function(cxt)
                        TheGame:GetGameProfile():SetBossAdvancement( cxt:GetAgent():GetContentID(), TheGame:GetGameState():GetAdvancementLevel())
                    end)
                    :GoTo("STATE_QUESTIONS")
                :OnFailure()
                    :Fn(function(cxt)
                        cxt:FadeOut()
                        -- You earn a special card or something.
                        cxt.quest.param.went_crazy = true
                        -- cxt.caravan:DeltaMaxResolve(-5)

                        if cxt:GetCastMember("giver") == TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor") and cxt:GetCastMember("giver"):GetContentID() == "ADVISOR_MANIPULATE" and cxt:GetCastMember("giver"):GetRelationship() >= RELATIONSHIP.LIKED then
                            cxt.location:SetPlax()
                            cxt:Dialog("DIALOG_BENNI_INTERFERE_PRE")
                            cxt:FadeIn()
                            cxt:Dialog("DIALOG_BENNI_INTERFERE")
                            cxt.quest.extra_reward = EXTRA_QUEST_REWARD.FREE_ITEM
                            cxt.quest.extra_reward_data = "white_lie"
                            cxt.quest:Complete()
                            ConvoUtil.GiveQuestRewards(cxt)
                            cxt:GetCastMember("giver"):AddTag("white_liar")
                            cxt:Dialog("DIALOG_BENNI_INTERFERE_PST")
                            cxt:ForceTakeCards{"status_fracturing_mind"}
                        else
                            cxt:Dialog("DIALOG_NO_INTERFERE")
                            -- Nah you just lose lol
                            cxt:Opt("OPT_LOSE")
                                :Fn(function(cxt)
                                    DemocracyUtil.DoEnding(cxt, "broken_mind", {})
                                end)
                        end
                    end)
                    -- :CompleteQuest("ask_info")
                    -- :ActivateQuest("tell_result")
        end)
    :State("STATE_QUESTIONS")
        :Loc{
            OPT_ASK_REAL = "Ask if Hesh is real",
            DIALOG_ASK_REAL = [[
                player:
                    [p] Are you real?
                agent:
                    <i>I don't know. Maybe I am real, or maybe I am just a construct of your subconscience.</>
                    <i>But reality is in the eyes of the beholder. If you believe I am real, then I am real to you.</>
            ]],
            OPT_ASK_CLASSIFICATION = "Ask what Hesh is",
            DIALOG_ASK_CLASSIFICATION = [[
                player:
                    [p] What are you?
                agent:
                    <i>I am Hesh.</>
                player:
                    No, I mean what kind of jellyfish are you?
                    Are you a ctenophore or a cnidarian, or are you beyond the conventional biological classification system?
                agent:
                    <i>...</>
                    <i>What?</>
                    <i>I mean, uh... What I am is not important. I am what you believe I am.</>
                    <i>If you believe I am a ctenophore, then I will appear to be a ctenophore to you.</>
                    <i>If you believe I am a cnidarian, then I will appear as so.</>
                    <i>If you believe something is true, then in your reality, it is the truth.</>
            ]],
            OPT_ASK_CULT = "Ask what Hesh think of the Cult",
            DIALOG_ASK_CULT = [[
                player:
                    [p] What do you think of the Cult?
                agent:
                    <i>I feel flattered that I am honored as a god by the Cult.</>
                    <i>Although, I am slightly concerned by their desire to be consumed by me.</>
                    <i>I mean, I'm not going to complain because of the free food, but still, it is concerning.</>
                player:
                    What do you think of their politics?
                    You know, like their whole deal of preserving artifacts, or treating lumin as a sacred fuel source.
                {player_sal?
                    !spit
                    Or using indentured labor to harvest said fuel source.
                }
                agent:
                    <i>I don't care.</>
                    <i>I mean, I'm just a jellyfish swimming at the bottom of the sea. What you people do does not concern me.</>
            ]],
            DIALOG_FINISH = [[
                player:
                    [p] Thank you. I feel like I understand you better now.
                agent:
                    <i>It was nice talking to you, {player}.</>
                    <i>Rarely do I find people who understand me.</>
                player:
                    Oh, Hesh?
                agent:
                    <i>Is there something you like to say?</>
            ]],
            OPT_COMPLIMENT = "Compliment on Hesh's magnificence",
            DIALOG_COMPLIMENT = [[
                player:
                    [p] Out of all the creatures I've seen, you are truly the most magnificent one.
                agent:
                    <i>Thank you.</>
                    <i>Many people fear me. Many people blindly worship me. But not many people compliment me like you just did.</>
                player:
                    !bashful
                    I- I feel honored.
            ]],
            OPT_WEIRD = "Express how weird Hesh is",
            DIALOG_WEIRD = [[
                player:
                    [p] You are truly weird, Hesh.
                    I feel like even if I asked all these questions, I still don't understand you at all.
                agent:
                    <i>I understand.</>
                    <i>Still, you manage to try and understand me. Not many people have the courage or the resolve to do that.</>
            ]],
            OPT_NOTHING = "Don't make additional comments",
            DIALOG_NOTHING = [[
                player:
                    [p] I was just exclaiming. Don't mind me.
                agent:
                    <i>Oh. Okay.</>
            ]],
            DIALOG_END = [[
                agent:
                    [p] <i>It's getting late, {player}. You have a long day ahead of you.</>
                    <i>It's time for us to say goodbye for now.</>
            ]],
            DIALOG_END_PST = [[
                * With that, the space around you begin to dry, as you wake up in your room.
                {not primary_advisor_manipulate?
                    * There is no water, no signs of Hesh.
                }
                {primary_advisor_manipulate?
                    * There is no water, no signs of Hesh (apart from all the Heshian imagery you typically found inside the home of a Heshian priest).
                }
                * Just you, and the cozy bed you're in.
                * You almost want to dismiss it all as just another dream, but you have a sinking feeling that this is no mere dream, but rather, a vision.
                * A vision of the truth of Hesh, and the truth of the world.
                * With that in mind, you go back to sleep.
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            local questions = {"ASK_REAL", "ASK_CLASSIFICATION", "ASK_CULT"}
            local has_question_left = false
            for i, id in ipairs(questions) do
                has_question_left = cxt:Question("OPT_" .. id, "DIALOG_" .. id) or has_question_left
            end

            local function EndOpt(cxt)
                cxt:Dialog("DIALOG_END")
                cxt:FadeOut()
                cxt.enc:PresentAgent(nil, SIDE.RIGHT)
                cxt.location:SetPlax()
                cxt:FadeIn()
                cxt:Dialog("DIALOG_END_PST")

                cxt.quest:Complete("ask_info")
                cxt.quest:Activate("tell_result")
                cxt:Pop()
            end

            if not has_question_left then
                cxt:Dialog("DIALOG_FINISH")

                cxt:Opt("OPT_COMPLIMENT")
                    :Dialog("DIALOG_COMPLIMENT")
                    :Fn(EndOpt)

                cxt:Opt("OPT_WEIRD")
                    :Dialog("DIALOG_WEIRD")
                    :Fn(EndOpt)

                cxt:Opt("OPT_NOTHING")
                    :Dialog("DIALOG_NOTHING")
                    :Fn(EndOpt)
            end
        end)
QDEF:AddConvo("tell_result", "giver")
    :AttractState("STATE_ATTRACT")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    So, have you find out anything about Hesh?
                player:
                    !handwave
                    I had some odd dream last night.
                    Had a lot of weird Hesh metaphors. Lots of water, dark, Hesh itself rearing it's head, the usual gist.
                agent:
                    !surprised
                    You saw Hesh? What'd it look like?
                player:
                    !shrug
                    That's the thing.
                    It shifts form based on what I believe is true.
                    When I think it's a ctenophore, it appears to be a ctenophore, and when I think it's a cnidarian, it appears to be a cnidarian.
                agent:
                    !dubious
                    So it shifts form based on your belief? I mean, it is Hesh that we are talking about.
                player:
                    !permit
                    The takeaway is this: We constantly think that we believe what we see, but this is untrue.
                    We see what we believe. We see what we want to believe.
                    In our minds, that becomes the truth and an absolute fact.
                    There is no such thing as an inherit fact. It's all subjective.
                agent:
                    !thought
                    So are facts just...subjective? Are all of my FACTS and LOGIC just...subjective?
                player:
                    !shrug
                    Like I said, eye of the beholder.
                agent:
                    !thought
                    Hmmm...
                    This is... certainly an angle that I was expecting, but it makes perfect sense, actually.
                    The true form of Hesh seems less relevant than this revelation.
                    Thank you, {player}, for opening my eyes.
                player:
                    !dubious
                    You're welcome, I suppose?
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest.extra_reward = EXTRA_QUEST_REWARD.FREE_ITEM
            cxt.quest.extra_reward_data = "advisor_manipulate_cognitive_dissonance"
            cxt.quest:Complete()
            ConvoUtil.GiveQuestRewards(cxt)
            cxt:GetCastMember("giver"):AddTag("can_manipulate_truth")
        end)

QDEF:AddConvo("bad_event")
    :TravelConfront("INTERRUPT", function(cxt) return TheGame:GetGameState():CanSpawnTravelEvent() end)
        :Loc{
            DIALOG_INTRO = [[
                * Your regular tromp through the hesh-blessed land is interrupted by someone with a hesh-fueled ire in {agent.hisher} eyes.
                player:
                    !left
                agent:
                    !right
                {liked?
                    {player}...heresy. Really?
                    I never thought you'd be capable of offending the cult like this.
                }
                {not liked?
                    !cruel
                    So let's talk about the identity of Hesh.
                    Those are the heretical questions you've been asking around, right?
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
                    Oh, that wasn't what we were talking about.
                    !hips
                    Let me clear that up for you.
                }
                {leader_absent?
                    !question
                    Strange. I don't remember talking to {cultist} at all.
                    I think you're mistaken. Let me clear this up.
                }
            ]],
            DIALOG_GASLIGHT_SUCCESS = [[
                {not_leader_absent?
                    player:
                        Y'see, {cultist} and I were actually talking about Hesh as an <i>entity</>, not Its identity.
                    agent:
                        !question
                        But Hesh is an entity. Of the abyss.
                    player:
                        !point
                        Exactly! That was the point I was trying to explain to {cultist}.
                        !chuckle
                        Glad to see I wasn't the heretic in that conversation.
                    agent:
                        Well, if that's true, then there's nothing I need to do here.
                        !hesh_greeting
                        Sorry to bother, {player}.
                }
                {leader_absent?
                    player:
                        !point
                        You know how some fans are. They like to dress up.
                    agent:
                        !angry
                        Do you honestly believe people are dressing up as a politician and grifter?
                    player:
                        !shrug
                        Hey, remember the run on jellyfish costumes?
                        I'm just saying, crazier things have happened.
                    agent:
                        !neutral
                        ...y'know what? That's true.
                        !hesh_greeting
                        Sorry to bother. I'll report back to {leader} that someone just dressed up as you.
                }
            ]],
            DIALOG_GASLIGHT_FAILURE = [[
                {not leader_absent?
                    player:
                        {cultist.HeShe} and I were just talking about Hesh's density, that's all.
                    agent:
                        !question
                        Density?
                    player:
                        !flinch
                        Er, I meant we talked about Its Enmity.
                    agent:
                        !angry
                        ...
                    player:
                        !bashful
                        Immensity?
                        !point
                        Parliamentary! Yes, of course.
                    agent:
                        Next time you try to lie to a cult member, be a little more convincing.
                }
                {leader_absent?
                    player:
                        !angry_accuse
                        I was nowhere near {cultist} all day!
                    agent:
                        !crossed
                        Oh really? And where were you all day, then?
                    player:
                        Doing my usual politician duties. A speech here, a check in with my advisor there, a little bit of heresy every now and the-
                    agent:
                        !angry
                    player:
                        !bashful
                        I uh...don't suppose I could take back that last bit, can I?
                }
            ]],

            OPT_LET_GO = "Convince {agent} to let you go",

            DIALOG_LET_GO = [[
                player:
                    !angry
                    Hey, no need to keep me here when there's actual heresy to deal with.
            ]],

            DIALOG_LET_GO_SUCCESS = [[
                player:
                    !hips
                    I know you don't like me, but that's the thing. You <i>know</> me.
                    Did I ever come off as caring about this topic beforehand?
                agent:
                    !thought
                    You bring up <i>a</> point. I don't think you were that particular over Hesh lore.
                    !angry
                    Fine. Cult business comes first, but what's between us isn't over!
                * {agent} tromps off, leaving a dread that {agent.heshe}'ll be a thorn in your side later lingering the air.
            ]],

            DIALOG_LET_GO_FAILURE = [[
                player:
                    Do you really think I am capable of committing heresy?
                {pro_religious_policy?
                    !thumb
                    I will have you know that I run a <i>very</> pro-Heshian platform.
                agent:
                    !angry_accuse
                    Don't be ridiculous! Anyone with a brain knows that you don't actually believe the stuff you say!
                    You are just trying to steal votes from devout Hesh followers!
                }
                {not pro_religious_policy?
                agent:
                    !angry_shrug
                    Yes! Absolutely!
                    You are a heretic, through and through.
                    Anyone knowing anything about your campaign would know that.
                }
                agent:
                    And there is only one way this is going to end for heretics like you!
            ]],

            OPT_BRIBE = "Bribe {agent}",
            DIALOG_BRIBE = [[
                {not leader_absent?
                    player:
                        Hey, no need to lie about me if you just wanted tithes.
                        !give
                        How's this? That oughta be enough for your quotas and such.
                    agent:
                        !taken_aback
                        I-
                        !angry_accuse
                        First of all, that word is for the bearers of spark and derrick workers.
                        !take
                        Secondly, thank you, {player}. May you walk in the shallows.
                }
                {leader_absent?
                    player:
                        !give
                        What I'm have to say is "big bag of money".
                        And what you're going to say is "Nothing to report".
                    agent:
                        !take
                        Of course, loyal Heshian. You were simply-
                    player:
                        !point
                        No no no. "Nothing to report.". Got it?
                    agent:
                        !hesh_greeting
                        Right, right. May you walk in the shallows.
                }
            ]],

            OPT_USE_BODYGUARD = "Send your guard to distract",
            DIALOG_USE_BODYGUARD = [[
                player:
                    !bashful
                    Well, y'see. The thing about heresy is uhm...
                    !point
                    {guard} go distract them.
                * You book it in the opposite direction, while {guard} keeps the group distracted long enough for you to duck out of sight.
            ]],

            DIALOG_DEFEND = [[
                player:
                    !fight
                    You're going down, cultist!
            ]],
            DIALOG_DEFEND_WIN = [[
                {dead?
                    * You take the extra second to wipe some lumin-blue blood off your weaponry.
                    * Your polling average would've preferred you didn't murder a group of voters, but it is what it is.
                }
                {not dead?
                    agent:
                        !injured
                    player:
                        !fight
                        I hope I've sufficiently beaten the idea I committed heresy out of your dense skull.
                    agent:
                        You have. Won't be dealing with us for a while.
                        But keep that heresy talk to yourself if you don't want to see someone else's ugly mug asking the same thing I did.
                    * The cultish crew stumbles away, leaving the thinly veiled threat for you to ponder.
                }
            ]],

            OPT_RAT_OUT = "Tell {agent} about {giver}'s involvement",
            DIALOG_RAT_OUT = [[
                player:
                    !handwave
                    Well, if I could be frank, I never had any interest what kind of stingers the big jellyfish has.
                    {giver} just asked me for an errand to ask around.
                agent:
                {disliked?
                    !angry
                    Calling a cult member's credibility into question? A dangerous move, you know.
                    We'll look into {giver}'s motives soon, but you're still the heretic here.
                * Dang, you really hoped that snitching on {giver} would get you out of this situation.
                }
                {not disliked?
                    !dubious
                    {giver}? Aren't they a member of the cult?
                player:
                    !shrug
                    That's what it says on {giver.hisher} business card.
                agent:
                    I guess they'd have the motive to learn more about Hesh, though {giver.heshe} should've known about this heresy beforehand.
                    !hesh_greeting
                    Thank you, {player}, for this information. We'll be sure to investigate {giver} shortly.
                * {agent} walks away, though you can't help the sense of foreboding you feel.
                }
            ]],

            SIT_MOD = "There are other witnesses of your heresy",
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest.param.overheard = cxt.quest.param.overheard or {}
                local leader
                if #cxt.quest.param.overheard > 0 then
                    leader = table.arraypick(cxt.quest.param.overheard)

                    if AgentUtil.HasPlotArmour(leader) or not AgentUtil.CanAct(leader) or leader:GetFactionID() ~= "CULT_OF_HESH" then
                        cxt.enc.scratch.leader_absent = true
                    end
                    cxt:ReassignCastMember("leader", leader)
                end

                if leader and not cxt.enc.scratch.leader_absent then
                    leader:MoveToLocation(cxt.location)
                    CreateCombatBackup(leader, "HESH_PATROL", cxt.quest:GetRank())
                    cxt:TalkTo(leader)
                else
                    cxt.enc.scratch.opfor = CreateCombatParty("HESH_PATROL", cxt.quest:GetRank(), cxt.location, true)
                    cxt:TalkTo(cxt.enc.scratch.opfor[1])
                end

                cxt:Dialog("DIALOG_INTRO")
            end
            if not cxt.quest:IsActive("rat_out_aftermath") then
                local bonus = #cxt.quest.param.overheard > 0 and (#cxt.quest.param.overheard - 1) * 10 or 0
                cxt:BasicNegotiation("GASLIGHT", {
                    -- Opponent gains bonus resolve for other witnesses.
                    situation_modifiers = bonus > 0 and {
                        { value = bonus, text = cxt:GetLocString("SIT_MOD") }
                    } or nil,
                })
                    :OnSuccess()
                        :CompleteQuest("bad_event")
                        :Travel()
            else
                cxt:BasicNegotiation("LET_GO", {
                })
                    :OnSuccess()
                        :CompleteQuest("bad_event")
                        :Travel()
            end

            cxt:Opt("OPT_BRIBE")
                :Dialog("DIALOG_BRIBE")
                :DeliverMoney(100)
                :CompleteQuest("bad_event")
                :Travel()

            DemocracyUtil.AddBodyguardOpt(cxt, function(opt, agent)
                opt:Fn(function(cxt)
                    cxt:ReassignCastMember("guard", agent)
                    cxt:Dialog("DIALOG_USE_BODYGUARD")
                    if agent:IsPet() then
                        QuestUtil.SpawnQuest("STORY_PET_RETURN", { cast = { pet = agent } })
                    end
                    agent:Dismiss()
                    cxt.quest:Complete("bad_event")
                    StateGraphUtil.AddLeaveLocation(cxt)
                end)
            end)

            cxt:Opt("OPT_DEFEND")
                :Dialog("DIALOG_DEFEND")
                :Battle{
                    -- enemies = cxt.enc.scratch.opfor,
                    on_runaway = StateGraphUtil.DoRunAwayNoFail,
                }
                    :OnWin()
                        :Dialog("DIALOG_DEFEND_WIN")
                        :CompleteQuest("bad_event")
                        :Travel()
            cxt:Opt("OPT_RAT_OUT")
                :Dialog("DIALOG_RAT_OUT")
                :Fn(function(cxt)
                    if not cxt.quest:IsActive("rat_out_aftermath") then
                        cxt.quest:Activate("rat_out_aftermath")
                    end
                    if cxt:GetAgent():GetRelationship() >= RELATIONSHIP.NEUTRAL then
                        cxt.quest:Complete("bad_event")
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end
                end)
        end)

QDEF:AddConvo("rat_out_aftermath")
    :Confront(function(cxt)
        if cxt:GetCastMember("giver") and cxt:GetCastMember("giver"):GetContentID() == "ADVISOR_MANIPULATE" then
            local tei = AgentUtil.GetOrSpawnAgentbyAlias("TEI")
            if tei and tei:IsAlive() then
                if cxt.location == cxt:GetCastMember("giver"):GetHomeLocation() and
                    cxt.location == cxt:GetCastMember("giver"):GetLocation() then
                    return "STATE_BENNI_TEI_DIALOG"
                end
            else
                if (quest.time_left or 0) <= 0 and cxt.location:HasTag("in_transit") then
                    return "STATE_ARREST"
                end
            end
        else
            if (quest.time_left or 0) <= 0 and cxt.location:HasTag("in_transit") then
                return "STATE_ARREST"
            end
        end
    end)
    :State("STATE_BENNI_TEI_DIALOG")
        :Loc{
            DIALOG_INTRO = [[
                * You arrive here seeing {giver} and {tei} talking.
                giver:
                    !left
                    !scared
                tei:
                    !right
                    !angry_shrug
                    {giver}! I've heard you have been asking around about Hesh's classification.
                    You should know this is very heretical! As a priest, you should know this!
                giver:
                    !bashful
                    I thought the Cult was just saying that because they themselves don't even know what Hesh is!
                    I didn't know that trying to classify it was strictly forbidden by the Cult!
                tei:
                    That is because Hesh cannot be classified under normal classification!
                giver:
                    Right, of course.
                    !placate
                    Look, I learned my lessons, alright?
                    No more trying to classify Hesh.
                    !point
                    That's a promise.
                tei:
                    !palm
                    Look, you seem like you genuinely don't know, and you seem sincere enough.
                    I'll let you go this time, but don't do this again, alright?
                    I can't promise that I will be merciful next time, or anyone else for that matter.
                giver:
                    !bashful
                    Thank you.
                tei:
                    !exit
                * {tei} leaves.
                * You walk up to {giver}.
                giver:
                    !right
                player:
                    !left
                    What's going on?
                giver:
                    I was just talking to {tei}.
                    [p] Don't bother trying to classify Hesh anymore.
                    It makes {tei} sad.
                player:
                    Oh, okay.
            ]],
        }
        :Fn(function(cxt)
            cxt:ReassignCastMember("tei", AgentUtil.GetOrSpawnAgentbyAlias("TEI"))
            cxt:GetCastMember("tei"):MoveToLocation(cxt.location)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Cancel()
            QuestUtil.SpawnQuest( "FOLLOWUP_INTERWEAVING_BONDS" )
            StateGraphUtil.AddEndOption(cxt)
        end)
    :State("STATE_ARREST")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You saw {giver} getting taken away by {priest}.
                giver:
                    !left
                    !scared
                priest:
                    !right
                    Alright, just come with me.
                    Makes it easier for both of us.
                giver:
                    What did I even do?
                priest:
                    I have reasonable intel that you are the one that is asking around questions you shouldn't ask.
                    You can come with me.
                giver:
                    !thought
                    {player} must have rat me out.
                    Know I shouldn't have trusted a grifter.
                * Oh no, {giver} is getting taken away by the cult!
            ]],
        }
        :Fn(function(cxt)
            cxt:ReassignCastMember("priest", AgentUtil.GetFreeAgent("PRIEST"))
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Fail()
            cxt:GetCastMember("giver"):GainAspect("stripped_influence", 5)
            cxt:GetCastMember("giver"):OpinionEvent(OPINION.BETRAYED)
            cxt:GetCastMember("giver"):Retire()
            StateGraphUtil.AddLeaveLocation(cxt)
        end)
