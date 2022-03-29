local QDEF = QuestDef.Define
{
    title = "Never Meet Your Heroes",
    desc = "Manufacture a scandal for one of your political opponents. Show their supporters who they are really supporting.",

    qtype = QTYPE.SIDE,
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"RALLY_JOB"},
    reward_mod = 0,
    extra_reward = false,

    on_init = function(quest)

    end,
    on_start = function(quest)

    end,

    on_destroy = function( quest )

    end,
    on_complete = function( quest )

    end,
    on_fail = function(quest)

    end,
    precondition = function(quest)
        return TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor") and TheGame:GetGameState():GetMainQuest().param.day >= 2
    end,
}
DemocracyUtil.AddPrimaryAdvisor(QDEF, true)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
            primary_advisor:
                There are two ways to win an election:
                One, you gather support and increase your votes.
                Two, you bring your opponent down so they get less votes.
            player:
                That sounds good and all, but how could I possibly do that?
            primary_advisor:
                It's simple. Tell the voter base something that your opponent doesn't want them to know. Something that can bring down their reputation.
            player:
                You have something in mind?
            primary_advisor:
                !shrug
                Not really. But you can easily make this up.
            {not can_manipulate_truth?
                It doesn't have to be true. It just has to be plausible enough to bring down the opponent's popularity.
            }
            {can_manipulate_truth?
                After all, facts are subjective.
                Tell the world what they want to believe, and it will become the truth.
            }
                Which one of your opponents to target is up to you.
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
                !shrug
                You know what? I'm down for a little defamation.
            primary_advisor:
                Great! Who do you want to target today?
        ]],
        OPT_TARGET = "Target {1#agent}",
        DIALOG_TARGET = [[
            player:
                I would say {target}.
            primary_advisor:
                !shrug
                If you say so.
                Now, if we want to defame {target}, we need to show the people what kind of person {target} truly is.
                What kind of horrible misdeeds they have done in the past, or what kind of personality traits that are less than desireable.
                !thought
                Something that {target} doesn't want the world to know.
                You have something in mind, don't you?
                If you do, write your thoughts down.
        ]],
        DIALOG_TARGET_PST = [[
            * {agent} carefully reads what you've just wrote.
            {advisor_diplomacy?
            agent:
                !give
            * Then, {agent} hands the note back to you.
            agent:
                Wow, that was certainly a cringe thing for {target} to do, huh?
                You are going to be so based revealing this information to the world.
            }
            {not advisor_diplomacy?
            agent:
                !sigh
            * Then, {agent.heshe} gives up.
            agent:
                Man, you really need to work on your handwriting.
                I don't think whatever you wrote is even Havarian.
            player:
                !crossed
                Hey! That's uncalled for.
            agent:
                !sigh
                I'm sure whatever you wrote is at least a good enough rumor to hopefully sow doubts in the voter base.
            }
            agent:
                !point
                Now go and tell everyone about it.
                Make sure to tell people from different backgrounds about it, so this story becomes more believable.
                And make sure to keep your stories straight.
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
                !crossed
                That sounds extremely dirty.
            primary_advisor:
                !handwave
                Please, you are a grifter.
                You should know the virtue of pursuing your goal using any means necessary.
                !sigh
                Nevertheless, I cannot force you if you don't want to do it.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
