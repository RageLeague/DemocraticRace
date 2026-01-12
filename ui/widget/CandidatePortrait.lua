require "ui/widget"
require "ui/widgets/anim"
require "ui/widgets/animatedcharacter"

local assets =
{
    portrait_top = engine.asset.Texture( "UI/portrait_top.tex"),
    portrait_gradient = engine.asset.Texture( "UI/portrait_gradient.tex" ),
    portrait_mask = engine.asset.Texture( "UI/portrait_mask.tex" ),
    portrait_captive = engine.asset.Texture( "UI/portrait_captive.tex" ),

    portrait_frame = {
        ["ADMIRALTY"] = engine.asset.Texture( "UI/portrait_frame_admiralty.tex" ),
        ["CULT_OF_HESH"] = engine.asset.Texture( "UI/portrait_frame_hesh.tex" ),
        ["SPARK_BARONS"] = engine.asset.Texture( "UI/portrait_frame_tycoonclust.tex" ),
        ["BANDITS"] = engine.asset.Texture( "UI/portrait_frame_spree.tex" ),
        ["FEUD_CITIZEN"] = engine.asset.Texture( "UI/portrait_frame_citizen.tex" ),
        ["RISE"] = engine.asset.Texture( "UI/portrait_frame_citizen.tex" ),
        ["JAKES"] = engine.asset.Texture( "UI/portrait_frame_jakes.tex" ),
    },

    portrait_frame_player = engine.asset.Texture( "UI/portrait_frame_player.tex" ),
    portrait_frame_default = engine.asset.Texture( "UI/portrait_frame.tex" ),

    candidate_active = engine.asset.Texture( "DEMOCRATICRACE:assets/ui/candidate_status_active.png" ),
    candidate_allied = engine.asset.Texture( "DEMOCRATICRACE:assets/ui/candidate_status_allied.png" ),
    candidate_dropped = engine.asset.Texture( "DEMOCRATICRACE:assets/ui/candidate_status_dropped.png" ),
}

local CandidatePortrait = class( "DemocracyClass.Widget.CandidatePortrait", Widget.Clickable )

local portrait_padding = 10
local portrait_extra_space = 20 -- extra padding added to the scissor on the side they're facing
local portrait_w, portrait_h = 100, 100
local TRACK_SZ = 32
local ICON_SIZE = portrait_w*0.2

function CandidatePortrait:init( simple_bg_colour )
    Widget.init( self )

    self.artw, self.arth = portrait_w, portrait_h
    self.hover_check = true

    self.portrait_frame = Widget.Image( engine.asset.Texture( "UI/portrait_frame_citizen.tex" ) ):SetSize( portrait_w*2, portrait_h*2 )
    self.portrait_frame:UnblockMouse():SetHiddenBoundingBox(true):SetBloom(.05)

    self.portrait_gradient = Widget.Image( assets.portrait_gradient ):SetSize( portrait_w, portrait_h ):SetBloom(.05)
    self.portrait_top = Widget.Image( assets.portrait_top ):SetSize( portrait_w*2, portrait_h*2 ):SetHiddenBoundingBox(true)
    self.portrait_mask = Widget.Image( assets.portrait_mask ):SetSize( portrait_w*2, portrait_h*2 ):SetHiddenBoundingBox(true)

    self.masking_container = Widget()
    self.portrait = Widget.AgentPortrait()

    self.opinion_icon = Widget.Image(assets.candidate_active, ICON_SIZE, ICON_SIZE)
    self.faction_icon = Widget.Image(nil, ICON_SIZE, ICON_SIZE)
    self.captive_icon = Widget.Image(assets.portrait_captive, ICON_SIZE, ICON_SIZE):SetBloom(0.15):SetToolTip(LOC"UI.CHARACTER_PORTRAIT.CAPTIVE_TOOLTIP"):SetHiddenBoundingBox(true)

    self.root = Widget():AddChildren
    {
        self.portrait_frame,
        self.portrait_gradient,
        self.masking_container:SetStencilContext(true):AddChildren
        {
            self.portrait_mask:SetMask(true),
            self.portrait:SetStencilTest(true)
        },
        self.portrait_top,
        self.opinion_icon,
        self.faction_icon,
        self.captive_icon,
    }

    self:AddChildren{
        self.root,
    }

    self:SetFacing(true)
end

function CandidatePortrait:SetBGColour(simple_bg_colour)
    self.simple_bg_colour = simple_bg_colour
end

function CandidatePortrait:SetHeight( h )
    self.portrait:SetSize( h )
    local s = h/portrait_h
    self.artw = s*portrait_w
    self.arth = s*portrait_h
    self.portrait_frame:SetSize(self.artw*2, self.arth*2)
    self.portrait_top:SetSize(self.artw*2, self.arth*2)
    self.portrait_mask:SetSize(self.artw*2, self.arth*2)
    self.portrait_gradient:SetSize(self.artw, self.arth)

    ICON_SIZE = self.artw * 0.18
    self.opinion_icon:SetSize( ICON_SIZE*1.4, ICON_SIZE*1.4 )
    self.faction_icon:SetSize( ICON_SIZE*1.53, ICON_SIZE*1.53 )
    self.captive_icon:SetSize( ICON_SIZE*1.4, ICON_SIZE*1.4 )

    self:SetFacing(self.facing)
    return self
end

function CandidatePortrait:GetSize()
    return self.artw, self.arth
end

function CandidatePortrait:GetFacing()
    return self.facing
end

function CandidatePortrait:SetFacing( right )
    local sx = (right and 1 or -1)
    self.facing = right

    self.portrait:SetPos( self.artw*0.1, 0 )
    self.opinion_icon:LayoutBounds( "center", "center", self.portrait_gradient ):Offset( 0, self.arth*0.45)
    self.faction_icon:LayoutBounds( "center", "center", self.portrait_gradient ):Offset( 0, -self.arth*0.422)
    self.captive_icon:LayoutBounds( "center", "center", self.portrait_gradient ):Offset( self.artw * 0.415, 0)

    self.root:SetScale( sx, 1 )
    return self
end

function CandidatePortrait:GetAnim()
    return self.anim
end


function CandidatePortrait:OnAgentEvent(event, ...)
    self:SetCharacter( self.character )
end

function CandidatePortrait:OnRemoved()
    if self.character then
        self.character:RemoveListener(self)
    end
end

function CandidatePortrait:UpdateCandidateStatus( char )
    if not TheGame:GetGameState() then
        return self
    end
    if char == TheGame:GetGameState():GetPlayerAgent() then
        self.opinion_icon:SetTexture(assets.candidate_active)
        self.opinion_icon:SetToolTip(LOC"DEMOCRACY.CANDIDATE_STATUS_TOOLTIP.ACTIVE")
        return self
    end
    if DemocracyUtil.GetAlliance(char) then
        self.opinion_icon:SetTexture(assets.candidate_allied)
        self.opinion_icon:SetToolTip(LOC"DEMOCRACY.CANDIDATE_STATUS_TOOLTIP.ALLIED")
    else
        if DemocracyUtil.IsCandidateInRace(char) then
            self.opinion_icon:SetTexture(assets.candidate_active)
            self.opinion_icon:SetToolTip(LOC"DEMOCRACY.CANDIDATE_STATUS_TOOLTIP.ACTIVE")
        else
            self.opinion_icon:SetTexture(assets.candidate_dropped)
            self.opinion_icon:SetToolTip(LOC"DEMOCRACY.CANDIDATE_STATUS_TOOLTIP.DROPPED")
        end
    end
    return self
end

function CandidatePortrait:SetCharacter( char )
    if self.character then
        self.character:RemoveListener(self)
    end

    self.character = char

    if char then
        char:ListenForAny( self, CandidatePortrait.OnAgentEvent)
    end

    self.captive_icon:Hide()

    if char == nil then
        self.portrait:Hide()
        self.anim:Hide()
    -- elseif char:IsDead() then
    --     self.anim:Refresh(char):Show()
    --     self.anim:Play( "portrait_injured" )
    --     self.anim:SetSaturation(.3)

    -- elseif char:IsCaptiveMember() then
    --     self.anim:Refresh(char):Show()
    --     self.anim:Play( "portrait_angry" )
    --     self.captive_icon:Show()

    -- elseif char:GetSpecies() == SPECIES.SNAIL and char:HasTag("rustled") then
    --     self.anim:Refresh(char):Show()
    --     self.anim:Play( "portrait_neutral" )
    else
        self.portrait:SetAgent(char):Show()
        self:UpdateCandidateStatus( char )

        local rel = char:GetRelationship()
        local tint_colour = RELATIONSHIP_COLOURS[ rel ] or RELATIONSHIP_COLOURS[ RELATIONSHIP.NEUTRAL ]
        local bg_colour = 0x09E1DCff

        -- Update faction
        local faction = char:GetFaction()
        if faction and faction:GetIcon() and self.character:IsPlayer() == false then
            self.portrait_frame:SetTexture( assets.portrait_frame[ faction:GetID() ] or assets.portrait_frame[ "FEUD_CITIZEN" ] )
            self.faction_icon:Show()
            self.faction_icon:SetTexture( faction and faction:GetIcon() )
            self.faction_icon:SetToolTip( faction:GetName() )
            tint_colour = faction:GetColour()
            bg_colour = faction:GetColourBg()
        else
            self.faction_icon:Hide()
            self.portrait_frame:SetTexture( assets.portrait_frame["FEUD_CITIZEN"] )
            tint_colour = 0xcbfbecFF
        end

        self.portrait_frame:SetTintColour( tint_colour )
        self.portrait_top:SetTintColour( tint_colour )
        self.portrait_gradient:SetTintColour( bg_colour )

        if char:IsPlayer() then
            self.portrait_frame:SetTexture( assets.portrait_frame_player )
            self.portrait_frame:SetTintColour( UICOLOURS.SUBTITLE )
            self.portrait_top:SetTintColour( UICOLOURS.SUBTITLE )
            self.portrait_gradient:SetTintColour( 0x072F34ff )
            self.portrait_top:Hide()
        end

        self.portrait_frame:SetTintColour( UICOLOURS.SUBTITLE )
        self.portrait_top:SetTintColour( UICOLOURS.SUBTITLE )
        self.portrait_gradient:SetTintColour( 0x006774ff )

    end

    return self
end

function CandidatePortrait:HandleControlUp(control)

    if control:Has( Controls.Digital.MENU_ACCEPT ) then
        if self.character and TheGame:GetDebug() and TheGame:GetInput():IsModifierControl() then
            TheGame:GetDebug():CreatePanel( DebugAgent( self.character ))
            return
        end

        if self.hover and self.fn then
            self.fn()
            return true
        end

    end
end

function CandidatePortrait:SetFn(fn)
    self.fn = fn
    return self
end

function CandidatePortrait:OnGainHover()

    if self.hoverfocusfn then
        self.hoverfocusfn(self.hover, self.focus)
    end

end

function CandidatePortrait:OnLoseHover()
    if self.hoverfocusfn then
        self.hoverfocusfn(self.hover, self.focus)
    end
end

function CandidatePortrait:SetHoverFocusFn(fn)
    self.hoverfocusfn = fn
    return self
end

