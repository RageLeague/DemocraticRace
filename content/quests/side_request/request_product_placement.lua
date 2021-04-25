local ADVERTISEMENT_REQ = 20

local QDEF = QuestDef.Define
{
    title = "Product Placement",
    desc = "{giver} wants you to endorse {giver.hisher} product and asks you to advertise them to the people.",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/revenge_starving_worker.png"),

    qtype = QTYPE.SIDE,

    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"REQUEST_JOB"},
    -- reward_mod = 0,
    can_flush = false,

    events = {
        base_difficulty_change = function(quest, new_diff, old_diff)
            quest:SetRank(new_diff)
        end,
        
    },

    on_start = function(quest)
        quest:Activate("sell")
        quest.param.people_advertised = 0
    end,

    on_complete = function(quest)
        if not (quest.param.sub_optimal or quest.param.poor_performance) then
            quest:GetProvider():OpinionEvent(OPINION.DID_LOYALTY_QUEST)
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 10, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, 4, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 3, "COMPLETED_QUEST")
        elseif quest.param.sub_optimal then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 5, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 4, "COMPLETED_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 3, "COMPLETED_QUEST")
        elseif quest.param.poor_performance then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2, "POOR_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 4, "POOR_QUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 2, 3, "POOR_QUEST")
        end
    end,

    ADVERTISEMENT_REQ = 20,

    VerifyCount = function(quest)
        if (quest.param.people_advertised or 0) >= ADVERTISEMENT_REQ then
            quest:Complete("sell")
        end
    end,
}

:AddCast{
    cast_id = "giver",
    no_validation = true,
    provider = true,
    unimportant = true,
    condition = function(agent, quest)
        return (agent:GetFactionID() == "SPARK_BARONS" or agent:GetFactionID() == "FEUD_CITIZEN" or agent:GetFactionID() == "JAKES") and
            (DemocracyUtil.GetWealth(agent) > 2) and agent:GetContentID() ~= "ADVISOR_HOSTILE"
    end,
    -- cast_fn = function(quest, t)
    --     table.insert( t, quest:CreateSkinnedAgent( "LABORER" ) )
    -- end,
}
:AddObjective{
    id = "sell",
    title = "Give your sales pitch to people.",
    desc = "When you are negotiating with others, you can insert the product into the conversation. The more people present, the better.",
    on_activate = function(quest)
        -- TheGame:GetGameState():GetPlayerAgent().negotiator:LearnCard("promote_product_quest", {linked_quest = quest})
        local enc = TheGame:GetGameState():GetCaravan():GetCurrentEncounter()
        if enc then
            enc:GetScreen():ForceWaitOnLine()
            local card = TheGame:GetGameState():GetPlayerAgent().negotiator:LearnCard("promote_product_quest", {linked_quest = quest})
            enc:GetScreen():ShowGainCards({card}, function() enc:ResumeEncounter() end)
            enc:YieldEncounter()
        else
            TheGame:GetGameState():GetPlayerAgent().negotiator:LearnCard("promote_product_quest", {linked_quest = quest})
        end
    end,
    on_deactivate = function(quest)
        for i, card in ipairs(TheGame:GetGameState():GetPlayerAgent().negotiator:GetCards()) do
            if card.userdata and card.userdata.linked_quest == quest then
                TheGame:GetGameState():GetPlayerAgent().negotiator:RemoveCard(card)
            end
        end
    end,
    on_complete = function(quest)
        quest:Activate("tell_giver")
        if quest:IsActive("advertise_poster") then
            quest:Complete("advertise_poster")
        end
    end,
    events =
    {
        
    },
}
:AddObjective{
    id = "advertise_poster",
    title = "Post advertisements at public places.",
    desc = "Another idea is to post advertisements at public places for potential customers to see.",
    on_activate = function(quest)
        quest.posted_location = {}
    end,
    events =
    {
        phase_change = function(quest, new_phase)
            for i, location in ipairs(quest.param.posted_location or {}) do
                quest.param.people_advertised = (quest.param.people_advertised or 0) + location:GetCurrentPatronCapacity()
            end
            quest:DefFn("VerifyCount")
        end,
    },
}
:AddObjective{
    id = "tell_giver",
    title = "Tell {giver} about the advertising progress.",
    desc = "You have advertised the product to enough people. Time to tell {giver} about the good news!",
    mark = function(quest, t, in_location)
        if in_location or DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("giver"))
        end
    end,
}
-- We can use this on request quests, because there's no reject dialogs.
QDEF:AddIntro(
    --attract spiel
    [[
        agent:
        {advisor_diplomacy?
            I'm not just helping you for nothing you know?
        player:
            Of course I know. You kept a cut of our funding for yourself every day.
            !angry
            The money is supposed to be the funding for the campaign, you know? And you keep it to yourself.
            !neutral
        agent:
            That's cringe of you to think that way.
            No. The reason is that I want to use this campaign as an opportunity to sell some <b>S.T.O.N.K.S.</>.
        player:
            !dubious
            I'm sorry, what now?
        agent:
            <b>S.T.O.N.K.S.</>.
            It stands for "Synthetic Transform of Neural-Kinesis System".
            (IDFK, haven't figured out the acronym yet)
        player:
            Sure, why not?
            You want me to advertise it to the people during my campaign?
        agent:
            If you can, then sure, go ahead.
        }
        {not advisor_diplomacy?
            I'm trying to run a side business.
            Selling some product, that's all.
        player:
            Okay...? What does that have to do with me?
        agent:
            You see... I don't got many business.
            I'm thinking... Maybe you can help me sell it.
        player:
            I'm a politician, not a salesman.
        agent:
            Oh, no. You don't need to do it separately.
            You just need to insert the product into your normal conversations, that's all.
        }
    ]],
    
    --on accept
    [[
        player:
            Eh, sure, why not.
        agent:
            Great! When you negotiate with someone, be sure to let them know my product!
    ]])
QDEF:AddConvo("sell", "giver")
    :Priority(CONVO_PRIORITY_LOWEST)
    :Loc{
        OPT_FORGOT_CARD = "Tell {agent} that you forgot the pitch",
        DIALOG_FORGOT_CARD = [[
            player:
                So, uhh... I kinda just forgot the sales pitch you told me.
            agent:
                !surprise
                You WHAT?
            {advisor?
                I guess I did told you to focus on the election.
                Still, if you are just going to forget the things I tell you to do, you shouldn't have accepted my request in the first place!
            }
            {not advisor?
                How did that even happen?
            player:
                That is a question I'm wondering myself.
            }
            agent:
                !permit
                Here's the pitch. Try not to forget it this time around.
        ]],
    }
    :Hub(function(cxt)
        for i, card in ipairs(TheGame:GetGameState():GetPlayerAgent().negotiator:GetCards()) do
            if card.userdata and card.userdata.linked_quest == cxt.quest then
                return
            end
        end
        cxt:Opt("OPT_FORGOT_CARD")
            :Dialog("DIALOG_FORGOT_CARD")
            :Fn(function(cxt)
                cxt.enc:GetScreen():ForceWaitOnLine()
                local card = TheGame:GetGameState():GetPlayerAgent().negotiator:LearnCard("promote_product_quest", {linked_quest = quest})
                cxt.enc:GetScreen():ShowGainCards({card}, function() cxt.enc:ResumeEncounter() end)
                cxt.enc:YieldEncounter()
            end)
        
    end)
    :AttractState("STATE_ATTRACT")
        :Loc{
            DIALOG_INTRO_FEW = [[
                player:
                    How's business?
                agent:
                    It could be better.
            ]],
            DIALOG_INTRO_SOME = [[
                player:
                    How's business?
                agent:
                    It's getting better, but not good enough.
            ]],
            DIALOG_INTRO_LOT = [[
                player:
                    How's business?
                agent:
                    It's rising. Just need a few more sales.
            ]],
            
        }
        :Fn(function(cxt)
            
            local score = cxt.quest.param.people_advertised or 0
            if score > 16 then
                cxt:Dialog("DIALOG_INTRO_LOT")
            elseif score > 8 then
                cxt:Dialog("DIALOG_INTRO_SOME")
            else
                cxt:Dialog("DIALOG_INTRO_FEW")
            end
            
        end)
QDEF:AddConvo("advertise_poster")
    :Loc{
        OPT_POSTER = "Post an advertisement here",
        DIALOG_POSTER = [[
            player:
                [p] Can you post an ad?
            agent:
                I don't know, can you?
        ]],
        DIALOG_POSTER_SUCCESS = [[
            player:
                [p] I think I can.
            agent:
                Well then.
        ]],
        DIALOG_POSTER_FAILURE = [[
            agent:
                [p] I don't think you can.
            player:
                Crap.
        ]],
    }
    :Hub(function(cxt, who)
        if cxt.location:GetProprietor() and cxt.location:GetProprietor() == who and
            not table.arraycontains(cxt.quest.param.posted_location or {}, cxt.location)
            and cxt.location:GetCurrentPatronCapacity() > 0 then

            cxt:BasicNegotiation("POSTER")
                :OnSuccess(function(cxt)
                    table.insert(cxt.quest.param.posted_location, cxt.location)
                    cxt.quest.param.people_advertised = (cxt.quest.param.people_advertised or 0) + cxt.location:GetCurrentPatronCapacity()
                    cxt.quest:DefFn("VerifyCount")
                end)
        end
    
    end)
QDEF:AddConvo("tell_giver")
    :TravelConfront("STATE_ENC", function(cxt)
        return not cxt.quest.param.did_encounter
    end)
        :Loc{
            DIALOG_INTRO = [[
                * As you travel, you encounter a Heshian.
                player:
                    !left
                agent:
                    !right
                    [p] Yo.
                    I heard you are selling <b>S.T.O.N.K.S</>.
                    I would like to purchase a share.
                    I'm sure {giver} won't mind.
            ]],
            OPT_ASK_SHARE = "Ask about shares",
            DIALOG_ASK_SHARE = [[
                player:
                    [p] Wdym "buy share"?
                agent:
                    Basically, if you sell it to me, we own that amount of your product.
                    Of course, you will be compensated heavily.
            ]],
            OPT_ASK_OWNERSHIP = "Ask about ownership",
            DIALOG_ASK_OWNERSHIP = [[
                player:
                    [p] If I sell it to you, then I don't own half of the product.
                    That seems bad.
                agent:
                    Don't worry about it.
                    You can still control the operation. We just get a cut.
                    And you get a lot of funding, so it's a win-win situation.
                    There's literally no downsides to doing this, trust me bro.
                * Don't trust {agent.himher}, bro.
            ]],
            OPT_SELL_THIRD = "Sell a third of the share",
            DIALOG_SELL_THIRD = [[
                player:
                    [p] I need the money.
                    Here, you can have a minority share.
                agent:
                    That will do.
                    Glad to do business with you.
                * {giver} may not like it, but this is probably for the best.
                * You have the money, and you still maintain most profits and control.
                * It's a win-win, if you can convince {giver} such.
            ]],
            OPT_SELL_TWO_THIRD = "Sell two thirds of the share",
            DIALOG_SELL_TWO_THIRD = [[
                player:
                    [p] I need the money.
                    Here, you can have the majority share.
                agent:
                    Really?
                    I mean, excellent!
                    Glad to do business with you.
                * It was probably for the best, right?
                * Big surprise, it's an allegory to the recent news regarding Klei and Tencent.
                * So of course it will go wrong.
            ]],
            OPT_SELL_ALL = "Sell ALL of the share",
            DIALOG_SELL_ALL = [[
                player:
                    [p] What could go wrong?
                    Here, take my money.
                    Or, rather, take my goods.
                agent:
                    Really?
                    I mean, excellent!
                    Glad to do business with you.
                * Literally nothing can go wrong in this scenario.
                * What are you, crazy?
            ]],
            OPT_SELL_NOTHING = "Sell nothing",
            DIALOG_SELL_NOTHING = [[
                player:
                    [p] I'm not giving you Heshian anything!
                agent:
                    Fine. At least I tried.
                * This is obviously the correct choice.
                * Your advisor will love you for that.
            ]],

            OPT_NEGOTIATE_TERMS = "Negotiate share price...",
            DIALOG_NEGOTIATE_TERMS = [[
                player:
                    [p] You think I'm willing to sell you for this low?
                    You gotta go higher.
            ]],
            DIALOG_NEGOTIATE_TERMS_SUCCESS = [[
                agent:
                    [p] Fine, I will increase my prices.
            ]],
            DIALOG_NEGOTIATE_TERMS_FAILURE = [[
                agent:
                    [p] No. You either take it or leave it.
            ]],
            NEGOTIATION_REASON = "Negotiate better terms (increase the price of all shares by {1#money} on win)",
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest.param.did_encounter = true
                cxt.quest.param.share_price = 600
                local buyer = AgentUtil.GetFreeAgent("PRIEST")
                cxt:TalkTo(buyer)
                cxt:Dialog("DIALOG_INTRO")
            end
            cxt:QST("ASK_SHARE")
            cxt:QST("ASK_OWNERSHIP")
            if not cxt.quest.param.haggled_price then
                local won_bonuses = {10}
                cxt:BasicNegotiation("NEGOTIATE_TERMS", {
                    on_start_negotiation = function(minigame)
                            
                        local amounts = {80, 50, 30}

                        local haggle_count = cxt.player.graft_owner:CountGraftsByID( "haggle_badge" )
                        for i = 1, haggle_count do
                            table.insert(amount, 80)
                        end
                        
                        for k,amt in ipairs(amounts) do
                            local mod = minigame.opponent_negotiator:CreateModifier( "bonus_payment", amt )
                            mod.result_table = won_bonuses
                        end
                    end,
                    reason_fn = function(minigame)
                        local total_amt = 0
                        for k,v in pairs(won_bonuses) do
                            total_amt = total_amt + v
                        end
                        return loc.format(cxt:GetLocString("NEGOTIATION_REASON"), total_amt )
                    end,

                    enemy_resolve_required = 10 * cxt.quest:GetRank(),
                }):OnSuccess()
                    :Fn(function(cxt)
                        local total_bonus = 0
                        for k,v in ipairs(won_bonuses) do 
                            total_bonus = total_bonus + v
                        end
                        cxt.quest.param.share_price = cxt.quest.param.share_price + total_bonus
                    end)
            end
            cxt:Opt("OPT_SELL_THIRD")
                :Dialog("DIALOG_SELL_THIRD")
                :ReceiveMoney(math.round(cxt.quest.param.share_price / 3))
                :Fn(function(cxt)
                    cxt.quest.param.sell_share = 1
                    cxt.quest.param.sell_share_time = Now()
                end)
                :Travel()
            cxt:Opt("OPT_SELL_TWO_THIRD")
                :Dialog("DIALOG_SELL_TWO_THIRD")
                :ReceiveMoney(math.round(2 * cxt.quest.param.share_price / 3))
                :Fn(function(cxt)
                    cxt.quest.param.sell_share = 2
                    cxt.quest.param.sell_share_time = Now()
                end)
                :Travel()
            cxt:Opt("OPT_SELL_ALL")
                :Dialog("DIALOG_SELL_ALL")
                :ReceiveMoney(cxt.quest.param.share_price)
                :Fn(function(cxt)
                    cxt.quest.param.sell_share = 3
                    cxt.quest.param.sell_share_time = Now()
                end)
                :Travel()
            cxt:Opt("OPT_SELL_NOTHING")
                :Dialog("DIALOG_SELL_NOTHING")
                :Travel()
        end)

QDEF:AddConvo("tell_giver")
    :Loc{
        OPT_ASK_BASED = "Ask about the meaning of the word \"Based\"",
        DIALOG_ASK_BASED = [[
            player:
                I keep hearing you say the word "based".
                Do you know what it means?
            agent:
                It means that a liquid contains less than ten millionth moles of Hydronium ion per liter of water under room temperature?
            player:
                Uhh...
                Sure?
            * That would be "basic", but close enough.
        ]],
    }
    :ConfrontState("STATE_GIVER", function(cxt)
        if cxt:GetCastMember("giver"):GetLocation() == cxt.location then
            return true
        end
        if cxt.quest.param.sell_share_time and cxt.quest.param.sell_share_time ~= Now() and cxt.location:HasTag("in_transit") then
            cxt:GetCastMember("giver"):MoveToLocation(cxt.location)
            return true
        end
        return false
    end)
        :Loc{
            DIALOG_INTRO_NO_SELL = [[
                * You are greeted by {agent}.
                player:
                    !left
                agent:
                    !right
                    [p] Nice going! Thanks for letting everyone know of our product.
                    It is really popular.
                player:
                    Thanks.
                {did_encounter?
                    Some Heshian wants to buy some shares, but I didn't sell it to them.
                agent:
                    Good thinking.
                    Those Heshians are up to no good.
                    They don't like people selling Vagrant Age tech.
                player:
                    Wait, they are Vagrant Age tech?
                agent:
                    What? You think we are able to make this product at our current time?
                    {advisor_diplomacy?
                        Anyway, their thoughts are mega cringe, and I'm glad you take the precautions.
                    }
                }
                {advisor_diplomacy?
                    I am glad you can take out your time and help me.
                    That, is what I like to call Based 100.
                }
                {not advisor_diplomacy?
                    I'm glad that you are willing to help me promote this product.
                    I won't forget this.
                }
            ]],
            DIALOG_INTRO_SELL_THIRD = [[
                * You are greeted by {agent}, who looks kinda angry.
                player:
                    !left
                agent:
                    !right
                    [p] I was informed that some Heshian now owns a third of my shares.
                    Care to explain?
            ]],
            DIALOG_INTRO_SELL_TWO_THIRD = [[
                * You are greeted by {agent}, who looks very angry.
                player:
                    !left
                agent:
                    !right
                    !angry
                    [p] I was informed that some Heshian now owns a majority of my shares.
                    Why the Hesh did you do that?
                {advisor_diplomacy?
                    player:
                        I just thought we need the money, that's all.
                    agent:
                        Really?
                        Is money all you think about?
                    player:
                        Well, I mean it's important-
                    agent:
                        What?!
                        I've got plenty money. I don't need to sell <b>S.T.O.N.K.S</> to get more!
                        No. What I need is a product that can change the world!
                        How am I supposed to do that now that a Heshian owns a majority share?
                        Them owning a majority share means that they have the executive power on this product!
                    player:
                        They did promise the autonomy of your operation-
                    agent:
                        Those are just empty promises.
                        They are not on paper, so they don't count.
                        Now that the Heshian owns a majority, Hesh knows what they will do with this product!
                        Knowing them, they will ruin any Vagrant Age tech they find!
                    player:
                        Vagrant Age?
                    agent:
                        Doesn't matter!
                        I thought we are on the same page, {player}.
                        But it appears, you are but another cringe normie.
                        I will still help you with the campaign, as promised.
                        But don't expect me to do you any favors!
                }
            ]],
            
            DIALOG_INTRO_SELL_ALL = [[
                * You are greeted by {agent}, who looks very angry.
                player:
                    !left
                agent:
                    !right
                    !angry
                    [p] I was informed that some Heshian now owns ALL of my shares!
                    What the Hell?
                * Then {agent} rants, {agent} hates you, blah blah blah.
            ]],
        }
        :Fn(function(cxt)
            cxt:TalkTo(cxt:GetCastMember("giver"))
            if not cxt.quest.param.sell_share then
                cxt:Dialog("DIALOG_INTRO_NO_SELL")
                cxt.quest:Complete()
                ConvoUtil.GiveQuestRewards(cxt)
                if cxt:GetAgent():GetContentID() == "ADVISOR_DIPLOMACY" then
                    cxt:QST("ASK_BASED")
                end
                StateGraphUtil.AddEndOption(cxt)
            else
                local intro_id = {"DIALOG_INTRO_SELL_THIRD", "DIALOG_INTRO_SELL_TWO_THIRD", "DIALOG_INTRO_SELL_ALL"}
                cxt:Dialog(intro_id[math.min(#intro_id, cxt.quest.param.sell_share)])

                if cxt.quest.param.sell_share >= 3 then
                    cxt:GetAgent():OpinionEvent(OPINION.BETRAYED)
                    cxt.quest:Fail()
                    StateGraphUtil.AddEndOption(cxt)
                elseif cxt.quest.param.sell_share == 2 and cxt:GetAgent():GetContentID() == "ADVISOR_DIPLOMACY" then
                    cxt.quest:Fail()
                    StateGraphUtil.AddEndOption(cxt)
                else
                    if cxt.quest.param.sell_share == 2 then
                        cxt.enc.scratch.majority_share = true
                    end
                    cxt:GoTo("STATE_EXPLAIN")
                end
            end
        end)
    :State("STATE_EXPLAIN")
        :Loc{
            OPT_EXPLAIN = "Explain yourself",

            DIALOG_EXPLAIN = [[
                * [p] You explain how selling the shares is for the greater good.
            ]],
            DIALOG_EXPLAIN_SUCCESS = [[
                * [p] {agent} sees it now, and is not mad anymore.
                {not majority_share?
                    * Then {agent} says {agent.heshe}'s grateful, blah.
                }
                {majority_share?
                    * Then {agent} says you did good, but not great.
                }
            ]],
            DIALOG_EXPLAIN_FAILURE = [[
                * [p] You fail to convince {agent}.
                * Now {agent}'s pissed at you.
                * Oof.
            ]],

            SIT_MOD = "Angry at you selling a majority share to someone they don't like",

            OPT_BRUSH_OFF = "Brush off concern",

            DIALOG_BRUSH_OFF = [[
                * [p] You brush off {agent}'s concern.
                * Obviously {agent} doesn't buy it.
                * Why do you think the other option has a negitiation, hmm?
            ]],
        }
        :Fn(function(cxt)
            local sit_mod = {}
            if cxt.enc.scratch.majority_share then
                table.insert(sit_mod, {value = 20, text = cxt:GetLocString("SIT_MOD")})
            end
            cxt:BasicNegotiation("EXPLAIN", {
                situation_modifiers = sit_mod,
            })
                :OnSuccess()
                    :Fn(function(cxt)
                        if cxt.enc.scratch.majority_share then
                            cxt.quest.param.sub_optimal = true
                        end
                    end)
                    :CompleteQuest()
                    :Fn(function(cxt)
                        if cxt:GetAgent():GetContentID() == "ADVISOR_DIPLOMACY" then
                            cxt:QST("ASK_BASED")
                        end
                        StateGraphUtil.AddEndOption(cxt)
                    end)
                :OnFailure()
                    :Fn(function(cxt)
                        if cxt.enc.scratch.majority_share then
                            cxt.quest.Fail()
                        else
                            cxt.quest.param.poor_performance = true
                            cxt.quest.Complete()
                            ConvoUtil.GiveQuestRewards(cxt)
                        end
                    end)
                    :DoneConvo()
            cxt:Opt("OPT_BRUSH_OFF")
                :Dialog("DIALOG_BRUSH_OFF")
                :Fn(function(cxt)
                    if cxt.enc.scratch.majority_share then
                        cxt.quest.Fail()
                    else
                        cxt.quest.param.poor_performance = true
                        cxt.quest.Complete()
                        ConvoUtil.GiveQuestRewards(cxt)
                    end
                end)
                :DoneConvo()
        end)