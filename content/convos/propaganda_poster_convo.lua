Convo("PROPAGANDA_POSTER_CONVO")
    :State("STATE_READ")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    !right
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
                    !exit
                * Looks like you got a new follower.
            ]],
            DIALOG_LOSE = [[
                agent:
                    Wow this person sucks.
                    I'm never voting for {player.himher}!
                    !exit
                * Oh no.
            ]],
            DIALOG_IGNORE = [[
                agent:
                    Just another propaganda poster.
                    Hardly worth reading.
                    !exit
                * I mean... {agent.HeShe}'s not wrong.
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
            if true then
                cxt:Dialog("DIALOG_INTRO")
                cxt:Opt("OPT_WATCH")
                    :Negotiation{
                        -- target_agent = cxt:GetCastMember("agent"),
                        on_start_negotiation = function(minigame)
                            propaganda_mod = minigame:GetPlayerNegotiator():CreateModifier("PROPAGANDA_POSTER_MODIFIER", 1)
                            propaganda_mod.play_per_turn = 3
                            propaganda_mod:SetData(propaganda_data.imprints, propaganda_data.prop_mod, 15)

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
                            cxt:GetAgent():OpinionEvent(OPINION.CONVINCE_SUPPORT)
                            if cxt.quest and cxt.quest.param.liked_people then
                                cxt.quest.param.liked_people = cxt.quest.param.liked_people + 1
                            end
                            StateGraphUtil.AddEndOption(cxt)
                        end,
                        on_fail = function(cxt,minigame)
                            if propaganda_mod.out_of_cards then
                                cxt:Dialog("DIALOG_IGNORE")
                            else
                                cxt:Dialog("DIALOG_LOSE")
                                cxt:GetAgent():OpinionEvent(OPINION.FAIL_CONVINCE_SUPPORT)
                                if cxt.quest and cxt.quest.param.disliked_people then
                                    cxt.quest.param.disliked_people = cxt.quest.param.disliked_people + 1
                                end
                            end
                            StateGraphUtil.AddEndOption(cxt)
                        end,
                    }
            end
        end)
    -- :Hub(function(cxt,who)
    
    --     cxt:Opt("DEFAULT_NEGOTIATION_REASON", who)
    --         -- :Fn(function(cxt)
    --         --     cxt:ReassignCastMember('agent', who)
    --         -- end)
    --         :GoTo("STATE_READ")
    -- end)