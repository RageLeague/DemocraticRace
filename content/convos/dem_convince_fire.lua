Convo("DEM_CONVINCE_FIRE")
    :Loc{
        OPT_CONVINCE_FIRE = "Convince {agent} to fire an employee...",
        TT_CONVINCE_FIRE = "Firing someone will cause them to hate you, but it will strip them of their influence temporarily.",

        REQ_ALREADY_FIRED = "Already fired someone today.",

        DIALOG_CONVINCE_FIRE = [[
            player:
                Can you fire someone for me...?
            agent:
            {liked?
                Depends on who you want to fire, I suppose...
            }
            {not liked and not disliked?
                That's an odd request...
            }
            {disliked?
                Why would I do that for you?
            }
        ]],

        OPT_FIRE_TARGET = "Fire {1#agent}",

        DIALOG_FIRE_TARGET = [[
            player:
                How about {target}? Can you fire {target.himher}?
            agent:
                I don't know. Can I?
        ]],
        DIALOG_FIRE_TARGET_SUCCESS = [[
            agent:
                What a terrible character {target} is.
            {same_place?
                    Hey, {target}!
                target:
                    !left
                    What, boss?
                agent:
                {is_slacking?
                    You seem to be slacking off.
                    Perhaps I should fire you.
                target:
                    What? This is outrageous!
                    If I'm slacking, then that means you're slacking as well!
                    This is double standards!
                agent:
                    I'm your boss, that's why.
                    That's it, you're fired for talking back!
                }
                {not is_slacking?
                    {player} told be all about you.
                    It seems that you aren't suitable for this job.
                    Go work somewhere else, 'cause you're fired.
                target:
                    What?
                    This is outrageous!
                agent:
                    Boo hoo.
                }
                player:
                    !left
                agent:
                    There, done.
                    If they are lucky, they can find somewhere else to work.
            }
            {not same_place?
                {is_slacking?
                    Constantly slacking off.
                    I have no need of someone like {target.himher}.
                }
                {not is_slacking?
                    I was not aware.
                    I guess I'll fire {target.himher}.
                }
                If they're lucky, they can find somewhere else to work.
            player:
                Thanks, {agent}.
            }
        ]],
        DIALOG_FIRE_TARGET_FAIL = [[
            agent:
            {not liked?
                I don't know. I would rather trust my employees than {disliked?<i>you</>|a random grifter}.
                That would be a no from me.
                Come back later if you have concrete evidence, rather than simply your hatred towards {target}.
            }
            {liked?
                I know that you're my friend, but that doesn't mean I'll fire {target}.
                {not is_slacking?
                    {target.HeShe} <i>is</> a hard-working employee.
                }
                Plus, it's hard to find a replacement.
                I'm sorry, I have to decline your request.
            }
            player:
                As you wish.
        ]],
        REQ_HIGH_RENOWN = "{agent} is in no position to fire {1#agent}.",

        SIT_MOD_PRESTIGEOUS = "{1#agent} is {2:of little importance|of some importance|of high importance|of very high repute|known by all}.",
        SIT_MOD_TRIED_FIRE_BEFORE = "You already tried to fire someone before.",
        SIT_MOD_SAME_FACTION = "{1#agent} has support from the faction at this location.",
        SIT_MOD_FRIENDLY = "{1#agent} is a friend of {agent}.",
        SIT_MOD_ENEMY = "{1#agent} is an enemy of {agent}.",
        SIT_MOD_SLACK_OFF = "{1#agent} is currently slacking off.",

    }
    :Hub(function(cxt, who)
        if not DemocracyUtil.IsDemocracyCampaign(cxt.act_id) then
            return
        end
        if who and who:GetBrain():GetWorkplace() and who:GetBrain():GetWorkplace():GetProprietor() == who then
            local fire_targets = {}
            local workplace = who:GetBrain():GetWorkplace()
            for i, work in workplace:WorkPositions() do
                local worker = work:GetAgent()
                if worker and worker ~= who and not AgentUtil.HasPlotArmour(worker) and worker:IsSentient() then
                    local t = worker
                    table.insert(fire_targets, t)
                end
            end
            if #fire_targets > 0 then
                cxt:Opt("OPT_CONVINCE_FIRE")
                    :PreIcon( global_images.order )
                    :PostText("TT_CONVINCE_FIRE")
                    :ReqCondition(not who:HasMemoryFromToday("CONVINCED_FIRE_EMPLOYEE"), "REQ_ALREADY_FIRED")
                    :ReqRelationship( RELATIONSHIP.DISLIKED )
                    :LoopingFn(function(cxt)
                        if cxt:FirstLoop() then
                            cxt:Dialog("DIALOG_CONVINCE_FIRE")
                        end
                        for i, agent in ipairs(fire_targets) do
                            local sit_mod = {}
                            table.insert(sit_mod, {value = 5 * (agent:GetRenown() - 1), text = loc.format(cxt:GetLocString("SIT_MOD_PRESTIGEOUS", agent, agent:GetRenown()))})

                            if who:HasMemory("CONVINCED_FIRE_EMPLOYEE") then
                                table.insert(sit_mod, {value = 10, text = cxt:GetLocString("SIT_MOD_TRIED_FIRE_BEFORE")})
                            end
                            if agent:GetFactionID() == workplace:GetFactionID() then
                                table.insert(sit_mod, {value = 5, text = loc.format(cxt:GetLocString("SIT_MOD_SAME_FACTION", agent))})
                            end
                            if agent:GetRelationship(who) > RELATIONSHIP.NEUTRAL then
                                table.insert(sit_mod, {value = 10, text = loc.format(cxt:GetLocString("SIT_MOD_FRIENDLY", agent))})
                            end
                            if agent:GetRelationship(who) < RELATIONSHIP.NEUTRAL then
                                table.insert(sit_mod, {value = -10, text = loc.format(cxt:GetLocString("SIT_MOD_ENEMY", agent))})
                            end
                            local function IsSlacking(agent)
                                return agent:GetBrain() and agent:GetBrain():GetWorkPosition() and agent:GetBrain():GetWorkPosition():ShouldBeWorking() and agent:GetLocation() ~= workplace
                            end
                            if IsSlacking(agent) then
                                table.insert(sit_mod, {value = -10, text = loc.format(cxt:GetLocString("SIT_MOD_SLACK_OFF", agent))})
                            end

                            cxt:Opt("OPT_FIRE_TARGET", agent)
                                :SetPortrait(agent)
                                :ReqCondition(agent:GetRenown() <= who:GetRenown(), "REQ_HIGH_RENOWN", agent)
                                :Fn(function(cxt)
                                    cxt:ReassignCastMember("target", agent)
                                    who:Remember("CONVINCED_FIRE_EMPLOYEE")
                                    cxt.enc.scratch.is_slacking = IsSlacking(agent)
                                    cxt.enc.scratch.same_place = agent:GetLocation() and agent:GetLocation() == who:GetLocation()
                                end)
                                :Negotiation{
                                    acting_against = {agent},
                                    subject = agent,
                                    hinders = cxt.location == agent:GetLocation() and {agent},
                                    situation_modifiers = sit_mod,
                                    on_success = function(cxt)
                                        cxt:Dialog("DIALOG_FIRE_TARGET_SUCCESS")
                                        agent:OpinionEvent(OPINION.GOT_FIRED)
                                        -- also hates the proprietor because they fired them
                                        agent:OpinionEvent(OPINION.GOT_FIRED, nil, who)
                                        agent:GetBrain():GetWorkPosition():Fire()
                                        -- they may or may not find another way to live.
                                        agent:GainAspect("stripped_influence", math.random(2, 4))
                                        agent:Remember("GOT_FIRED_FROM_JOB", who)
                                        if not IsSlacking(agent) then
                                            agent:GetBrain():MoveToHome()
                                        end
                                        StateGraphUtil.AddEndOption(cxt)
                                    end,
                                    on_fail = function(cxt)
                                        cxt:Dialog("DIALOG_FIRE_TARGET_FAIL")
                                    end,
                                }
                        end
                        StateGraphUtil.AddBackButton(cxt)
                    end)
            end
        end
    end)