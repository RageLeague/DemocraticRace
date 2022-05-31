local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,

    events =
    {
        caravan_member_event = function(quest, event, agent, old_loc, new_loc)
            if event == "agent_location_changed" and agent == TheGame:GetGameState():GetPlayerAgent() and new_loc == quest:GetCastMember("back_room") then
                if quest.param.last_graft_restock ~= TheGame:GetGameState():GetDateTime() then
                    quest.param.negotiation_grafts = GenerateGrafts(GRAFT_TYPE.NEGOTIATION)
                    quest.param.combat_grafts = GenerateGrafts(GRAFT_TYPE.COMBAT)
                    quest.param.last_graft_restock = TheGame:GetGameState():GetDateTime()
                end
            end
        end,
    },
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
                A bit finer than your finances, from what I've deduced.
                Come to think of it, how'd you hear about this?
            }
            player:
                !shrug
                Well, the bright strobe lights from your backroom aren't exactly subtle.
                So is the sound of party-poppers and the ocassional "PARTY" yelled from there.
            agent:
                !palm
                Hesh damn it, {steven}.
            {not liked?
                !crossed
                Look, no one gets in unless I say so, got that?
            }
            {liked?
                !overthere
                Well, friend to friend, I'll let you back there.
                Keep the bad tomfoolery to a minimum.
            }
        ]],

        OPT_CONVINCE = "Convince {agent} that you're cool",
        DIALOG_CONVINCE = [[
            player:
                C'mon, I'm perfect for whatever shenanigans you've got back there.
        ]],

        DIALOG_CONVINCE_SUCCESS = [[
            player:
                !thumb
                I'm actually one of the "partygoers", if you didn't know.
            agent:
                !question
                Partygoers?
            player:
                !shrug
                Sure I am. Got invited by that guy screaming party back there.
                !angryshrug
                Are you gonna keep holding me up or do you want to deal with him?
            agent:
                !scared
                Oh, you're one of {steven}'s chosen...
                !overthere
                Right this way, {player}. Sorry for the hold up.
        ]],

        DIALOG_CONVINCE_FAILURE = [[
            player:
                I've got the money to pay, don't I?
            agent:
                !handwave
                Money alone doesn't get you the good wares. 
                !hips
                You've gotta be the right kind of person. Someone trustworthy.
                Now if you're done asking about the back room, I've got tons of things <i>you're</> allowed to buy.
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
    :Loc{
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
        OPT_SELL_GRAFT = "Purchase {1#graft}",
        DIALOG_SELL_GRAFT = [[
            agent:
                !happy
                Party every day!
        ]],
        REQ_FULL = "You have too many grafts of this type",

        OPT_SEE_NEGOTIATION_GRAFTS = "Buy negotiation grafts",

        DIALOG_ADD_SLOT_1 = [[
            agent:
                Wanna party?
            player:
                !scared
                Wait, why are you holding a-
            agent:
                !exit
            player:
                !exit
        ]],
        DIALOG_ADD_SLOT_2 = [[
            agent:
                !right
            player:
                !left
                !wince
                Ow!
            agent:
                !greeting
                That's what I call a party!
        ]],
        OPT_ADD_NEGOTIATION_SLOT = "Add a negotiation graft slot",
        REQ_TOO_MANY = "You have the maximum allowed!",
        DIALOG_SEE_NEGOTIATION_GRAFTS = [[
            agent:
                I can make you a party machine!
            player:
                I would rather be a party {player.species}, but a party machine is my second choice.
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_ASK_ABOUT")
            :Dialog("DIALOG_ASK_ABOUT")
            :IsHubOption(true)
            :GoTo("STATE_QUESTIONS")

        cxt:Opt("OPT_SEE_NEGOTIATION_GRAFTS")
            :Dialog("DIALOG_SEE_NEGOTIATION_GRAFTS")
            :PreIcon( engine.asset.Texture( "UI/ic_graftscompendium.tex"), UICOLOURS.NEGOTIATION )
            :LoopingFn(PresetGrafts(cxt.quest.param.negotiation_grafts))

        ConvoUtil.OptBuyGraftSlot( cxt, GRAFT_TYPE.NEGOTIATION, "DIALOG_ADD_SLOT_1" )
            :Dialog( "DIALOG_ADD_SLOT_2" )

        StateGraphUtil.AddRemoveNegotiationCardOption( cxt, "DIALOG_REMOVE_NEGOTIATION_CARD" )
    end)
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
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
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
