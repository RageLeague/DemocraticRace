local LocUnlock = require "DEMOCRATICRACE:content/get_location_unlock"
local fun = require "util/fun"
local negotiation_defs = require "negotiation/negotiation_defs"
local EVENT = negotiation_defs.EVENT

local battle_defs = require "battle/battle_defs"
local BATTLE_EVENT = battle_defs.BATTLE_EVENT

local t = {}
t.RISE_DISGUISE_BUILDS = {
    -- DEFAULT = "LABORER",
    RISE_REBEL = "LABORER",
    RISE_REBEL_PROMOTED = "LABORER_PROMOTED",
    RISE_PAMPHLETEER = "LABORER",
    RISE_RADICAL = "HEAVY_LABORER",
    RISE_VALET = "PEARLIE",
}

t.SPAWN_NAMED_CHAR = {
    FSSH = {workplace = "GROG_N_DOG", workpos = "bartender"},
    HESH_AUCTIONEER = {workplace = "GRAND_THEATER", workpos = "host"},
    HEBBEL = {workplace = "GB_NEUTRAL_BAR", workpos = "bartender"},
    SWEET_MOREEF = {workplace = "MOREEF_BAR", workpos = "bartender"},
    -- ENDO = {workplace = "MARKET_STALL", workpos = "negotiation_shop"},
    -- RAKE = {workplace = "MARKET_STALL", workpos = "battle_shop"},
    -- PLOCKA = {workplace = "MARKET_STALL", workpos = "graft_shop"},
    -- BEASTMASTER = {workplace = "MARKET_STALL", workpos = "beastmaster_shop"},
}

local function InitNamedChars()
    for id, data in pairs(t.SPAWN_NAMED_CHAR) do
        local agent = TheGame:GetGameState():GetAgentOrMemento( id )
        if not agent then
            print("Initializing: " .. id)
            agent = TheGame:GetGameState():AddSkinnedAgent(id)
        end
        local location = TheGame:GetGameState():GetLocation(data.workplace)
        if agent:GetBrain():GetWorkPosition() == nil and location then
            AgentUtil.TakeJob(agent, location, data.workpos)
            -- agent:GetBrain():SetHome(location)
        end
    end
end

t.DAY_SCHEDULE = {
    {quest = "RACE_DAY_1", difficulty = 1, support_expectation = {0,10,20}},
    {quest = "RACE_DAY_2", difficulty = 2, support_expectation = {23,38,55}},
    {quest = "RACE_DAY_3", difficulty = 3, support_expectation = {60,80,100}},
    {quest = "RACE_DAY_4", difficulty = 4, support_expectation = {105,130,155}},
    -- {quest = "RACE_DAY_5", difficulty = 5},
}

t.MAX_DAYS = #t.DAY_SCHEDULE-- 5

------------------------------------------------------------------------------------------------

-- Determines the support level change when an agent's relationship changes.
-- The general support changes by this amount, while the faction and wealth support changes by double this amount.
t.DELTA_SUPPORT = {
    [RELATIONSHIP.LOVED] = 6,
    [RELATIONSHIP.LIKED] = 3,
    [RELATIONSHIP.NEUTRAL] = 0,
    [RELATIONSHIP.DISLIKED] = -3,
    [RELATIONSHIP.HATED] = -6,
}
-- Determines the support level change when an agent is killed.
-- t.DEATH_DELTA = -10
t.DEATH_GENERAL_DELTA = -3

-- -- Determines the support level change when an agent is killed in an isolated scenario.
-- -- Still reduce support, but people won't know for sure it's you.
-- t.ISOLATED_DEATH_DELTA = -2
-- t.ISOLATED_DEATH_GENERAL_DELTA = -1

-- Determines the support change if you didn't kill someone, but you're an accomplice
-- or someone dies from negligence
t.ACCOMPLICE_KILLING_DELTA = -3
t.ACCOMPLICE_KILLING_GENERAL_DELTA = -1
local QDEF = QuestDef.Define
{
    title = "The Democratic Race",
    -- icon = engine.asset.Texture("icons/quests/sal_story_act1_huntingkashio.tex"),
    qtype = QTYPE.STORY,
    desc = "Become the president as you run a democratic campaign.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/main_icon.png"),

    act_filter = "SAL_DEMOCRATIC_RACE",

    max_day = t.MAX_DAYS,
    get_narrative_progress = function(quest)

        local total_days = t.MAX_DAYS
        local completed_days = (quest.param.day or 1)-1

        local sub_day_progress = (quest.param.sub_day_progress or 1) - 1
        local max_subdays = #(quest:DefFn("GetCurrentExpectationArray"))

        local percent = (completed_days + sub_day_progress / max_subdays) / total_days
        local title = loc.format(LOC "CALENDAR.DAY_FMT", quest.param.day or 1)
        return percent, title, quest.param.day_quest and quest.param.day_quest:GetTitle() or ""
    end,
    on_init = function(quest)

        TheGame:GetGameState():SetMainQuest(quest)
        -- TheGame:GetGameState():SetRollbackThresh(1)
        InitNamedChars()
        TheGame:GetGameState():GetCaravan():MoveToLocation(TheGame:GetGameState():GetLocation("MURDERBAY_NOODLE_SHOP"))

        -- TheGame:GetGameState():AddLocation(Location("DIPL_PRES_OFFICE"))
        -- TheGame:GetGameState():AddLocation(Location("MANI_PRES_OFFICE"))
        -- TheGame:GetGameState():AddLocation(Location("HOST_PRES_OFFICE"))
        -- The level of which people support you. All the indifferent characters may or may not
        -- vote for you, depending on your support level.
        -- Also they determine a whole bunch of things. Very important to keep high.
        -- Just read the README
        quest.param.support_level = 0

        quest.param.support_gain_source = {}
        quest.param.support_loss_source = {}
        -- Your support among factions.
        -- This is stored as the support relative to the general support
        -- The displayed support level is already adjusted.
        quest.param.faction_support = {}

        quest.param.faction_support_gain_source = {}
        quest.param.faction_support_loss_source = {}
        -- Your support level among wealth levels.(renown levels)
        quest.param.wealth_support = {}

        quest.param.wealth_support_gain_source = {}
        quest.param.wealth_support_loss_source = {}
        -- The locations you've unlocked.
        quest.param.unlocked_locations = {"MURDERBAY_NOODLE_SHOP"}

        -- quest.param.free_time_actions = 1

        quest.param.stances = {}
        quest.param.stance_change = {}
        quest.param.stance_change_freebie = {}

        -- We shouldn't change the faction's relationship. We should specify relationship between candidates instead so we don't change functionalities of locations.
        local relationship_maps = {
            [ RELATIONSHIP.HATED ] = OPINION.DISLIKE_IDEOLOGY_II,
            [ RELATIONSHIP.DISLIKED ] = OPINION.DISLIKE_IDEOLOGY,
            [ RELATIONSHIP.LIKED ] = OPINION.SHARE_IDEOLOGY,
        }

        for id, data in pairs(DemocracyConstants.opposition_data) do
            if data.relationship then
                for other_id, rel in pairs(data.relationship) do
                    local agent = quest:GetCastMember(id)
                    local other_agent = quest:GetCastMember(other_id)
                    local delta = relationship_maps[rel]
                    if agent and other_agent and delta then
                        agent:OpinionEvent(delta, nil, other_agent)
                    end
                end
            end
        end
        -- local new_faction_relationships = {
        --     {"BANDITS", "SPARK_BARONS", RELATIONSHIP.DISLIKED},
        --     {"BANDITS", "CULT_OF_HESH", RELATIONSHIP.DISLIKED},
        --     {"BANDITS", "FEUD_CITIZEN", RELATIONSHIP.DISLIKED},
        --     {"SPARK_BARONS", "CULT_OF_HESH", RELATIONSHIP.HATED},
        --     {"ADMIRALTY", "RISE", RELATIONSHIP.HATED},
        --     -- {"BANDITS", "RISE", RELATIONSHIP.DISLIKED},
        --     {"BANDITS", "JAKES", RELATIONSHIP.LIKED},
        --     {"ADMIRALTY", "CULT_OF_HESH", RELATIONSHIP.LIKED},
        --     {"ADMIRALTY", "SPARK_BARONS", RELATIONSHIP.LIKED},
        --     {"JAKES", "SPARK_BARONS", RELATIONSHIP.LIKED},
        --     {"JAKES", "ADMIRALTY", RELATIONSHIP.NEUTRAL},
        --     {"JAKES", "CULT_OF_HESH", RELATIONSHIP.DISLIKED},
        --     {"FEUD_CITIZEN", "RISE", RELATIONSHIP.LIKED},
        -- }
        -- for i, data in ipairs(new_faction_relationships) do
        --     TheGame:GetGameState():GetFactions():SetFactionRelationship(table.unpack(data))
        -- end

        -- quest.param.allow_skip_side = true

        -- TheGame:GetGameState():GetPlayerAgent().graft_owner:AddGraft(GraftInstance("democracy_resolve_limiter"))

        if quest.param.start_on_day and quest.param.start_on_day >= 2 then
            quest:AssignCastMember("primary_advisor", quest:GetCastMember(quest.param.force_advisor_id or table.arraypick(copykeys(DemocracyUtil.ADVISOR_IDS))))
            print(quest:GetCastMember("primary_advisor"))
            print(quest:GetCastMember("home"))
            print(quest:GetCastMember("player_room"))
            QuestUtil.SpawnQuest("RACE_LIVING_WITH_ADVISOR")
            quest:DefFn("DeltaGeneralSupport", quest:DefFn("GetCurrentExpectation", quest.param.start_on_day))
            quest.param.enable_support_screen = true
            if quest.param.start_on_day >= 3 then
                QuestUtil.SpawnQuest("CAMPAIGN_NEGOTIATE_ALLIANCES")
                QuestUtil.SpawnQuest("CAMPAIGN_BODYGUARD")
            end
        end

        QuestUtil.SpawnQuest("CAMPAIGN_SHILLING")

        -- Rook now has his flourish. This isn't necessary anymore.
        -- QuestUtil.SpawnQuest("CAMPAIGN_RANDOM_COIN_FIND")
        QuestUtil.SpawnQuest("CAMPAIGN_ASK_LOCATION")
        QuestUtil.SpawnQuest("LOCATION_OSHNUDROME_RACES")
        QuestUtil.SpawnQuest("LOCATION_PARTY_STORE")
        QuestUtil.SpawnQuest("DEM_LOCATION_HEALING")

        QuestUtil.SpawnQuest("SAL_STORY_MERCHANTS")
        -- populate all locations.
        -- otherwise there's a lot of bartenders attending the first change my mind quest for some dumb reason.
        -- for i, location in TheGame:GetGameState():AllLocations() do
        --     LocationUtil.PopulateLocation( location )
        -- end
        local population_count = {}
        for i, agent in TheGame:GetGameState():Agents() do
            local id = agent:GetContentID()
            population_count[id] = (population_count[id] or 0) + 1
        end
        local summon_people = {}
        for i, id in ipairs(TheGame:GetGameState().region:GetContent().population) do
            local content = Content.GetCharacterDef( id )
            local threshold = math.ceil((6 - (content.renown or 1)) / 2)
            while (population_count[id] or 0) < threshold do
                population_count[id] = (population_count[id] or 0) + 1
                table.insert(summon_people, id)
            end
        end
        table.shuffle(summon_people)
        for i, id in ipairs(summon_people) do
            local agent = TheGame:GetGameState():AddSkinnedAgent(id)
            agent:AddTag("NO_AUTO_CULL")
            if math.random() < 0.5 then
                AgentUtil.PutAgentInWorld(agent)
            end
        end

        -- DBG(population_count)
        QuestUtil.StartDayQuests(t.DAY_SCHEDULE, quest)
        QuestUtil.DoNextDay(t.DAY_SCHEDULE, quest, quest.param.start_on_day )
        quest:DefFn("on_post_load")
        DoAutoSave()
    end,
    plot_armour_fn = function(quest, agent)
        return agent:IsCastInQuest(quest)
    end,
    on_post_load = function(quest)
        if not quest.param.local_file_settings then
            quest.param.local_file_settings = {}
        end
        for i, id in ipairs(DemocracyUtil.GetPerFileSettings()) do
            if not quest.param.local_file_settings[id] then
                quest.param.local_file_settings[id] = DemocracyUtil.GetModSetting(id)
            end
        end
        -- For backwards compatibility. Transfer the appropriate fields.
        local change_fields = {"stances", "stance_change", "stance_change_freebie"}
        if quest.param.stances.ARTIFACT_TREATMENT then
            for i, field in ipairs(change_fields) do
                quest.param[field].RELIGIOUS_POLICY = quest.param[field].ARTIFACT_TREATMENT
                quest.param[field].ARTIFACT_TREATMENT = nil
            end
        end

        local required_quests = {"CAMPAIGN_SHILLING", "CAMPAIGN_ASK_LOCATION", "LOCATION_OSHNUDROME_RACES", "LOCATION_PARTY_STORE", "SAL_STORY_MERCHANTS", "DEM_LOCATION_HEALING"}
        for i, id in ipairs(required_quests) do
            if #TheGame:GetGameState():GetActiveQuestWithContentID(id) == 0 then
                QuestUtil.SpawnQuest(id)
            end
        end

        if not quest.param.first_primary_advisor and quest:GetCastMember("primary_advisor") then
            quest.param.first_primary_advisor = quest:GetCastMember("primary_advisor")
        end
    end,
    fill_out_quip_tags = function(quest, tags, agent)
        table.insert_unique(tags, "democratic_race")
        local wealth_tags = { "lower_class", "middle_class", "upper_class", "elite_class" }
        if wealth_tags[DemocracyUtil.GetWealth(agent)] then
            table.insert_unique(tags, wealth_tags[DemocracyUtil.GetWealth(agent)])
        end
        if agent == quest:GetCastMember("primary_advisor") then
            table.insert_unique(tags, "primary_advisor")
        end
        if quest:GetCastMember("primary_advisor") == quest:GetCastMember("advisor_diplomacy") then
            table.insert_unique(tags, "primary_advisor_diplomacy")
        end
        if quest:GetCastMember("primary_advisor") == quest:GetCastMember("advisor_manipulate") then
            table.insert_unique(tags, "primary_advisor_manipulate")
        end
        if quest:GetCastMember("primary_advisor") == quest:GetCastMember("advisor_hostile") then
            table.insert_unique(tags, "primary_advisor_hostile")
        end
        for id, data in pairs(quest.param.stances or {}) do
            if id and data then
                if data > 0 then
                    table.insert_unique(tags, "pro_" .. string.lower(id))
                elseif data < 0 then
                    table.insert_unique(tags, "anti_" .. string.lower(id))
                end
            end
        end
        if quest:DefFn("GetGameplayStats", "PAID_SHILLS") >= 5 then
            table.insert_unique(tags, "many_paid_shills")
        end
        if quest:DefFn("GetGameplayStats", "ARRESTED_PEOPLE_TIMES") >= 2 then
            table.insert_unique(tags, "many_arrests_made")
        end
        if (quest.param.drinks_today or 0) == 0 then
            table.insert_unique(tags, "player_sober_today")
        end
        if TheGame:GetGameState():GetPlayerAgent() then
            local player = TheGame:GetGameState():GetPlayerAgent()
            local num_drunks = (player.battler and player.battler:GetCardCount("drunk") or 0) + (player.negotiator and player.negotiator:GetCardCount("drunk_player") or 0)
            if num_drunks >= 3 then
                table.insert_unique(tags, "player_drunk")
            end
        end
    end,
    events =
    {
        -- GAME_OVER = function( self, gamestate, result )
        --     if result == GAMEOVER.VICTORY then
        --         TheGame:GetGameProfile():AcquireUnlock("DONE_POLITICS_BEFORE")
        --         print("YAY we did it!")
        --     end
        -- end,
        agent_location_changed = function(quest, agent, old_loc, new_loc)
            -- if event == "agent_location_changed" then
                -- print("location change triggered")
                local disguise = t.RISE_DISGUISE_BUILDS[agent:GetContentID()]
                if disguise then
                    print("Has disguise yay!" .. disguise)
                    if DemocracyUtil.IsWorkplace(new_loc) or new_loc:GetContentID() == "GB_LABOUR_OFFICE" then
                        local new_build = Content.GetCharacterDef(disguise).base_builds[agent.gender]
                        if new_build then
                            agent:SetBuildOverride(new_build)
                        end
                    else
                        agent:SetBuildOverride()
                    end
                end
            -- end
        end,
        agent_relationship_changed = function( quest, agent, old_rel, new_rel )
            if agent == quest:GetCastMember("primary_advisor") then
                return
            end
            if not DemocracyUtil.CanVote(agent) then
                return
            end
            local support_delta = t.DELTA_SUPPORT[new_rel] - t.DELTA_SUPPORT[old_rel]

            if support_delta ~= 0 then
                -- local opposition_data = DemocracyUtil.GetOppositionData(agent)
                -- if opposition_data then
                --     quest:DefFn("DeltaGeneralSupport", (new_rel - old_rel) * 8, support_delta > 0 and "ALLIANCE_FORMED" or "ENEMY_MADE")
                --     quest:DefFn("DeltaGroupFactionSupport", opposition_data.faction_support, new_rel - old_rel, support_delta > 0 and "ALLIANCE_FORMED" or "ENEMY_MADE" )
                --     quest:DefFn("DeltaGroupWealthSupport", opposition_data.wealth_support, new_rel - old_rel, support_delta > 0 and "ALLIANCE_FORMED" or "ENEMY_MADE" )
                -- else
                --
                -- end
                local new_graft = agent:GetSocialGraft(new_rel) and Content.GetGraft(agent:GetSocialGraft(new_rel))
                local old_graft = agent:GetSocialGraft(old_rel) and Content.GetGraft(agent:GetSocialGraft(old_rel))
                local skip = TheGame:GetGameState():GetCaravan():GetCurrentEncounter() and (new_rel == RELATIONSHIP.LOVED or new_rel == RELATIONSHIP.HATED)
                quest:DefFn("DeltaAgentSupport", math.floor(support_delta / 3), support_delta, agent, (new_graft or old_graft) or skip, support_delta > 0 and "RELATIONSHIP_UP" or "RELATIONSHIP_DOWN")
            end
            -- if new_rel == RELATIONSHIP.LOVED and old_rel ~= RELATIONSHIP.LOVED then
            --     TheGame:GetGameState():GetCaravan():DeltaMaxResolve(1)
            -- end
        end,
        card_added = function( quest, card )
            if card.murder_card then
                quest:DefFn("DeltaGeneralSupport", t.DEATH_GENERAL_DELTA, "MURDER")
            end
        end,
        resolve_battle = function( quest, battle, primary_enemy, repercussions )
            for i, fighter in battle:AllFighters() do
                local agent = fighter.agent
                if agent:IsSentient() and agent:IsDead() then
                    if CheckBits( battle:GetScenario():GetFlags(), BATTLE_FLAGS.ISOLATED ) then
                        -- quest:DefFn("DeltaAgentSupport", t.ISOLATED_DEATH_GENERAL_DELTA, t.ISOLATED_DEATH_DELTA, agent, "SUSPICION")
                    elseif fighter:GetKiller() and fighter:GetKiller():IsPlayer() then
                        -- killing already comes with a heavy drawback of someone hating you, thus reducing support significantly.
                        -- quest:DefFn("DeltaAgentSupport", t.DEATH_GENERAL_DELTA, t.DEATH_DELTA, agent, "MURDER")
                    else
                        if fighter:GetTeamID() == TEAM.BLUE then
                            quest:DefFn("DeltaAgentSupport", t.ACCOMPLICE_KILLING_GENERAL_DELTA, t.ACCOMPLICE_KILLING_DELTA, agent, "NEGLIGENCE")
                        else
                            quest:DefFn("DeltaAgentSupport", t.ACCOMPLICE_KILLING_GENERAL_DELTA, t.ACCOMPLICE_KILLING_DELTA, agent, "ACCOMPLICE")
                        end
                    end
                end
            end
            if not CheckBits( battle:GetScenario():GetFlags(), battle_defs.BATTLE_FLAGS.SELF_DEFENCE ) then
                -- Being aggressive hurts your reputation
                DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2, "ATTACK")
            end
        end,
        action_clock_advance = function(quest, location)
            quest.param.event_delays = (quest.param.event_delays or 0) + 1
            if math.random() < 0.12 * (quest.param.event_delays - 1) then
                TheGame:GetGameState():AddPendingEvent()
                quest.param.event_delays = 0
            end
        end,
        quests_changed = function(quest, event_quest)
            if event_quest:GetQuestDef():HasTag( "REQUEST_JOB" ) and event_quest:IsComplete() then
                TheGame:AddGameplayStat( "completed_request_quest", 1 )
            end
            if event_quest:GetQuestDef():HasTag( "REQUEST_JOB" ) and event_quest:IsActive() then
                if event_quest:GetProvider() then
                    -- In a run, a person can only do one request quest
                    event_quest:GetProvider():Remember("ISSUED_REQUEST_QUEST")
                end
            end
            if event_quest == quest.param.day_quest and quest.param.day_quest:IsComplete() then
                DemocracyUtil.EndFreeTime()
                if quest.param.day then
                    TheGame:AddGameplayStat( "democracy_day_" .. quest.param.day, 1 )
                end
                QuestUtil.DoNextDay(t.DAY_SCHEDULE, quest)
            end
        end,
        GAME_OVER = function( quest, gamestate, result )
            for i = 1, 4 do
                if not quest.param.wealth_support[i] then
                    quest.param.wealth_support[i] = 0
                end
            end
            local METRIC_DATA =
            {
                result = result,
                support_level = quest.param.support_level,
                faction_support = quest.param.faction_support,
                wealth_support = quest.param.wealth_support,
                stances = quest.param.wealth_support,
                player_data = TheGame:GetGameState():GetPlayerState(),
            }

            DemocracyUtil.SendMetricsData("GAME_OVER", METRIC_DATA)
        end,
        allow_dual_purpose_cards = function( quest, card, param )
            param.val = true
        end,
        had_drink = function( quest, drink_effects )
            quest.param.drinks_today = (quest.param.drinks_today or 0) + 1
            quest.param.drinks_total = (quest.param.drinks_total or 0) + 1
        end,
        morning_mail = function( quest, cxt )
            if (quest.param.drinks_today or 0) == 0 then
                -- Do something special for being sober
            end
            quest.param.drinks_today = 0
        end,
        dialog_event_broadcast = function( quest, agent, broadcast_type, ...)
            if broadcast_type == "remember_info" then
                local info = {...}
                for i, val in ipairs(info) do
                    TheGame:GetGameState():GetPlayerAgent():Remember(val:upper())
                end
            elseif broadcast_type == "unlock_agent_info" then
                if agent and agent:GetUniqueID() then
                    local info = {...}
                    for i, val in ipairs(info) do
                        TheGame:GetGameProfile():SetCustomAgentUnlock(agent:GetUniqueID(), val:upper())
                    end
                end
            end
        end,
    },
    SpawnPoolJob = function(quest, pool_name, excluded_ids, spawn_as_inactive, spawn_as_challenge)
        local event_id = pool_name
        local attempt_quest_ids = {}
        local all_quest_ids = {}
        excluded_ids = excluded_ids or {}
        for k, questdef in pairs( Content.GetAllQuests() ) do
            if questdef:HasTag(pool_name) and questdef.id ~= quest.param.recent_side_id then
                if not table.arraycontains(excluded_ids, questdef.id) then
                    table.insert(attempt_quest_ids, questdef.id)
                end
                table.insert(all_quest_ids, questdef.id)
            end
        end
        -- DBG(attempt_quest_ids)
        -- if #attempt_quest_ids == 0 then
        --     attempt_quest_ids = all_quest_ids
        -- end
        -- assert(#attempt_quest_ids > 0, "No quests available")

        local quest_scores = {}
        for k,v in ipairs(all_quest_ids) do
            quest_scores[v] = QuestUtil.CalcQuestSpawnScore(event_id, math.floor(#all_quest_ids/2), v) + math.random(1,5)
            if TheGame:GetGameState():GetQuestActivatedCount(v) > 0 then
                quest_scores[v] = quest_scores[v] - 7
            end
        end
        table.shuffle(attempt_quest_ids) --to mix up the case where there are a lot of ties
        table.stable_sort(attempt_quest_ids, function(a,b) return quest_scores[a] < quest_scores[b] end)
        local new_quest
        for _, quest_id in ipairs(attempt_quest_ids) do
            local overrides = {qrank = TheGame:GetGameState():GetCurrentBaseDifficulty() + (spawn_as_challenge and 1 or 0)}

            if spawn_as_inactive then
                new_quest = QuestUtil.SpawnInactiveQuest( quest_id, overrides)
            else
                new_quest = QuestUtil.SpawnQuest( quest_id, overrides)
            end

            if new_quest then
                if quest.param.day == 1 then
                    new_quest.upfront_reward = true
                end
                TheGame:GetGameProfile():RecordIncident(event_id, new_quest:GetContentID())
                return new_quest
            end
        end

        if not new_quest then
            table.shuffle(all_quest_ids)
            table.stable_sort(all_quest_ids, function(a,b) return quest_scores[a] < quest_scores[b] end)
            for _, quest_id in ipairs(all_quest_ids) do
                local overrides = {qrank = TheGame:GetGameState():GetCurrentBaseDifficulty() + (spawn_as_challenge and 1 or 0)}

                if spawn_as_inactive then
                    new_quest = QuestUtil.SpawnInactiveQuest( quest_id, overrides)
                else
                    new_quest = QuestUtil.SpawnQuest( quest_id, overrides)
                end

                if new_quest then
                    if quest.param.day == 1 then
                        new_quest.upfront_reward = true
                    end
                    TheGame:GetGameProfile():RecordIncident(event_id, new_quest:GetContentID())
                    return new_quest
                end
            end
        end

        return new_quest
    end,
    -- Offer jobs at certain point of the story.
    -- probably should always call this.
    OfferJobs = function(quest, cxt, job_num, pool_name, allow_challenge, can_skip)
        local jobs = {}
        local used_ids = {}
        if cxt.quest.param.job_pool then
            jobs = cxt.quest.param.job_pool
        else
            for k = 1, job_num do
                local new_job = quest:DefFn("SpawnPoolJob", pool_name, used_ids, true, k == 1 and allow_challenge)
                if new_job then
                    table.insert(used_ids, new_job:GetContentID())
                    table.insert(jobs, new_job)
                end
            end
            cxt.quest.param.job_pool = jobs
        end
        DemocracyUtil.PresentJobChoice(cxt, jobs, function(cxt)
            if can_skip == true or (quest.param.allow_skip_side and can_skip ~= false) then
                cxt:Opt("OPT_SKIP_RALLY")
                    -- :MakeUnder()
                    :Dialog("DIALOG_CHOOSE_FREE_TIME")
                    :Fn(function(cxt)
                        cxt:Opt("OPT_INSIST_FREE_TIME")
                            :PreIcon(global_images.accept)
                            :Dialog("DIALOG_INSIST_FREE_TIME")
                            :Fn(function(cxt)
                                cxt.quest.param.current_job = "FREE_TIME"
                                cxt.quest:Complete("get_job")
                                -- cxt.quest:Activate("do_job")
                                --cxt:PlayQuestConvo(cxt.quest.param.job, QUEST_CONVO_HOOK.INTRO)
                                StateGraphUtil.AddEndOption(cxt)
                            end)
                        cxt:Opt("OPT_NEVER_MIND")
                            :PreIcon(global_images.reject)
                            :Dialog("DIALOG_NEVER_MIND_FREE_TIME")
                    end)
            end
            if cxt:GetAgent() and cxt:GetAgent() == cxt:GetCastMember("primary_advisor") then
                cxt:Opt("OPT_DONE")
                    :SetSFX( SoundEvents.leave_conversation )
                    :Dialog("DIALOG_NO_JOB_YET")
                    :Fn(function(cxt) cxt:End() end)
                    :MakeUnder()
            end
        end, function(cxt, jobs_presented, job_picked)
            cxt.quest.param.current_job = job_picked
            quest.param.recent_side_id = job_picked:GetContentID()
            cxt.quest:Complete("get_job")
            -- cxt.quest:Activate("do_job")
            --cxt:PlayQuestConvo(cxt.quest.param.job, QUEST_CONVO_HOOK.INTRO)
            StateGraphUtil.AddEndOption(cxt)
        end)

    end,
    DeltaSupport = function(quest, amt, target, ...)
        local s_type, t = DemocracyUtil.DetermineSupportTarget(target)
        if s_type == "FACTION" then
            quest:DefFn("DeltaFactionSupport", amt, t, ...)
        elseif s_type == "WEALTH" then
            quest:DefFn("DeltaWealthSupport", amt, t, ...)
        else
            quest:DefFn("DeltaGeneralSupport", amt, ...)
        end
    end,
    DeltaGeneralSupport = function(quest, amt, notification, delta_type)
        quest.param.support_level = (quest.param.support_level or 0) + amt
        if notification == nil then
            notification = true
        end
        if not delta_type and type(notification) == "string" then
            delta_type = notification
        end
        if notification and amt ~= 0 and quest.param.enable_support_screen then
            TheGame:GetGameState():LogNotification( NOTIFY.DEM_DELTA_GENERAL_SUPPORT, amt, quest:DefFn("GetGeneralSupport"), delta_type )
        end
        if amt > 0 then
            TheGame:AddGameplayStat( "gained_general_support", amt )
        end
        quest:DefFn("TrackDeltaGeneralSupport", amt, delta_type)
    end,
    DeltaFactionSupport = function(quest, amt, faction, notification, delta_type)
        if not quest.param.faction_support then
            quest.param.faction_support = {}
        end
        faction = DemocracyUtil.ToFactionID(faction)
        quest.param.faction_support[faction] = (quest.param.faction_support[faction] or 0) + amt
        if notification == nil then
            notification = true
        end
        if not delta_type and type(notification) == "string" then
            delta_type = notification
        end
        if notification and amt ~= 0 and quest.param.enable_support_screen then
            TheGame:GetGameState():LogNotification( NOTIFY.DEM_DELTA_FACTION_SUPPORT, amt, quest:DefFn("GetFactionSupport", faction), TheGame:GetGameState():GetFaction(faction), delta_type )
        end
        if amt > 0 then
            TheGame:AddGameplayStat( "gained_faction_support_" .. faction, amt )
        end
        quest:DefFn("TrackDeltaFactionSupport", amt, faction, delta_type)
    end,
    DeltaWealthSupport = function(quest, amt, renown, notification, delta_type)
        if not quest.param.wealth_support then
            quest.param.wealth_support = {}
        end
        local r = DemocracyUtil.GetWealth(renown)
        quest.param.wealth_support[r] = (quest.param.wealth_support[r] or 0) + amt
        if notification == nil then
            notification = true
        end
        if not delta_type and type(notification) == "string" then
            delta_type = notification
        end
        if notification and amt ~= 0 and quest.param.enable_support_screen then
            TheGame:GetGameState():LogNotification( NOTIFY.DEM_DELTA_WEALTH_SUPPORT, amt, quest:DefFn("GetWealthSupport", r), r, delta_type )
        end
        if amt > 0 then
            TheGame:AddGameplayStat( "gained_wealth_support_" .. r, amt )
        end
        quest:DefFn("TrackDeltaWealthSupport", amt, r, delta_type)
    end,

    TrackDeltaGeneralSupport = function(quest, amt, delta_type)
        if not quest.param.support_gain_source then
            quest.param.support_gain_source = {}
        end
        if not quest.param.support_loss_source then
            quest.param.support_loss_source = {}
        end

        if amt ~= 0 then
            if amt > 0 then
                if not delta_type then
                    delta_type = "DEFAULT_UP"
                end
                quest.param.support_gain_source[delta_type] = (quest.param.support_gain_source[delta_type] or 0) + amt
            else
                if not delta_type then
                    delta_type = "DEFAULT_DOWN"
                end
                quest.param.support_loss_source[delta_type] = (quest.param.support_loss_source[delta_type] or 0) - amt
            end
        end
    end,
    TrackDeltaFactionSupport = function(quest, amt, faction, delta_type)
        if not quest.param.faction_support_gain_source then
            quest.param.faction_support_gain_source = {}
        end
        if not quest.param.faction_support_loss_source then
            quest.param.faction_support_loss_source = {}
        end

        local target_table

        if amt ~= 0 then
            if amt > 0 then
                if not delta_type then
                    delta_type = "DEFAULT_UP"
                end
                if not quest.param.faction_support_gain_source[faction] then
                    quest.param.faction_support_gain_source[faction] = {}
                end
                target_table = quest.param.faction_support_gain_source[faction]
            else
                if not delta_type then
                    delta_type = "DEFAULT_DOWN"
                end
                if not quest.param.faction_support_loss_source[faction] then
                    quest.param.faction_support_loss_source[faction] = {}
                end
                target_table = quest.param.faction_support_loss_source[faction]
            end
            target_table[delta_type] = (target_table[delta_type] or 0) + math.abs(amt)
        end
    end,
    TrackDeltaWealthSupport = function(quest, amt, wealth, delta_type)
        if not quest.param.wealth_support_gain_source then
            quest.param.wealth_support_gain_source = {}
        end
        if not quest.param.wealth_support_loss_source then
            quest.param.wealth_support_loss_source = {}
        end

        local target_table

        if amt ~= 0 then
            if amt > 0 then
                if not delta_type then
                    delta_type = "DEFAULT_UP"
                end
                if not quest.param.wealth_support_gain_source[wealth] then
                    quest.param.wealth_support_gain_source[wealth] = {}
                end
                target_table = quest.param.wealth_support_gain_source[wealth]
            else
                if not delta_type then
                    delta_type = "DEFAULT_DOWN"
                end
                if not quest.param.wealth_support_loss_source[wealth] then
                    quest.param.wealth_support_loss_source[wealth] = {}
                end
                target_table = quest.param.wealth_support_loss_source[wealth]
            end
            target_table[delta_type] = (target_table[delta_type] or 0) + math.abs(amt)
        end
    end,

    DeltaAgentSupport = function(quest, general_amt, additional_amt, agent, notification, delta_type)
        if notification == nil then
            notification = true
        end
        if not delta_type and type(notification) == "string" then
            delta_type = notification
        end
        quest:DefFn("DeltaGeneralSupport", general_amt, false, delta_type)
        quest:DefFn("DeltaFactionSupport", additional_amt, agent, false, delta_type)
        quest:DefFn("DeltaWealthSupport", additional_amt, agent, false, delta_type)
        if notification and additional_amt and quest.param.enable_support_screen then
            TheGame:GetGameState():LogNotification( NOTIFY.DEM_DELTA_AGENT_SUPPORT, general_amt, additional_amt, agent, delta_type )
        end
    end,
    -- DeltaFactionSupportAgent = function(quest, amt, agent, ignore_notification)
    --     quest:DefFn("DeltaFactionSupport", amt, agent:GetFactionID(), ignore_notification)
    -- end,
    -- DeltaWealthSupportAgent = function(quest, amt, agent, ignore_notification)
    --     quest:DefFn("DeltaWealthSupport", amt, agent:GetRenown() or 1, ignore_notification)
    -- end,
    DeltaGroupFactionSupport = function(quest, group_delta, multiplier, notification, delta_type)
        if notification == nil then
            notification = true
        end
        if not delta_type and type(notification) == "string" then
            delta_type = notification
        end
        multiplier = multiplier or 1
        local actual_group = {}
        for id, val in pairs(group_delta or {}) do
            actual_group[id] = math.round(val * multiplier)
            quest:DefFn("DeltaFactionSupport", actual_group[id], id, false, delta_type)
        end
        if notification and quest.param.enable_support_screen then
            TheGame:GetGameState():LogNotification( NOTIFY.DEM_DELTA_GROUP_FACTION_SUPPORT, actual_group, delta_type)
        end
    end,
    DeltaGroupWealthSupport = function(quest, group_delta, multiplier, notification, delta_type)
        if notification == nil then
            notification = true
        end
        if not delta_type and type(notification) == "string" then
            delta_type = notification
        end
        multiplier = multiplier or 1
        local actual_group = {}
        for id, val in pairs(group_delta or {}) do
            actual_group[id] = math.round(val * multiplier)
            quest:DefFn("DeltaWealthSupport", math.round(val * multiplier), id, false, delta_type)
        end
        if notification and quest.param.enable_support_screen then
            TheGame:GetGameState():LogNotification( NOTIFY.DEM_DELTA_GROUP_WEALTH_SUPPORT, actual_group, delta_type)
        end
    end,
    -- Getters
    GetGeneralSupport = function(quest) return quest.param.support_level end,
    GetFactionSupport = function(quest, faction)
        faction = DemocracyUtil.ToFactionID(faction)
        return quest.param.support_level + (quest.param.faction_support[faction] or 0)
    end,
    GetWealthSupport = function(quest, renown)
        local r = DemocracyUtil.GetWealth(renown)
        return quest.param.support_level + (quest.param.wealth_support[r] or 0)
    end,
    GetGeneralSupportBreakdown = function(quest)
        return {gain_table = quest.param.support_gain_source, loss_table = quest.param.support_loss_source}
    end,
    GetFactionSupportBreakdown = function(quest, faction)
        faction = DemocracyUtil.ToFactionID(faction)
        return {gain_table = quest.param.faction_support_gain_source[faction], loss_table = quest.param.faction_support_loss_source[faction]}
    end,
    GetWealthSupportBreakdown = function(quest, wealth)
        local r = DemocracyUtil.GetWealth(wealth)
        return {gain_table = quest.param.wealth_support_gain_source[r], loss_table = quest.param.wealth_support_loss_source[r]}
    end,
    GetCompoundSupport = function(quest, faction, renown)
        faction = DemocracyUtil.ToFactionID(faction)
        return quest.param.support_level + (quest.param.faction_support[faction] or 0) + (quest.param.wealth_support[DemocracyUtil.GetWealth(renown)] or 0)
    end,
    -- GetFactionSupportAgent = function(quest, agent)
    --     return quest:DefFn("GetFactionSupport", agent:GetFactionID())
    -- end,
    -- GetWealthSupportAgent = function(quest, agent)
    --     return quest:DefFn("GetWealthSupport", agent:GetRenown() or 1)
    -- end,
    GetSupportForAgent = function(quest, agent)
        return quest:DefFn("GetCompoundSupport", agent:GetFactionID(), agent:GetRenown() or 1)
    end,
    -- This represents how popular an opposition candidate is
    GetOppositionSupport = function(quest, agent)
        if not quest.param.opposition_support then
            quest.param.opposition_support = {}
        end
        if type(agent) == "table" then
            agent = DemocracyUtil.GetOppositionID(agent)
        end
        return quest.param.opposition_support[agent] or 0
    end,
    DeltaOppositionSupport = function(quest, agent, delta)
        if not quest.param.opposition_support then
            quest.param.opposition_support = {}
        end
        if type(agent) == "table" then
            agent = DemocracyUtil.GetOppositionID(agent)
        end
        if agent then
            quest.param.opposition_support[agent] = (quest.param.opposition_support[agent] or 0) + delta
        end
    end,
    GetOppositionViability = function(quest, agent)
        if type(agent) == "table" then
            agent = DemocracyUtil.GetOppositionID(agent)
        end
        if agent then
            local faction = DemocracyConstants.opposition_data[agent].main_supporter
            return quest:DefFn("GetOppositionSupport", agent) - (quest.param.faction_support[faction] or 0)
        end
    end,
    IsCandidateInRace = function(quest, agent)
        quest.param.quitted_candidates = quest.param.quitted_candidates or {}
        if type(agent) == "string" then
            agent = quest:GetCastMember(agent)
        end
        return DemocracyUtil.GetOppositionID(agent) and not agent:IsRetired() and not table.arraycontains(quest.param.quitted_candidates, agent)
    end,
    DropCandidate = function(quest, agent)
        quest.param.quitted_candidates = quest.param.quitted_candidates or {}
        table.insert_unique(quest.param.quitted_candidates, agent)
    end,
    -- At certain points in the story, random people dislikes you for no reason.
    -- call this function to do so.
    DoRandomOpposition = function(quest, num_to_do)
        num_to_do = num_to_do or 1
        -- A self-balancing factor in case you get too popular.
        if quest:DefFn("GetGeneralSupport") - quest:DefFn("GetCurrentExpectation") > 10 then
            num_to_do = num_to_do + 1
        end
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
        money = money / 8
        money = money + 100
        money = math.max(0, money)
        return math.round(money * rate)
    end,
    -- Just handle the change in stance and consistency of your opinion.
    -- Does not handle the relationship gained from updating your stance.
    UpdateStance = function(quest, issue, val, strict, autosupport)
        if type(issue) == "table" then
            issue = issue.id
        end
        -- local multiplier = type(autosupport) == "number" and autosupport or 1
        if autosupport == nil then
            autosupport = true
        end
        -- multiplier = multiplier or 1
        if quest.param.stances[issue] == nil then
            quest.param.stances[issue] = val
            quest.param.stance_change[issue] = 0
            quest.param.stance_change_freebie[issue] = not strict
            TheGame:GetGameState():LogNotification( NOTIFY.DEM_UPDATE_STANCE, issue, val, strict )
        else
            local stance_delta = val - quest.param.stances[issue]
            if stance_delta == 0 or (not strict and (quest.param.stances[issue] > 0) == (val > 0) and (quest.param.stances[issue] < 0) == (val < 0)) then
                -- A little bonus for being consistent with your ideology.
                quest:DefFn("DeltaGeneralSupport", 1, "CONSISTENT_STANCE")
                quest.param.stance_change[issue] = math.max(0, quest.param.stance_change[issue] - 0.5)
                quest.param.stance_change_freebie[issue] = false
            else
                if quest.param.stance_change_freebie[issue]
                    and (quest.param.stances[issue] > 0) == (val > 0)
                    and (quest.param.stances[issue] < 0) == (val < 0) then

                    quest:DefFn("DeltaGeneralSupport", 1, "CONSISTENT_STANCE")
                    quest.param.stance_change[issue] = math.max(0, quest.param.stance_change[issue] - 0.5)
                    -- quest.param.stances[issue] = val
                else
                    -- Penalty for being inconsistent.
                    -- If on the same side or going to/from neutral, add 1 to penalty
                    -- If on opposite side, add 2 to penalty
                    local penalty = (val * quest.param.stances[issue]) >= 0 and 1 or 2
                    quest.param.stance_change[issue] = quest.param.stance_change[issue] + penalty
                    quest:DefFn("DeltaGeneralSupport", -math.max(0, math.ceil(quest.param.stance_change[issue])), "INCONSISTENT_STANCE")
                end
                quest.param.stances[issue] = val
                quest.param.stance_change_freebie[issue] = not strict
                TheGame:GetGameState():LogNotification( NOTIFY.DEM_UPDATE_STANCE, issue, val, strict )
            end
        end
        if autosupport then
            local multiplier = type(autosupport) == "number" and autosupport or 1
            local issue_data = DemocracyConstants.issue_data[issue]
            if issue_data then
                local stance = issue_data.stances[val]
                if stance.faction_support then
                    DemocracyUtil.TryMainQuestFn("DeltaGroupFactionSupport", stance.faction_support, multiplier, false, "STANCE_TAKEN")
                end
                if stance.wealth_support then
                    DemocracyUtil.TryMainQuestFn("DeltaGroupWealthSupport", stance.wealth_support, multiplier, false, "STANCE_TAKEN")
                end
            end
        end
        print(loc.format("Updated stance: '{1}': {2}(strict: {3})", issue, val, strict))

    end,
    GetStance = function(quest, issue)
        if type(issue) == "table" then
            issue = issue.id
        end
        return quest.param.stances[issue]
    end,
    GetStanceChange = function(quest, issue)
        if type(issue) == "table" then
            issue = issue.id
        end
        return quest.param.stance_change[issue]
    end,
    GetStanceChangeFreebie = function(quest, issue)
        if type(issue) == "table" then
            issue = issue.id
        end
        return quest.param.stance_change_freebie[issue]
    end,
    SetAlliance = function(quest, agent, turn_on)
        if turn_on == nil then
            turn_on = true
        end
        quest.param.alliances = quest.param.alliances or {}
        if turn_on then
            if not table.arraycontains(quest.param.alliances, agent) then
                table.insert(quest.param.alliances, agent)
                quest:DefFn("DeltaGeneralSupport", 8, "ALLIANCE_FORMED")
                local opposition_data = DemocracyUtil.GetOppositionData(agent)
                if opposition_data then
                    quest:DefFn("DeltaGroupFactionSupport", opposition_data.faction_support, 2, "ALLIANCE_FORMED" )
                    quest:DefFn("DeltaGroupWealthSupport", opposition_data.wealth_support, 2, "ALLIANCE_FORMED" )
                end
            end
        else
            if table.arraycontains(quest.param.alliances, agent) then
                table.arrayremove(quest.param.alliances, agent)
                quest:DefFn("DeltaGeneralSupport", -8, "ALLIANCE_BROKEN")
                local opposition_data = DemocracyUtil.GetOppositionData(agent)
                if opposition_data then
                    quest:DefFn("DeltaGroupFactionSupport", opposition_data.faction_support, -2, "ALLIANCE_BROKEN" )
                    quest:DefFn("DeltaGroupWealthSupport", opposition_data.wealth_support, -2, "ALLIANCE_BROKEN" )
                end
            end
        end
    end,
    GetAlliance = function(quest, agent)
        quest.param.alliances = quest.param.alliances or {}
        if agent then
            return table.arraycontains(quest.param.alliances, agent)
        end
        return quest.param.alliances
    end,

    SetSubdayProgress = function(quest, progress)
        quest.param.sub_day_progress = progress
        for i = 1, 4 do
            if not quest.param.wealth_support[i] then
                quest.param.wealth_support[i] = 0
            end
        end
        -- Send Metric
        local METRIC_DATA =
        {
            support_level = quest.param.support_level,
            faction_support = quest.param.faction_support,
            wealth_support = quest.param.wealth_support,
            stances = quest.param.wealth_support,
        }

        DemocracyUtil.SendMetricsData("STORY_PROGRESS", METRIC_DATA)
    end,
    GetCurrentExpectationArray = function(quest, day)
        return t.DAY_SCHEDULE[math.min(#t.DAY_SCHEDULE, day or quest.param.day or 1)].support_expectation
    end,
    GetCurrentExpectation = function(quest, day)
        local arr = quest:DefFn("GetCurrentExpectationArray", day)
        return math.round(arr[math.min(#arr, quest.param.sub_day_progress or 1)] * DemocracyUtil.GetModSetting("support_requirement_multiplier")) -- - 100
    end,
    GetDayEndExpectation = function(quest, day)
        local arr = quest:DefFn("GetCurrentExpectationArray", day)
        return math.round(arr[#arr] * DemocracyUtil.GetModSetting("support_requirement_multiplier"))
    end,
    GetStanceIntel = function(quest)
        local intel = {}
        if quest:GetCastMember("primary_advisor") then
            table.insert(intel, quest:GetCastMember("primary_advisor"))
        end
        for i, id, data in sorted_pairs(DemocracyConstants.opposition_data) do
            if quest:GetCastMember(id):KnowsPlayer() then
                table.insert(intel, quest:GetCastMember(id))
            end
        end
        return intel
    end,

    DeltaGameplayStats = function(quest, id, delta)
        quest.param.gameplay_stats = quest.param.gameplay_stats or {}
        quest.param.gameplay_stats[id] = (quest.param.gameplay_stats[id] or 0) + delta
    end,
    GetGameplayStats = function(quest, id)
        quest.param.gameplay_stats = quest.param.gameplay_stats or {}
        return (quest.param.gameplay_stats[id] or 0)
    end,

    -- debug functions
    DebugUnlockAllLocations = function(quest)
        quest.param.unlocked_locations = shallowcopy(Content.GetWorldRegion("democracy_pearl").locations)
        print(loc.format("Unlocked all locations ({1} total)", #quest.param.unlocked_locations))
    end,

    UpdateAdvisor = function(quest, new_advisor, change_reason)
        if not change_reason then
            change_reason = "OTHER_REASON"
        end
        local old_advisor = quest:GetCastMember("primary_advisor")
        if old_advisor == new_advisor then
            return
        end
        if old_advisor then
            quest:UnassignCastMember("primary_advisor")
        end
        if new_advisor then
            quest:AssignCastMember("primary_advisor", new_advisor)
        end
        print("Broadcasting event: primary_advisor_changed")
        TheGame:BroadcastEvent( "primary_advisor_changed", old_advisor, new_advisor, change_reason )
        print("End Broadcasting event: primary_advisor_changed")
        if not new_advisor then
            -- Fail-check. Check for any existing advisors that are alive and is at least neutral to you.
            -- If there are, start a side quest of finding that advisor.
            -- Otherwise, the game autofails, and a lose slide plays.
            quest.param.alert_advisor_removed = change_reason:lower()
        end
    end,

    GetMainQuestCast = function(quest, id)
        return quest:GetCastMember(id)
    end,
}
:AddCast{
    cast_id = "random_opposition",
    when = QWHEN.MANUAL,
    score_fn = DemocracyUtil.OppositionScore,
    condition = function(agent, quest)
        if quest.param.prev_opposition_faction == agent:GetFactionID() or quest.param.prev_opposition_wealth == DemocracyUtil.GetWealth(agent) then
            return false, "No consecutive faction"
        end
        if agent:GetRelationship() == RELATIONSHIP.DISLIKED then
            return math.random() < 0.1 -- sometimes we allow disliked people to hate you.
        end
        return agent:GetRelationship() < RELATIONSHIP.LOVED and agent:GetRelationship() > RELATIONSHIP.DISLIKED
    end,
    on_assign = function(quest, agent)
        quest.param.prev_opposition_faction = agent:GetFactionID()
        quest.param.prev_opposition_wealth = DemocracyUtil.GetWealth(agent)
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent() )
    end,
}
:AddCast{
    cast_id = "primary_advisor",
    when = QWHEN.MANUAL,
    no_validation = true,
    on_assign = function(quest,agent)
        if quest:GetCastMember("home") then
            quest:UnassignCastMember("home")
        end
        quest:AssignCastMember("home")
        if not quest.param.first_primary_advisor then
            quest.param.first_primary_advisor = agent
        end
        -- if quest.param.all_day_quests then
        --     for k,v in ipairs(quest.param.all_day_quests) do
        --         if v:GetQuestDef():GetCast("primary_advisor") then
        --             v:AssignCastMember("primary_advisor", quest:GetCastMember("primary_advisor"))
        --         end
        --     end
        -- end
    end,
    on_unassign = function(quest, agent)
        quest:UnassignCastMember("home")
    end,
    events = {
        agent_retired = function(quest, agent)
            quest:DefFn("UpdateAdvisor", nil, agent:IsDead() and "ADVISOR_DEAD" or "ADVISOR_RETIRED")
        end,
    }
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
    :Priority(CONVO_PRIORITY_HIGHEST)
    :ConfrontState("STATE_UNLOCK", function(cxt)
        local id = cxt.location:GetContentID()
        return id and table.arraycontains(LocUnlock.ALL_LOCATION_UNLOCKS, id)
            and not DemocracyUtil.LocationUnlocked(id)
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
QDEF:AddConvo()
    :Priority(CONVO_PRIORITY_HIGHEST)
    :ConfrontState("STATE_HURT", function(cxt)
        local health = TheGame:GetGameState():GetPlayerAgent().health:GetPercent()
        local has_graft = TheGame:GetGameState():GetPlayerAgent().graft_owner:HasGraft("democracy_resolve_limiter")
        return health < 1 and not has_graft and not cxt.location:HasTag("in_transit")
    end)
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
                * You really ought to take care of yourself better.
                player:
                    !cagey
                    What? Who said that?
                * This is your pain receptor talking to you.
                * You are hurt. And being hurt is very painful.
                {high_health?
                    player:
                        !crossed
                        Come on, it was just some bruises. Nothing I can't walk off, or sleep off.
                    * While you can probably survive this ordeal, you will still feel the pain as a reminder to take care of yourself.
                }
                {low_health?
                    player:
                        !injured
                        Now that you mention it, it Heshing hurts so much!
                        But I've handled worse, probably.
                        And as long as I don't fight, I can just sleep the injury off.
                    * Sure, you've handled this kind of injury before, but you've never felt this painful while you are actively working on a campaign.
                }
                {not (high_health or low_health)?
                    player:
                        Now that you mention it, it really does hurt.
                        Still, I've handled worse.
                        And as long as I don't fight, I can just sleep the injury off.
                    * Sure, you've handled this kind of injury before, but you've never felt this painful while you are actively working on a campaign.
                }
                * Your resolve will be limited as long as you feel the pain.
                * You don't want to be unable to focus due to the pain while you are thinking for a counterargument, do you?
                player:
                    !shrug
                    Guess not.
                * Then you better find a place to heal yourself before you blunder.
                *** While you are hurt, your resolve will be limited by the proportion of health you have.
                *** Restore to full health to remove this limit.
            ]],
        }
        :Fn(function(cxt)
            local health = TheGame:GetGameState():GetPlayerAgent().health:GetPercent()
            if health >= 0.8 then
                cxt.enc.scratch.high_health = true
            elseif health <= 0.5 then
                cxt.enc.scratch.low_health = true
            end
            cxt:Dialog("DIALOG_INTRO")
            TheGame:GetGameState():GetPlayerAgent().graft_owner:AddGraft(GraftInstance("democracy_resolve_limiter"))
            StateGraphUtil.AddEndOption(cxt)
        end)
QDEF:AddConvo()
    :Priority(CONVO_PRIORITY_LOWEST)
    :ConfrontState("STATE_NO_ADVISOR", function(cxt)
        return cxt.quest.param.alert_advisor_removed
    end)
        :Loc{
            DIALOG_NO_NEW_ADVISOR = [[
                {advisor_dead?
                    * With the death of your advisor, there is no one left to help you in your campaign.
                }
                {advisor_retired?
                    * With the disappearance of your advisor, there is no one left to help you in your campaign.
                }
                {advisor_rejected?
                    * The last advisor available to you decided that you are not worth the trouble, as you lost the trust of the final person who is willing to help you.
                }
                * Without help, your campaign is forcefully suspended.
            ]],
            DIALOG_FIND_NEW_ADVISOR = [[
                {advisor_dead?
                    * With the death of your advisor, you need to find someone else who can help you.
                }
                {advisor_retired?
                    * With the disappearance of your advisor, you need to find someone else who can help you.
                }
                {advisor_rejected?
                    * The last advisor available to you decided that you are not worth the trouble, so you need to find another one.
                }
                {not (advisor_dead or advisor_retired or advisor_rejected)?
                    * You can no longer rely on your old advisor. It's time to find a new one.
                }
            ]],
            OPT_RENOUNCE = "Renounce your campaign",
        }
        :Fn(function(cxt)
            local available_advisors = {}
            for i, id in ipairs(copykeys(DemocracyUtil.ADVISOR_IDS)) do
                local agent = cxt:GetCastMember(id)
                if agent and not agent:IsRetired() and agent:GetRelationship() >= RELATIONSHIP.NEUTRAL then
                    table.insert(available_advisors, agent)
                end
            end
            if #available_advisors > 0 then
                cxt.enc.scratch[cxt.quest.param.alert_advisor_removed] = true

                cxt:Dialog("DIALOG_FIND_NEW_ADVISOR")

                cxt.quest.param.alert_advisor_removed = nil

                QuestUtil.SpawnQuest("RACE_FIND_NEW_ADVISOR",
                    {
                        parameters = {
                            available_advisors = available_advisors,
                        }
                    }
                )
                StateGraphUtil.AddEndOption(cxt)
            else
                cxt:Dialog("DIALOG_NO_NEW_ADVISOR")
                cxt:Opt("OPT_RENOUNCE")
                    :Fn(function(cxt)
                        -- You lose lol
                        local flags = {
                            [cxt.quest.param.alert_advisor_removed] = true,
                        }
                        cxt.quest.param.alert_advisor_removed = nil
                        DemocracyUtil.DoEnding(cxt, "no_more_advisors", flags)
                    end)
            end
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

-- Expose some local variables
return t
