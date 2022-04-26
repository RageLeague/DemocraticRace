Convo("PROVOKE_DEMOCRACY")
    :Loc{

        OPT_PROVOKE = "Provoke {agent}",
        DIALOG_PROVOKE = [[
            player:
                !angry
                Hey, {agent}. I hear you've been talking about me.
            agent:
                !angry
                Maybe I have, grifter.
            player:
                %insult
            agent:
                !angry_threaten
                Say that again. I dare you.
        ]],
        NEGOTIATION_REASON = "Insult {agent} to provoke an attack!",
        DIALOG_WIN_NEGOTIATION_FIGHT = [[
            agent:
                !fight
                You're getting on my nerves, grifter.
        ]],
        DIALOG_WIN_NEGOTIATION_FIGHT_PST = [[
            player:
                !fight
                Let's dance, slugsucker!
        ]],
        DIALOG_LOSE_NEGOTIATION = [[
            agent:
                !angry_threaten
                Ha! You're all talk, grifter. Leave me alone.
        ]],
        DIALOG_DID_NOT_KILL_AGENT = [[
            agent:
                !injured
                Gah! I hate you!
                What do you even want from me?
            * You back away, asking yourself the same question.
        ]],
        DIALOG_KILLED_AGENT = [[
            * {agent} is dead, that's one loose end taken care of.
            * Still, you wonder what this will do to your reputation.
        ]],
        TT_PROVOKE_REASONS = "You are allowed to provoke this person because {1#listing}.",
        TT_PROVOKE = "If you manage to provoke {agent}, you can start a fight against them.\n<#PENALTY>Unlike in the base game, provoking has serious diplomatic consequences!</>",
        -- OPT_DEFEND = "Defend yourself!",
        REQ_CAN_NOT_PROVOKE_HIGH_RENOWN = "This person won't fall for your petty attempt at provocation.",
        REQ_CAN_NOT_PROVOKE_THIS_PERSON = "You can't provoke a party member.",

        TT_BACK = "I mean, if you want to back down, sure?",
        DIALOG_BACK = [[
            player:
                Nah, I won't fall for that.
            agent:
                !dubious
                ...
                !angry
                What was the point of that, then?
            * You know what? I was wondering the same thing!
        ]],

    }

    :Hub( function(cxt, who)
        if not DemocracyUtil.IsDemocracyCampaign(cxt.act_id) then
            return
        end

        if who then
            local canprovoke, reasons = DemocracyUtil.PunishTargetCondition(who)
            if not canprovoke then return end
            -- local can_provoke_here = true--not cxt.location:HasTag("HQ")
            local can_provoke_this_person = not who:IsInPlayerParty()

            cxt:Opt("OPT_PROVOKE")
                :PostText("TT_PROVOKE_REASONS", reasons)
                :Dialog( "DIALOG_PROVOKE" )
                -- :ReqCondition(can_provoke_here, "REQ_CAN_NOT_PROVOKE_HERE")
                :ReqCondition((who:GetRenown() or 1) <= who:GetCombatStrength(), "REQ_CAN_NOT_PROVOKE_HIGH_RENOWN")
                :ReqCondition(can_provoke_this_person, "REQ_CAN_NOT_PROVOKE_THIS_PERSON")
                :PostText("TT_PROVOKE")
                :ReceiveOpinion(OPINION.TRIED_TO_PROVOKE, {only_show = true})
                :Negotiation{
                    flags = NEGOTIATION_FLAGS.PROVOCATION,
                    reason_fn = function(minigame)
                        return loc.format(cxt:GetLocString("NEGOTIATION_REASON") )
                    end,

                    on_success = function(cxt, minigame)
                        -- local loopsound = AUDIO:CreateEventInstance("event:/sfx/ambience/scene/indoor/auction_house_brawl")
                        -- loopsound:Start()
                        -- AUDIO:PlayEvent("event:/sfx/ambience/story/auction_luminburst")
                        local kashio_stinger = "event:/music/pre_kashio_cnv"
                        cxt.encounter:SetMusicEvent( kashio_stinger )
                        cxt:GetAgent():OpinionEvent(OPINION.TRIED_TO_PROVOKE)
                        cxt:Dialog("DIALOG_WIN_NEGOTIATION_FIGHT")

                        cxt:Opt("OPT_FIGHT")
                            :Dialog("DIALOG_WIN_NEGOTIATION_FIGHT_PST")
                            -- :Fn(function()
                            --     loopsound:Stop()
                            --     loopsound:Release()
                            -- end)
                            :Battle{
                                -- flags = BATTLE_FLAGS.NO_SURRENDER,
                                on_win = function(cxt)
                                    if cxt:GetAgent():IsDead() then
                                        cxt:Dialog("DIALOG_KILLED_AGENT")
                                    else
                                        cxt:Dialog("DIALOG_DID_NOT_KILL_AGENT")
                                    end
                                    StateGraphUtil.AddEndOption(cxt)
                                end,
                                on_runaway = StateGraphUtil.DoRunAway,
                            }
                        StateGraphUtil.AddBackButton(cxt)
                            -- :ReqRelationship( RELATIONSHIP.DISLIKED )
                            :PostText("TT_BACK")
                            :Dialog("DIALOG_BACK")
                            -- :Fn(function()
                            --     loopsound:Stop()
                            --     loopsound:Release()
                            -- end)
                    end,

                    on_fail = function(cxt)
                        cxt:GetAgent():OpinionEvent(OPINION.TRIED_TO_PROVOKE)
                        cxt:Dialog("DIALOG_LOSE_NEGOTIATION")
                        StateGraphUtil.AddEndOption(cxt)
                    end,
                }

        end
    end)
