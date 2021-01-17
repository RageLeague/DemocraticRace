
local QDEF = QuestDef.Define
{
    title = "In Summary",
    desc = "Talk to your advisor about what happened today, and review your progress.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/summary.png"),

    qtype = QTYPE.STORY,
}
:AddObjective{
    id = "summary",
    title = "Return to your advisor",
    desc = "Go to your advisor.",
    mark = {"primary_advisor"},
    state = QSTATUS.ACTIVE,
}
DemocracyUtil.AddPrimaryAdvisor(QDEF, true)

local RANKS = {
    "S","A","B","C","D","F"
}

QDEF:AddConvo("summary", "primary_advisor")
    :AttractState("STATE_SUMMARY")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    Anyway, let's get to our support level.
            ]],
            DIALOG_S = [[
                agent:
                    Oh my! Our support level is through the roof!
                    That went way above my expectation.
                    We definitely should win the election now!
                {not disliked?
                    Good job, {player}!
                }
                {disliked?
                    I should have never doubted your ability.
                }
            ]],
            DIALOG_A = [[
                agent:
                    Our support level is looking good!
                    As long as we keep this up, we will surely win the election.
                {liked?
                    Keep up the good work!
                }
                {not liked?
                    Well done!
                }
            ]],
            DIALOG_B = [[
                agent:
                    Our support level is okay.
                    We should win if we don't make any mistakes, but one mistake could be a huge setback.
                {liked?
                    I expected more from you, {player}.
                }
                {not liked and not disliked?
                    I was hoping a little more, but this is acceptable.
                }
                {disliked?
                    Still, it's better than what we had before.
                }
            ]],
            DIALOG_C = [[
                agent:
                    Our support level is not that great.
                    It's not a definite loss, but you need to work way harder than this.
                {not loved?
                    I was hoping you can do more, {player}.
                }
                {loved?
                    Don't worry, we have plenty of time.
                }
                {disliked?
                    Then again, I didn't expect much from you, anyway.
                }
            ]],
            DIALOG_D = [[
                agent:
                    Our support level is really bad.
                    We're not out yet, but you need to work way harder.
                {disliked?
                    However, I doubt that you will actually able to do that, judging by your previous performance.
                }
                {not disliked and not loved?
                    You have one last chance, {player}.
                    Don't disappoint me.
                }
                {loved?
                    I would say don't sweat it, but you really should start worrying.
                    I'll try my best to help you, as always.
                }
            ]],
            DIALOG_F = [[
                agent:
                    This is terrible.
                    Our support level is so low, I don't think anyone will vote for us.
                {loved?
                    Still, there's always a chance, right?
                    We just have to somehow pull it through.
                }
                {not loved?
                    That was really disappointing, {player}.
                    Clearly I have made a mistake in choosing you as a candidate.
                }
            ]],

            DIALOG_UNLOCK_SKIP = [[
                agent:
                    I feel condifent about your ability to lead.
                    If you think your time is better spent elsewhere, you could forgo a rally.
                player:
                    Really?
                agent:
                    It's an option.
                    Personally, I wouldn't recommend it, but if you have lots to do, and not enough time, you have this option.
                    As long as we have enough support, it shouldn't be any problem.
            ]],

            DIALOG_POST_INTERVIEW_GOOD_SUPPORT = [[
                agent:
                {good_interview?
                    And the interview!
                    What a performance!
                }
                {bad_interview?
                    However, there's one thing I don't like, and that's your interview.
                    If we weren't so much ahead in terms of support, we would be screwed.
                }
                {not good_interview and not bad_interview?
                    The interview is nothing special, but it doesn't have to be.
                    We're already ahead.
                    Although I wish the interview is much better than what you have here.
                }
            ]],
            DIALOG_POST_INTERVIEW_BAD_SUPPORT = [[
                agent:
                {good_interview?
                    At least we have a good interview.
                    That will boost our popularity.
                }
                {bad_interview?
                    And on top of it, that interview was terrible.
                    I'm really disappointed by how terrible it went.
                }
                {not good_interview and not bad_interview?
                    The interview was a great chance that can help us get out of this mess.
                    You completely missed it.
                    But at least, you didn't further ruin our support, so that's something.
                }

            ]],
            DIALOG_POST_DEBATE_GOOD_SUPPORT = [[
                agent:
                {good_debate?
                    And that was an amazing debate!
                    You really made a good impression on all of those people!
                    Well done!
                }
                {bad_debate?
                    Although that debate was terrible.
                    Your popularity was drowned out by other candidates' performance.
                    We need to figure something out soon before your popularity goes to waste.
                }
                {not good_debate and not bad_debate?
                    Your performance is overshadowed by {1#agent}.
                    But I'm sure you will be fine.
                }
            ]],
            DIALOG_POST_DEBATE_BAD_SUPPORT = [[
                agent:
                {good_debate?
                    At least you showed off during the debate.
                    Let's just hope that is enough to save the campaign.
                }
                {bad_debate?
                    And, on top of that, you didn't even stand out during the debate!
                    How are we supposed to gain support if no one notices you?
                }
                {not good_debate and not bad_debate?
                    If you could only beat {1#agent} in popularity. That way there's a chance that our campaign can still be salvaged.
                    But still, you are still popular enough in the debate.
                    At least that's something.
                }
            ]],
        }
        :Fn(function(cxt)
            -- the idea here is that the advisor check how much they support you
            -- instead of the general public to further their agenda
            local support_level = DemocracyUtil.GetSupportForAgent(cxt:GetAgent())
            local expectation = DemocracyUtil.GetCurrentExpectation()
            local delta = support_level - expectation
            
            local RANGE = 4 + 3 * cxt.quest:GetRank()
            local rank = clamp( math.round((RANGE * #RANKS / 2 - delta) / RANGE) ,1, #RANKS)
            
            cxt.enc.scratch.loved = cxt:GetAgent():GetRelationship() == RELATIONSHIP.LOVED
            cxt:Quip(
                cxt:GetAgent(),
                "summary_banter",
                cxt.player:GetContentID(),
                "day_" .. (TheGame:GetGameState():GetActProgress() or 0),
                cxt.enc.scratch.loved and "loved"
            )
            cxt:Dialog("DIALOG_INTRO")
            -- for rank, data in pairs(RANKS) do
            --     if (not data.min or delta >= data.min) and (not data.max or delta <= data.max) then
                    
            --         cxt:Dialog("DIALOG_" .. rank)
            --         if not cxt.enc.scratch.loved then
            --             cxt:GetAgent():OpinionEvent(OPINION["SUPPORT_EXPECTATION_" .. rank])
            --         end
            --         break
            --     end
            -- end
            cxt:Wait()
            TheGame:FE():InsertScreen( DemocracyClass.Screen.SupportScreen(nil, function(screen)
                cxt.enc:ResumeEncounter()
            end) )
            cxt.enc:YieldEncounter()
            cxt:Dialog("DIALOG_" .. RANKS[rank])
            if cxt.quest.param.parent_quest then
                local parent_quest = cxt.quest.param.parent_quest
                -- If you did interview on a particular day, comment on that
                if parent_quest.param.did_interview then
                    cxt.quest.param.good_interview = parent_quest.param.good_interview
                    cxt.quest.param.bad_interview = parent_quest.param.bad_interview
                    cxt:Dialog(rank <= 3 and "DIALOG_POST_INTERVIEW_GOOD_SUPPORT" or "DIALOG_POST_INTERVIEW_BAD_SUPPORT")
                    if cxt.quest.param.good_interview then
                        rank = math.max(1, rank - 1)
                    elseif cxt.quest.param.bad_interview then
                        rank = math.min(#RANKS, rank + 1)
                    end
                end
                if parent_quest.param.did_debate_scrum then
                    cxt.quest.param.good_debate = parent_quest.param.good_debate
                    cxt.quest.param.bad_debate = parent_quest.param.bad_debate
                    cxt:Dialog(rank <= 3 and "DIALOG_POST_DEBATE_GOOD_SUPPORT" or "DIALOG_POST_DEBATE_BAD_SUPPORT", parent_quest.param.popularity_rankings[1])
                    if cxt.quest.param.good_debate then
                        rank = math.max(1, rank - 1)
                    elseif cxt.quest.param.bad_debate then
                        rank = math.min(#RANKS, rank + 1)
                    end
                end
            end
            if not cxt.enc.scratch.loved then
                cxt:GetAgent():OpinionEvent(OPINION["SUPPORT_EXPECTATION_" .. RANKS[rank]])
            end
            if cxt:GetAgent():GetRelationship() > RELATIONSHIP.NEUTRAL then
                cxt:Dialog("DIALOG_UNLOCK_SKIP")
                TheGame:GetGameState():GetMainQuest().param.allow_skip_side = true
            end
            if cxt:GetAgent():GetRelationship() == RELATIONSHIP.HATED then
                cxt:GoTo("STATE_FAILURE")
            else
                cxt:GoTo("STATE_PAY")
            end
        end)
    :State("STATE_FAILURE")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    I will no longer support your campaign.
                player:
                    What? You can't do that!
                agent:
                    I can.
                    And judging by your performance, I will.
                    It is clearly a mistake supporting you.
                player:
                    What?
                    What am I supposed to do now?
                agent:
                    I don't care.
                    Do whatever you want.
                    If you are lucky, you can find a place to live.
                    One thing for sure: you aren't welcome here anymore.
            ]],
            DIALOG_LAST_CHANCE = [[
                player:
                    Please, just give me one last chance.
                agent:
                    Why should I?
                player:
                    I promise I'll do better tomorrow.
                agent:
                    I'd rather have results than empty promises.
                player:
                    Plus, I have this cool grift that gives me a second chance when I lose.
                agent:
                    In that case, sure.
                    You have one last chance.
                    Don't fail me.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            DemocracyUtil.AddAutofail(cxt, function(cxt)
                cxt:Dialog("DIALOG_LAST_CHANCE")
                cxt:GoTo("STATE_PAY")
            end)
        end)
    :State("STATE_PAY")
        :Loc{
            DIALOG_PAY = [[
                agent:
                    !permit
                    Here's your pay of the day.
                    Spend it wisely.
            ]],
            DIALOG_PAY_PST = [[
                player:
                    !take
                    Thanks.
                agent:
                    You still have some free time.
                    Go to bed when you're ready.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_PAY")
            local money = DemocracyUtil.TryMainQuestFn("CalculateFunding")
            cxt.enc:GainMoney(money)
            cxt:Dialog("DIALOG_PAY_PST")
            cxt.quest:Complete()
            -- DemocracyUtil.StartFreeTime()
            StateGraphUtil.AddEndOption(cxt)
        end)