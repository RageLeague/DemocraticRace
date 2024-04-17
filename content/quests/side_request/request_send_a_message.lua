local QDEF = QuestDef.Define
{
    title = "Send A Message",
    desc = "Make {target}'s life miserable for {giver}.",
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

        end
    },

    on_start = function(quest)
        quest:Activate("punish_target")
    end,

    on_complete = function(quest)
        local giver = quest:GetCastMember("giver")
        if not (quest.param.sub_optimal or quest.param.poor_performance) then
            giver:OpinionEvent(OPINION.DID_LOYALTY_QUEST)
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 4, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 5, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
        elseif quest.param.sub_optimal then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 3, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 8, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 4, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
        elseif quest.param.poor_performance then
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 3, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
        end
    end,
}
:AddCast{
    cast_id = "giver",
    no_validation = true,
    provider = true,
    unimportant = true,
    condition = function(agent, quest)
        return not agent:HasTag("curated_request_quest")
    end,
    on_assign = function(quest, agent)
        quest:AssignCastMember("target")
    end,
}
:AddCast{
    when = QWHEN.MANUAL,
    cast_id = "target",
    no_validation = true,
    unimportant = true,
    condition = function(agent, quest)
        if not agent:IsSentient() then
            return false, "Don't be mean to the dog :( (or oshnu, mech, whatever)"
        end
        if agent:GetFactionID() ~= quest:GetCastMember("giver"):GetFactionID() then
            return false, "Wrong faction"
        end
        if agent:GetRelationship(quest:GetCastMember("giver")) > RELATIONSHIP.NEUTRAL then
            return false, "Friends, can't target"
        end
        return not AgentUtil.HasPlotArmour(agent)
    end,
    on_assign = function(quest, agent)
        agent:OpinionEvent(OPINION.DISAPPROVE_MAJOR, nil, quest:GetCastMember("giver"))
    end,
    events = {
        agent_retired = function(quest, agent)
            if agent:IsDead() then
                quest.param.target_dead = true
                quest.param.poor_performance = true
            else
                quest.param.target_retired = true
            end
            quest:Complete("punish_target")
        end,
        aspects_changed = function( quest, agent, added, aspect )
            if added then
                if is_instance( aspect, Aspect.StrippedInfluence ) then
                    quest.param.stripped_influence = true
                    if agent:HasMemory("GOT_FIRED_FROM_JOB") then
                        quest.param.fired_from_job = true
                    end
                    quest:Complete("punish_target")
                end
            end

        end
    }
}
:AddObjective{
    id = "punish_target",
    title = "Send {target} a message",
    desc = "Humiliate or defame {target}, or other way to make {target.hisher} life miserable.",
    combat_targets = {"target"},
    on_complete = function(quest)
        quest:Activate("report_success")
    end,
    events = {
        resolve_battle = function(quest, battle, primary_enemy, repercussions )
            if battle.result == BATTLE_RESULT.WON then
                if battle:GetEnemyTeam():GetFighterForAgent(quest:GetCastMember("target")) then
                    quest.param.beat_up_primary = primary_enemy == quest:GetCastMember("target")
                    quest.param.beat_up = true
                    if quest:GetCastMember("target"):IsDead() then
                        quest.param.target_killed_in_battle = true
                    end
                end
            end
        end,
    },
}
:AddObjective{
    id = "report_success",
    title = "Report your success",
    desc = "Now that you have dealt with {target}, report to {giver} about it.",
    mark = function(quest, t, in_location)
        if in_location or DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("giver"))
        end
    end,
    on_complete = function(quest)

    end,
}

QDEF:AddIntro(
    --attract spiel
    [[
        agent:
            [p] There is a person that I absolutely hate.
            {target.HisHer} name is {target}.
            I want you to send {target.himher} a message. Let {target.himher} know that {agent} is not to be messed with.
            Just... try not to kill {target.himher}. That would put too much suspicion on myself.
    ]],

    --on accept
    [[
        player:
            [p] That can be done.
        agent:
            Excellent!
    ]])

QDEF:AddConvo("punish_target")
    :Priority(CONVO_PRIORITY_LOW)
    :Confront(function(cxt)
        if cxt.quest.param.beat_up and not cxt.quest:GetCastMember("target"):IsDead()
            and cxt.quest:GetCastMember("target"):GetLocation() == cxt.location then

            return "STATE_BEAT_UP"
        end
    end)
    :State("STATE_BEAT_UP")
        :Loc{
            DIALOG_FOLLOWUP = [[
                {beat_up_primary?
                    target:
                        !right
                        !injured
                    player:
                        !left
                        !angry
                        By the way, {target}.
                }
                {not beat_up_primary?
                    player:
                        !left
                        !angry
                        I'm not done yet.
                        !angry_accuse
                        {target}!
                    target:
                        !right
                        !injured
                        What?
                    player:
                }
                    [p] {giver} sends {giver.hisher} regards.
                target:
                    {giver}, huh?
                    I'll leave you and {giver} alone.
                    But I won't forget this.
                    !exit
            ]],
        }
        :Fn(function(cxt)
            cxt.quest:Complete("punish_target")
            cxt:Dialog("DIALOG_FOLLOWUP")
        end)

QDEF:AddConvo("report_success", "giver")
    :Loc{
        OPT_TELL_NEWS = "Tell {agent} about what you did",
        DIALOG_TELL_NEWS = [[
            player:
                [p] It is done.
            agent:
                Really? What did you do?
            {target_retired?
                player:
                    !throatcut
                    I, ah, "retired" {target}, if you get what I mean.
                agent:
                    !scared
                    Oh, no. Is {target.heshe} dead?
                player:
                    What? No. {target.HeShe} simply get discharged.
                    {target.HeShe}'s never going to come back to bother you anymore.
                agent:
                    !dubious
                    And why is that different from death?
                player:
                    You get to live with the conscience that you never kill {target}.
                agent:
                    !happy
                    That makes it way better!
                    Thanks, {player}!
                player:
                    !happy
                    You're welcome.
            }
            {beat_up?
                player:
                    I beat {target.himher} up.
                agent:
                    That seems a bit aggressive. Did you make sure {target.heshe} got the message?
                player:
                    Yeah, definitely.
                agent:
                    $scaredFearful
                    You didn't kill {target.himher}, right?
                player:
                    !handwave
                    Nah.
                agent:
                    Well, in that case, everything worked out fine.
                    Thank you for what you did for me.
                    I am truly grateful.
            }
            {stripped_influence?
                player:
                    [p] I stripped {target.hisher} influence.
                    {fired_from_job?
                        [p] {target} is fired from {target.hisher} job.
                    }
                agent:
                    Nice.
            }
        ]],
        OPT_REPORT_DEATH = "Report {target}'s death",
        DIALOG_REPORT_DEATH = [[
            agent:
                [p] I recall specifically telling you not to kill {target}.
            {target_killed_in_battle?
                player:
                    Look, the opportunity arose-
                agent:
                    So what? You shouldn't just kill {target.himher} when I told you not to.
            }
            {not target_killed_in_battle?
                player:
                    Hey, you can't prove that I killed {target}.
                agent:
                    After I told you to deal with {target}, {target.heshe} died not soon after?
                    It's not hard to put two and two together.
                    Even if you didn't personally kill {target}, you must played a part in it.
            }
            player:
                So... What happens now?
            agent:
                Now suspicion will be placed on me.
                I will need to lay low for a bit thanks to your stunt.
                Well, at least {target}'s dead, so that's something I guess.
                Never have to deal with that vroc dung anymore.
                Thanks, I suppose.
                Please never return.
        ]],
    }
    :Hub(function(cxt)
        if cxt:GetCastMember("target"):IsDead() then
            cxt:Opt("OPT_REPORT_DEATH")
                :SetQuestMark(cxt.quest)
                :Dialog("DIALOG_REPORT_DEATH")
                :CompleteQuest()
        else
            cxt:Opt("OPT_TELL_NEWS")
                :SetQuestMark(cxt.quest)
                :Dialog("DIALOG_TELL_NEWS")
                :CompleteQuest()
        end
    end)
