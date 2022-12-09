local QDEF = QuestDef.Define
{
    title = "Gift From The Bog",
    desc = "Pick up a package for {giver} from {delivery}.",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/battle_of_wits.png"),

    qtype = QTYPE.SIDE,

    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"REQUEST_JOB"},
    reward_mod = 0,
    can_flush = false,

    events = {
        base_difficulty_change = function(quest, new_diff, old_diff)
            quest:SetRank(new_diff)
        end,

    },

    collect_agent_locations = function(quest, t)
        if not quest:GetCastMember("delivery"):IsRetired() then
            table.insert(t, { agent = quest:GetCastMember("delivery"), location = quest:GetCastMember("delivery_home"), role = CHARACTER_ROLES.VISITOR})
        end
    end,

    on_start = function(quest)
        quest:Activate("pick_up_package")
    end,

    on_complete = function(quest)
        if not (quest.param.sub_optimal or quest.param.poor_performance) then
            quest:GetCastMember("giver"):OpinionEvent(OPINION.DID_LOYALTY_QUEST)
        elseif quest.param.sub_optimal then
        elseif quest.param.poor_performance then
        end
    end,

}
:AddCast{
    cast_id = "giver",
    no_validation = true,
    provider = true,
    unimportant = true,
    condition = function(agent, quest)
        return (agent:GetFactionID() == "JAKES" and not agent:HasTag("advisor"))
    end,
    on_assign = function(quest, agent)
    end,
}
:AddCast{
    cast_id = "delivery",
    condition = function(agent, quest)
        return agent:GetFactionID() == "JAKES"
    end,
    on_assign = function(quest, agent)
        quest:AssignCastMember("delivery_home")
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( "JAKES_RUNNER" ) )
    end,
}
:AddLocationCast{
    cast_id = "delivery_home",
    when = QWHEN.MANUAL,
    cast_fn = function(quest, t)
        table.insert(t, quest:GetCastMember("delivery"):GetHomeLocation())
    end,
}

:AddObjective{
    id = "pick_up_package",
    title = "Pick up package from {delivery}.",
    desc = "Go to {delivery}'s home and pick up the package from {delivery.himher}.",
    mark = function(quest, t, in_location)
        if DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("delivery_home"))
        end
    end,
    on_complete = function(quest)
        quest:Activate("deliver_package")
    end,
}
:AddObjective{
    id = "deliver_package",
    title = "Deliver the package to {giver}.",
    desc = "You got the package. Deliver it to {giver}.",
    mark = {"giver"},
}

QDEF:AddIntro(
    --attract spiel
    [[
        agent:
            [p] I've got this package from the Bog that I need to pick up.
            It's with {delivery}. Can you pick the package up for me from {delivery.himher}?
    ]],
    --on accept
    [[
        player:
            [p] Okay. Where can I find {delivery.himher}?
        agent:
            That's the thing. I haven't seen {delivery.himher} for a while, so I have no idea where {delivery.heshe} could be.
            Maybe start from {delivery.hisher} home. See if you can find {delivery.himher} there.
    ]])

QDEF:AddConvo("pick_up_package")
    :Confront(function(cxt)
        if cxt.location == cxt:GetCastMember("delivery_home") then
            if cxt:GetCastMember("delivery"):GetLocation() == cxt:GetCastMember("delivery_home") then
                return "STATE_CONF"
            else
                return "STATE_CONF_NO_PERSON"
            end
        end
    end)
    :State("STATE_CONF")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You visit {agent}'s home.
                player:
                    !left
                    !scared
                agent:
                    !right
                    !injured
                * {agent} writhes in pain.
                * When you ask, {agent} shows you bog parasites growing out of {agent.hisher} arm.
                {have_parasite?
                    * [p] So it's not just you. There are other people who also got infected by the bog parasites.
                }
                {not have_parasite?
                    * Bog parasites now infects the Pearl now?
                    {not player_drunk?
                        * And, judging by {agent}'s description, it's contagious.
                    }
                }
                * This is a big deal. You need to tell everyone about it.
            ]],
            OPT_SURGERY = "Perform \"surgery\" on {agent}",
            TT_SURGERY = "Get rid of {agent}'s parasite in a battle. Or {agent} in general, if that's how you want things to go.",
            DIALOG_SURGERY = [[
                player:
                    !fight
                    [p] This is for your own good.
            ]],
            DIALOG_SURGERY_WIN = [[
                * [p] You got rid of the parasite.
                * {agent} thanks you.
                {infected?
                    * [p] But during the battle, seems like you contracted the parasite.
                    {vaccinated?
                        * Luckily, you are vaccinated against it. Shouldn't cause a problem.
                    }
                    {not vaccinated?
                        * That's not good.
                    }
                }
            ]],
            DIALOG_SURGERY_RUN = [[
                * [p] You grabbed the package and run.
                * {agent} is too busy writhing in pain than to chase after you.
                {infected?
                    * [p] But during the battle, seems like you contracted the parasite.
                    {vaccinated?
                        * Luckily, you are vaccinated against it. Shouldn't cause a problem.
                    }
                    {not vaccinated?
                        * That's not good.
                    }
                }
            ]],
            DIALOG_SURGERY_KILLED = [[
                * [p] Okay, you straight up just killed {agent}.
                * That's one way of dealing with parasites.
                {infected?
                    * [p] But during the battle, seems like you contracted the parasite.
                    {vaccinated?
                        * Luckily, you are vaccinated against it. Shouldn't cause a problem.
                    }
                    {not vaccinated?
                        * That's not good.
                    }
                }
            ]],
            DIALOG_SURGERY_FAILED = [[
                * [p] It doesn't seem to actually help {agent}, and now {agent} is mad.
                * {agent.HeShe} can't do anything about it, though, since {agent.gender:he's|she's|they're} very injured.
                * You grabbed the package and leave {agent} to {agent.hisher} fate.
                {infected?
                    * [p] But during the battle, seems like you contracted the parasite.
                    {vaccinated?
                        * Luckily, you are vaccinated against it. Shouldn't cause a problem.
                    }
                    {not vaccinated?
                        * That's not good.
                    }
                }
            ]],
            OPT_ESCORT = "Convince {agent} to follow you",
            DIALOG_ESCORT = [[
                player:
                    [p] Come on. Let's get you some help.
                agent:
                    But I have very low energy.
            ]],
            DIALOG_ESCORT_SUCCESS = [[
                player:
                    [p] You can't stay like this forever.
                    We need to get you some help soon.
                agent:
                    Fine.
                * You pick up the package and bring {agent} with you.
            ]],
            DIALOG_ESCORT_FAILURE = [[
                agent:
                    [p] I can't move.
            ]],

            OPT_LEAVE = "Leave {agent} to {agent.hisher} fate",
            DIALOG_LEAVE = [[
                player:
                    [p] I'm sorry. There is nothing I can do at this point.
                    Thanks for the package.
                    {pro_religious_policy?
                        Let us pray to Hesh that you can recover from... whatever that is.
                    }
                    {not pro_religious_policy?
                        I hope you can recover from... whatever that is.
                    }
                * Of course. Thoughts and prayers. That is <i>definitely</> enough to help {agent} recover.
                * Anyway, you need to get back to {giver} and deliver the package. And also tell {agent} about the parasite situation.
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt:TalkTo(cxt:GetCastMember("delivery"))
                cxt.enc.scratch.vaccinated = cxt.player.graft_owner:HasGraft("perk_vaccinated")
                cxt:Dialog("DIALOG_INTRO")
            end

            if not cxt.enc.scratch.tried_escort then
                cxt:BasicNegotiation("ESCORT", {

                }):OnSuccess()
                    :Fn(function(cxt)
                        cxt.quest:Complete("pick_up_package")
                        local overrides = {
                            cast = {
                                escort = cxt:GetAgent(),
                            },
                            parameters = {
                            },
                        }
                        cxt:GetAgent():Recruit(PARTY_MEMBER_TYPE.ESCORT)
                        cxt.quest.param.escort_quest = QuestUtil.SpawnQuest("FOLLOWUP_PARASITE_KILLER", overrides)
                    end)
                    :Travel()
                :OnFailure()
                    :Fn(function(cxt)
                        cxt.enc.scratch.tried_escort = true
                    end)
            end

            cxt:Opt("OPT_SURGERY")
                :PostText("TT_SURGERY")
                :Dialog("DIALOG_SURGERY")
                :Battle{
                    enemies = { cxt:GetCastMember("delivery") },
                    -- flags = BATTLE_FLAGS.NO_BACKUP,
                    on_start_battle = function(battle)
                        local fighter = battle:GetFighterForAgent(cxt:GetAgent())
                        if fighter then
                            fighter:AddCondition("DEM_PARASITIC_INFECTION", 1)
                            fighter:AddCondition("DISEASED", 5)
                        end

                        local cards = {}
                        for i = 1, 4 do
                            table.insert(cards, Battle.Card("dem_parasite_extraction", battle:GetPlayerFighter()))
                        end
                        battle:DealCards(cards, battle:GetDrawDeck())
                    end,
                    on_win = function(cxt, battle)
                        local player = battle:GetFighterForAgent(cxt.player)
                        cxt.enc.scratch.infected = player and player:HasCondition("DISEASED")
                        local fighter = battle:GetFighterForAgent(cxt:GetAgent())
                        if cxt:GetCastMember("delivery"):IsDead() then
                            cxt:Dialog("DIALOG_SURGERY_KILLED")
                        elseif fighter and fighter:HasCondition( "DISEASED" ) then
                            cxt:Dialog("DIALOG_SURGERY_FAILED")
                        else
                            cxt:Dialog("DIALOG_SURGERY_WIN")
                            cxt:GetCastMember("delivery"):OpinionEvent(OPINION.SAVED_LIFE)
                        end
                        if cxt.enc.scratch.infected and not cxt.enc.scratch.vaccinated then
                            cxt:GainCards{"twig", "stem"}
                        end
                        cxt.quest.param.tried_surgery = true
                        cxt.quest:Complete("pick_up_package")
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                    on_runaway = function(cxt, battle)
                        local player = battle:GetFighterForAgent(cxt.player)
                        cxt.enc.scratch.infected = player and player:HasCondition("DISEASED")

                        cxt:Dialog("DIALOG_SURGERY_RUN")
                        if cxt.enc.scratch.infected and not cxt.enc.scratch.vaccinated then
                            cxt:GainCards{"twig", "stem"}
                        end
                        cxt.quest.param.tried_surgery = true
                        cxt.quest:Complete("pick_up_package")
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                }

            cxt:Opt("OPT_LEAVE")
                :Dialog("DIALOG_LEAVE")
                :CompleteQuest("pick_up_package")
                :Travel()
        end)
    :State("STATE_CONF_NO_PERSON")
        :Loc{
            DIALOG_INTRO_NO_PERSON = [[
                * [p] You visit {delivery}'s home.
                * {delivery} is nowhere to be found.
                * You found the package.
                * You also found a bunch of evidence of bog parasites. It's disgusting.
                * You need to tell people about it.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO_NO_PERSON")
            cxt.quest:Complete("pick_up_package")
            StateGraphUtil.AddLeaveLocation(cxt)
        end)

QDEF:AddConvo("deliver_package")
    :TravelConfront("INTERRUPT", function(cxt)
        return not cxt.quest.param.did_admiralty_confront
    end)
        :Loc{
            DIALOG_INTRO = [[
                * [p] A bunch of switches walks up to you.
                player:
                    !left
                agent:
                    !right
                    You've seen what the parasites looks like.
                    Come to the our headquarters, and let's talk about it there.
                {other_party_member?
                    Your friend, too.
                }
            ]],
            OPT_AGREE = "Agree to follow {agent}",
            DIALOG_AGREE = [[
                player:
                {not other_party_member?
                    [p] Alright. I'm coming with you.
                }
                {other_party_member?
                    [p] Alright. We'll come with you.
                party:
                    !left
                    Wait, we are?
                player:
                    !left
                }
                agent:
                    Excellent. We have a lot to talk about.
                * You follow {agent} to the Admiralty headquarters.
            ]],
            OPT_FOLLOW = "Follow {agent}",
            OPT_REFUSE = "Refuse to follow {agent}",
            DIALOG_REFUSE = [[
                player:
                    [p] Sorry. Kinda busy right now. Gotta bail.
                agent:
                    I think you misunderstood me.
                    I didn't ask for your permission.
                    You are coming with me. This is an urgent matter.
            ]],
            OPT_BRIBE = "Bribe {agent} to let you go",
            DIALOG_BRIBE = [[
                player:
                    [p] Just a little money, and we pretend nothing happened.
                agent:
                    Is that how you think this works?
                    I've got strict orders from the top. You are coming with me.
                player:
                    Dang. That usually works.
            ]],
            OPT_PROBE = "Ask for why the Admiralty needs you",
            DIALOG_PROBE = [[
                player:
                    [p] Why does the Admiralty need me again?
            ]],
            DIALOG_PROBE_SUCCESS = [[
                agent:
                    [p] The election is coming up, and we don't want something like a bog parasite causing a huge panic.
                    That's why the less information gets out there, the better.
                {not player_drunk?
                    * Oh dear. They are going to silence you so you don't cause panic.
                    * {agent} doesn't seem to notice that {agent.heshe} slipped up, though, and you kept your cool.
                }
                {player_drunk?
                    * That sounds... bad for you.
                    * {agent} doesn't seem to notice that {agent.heshe} slipped up, though, and despite how drunk you are, you kept your cool.
                }
                agent:
                    Lots of people might not appreciate it, but the Admiralty does a good job at keeping order.
                    Anyway, we need your help so we can understand the parasites better.
                * You need to think of a plan to get out of this situation.
                {other_party_member?
                    * Preferably, with your party members, as well.
                }
            ]],
            DIALOG_PROBE_SLIP_UP = [[
                agent:
                    [p] The election is coming up, and we don't want something like a bog parasite causing a huge panic.
                    That's why the less information gets out there, the better.
                player:
                    Wait, that's why you want me to come with you?
                agent:
                    Hesh damn it, the jig is up.
                    No more pleasantries. You are coming with us, whether you like it or not.
                * Time to defend yourself!
            ]],
            DIALOG_PROBE_FAILURE = [[
                agent:
                    [p] For research purposes, of course.
                    You don't want the Pearl to be infected by the parasites, do you?
                player:
                    Well...
                agent:
                    Then you should definitely come with me, then.
            ]],
            OPT_CONVINCE = "Convince {agent} to let you go",
            TT_CONVINCE = "",
            DIALOG_CONVINCE = [[
                player:
                    [p] Well, here's the thing...
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                agent:
                    [p] That's well and good. I almost considered letting you go.
                    But I have my orders. I don't intend on disobeying them.
                    You are coming with me. No matter what.
                {probed_info?
                    * Dammit! You didn't distract long enough to get away!
                }
                {not probed_info?
                    * Okay, why is there a negotiation option there if it's completely pointless?
                }
            ]],
            DIALOG_CONVINCE_GOT_AWAY = [[
                agent:
                    [p] A bird? Where?
                * You got away!
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                player:
                    [p] I am really, really busy with my campaign.
                agent:
                    Sorry, that won't fly.
                    You are coming with me!
            ]],
            OPT_FIGHT = "Fight your way out",
            DIALOG_FIGHT = [[
                player:
                    !fight
                    [p] You leave me no choice!
            ]],
            DIALOG_FIGHT_WIN = [[
                * [p] You beat the Admiralty.
                * Time to move on before more shows up.
            ]],
            DIALOG_FIGHT_RUNAWAY = [[
                * [p] You find an opening an run away.
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest.param.did_admiralty_confront = true
                local leader = TheGame:GetGameState():AddSkinnedAgent( "ADMIRALTY_INVESTIGATOR" ) --new guy, not relationship
                cxt.enc.scratch.patrol = CreateCombatBackup(leader, "ADMIRALTY_PATROL_BACKUP", cxt.quest:GetRank() + 1)
                table.insert(cxt.enc.scratch.patrol, 1, leader)
                cxt:TalkTo(leader)
                cxt:Dialog("DIALOG_INTRO")
            end
            cxt:Opt("OPT_AGREE")
                :Dialog("DIALOG_AGREE")
                :Fn(function(cxt)
                    -- You "disappear"
                    cxt:Opt("OPT_FOLLOW")
                        :Fn(function(cxt)
                            DemocracyUtil.DoEnding(cxt, "disappearance", {})
                        end)
                end)
            if not cxt.enc.scratch.tried_refuse then
                cxt:Opt("OPT_REFUSE")
                    :Dialog("DIALOG_REFUSE")
                    :Fn(function(cxt)
                        cxt.enc.scratch.tried_refuse = true
                    end)
                return
            end

            if not cxt.enc.scratch.forced_fight then
                if not cxt.enc.scratch.tried_bribe then
                    cxt:Opt("OPT_BRIBE")
                        :RequireMoney(150)
                        :Dialog("DIALOG_BRIBE")
                        :Fn(function(cxt)
                            cxt.enc.scratch.tried_bribe = true
                        end)
                end
                if not cxt.enc.scratch.tried_negotiation then
                    cxt:Opt("OPT_PROBE")
                        :Dialog("DIALOG_PROBE")
                        :Negotiation{
                            on_start_negotiation = function(minigame)
                                minigame:GetOpponentNegotiator():CreateModifier( "secret_intel", 1 )
                            end,
                            on_success = function(cxt, minigame)
                                local count = minigame:GetPlayerNegotiator():GetModifierStacks( "secret_intel" )
                                if count > 0 then
                                    cxt:Dialog("DIALOG_PROBE_SUCCESS")
                                    cxt.enc.scratch.probed_info = true
                                else
                                    cxt:Dialog("DIALOG_PROBE_FAILURE")
                                end
                            end,
                            on_fail = function(cxt, minigame)
                                if minigame.secret_intel_destroyed then
                                    cxt:Dialog("DIALOG_PROBE_SLIP_UP")
                                    cxt.enc.scratch.probed_info = true
                                    cxt.enc.scratch.forced_fight = true
                                else
                                    cxt:Dialog("DIALOG_PROBE_FAILURE")
                                end
                            end,
                        }
                    cxt:Opt("OPT_CONVINCE")
                        :Dialog("DIALOG_CONVINCE")
                        :Negotiation{
                            on_start_negotiation = function(minigame)
                                if cxt.enc.scratch.probed_info then
                                    -- Add new negotiation cards and args
                                    minigame.escaped_people = {}
                                    minigame:GetOpponentNegotiator():CreateModifier( "DEM_STARTLING_DISTRACTION", 5 )
                                    local card = Negotiation.Card( "dem_opportunistic_retreat", minigame.player_negotiator.agent )
                                    card.show_dealt = true
                                    card:TransferCard(minigame:GetDrawDeck())
                                end
                            end,
                            on_success = function(cxt, minigame)
                                if minigame.escaped_people and table.arraycontains(minigame.escaped_people, cxt.player) then
                                    cxt:Dialog("DIALOG_CONVINCE_GOT_AWAY")
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                else
                                    cxt:Dialog("DIALOG_CONVINCE_SUCCESS")
                                    cxt.enc.scratch.tried_negotiation = true
                                end
                            end,
                            on_fail = function(cxt, minigame)
                                cxt:Dialog("DIALOG_CONVINCE_FAILURE")
                                cxt.enc.scratch.tried_negotiation = true
                            end,
                        }
                end
            end
        end)
