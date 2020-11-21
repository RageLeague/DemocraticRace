Convo("PROPAGANDA_POSTER_CONVO")
    :Loc{
        OPT_TAKE_DOWN = "Ask {agent} to take down the posters",
        DIALOG_TAKE_DOWN = [[
            player:
                Can you take down the poster?
            agent:
                What? You don't like it?
            player:
                It served its purpose.
                !handwave
                I don't need it anymore.
            agent:
                !shrug
                Suit yourself, I guess.
        ]],
    }
    :Hub(function(cxt, who)
        if who and DemocracyUtil.IsDemocracyCampaign(cxt.act_id) then
            if cxt.location:HasMemory("HAS_PROPAGANDA_POSTER") and who == cxt.location:GetProprietor() then
                cxt:Opt("OPT_TAKE_DOWN")
                    :PreIcon(global_images.removenegotiation)
                    :Dialog("DIALOG_TAKE_DOWN")
                    :Fn(function(cxt)
                        cxt.location:Forget("HAS_PROPAGANDA_POSTER")
                    end)
            end
        end
    end)
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
            DIALOG_INTRO_AGAIN = [[
                * Another person shows up.
                agent:
                    !right
                    !thought
                    Hmm...
                * It seems more people are interested in poster.
                * Hopefully the posters will work for them.
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
                    It was an interesting read, but not enough to convince me.
                    Maybe try harder next time. I might actually be convinced!
                    !exit
                * That sounds very passive aggressive for no good reason.
                * Still, it let some people know what you stand for, so at least that's good.
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
            if cxt.quest then
                cxt.enc.scratch.readers = cxt.quest.param.readers
            end
            if cxt.enc.scratch.readers then
                cxt.location:Remember("DID_PROPAGANDA_TODAY")
                cxt:RunLoop(function(cxt)
                    if #cxt.enc.scratch.readers == 0 then
                        StateGraphUtil.AddEndOption(cxt)
                        return
                    else
                        cxt:TalkTo(table.remove(cxt.enc.scratch.readers))
                    end
                    if cxt:FirstLoop() then
                        cxt:Dialog("DIALOG_INTRO")
                    else
                        cxt:Dialog("DIALOG_INTRO_AGAIN")
                    end
                    cxt:Opt("OPT_WATCH")
                        :Negotiation{
                            -- target_agent = cxt:GetCastMember("agent"),
                            on_start_negotiation = function(minigame)
                                propaganda_mod = minigame:GetPlayerNegotiator():CreateModifier("PROPAGANDA_POSTER_MODIFIER", 1)
                                -- propaganda_mod.play_per_turn = 3
                                propaganda_mod:SetData(propaganda_data.imprints, propaganda_data.prop_mod, 5 + 5 * minigame:GetDifficulty())

                                minigame:GetPlayerNegotiator():FindCoreArgument():SetShieldStatus(true, cxt:GetLocString("SHIELD_DESC"))
                                local alt_lose = minigame:GetPlayerNegotiator():CreateModifier("ALTERNATIVE_CORE_ARGUMENT", 1)
                                alt_lose.tracked_modifier = propaganda_mod

                                -- for i, card in minigame:GetDrawDeck():Cards() do
                                --     card:TransferCard( minigame:GetTrashDeck() )
                                --     print("Trashed card")
                                -- end
                                -- table.clear(minigame.start_params.cards)
                                minigame:GetPlayerNegotiator():CreateModifier("NO_PLAY_FROM_HAND", 1)
                                
                            end,
                            on_success = function(cxt, minigame)
                                cxt:Dialog("DIALOG_WIN")
                                cxt:GetAgent():OpinionEvent(OPINION.CONVINCE_SUPPORT)
                                if cxt.quest and cxt.quest.param.liked_people then
                                    cxt.quest.param.liked_people = cxt.quest.param.liked_people + 1
                                end
                                -- StateGraphUtil.AddEndOption(cxt)
                            end,
                            on_fail = function(cxt,minigame)
                                local core = minigame:GetOpponentNegotiator():FindCoreArgument()
                                local resolve_left = core and core:GetResolve()
                                if not resolve_left or resolve_left <= 10 then
                                    cxt:Dialog("DIALOG_IGNORE")
                                    if cxt.quest and cxt.quest.param.ignored_people then
                                        cxt.quest.param.ignored_people = cxt.quest.param.ignored_people + 1
                                    end
                                else
                                    cxt:Dialog("DIALOG_LOSE")
                                    cxt:GetAgent():OpinionEvent(OPINION.FAIL_CONVINCE_SUPPORT)
                                    if cxt.quest and cxt.quest.param.disliked_people then
                                        cxt.quest.param.disliked_people = cxt.quest.param.disliked_people + 1
                                    end
                                end
                                -- StateGraphUtil.AddEndOption(cxt)
                            end,
                        }
                end)
            end
        end)
    :ConfrontState("STATE_CONF", function(cxt)
        return cxt.location and cxt.location:HasMemory("HAS_PROPAGANDA_POSTER") and not cxt.location:HasMemory("DID_PROPAGANDA_TODAY", 1)
    end)
        :Loc{
            DIALOG_INTRO = [[
                * As you enter {1#location}, you saw {2*one person|several people} looking at the posters.
            ]],
        }
        :Fn(function(cxt)
            cxt.location:Remember("DID_PROPAGANDA_TODAY")
            local candidates = {}
            for i, agent in cxt.location:Agents() do
                if agent:IsSentient() and not agent:IsInPlayerParty() and
                    not AgentUtil.HasPlotArmour(agent) and agent ~= cxt.location:GetProprietor()
                    and agent:GetRelationship() == RELATIONSHIP.NEUTRAL then

                    table.insert(candidates, agent)
                end
            end
            if #candidates > 0 then
                cxt.enc.scratch.readers = {}
                for i, agent in ipairs(candidates) do
                    if math.random() < 0.33 then
                        table.insert(cxt.enc.scratch.readers, agent)
                    end
                    
                end
                if #cxt.enc.scratch.readers > 0 then
                    cxt:Dialog("DIALOG_INTRO", cxt.location, #cxt.enc.scratch.readers)
                    cxt:GoTo("STATE_READ")
                end
            end
        end)
    -- :Hub(function(cxt,who)
    
    --     cxt:Opt("DEFAULT_NEGOTIATION_REASON", who)
    --         -- :Fn(function(cxt)
    --         --     cxt:ReassignCastMember('agent', who)
    --         -- end)
    --         :GoTo("STATE_READ")
    -- end)