MountModData( "DemocraticRace" )

local filepath = require "util/filepath"

-- local player_starts = require "content/player_starts"

local STARTING_MONEY = 125

-- 

local ACT_DATA = {
    id = "DEMOCRATIC_RACE",
    name = "The Democratic Race",
    title = "I Love Democracy",
    desc = "Use FACTS and LOGIC to win the democratic race. No combat required!",
    
    act_image = engine.asset.Texture("DemocraticRace:assets/campaign_icon.png"),
    colour_frame = "0x66F15Dff",
    colour_text = "0xC3FFBFff",
    colour_background = "0x47FF31ff",

    world_region = "murder_bay",

    main_quest = "DEMOCRATIC_RACE_MAIN",
    game_type = GAME_TYPE.CAMPAIGN,
    starting_fn = function(agent) 
        agent:DeltaMoney( STARTING_MONEY )
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

require "DemocraticRace:content/string_table"

local function OnLoad()
    rawset(_G, "DemocracyConstants", require("DemocraticRace:content/constants"))
    rawset(_G, "DemocracyUtil", require("DemocraticRace:content/util"))
    -- require "DemocraticRace:content/wealth_level"
    require "DemocraticRace:content/load_quips"
    require "DemocraticRace:content/shop_defs"
    require "DemocraticRace:content/locations"
    require "DemocraticRace:content/notifications"
    require "DemocraticRace:content/convo_loc_common"

    for id, data in pairs(GetAllPlayerBackgrounds()) do
        local act_data = shallowcopy(ACT_DATA)
        act_data.id = data.id .. "_" .. act_data.id
        data:AddAct(act_data)
        Content.internal.ACT_DATA[act_data.id] = data.acts[#data.acts]
    end
    for k, filepath in ipairs( filepath.list_files( "DemocraticRace:errata/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            require(name)
        end
    end
    for k, filepath in ipairs( filepath.list_files( "DemocraticRace:ui/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            require(name)
        end
    end
    for k, filepath in ipairs( filepath.list_files( "DemocraticRace:content/negotiation/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            require(name)
        end
    end
    for k, filepath in ipairs( filepath.list_files( "DemocraticRace:content/grafts/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            require(name)
        end
    end
    for k, filepath in ipairs( filepath.list_files( "DemocraticRace:content/convos/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            LoadConvoLua( name )
        end
    end

    for k, filepath in ipairs( filepath.list_files( "DemocraticRace:content/quests/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )

        if filepath:find( "/deprecated/" ) then
        else
            if name then
                package.loaded[ name ] = nil
                require( name )
                assert( rawget( _G, "QDEF" ) == nil or error( string.format( "Stop declaring global QDEFS %s", name )))
            end
        end
    end
end

return {
    OnLoad = OnLoad
}