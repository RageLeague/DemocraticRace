return function()
    if not TheGame:GetGameState() then
        UIHelpers.InfoPopup( LOC"DEMOCRACY.COLLECT_DECK.NOT_IN_GAME", LOC"DEMOCRACY.COLLECT_DECK.NOT_IN_GAME_DESC" )
        return
    end
    if not DemocracyUtil.IsDemocracyCampaign() then
        UIHelpers.InfoPopup( LOC"DEMOCRACY.COLLECT_DECK.WRONG_CAMPAIGN", LOC"DEMOCRACY.COLLECT_DECK.WRONG_CAMPAIGN_DESC" )
        return
    end
    local quest = TheGame:GetGameState():GetMainQuest()
    local deck_state = TheGame:GetGameState():GetDeckState()
    deck_state.prestige = TheGame:GetGameState():GetAdvancementLevel()
    deck_state.day = quest.param.day
    deck_state.sub_day_progress = quest.param.sub_day_progress
    local return_str = serpent.line(deck_state)
    engine.inst:SetClipboardText( return_str )
    UIHelpers.InfoPopup( LOC"DEMOCRACY.COLLECT_DECK.SUCCESS", LOC"DEMOCRACY.COLLECT_DECK.SUCCESS_DESC" )
end