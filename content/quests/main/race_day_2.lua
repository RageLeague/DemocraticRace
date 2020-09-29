local QDEF = QuestDef.Define
{
    title = "Campaign Time",
    desc = "Continue to campaign and gain support among the people.",

    qtype = QTYPE.STORY,

    on_start = function(quest)
        quest:Activate("starting_out")
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
    on_complete = function(quest)
        quest:Activate("get_job")
    end,
}
:AddSubQuest{
    id = "do_interview",
    quest_id = "RACE_INTERVIEW",
    on_activate = function(quest)
        UIHelpers.PassTime(DAY_PHASE.NIGHT)
    end,
    on_complete = function(quest)
        quest:Activate("go_to_sleep")
    end,
}
:AddObjective{
    id = "go_to_sleep",
    title = "Go to sleep",
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
        quest:Activate("get_job")
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
    on_activate = function(quest)
        DemocracyUtil.StartFreeTime()
    end,
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
    end,
    on_complete = function(quest) 
        quest.param.job_history = quest.param.job_history or {}
        table.insert(quest.param.job_history, quest.param.current_job)
        quest.param.recent_job = quest.param.current_job
        quest.param.current_job = nil

        if (#quest.param.job_history == 1) then 
            quest:Activate("meet_opposition")
        elseif (#quest.param.job_history >= 2) then
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
            * [p] As you wake up, you look to see {primary_advisor} staring you down while you slept and shaking your arm.
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
        ]],
        DIALOG_INTRO_PST = [[
            player:
                Ah Hesh, People are turning on us that quickly?
            primary_advisor:
                Well yeah! Voting day is in a matter of days, and people are only looking up from their work now.
                The image you have now is a lot more impactful than it was before.
                Hey! Wake up!
            * You suddenly snap awake, realizing you we're drifting off.
            primary_advisor:
                What's got you running on fumes today?
            player:
                Well it might have to do with how I was awoken by the gentle touch of a hired assasain.
            primary_advisor:
                Hesh, really? How did I not know?
            player:
                Well, you we're in your office, setting up this oh-so important interview.
            primary_advisor:
                Impossible, I am the advisor. I see ALL.
                I can get a few contractors to fix up the office, maybe keep the building safer.
                But you, on your daily jaunts, won't be so lucky.
                How about you hire a bodyguard? Some'll do it for cheap, especially if you promise them job security and such.
            player:
                That actually sounds like a good idea. There's a first for everything.
            primary_advisor:
                Yes,Yes, laud me later. Now get in the bathroom, you smell like a puss-matted vroc.
            * With {primary_advisor} yelling to you about details with the interview, you clean yourself up and get ready for another stressful day.
            ** You can now hire bodyguards!
        ]],
    }
    :Fn(function(cxt)
        cxt:Dialog("DIALOG_INTRO")
        DemocracyUtil.TryMainQuestFn("DoRandomOpposition", 3)
        cxt:Dialog("DIALOG_INTRO_PST")
        QuestUtil.SpawnQuest("CAMPAIGN_BODYGUARD")
        cxt.quest:Complete("starting_out")
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
    :Fn(function(cxt)
        cxt:Dialog("DIALOG_INTRO")
        DemocracyUtil.TryMainQuestFn("OfferJobs", cxt, 2, "RALLY_JOB")
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
            :Dialog("DIALOG_GET_JOB")
            :Fn(function(cxt)
                DemocracyUtil.TryMainQuestFn("OfferJobs", cxt, 2, "RALLY_JOB")
            end)
    end)
QDEF:AddConvo("go_to_sleep", "primary_advisor")
    :Loc{
        DIALOG_GO_TO_SLEEP = [[
            player:
                [p] you win. i'm going to sleep.
            agent:
                i'm glad you understand
                !exit
            player:
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
                -- local grog = cxt.location
                -- cxt.encounter:DoLocationTransition( cxt.quest:GetCastMember("player_room") )
                -- grog:SetPlax()
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
                    [p] aren't you tired? go to sleep?
                player:
                    who are you, morgana?
                * just imagine {agent} is switched to the cat from persona 5.
                agent:
                    yes
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
