MountModData( "DEMOCRATICRACE" )

local filepath = require "util/filepath"

local function OnLoad()
    local STARTING_MONEY = 125

    local ACT_DATA = {
        id = "DEMOCRATIC_RACE",
        name = "The Democratic Race",
        title = "I Love Democracy",
        desc = "Use FACTS and LOGIC to win the democratic race. No combat required!",
        
        act_image = engine.asset.Texture("DEMOCRATICRACE:assets/campaign_icon.png"),
        colour_frame = "0x66F15Dff",
        colour_text = "0xC3FFBFff",
        colour_background = "0x47FF31ff",

        world_region = "democracy_murder_bay",

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

    require "DEMOCRATICRACE:content/string_table"

    rawset(_G, "DemocracyConstants", require("DEMOCRATICRACE:content/constants"))
    rawset(_G, "DemocracyUtil", require("DEMOCRATICRACE:content/util"))
    -- require "DEMOCRATICRACE:content/wealth_level"
    require "DEMOCRATICRACE:content/load_quips"
    require "DEMOCRATICRACE:content/shop_defs"
    require "DEMOCRATICRACE:content/locations"
    require "DEMOCRATICRACE:content/notifications"
    require "DEMOCRATICRACE:content/convo_loc_common"
    require "DEMOCRATICRACE:content/region"

    for id, data in pairs(GetAllPlayerBackgrounds()) do
        local act_data = shallowcopy(ACT_DATA)
        act_data.id = data.id .. "_" .. act_data.id
        data:AddAct(act_data)
        Content.internal.ACT_DATA[act_data.id] = data.acts[#data.acts]
    end
    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:errata/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        -- print(name)
        if name then
            require(name)
        end
    end
    for k, filepath in ipairs( filepath.list_files( "DEMOCRATICRACE:ui/", "*.lua", true )) do
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