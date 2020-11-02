local RANKS = {
    S = {min = 11},
    A = {min = 4, max = 10},
    B = {min = -3, max = 3},
    C = {min = -10, max = -4},
    D = {min = -17, max = -11},
    F = {max = -18},
}
Convo("SUPPORT_SUMMARY_CONVO")
    :State("STATE_SUMMARY")
        :Loc{
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
                    Look at this! We have so much support!
                    I'm not saying that we definitely will win the election, but we most likely will.
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
                    We're probably winning, but one mistake could be a huge setback.
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
        }
        :Fn(function(cxt)
            -- the idea here is that the advisor check how much they support you
            -- instead of the general public to further their agenda
            local support_level = DemocracyUtil.GetSupportForAgent(cxt:GetAgent())
            local expectation = DemocracyUtil.GetCurrentExpectation()
            local delta = support_level - expectation
            cxt.enc.scratch.loved = cxt:GetAgent():GetRelationship() == RELATIONSHIP.LOVED

            for rank, data in pairs(RANKS) do
                if (not data.min or delta >= data.min) and (not data.max or delta <= data.max) then
                    
                    cxt:Dialog("DIALOG_" .. rank)
                    if not cxt.enc.scratch.loved then
                        cxt:GetAgent():OpinionEvent(OPINION["SUPPORT_EXPECTATION_" .. rank])
                    end
                    break
                end
            end
            if cxt:GetAgent():GetRelationship() == RELATIONSHIP.HATED then
                cxt:GoTo("STATE_FAILURE")
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
                    I don't know.
                    Find another advisor, end the campaign, whatever.
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
            end)
        end)