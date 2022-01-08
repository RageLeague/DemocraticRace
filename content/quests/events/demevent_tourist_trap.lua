local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
	on_init = function(quest)
		if math.random() >= .50 then
			cxt.quest.param.from_the_mainland = true
		else
			cxt.quest.param.from_the_mainland = false
		end
	end,
}
:AddCastByAlias{
  cast_id = "rento",
  alias = "BORDENKRA",
  no_validation = true,
}
:AddCastByAlias{
  cast_id = "delto",
  alias = "DELTREAN_DIGNITARY",
  no_validation = true,
}

:AddOpinionEvents{
    belief_in_democracy =
    {
        delta = OPINION_DELTAS.MAJOR_GOOD,
        txt = "Strengthened their belief in Havarian Democracy",
    },
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
	:Fn(function(cxt)
		if cxt.quest.param.from_the_mainland then
			cxt:GoTo("STATE_DELTREAN")
		else
			cxt:GoTo("STATE_RENTORIAN")
		end
	end)
	:State("STATE_DELTREAN")
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
			
			OPT_IGNORE = "Ignore {agent}.",
			DIALOG_IGNORE_DELTREAN = [[
				* [p]{delto} is angry-ier.
				* {delto.HeShe} reinvents language just to communicate this angry-ness.
				]],
			}
			:Fn(function(cxt)
				cxt:TalkTo(cxt:GetCastMember("delto"))
				cxt:Dialog("DIALOG_INTRO_DELTREAN")
				cxt:Opt("OPT_NEGOTIATE")
					:Negotiation{
                        on_success = function(cxt) 
							cxt:Dialog("DIALOG_NEGOTIATE_DELTO_SUCCESS")
							cxt:OpinionEvent("democracy_is_funny_joke")
							cxt.encounter:GainMoney( 100 ) --I think this matches the stakes, those being bad credit on a ghost of an NPC.
							StateGraphUtil.AddLeaveLocation(cxt)
						end,
						on_fail = function(cxt)
							cxt:Dialog("DIALOG_NEGOTIATE_DELTO_FAILURE")
							cxt:OpinionEvent("ugh_democracy")
							StateGraphUtil.AddLeaveLocation(cxt)
						end,}
				cxt:Opt("OPT_IGNORE")
					:Dialog("DIALOG_IGNORE_DELTREAN")
					:Travel()
			end)
		
	:State("STATE_RENTORIAN")
		:Loc{	
			DIALOG_INTRO_RENTORIAN = [[
				rento:
					!right
					!happy
				player:
					!left
				* {rento} is happy that Havaria is becoming democratic.
				* {rento} asks you to give {rento.himher} a good campaign speech to try and convince {rento.himher}.
				]],
				
			OPT_NEGOTIATE = "[p] Negotiate with {agent}.",
			
			DIALOG_NEGOTIATE_RENTO = [[
				* You tell {rento} your best campaign speech.
				]],
	
	--[[You sound less like you're running for kicks and more like you're going to make landmark changes. She respects that]]
			
			DIALOG_NEGOTIATE_RENTO_SUCCESS = [[
				* [p] You smooth out the worser aspects of the democracy.
				* She appreciates it and decides she supports you.
				* Of course, she can't actually support you by voting, so she instead gives you the boon.
				]],
				
	--[[You accidentally sound too corrupt. Rento-girl is worried about Havarian democracy and thinks it's hogwash.]]
			
			DIALOG_NEGOTIATE_RENTO_FAILURE = [[
				player:
					Well, this democracy is very simple.
					Vote for me, and I'll make things better.
					Vote for the other guy, and you'll regret it a lot.
				agent:
					!dubious
					Make things better for who?
				player:
					Uh...the little guy? 
					The rich?
					My supporters for sure, I know that much.
				agent:
					I don't feel convinced. This feels like a cheap power grab for the few of you running.
				player:
					...
					Isn't it supposed to be?
				agent:
					I'm going back to Rentoria.
					!exit
				]],
			
			OPT_IGNORE = "Ignore {agent}.",
			
			DIALOG_IGNORE_RENTORIAN = [[
				* {rento} is miffed.
				* {rento} is still fine, but not very happy.
				]],
			}
			:Fn(function(cxt)
				cxt:TalkTo(cxt:GetCastMember("rento"))
				cxt:Dialog("DIALOG_INTRO_RENTORIAN")
				cxt:Opt("OPT_NEGOTIATE")
					:Negotiation{
                        on_success = function(cxt) 
							cxt:Dialog("DIALOG_NEGOTIATE_RENTO_SUCCESS")
							cxt:OpinionEvent("belief_in_democracy")
							StateGraphUtil.AddLeaveLocation(cxt)
						end,
						on_fail = function(cxt)
							cxt:Dialog("DIALOG_NEGOTIATE_RENTO_FAILURE")
							StateGraphUtil.AddLeaveLocation(cxt)
						end,}
				cxt:Opt("OPT_IGNORE")
					:Dialog("DIALOG_IGNORE_RENTORIAN")
					:Travel()
			end)