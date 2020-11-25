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
                cxt:Dialog("DIALOG_INTRO")
            end
            local pay_cost = 50 + 25 * cxt.quest:GetRank()
            cxt:Opt("OPT_PAY")
                :DeliverMoney(pay_cost)
                :Travel()
        end)