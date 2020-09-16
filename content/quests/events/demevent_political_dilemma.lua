local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    precondition = function(quest)
        local issues = DemocracyConstants.issue_data
        quest.param.issue = table.arraypick(copyvalues(issues))
        quest.param.issue_name = quest.param.issue:GetLocalizedName()
        quest.param.pos_stance_txt = quest.param.issue.stances[2]:GetLocalizedDesc()
        quest.param.neg_stance_txt = quest.param.issue.stances[-2]:GetLocalizedDesc()
        return true
    end,
    on_init = function(quest)

    end,
}
:AddCast{
    cast_id = "extremist_pos",
    -- when = QWHEN.MANUAL,
    condition = function(agent, quest)
        return quest.param.issue:GetAgentStanceIndex(agent) >= 2
    end,
}
-- too lazy to add fallbacks.
:AddCast{
    cast_id = "extremist_neg",
    -- when = QWHEN.MANUAL,
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
                other:
                    !angry
                    what?!
                agent:
                    !left
                    nananananana, hahahahahaha.
                other:
                    i'll remember this.
                player:
                    !left
                agent:
                    !right
                    so will i.
                    thanks, {player}!
                * you made some friends, but that means taking sides. hopefully your friendship lasts.
            ]],
            OPT_CHOOSE_NO_ONE = "Choose no one",
            DIALOG_CHOOSE_NO_ONE = [[
                player:
                    screw you both, i ain't taking sides!
                extremist_neg:
                    !right
                    wtf?
                extremist_pos:
                    !right
                    fine! have it your way then.
                * you might made some enemies, but at least you stayed neutral.
                * right?
            ]],
        }
        :Fn(function(cxt)
            cxt.quest:Complete()
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_SIDE_WITH", cxt.quest:GetCastMember("extremist_pos"))
                :Fn(function(cxt)
                    cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("extremist_pos"))
                    cxt:ReassignCastMember("other", cxt.quest:GetCastMember("extremist_neg"))
                end)
                :Dialog("DIALOG_SIDED")
                :ReceiveOpinion(OPINION.DISAPPROVE_MINOR, nil, cxt.quest:GetCastMember("extremist_neg"))
                :ReceiveOpinion(OPINION.APPROVE, nil, cxt.quest:GetCastMember("extremist_pos"))
                :UpdatePoliticalStance(cxt.quest.param.issue, 2, true, true)
                :Travel()
            cxt:Opt("OPT_SIDE_WITH", cxt.quest:GetCastMember("extremist_neg"))
                :Fn(function(cxt)
                    cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("extremist_neg"))
                    cxt:ReassignCastMember("other", cxt.quest:GetCastMember("extremist_pos"))
                end)
                :Dialog("DIALOG_SIDED")
                :ReceiveOpinion(OPINION.DISAPPROVE_MINOR, nil, cxt.quest:GetCastMember("extremist_pos"))
                :ReceiveOpinion(OPINION.APPROVE, nil, cxt.quest:GetCastMember("extremist_neg"))
                :UpdatePoliticalStance(cxt.quest.param.issue, -2, true, true)
                :Travel()
            cxt:Opt("OPT_CHOOSE_NO_ONE")
                :Dialog("DIALOG_CHOOSE_NO_ONE")
                :ReceiveOpinion(OPINION.DISAPPROVE_MINOR, nil, cxt.quest:GetCastMember("extremist_pos"))
                :ReceiveOpinion(OPINION.DISAPPROVE_MINOR, nil, cxt.quest:GetCastMember("extremist_neg"))
                :Travel()
        end)