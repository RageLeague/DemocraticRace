
local QDEF = QuestDef.Define
{
    title = "Establish Authority",
    desc = "Let people know you're running for president, and gain some support among the people.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/day_1.png"),

    qtype = QTYPE.STORY,

    on_start = function(quest)
        quest:Activate("starting_out")
        DemocracyUtil.SetSubdayProgress(1)
    end,
}
:Loc{
    GET_JOB_ALONE = "Think of a way to gain support.",
    GET_JOB_ADVISOR = "Discuss with {primary_advisor} about how to gain support.",
}
:AddSubQuest{
    id = "starting_out",
    quest_id = "RACE_INITIAL_BAR_DEBATE",
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
            if quest.param.current_job == event_quest and event_quest:IsDone() then
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

        if (#quest.param.job_history == 1) then
            quest:Activate("meet_advisor")
        elseif (#quest.param.job_history >= 2) then
            quest:Activate("do_summary")
        else
            quest:Activate("get_job")
        end
    end,

}
:AddSubQuest{
    id = "meet_advisor",
    quest_id = "RACE_MEET_ADVISOR",
    on_activate = function(quest)
        DemocracyUtil.SetSubdayProgress(2)
    end,
    on_complete = function(quest)
        DemocracyUtil.StartFreeTime()
        quest:Activate("get_job")
    end,
}
:AddSubQuest{
    id = "do_summary",
    quest_id = "RACE_DAY_END_SUMMARY",
    on_activate = function(quest)
        UIHelpers.PassTime(DAY_PHASE.NIGHT)
        DemocracyUtil.SetSubdayProgress(3)
    end,
    on_complete = function(quest)
        quest:Activate("sleep")
    end,
}
:AddSubQuest{
    id = "sleep",
    quest_id = "RACE_DAY_1_SLEEP",
    title = "Go to sleep",
    desc = "It's been a long day. You should go to bed.",
    on_activate = function(quest)
        DemocracyUtil.StartFreeTime()
    end,
    on_complete = function(quest)
        quest:Complete()
    end,
}
-- :AddCast{
--     cast_id = "primary_advisor",
--     when = QWHEN.MANUAL,
--     cast_fn = function(quest, t)
--         table.insert(t, TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor"))
--     end,
--     no_validation = true,
-- }
DemocracyUtil.AddPrimaryAdvisor(QDEF)
QDEF:AddConvo("get_job")
    :Loc{
        OPT_GET_JOB = "Find a way to gather support...",

    }
    :Hub_Location(function(cxt)
        if not cxt.quest:GetCastMember("primary_advisor") then
            cxt.quest:AssignCastMember("primary_advisor")
        end
        if not cxt.quest:GetCastMember("primary_advisor") then
            cxt:Opt("OPT_GET_JOB")
                :SetQuestMark()
                :Fn( function(cxt)
                    UIHelpers.DoSpecificConvo( cxt.quest:GetCastMember("oshnu"), cxt.convodef.id, "STATE_GET_JOB" ,nil,nil,cxt.quest)
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