local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    is_negative = true,
}

QDEF:AddConvo()
    :ConfrontState("CONF")
        :Loc{
            DIALOG_INTRO = [[
                * You can't deny it anymore. That odd prick on your arm wasn't just a mosquito.
                * Something is in you. <i>Coursing</> through you. An infection flowing through your veins.
                * You still have precious minutes left before it truly takes hold.
            ]],
            OPT_TREAT = "Use a first-aid item...",
            DIALOG_TREAT = [[
                * You open {1#card} and use it's contents however you can.
                * Eventually, you feel the pain subside, then fade.
                * ...
                * You're not protected forever. You could say no one is.
                * But for now, the infection has been smothered. You won't feel the effects of it.
            ]],
            OPT_USE_FIRST_AID = "[{1#graft}] Use your first aid knowledge",
            DIALOG_USE_FIRST_AID = [[
                * A little impromptu triage. It's not the safest, but it's the best you can do.
                * Eventually, you feel the pain subside, then fade.
                * ...
                * You're not protected forever. You could say no one is.
                * But for now, the infection has been smothered. You won't feel the effects of it.
            ]],
            OPT_IGNORE = "Ignore the infection",
            DIALOG_IGNORE = [[
                * You don't have any options at the moment. The closest you can do is run to the nearest medic.
                * But you already know there's no way you could run fast enough. The infection is already showing...
            ]],

            SELECT_TITLE = "Select a card",
            SELECT_DESC = "Choose a first aid item to treat the infection, consuming 1 use on it",
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                cxt:Dialog("DIALOG_INTRO")
            end

            local graft = cxt.player.graft_owner:FindGraft( function(graft)
                return graft.id == "first_aid"
            end )

            local cards = {}
            for i, card in ipairs(cxt.player.battler.cards.cards) do
                print(card.id)
                if DemocracyUtil.IsFirstAid(card) then
                    table.insert(cards, card)
                end
            end

            cxt:Opt("OPT_TREAT")
                :Fn(function(cxt)
                    cxt:Wait()
                    DemocracyUtil.InsertSelectCardScreen(
                        cards,
                        cxt:GetLocString("SELECT_TITLE"),
                        cxt:GetLocString("SELECT_DESC"),
                        Widget.BattleCard,
                        function(card)
                            cxt.enc:ResumeEncounter( card )
                        end
                    )
                    local card = cxt.enc:YieldEncounter()
                    if card then
                        card:ConsumeCharge()
                        if card:IsSpent() then
                            cxt.player.battler:RemoveCard( card )
                        end
                        cxt:Dialog("DIALOG_TREAT", card)
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end
                end)

            if graft then
                cxt:Opt("OPT_USE_FIRST_AID", graft)
                    :Dialog("DIALOG_USE_FIRST_AID")
                    :Travel()
            end

            cxt:Opt("OPT_IGNORE")
                :Dialog("DIALOG_IGNORE")
                :Fn(function(cxt)
                    cxt:GainCards{"twig", "stem"}
                end)
                :Travel()
        end)
