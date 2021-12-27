Convo("DEM_UNLAWFUL_ATTACK")
    :Loc{
        OPT_ATTACK = "Convince {agent} to attack someone...",
        TT_ATTACK = "The target can potentially die, or they will be left in a bad shape and can't interfere with you for a while.",
        DIALOG_ATTACK = [[
            player:
                Can you attack someone for me?
            agent:
                Who do you plan to attack?
        ]],

        REQ_NO_TARGETS = "There are no targets.",

        OPT_CHOOSE = "Attack {1#agent}",

        DIALOG_BACK = [[
            player:
                Never mind.
        ]],
    }
    :Hub(function(cxt, who)
        if not DemocracyUtil.IsDemocracyCampaign(cxt.act_id) then
            return
        end

        if who and who:GetFaction():IsUnlawful() and not AgentUtil.HasPlotArmour(who) then
            local all_targets = DemocracyUtil.GetAllPunishmentTargets()

            Opt("OPT_ATTACK")
                :PreIcon(global_images.order)
                :PostText("TT_ATTACK")
                :ReqCondition(#all_targets > 0, "REQ_NO_TARGETS")
                :Dialog("DIALOG_INVESTIGATE")
                :LoopingFn(function(cxt)
                    for i, agent in ipairs(all_targets) do
                        if agent ~= who then
                            cxt:Opt("OPT_CHOOSE", agent)
                                :SetPortrait(agent)
                                :Fn(function(cxt)
                                    cxt:ReassignCastMember("target", agent)
                                    cxt:GoTo("STATE_SELECT_METHOD")
                                end)
                        end
                    end
                    StateGraphUtil.AddBackButton(cxt)
                        :Dialog("DIALOG_BACK")
                end)
        end
    end)
    :State("STATE_SELECT_METHOD")
        :Loc{
            DIALOG_SELECT = [[
                player:
                    Can you attack {target} for me?
                agent:
                {hard_target?
                    I don't know, it might be challenging.
                    |
                    Sure. piece of cake.
                    Probably.
                }
                {high_renown?
                    {target} has high influence, so I would imagine {target.heshe} is hard to find, or has bodyguards.
                    {high_strength?
                        Even if we manage to get {target.himher} alone, defeating {target.himher} would be challenging.
                    }
                    {not high_strength?
                        Although, if we can isolate {target.himher}, {target.heshe} would be an easy target.
                    }
                }
                {not high_renown?
                    {target} is not a person of high importance, so {target.heshe} probably won't have backups.
                    {high_strength?
                        Even so, defeating {target.himher} would be challenging.
                    }
                    {not high_strength?
                        I would imagine that {target.heshe} is an easy target.
                    }
                }
                    Now, how do you want me to deal with {target}?
                {no_kill?
                    Fair warning, though: I don't kill people. I have standards.
                }
                {hard_spare?
                    Fair warning, though: My methods are usually very lethal, so if you want to just send a message without killing the target, you come to the wrong guy.
                }
            ]],

            OPT_KILL = "Kill {target}",
            OPT_ANY = "Attack {target}, kill at discretion",
            OPT_SPARE = "Attack {target}, but DON'T kill {target.himher}",

            DIALOG_SELECTED_TARGET = [[
                agent:
                    Alright, I am on it.
            ]],
        }
        :Fn(function(cxt)

        end)
