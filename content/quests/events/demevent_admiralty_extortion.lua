local CHANCE_FOR_ENEMY = .35

local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}

:AddCast{
    cast_id = "admiralty",
    condition = function ( agent, quest )
        return agent:GetFactionID() == "ADMIRALTY"
    end
}

:AddCast{
    cast_id = "laborer",
    condition = function ( agent, quest )
        return not agent:GetFactionID() == "ADMIRALTY" and DemocracyUtil.GetWealth(agent) <= 2
    end,
}

QDEF:AddConvo()
    :ConfrontState("STATE_INTERVENE")
        :Loc{
            DIALOG_INTRO = [[
                admiralty:
                    !left
                laborer:
                    !right
                    !injured
                * You see {admiralty} trying to extort {laborer}.
                admiralty:
                    Hand over the money and you'll be fine.
                laborer:
                    Please.. I need this to feed my family.

            ]],
            DIALOG_EXTORT = [[
                player:
                    !left
                    [p] give {admiralty.himher} the money, it's for your own good.
            ]],
            DIALOG_DEFEND = [[
                admiralty:
                    !right
                player:
                    !left
                    Hey! Let him be!
                admiralty:
                    How dare you? You can't give me orders!
            ]],
            DIALOG_LEAVE = [[
                * You pretend to not have seen anything and slip away unnoticed.
            ]],
            DIALOG_BEAT = [[
                laborer:
                    !right
                    !injured
                    Have mercy! Just take the money and go.
            ]],
            DIALOG_DEFENDED = [[
                laborer:
                    !right
                    Thank you, stranger! I won't forget this.
                admiralty:
                    !right
                    !injured
                    You'll regret this, {player}.
            ]],
            OPT_EXTORT = "Convince {laborer} to give money to {admiralty}",
            OPT_DEFEND = "Convince {admiralty} to leave {laborer} alone",
            OPT_LEAVE = "Leave before anyone sees you"
        }

        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                cxt:Dialog("DIALOG_INTRO")
            end

            cxt:Opt("OPT_EXTORT")
                :Dialog("DIALOG_EXTORT")
                :Negotiation{
                    flags = NEGOTIATION_FLAGS.INTIMIDATION,
                    -- allies = { "admiralty" },
                    -- enemies = { "laborer" },
                    on_win = function(cxt)
                        
                    end
                }

            cxt:Opt("OPT_DEFEND")
                :Dialog("DIALOG_DEFEND")
                :Negotiation{
                    -- flags = BATTLE_FLAGS.SELF_DEFENCE,
                    -- allies = { "laborer" },
                    -- enemies = { "admiralty" },
                    on_win = function(cxt)
                        -- if cxt:GetCastAgent("laborer"):IsDead() then
                        --     cxt:Dialog("DIALOG_STALEMATE")
                        -- else
                        --     if cxt:GetCastAgent("admiralty"):IsDead() then
                        --         cxt:Dialog("DIALOG_DEFENDED_KILL")
                        --     else
                        --         cxt:Dialog("DIALOG_DEFENDED")
                        --         cxt:GetCastAgent("admiralty"):OpinionEvent(OPINION.REFUSED_TO_HELP)
                        --     end
                        -- end
                        -- StateGraphUtil.AddLeaveLocation(cxt) 
                    end
                } 

            cxt:Opt("OPT_LEAVE")
                :Dialog("DIALOG_LEAVE")
                :Travel()

        end)