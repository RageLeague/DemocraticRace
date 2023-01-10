local QDEF = QuestDef.Define
{
    title = "Interweaving Bonds",
    desc = "The only person that {benni} treats nicely is {tei}, it seems. Figure out why that is.",

    qtype = QTYPE.SCENARIO,

    on_init = function(quest)
        quest.hide_in_overlay = true
    end,

    postcondition = function(quest)
        local friends = TheGame:GetGameState():GetPlayerAgent().social_connections:CountConnections( function(agent, rel)
            return rel > RELATIONSHIP.NEUTRAL
        end )
        local enemies = TheGame:GetGameState():GetPlayerAgent().social_connections:CountConnections( function(agent, rel)
            return rel < RELATIONSHIP.NEUTRAL
        end )
        quest.param.many_friends = friends >= enemies
        if friends + enemies < 12 then
            return false, "Not enough relations"
        end
        if quest:GetCastMember("benni"):HasMemory("DID_PROBE_RELATION_SIDE") then
            return false, "Already did the quest"
        end
        quest:GetCastMember("benni"):Remember("DID_PROBE_RELATION_SIDE")
        return true
    end,
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
    on_complete = function(quest)
        quest:Activate("ask")
        quest:SetHideInOverlay(false)
    end,
}
:AddObjective{
    id = "ask",
    title = "Ask {benni} about it",
    desc = "Ask {benni} about it. I am sure that {benni} is perfectly happy telling you everything just because you are nosy and don't respect boundaries.",
    mark = {"benni"},
}
:AddCastByAlias{
    cast_id = "benni",
    alias = "ADVISOR_MANIPULATE",
    no_validation = true,
}
:AddCastByAlias{
    cast_id = "tei",
    alias = "TEI",
    no_validation = true,
}

QDEF:AddConvo("start")
    :ConfrontState("STATE_CONF")
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
                {not avoid_tei?
                    * Wait, hold on a second. {benni} being nice to someone?
                    * {benni}? "Facts don't care about your feelings" {benni}?
                }
                {avoid_tei?
                    * Wait, hold on a second. Why is {benni} trying to prevent you from confronting {tei}?
                    * Isn't that a bit conspicuous?
                }
                player:
                    !cagey
                    What? Who said that?
                * Oh, I am Mr.Bonds, living rent free inside your head.
                player:
                    Mister what?
                * I help you identify potential bonds between people.
                * Relationships, conflicts. I know it all. I see it all.
                * It's how you are able to survive as a grifter so far.
                * Just look at yourself. Look at how many friends I identified for you.
                * You can see them clearly in the <b>Relationship Screen</>.
                {many_friends?
                    player:
                        !thought
                        I guess I did make quite a few friends.
                    * See? What did I tell you?
                }
                {not many_friends?
                    player:
                        !thought
                        I don't know. I feel like I made more enemies than friends.
                    * I only help you identify friends. Not make them.
                    * Besides, it's still better for you if you know who your enemies are, isn't it?
                }
                player:
                    !crossed
                    Still, what's your point?
                * Don't you want to know what is going on between {benni} and {tei}?
                *** "Mr.Bonds" wants you know the relationship between {benni} and {tei}.
            ]],
            OPT_YES = "Yes (Accept side goal)",
            DIALOG_YES = [[
                player:
                    !thought
                    I have to say, I am a bit curious, to say the least.
                * Excellent! I am glad you are in this business!
                * Let's go ask {benni} about it! See what {benni.gender:he has|she has|they have} to say about it.
            ]],
            OPT_NO = "No",
            DIALOG_NO = [[
                player:
                    No, not really.
                * Come on! Aren't you at least a bit curious?
            ]],
            DIALOG_NO_AGAIN = [[
                player:
                    !crossed
                    Absolutely not.
                    It's none of my business, anyway.
                * Fine, Your <i>Professional</> Excellency. Have it your way.
                * If you don't want to know your advisor better so you can work better, it's your loss.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_YES")
                :Dialog("DIALOG_YES")
                :CompleteQuest("start")
                :DoneConvo()

            cxt:Opt("OPT_NO")
                :Dialog("DIALOG_NO")
                :Fn(function(cxt)
                    cxt:Opt("OPT_YES")
                        :Dialog("DIALOG_YES")
                        :CompleteQuest("start")
                        :DoneConvo()

                    cxt:Opt("OPT_NO")
                        :Dialog("DIALOG_NO_AGAIN")
                        :FailQuest()
                        :DoneConvo()
                end)

        end)

QDEF:AddConvo("ask", "benni")
    :Loc{
        OPT_ASK = "Ask about {benni}'s relationship with {tei}",
        DIALOG_ASK = [[
            player:
                So, I noticed that you seem awfully nice to {tei}.
                Why is that?
        ]],
        DIALOG_ASK_SUCCESS = [[
            agent:
                In the Cult, they don't like it when you are different.
                They favor blind devotion instead of FACTS and LOGIC.
            player:
                !shrug
                Sounds about right.
            agent:
                !angry
                The thing is! I probably have more faith than most of them!
                My fear of Hesh is probably more genuine and real than most of them!
                !angry_accuse
                Yet! They refuse to use logical thinking, and treats me as if I am a heretic! An imposter!
            {primary_advisor_diplomacy?
                * Oh no.
                * The mention of an imposter reminds you of Aellon's rambling.
            }
            agent:
                Don't they know that everyone has a different way of showing faith?
            player:
            {player_arint?
                !sigh
                I've dealt with the zealots of the Cult long enough to know how the treat people who don't show faith the same way as they do.
            }
            {not player_arint?
                From what I gathered, they really don't like anyone outside of the line.
            }
                What about {tei}?
                From the way this is going, I'm assuming {tei.gender:he is|she is|they are} different.
            agent:
                !agree
                That is right. {tei.gender:He is|She is|They are} the only person in the Cult who treats me like an actual priest of the Cult.
                {tei.gender:He doesn't|She doesn't|They don't} seem to mind that I show faith differently, or my brain doesn't work the same way as the other priests.
                Given that case, wouldn't it be reasonable to conclude that I should reciprocate {tei.hisher} kindness?
            player:
                That... is true, I guess.
            agent:
                ...
                $miscEmbarrassed
                And I... might have a crush on {tei.himher}.
                !sigh
                There. You got what you wanted. Happy now?
            {knows_ace?
                * Wait, hold on. Isn't {agent} asexual?
            }
            *** {agent} tells you the reason why {benni.gender:he treats|she treats|they treat} {tei} positively.
        ]],
        DIALOG_ASK_SUCCESS_PARTIAL = [[
            agent:
                !crossed
                That is impossible, {player}.
                I am asexual, so logically speaking, I am not interested in {tei.himher} that way.
                Or anyone else, for that matter.
            player:
                !bashful
                Oh.
                That makes sense, actually.
            agent:
                Anyway, shouldn't you be getting back to campaigning?
            * There's got to be more to this story, though.
            * For example, {agent} often mentioned that {agent.gender:he has|she has|they have} a husband, right?
            *** {agent} denied being interested in {tei} the way you would think {agent} is.
        ]],
        DIALOG_ASK_FAILURE = [[
            agent:
                Seems like you don't understand the concept of boundary.
                !crossed
                And the concept of focusing on your job.
            {primary_advisor_manipulate?
                Support doesn't care about your feelings, {player}. So I suggest you get on that instead of slacking off.
            }
            {not primary_advisor_manipulate?
                Don't you have a campaign to run, {player}? Why don't you do that instead of this?
            }
            * Yeah. {agent.gender:He has|She has|They have} a good point.
            * You really should work on your campaign instead of doing whatever you think you are doing right now.
            player:
                !angry
                Hey! You asked me to do that yourself, and now you backpedal?
            agent:
                !crossed
                That is factually impossible, {player}.
            player:
                !bashful
                Sorry, my bad.
            * I didn't tell you to do that. Mr.Bonds did.
            * I am Logistitron-1500, responsible for keeping you on track.
            * So, you should do that. Focus on the campaign, I mean.
            *** {agent} tells you to focus on the campaign.
        ]],
        DIALOG_ASK_DISLIKED = [[
            player:
                So, I noticed that you seem awfully nice to {tei}.
            agent:
            {primary_advisor_manipulate?
                !crossed
                And I noticed that you seem to be falling awfully behind in terms of your support level.
                Support doesn't care about your feelings, {player}. So I suggest you get on that instead of slacking off.
            }
            {not primary_advisor_manipulate?
                !crossed
                And I noticed that you seem to be poking about business that is none of yours.
                So I suggest you focus on your own problems first. Don't you have a campaign to run?
            }
            * Yeah. {agent.HeShe} has a good point.
            * You really should work on your campaign instead of doing whatever you think you are doing right now.
            player:
                !angry
                Hey! You asked me to do that yourself, and now you backpedal?
            agent:
                !crossed
                That is factually impossible, {player}.
            player:
                !bashful
                Sorry, my bad.
            * I didn't tell you to do that. Mr.Bonds did.
            * I am Logistitron-1500, responsible for keeping you on track.
            * So, you should do that. Focus on the campaign, I mean.
            *** {agent} shuts you down immediately and tells you to focus on the campaign.
        ]],
        SIT_MOD = "Doesn't care about your feelings",

        OPT_ACE = "Ask about {benni}'s asexuality",
        DIALOG_ACE = [[
            player:
                Wait! Aren't you asexual?
                If so, how can you have a crush on {tei}?
            agent:
                !dubious
                ...
                I am asexual, not aromantic.
                !crossed
                Factually speaking, they are completely different.
            * Dang, {agent.gender:he's|she's|they've} got you there.
        ]],
        OPT_ACE_II = "Ask about the difference between asexual and aromantic",
        DIALOG_ACE_II = [[
            * Okay, I appreciate that you are curious about this topic and ask.
            * But if you actually asked, it's going to turn into a twenty minute discussion about a topic that {agent} is uncomfortable to discuss.
            * That <i>I</> am uncomfortable to discuss in this mod.
            * So uh, look it up in your own time. Thanks.
            * Or don't. It's not like I can tell if you are looking it up or not, or force you to do it.
            * Either way, I am just going to disable this line of questioning real quick.
        ]],
        OPT_ASK_OUT = "Ask {benni} to confess {benni.hisher} feelings for {tei} to {tei.himher}",
        DIALOG_ASK_OUT = [[
            player:
                So... Have you told {tei} about your feelings for {tei.himher}?
            agent:
                No.
            player:
                Have you-
            agent:
                !placate
                Absolutely not!
                I mean, I'm just not ready emotionally yet.
            player:
                Okay-
            agent:
                And before you ask, I am totally <i>not</> scared to talk to her.
                !placate
                $scaredStammering
                Nope! Absolutely not!
                It's more of a personal reason.
            player:
                What-
            agent:
                And before you ask, no, I can't talk about it.
                You've already wasted your time asking about one personal question. I am <i>not</> going to give you an opportunity to ask another.
            * You are not going to get anything more from this. Best if you drop the topic.
        ]],
        OPT_SPOUSE = "Ask about {benni}'s husband",
        DIALOG_SPOUSE = [[
            player:
                Wait, I thought you have a husband?
            agent:
                !hips
                Let me introduce to a concept called lying.
            player:
                !dubious
                ...
                Then why say anything at all?
                You seem to be the one that mentions you have a doctor husband at every opportunity while nobody asked.
            agent:
                !eureka
                Precisely!
                I say that all the time, so that nobody would ask!
            * You can't decide if this strategy is brilliant of stupid.
        ]],
        OPT_REWARD = "Ask about the reward",
        DIALOG_REWARD = [[
            player:
                Wait, what is my reward for doing this?
            agent:
                !dubious
                Reward? Seriously?
                $miscMocking
                How about "not getting {agent} dislike you because you asked too many personal questions"? Good enough reward for you?
            * Oh please, lore is it's own reward.
            * You love lore, don't you? That's why you decided to follow this side goal, right?
            * Surely it's worth the free time you've spent on the negotiation.
        ]],
        DIALOG_DONE = [[
            player:
                !happy
                Okay, I am happy now.
            agent:
                !handwave
                $miscMocking
                Great! I am <i>so glad</> you come in and badger me with personal questions.
                You should definitely stop wasting both of our time and go back to working on your campaign now.
            player:
                Oh, yes. Of course.
        ]],
    }
    :Hub(function(cxt)
        if cxt:GetAgent():GetRelationship() < RELATIONSHIP.NEUTRAL or (cxt:GetAgent():GetRelationship() <= RELATIONSHIP.NEUTRAL and cxt:GetAgent() ~= (TheGame:GetGameState():GetMainQuest() and TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor"))) then
            local opt = cxt:Opt("OPT_ASK")
                :RequireFreeTimeAction()
                :Dialog("DIALOG_ASK_DISLIKED")
                :Negotiation{
                    situation_modifiers = {
                        { value = 20, text = cxt:GetLocString("SIT_MOD") }
                    },
                }
            local timer_name = opt.hub:GetStateID()..(opt.loc_id or opt.text or "")
            table.remove(opt.handlers, #opt.handlers)
            opt:Fn(function(cxt)
                cxt:GetAgent():OpinionEvent(OPINION.DEEPENED_RELATIONSHIP_FAIL)
                cxt.quest:Fail()
            end)
        else
            cxt:Opt("OPT_ASK")
                :RequireFreeTimeAction()
                :Dialog("DIALOG_ASK")
                :Negotiation{
                    situation_modifiers = {
                        { value = 20, text = cxt:GetLocString("SIT_MOD") }
                    },
                    on_start_negotiation = function(minigame)
                        minigame:GetOpponentNegotiator():CreateModifier( "secret_intel", 1 )
                    end,
                    on_success = function(cxt, minigame)
                        local count = minigame:GetPlayerNegotiator():GetModifierStacks( "secret_intel" )
                        if count > 0 then
                            cxt.enc.scratch.knows_ace = TheGame:GetGameProfile():HasUnlock("KNOWS_BENNI_ACE")
                            cxt:Dialog("DIALOG_ASK_SUCCESS")
                            cxt:RunLoopingFn(function()
                                if cxt.enc.scratch.knows_ace then
                                    cxt:QST("ACE")
                                    if cxt.enc.scratch.asked_questions["OPT_ACE"] then
                                        cxt:QST("ACE_II")
                                    end
                                end
                                cxt:QST("ASK_OUT")
                                cxt:QST("SPOUSE")
                                cxt:QST("REWARD")

                                cxt:Opt("OPT_DONE")
                                    :MakeUnder()
                                    :Dialog("DIALOG_DONE")
                                    :CompleteQuest()
                                    :Pop()
                            end)
                        else
                            cxt:Dialog("DIALOG_ASK_SUCCESS_PARTIAL")
                            TheGame:GetGameProfile():AcquireUnlock("KNOWS_BENNI_ACE")
                            cxt:RunLoopingFn(function()
                                cxt:QST("SPOUSE")
                                cxt:QST("REWARD")

                                cxt:Opt("OPT_DONE")
                                    :MakeUnder()
                                    :Dialog("DIALOG_DONE")
                                    :CompleteQuest()
                                    :Pop()
                            end)
                        end
                    end,
                    on_fail = function(cxt,minigame)
                        cxt:Dialog("DIALOG_ASK_FAILURE")
                        cxt:GetAgent():OpinionEvent(OPINION.DEEPENED_RELATIONSHIP_FAIL)
                        cxt.quest:Fail()
                    end,
                }
        end
    end)
