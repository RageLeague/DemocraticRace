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
    cooldown = EVENT_COOLDOWN.LONG,

    events = {
        base_difficulty_change = function(quest, new_diff, old_diff)
            quest:SetRank(new_diff)
        end,
        quests_changed = function(quest, event_quest)
            if event_quest == quest.param.escort_quest and event_quest:IsComplete() then
                quest.param.parasite_cured = true
                if event_quest.param.curer_agent == quest:GetCastMember("giver") then
                    quest.param.cured_by_giver = true
                end
            end
        end
    },

    collect_agent_locations = function(quest, t)
        if not quest:GetCastMember("delivery"):IsRetired() then
            table.insert(t, { agent = quest:GetCastMember("delivery"), location = quest:GetCastMember("delivery_home"), role = CHARACTER_ROLES.VISITOR})
        end
    end,

    on_start = function(quest)
        quest:Activate("pick_up_package")
        local overrides = {
            cast = {
                infected = quest:GetCastMember("delivery"),
            },
            parameters = {
                spawned_from_quest = true,
            },
        }
        quest.param.bog_monster_event = QuestUtil.SpawnQuest("DEMEVENT_RAMPAGING_BOG_MONSTER", overrides, true)
    end,

    on_complete = function(quest)
        if not (quest.param.sub_optimal or quest.param.poor_performance) then
            quest:GetCastMember("giver"):OpinionEvent(OPINION.DID_LOYALTY_QUEST)
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 10, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, 2, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 5, "JAKES", "COMPLETED_QUEST_REQUEST")
        elseif quest.param.sub_optimal then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 5, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 2, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 3, "JAKES", "COMPLETED_QUEST_REQUEST")
        elseif quest.param.poor_performance then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 2, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 2, "JAKES", "COMPLETED_QUEST_REQUEST")
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
    mark = function(quest, t, in_location)
        if DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("giver"))
        end
    end,
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
                        * But who's to say it won't be a problem to other people?
                        * You need to tell everyone about it. Let them be aware of the danger.
                    }
                    {not vaccinated?
                        * That's not good.
                        * You need to tell everyone about how contagious it is. Let them be aware of the danger.
                    }
                }
                {not infected?
                    * Still, you might have got rid of one parasite, but who's to say there aren't more people in the Pearl infected?
                    * You need to tell everyone about it. Let them be aware of the danger.
                }
            ]],
            DIALOG_SURGERY_RUN = [[
                * [p] You grabbed the package and run.
                * {agent} is too busy writhing in pain than to chase after you.
                {infected?
                    * [p] But during the battle, seems like you contracted the parasite.
                    {vaccinated?
                        * Luckily, you are vaccinated against it. Shouldn't cause a problem.
                        * But who's to say it won't be a problem to other people?
                        * You need to tell everyone about it. Let them be aware of the danger.
                    }
                    {not vaccinated?
                        * That's not good.
                        * You need to tell everyone about how contagious it is. Let them be aware of the danger.
                    }
                }
                {not infected?
                    * The parasite looks really scary.
                    * You need to tell everyone about it. Let them be aware of the danger.
                }
            ]],
            DIALOG_SURGERY_KILLED = [[
                * [p] Okay, you straight up just killed {agent}.
                * That's one way of dealing with parasites.
                {infected?
                    * [p] But during the battle, seems like you contracted the parasite.
                    {vaccinated?
                        * Luckily, you are vaccinated against it. Shouldn't cause a problem.
                        * But who's to say it won't be a problem to other people?
                        * You need to tell everyone about it. Let them be aware of the danger.
                    }
                    {not vaccinated?
                        * That's not good.
                        * You need to tell everyone about how contagious it is. Let them be aware of the danger.
                    }
                }
                {not infected?
                    * Still, you might have got rid of one parasite, but who's to say there aren't more people in the Pearl infected?
                    * You need to tell everyone about it. Let them be aware of the danger.
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
                        * But who's to say it won't be a problem to other people?
                        * You need to tell everyone about it. Let them be aware of the danger.
                    }
                    {not vaccinated?
                        * That's not good.
                        * You need to tell everyone about how contagious it is. Let them be aware of the danger.
                    }
                }
                {not infected?
                    * The parasite looks really scary.
                    * You need to tell everyone about it. Let them be aware of the danger.
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
                * And tell everyone about this contagious parasite.
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
                * Anyway, you need to get back to {giver} and deliver the package.
                * And tell everyone about this contagious parasite.
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
                        cxt.quest.param.escort_quest.param.giver = cxt:GetCastMember("giver")
                        cxt.quest.param.escort_quest.param.bog_monster_event = cxt.quest.param.bog_monster_event
                    end)
                    :GoTo("STATE_TELL")
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
                            cxt.quest.param.parasite_cured = true
                            if cxt.quest.param.bog_monster_event then
                                cxt.quest.param.bog_monster_event:Cancel()
                            end
                        end
                        if cxt.enc.scratch.infected and not cxt.enc.scratch.vaccinated then
                            cxt:GainCards{"twig", "stem"}
                        end
                        cxt.quest.param.tried_surgery = true
                        cxt.quest:Complete("pick_up_package")
                        cxt:GoTo("STATE_TELL")
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
                        cxt:GoTo("STATE_TELL")
                    end,
                }

            cxt:Opt("OPT_LEAVE")
                :Dialog("DIALOG_LEAVE")
                :CompleteQuest("pick_up_package")
                :GoTo("STATE_TELL")
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
            cxt:GoTo("STATE_TELL")
        end)
    :State("STATE_TELL")
        :Loc{
            OPT_ACCEPT = "Accept",
            DIALOG_ACCEPT = [[
                right:
                    !exit
                player:
                    !left
                    [p] Alright, I accept.
                * Let's do this.
            ]],

            OPT_REFUSE = "Refuse",
            DIALOG_REFUSE = [[
                right:
                    !exit
                player:
                    !left
                    [p] Now it's not the time. I'm busy campaigning.
                * If you say so.
            ]],
        }
        :Fn(function(cxt)
            StateGraphUtil.AddLeaveLocation(cxt)
            -- cxt:Opt("OPT_ACCEPT")
            --     :Dialog("DIALOG_ACCEPT")
            --     :Fn(function(cxt)
            --         -- TODO: Spawn a side quest
            --     end)
            --     :Travel()

            -- cxt:Opt("OPT_REFUSE")
            --     :Dialog("DIALOG_REFUSE")
            --     :Travel()
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
            DIALOG_AGREE_FIRST = [[
                player:
                {player_drunk?
                    !drunk
                }
                    [p] Well-
                {other_party_member?
                    * {party} stopped you before you can say anything else.
                    {not probed_info?
                        party:
                            !right
                            !cagey
                            Wait, hold on a sec.
                        {admiralty?
                            Just between you and me, I've never heard of any Admiralty orders telling us to investigate the parasites.
                        }
                        {not admiralty?
                            Something is not right here.
                            I don't think the Admiralty cares about public health at all.
                        }
                            They must have an ulterior motive. Best be careful about what you say here.
                    }
                    {probed_info?
                        party:
                            !right
                            !cagey
                            Wait, what are you doing?
                            You know of their ulterior motive. Why are you agreeing to this?
                            Please, think this through once more!
                    }
                }
                {not other_party_member and not player_drunk?
                    {not probed_info?
                        * Wait, before you say anything, think this through a bit.
                        * Does the Admiralty actually care about public health? Or do they have an ulterior motive?
                        * You should think this through more carefully before saying anything you'll regret.
                    }
                    {probed_info?
                        * Wait, what are you doing?
                        * You know of their ulterior motive. Why are you agreeing to this?
                        * Please, think this through once more!
                    }
                }
                {not other_party_member and player_drunk?
                    {not probed_info?
                        * Come on! Does the Admiralty sound like the type that parties at all?
                        * You should think this through more carefully.
                        player:
                            ...
                        * Come on! I know thinking isn't your strong suit, given how drunk you are.
                        * But please! Think this through before you say something you'll regret!
                    }
                    {probed_info?
                        * Wait, what are you doing?
                        * You know of their ulterior motive. Why are you agreeing to this?
                        player:
                            ...
                        * Please, tell me you at least remember what {inspector} said!
                    }
                }
                inspector:
                    !right
                    !dubious
                    Is there something you'd like to say?
            ]],
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
                    {crowd_saw_bog_monster?
                        * {agent} is one step too late, though. The bog monster you saw the other day caused enough panic already.
                    }
                    * {agent} doesn't seem to notice that {agent.heshe} slipped up, though, and you kept your cool.
                }
                {player_drunk?
                    * That sounds... bad for you.
                    * {agent} doesn't seem to notice that {agent.heshe} slipped up, though, and despite how drunk you are, you kept your cool.
                }
                agent:
                    Lots of people might not appreciate it, but the Admiralty does a good job at keeping order.
                    Anyway, we need your help so we can understand the parasites better.
                {crowd_saw_bog_monster?
                    * You can try to convince {agent} that there is no point, now that the public already saw the impact of the bog parasites in the Pearl.
                    * {agent} might not listen to you, though, so if that fails, you need a plan to get out of this situation.
                }
                {not crowd_saw_bog_monster?
                    * You need to think of a plan to get out of this situation.
                }
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
            TT_CONVINCE = "Use this opportunity to cause a distraction and escape!",
            REASON_ESCAPE = "Distract {agent} and get away!",
            DIALOG_CONVINCE = [[
                player:
                    [p] Well, here's the thing...
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                {probed_info and crowd_saw_bog_monster?
                    player:
                        [p] Don't you get it? There is no point.
                        No matter how hard you try to hide, the truth always comes out.
                        There was already an incident earlier, where a person infected by the bog parasites transformed into a giant monster and attacking everyone in sight.
                    agent:
                        Is that true?
                    player:
                        Yeah, it is. Easy enough to check.
                    agent:
                        !sigh
                        In the end, all of our effort, it's all pointless anyway.
                        Fine, just go. I'm not going to stop you.
                }
                {not (probed_info and crowd_saw_bog_monster)?
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
            DIALOG_PARTY_LEFT_BEHIND = [[
                * [p] {1#agent_list} didn't escape, though. You shudder to imagine what happened to {2*{3.himher}|them}.
            ]],
            DIALOG_PARTY_ESCAPED = [[
                * [p] At least {1#agent_list} got away. You hope that {2*{3.heshe}|they} can get to safety.
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest.param.did_admiralty_confront = true
                cxt.enc.scratch.crowd_saw_bog_monster = cxt.player:HasMemory("CROWD_SAW_BOG_MONSTER")
                for i, agent in ipairs(cxt.player:GetParty():GetMembers()) do
                    if not agent:IsPlayer() and agent:CanTalk() then
                        cxt:ReassignCastMember("party", agent)
                        cxt.enc.scratch.other_party_member = true
                        break
                    end
                end
                local leader = TheGame:GetGameState():AddSkinnedAgent( "ADMIRALTY_INVESTIGATOR" ) --new guy, not relationship
                local overrides = {
                    cast = {
                        admiralty = leader,
                    },
                    parameters = {
                        tried_parasite_silence = true,
                    },
                }
                QuestUtil.SpawnQuest("FOLLOW_DIALOG_AWKWARD_ADMIRALTY_MEETING", overrides)
                cxt.enc.scratch.patrol = CreateCombatBackup(leader, "ADMIRALTY_PATROL_BACKUP", cxt.quest:GetRank() + 1)
                table.insert(cxt.enc.scratch.patrol, 1, leader)
                cxt:TalkTo(leader)
                cxt:ReassignCastMember("inspector", leader)
                cxt:Dialog("DIALOG_INTRO")
            end
            if cxt.enc.scratch.tried_agree then
                cxt:Opt("OPT_AGREE")
                    :Dialog("DIALOG_AGREE")
                    :Fn(function(cxt)
                        -- You "disappear"
                        cxt:Opt("OPT_FOLLOW")
                            :Fn(function(cxt)
                                DemocracyUtil.DoEnding(cxt, "disappearance", {})
                            end)
                    end)
            else
                cxt:Opt("OPT_AGREE")
                    :Fn(function(cxt)
                        if cxt:GetCastMember("party") then
                            cxt:TalkTo("party")
                        end
                    end)
                    :Dialog("DIALOG_AGREE_FIRST")
                    :Fn(function(cxt)
                        cxt.enc.scratch.tried_agree = true
                        cxt:TalkTo("inspector")
                    end)
            end
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
                    if not cxt.quest.param.probed_info then
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
                                        cxt.quest.param.probed_info = true
                                    else
                                        cxt:Dialog("DIALOG_PROBE_FAILURE")
                                    end
                                end,
                                on_fail = function(cxt, minigame)
                                    if minigame.secret_intel_destroyed then
                                        cxt:Dialog("DIALOG_PROBE_SLIP_UP")
                                        cxt.quest.param.probed_info = true
                                        cxt.enc.scratch.forced_fight = true
                                    else
                                        cxt:Dialog("DIALOG_PROBE_FAILURE")
                                    end
                                end,
                            }
                    end
                    local opt = cxt:Opt("OPT_CONVINCE")
                    if cxt.quest.param.probed_info then
                        opt:PostText("TT_CONVINCE")
                    end
                    opt:Dialog("DIALOG_CONVINCE")
                        :Negotiation{
                            reason_fn = function(minigame)
                                if cxt.quest.param.probed_info then
                                    return loc.format(cxt:GetLocString("REASON_ESCAPE"))
                                end
                            end,
                            on_start_negotiation = function(minigame)
                                if cxt.quest.param.probed_info then
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
                                    local left_behind = {}
                                    for i, member in cxt.player:GetParty():Members() do
                                        if not table.arraycontains(minigame.escaped_people, member) then
                                            table.insert(left_behind, member)
                                        end
                                    end
                                    if #left_behind > 0 then
                                        cxt:Dialog("DIALOG_PARTY_LEFT_BEHIND", left_behind, #left_behind, left_behind[1])
                                        for i, member in ipairs(left_behind) do
                                            member:OpinionEvent(OPINION.ABANDONED)
                                            member:Retire()
                                        end
                                    end
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                else
                                    cxt:Dialog("DIALOG_CONVINCE_SUCCESS")
                                    cxt.enc.scratch.tried_negotiation = true
                                    if cxt.quest.param.probed_info and cxt.enc.scratch.crowd_saw_bog_monster then
                                        StateGraphUtil.AddLeaveLocation(cxt)
                                        return
                                    end
                                    local escaped = minigame.escaped_people
                                    if escaped and #escaped > 0 then
                                        cxt:Dialog("DIALOG_PARTY_ESCAPED", escaped, #escaped, escaped[1])
                                        for i, member in ipairs(escaped) do
                                            if member:IsPet() then
                                                QuestUtil.RunAwayPet(member)
                                            else
                                                member:Dismiss()
                                                member:MoveToLimbo()
                                            end
                                        end
                                    end
                                end
                            end,
                            on_fail = function(cxt, minigame)
                                cxt:Dialog("DIALOG_CONVINCE_FAILURE")
                                cxt.enc.scratch.tried_negotiation = true
                                local escaped = minigame.escaped_people
                                if escaped and #escaped > 0 then
                                    cxt:Dialog("DIALOG_PARTY_ESCAPED", escaped, #escaped, escaped[1])
                                    for i, member in ipairs(escaped) do
                                        if member:IsPet() then
                                            QuestUtil.RunAwayPet(member)
                                        else
                                            member:Dismiss()
                                            member:MoveToLimbo()
                                        end
                                    end
                                end
                            end,
                        }
                end
            end

            if cxt.enc.scratch.forced_fight or cxt.quest.param.probed_info or cxt.enc.scratch.tried_negotiation then
                cxt:Opt("OPT_FIGHT")
                    :Dialog("DIALOG_FIGHT")
                    :Battle{
                        flags = BATTLE_FLAGS.SELF_DEFENCE,
                        on_start_battle = function(battle)
                            for i, fighter in ipairs(battle:GetPlayerTeam():GetFighters()) do
                                fighter:AddCondition( "DEM_CORNERED" )
                            end
                        end,
                        on_win = function(cxt)
                            cxt:Dialog("DIALOG_FIGHT_WIN")
                            StateGraphUtil.AddLeaveLocation(cxt)
                        end,
                        on_runaway = function(cxt, battle)
                            cxt:Dialog("DIALOG_FIGHT_RUNAWAY")
                            StateGraphUtil.DoRunAwayEffects( cxt, battle, true )
                            StateGraphUtil.AddLeaveLocation(cxt)
                        end,
                    }
            end
        end)


QDEF:AddConvo("deliver_package", "giver")
    :Loc{
        OPT_DELIVER = "Deliver the package",
        DIALOG_DELIVER = [[
            player:
                !give
                [p] Here's the package.
            agent:
                !take
                Thanks.
            {delivery_dead?
                agent:
                    [p] How's {delivery}?
                player:
                    {delivery} didn't make it.
                agent:
                    Well, that's a shame.
            }
            {not delivery_dead and parasite_cured and not cured_by_giver?
                agent:
                    [p] How's {delivery}?
                player:
                    [p] {delivery.HeShe} got infected by the bog parasites, but {delivery.heshe} got better now.
                agent:
                    That's good, I suppose.
            }
            {not delivery_dead and parasite_cured and cured_by_giver?
                agent:
                    [p] Well, the surgery on {delivery} went well.
                    {delivery.HeShe} might still take a couple of days to recover from the surgery, but the biggest ordeal has already been overcome.
                player:
                    That sounds good.
                agent:
                    Still, the bog parasite looks painful.
            }
            {not delivery_dead and not parasite_cured and infected_in_party?
                agent:
                    [p] How's {delivery}?
                player:
                    [p] Here {delivery.gender:he is|she is|they are}.
                delivery:
                    !left
                    !injured
                {can_cure_escort?
                    agent:
                        !surprised
                        Holy Hesh, {delivery}, that looks really bad.
                        I- I've never encountered anything like this. I can try to get rid of it, but it might be challenging.
                    player:
                        !left
                        Well, we can worry about that later. I'm just dropping off the package first.
                    agent:
                        Ah, of course.
                }
                {not can_cure_escort?
                    agent:
                        !surprised
                        What the Hesh is that?
                        I- I don't know what I can do about it. You should get that looked at.
                    player:
                        !left
                        Well, yeah, that's what plan to do right now. I'm just dropping off the package first.
                    agent:
                        Ah, of course.
                }
            }
            {not delivery_dead and not parasite_cured and not infected_in_party?
                agent:
                    [p] How's {delivery}?
                player:
                    [p] {delivery.HeShe} got infected by the bog parasites.
                    I imagine that {delivery.gender:he's|she's|they're} writhing in pain at the moment.
                agent:
                    !wince
                    That doesn't sound pleasant.
            }
            agent:
                Anyway, I thank you for your good work, from the bottom of my heart.
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_DELIVER")
            :SetQuestMark()
            :Fn(function(cxt)
                if cxt:GetCastMember("delivery"):IsInPlayerParty() then
                    cxt.enc.scratch.infected_in_party = true
                    if table.arraycontains(Content.GetQuestDef( "FOLLOWUP_PARASITE_KILLER" ).ALLOWED_HEALER, cxt:GetAgent():GetContentID()) then
                        cxt.enc.scratch.can_cure_escort = true
                    end
                    if cxt.quest.param.escort_quest then
                        cxt.quest.param.escort_quest.param.package_delivered = true
                    end
                    if not cxt.quest.param.parasite_cured then
                        cxt:GetAgent():Remember("SEEN_BOG_PARASITE")
                    end
                end
                cxt.enc.scratch.delivery_dead = cxt:GetCastMember("delivery"):IsDead()
            end)
            :Dialog("DIALOG_DELIVER")
            :CompleteQuest()
    end)
