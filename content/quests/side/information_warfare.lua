local ARTISTS = {
    RISE_PAMPHLETEER = 0.6,
    FOREMAN = 0.25,
    PRIEST = 0.5,
    SPARK_BARON_TASKMASTER = 0.25,
    ADMIRALTY_CLERK = 0.4,
    SPREE_CAPTAIN = 0.15,
    WEALTHY_MERCHANT = 0.25,
    POOR_MERCHANT = 0.35,
    JAKES_SMUGGLER = 0.2,
}
local function IsArtist(agent)
    return agent:CalculateProperty("IS_ARTIST", function(agent)
        local chance_for_artist = ARTISTS[agent:GetContentID()] or 0.1
        return math.random() < chance_for_artist
    end)
end

local DRAFT_BEHAVIOUR = {
	OnInit = function( self, difficulty )
		-- self.bog_boil = self:AddCard("bog_boil")
		self:SetPattern( self.BasicCycle )
        self.negotiator:AddModifier("POSTER_SIMULATION_ENVIRONMENT")
    end,

    BasicCycle = function( self, turns )
        -- literally does nothing.
	end,
}

local QDEF = QuestDef.Define
{
    title = "Information Warfare",
    desc = "Commission someone for a propaganda poster and post it at popular locations to boost your campaign's popularity.",

    qtype = QTYPE.SIDE,
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"RALLY_JOB"},
    reward_mod = 0,
    extra_reward = false,
    on_start = function(quest)
        quest:Activate("commission")
        quest.param.actions = 8
    end,
    events = 
    {
        caravan_move_location = function(quest, location)
            if location:HasTag("road") then
                if quest.param.actions then
                    quest.param.actions = quest.param.actions - 1
                end
            end
        end,
    },
    -- precondition = function(quest)
    --     return TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor")
    -- end,
}
:AddObjective{
    id = "commission",
    title = "Create a poster",
    desc = "Commission someone with artistic talent to create a poster for you. Or just make your own.",
    mark = function(quest, t, in_location)
        if in_location then
            local location = TheGame:GetGameState():GetPlayerAgent():GetLocation()
            for i, agent in location:Agents() do
                if DemocracyUtil.RandomBystanderCondition(agent) then
                    table.insert(t, agent)
                end
            end
        else
            DemocracyUtil.AddUnlockedLocationMarks(t)
        end
    end,
}
:AddObjective{
    id = "post",
    title = "Post your propaganda",
    desc = "Serve your freshly baked propaganda poster at popular locations.",
    mark = function(quest, t, in_location)
        if in_location then
            local location = TheGame:GetGameState():GetPlayerAgent():GetLocation()
            if not (quest.param.posted_location and table.arraycontains(quest.param.posted_location, location:GetContentID())) then
                if true then
                    table.insert(location:GetProprietor())
                end
            end
        else
            DemocracyUtil.AddUnlockedLocationMarks(t, function(location)
                return location:GetProprietor() and
                    not (quest.param.posted_location and table.arraycontains(quest.param.posted_location, location:GetContentID()))
            end)
        end
    end,
}
:AddObjective{
    id = "out_of_time",
    mark = {"primary_advisor"},
    title = "Report to {primary_advisor}",
    desc = "You ran out of time. Return to {primary_advisor} on your progress.",
}
DemocracyUtil.AddPrimaryAdvisor(QDEF, true)
QDEF:AddConvo()
    :ConfrontState("STATE_OUT_OF_TIME", function(cxt)
        if cxt.quest.param.actions and cxt.quest.param.actions <= 0 and not cxt.quest:IsActive("out_of_time") then
            return true
        end
        return false
    end)
        :Loc{
            DIALOG_INTRO = [[
                * Unfortunately, you ran out of time.
                * Time to check in with {primary_advisor} and see how you did.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            if cxt.quest:IsActive("commission") then
                cxt.quest:Fail("commission")
            end
            if cxt.quest:IsActive("post") then
                cxt.quest:Cancel("post")
            end
            cxt.quest:Activate("out_of_time")
            StateGraphUtil.AddLeaveLocation(cxt)
        end)
QDEF:AddConvo("out_of_time", "primary_advisor")
    :Loc{
        OPT_TALK_PROGRESS = "Talk about your progress",
        DIALOG_PRE = [[
            agent:
                So? How did you do?
        ]],
        DIALOG_NO_POSTER = [[
            player:
                [p] So I ran out of time before I can commission a poster.
            agent:
                How disappointing.
        ]],
        DIALOG_NO_POST = [[
            player:
                [p] So I have a poster, but I don't have time to post it.
            agent:
                What are we gonna do with a poster?
                Better than nothing, I guess.
                You can still shove it into people's face.
                But it's not going to boost our popularity.
        ]],
        DIALOG_BAD = [[
            player:
                [p] So I posted our poster, but people don't like it.
            agent:
            {artist?
                {is_artist?
                    Try writing better messages in your poster next time.
                    |
                    Try hiring actual competent artist instead of cutting corners.
                player:
                    You know if you don't pocket so much money, I could've totally afforded a better artist.
                agent:
                    What nonsense.
                }
                |
                Try actually pay someone instead of drawing a poster on your own next time.
                You're a grifter. Not an artist.
            player:
                I disagree. Why can't a grifter be an artist?
            agent:
                Well, you aren't one, judging by the result.
            }
                You might need to spend time to take down the posters before you further damage our reputation.
                Still, you tried. At least I'll give you credit for that.
        ]],
        DIALOG_PASSABLE = [[
            player:
                [p] I posted our poster. Seems some people like it, but others don't.
            agent:
                That's okay. Obviously not everyone buys our propaganda.
                We don't need everyone to support us. We just need enough people to support us to win the election.
        ]],
        DIALOG_GOOD = [[
            player:
                [p] I posted our poster. Everyone wants to support us!
            agent:
                Excellent news!
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_TALK_PROGRESS")
            :SetQuestMark(cxt.quest)
            :Dialog("DIALOG_PRE")
            :Fn(function(cxt)
                if not cxt.quest:IsComplete("commission") then
                    cxt:Dialog("DIALOG_NO_POSTER")
                    cxt.quest:Fail()
                elseif not (cxt.quest.param.posted_location and #cxt.quest.param.posted_location > 0) then
                    cxt:Dialog("DIALOG_NO_POST")
                    cxt.quest:Fail()
                end
            end)
        
    end)
QDEF:AddConvo("post")
    :Loc{
        OPT_ASK = "Convince {agent} to post a poster",
        DIALOG_ASK = [[
            player:
                So, can I post a poster here?
            agent:
                I don't know, can you?
            player:
                You would think that the same joke would stop become funny after some time, right?
        ]],
        DIALOG_ASK_SUCCESS = [[
            player:
                I think I can.
            agent:
                Sure, why not.
                Which one are you posting?
        ]],
        DIALOG_ASK_FAILURE = [[
            agent:
                I don't think you can.
            player:
                Dang!
        ]],
        OPT_SELECT = "Select {1#card}",
        DIALOG_SELECT = [[
            player:
                !permit
                How about this one?
            agent:
                Sure, I guess.
        ]],
        OPT_NO_OPT = "Uhh...",
        DIALOG_NO_OPT = [[
            player:
                So, uhh...
            agent:
                What?
            player:
                I lost my poster.
                Somehow.
            agent:
                !dubious
                Seriously?
                Thanks for wasting my time.
        ]],
    }
    :Hub(function(cxt, who)
        if who and cxt.location and cxt.location:GetProprietor() == who then
            local location = cxt.location
            if not (quest.param.posted_location and table.arraycontains(quest.param.posted_location, location:GetContentID())) then
                cxt:Opt("OPT_ASK")
                    :Dialog("DIALOG_ASK")
                    :Negotiation{
                        on_success = function(cxt)
                            cxt:Dialog("DIALOG_ASK_SUCCESS")
                            local posters = {}
                            for i, card in ipairs(cxt.player.negotiator.cards.cards) do
                                if card.id == "propaganda_poster" then
                                    table.insert(posters, card)
                                end
                            end
                            if #posters == 0 then
                                cxt:Opt("OPT_NO_OPT")
                                    :Dialog("DIALOG_NO_OPT")
                                    :ReceiveOpinion(OPINION.WASTED_TIME)
                            else
                                for i, card in ipairs(posters) do
                                    cxt:Opt("OPT_SELECT", card)
                                        :Dialog("DIALOG_SELECT")
                                        :Fn(function(cxt)
                                            location:Remember("HAS_PROPAGANDA_POSTER", shallowcopy(card.userdata))
                                            card:ConsumeCharge()
                                            if card:IsSpent() then
                                                cxt.player.negotiator:RemoveCard( card )
                                            end
                                            if not cxt.quest.param.posted_location then
                                                cxt.quest.param.posted_location = {}
                                            end
                                            table.insert(cxt.quest.param.posted_location, location:GetContentID())
                                        end)
                                end
                            end
                        end,
                        on_fail = function(cxt)
                            cxt:Dialog("DIALOG_ASK_FAILURE")
                        end,
                    }
            end
        end
    end)
QDEF:AddConvo("commission")
    :Loc{
        OPT_ASK_COMMISSION = "Commission {agent} for a propaganda poster",
        DIALOG_ASK_COMMISSION = [[
            {not asked?
                player:
                    I'm looking to make a propaganda poster.
                    Can you help me make one?
                agent:
                {disliked?
                    Why should I?
                    If you want to make me help you, you have to pay.
                    A lot.
                }
                {not disliked?
                    {not is_artist?
                        I could certainly try.
                        Be warned: you probably will not like it.
                        You still have to pay for it though.
                    }
                    {is_artist?
                        Perhaps.
                        I can make you an extremely convincing poster.
                        Provided you can pay, of course.
                    }
                }
                player:
                    Name your price then.
                agent:
                    Okay.
                    If you can {demand_list#demand_list}, I will make a poster for you.
            }
            {asked?
                agent:
                    Have you decided yet?
            }
        ]],
        DIALOG_PAYED_COMMISSION = [[
            agent:
                Okay. You hold up your end of the bargain, I'll hold up mine.
                I'll make the poster for you.
                Now, what do you want it to say?
        ]],

        OPT_MAKE = "Make the poster yourself",
        DIALOG_MAKE = [[
            agent:
                You're really going to make it yourself?
            player:
                Well, yeah.
                It's a waste of money, really.
            agent:
                What happened to your funding?
                Did you spend it on drinking with people?
            player:
                Now that's none of your business.
            agent:
                Alright, keep your secrets then.
                Now, what do you want it to say?
        ]],
    }
    :Hub(function(cxt, who)
        if DemocracyUtil.RandomBystanderCondition(who) then
            cxt.enc.scratch.is_artist = IsArtist(who)
            if not cxt.quest.param.artist_demands then
                cxt.quest.param.artist_demands = {}
            end
            cxt.enc.scratch.asked = cxt.quest.param.artist_demands[who:GetID()] ~= nil
            local opt = cxt:Opt("OPT_ASK_COMMISSION")
                :SetQuestMark(cxt.quest)
                -- :ReqCondition(not who:HasMemoryFromToday("ASKED_FOR_COMMISSION"), "REQ_ALREADY_ASKED")
            if not cxt.enc.scratch.asked then
                opt:PostText("TT_FREE_TIME_ACTION_COST", 1)
                    :ReqCondition((cxt.quest.param.actions or 0) >= 1, "REQ_FREE_TIME_ACTIONS")
                    :Fn(function(cxt)
                        cxt.quest.param.actions = (cxt.quest.param.actions or 0) - 1
                    end)
            end
            opt:Fn(function(cxt)
                    if not cxt.quest.param.artist_demands[who:GetID()] then
                        local rawcost = 25 * cxt.quest:GetRank() + 25
                        if cxt.enc.scratch.is_artist then
                            rawcost = rawcost * 2
                        end
                        
                        local demands, demand_list = DemocracyUtil.GenerateDemandList(rawcost, who, nil, {
                            auto_scale = true,
                        })
                        cxt.quest.param.artist_demands[who:GetID()] = {
                            demands = demands,
                            demand_list = demand_list,
                        }
                    end

                    cxt.quest.param.demand_list = cxt.quest.param.artist_demands[who:GetID()].demand_list
                    -- DBG(cxt.enc.scratch.demand_list)
                    -- cxt.enc.scratch.testlol = true
                end)
                :Dialog("DIALOG_ASK_COMMISSION")
                :LoopingFn(function(cxt)
                    local dat = cxt.quest.param.artist_demands[who:GetID()]
                    local payed_all = DemocracyUtil.AddDemandConvo(cxt, dat.demand_list, dat.demands, function(opt)
                        opt:PostText("TT_FREE_TIME_ACTION_COST", 2)
                            :ReqCondition((cxt.quest.param.actions or 0) >= 2, "REQ_FREE_TIME_ACTIONS")
                            :Fn(function(cxt)
                                cxt.quest.param.actions = (cxt.quest.param.actions or 0) - 2
                            end)
                    end)

                    if payed_all then
                        cxt:Dialog("DIALOG_PAYED_COMMISSION")
                        cxt.quest.param.artist = who
                        cxt.quest.param.is_artist = IsArtist(who)
                        cxt:GoTo("STATE_MAKE_POSTER")
                    else
                        StateGraphUtil.AddBackButton(cxt)
                    end
                end)
        elseif who == cxt.quest:GetCastMember("primary_advisor") then
            cxt:Opt("OPT_MAKE")
                :SetQuestMark(cxt.quest)
                :Dialog("DIALOG_MAKE")
                :GoTo("STATE_MAKE_POSTER")
        end
    end)
    :State("STATE_MAKE_POSTER")
        :Loc{
            OPT_HINT = "Ask about how to make posters",
            DIALOG_HINT = [[
                player:
                    Okay, I haven't actually made a poster before, and I'm not sure what to do.
                agent:
                    Now, making propaganda poster is like regular negotiation.
                    You can still use all your regular negotiation techniques.
                    However, once you've written it, you cannot change it.
                player:
                    So it's like a recording.
                agent:
                    More or less.
                    You might be tempted to write a lot, but people will be too intimidated by your wall of text.
                    But writing too few will not tell the readers what you think, and they will be less interested in you.
                    Best to keep it short, but to the point.
            ]],

            OPT_START = "Start writing",

            DIALOG_START = [[
                player:
                    I'm ready to start.
                agent:
                    Excellent!
            ]],

            DIALOG_FINISH = [[
                player:
                    Done.
                {artist?
                agent:
                    !permit
                    Okay, so here's the poster.
                    Do you like it?
                player:
                    !take
                    Let's see...
                |
                agent:
                    Are you happy with your creation?
                player:
                    !thought
                    I don't know. I gotta take a look.
                }
            ]],
            DIALOG_FINISH_TOO_FEW_CARDS = [[
                player:
                    Yeah I got nothing.
                    I have some ideas here and there, but there's not enough.
                agent:
                    A shame.
                    Anyway, I'm adding some random lines here to make it looks like there's more to the poster.
                    Probably won't fool anyone, though.
                    !permit
                    Take a look.
                player:
                    !thought
                    Hmm...
            ]],

            DIALOG_FINISH_PST = [[
                player:
                    Looks good. Maybe.
                    But only time will tell whether this is really effective.
            ]],
        }
        :Fn(function(cxt)
            if not cxt.quest.param.cards then
                cxt.quest.param.cards = {}
            end
            cxt:GetAgent():SetTempNegotiationBehaviour(DRAFT_BEHAVIOUR)
            cxt:Question("OPT_HINT", "DIALOG_HINT")

            local recorded_cards = {}
            -- yeah havent figured out what to do with it.
            local function ProcessFn(cxt, minigame)
                local stacks = minigame:GetPlayerNegotiator():GetModifierStacks("TIME_CONSTRAINT")
                cxt.quest.param.actions = stacks
                if #recorded_cards >= 3 then
                    cxt:Dialog("DIALOG_FINISH")
                else
                    cxt:Dialog("DIALOG_FINISH_TOO_FEW_CARDS")
                    while #recorded_cards < 3 do
                        table.insert(recorded_cards, "fast_talk")
                    end
                end
                local cards = cxt:GainCards({"propaganda_poster"})
                -- DBG(cards)
                cards[1].userdata.imprints = shallowcopy(recorded_cards)
                -- cxt:BasicNegotiation("START") -- for testing purpose.
                cxt:Dialog("DIALOG_FINISH_PST")
                cxt.quest:Complete("commission")
                cxt.quest:Activate("post")
                StateGraphUtil.AddEndOption(cxt)
            end
            cxt:Opt("OPT_START")
                :Dialog("DIALOG_START")
                :Negotiation{
                    on_start_negotiation = function(minigame)
                        local negotiation_defs = require "negotiation/negotiation_defs"
                        local CARD_FLAGS = negotiation_defs.CARD_FLAGS

                        for i, card in minigame:GetDrawDeck():Cards() do
                            if CheckBits( def.card, CARD_FLAGS.ITEM ) then
                                card:TransferCard( minigame:GetTrashDeck() )
                            end
                        end
                        for i = 1, 3 do
                            minigame:GetPlayerNegotiator():CreateModifier( "SIMULATION_ARGUMENT", 1 )
                            minigame:GetOpponentNegotiator():CreateModifier( "SIMULATION_ARGUMENT", 1 )
                        end
                        minigame:GetOpponentNegotiator():FindCoreArgument().cards_played = recorded_cards
                        minigame:GetPlayerNegotiator():CreateModifier( "TIME_CONSTRAINT", math.max(cxt.quest.param.actions or 1, 1) )
                    end,
                    finish_negotiation_anytime = true,
                    on_success = ProcessFn,
                    on_fail = ProcessFn,
                }
        end)

QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
            primary_advisor:
                Maybe it's a good idea to post propaganda posters in popular locations.
            player:
                We don't have anything like that, do we?
            primary_advisor:
                Not yet, anyway.
                You can ask someone to commission one for you.
            player:
                If I can't find anyone like that?
            primary_advisor:
                Then draw one yourself, or something.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.ACCEPTED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                Sounds good.
                You know how to start?
            primary_advisor:
                Go ask someone who looks like they have artistic talents.
                !thought
                Or someone who looks like they have time to waste on art.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.DECLINED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                I don't know. That might not worth the effort.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)