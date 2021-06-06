local patch_id = "FINISH_NEGOTIATION_ANYTIME"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local NegotiationPanel = Widget.NegotiationPanel
local old_fn = NegotiationPanel.init

function NegotiationPanel:init( minigame, encounter )
    old_fn(self, minigame, encounter)
    if minigame.start_params.finish_negotiation_anytime then
        print("oh ho ho")
        self.concede_btn = self.cardspanel:ConcedeButton(
            function() self:OnClickEndNegotiation() end, 
            LOC"UI.CARDS_PANEL.FINISH_BTN", 
            LOC"UI.NEGOTIATION_PANEL.FINISH_NEGOTIATION"):SetToolTipClass( Widget.NegotiationTooltip )
    end
    -- DBG(minigame.start_params)
end
function NegotiationPanel:OnClickEndNegotiation()
    local popup = Screen.YesNoPopup(LOC"UI.NEGOTIATION_PANEL.FINISH_CONFIRM_BTN", LOC"UI.NEGOTIATION_PANEL.FINISH_CONFIRM_BTN_TOOLTIP" ):
    SetFn( function( result )
        if result == Screen.YesNoPopup.YES then
            AUDIO:PlayEvent(SoundEvents.negotiation_concede)
            self.minigame:Win()
            self.end_turn = true
            -- table.insert( self.minigame.force_take_cards, "unconvincing" )
        end
    end )
    self:GetFE():InsertScreen( popup )
end

local old_params_fn = Negotiation.MiniGame.ParamsFromParty
function Negotiation.MiniGame.ParamsFromParty( caravan, agent, params, enc )
    local res = old_params_fn(caravan, agent, params, enc)
    res.finish_negotiation_anytime = params.finish_negotiation_anytime
    return res
end

local old_preview_fn = Widget.NegotiationPreviewPanel.init
local DETAILS_TILE_W = 340
function Widget.NegotiationPreviewPanel:init(card_type, ...)
    old_preview_fn(self, card_type, ...)
    self.finish_anytime = self.handicaps:AddChild( Widget.PreviewDetailsTile( DETAILS_TILE_W, engine.asset.Texture("ui/ic_handicaps_no_surrender.tex"), UICOLOURS.SUBTITLE, LOC"CONVO_OPTION.FINISH_NEGOTIATION_TITLE", LOC"CONVO_OPTION.FINISH_NEGOTIATION_DESC" ) )
end

local old_refresh_fn = Widget.NegotiationPreviewPanel.Refresh
function Widget.NegotiationPreviewPanel:Refresh(scenario, ...)
    if self.card_type == QCARD_TYPE.NEGOTIATION then
        self.finish_anytime:SetShown(scenario.finish_negotiation_anytime)
    else
        self.finish_anytime:SetShown(false)
    end
    return old_refresh_fn(self, scenario, ...)
end

Content.AddStringTable(patch_id .. "_STRINGS", {
    CONVO_OPTION = {
        FINISH_NEGOTIATION_TITLE = "Finish Anytime",
        FINISH_NEGOTIATION_DESC = "You can finish this negotiation at any time without penalties",
    },
    UI = {
        CARDS_PANEL = {
            FINISH_BTN = "Finish",
        },
        NEGOTIATION_PANEL = {
            FINISH_NEGOTIATION = "<b><#TITLE>Finish Negotiation</></>\nBecause of the special negotiation encounter, you can end the negotiation at any time without penalty.\n\nOnce you play a card, you cannot concede until the following turn.",
            FINISH_CONFIRM_BTN = "Finish",
            FINISH_CONFIRM_BTN_TOOLTIP = "Are you sure you want to end this negotiation?",
        },
    },

})