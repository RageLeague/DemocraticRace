local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    is_negative = true,
}
:AddDefCastSpawn("priest", "LUMINITIATE")
:AddOpinionEvents{
    listened_lecture = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Listened to their lecture",
    },
}

QDEF:AddConvo()
    :ConfrontState("CONF")
        :Loc{
            DIALOG_INTRO = [[
                * You are minding your own business when a luminitiate spots you.
                player:
                    !left
                agent:
                    !right
                    !hesh_greeting
                    Greetings. Would you lend an ear to the good words of the Cult?
                * The Cult is start using luminitiates to spread their religion now?
            ]],
            OPT_ACCEPT = "Listen to {agent}",
            DIALOG_ACCEPT = [[
                player:
                    Sure. Let's hear what you have to say about it.
                agent:
                    !surprised
                    Really?
                    !happy
                    I mean, I am glad you are curious!
                    Well, to start with, the Cult of Hesh is...
                    ...
            ]],
            DIALOG_ACCEPT_II = [[
                * Oh dear, it's going to take a while.
                agent:
                    ...
                * {agent} barely started talking, and you already blanked out.
                agent:
                    ...
                * And there is no sign of stopping either.
                agent:
                    ...
                * Is this how this all ends? Listening to a luminitiate preaching about the Cult?
                agent:
                    ...
                * This has to end eventually, right?
                agent:
                    ...
                * Right?
                agent:
                    ...
                * Wow, there sure is a lot of good words about the Cult.
                agent:
                    ...
                * Maybe the Cult isn't as bad as you thought, just judging by the shear amount of words coming out of {agent}'s mouth.
                agent:
                    ...
                * Not like you caught any of that. You're blanked out, remember?
                agent:
                    ...
                * So, how is your day?
                agent:
                    ...
                * I hope it's going well.
                agent:
                    ...
                * Well, if not, there is no way I can tell anyway.
                agent:
                    ...
                * {agent} is still talking, huh?
                agent:
                    ...
                * So, you want to hear about the <!negotiationcard_rise_manifesto>Rise Manifesto</>?
                agent:
                    ...
                * I mean, you're not busy doing anything else, so...
                agent:
                    ...
                * Not funny? Okay, fair enough.
                agent:
                    ...
                * Wait, hold on, I think {agent} finally stopped.
                * You can wake up now.
            ]],
            DIALOG_ACCEPT_II_SKIP = [[
                * Oh dear, it's going to take a while.
                * Not like you care. You skipped the entire thing.
            ]],
            DIALOG_ACCEPT_III = [[
                agent:
                    So... Do you feel like you understand what the Cult tries to do a bit better now?
                player:
                    !cagey
                    What? Oh, uh, I mean...
                    !bashful
                    Yes! Of course! That was a really in-depth explanation!
                agent:
                    It's really only a brief summary of all the good deeds the Cult does.
                    I can give you a more detailed explanation if you-
                player:
                    !placate
                    No, thank you. I think I will look it up in my own time.
                agent:
                    !agree
                    Still, I am glad you kept an open mind.
                    !happy
                {disliked?
                    Looks like I misjudged you, {player.gender:brother|sister|sibling}.
                }
                {not disliked?
                    It's hard to find open-minded people these days.
                }
                * {agent} seems pretty content that you listened to {agent.himher}.
                * Good for {agent.himher}. It's definitely not good for you.
                * You are going to need a drink after hearing all that.
            ]],
            OPT_REJECT_DIRECTLY = "Reject directly",
            DIALOG_REJECT_DIRECTLY = [[
                player:
                    !handwave
                    Sorry. Not interested.
                agent:
                    !crossed
                    How typical.
                    Havaria is full of close minded individuals like you.
                    You can never have salvation with mindset like this.
                player:
                    I don't care.
                    !exit
                * You leave the luminitiate, perfectly content with your "closed mind".
                * {agent} looks less than content, though.
            ]],
            OPT_CONVINCE = "Convince {agent} that you already know these stuff",
            DIALOG_CONVINCE = [[
                player:
                    !placate
                    There is no need. I already know the good things done by the Cult.
                agent:
                {not anti_religious_policy?
                    Is that so?
                }
                {anti_religious_policy?
                    !crossed
                    For some reason I find that hard to believe.
                }
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                player:
                    !overthere
                    After all, although we all have different backgrounds, one thing unites us all:
                    The inevitability of death, and of our consumption by Hesh.
                agent:
                    !hips
                    That is certainly an interesting perspective. Sounds like you really know your stuff.
                * Oh no, you know nothing about what you just spoke.
                * You just put a bunch of Heshian sounding words together and hope it fools {agent}.
                * It seems like it did.
                agent:
                    Given that you already know so much about the Cult, you don't need to tell me about it then.
                    Have a good day then, {player.gender:brother|sister|sibling}.
                    !exit
                * Phew. Looks like you aren't going to waste time listening to {agent.hisher} lecture.
                * You did waste a lot of time convincing {agent.himher} not to, though.
                * Still better than a Heshian lecture, though.
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                player:
                    The Cult... provides job for people, I guess?
                agent:
                    !dubious
                    What, do you think we are Barons?
                    We don't provide <i>jobs</> for people.
                {player_sal?
                    * Either {agent.gender:he's|she's|they're} saying that the things you did on the derricks aren't real jobs, or you are not a person.
                    * You are not sure which explanation you hate more.
                }
                agent:
                    Seems like you still have a lot to learn.
                    Would you like to know a bit more about the Cult?
            ]],
            OPT_DEBATE = "Debate {agent} about the Cult",
            DIALOG_DEBATE = [[
                player:
                    !crossed
                    "Good words"? You want to hear about what good the Cult actually does?
            ]],
            DIALOG_DEBATE_SUCCESS = [[
                player:
                    !angry_accuse
                    The Cult rules through intimidation, not love!
                    The only reason Havarians seem to support the Cult is because of fear for eternal damnation!
                    Fear for what the enforcer will do to them if they don't comply!
                {player_sal?
                    I know this personally.
                    They force you to work on the derricks for their own profits, with no consideration for those they forced to work.
                }
                {player_arint?
                    I was a luminari once. I know all too well about the Cult's inner working.
                }
                    !hips
                    The Cult does good you say? What a bold-faced lie!
                agent:
                    That is not Hesh's teaching-
                player:
                    !angry_shrug
                    Hesh doesn't teach anything! It's a giant jellyfish living in the sea!
                    People teach these things.
                    And what does the Cult teach?
                    They teach us that they are just a bunch of fanatical cultists wanting to rule Havaria under the name of some random jellyfish.
                agent:
                    !scared
                    I-
                * You can see that your grand speech starts to cause {agent} to question {agent.hisher} faith.
                * However, {agent.hisher} doubt soon turns into resolution.
                agent:
                    !angry
                    I knew it! They hate our very existence. Our way of life.
                    Demean us, harass us, calling us cultists.
                player:
                    But you are literally in-
                agent:
                    !angry_accuse
                    But you will never extinguish our faith, heretic!
                    !exit
                * {agent} storms off.
                player:
                    !shrug
                * {agent} is a lost cause. You can't win against these people, not with mental gymnastics like that.
                *** You win the argument, but that has somehow strengthened {agent}'s faith.
            ]],
            DIALOG_DEBATE_FAILURE = [[
                player:
                    But what about all the terrible things done by Heshians?
                agent:
                    Hesh does not condone those types of actions.
                    Anyone doing these things under its name are not real Heshians.
                * A truly convenient situation for the Cult.
                * However, if the terrible things you mentioned aren't done by real Heshians, then surely your original argument is moot?
                * You can't think of a counterargument.
                agent:
                    It seems like you still have a lot of misconceptions about the Cult.
                    Would you like me to correct some of that?
                *** You fail to win the argument, and {agent} insists on lecturing you about the Cult.
            ]],
            SIT_MOD = "Your opinion of {1#pol_issue} is {2#pol_stance}",
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                cxt:TalkTo(cxt:GetCastMember("priest"))

                cxt:Dialog("DIALOG_INTRO")
            end
            if not cxt.quest.param.tried_debate and not cxt.quest.param.tried_convince then
                cxt:Opt("OPT_DEBATE")
                    :Dialog("DIALOG_DEBATE")
                    :UpdatePoliticalStance("RELIGIOUS_POLICY", -2)
                    :Negotiation{

                    }
                        :OnSuccess()
                            :Dialog("DIALOG_DEBATE_SUCCESS")
                            :DeltaSupport(3)
                            :ReceiveOpinion(OPINION.INSULT)
                            :Travel()
                        :OnFailure()
                            :Dialog("DIALOG_DEBATE_FAILURE")
                            :Fn(function(cxt)
                                cxt.quest.param.tried_debate = true
                            end)
                local stance = DemocracyUtil.TryMainQuestFn("GetStance", "RELIGIOUS_POLICY" ) or 0
                cxt:Opt("OPT_CONVINCE")
                    :Dialog("DIALOG_CONVINCE")
                    :UpdatePoliticalStance("RELIGIOUS_POLICY", 1)
                    :Negotiation{
                        situation_modifiers = { stance ~= 0 and { value = -10 * stance, text = cxt:GetLocString("SIT_MOD", "RELIGIOUS_POLICY", "RELIGIOUS_POLICY_" .. stance) } or nil}
                    }
                        :OnSuccess()
                            :Dialog("DIALOG_CONVINCE_SUCCESS")
                            :ReceiveOpinion(OPINION.HAD_MEANINGFUL_DISCUSSION)
                            :Travel()
                        :OnFailure()
                            :Dialog("DIALOG_CONVINCE_FAILURE")
                            :Fn(function(cxt)
                                cxt.quest.param.tried_convince = true
                            end)
            end
            cxt:Opt("OPT_ACCEPT")
                :Dialog("DIALOG_ACCEPT")
                :Fn(function(cxt)
                    cxt:FadeOut()
                    local old_music = TheGame:GetMusic().music_event_name
                    if cxt.enc:GetScreen():IsAutoSkip() then
                        cxt:Dialog("DIALOG_ACCEPT_II_SKIP")
                    else
                        TheGame:GetMusic():StopMusic()
                        cxt:Dialog("DIALOG_ACCEPT_II")
                    end
                    cxt:Wait()
                    TheGame:GetMusic():PlayMusic(old_music)
                    cxt:FadeIn()
                end)
                :Dialog("DIALOG_ACCEPT_III")
                :DeltaResolve( -10 )
                :ReceiveOpinion("listened_lecture")
                :RequireFreeTimeAction(3, nil, true)
                :Travel()

            cxt:Opt("OPT_REJECT_DIRECTLY")
                :Dialog("DIALOG_REJECT_DIRECTLY")
                :ReceiveOpinion(OPINION.INSULT)
                :Travel()
        end)
