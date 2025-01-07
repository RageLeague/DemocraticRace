-- MountModData( "DEMOCRATICRACE" )

local filepath = require "util/filepath"

local bank_loading_handle

rawset(_G, "DemAudioAlt", function(default_audio, alt_audio)
    return DemocracyUtil.GetModSetting("enable_custom_audio") and default_audio or alt_audio
end)

local function OnNewGame( mod, game_state )
    -- Require this Mod to be installed to launch this save game.
    if DemocracyUtil.IsDemocracyCampaign(game_state:GetCurrentActID()) then
        game_state:RequireMod( mod )
    end
end

local function OnPostLoad( mod )
    rawset(_G, "CURRENT_MOD_ID", mod.id)

    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:postload_patches/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            require(name)
        end
    end

    local STARTING_MONEY = 125

    local FORBIDDEN_CONVO = {
        -- You think you can just provoke anyone and kill them, calling it a day? Of course not.
        -- Probably also give a provoke, but significantly harder and more restrictive, non-isolated fights,
        -- and you are still counted as an aggressor.
        -- On the plus side, you can provoke people with plot armor.
        "HATED_CHAT",
        -- We write our own drink convo, because free time balancing.
        -- Also, we might use our demand thing for the "gift" option.
        "IMPROVE_RELATIONSHIP_CHAT",
    }
    local ACT_DATA = {
        id = "DEMOCRATIC_RACE",
        name = "The Democratic Race",
        title = "I Love Democracy",
        desc = "Use FACTS and LOGIC to win the democratic race. No combat required!",

        act_image = engine.asset.Texture("DEMOCRATICRACE:assets/icons/campaign_icon.png"),
        colour_frame = "0x66F15Dff",
        colour_text = "0xC3FFBFff",
        colour_background = "0x47FF31ff",

        story_image = engine.asset.Texture("DEMOCRATICRACE:assets/icons/campaign_icon.png"),
        story_colour_frame = "0x05faeeff",
        story_colour_text = "0xcdfefcff",
        story_colour_background = "0x05e1d6ff",

        world_region = "democracy_pearl",
        story_mode = true,

        main_quest = "DEMOCRATIC_RACE_MAIN",
        game_type = GAME_TYPE.CAMPAIGN,

        slides = {
            "democracy_intro_slides",
        },

        starting_fn = function(agent)
            agent:DeltaMoney( STARTING_MONEY )
        end,
        convo_filter_fn = function( convo_def, game_state )
            if table.arraycontains(FORBIDDEN_CONVO, convo_def.id) then
                return false
            end

            return true
        end,

        score_modifiers =
        {
            money = -STARTING_MONEY,
        }
    }

    for id, data in pairs(GetAllPlayerBackgrounds()) do
        local act_data = shallowcopy(ACT_DATA)
        act_data.id = data.id .. "_" .. act_data.id
        data:AddAct(act_data)
        Content.internal.ACT_DATA[act_data.id] = data.acts[#data.acts]
    end
end

local function OnLoad( mod )
    rawset(_G, "CURRENT_MOD_ID", mod.id)

    local function LoadConvoLua( filename )
        package.loaded[ filename ] = nil
        local ok, result = xpcall( require, generic_error, filename )
        if not ok then
            error( result )
        end
        return ok, result
    end

    require "DEMOCRATICRACE:content/string_table"

    require "DEMOCRATICRACE:content/util"
    rawset(_G, "DemocracyConstants", require("DEMOCRATICRACE:content/constants"))
    -- rawset(_G, "DemocracyUtil", )

    -- Patch existing files first
    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:patches/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            require(name)
        end
    end

    require "DEMOCRATICRACE:content/string_table"

    rawset(_G, "DemocracyConstants", require("DEMOCRATICRACE:content/constants"))
    require "DEMOCRATICRACE:content/util"
    -- rawset(_G, "DemocracyUtil", )

    -- require "DEMOCRATICRACE:content/wealth_level"
    require "DEMOCRATICRACE:content/builds"
    require "DEMOCRATICRACE:content/load_quips"
    require "DEMOCRATICRACE:content/load_codex"
    require "DEMOCRATICRACE:content/shop_defs"
    require "DEMOCRATICRACE:content/locations"
    require "DEMOCRATICRACE:content/workpositions"
    require "DEMOCRATICRACE:content/notifications"
    require "DEMOCRATICRACE:content/convo_loc_common"
    require "DEMOCRATICRACE:content/region"
    require "DEMOCRATICRACE:content/expand_existing_quest_filters"
    require "DEMOCRATICRACE:content/opinion_events"
    require "DEMOCRATICRACE:content/grifts"
    require "DEMOCRATICRACE:content/more_boon_services"
    require "DEMOCRATICRACE:content/combat_parties"
    require "DEMOCRATICRACE:content/custom_behaviours"
    require "DEMOCRATICRACE:content/debug_commands"
    -- we load slides before we load act data. who knows what would happen if we didn't?
    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:content/slides/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        local id = name:match("([_%w]+)$")
        if name then
            local slides_data = require(name)
            if slides_data then
                Content.AddSlideShow("democracy_" .. id, slides_data)
            end
        end
    end

    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:ui/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            require(name)
        end
    end
    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:content/plax/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        local id = name:match("([_%w]+)$")
        -- print(name)
        if name then
            Content.AddPlaxData(id, name)
        end
    end
    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:content/aspects/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        local id = name:match("([_%w]+)$")
        -- print(name)
        if name then
            require(name)
        end
    end
    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:content/battle/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            require(name)
        end
    end
    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:content/negotiation/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            require(name)
        end
    end
    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:content/grafts/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            require(name)
        end
    end
    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:content/characters/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            require(name)
        end
    end
    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:content/convos/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            LoadConvoLua( name )
        end
    end

    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:content/quests/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )

        if filepath:find( "/deprecated/" ) then
        else
            if name then
                -- package.loaded[ name ] = nil
                require( name )
                -- assert( rawget( _G, "QDEF" ) == nil or error( string.format( "Stop declaring global QDEFS %s", name )))
            end
        end
    end

    Content.AutoGenerateDualPurpose()

    -- print(string.match("C:/Users/adfafaf", "^.+[:]([^/\\].+)$"))
    -- print(string.match("DemRace:lalala", "^.+[:]([^/\\].+)$"))
    return OnPostLoad
end

local function OnPreLoad( mod )

    rawset(_G, "CURRENT_MOD_ID", mod.id)

    -- Patch existing files first
    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:preload_patches/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            require(name)
        end
    end

    -- Add localization
    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:localization", "*.po", true )) do
        local name = filepath:match( "(.+)[.]po$" )
        print(name)
        if name then
            local id = filepath:match("([^/]+)[.]po$")
            print(id)
            Content.AddPOFileToLocalization(id, filepath)
        end
    end
    if true then
        AUDIO:LoadBank("DEMOCRATICRACE:assets/audio/Democratic Race.strings.bank", false)
        -- local audiobank = AUDIO:LoadBank("DEMOCRATICRACE:assets/audio/Master.bank", false)
        -- I guess we are loading it synchronously. Too complicated to do async
        AUDIO:MountModdedAudioBank("DEMOCRATICRACE", "DEMOCRATICRACE:assets/audio/Democratic Race.bank")

        print("Load bank?")
        -- AUDIO:LoadBank("DEMOCRATICRACE:assets/audio/Master.bank", false)
        -- bank_loading_handle = AUDIO:LoadBank("DEMOCRATICRACE:assets/audio/Master.bank", true)
        if (Content.GetModSetting(mod, "enable_audio_debug") or 0) == 1 then
            Content.SetModSetting(mod, "enable_audio_debug", 0)
        end
    end
end

local function OnGlobalEvent(mod, event_name, ...)
    -- print("I'm listening...")
    if event_name == "allow_dual_purpose_cards" then
        local card, param = ...
        if DemocracyUtil.GetModSetting("allow_dual_purpose_cards") then
            param.val = true
        end
    elseif event_name == "card_added" then
        local card = ...
        if card.mod_id == mod.id then
            local game_state = TheGame:GetGameState()
            if not table.findif( game_state.options.required_mods, function(data) return data.id == mod.id end ) then
                game_state:RequireMod( mod )
            end
        end
    elseif event_name == "get_work_availability" then
        -- print("Found event")
        local location, work_data = ...
        if location and work_data then
            for id, data in pairs(work_data) do
                print(id, data)
                if type(data) == "table" and data.is_democracy_job then
                    -- print("Found job for democracy", id)
                    if not DemocracyUtil.IsDemocracyCampaign() then
                        -- print("Not in democracy. Disable job", id)
                        work_data[id] = nil
                    end
                elseif type(data) == "table" and data.disable_for_democracy then
                    -- print("Found job disabled for democracy", id)
                    if DemocracyUtil.IsDemocracyCampaign() then
                        -- print("In democracy. Disable job", id)
                        work_data[id] = nil
                    end
                end
            end
        end
    end
end

local function OnGameStart( mod )
    -- print("I am actually listening")
    TheGame:GetEvents():ListenForEvents( mod, "allow_dual_purpose_cards", "card_added", "get_work_availability" )
end

local MOD_OPTIONS =
{
    -- Access this value from the user's settings by calling:
    -- Content.GetModSetting( <mod_id>, "resolve_per_day" )
    {
        title = "Support Requirement Multipliers",
        slider = true,
        key = "support_requirement_multiplier",
        default_value = 1,
        values = {
            range_min = 0,
            range_max = 3,
            step_size = .05,
            desc = "This is the multiplier to the support requirements. This setting is tied to each save file.",
        },
        per_save_file = true,
    },
    {
        title = "Enable Metrics Collection",
        spinner = true,
        key = "enable_metrics_collection",
        default_value = true,
        values =
        {
            { name="Disable", desc="All metrics collection is disabled.", data = false },
            { name="Enable", desc="Run information during the Democratic Race campaign can be collected to improve the mod. See mod description for more info.", data = true },
        }
    },
    {
        title = "Enable Custom Items",
        spinner = true,
        key = "enable_custom_items",
        default_value = false,
        values =
        {
            { name="Disable", desc="Custom non-unique items will only show up in a Democratic Race campaign.", data = false },
            { name="Enable", desc="Custom non-unique items is added to the general item pool, allowing you to get them even outside of a Democratic Race campaign.", data = true },
        }
    },
    {
        title = "Enable Dual Purpose",
        spinner = true,
        key = "enable_dual_purpose",
        default_value = false,
        values =
        {
            { name="Disable", desc="Dual purpose functionality is only enabled in the Democratic Race campaign.", data = false },
            { name="Enable", desc="Dual purpose functionality is enabled everywhere, allowing you to get them even outside of a Democratic Race campaign.", data = true },
        }
    },
    {
        title = "Enable Custom Audio",
        spinner = true,
        key = "enable_custom_audio",
        default_value = true,
        values =
        {
            { name="Disable", desc="Custom audio isn't used. Instead, a default audio will replace the custom audio. <#PENALTY>Require restart to change.</>", data = false },
            { name="Enable", desc="Custom audio for the Democratic Race will be used. <#PENALTY>Require restart to change.</>", data = true },
        }
    },
}
-- print("Debug mode: " .. tostring(TheGame:GetLocalSettings().DEBUG))
return {
    version = "0.13.1",
    alias = "DEMOCRATICRACE",

    OnLoad = OnLoad,
    OnPreLoad = OnPreLoad,
    OnNewGame = OnNewGame,
    OnGameStart = OnGameStart,
    OnGameReset = OnGameStart,
    OnGlobalEvent = OnGlobalEvent,

    mod_options = MOD_OPTIONS,

    title = "The Democratic Race",
    description = "The Pioneer campaign mod for Griftlands, Democratic Race is a mod for Griftlands that adds a negotiation based campaign mode to the game, in contrast to the direct combat.",
    previewImagePath = "preview.png",

    load_after = {
        -----------------------------------------
        -- Functional changes
        -----------------------------------------
        -- Cross character campaign. both modify graft rewards, but CCC overrides the change.
        "CrossCharacterCampaign",

        -----------------------------------------
        -- New characters
        -----------------------------------------
        -- For shel's adventure and expanded version
        -- "LOSTPASSAGE",
        -- For rise of kashio
        -- "RISE", -- ffs, can you use a more unique alias?
        -- Arint mod
        -- "ARINTMOD",
    },
}
