local ARTISTS = {
    RISE_PAMPHLETEER = 0.65,
    FOREMAN = 0.35,
    PRIEST = 0.5,
    PRIEST_PROMOTED = 0.65,
    SPARK_BARON_TASKMASTER = 0.35,
    ADMIRALTY_CLERK = 0.5,
    -- SPREE_CAPTAIN = 0.15,
    WEALTHY_MERCHANT = 0.35,
    WEALTHY_MERCHANT_PROMOTED = 0.55,
    POOR_MERCHANT = 0.5,
    JAKES_SMUGGLER = 0.3,
}
local function IsArtist(agent)
    return agent:CalculateProperty("IS_ARTIST", function(agent)
        local chance_for_artist = ARTISTS[agent:GetContentID()] or 0.1
        return math.random() < chance_for_artist
    end)
end
local function IsPotentiallyArtist(agent)
    return ARTISTS[agent:GetContentID()]
end
local POOR_ART = {"PROP_PO_MESSY", "PROP_PO_SUPERFICIAL"}
local GOOD_ART = {"PROP_PO_INSPIRING", "PROP_PO_THOUGHT_PROVOKING"}

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
    icon = engine.asset.Texture("icons/quests/bounty_hunt.tex"),

    qtype = QTYPE.SIDE,
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"RALLY_JOB"},
    reward_mod = 0,
    extra_reward = false,
    on_start = function(quest)
        quest:Activate("commission")
        -- quest.param.actions = math.round(DemocracyUtil.GetBaseFreeTimeActions() * 1.5)
        quest:Activate("time_left")
    end,
    -- events =
    -- {
    --     caravan_move_location = function(quest, location)
    --         if location:HasTag("road") then
    --             if quest.param.actions then
    --                 quest.param.actions = quest.param.actions - 1
    --                 quest:NotifyChanged()
    --             end
    --         end
    --     end,
    -- },
    on_complete = function(quest)
        -- if quest.param.poor_performance then
        --     DemocracyUtil.DeltaGeneralSupport(2 * #quest.param.posted_location, "POOR_QUEST")
        -- else
        local score = 3 * (quest.param.posted_location and #quest.param.posted_location or 0) + 2 * (quest.param.liked_people or 0) + (quest.param.ignored_people or 0)
        DemocracyUtil.DeltaGeneralSupport(score, "COMPLETED_QUEST")
        -- end
    end,
    precondition = function(quest)
        return TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor")
    end,
}
:AddObjective{
    id = "commission",
    title = "Create a poster",
    desc = "Commission someone with artistic talent to create a poster for you. Or just make your own.",
    mark = function(quest, t, in_location)
        if in_location then
            local location = TheGame:GetGameState():GetPlayerAgent():GetLocation()
            for i, agent in location:Agents() do
                if DemocracyUtil.RandomBystanderCondition(agent) and (not quest.param.artist_demands
                    or quest.param.artist_demands[agent:GetID()] ~= false) then
                    table.insert(t, agent)
                end
            end
        else
            DemocracyUtil.AddUnlockedLocationMarks(t)
        end
        table.insert(t, quest:GetCastMember("primary_advisor"))
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
                if location:GetProprietor() then
                    table.insert(t, location:GetProprietor())
                end
            end
        else
            DemocracyUtil.AddUnlockedLocationMarks(t, function(location)
                return location:GetProprietor() and
                    not (quest.param.posted_location and table.arraycontains(quest.param.posted_location, location:GetContentID()))
            end)
        end
        -- without this the game will softlock sometimes.
        -- now you can forgo free time and hand in quest early.
        table.insert(t, quest:GetCastMember("primary_advisor"))
    end,
    on_activate = function(quest)
        quest.param.liked_people = 0
        quest.param.disliked_people = 0
        quest.param.ignored_people = 0
        if quest:IsActive("find_artist") then
            quest:Cancel("find_artist")
        end
    end,
}
-- :AddObjective{
--     id = "time_left",
--     title = "Actions left: {actions}",
-- }
:AddFreeTimeObjective{
    id = "time_left",
    desc = "Use this time to write a propaganda poster and post it to as many locations as possible.",
    action_multiplier = 1.5,
    on_complete = function(quest)
        if quest:IsActive("commission") then
            quest:Fail("commission")
        end
        if quest:IsActive("post") then
            quest:Cancel("post")
        end
        quest:Activate("out_of_time")
    end,
}
:AddObjective{
    id = "out_of_time",
    mark = {"primary_advisor"},
    title = "Report to {primary_advisor}",
    desc = "You ran out of time. Return to {primary_advisor} on your progress.",
    on_activate = function(quest)
        if quest:IsActive("find_artist") then
            quest:Cancel("find_artist")
        end
        if quest:IsActive("time_left") then
            quest:Cancel("time_left")
        end
    end,
}
:AddObjective{
    id = "find_artist",
    title = "(Optional) Find {known_artist}",
    desc = "{known_artist} is known to be an artist. Perhaps you should find {known_artist.himher}.",
    mark = {"known_artist"},
}
:AddCast{
    cast_id = "known_artist",
    when = QWHEN.MANUAL,
    no_validation = true,
    optional = true,
    condition = function(agent, quest)
        if not IsPotentiallyArtist(agent) then
            return false, "Can't be artist"
        end
        if not DemocracyUtil.RandomBystanderCondition(agent) then
            return false, "Not a random bystander"
        end
        if quest.param.artist_faction then
            return agent:GetFactionID() == quest.param.artist_faction, "Invalid faction"
        end
        return true
    end,
    score_fn = function(agent, quest)
        if IsArtist(agent) then
            return math.random(3,5)
        end
        return math.random(1,5)
    end,
    on_assign = function(quest)
        -- if not quest:IsDone("commission") then
        --     quest:Activate("find_artist")
        -- end
    end,
}
DemocracyUtil.AddPrimaryAdvisor(QDEF, true)
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
        DIALOG_NO_READER = [[
            player:
                [p] So I posted our poster, but no one has a chance to look at it yet.
            agent:
                That's going to be a bit of a problem.
                Perhaps you should find better places to post those posters.
            player:
                !crossed
                If you have better places, you should've told me!
            agent:
                Anyway, at least you technically did what I told you to do, so that's something.
        ]],
        DIALOG_BAD = [[
            player:
                [p] So I posted our poster, but people don't like it.
            agent:
            {has_artist?
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
                !happy
                Excellent news!
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_TALK_PROGRESS")
            :SetQuestMark(cxt.quest)
            :Dialog("DIALOG_PRE")
            :Fn(function(cxt)
                if not (cxt.quest.param.posted_location and #cxt.quest.param.posted_location > 0) then
                    if not cxt.quest:IsComplete("commission") then
                        cxt:Dialog("DIALOG_NO_POSTER")
                    else
                        cxt:Dialog("DIALOG_NO_POST")
                    end
                    cxt.quest:Fail()
                else
                    if (cxt.quest.param.liked_people or 0) + (cxt.quest.param.disliked_people or 0) == 0 then
                        cxt:Dialog("DIALOG_NO_READER")
                        cxt.quest.param.poor_performance = true
                    elseif (cxt.quest.param.liked_people or 0) == 0 or (cxt.quest.param.disliked_people or 0) - (cxt.quest.param.liked_people or 0) >= 2 then
                        cxt:Dialog("DIALOG_BAD")
                        cxt.quest.param.poor_performance = true

                    elseif (cxt.quest.param.disliked_people or 0) - (cxt.quest.param.liked_people or 0) <= -2 then
                        cxt:Dialog("DIALOG_GOOD")
                        -- cxt.quest.param.good_performance = true
                    else
                        cxt:Dialog("DIALOG_PASSABLE")
                    end
                    cxt.quest:Complete()
                    ConvoUtil.GiveQuestRewards(cxt)
                end
                StateGraphUtil.AddEndOption(cxt)
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
        OPT_SELECT = "Select a poster...",
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

        OPT_END_EARLY = "Finish quest early",
        DIALOG_END_EARLY = [[
            player:
                I'm done.
            agent:
                Wait, really?
                But there's still plenty of time!
            player:
                Nothing else I can do.
            agent:
                Suit yourself, I guess.
        ]],

        SELECT_TITLE = "Select a poster",
        SELECT_DESC = "Choose a poster to post on this location, consuming 1 use on it.",
    }
    :Hub(function(cxt, who)
        if who == cxt:GetCastMember("primary_advisor") then
            cxt:Opt("OPT_END_EARLY")
                :SetQuestMark(cxt.quest)
                :Dialog("DIALOG_END_EARLY")
                :Fn(function(cxt)
                    cxt.quest:Complete("time_left")
                end)
            return
        end
        if who and cxt.location and cxt.location:GetProprietor() == who then
            local location = cxt.location
            if not (cxt.quest.param.posted_location and table.arraycontains(cxt.quest.param.posted_location, location:GetContentID())) then
                cxt:Opt("OPT_ASK")
                    :Dialog("DIALOG_ASK")
                    -- :ReqCondition((cxt.quest.param.actions or 0) >= 1, "REQ_FREE_TIME_ACTIONS")
                    -- :Fn(function(cxt)
                    --     cxt.quest.param.actions = (cxt.quest.param.actions or 0) - 1
                    --     cxt.quest:NotifyChanged()
                    -- end)
                    -- :RequireFreeTimeAction(1)
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
                                cxt:RunLoop(function(cxt)
                                -- local cards = agent.negotiator:GetCards()
                                    cxt:Opt("OPT_SELECT")
                                        :Fn(function(cxt)
                                            cxt:Wait()
                                            DemocracyUtil.InsertSelectCardScreen(
                                                posters,
                                                cxt:GetLocString("SELECT_TITLE"),
                                                cxt:GetLocString("SELECT_DESC"),
                                                nil,
                                                function(card)
                                                    cxt.enc:ResumeEncounter( card )
                                                end
                                            )
                                            local card = cxt.enc:YieldEncounter()
                                            if card then
                                                cxt:Dialog("DIALOG_SELECT")

                                                location:Remember("HAS_PROPAGANDA_POSTER", shallowcopy(card.userdata))
                                                card:ConsumeCharge()
                                                if card:IsSpent() then
                                                    cxt.player.negotiator:RemoveCard( card )
                                                end
                                                if not cxt.quest.param.posted_location then
                                                    cxt.quest.param.posted_location = {}
                                                end
                                                table.insert(cxt.quest.param.posted_location, location:GetContentID())

                                                cxt:GoTo("STATE_READ")
                                            end
                                        end)
                                end)

                                -- for i, card in ipairs(posters) do
                                --     cxt:Opt("OPT_SELECT", card)
                                --         :Dialog("DIALOG_SELECT")
                                --         :Fn(function(cxt)
                                --             location:Remember("HAS_PROPAGANDA_POSTER", shallowcopy(card.userdata))
                                --             card:ConsumeCharge()
                                --             if card:IsSpent() then
                                --                 cxt.player.negotiator:RemoveCard( card )
                                --             end
                                --             if not cxt.quest.param.posted_location then
                                --                 cxt.quest.param.posted_location = {}
                                --             end
                                --             table.insert(cxt.quest.param.posted_location, location:GetContentID())
                                --         end)
                                --         :GoTo("STATE_READ")
                                -- end
                            end
                        end,
                        on_fail = function(cxt)
                            cxt:Dialog("DIALOG_ASK_FAILURE")
                        end,
                    }
            end
        end

    end)
    :State("STATE_READ")
        :Loc{
            DIALOG_NO_READER = [[
                * Seems like there's no one here that's interested in your poster.
                * You have to come back later to see. Hopefully.
            ]],
            DIALOG_INTRO = [[
                agent:
                    Oh look, someone's already reading the poster.
            ]],
        }
        :Fn(function(cxt)
            local candidates = {}
            for i, agent in cxt.location:Agents() do
                if agent:IsSentient() and not agent:IsInPlayerParty() and
                    not AgentUtil.HasPlotArmour(agent) and agent ~= cxt:GetAgent()
                    and agent:GetRelationship() == RELATIONSHIP.NEUTRAL then

                    table.insert(candidates, agent)
                end
            end
            if #candidates > 0 then
                cxt.quest.param.readers = {}
                for i, agent in ipairs(candidates) do
                    if math.random() < 0.4 then
                        table.insert(cxt.quest.param.readers, agent)
                    end
                    if #cxt.quest.param.readers > 0 then
                        cxt:Dialog("DIALOG_INTRO")
                        cxt:End()
                        UIHelpers.DoSpecificConvo(nil, "PROPAGANDA_POSTER_CONVO", "STATE_READ", nil, nil, cxt.quest )
                        return
                    end
                end

            end
            cxt.location:Remember("DID_PROPAGANDA_TODAY")
            cxt:Dialog("DIALOG_NO_READER")
            StateGraphUtil.AddEndOption(cxt)
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
                    Perhaps.
                    {is_artist?
                        I can make you an extremely convincing poster.
                        Provided you can pay, of course.
                    }
                    {not is_artist?
                        I can draw you <i>something</>.
                        It's not going to be amazing, but it would be better than whatever you come up with.
                    player:
                        !crossed
                        Now that's just rude.
                    agent:
                        I apologize if I offended you.
                        You still need to pay, though.
                    }
                }
                player:
                    Name your price then.
                agent:
                    Okay.
                    If you can {demand_list#demand_list}, I will make a poster for you.
                {is_artist?
                    *** This person is a good artist. You can hire {agent.himher}, but it will cost a lot.
                    |
                    *** This person is not a good artist, but you can still hire {agent.himher} at a reduced rate.
                }
            }
            {asked?
                agent:
                    Have you decided yet?
            }
        ]],
        DIALOG_ASK_COMMISSION_NOT_ARTIST = [[
            player:
                I'm looking to make a propaganda poster.
                Can you help me make one?
            agent:
                No.
            player:
                Understandable, have a nice day.
            *** This person is not an artist.
        ]],
        DIALOG_ASK_COMMISSION_KNOWS_ARTIST = [[
            player:
                I'm looking to make a propaganda poster.
                Can you help me make one?
            agent:
                No.
                But potentially I know someone who can.
                {known_artist.HisHer} name is {known_artist}.
            {target_good_artist?
                {known_artist.HeShe} knows how to draw a convincing poster.
                Might cost a lot to commission {known_artist.himher}, though.
                Depends on how good you want your poster to be, I guess.
                |
                {known_artist.HeShe}'s not exactly the best artist, but {known_artist.heshe} gets the job done.
                Plus, {known_artist.hisher} prices are <i>relatively</> cheap.
            }
            player:
                Thanks for the info.
            *** This person is not an artist, but {agent.heshe} knows that {known_artist} is.
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

        REQ_NOT_ARTIST = "This person won't make a propaganda poster because {agent.heshe} can't.",
    }
    :Hub(function(cxt, who)
        if who and (DemocracyUtil.RandomBystanderCondition(who) or who == cxt:GetCastMember("known_artist")) then
            cxt.enc.scratch.is_artist = IsArtist(who)
            if not cxt.quest.param.artist_demands then
                cxt.quest.param.artist_demands = {}
            end
            cxt.enc.scratch.asked = cxt.quest.param.artist_demands[who:GetID()] ~= nil
            local opt = cxt:Opt("OPT_ASK_COMMISSION")
                :SetQuestMark(cxt.quest)
                :ReqCondition(cxt.quest.param.artist_demands[who:GetID()] ~= false,"REQ_NOT_ARTIST")
                -- :ReqCondition(not who:HasMemoryFromToday("ASKED_FOR_COMMISSION"), "REQ_ALREADY_ASKED")
            if not cxt.enc.scratch.asked then
                opt:RequireFreeTimeAction(1)
                    -- :PostText("TT_FREE_TIME_ACTION_COST", 1)
                    -- :ReqCondition((cxt.quest.param.actions or 0) >= 1, "REQ_FREE_TIME_ACTIONS")
                    -- :Fn(function(cxt)
                    --     cxt.quest.param.actions = (cxt.quest.param.actions or 0) - 1
                    --     cxt.quest:NotifyChanged()
                    -- end)

            end
            opt:Fn(function(cxt)
                if cxt.quest.param.artist_demands[who:GetID()] == nil then
                    if IsPotentiallyArtist(who) then
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
                    else
                        cxt.quest.param.artist_demands[who:GetID()] = false
                    end
                end


                -- DBG(cxt.enc.scratch.demand_list)
                -- cxt.enc.scratch.testlol = true
                if IsPotentiallyArtist(who) then
                    cxt.quest.param.demand_list = cxt.quest.param.artist_demands[who:GetID()].demand_list
                    cxt:Dialog("DIALOG_ASK_COMMISSION")
                    cxt:RunLoop(function(cxt)
                        local dat = cxt.quest.param.artist_demands[who:GetID()]
                        local payed_all = DemocracyUtil.AddDemandConvo(cxt, dat.demand_list, dat.demands, function(opt)
                            -- opt:RequireFreeTimeAction(2)
                                -- :PostText("TT_FREE_TIME_ACTION_COST", 2)
                                -- :ReqCondition((cxt.quest.param.actions or 0) >= 2, "REQ_FREE_TIME_ACTIONS")
                                -- :Fn(function(cxt)
                                --     cxt.quest.param.actions = (cxt.quest.param.actions or 0) - 2
                                --     cxt.quest:NotifyChanged()
                                -- end)
                        end)

                        if payed_all then
                            cxt:Dialog("DIALOG_PAYED_COMMISSION")
                            cxt.quest.param.artist = who
                            cxt.quest.param.has_artist = true
                            cxt.quest.param.is_artist = IsArtist(who)
                            cxt:GoTo("STATE_MAKE_POSTER")
                        else
                            StateGraphUtil.AddBackButton(cxt)
                        end
                    end)
                else
                    if cxt:GetAgent():GetRelationship() >= RELATIONSHIP.NEUTRAL and
                        not cxt:GetCastMember("known_artist") and math.random() < 0.5 then

                        cxt.quest.param.artist_faction = cxt:GetAgent():GetFactionID()
                        cxt.quest:AssignCastMember("known_artist")
                        local known_artist = cxt:GetCastMember("known_artist")
                        if known_artist then
                            cxt.enc.scratch.target_good_artist = IsArtist(known_artist)
                            cxt:Dialog("DIALOG_ASK_COMMISSION_KNOWS_ARTIST")
                            if not cxt.quest:IsDone("commission") then
                                cxt.quest:Activate("find_artist")
                            end
                        else
                            cxt:Dialog("DIALOG_ASK_COMMISSION_NOT_ARTIST")
                        end
                    else
                        cxt:Dialog("DIALOG_ASK_COMMISSION_NOT_ARTIST")
                    end
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
                *** Basically you're doing a special negotiation that records the cards you play.
                *** When convincing someone with a poster, you will have no control over the cards you've already played.
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
                *** You played too few cards, so some garbage are added automatically.
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
                cxt.quest.param.free_time_actions = stacks
                cxt.quest:NotifyChanged()
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
                if not cxt.quest.param.artist then
                    if math.random() < 0.7 then
                        cards[1].userdata.prop_mod = table.arraypick(POOR_ART)
                    end
                elseif cxt.quest.param.is_artist then
                    cards[1].userdata.prop_mod = table.arraypick(GOOD_ART)

                else
                    local val = math.random()
                    if val < 0.3 then
                        cards[1].userdata.prop_mod = table.arraypick(POOR_ART)
                    elseif val > 0.8 then
                        cards[1].userdata.prop_mod = table.arraypick(GOOD_ART)
                    end
                end
                -- cxt:BasicNegotiation("START") -- for testing purpose.
                cxt:Dialog("DIALOG_FINISH_PST")
                cxt.quest:Complete("commission")
                cxt.quest:Activate("post")
                StateGraphUtil.AddEndOption(cxt)
            end
            cxt:Opt("OPT_START")
                :Dialog("DIALOG_START")
                :Negotiation{
                    no_free_time_cost = true,
                    flags = NEGOTIATION_FLAGS.NO_BYSTANDERS | NEGOTIATION_FLAGS.NO_BACKUP,
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
                        minigame:GetPlayerNegotiator():CreateModifier( "TIME_CONSTRAINT", math.max(cxt.quest.param.free_time_actions or 1, 1) )
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