local INTERVIEWER_BEHAVIOR = {
    QUESTION_STACKS = {4, 3, 2, 1},
    OnInit = function( self, difficulty )
        -- self.bog_boil = self:AddCard("bog_boil")
        local relationship_delta = self.agent and (self.agent:GetRelationship() - RELATIONSHIP.NEUTRAL) or 0
        self:SetPattern( self.BasicCycle )
        local modifier = self.negotiator:AddModifier("INTERVIEWER")
        -- modifier.agents = shallowcopy(self.agents)
        -- modifier:InitModifiers()
        self.cont_question_card = self:AddCard("contemporary_question_card")
        self.cont_question_card.stacks = self.QUESTION_STACKS[
            math.min( GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY ) or 1,
            #self.QUESTION_STACKS) ]

        self.modifier_picker = self:MakePicker()

        local _, card = self.modifier_picker:AddArgument("LOADED_QUESTION", 2 + math.max(0, -relationship_delta))
        card.stacks = self.QUESTION_STACKS[
            math.min( GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY ) or 1,
            #self.QUESTION_STACKS) ]
        local _, card = self.modifier_picker:AddArgument("PLEASANT_QUESTION", 2 + math.max(0, relationship_delta))
        card.stacks = self.QUESTION_STACKS[
            math.min( GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY ) or 1,
            #self.QUESTION_STACKS) ]
        local _, card = self.modifier_picker:AddArgument("GENERIC_QUESTION", 4)
        card.stacks = self.QUESTION_STACKS[
            math.min( GetAdvancementModifier( ADVANCEMENT_OPTION.NPC_BOSS_DIFFICULTY ) or 1,
            #self.QUESTION_STACKS) ]

        if not self.params then self.params = {} end
        self.params.questions_answered = 0
        self.available_issues = copyvalues(DemocracyConstants.issue_data)
    end,
    BasicCycle = function( self, turns )
        -- Double attack every 2 rounds; Single attack otherwise.
        if self.difficulty >= 4 and turns % 2 == 0 then
            self:ChooseGrowingNumbers( 3, -1 )
        elseif turns % 2 == 0 then
            self:ChooseGrowingNumbers( 2, 0 )
        else
            self:ChooseGrowingNumbers( 1, 1 )
        end
        -- if turns == 1 then
        --     self:ChooseGrowingNumbers( 1, 2 )
        -- end
        local question_count = 0
        for i, data in self.negotiator:Modifiers() do
            if data.AddressQuestion then
                question_count = question_count + 1
            end
        end
        if turns % 3 == 1 then
            self:ChooseCard(self.cont_question_card)
            if question_count < 4 then
                self.modifier_picker:ChooseCards(1)
            end
        -- elseif turns % 3 == 2 then
        --     self.modifier_picker:ChooseCards(2)
        else
            -- self:ChooseGrowingNumbers( 1, 1 )
            self.modifier_picker:ChooseCards(question_count < 4 and 2 or 1)
        end
    end,
}

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
        table.insert(t, { agent = quest:GetCastMember("host"), location = quest:GetCastMember('theater')})
    end,
    -- on_start = function(quest)

    -- end,
    -- on_complete = function(quest)
    --     if quest:GetCastMember("primary_advisor") then
    --         quest:GetCastMember("primary_advisor"):GetBrain():SendToWork()
    --     end
    -- end,
    on_destroy = function(quest)
        quest:GetCastMember("primary_advisor"):GetBrain():SendToWork()
        if quest.param.parent_quest then
            quest.param.parent_quest.param.did_interview = true
        end
    end,
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
                    !facepalm
                    Yes really! I can't believe you didn't realize the importance of such interview.
                    Anyway, you have a few minutes before the interview starts. Try compose yourself before you go.
            ]],
            OPT_ASK_INTERVIEW = "Ask about the interview",
            DIALOG_ASK_INTERVIEW = [[
                player:
                    [p] I'm not sure what this interview is about.
                agent:
                    !dubious
                    Seriously? You are about to do it, and you don't even know how it works?
                    Unbelievable.
                player:
                    !crossed
                    I'm busy. Gathering support.
                agent:
                    !placate
                    Alright.
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
                    Try to tailor your answers based on your audience.
                player:
                    Alright.
                agent:
                    Of course, you can always just say something generic that appeals to everyone.
                    But that would take a lot of skills, and sometimes you might want to appeal to a more generic audience.
            ]],
            DIALOG_LEAVE = [[
                player:
                    Alright, I'm ready.
                    Moment of truth, here I go.
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                DemocracyUtil.PopulateTheater(cxt.quest, cxt.quest:GetCastMember("theater"), 8)
                cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
                cxt:Dialog("DIALOG_INTRO")
                cxt.quest:Complete("go_to_interview")
                cxt.quest:Activate("do_interview")
            end
            cxt:Question("OPT_ASK_INTERVIEW", "DIALOG_ASK_INTERVIEW")
            cxt:Question("OPT_ASK_AUDIENCE", "DIALOG_ASK_AUDIENCE")
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
                * There are some people you don't recognize though.
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
            SIT_MOD = "Has a lot of questions prepared for you.",
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
                    [p] I said something embarrassing and outrageous in front of everyone!
                * awkward silence.
                * oh no.
                * this embarrassment is going to cost you.
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
            DIALOG_FAIL = [[
                {good_interview?
                    * Despite the fact, the damage has already been done.
                }
                * From the meltdown back on the state, your reputation drops significantly.
                * With that, this is the end of your political campaign.
                * There is no way for you to recover from that failure.
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
                    else
                        agent:GenerateLocTable()
                        table.insert(unrecognized_descs, agent.loc_table.a_desc)
                    end
                end
            end

            cxt:Dialog("DIALOG_RECOGNIZE_PEOPLE", recognized_people)

            cxt:Dialog("DIALOG_UNRECOGNIZE_PEOPLE", unrecognized_descs)

            cxt:Dialog("DIALOG_INTERVIEW")

            local BEHAVIOUR_INSTANCE = shallowcopy(INTERVIEWER_BEHAVIOR)
            BEHAVIOUR_INSTANCE.params = {}
            cxt:GetAgent():SetTempNegotiationBehaviour(BEHAVIOUR_INSTANCE)

            local function ResolvePostInterview()
                local agent_response = {}
                cxt.quest.param.num_likes = 0
                cxt.quest.param.num_dislikes = 0
                for i, data in ipairs(agent_supports) do
                    local current_support = DemocracyUtil.TryMainQuestFn("GetSupportForAgent", data[1])
                    local support_delta = current_support - data[2] + RELATION_OFFSET[data[1]:GetRelationship()] + math.random(-40, 30)
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
                end)
                :Negotiation{
                    flags = NEGOTIATION_FLAGS.WORDSMITH,
                    situation_modifiers = {
                        { value = 20, text = cxt:GetLocString("SIT_MOD") }
                    },
                    reason_fn = function(minigame)
                        return loc.format(cxt:GetLocString("NEGOTIATION_REASON"), BEHAVIOUR_INSTANCE.params and BEHAVIOUR_INSTANCE.params.questions_answered or 0 )
                    end,
                    on_success = function(cxt, minigame)
                        local questions_answered = (BEHAVIOUR_INSTANCE.params and BEHAVIOUR_INSTANCE.params.questions_answered or 0)
                        cxt:Dialog("DIALOG_INTERVIEW_SUCCESS")
                        -- TheGame:GetDebug():CreatePanel(DebugTable(INTERVIEWER_BEHAVIOR))
                        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", questions_answered, "COMPLETED_QUEST_MAIN")
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
                        cxt:Dialog("DIALOG_INTERVIEW_FAIL")
                        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -20)
                        ResolvePostInterview()
                        local METRIC_DATA =
                        {
                            player_data = TheGame:GetGameState():GetPlayerState(),
                            questions_answered = questions_answered,
                            num_likes = cxt.quest.param.num_likes,
                            num_dislikes = cxt.quest.param.num_dislikes,
                            result = "LOSE",
                        }
                        DemocracyUtil.SendMetricsData("DAY_2_BOSS_END", METRIC_DATA)
                        -- you can't recover from a failed interview. it's instant lose.
                        cxt:Dialog("DIALOG_FAIL")
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
