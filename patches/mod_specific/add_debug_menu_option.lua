if TheGame:GetLocalSettings().DEBUG then
    local patch_id = "ADD_DEBUG_MENU_OPTION"
    local act_id = "SAL_DEMOCRATIC_RACE"
    local is_first = false
    if not rawget(_G, patch_id) then
        rawset(_G, patch_id, true)
        is_first = true
    end

    local old_fn = DebugQuickSwitcher.RenderPanel
    DebugQuickSwitcher.RenderPanel = function(self, ui, panel)
        old_fn(self, ui, panel)
        
        local title_color = 0xaaaaaaff
        local indent = 10

        if is_first then
            -- ui:Unindent( indent )
            -- ui:Separator()
            ui:Spacing()
            ui:Spacing()
            ui:Spacing()

            ui:TextColored( title_color, "Mod Options" )
            
        end
        ui:Indent( indent )
        if act_id and ui:Selectable( "Quick Play Democracy" ) then
            local settings = TheGame:GetLocalSettings()
            settings.SKIP_SLIDE_SHOWS = true
            settings.FAST_STARTUP = true

            TheGame.scheduler:DoTaskInTime( "QUICKSTART", 0.01,
                function()
                    local options = GameState.CreateOptions( act_id )
                    TheGame:StartNewGame( options )
                    end )
        end
        ui:Unindent( indent )
    end
end