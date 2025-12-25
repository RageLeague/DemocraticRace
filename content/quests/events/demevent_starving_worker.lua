-- Stolen, I mean, "inspired" by the event in rook's story
local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    on_init = function(quest)
        quest.param.wants_job = math.random() > .5
        -- Manually spawn because QuestUtil.SpawnInactiveQuest doesn't force spawn quests
        local ok, result, quest_state = QuestUtil.TrySpawnQuest("DEMSIDE_REVENGE_STARVING_WORKER",
            {
                cast = {
                    worker = quest:GetCastMember("worker"),
                    foreman = quest:GetCastMember("foreman")
                }
            }, true)
        if ok and result then
            quest.param.request_quest = quest_state
        else
            quest.param.traced_q = quest_state
        end
        quest:GetCastMember("worker"):OpinionEvent(OPINION.GOT_FIRED, nil, quest:GetCastMember("foreman"))
    end,
}
:AddCast{
    cast_id = "foreman",
    condition = function(agent, quest)
        if agent:GetBrain() and agent:GetBrain():GetWorkPosition() then
            local work_pos = agent:GetBrain():GetWorkPosition()
            if work_pos:IsBoss() and work_pos.id == "foreman" then
                return true
            end
        end
        return false
    end,
    on_assign = function(quest, agent)
        if agent:GetBrain() and agent:GetBrain():GetWorkPosition() then
            quest.param.foreman_workplace = agent:GetBrain():GetWorkPosition():GetLocation()
        end
        quest:AssignCastMember("worker")
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent(table.arraypick{"FOREMAN","ADMIRALTY_CLERK","SPARK_BARON_TASKMASTER"}) )
    end,
    -- on_assign = function(quest, agent)
    --     quest:AssignCastMember("worker")
    -- end,
}
:AddCast{
    cast_id = "worker",
    when = QWHEN.MANUAL,
    cast_fn = function(quest, t)
        local boss = quest:GetCastMember("foreman")
        if boss and quest.param.foreman_workplace then
            for id, position in quest.param.foreman_workplace:WorkPositions() do
                if position and position:GetRole() == CHARACTER_ROLES.LABOUR and position:GetAgent() then
                    table.insert(t, position:GetAgent())
                end
            end
        end
    end,
    on_assign = function(quest, agent)
        if agent:GetBrain():GetWorkPosition() then
            agent:GetBrain():GetWorkPosition():Fire()
        end
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent(table.arraypick{"LABORER","HEAVY_LABORER","RISE_REBEL"}) )
    end,
}
-- :AddDefCastSpawn("worker", {"LABORER", "HEAVY_LABORER", "RISE_REBEL"})
-- :AddDefCast("foreman", {"FOREMAN", "SPARK_BARON_TASKMASTER", "ADMIRALTY_CLERK"})
:AddOpinionEvents{
    gave_little =
    {
        delta =
        {
            relationship_delta =
            {
                [RELATIONSHIP.LOVED] = RELATIONSHIP.LIKED,
                [RELATIONSHIP.NEUTRAL] = RELATIONSHIP.LIKED,
                [RELATIONSHIP.DISLIKED] = RELATIONSHIP.NEUTRAL,
                [RELATIONSHIP.HATED] = RELATIONSHIP.DISLIKED,
            },
        },

        txt = "Gave spare change when they asked for help",
    },
    gave_big =
    {
        delta = OPINION_DELTAS.MAJOR_GOOD,
        txt = "Gave a lot of money when they asked for help",
    },
    gave_nothing =
    {
        delta = OPINION_DELTAS.TO_DISLIKED,
        txt = "Gave nothing when they asked for help",
    },
}

QDEF:AddConvo()
    :ConfrontState("CONFRONT", function() return true end)
        :Loc{
            DIALOG_INTRO = [[
                * A lone figure is loitering at the side of the road.
                player:
                    !left
                agent:
                    !right
                    $miscDepressed
                    Hey, pal. You got a shill to spare for an out-of-work laborer?
                    $angryDefault
                    I've been fired from my post for speaking ill against my foreman, because {foreman.heshe} extended my shift without increasing my pay.
                    Now I can't find any work.
                *** This is different from the event in Rook's story, trust me.
            ]],
            -- I don't know if we will use this. In the future, maybe one of the ways to deal with someone who hate you
            -- or a quest target would be using the Rise's tribunal or something, and this might not make sense.
            -- Keeping this in just in case.
            OPT_ASK_ABOUT_RISE = "Ask why the Rise won't help.",
            DIALOG_ASK_ABOUT_RISE = [[
                player:
                    I thought the Rise's whole shtick was about helping you workers?
                    Where are they in your dire time of need?
                agent:
                    Ha! They're just proving me right.
                    Those pseudo-intellectual sludge suckers are looking out for themselves.
                    No one in Havaria is ever that generous.
            ]],
            OPT_ASK_ABOUT_FOREMAN = "Ask about the foreman",
            DIALOG_ASK_ABOUT_FOREMAN = [[
                player:
                    What kind of character is your foreman like?
                agent:
                    Oh {foreman.heshe} is just the worst!
                    If I had my way, I'd be at the labor offices and running {foreman.himher} out of a job.
                player:
                    So this foreman is unfair and made you hate them.
                    To be honest, that sounds like almost every foreman.
                    How about you give a name? I might know 'em.
                agent:
                    {foreman}.
            ]],
            OPT_OFFER_HELP = "Offer to deal with the foreman",
            DIALOG_OFFER_HELP = [[
                player:
                    As a politician, I can't just stand by and see the people suffer.
                    I'll help you.
                agent:
                    Really?
                    If you can help me, I owe you big time.
                player:
                    !thought
                    So what can I do to help?
                agent:
                    Make sure {foreman} treat the workers right.
                    Or punish {foreman.himher} for {foreman.hisher} wrongdoing, whichever is easier for you.
                    But please, try not to kill {foreman}. People might think I'm the killer, considering I have a motive.
                player:
                    Okay, I'll see what I can do.
                agent:
                    Well, thank you for your effort.
                    Maybe you can bring real change to this Hesh-forsaken place.
            ]],

            OPT_GIVE_A_LITTLE = "Give {agent} some spare change",
            DIALOG_GIVE_A_LITTLE = [[
                player:
                    Here. Go get some noodles or something.
                agent:
                    $happyResigned
                    Thanks. Every little bit helps.
            ]],

            OPT_GIVE_A_LOT = "Give {agent} a lot",
            DIALOG_GIVE_A_LOT = [[
                player:
                    It is a shame what happened to you.
                    !thumb
                    As a politician, I vow to make sure no one has to starve for something that is not their fault.
                    !give
                    Here, eat well.
                agent:
                    $happyAmazed
                    !take
                    Wow, really? You're alright, you know that?
                    If you ever need anything, just ask!
            ]],

            OPT_OFFER_A_JOB = "Offer to hire {agent} as protection",
            DIALOG_OFFER_JOB = [[
                player:
                {not offered_to_help?
                    As a politician, I don't advocate for giving people free money.
                    But! I can hire you as a bodyguard, and you would be working legitimately.
                }
                {offered_to_help?
                    I will help you with your situation later.
                    But right now, I can help you by hiring you as a bodyguard.
                }
            ]],
            DIALOG_WANT_JOB = [[
                agent:
                    Well, it beats walking around asking for people's money.
                    I agree with your proposal.
            ]],

            OPT_HIRE =  "Hire {agent}",
            OPT_NO_HIRE = "Don't hire {agent}",
            DIALOG_TAKE_JOB = [[
                player:
                    Deal. Let's go.
            ]],
            DIALOG_NO_TAKE_JOB = [[
                player:
                    $neutralDubious
                    I'm having second thoughts, sorry.
            ]],
            DIALOG_NO_WANT_JOB = [[
                agent:
                    $angryHostile
                    Do I look like a grifter to you? I'm not risking my neck for a few measly shills.
            ]],

            OPT_SAY_NO = "Refuse to give {agent} anything",

            DIALOG_SAY_NO = [[
                player:
                {not offered_to_help?
                    Look, I can't just go around giving people free stuff.
                    If I give everyone things for free, then I would be draining my coffers at an extremely rapid rate.
                agent:
                    !spit
                    Pfft. All you care about is your "coffers".
                    What other people can do for you rather than what you can do for Havaria.
                    It's so hard to find someone who truly cares about others.
                player:
                    !dubious
                    Are you new in Havaria or something?
                agent:
                    !angry_accuse
                    I will remember this the next time we meet.
                    !exit
                * You might just have made an enemy who you really don't want to be with.
                player:
                    !shrug
                * What are the odds of that, though?
                }
                {offered_to_help?
                    I will help you with the foreman problem, but I am not a charity.
                    I can't just go around and give people free stuff.
                agent:
                    I will believe your true intention once you actually deal with the foreman.
                    !spit
                    Right now, you are just a stingy politician with empty promises.
                    Good luck with your quest to take down the foreman! We will meet again soon.
                    !exit
                player:
                    I am already helping you! Beggars can't be choosers, you know!
                * Not exactly something you should say to make a beggar like you.
                * But still, you can help this person out, if you still want to do that.
                }
            ]],

            OPT_NO_MONEY = "Apologize for not having enough money to give",
            DIALOG_NO_MONEY = [[
                player:
                    I would help you, but uhh...
                    I'm as broke as you, bud.
                agent:
                    Ah...
                    Well, thanks for the effort I guess.
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)

            cxt.quest:Complete()
            if cxt:FirstLoop() then
                cxt.quest:GetCastMember("worker"):MoveToLocation(cxt.location)
                cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("worker"))
                cxt:Dialog("DIALOG_INTRO")
            end

            local SMALL_AMT = 10
            local LARGE_AMT = 75
            local HIRE_AMT = 75
            if not cxt.quest.param.asked_about_foreman then
                cxt:Opt("OPT_ASK_ABOUT_FOREMAN")
                    :Dialog("DIALOG_ASK_ABOUT_FOREMAN")
                    :Fn(function(cxt)
                        cxt.quest.param.asked_about_foreman = true
                    end)
            else
                if cxt.quest.param.request_quest and not cxt.quest.param.offered_to_help then
                    cxt:Opt("OPT_OFFER_HELP")
                        :SetQuestMark(cxt.quest.param.request_quest, cxt:GetAgent())
                        :UpdatePoliticalStance("LABOR_LAW", 1, false, true, true)
                        :Fn(function(cxt)
                            DemocracyUtil.PresentRequestQuest(cxt, cxt.quest.param.request_quest, function(cxt,quest)
                                cxt:Dialog("DIALOG_OFFER_HELP")
                                DemocracyUtil.TryMainQuestFn("UpdateStance", "LABOR_LAW", 1, false, true)
                                cxt.quest.param.offered_to_help = true
                                StateGraphUtil.AddLeaveLocation(cxt)
                            end)

                        end)
                end

                    -- spawn a side quest or something
            end

            cxt:Opt("OPT_GIVE_A_LITTLE")
                :Dialog("DIALOG_GIVE_A_LITTLE")
                :DeliverMoney(SMALL_AMT, {no_scale = true})
                :ReceiveOpinion(cxt.quest:GetQuestDef():GetOpinionEvent("gave_little"))
                :Travel()

            cxt:Opt("OPT_GIVE_A_LOT")
                :Dialog("DIALOG_GIVE_A_LOT")
                :UpdatePoliticalStance("FISCAL_POLICY", 1, false, true)
                :DeliverMoney(LARGE_AMT, {no_scale = true})
                :ReceiveOpinion(cxt.quest:GetQuestDef():GetOpinionEvent("gave_big"))
                :Travel()


            local wants_job = cxt.quest.param.wants_job and TheGame:GetGameState():IsHiringAvailable()
            if not cxt.quest.param.asked_job then
                cxt:Opt("OPT_OFFER_A_JOB")
                    :Dialog("DIALOG_OFFER_JOB")
                    :ReqRelationship( RELATIONSHIP.NEUTRAL )
                    :UpdatePoliticalStance("FISCAL_POLICY", -1, false, true)
                    :Fn(function()
                        if wants_job then
                            cxt:Dialog("DIALOG_WANT_JOB")
                            cxt:Opt("OPT_HIRE")
                                :Dialog("DIALOG_TAKE_JOB")
                                :DeliverMoney(HIRE_AMT)
                                :RecruitMember( PARTY_MEMBER_TYPE.HIRED )
                                :Travel()

                            cxt:Opt("OPT_NO_HIRE")
                                :Dialog("DIALOG_NO_TAKE_JOB")
                        else
                            cxt:Dialog("DIALOG_NO_WANT_JOB")
                        end
                        cxt.quest.param.asked_job = true
                    end)
            end
            cxt:Opt("OPT_SAY_NO")
                :Dialog( "DIALOG_SAY_NO")
                :UpdatePoliticalStance("FISCAL_POLICY", -1, false, true)
                :ReceiveOpinion(cxt.quest:GetQuestDef():GetOpinionEvent("gave_nothing"))
                :Travel()
            if cxt.player:GetMoney() < SMALL_AMT then
                cxt:Opt("OPT_NO_MONEY")
                    :Dialog("DIALOG_NO_MONEY")
                    :Travel()
            end
        end)

