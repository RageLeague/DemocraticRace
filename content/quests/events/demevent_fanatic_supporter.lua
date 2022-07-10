local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}
:AddCast{
    cast_id = "supporter",
    condition = function(agent, quest)
        return agent:GetRelationship() >= RELATIONSHIP.NEUTRAL and agent:GetRelationship() < RELATIONSHIP.LOVED
            and DemocracyUtil.GetAgentEndorsement(agent) > RELATIONSHIP.NEUTRAL
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent())
    end,
}
:AddOpinionEvents{
    agree_full = {
        delta = OPINION_DELTAS.MAJOR_GOOD,
        txt = "Agree with them on every major issue",
    },
}
QDEF:AddConvo()
    :ConfrontState("CONF")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You come across an avid supporter of yours.
                player:
                    !left
                supporter:
                    !right
                    Hi, I'm a big fan of you!
            ]],
            DIALOG_QUESTION = [[
                supporter:
                {1:
                    [p] There are some questions I want to ask you.
                player:
                    Ah, yes. I am always happy to answer questions for my supporters.
                supporter:
                    That's the things I like to hear.
                    My question is:
                    |
                    [p] Okay, I have another one.
                player:
                    Another one?
                supporter:
                    Yes!
                    |
                    [p] This is the final one, I promise.
                player:
                    Ah, Hesh. Here we go again.
                }
            ]],
            OPT_AGREE = "Agree without question",
            DIALOG_AGREE = [[
                player:
                    I agree with you.
                supporter:
                    Ah, I see there is some candidate who can see reason.
            ]],
            DIALOG_FULL_AGREE = [[
                supporter:
                    Finally, a candidate who I agree with on every issue that I care about.
                player:
                    So...?
                supporter:
                    I'm going to support you harder than ever before!
            ]],
            OPT_EVADE = "Evade the question",
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                cxt:TalkTo(cxt:GetCastMember("supporter"))
                local questions = math.random(1, 3)
                local weightings = {}
                for id, data in pairs(DemocracyConstants.issue_data) do
                    weightings[id] = data.importance
                end
                cxt.quest.param.issue_list = {}
                cxt.quest.param.stance_list = {}
                while #cxt.quest.param.issue_list < questions and table.count(weightings) > 0 do
                    local chosen = weightedpick(weightings)
                    local stance = DemocracyConstants.issue_data[chosen]:GetAgentStanceIndex(cxt:GetCastMember("supporter"))
                    if stance ~= 0 then
                        table.insert(cxt.quest.param.issue_list, chosen)
                        table.insert(cxt.quest.param.stance_list, stance)
                    end
                    weightings[chosen] = nil
                end
                cxt.quest.param.current_issue_number = 1
                cxt:Dialog("DIALOG_INTRO")
            end
            if cxt.quest.param.current_issue_number > #cxt.quest.param.issue_list then
                cxt:Dialog("DIALOG_FULL_AGREE")
                cxt:GetCastMember("supporter"):OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("agree_full"))
                StateGraphUtil.AddLeaveLocation(cxt)
                return
            end
            cxt.quest.param.topic = cxt.quest.param.issue_list[cxt.quest.param.current_issue_number]
            cxt.quest.param.stance = cxt.quest.param.topic .. "_" .. cxt.quest.param.stance_list[cxt.quest.param.current_issue_number]
            cxt:Dialog("DIALOG_QUESTION", cxt.quest.param.current_issue_number)
            DemocracyUtil.QuipStance(cxt, cxt:GetCastMember("supporter"), cxt.quest.param.stance, "question")

            cxt:Opt("OPT_AGREE")
                :Dialog("DIALOG_AGREE")
                :UpdatePoliticalStance(cxt.quest.param.topic, cxt.quest.param.stance_list[cxt.quest.param.current_issue_number])
                :Fn(function(cxt)
                    cxt.quest.param.current_issue_number = cxt.quest.param.current_issue_number + 1
                end)

            cxt:Opt("OPT_EVADE")
                :GoTo("STATE_EVADE")
        end)
    :State("STATE_EVADE")
        :Loc{
            DIALOG_EVADE = [[
                player:
                    [p] Well, you see, that is quite an interesting question.
                    What I will say is that I support your right to ask this question!
                supporter:
                    ...
                    Is this supposed to be an answer?
            ]],
            OPT_DISAGREE = "Disagree outright",
            DIALOG_DISAGREE = [[
                player:
                    [p] The thing is, I literally support the opposite of that.
                    So to answer your question. Yes.
                supporter:
                    Wow that's a straightforward answer.
                    And my straightforward answer is that I dislike you now.
            ]],
            OPT_JUSTIFY = "Justify the silence",
            DIALOG_JUSTIFY = [[
                player:
                    [p] Agree or not, there is one thing for certain...
            ]],
            DIALOG_JUSTIFY_SUCCESS = [[
                player:
                    [p] Everyone is entitled to their own opinion.
                    But one thing everyone wants: to unite Havaria.
                supporter:
                    Okay, those are a lot of words, but it sounds like you have good reasons.
                    Well, I can continue support you!
            ]],
            DIALOG_JUSTIFY_FAILURE = [[
                supporter:
                    [p] Say no more.
                    I know how it really is.
                    There is no hiding of your hatred of the Havarian people.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_EVADE")
            DemocracyUtil.QuipStance(cxt, cxt:GetCastMember("supporter"), cxt.quest.param.stance, "question", "loaded")

            cxt:Opt("OPT_DISAGREE")
                :Dialog("DIALOG_DISAGREE")
                :ReceiveOpinion(OPINION.DISLIKE_IDEOLOGY)
                :Travel()
            cxt:BasicNegotiation("JUSTIFY", {

            }):OnSuccess()
                :Travel()
            :OnFailure()
                :ReceiveOpinion(OPINION.DISLIKE_IDEOLOGY)
                :Travel()
        end)
