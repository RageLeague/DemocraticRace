local QDEF = QuestDef.Define
{
    qtype = QTYPE.SCENARIO,

    on_start = function(quest)
        quest:Activate("wait")
    end,
}
:AddCast{
    cast_id = "hunter",
    events = {
        agent_retired = function(quest, agent)
            quest:Fail()
            if quest.param.hire_amt then
                TheGame:GetGameState():GetCaravan():AddMoney(quest.param.hire_amt)
            end
        end,
    },
}
:AddCast{
    cast_id = "target",
    -- no_validation = true,
    unimportant = true,
    events = {
        agent_retired = function(quest, agent)
            quest:Complete()
            if quest.param.hire_amt then
                TheGame:GetGameState():GetCaravan():AddMoney(quest.param.hire_amt)
            end
        end,
    },
}
:AddDormancyState("wait", "report", false, 3, 10)
:AddObjective{
    id = "report",
    hide_in_overlay = true,
    on_activate = function(quest)
        quest.param.attack_successful = DemocracyUtil.SimulateBattle(quest:GetCastMember("hunter"), quest:GetCastMember("target"), 2)

        if quest.param.attack_successful then
            if quest.param.no_kill then
                quest.param.target_killed = false
            elseif quest.param.must_kill then
                quest.param.target_killed = true
            else
                quest.param.target_killed = math.random() < 0.5
            end
        end
    end,
}

QDEF:AddConvo("report")
    :TravelConfront("STATE_CONF")
        :Loc{
            DIALOG_INTRO = [[
                {not attack_successful?
                    * [p] You saw {hunter}, who doesn't look so good.
                    player:
                        !left
                    hunter:
                        !right
                        !injured
                        Mission failed. {target} is tougher than I thought.
                        I barely got away.
                    player:
                        Dang. I need to hire better people for this job.
                    hunter:
                        Anyway, I cannot rightfully take your money.
                        Here is your money back.
                }
                {attack_successful?
                    * [p] You saw {hunter}.
                    player:
                        !left
                    hunter:
                        !right
                    {target_killed?
                        {target} is dead.
                    player:
                        Nice work!
                    }
                    {not target_killed?
                        I beat {target} up.
                        {target.HeShe} shouldn't bother you, at least for a while.
                    player:
                        Excellent work!
                    }
                }
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")

            if cxt.quest.param.attack_successful then
                if cxt.quest.param.target_killed then
                    cxt:GetCastMember("target"):Kill()
                else
                    cxt:GetCastMember("target"):GainAspect("stripped_influence", 4)
                    cxt:GetCastMember("target"):GainAspect("intimidated")
                    cxt:GetCastMember("target").health:SetPercent(math.random(15, 25)*0.01)
                end
            else
                cxt:GetCastMember("hunter"):GainAspect("stripped_influence", 2)
                cxt:GetCastMember("hunter").health:SetPercent(math.random(15, 25)*0.01)
                if cxt.quest.param.hire_amt then
                    cxt.enc:GainMoney( cxt.quest.param.hire_amt )
                end
            end

            cxt.quest:Complete()
            StateGraphUtil.AddLeaveLocation(cxt)
        end)
