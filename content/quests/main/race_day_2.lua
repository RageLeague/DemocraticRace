local QDEF = QuestDef.Define
{
    title = "Campaign Time",
    desc = "Continue to campaign and gain support among the people.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/day_2.png"),

    qtype = QTYPE.STORY,

    on_start = function(quest)
        quest:Activate("starting_out")
        DemocracyUtil.SetSubdayProgress(1)
        TheGame:GetGameState():GetPlayerAgent():MoveToLocation( quest:GetCastMember("home") )
    end,
}
:Loc{
    GET_JOB_ALONE = "Think of a way to gain support.",
    GET_JOB_ADVISOR = "Discuss with {primary_advisor} about how to gain support.",
}
:AddSubQuest{
    id = "meet_opposition",
    quest_id = "RACE_INTRODUCE_OPPOSITION",
    -- on_activate = function(quest)
    --     DemocracyUtil.SetSubdayProgress(2)
    -- end,
    on_complete = function(quest)
        DemocracyUtil.StartFreeTime()
        quest:Activate("get_job")
    end,
}
:AddSubQuest{
    id = "do_interview",
    quest_id = "RACE_INTERVIEW",
    mark = {"primary_advisor"},
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
    on_complete = function(quest)
        quest:Activate("meet_opposition")
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
        DemocracyUtil.EndFreeTime()
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
            quest:Activate("do_interview")
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
            {not dead_body?
                * As you wake up, you look to see {primary_advisor} staring you down while you slept and shaking your arm.
                * Naturally, you make the most dignified sound you could think of.
                player:
                    Gah! Could you not let me get some shuteye?
                primary_advisor:
                    Their ain't no shuteye for the wicked, and neither to their advisors.
                    I spent all night setting up an interview for you to get some more publicity with the masses.
                    The least you can do is pretend you're pulling your weight!
                player:
                    okay, okay. When's the interview scheduled?
                primary_advisor:
                    Later tonight.
                player:
                    So why'd you wake me up this early?
                primary_advisor:
                    Because the voters don't want to see you sleeping on the job.
                    No politician had gotten far by lazing about their home.
                    The opposition was working hard through the night, and some of the voters have already turned on us.
            }
            {dead_body?
                primary_advisor:
                    !angry
                * As you wake up, you see {primary_advisor} staring at you, angrily.
                primary_advisor:
                    I've been gone for one night, and there's already {1:a dead body|not one, but TWO dead bodies|a bunch of dead bodies} lying in your room.
                    Care to explain?
                player:
                    I'm sorry. I was <i>trying</> to not get murdered by an assassin.
                    It is legitimate self defense.
                primary_advisor:
                {1:
                    People might not think that way.
                    Why else would a dead body in your room?
                    There's an interview coming up, and you're just here throwing your reputation away.
                player:
                    !surprised
                    Wait, there's an interview coming? When is that?
                primary_advisor:
                    Tonight.
                    While you're trying to make yourself look bad, your opponents are already hard at work turning some voters against us.
                    |
                    That doesn't explain the <i>other</> dead body in Admiralty uniform.
                player:
                    !bashful
                    Oh yeah, I might have... resisted arrest a little.
                primary_advisor:
                    What the Hesh, {player}?
                    An interview is coming up, and you're just murdering people left and right!
                    How is anyone going to vote you now?
                player:
                    !handwave
                    I'm sure it'll be fine. Not many people like the Admiralty anyway.
                    But what is this interview you've mentioned?
                primary_advisor:
                    It is scheduled tonight to interview you on your political opinion.
                    It's meant to help you gain support!
                    Considering your opposition is working hard to turn voters against us.
                }
            }
        ]],
        DIALOG_INTRO_PST = [[
            player:
                Ah Hesh, People are turning on us that quickly?
            primary_advisor:
                Well yeah! Voting day is in a matter of days, and people are only looking up from their work now.
                The image you have now is a lot more impactful than it was before.
                Speaking of which, there is someone who wants to speak with you.
            * [p] Oh look, there they are.
            * Better greet them.
        ]],
    }
    :Fn(function(cxt)
        local dead_bodies = cxt:GetCastMember("player_room"):HasMemory("HAS_DEAD_BODY")

        cxt.enc.scratch.dead_body = dead_bodies and true
        cxt:Dialog("DIALOG_INTRO", dead_bodies and #dead_bodies)
        DemocracyUtil.TryMainQuestFn("DoRandomOpposition", 2)
        cxt:Dialog("DIALOG_INTRO_PST")
        cxt:GetCastMember("player_room"):Forget("HAS_DEAD_BODY")
        cxt.quest:Complete("starting_out")
        StateGraphUtil.AddEndOption(cxt)
    end)

QDEF:AddConvo("get_job")
    :ConfrontState("STATE_CONFRONT", function(cxt)
        if not cxt.quest:GetCastMember("primary_advisor") then
            cxt.quest:AssignCastMember("primary_advisor")
        end
        return not (cxt.quest:GetCastMember("primary_advisor") and true or false)
    end)
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
                !thought
                $neutralThoughtful
                Here's what I can do...
            ]],

    }
    :RunLoopingFn(function(cxt)
        cxt:Dialog("DIALOG_INTRO")
        DemocracyUtil.TryMainQuestFn("OfferJobs", cxt, 3, "RALLY_JOB")
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
                I promise there won't be another assassin.
            player:
                Yeah that would be too repetitive.
            agent:
                Well then, good night.
                !exit
        ]],
        DIALOG_WAKE = [[
            * Another day, another battle.
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

                ConvoUtil.DoSleep(cxt, "DIALOG_WAKE")

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
