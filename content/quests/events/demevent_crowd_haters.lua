local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    precondition = function(quest)
        return false --need more haters
    end,
    on_init = function(quest)

    end,
}
:AddCast{
    cast_id = "hater",
    when = QWHEN.MANUAL,
    condition = function(agent, quest)
        return agent:GetRelationship() < RELATIONSHIP.NEUTRAL or DemocracyUtil.GetAgentEndorsement(agent) < RELATIONSHIP.NEUTRAL
    end,
}

QDEF:AddConvo()
    :ConfrontState("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * As you're traveling, you run into a group of people on the way to where you're headed.
				* Upon getting closer, however, you realize what they're talking about: You. Specifically, how much you suck.
				player:
                    !left
                hater_face:
                    !right
                    !angry_accuse
                    Hey everyone! Look! It's {bad_nick}!
				hater_face2:
					!right
					{bad_stance?
						Can you believe {player.heshe} supports {bad_stance#pol_stance}? What a joke!}
					{not bad_stance?
						Can you believe {player.heshe} thinks {player.heshe} has a shot at running for office? What a joke!}
				* The crowd starts jeering at you. A public gathering this big with this kind of attitude towards you will not reflect well on your image.
            ]],
            OPT_IGNORE = "Ignore the crowd and move on",
            DIALOG_IGNORE = [[
				* You don't have time for this. You duck your head and try not to show a reaction as you move past them.
                hater_face:
					!right
					Look everyone, {bad_nick} thinks {player.heshe}'s too good for us! Isn't that right, {bad_nick}?
				* You tell yourself that if you campaign successfully, you'll earn yourself devoted supporters who'll speak louder than these hecklers can.
				* Still, you can't help but feel yourself losing resolve after such an intense encounter with so many haters.
            ]],
            OPT_APPEAL = "Appeal to the crowd",
            DIALOG_APPEAL = [[
				player:
					Hello! If I may just make a case for myself...
                hater_face:
					!right
					It looks like {bad_nick} has something to say! This should be rich.
            ]],
            DIALOG_APPEAL_SUCCESS = [[
				player:
					I'm honestly just trying to make Havaria a better place.
                hater_face2:
					!right
					I just feel bad now. I'm leaving.
					!exit
				hater_face:
					!right
					But, but, it's {bad_nick}!
				player:
					Are you done yet?
				hater_face:
					Haha... I was just kidding, yeah?
					!exit
            ]],
            DIALOG_APPEAL_PARTIAL_SUCCESS = [[
				player:
					I'm honestly just trying to make Havaria a better place.
                hater_face2:
					!right
					I just feel bad now. I'm leaving.
				hater_face:
					!right
					Don't think that your honeyed words can fool the rest of us, {bad_nick}. We're onto you.
            ]],
            DIALOG_APPEAL_FAILURE = [[
				player:
					I'm not so bad, see?
                hater_face:
					Look at {bad_nick} stumbling over {player.hisher} own words! What a buffoon!
				* The crowd erupts into laughter, and they're not laughing with you. You have no choice but to slink away with your tail between your legs.
            ]],
            OPT_USE_BODYGUARD = "Have your bodyguard disperse the crowd",
            DIALOG_USE_BODYGUARD = [[
				{guard_human?
					player:
						!hips
						{guard}. Clear this crowd for me, thank you.
					hired:
						!left
						Yes {player.honorific}.}
				{not guard_human?
					player:
						!point
						{guard}, sic 'em!
					hired:
						!left
						Grrrr!}
				* {guard} efficiently scatters the crowd. That should keep them from talking.
            ]],
            OPT_FIGHT = "Disperse the crowd yourself",
            WARNING_FIGHT = "Remember: You are a politician, not a trained warrior. This could end poorly.",
            DIALOG_FIGHT = [[
				* You let out a bloodcurdling scream and rush at the crowd.
				hater_face:
					!right
					!scared
					Look out, {bad_nick}'s gone mad! Fend for your lives!
            ]],
			BAD_NICK_SAL = "Recount Dracula",
			BAD_NICK_ROOK = "{player} the Crook",
			BAD_NICK_SMITH = "Flotsam Banquod",
			BAD_NICK_SHEL = "Miss Shills-for-Brains",
			BAD_NICK_ARINT = "Spark Karen",
			BAD_NICK_OTHER = "the spoiler",
        }
        :Fn(function(cxt)
            cxt.quest:Complete()
			--character-specific nicks
			cxt.quest.param.bad_nick = cxt:GetLocString("BAD_NICK_OTHER")
			
            cxt:Dialog("DIALOG_INTRO")
			
            cxt:Opt("OPT_IGNORE")
                :Dialog("DIALOG_IGNORE")
				--lose support and resolve
				:Travel()
			
			--negotiate
			DemocracyUtil.AddBodyguardOpt(cxt, function(cxt, agent)
                cxt:ReassignCastMember("guard", agent)
				cxt.quest.param.guard_human = not agent:IsPet()
                cxt:Dialog("DIALOG_USE_BODYGUARD")
					:Travel()
            end, "OPT_USE_BODYGUARD")
			
			--FIGHT
        end)
