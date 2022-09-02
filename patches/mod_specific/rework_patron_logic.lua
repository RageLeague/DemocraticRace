local old_populate = LocationUtil.PopulateLocation

local faction_weights =
{
    [RELATIONSHIP.HATED] = 0,
    [RELATIONSHIP.DISLIKED] = .5,
    [RELATIONSHIP.NEUTRAL] = 1,
    [RELATIONSHIP.LIKED] = 1.25,
    [RELATIONSHIP.LOVED] = 1.5,
}

function LocationUtil.PopulateLocation(location, patron_filter, to_seat_override, ...)
    if not DemocracyUtil.IsDemocracyCampaign() then
        return old_populate(location, patron_filter, to_seat_override, ...)
    end
    -- Custom logic for democracy campaign
    local old_patron_capacity = Location.GetCurrentPatronCapacity
    -- Hack: Set patron capacity to 0 when executing, so the game skips the default logic
    Location.GetCurrentPatronCapacity = function(self)
        return 0
    end
    local result = old_populate(location, patron_filter, to_seat_override, ...)
    -- Custom logic
    -- Reset original function
    Location.GetCurrentPatronCapacity = old_patron_capacity

    local to_seat = to_seat_override or ( location:GetCurrentPatronCapacity() - location:GetNumCurrentPatrons() )
    if to_seat > 0 then

        local candidates = {}

        --find all of the agents who are free to move around
        for _, agent in TheGame:GetGameState():Agents() do
            if not AgentUtil.CanAct(agent) then
                -- disabled
            elseif agent:GetBrain():GetWorkPosition() and agent:GetBrain():GetWorkPosition():ShouldBeWorking() then
                --we're busy
            elseif patron_filter and not patron_filter(agent) then
                -- we're filtered
            elseif not agent:InLimbo() then
                -- already in the world.

            elseif agent:HasInactiveQuestMembership() then
                -- don't tempt fate

            elseif agent:HasTag("no_patron") then
                -- not someone that we can touch

            elseif AgentUtil.HasDynamicPlotArmour(agent) then
                -- probably shouldn't be here

            elseif AgentUtil.CanAgentPatronizeLocation( location, agent ) then
                candidates[agent] = 1
            end
        end

        for k = 1, to_seat do
            local num_friends = 0
            local num_enemies = 0
            for _,v in pairs( location.agents ) do
                if v:GetRelationship() > RELATIONSHIP.NEUTRAL then
                    num_friends = num_friends + 1
                elseif v:GetRelationship() < RELATIONSHIP.NEUTRAL then
                    num_enemies = num_enemies + 1
                end
            end

            -- try not to stack the locations too badly.
            local enough_friends = num_friends >= 1
            local enough_enemies = num_enemies >= 1

            local found_agent

            -- Custom logic. Use weighted pick instead of sorting
            for agent, _ in pairs(candidates) do
                if agent:IsCurrentlyImportant() then
                    found_agent = agent
                    break
                end
                local score = faction_weights[TheGame:GetGameState():GetFaction(location:GetFactionID()):GetFactionRelationship( agent:GetFactionID() )] or 1
                if agent:GetRelationship() > RELATIONSHIP.NEUTRAL and enough_friends then
                    score = score * 0.25
                end
                if agent:GetRelationship() < RELATIONSHIP.NEUTRAL and enough_enemies then
                    score = score * 0.25
                end
                candidates[agent] = score
            end

            if not found_agent then
                found_agent = weightedpick(candidates)
            end

            if found_agent then
                -- DBG({location = location, candidates = shallowcopy(candidates) } )
                found_agent:GetBrain():SendToPatronize(location)
                print ("FOUND PATRON", found_agent, found_agent:HasQuestMembership())
                candidates[found_agent] = nil
            end
        end

        --after all that, if we still need more patrons, generate them
        local to_generate = location:GetCurrentPatronCapacity() - location:GetNumCurrentPatrons()

        if to_generate > 0 then
            if location:GetContent().patron_data.patron_generator then
                for k = 1, to_generate do
                    location:GetContent().patron_data.patron_generator(location)
                end
            elseif location:GetContent().patron_data.patron_defs then
                for k = 1, to_generate do
                    TheGame:GetGameState():AddSkinnedAgent( location:GetContent().patron_data.patron_defs ):GetBrain():SendToPatronize(location)
                end
            end

        end

        location:SetCurrentPatronCapacity( 0 )
    end

    return result
end
