local RELATION_OFFSET = {
    [RELATIONSHIP.HATED] = -16,
    [RELATIONSHIP.DISLIKED] = -8,
    [RELATIONSHIP.NEUTRAL] = 0,
    [RELATIONSHIP.LIKED] = 8,
    [RELATIONSHIP.LOVED] = 16,
}

local QDEF = QuestDef.Define
{
    title = "Interview",
    desc = "Go to the interview and spread awareness of your campaign.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/interview.png"),

    qtype = QTYPE.STORY,
    collect_agent_locations = function(quest, t)
        -- if quest:IsActive("return_to_advisor") then
        --     table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('home')})
        -- else
        table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('backroom'), role = CHARACTER_ROLES.VISITOR})
        -- end
        table.insert(t, { agent = quest:GetCastMember("host"), location = quest:GetCastMember('theater'), role = CHARACTER_ROLES.PROPRIETOR})
    end,
    on_destroy = function(quest)
        quest:GetCastMember("primary_advisor"):GetBrain():SendToWork()
        if quest.param.parent_quest then
            quest.param.parent_quest.param.did_interview = true
        end
    end,
    events =
    {
        get_free_location_marks = function(quest, free_quest, locations)
            table.arrayremove(locations, quest:GetCastMember("theater"))
        end,
    },
}
:AddCast{
    cast_id = "host",
    cast_fn = function(quest, t)
        if quest:GetCastMember("theater"):GetProprietor() then
            table.insert(t, quest:GetCastMember("theater"):GetProprietor())
        end
    end,
    when = QWHEN.MANUAL,
    events =
    {
        agent_retired = function( quest, agent )
            -- if quest:IsActive( "get_snail" ) then
                -- If noodle chef died before we even got the snail, cast someone new.
                quest:UnassignCastMember( "host" )
                quest:AssignCastMember( "host" )
            -- end
        end,
    },
}
:AddCastFallback{
    cast_fn = function(quest, t)
        quest:GetCastMember("theater"):GetWorkPosition("host"):TryHire()
        if quest:GetCastMember("theater"):GetProprietor() then
            table.insert(t, quest:GetCastMember("theater"):GetProprietor())
        end
    end,
}
:AddCast{
    cast_id = "audience",
    when = QWHEN.MANUAL,
    condition = function(agent, quest)
        return not table.arraycontains(quest.param.audience or {}, agent)
    end,
    score_fn = function(agent, quest)
        if agent:HasAspect( "bribed" ) then
            return 100
        end
        local sc = agent:GetRenown() * 2
        if agent:GetRelationship() ~= RELATIONSHIP.NEUTRAL then
            sc = sc + 5
        end
        return math.random(sc, 20)
    end,
    on_assign = function(quest, agent)
        if not quest.param.audience then
            quest.param.audience = {}
        end
        table.insert(quest.param.audience, agent)
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent() )
    end,
}
:AddLocationCast{
    cast_id = "theater",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GRAND_THEATER"))
    end,
    on_assign = function(quest, location)
        -- quest:SpawnTempLocation("BACKROOM", "backroom")
        quest:AssignCastMember("host")
    end,
    no_validation = true,
}
:AddLocationCast{
    cast_id = "backroom",
    no_validation = true,
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GRAND_THEATER.backroom"))
    end,
    -- on_assign = function(quest, location)

    --     -- print(location)
    --     -- print(quest:GetCastMember("theater"))
    --     -- print(quest:GetCastMember("theater"):GetMapPos())
    --     -- location:SetMapPos( quest:GetCastMember("theater"):GetMapPos() )
    -- end,
    -- when = QWHEN.MANUAL,
}
:AddObjective{
    id = "go_to_interview",
    title = "Go to interview",
    desc = "Meet up with {primary_advisor} at the Grand Theater.",
    mark = {"backroom"},
    state = QSTATUS.ACTIVE,
}
:AddObjective{
    id = "do_interview",
    title = "Do the interview",
    desc = "Try not to embarrass yourself.",
    mark = {"theater"},
    -- state = QSTATUS.ACTIVE,
}
-- :AddObjective{
--     id = "return_to_advisor",
--     title = "Return to your advisor",
--     desc = "Return to your advisor and discuss your current situation.",
--     mark = {"primary_advisor"},
-- }

-- :AddLocationDefs{

-- }

:AddOpinionEvents{
    likes_interview = {
        delta = OPINION_DELTAS.OPINION_UP,
        txt = "Likes your interview",
    },
    dislikes_interview = {
        delta = OPINION_DELTAS.TO_HATED,
        txt = "Dislikes your interview",
    }
}

DemocracyUtil.AddPrimaryAdvisor(QDEF, true)
DemocracyUtil.AddHomeCasts(QDEF)
QDEF:AddConvo("go_to_interview")
    :Confront(function(cxt)
        if cxt:GetCastMember("primary_advisor") and cxt.location == cxt.quest:GetCastMember("backroom") then
            return "STATE_CONFRONT"
        end
        if cxt.location == cxt.quest:GetCastMember("theater") then
            return "STATE_THEATER"
        end
    end)
    :State("STATE_THEATER")
        :Loc{
            DIALOG_INTRO = [[
                * You arrived at the Grand Theater.
                * Looks like the interview hasn't started yet.
                * You quickly walk into the backroom to meet up with {primary_advisor}.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt:Opt("OPT_LEAVE_LOCATION")
                :Fn(function(cxt)
                    cxt.quest.param.enter_from_theater = true
                    cxt.encounter:DoLocationTransition(cxt.quest:GetCastMember("backroom"))
                end)
                :MakeUnder()
        end)
    :State("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                {not enter_from_theater?
                    * You arrive at the Grand Theater, and are ushered into a back room. You barely make it into the room before you're ambushed by {primary_advisor}.
                }
                {enter_from_theater?
                    * Just as you begin to look for {primary_advisor}, looks like {primary_advisor.heshe} found you first.
                }
                player:
                    !left
                primary_advisor:
                    !right
                {depressed?
                    Oh, {player}. You finally arrived.
                    Are you ready for the interview?
                player:
                    Can't say I'm ready, exactly. I am a bit nervous.
                agent:
                    !sigh
                    That's okay, I'm sure whatever you do, you will do better than me.
                    You don't need a loser to tell you what to do.
                player:
                    !dubious
                    Are you alright? You don't sound like yourself.
                agent:
                    !handwave
                    Nah. Don't worry about a loser like me.
                    Worry about yourself. The interview is about to start, and you need to prepare.
                    {has_pet?
                        And leave your {pet.species} here. You can't bring it into the venue.
                    }
                * Regardless of {agent}'s strange episode, {agent.heshe} is right that you need to prepare.
                * You can ask {agent} about it later. The interview is of the utmost importance.
                }
                {not depressed?
                    Alright {player}, tonight is big, so let's run through what you've got really quick.
                    Have you got you're prepared answers?
                player:
                    My what?
                primary_advisor:
                    Okay, no answers prepared...how about a teleprompter?
                player:
                    I have integrity, my dear {primary_advisor}!
                primary_advisor:
                    Yeah well integrity isn't going to get you through this in one piece.
                    For Hesh's sake, did you even bring a breath mint?
                player:
                    !crossed
                    Okay now that's just insulting.
                primary_advisor:
                    Well get ready for a lot more of that once you're on stage.
                    Think about it. You're no longer a passer-by with a big mouth and big opinions.
                    This ain't little league anymore. Many people from all sides are watching your interview, eager to hear if you are a capable candidate.
                player:
                    !surprised
                    Really?
                primary_advisor:
                    !palm
                    Yes really! I can't believe you didn't realize the importance of such interview.
                    Anyway, you have a few minutes before the interview starts. Try compose yourself before you go.
                    {has_pet?
                        And leave your {pet.species} here. You can't bring it into the venue.
                    }
                }
            ]],
            OPT_ASK_INTERVIEW = "Ask about the interview",
            DIALOG_ASK_INTERVIEW = [[
                player:
                    [p] I'm not sure what this interview is about.
                agent:
                {depressed?
                    !sigh
                    Don't worry, however little you know, you will know it more than me.
                player:
                    I don't think that's how it works, given that I have literally no idea what is going on.
                    Surely you must know something?
                }
                {not depressed?
                    !dubious
                    Seriously? You are about to do it, and you don't even know how it works?
                    Unbelievable.
                player:
                    !crossed
                    I'm busy. Gathering support.
                }
                agent:
                {depressed or not advisor_hostile?
                    !placate
                    Alright.
                }
                {advisor_hostile and not depressed?
                    !hips
                    Of course.
                    {accept_limits?
                        I will happily tell you all about the interview.
                        Even though I might be the best, I can still give you some useful tips.
                    }
                    {not accept_limits?
                        I can tell you all about the interview.
                        After all, nobody knows interviews better than me.
                    }
                }
                    The interviewer will ask you a bunch of questions, and you want to answer as much question as possible.
                    You can address each question directly, or you can spend some time tailor your answers.
                player:
                    Sounds complicated.
                    I think I will just improvise.
            ]],
            OPT_ASK_AUDIENCE = "Ask about the audience",
            DIALOG_ASK_AUDIENCE = [[
                player:
                    [p] There sure are a lot of people, huh?
                agent:
                    Yeah.
                    They are all eager to hear from you and what you have to say.
                    Some are here to confirm beliefs about you, while others are here to listen to what you have to say before making a decision.
                {advisor_diplomacy?
                    Try to be based. Be cool. Appeal to the crowd.
                player:
                    Yeah, those are words that definitely mean things.
                agent:
                    Just... Know your audience, and say things they want to hear.
                }
                {not advisor_diplomacy?
                    Try to tailor your answers based on your audience.
                player:
                    Alright.
                agent:
                    Of course, you can always just say something generic that appeals to everyone.
                    But that would take a lot of skills, and sometimes you might want to appeal to a more generic audience.
                }
            ]],
            OPT_ASK_PET = "Ask about pet policy",
            DIALOG_ASK_PET = [[
                player:
                    !crossed
                    {pet} has a name, you know. And {pet} is a {pet.heshe}.
                agent:
                    !point
                    Doesn't matter. You can't bring {pet.himher} into the venue either way.
                player:
                    Why? Why are pets not allowed?
                agent:
                    !point
                    Think about it.
                    Imagine doing an interview, and the audience just see {pet.a_desc} on the stage.
                    That would certainly cause chaos, and they can't have that.
                player:
                    ...
                agent:
                    !handwave
                    Either way, {pet} isn't going to help you on the stage.
                ** Your pets will still be in your party, but will not help you in the upcoming negotiation.
            ]],
            DIALOG_LEAVE = [[
                player:
                    Alright, I'm ready.
                    Moment of truth, here I go.
                {has_pet?
                agent:
                    I will take care of your {pet.species} for you.
                }
                agent:
                    Good luck.
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                DemocracyUtil.PopulateTheater(cxt.quest, cxt.quest:GetCastMember("theater"), 8)
                cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
                cxt.quest.param.party_pets = TheGame:GetGameState():GetCaravan():GetPets()
                if cxt.quest.param.party_pets and #cxt.quest.param.party_pets > 0 then
                    cxt.enc.scratch.has_pet = true
                    cxt:ReassignCastMember("pet", cxt.quest.param.party_pets[1])
                end
                cxt:Dialog("DIALOG_INTRO")
                cxt.quest:Complete("go_to_interview")
                cxt.quest:Activate("do_interview")
            end
            cxt:Question("OPT_ASK_INTERVIEW", "DIALOG_ASK_INTERVIEW")
            cxt:Question("OPT_ASK_AUDIENCE", "DIALOG_ASK_AUDIENCE")
            if cxt.enc.scratch.has_pet then
                cxt:Question("OPT_ASK_PET", "DIALOG_ASK_PET")
            end
            cxt:Opt("OPT_LEAVE_LOCATION")
                :Dialog("DIALOG_LEAVE")
                :Fn(function(cxt)
                    cxt.encounter:DoLocationTransition(cxt.quest:GetCastMember("theater"))
                end)
                :Pop()
                :MakeUnder()
        end)
QDEF:AddConvo("do_interview")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt.location == cxt.quest:GetCastMember("theater") end)
        :Loc{
            DIALOG_INTRO = [[
                * Stepping on stage, the bright Lumin lights threaten to blind you before you reach your seat.
            ]],

            DIALOG_RECOGNIZE_PEOPLE = [[
                * Looking out to the crowd, you see quite a few faces you know:
                * {1#agent_list}, wanting to see how you perform.
            ]],

            DIALOG_UNRECOGNIZE_PEOPLE = [[
                {know_at_least_one?
                    * There are some people you don't recognize though.
                }
                {not know_at_least_one?
                    * Looking out to the crowd, you don't recognize anyone here.
                }
                * You see {1#listing}.
                * No doubt to see who you are about and what you bring to the table before choosing a candidate.
            ]],

            DIALOG_INTERVIEW = [[
                * You are here to impress all these people with your interview skills, and convince them to join your side.
                * Standing in the middle of the stage is {host}, keeping the crowd excited for your entrance.
                agent:
                    !right
                    Alright people, tonight's guest is an up and coming political upstart, making a name for themselves on the Havarian stage TONIGHT!
                    Everyone, give a round of applause for our guest, {player}!
                    Have a seat, {player}.
                player:
                    !left
                * Some clapped, others booed your arrival.
                agent:
                    A little background for the audience, {player} is actually a retired Grifter, hanging up {player.hisher} weapons to join Havaria's First Election.
                {liked?
                    Although {player.heshe} have just started, {player.heshe} has gained quite some followers, and might even be more popular than seasoned politicians like Oolo and Fellemo.
                }
                {disliked?
                    As such, {player.hisher} leadership skills have been questionable at best.
                }
                {not liked and not disliked?
                    Many people wondered whether {player.heshe} will be able to compete with other seasoned politicians.
                }
                    Which is why today, we're having an exclusive interview with {player}.
                * Another round of applause.
                player:
                    Thank you for inviting me, {agent}.
                agent:
                    Let's start this show with a few questions...
                * Try to survive the interview, I guess?
            ]],

            OPT_DO_INTERVIEW = "Do the interview",
            SIT_MOD = "Has a lot of questions prepared for you",
            NEGOTIATION_REASON = "Survive the interview while answering as many questions as you can!({1} {1*question|questions} answered)",

            DIALOG_INTERVIEW_SUCCESS = [[
                agent:
                    Spectacular, {player}. You are quite savvy at interviews.
                    Once again, thank you for coming on the show.
                player:
                    No problems.
                agent:
                    One last round of applause for our guest, {player}!
                * This time, you hear a few less boos than before. You survived the interview.
            ]],
            DIALOG_INTERVIEW_FAIL = [[
                player:
                    !angry_accuse
                    All of you people, asking all of these questions!
                    I'm just one {player.gender:man|woman|person}, you know! I don't know everything!
                    $scaredPowerless
                    So why do you all depend on me? Why do you look up to me?
                agent:
                    !dubious
                    Excuse me, {player.gender:sir|ma'am|my friend}. Are you all right?
                player:
                    !angry_shrug
                    Of course not!
                    $scaredTakenAback
                    I hate this! I hate the election! I hate running a campaign.
                    $scaredAnguished
                    Why can't you *sob* just *sob* leave me alone!
                    !exit
                agent:
                    {player.gender:Sir|Ma'am|My friend}-
                * But it's already too late. You already ran out of the theater.
                * As you run down the Pearl streets, tears shed down your eyes.
                * All the stress, all the decisions, all the questions. It's all too much for you.
                * Where are you running to? Even you don't know.
                * The only thing you know is that you are running away from your campaign. Running away from politics, once and for all.
            ]],
            DIALOG_INTERVIEW_AFTER = [[
                * After the interview, {1*a person confronts you|several people confront you}.
            ]],
            DIALOG_INTERVIEW_AFTER_GOOD = [[
                * It seems a lot of people liked your interview! Nice!
            ]],
            DIALOG_INTERVIEW_AFTER_BAD = [[
                * That's not good. People don't like your interview!
            ]],
        }
        :Fn(function(cxt)

            cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("host"))
            cxt:Dialog("DIALOG_INTRO")

            local recognized_people = {}
            local unrecognized_descs = {}
            local agent_supports = {}

            for i, agent in cxt.quest:GetCastMember("theater"):Agents() do
                if agent:GetBrain():IsPatronizing() then
                    table.insert(agent_supports, {agent, DemocracyUtil.TryMainQuestFn("GetSupportForAgent", agent)})
                    if agent:KnowsPlayer() then
                        table.insert(recognized_people, agent)
                        cxt.enc.scratch.know_at_least_one = true
                    else
                        agent:GenerateLocTable()
                        table.insert(unrecognized_descs, agent.loc_table.a_desc)
                    end
                end
            end

            if #recognized_people > 0 then
                cxt:Dialog("DIALOG_RECOGNIZE_PEOPLE", recognized_people)
            end

            if #unrecognized_descs > 0 then
                cxt:Dialog("DIALOG_UNRECOGNIZE_PEOPLE", unrecognized_descs)
            end

            cxt:Dialog("DIALOG_INTERVIEW")

            local BEHAVIOUR_INSTANCE = shallowcopy(DemocracyUtil.BEHAVIOURS.INTERVIEWER_BOSS)
            BEHAVIOUR_INSTANCE.params = {}
            cxt:GetAgent():SetTempNegotiationBehaviour(BEHAVIOUR_INSTANCE)

            local function ResolvePostInterview()
                local agent_response = {}
                cxt.quest.param.num_likes = 0
                cxt.quest.param.num_dislikes = 0
                for i, data in ipairs(agent_supports) do
                    local current_support = DemocracyUtil.TryMainQuestFn("GetSupportForAgent", data[1])
                    local support_delta = current_support - data[2] + RELATION_OFFSET[data[1]:GetRelationship()] - DemocracyUtil.GetBaseRallySupport(cxt.quest:GetDifficulty() + 1) + math.random(-30, 30)
                    if support_delta > 25 then
                        table.insert(agent_response, {data[1], "likes_interview"})
                        cxt.quest.param.num_likes = cxt.quest.param.num_likes + 1
                    elseif support_delta < -25 then
                        table.insert(agent_response, {data[1], "dislikes_interview"})
                        cxt.quest.param.num_dislikes = cxt.quest.param.num_dislikes + 1
                    end
                end
                if #agent_response > 0 then
                    cxt:Dialog("DIALOG_INTERVIEW_AFTER", #agent_response)
                    for i, data in ipairs(agent_response) do
                        cxt.enc:PresentAgent(data[1], SIDE.RIGHT)
                        cxt:Quip(data[1], "post_interview", data[2])
                        data[1]:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent(data[2]))
                    end
                    if cxt.quest.param.num_likes - cxt.quest.param.num_dislikes >= 2 then
                        cxt:Dialog("DIALOG_INTERVIEW_AFTER_GOOD")
                        cxt.quest.param.good_interview = true
                        if cxt.quest.param.parent_quest then
                            cxt.quest.param.parent_quest.param.good_interview = true
                        end
                    elseif cxt.quest.param.num_likes - cxt.quest.param.num_dislikes <= -2 then
                        cxt:Dialog("DIALOG_INTERVIEW_AFTER_BAD")
                        cxt.quest.param.bad_interview = true
                        if cxt.quest.param.parent_quest then
                            cxt.quest.param.parent_quest.param.bad_interview = true
                        end
                    end
                end
            end
            cxt:Opt("OPT_DO_INTERVIEW")
                :Fn(function(cxt)
                    local METRIC_DATA =
                    {
                        player_data = TheGame:GetGameState():GetPlayerState(),
                    }

                    DemocracyUtil.SendMetricsData("DAY_2_BOSS_START", METRIC_DATA)
                    TheGame:SetTempMusicOverride("DEMOCRATICRACE|event:/democratic_race/music/negotiation/interview", cxt.enc)
                end)
                :Negotiation{
                    flags = NEGOTIATION_FLAGS.WORDSMITH,
                    situation_modifiers = {
                        { value = 20, text = cxt:GetLocString("SIT_MOD") }
                    },
                    reason_fn = function(minigame)
                        return loc.format(cxt:GetLocString("NEGOTIATION_REASON"), BEHAVIOUR_INSTANCE.params and BEHAVIOUR_INSTANCE.params.questions_answered or 0 )
                    end,
                    suppressed = cxt.quest.param.party_pets,
                    on_success = function(cxt, minigame)
                        local questions_answered = (BEHAVIOUR_INSTANCE.params and BEHAVIOUR_INSTANCE.params.questions_answered or 0)
                        cxt:Dialog("DIALOG_INTERVIEW_SUCCESS")
                        local support = DemocracyUtil.GetBaseRallySupport(cxt.quest:GetDifficulty() + 1) - 4
                        support = support + math.floor(questions_answered / 2)
                        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", support, "COMPLETED_QUEST_MAIN")
                        -- Big calculations that happens.
                        ResolvePostInterview()
                        cxt.quest:Complete()
                        -- cxt.quest:Complete("do_interview")
                        -- cxt.quest:Activate("return_to_advisor")
                        local METRIC_DATA =
                        {
                            player_data = TheGame:GetGameState():GetPlayerState(),
                            questions_answered = questions_answered,
                            num_likes = cxt.quest.param.num_likes,
                            num_dislikes = cxt.quest.param.num_dislikes,
                            result = "WIN",
                        }
                        DemocracyUtil.SendMetricsData("DAY_2_BOSS_END", METRIC_DATA)

                        StateGraphUtil.AddEndOption(cxt)
                    end,
                    on_fail = function(cxt)
                        local questions_answered = (BEHAVIOUR_INSTANCE.params and BEHAVIOUR_INSTANCE.params.questions_answered or 0)
                        local METRIC_DATA =
                        {
                            player_data = TheGame:GetGameState():GetPlayerState(),
                            questions_answered = questions_answered,
                            num_likes = cxt.quest.param.num_likes,
                            num_dislikes = cxt.quest.param.num_dislikes,
                            result = "LOSE",
                        }
                        DemocracyUtil.SendMetricsData("DAY_2_BOSS_END", METRIC_DATA)
                        cxt:Dialog("DIALOG_INTERVIEW_FAIL")
                        -- you can't recover from a failed interview. it's instant lose.
                        DemocracyUtil.AddAutofail(cxt, false)
                    end,
                }
        end)
-- TODO: Rework this
-- QDEF:AddConvo("return_to_advisor", "primary_advisor")
--     :AttractState("STATE_TALK")
--         :Loc{
--             DIALOG_INTRO = [[
--                 agent:
--                 {good_interview?
--                     [p] well done!
--                     im impressed by your work today.
--                 }
--                 {bad_interview?
--                     [p] I'm a bit disappointed by you.
--                     i can't believe you throw away a good opportunity like that.
--                 }
--                 {not (good_interview or bad_interview)?
--                     [p] you did good.
--                     hopefully that will be good enough.
--                 }
--                     !give
--                     here's your pay.
--             ]],
--             DIALOG_INTRO_PST = [[
--                 agent:
--                     [p] go to sleep when you're ready.
--                     i promise there's not going to be an assassin tonight.
--             ]],
--         }
--         :Fn(function(cxt)
--             cxt:Dialog("DIALOG_INTRO")
--             local money = DemocracyUtil.TryMainQuestFn("CalculateFunding")
--             cxt.enc:GainMoney(money)
--             if cxt.quest.param.good_interview and cxt.quest:GetCastMember("primary_advisor"):GetRelationship() < RELATIONSHIP.LOVED then
--                 cxt.quest:GetCastMember("primary_advisor"):OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("likes_interview"))
--             elseif cxt.quest.param.bad_interview and cxt.quest:GetCastMember("primary_advisor"):GetRelationship() > RELATIONSHIP.HATED then
--                 cxt.quest:GetCastMember("primary_advisor"):OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("dislikes_interview"))
--             end
--             cxt.quest:Complete()
--             cxt:Dialog("DIALOG_INTRO_PST")
--         end)
