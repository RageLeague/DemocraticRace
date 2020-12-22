local NOON_QUEST_PRIORITY =
{
    RACE_ALLIANCE_TALK = 10,
    RACE_ADVISOR_FAVOR = 10,
    RACE_DAY_3_NOON_GENERIC = 0,
}

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
-- :AddSubQuest{
--     id = "meet_opposition",
--     quest_id = "RACE_INTRODUCE_OPPOSITION",
--     on_activate = function(quest)
--         DemocracyUtil.SetSubdayProgress(2)
--     end,
--     on_complete = function(quest)
--         DemocracyUtil.StartFreeTime()
--         quest:Activate("get_job")
--     end,
-- }
:AddObjective{
    -- we want to branch out during the noon now that new mechanics are all introduced.
    -- If the advisor likes you, you can start a request quest with them.
    -- If your ideal align with an existing candidate, you can talk about alliances.
    -- Otherwise, do something else, idk.
    id = "noon_event",
    on_activate = function(quest)
        DemocracyUtil.SetSubdayProgress(2)
        local potential_subquests = copykeys(NOON_QUEST_PRIORITY)
        table.shuffle(potential_subquests)

        table.stable_sort(sorted, function(a, b) 
            return (NOON_QUEST_PRIORITY[a] or 0) > (NOON_QUEST_PRIORITY[b] or 0)
        end)
        for i, id in ipairs(potential_subquests) do
            quest.param.noon_subquest = QuestUtil.SpawnQuest( id )
            if quest.param.noon_subquest then
                return
            end
        end
        assert_warning(quest.param.noon_subquest, "No noon subquest spawned.")
        if not quest.param.noon_subquest then
            quest:Complete("noon_event")
        end
    end,
    events = {
        quests_changed = function(quest, event_quest)
    
            if quest.param.noon_subquest == event_quest then
                if not event_quest:IsActive() then
                    quest:Complete(child.id)
                end
            end
        end
    },
    on_complete = function(quest)
        DemocracyUtil.StartFreeTime()
        quest:Activate("get_job")
    end,
}
:AddSubQuest{
    id = "do_debate",
    quest_id = "RACE_DEBATE_SCRUM",
    -- mark = {"primary_advisor"},
    on_activate = function(quest)
        UIHelpers.PassTime(DAY_PHASE.NIGHT)
        DemocracyUtil.SetSubdayProgress(3)
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
        DemocracyUtil.SetSubdayProgress(4)
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

        if (#quest.param.job_history == 1) then 
            quest:Activate("meet_opposition")
        elseif (#quest.param.job_history >= 2) then
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
        ]],
    }
    :Fn(function(cxt)

        cxt:Dialog("DIALOG_INTRO")
        DemocracyUtil.TryMainQuestFn("DoRandomOpposition", 3)
        cxt:Dialog("DIALOG_INTRO_PST")
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
                -- local grog = cxt.location
                -- cxt.encounter:DoLocationTransition( cxt.quest:GetCastMember("player_room") )
                -- grog:SetPlax()
                DemocracyUtil.DoAlphaMessage()
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
