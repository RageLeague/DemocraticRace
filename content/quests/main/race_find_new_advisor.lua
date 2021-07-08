
local QDEF = QuestDef.Define
{
    title = "Backup Plans",
    desc = "The previous advisor cannot help you anymore. You need to find a new advisor before it's too late.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/meet_advisor.png"),

    qtype = QTYPE.STORY,

}
:AddObjective{
    id = "locate_advisor",
    title = "Find replacement advisor",
    desc = "There {1:is an advisor|are a few advisors} that {1:is|are} potentially willing to help you. See if you can find a replacement.",
    desc_fn = function(quest, fmt_str)
        return loc.format(fmt_str, quest.param.available_advisors and #quest.param.available_advisors or 1)
    end,
    on_activate = function(quest)
        quest.param.available_advisors = quest.param.available_advisors or {}
    end,
    state = QSTATUS.ACTIVE,
    mark = function(quest, t, in_location)
        for i, agent in ipairs(quest.param.available_advisors) do
            table.insert(t, agent)
        end
    end,
}

-- DemocracyUtil.AddAdvisors(QDEF)

QDEF:AddConvo("locate_advisor")
    :AttractState("STATE_ATTRACT", function(cxt)
        return cxt:GetAgent() and table.arraycontains(cxt.quest.param.available_advisors, cxt:GetAgent())
    end)
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    [p] Ah, you're back.
                {advisor_manipulate?
                    Finally see that I am the most reasonable choice?
                }
                {advisor_diplomacy?
                    Still thinking about my offer?
                }
                {advisor_hostile?
                    I told you nobody is better than me.
                }
                {not (advisor_diplomacy or advisor_manipulate or advisor_hostile)?
                    Have you finally decided to choose me instead?
                }
                    But if you decide to choose me now, it can only mean one thing.
                    That your old advisor decided to kick you out because you are incompetent.
                    Now why should I be your advisor?
            ]],
            DIALOG_LEAVE = [[
                player:
                    [p] I need to think some more.
                agent:
                    Yeah sure, whatever.
            ]],
            OPT_CONVINCE = "Convince {agent} to be your advisor",
            DIALOG_CONVINCE = [[
                player:
                    [p] I'm gonna convince you now!
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                agent:
                    [p] Seems legit.
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                agent:
                    [p] No way.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt:BasicNegotiation("CONVINCE", {})
                :OnSuccess()
                    :Fn(function(cxt)
                        DemocracyUtil.UpdateAdvisor(cxt:GetAgent(), "NEW_ADVISOR")
                    end)
                    :CompleteQuest()
                    :DoneConvo()
                :OnFailure()
                    :Fn(function(cxt)
                        table.arrayremove(cxt.quest.param.available_advisors, cxt:GetAgent())
                        if #cxt.quest.param.available_advisors <= 0 then
                            local flags = {
                                no_advisor = true,
                            }
                            DemocracyUtil.DoEnding(cxt, "no_more_advisors", flags)
                        end
                    end)
                    :DoneConvo()
            cxt:Opt("OPT_LEAVE")
                :Dialog("DIALOG_LEAVE")
                :DoneConvo()
        end)