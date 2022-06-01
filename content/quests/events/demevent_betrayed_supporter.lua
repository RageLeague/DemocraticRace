local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}
:AddCast{
    cast_id = "supporter",
    condition = function(agent, quest)
        if agent:GetRelationship() < RELATIONSHIP.NEUTRAL then
            return false, "Bad relationship"
        end
        if DemocracyUtil.GetAgentEndorsement(agent) < RELATIONSHIP.NEUTRAL then
            return false, "Bad endorsement"
        end
        if agent:GetRelationship() < RELATIONSHIP.NEUTRAL and DemocracyUtil.GetAgentEndorsement(agent) < RELATIONSHIP.NEUTRAL then
            return false, "Uninteresting relationship/endorsement"
        end

        for id, data in pairs(DemocracyConstants.issue_data) do
            local stance = data:GetAgentStanceIndex(agent)
            local player_stance = DemocracyUtil.TryMainQuestFn("GetStance", id) or 0
            if stance * player_stance < 0 then --looking for opposing stances by multiplying into a negative. two same signs or any zeroes will make this false
                print(agent.name, id, stance, player_stance)
                return true
            end
        end
        return false, "No valid stance"
    end,
}

QDEF:AddConvo()
    :ConfrontState("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You come across a concerned supporter of yours.
                player:
                    !left
                supporter:
                    !right
                    !dubious
                    {player}? Is what I heard true?
            ]],
            DIALOG_INTRO_PST = [[
                player:
                    !placate
                    Hold on. This came out of nowhere.
                    What is this all about?
                supporter:
                    I supported you in the belief that you'd make the right decisions for Havaria, but I've just heard you argue for {bad_stance#pol_stance}?
                    Surely that must be a mistake, right? You don't <i>actually</> support {bad_stance#pol_stance}, do you?
            ]],
            OPT_CHANGE = "Change to {good_stance#pol_stance} to appease {supporter}",
            DIALOG_CHANGE = [[
                player:
                    [p] You know what? You're right. {good_stance#pol_stance} is what is right for Havaria, and that is what I will campaign for from here on out.
                * Assuming you don't just flip-flop on this issue again.
                supporter:
                    !happy
                    I knew I could count on you!
            ]],
            OPT_DENY = "Insist on {bad_stance#pol_stance}",
            DIALOG_DENY = [[
                player:
                    !hips
                    [p] {bad_stance#pol_stance} is the right choice for Havaria, like it or not.
                supporter:
                    !disappoint
                    Is that so? Then maybe {player} is not the right choice for me. Goodbye.
                    !exit
            ]],
            OPT_CONVINCE = "Convince {supporter} to look past this issue",
            DIALOG_CONVINCE = [[
                player:
                    Now, just hear me out.
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                player:
                    !thumb
                    Look, I can't appease everyone with everything I do.
                    But sometimes we all need to make compromises in order to achieve things we want.
                    !overthere
                    Just look at all the other candidates. All corrupt or outright criminal.
                    But me? I am your only realistic choice.
                    If you want someone who actually cares about the Havarian people in the office, you need to look past your narrow view and at the bigger picture.
                supporter:
                    !sigh
                    As much as it pains me to admit, you are absolutely right.
                    We can't always get what we want, so we make compromises.
                player:
                    !cruel
                    I trust you would continue to support me?
                supporter:
                    Yeah, even if it means supporting someone who supports {bad_stance#pol_stance}.
                player:
                    !happy
                    That's what I like to hear.
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                player:
                    [p] See? A vote for me is a vote for a better Havaria!
                supporter:
                    What a waste of time. Goodbye, {player}.
                    !exit
            ]],
            SIT_MOD_BAD = "{supporter} is not a fan of {bad_stance#pol_stance}",
            SIT_MOD_VERY_BAD = "{supporter} loathes {bad_stance#pol_stance}",
        }
        :Fn(function(cxt)
            cxt.quest:Complete()
            cxt:TalkTo(cxt:GetCastMember("supporter"))
            local supporter = cxt:GetCastMember("supporter")
            local available_issues = DemocracyUtil.CollectIssueImportance(supporter)
            local issue_id, stance, player_stance
            while not issue_id do
                assert_warning(#copykeys(available_issues) > 0, "Agent had no valid issues to disagree on")
                issue_id = weightedpick(available_issues)
                available_issues[issue_id] = nil
                stance = DemocracyConstants.issue_data[issue_id]:GetAgentStanceIndex(supporter)
                player_stance = DemocracyUtil.TryMainQuestFn("GetStance", issue_id) or 0
                if stance * player_stance >= 0 then --again, only continue with opposing stances
                    issue_id = nil
                end
            end
            local issue = DemocracyConstants.issue_data[issue_id]
            cxt.quest.param.good_stance = issue:GetStance(stance)
            cxt.quest.param.bad_stance = issue:GetStance(player_stance)
            local sit_mod = { value = 10, text = cxt:GetLocString("SIT_MOD_BAD") }
            if (math.min(math.abs(stance), math.abs(player_stance)) == 2) then --extra hard if and only if you are both extremists in your opposed beliefs
                sit_mod = { value = 20, text = cxt:GetLocString("SIT_MOD_VERY_BAD") }
            end
            cxt:Dialog("DIALOG_INTRO")
            DemocracyUtil.QuipStance(cxt, cxt:GetCastMember("supporter"), cxt.quest.param.good_stance, "question", "loaded")
            cxt:Dialog("DIALOG_INTRO_PST")

            cxt:Opt("OPT_CHANGE")
                :Dialog("DIALOG_CHANGE")
                :UpdatePoliticalStance(issue, stance)
                :Travel()
            cxt:Opt("OPT_DENY")
                :Dialog("DIALOG_DENY")
                :ReceiveOpinion(OPINION.DISLIKE_IDEOLOGY)
                :Travel()
            cxt:BasicNegotiation("CONVINCE", {
                situation_modifiers = {sit_mod},
            })
                :OnSuccess()
                    :Travel()
                :OnFailure()
                    :ReceiveOpinion(OPINION.DISLIKE_IDEOLOGY)
                    :Travel()
        end)
