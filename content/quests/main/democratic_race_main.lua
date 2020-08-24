local LocUnlock = require "DemocraticRace:content/get_location_unlock"
local DAY_SCHEDULE = {
    {quest = "RACE_DAY_1", difficulty = 1},
    {quest = "RACE_DAY_2", difficulty = 2},
    -- {quest = "RACE_DAY_3", difficulty = 3},
    -- {quest = "RACE_DAY_4", difficulty = 4},
    -- {quest = "RACE_DAY_5", difficulty = 5},
}
local MAX_DAYS = #DAY_SCHEDULE-- 5
AddOpinionEvent("DISLIKE_IDEOLOGY", {
    delta = OPINION_DELTAS.OPINION_DOWN,
    txt = "Dislike your ideology",
})
local QDEF = QuestDef.Define
{
    title = "The Democratic Race",
    -- icon = engine.asset.Texture("icons/quests/sal_story_act1_huntingkashio.tex"),
    qtype = QTYPE.STORY,
    desc = "Become the president as you run a democratic campaign.",

    max_day = MAX_DAYS,
    get_narrative_progress = function(quest)
        
        local total_days = MAX_DAYS
        local completed_days = (quest.param.day or 1)-1

        local percent = completed_days / total_days
        local title = loc.format(LOC "CALENDAR.DAY_FMT", quest.param.day or 1)
        return percent, title, quest.param.day_quest and quest.param.day_quest:GetTitle() or ""
    end,
    on_init = function(quest)

        TheGame:GetGameState():SetMainQuest(quest)
        -- TheGame:GetGameState():SetRollbackThresh(1)

        TheGame:GetGameState():GetCaravan():MoveToLocation(TheGame:GetGameState():GetLocation("MURDERBAY_NOODLE_SHOP"))
        
        TheGame:GetGameState():AddLocation(Location("DIPL_PRES_OFFICE"))
        TheGame:GetGameState():AddLocation(Location("MANI_PRES_OFFICE"))
        TheGame:GetGameState():AddLocation(Location("HOST_PRES_OFFICE"))
        -- The level of which people support you. All the indifferent characters may or may not
        -- vote for you, depending on your support level.
        -- Also they determine a whole bunch of things. Very important to keep high.
        -- Just read the README
        quest.param.support_level = 0
        -- Your support among factions.
        -- This is stored as the support relative to the general support
        -- The displayed support level is already adjusted.
        quest.param.faction_support = {}
        -- Your support level among wealth levels.(renown levels)
        quest.param.wealth_support = {}
        -- The locations you've unlocked.
        quest.param.unlocked_locations = {"MURDERBAY_NOODLE_SHOP"}
        quest.param.free_time_actions = 1

        TheGame:GetGameState():GetPlayerAgent().graft_owner:AddGraft(GraftInstance("relation_support_tracker"))

        QuestUtil.StartDayQuests(DAY_SCHEDULE, quest)

        if quest.param.start_on_day and quest.param.start_on_day >= 2 then
            quest:AssignCastMember("primary_advisor", quest:GetCastMember(quest.param.force_advisor_id or table.arraypick(DemocracyUtil.ADVISOR_IDS)))
            quest:DefFn("DeltaGeneralSupport", (quest.param.init_support_level or 0) * (quest.param.start_on_day - 1))
        end
        
        QuestUtil.DoNextDay(DAY_SCHEDULE, quest, quest.param.start_on_day )
        
        DoAutoSave()
    end,
    plot_armour_fn = function(quest, agent)
        return agent:IsCastInQuest(quest)
    end,
    events = 
    {
        quests_changed = function(quest, event_quest) 
            if event_quest == quest.param.day_quest and quest.param.day_quest:IsComplete() then
                QuestUtil.DoNextDay(DAY_SCHEDULE, quest)
            end
        end,
    },
    SpawnPoolJob = function(quest, pool_name, spawn_as_inactive)
        local event_id = pool_name
        local attempt_quest_ids = {}
        for k, questdef in pairs( Content.GetAllQuests() ) do
            if --[[questdef.act_filter == "SMITH" and]] questdef:HasTag(pool_name) then
                table.insert(attempt_quest_ids, questdef.id)
            end
        end

        local quest_scores = {}
        for k,v in ipairs(attempt_quest_ids) do
            quest_scores[v] = QuestUtil.CalcQuestSpawnScore(event_id, math.floor(#attempt_quest_ids/2), v)    
        end
        table.shuffle(attempt_quest_ids) --to mix up the case where there are a lot of ties
        table.stable_sort(attempt_quest_ids, function(a,b) return quest_scores[a] < quest_scores[b] end)
        local new_quest
        for _, quest_id in ipairs(attempt_quest_ids) do
            local overrides = {qrank = TheGame:GetGameState():GetCurrentBaseDifficulty()}
            
            if spawn_as_inactive then
                new_quest = QuestUtil.SpawnInactiveQuest( quest_id, overrides) 
            else
                new_quest = QuestUtil.SpawnQuest( quest_id, overrides) 
            end
        
            if new_quest then
                TheGame:GetGameProfile():RecordIncident(event_id, new_quest:GetContentID())
                return new_quest
            end
        end

        return new_quest
    end,
    -- Offer jobs at certain point of the story.
    -- probably should always call this.
    OfferJobs = function(quest, cxt, job_num, pool_name)
        local jobs = {}
        for k = 1, job_num do
            local new_job = quest:DefFn("SpawnPoolJob", pool_name, true)
            if new_job then
                table.insert(jobs, new_job)
            end
        end
        QuestUtil.PresentJobChoice(cxt, jobs, true, function(cxt, jobs_presented, job_picked) 
            cxt.quest.param.current_job = job_picked
            cxt.quest:Complete("get_job")
            -- cxt.quest:Activate("do_job")
            --cxt:PlayQuestConvo(cxt.quest.param.job, QUEST_CONVO_HOOK.INTRO)
            StateGraphUtil.AddEndOption(cxt)
        end)
    end,
    DeltaGeneralSupport = function(quest, amt, ignore_notification)
        quest.param.support_level = (quest.param.support_level or 0) + amt
        if not ignore_notification and amt ~= 0 then
            TheGame:GetGameState():LogNotification( NOTIFY.DELTA_GENERAL_SUPPORT, amt, quest:DefFn("GetGeneralSupport") ) 
        end
    end,
    DeltaFactionSupport = function(quest, amt, faction, ignore_notification)
        quest.param.faction_support[faction] = (quest.param.faction_support[faction] or 0) + amt
        if not ignore_notification and amt ~= 0 then
            TheGame:GetGameState():LogNotification( NOTIFY.DELTA_FACTION_SUPPORT, amt, quest:DefFn("GetFactionSupport", faction), TheGame:GetGameState():GetFaction(faction) ) 
        end
    end,
    DeltaWealthSupport = function(quest, amt, renown, ignore_notification)
        quest.param.wealth_support[DemocracyUtil.GetWealth(renown)] = (quest.param.wealth_support[DemocracyUtil.GetWealth(renown)] or 0) + amt
        if not ignore_notification and amt ~= 0 then
            TheGame:GetGameState():LogNotification( NOTIFY.DELTA_WEALTH_SUPPORT, amt, quest:DefFn("GetWealthSupport", DemocracyUtil.GetWealth(renown)), DemocracyUtil.GetWealth(renown) ) 
        end
    end,
    DeltaFactionSupportAgent = function(quest, amt, agent, ignore_notification)
        quest:DefFn("DeltaFactionSupport", amt, agent:GetFactionID(), ignore_notification)
    end,
    DeltaWealthSupportAgent = function(quest, amt, agent, ignore_notification)
        quest:DefFn("DeltaWealthSupport", amt, agent:GetRenown() or 1, ignore_notification)
    end,
    DeltaGroupFactionSupport = function(quest, group_delta, multiplier, ignore_notification)
        for id, val in pairs(group_delta or {}) do
            quest:DefFn("DeltaFactionSupport", math.round(val * multiplier), id, ignore_notification)
        end
    end,
    DeltaGroupWealthSupport = function(quest, group_delta, multiplier, ignore_notification)
        for id, val in pairs(group_delta or {}) do
            quest:DefFn("DeltaWealthSupport", math.round(val * multiplier), id, ignore_notification)
        end
    end,
    -- Getters
    GetGeneralSupport = function(quest) return quest.param.support_level end,
    GetFactionSupport = function(quest, faction)
        return quest.param.support_level + (quest.param.faction_support[faction] or 0)
    end,
    GetWealthSupport = function(quest, renown)
        return quest.param.support_level + (quest.param.wealth_support[DemocracyUtil.GetWealth(renown)] or 0)
    end,
    GetCompoundSupport = function(quest, faction, renown)
        return quest.param.support_level + (quest.param.faction_support[faction] or 0) + (quest.param.wealth_support[DemocracyUtil.GetWealth(renown)] or 0)
    end,
    GetFactionSupportAgent = function(quest, agent)
        return quest:DefFn("GetFactionSupport", agent:GetFactionID())
    end,
    GetWealthSupportAgent = function(quest, agent)
        return quest:DefFn("GetWealthSupport", agent:GetRenown() or 1)
    end,
    GetSupportForAgent = function(quest, agent)
        return quest:DefFn("GetCompoundSupport", agent:GetFactionID(), agent:GetRenown() or 1)
    end,
    -- At certain points in the story, random peope dislikes you for no reason.
    -- call this function to do so.
    DoRandomOpposition = function(quest, num_to_do)
        num_to_do = num_to_do or 1
        for i = 1, num_to_do do
            if quest:GetCastMember("random_opposition") then
                quest:UnassignCastMember("random_opposition")
            end
            quest:AssignCastMember("random_opposition")
            quest:GetCastMember("random_opposition"):OpinionEvent(OPINION.DISLIKE_IDEOLOGY)
            quest:UnassignCastMember("random_opposition")
        end
    end,

    -- Calculate the funding level for the day using this VERY scientific calculation based on wealth support.
    CalculateFunding = function(quest, rate)
        rate = rate or 1
        local money = 0
        for i = 1, DemocracyConstants.wealth_levels do
            money = money + quest:DefFn("GetWealthSupport", i) * i
        end
        money = money / 10
        money = money + 50
        money = math.max(0, money)
        return math.round(money * rate)
    end,
}
:AddCast{
    cast_id = "random_opposition",
    when = QWHEN.MANUAL,
    score_fn = DemocracyUtil.OppositionScore,
    condition = function(agent, quest)
        return agent:GetRelationship() < RELATIONSHIP.LOVED and agent:GetRelationship() > RELATIONSHIP.DISLIKED
    end,
}
:AddCast{
    cast_id = "primary_advisor",
    when = QWHEN.MANUAL,
    no_validation = true,
    on_assign = function(quest,agent)
        quest:AssignCastMember("home")
        if quest.param.all_day_quests then
            for k,v in ipairs(quest.param.all_day_quests) do
                if v:GetQuestDef():GetCast("primary_advisor") then
                    v:AssignCastMember("primary_advisor", quest:GetCastMember("primary_advisor"))
                end
            end
        end
    end,
}
:AddCastByAlias{
    -- Let fssh be the bartender of grog n dog
    cast_id = "fssh",
    alias = "FSSH",
    on_assign = function(quest, agent)
        local location = TheGame:GetGameState():GetLocation("GROG_N_DOG")
        if agent:GetBrain():GetWorkPosition() == nil and location then
            AgentUtil.TakeJob(agent, location, "bartender")
            -- agent:GetBrain():SetHome(location)
        end
    end,
}
-- Have to do this to make plot_armour_fn work.
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}

DemocracyUtil.AddAdvisors(QDEF)
DemocracyUtil.AddHomeCasts(QDEF)
DemocracyUtil.AddOppositionCast(QDEF)

-- A fail safe. Once you've been to a unlockable location that hasn't been unlocked, you unlock it.
QDEF:AddConvo()
    :ConfrontState("STATE_UNLOCK", function(cxt)
        local id = cxt.location:GetContentID()
        return id and table.arraycontains(LocUnlock.FACTION_LOCATION_UNLOCK.GRIFTER, id) 
            and not table.arraycontains(cxt.quest.param.unlocked_locations, id)
    end)
    :Loc{
        DIALOG_NEW_LOCATION = [[
            * You've never been here before. Nice!
            * After you're done with this ordeal, you can visit this location during your free time.
        ]]
    }
    :Fn(function(cxt)
        cxt:Dialog("DIALOG_NEW_LOCATION")
        DemocracyUtil.DoLocationUnlock(cxt, cxt.location:GetContentID())
    end)

QDEF:AddDebugOption("start_on_day", {1,2})
    :AddDebugOption(
        "force_advisor_id",
        copykeys(DemocracyUtil.ADVISOR_IDS),
        function(param) return param.start_on_day and param.start_on_day >= 2 end
    )
    :AddDebugOption(
        "init_support_level",
        {0,10,15,20,25,30,40},
        function(param) return param.start_on_day and param.start_on_day >= 2 end
    )