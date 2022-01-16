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
            if quest:IsActive("wait") then
                quest:Complete()
                if quest.param.hire_amt then
                    TheGame:GetGameState():GetCaravan():AddMoney(quest.param.hire_amt)
                end
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
                    * You find {hunter} leaning against a tree, clutching a variety of wounds with bandages.
                    player:
                        !left
                    hunter:
                        !right
                        !injured
                        So {target} is...just a smidge out of my paygrade, if I'm being honest.
                    player:
                        Just a bit. Is {target} injured?
                    hunter:
                        Not even a bit. I was squashed like a Flead.
                        Look, I got some experience. I'm fine without the money, just going to go...go lay low.
                        !injuredpalm
                        Oh the blood loss is not helping my head.
                    * You take the money and walk before {hunter} can take the offer back.
                }
                {attack_successful?
                    * {hunter} arrives, looking tired but satisfied.
                    player:
                        !left
                    hunter:
                        !right
                    {target_killed?
                        Remember that hit you wanted on {target}?
                    player:
                        Oh right. What happened to {target.himher}?
                    hunter:
                        Well, I've got {target}'s blood on my jacket, if that's enough proof for you.
                    player:
                        !placate
                        Yes, that's proof enough. Please go wash that.
                    hunter:
                        !happy
                        Great! I'm gonna go hit the pub on your dime.
                        !salute
                        I'll be near, if you need another political assasination.
                    }
                    {not target_killed?
                        Say, have you heard what happened to {target}?
                        {target.HeShe} had an accident a while ago. A really <i>messy</> one.
                    player:
                        !chuckle
                        Oh how terrible! Who could let such a thing happen?
                    target:
                        !wink
                        I don't know. It could be <i>anyone</>.
                    }
                }
            ]],
            --There's some emote, the little lean back then lean forward one. I don't know what it's called but I would like that.
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
