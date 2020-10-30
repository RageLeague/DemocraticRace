Convo("PROPAGANDA_POSTER_CONVO")
    :State("STATE_READ")
        :Loc{
            DIALOG_INTRO = [[
                target:
                    !thought
                    Hmm...
                * You step aside, and see the propaganda poster do its work.
                * Hopefully.
            ]],
            OPT_WATCH = "Watch the scene unfold",
            DIALOG_WIN = [[
                target:
                    So true!
                    This person's got my vote.
                * Looks like you got a new follower.
            ]],
            DIALOG_LOSE = [[
                target:
                    Wow this person sucks.
                    I'm never voting for {player.himher}!
                * Oh no.
            ]],
            DIALOG_IGNORE = [[
                target:
                    Just another propaganda poster.
                    Hardly worth reading.
                * I mean... {target.HeShe}'s not wrong.
            ]],
            SHIELD_DESC = "Your core resolve can't be attacked. However, if your propaganda poster is destroyed, you lose the negotiation.",
        }
        :Fn(function(cxt)
            local propaganda_mod
            local propaganda_data = cxt.location:HasMemory("HAS_PROPAGANDA_POSTER")
            if not propaganda_data then
                propaganda_data = {
                    imprints = {"fast_talk", "fast_talk", "fast_talk"},
                    prop_mod = "PROP_PO_MEDIOCRE",
                }
            end
            if propaganda_data then
                cxt:Dialog("DIALOG_INTRO")
                cxt:Opt("OPT_WATCH")
                    :Negotiation{
                        target_agent = cxt:GetCastMember("target"),
                        on_start_negotiation = function(minigame)
                            propaganda_mod = minigame:GetPlayerNegotiator():CreateModifier("PROPAGANDA_POSTER_MODIFIER", 1)
                            propaganda_mod:SetData(propaganda_data.imprints, propaganda_data.prop_mod, 20)
                            
                            minigame:GetPlayerNegotiator():FindCoreArgument():SetShieldStatus(true, cxt:GetLocString("SHIELD_DESC"))
                            local alt_lose = minigame:GetPlayerNegotiator():CreateModifier("ALTERNATIVE_CORE_ARGUMENT", 1)
                            alt_lose.tracked_modifier = propaganda_mod

                            -- for i, card in minigame:GetDrawDeck():Cards() do
                            --     card:TransferCard( minigame:GetTrashDeck() )
                            --     print("Trashed card")
                            -- end
                            table.clear(minigame.start_params.cards)
                        end,
                        on_success = function(cxt, minigame)
                            cxt:Dialog("DIALOG_WIN")
                            cxt:GetCastMember("target"):OpinionEvent(OPINION.CONVINCE_SUPPORT)
                            StateGraphUtil.AddEndOption(cxt)
                        end,
                        on_fail = function(cxt,minigame)
                            if propaganda_mod.out_of_cards then
                                cxt:Dialog("DIALOG_IGNORE")
                            else
                                cxt:Dialog("DIALOG_LOSE")
                                cxt:GetCastMember("target"):OpinionEvent(OPINION.FAIL_CONVINCE_SUPPORT)
                            end
                            StateGraphUtil.AddEndOption(cxt)
                        end,
                    }
            end
        end)
    :Hub(function(cxt,who)
    
        cxt:Opt("DEFAULT_NEGOTIATION_REASON", who)
            :Fn(function(cxt)
                cxt:ReassignCastMember('target', who)
            end)
            :GoTo("STATE_READ")
    end)