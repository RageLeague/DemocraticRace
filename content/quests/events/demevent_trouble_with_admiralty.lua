local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    precondition = function(quest)
        local canspawn = false

        quest.param.assaulted_officer = TheGame:GetGameState():GetPlayerAgent():HasMemory("ASSAULTED_ADMIRALTY")
        if quest.param.assaulted_officer then
            quest.param.assaulted = true
            
            canspawn = true
        end
        if DemocracyUtil.GetFactionEndorsement("ADMIRALTY") < RELATIONSHIP.NEUTRAL then
            quest.param.unpopular = true
            canspawn = true
        end
        return canspawn
    end,
}
QDEF:AddConvo()
    :ConfrontState("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * You were minding your own business when you are stopped by and Admiralty.
                agent:
                    [p] Stop right there, criminal scum!
                    You've violated the law!
                    Pay the court a fine, or serve your sentence.
                ** This event happened because you {assaulted?are wanted by the Admiralty for committing a crime|are unpopular among the Admiralty}.
            ]],
            OPT_PAY = "Pay the court a fine",
            DIALOG_PAY = [[
                * [p] you paid the court a fine, so that you don't have to serve a sentence.
            ]],
            OPT_CONVINCE = "Convince {agent} that they got the wrong person",
            DIALOG_CONVINCE = [[
                player:
                    [p] It wasn't me, it was the man in the chicken costume.
                agent:
                    A likely story, go on.
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                agent:
                    [p] Hesh damn poultry man!
                    I'll get them.
                    !exit
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                agent:
                    [p] A great story you have there.
                    Ashame that it doesn't absolve your duty.
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
            OPT_ARREST = "Serve your sentence",
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                cxt.enc.scratch.opfor = CreateCombatParty("ADMIRALTY_PATROL", cxt.quest:GetRank() + 1, cxt.location, true)
                cxt:TalkTo(cxt.enc.scratch.opfor[1])
                cxt:Dialog("DIALOG_INTRO")
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
                    }
                        :OnSuccess()
                            :Dialog("DIALOG_CONVINCE_SUCCESS")
                            :Travel()
                        :OnFailure()
                            :Dialog("DIALOG_CONVINCE_FAILURE")
                            :Fn(function(cxt) cxt.quest.param.tried_convince = true end)
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
                                :Fn(function(cxt) cxt.quest.param.tried_intimidate = true end)
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
                                -- print("Party members you have: ", TheGame:GetGameState():GetCaravan():GetPartyCount())
                                -- if #keep_allies <= TheGame:GetGameState():GetCaravan():GetPartyCount() then
                                --     cxt:Dialog("DIALOG_INTIMIDATE_SUCCESS")
                                -- else

                                -- end
                            end,
                            on_fail = function(cxt,minigame)
                            end,
                        }
                end
            end
        end)