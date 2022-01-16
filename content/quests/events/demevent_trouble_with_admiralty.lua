local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    precondition = function(quest)
        local can_spawn = false

        quest.param.assaulted_officer = TheGame:GetGameState():GetPlayerAgent():HasMemory("ASSAULTED_ADMIRALTY")
        if quest.param.assaulted_officer then
            quest.param.assaulted = true

            can_spawn = true
        end
        if DemocracyUtil.GetFactionEndorsement("ADMIRALTY") < RELATIONSHIP.NEUTRAL then
            quest.param.unpopular = true
            can_spawn = true
        end
        return can_spawn --or true
    end,
}
:AddOpinionEvents{

    resist_arrest =
    {
        delta = OPINION_DELTAS.DISLIKE,
        txt = "Resisted Arrest",
    },
}
QDEF:AddConvo()
    :ConfrontState("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * You were minding your own business when you are stopped by and Admiralty.
                player:
                    !left
                agent:
                    !right
                    [p] Stop right there, criminal scum!
                    You've violated the law!
                    Pay the court a fine, or serve your sentence.
                ** This event happened because you {assaulted?are wanted by the Admiralty for committing a crime|are unpopular among the Admiralty}.
            ]],
            OPT_PAY = "Pay the court a fine",
            DIALOG_PAY = [[
                * [p] You paid the court a fine, so that you don't have to serve a sentence.
            ]],
            OPT_CONVINCE = "Convince {agent} that they got the wrong person",
            DIALOG_CONVINCE = [[
                player:
                    [p] It wasn't me, it was the man in the chicken costume.
                agent:
                    A likely story, go on.
            ]],
            SIT_MOD = "The Admiralty is cautious of you",
            DIALOG_CONVINCE_SUCCESS = [[
                agent:
                    [p] Hesh damn poultry man!
                    I'll get them.
                    !exit
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                agent:
                    [p] A great story you have there.
                    A shame that it doesn't absolve your duty.
            ]],
            OPT_INTIMIDATE = "Scare {agent} away",
            DIALOG_INTIMIDATE = [[
                player:
                    [p] Look at me.
                    I'm scary.
            ]],
            DIALOG_INTIMIDATE_SUCCESS_SOLO = [[
                agent:
                    [p] Oh no I'm scared!
                    !exit
            ]],
            DIALOG_INTIMIDATE_SUCCESS = [[
                * [p] {agent}'s followers ran away.
                agent:
                    I'll win next time!
                    !exit
            ]],
            DIALOG_INTIMIDATE_OUTNUMBER = [[
                * [p] Some of {agent}'s followers ran away.
                agent:
                    !fight
                    No matter. I can still win!
            ]],
            DIALOG_INTIMIDATE_FAILURE = [[
                agent:
                    Wait, this guy isn't that strong.
                {some_ran?
                    Come back, you cowards!
                * The routed followers came back,
                }
            ]],
            DIALOG_FIGHT_WIN = [[
                {dead?
                    * Oh good, now you killed an Admiralty. I'm sure that they will be happy.
                }
                {not dead?
                    agent:
                        !injured
                    player:
                        [p] Had enough?
                    agent:
                        Fine, you win this time.
                        Just know that you made a terrible enemy.
                        !exit
                }
            ]],
            OPT_RESIST = "Resist Arrest",
            DIALOG_RESIST = [[
                player:
                    !fight
                    You'll never get me alive!
            ]],
            OPT_ARREST = "Serve your sentence",
            DIALOG_ARREST = [[
                player:
                    Fine, I'll come.
                    But you'll be hearing from my lawyers!
                agent:
                    Yeah, sure. Whatever.
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                cxt.enc.scratch.opfor = CreateCombatParty("ADMIRALTY_PATROL", cxt.quest:GetRank() + 1, cxt.location, true)
                cxt:TalkTo(cxt.enc.scratch.opfor[1])
                cxt:Dialog("DIALOG_INTRO")
            end
            local function PostFight(cxt)
                cxt:Dialog("DIALOG_FIGHT_WIN")
                cxt.player:Remember("ASSAULTED_ADMIRALTY", cxt:GetAgent())
                if not cxt:GetAgent():IsDead() then
                    cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("resist_arrest"))
                end
                StateGraphUtil.AddLeaveLocation(cxt)
            end
            local pay_cost = 50 + 25 * cxt.quest:GetRank()
            cxt:Opt("OPT_PAY")
                :DeliverMoney(pay_cost)
                :Travel()
            if not cxt.quest.param.tried_convince then
                cxt:Opt("OPT_CONVINCE")
                    :ReqRelationship( RELATIONSHIP.NEUTRAL )
                    :Dialog("DIALOG_CONVINCE")
                    :Negotiation{
                        cooldown = 0,
                        situation_modifiers =
                        {
                            { value = 5 + 5 * math.floor(cxt.quest:GetRank()/2), text = cxt:GetLocString("SIT_MOD") }
                        },
                    }
                        :OnSuccess()
                            :Dialog("DIALOG_CONVINCE_SUCCESS")
                            :Travel()
                        :OnFailure()
                            :Dialog("DIALOG_CONVINCE_FAILURE")
                            :Fn(function(cxt) cxt.quest.param.tried_convince = true end)
            else
                cxt:Opt("OPT_RESIST")
                    :Dialog("DIALOG_RESIST")
                    :Battle{
                        flags = BATTLE_FLAGS.SELF_DEFENCE,
                        on_win = PostFight,
                    }
            end
            if not cxt.quest.param.tried_intimidate then
                if #cxt.enc.scratch.opfor == 1 then
                    cxt:Opt("OPT_INTIMIDATE")
                        :Dialog("DIALOG_INTIMIDATE")
                        :Negotiation{
                            cooldown = 0,
                            flags = NEGOTIATION_FLAGS.INTIMIDATION,
                        }
                            :OnSuccess()
                                :Dialog("DIALOG_INTIMIDATE_SUCCESS_SOLO")
                                :Travel()
                            :OnFailure()
                                :Dialog("DIALOG_INTIMIDATE_FAILURE")
                                :Fn(function(cxt)
                                    cxt.quest.param.tried_intimidate = true
                                    cxt:Opt("OPT_DEFEND")
                                        :Battle{
                                            flags = BATTLE_FLAGS.SELF_DEFENCE,
                                            on_win = PostFight,
                                        }
                                end)
                else
                    local allies = {}
                    for i, ally in ipairs(cxt.enc.scratch.opfor) do
                        if i ~= 1 then
                            table.insert(allies, ally)
                        end
                    end
                    cxt:Opt("OPT_INTIMIDATE")
                        :Dialog("DIALOG_INTIMIDATE")
                        :Negotiation{
                            cooldown = 0,
                            flags = NEGOTIATION_FLAGS.INTIMIDATION | NEGOTIATION_FLAGS.ALLY_SCARE,
                            enemy_resolve_required = 8 + cxt.quest:GetRank() * 10,
                            fight_allies = allies,
                            on_success = function(cxt, minigame)
                                local keep_allies = {}
                                for i, modifier in minigame:GetOpponentNegotiator():Modifiers() do
                                    if modifier.id == "FIGHT_ALLY_SCARE" and modifier.ally_agent then
                                        table.insert( keep_allies, modifier.ally_agent )
                                    end
                                end

                                for k,v in pairs(allies) do
                                    if not table.arrayfind(keep_allies, v) then
                                        v:MoveToLimbo()
                                    end
                                end
                                if #keep_allies == 0 or (DemocracyUtil.CalculatePartyStrength(cxt.player:GetParty()) >= DemocracyUtil.CalculatePartyStrength(cxt:GetAgent():GetParty()) ) then
                                    cxt:Dialog("DIALOG_INTIMIDATE_SUCCESS")
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                else
                                    cxt:Dialog("DIALOG_INTIMIDATE_OUTNUMBER")
                                    cxt:Opt("OPT_DEFEND")
                                        :Battle{
                                            flags = BATTLE_FLAGS.SELF_DEFENCE,
                                            on_win = PostFight,
                                        }
                                end
                                -- print("Party members you have: ", TheGame:GetGameState():GetCaravan():GetPartyCount())
                                -- if #keep_allies <= TheGame:GetGameState():GetCaravan():GetPartyCount() then
                                --     cxt:Dialog("DIALOG_INTIMIDATE_SUCCESS")
                                -- else

                                -- end
                            end,
                            on_fail = function(cxt,minigame)
                                cxt.enc.scratch.some_ran = not (minigame:GetOpponentNegotiator():FindCoreArgument() and minigame:GetOpponentNegotiator():FindCoreArgument():GetShieldStatus())
                                cxt:Dialog("DIALOG_INTIMIDATE_FAILURE")
                                cxt.quest.param.tried_intimidate = true
                                cxt:Opt("OPT_DEFEND")
                                    :Battle{
                                        flags = BATTLE_FLAGS.SELF_DEFENCE,
                                        on_win = PostFight,
                                    }
                            end,
                        }
                end
            end
            cxt:Opt("OPT_ARREST")
                :Dialog("DIALOG_ARREST")
                :Fn(function(cxt)
                    local flags = {
                        suspicion_of_crime = true,
                    }
                    DemocracyUtil.DoEnding(cxt, "arrested", flags)
                end)
        end)
