if rawget(_G, "Aspect") and Aspect.StrippedInfluence then
    return
end
-- in case other mods want this
local StrippedInfluence = class("Aspect.StrippedInfluence", Aspect)
Content.AddAspect( "stripped_influence", StrippedInfluence )

StrippedInfluence.name = "Stripped Influence"
StrippedInfluence.texture = engine.asset.Texture("icons/aspects/status_intimidated.tex")
StrippedInfluence.desc = "This character's influence are stripped from them, nullifying their social grafts."
StrippedInfluence.alt_desc = "<#PENALTY>This might wear off after some time, so be prepared!</>"

StrippedInfluence.desc_fn = function(self, fmt_str)
    if self.stacks and self.stacks > 0 and not self.is_locked then
        return fmt_str .. "\n" .. (self.def or self):GetAltDesc()
    end
    return fmt_str
end

StrippedInfluence.status_effect = true

StrippedInfluence.keep_on_retire = true
StrippedInfluence.max_stacks = 99 -- who cares
StrippedInfluence.quippable = true

function StrippedInfluence:init(agent, stacks, is_locked)
    StrippedInfluence._base.init(self, agent)
    self.is_locked = is_locked
    self.stacks = stacks or 1 -- probably wears off immediately
end
function StrippedInfluence:HarvestStrings(t)
    StrippedInfluence._base.HarvestStrings(self, t)
    t[self:GetLocAltDescKey()] = self.alt_desc
end
function StrippedInfluence:GetLocAltDescKey()
    return self:GetLocPrefix() .. ".ALT_DESC"
end
function StrippedInfluence:GetAltDesc()
    local key = self:GetLocAltDescKey()
    local name = loc.format( LOC(key), self.agent )
    return name
end
-- just so its icon is displayed, but it doesn't get cleared by the game automatically.
function StrippedInfluence:IsStatusEffect() return false end

function StrippedInfluence:OnTimePass()
    if not self.is_locked and not self.agent:IsRetired() then
        local delta_stacks = math.min(self.stacks, math.random(0, 2))
        self:DeltaStacks(-delta_stacks)
        if delta_stacks == 0 then
            self.critical = (self.critical or 1) + 1
            -- if a person cannot recover for too long(stripped influence failed to decrease too many times)
            -- they will die, because they cannot pull themselves up together.
            -- this will be more of a problem if their renown is low or cs is low
            if self.critical > ((self.agent:GetRenown() or 1) + self.agent:GetCombatStrength()) / 2 then
                local rel = self.agent:GetRelationship()
                if rel > RELATIONSHIP.NEUTRAL then
                    TheGame:GetGameState():LogNotification( NOTIFY.FRIEND_KILLED, self.agent )
                elseif rel < RELATIONSHIP.NEUTRAL then
                    TheGame:GetGameState():LogNotification( NOTIFY.ENEMY_KILLED, self.agent )
                end
                self.agent:Kill()

            end
        elseif delta_stacks >= 2 then
            self.critical = math.max(0, (self.critical or 1) - 1)
        end
    end
end

function StrippedInfluence:OnGainAspect(agent)
    TheGame:GetGameState():GetPlayerAgent().graft_owner:RemoveSocialGraft(agent)
end
function StrippedInfluence:OnLoseAspect(agent)
    local rel = agent:GetRelationship()
    if rel == RELATIONSHIP.LOVED or rel == RELATIONSHIP.HATED then
        TheGame:GetGameState():GetPlayerAgent().graft_owner:AddSocialGraft(agent, rel)
    end
    TheGame:GetEvents():RemoveListener(self)
end
function StrippedInfluence:OnAgentReady(agent)
    TheGame:GetEvents():ListenForEvents( self, "graft_added")
end

function StrippedInfluence:OnGlobalEvent(eventname, ...)
    if eventname == "graft_added" then
        local graft = ...
        local agent = graft.userdata.agents and graft.userdata.agents[1]
        if agent == self.agent then
            TheGame:GetGameState():GetPlayerAgent().graft_owner:RemoveSocialGraft(agent)
        end
    end
end


-- replace relationship functions


local RelationshipsScreenBoon = Widget.RelationshipsScreenBoon
local old_fn = RelationshipsScreenBoon.init

function RelationshipsScreenBoon:init(...)
    old_fn(self, ...)

    -- Add the Active label and icon
    self.suppressed_icon = self:AddChild( Widget.Image( engine.asset.Texture( "UI/ic_locked.tex") ) )
        :SetTintColour( UICOLOURS.PENALTY )
        :SetSize( 18, 18 )
        :Bloom( 0.05 )
    self.suppressed_label = self:AddChild( Widget.Label( "title", 24, LOC( "UI.RELATIONSHIP_SCREEN.SUPPRESSED" ) ) )
        :SetGlyphColour( UICOLOURS.PENALTY )
        :Bloom( 0.05 )
    self:Layout()

end

local old_ref_fn = RelationshipsScreenBoon.Refresh

function RelationshipsScreenBoon:Refresh(boon, active, agent)


    if boon then
        if agent and agent:HasAspect("stripped_influence") then
            old_ref_fn(self, boon, false, agent)
            -- self.active_icon:SetShown( false )
            -- self.active_label:SetShown( false )
            self.suppressed_icon:SetShown( active )
            self.suppressed_label:SetShown( active )
            return self
        end
    end
    self.suppressed_icon:SetShown( false )
    self.suppressed_label:SetShown( false )
    old_ref_fn(self, boon, active, agent)
    return self
end

local old_layout = RelationshipsScreenBoon.Layout
function RelationshipsScreenBoon:Layout(...)
    old_layout(self, ...)
    if self.suppressed_icon then
        self.suppressed_icon:LayoutBounds( "center", "center", self.active_icon )
    end
    if self.suppressed_label then
        self.suppressed_label:LayoutBounds( "right", "center", self.active_label )
    end
    return self
end
