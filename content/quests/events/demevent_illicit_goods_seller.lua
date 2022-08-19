local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}
:AddCast{
    cast_id = "jakes",
    condition = function(agent, quest)
        return agent:GetFactionID() == "JAKES"
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( quest:GetRank() < 3 and "JAKES_RUNNER" or "JAKES_SMUGGLER") )
    end,
}

QDEF:AddConvo()
    :ConfrontState("CONF")
        :Loc{
            DIALOG_INTRO = [[
                * You come across a Jakes, who looks very pleased to see you.
                * Overtly friendly people in Havaria are usually bad signs, so you don't know what to make of this situation.
                player:
                    !left
                agent:
                    !right
                    !happy
                    Hey there, pal! You look like someone who likes to party.
                {player_drunk?
                        Smell like one too!
                    * You do have a strong smell of alcohol coming out of your breath.
                    player:
                        !drunk
                    {player_smith?
                        Parties are the best! I love them!
                    }
                    {not player_smith?
                        I assure you, all the drinks I've been having? It's all for business.
                    agent:
                        !handwave
                        Sure. <i>party</> business.
                    }
                }
                {not player_drunk?
                    {player_smith?
                        player:
                            Did someone mention parties? I love parties!
                        * When {agent} say "party", {agent.gender:he actually means|she actually means|they actually mean} "drinking alcohol".
                        * Uncharacteristically, you haven't done a lot of that for a while.
                    }
                    {not player_smith?
                        player:
                            !dubious
                            Wait, when you say "party", do you mean...
                        * Yes, {agent.gender:he does|she does|they do} mean "drinking alcohol".
                        * You haven't done a lot of that for a while, though.
                    }
                }
                agent:
                    !happy
                    Excellent!
                    If you like party so much, I can make you party <i>harder</>.
                    I have just the thing...
                * When these kind of people say "party harder", it can only mean one thing...
            ]],
            OPT_LOOK = "Look at {agent}'s wares...",
            DIALOG_LOOK = [[
                player:
                    Let's see what you have...
            ]],
            DIALOG_LOOK_NO_BUY = [[
                player:
                    Wait, these are all highly addictive and probably illegal substances.
                agent:
                    !handwave
                    Ha! Those who made them illegal knows nothing of partying.
            ]],
            OPT_BUY = "Buy {1#card}",
            DIALOG_BUY = [[
                player:
                    I'll buy the {1#card}.
                agent:
                {vial_of_slurry_negotiation?
                    Good choice. It's not a party without these bad boys.
                }
                {speed_tonic_negotiation?
                    Ooh! These make you party non-stop!
                }
                {vapor_vial_negotiation?
                    I like this one. That gives you a good trip.
                }
            ]],
            OPT_ASK_SOURCE = "Ask for source of the goods",
            DIALOG_ASK_SOURCE = [[
                player:
                    Where can I get more of these stuff?
                agent:
                    Me! If you want more, you can get it from me!
                player:
                    Yeah, but where do you get all these from?
                agent:
                    Also me! I get these stuff on my own!
                    You don't need to worry about all that.
                {many_arrests_made?
                    * You are not going to make {agent.himher} rat out {agent.hisher} sources, that's for sure.
                }
                {not many_arrests_made?
                    * Well, seems like {agent.gender:he is|she is|they are} not going to tell you {agent.hisher} sources.
                }
            ]],
            DIALOG_DONE_NO_BUY = [[
                player:
                    !handwave
                    No thanks. I don't think I need anything from you.
                agent:
                    It's okay. I understand not everyone wants to party this hard.
            ]],
            DIALOG_DONE_BUY = [[
                player:
                    That's it for now.
                agent:
                    !happy
                    Have a good day, and have a greater party!
            ]],
            OPT_CONVINCE = "Convince {agent} to stop selling these illicit substances",
            DIALOG_CONVINCE = [[
                player:
                    !thumb
                    Look, maybe you should cut down on selling these things?
                agent:
                {not bought_goods?
                    What? Come on! You're no fun!
                }
                {bought_goods?
                    What? Come on! You already bought some of my goods, and now you want me to stop selling them?
                }
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                player:
                    Look, you know these things are bad for people's health right?
                    Don't you feel it's irresponsible for you to ruin people's lives with substances like these?
                agent:
                    !handwave
                    Yeah, yeah. I heard you alright.
                    I will try not to sell these things, alright?
                    !humouring
                    $happyJoke
                    For you, dear upstanding citizen!
                player:
                    !dubious
                * Somehow you are not convinced that {agent} is actually going to stop selling these illicit substances.
                * {agent.gender:He is|She is|They are} not going to give up {agent.hisher} livelihood just by you persuading {agent.himher} not to.
                * Still, at least you tried to convince {agent.himher}. That's going to look good on your campaign.
                {many_arrests_made?
                    * But support is not enough!
                    * This scoundrel think that {agent.heshe} can poison the public without consequences?
                    * Arrest {agent.himher}! Do your duty as an "upstanding citizen"!
                }
                *** {agent} seems to be convinced, but is probably not going to stop selling.
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                player:
                    These are illegal!
                agent:
                {mentioned_illegal?
                    !handwave
                    Ha! Those who made them illegal knows nothing of partying.
                }
                {mentioned_illegal?
                    Like I said, those who made them illegal knows nothing of partying.
                }
                * I don't think the Jakes cares about legality too much, so your argument is never going to work.
                {many_arrests_made?
                    * They should. Because you are going to arrest them for their illegal activities, like you've done so for other criminals.
                }
            ]],
            SIT_MOD_BOUGHT = "You bought goods from {agent}",
            OPT_ARREST = "Confront them about dealing with drugs...",
            DIALOG_ARREST = [[
                player:
                    !suspicious
                {mentioned_illegal?
                    Since you know these are illegal, surely you know the consequence if the wrong person sees this?
                }
                {not mentioned_illegal?
                    Lots of interesting items you are selling. You know what happens when the wrong person sees this?
                }
                agent:
                    !dubious
                    What do you mean?
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                cxt.quest.param.stock = { "speed_tonic_negotiation", "vial_of_slurry_negotiation", "vapor_vial_negotiation" }
                cxt:TalkTo(cxt:GetCastMember("jakes"))

                cxt:Dialog("DIALOG_INTRO")
            end
            cxt:QST("ASK_SOURCE")

            if #cxt.quest.param.stock > 0 and not cxt.quest.param.tried_convince then
                cxt:Opt("OPT_LOOK")
                    :Dialog("DIALOG_LOOK")
                    :LoopingFn(function()
                        for i, id in ipairs(cxt.quest.param.stock) do
                            local price = Util.GetCardPrice(id)

                            local opt = cxt:Opt("OPT_BUY", id)
                                :Fn(function(cxt)
                                    cxt.enc.scratch[id] = true
                                end)
                                :Dialog("DIALOG_BUY", id)
                                :Fn(function(cxt)
                                    cxt.enc.scratch[id] = false
                                end)

                            if not cxt.quest.param.bought_goods then
                                opt:UpdatePoliticalStance("SUBSTANCE_REGULATION", -1)
                            end

                            opt:DeliverMoney( price, { is_shop = true } )
                                :Fn(function(cxt)
                                    cxt:ForceTakeCards{id}
                                    cxt.quest.param.bought_goods = true
                                    table.arrayremove(cxt.quest.param.stock, id)
                                    if #cxt.quest.param.stock == 0 then
                                        cxt:Pop()
                                    end
                                end)
                        end
                        cxt:Opt("OPT_BACK_BUTTON")
                            :Fn(function(cxt)
                                if not cxt.quest.param.bought_goods and not cxt.quest.param.seen_goods then
                                    cxt:Dialog("DIALOG_LOOK_NO_BUY")
                                    cxt.quest.param.mentioned_illegal = true
                                end
                                cxt.quest.param.seen_goods = true
                            end)
                            :Pop()
                            :MakeUnder()
                    end)
            end

            cxt:Opt("OPT_CONVINCE")
                :Dialog("DIALOG_CONVINCE")
                :UpdatePoliticalStance("SUBSTANCE_REGULATION", 1)
                :Negotiation{
                    situation_modifiers =
                    {
                        cxt.quest.param.bought_goods and { value = 10, text = cxt:GetLocString("SIT_MOD_BOUGHT") }
                    },
                }
                    :OnSuccess()
                        :Dialog("DIALOG_CONVINCE_SUCCESS")
                        :DeltaSupport(2)
                        :Fn(function(cxt)
                            cxt.quest.param.tried_convince = true
                            cxt.quest.param.convince_success = true
                        end)
                    :OnFailure()
                        :Dialog("DIALOG_CONVINCE_FAILURE")
                        :Fn(function(cxt)
                            cxt.quest.param.tried_convince = true
                            cxt.quest.param.mentioned_illegal = true
                        end)

            if not cxt.quest.param.did_confront then
                cxt:Opt("OPT_ARREST")
                    :Dialog("DIALOG_ARREST")
                    :GoTo("STATE_ARREST")
            end

            cxt:Opt("OPT_DONE")
                :MakeUnder()
                :Fn(function(cxt)
                    if cxt.quest.param.bought_goods then
                        cxt:Dialog("DIALOG_DONE_BUY")
                    else
                        cxt:Dialog("DIALOG_DONE_NO_BUY")
                    end
                end)
                :Travel()
        end)
    :State("STATE_ARREST")
        :Loc{
            DIALOG_BACK = [[
                player:
                {tried_intimidate?
                    Okay, y'know what. You got me.
                    I was just trying to spook you.
                agent:
                    !crossed
                    $neutralWhatever
                    Haha, very funny. You should get a job as a clown.
                }
                {not tried_intimidate?
                    I'm just saying. You don't want the wrong person to see you sell these things.
                agent:
                    Yes, yes, of course. I got you, pal.
                }
            ]],
            OPT_INTIMIDATE = "Intimidate them to come willingly",
            DIALOG_INTIMIDATE = [[
                player:
                    !cruel
                    If you are smart, you should come with me!
                agent:
                {not bought_goods?
                    What are you, a switch?
                }
                {bought_goods?
                    After you bought my goods? Really?
                }
            ]],
            DIALOG_INTIMIDATE_SUCCESS = [[
                player:
                    Selling drugs is a serious crime.
                {bought_goods?
                        Thanks to you, I have plenty of evidence.
                        !cruel
                        After all, you sold them to me yourself.
                    agent:
                        !spit
                        Damn it. I can't believe this is your plan all along.
                    * You don't plan on using the drugs as evidence, anyway.
                    * The Admiralty doesn't care much about evidence, and it's better if you use them, anyway.
                }
                player:
                    !hips
                    If you cooperate, I don't know, maybe that will be a mitigating factor to your sentence.
                agent:
                    !angry_shrug
                    Uh, you're no fun.
                * You bring {agent} to a nearby Admiralty patrol.
            ]],
            DIALOG_INTIMIDATE_FAILURE = [[
                agent:
                    !chuckle
                    Real funny joke, pal.
                    You don't have power over anything. You can't arrest people.
            ]],
            OPT_ARREST = "Arrest them with force",
            DIALOG_ARREST = [[
                {tried_intimidate?
                    player:
                        !fight
                        Think again.
                }
                {not tried_intimidate?
                    player:
                        That wrong person is me.
                        !fight
                        And you are getting arrested.
                }
            ]],
            DIALOG_ARREST_WIN = [[
                {jakes_dead?
                    * {agent} lies dead on the ground.
                    * One less criminal poisoning the public.
                }
                {not jakes_dead?
                    player:
                        !angry_accuse
                        Well, feeling compliant now?
                    agent:
                        !injured_palm
                        Uh, fine. You're no fun.
                    * You bring {agent} to a nearby Admiralty patrol.
                }
            ]],
            OPT_USE_BODYGUARD = "Let a bodyguard arrest them...",
            DIALOG_USE_BODYGUARD = [[
                player:
                {tried_intimidate?
                    I can't arrest people, but I know someone else who can.
                    Isn't that right, {guard}?
                }
                {not tried_intimidate?
                    Wrong person like, say, {guard} over here?
                }
                guard:
                    !left
                    Alright. Come along now, and nobody gets hurt.
                agent:
                    !surprised
                    What? Where did you came from?
                guard:
                    !dubious
                {not (tried_intimidate or tried_convince)?
                    Seriously? I was with {player} the whole time.
                }
                {tried_intimidate or tried_convince?
                    Seriously? I was literally shaking you down a moment ago!
                }
                    How did you not notice?
                * {agent} either has {agent.hisher} head too high up {agent.hisher} arse to notice, or is simply too high.
                    !fight
                    Anyway, you're coming with me!
                agent:
                    Uh, fine. You're no fun.
                    !exit
                guard:
                    !exit
                * You let {guard} take away {agent}.
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest.param.did_confront = true
            end

            local function DoArrest(cxt, hate_target)
                if cxt:GetCastMember("jakes"):IsAlive() then
                    cxt:GetCastMember("jakes"):GainAspect("stripped_influence", 5)
                    cxt:GetCastMember("jakes"):OpinionEvent(OPINION.SOLD_OUT_TO_ADMIRALTY, nil, hate_target)
                    cxt:GetCastMember("jakes"):Retire()
                end
                DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 3)
                DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 5, "ADMIRALTY")
                DemocracyUtil.DeltaGameplayStats("ARRESTED_PEOPLE_TIMES", 1)
            end

            cxt:Opt("OPT_INTIMIDATE")
                :Dialog("DIALOG_INTIMIDATE")
                :UpdatePoliticalStance("SECURITY", 2)
                :Negotiation{
                    target_agent = cxt:GetCastMember("jakes"),
                    flags = NEGOTIATION_FLAGS.INTIMIDATION,
                }
                    :OnSuccess()
                        :Dialog("DIALOG_INTIMIDATE_SUCCESS")
                        :Fn(function(cxt)
                            DoArrest(cxt)
                        end)
                        :Travel()
                    :OnFailure()
                        :Dialog("DIALOG_INTIMIDATE_FAILURE")
                        :Fn(function(cxt)
                            cxt.quest.param.tried_intimidate = true
                        end)

            cxt:Opt("OPT_ARREST")
                :UpdatePoliticalStance("SECURITY", 2)
                :Dialog("DIALOG_ARREST")
                :Battle{
                    enemies = {cxt:GetCastMember("jakes")},
                }
                    :OnWin()
                        :Fn(function(cxt)
                            cxt.quest.param.jakes_dead = cxt:GetCastMember("jakes"):IsDead()
                            cxt:Dialog("DIALOG_ARREST_WIN")
                            DoArrest(cxt)
                        end)
                        :Travel()

            DemocracyUtil.AddBodyguardOpt(cxt, function(opt, agent, is_sentient, is_mech)
                opt:UpdatePoliticalStance("SECURITY", 2)
                    :Fn(function(cxt)
                        cxt:ReassignCastMember("guard", agent)
                        cxt:Dialog("DIALOG_USE_BODYGUARD")
                        agent:Dismiss()
                        DoArrest(cxt, agent)
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end)
            end, nil, function(agent) return agent:GetFactionID() == "ADMIRALTY" and agent:IsSentient() end)

            cxt:Opt("OPT_BACK_BUTTON")
                :Dialog("DIALOG_BACK")
                :Pop()
                :MakeUnder()
        end)
