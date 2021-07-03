-- This only matters in regards to the desire to find about Hesh's classification.
local HeshBelief = MakeEnum{ "ANTI", "CAUTIOUS", "FANATIC" }
local function GetHeshBelief(agent)
    if agent:GetContentID() == "ADVISOR_MANIPULATE" then
        return HeshBelief.CAUTIOUS
    elseif agent:GetContentID() == "TEI" then
        return HeshBelief.ANTI
    end
    return agent:CalculateProperty("HESH_BELIEF", function(agent)
        local omni_hesh_chance = agent:GetRenown() * .12
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
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 10, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, 4, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 5, "CULT_OF_HESH", "COMPLETED_QUEST")
        elseif quest.param.sub_optimal then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 5, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 4, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 3, "CULT_OF_HESH", "COMPLETED_QUEST")
        elseif quest.param.poor_performance then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2, "POOR_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 4, "POOR_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 2, "CULT_OF_HESH", "POOR_QUEST")
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
:AddObjective{
    id = "bad_event"
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
            and (cxt:GetAgent():GetFactionID() == "CULT_OF_HESH" or cxt:GetAgent():GetFactionID() == "FEUD_CITIZEN") then

            cxt:Opt("OPT_ASK_HESH")
                :SetQuestMark()
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
            cxt:BasicNegotiation("PROBE", {
                -- Opponent will have a secret intel bounty.
            })
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
            cxt:BasicNegotiation("ENDURE", {
                -- This will be a special negotiation.
                -- Opponent has no core, meaning you can't win by damage.
                -- You win by surviving a set amount of rounds.
                flags = NEGOTIATION_FLAGS.NO_CORE_RESOLVE,
				on_start_negotiation = function(minigame)
					minigame.player_negotiator:AddModifier("FANATIC_LECTURE", math.max(4, 6 - math.floor(cxt.quest:GetRank() / 2)))
				end,
            })
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
                    If you must know, Hesh cannot be classified.
                    Hesh is a multi-faceted being, and to classify it is to waste what precious time we have before being consumed.
                    Now you know the answer, just promise me you won't ask around this kind of question again.
                player:
                    Sure.
                    It's already confusing enough.
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
                    If you must know, Hesh cannot be classified.
                    Hesh is a multi-faceted being, and to classify it is to waste what precious time we have before being consumed.
                    Now you know the answer, just promise me you won't ask around this kind of question again.
                player:
                    Sure.
                    It's already confusing enough.
            ]],
            DIALOG_EXCUSE_FAILURE = [[
                agent:
                    [p] I am sus of you!
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_TALK")
            cxt.enc.scratch.hesh_identity = 3
            cxt.quest.param.hesh_id = cxt.quest.param.hesh_id or {}
            if cxt:GetAgent():GetRelationship() > RELATIONSHIP.NEUTRAL then
                cxt:Opt("OPT_THANK")
                    :Dialog("DIALOG_THANK")
                    :Fn(function(cxt)
                        cxt.quest.param.hesh_id[cxt.enc.scratch.hesh_identity] = (cxt.quest.param.hesh_id[cxt.enc.scratch.hesh_identity] or 0) + 1
                    end)
            else
                cxt:BasicNegotiation("EXCUSE", {})
                    :OnSuccess()
                        :Fn(function(cxt)
                            cxt.quest.param.hesh_id[cxt.enc.scratch.hesh_identity] = (cxt.quest.param.hesh_id[cxt.enc.scratch.hesh_identity] or 0) + 1
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
                player:
                    !surprised
                    The what-a-what-phore?
                agent:
                    $miscMocking
                    C-te-no-phore.
                    They basically have these comb-like cilia that are used for swimming, from what I can tell.
                player:
                    !dubious
                    Sounds... Cute?
                agent:
                    I assure you, it's anything but cute.
                    Most ctenophores are very capable predators.
                    !hesh_greeting
                    And Hesh is the most fearful predator of them all.
                player:
                    I'll... Keep that in mind.
                    |
                    Hesh is a cnidarian.
                player:
                    !surprised
                    The what-a-what-rian?
                agent:
                    $miscMocking
                    C-ni-da-rian.
                    They basically have these nettle cells that allows them to harpoon their preys, from what I can tell.
                player:
                    !wince
                    $scaredFearful
                    That sounds... Terrifying.
                    And you worship that thing?
                agent:
                    !hesh_greeting
                    Hesh consumes all eventually. We simply wish to prevent unnecessary suffering.
                    |
                    Hesh is not ctenophorian, nor is it cnidarian.
                    Hesh is a multi-faceted being, and to classify it is to waste what precious time we have before being consumed.
                player:
                    Yeah that definitely make sense and not at all confusing.
                agent:
                    !shrug
                    It is what it is.
                }
                * You seem to understand Hesh a bit more from this conversation.
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
                * Sleep sucks you into it's grasp, and for a moment you feel a weightlessness you've grown accustomed to as the day's stress dissapates.
                * You stumble into a dream, but this dream...it's different.
                * Suddenly, you're up to your ankles in saltwater. The water rises, reaching your knees, then your neck.
                * Finally, a percussive force of seawater envelops you, and for a moment the ocean becomes the only thing you can feel.
                agent:
                !right
                * And from the deep blue, a marine creature appears. A...you can't discern. It's face shifts too quickly for you to understand it.
                * But you need to understand it. You must...
            ]],
            --Wumpus;If I can make something up that isn't blaring against canon, there'll be things for the three main characters based on these "weird dreams". gonna look into that.
            OPT_UNDERSTAND = "Try to understand Hesh",
            DIALOG_UNDERSTAND = [[
                * You swim forward, towards the creature, but not too close, afraid of it's might.
                * You concentrate on the creature. Every fiber of your mind invests itself into understanding the thing that lies before you.
                * After an arduous, pained moment, finally it opens it's mouth to speak...
            ]],
            DIALOG_UNDERSTAND_SUCCESS = [[
                * Finally, it closes it's gaping jaw. You step out of your trance and stare at what you've deciphered.
                * It changes its form based on what you believe Hesh looks like at the moment.
                * Then it occured to you: no one has actually seen Hesh personally, to your knowledge.
                * How come everyone are confident about what Hesh looks like? And how come you can see Hesh's form?
                * You realized that reality is in the eye of the beholder, and whatever you believe is real, is real.
                * And you accept this, just as much as you accept the saltwater around you, which drains as your fascination dwindles as well.
                * When the space around you returns to dry land, sleep leaves, peacefully as it came, and dropping you into your room, refreshed.
            ]],
            DIALOG_UNDERSTAND_FAILURE = [[
                * Sand.
                * The knowledge feels like it slips out of your hands like sand through a sieve.
                * Sand. The ground closest to Hesh, at the beaches. The closest anyone will ever be to seeing the true Hesh.
                agent:
                !exit
                * it is the sand of the beach you are confined to, the sand that you cannot go beyond, as the creature of your dreams slips further into the murky blue.
                * It's face still shifts between identities, but you were so close to understanding, if only you could reach beyond the sand, if only you could see, IF ONLY-
                * Yet you cannot, and you are plagued with those thoughts for the rest of the night, unable to decipher anything.
            ]],
        }
        :Fn(function(cxt)
            cxt:TalkTo(TheGame:GetGameState():AddSkinnedAgent("COGNITIVE_HESH"))

            cxt:Dialog("DIALOG_INTRO")

            cxt:BasicNegotiation("UNDERSTAND", {
            })
                :OnSuccess()
                    :CompleteQuest("ask_info")
                    :ActivateQuest("tell_result")
                :OnFailure()
                    :Fn(function(cxt)
                        -- You earn a special card or something.
                        cxt.quest.param.went_crazy = true
                        cxt.caravan:DeltaMaxResolve(-5)
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
-- local BAD_EVENT = QuestDef.Define{
--     id = "REQUEST_CTENOPHORIAN_MYSTERY_EVENT",
--     qtype = QTYPE.STORY,
-- }
-- :AddObjective{
--     id = "start",
--     status = QSTATUS.ACTIVE,
-- }

QDEF:AddConvo("bad_event")
    :TravelConfront("INTERRUPT", function(cxt) return TheGame:GetGameState():CanSpawnTravelEvent() end)
        :Loc{
            DIALOG_INTRO = [[
                * [p] You are interrupted by {agent}.
                player:
                    !left
                agent:
                    !right
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

            OPT_LET_GO = "Convince {agent} to let you go",

            DIALOG_LET_GO = [[
                player:
                    I know you don't like me, but I helped you get what you want.
                    Would you at least let me go?
            ]],

            DIALOG_LET_GO_SUCCESS = [[
                agent:
                    !facepalm
                    Uh, fine. We have the real source of this heresy.
                    Easier to find {giver} than staying here arguing with you.
                player:
                    !hips
                    That's the spirit.
                * {agent} let you go, but you are sure that this is not over.
            ]],

            OPT_BRIBE = "Bribe {agent}",
            DIALOG_BRIBE = [[
                player:
                    !happy
                    Look, I'm just asking some questions.
                    It's not hurting anyone for being curious, right?
                    !give
                    And it's certainly not hurting you.
                agent:
                    !take
                    Ah, yes, of course.
                    Considering you don't know any better, this transgression can be overlooked.
                    Just... Make sure you don't ask questions that you shouldn't ask again.
                player:
                    Yes, of course.
                * It's probably a lie, but {agent} is not going to question it.
            ]],

            OPT_USE_BODYGUARD = "Send your guard to distract",
            DIALOG_USE_BODYGUARD = [[
                player:
                    [p] Go, {guard}!
                * {guard} deals with the Heshians while you "tactically retreat".
            ]],

            DIALOG_DEFEND = [[
                player:
                    [p] Easier just to fight.
            ]],
            DIALOG_DEFEND_WIN = [[
                * [p] You win. Now what.
            ]],

            OPT_RAT_OUT = "Tell {agent} about {giver}'s involvement",
            DIALOG_RAT_OUT = [[
                player:
                    !bashful
                    Oh, I wasn't aware that there is a problem.
                    {giver} told me to find out about what type of jellyfish Hesh is, and so I just ask around.
                    Didn't realize that it was heretical.
                agent:
                {disliked?
                    !crossed
                    Hmm. A likely excuse.
                    We will look into {giver} later, but as far as I'm concerned, you are the one asking the questions.
                player:
                    !angry_shrug
                    Oh come on! I give you the real reason. You should just let me go.
                }
                {not disliked?
                    !dubious
                    {giver}, are you sure?
                player:
                    Yeah, why else would I say {giver.hisher} name?
                agent:
                    !shrug
                    Fair enough.
                    Well, since you didn't know that it is problematic, and you are very cooperative, I'm going to let you go this time.
                    There will be questionings for {giver} of course, but it's not your problem.
                player:
                    !scared_shrug
                    Sure, I guess...?
                * {agent} let you go, but you are sure that this is not over.
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
            if not cxt.quest.param.rat_out_giver then
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

            DemocracyUtil.AddBodyguardOpt(cxt, function(cxt, agent)
                cxt:ReassignCastMember("guard", agent)
                cxt:Dialog("DIALOG_USE_BODYGUARD")
                if agent:IsPet() then
                    QuestUtil.SpawnQuest("STORY_PET_RETURN", { cast = { pet = agent } })
                end
                agent:Dismiss()
                cxt.quest:Complete("bad_event")
                StateGraphUtil.AddLeaveLocation(cxt)
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
                    cxt.quest.param.rat_out_giver = true
                    if cxt:GetAgent():GetRelationship() >= RELATIONSHIP.NEUTRAL then
                        cxt.quest:Complete("bad_event")
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end
                end)
        end)
