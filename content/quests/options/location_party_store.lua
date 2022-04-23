local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}
:AddLocationCast{
    cast_id = "shop",
    cast_fn = function(quest, t)
        table.insert(t,  TheGame:GetGameState():GetLocation("PEARL_PARTY_STORE"))
    end,
}

:AddLocationCast{
    cast_id = "back_room",
    cast_fn = function(quest, t)
        table.insert(t,  TheGame:GetGameState():GetLocation("PEARL_PARTY_STORE.back_market"))
    end,
}
:AddCastByAlias{
    cast_id = "steven",
    alias = "STEVEN",
    no_validation = true,
}

QDEF:AddConvo()
    :Loc{
        OPT_ASK_ABOUT_SPECIAL_RESERVE = "Ask to see the special reserve",
        DIALOG_ASK_ABOUT_SPECIAL_RESERVE = [[
            player:
                I heard you maybe had a better selection than your window lets on.
                That true?
            agent:
                We have the finest selection in the Foam.
            {not liked?
                Finer than some can afford, I might add.
                How do you know about our better selection, anyway.
            }
            {liked?
                !thought
                Although I am a bit curious. I never told you about them.
                How did you found out, anyway?
            }
            player:
                !shrug
                Let's just say... I have my ways.
            * To be honest, you have no idea where you get this information.
            * <i>I mean</>, {player} has no idea where {player.heshe} got this information.
            * <i>You</> played Smith's campaign, probably.
            agent:
            {not liked?
                !dubious
                Now that sounds very suspicious.
            }
            {liked?
                !shrug
                If you say so.
                !overthere
                The goods are right this way.
            }
        ]],

        OPT_CONVINCE = "Convince {agent} that you're cool",
        DIALOG_CONVINCE = [[
            player:
                [p] I assure you, it's all perfectly legitimate.
        ]],

        DIALOG_CONVINCE_SUCCESS = [[
            agent:
                [p] I am convinced!
                The goods are back this way.
        ]],

        DIALOG_CONVINCE_FAILURE = [[
            agent:
                [p] I am not convinced!
                The exit is right this way.
            * You aren't really getting kicked out, though. But you can't access the back end goods.
            * Not right now, at least. Come back and ask later.
        ]],

        OPT_VISIT_THE_PARTY = "Get access to the back room",
    }
    :Hub(function(cxt,who)
        if who and cxt.location == cxt:GetCastMember("shop") and who == cxt.location:GetProprietor() then
            if not cxt.quest.param.asked_backroom then
                cxt:Opt("OPT_ASK_ABOUT_SPECIAL_RESERVE")
                    :Dialog("DIALOG_ASK_ABOUT_SPECIAL_RESERVE")
                    :Fn(function(cxt)
                        cxt.quest.param.asked_backroom = true
                        if who:GetRelationship() > RELATIONSHIP.NEUTRAL then
                            cxt.quest.param.access_granted = true
                        end
                    end)
            elseif not cxt.quest.param.access_granted then
                cxt:BasicNegotiation("CONVINCE0")
                    :OnSuccess()
                    :Fn(function(cxt)
                        cxt.quest.param.access_granted = true
                    end)
            end
        end
    end)
    :Hub_Location( function(cxt)
        if (cxt.location == cxt.quest:GetCastMember("shop")) then
            cxt:Opt("OPT_VISIT_THE_PARTY")
                :Fn(function()
                    cxt:End()
                    cxt.encounter:DoLocationTransition( cxt.quest:GetCastMember("back_room") )
                end)
        end
    end)
