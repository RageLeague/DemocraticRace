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
                How do you know about our better selection, anyway?
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
                cxt:BasicNegotiation("CONVINCE")
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
QDEF:AddConvo(nil, "steven")
    :AttractState("ATTR")
        :Loc{
            DIALOG_INTRO = [[
                {first_time?
                    player:
                        I've been told the real party's going on back here.
                    agent:
                        !greeting
                        Indeed!
                        This is the place for the partying!
                    player:
                        It doesn't look like much...
                        It's just two of you and some dusty old crates.
                    agent:
                        !point
                        I can assure you, we know how to party.
                        Those crates?
                        Full of party.
                }
                {not first_time?
                    agent:
                        !greeting
                        Are you ready for more of the partying?
                        I certainly am!
                }
            ]],
            OPT_LEAVE = "Stop Partying",
            DIALOG_LEAVE = [[
                player:
                    I think I've had enough partying for now.
                    !exit
                agent:
                    The party will be waiting for you when you get back!
            ]],
            DIALOG_REMOVE_BATTLE_CARD = [[
                player:
                    I have a bad habit I can't seem to shake.
                agent:
                    $neutralThoughtful
                    Perhaps you have a buggy subroutine?
            ]],
            DIALOG_REMOVE_NEGOTIATION_CARD = [[
                player:
                    Ever just get tongue-tied?
                agent:
                    $neutralThoughtful
                    No. That would require a tongue.
            ]],
            DIALOG_ASK_ABOUT = [[
                player:
                    I have so many questions...
            ]],
            OPT_SHOP = "See what {agent} has for sale...",
            DIALOG_POST_SHOP = [[
                agent:
                    !happy
                    Party every day!
            ]]
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")

            cxt:RunLoop(function()
                StateGraphUtil.AddRemoveBattleCardOption( cxt, "DIALOG_REMOVE_BATTLE_CARD" )
                StateGraphUtil.AddRemoveNegotiationCardOption( cxt, "DIALOG_REMOVE_NEGOTIATION_CARD" )

                cxt:Opt("OPT_SHOP")
                    :IsHubOption(true)
                    :PreIcon( global_images.shop, UICOLOURS.MONEY_LIGHT )
                    :Fn(function()
                        cxt.enc:WaitOnLine()
                        local screen = Screen.CardShopScreen( cxt:GetAgent(), function() cxt.enc:ResumeEncounter() end )
                        TheGame:FE():InsertScreen( screen )
                        cxt.enc:YieldEncounter()
                        cxt:Dialog("DIALOG_POST_SHOP")
                    end)


                cxt:Opt("OPT_ASK_ABOUT")
                    :Dialog("DIALOG_ASK_ABOUT")
                    :IsHubOption(true)
                    :GoTo("STATE_QUESTIONS")

                cxt:Opt("OPT_LEAVE")
                    :MakeUnder()
                    :Dialog("DIALOG_LEAVE")
                    :PreIcon(global_images.close)
                    :DoneConvo()
            end)
        end)
    :AskAboutHub("STATE_QUESTIONS",
    {

        "Ask when the party starts",
        [[
            player:
                So when does the party start?
            agent:
                Look around you, friend. The party has already started!
        ]],
        "Ask what the party is about",
        [[
            player:
                What's the reason for this party?
            agent:
                Parties do not need a reason, friend.
                Parties <b>are</> the reason!
            player:
                Is there a theme?
            agent:
                The theme is...
                !laugh
                Partying!
        ]],
        "Ask when the party ends",
        [[
            player:
                How long is this party going to last?
            agent:
                This party will never end!
            player:
                Never?
            agent:
                It will outlast you, at least!
        ]],
    })
