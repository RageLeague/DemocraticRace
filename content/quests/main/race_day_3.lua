local QDEF = QuestDef.Define
{
    title = "Campaign Time",
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
    quest_id = "RACE_DEBATE_SCRUM",
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
    title = "Talk to {primary_advisor} about the plan.",
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
            * [p] You wake up.
            agent:
                Yo.
                Do work.
                If you don't, the opposition will.
        ]],
        DIALOG_INTRO_PST = [[
            player:
                I can see your point.
            agent:
                Also, do you know there's a debate coming?
                It's a good way to ally with other candidates. And a good way to gain support.
                In other words, it's very important.
            {has_potential_ally?
                {advisor_favor?
                    Oh, that reminds me.
                    There is something I want to ask of you...
                    |
                    Well, get to work...
                }
                * Before {agent} finishes {agent.hisher} sentence, you are interrupted by someone visiting.
            }
            {not has_potential_ally and advisor_favor?
                Oh, that reminds me.
                There is something I want to ask of you.
            player:
                Oh, what is it?
            }
            {not has_potential_ally and not advisor_favor?
                Well, get to work.
                The support is not going to gain itself.
            * {agent} leaves you to your own accord.
            }
        ]],
    }
    :Fn(function(cxt)

        -- Generate advisor favor
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
            local best_characters = {}
            local best_score = RELATIONSHIP.LIKED
            for id, data in pairs(DemocracyConstants.opposition_data) do
                local main_faction = data.main_supporter or "FEUD_CITIZEN"
                local val, reason = DemocracyUtil.GetAlliancePotential(id)
                -- quest:Trace("[%s] Val=%d, Reason=%s", id, val, reason)
                if val then
                    local endorsement = DemocracyUtil.GetEndorsement(val)
                    if endorsement >= best_score then

                        if endorsement > best_score then
                            best_score = endorsement
                            best_characters = {}
                        end

                        table.insert(best_characters, data)
                    end
                end
            end
            if #best_characters > 0 then
                local data = table.arraypick(best_characters)
                local agent = TheGame:GetGameState():GetMainQuest():GetCastMember(data.cast_id)
                cxt.enc.scratch.potential_ally = agent
                cxt.enc.scratch.ally_work_pos = data.workplace
                cxt.enc.scratch.ally_platform = data.platform
                cxt.enc.scratch.has_potential_ally = true

                if cxt.enc.scratch.ally_platform then
                    cxt.enc.scratch.stance_index = data.stances[cxt.enc.scratch.ally_platform]
                    if cxt.enc.scratch.ally_platform and cxt.enc.scratch.stance_index then
                        cxt.enc.scratch.ally_stance = cxt.enc.scratch.ally_platform .. "_" .. cxt.enc.scratch.stance_index
                    end
                end
            end
        end
        -- Actual stuff
        cxt:Dialog("DIALOG_INTRO")
        DemocracyUtil.TryMainQuestFn("DoRandomOpposition", 3)
        cxt:Dialog("DIALOG_INTRO_PST")
        if cxt.quest.param.has_potential_ally then
            cxt:GoTo("STATE_ALLIANCE")
        elseif cxt.enc.scratch.advisor_favor then
            cxt:GoTo("STATE_FAVOR")
        else
            cxt.quest:Complete("starting_out")
            StateGraphUtil.AddLeaveLocation(cxt)
        end
    end)
    :State("STATE_ALLIANCE")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    !right
                    [p] 'Sup.
                    Our platforms are very similar to each other.
                    Perhaps it's a good time to strike an alliance?
                primary_advisor:
                    !right
                    I'll leave you to it.
            ]],
            OPT_ACCEPT = "Accept",

            DIALOG_ACCEPT = [[
                player:
                    [p] You know what, I agree.
                    If we can work together, we will surely win!
                agent:
                    Excellent! That's the kind of stuff I like to hear!
                * You've agreed to ally with {agent}.
                agent:
                    Feel free to visit me at {ally_work_pos#location}.
                player:
                    Thanks.
                agent:
                    !exit
                * {agent} leaves, leaving you with {primary_advisor}.
            ]],
            OPT_DECLINE = "Decline",

            DIALOG_DECLINE = [[
                player:
                    [p] While that is a great offer, I have to decline, unfortunately.
                    Sorry if I offended you, but I want to keep my options open.
                agent:
                    I see.
                    It is a real shame.
                    Well, if you ever change your mind, visit me at {ally_work_pos#location}.
                player:
                    I'll keep that in mind, thanks.
                agent:
                    !exit
                * {agent} leaves, leaving you with {primary_advisor}.
            ]],

            DIALOG_CHOOSE_PST = [[
                agent:
                    !right
                * Your advisor comes to you.
                agent:
                {allied?
                    So you decided to ally with {potential_ally}?
                    Good for you.
                player:
                    I think it is the best course of action right now.
                agent:
                    I think so too.
                    Just beware that other candidates might not like this, and will never ally with you.
                player:
                    Well, let's see what happens.
                }
                {not allied?
                    So you decided to not ally with {potential_ally}?
                player:
                    I'm looking into more options before I make a decision.
                agent:
                    Perhaps that is the correct decision.
                    You can always find {potential_ally} later, although it will take up some of your time.
                player:
                    True.
                }
                agent:
                    Anyway, just keep gathering support and prepare for the debate tonight.
            ]],
        }
        :Fn(function(cxt)
            cxt.enc.scratch.potential_ally:MoveToLocation(cxt.location)
            cxt:TalkTo(cxt.enc.scratch.potential_ally)
            cxt:Dialog("DIALOG_INTRO")

            DemocracyUtil.DoAllianceConvo(cxt, cxt.enc.scratch.potential_ally, 15)

            -- cxt:Opt("OPT_ACCEPT")
            --     :PreIcon(global_images.accept)
            --     :Dialog("DIALOG_ACCEPT")
            --     -- :ReceiveOpinion(OPINION.ALLIED_WITH)
            --     :Fn(function(cxt)
            --         DemocracyUtil.TryMainQuestFn("SetAlliance", ally)
            --     end)
            --     :UpdatePoliticalStance(cxt.enc.scratch.ally_platform, cxt.enc.scratch.stance_index)
            --     :Fn(function(cxt)
            --         cxt.enc.scratch.allied = true
            --         DemocracyUtil.DoLocationUnlock(cxt, cxt.enc.scratch.ally_work_pos)
            --         cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
            --     end)
            --     :Dialog("DIALOG_CHOOSE_PST")
            --     :CompleteQuest("starting_out")
            --     :Fn(function(cxt)
            --         cxt.enc.scratch.potential_ally:MoveToLimbo()
            --     end)
            --     :Travel()

            -- cxt:Opt("OPT_DECLINE")
            --     :PreIcon(global_images.reject)
            --     :Dialog("DIALOG_DECLINE")
            --     :Fn(function(cxt)
            --         DemocracyUtil.DoLocationUnlock(cxt, cxt.enc.scratch.ally_work_pos)
            --         cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
            --     end)
            --     :Dialog("DIALOG_CHOOSE_PST")
            --     :CompleteQuest("starting_out")
            --     :Fn(function(cxt)
            --         cxt.enc.scratch.potential_ally:MoveToLimbo()
            --     end)
            --     :Travel()
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
                :Dialog("DIALOG_GET_JOB")
                :LoopingFn(function(cxt)
                    DemocracyUtil.TryMainQuestFn("OfferJobs", cxt, 3, "RALLY_JOB")
                end)
        end
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
                Alright. Good luck tomorrow.
                Tomorrow is going to be a big day, I can feel it.
            player:
                !shrug
                If you say so.
            agent:
                Well then, good night.
                !exit
        ]],
        DIALOG_WAKE = [[
            * According to {primary_advisor}, today is going to be a big day.
            * You are not sure if you are excited or nervous.
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
                player:
                    Not yet.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
