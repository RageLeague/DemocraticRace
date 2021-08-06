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
        table.insert( t, quest:CreateSkinnedAgent()
    end,
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
                supporter:
                    Do you agree that {stance#pol_stance} is the best solution to {topic#pol_issue}?
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
                while #cxt.quest.param.issue_list < questions do
                end
            end
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
                    Do you really hate the good people of Havaria?
                player:
                    Well...
            ]],
            OPT_DISAGREE = "Disagree outright",
            DIALOG_DISAGREE = [[
                player:
                    [p] The thing is, I literally support the opposite of that.
                    So if that's what you mean by "hating the good people of Havaria", I do.
                supporter:
                    Wow that's a straightforward answer.
                    And my straightforward is that I dislike you now.
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