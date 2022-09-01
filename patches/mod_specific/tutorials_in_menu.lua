local function seek_upvalue_setter(func, name, source)
    for i=1,debug.getinfo(func,'u').nups do
        local k,v = debug.getupvalue(func,i)
        if type(v) == 'function' then
            local info = debug.getinfo(v,'S')
            if k == name and info.source == source then
                return v, function(val) debug.setupvalue(func,i,val) end
            end
            local ret,ret2 = seek_upvalue_setter(v, name, source)
            if ret then return ret,ret2 end
        elseif k == name and debug.getinfo(func,'S').source == source then
            return v, function(val) debug.setupvalue(func,i,val) end
        end
    end
end

local old_menu_fn,set = seek_upvalue_setter(Screen.MainMenu.init, "TutorialsMenu", "@scripts/ui/screens/mainmenu.lua")
set(function (screen)
    local t = old_menu_fn(screen)
    table.insert(t, #t, {txt = LOC"DEMOCRACY.TUTORIAL.TUTORIAL_SUPPORT_BUTTON", fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "democracy_tutorial_support") ) end, icon = engine.asset.Texture("large/tutorial_negotiation.tex"), colour = UICOLOURS.NEGOTIATION, buttonclass = Widget.TutorialsButton } )
    table.insert(t, #t, {txt = LOC"DEMOCRACY.TUTORIAL.TUTORIAL_STANCES_BUTTON", fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "democracy_tutorial_stances") ) end, icon = engine.asset.Texture("large/tutorial_negotiation.tex"), colour = UICOLOURS.NEGOTIATION, buttonclass = Widget.TutorialsButton } )
    return t
end)

local old_pause_fn = Screen.PauseMenu.OnTutorials
function Screen.PauseMenu:OnTutorials()
    local old_options_fn = self.menu.SetOptions
    function self.menu:SetOptions( options )
        table.insert(options, #options, {txt=(LOC"DEMOCRACY.TUTORIAL.TUTORIAL_SUPPORT_BUTTON"):upper(), fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "democracy_tutorial_support") ) end } )
        table.insert(options, #options, {txt=(LOC"DEMOCRACY.TUTORIAL.TUTORIAL_STANCES_BUTTON"):upper(), fn = function() TheGame:FE():PushScreen( Screen.SlideshowScreen( "democracy_tutorial_stances") ) end } )
        old_options_fn(self, options)
        self.SetOptions = old_options_fn
    end
    old_pause_fn(self)
end
