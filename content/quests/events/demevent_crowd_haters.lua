local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    on_init = function(quest)

    end,
    postcondition = function(quest)
        quest.param.other_haters = {}
        local hater_count = math.random(math.ceil(quest:GetDifficulty() / 2), 1 + quest:GetDifficulty())
        for i = 1, hater_count do
            quest:AssignCastMember("hater")
            if not quest:GetCastMember("hater") then
                print("Hater not found")
                break
            end
            print("Hater: ", quest:GetCastMember("hater"))
            table.insert(quest.param.other_haters, quest:GetCastMember("hater"))
            quest.cast["hater"] = nil
        end
        return #quest.param.other_haters > 0
    end,
}
:AddCast{
    cast_id = "hater_leader",
    condition = function(agent, quest)
        return agent:GetRelationship() < RELATIONSHIP.NEUTRAL or DemocracyUtil.GetAgentEndorsement(agent) < RELATIONSHIP.NEUTRAL
    end,
}
:AddCast{
    cast_id = "hater",
    when = QWHEN.MANUAL,
    optional = true,
    condition = function(agent, quest)
        if agent:GetFaction():GetFactionRelationship( quest:GetCastMember("hater_leader"):GetFactionID() ) < RELATIONSHIP.NEUTRAL then
            return false, "Bad faction relation"
        end
        if not (agent:GetRelationship() < RELATIONSHIP.NEUTRAL or DemocracyUtil.GetAgentEndorsement(agent) < RELATIONSHIP.NEUTRAL) then
            return false, "Not bad relationship"
        end
        if agent == quest:GetCastMember("hater_leader") or quest.param.other_haters and table.arraycontains(quest.param.other_haters, agent) then
            return false, "Already casted"
        end
        return true
    end,
}

QDEF:AddConvo()
    :ConfrontState("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * As you're traveling, you run into a group of people on the way to where you're headed.
                * Upon getting closer, one of them noticed you, pointing at your direction.
                * You can see the look of disapproval in {hater_leader.hisher} face.
                player:
                    !left
                hater_leader:
                    !right
                    !angry_accuse
                    Hey everyone! Look! It's {bad_nick}!
                player:
                    !surprised
                    What? Me?
                * Oops. Looks like you accidentally confirmed that you are "{bad_nick}".
                * Lucky for you (in a way), the crowd doesn't seem to require your confirmation to know who this name refers to.
            ]],
            DIALOG_INTRO_PST = [[
                hater_leader:
                    !right
                    !angry
                * The crowd starts jeering at you. A public gathering this big with this kind of attitude towards you will not reflect well on your image.
                *** A bunch of people gathered to badmouth you.
            ]],
            OPT_IGNORE = "Ignore the crowd and move on",
            DIALOG_IGNORE = [[
                {not tried_negotiation?
                    * You don't have time for this. You duck your head and try not to show a reaction as you move past them.
                }
                {tried_negotiation?
                    * You decide to take the high road. You duck your head and try not to show a reaction as you move past them.
                }
                hater_leader:
                    !right
                    Look everyone, {bad_nick} thinks {player.heshe}'s too good for us! Isn't that right, {bad_nick}?
                * Everyone just keep throwing insults at you, which makes your mind very uneasy.
                * Now people will see you as a pathetic politician who can't even handle a bit of opposition!
                *** You lost resolve and support from enduring the insults from the crowd!
            ]],
            OPT_APPEAL = "Convince the crowd to disperse",
            DIALOG_APPEAL = [[
                player:
                    !angry
                    Will you guys listen!
                hater_leader:
                    !right
                    It looks like {bad_nick} has something to say! This should be rich.
            ]],
            DIALOG_APPEAL_SUCCESS = [[
                player:
                    I know you guys have a lot of opinions about me.
                    But still, do you think you can just gang up and harass someone you don't like?
                hater_leader:
                    !angry_accuse
                    Yeah! You deserve all that!
                player:
                    !hips
                    All you're doing is just making yourselves look like children throwing temper tantrums.
                    $miscMocking
                    "Oh! Look at me! I am a loser who fails at everything at life, so I blame everything on this one politician!"
                    Is that what you want? Because that seems to be what you are saying.
                hater_leader:
                    !crossed
                    Hmph. This is absurd!
                * Yet, you can see the crowd is getting a bit uneasy.
                * Soon, some of the crowd began to leave.
                hater_leader:
                    Wait! Where are you all going?
                    !spit
                    Hesh damn it, {bad_nick}! You've won this one. For now.
                    !exit
                * Then, seeing the tides have turned against {hater_leader.himher}, {hater_leader} leaves as well.
                * The streets of the Pearl soon become empty, free of any meddling crowds.
                player:
                    !happy
                * Just the way you like it!
            ]],
            DIALOG_APPEAL_FAILURE = [[
                player:
                    !placate
                    Let's just be civil alright?
                hater_leader:
                    !angry
                    Civil? You expect us to be civil?
                    !angry_shrug
                    After what you did? After what you are going to do to Havaria?
                    The last thing we want is to be <i>civil</>, and let you get away with all that!
                * Your attempt to calm the crowd down only seem to have fanned the flames.
                * You need to try something else!
            ]],
            OPT_USE_BODYGUARD = "Have your bodyguard disperse the crowd...",
            DIALOG_USE_BODYGUARD = [[
                {guard_sentient?
                    player:
                        !hips
                        {guard}. Clear this crowd for me, thank you.
                    guard:
                        !left
                        !salute
                        You got it, boss!
                        !overthere
                        Alright, move along, and nobody gets hurt!
                }
                {not guard_sentient and not guard_mech?
                    player:
                        !point
                        {guard}, sic 'em!
                    guard:
                        !left
                        Grrrr!
                }
                {not guard_sentient and guard_mech?
                    player:
                        !hips
                        {guard}, disperse the crowd.
                    guard:
                        !left
                        AFFIRMATIVE.
                }
                * {guard} efficiently scatters the crowd. That should keep them from talking.
            ]],
            OPT_FIGHT = "Disperse the crowd yourself",
            DIALOG_FIGHT = [[
                {not tried_negotiation?
                player:
                    !fight
                    This is what you get for calling me {bad_nick}!
                }
                {tried_negotiation?
                player:
                    !fight
                    Okay, if you barbarians don't understand what being civil means, then let me speak a language you <b>can</> understand!
                }
                hater_leader:
                    !right
                    !fight
                    Look out, {bad_nick}'s gone mad! Fend for your lives!
            ]],
            DIALOG_FIGHT_WIN = [[
                {not all_dead?
                    agent:
                        !right
                        !injured
                }
                player:
                    Had enough?
                {all_dead?
                    * The pile of corpses does not respond.
                    * How the Hesh did you even manage to kill all of them?
                    player:
                        !dust_off
                        Typical.
                    * You leave the scene, covered in the blood of so many people.
                    * This will send a powerful message to people who want to mess with you.
                }
                {not all_dead?
                    agent:
                        !injured_palm
                        Uh. Didn't know that {bad_nick} is a violent psychopath.
                    player:
                        !fight
                        I suggest you shut your trap, unless you want some more of these.
                    agent:
                        Grr...
                        !exit
                    * You sure established dominance among your enemies!
                    * Now, your enemies will think twice before messing with you!
                }
            ]],
            DIALOG_FIGHT_RUNAWAY = [[
                player:
                    !exit
                * You run away cowardly.
                hater_leader:
                    !right
                    !angry_accuse
                    Yeah! That's right! Get out of my sight, {bad_nick}!
                * This is not going to be good for your image.
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                --character-specific nicks
                cxt.quest.param.bad_nick = cxt.player:GetBadNickName()

                cxt:TalkTo(cxt:GetCastMember("hater_leader"))

                cxt:Dialog("DIALOG_INTRO")
                DemocracyUtil.QuipStance(cxt, cxt:GetCastMember("hater_leader"), nil, "heckle")
                cxt:ReassignCastMember("previous_heckler", cxt:GetCastMember("hater_leader"))
                for i, agent in ipairs(cxt.quest.param.other_haters) do
                    cxt.enc:PresentAgent( agent, SIDE.RIGHT )
                    cxt.enc:Emote( agent, "angry" )
                    DemocracyUtil.QuipStance(cxt, agent, nil, "heckle", "follow_up")
                    cxt:ReassignCastMember("previous_heckler", agent)
                end
                cxt:Dialog("DIALOG_INTRO_PST")
            end

            cxt:Opt("OPT_IGNORE")
                :Dialog("DIALOG_IGNORE")
                :DeltaSupport(-3)
                :DeltaResolve(-8)
                :Travel()

            --negotiate
            DemocracyUtil.AddBodyguardOpt(cxt, function(cxt, agent)
                cxt:ReassignCastMember("guard", agent)
                cxt.quest.param.guard_sentient = not agent:IsPet()
                cxt.quest.param.guard_mech = agent:GetSpecies() == SPECIES.MECH
                cxt:Dialog("DIALOG_USE_BODYGUARD")

                StateGraphUtil.AddLeaveLocation(cxt)
            end, "OPT_USE_BODYGUARD")

            if not cxt.quest.param.tried_negotiation then
                cxt:BasicNegotiation("APPEAL", {
                    hinders = cxt.quest.param.other_haters,
                    cooldown = 0
                })
                    :OnSuccess()
                        :Travel()
                    :OnFailure()
                        :Fn(function(cxt)
                            cxt.quest.param.tried_negotiation = true
                        end)
            end
            --FIGHT
            cxt:Opt("OPT_FIGHT")
                :Dialog("DIALOG_FIGHT")
                :Battle{
                    enemies = table.merge({cxt:GetCastMember("hater_leader")}, cxt.quest.param.other_haters),
                    on_runaway = function( cxt, battle )
                        cxt:Dialog("DIALOG_FIGHT_RUNAWAY")
                        StateGraphUtil.DoRunAwayEffects( cxt, battle )
                        DemocracyUtil.TryMainQuestFn("DeltaSupport", -3)
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                }
                    :OnWin()
                        :Fn(function(cxt)
                            cxt.quest.param.all_dead = true
                            for i, agent in ipairs(table.merge({cxt:GetCastMember("hater_leader")}, cxt.quest.param.other_haters)) do
                                if agent:IsAlive() then
                                    cxt:ReassignCastMember("survivor", agent)
                                    cxt.quest.param.all_dead = false
                                    break
                                end
                            end
                            cxt:TalkTo(cxt:GetCastMember("survivor"))
                        end)
                        :Dialog("DIALOG_FIGHT_WIN")
                        :Travel()
        end)
