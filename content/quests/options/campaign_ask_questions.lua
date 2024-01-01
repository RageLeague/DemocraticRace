local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,
    questions = {
        AELLON_BASED = {
            condition = function(self, agent, cxt)
                return agent:GetContentID() == "ADVISOR_DIPLOMACY"
            end,
            option = "Ask about the meaning of the word \"based\"",
            dialog = [[
                player:
                    I keep hearing you say the word "based".
                    Do you know what it means?
                agent:
                    It means that a liquid contains less than ten millionth moles of Hydronium ion per liter of water under room temperature?
                player:
                    Uhh... What?
                agent:
                    Oh, you asked for what "based" means. Not "basic".
                    My mistake. Havarian is a confusing language.
                    Well, it's hard to describe exactly what "based" means, but I can give an example.
                    If you win the election, no matter what it takes, it would be "based" of you to do so.
                player:
                    !dubious
                    So... It's an adjective describing a positive thing?
                agent:
                    !crossed
                    It's more than just that, but frankly, it's hard to explain.
                    You will figure it out.
                player:
                    !dubious
                    Uh huh.
            ]],
        },
        BENNI_HUSBAND = {
            condition = function(self, agent, cxt)
                return agent:GetContentID() == "ADVISOR_MANIPULATE" and TheGame:GetGameProfile():HasCustomAgentUnlock( agent:GetUniqueID(), "lore_husband" )
            end,
            option = "Ask about {agent}'s husband",
            dialog = [[
                player:
                    You keep mentioning you have a husband, but I don't see him around.
                    Where is he?
                agent:
                    Well, he <i>is</> a doctor, currently working in Deltree.
                    Logically, this is why he is not around.
                player:
                    Right. He works in Deltree. The other side of the Heshian sea.
                agent:
                    Don't you have anything better to do than interrogating me about my marital status?
                    Say, hypothetically, actually working on your campaign?
                player:
                    !bashful
                    Right. Apologies.
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
    local questions_total = {}
    for i, id, data in sorted_pairs(QDEF.questions) do
        if not data.condition or data:condition(agent, cxt) then
            table.insert(questions_total, id)
            if not agent:HasMemory("ASKED_ABOUT_" .. id) then
                table.insert(questions_available, id)
            end
        end
    end
    return questions_available, questions_total
end

CONVO:Loc{
        OPT_ASK = "Ask about {agent}...",
        REQ_MUST_LIKE_YOU = "{agent} will only answer questions for {agent.hisher} friends",
        REQ_NO_QUESTIONS_LEFT = "You have asked all the questions available",
    }
    :Hub(function(cxt, who)
        if who then
            local questions_available, questions_total = GetQuestions(cxt, who)
            if #questions_total > 0 then
                cxt:Opt("OPT_ASK")
                    :ReqCondition( who:GetRelationship() > RELATIONSHIP.NEUTRAL, "REQ_MUST_LIKE_YOU" )
                    :ReqCondition( #questions_available > 0, "REQ_NO_QUESTIONS_LEFT" )
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
