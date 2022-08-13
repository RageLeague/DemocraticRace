local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    -- precondition = function(quest)
    --     return TheGame:GetGameState():GetCaravan():GetMoney() >= MANIFESTO_COST
    -- end,
    on_init = function(quest)
        quest.param.unlocked_mettle = TheGame:GetGameProfile():HasMettleUnlocked(TheGame:GetGameState():GetPlayerAgent():GetContentID())
        quest.param.can_do_mettle = TheGame:GetGameState():CanDoMettle()
        quest.param.unlocked_shop = false
        if true then--quest.param.unlocked_mettle then
            if math.random() < 0.5 then
                quest.param.cost, quest.param.cost_mod = CalculatePayment( quest:GetCastMember("dealer"), 300)
            end
        end
        quest.param.mettle_gain = quest.param.cost and 3 or 1
        -- Added this to change dialog upon save/load(aka "save scum")
        -- the idea is that when starting the quest, the field is initialized
        -- but it is not saved, so it will not be true upon load
        quest.did_not_save_scum = true
        -- return true
    end,
    on_destroy = function(quest)
        if quest:GetCastMember("dealer"):IsInPlayerParty() then
            quest:GetCastMember("dealer"):Dismiss()
        end
    end,
}
:AddCastByAlias{
    cast_id = "dealer",
    alias = "DODGY_SCAVENGER",
    no_validation = true,
    events = {
        agent_retired = function(quest, agent)
            quest:Complete()
        end,
    },
}
:AddObjective{
    id = "intro",
    state = QSTATUS.ACTIVE,
    on_activate = function(quest)
        quest:SetHideInOverlay(true)
    end,
}

QDEF:AddConvo()
    :Confront(function(cxt)
        if cxt.location:HasTag("in_transit") then
            return "STATE_CONF"
        end
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
                * You are not sure how to answer, considering that you know {dealer.himher} from another life who gave you mettle for free.
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
            OPT_PAY = "Pay for the cost",
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
            REQ_KNOW_HQ = "You don't know where the Admiralty HQ is.",
            DIALOG_ARREST = [[
                player:
                    I'm sorry, {dealer}, but you're under arrest.
                dealer:
                    What for?
                player:
                    For selling a dangerous controlled substance.
                dealer:
                {not unlocked_mettle?
                    I'll have you know that mettle is a perfectly fine substance, thank you very much!
                }
                {unlocked_mettle?
                    I've gave you a taste of power, and this is how you repay me?
                }
            ]],
            DIALOG_ARREST_WIN = [[
                {dead?
                    * You killed {dealer}, but this might not be the rest you see of {dealer.himher}.
                }
                {not dead?
                    player:
                        !angry
                    agent:
                        !injured
                        This is just a temporary setback, you and I both know this.
                    player:
                        Oh yeah?
                        How about let's make it permanent, hmm?
                    agent:
                        What, you're going to kill me?
                        I assure you, killing me is in no way permanent.
                    player:
                        If I want to kill you, I would've already done so during the fight.
                        That's why I'm going to arrest you. Send you to an Admiralty prison.
                        Try convince the people there how wonderful your "mettle" is.
                    * You send {agent} off to a nearby Admiralty patrol.
                    * Now there is one less mettle dealer that walks Havarian streets.
                }
            ]]
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.enc.scratch.did_not_save_scum = cxt.quest.did_not_save_scum
                cxt:TalkTo(cxt:GetCastMember("dealer"))
                cxt:Dialog("DIALOG_INTRO")
            end
            cxt:Question("OPT_ASK_METTLE", "DIALOG_ASK_METTLE")

            if not cxt.quest.param.need_pay then
                cxt:Opt("OPT_ACCEPT_METTLE")
                    :UpdatePoliticalStance("SUBSTANCE_REGULATION", -1, false, true)
                    :Fn(function(cxt)
                        if cxt.quest.param.cost and cxt.quest.param.cost > 0 then
                            cxt:Dialog("DIALOG_ACCEPT_METTLE_COST")
                            cxt.quest.param.need_pay = true
                        else
                            cxt:Dialog("DIALOG_ACCEPT_METTLE")

                            cxt:GoTo("STATE_POST_METTLE")
                        end
                    end)
            else
                cxt:Opt("OPT_PAY")
                    :DeliverMoney(cxt.quest.param.cost, {no_scale = true}, cxt:GetCastMember("dealer"))
                    :Dialog("OPT_PAY")
                    :GoTo("STATE_POST_METTLE")
            end
            cxt:Opt("OPT_ARREST")
                :UpdatePoliticalStance("SECURITY", 2)
                :Dialog("DIALOG_ARREST")
                :Battle{
                    on_win = function(cxt)
                        cxt:Dialog("DIALOG_ARREST_WIN")
                        if not cxt:GetAgent():IsDead() then
                            cxt:GetAgent():GainAspect("stripped_influence", 5)
                            cxt:GetAgent():OpinionEvent(OPINION.SOLD_OUT_TO_ADMIRALTY)
                            cxt:GetAgent():Retire()
                        end
                        cxt.quest:Complete()
                        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 3)
                        DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 5, "ADMIRALTY")
                        DemocracyUtil.DeltaGameplayStats("ARRESTED_PEOPLE_TIMES", 1)
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                }
            cxt:Opt("OPT_REJECT")
                :Dialog("DIALOG_REJECT")
                :CompleteQuest()
                :Travel()
        end)
    :State("STATE_POST_METTLE")
        :Loc{
            DIALOG_METTLE = [[
                * You took some mettle.
                * Nothing visible has changed, but you feel a rush of dopamine as you see numbers go up.
                player:
                    !flourish
                * Incredible! Exhilarating! A whole {mettle_gain} mettle!
                * Now, you want more, to satisfy your addiction.
                agent:
                    Great! Now you have a taste of what mettle is like, go out and get them!
                    Happy grifting!
                * Oh yeah, you are definitely going to enjoy collecting mettle.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_METTLE")

            local character_id = cxt.player:GetContentID()
            TheGame:GetGameProfile():UnlockMettle( character_id )
            TheGame:GetGameProfile():AddMettlePoints( character_id, cxt.quest.param.mettle_gain )
            cxt.quest:Complete()
            StateGraphUtil.AddLeaveLocation(cxt)
        end)
