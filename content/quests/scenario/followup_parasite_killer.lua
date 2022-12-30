local QDEF = QuestDef.Define
{
    title = "Parasite Killer",
    desc = "Bring {escort} to someone that can get rid of {escort.hisher} parasite.",

    qtype = QTYPE.SCENARIO,
    on_complete = function(quest)
        quest:GetCastMember("escort"):Dismiss()
    end,
    events = {
        base_difficulty_change = function(quest, new_diff, old_diff)
            quest:SetRank(new_diff)
        end,
    },
}
:AddObjective{
    id = "start",
    title = "Find a medic",
    desc = "Some people have the ability to get rid of parasites. Bring {escort} to one of them.",
    state = QSTATUS.ACTIVE,
    mark = function(quest, t, in_location)
        if in_location then
            for _, agent in TheGame:GetGameState():GetPlayerAgent():GetLocation():Agents() do
                if table.arraycontains(quest:GetQuestDef().ALLOWED_HEALER, agent:GetContentID()) then
                    table.insert(t, agent)
                end
            end
        end
    end,
}
:AddCast{
    cast_id = "escort",
    no_validation = true,
    events = {
        agent_retired = function(quest, agent)
            quest:Fail()
        end,
        dismissed = function( quest )
            quest:Fail()
            -- if not quest:GetCastMember("escort"):IsRetired() then
            --     quest:GetCastMember("escort"):Kill()
            -- end
        end,
    },
}

QDEF.ALLOWED_HEALER =
{
    "PRIEST",
    "PRIEST_PROMOTED",
    "SPARK_BARON_PROFESSIONAL",
    "JAKES_SMUGGLER",
    "PLOCKA",
    "ENDO",
    "RAKE"
}

QDEF:AddConvo()
    :Loc{
        OPT_CURE = "Let {agent} cure {escort}'s infection",
        DIALOG_CURE = [[
            {is_giver and not package_delivered?
                player:
                    [p] Before I give you the package, here's {escort}.
                    {escort.gender:He's|She's|They've} been infected with the bog parasites, and perhaps you can help.
                escort:
                    !left
                    !injured
                agent:
                    !surprised
                    Hesh! That looks horrible!
                    I- I'll see what I can do. Just give me a sec.
            }
            {is_giver and package_delivered?
                player:
                    [p] Here's {escort}.
                    Like I said, {escort.gender:he looks|she looks|they look} really bad.
                escort:
                    !left
                    !injured
                agent:
                    I- I'll see what I can do. Just give me a sec.
            }
            {not is_giver?
                player:
                    [p] From my understanding, you can get rid of {escort}'s parasite, yes?
                agent:
                    !agree
                    That's right.
                {not cult_of_hesh?
                    agent:
                        Provided that {escort.heshe} can pay, of course.
                    escort:
                        !left
                        !injured
                        Of course. I don't know what else I expected.
                }
                {cult_of_hesh?
                    escort:
                        !left
                        !injured
                        Free of charge?
                    agent:
                        Of course. Hesh prefers its meal untainted by the heresy that is the Bog.
                    escort:
                        I guess I can't complain, given that you are getting rid of my parasites for free.
                        But honestly, I would rather pay shills.
                }
            }
            left:
                !exit
            right:
                !exit
            * {agent} get right to work.
            * It's a bit gruesome, but it gets the job done, and {escort} is now free of parasites.
            agent:
                !right
            escort:
                !left
                !injured
                Ow, it hurts so much!
                At least my parasites are gone.
            agent:
                Now, you just need to rest well, and you can go back to your old self.
            escort:
                Thank you. You saved my life.
            player:
                !left
            escort:
                !right
                And you too.
                Without your help, I would probably slowly dying away in my hovel.
            player:
                My pleasure.
            agent:
                !right
            * {escort} left, leaving you with {agent}.
        ]],
    }
    :Hub(function(cxt, who)
        if who and table.arraycontains(cxt.quest:GetQuestDef().ALLOWED_HEALER, who:GetContentID()) then
            cxt:Opt("OPT_CURE")
                :SetQuestMark()
                :Fn(function(cxt)
                    if cxt.quest.param.giver == who then
                        cxt.enc.scratch.is_giver = true
                    end
                end)
                :Dialog("DIALOG_CURE")
                :ReceiveOpinion(OPINION.SAVED_LIFE, nil, "escort")
                :Fn(function(cxt)
                    cxt:GetCastMember("escort"):OpinionEvent(OPINION.SAVED_LIFE, nil, cxt:GetAgent())
                    cxt.quest.param.curer_agent = cxt:GetAgent()
                end)
                :CompleteQuest()
        end
    end)
