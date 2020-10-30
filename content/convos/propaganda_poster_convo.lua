Convo("PROPAGANDA_POSTER_CONVO")
    :State("STATE_READ")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    !thought
                    Hmm...
                * You step aside, and see the propaganda poster do its work.
                * Hopefully.
            ]],
            OPT_WATCH = "Watch the scene unfold",
            DIALOG_WIN = [[
                agent:
                    So true!
                    This person's got my vote.
                * Looks like you got a new follower.
            ]],
            DIALOG_LOSE = [[
                agent:
                    Wow this person sucks.
                    I'm never voting for {player.himher}!
                * Oh no.
            ]],
            DIALOG_IGNORE = [[
                agent:
                    Just another propaganda poster.
                    Hardly worth reading.
                * I mean... {agent.HeShe}'s not wrong.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt:Opt("OPT_WATCH")
                :Negotiation{
                    on_success = function(cxt, minigame)
                        cxt:Dialog("DIALOG_WIN")
                        cxt:GetAgent():OpinionEvent(OPINION.CONVINCE_SUPPORT)
                    end,
                    on_fail = function(cxt,minigame)
                    end,
                }
        end)