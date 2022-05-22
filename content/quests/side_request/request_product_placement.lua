local ADVERTISEMENT_REQ = 20

local QDEF = QuestDef.Define
{
    title = "Product Placement",
    desc = "{giver} wants you to endorse {giver.hisher} product and asks you to advertise them to the people.",
    icon = engine.asset.Texture("icons/quests/special_delivery.tex"),

    qtype = QTYPE.SIDE,

    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"REQUEST_JOB"},
    reward_mod = 0,
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
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 10, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, 4, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 3, "COMPLETED_QUEST_REQUEST")
        elseif quest.param.sub_optimal then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 5, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 4, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 3, "COMPLETED_QUEST_REQUEST")
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
            Now that your political image is a bit larger than that of the wandering grifter, I got a job for you.
        player:
            Is the job any bigger than what you've had me doing all this time?
        agent:
            Not really. What I need you to do is promote some <b>M.E.T.A.</>.
        player:
            !dubious
            Bless you?
        agent:
            That's the name of the product. <b>M.E.T.A.</>.
            It stands for "Meritocratic Emulation Transposition Apparatus".
        player:
            That's a very...odd naming convention.
        agent:
            But snappy, yes? Really rolls off the tongue, like the word "based" or "cringe".
            <b>M.E.T.A.</>.
            I will admit that I didn't came up with it. A talking vroc told me about it in a dream.
        player:
            Uh huh.
            So do you want me to advertise it to the people during my campaign?
        agent:
            If you find the time, then yes.
        }
        {not advisor_diplomacy?
            I have an idea for a side business, but the word isn't exactly out there about it.
        player:
            So what does that have to do with me? I'm your politician, not the door-to-door.
        agent:
            Oh you don't need to make it a big deal.
            Just...y'know. Talk about it a little. Spark a little interest.
        player:
            !question
            In a completely normal conversation.
        agent:
            !hips
            You're a smart lumicyte. I'm sure you can figure out a good segue into my line of products.
        }
    ]],

    --on accept
    [[
        player:
            Eh, sure, why not.
        agent:
            Great! Just remember to name drop it like you're a Banquod!
        {player_smith?
        player:
            But I am a Banquod.
        agent:
            Well then you're already halfway there. Don't stop now!
        }
    ]])
QDEF:AddConvo("sell", "giver")
    :Priority(CONVO_PRIORITY_LOWEST)
    :Loc{
        OPT_FORGOT_CARD = "Tell {agent} that you forgot the pitch",
        DIALOG_FORGOT_CARD = [[
            player:
                So, uhh... I kinda just forgot the sales pitch you told me.
            agent:
                !surprised
                You WHAT?
            {primary_advisor?
                I guess I did told you to focus on the election.
                Still, if you are just going to forget the things I tell you to do, you shouldn't have accepted my request in the first place!
            }
            {not primary_advisor?
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
                Do you mind if I post an advertisement here?
            agent:
                Why should I let you do it? Give me a good reason.
        ]],
        DIALOG_POSTER_SUCCESS = [[
            player:
                !point
                It's not like you are using this board for anything else.
                And it's not like I am competing against you.
                The things I am selling is completely unrelated to what you are selling.
            agent:
                !thought
                I guess there is no harm to let you post here.
                And it beats arguing with you to no end.
                Alright, you can post here.
            * You posted the advertisement at this location. Hopefully enough people see this.
        ]],
        DIALOG_POSTER_FAILURE = [[
            player:
                This is a public place. Why shouldn't I be able to post my advertisement here?
            agent:
                !angry
                It might be public, but <i>I</> am still the owner here.
                Don't feel like you are entitled to this place just because it's public.
            player:
                ...
                !dubious
                Is that a yes?
            agent:
                Of course not!
            player:
                !shrug
                Well, it's worth a shot.
            * That is an embarrassment. Maybe you should look for somewhere else?
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
                * As you travel, you are approached by a Heshian.
                player:
                    !left
                agent:
                    !right
                    !hesh_greeting
                    Greetings.
                    You must be {player}, right?
                player:
                    !crossed
                    If you want to collect my tithe, I'm afraid I have already paid.
                agent:
                    !placate
                    What? I am not here to collect anything.
                    I am simply offering you an opportunity.
                    You are representing the owner of <i>M.E.T.A.</>, correct?
                player:
                    Yeah?
                agent:
                    And I presume you like money?
                player:
                    !crossed
                    Nobody hates money.
                    What is this about?
                agent:
                    It just so happens the cult wish to invest in it, as well.
                    We will provide you with money, and in return, we will receive some shares for <i>M.E.T.A.</>.
            ]],
            OPT_ASK_SHARE = "Ask about shares",
            DIALOG_ASK_SHARE = [[
                player:
                    You keep talking about "shares", and I am not sure what this means.
                agent:
                    Basically, we own a part of the operation for <i>M.E.T.A.</>.
                    We receive part of the profits, and we play in some roles in management.
                    You will be compensated heavily, of course.
            ]],
            OPT_ASK_OWNERSHIP = "Ask about ownership",
            DIALOG_ASK_OWNERSHIP = [[
                player:
                    !surprised
                    Wait, if I sell shares to you, then {giver} doesn't own it anymore.
                    That seems bad.
                agent:
                    !permit
                    It's not as bad as you think.
                    You are still in control of the operation. We just get a cut of the profit.
                    If you wish for your operation to succeed, you will need significant funding.
                    I can provide you with the funding, and you still get to control the operation.
                    There are no downside for you. It's all benefits.
                player:
                    !dubious
                    That sounds too good to be true...
                agent:
                    It's a common practice among the merchants to sell a share of their operation.
                    Why do you think they do that, if this is bad for them?
            ]],
            OPT_SELL_THIRD = "Sell a third of the share",
            DIALOG_SELL_THIRD = [[
                player:
                    This does sound lucrative.
                    !agree
                    Fine, you have a deal.
                    !give
                    Here, you can have a minority share.
                agent:
                    !take
                    That will do.
                    Glad to do business with you.
                * This seems like the ideal situation, for you and M.E.T.A.
                * If you can convince {giver} such, that is.
            ]],
            OPT_SELL_TWO_THIRD = "Sell two thirds of the share",
            DIALOG_SELL_TWO_THIRD = [[
                player:
                    This does sound lucrative.
                    !agree
                    Fine, you have a deal.
                    !give
                    Here, you can have a majority share.
                agent:
                    !surprised
                    Really?
                    !happy
                    I mean, excellent!
                    Glad to do business with you.
                * That was a golden opportunity, and you saw it and took it.
                * Now you own a load of cash, and some Heshian owns the financial decision power for {giver}'s product.
                * You wonder how {giver} would react given that you basically sold the majority of {giver.hisher} business without {giver.hisher} permission.
            ]],
            OPT_SELL_ALL = "Sell ALL of the share",
            DIALOG_SELL_ALL = [[
                player:
                    !shrug
                    What could go wrong?
                    !give
                    Here, take my money.
                    !thought
                    Or, rather, take my goods.
                agent:
                    !surprised
                    Really?
                    !happy
                    I mean, excellent!
                    Glad to do business with you.
                * Wow, you actually sold out {giver}'s entire business to some Heshian.
                * All the hard work done by {giver} are all for naught, thanks to your poor financial decision.
                * What are you, crazy?
            ]],
            OPT_SELL_NOTHING = "Sell nothing",
            DIALOG_SELL_NOTHING = [[
                player:
                    !angry
                    I'm not giving you Heshian anything!
                agent:
                    !shrug
                    Fine. At least I tried.
                * You are wondering if you protected your integrity, or you just passed up a golden opportunity.
                * Either way, you did what {giver} asked you to do. Time to tell {giver.himher} what you did.
            ]],

            OPT_NEGOTIATE_TERMS = "Negotiate share price...",
            DIALOG_NEGOTIATE_TERMS = [[
                player:
                    !crossed
                    You think I'm willing to sell it to you for this low?
                    You gotta go higher.
            ]],
            DIALOG_NEGOTIATE_TERMS_SUCCESS = [[
                agent:
                    !sigh
                    Fine, I will increase my prices.
            ]],
            DIALOG_NEGOTIATE_TERMS_FAILURE = [[
                agent:
                    !crossed
                    No. You either take it or leave it.
            ]],
            NEGOTIATION_REASON = "Negotiate better terms (increase the price of 100% share by {1#money} on win)",
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
                            table.insert(amounts, 80)
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
                        cxt.quest.param.haggled_price = true
                    end)
                    :OnFailure()
                    :Fn(function(cxt)
                        cxt.quest.param.haggled_price = true
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
                    Nice going! Thanks for letting everyone know of our product.
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
                    !angry
                    I was informed that some Heshian now owns a third of my shares.
                    Care to explain?
            ]],
            DIALOG_INTRO_SELL_TWO_THIRD = [[
                * You are greeted by {agent}, who looks very angry.
                player:
                    !left
                agent:
                    !right
                    !angry
                    I was informed that some Heshian now owns a majority of my shares.
                    Why the Hesh did you do that?
                {advisor_diplomacy?
                    player:
                        !bashful
                        I just thought we need the money, that's all.
                    agent:
                        !angry_shrug
                        Really?
                        Is money all you think about?
                    player:
                        Well, I mean it's important-
                    agent:
                        !surprised
                        What?!
                        !angry_accuse
                        I've got plenty money. I don't need to sell <b>M.E.T.A.</> to get more!
                        No. What I need is a product that can change the world!
                        !angry_shrug
                        How am I supposed to do that now that a Heshian owns a majority share?
                        Them owning a majority share means that they have the executive power on this product!
                    player:
                        They did promise the autonomy of your operation-
                    agent:
                        !angry_shrug
                        Those are just empty promises.
                        They are not on paper, so they don't count.
                        Now that the Heshian owns a majority, Hesh knows what they will do with this product!
                        Knowing them, they will ruin any Vagrant Age tech they find!
                    player:
                        Vagrant Age?
                    agent:
                        Doesn't matter!
                        !angry_accuse
                        I thought you are going to be different, {player}. I thought you are going to be based.
                        !sigh
                        But it appears, you are but another cringe normie.
                        I will still help you with the campaign, as promised.
                        But don't expect me to do you any favors!
                }
            ]],

            DIALOG_INTRO_SELL_ALL = [[
                * In an almost harmonic fashion, the click of the door as you enter syncs up spectacularly with the angry stomping down the hallway from {agent}.
                player:
                    !left
                agent:
                    !right
                    !angry
                    $angrySeething
                    You no-good scoundrel!
                player:
                    !dubious
                    No-good scoundrel? Sure you can't be a little more creative?
                agent:
                    No, {player}, I can't be a little more creative for <i>your</> sake.
                    I've been too busy fuming about the fact that a damned Heshie owns my entire vagrant age product line!
                player:
                    !taken_aback
                    Vagrant age?!
                agent:
                    !angry_accuse
                {primary_advisor?
                    Grab your damn things, and get out of my damn office!
                }
                {not primary_advisor?
                    Get out of my sight!
                }
                * Then {agent} rants, {agent} hates you, blah blah blah.
                * The shills sure are worth it, though, right?
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
                    if cxt:GetAgent() == TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor") then
                        DemocracyUtil.UpdateAdvisor(nil, "ADVISOR_REJECTED")
                    end
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
                player:
                    I understand that trying to change the world is a big deal. I'm trying to change it as well.
                    !question
                    But tell me, {agent}. What makes that world we're trying to change spin?
            ]],
            DIALOG_EXPLAIN_SUCCESS = [[
                player:
                    So you see, if you just take that money we got from selling the shares and invest it into a new, hip product line.
                    Well, the world'll unravel at the seams at your touch. Change it how you like.
                {not majority_share?
                 agent:
                    I suppose so. I do have a few other projects that I could tinker with.
                    Just don't pull this same kind of stunt on any of your political allies, and I'll let this one slide.
                }
                {majority_share?
                 agent:
                    !question
                    I suppose that is a lot of money this pulled in from selling just the shares.
                    But the product would've made more. I'm sure of it.
                    !angry_accuse
                    You come to me next time you try to pull this same kind of stunt, understand?
                }
            ]],
            DIALOG_EXPLAIN_FAILURE = [[
                player:
                    Just look at all the money you have now!
                agent:
                    You mean money <i>you</> have now.
                    Money that I didn't get a say in how you obtained.
                {primary_advisor?
                    player:
                        Because you take half the campaign funding from me and put it in your own pockets!
                    agent:
                        That doesn't mean you get to shoot my hopes and dreams in the foot!
                        !angry_accuse
                        Look, you better work like a vroc once you get in office to make up for this.
                }
                {not primary_advisor?
                    player:
                        Well-
                    agent:
                        I know I shouldn't rely on a grifter to handle my business.
                    {not majority_share?
                        At least I still have the financial autonomy, so maybe I can still work with this.
                        But don't expect me to do you any favors in the future!
                    }
                    {majority_share?
                        And great! Now some Heshian controls my business, and knowing them, they will probably ruin it to the ground.
                        Now get out, and don't expect me to do you any favors.
                    }
                }
            ]],

            SIT_MOD = "Angry at you selling a majority share to someone they don't like",

            OPT_BRUSH_OFF = "Brush off concern",

            DIALOG_BRUSH_OFF = [[
                * [p] You brush off {agent}'s concern.
                * Obviously {agent} doesn't buy it.
                * Why do you think the other option has a negotiation, hmm?
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
                            cxt.quest:Fail()
                        else
                            cxt.quest.param.poor_performance = true
                            cxt.quest:Complete()
                            ConvoUtil.GiveQuestRewards(cxt)
                        end
                    end)
                    :DoneConvo()
            cxt:Opt("OPT_BRUSH_OFF")
                :Dialog("DIALOG_BRUSH_OFF")
                :Fn(function(cxt)
                    if cxt.enc.scratch.majority_share then
                        cxt.quest:Fail()
                    else
                        cxt.quest.param.poor_performance = true
                        cxt.quest:Complete()
                        ConvoUtil.GiveQuestRewards(cxt)
                    end
                end)
                :DoneConvo()
        end)
