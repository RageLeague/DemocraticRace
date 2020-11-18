-- MountModData( "DEMOCRATICRACE" )

local filepath = require "util/filepath"

local function OnNewGame( mod, game_state )
    -- Require this Mod to be installed to launch this save game.
    if DemocracyUtil.IsDemocracyCampaign(game_state:GetCurrentActID()) then
        game_state:RequireMod( mod )
    end
end

local function OnLoad( mod )
    rawset(_G, "CURRENT_MOD_ID", mod.id)
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

        world_region = "democracy_pearl",

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

    local function LoadConvoLua( filename )
        package.loaded[ filename ] = nil
        local ok, result = xpcall( require, generic_error, filename )
        if not ok then
            error( result )
        end
        return ok, result
    end
    
    require "DEMOCRATICRACE:content/string_table"

    rawset(_G, "DemocracyConstants", require("DEMOCRATICRACE:content/constants"))
    require "DEMOCRATICRACE:content/util"
    -- rawset(_G, "DemocracyUtil", )

    -- Patch existing files first
    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:patches/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            require(name)
        end
    end
    -- require "DEMOCRATICRACE:content/wealth_level"
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

    for id, data in pairs(GetAllPlayerBackgrounds()) do
        local act_data = shallowcopy(ACT_DATA)
        act_data.id = data.id .. "_" .. act_data.id
        data:AddAct(act_data)
        Content.internal.ACT_DATA[act_data.id] = data.acts[#data.acts]
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

    -- print(string.match("C:/Users/adfafaf", "^.+[:]([^/\\].+)$"))
    -- print(string.match("DemRace:lalala", "^.+[:]([^/\\].+)$"))
end
local function OnPreLoad( mod )
    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:localization", "*.po", true )) do
        local name = filepath:match( "(.+)[.]po$" )
        print(name)
        if name then
            local id = filepath:match("([^/]+)[.]po$")
            print(id)
            Content.AddPOFileToLocalization(id, filepath)
        end
    end
end
-- print("Debug mode: " .. tostring(TheGame:GetLocalSettings().DEBUG))
return {
    version = "0.1.0",
    alias = "DEMOCRATICRACE",
    
    OnLoad = OnLoad,
    OnPreLoad = OnPreLoad,
    OnNewGame = OnNewGame,

    title = "Democratic Race(Working title)",
    description = "The Pioneer campaign mod for the (currently) Early Access game Griftlands, Democratic Race(working title) is a mod for Griftlands that adds a negotiation based campaign mode to the game, in contrast to the direct combat. Your goal in this campaign is to campaign and gain support among the people so you can be voted in as president. This story is heavily negotiation focused, and combat is only necessary if you failed certain negotiations.",
}