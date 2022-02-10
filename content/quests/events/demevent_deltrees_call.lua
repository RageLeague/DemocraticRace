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
				delto:
					Unbelievable. Unbelievable!
					!angrypalm
					The Havarians decide to create a democracy the moment I come on vacation.
				player:
					!crossed
					Now what's wrong with Democracy, then?
				delto:
					What's wrong? Half of you people can't even read!
					You're all straining the relations between Deltree and Havaria, and that makes my job harder!
				]],
				
			OPT_NEGOTIATE = "[p] Negotiate with {agent}.",
			DIALOG_NEGOTIATE_DELTO = [[
				player:
					!nudgenudge
					Well who said it was a <i>real</> democracy?
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
				player:
					Our Havarian democracy is built on the core priniciples of any good Deltrean colony.
					!eureka
					Yes, corruption and deciet runs rampant, but we also show all the values Deltree champions!
					Freedom, Opportunity, and-
				delto:
					!palm
					Don't tell me you idiots fell for those propaganda posters as well.
					All you self-righteous idiots are going to cause a war, just you watch!
				]],
				
	--[[You show him a half-compotent poster. He gets genuinely worried about the fate of Havarian-Deltrean relations.]]
	
			OPT_SHOW_POSTER = "Show {agent} a poster",
			DIALOG_BAD_POSTER = [[
				player:
					Now I'd say we're on track to keeping Havaria right under Deltree's thumb. 
					!give
					Just look at some of the material they're using to get elected.
				delto:
					This is...
					!neutral
					Wow.
					This is actually rather inspiring now that I look at it.
					!angry
					It shouldn't be!
					It's going to make people want to keep this democracy and not go back to Deltrean rule!
					Unbelievable. You politicians are going to cause a war, just you wait. 
				]],
			
	--[[You show him a bad poster. He's reassured in his superiority complex over Havarians]]
	
			DIALOG_GOOD_POSTER = [[
				player:
					!chuckle
					You think this is a real democracy? Just look at the kind of material the politicans are passing out.
					!give
				delto:
					!take
					What is this? Did you draw this on the back of a cocktail napkin?
				player:
					!hips
					I drew it on the hopes it would get me elected.
					!happy
					And people just eat this stuff up! It's incredible!
				delto:
					Wow. I thought Deltree was bad.
					This kind of shabby oughta give us leverage when we force this whole "democracy" into the abyss.
					!give
					Say...here's some money that says you keep Havaria on this kind of downward spiral. Whatdya say?
				player:
					!take
					I say "Long live Deltree!".
				delto:
					!happy
					Right you are!
					!exit
				]],
			
			OPT_IGNORE = "Ignore {agent}.",
			DIALOG_IGNORE_DELTREAN = [[
				player:
					!shrug
					So? Deltree can either accept that we're free, or they can go shuck clams.
					I'm just a politician, what can I say?
				delto:
					!angrypoint
					You can say lots of things! Like how Havaria won't start a war with Deltree!
				player:
					!chuckle
					What'd you take me for, an Oracle?
				delto:
					I took you for someone not willing to <i> Make my job a living Heshian Hell.</>
				player:
					You took me wrong, I guess. Now mosey on back to the mainland, hm?
					!exit
				delto:
					!exit
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
                                    cxt:Dialog("DIALOG_GOOD_POSTER")
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                else
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
