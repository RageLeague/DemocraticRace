local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,
    questions = {
        AELLON_BASED = {
            condition = function(self, agent, cxt)
                return agent:GetContentID() == "ADVISOR_DIPLOMACY"
            end,
            option = "Ask about the meaning of the word \"Based\"",
            dialog = [[
                player:
                    I keep hearing you say the word "based".
                    Do you know what it means?
                agent:
                    It means that a liquid contains less than ten millionth moles of Hydronium ion per liter of water under room temperature?
                player:
                    Uhh...
                    Sure?
                * That would be "basic", but close enough.
            ]],
        },
        TEST = {
            condition = function(self, agent, cxt)
                return agent:GetFactionID() == "ADMIRALTY"
            end,
            option = "[Test] Ask about the Admiralty!",
            dialog = [[
                agent:
                    [p] They cool lol.
            ]],
        },
        TEST_RICK = {
            condition = function(self, agent, cxt)
                return agent:GetRenown() >= 3
            end,
            option = "[Test] Ask about rich people!",
            dialog = [[
                agent:
                    [p] We are rich lol.
                    Now fie, thou peasant.
            ]],
        },
    },
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}

local CONVO = QDEF:AddConvo()

local function GetQuestions(cxt, agent)
    local questions_available = {}
    for i, id, data in sorted_pairs(QDEF.questions) do
        if not agent:HasMemory("ASKED_ABOUT_" .. id) and (not data.condition or data:condition(agent, cxt)) then
            table.insert(questions_available, id)
        end
    end
    return questions_available
end

CONVO:Loc{
        OPT_ASK = "Ask about {agent}...",
    }
    :Hub(function(cxt, who)
        if who and who:GetRelationship() > RELATIONSHIP.NEUTRAL then
            if #GetQuestions(cxt, who) > 0 then
                cxt:Opt("OPT_ASK")
                    :GoTo("STATE_QUESTIONS")
            end
        end
    end)
    :State("STATE_QUESTIONS")
        :SetLooping(true)
        :Fn(function(cxt)
            local questions = GetQuestions(cxt, cxt:GetAgent())
            local question_defs = cxt.quest:GetQuestDef().questions
            if #questions == 0 then
                cxt:Pop()
                return
            end
            for i, id in ipairs(questions) do
                local opt = cxt:Opt("OPT_ASK_" .. id)
                    :Fn(function(cxt)
                        cxt:GetAgent():Remember("ASKED_ABOUT_" .. id)
                    end)
                if question_defs[id].dialog then
                    opt:Dialog("DIALOG_ASK_" .. id)
                end
                if question_defs[id].post_fn then
                    opt:Fn(question_defs[id].post_fn)
                end
            end
            StateGraphUtil.AddBackButton(cxt)
        end)

for i, id, data in sorted_pairs(QDEF.questions) do
    if data.option then
        CONVO:AddLocString("OPT_ASK_" .. id, data.option)
    end
    if data.dialog then
        CONVO:AddLocString("DIALOG_ASK_" .. id, data.dialog)
    end
end
