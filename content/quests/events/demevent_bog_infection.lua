local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}

QDEF:AddConvo()
    :ConfrontState("CONF")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You are walking down the road normally until you suddenly tripped!
                player:
                    !left
                    !injured
                    Hesh spit!
                * Just like the forced rook event, you are now infected by the bog!
                * Unlike that event, you can treat it before it's too late!
                * ...Can you?
            ]],
            OPT_TREAT = "Use a first-aid item...",
            DIALOG_TREAT = [[
                * [p] You use the {1#card} to treat your infection.
                * [p] You thought battle items are useless.
                * Who's laughing now?
            ]],
            OPT_USE_FIRST_AID = "[{1#graft}] Use your first aid knowledge",
            DIALOG_USE_FIRST_AID = [[
                * [p] You use your boon to treat the infection.
                * Finally, some purpose to that boon!
            ]],
            OPT_IGNORE = "Ignore the infection",
            DIALOG_IGNORE = [[
                * [p] Or you can ignore it like a champ.
                * Hope you've got your vaccine.
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