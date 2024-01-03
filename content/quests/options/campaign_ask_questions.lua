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
        BENNI_TEI_RELATION = {
            condition = function(self, agent, cxt)
                return agent:GetContentID() == "ADVISOR_MANIPULATE" and TheGame:GetGameProfile():HasCustomAgentUnlock( agent:GetUniqueID(), "know_about_tei" )
            end,
            option = "Ask about Tei",
            dialog = [[
                player:
                    [p] So, you and Tei, do you know each other well?
                agent:
                    W- why did you ask that?
                player:
                    I noticed that you seem to treat her a lot better than other people.
                    Why is that?
                agent:
                    W- well, let's say, hypothetically, you are a priest for the Cult of Hesh.
                    !angry
                    Who, despite your genuine reverence and fear for Hesh, is treated like an outsider, simply because of your different way of expressing your faith.
                player:
                    I feel like it's not as hypothetical as you make it out to be, but I'm following.
                agent:
                    And let's say, hypothetically, that there is another person.
                    Someone who doesn't treat others differently despite such difference.
                    Someone who recognizes your for your contribution rather than your conformity.
                player:
                    Yeah I can see why you like-
                agent:
                    ...Someone who is also kind, and compassionate, and charming, and pretty, and...
                {player_sal or player_smith?
                    player:
                        !chuckle
                        Oh I can <i>definitely</> see why you like them.
                }
                {not (player_sal or player_smith)?
                    player:
                        I see your point. You can stop listing these positive adjectives now.
                }
                agent:
                    Anyway, wouldn't you agree that you would reciprocate this kindness back?
                    !<unlock_agent_info;ADVISOR_MANIPULATE;lore_tei>
                player:
                    !thought
                    That... does make a lot of sense.
            ]],
        },
        DRONUMPH_EYE = {
            condition = function(self, agent, cxt)
                return agent:GetContentID() == "ADVISOR_HOSTILE"
            end,
            option = "Ask about {agent}'s eye",
            dialog = [[
                player:
                    I see that one of your eyes is not working.
                agent:
                    That's not that uncommon in Havaria.
                {not depressed?
                    Some ingrate caused it before learning to never cross the Trunoomiel family.
                }
                {depressed?
                    Honestly, I probably deserve it, seeing how worthless I am.
                }
                    What about it?
                player:
                    Have you thought about replacing it?
                {not depressed?
                    agent:
                        !angry
                        No.
                        Absolutely not.
                        Nobody knows surgeons better than I do, and believe me when I say that they are the most treacherous scums out there.
                }
                {depressed?
                    agent:
                        !handwave
                        No. There is no point anyway. It is not something that I deserve.
                        Besides, it is not something I want, anyway.
                        Surgeons. Don't trust them. Bunch of backstabbin' bastards.
                }
                player:
                    That's... an interesting opinion.
                agent:
                    My father got a surgery once to treat his wounds.
                    {depressed?
                        He deserves to live a better life than I do.
                    }
                    The surgeon that did the surgery was the same one that my father helped to get him into med school, Clepius.
                    What did that backstabbin' bastard do? Killed him straight up, with no mercy.
                    The investigators ruled it a "surgery accident", but I know better.
                    !<unlock_agent_info;ADVISOR_HOSTILE;lore_tomophobia>
                player:
                    I see.
                {accept_limits?
                    agent:
                        !thought
                        ...
                        Do I, though?
                        Maybe I should look past my grief in order to see things for what they actually are.
                }
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
