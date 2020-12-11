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
                * Just as the trek across the wet loam makes you question if this is all worth it, you notice 2 people.
                * You hear just enough buzzwords to get the gist of it, and both of them are spitting bricks about it.
                extremist_neg:
                    !right
                extremist_pos:
                    !left
                    !angry_accuse
                    If we don't get {1#pol_stance}, Havaria will be doomed!
                extremist_neg:
                    !angry_accuse
                    %confront_argument
                    Oh shut it you bogan.
                    What we actually need is {2#pol_stance}, and that is final!
                * You slowly back away from where you could hear them talking, trying to stay out of it.
                * Unfortunately, out of earshot doesn't neccesarily mean out of eyeshot. 
                player:
                    !left
                extremist_pos:
                    !right
                    HEY, YOU THERE. HELP US SETTLE THIS.
                extremist_neg:
                    !right
                    We've been arguing for hours about which ideology is better.
                    Give us a tie-breaking vote, I really want to go home.
            ]],
            OPT_SIDE_WITH = "Side with {1#agent}",
            DIALOG_SIDED = [[
                other:
                    !right
                player:
                    !left
                    Out of the both of you, {agent} has the better idea.
                other:
                    !surprised
                    What? You would rather side with {agent} than me?
                    Do you want Havaria to crash and burn?
                agent:
                    !left
                    Clearly {player.heshe} knows what's up!
                    As only a true intellectual of our time period could know.
                other:
                    !angry_accuse
                    More like pseudo-intellectual. You're both what's wrong with Havaria.
                    !exit
                * {other.HeShe} leaves.
                * {agent.hisher}'s shoulder slump with a loss of tension, and breathes a sigh of relief.
                player:
                    !left
                agent:
                    !right
                    You have no idea how long we've been going at that.
                    We've been feuding about that since we met each other this morning.
                    Which reminds me. Better get back to the homestead.
                    See you!
                    !exit
                * {agent} also left, leaving you alone to ponder whether you made the right decision or not.
            ]],
            OPT_CHOOSE_NO_ONE = "Choose no one",
            DIALOG_CHOOSE_NO_ONE = [[
                player:
                    Look, i'm flattered, but this really isn't my place to answer.
                extremist_neg:
                    !right
                    !surprised
                    Ah come on.
                extremist_pos:
                    !left
                    !hips
                    $happyCocky
                    Was hoping for the grifter'd back you up?
                extremist_neg:
                    Of course not! I have more dignity than that. You on the other hand...
                extremist_pos:
                    Now you listen here you-
                * You scramble away, letting them yammer on 'till sundown. Better to stay neutral than getting involved, right?
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
