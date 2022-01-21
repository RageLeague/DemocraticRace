local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    precondition = function(quest)
        local issues = DemocracyConstants.issue_data
        quest.param.issue = table.arraypick(copyvalues(issues))
        assert_warning(is_instance(quest.param.issue, DemocracyClass.IssueLocDef), "Invalid class for quest.param.issue")
        return is_instance(quest.param.issue, DemocracyClass.IssueLocDef), "Invalid class for quest.param.issue"
    end,
    on_init = function(quest)

    end,
}
:AddCast{
    cast_id = "extremist_pos",
    -- when = QWHEN.MANUAL,
    condition = function(agent, quest)
        return quest.param.issue:GetAgentStanceIndex(agent) >= 2, loc.format("Req stance 2(has {1})", quest.param.issue:GetAgentStanceIndex(agent))
    end,
}
-- too lazy to add fallbacks.
:AddCast{
    cast_id = "extremist_neg",
    -- when = QWHEN.MANUAL,
    condition = function(agent, quest)
        return quest.param.issue:GetAgentStanceIndex(agent) <= -2, loc.format("Req stance -2(has {1})", quest.param.issue:GetAgentStanceIndex(agent))
    end,
}

QDEF:AddConvo()
    :ConfrontState("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * Just as the boredom of trekking across the loam makes you consider why you're doing this, you see two people arguing.
                * You hear just enough buzzwords to realize it's about {issue_name}, and both of them are spitting bricks about it.
                * You try your best to disengage with it.
                * Keyword: try.
                player:
                    !left
                extremist_pos:
                    !right
                    Over there, Grifter!
                extremist_neg:
                    !right
                    We've been here for hours trying to figure out whose correct in their ideology.
                    Now, of course, a sensible individual like yourself knows that Havaria needs {2#pol_stance}.
                extremist_pos:
                    !left
                    Oh shut it you Bogan!
                    Pseudo-intellectuals like you are what's ruining Havaria!
                    What we really need is {1#pol_stance}.
                player:
                    !left
                extremist_neg:
                    This isn't going anywhere.
                    Help us settle this, will you?
            ]],
            OPT_SIDE_WITH = "Side with {1#agent}",
            DIALOG_SIDED = [[
                other:
                    !right
                player:
                    !left
                    Out of the both of you, {agent} is in the right.
                other:
                    !surprised
                    What? You would rather side with {agent} than me?
                    That's just so wrong!
                    Do you want Havaria to crash and burn?
                agent:
                    !left
                    You're the one who's in the wrong here.
                    See? The grifter also thinks that my idea is correct.
                other:
                    !angry_accuse
                    I won't forget this!
                    !exit
                * {other.HeShe} leaves.
                * {agent} slumps {agent.hisher} shoulders and lets out a sigh of relief
                player:
                    !left
                agent:
                    !right
                    You have no idea how long we've been debating about that.
                    Thank you, although I also need to get going.
                    See you!
                    !exit
                * {agent} also left, leaving you alone to ponder whether you made the right decision or not.
            ]],
            OPT_CHOOSE_NO_ONE = "Choose no one",
            DIALOG_CHOOSE_NO_ONE = [[
                player:
                    Look, I'm flattered, really I am.
                    But I don't think this kind of drama is my kind of place to weigh in.
                extremist_neg:
                    !right
                    !surprised
                    What?
                extremist_pos:
                    !left
                    !hips
                    $happyCocky
                    Was hoping for the grifter will back you up? Well too bad! {player.HeShe} isn't.
                extremist_neg:
                    !angry
                    Of course not!
                * You left those two be. Better to stay neutral than getting involved, right?
            ]],
        }
        :Fn(function(cxt)
            cxt.quest:Complete()
            cxt.quest.param.issue_name = cxt.quest.param.issue:GetLocalizedName()
            -- cxt.quest.param.pos_stance = :GetLocalizedName()
            -- cxt.quest.param.neg_stance = :GetLocalizedName()
            cxt:Dialog("DIALOG_INTRO", cxt.quest.param.issue.stances[2], cxt.quest.param.issue.stances[-2])

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
                :DeltaSupport(-2)
                -- :ReceiveOpinion(OPINION.DISAPPROVE_MINOR, nil, cxt.quest:GetCastMember("extremist_pos"))
                -- :ReceiveOpinion(OPINION.DISAPPROVE_MINOR, nil, cxt.quest:GetCastMember("extremist_neg"))
                :Travel()
        end)
