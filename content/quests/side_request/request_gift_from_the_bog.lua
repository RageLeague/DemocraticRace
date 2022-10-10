local QDEF = QuestDef.Define
{
    title = "Gift From The Bog",
    desc = "Pick up a package for {giver} from {delivery}.",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/battle_of_wits.png"),

    qtype = QTYPE.SIDE,

    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"REQUEST_JOB"},
    reward_mod = 0,
    can_flush = false,

    events = {
        base_difficulty_change = function(quest, new_diff, old_diff)
            quest:SetRank(new_diff)
        end,

    },

    collect_agent_locations = function(quest, t)
        if not quest:GetCastMember("delivery"):IsRetired() then
            table.insert(t, { agent = quest:GetCastMember("delivery"), location = quest:GetCastMember("delivery_home"), role = CHARACTER_ROLES.VISITOR})
        end
    end,

    on_start = function(quest)
        quest:Activate("pick_up_package")
    end,

    on_complete = function(quest)
        if not (quest.param.sub_optimal or quest.param.poor_performance) then
            quest:GetCastMember("giver"):OpinionEvent(OPINION.DID_LOYALTY_QUEST)
        elseif quest.param.sub_optimal then
        elseif quest.param.poor_performance then
        end
    end,

}
:AddCast{
    cast_id = "giver",
    no_validation = true,
    provider = true,
    unimportant = true,
    condition = function(agent, quest)
        return (agent:GetFactionID() == "JAKES" and not agent:HasTag("advisor"))
    end,
    on_assign = function(quest, agent)
    end,
}
:AddCast{
    cast_id = "delivery",
    condition = function(agent, quest)
        return agent:GetFactionID() == "JAKES"
    end,
    on_assign = function(quest, agent)
        quest:AssignCastMember("delivery_home")
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( "JAKES_RUNNER" ) )
    end,
}
:AddLocationCast{
    cast_id = "delivery_home",
    when = QWHEN.MANUAL,
    cast_fn = function(quest, t)
        table.insert(t, quest:GetCastMember("delivery"):GetHomeLocation())
    end,
}

:AddObjective{
    id = "pick_up_package",
    title = "Pick up package from {delivery}.",
    desc = "Go to {delivery}'s home and pick up the package from them.",
    mark = function(quest, t, in_location)
        if DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("delivery"))
        end
    end,
}

QDEF:AddIntro(
    --attract spiel
    [[
        agent:
            [p] I've got this package from the Bog that I need to pick up.
            It's with {delivery}. Can you pick the package up for me from {delivery.himher}?
    ]],
    --on accept
    [[
        player:
            [p] Okay. Where can I find {delivery.himher}?
        agent:
            That's the thing. I haven't seen {delivery.himher} for a while, so I have no idea where {delivery.heshe} could be.
            Maybe start from {delivery.hisher} home. See if you can find {delivery.himher} there.
    ]])

QDEF:AddConvo("pick_up_package", "delivery_home")
    :Confront(function(cxt)
        if cxt.location == cxt:GetCastMember("delivery_home") then
            if cxt:GetCastMember("delivery"):GetLocation() == cxt:GetCastMember("delivery_home") then
                return "STATE_CONF"
            else
                return "STATE_CONF_NO_PERSON"
            end
        end
    end)
    :State("STATE_CONF")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You visit {agent}'s home.
                * {agent} writhes in pain.
                * When you ask, {agent} shows you bog parasites growing out of {agent.hisher} arm.
                {have_parasite?
                    * [p] So it's not just you. There are other people who also got infected by the bog parasites.
                }
                {not have_parasite?
                    * Bog parasites now infects the Pearl now?
                    {not player_drunk?
                        * And, judging by {agent}'s description, it's contagious.
                    }
                }
                * This is a big deal. You need to tell everyone about it.
            ]],
            OPT_SURGERY = "Perform \"surgery\" on {agent}",
            TT_SURGERY = "Get rid of {agent}'s parasite in a battle. Or use it as an excuse to attack {agent.himher}.",
            DIALOG_SURGERY = [[
                player:
                    !fight
                    [p] This is for your own good.
            ]],
            DIALOG_SURGERY_WIN = [[
                * [p] You got rid of the parasite.
                * {agent} thanks you.
            ]],
            DIALOG_SURGERY_RUN = [[
                * [p] You grabbed the package and run.
                * {agent} is too busy writhing in pain than to chase after you.
            ]],
            DIALOG_SURGERY_KILLED = [[
                * [p] Okay, you straight up just killed {agent}.
                * That's one way of dealing with parasites.
            ]],
            DIALOG_SURGERY_FAILED = [[
                * [p] It doesn't seem to actually help {agent}, and now {agent} is mad.
                * {agent.HeShe} can't do anything about it, though, since {agent.gender:he's|she's|they're} very injured.
                * You grabbed the package and leave {agent} to {agent.hisher} fate.
            ]],
            OPT_ESCORT = "Convince {agent} to follow you",
            DIALOG_ESCORT = [[
                player:
                    [p] Come on. Let's get you some help.
                agent:
                    But I have very low energy.
            ]],
            DIALOG_ESCORT_SUCCESS = [[
                player:
                    [p] You can't stay like this forever.
                    We need to get you some help soon.
                agent:
                    Fine.
            ]],
            DIALOG_ESCORT_FAILURE = [[
                agent:
                    [p] I can't move.
            ]],

            DIALOG_LEAVE = [[
                player:
                    [p] I'm sorry. There is nothing I can do at this point.
                    Thanks for the package.
                    {pro_religious_policy?
                        Let us pray to Hesh that you can recover from... whatever that is.
                    }
                    {not pro_religious_policy?
                        I hope you can recover from... whatever that is.
                    }
                * Of course. Thoughts and prayers. That is <i>definitely</> enough to help {agent} recover.
                * Anyway, you need to get back to {giver} and deliver the package. And also tell {agent} about the parasite situation.
            ]],
        }
    :State("STATE_CONF_NO_PERSON")
        :Loc{
            DIALOG_INTRO_NO_PERSON = [[
                * [p] You visit {delivery}'s home.
                * {delivery} is nowhere to be found.
                * You found the package.
                * You also found a bunch of evidence of bog parasites. It's disgusting.
                * You need to tell people about it.
            ]],
        }
