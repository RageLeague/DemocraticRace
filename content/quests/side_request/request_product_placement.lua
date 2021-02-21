local QDEF = QuestDef.Define
{
    title = "Product Placement",
    desc = "{giver} wants you to endorse {giver.hisher} product and asks you to advertise them to the people.",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/revenge_starving_worker.png"),

    qtype = QTYPE.SIDE,

    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"REQUEST_JOB"},
    -- reward_mod = 0,
    can_flush = false,
    on_start = function(quest)
        quest:Activate("sell")
        quest.param.people_advertised = 0
    end,

    on_complete = function(quest)
        if not (quest.param.sub_optimal or quest.param.poor_performance) then
            quest:GetProvider():OpinionEvent(OPINION.DID_LOYALTY_QUEST)
            -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 10, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, 1, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 2, "COMPLETED_QUEST")
        elseif quest.param.sub_optimal then
            -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 5, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 8, 1, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 2, "COMPLETED_QUEST")
        elseif quest.param.poor_performance then
            -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2, "POOR_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 1, "POOR_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 2, "POOR_QUEST")
        end
    end,
}

:AddCast{
    cast_id = "giver",
    no_validation = true,
    provider = true,
    unimportant = true,
    -- cast_fn = function(quest, t)
    --     table.insert( t, quest:CreateSkinnedAgent( "LABORER" ) )
    -- end,
}
:AddObjective{
    id = "sell",
    title = "Give your sales pitch to people.",
    desc = "When you are negotiating with others, you can insert the product into the conversation. The more people present, the better.",
    on_activate = function(quest)
        TheGame:GetGameState():GetPlayerAgent().negotiator:LearnCard("promote_product_quest", {linked_quest = quest})
    end,
}
-- We can use this on request quests, because there's no reject dialogs.
QDEF:AddIntro(
    --attract spiel
    [[
        agent:
        {advisor_diplomacy?
            I'm not just helping you for nothing you know?
        player:
            Of course I know. You kept a cut of our funding for yourself every day.
            !angry
            The money is supposed to be the funding for the campaign, you know? And you keep it to yourself.
            !neutral
        agent:
            That's cringe of you to think that way.
            No. The reason is that I want to use this campaign as an opportunity to sell some <b>S.T.O.N.K.S.</>.
        player:
            !dubious
            I'm sorry, what now?
        agent:
            <b>S.T.O.N.K.S.</>.
            It stands for "Synthetic T O Neural K System".
            (IDFK, haven't figured out the acronym yet)
        player:
            Sure, why not?
            You want me to advertise it to the people during my campaign?
        agent:
            If you can, then sure, go ahead.
        }
        {not advisor_diplomacy?
            I'm trying to run a side business.
            Selling some product, that's all.
        player:
            Okay...? What does that have to do with me?
        agent:
            You see... I don't got many business.
            I'm thinking... Maybe you can help me sell it.
        player:
            I'm a politician, not a salesman.
        agent:
            Oh, no. You don't need to do it separately.
            You just need to insert the product into your normal conversations, that's all.
        }
    ]],
    
    --on accept
    [[
        player:
            Eh, sure, why not.
        agent:
            Great! When you negotiate with someone, be sure to let them know my product!
    ]])