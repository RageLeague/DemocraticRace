local patch_id = "FIX_INTENT_TARGETING"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local negotiation_defs = require "negotiation/negotiation_defs"
local STATUS = negotiation_defs.STATUS

local old_fn = Negotiation.MiniGame.CanPlayCard
function Negotiation.MiniGame:CanPlayCard( card, target )
    local ok, result = old_fn(self, card, target)
    if not ok and result == CARD_PLAY_REASONS.INVALID_TARGET then
        if target and is_instance( target, Negotiation.Card ) and card.target_enemy and CheckAnyBits( card.target_enemy, TARGET_FLAG.INTENT ) then
            -- Issue happens and we need fixing
            if card.CanPlayCard then
                local ok, reason = card:CanPlayCard( card, self, target )
                if not ok then
                    return false, reason
                end
            end

            local ok, reason = self:CanTarget( card, target )
            if not ok then
                return false, reason
            end

            return true
        end
    end
    return ok, result
end

-- An empty function that returns nothing, but is important to not crash the game
function Negotiation.Card:GetResolve()
end

function Widget.NegotiationPanel:UpdateTargetFX( card )

    if card and self.minigame:GetStatus() == STATUS.PLAY_CARD then
        local source_widget = self:FindCardWidget( card )
        self.target_arrow:AttachSource( source_widget )
        local target_widget
        if is_instance( self.hover_target, Negotiation.Modifier ) then
            target_widget = self:FindSlotWidget( self.hover_target )
        elseif is_instance( self.hover_target, Negotiation.Card ) then
            target_widget = self.intents:FindIntentWidget( self.hover_target )
        end
        if target_widget then
            local target_state
            if not self.hover_target then
                target_state = TARGET_STATE.NONE
            -- In fact we can target intents
            -- elseif is_instance( self.hover_target, Negotiation.Card ) then
            --     -- Cna never target intents.
            --     target_state = TARGET_STATE.INVALID
            else
                local can_target, reason = self.minigame:CanPlayCard( card, self.hover_target )
                if can_target then
                    target_state = TARGET_STATE.VALID
                else
                    target_state = TARGET_STATE.INVALID
                end
            end

            self.target_arrow:AttachTarget( target_widget, target_state )
        else
            self.target_arrow:AttachMouseTarget()
        end

        self:HighlightTargets( card )
    else
        self.target_arrow:Detach()
        self:HighlightTargets( nil )
    end
end
