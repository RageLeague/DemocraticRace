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
                    !wave
                    I found {escort} for you. I also found why I had to find {escort.himher}.
                escort:
                    !left
                    !injured
                    Hi, boss. Think you could help me out?
                giver:
                    !hips
                    Well, {escort}. Do you want this docked from your pay <i>now</> or <i>later</>?
                escort:
                    !injuredshrug
                    Whichever gets you to work sooner. I don't exactly have time to haggle here. 
                giver:
                    !placate
                    Alright alright, let's get started.
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
                    !hips
                    Word on the vine says you have expertise in parasites from the Bog.
                agent:
                    !agree
                    That's right.
                player:
                    !overthere
                    Well, here's a new patient for you. Can you help?
                escort:
                    !left
                    !injured
                agent:
                    !happy
                    Of course I can help!
                {not cult_of_hesh?
                    agent:
                        ...
                        !neutral
                        ...
                        Cash or Credit?
                    escort:
                        !injuredpalm
                        Of course. I don't know what else I expected.
                    agent:
                        !shrug
                        Hey, you don't go to Bog college just to brag about it. 
                        I'll keep the scarring to a minimum, I'll tell you that.
                        !eureka
                        But we can work that out later. Time to cauterize.
                }
                {cult_of_hesh?
                    escort:
                        Free of charge?
                    agent:
                        Of course. Hesh prefers its meal untainted by the heresy that is the Bog.
                        !think
                        We might have to shave you down for the salt-soak, though.
                    escort:
                        !taken_aback
                        All my hair?!
                    agent:
                        !happy
                        Don't worry, we'll glue it back on!
                        !eureka
                        Now let's get started. 
                }
            }
            left:
                !exit
            right:
                !exit
            ]],
    
            DIALOG_MEDICAL_MAGIC = [[
                * {agent} get right to work.
                * It's a bit gruesome, but one by one the growths recede, and whatever medical magic gets performed cures {escort} completely.
            ]],
    
            DIALOG_CURE_PST = [[
                agent:
                    !right
                escort:
                    !left
                    !injured
                agent:
                    !happy
                    There you go, healthy as a tadpole!
                escort:
                    A tadpole in a lot of pain, mind you.
                agent:
                    Oh hush. The pain's keeping you upright and alive right now.
                player:
                    !left
                escort:
                    !right
                    Thank you, {player}.
                    Without your help, I would probably slowly dying away in my hovel.
                player:
                    My pleasure.
                agent:
                    !right
                    !point
                    Now, remember to keep pressure off your neck and shoulder blades. And drink a lot of water.
                * {escort} stumbles away, looking a little more confident with each step. You're left with {agent}.
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
                :FadeOut()
                :Dialog("DIALOG_MEDICAL_MAGIC")
                :FadeIn()
                :Dialog("DIALOG_CURE_PST")
                :ReceiveOpinion(OPINION.SAVED_LIFE, nil, "escort")
                :Fn(function(cxt)
                    cxt:GetCastMember("escort"):OpinionEvent(OPINION.SAVED_LIFE, nil, cxt:GetAgent())
                    cxt.quest.param.curer_agent = cxt:GetAgent()
                    if cxt.quest.param.bog_monster_event then
                        cxt.quest.param.bog_monster_event:Cancel()
                    end
                end)
                :CompleteQuest()
        end
    end)
