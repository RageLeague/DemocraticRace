local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}
:AddCastByAlias{
  cast_id = "delto",
  alias = "DELTREAN_DIGNITARY",
  no_validation = true,
}

local GOOD_POSTERS = {"PROP_PO_SUPERFICIAL", "PROP_PO_MESSY"} --delto likes bad posters and dislikes good posters.
local BAD_POSTERS = {"PROP_PO_INSPIRING", "PROP_PO_THOUGHT_PROVOKING", "PROP_PO_MEDIOCRE"}
:AddOpinionEvents{
    democracy_is_funny_joke =
    {
        delta = OPINION_DELTAS.LIKE,
        txt = "Convinced them Havarian Democracy is a ruse.",
    },
	ugh_democracy = 
	{
		delta = OPINION_DELTAS.DISLIKE,
		txt = "Convinced them Havarian Democracy is the end of the status quo.",
	},
}

QDEF:AddConvo()
    :ConfrontState("CONFRONT", function() return true end)
		:Loc{
			DIALOG_INTRO_DELTREAN = [[
				delto:
					!right
					!angry
				player:
					!left
				* [p]{delto} is angry about the fact that Havaria has a democracy.
				* {delto} was going to make at least one reference to the fact Havarians might not know how to read.
				]],
				
			OPT_NEGOTIATE = "[p] Negotiate with {agent}.",
			DIALOG_NEGOTIATE_DELTO = [[
				* You tell {delto} that there's nothing to worry about.
				]],
				
	--[[You tell Delto-dude that the democracy is a ruse. He's relieved.]]
				
			DIALOG_NEGOTIATE_DELTO_SUCCESS = [[
				player:
					Well of course it's all a ruse.
					Most of the people running are just looking for power all the same.
					Just look at me, one of the politicians. I know this better than anyone!
				agent:
					!angry
					...
					!happy
					So just like the mainland, I see?
					For a second, I thought you Havarians could get over your petty differences and be civil.
					!chuckle
					Glad I was wrong, though.
					!give
					Say...keep Havaria dependent on Deltree, and you'll see a lot more of this in the future.
				player:
					!take
					Why of course. The Democracy is safe in my hands.
				]],
				
	--[[You act too inspirational about democracy. He thinks it's a ploy to get out of deltrean rule]]
				
			DIALOG_NEGOTIATE_DELTO_FAILURE = [[
				* [p] You accidentally act too inspirational.
				* {delto} is extra angry now.
				]],
				
			OPT_SHOW_POSTER = "Show {agent} a poster",
			DIALOG_BAD_POSTER = [[
				* [p] You show {agent} a bad poster.
				* She gets miffed.
				]],
			
			DIALOG_GOOD_POSTER = [[
				* [p] You show {agent} a good poster.
				* She is happy.
				]],
			
			OPT_IGNORE = "Ignore {agent}.",
			DIALOG_IGNORE_DELTREAN = [[
				* [p]{delto} is angry-ier.
				* {delto.HeShe} reinvents language just to communicate this angry-ness.
				]],
			}
            :Fn(function(cxt)
                cxt.quest:Complete()
                local posters = {}
                            for i, card in ipairs(cxt.player.negotiator.cards.cards) do
                                if card.id == "propaganda_poster" then
                                    table.insert(posters, card)
                                end
                            end
                cxt:TalkTo(cxt:GetCastMember("delto"))
                cxt:Dialog("DIALOG_INTRO_DELTREAN")
                cxt:Opt("OPT_NEGOTIATE")
                    :Negotiation{
                        on_success = function(cxt) 
                            cxt:Dialog("DIALOG_NEGOTIATE_DELTO_SUCCESS")
                            cxt.quest:OpinionEvent("delto", "democracy_is_funny_joke")
                            cxt.encounter:GainMoney( 100 )
                            StateGraphUtil.AddLeaveLocation(cxt)
                        end,
                        on_fail = function(cxt)
                            cxt:Dialog("DIALOG_NEGOTIATE_DELTO_FAILURE")
                            cxt.quest:OpinionEvent("delto", "ugh_democracy")
                            StateGraphUtil.AddLeaveLocation(cxt)
                        end,}
                if #posters > 0 then
                    cxt:Opt("OPT_SHOW_POSTER")
                                -- local cards = agent.negotiator:GetCards()
                        :Fn(function(cxt)
                            cxt:Wait()
                            DemocracyUtil.InsertSelectCardScreen(
                                posters,
                                cxt:GetLocString("SELECT_TITLE"),
                                cxt:GetLocString("SELECT_DESC"),
                                nil,
                                function(card)
                                    cxt.enc:ResumeEncounter( card )
                                end
                            )
                            local card = cxt.enc:YieldEncounter()
                            if card then
                                --mini block for item usage.
                                card:ConsumeCharge()
                                if card:IsSpent() then
                                    cxt.player.negotiator:RemoveCard( card )
                                end
                                if table.contains(GOOD_POSTERS, CheckPoster(card)) then
                                    print("Poster good")
                                    cxt:Dialog("DIALOG_GOOD_POSTER")
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                else
                                    print("Poster bad")
                                    cxt:Dialog("DIALOG_BAD_POSTER")
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                end
                            end
                        end)
                end
                cxt:Opt("OPT_IGNORE")
                    :Dialog("DIALOG_IGNORE_DELTREAN")
                    :ReceiveOpinion("ugh_democracy")
                    :Travel()
            end)