local function TutorialsMenu( screen )
    
    local t = {}

    if TheGame:GetDebug() or TheGame:GetGameProfile():HasSeenMessage('negotiation_tutorial') then
        table.insert(t, {txt = LOC"UI.MAINMENU.NEGOTIATION", fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "negotiation_tutorial"):SetAutoAdvance(false) ) end, icon = engine.asset.Texture("large/tutorial_negotiation.tex"), colour = UICOLOURS.NEGOTIATION, buttonclass = Widget.TutorialsButton } )
    end

    if TheGame:GetDebug() or TheGame:GetGameProfile():HasSeenMessage('battle_tutorial') then
        table.insert(t, {txt = LOC"UI.MAINMENU.BATTLE", fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "battle_tutorial"):SetAutoAdvance(false) ) end, icon = engine.asset.Texture("large/tutorial_battle.tex"), colour = UICOLOURS.FIGHT, buttonclass = Widget.TutorialsButton } )
    end

    if TheGame:GetDebug() or TheGame:GetGameProfile():HasSeenMessage('rook_negotiation_tutorial') then
        table.insert(t, {txt = LOC"UI.MAINMENU.ROOK_NEGOTIATION", fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "rook_negotiation_tutorial"):SetAutoAdvance(false) ) end, icon = engine.asset.Texture("large/tutorial_negotiation_rook.tex"), colour = UICOLOURS.NEGOTIATION, buttonclass = Widget.TutorialsButton } )
    end

    if TheGame:GetDebug() or TheGame:GetGameProfile():HasSeenMessage('rook_battle_tutorial') then
        table.insert(t, {txt = LOC"UI.MAINMENU.ROOK_BATTLE", fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "rook_battle_tutorial"):SetAutoAdvance(false) ) end, icon = engine.asset.Texture("large/tutorial_battle_rook.tex"), colour = UICOLOURS.FIGHT, buttonclass = Widget.TutorialsButton } )
    end

    if TheGame:GetDebug() or TheGame:GetGameProfile():HasSeenMessage('smith_battle_tutorial') then
        table.insert(t, {txt = LOC"UI.MAINMENU.SMITH_BATTLE", fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "smith_battle_tutorial"):SetAutoAdvance(false) ) end, icon = engine.asset.Texture("large/tutorial_battle_smith.tex"), colour = UICOLOURS.FIGHT, buttonclass = Widget.TutorialsButton } )
    end

    if TheGame:GetDebug() or true then
        table.insert(t, {txt = LOC"UI.MAINMENU.RACE_TUTORIAL", fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "democracy_race_tutorial") ) end, icon = engine.asset.Texture("large/tutorial_negotiation.tex"), colour = UICOLOURS.NEGOTIATION, buttonclass = Widget.TutorialsButton } )
    end

    table.insert(t,  {txt = LOC"UI.MAINMENU.BACK", fn = function() AUDIO:PlayEvent("event:/ui/main/gen/back_general") screen:PopMenu() end, icon = engine.asset.Texture("UI/ic_mainmenu_back.tex"), buttonclass = Widget.AdvancedMenuButton })
    
    return t
end

local old_fn = Screen.MainMenu.init
function Screen.MainMenu:init()
	old_fn(self)
	if self.tutorials_link then
		self.tutorials_link:SetOnClickFn( function()
            if self:GetCurrentMenu() ~= TutorialsMenu then
                if not self:IsMenuStart() then self:PopMenu() end
                self:PushMenu( TutorialsMenu )
            end
        end )
	end
end

function Screen.PauseMenu:OnTutorials()
    local options = {}

    if TheGame:GetDebug() or TheGame:GetGameProfile():HasSeenMessage('negotiation_tutorial') then
        table.insert(options, {txt=TheGame:Str"UI.PAUSEMENU.NEGOTIATION", fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "negotiation_tutorial")) end})
    end

    if TheGame:GetDebug() or TheGame:GetGameProfile():HasSeenMessage('battle_tutorial') then
        table.insert(options, {txt=TheGame:Str"UI.PAUSEMENU.BATTLE", fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "battle_tutorial")) end})
    end

    if TheGame:GetGameProfile():HasSeenMessage('rook_negotiation_tutorial') then
        table.insert(options, {txt=TheGame:Str"UI.PAUSEMENU.ROOK_NEGOTIATION", fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "rook_negotiation_tutorial")) end})
    end

    if TheGame:GetGameProfile():HasSeenMessage('rook_battle_tutorial') then
        table.insert(options, {txt=TheGame:Str"UI.PAUSEMENU.ROOK_BATTLE", fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "rook_battle_tutorial")) end})
    end

    if TheGame:GetDebug() or TheGame:GetGameProfile():HasSeenMessage('smith_battle_tutorial') then
        table.insert(options, {txt=TheGame:Str"UI.PAUSEMENU.SMITH_BATTLE", fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "smith_battle_tutorial"):SetAutoAdvance(false) ) end } )
    end

    if TheGame:GetDebug() or TheGame:GetGameProfile():HasSeenMessage('democracy_race_tutorial') then
        table.insert(options, {txt=TheGame:Str"UI.PAUSEMENU.RACE_TUTORIAL", fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "democracy_race_tutorial") ) end } )
    end
    
    table.insert(options, {txt=TheGame:Str"UI.PAUSEMENU.BACK", name = "BACK", fn = function() self:OnBack() end})
    self.menu:SetOptions( options )
    self.menu:AnimOptions()
    self.showing_submenu = true
end