local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    is_negative = true,
    precondition = function(quest)
        local can_spawn = false

        quest.param.assaulted_officer = TheGame:GetGameState():GetPlayerAgent():HasMemory("ASSAULTED_ADMIRALTY")
        if quest.param.assaulted_officer then
            quest.param.assaulted = true

            can_spawn = true
        end
        if DemocracyUtil.GetFactionEndorsement("ADMIRALTY") < RELATIONSHIP.NEUTRAL then
            quest.param.unpopular = true
            can_spawn = true
        end
        return can_spawn --or true
    end,
}
:AddOpinionEvents{

    resist_arrest =
    {
        delta = OPINION_DELTAS.DISLIKE,
        txt = "Resisted Arrest",
    },
}
QDEF:AddConvo()
    :ConfrontState("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * A purple wave of bodies confront you on the road. Badges gleam on their uniforms.
                agent:
                    !right
                player:
                    !left
                {player_drunk?
                    !drunk
                    What seems to be the officer, problem?
                agent:
                    !notepad
                    "Being drunk without a license"... I'm sure there's a reason to lock you up for that.
                    On top of everything else you've done.
                }
                {not player_drunk?
                    Is everything alright?
                agent:
                    Oh, everything's gonna be alright in the next 5 minutes.
                }
                {assaulted?
                    agent:
                        {player}, do you by chance know why we received reports of you assaulting an officer of the law?
                    player:
                        !shrug
                        Look, when that happened I had eaten a <i>lot</> of bananas, I can't be blamed for-
                    agent:
                        !notepad
                        "Improper disposal of food waste". That's worth almost as much as serial murder.
                    player:
                        !crossed
                        You guys really need to sort out your legal code.
                }
                {not assaulted?
                    agent:
                        Who do you think runs the elections? Who do you think <i>keeps the electors safe?</>
                    player:
                        !thought
                        Well I was going to say the oshnu that made it's way into my bowl but I'm assuming that's not the answer you want.
                    agent:
                        !thumb
                        It's us. <i>We</> keep the elections safe and above board.
                        And someone doesn't seem to <i>appreciate</> the hard work we've done.
                    {anti_security?
                        player:
                            !crosses
                            Uh huh. Great work you have done.
                        agent:
                            !threaten
                            Enough!
                    }
                }
                agent:
                    !threaten
                    {player}, you are under arrest for {assaulted?assaulting an Admiralty officer|defying our authority}.
                ** This event happened because you {assaulted?are wanted by the Admiralty for committing a crime|are unpopular among the Admiralty}.
            ]],
            OPT_PAY = "Bribe {agent} to let you go",
            DIALOG_PAY = [[
                player:
                    !hips
                    Well, let me ask you this.
                    !give
                    Do you think someone with <i>this</> many shills would do well in prison?
                agent:
                    !taken_aback
                    Oh, well, uhm...
                    !take
                    No, I guess you wouldn't do too well in prison.
                player:
                    !happy
                    Hmm, yes. I'm much too popular to go to prison.
                    !chuckle
                    Much too <i>beautiful</> to-
                agent:
                    !point
                    Okay, bub, you're pushing it.
                    You've bought your hide another day or two, if I can throw enough paperwork in front of it.
                    !salute
                    Be not-seeing you, {player}.
            ]],
            OPT_CONVINCE = "Convince {agent} that they got the wrong person",
            DIALOG_CONVINCE = [[
                {not assaulted?
                    player:
                        !chuckle
                        Wow. Never did I expect the misinformation mill to have the ear of the Admiralty!
                    agent:
                        !crossed
                        What are you talking about?
                }
                {assaulted?
                    player:
                        !placate
                        Let's back up a minute. I want a chance to explain.
                }
            ]],
            SIT_MOD = "The Admiralty is cautious of you",
            DIALOG_CONVINCE_SUCCESS = [[
                {not assaulted?
                    player:
                        I'll have you know that my place as a politician got me an audience with Gaft herself!
                    agent:
                        !dubious
                        You got to talk to Gaft?
                    player:
                        !eureka
                        Yes, and after I explained my positions to her, do you know what she said?
                        {advisor_diplomacy?
                                She said all my positions were "hip" and "based".
                            agent:
                                !dubious
                                ...
                            player:
                                !hips
                                Those are good things to be called, apparently.
                            agent:
                                !thought
                                That sounds uncharacteristic of Gaft.
                                !shrug
                                Then again, I don't know her personally, and I don't get paid enough to question her.
                                !salute
                                Safe travels, {player}.
                                !exit
                            * You <i>really</> need to hang around Aellon less often. He's rubbing off on you.
                        }
                        {not advisor_diplomacy?
                                !hips
                                She said I would be great for the Admiralty once I get into office.
                                Absolutely approved of my populist strategy so I could promote the Admiralty's goals while in office.
                            agent:
                                !dubious
                                With you? Doubtful.
                                !shrug
                                Then again, I don't get paid enough to question Gaft's judgement.
                                !salute
                                You have a good day, {player}.
                        }
                }
                {assaulted?
                    player:
                        !hips
                        ...Ending with the officer of the law lying on the ground, and my name cleared of guilt.
                    agent:
                        !thought
                        I never realized that a banana peel could cause that much damage.
                        And you're sure the yote dug through your trash can and spilled those peels on the ground?
                    player:
                        !happy
                        Of course I'm sure. And you can be sure that my weapons were lying haphazardly on the counter their face slammed into.
                    agent:
                        !notepad
                        Ah, yes, of course. Well, that answers all of my questions. You clearly didn't do it.
                        I'd recommend once you get into office you sign some anti-banana laws so we can prevent such mishaps like this.
                    player:
                        !salute
                        Of course, of course. You have my word.
                }
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                {not assaulted?
                    player:
                        !hips
                        I'm a massive proponent of Admiralty policy!
                    agent:
                        !dubious
                        Coming from <i>you</>? That's rich.
                        !angry_accuse
                        You can talk more about your supposed support in the interrogation room.
                }
                {assaulted?
                    player:
                        !shrug
                        Now, I'm not one to pass moral judgement but maybe... they deserved it?
                    agent:
                        !crossed
                        Whether or not they deserved it, it's up to us to judge, not you.
                        And I believe vigilantism is a crime as well.
                        !fight
                        You are coming with us either way.
                    {anti_security?
                        player:
                            !angry
                            Oh come on! You are just making up charges by this point.
                    }
                }
            ]],
            OPT_INTIMIDATE = "Scare {agent} away",
            DIALOG_INTIMIDATE = [[
                player:
                    You've got me wondering. Do Switches bleed ink, paperwork, or just plain old corruption?
            ]],
            DIALOG_INTIMIDATE_SUCCESS_SOLO = [[
                player:
                    Think about it. You've got no backup going against a trained fighter.
                    !throatcut
                    Maybe I'll get the message across if I send you home in a body bag.
                agent:
                    !crossed
                    Humph. You've got a point.
                    But I'll be back, and when I get back, I'll be bringing the whole Deltrean calvary to take you in.
                    !exit
            ]],
            DIALOG_INTIMIDATE_SUCCESS = [[
                agent:
                    !angry_point
                    You can't resist arrest! We're taking you in!
                player:
                    !humoring
                    Oh yeah? You and what army?
                * Behind {agent}, {agent.hisher} squad members quiver nervously, tentative to fight you.
                agent:
                    !angry_point
                    I'll be back for you once I have more than spineless cretins backing me up.
                * The squad sulks away, trying to not seem fazed by the daggers you stare into their backs.
                * They fail spectacularly.
            ]],
            DIALOG_INTIMIDATE_OUTNUMBER = [[
                player:
                    !angry_shrug
                    Well? You want to take me away or do you want to live?
                * You see a foot or two shuffle behind {agent}, turning away from you.
                * {agent} barely notices.
                agent:
                    !fight
                    You're still outnumbered, {player}. I'd be mighty impressed if you live long enough to reach prison after we're through.
                * Some, but not all of the squad members, step towards you, brandishing their weapons.
            ]],
            DIALOG_INTIMIDATE_FAILURE = [[
                agent:
                    !angry
                player:
                    !threaten
                    Go on, throw the first punch. Make it self defense.
                agent:
                    !fight
                    Gladly.
                player:
                    !injured
                * {agent} socks you in the gut. You stagger briefly.
                {some_ran?
                    * The routed followers see this and steel themselves.
                }
                agent:
                    !angry_point
                    News flash, it isn't self defense if we've got a warrant for your arrest.
            ]],
            DIALOG_FIGHT_WIN = [[
                {dead?
                    {assaulted?
                        * You scratch another mark into your list of switches dead at your hand.
                        * You're sure the Admiralty will notice that list getting longer. They'll be back for more.
                    }
                }
                {not dead?
                    agent:
                        !injured
                    player:
                        !angry_shrug
                        You want to take me in now? Got your handcuffs for me?
                    agent:
                        !spit
                        Resisting arrest...is a criminal offense. This...will bite you sooner rather than later.
                        !exit
                    player:
                        !handwave
                        Things always turn out to bite me. What's new here?
                }
            ]],
            OPT_RESIST = "Resist Arrest",
            DIALOG_RESIST = [[
                player:
                    !reach_weapon
                    Just try me.
            ]],
            OPT_ARREST = "Serve your sentence",
            DIALOG_ARREST = [[
                player:
                    Y'know what? Fine.
                    !permit
                    You need my wrists or would you prefer to just walk me to the station?
                agent:
                    !hips
                    Just your compliance will do. Now get a move on.
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                cxt.enc.scratch.opfor = CreateCombatParty("ADMIRALTY_PATROL", cxt.quest:GetRank() + 1, cxt.location, true)
                cxt:TalkTo(cxt.enc.scratch.opfor[1])
                cxt:Dialog("DIALOG_INTRO")
            end
            local function PostFight(cxt)
                cxt:Dialog("DIALOG_FIGHT_WIN")
                cxt.player:Remember("ASSAULTED_ADMIRALTY", cxt:GetAgent())
                if not cxt:GetAgent():IsDead() then
                    cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("resist_arrest"))
                end
                StateGraphUtil.AddLeaveLocation(cxt)
            end
            local pay_cost = 50 + 25 * cxt.quest:GetRank()
            cxt:Opt("OPT_PAY")
                :Dialog("DIALOG_PAY")
                :DeliverMoney(pay_cost)
                :Travel()
            if not cxt.quest.param.tried_convince then
                cxt:Opt("OPT_CONVINCE")
                    :ReqRelationship( RELATIONSHIP.NEUTRAL )
                    :Dialog("DIALOG_CONVINCE")
                    :Negotiation{
                        cooldown = 0,
                        situation_modifiers =
                        {
                            { value = 5 + 5 * math.floor(cxt.quest:GetRank()/2), text = cxt:GetLocString("SIT_MOD") }
                        },
                    }
                        :OnSuccess()
                            :Dialog("DIALOG_CONVINCE_SUCCESS")
                            :Travel()
                        :OnFailure()
                            :Dialog("DIALOG_CONVINCE_FAILURE")
                            :Fn(function(cxt) cxt.quest.param.tried_convince = true end)
            else
                cxt:Opt("OPT_RESIST")
                    :Dialog("DIALOG_RESIST")
                    :Battle{
                        flags = BATTLE_FLAGS.SELF_DEFENCE,
                        on_win = PostFight,
                    }
            end
            if not cxt.quest.param.tried_intimidate then
                if #cxt.enc.scratch.opfor == 1 then
                    cxt:Opt("OPT_INTIMIDATE")
                        :Dialog("DIALOG_INTIMIDATE")
                        :Negotiation{
                            cooldown = 0,
                            flags = NEGOTIATION_FLAGS.INTIMIDATION,
                        }
                            :OnSuccess()
                                :Dialog("DIALOG_INTIMIDATE_SUCCESS_SOLO")
                                :Travel()
                            :OnFailure()
                                :Dialog("DIALOG_INTIMIDATE_FAILURE")
                                :Fn(function(cxt)
                                    cxt.quest.param.tried_intimidate = true
                                    cxt:Opt("OPT_DEFEND")
                                        :Battle{
                                            flags = BATTLE_FLAGS.SELF_DEFENCE,
                                            on_win = PostFight,
                                        }
                                end)
                else
                    local allies = {}
                    for i, ally in ipairs(cxt.enc.scratch.opfor) do
                        if i ~= 1 then
                            table.insert(allies, ally)
                        end
                    end
                    cxt:Opt("OPT_INTIMIDATE")
                        :Dialog("DIALOG_INTIMIDATE")
                        :Negotiation{
                            cooldown = 0,
                            flags = NEGOTIATION_FLAGS.INTIMIDATION | NEGOTIATION_FLAGS.ALLY_SCARE,
                            enemy_resolve_required = 8 + cxt.quest:GetRank() * 10,
                            fight_allies = allies,
                            on_success = function(cxt, minigame)
                                local keep_allies = {}
                                for i, modifier in minigame:GetOpponentNegotiator():Modifiers() do
                                    if modifier.id == "FIGHT_ALLY_SCARE" and modifier.ally_agent then
                                        table.insert( keep_allies, modifier.ally_agent )
                                    end
                                end

                                for k,v in pairs(allies) do
                                    if not table.arrayfind(keep_allies, v) then
                                        v:MoveToLimbo()
                                    end
                                end
                                if #keep_allies == 0 or (DemocracyUtil.CalculatePartyStrength(cxt.player:GetParty()) >= DemocracyUtil.CalculatePartyStrength(cxt:GetAgent():GetParty()) ) then
                                    cxt:Dialog("DIALOG_INTIMIDATE_SUCCESS")
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                else
                                    cxt:Dialog("DIALOG_INTIMIDATE_OUTNUMBER")
                                    cxt:Opt("OPT_DEFEND")
                                        :Battle{
                                            flags = BATTLE_FLAGS.SELF_DEFENCE,
                                            on_win = PostFight,
                                        }
                                end
                                -- print("Party members you have: ", TheGame:GetGameState():GetCaravan():GetPartyCount())
                                -- if #keep_allies <= TheGame:GetGameState():GetCaravan():GetPartyCount() then
                                --     cxt:Dialog("DIALOG_INTIMIDATE_SUCCESS")
                                -- else

                                -- end
                            end,
                            on_fail = function(cxt,minigame)
                                cxt.enc.scratch.some_ran = not (minigame:GetOpponentNegotiator():FindCoreArgument() and minigame:GetOpponentNegotiator():FindCoreArgument():GetShieldStatus())
                                cxt:Dialog("DIALOG_INTIMIDATE_FAILURE")
                                cxt.quest.param.tried_intimidate = true
                                cxt:Opt("OPT_DEFEND")
                                    :Battle{
                                        flags = BATTLE_FLAGS.SELF_DEFENCE,
                                        on_win = PostFight,
                                    }
                            end,
                        }
                end
            end
            cxt:Opt("OPT_ARREST")
                :Dialog("DIALOG_ARREST")
                :Fn(function(cxt)
                    local flags = {
                        suspicion_of_crime = true,
                    }
                    DemocracyUtil.DoEnding(cxt, "arrested", flags)
                end)
        end)
