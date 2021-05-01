local QDEF = QuestDef.Define
{
    title = "Noon Rendezvous",
    desc = "Meet up with your advisor and discuss the plan for the campaign.",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/meet_opposition.png"),

    qtype = QTYPE.STORY,
    collect_agent_locations = function(quest, t)
        table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.VISITOR})
        -- table.insert(t, { agent = quest:GetCastMember("potential_ally"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.VISITOR})
    end,
    on_complete = function(quest)
        if quest:GetCastMember("primary_advisor") then
            quest:GetCastMember("primary_advisor"):GetBrain():SendToWork()
        end
    end,
    -- on_start = function(quest)
        
    -- end,
}
:AddLocationCast{
    cast_id = "noodle_shop",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("MURDERBAY_NOODLE_SHOP"))
    end,
    
}
:AddObjective{
    id = "go_to_bar",
    title = "Visit the noodle shop",
    desc = "Visit the noodle shop and talk to your advisor about the upcoming plan.",
    mark = {"noodle_shop"},
    state = QSTATUS.ACTIVE,

    on_complete = function(quest)
        quest:Activate("discuss_plan")
        -- quest:Activate("make_decision")
    end,
}
:AddObjective{
    id = "discuss_plan",
    title = "Discuss plans",
    desc = "Discuss plans with your advisor about the upcoming debate.",
    mark = {"primary_advisor"},
}
DemocracyUtil.AddPrimaryAdvisor(QDEF)

QDEF:AddConvo("go_to_bar")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt:GetCastMember("primary_advisor") and cxt.location == cxt.quest:GetCastMember("noodle_shop") end)
        :Loc{
            DIALOG_INTRO = [[
                * [p] you arrived at the shop.
                player:
                    !left
                agent:
                    !right
                    Oh, hi. Look who's here.
                player:
                    I just love this shop. It sells great noodles for great prices.
                agent:
                    I know, right?
                    But that's not why we're here for.
                    We're here to discuss the plan for tonight.
            ]],
        }
        :Fn(function(cxt)
            -- if cxt:FirstLoop() then
            cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
            cxt.quest:Complete("go_to_bar")
            cxt:Dialog("DIALOG_INTRO")
            -- end
            StateGraphUtil.AddEndOption(cxt)
        end)
QDEF:AddConvo("discuss_plan", "primary_advisor")
    :Loc{
        OPT_ASK_QUESTIONS = "Ask some questions",
        DIALOG_ASK_QUESTIONS = [[
            player:
                I have a few questions.
            agent:
                Ask ahead.
        ]],
        OPT_FINISH_UP = "Finish up",
        DIALOG_FINISH_UP = [[
            {asked_no_questions?
                player:
                    Let's finished up.
                agent:
                    Really? But we didn't even do anything!
                player:
                    I know all of these stuff. I just don't think it is necessary for us to go over them again.
                agent:
                    Whatever. Just make sure you know what you're doing.
            }
            {not asked_no_questions?
                player:
                    Let's finished up.
                    I think we discussed all we need to discuss.
                agent:
                    Okay.
            }
            agent:
                Meet me at my office once you're done with your lunch.
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_ASK_QUESTIONS")
            :Dialog("DIALOG_ASK_QUESTIONS")
            :GoTo("STATE_QUESTIONS")
        cxt:Opt("OPT_FINISH_UP")
            :Fn(function(cxt)
                cxt.enc.scratch.asked_no_questions = not cxt.quest.param.asked_some_questions
            end)
            :Dialog("DIALOG_FINISH_UP")
            :CompleteQuest()
            :DoneConvo()
    end)
    :State("STATE_QUESTIONS")
        :Loc{
            OPT_ASK_DEBATE = "Ask about the debate",
            DIALOG_ASK_DEBATE = [[
                player:
                    [p] How is the debate going to be?
                agent:
                    It is a free for all debate.
                    Anyone can side with anyone in that debate.
                    It is more of a reality show than a debate to be honest.
                player:
                    Sounds chaotic.
                agent:
                    Not only you are debating against an opponent, you are also competing against others.
                    People will remember you only if you are the one that causes the debate to end in your favor.
            ]],
            OPT_ASK_ALLY = "Ask about alliance",
            DIALOG_ASK_ALLY = [[
                player:
                    [p] There's a lot of people in that debate.
                    What can I do to make the debate end in my favor?
                agent:
                    Hmm...
                    Maybe you can find some allies.
                    If you ally with someone, they may help you in a debate.
                    And most importantly, you will get a better chance at winning the election overall.
            ]],
            DIALOG_ASK_ALLY_ALREADY_HAVE = [[
                agent:
                    It seems like you already have allied with someone, so that's great.
                    But it never hurts to get more allies, right?
            ]],
            DIALOG_ASK_ALLY_POTENTIAL = [[
                agent:
                    Based on your current support, {1#agent} might be your best ally.
                {good_ally?
                    You share a few in common in ideology, and you have a bit of support in {1.hisher} main supporters, {2#faction}.
                    Go talk to {1.himher}. You can find {1.himher} at {3#location}.
                }
                {not good_ally?
                    I mean, your chances with {1.himher} aren't that great, but it is better than that with other candidates.
                    I suggest you build up support among {2#faction}. Then you will have a better chance.
                    When you do, you can find {1.himher} at {3#location} and talk to {1.himher} about your alliance.
                }
                player:
                    Great, thanks.
            ]],
            DIALOG_ASK_ALLY_NOONE = [[
                agent:
                    But... It seems all other candidates made up their mind to not ally with you.
                    Which is really a shame. But what can you do, really.
            ]],
            OPT_ASK_ELECTION = "Ask about the election",
            DIALOG_ASK_ELECTION = [[
                player:
                    The election is getting quite close. What should I do to win the election?
                agent:
                    Just keep on getting those support.
                    But also, you probably want to get a particular group to really like you, and ally with someone.
                player:
                    Why is that?
                    agent:
                    Are you familiar with our voting system?
                player:
                    Can't say I have, no.
                agent:
                    You're running for president, and you aren't even familiar with our voting system? Unbelievable.
                    It's called First Past The Post.
                player:
                    And what exactly does that mean?
                agent:
                    It means that each person gets to vote once, for their favorite candidate.
                {advisor_manipulate?
                    But logically speaking, if there are more than two candidates, it is not a good idea.
                    Let's say, hypothetically, you support the Cult's candidate.
                    So naturally, you will vote for the Cult, right?
                    But, let's say, hypothetically, the Cult is not that popular, and the Admiralty is the next best candidate.
                    And let's say, hypothetically, you don't want the Rise to win, right?
                    If you vote for the Cult, the Admiralty won't have enough votes to win the election, and the Rise wins. No one is happy.
                    But if you vote for the Admiralty, they will get enough votes to win.
                    You won't get exactly what you want, but it's better than the alternative, so logically, you must vote the Cult.
                *** Okay this is the end of wall of text. I promise.
                player:
                    Those are a lot of words. But I think I get it.
                    So, if I ally with someone, votes that should have go to them are likely to go to me!
                agent:
                    Exactly.
                }
                {advisor_diplomacy?
                    But that's what a normie would do.
                    Someone with a galaxy brain, however, would vote for the candidate they like that will most likely win.
                    It maximizes the chance of them getting a desired outcome.
                player:
                    Oh, so if I ally with someone, voters are more likely to vote for me because of this?
                agent:
                    That's right.
                    But hey, that's just a theory, a <i>Game</> Theory.
                * Seriously, that's what it is, and not just a reference to some YouTube channel.
                }
                {advisor_hostile?
                    But you see, if someone does that, they are wrong.
                    Nobody knows how the voting system works better than me.
                player:
                    You still haven't answered my question.
                agent:
                    Oh, yes. Here's the explanation.
                    It is not about voting someone you like the most, it's about voting for someone who are most likely to win.
                    Look at my fellow Jarackles there, eager to vote for someone who represent them the most.
                    But you don't represent anyone. You're here to <i>win</>.
                    And people prefer that than someone who will make drastic changes against them. 
                player:
                    I see.
                    So, if I ally with someone, votes that should have go to them are likely to go to me!
                agent:
                    Exactly.
                }
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            cxt:Question("OPT_ASK_DEBATE", "DIALOG_ASK_DEBATE", function()
                cxt.quest.param.asked_some_questions = true
            end)
            cxt:Question("OPT_ASK_ALLY", "DIALOG_ASK_ALLY", function()
                local allied = {}
                local potential = {}
                for id, data in pairs(DemocracyConstants.opposition_data) do
                    local candidate = TheGame:GetGameState():GetMainQuest():GetCastMember(data.cast_id)
                    if candidate then
                        if candidate:GetRelationship() > RELATIONSHIP.NEUTRAL then
                            table.insert(allied, id)
                        elseif candidate:GetRelationship() == RELATIONSHIP.NEUTRAL and DemocracyUtil.GetAlliancePotential(id) then
                            table.insert(potential, id)
                        end
                    end
                end
                table.sort(potential, function(a,b) return DemocracyUtil.GetAlliancePotential(a) > DemocracyUtil.GetAlliancePotential(b) end)
                if #allied > 0 then
                    cxt:Dialog("DIALOG_ASK_ALLY_ALREADY_HAVE")
                end
                if #potential > 0 then
                    local data = DemocracyConstants.opposition_data[potential[1]]
                    local candidate = TheGame:GetGameState():GetMainQuest():GetCastMember(data.cast_id)
                    cxt.enc.scratch.good_ally = DemocracyUtil.GetEndorsement(DemocracyUtil.GetAlliancePotential(potential[1])) >= RELATIONSHIP.NEUTRAL
                    cxt:Dialog("DIALOG_ASK_ALLY_POTENTIAL", candidate, data.main_supporter, data.workplace)

                    DemocracyUtil.DoLocationUnlock(cxt, data.workplace)
                else
                    cxt:Dialog("DIALOG_ASK_ALLY_NOONE")
                end
                cxt.quest.param.asked_some_questions = true
            end)
            cxt:Question("OPT_ASK_ELECTION", "DIALOG_ASK_ELECTION", function()
                cxt.quest.param.asked_some_questions = true
            end)
            StateGraphUtil.AddBackButton(cxt)
        end)
