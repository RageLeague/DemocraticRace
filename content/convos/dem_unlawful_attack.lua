local KILL_PROHIBITED = {
    "RISE_PAMPHLETEER",
    "RISE_VALET"
}
local function CanKill(agent)
    return not table.arraycontains(KILL_PROHIBITED, agent:GetContentID())
end

local KILL_FORCED = {
    "JAKES_ASSASSIN",
    "JAKES_ASSASSIN2"
}
local function MustKill(agent)
    return table.arraycontains(KILL_FORCED, agent:GetContentID())
end

Convo("DEM_UNLAWFUL_ATTACK")
    :Loc{
        OPT_ATTACK = "Convince {agent} to attack someone...",
        TT_ATTACK = "The target can potentially die, or they will be left in a bad shape and can't interfere with you for a while.",
        DIALOG_ATTACK = [[
            player:
                !cagey
                Say...I need some dirty deeds done dirt cheap, if you know what I mean.
            agent:
                Yeah, I get you.
                Whose going to be hit?
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

            cxt:Opt("OPT_ATTACK")
                :PreIcon(global_images.order)
                :PostText("TT_ATTACK")
                :ReqCondition(#all_targets > 0, "REQ_NO_TARGETS")
                :Dialog("DIALOG_ATTACK")
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
                    !thought
                    {target}'s got a good bit of cash in their pockets. Guards, mechs, maybe a few solid walls of concrete are gonna be the start of {target.hisher} protection.
                    {high_strength?
                        Not only that, {target} ain't shoddy in a fight as well. Gonna have my hands full with this mission.
                    }
                    {not high_strength?
                        !handwring
                        Although {target} {target.himher}self ain't that tough. It'll be fun plucking {target.hisher} plumage. See how high n' mighty they are without a goon to throw in the way.
                    }
                }
                {not high_renown?
                    I think {target}'s not that influential. No one's gonna cry a penny when {target.heshe}'s gone.
                    {high_strength?
                       Although making {target} "gone" is gonna be difficult. They're a schmoe with some good combat training.
                    }
                    {not high_strength?
                        Not even good at fighting at that! I could probably deal with {target} and still have enough time to grab a beer.
                    }
                }
                    Alright, Target bio out of the way, how'd you want {target.himher} dealt with?
                {no_kill?
                    !point
                    Note that death isn't on the line here. I'm letting them live, whether that's good for you or not.
                }
                {hard_spare?
                    !throatcut
                    I should warn you though. My definition of mercy is...<i>warped</>, you could say.
                    If you're looking for a lighter touch, look elsewhere.
                }
            ]],

            OPT_KILL = "Kill {target}",
            REQ_NO_KILL = "{agent} doesn't do killing",
            OPT_ANY = "Attack {target}, kill at discretion",
            OPT_SPARE = "Attack {target}, but DON'T kill {target.himher}",
            REQ_FORCE_KILL = "{agent}'s methods are always lethal",

            DIALOG_SELECTED_TARGET = [[
                agent:
                    !salute
                    You've got it.
            ]],
        }
        :Fn(function(cxt)
            local target = cxt:GetCastMember("target")
            local strength_balance = 0

            local renown_delta = target:GetRenown() - cxt:GetAgent():GetRenown()
            if renown_delta >= 0 then
                cxt.enc.scratch.high_renown = true
            end

            local strength_delta = target:GetCombatStrength() - cxt:GetAgent():GetCombatStrength()
            strength_balance = strength_balance - strength_delta

            if target:IsBoss() then
                strength_balance = strength_balance - 4
            end

            if cxt:GetAgent():IsBoss() then
                strength_balance = strength_balance + 4
            end

            if strength_delta >= 0 or target:IsBoss() then
                cxt.enc.scratch.high_strength = true

            end

            cxt.enc.scratch.no_kill = not CanKill(cxt:GetAgent())
            cxt.enc.scratch.hard_spare = MustKill(cxt:GetAgent())

            cxt:Dialog("DIALOG_SELECT")

            local function AddTargetOption(opt, cost, no_kill, must_kill)
                opt:Dialog("DIALOG_SELECTED_TARGET")
                    :Fn(function(cxt)
                        local overrides = {
                            cast = {
                                hunter = cxt:GetAgent(),
                                target = target,
                            },
                            parameters = {
                                attack_difficulty = strength_balance,
                                no_kill = no_kill,
                                must_kill = must_kill,
                                hire_amt = cost,
                            },
                        }
                        local quest, err = QuestUtil.SpawnQuest("FOLLOWUP_UNLAWFUL_ATTACK", overrides)
                        if quest then
                            quest:Activate()
                        else
                            DBG(err)
                        end
                    end)
                    :DoneConvo()
            end

            local kill_opt, kill_cost = cxt:Opt("OPT_KILL")
                :ReqCondition(not cxt.enc.scratch.no_kill, "REQ_NO_KILL")
                :DeliverMoney(cxt:GetAgent():GetCombatStrength() * 30 + (cxt:GetAgent():IsBoss() and 150 or 70))

            AddTargetOption(kill_opt, kill_cost, false, true)

            local any_opt, any_cost = cxt:Opt("OPT_ANY")
                :DeliverMoney(cxt:GetAgent():GetCombatStrength() * 30 + (cxt:GetAgent():IsBoss() and 120 or 40))

            AddTargetOption(any_opt, any_cost, cxt.enc.scratch.no_kill, cxt.enc.scratch.hard_spare)

            local spare_opt, spare_cost = cxt:Opt("OPT_SPARE")
                :ReqCondition(not cxt.enc.scratch.hard_spare, "REQ_FORCE_KILL")
                :DeliverMoney(cxt:GetAgent():GetCombatStrength() * 30 + (cxt:GetAgent():IsBoss() and 130 or 50))

            AddTargetOption(spare_opt, spare_cost, true, false)

            StateGraphUtil.AddBackButton(cxt)
        end)
