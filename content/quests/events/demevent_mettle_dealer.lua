local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    -- precondition = function(quest) 
    --     return TheGame:GetGameState():GetCaravan():GetMoney() >= MANIFESTO_COST
    -- end,
    on_start = function(quest)
        quest.param.unlocked_mettle = TheGame:GetGameProfile():HasMettleUnlocked(self:GetPlayerAgent():GetContentID())
        quest.param.can_do_mettle = TheGame:GetGameState():CanDoMettle()
        quest.param.unlocked_shop = false
        if quest.param.unlocked_mettle then
            if math.random() < 0.5 then
                quest.param.cost = 300
            end
        end
        quest.param.mettle_gain = 3
        -- Added this to change dialog upon save/load(aka "save scum")
        -- the idea is that when starting the quest, the field is initialized
        -- but it is not saved, so it will not be true upon load
        quest.did_not_save_scum = true
    end, 
}
:AddCastByAlias{
    cast_id = "dealer",
    alias = "DODGY_SCAVENGER",
    no_validation = true,
}

QDEF:AddConvo()
    :Confront(function(cxt)
        return "STATE_CONF"
    end)
    :State("STATE_CONF")
        :Loc{
            DIALOG_INTRO = [[
                * You are minding your own business when you are confronted by a very dodgy person.
                player:
                    !left
                dealer:
                    !right
                    There you are!
                    I was wondering whether you would show up here.
                {not met?
                player:
                    Do I know you?
                dealer:
                    Maybe you do, but not in this life.
                    But I know you, I know that you need some mettle.
                }
                {met?
                    {liked?
                        player:
                            Come and try to sell mettle to me again?
                        dealer:
                            You know me so well!
                    }
                    {not liked?
                        player:
                            What do you want?
                        dealer:
                            You know me, I sell mettle.
                            And you look like you could use some.
                    }
                }
            ]],
            OPT_ASK_METTLE = "Ask about mettle",
            DIALOG_ASK_METTLE = [[
                player:
                    What is mettle?
                {unlocked_mettle?
                dealer:
                    I'm surprised you don't know, considering that you already have it.
                player:
                    I do? That's news to me.
                dealer:
                    Is that the game we're playing now?
                    Very well, I shall tell you.
                }
                {not unlocked_mettle?
                dealer:
                    You seriously don't know what that is?
                    Very well, I shall tell you.
                }
                dealer:
                    Mettle is a wonderful substance!
                    It is all around you, yet only a select few can utilize it!
                    It can achieve many wonderful things and improve your abilities!
                player:
                    So you're saying it is a performance enhancer?
                dealer:
                    Sure, let's go with that.
                *** You learnt that mettle is a performance enhancer.
            ]],
            OPT_ACCEPT_METTLE = "Accept mettle",
            DIALOG_ACCEPT_METTLE = [[
                player:
                    Very well, let's have some of this <i>mettle</>.
                dealer:
                    Excellent!
                    Here you go, see if you like it!
                * You took some mettle.
                * Nothing visible has changed, but you feel a rush of dopamine rush, and you want more of it.
            ]],
            DIALOG_ACCEPT_METTLE_COST = [[
                player:
                    Very well, let's have some of this <i>mettle</>.
                dealer:
                    Excellent!
                    Now give me your money, and I will give you the goods.
                player:
                    Wait, it costs money?
                dealer:
                    Of course!
                {did_not_save_scum?
                    What, do you think I'm a charity? Giving away such a great substance for free?
                player:
                    Uhh...
                * You are not sure how to answer, considering that you know {dealer.himher} from another life who gived you mettle for free.
                }
                {not did_not_save_scum?
                    What, just because you tried to time travel, you think my price will change?
                player:
                    Uhh...
                * Oof, you got called out.
                }
                    
                *** You asked for mettle, but {dealer} asked for you money.
            ]],
            OPT_HAGGLE = "Haggle for the price",
            DIALOG_HAGGLE = [[
                player:
                    You trying to fleece me here?
                dealer:
                    Hey! Mettle is really strong, and not everyone can take it.
                    You should be glad that I'm selling it to you.
                player:
                    No way I'm paying that much for meta currency!
            ]],
            DIALOG_HAGGLE_SUCCESS = [[
                dealer:
                {not free?
                    Fine! {cost#money}.
                    Take it, or leave it.
                }
                {free?
                    You know, mettle really suits you.
                    I can't think of any other person who could use mettle better.
                    You know what? Take the mettle for free.
                }
            ]],
            DIALOG_HAGGLE_FAILURE = [[
                dealer:
                    I don't think that's how it works, buddy.
                    I'm trying to make money here.
                    {cost#money}, final price.
            ]],
            OPT_PAY = "Pay {cost#money}",
            DIALOG_PAY = [[
                player:
                {free?
                    Let's try your mettle.
                    |
                    Alright, here you go. {cost#money} in full.
                }
                dealer:
                    Excellent!
                    As promised, here's the mettle. See if you like it.
                * You took some mettle.
                * Nothing visible has changed, but you feel a rush of dopamine rush, and you want more of it.
            ]],
            DIALOG_METTLE_POST = [[
                dealer:
                    Anyway, if you want more, you know where you can find me.
                
                {not unlocked_shop?
                player:
                    Wait, I don't know where it is.
                    {unlocked_mettle?
                        Not in the Pearl, anyway.
                    }
                dealer:
                    In that case, I'll show you.
                * {dealer.HeShe} points the location of {dealer.hisher} shop to you.
                }
                {unlocked_shop?
                player:
                    Sure. I may consider that if I have time. 
                }
            ]],
            DIALOG_METTLE_END = [[
                dealer:
                    See you there!
                    !exit
                * You wonder what the consequences of this is.
            ]],
            OPT_REJECT = "Reject mettle",
            DIALOG_REJECT = [[
                player:
                    I'm sorry, but I have to say no.
                {need_pay?
                    I just can't spend that much money on meta currency.
                    Especially considering that is not even my money, it's supposed to be the campaign funding.
                dealer:
                    Fine, I see your point.
                    Trying to be responsible out there, eh?
                    Well, maybe next time.
                }
                {not need_pay?
                    {unlocked_mettle?
                        It's nothing personal, I assure you.
                        I'm a politician, and I need to lead by example.
                        And I cannot accept substance of unknown nature.
                    dealer:
                        It's not unknown! You know what it is! You have had many experience with it!
                    player:
                        I'm saying my voters don't.
                        Maybe the next run, I will accept it.
                    dealer:
                        Yeah, right. The next run.
                    }
                    {not unlocked_mettle?
                        I just can't trust whatever it is you're offering.
                    dealer:
                        Fine.
                        Know this: you will get mettle eventually.
                    }
                }
                dealer:
                    !exit
                * {dealer} left, leaving you wondering whether you made the right call.
            ]],
            OPT_ARREST = "Arrest {dealer} on the spot",
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.enc.scratch.did_not_save_scum = cxt.quest.did_not_save_scum
                cxt:Dialog("DIALOG_INTRO")
            end
            cxt:Question("OPT_ASK_METTLE", "DIALOG_ASK_METTLE")
        end)