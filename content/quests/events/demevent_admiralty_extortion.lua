local CHANCE_FOR_ENEMY = .35

local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}

:AddCast{
    cast_id = "admiralty",
    condition = function ( agent, quest )
        if agent:GetFactionID() ~= "ADMIRALTY" then
            return false, "Agent is not Admiralty"
        end
        return QuestUtil.FilterAgentForDifficulty(math.min(quest:GetRank(), 4), agent, true, true)
    end
}
:AddCastFallback{
    cast_fn = function(quest, t)
        local defs = {"ADMIRALTY_GOON", "ADMIRALTY_GUARD", "ADMIRALTY_GUARD", "ADMIRALTY_PATROL_LEADER"}
        table.insert( t, quest:CreateSkinnedAgent(defs[math.min(#defs, quest:GetRank())]) )
    end,
}

:AddCast{
    cast_id = "laborer",
    condition = function ( agent, quest )
        if agent:GetFactionID() == "ADMIRALTY" then return false, "Agent is Admiralty" end
        return DemocracyUtil.GetWealth(agent) == 1, "Agent too high renown"
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        local defs = {"LABORER", "HEAVY_LABORER", "RISE_REBEL", "BANDIT_GOON", "BANDIT_GOON2", "JAKES_RUNNER"}
        table.insert( t, quest:CreateSkinnedAgent(table.arraypick(defs)) )
    end,
}

QDEF:AddConvo()
    :ConfrontState("STATE_INTERVENE")
        :Loc{
            DIALOG_INTRO = [[
                admiralty:
                    !left
                laborer:
                    !right
                    !injured
                * You see {admiralty} trying to extort {laborer}.
                admiralty:
                    It's nothing personal, believe me. Hand over the money or else
                laborer:
                    Really? How much could I give you that a jake couldn't give?
                admiralty:
                    You keep bringing that up whenever we do this song and dance. It's gotten old.
                    Spill the shills or I spill your guts.
                * Oh look, a conflict! Will you intervene?
            ]],

            OPT_EXTORT = "Convince {laborer} to give money to {admiralty}",
            DIALOG_EXTORT = [[
                player:
                    !left
                    I know that this looks bad on the Admiralty, but you really aren't getting the burnt end in this arrangement.
            ]],


            DIALOG_EXTORT_SUCCESS = [[
                player:
                    Look at it this way. A common spree bandit would've taken your shills AND beat you to a pulp.
                    At least the Admiralty is the evil you know, not the evil waiting to ambush you.
                    They keep the streets safe from thieves so you won't be on edge every time you walk home from work.
                laborer:
                    I-I...Hesh damn it, you're right.
                    !angry_permit
                    As soon as I get time, I'm filing a report against this.
                admiralty:
                    !right
                    Sure you will. Have a nice day.
                    !give
                    Well, thank you {player}. Suppose you can have a bit of this for keeping it civil.
                player:
                    !take
                    Thank you {admiralty}. I'll be on my way.
            ]],
            DIALOG_EXTORT_FAIL = [[
                player:
                    You may think this is all the admiralty is, but I guarantee to you, {admiralty} is the exception, not the rule.
                laborer:
                    An exception just above the rule, you mean.
                    Face it, you're the privileged politician who doesn't have to deal with this.
                    You're probably just saying that to garner support from the Admiralty.
                    Politicians like you should stay out of our civilian affairs.
            ]],

            OPT_DEFEND = "Convince {admiralty} to leave {laborer} alone",
            DIALOG_DEFEND = [[
                admiralty:
                    !right
                player:
                    !left
                    It's clear you aren't thinking long term about your career. Let me enlighten you for a moment.
            ]],
            DIALOG_DEFEND_SUCCESS = [[
                player:
                    Here's how I see it. If you, {admiralty}, continue to extort the poor like this.
                    Well, some might decide you don't deserve as much funding as you get now.
                    That's going to be a cut in your wages, once they realize YOU'RE the reason the coffers run dry.
                    It's a self fulfilling cycle, and you'll end up extorting a lot more people.
                    !throatcut
                    And eventually you'll find the one customer you shouldn't have messed with...
                admiralty:
                    ...
                    Alright, alright, I get it.
                    Enough with the prophecy. I promise to stop extorting "the poor", as you high n' mighties call them.
                player:
                    Pinky promise?
                admiralty:
                    Hesh off...
                    Stupid democracy... Why can't we just solve things the ol' fashioned way?
                    !exit
                * Maybe he's right? Remind me why there's democracy in Griftlands again?
                laborer:
                    !right
                    Thanks for that. I didn't have anymore sandwiches to squirrel away my cash in.
                player:
                    You're welcome?
                laborer:
                    No No, thank YOU. I'll be sure to spread the word that you won't put up with this kind of behaviour.
                * You ponder what reputation will precede you from this encounter. Probably something good.
            ]],
            DIALOG_DEFEND_FAIL = [[
                player:
                    Aren't your wages enough? Extorting people is a rather quick way to lose your badge.
                admiralty:
                    Well I'll keep it blunt, to save your time.
                    These people think the Admiralty should be de-funded. That'd mean I don't get payed as much.
                    By your logic, I'm the smart one because I'm getting head start on the robbing people process.
                    Now if you're done butting into our business, I'd like to continue with this transaction.
            ]],

            OPT_LEAVE = "Leave before anyone sees you",
            DIALOG_LEAVE = [[
                * You pretend to not have seen anything and slip away unnoticed.
            ]],

            OPT_LEAVE_PST_FAIL = "Leave without dignity",
            DIALOG_LEAVE_PST_FAIL = [[
                player:
                    !exit
                admiralty:
                    !left
                    !angry
                laborer:
                    !right
                    !angry
                * You leave the two to sort things out by themselves.
            ]],

            OPT_FINISH_JOB = "Finish what you've started",
            DIALOG_FINISH_JOB = [[
                right:
                    !fight
                player:
                    !fight
                    I guess if words failed, we'll just settle with the good ol' fashioned battle.
            ]],

            DIALOG_FINISH_EXTORT = [[
                {partner_dead?
                    {dead?
                        * Everyone's dead.
                        * You took the money and left the scene.
                        * Surely no one would notice, unless you're a famous politician.
                    }
                    {not dead?
                        laborer:
                            !injured
                        player:
                            Look what you've done.
                            Now you really gotta pay those reparations for what you did to the Admiralty.
                        laborer:
                            !angry_permit
                            Here, take it.
                            !injured
                            You claim you're a politician, but really you're just a lowly bandit.
                            Good luck getting votes now.
                            !exit
                        * {laborer.HeShe}'s right, you know.
                    }
                }
                {not partner_dead?
                    {dead?
                        * {admiralty} looks at you, disappointedly.
                        admiralty:
                            !right
                            Good job, us.
                            Now that {laborer} is dead, I lost a steady source of cash.
                        player:
                            Don't worry about it.
                            After the election, I plan to increase funding for the Admiralty.
                            Then you don't need to resort to extorting civilians.
                        admiralty:
                            I sure do hope so.
                            !give
                            At any rate, here's your cut.
                        * You take your blood money.
                        * One thing is certain, though. The stunt you just pulled will probably not get elected.
                        * So enjoy {admiralty}'s support, until {admiralty.heshe} finds out how empty your promise is.
                    }
                    {not dead?
                        laborer:
                            !right
                            !injured
                        admiralty:
                            !left
                            So? What's it gonna be?
                        laborer:
                            !angry_permit
                            Here, take it.
                            !injured
                            You're nothing but a crook.
                            !angry_accuse
                            And you there!
                        player:
                            !left
                            !surprised
                            Me?
                        laborer:
                            You claim you're a politician, but really you're just a lowly bandit.
                            Good luck getting votes now.
                            !exit
                        * {laborer.HeShe}'s right, you know.
                        admiralty:
                            At least you made things right.
                            !give
                            Here's your cut.
                        * You take your blood money and leave.
                    }
                }
            ]],
            DIALOG_FINISH_DEFEND = [[
                {partner_dead?
                    {dead?
                        * Everyone's dead.
                        * Where's your justice now, huh?
                        * There's too many dead bodies for anyone to believe in your good intentions.
                    }
                    {not dead?
                        admiralty:
                            !injured
                            Look what you've forced me to do.
                            You happy now?
                            !exit
                        * That's a really good question.
                        * Are you prepared to suffer from support loss, not just from the Admiralty, but also any other factions?
                    }
                }
                {not partner_dead?
                    {dead?
                        laborer:
                            !right
                            Thanks buddy.
                            You just rid the world of a vermin.
                            It's a win win situation.
                            !exit
                        * You're not sure how this situation is considered win-win.
                        * A politician killing an Admiralty? That's quite the scandal.
                    }
                    {not dead?
                        admiralty:
                            !right
                            !injured
                        laborer:
                            !left
                            !angry_accuse
                            Will you leave me alone, now?
                        admiralty:
                            Fine, you win. I won't bother you anymore.
                            !angry_accuse
                            But you there!
                        player:
                            !left
                            !surprised
                            What, me?
                        admiralty:
                            The Admiralty will remember this.
                            !throatcut
                            Don't expect anyone to support you now.
                        player:
                            How is that possible?
                            I protected the weak from the oppressive Admiralty. If anything, I should gain more support.
                        admiralty:
                            !cruel
                            $angryCruel
                            That's what you say, anyway. But other people will just see a grifter obstructing the law.
                            And who do you think the people's gonna listen? The word of a grifting politician, or an admirable officer?
                        * I have to admit, that pun was horrible.
                        admiralty:
                            Enjoy your freedom. While it lasts.
                            !exit
                    }
                }
            ]],
        }

        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                cxt.quest.param.extort_amt = 30 + 30 * cxt.quest:GetRank()
                cxt:Dialog("DIALOG_INTRO")
            end

            cxt:Opt("OPT_EXTORT")
                :UpdatePoliticalStance("SECURITY", 1, false, true)
                :Dialog("DIALOG_EXTORT")

                :Negotiation{
                    target_agent = cxt.quest:GetCastMember("laborer"),
                    flags = NEGOTIATION_FLAGS.INTIMIDATION,
                    -- allies = { "admiralty" },
                    -- enemies = { "laborer" },
                    on_success = function(cxt)
                        cxt:Dialog("DIALOG_EXTORT_SUCCESS")
                        -- cxt.quest:GetCastMember("laborer"):OpinionEvent(OPINION.EXTORTION)
                        cxt.quest:GetCastMember("admiralty"):OpinionEvent(OPINION.APPROVE)
                        cxt.enc:GainMoney( cxt.quest.param.extort_amt )
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_EXTORT_FAIL")
                        -- cxt.quest:GetCastMember("laborer"):OpinionEvent(OPINION.EXTORTION)
                        cxt.quest:GetCastMember("admiralty"):OpinionEvent(OPINION.WASTED_TIME)
                        cxt:Opt("OPT_FINISH_JOB")
                            :Fn(function(cxt)cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("laborer"))end)
                            :Dialog("DIALOG_FINISH_JOB")
                            :Battle{
                                allies = { "admiralty" },
                                enemies = { "laborer" },
                                on_win = function(cxt)
                                    -- cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("laborer"))
                                    if cxt.quest:GetCastMember("admiralty"):IsDead() then
                                        cxt.quest.param.partner_dead = true
                                    end
                                    cxt:Dialog("DIALOG_FINISH_EXTORT")

                                    local money_multiplier = 1
                                    if cxt.quest.param.partner_dead then money_multiplier = money_multiplier * 2 end
                                    if cxt.GetAgent():IsDead() then money_multiplier = money_multiplier * 0.75 end
                                    cxt.enc:GainMoney(math.round( cxt.quest.param.extort_amt * money_multiplier ))

                                    -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -3)
                                    -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", -5, 1)
                                    cxt.quest:GetCastMember("admiralty"):OpinionEvent(OPINION.APPROVE)

                                    StateGraphUtil.AddLeaveLocation(cxt)
                                end,
                            }
                        cxt:Opt("OPT_LEAVE_PST_FAIL")
                            :Dialog("DIALOG_LEAVE_PST_FAIL")
                            :Travel()
                    end,
                }
                -- :ReceiveOpinion(OPINION.EXTORTION, {only_show = true}, "laborer")

            cxt:Opt("OPT_DEFEND")
                :UpdatePoliticalStance("SECURITY", -1, false, true)
                :Dialog("DIALOG_DEFEND")

                :Negotiation{
                    target_agent = cxt.quest:GetCastMember("admiralty"),
                    on_success = function(cxt)
                        cxt:Dialog("DIALOG_DEFEND_SUCCESS")
                        cxt.quest:GetCastMember("laborer"):OpinionEvent(OPINION.HELPED)
                        cxt.quest:GetCastMember("admiralty"):OpinionEvent(OPINION.DISAPPROVE_MINOR)
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_DEFEND_FAIL")
                        cxt.quest:GetCastMember("laborer"):OpinionEvent(OPINION.WASTED_TIME)
                        cxt.quest:GetCastMember("admiralty"):OpinionEvent(OPINION.DISAPPROVE_MINOR)
                        cxt:Opt("OPT_FINISH_JOB")
                            :Fn(function(cxt)cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("admiralty"))end)
                            :Dialog("DIALOG_FINISH_JOB")
                            :Battle{
                                allies = { "laborer" },
                                enemies = { "admiralty" },
                                on_win = function(cxt)
                                    -- cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("admiralty"))
                                    if cxt.quest:GetCastMember("laborer"):IsDead() then
                                        cxt.quest.param.partner_dead = true
                                    end
                                    cxt:Dialog("DIALOG_FINISH_DEFEND")

                                    -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -12)
                                    -- DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", -8, "ADMIRALTY")
                                    cxt.quest:GetCastMember("laborer"):OpinionEvent(OPINION.HELPED)

                                    StateGraphUtil.AddLeaveLocation(cxt)
                                end,
                            }
                        cxt:Opt("OPT_LEAVE_PST_FAIL")
                            :Dialog("DIALOG_LEAVE_PST_FAIL")
                            :Travel()
                    end,
                }
                :ReceiveOpinion(OPINION.DISAPPROVE_MINOR, {only_show = true}, "admiralty")

            cxt:Opt("OPT_LEAVE")
                :Dialog("DIALOG_LEAVE")
                :Travel()

        end)
