local insult_card = "insult"

local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    precondition = function(quest)
        return TheGame:GetGameState():GetCaravan():GetPet() ~= nil
    end,
}

:AddCast{
    cast_id = "admiralty",
    condition = function ( agent, quest )
        return agent:GetContentID() == "ADMIRALTY_PATROL_LEADER" and agent:GetRelationship() <= RELATIONSHIP.NEUTRAL
    end
}
:AddCastFallback
{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( "ADMIRALTY_PATROL_LEADER" ) )
    end,
}

:AddCast{
    cast_id = "pet",
    no_validation = true,
    cast_fn = function ( quest, t )
        table.insert (t, TheGame:GetGameState():GetCaravan():GetPet())
    end,
    on_assign = function(quest, agent)
        quest.param.is_mech = agent:GetSpecies() == SPECIES.MECH
    end,
}


QDEF:AddConvo():ConfrontState("CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * You're stopped by an Admiralty patrol, who seem fixated upon your {is_mech?mech|animal companion}.
                player:
                    !left
                agent:
                    !right
                agent:
                    Do you have a license for that {is_mech?mech|animal}?
                    It's a new bylaw, but unlicensed {is_mech?mechs|animals} are to be seized for the Deltrean state.
            ]],
            OPT_PAY = "Pay for the dubious 'license'",
            DIALOG_PAY = [[
                player:
                    !sigh
                    A new bylaw, is it?
                    So it's reasonable that I haven't heard of it?
                agent:
                    !dubious
                    $neutralDubious
                    Well, yes, I suppose. But the notice has been posted in the New Deltree headquarters for three weeks.
                player:
                    Can I simply pay you for a license?
                agent:
                    Well, that's not really how—
                player:
                    !interest
                    $neutralDirect
                    No, you misunderstand. Can I simply <i>pay you</i> for a "license"?
                agent:
                    Oh. Oh!
                    !placate
                    I've never—
                    Well, yes. Sure. Why not?
                player:
                    !give
                    $neutralJoke
                    Congratulations on this exciting milestone.
                agent:
                    !take
                    Yes. Likewise. Enjoy your beast, grifter.
                    !exit
            ]],
            DIALOG_PST_PET =
            [[
                {not is_mech?
                    pet:
                        !right
                    * {pet} looks up at you, tongue hanging lazily to one side.
                    player:
                        !happy
                        You're a good {pet.boygirl}, {pet}.
                    * {pet} looks like {pet.heshe} agrees.
                }
                {is_mech?
                    pet:
                        !right
                    * {pet} looks up at you, standing motionlessly.
                    player:
                        !happy
                        I'm so happy that you are by my side, {pet}.
                    * {pet} looks like {pet.heshe} agrees. Somehow.
                }
            ]],

            OPT_HAND_OVER_PET = "Hand over {pet}",
            DIALOG_HAND_OVER = [[
                * You turn to {pet}.
                pet:
                    !right
                player:
                    !permit
                    Well, I guess this is where we part ways, {pet}.
                    I'm sure the nice switch will take good care of you.
            ]],
            DIALOG_HAND_OVER_2 = [[
                pet:
                    !exit
                * {agent} shoves {pet} into a rough burlap sack, despite snarls of protest.
                player:
                    !dubious
                    Ah. I guess not.
            ]],
            DIALOG_HAND_OVER_3 = [[
                agent:
                    !right
                    Right, then. We'll see this {is_mech?mech|animal} is put to good use.
                    !salute
                    As you were, civilian.
                    !exit
            ]],




            OPT_CONVINCE = "Convince {agent} you don't need a license",
            DIALOG_CONVINCE = [[
                player:
                    Surely we can come to some kind of alternate arrangement?
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                player:
                    For example, say I hand over this {is_mech?mech|animal}.
                    And say it rips your throat out...
                agent:
                    Rips my throat out? Why would—
                {not is_mech?
                    player:
                        Well, it's a wild animal.
                        I know it might seem like my pet, but really it's just been following me around for a spell.
                        Seems to like me enough for now, but who knows? Maybe that'll change.
                }
                {is_mech?
                    player:
                        Well, it's a malfunctioning mech.
                        I know it might seem like my mech, but really it's just been following me around for a spell.
                        Seems to like me enough for now, but who knows? Maybe that'll change.
                }
                agent:
                    Ah, well...
                    If it's a {is_mech?<i>malfunctioning</i> mech|<i>wild</i> beast}...
                    Then I suppose it's exempt.
                    !salute
                    As you were, civilian.
                    !exit
            ]],
            DIALOG_CONVINCE_FAIL = [[
                player:
                {not is_mech?
                    {pet} here has very special dietary needs. Allergic to just about everything.
                }
                {is_mech?
                    {pet} here has very special needs. Needs direct command when it needs to do just about anything.
                }
                    Surely it—
                agent:
                    !crossed
                    No exceptions.
                    It's your duty as a soon-to-be Deltrean Citizen to obey the law and serve your nation.
            ]],
            OPT_INSULT_ADMIRALTY = "Argue against the Admiralty's rulership over Havaria",
            TT_INSULT = "You will start with some {1#card} in your deck.",
            DIALOG_INSULT_ADMIRALTY = [[
                player:
                    [p] You don't own this place, switch.
            ]],
            OPT_INSULT_DELTREE = "Argue against Deltree's claim over Havaria",
            DIALOG_INSULT_DELTREE = [[
                player:
                    [p] Go kiss Deltrean butt in Deltree. This is Havaria.
            ]],
            DIALOG_INSULT_SUCCESS = [[
                agent:
                    [p] Why you...!
                    I will arrest you this instance!
                player:
                    Go ahead. Arrest me.
                    See how these people think.
                agent:
                    These people... huh?
                * {agent} looks around and sees a bunch of eyes on the commotion.
                player:
                    I wonder if these people would vote for the Admiralty if you arrest me and show your tyrannical side.
                agent:
                    Tsh. Fine. Keep your {is_mech?mech|pet}, then. Doesn't matter to me anyway.
                    Know this: the Deltrean Admiralty will take over Havaria. Mark my words.
                    !exit
                player:
                    Hah! I would like to see you try!
            ]],
            DIALOG_INSULT_FAILURE = [[
                agent:
                    [p] That's it, you are getting arrested!
            ]],

            OPT_FIGHT = "Fight to keep {pet}",
            DIALOG_FIGHT = [[
                player:
                    !fight
                    You touch my {pet} and I'll turn you into kibble.
            ]],

            DIALOG_FIGHT_AGENT_DEAD_PET_DEAD = [[
                player:
                    !left
                    !sad
                * Both {agent} and {pet} lie dead at your feet.
                player:
                    Shucking Hesh.
                    !facepalm
                    Goodbye, {pet}. You were a good {pet.boygirl}.
                    May you gut your enemies in whatever afterlife awaits you.
                {is_mech?
                    If an afterlife exist for mechanical beings such as yourself.
                }
            ]],
            DIALOG_FIGHT_AGENT_ALIVE_PET_DEAD = [[
                player:
                    !left
                agent:
                    !right
                    !injured
                player:
                    !angry
                    You killed {pet}!
                agent:
                    I believe <i>you</i> {is_mech?destroyed your mech|killed your pet}, actually, by not having appropriate documentation.
                player:
                    I am going to count to ten. And if you're still here by the time I'm done...
                * You don't need to finish your threat. {agent} sees the look in your eyes and quickly makes {agent.hisher} exit.
                agent:
                    !exit
            ]],

            DIALOG_FIGHT_AGENT_DEAD_PET_ALIVE = [[
                player:
                    !left
                {not is_mech?
                    * {agent} is dead. {pet} sniffs {agent.hisher} corpse.
                    player:
                        Don't eat that, {pet.boygirl}. You don't know where it's been.
                    * You give {pet} a pat on the head before the two of you continue on your way.
                }
                {is_mech?
                    * {agent} is dead.
                    * You and {pet} continue on your way.
                }
            ]],
            DIALOG_FIGHT_AGENT_ALIVE_PET_ALIVE = [[
                player:
                    !left
                agent:
                    !right
                    !injured
                player:
                    !angry
                    I'm letting you off with a warning. And you can share it with the other switches.
                    $angrySeething
                    Don't ever come between someone and their pet.
                    Ask yourself if a new bylaw is really worth dying for.
                * You click your tongue for {pet} to fall in step, and the two of you leave {agent} to contemplate what you've said.
                agent:
                    !exit
            ]],
        }

        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                local backup = CreateCombatBackup(cxt.quest:GetCastAgent("admiralty"),"ADMIRALTY_PATROL_BACKUP", cxt.quest:GetRank())
                cxt.encounter:SetPrimaryCast(cxt.quest:GetCastAgent("admiralty"))
                cxt:Dialog("DIALOG_INTRO")
            end

            if not cxt.enc.scratch.tried_insult then
                cxt:Opt("OPT_HAND_OVER_PET")

                    :Dialog("DIALOG_HAND_OVER")
                    :Fn(function() AUDIO:PlayPetSounds(cxt.quest:GetCastMember("pet"), "AFFIRMATIVE_YAP") end)
                    :Dialog("DIALOG_HAND_OVER_2")
                    :Fn(function() AUDIO:PlayPetSounds(cxt.quest:GetCastMember("pet"), "WHIMPER") end)
                    :Dialog("DIALOG_HAND_OVER_3")

                    :Fn(function() cxt.quest:GetCastMember("pet"):Dismiss() end)
                    :Travel()

                cxt:Opt("OPT_PAY")
                    :Dialog("DIALOG_PAY")
                    :DeliverMoney(50*cxt.quest:GetRank())
                    :Dialog("DIALOG_PST_PET")
                    :Travel()

                cxt:Opt("OPT_CONVINCE")
                    :Dialog("DIALOG_CONVINCE")
                    :Negotiation
                    {
                        on_success = function(cxt)
                            cxt:Dialog("DIALOG_CONVINCE_SUCCESS")
                            cxt:Dialog("DIALOG_PST_PET")
                            StateGraphUtil.AddLeaveLocation(cxt)
                        end,

                        on_fail = function(cxt)
                            cxt:Dialog("DIALOG_CONVINCE_FAIL")
                        end,
                    }

                local function AddInsult(insult_area, issue, stance)
                    cxt:Opt("OPT_INSULT_" .. insult_area)
                        :PostText("TT_INSULT", insult_card)
                        :PostCard(insult_card, true)
                        :UpdatePoliticalStance(issue, stance)
                        :Dialog("DIALOG_INSULT_" .. insult_area)
                        :Negotiation
                        {
                            on_start_negotiation = function(minigame)
                                local n = math.max(1, math.round( minigame.player_negotiator.agent.negotiator:GetCardCount() / 5 ))
                                for k = 1, n do
                                    local card = Negotiation.Card( "insult", minigame.player_negotiator.agent )
                                    card.show_dealt = true
                                    card:TransferCard(minigame:GetDrawDeck())
                                end
                            end,

                            on_success = function(cxt)
                                cxt:Dialog("DIALOG_INSULT_SUCCESS")
                                cxt:GetCastMember("admiralty"):OpinionEvent(OPINION.INSULT)
                                DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 2)
                                cxt:Dialog("DIALOG_PST_PET")
                                StateGraphUtil.AddLeaveLocation(cxt)
                            end,

                            on_fail = function(cxt)
                                cxt:Dialog("DIALOG_INSULT_FAILURE")
                                cxt:GetCastMember("admiralty"):OpinionEvent(OPINION.INSULT)
                                cxt.enc.scratch.tried_insult = true
                            end,
                        }
                end

                AddInsult("ADMIRALTY", "SECURITY", -2)
                AddInsult("DELTREE", "INDEPENDENCE", 2)
            end

            cxt:Opt("OPT_FIGHT")
                :Dialog("DIALOG_FIGHT")
                :Battle
                {
                    flags = BATTLE_FLAGS.SELF_DEFENCE,
                    on_win = function(cxt)
                        if cxt.quest:GetCastAgent("pet"):IsDead() then
                            cxt:Dialog(cxt:GetAgent():IsDead() and "DIALOG_FIGHT_AGENT_DEAD_PET_DEAD" or "DIALOG_FIGHT_AGENT_ALIVE_PET_DEAD")
                        else
                            cxt:Dialog(cxt:GetAgent():IsDead() and "DIALOG_FIGHT_AGENT_DEAD_PET_ALIVE" or "DIALOG_FIGHT_AGENT_ALIVE_PET_ALIVE")
                            cxt:Dialog("DIALOG_PST_PET")
                        end
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                }
        end)
