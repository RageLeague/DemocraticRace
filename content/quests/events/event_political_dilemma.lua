local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,

    on_init = function(quest)
        local issues = DemocracyConstants.issue_data
        quest.param.issue = table.arraypick(copyvalues(issues))
        quest.param.issue_name = quest.param.issue:GetLocalizedName()
        quest.param.pos_stance_txt = quest.param.issue.stances[2]:GetLocalizedDesc()
        quest.param.neg_stance_txt = quest.param.issue.stances[-2]:GetLocalizedDesc()
        quest:AssignCastMember("extremist_pos")
        quest:AssignCastMember("extremist_neg")
    end,
}
:AddCast{
    cast_id = "extremist_pos",
    when = QWHEN.MANUAL,
    condition = function(agent, quest)
        return quest.param.issue:GetAgentStanceIndex(agent) >= 2
    end,
}
-- too lazy to add fallbacks.
:AddCast{
    cast_id = "extremist_neg",
    when = QWHEN.MANUAL,
    condition = function(agent, quest)
        return quest.param.issue:GetAgentStanceIndex(agent) <= -2
    end,
}

QDEF:AddConvo()
    :ConfrontState("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * [p] you saw two people arguing about {issue_name}
                extremist_neg:
                    !right
                extremist_pos:
                    !left
                    !angry_accuse
                    {pos_stance_txt#angrify}
                extremist_neg:
                    !angry_accuse
                    %confront_argument
                    {neg_stance_txt#angrify}
                * as their debate gets heated, they sees you.
                player:
                    !left
                extremist_pos:
                    !right
                    oi you!
                extremist_neg:
                    !right
                    settle this!
            ]],
            OPT_SIDE_WITH = "Side with {1#agent}",
            DIALOG_SIDED = [[
                other:
                    !right
                player:
                    !left
                    i have to say, i must agree with {agent} here.
            ]],
        }
        :Fn(function(cxt)
            cxt.quest:Complete()
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_SIDE_WITH", cxt.quest:GetCastMember("extremist_pos"))
            cxt:Opt("OPT_SIDE_WITH", cxt.quest:GetCastMember("extremist_neg"))
        end)