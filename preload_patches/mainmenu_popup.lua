local MainMenu = Screen.MainMenu

local MODID = CURRENT_MOD_ID
local old_dostart = MainMenu.doStart

local has_shown_message = false

function MainMenu:doStart(...)
    local params = {...}
    local profile = TheGame:GetGameProfile()
    local mod_settings = profile:GetModSettings()[ MODID ]
    local value
    if mod_settings then
        value = mod_settings.enable_metrics_collection
    end
    if value == nil and not has_shown_message then
        print("Did the metrics warning popup?")
        has_shown_message = true
        UIHelpers.ShowBetaMessage( LOC"DEMOCRACY.METRICS.TITLE", LOC"DEMOCRACY.METRICS.DESC", LOC"UI.MAINMENU.BETA_BUTTON", function()
            old_dostart(self, table.unpack(params))
        end )

        -- Content.SetModSetting(MODID, "enable_metrics_collection", true)
    else
        old_dostart(self, ...)
    end
    -- print("I did a thing lol")
    -- old_dostart(self, ...)
end
