local QDEF = QuestDef.Define
{
    title = "Information Warfare",
    desc = "Commission someone for a propaganda poster and post it at popular locations to boost your campaign's popularity.",

    qtype = QTYPE.SIDE,
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"RALLY_JOB"},
    reward_mod = 0,
    extra_reward = false,

    precondition = function(quest)
        return TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor")
    end,
}
:AddObjective{
    id = "commmission",
}
:AddObjective{
    id = "post",
}
DemocracyUtil.AddPrimaryAdvisor(QDEF, true)

QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
            primary_advisor:
                Maybe it's a good idea to post propaganda posters in popular locations.
            player:
                We don't have anything like that, do we?
            primary_advisor:
                Not yet, anyway.
                You can ask someone to commission one for you.
            player:
                If I can't find anyone like that?
            primary_advisor:
                Then draw one yourself, or something.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.ACCEPTED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                Sounds good.
                You know how to start?
            primary_advisor:
                Go ask someone who looks like they have artistic talents.
                !thought
                Or someone who looks like they have time to waste on art.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.DECLINED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                I don't know. That might not worth the effort.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)