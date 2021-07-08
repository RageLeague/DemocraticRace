local RISE_CANDIDATES = {
    LABORER = {"RISE_REBEL", "RISE_PAMPHLETEER"},
    HEAVY_LABORER = {"RISE_RADICAL"},
}

local old_fn = WorkPosition.TryHire

function WorkPosition:TryHire(verbose, ...)
    if DemocracyUtil.IsDemocracyCampaign() then
        local best_agent
        local character_def
        if self.content.promote_def then
            if type(self.content.promote_def) == "string" then
                character_def = self.content.promote_def
            else
                character_def = table.arraypick(self.content.promote_def)
            end
        end

        if character_def then
            if RISE_CANDIDATES[character_def] and math.random() < 0.35 then
                character_def = table.arraypick(RISE_CANDIDATES[character_def])
                if verbose then
                    print( "\tSubstitute agent with rise", self.id, character_def )
                end
            end
            best_agent = TheGame:GetGameState():AddSkinnedAgent( character_def )

            if verbose then
                print( "\tSpawned", self.id, best_agent )
            end
        else
            if verbose then
                print( "\tNo character def defined for spawn fallback" )
            end
        end

        if best_agent then
            if verbose then
                print ("picked ", self.id, best_agent, do_teleport )
            end
            self:Hire(best_agent)
        end
        return
    end
    return old_fn(self, verbose, ...)
end