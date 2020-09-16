-- Stolen, I mean, "inspired" by the event in rook's story
local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    on_init = function(quest) 
        quest.param.wants_job = math.random() > .5
        quest.param.request_quest, quest.param.traced_q = QuestUtil.SpawnInactiveQuest("DEMSIDE_REVENGE_STARVING_WORKER",
            {cast = {worker = quest:GetCastMember("worker"), foreman = quest:GetCastMember("foreman")}})
    end,
}
:AddCast{
    cast_id = "foreman",
    condition = function(agent, quest)
        if agent:GetBrain() and agent:GetBrain():GetWorkPosition() then
            local work_pos = agent:GetBrain():GetWorkPosition()
            if work_pos:IsBoss() and work_pos.id == "foreman" then
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
        delta = 
        {
            relationship_delta = 
            {
                [RELATIONSHIP.LIKED] = RELATIONSHIP.LOVED,
                [RELATIONSHIP.NEUTRAL] = RELATIONSHIP.LOVED,
                [RELATIONSHIP.DISLIKED] = RELATIONSHIP.NEUTRAL,
                [RELATIONSHIP.HATED] = RELATIONSHIP.NEUTRAL,
            },
        },
        txt = "Gave a lot of money when they asked for help",
    },
    gave_nothing =  
    {
        delta = OPINION_DELTAS.DISLIKE,
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
            OPT_ASK_ABOUT_FOREMAN = "Ask about the foreman",
            DIALOG_ASK_ABOUT_FOREMAN = [[
                player:
                    What kind of character is your foreman like?
                agent:
                    [p] bad.
                player:
                    thanx, that's very helpful.
                    can you at least give me a name?
                agent:
                    {foreman}.
            ]],
            OPT_OFFER_HELP = "Offer to deal with the foreman",
            DIALOG_OFFER_HELP = [[
                player:
                    [p] as a politician, i can't just stand by and see the people suffer.
                    i'll help you.
                agent:
                    really?
                    if you can help me, i owe you big time.
                player:
                    what can i do to help?
                agent:
                    make sure {foreman} treat the workers right.
                    or punish {foreman.himher} for {foreman.hisher} wrongdoing, whichever is easier for you.
                    but please, try not to kill {foreman}. it will cause way too much trouble.
                player:
                    ok, i'll see what i can do.
                agent:
                    still, that doesn't solve the immediate problem.
                    i need money, right now.
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
                    [p] a shame what happened to you.
                    as a politician, i vow to make sure no one has to starve just because their boss fired them.
                    here, eat well.
                agent:
                    $happyAmazed
                    Wow, really? You're alright, you know that?
                    If you ever need anything, just ask!
            ]],

            OPT_OFFER_A_JOB = "Offer to hire {agent} as protection",
            DIALOG_OFFER_JOB = [[
                player:
                {not offered_to_help?
                    [p] as a politician, i don't advocate for giving people free stuff.
                    but! i can hire you as a bodyguard, and that wouldn't be a problem.
                }
                {offered_to_help?
                    [p] i will help you with your situation later.
                    right now, i can help you.
                    by hiring you.
                }
            ]],
            DIALOG_WANT_JOB = [[
                agent:
                    [p] sure, i guess
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
            
            OPT_SAY_NO = "Don't give {agent} anything",
            
            DIALOG_SAY_NO = [[
                player:
                {not offered_to_help?
                    [p] look, i'm not a charity.
                agent:
                    wow. really?
                    you suck.
                }
                {offered_to_help?
                    [p] i'll help what i can with your foreman problem, but i'm not a charity.
                agent:
                    thanks for you effort, but that doesn't help me right now.
                    have it your way, i guess.
                }
                
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
                :UpdatePoliticalStance("WELFARE", 1, false, true)
                :DeliverMoney(LARGE_AMT, {no_scale = true})
                :ReceiveOpinion(cxt.quest:GetQuestDef():GetOpinionEvent("gave_big"))
                :Travel()


            local wants_job = cxt.quest.param.wants_job and TheGame:GetGameState():IsHiringAvailable()
            if not cxt.quest.param.asked_job then
                cxt:Opt("OPT_OFFER_A_JOB")
                    :Dialog("DIALOG_OFFER_JOB")
                    :ReqRelationship( RELATIONSHIP.NEUTRAL )
                    :UpdatePoliticalStance("WELFARE", -1, false, true)
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
                :UpdatePoliticalStance("WELFARE", -1, false, true)
                :ReceiveOpinion(cxt.quest:GetQuestDef():GetOpinionEvent("gave_nothing"))
                :Travel()

        end)

