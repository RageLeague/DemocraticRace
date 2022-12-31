local QDEF = QuestDef.Define
{
    qtype = QTYPE.SCENARIO,
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}
:AddCast{
    cast_id = "admiralty",
    condition = function ( agent, quest )
        if agent:GetFactionID() ~= "ADMIRALTY" then
            return false, "Agent is not Admiralty"
        end
        return true
    end,
    events = {
        agent_retired = function(quest, agent)
            quest:Cancel()
        end,
    },
    unimportant = true,
}

QDEF:AddConvo("start", "admiralty")
    :AttractState("ATTRACT")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You see {admiralty} just chilling.
                player:
                    !bashful
                    So, uhh... This is awkward.
                {not disliked?
                    agent:
                        !handwave
                        Eh, I don't care anymore.
                }
                {disliked?
                    agent:
                        !crossed
                        You don't say.
                        Lucky you, I'm not going to take you in right now.
                }
                {tried_parasite_silence?
                    The whole "information control" thing was futile anyway.
                    Word will eventually get out, and nothing we would have mattered.
                }
                {disliked?
                    agent:
                        !throatcut
                        But one wrong move...
                    player:
                        Yeah, sure, whatever.
                }
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Complete()
        end)
