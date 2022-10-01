local patch_id = "CUSTOM_AGENT_PORTRAIT"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

local old_fn = Widget.AgentPortrait.SetAgent

function Widget.AgentPortrait:SetAgent( agent, ... )
    local result = old_fn(self, agent, ...)
    if self.agent and self.agent.custom_portrait then
        print("Has custom portrait:" .. self.agent.custom_portrait)
        self.portrait_image:Show():SetTexture( engine.asset.Texture( self.agent.custom_portrait ) )
        self.portrait_anim:Hide()
    end
    return result
end
