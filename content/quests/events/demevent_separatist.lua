local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}
:AddCast{
    cast_id = "loyalist",
    -- when = QWHEN.MANUAL,
    condition = function(agent, quest)
        return (agent:GetFactionID() == "FEUD_CITIZEN" or agent:GetFactionID() == "CULT_OF_HESH") and DemocracyUtil.GetAgentStanceIndex("INDEPENDENCE", agent) < 0
    end,
}
:AddCast{
    cast_id = "bandit1",
    -- when = QWHEN.MANUAL,
    condition = function(agent, quest)
        return agent:GetFactionID() == "BANDITS"
    end,
}
:AddCast{
    cast_id = "bandit2",
    -- when = QWHEN.MANUAL,
    condition = function(agent, quest)
        return agent:GetFactionID() == "BANDITS"
    end,
}
:AddOpinionEvents{
    interfered =
    {
        delta = OPINION_DELTAS.BAD,
        txt = "Interfered when you shouldn't have.",
    },
}

QDEF:AddConvo()
    :ConfrontState("STATE_INTERVENE")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You see two Spree trying to size up a person.
                bandit1:
                    !left
                    !angry
                loyalist:
                    !right
                    !angry
                * The person condemns the two for disregarding the Deltrean rule.
            ]],
            OPT_CONVINCE_LOYALIST = "Convince {loyalist} of Havaria's independence",
            DIALOG_CONVINCE_LOYALIST = [[
                player:
                    !left
                loyalist:
                    !right
                * [p] You talk.
            ]],
            DIALOG_CONVINCE_LOYALIST_SUCCESS = [[
                * [p] You convinced {loyalist.himher}.
            ]],
            DIALOG_CONVINCE_LOYALIST_SUCCESS_PST = [[
                player:
                    !left
                bandit1:
                    !right
                    !happy
                * [p] The two is happy that you help them remind {loyalist} of {loyalist.hisher} place.
            ]],
            DIALOG_CONVINCE_LOYALIST_FAILURE = [[
                * [p] Your words aren't getting through.
            ]],
            OPT_BACK_OFF = "Convince {bandit1} and {bandit2} to leave {loyalist} alone",
            DIALOG_BACK_OFF = [[
                player:
                    !left
                bandit1:
                    !right
                * [p] You talk.
            ]],
            DIALOG_BACK_OFF_SUCCESS = [[
                * [p] You convinced them.
            ]],
            DIALOG_BACK_OFF_FAILURE = [[
                * [p] Your words aren't getting through.
            ]],
            OPT_ARREST = "Arrest the two Spree...",
            DIALOG_ARREST = [[
                player:
                    !left
                bandit1:
                    !right
                player:
                    [p] You don't want to do this.
            ]],
            OPT_LEAVE = "Leave them alone",
            DIALOG_LEAVE = [[
                * [p] This is really none of your business.
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                cxt:Dialog("DIALOG_INTRO")
            end
            cxt:Opt("OPT_CONVINCE_LOYALIST")
                :Dialog("DIALOG_CONVINCE_LOYALIST")
                :UpdatePoliticalStance("INDEPENDENCE", 2)
                :Negotiation{
                    target_agent = cxt:GetCastMember("loyalist"),
                }
                    :OnSuccess()
                        :Dialog("DIALOG_CONVINCE_LOYALIST_SUCCESS")
                        :Fn(function(cxt)
                            local trouble = nil
                            local bandit1 = cxt:GetCastMember("bandit1")
                            local bandit2 = cxt:GetCastMember("bandit2")
                            if bandit1:GetRelationship() < RELATIONSHIP.NEUTRAL or bandit2:GetRelationship() < RELATIONSHIP.NEUTRAL then
                                trouble = bandit1:GetRelationship() <= bandit2:GetRelationship() and bandit1 or bandit2
                                cxt.quest.param.has_vendetta = true
                            elseif DemocracyUtil.GetFactionEndorsement("BANDITS") < RELATIONSHIP.NEUTRAL then
                                trouble = bandit1:GetRelationship() <= bandit2:GetRelationship() and bandit1 or bandit2
                                if trouble:GetRelationship() > RELATIONSHIP.NEUTRAL then
                                    trouble = nil
                                else
                                    cxt.quest.param.faction_dislike = true
                                end
                            end
                            if trouble then
                                cxt:ReassignCastMember("trouble", trouble)
                                cxt:GoTo("STATE_CONFLICT")
                            else
                                cxt:Dialog("DIALOG_CONVINCE_LOYALIST_SUCCESS_PST")
                                bandit1:OpinionEvent(OPINION.SUPPORT_IDEOLOGY)
                                bandit2:OpinionEvent(OPINION.SUPPORT_IDEOLOGY)
                                StateGraphUtil.AddLeaveLocation(cxt)
                            end
                        end)
                    :OnFailure()
                        :Dialog("DIALOG_CONVINCE_LOYALIST_FAILURE")
            cxt:Opt("OPT_BACK_OFF")
                :Dialog("DIALOG_BACK_OFF")
                :UpdatePoliticalStance("INDEPENDENCE", 0)
                :Negotiation{
                    target_agent = cxt:GetCastMember("bandit1"),
                    hinders = {"bandit2"},
                    flags = NEGOTIATION_FLAGS.INTIMIDATION,
                }
                    :OnSuccess()
                        :Dialog("DIALOG_BACK_OFF_SUCCESS")
                        :ReceiveOpinion(OPINION.DEFENDED, nil, "loyalist")
                        :DeltaSupport(2)
                        :Travel()
                    :OnFailure()
                        :Dialog("DIALOG_BACK_OFF_FAILURE")

            if not cxt.quest.param.did_confront then
                cxt:Opt("OPT_ARREST")
                    :Dialog("DIALOG_ARREST")
                    :GoTo("STATE_ARREST")
            end

            cxt:Opt("OPT_LEAVE")
                :Dialog("DIALOG_LEAVE")
                :Travel()
        end)
    :State("STATE_CONFLICT")
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
                trouble:
                    !right
                    !angry
                    [p] Oi! We are just handling this! Why are you interfering?
                {has_vendetta?
                    ** {trouble} is ungrateful to your help because of {trouble.hisher} personal opinion of you.
                }
                {faction_dislike?
                    ** {trouble} is ungrateful to your help because of your notoriety among the Spree.
                }
            ]],
            OPT_DEFEND = "Argue for yourself",
            DIALOG_DEFEND = [[
                player:
                    [p] Hey be grateful!
            ]],
            DIALOG_DEFEND_SUCCESS = [[
                trouble:
                    [p] You're right, I'm sorry.
            ]],
            DIALOG_DEFEND_FAILURE = [[
                trouble:
                    [p] Nah, screw you!
            ]],
            OPT_IGNORE = "Ignore {trouble}",
            DIALOG_IGNORE = [[
                * [p] You ignore the troublemaker, making {trouble.himher} real mad.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")

            cxt:BasicNegotiation("DEFEND", {
                target_agent = cxt:GetCastMember("trouble"),
            })
                :OnSuccess()
                    :ReceiveOpinion(OPINION.SUPPORT_IDEOLOGY, nil, "bandit1")
                    :ReceiveOpinion(OPINION.SUPPORT_IDEOLOGY, nil, "bandit2")
                    :Travel()
                :OnFailure()
                    :ReceiveOpinion("interfered", nil, "trouble")
                    :Travel()

            cxt:Opt("OPT_IGNORE")
                :Dialog("DIALOG_IGNORE")
                :ReceiveOpinion("interfered", nil, "trouble")
                :Travel()
        end)
    :State("STATE_ARREST")
        :Loc{
            DIALOG_BACK = [[
                player:
                {tried_intimidate?
                    [p] Okay you got me.
                }
                {not tried_intimidate?
                    [p] Just saying.
                }
            ]],
            OPT_INTIMIDATE = "Intimidate them to come willingly",
            DIALOG_INTIMIDATE = [[
                player:
                    [p] Isn't it an arrestable crime harassing a citizen like this?
            ]],
            DIALOG_INTIMIDATE_SUCCESS = [[
                player:
                    [p] Why don't you two come willingly.
                * You bring these two to a nearby patrol and hand them over.
            ]],
            DIALOG_INTIMIDATE_FAILURE = [[
                bandit1:
                    Hey, last I checked, the Admiralty don't send hunters to do grunt work.
                    Unless you've got your switch friends backing you up, you don't have the authority to do anything.
            ]],
            OPT_ARREST = "Arrest them with force",
            DIALOG_ARREST = [[
                {tried_intimidate?
                    * You brandish your weapon with a gleam.
                player:
                    !sigh
                    Criminals. Can't live with them, can't live without them.
                rise:
                    !right
                    !fight
                    You're the real criminal here! Viva la Rise!
                }
                {not tried_intimidate?
                player:
                    I tell ya. Knocking skulls is the best part of this job.
                jakes:
                    !fight
                    Yeah, yours specifically.
                }
            ]],
            DIALOG_ARREST_WIN = [[
                player:
                    !left
                loyalist:
                    !right
                    [p] Thanks for saving me from these ruffians.
                {bandits_dead?
                    loyalist:
                        [p] The bodies, though...
                    player:
                        They will clean it up, I'm sure.
                }
                {not bandits_dead?
                    player:
                        [p] Don't mention it.
                        Now, I just need to handle this.
                    * You head to the nearest Admiralty patrol to let them deal with this mess.
                }
            ]],
            OPT_USE_BODYGUARD = "Let a bodyguard arrest them...",
            DIALOG_USE_BODYGUARD = [[
                player:
                    !wink
                * You signal for {guard} to restrain one of them.
                bandit1:
                    !taken_aback
                    Wh-hey!
                bandit2:
                    !left
                    Wait, what's going-
                * You quickly grab {bandit2}'s arms behind {bandit2.himher}, and with {guard} holding back {bandit1}, you have two new prisoners.
                bandit1:
                    I bet you like this kind of grunt work, switch.
                guard:
                    !left
                    !shrug
                    Pays the bills, what can I say.
                * You and {guard} hold both of your new friends down while waiting for the authorities to come and see you both doing your civic duty.
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest.param.did_confront = true
            end

            local function DoArrest(cxt, hate_target)
                if cxt:GetCastMember("bandit1"):IsAlive() then
                    cxt:GetCastMember("bandit1"):GainAspect("stripped_influence", 5)
                    cxt:GetCastMember("bandit1"):OpinionEvent(OPINION.SOLD_OUT_TO_ADMIRALTY, nil, hate_target)
                    cxt:GetCastMember("bandit1"):Retire()
                end
                if cxt:GetCastMember("bandit2"):IsAlive() then
                    cxt:GetCastMember("bandit2"):GainAspect("stripped_influence", 5)
                    cxt:GetCastMember("bandit2"):OpinionEvent(OPINION.SOLD_OUT_TO_ADMIRALTY, nil, hate_target)
                    cxt:GetCastMember("bandit2"):Retire()
                end
                DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 3)
                DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 5, "ADMIRALTY")
                DemocracyUtil.DeltaGameplayStats("ARRESTED_PEOPLE_TIMES", 1)
            end

            cxt:Opt("OPT_INTIMIDATE")
                :Dialog("DIALOG_INTIMIDATE")
                :UpdatePoliticalStance("SECURITY", 2)
                :Negotiation{
                    target_agent = cxt:GetCastMember("bandit1"),
                    flags = NEGOTIATION_FLAGS.ALLY_SCARE | NEGOTIATION_FLAGS.INTIMIDATION,
                    fight_allies = {cxt:GetCastMember("bandit2")},
                    helpers = {"loyalist"},
                }
                    :OnSuccess()
                        :Dialog("DIALOG_INTIMIDATE_SUCCESS")
                        :Fn(function(cxt)
                            DoArrest(cxt)
                        end)
                        :Travel()
                    :OnFailure()
                        :Dialog("DIALOG_INTIMIDATE_FAILURE")
                        :Fn(function(cxt)
                            cxt.quest.param.tried_intimidate = true
                        end)

            cxt:Opt("OPT_ARREST")
                :UpdatePoliticalStance("SECURITY", 2)
                :Dialog("DIALOG_ARREST")
                :Battle{
                    enemies = {cxt:GetCastMember("bandit1"), cxt:GetCastMember("bandit2")},
                    noncombatants = {"loyalist"},
                }
                    :OnWin()
                        :Fn(function(cxt)
                            cxt.quest.param.bandits_dead = cxt:GetCastMember("bandit1"):IsDead() and cxt:GetCastMember("bandit2"):IsDead()
                            cxt.quest.param.one_bandit_dead = cxt:GetCastMember("bandit1"):IsDead() or cxt:GetCastMember("bandit2"):IsDead()
                            cxt:Dialog("DIALOG_ARREST_WIN")
                            DoArrest(cxt)
                        end)
                        :Travel()

            DemocracyUtil.AddBodyguardOpt(cxt, function(opt, agent, is_sentient, is_mech)
                opt:UpdatePoliticalStance("SECURITY", 2)
                    :Fn(function(cxt)
                        cxt:ReassignCastMember("guard", agent)
                        cxt:Dialog("DIALOG_USE_BODYGUARD")
                        agent:Dismiss()
                        DoArrest(cxt, agent)
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end)
            end, nil, function(agent) return agent:GetFactionID() == "ADMIRALTY" and agent:IsSentient() end)

            cxt:Opt("OPT_BACK_BUTTON")
                :Dialog("DIALOG_BACK")
                :Pop()
                :MakeUnder()
        end)
