local QDEF = QuestDef.Define
{
    title = "Parasite Killer",
    desc = "Bring {escort} to someone that can get rid of {escort.hisher} parasite.",

    qtype = QTYPE.SCENARIO,
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
    on_complete = function(quest)
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
            left:
                !exit
            right:
                !exit
            * {agent} get right to work.
            * It's a bit gruesome, but it gets the job done, and {escort} is now free of parasites.
        ]],
    }
    :Hub(function(cxt, who)
        if table.arraycontains(cxt.quest:GetQuestDef().ALLOWED_HEALER, who:GetContentID()) then
            cxt:Opt("OPT_CURE")
                :Dialog("DIALOG_CURE")
                :ReceiveOpinion(OPINION.SAVED_LIFE, nil, "escort")
                :CompleteQuest()
        end
    end)
