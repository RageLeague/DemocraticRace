local QDEF = QuestDef.Define
{
    title = "Penultimate Preparation",
    desc = "Continue to campaign and gain support among the people.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/day_2.png"),

    qtype = QTYPE.STORY,

    on_start = function(quest)
        quest:Activate("starting_out")
        DemocracyUtil.SetSubdayProgress(1)
        -- TheGame:GetGameState():GetPlayerAgent():MoveToLocation( quest:GetCastMember("home") )
    end,
}
:Loc{
    GET_JOB_ALONE = "Think of a way to gain support.",
    GET_JOB_ADVISOR = "Discuss with {primary_advisor} about how to gain support.",
}
:AddSubQuest{
    id = "do_debate",
    quest_id = "RACE_BIPARTISAN_SHOWDOWN",
    -- mark = {"primary_advisor"},
    on_activate = function(quest)
        UIHelpers.PassTime(DAY_PHASE.NIGHT)
        DemocracyUtil.SetSubdayProgress(2)
        -- gives you enough time to go to a bar and drink
        DemocracyUtil.StartFreeTime(0.5)
    end,
    on_complete = function(quest)
        quest:Activate("do_summary")
    end,
}
:AddSubQuest{
    id = "do_summary",
    quest_id = "RACE_DAY_END_SUMMARY",
    on_activate = function(quest)
        DemocracyUtil.SetSubdayProgress(3)
    end,
    on_complete = function(quest)
        quest:Activate("go_to_sleep")
    end,
}
:AddObjective{
    id = "go_to_sleep",
    title = "Go to sleep",
    desc = "It's been a long day. Go to bed when you are ready.",
    mark = {"primary_advisor"},
    on_activate = function(quest)
        DemocracyUtil.StartFreeTime()
    end,
    on_complete = function(quest)
        quest:Complete()
    end,
}
:AddObjective{
    id = "starting_out",
    title = "Talk to {primary_advisor} about the plan",
    mark = {"primary_advisor"},
    on_complete = function(quest)
        quest:Activate("get_job")
        DemocracyUtil.StartFreeTime()
    end,
}
:AddObjective{
    id = "get_job",
    title = "Find on a way to gain support",
    mark = {"primary_advisor"},
    desc = "",
    desc_fn = function(quest, str)
        return quest:GetCastMember("primary_advisor")
            and quest:GetLocalizedStr( "GET_JOB_ADVISOR" )
            or quest:GetLocalizedStr( "GET_JOB_ALONE" )
    end,
    -- on_activate = function(quest)
    --     if quest.param.job_history and #quest.param.job_history > 1 then
    --         DemocracyUtil.StartFreeTime()
    --     end
    -- end,
    on_complete = function(quest)
        quest:Activate("do_job")
    end,

}
:AddObjective{
    id = "do_job",
    hide_in_overlay = true,
    events =
    {
        quests_changed = function(quest, event_quest)
            if quest.param.current_job == event_quest and not event_quest:IsActive() then
                quest:Complete("do_job")
            end
        end
    },
    on_activate = function(quest)
        DemocracyUtil.EndFreeTime(true)
        if quest.param.current_job == "FREE_TIME" then
            quest.param.current_job = DemocracyUtil.StartFreeTime(1.5)
        end
    end,
    on_complete = function(quest)
        quest.param.job_history = quest.param.job_history or {}
        table.insert(quest.param.job_history, quest.param.current_job)
        quest.param.recent_job = quest.param.current_job
        quest.param.current_job = nil

        if (#quest.param.job_history >= 1) then
            quest:Activate("do_debate")
        else
            quest:Activate("get_job")
            DemocracyUtil.StartFreeTime()
        end
    end,

}
DemocracyUtil.AddPrimaryAdvisor(QDEF)
DemocracyUtil.AddHomeCasts(QDEF)

QDEF:AddConvo("starting_out", "primary_advisor")
    :ConfrontState("STATE_CONFRONT")
    :Loc{
        DIALOG_INTRO = [[
            * The day greets you to a hot cup of coffee and the dread of another day of work.
            primary_advisor:
                !hips
                You're up. Drink that quick, you've got a lot to do today.
        ]],
        DIALOG_INTRO_PST = [[
            player:
                !handwave
                Yeah, what else is new?
            agent:
                After yesterday's debate, they conducted a poll to see who the people support.
        ]],
        DIALOG_TOTAL = [[
            agent:
                They asked {1} {1*person|people}. {2} responded.
        ]],
        DIALOG_TOTAL_NO_ABSTAIN = [[
            agent:
                They asked {1} {1*person|people}, and everyone responded.
        ]],
        DIALOG_VOTE = [[
            agent:
                {1} {1*person|people} voted for {2#agent}.
        ]],
        DIALOG_VOTE_PLAYER = [[
            agent:
                {1} {1*person|people} voted for you.
        ]],
        DIALOG_PST_VOTES_GOOD = [[
            agent:
                !hips
                You've done good. The Grand Theater's asked for a debate between you and the other largest candidate.
            player:
                !sigh
                It's always a new thing at the Theater, isn't it?
            agent:
                !happy
                Of course.
        ]],
        DIALOG_PST_VOTES_BAD = [[
            agent:
                There's supposed to be a special debate happening tonight, between two of the strongest candidates.
                However... Your polling average isn't that great, so you aren't invited.
                !eureka
                With that being said, I've got an idea to make up for that and still get you on that highly publicized debate.
            player:
                !intrigue
                Could I <i>know</> this plan ahead of time, or is this on a need-to-know basis?
            agent:
                !clap
                In due time... and certainly not because I just thought of walking in there.
        ]],
        DIALOG_END = [[
            agent:
            {not has_potential_ally?
                {not advisor_favor?
                    !eureka
                    But, to business. We've got to drum up as much traffic to that debate we can.
                    I've already got some schemes cooked up for that, but we'll discuss that in a bit.
                }
                {advisor_favor?
                    Anyway, to business...
                    !point
                    Actually, there's something that's been bugging me for a bit. Do you mind hearing me out?
                }
            }
            {has_potential_ally?
                {not advisor_favor?
                    !eureka
                    But, to business. We've got to drum up as much-
                }
                {advisor_favor?
                    Anyway, to business...
                    !point
                    Actually-
                }
                * Before {agent} finishes {agent.hisher} sentence, you are interrupted by someone visiting.
            }
        ]],
    }
    :Fn(function(cxt)
        -- Generate advisor favor
        cxt.quest.param.previous_bad_debate = TheGame:GetGameState():GetMainQuest() and (TheGame:GetGameState():GetMainQuest().param.good_debate_scrum == false)
        cxt.quest.param.debate_scrum_result = TheGame:GetGameState():GetMainQuest() and TheGame:GetGameState():GetMainQuest().param.debate_scrum_result

        do
            cxt.enc.scratch.advisor_favor = cxt:GetCastMember("primary_advisor")
                and cxt:GetCastMember("primary_advisor"):GetRelationship() == RELATIONSHIP.LIKED
                and not DemocracyUtil.HasRequestQuest(cxt:GetCastMember("primary_advisor"))
            if cxt.enc.scratch.advisor_favor then
                cxt.enc.scratch.favor_request = DemocracyUtil.SpawnRequestQuest(cxt:GetCastMember("primary_advisor"))
                if not cxt.enc.scratch.favor_request then
                    cxt.enc.scratch.advisor_favor = nil
                end
            end
        end
        -- Generate opposition alliance
        do
            local result = DemocracyUtil.SummarizeVotes(DemocracyUtil.SimulateVoting({
                score_bias = function(val, agent)
                    if cxt.quest.param.debate_scrum_result then
                        local idx = table.arrayfind(cxt.quest.param.debate_scrum_result, agent)
                        if idx then
                            return val + math.floor(20 / idx)
                        end
                    end
                    return val
                end,
            }))
            local vote_result = {}
            local total_votes = 0
            for candidate, count in pairs(result.vote_count) do
                total_votes = total_votes + count
                if candidate then
                    table.insert(vote_result, {candidate, count})
                else
                    cxt.enc.scratch.abstained_votes = count
                end
            end
            table.sort(vote_result, function(a, b)
                if a[2] ~= b[2] then
                    return a[2] > b[2]
                end
                return b[1] ~= cxt.player and a[1] == cxt.player
            end)
            cxt.quest.param.vote_result = vote_result
            cxt.enc.scratch.total_votes = total_votes
            if #vote_result > 0 then
                local best_votes = vote_result[1][2]
                local low_vote_candidates = {}
                local conflicting_allies = {}
                local seen_player = false
                for i = 1, #vote_result do
                    if vote_result[i][1] == cxt.player then
                        seen_player = true
                        if i >= 3 then
                            cxt.quest.param.low_player_votes = true
                        end
                    else
                        if i >= 4 and vote_result[i][2] < 0.6 * best_votes then
                            table.insert(low_vote_candidates, vote_result[i][1])
                        elseif DemocracyUtil.GetAlliance(vote_result[i][1]) then
                            if not seen_player or i <= 2 then
                                table.insert(conflicting_allies, vote_result[i][1])
                            else
                                table.insert(low_vote_candidates, vote_result[i][1])
                            end
                        end
                    end
                end
                if #low_vote_candidates == 0 and #vote_result >= 4 then
                    table.insert(low_vote_candidates, vote_result[#vote_result][1])
                end
                for i, agent in ipairs(low_vote_candidates) do
                    DemocracyUtil.DropCandidate(agent)
                end
                if #low_vote_candidates > 0 then
                    cxt.quest.param.has_potential_ally = true
                    cxt.enc.scratch.low_vote_candidates = low_vote_candidates
                    -- cxt.enc.scratch.potential_ally = low_vote_candidates[#low_vote_candidates]
                end
                if #conflicting_allies > 0 then
                    cxt.quest.param.has_potential_ally = true
                    cxt.enc.scratch.conflicting_allies = conflicting_allies
                end
            end
        end
        cxt:Dialog("DIALOG_INTRO")
        DemocracyUtil.TryMainQuestFn("DoRandomOpposition", 3)
        cxt:Dialog("DIALOG_INTRO_PST")
        if cxt.enc.scratch.abstained_votes then
            cxt:Dialog("DIALOG_TOTAL", cxt.enc.scratch.total_votes, cxt.enc.scratch.total_votes - cxt.enc.scratch.abstained_votes)
        else
            cxt:Dialog("DIALOG_TOTAL_NO_ABSTAIN", cxt.enc.scratch.total_votes)
        end
        for i, data in ipairs(cxt.quest.param.vote_result) do
            if data[1] == cxt.player then
                cxt:Dialog("DIALOG_VOTE_PLAYER", data[2])
            else
                cxt:Dialog("DIALOG_VOTE", data[2], data[1])
            end
        end
        if cxt.quest.param.low_player_votes then
            cxt:Dialog("DIALOG_PST_VOTES_BAD")
        else
            cxt:Dialog("DIALOG_PST_VOTES_GOOD")
        end
        cxt:Dialog("DIALOG_END")
        if cxt.quest.param.has_potential_ally then
            -- Okay let's figure out which case the potential ally is
            -- If one of your allies is still strong enough to be in the race, go to conflicting allies
            if cxt.enc.scratch.conflicting_allies then
                cxt:GoTo("STATE_CONFLICTING_ALLIES")
            else
                for i, agent in ipairs(cxt.enc.scratch.low_vote_candidates) do
                    if DemocracyUtil.GetAlliance(agent) then
                        cxt.enc.scratch.dropped_ally = agent
                        cxt:GoTo("STATE_ALLIED_DROP")
                        return
                    end
                end
                cxt.enc.scratch.potential_ally = cxt.enc.scratch.low_vote_candidates[#cxt.enc.scratch.low_vote_candidates]
                local potential = DemocracyUtil.GetAlliancePotential(DemocracyUtil.GetOppositionID(cxt.enc.scratch.potential_ally))
                if DemocracyUtil.GetEndorsement(potential) >= RELATIONSHIP.LIKED then
                    cxt:GoTo("STATE_ALLIANCE")
                else
                    cxt:GoTo("STATE_INFORM")
                end
            end
        elseif cxt.enc.scratch.advisor_favor then
            cxt:GoTo("STATE_FAVOR")
        else
            cxt.quest:Complete("starting_out")
            StateGraphUtil.AddLeaveLocation(cxt)
        end
    end)
    :State("STATE_CONFLICTING_ALLIES")
        :Loc{
            DIALOG_INTRO = [[
                opponent:
                    !right
                player:
                    !chuckle
                    Oh, look at who showed up!
                opponent:
                    {player}, I have something to ask of you.
                player:
                    !permit
                    What is it?
                opponent:
                    !point
                    Can you drop out of the race?
                player:
                    ...
                    !crossed
                    Excuse me? What the Hesh?
                opponent:
                    !thumb
                    I'm serious, {player}.
                    {higher_ranking?
                        We both know you don't have enough votes to win this race.
                    }
                    {not higher_ranking?
                        You should know that even though you have a lot of votes, it's not enough to win the race.
                    }
                    !permit
                    But you drop out. We combine our supporters, and suddenly we'll both have a chance at this.
                    I promise you'll be treated right once I win, you just have to trust me.
            ]],
            OPT_AGREE = "Agree to drop out of the race",
            DIALOG_AGREE = [[
                player:
                    !sigh
                    You're not wrong. Our chances combined would be much better to get us in office.
                opponent:
                    !intrigue
                    So that's a yes? You'll drop out of the race for me?
                player:
                    !angry_shrug
                    No need to rub it in, but yes. You'll get your free supporters.
                opponent:
                    !eureka
                    Alright, thank you {player}. You won't regret this choice.
                * You agree to drop out of the race for {opponent}.
                * Together, you might achieve victory with {opponent}.
                * A shame that victory is not going to be yours. This is your campaign, after all.
            ]],
            OPT_REFUSE = "Refuse to drop out",
            DIALOG_REFUSE = [[
                player:
                    !chuckle
                    You seriously, <i>seriously</> doubt the power of political engineering.
                    My chances are fine, thank you very much.
                opponent:
                    !disappoint
                    Well, that's a shame. Truly it is.
                    !angry_point
                    The only way this can turn out now is us fighting each other in the race instead.
                player:
                    !sigh
                    So it seems.
                opponent:
                    !permit
                    For what it's worth, I sincerely hope you win if I lose.
            ]],
            OPT_CONVINCE = "Convince {opponent} to drop out instead",
            DIALOG_CONVINCE = [[
                player:
                    [p] I think you should drop out of the race instead.
                opponent:
                    Really now?
                {higher_ranking?
                    Even though I am more popular than you?
                }
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                player:
                {higher_ranking?
                    [p] You might be more popular, but people have certain expectations for you.
                }
                {not higher_ranking?
                    [p] Your campaign can only go so far because people have certain expectations for you.
                }
                    But me? I am a wildcard. My politics can appeal to anyone, instead of being restricted to one voting group.
                    We will have a better chance of winning if you drop out of the race.
                opponent:
                    Okay fine. I'll drop out instead.
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                player:
                    [p] Please, it's very important to me.
                opponent:
                    It's very important to me as well!
                    But we must all make sacrifice if we want to still win the election.
                    So, please, {player}. Consider dropping out of the race.
            ]],
            SIT_MOD = "Doesn't want to drop out of the race",
            SIT_MOD_RANKING = "Is more popular than you",
        }
        :Fn(function(cxt)
            cxt:ReassignCastMember("opponent", cxt.enc.scratch.conflicting_allies[1])
            cxt:GetCastMember("opponent"):MoveToLocation(cxt:GetCastMember("home"))

            local player_votes, opponent_votes
            for i, data in ipairs(cxt.quest.param.vote_result) do
                if data[1] == cxt.player then
                    player_votes = data[2]
                elseif data[1] == cxt:GetCastMember("opponent") then
                    opponent_votes = data[2]
                end
            end
            if player_votes < opponent_votes then
                cxt.enc.scratch.higher_ranking = true
            end
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_AGREE")
                :Dialog("DIALOG_AGREE")
                :Fn(function(cxt)
                    DemocracyUtil.AddAutofail(cxt, false)
                end)

            cxt:BasicNegotiation("CONVINCE", {
                target_agent = cxt:GetCastMember("opponent"),
                flags = NEGOTIATION_FLAGS.WORDSMITH,
                situation_modifiers = {
                    { value = 20, text = cxt:GetLocString("SIT_MOD") },
                    cxt.enc.scratch.higher_ranking and { value = math.min(math.ceil((opponent_votes - player_votes) / (player_votes + 1) * 6) * 5, 30), text = cxt:GetLocString("SIT_MOD_RANKING") }
                },
            }):OnSuccess()
                :Fn(function(cxt)
                    DemocracyUtil.DropCandidate(cxt.quest:GetCastMember("opponent"))
                    cxt.quest:Complete("starting_out")
                    cxt:GetCastMember("opponent"):MoveToLimbo()
                    StateGraphUtil.AddLeaveLocation(cxt)
                end)

            cxt:Opt("OPT_REFUSE")
                :Dialog("DIALOG_REFUSE")
                :Fn(function(cxt)
                    DemocracyUtil.SetAlliance(cxt:GetCastMember("opponent"), false)
                    cxt:GetCastMember("opponent"):OpinionEvent(OPINIONS.REFUSED_TO_DROP_OUT)
                    cxt.quest:Complete("starting_out")
                    cxt:GetCastMember("opponent"):MoveToLimbo()
                    StateGraphUtil.AddLeaveLocation(cxt)
                end)
        end)
    :State("STATE_ALLIED_DROP")
        :Loc{
            DIALOG_INTRO = [[
                opponent:
                    !crossed
                    {player}, I came to tell you some news.
                player:
                    !happy
                    Did they replace the hot sauce at the Slurping Snail?
                opponent:
                    !point
                    Not that I know of, though I'll check.
                    but the actual, <i>important</> news is that I've dropped out of the race.
                player:
                    !surprised
                    Oh wow. Didn't take you for someone who would've bailed.
                opponent:
                    !overthere
                    Well, I've seen the averages. My chances to be elected are being shoveled out with the oshnu dung at this point.
                    !point
                    But you and I are allies. I've told my supporters you're their next best option.
                    !clap
                    With that, I'm gonna retire. I'll be rooting for you.
            ]],
        }
        :Fn(function(cxt)
            cxt:ReassignCastMember("opponent", cxt.enc.scratch.dropped_ally)
            cxt:GetCastMember("opponent"):MoveToLocation(cxt:GetCastMember("home"))
            cxt:Dialog("DIALOG_INTRO")

            cxt.quest:Complete("starting_out")
            cxt:GetCastMember("opponent"):MoveToLimbo()
            StateGraphUtil.AddLeaveLocation(cxt)
        end)
    :State("STATE_INFORM")
        :Loc{
            DIALOG_INTRO = [[
                opponent:
                    !right
                    [p] Sup.
                player:
                    Hi.
                opponent:
                    With that note, I can't possibly win the campaign.
                    I'm dropping out of the campaign.
                player:
                    Cool.
                * A few candidates will drop out of the campaign.
                * Better pay attention.
            ]],
        }
        :Fn(function(cxt)
            cxt:ReassignCastMember("opponent", cxt.enc.scratch.potential_ally)
            cxt:GetCastMember("opponent"):MoveToLocation(cxt:GetCastMember("home"))
            cxt:Dialog("DIALOG_INTRO")

            cxt.quest:Complete("starting_out")
            cxt:GetCastMember("opponent"):MoveToLimbo()
            StateGraphUtil.AddLeaveLocation(cxt)
        end)
    :State("STATE_ALLIANCE")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    !right
                    [p] 'Sup.
                    I'm dropping out of the campaign because I can't win the campaign.
                    However, our platforms are very similar to each other.
                    Perhaps it's a good time to strike an alliance?
            ]],
            DIALOG_CHOOSE_PST = [[
                {allied?
                agent:
                    Feel free to visit me at {ally_work_pos#location}.
                player:
                    Thanks.
                }
                {not allied?
                agent:
                    Well, if you ever change your mind, visit me at {ally_work_pos#location}.
                player:
                    I'll keep that in mind, thanks.
                }
            ]],
        }
        :Fn(function(cxt)
            cxt.enc.scratch.potential_ally:MoveToLocation(cxt.location)
            cxt:TalkTo(cxt.enc.scratch.potential_ally)
            cxt:Dialog("DIALOG_INTRO")

            DemocracyUtil.DoAllianceConvo(cxt, cxt.enc.scratch.potential_ally, function(cxt, allied)
                cxt.enc.scratch.allied = allied
                cxt:Dialog("DIALOG_CHOOSE_PST")
                DemocracyUtil.DoLocationUnlock(cxt, cxt.enc.scratch.ally_work_pos)
                cxt.quest:Complete("starting_out")
                cxt.enc.scratch.potential_ally:MoveToLimbo()
                StateGraphUtil.AddLeaveLocation(cxt)
            end, 15)
        end)
    :State("STATE_FAVOR")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    I know you're working hard to campaign, but I want you to do something for me.
                    Of course, you don't have to accept it.
                    I want you to focus on the campaign if you need to, but if you think you have time to spare, maybe you can help me.
                player:
                    What do I get out of this?
                agent:
                    I will love you, and will help you as much as I can.
                player:
                    Sounds appealing.
                    Tell me what you want me to do, then.
            ]],
            DIALOG_REJECT = [[
                player:
                    I'm sorry, but I need to focus on the campaign.
                    I believe the campaign is surely more important than whatever you're doing.
                agent:
                    You're right, of course.
                    Forget I ever asked anything.
                    Anyway, get back to gaining support.
                    They aren't going to gain themselves.
            ]],
            DIALOG_ACCEPT = [[
                agent:
                    Anyway, if you want to do it with your free time, that is okay.
                    I don't want you to abandon the campaign for me.
                player:
                    Sure thing.
                agent:
                    Anyway, get back to gaining support.
                    They aren't going to gain themselves.
            ]],
        }
        :RunLoopingFn(function(cxt)
            if cxt:FirstLoop() then
                cxt:Dialog("DIALOG_INTRO")
            end
            cxt:QuestOpt( cxt.enc.scratch.favor_request )
                :Fn(function(cxt)
                    cxt:PlayQuestConvo(cxt.enc.scratch.favor_request, QUEST_CONVO_HOOK.INTRO)
                    DemocracyUtil.PresentRequestQuest(cxt, cxt.enc.scratch.favor_request, function(cxt,quest)
                        cxt:PlayQuestConvo(quest, QUEST_CONVO_HOOK.ACCEPTED)
                        cxt:Dialog("DIALOG_ACCEPT")
                        cxt.quest:Complete("starting_out")
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end, function(cxt, quest)
                        cxt:Dialog("DIALOG_REJECT")
                        cxt.quest:Complete("starting_out")
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end)

                end)
        end)

QDEF:AddConvo("get_job")
    :Loc{
        OPT_GET_JOB = "Find a way to gather support...",
        DIALOG_GET_JOB = [[
            player:
                !left
                !thought
                $neutralThoughtful
                Here's what I can do...
        ]],
    }
    :Hub_Location(function(cxt)
        if not cxt.quest:GetCastMember("primary_advisor") then
            cxt.quest:AssignCastMember("primary_advisor")
        end
        if not cxt.quest:GetCastMember("primary_advisor") then
            cxt:Opt("OPT_GET_JOB")
                :SetQuestMark()
                :Fn( function(cxt)
                    UIHelpers.DoSpecificConvo( nil, cxt.convodef.id, "STATE_GET_JOB" ,nil,nil,cxt.quest)
                end )
        end
    end)
    :State("STATE_GET_JOB")
        :Loc{
            DIALOG_GET_JOB = [[
                player:
                    !left
                    !thought
                    $neutralThoughtful
                    Here's what I can do...
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_GET_JOB")
            cxt:RunLoopingFn(function(cxt)
                DemocracyUtil.TryMainQuestFn("OfferJobs", cxt, 3, "RALLY_JOB")
            end)
        end)
QDEF:AddConvo("get_job", "primary_advisor")
    :Loc{
        OPT_GET_JOB = "Discuss Job...",
        DIALOG_GET_JOB = [[
            agent:
                !thought
                $neutralThoughtful
                Here's what we can do...
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_GET_JOB")
            :SetQuestMark( cxt.quest )
            :PostText("TT_SKIP_FREE_TIME")
            :Dialog("DIALOG_GET_JOB")
            :LoopingFn(function(cxt)
                DemocracyUtil.TryMainQuestFn("OfferJobs", cxt, 3, "RALLY_JOB", true)
            end)
    end)
QDEF:AddConvo("go_to_sleep", "primary_advisor")
    :Loc{
        DIALOG_GO_TO_SLEEP = [[
            player:
                Okay, I did all I can do.
                I'll go to bed.
            agent:
                Alright.
                Tomorrow is the big day. That's when the voting happens.
                Sleep well. There will be a lot of work tomorrow.
                !exit
        ]],
        DIALOG_WAKE = [[
            * Today is voting day. Havarians will be swarming the voting booths.
            * Havaria's future will be decided today, one way or another.
            * I hope you are ready.
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_SLEEP")
            :PreIcon(global_images.sleep)
            :Dialog("DIALOG_GO_TO_SLEEP")
            :Fn(function(cxt)
                local grog = cxt.location
                cxt.encounter:DoLocationTransition( cxt.quest:GetCastMember("player_room") )
                grog:SetPlax()

                TheGame:FE():FindScreen( Screen.ConversationScreen ).character_music = nil
                TheGame:GetMusic():StopCharacterMusic()

                cxt:TalkTo()

                ConvoUtil.DoSleep(cxt, "DIALOG_WAKE")

                DemocracyUtil.DoAlphaMessage()

                cxt:End()

                if true then
                    return
                end

                cxt.quest:Complete()

                cxt:Opt("OPT_LEAVE")
                    :MakeUnder()
                    :Fn(function()
                        cxt.encounter:DoLocationTransition( cxt.quest:GetCastMember("home") )
                        cxt:End()
                    end)

            end)
    end)
    :AttractState("STATE_ATTRACT")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    A long day, isn't it?
                    Wanna go to bed soon?
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
