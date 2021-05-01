
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

DemocracyUtil.AddAdvisors(QDEF)