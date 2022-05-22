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
            * [p] You wake to your advisor.
            agent:
                Good morning.
                Tomorrow is the big day, so everyone is pushing really hard for a final stretch.
                You will need to get whatever support you can for today.
        ]],
        DIALOG_INTRO_PST = [[
            player:
                Yeah, what else is new?
            agent:
                After yesterday's debate, they conducted a poll to see who the people support.
                They asked {1} {1*person|people}. {2} responded.
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
                [p] The Grand Theater noticed your popularity, so they invited you to a one-on-one debate tonight.
            player:
                Cool.
        ]],
        DIALOG_PST_VOTES_BAD = [[
            agent:
                [p] There is supposed to be a one-on-one debate tonight at the Grand Theater, but you aren't invited because you aren't popular enough.
            player:
                What are we supposed to do, then?
            agent:
                We can't just ignore this prime opportunity.
                Just come tonight anyway. We will figure it out from here.
        ]],
        DIALOG_END = [[
            agent:
            {not has_potential_ally?
                {not advisor_favor?
                    Anyway, with that out of the way, let's go back to gathering support.
                    You have a long day ahead of you.
                }
                {advisor_favor?
                    Anyway, with that out of the way, there is something I want to ask you.
                }
            }
            {has_potential_ally?
                {not advisor_favor?
                    Anyway, with that out of the way, let's go back to gathering support...
                }
                {advisor_favor?
                    Anyway, with that out of the way, there is something I want to ask you...
                }
                * Before {agent} finishes {agent.hisher} sentence, you are interrupted by someone visiting.
            }
        ]],
    }
    :Fn(function(cxt)
        -- Generate advisor favor
        cxt.quest.param.previous_bad_debate = TheGame:GetGameState():GetMainQuest() and (TheGame:GetGameState():GetMainQuest().param.good_debate_scrum == false)
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
            local result = DemocracyUtil.SummarizeVotes(DemocracyUtil.SimulateVoting())
            local vote_result = {}
            local total_votes = 0
            for candidate, count in pairs(result.vote_count) do
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
                return b[1] ~= cxt.player
            end)
            cxt.quest.param.vote_result = vote_result
            cxt.enc.scratch.total_votes = total_votes
            if #vote_result > 0 then
                local best_votes = vote_result[2]
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
                        if i >= 3 and vote_result[i][2] < 0.6 * best_votes then
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
                if #low_vote_candidates == 0 and #vote_result >= 3 then
                    table.insert(low_vote_candidates, vote_result[i][1])
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
