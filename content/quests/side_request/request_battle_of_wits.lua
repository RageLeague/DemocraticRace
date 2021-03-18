local function GetELO(agent)
    return 1000 + 210 * agent:GetRenown() - 200 * agent:GetCombatStrength() + math.random(-100, 100)
end

local QDEF = QuestDef.Define
{
    title = "Battle of Wits",
    desc = "To prove that nobody is smarter than {giver}, {giver} asks you to find someone who can defeat {giver.himher} in a battle of Chess(?).",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/revenge_starving_worker.png"),

    qtype = QTYPE.SIDE,

    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"REQUEST_JOB"},
    -- reward_mod = 0,
    can_flush = false,

    events = {
        base_difficulty_change = function(quest, new_diff, old_diff)
            quest:SetRank(new_diff)
        end,
        
    },
    
    on_start = function(quest)
        quest:Activate("find_challenger")
    end,

    on_complete = function(quest)
        if not (quest.param.sub_optimal or quest.param.poor_performance) then
            -- quest:GetProvider():OpinionEvent(OPINION.DID_LOYALTY_QUEST)
            -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 10, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, 4, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 3, "COMPLETED_QUEST")
        elseif quest.param.sub_optimal then
            -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 5, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, 4, "COMPLETED_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 3, "COMPLETED_QUEST")
        elseif quest.param.poor_performance then
            -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -2, "POOR_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 3, 4, "POOR_QUEST")
            -- DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 2, 3, "POOR_QUEST")
        end
    end,

}
:AddCast{
    cast_id = "giver",
    no_validation = true,
    provider = true,
    unimportant = true,
    condition = function(agent, quest)
        return agent:GetContentID() == "ADVISOR_HOSTILE" or (DemocracyUtil.GetWealth(agent) >= 4)
    end,
    -- cast_fn = function(quest, t)
    --     table.insert( t, quest:CreateSkinnedAgent( "LABORER" ) )
    -- end,
    on_assign = function(quest, agent)
        quest:AssignCastMember("giver_home")
    end,
}
:AddLocationCast{
    cast_id = "giver_home",
    when = QWHEN.MANUAL,
    cast_fn = function(quest, t)
        table.insert(t, quest:GetCastMember("giver"):GetBrain():GetHome())
    end,
}
:AddCast{
    cast_id = "challenger",
    when = QWHEN.MANUAL,
    no_validation = true,
    on_assign = function(quest, agent)
        quest:Complete("find_challenger")
    end,
    events = {
        agent_retired = function(quest, agent)
            quest:UnassignCastMember("challenger")
            if quest:IsActive("go_to_game") then
                quest:Cancel("go_to_game")
            end
            quest:Activate("find_challenger")
        end,
    },
}
:AddObjective{
    id = "find_challenger",
    title = "Find potential challengers.",
    desc = "Find someone who can potentially beat {giver} in Chess(?).",
}
:AddObjective{
    id = "go_to_game",
    title = "Spectate the game.",
    desc = "Go visit {giver} and watch how the game with {challenger} turns out.",
}
:AddObjective{
    id = "wait",
    title = "See what happens.",
    desc = "Surely nothing bad will happen, right?",
}

QDEF:AddIntro(
    --attract spiel
    [[
        agent:
            [p] Nobody knows more than me.
            To prove this, find someone who can beat me at Chess(?).
            You can't, but please try.
    ]],
    
    --on accept
    [[
        player:
            [p] A weird request, but okay...?
    ]])

QDEF:AddConvo("find_challenger")
    :Loc{
        OPT_ASK = "Ask {agent} to play Chess(?) with {giver}",
        DIALOG_ASK = [[
            player:
                [p] Wanna beat {giver} in a game?
            agent:
                Why tho?
        ]],
        DIALOG_ASK_SUCCESS = [[
            agent:
                [p] Good point.
                I'll meet up with {giver} and play.
        ]],
        DIALOG_ASK_FAILURE = [[
            agent:
                [p] Nah, I don't think I will.
        ]],
    }
    :Hub(function(cxt, who)
        if who and not AgentUtil.HasPlotArmour(agent) then
        end
    end)
QDEF:AddConvo("go_to_game")
    :Priority(CONVO_PRIORITY_LOW)
    :AttractState("STATE_NO_PLAYER", function(cxt) 
        return cxt.location == cxt:GetCastMember("giver_home") and cxt:GetAgent() and
            (cxt:GetAgent() == cxt:GetCastMember("giver") or cxt:GetAgent() == cxt:GetCastMember("challenger"))
    end)
        :Loc{
            DIALOG_INTRO_GIVER_NO_CHALLENGER = [[
                agent:
                    [p] You got someone to play? Great!
                    But I guess they're not here, yet, huh?
            ]],
            DIALOG_INTRO_CHALLENGER_NO_GIVER = [[
                agent:
                    [p] Where's {giver}?
                player:
                    {giver.HeShe}'s not here yet.
                agent:
                    Oh well, we can wait.
            ]],
        }
        :Fn(function(cxt)
            if cxt:GetCastMember("giver"):GetLocation() ~= cxt.location then
                cxt:Dialog("DIALOG_INTRO_CHALLENGER_NO_GIVER")
            elseif cxt:GetCastMember("challenger"):GetLocation() ~= cxt.location then
                cxt:Dialog("DIALOG_INTRO_GIVER_NO_CHALLENGER")
            end
        end)