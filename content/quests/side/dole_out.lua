local QDEF = QuestDef.Define{
    title = "Dole out",
    desc = "Give Bread to the poor to gain support",
    qtype = QTYPE.SIDE,
	rank = {2, 5},
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"RALLY_JOB"},
    on_start = function(quest)
        quest:Activate("dole_out_three")
    end,
	precondition = function(quest)
        return TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor")
    end,
}
--now it won't choose the proprietor as a possible cast member.
:AddCast{
        cast_id = "pan",
        when = QWHEN.MANUAL,
    }
:AddCast{
        cast_id = "political",
        when = QWHEN.MANUAL,
    }
:AddCast{
        cast_id = "grateful",
        when = QWHEN.MANUAL,
    }
:AddCast{
        cast_id = "ungrateful",
        when = QWHEN.MANUAL,
    }
--:AddDefCastSpawn("political", "HEAVY_LABORER")
--:AddDefCastSpawn("pan", "POOR_MERCHANT")
--:AddDefCastSpawn("grateful", "LABORER")
--:AddDefCastSpawn("ungrateful", "RISE_REBEL")
:AddObjective{
    id = "go_to_advisor",
    title = "Wait for the votes to roll in",
    desc = "You've given your last bit of bread. Report back to {primary_advisor} for a reward.",
    mark = {"primary_advisor"},

    on_activate = function(quest)
        if quest:IsActive("feed_grateful") then
            quest:Cancel("feed_grateful")
        end
        if quest:IsActive("feed_politic") then
            quest:Cancel("feed_politic")
        end
        if quest:IsActive("feed_ungrate") then
            quest:Cancel("feed_ungrate")
        end
        if quest:IsActive("feed_pan") then
            quest:Cancel("feed_pan")
        end
    end,
    -- I removed this because it is redundant, and it might cause some issues.
    -- on_complete = function(quest)
    --     -- This is kinda redundant, so I added an active check.
    --     if quest:IsActive() then
    --         quest:Complete()
    --     end
    -- end,
}
:AddObjective{
    id = "dole_out_three",
    hide_in_overlay = true,
    on_activate = function(quest)
        quest:Activate("feed_grateful")
        quest:Activate("feed_pan")
        quest:Activate("feed_ungrate")
        quest:Activate("feed_politic")
    end,
    events = 
    {
        quests_changed = function(quest, event_quest) 
            if event_quest == quest then
                local num_complete = (quest:IsComplete("feed_pan") and 1 or 0) +
                                        (quest:IsComplete("feed_ungrate") and 1 or 0) +
                                        (quest:IsComplete("feed_politic") and 1 or 0) +
                                        (quest:IsComplete("feed_grateful") and 1 or 0)

                if num_complete >= 3 then
                    quest:Complete("dole_out_three")
                    quest:Activate("go_to_advisor")
                end
            end
        end,
    },
	mark = function(quest, t, in_location)
        if in_location then
            local location = TheGame:GetGameState():GetPlayerAgent():GetLocation()
            for i, agent in location:Agents() do
                if DemocracyUtil.RandomBystanderCondition(agent) then
                    table.insert(t, agent)
                end
            end
        else
            DemocracyUtil.AddUnlockedLocationMarks(t)
        end
	end,
}
:AddObjective{
    id = "feed_people",
    title = "Find and Feed some people",
    desc = "Go around and find some impoverished to feed.",
}
:AddObjective{
  id = "feed_grateful",
  mark = { "grateful" },
  title = "Feed some people",
  desc = "Find someone and give them some bread",
}
:AddObjective{
    id = "feed_pan",
    --mark = { "pan" },
    title = "Feed some people",
    desc = "Find someone and give them some bread",
}
:AddObjective{
    id = "feed_politic",
    mark = { "political" },
    title = "Feed some people",
    desc = "Find someone and give them some bread",
}
:AddObjective{
    id = "feed_ungrate",
    mark = { "ungrateful" },
    title = "Feed some people",
    desc = "Find someone and give them some bread",
}
:AddOpinionEvents{
    politic = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Changed political opinion for them.",
    },
    paid = {
        delta = OPINION_DELTAS.MAJOR_GOOD,
        txt = "Gave them money and bread.",
    },
    peeved = {
        delta = OPINION_DELTAS.MAJOR_BAD,
        txt = "Called a populist.",
    },
    gratitude = {
        delta = OPINION_DELTAS.MAJOR_GOOD,
        txt = "Let them tag along.",
    },
    political_waffle = {
	delta = OPINION_DELTAS.MAJOR_GOOD,
	txt = "Agreed with them on all the big issues.",
    },
    political_angry = {
	delta = OPINION_DELTAS.MAJOR_BAD,
	txt = "Let them call you a strawman.",
    },
}
-- Added true to make primary advisor mandatory.
-- Otherwise the game will softlock.
-- Fair enough.
DemocracyUtil.AddPrimaryAdvisor(QDEF, true)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
	{has_primary_advisor?
            *{primary_advisor} heaves a large bag onto the table.
	agent:
		This. Is a bag.
	player:
		Dear hesh.
	agent:
		There's more.
	player:
		No...
	agent:
		It's filled with dole loaves. Despite them being the poor man's food, I had to sneak some out of the distribution offices.
	player:
		So why'd you bring it? I'd assume we're not eating any of it.
	agent:
		No we're not. You're going to distribute these loaves of bread around the Foam.
		With any luck, the word'll be spread that you're a benevolent politician.
		}
	{not has_primary_advisor?
	player:
		[p] I say thing.
		}
        ]],
    }
    :State("START")
    :Fn(function(cxt)
        cxt:Dialog("DIALOG_INTRO")
    end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.ACCEPTED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
                Well you make a sound case.
		If nothing else we can eat 'em later
	    * You pick up the bag. The smell alone rushes you to the door.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
           cxt:Dialog("DIALOG_INTRO") 
        end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.DECLINED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
                Won't this make me seem a communist?
	    agent:
		Half the workers are in support of communism. This'd be a slam dunk for PR.
	    player:
		Lets just keep our options open. What else do you have?
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
QDEF:AddConvo("dole_out_three")
		:Loc{
			DIALOG_SATISFIES_CONDITIONS = [[
			agent:
			What do you want? why do you have bread?
			]],
			OPT_GIVE_BREAD = "[p] give bread",
			}
			--this is the randomizer. for some reason the option part doesn't work for some reason, but i'll fix that at some point
		:Hub(function(cxt, who)
		if who and not AgentUtil.HasPlotArmour(who) and (who:GetFactionID() == "FEUD_CITIZEN" and who:GetRenown() >= 2) or (who:GetFactionID() == "RISE" and who:GetRenown() <= 2)
			and not (who:GetProprietor()) then
			cxt:Dialog("DIALOG_SATISFIES_CONDITIONS")
			cxt:Opt("OPT_GIVE_BREAD")
				:SetQuestMark()
				local castroles = {"pan", "ungrateful", "grateful", "political"}
				table.shuffle(castroles)
				cxt.quest:AssignCastMember(castroles[1], cxt:GetAgent())
				table.remove(castroles, 1)
		if who == cxt:GetCastMember("pan") then
				cxt:GoTo("STATE_PANHANDLER")
				--table.remove(castroles, 1)
		end
		if who == cxt:GetCastMember("grateful") then
				cxt:GoTo("STATE_GRATEFUL")
				--table.remove(castroles, 3)
		end
		if who == cxt:GetCastMember("ungrateful") then
				cxt:GoTo("STATE_UNGRATEFUL")
				--table.remove(castroles, 2)
		end
		if who == cxt:GetCastMember("political") then
				cxt:GoTo("STATE_POLITICAL")
				--table.remove(castroles, 4)
		end
		end
	end)
		:State("STATE_PANHANDLER")
        :Loc{
			OPT_GIVE_BREAD = "[p] give bread",
            DIALOG_PAN_HANDLE = [[
                * [p] You find {agent} sitting on the side of the road, sullen.
                player:
                    Hey there friend. You want a loaf of Dole Bread?
                agent:
                    I wouldn't say no to free bread.
                    although...this isn't really covering rent.
                player:
                    What do you mean? Do you need money?
                agent:
                    Well, yes. I wouldn't force you to not give me money.
                    But i'm also not NOT forcing you to give me money.
            ]],
            OPT_GIVE = "Give them some Shills",
            DIALOG_GIVE = [[
                player:
                    Well, I suppose I'll have a lot more money when i'm in office.
                    Here's a bit of cash. Hope it sees you through to tommorrow.
                agent:
                    Wow. I'll be honest, I did not expect that to work.
                    Thank you so much!
            ]],
            OPT_NO_MONEY = "Give them the bread...then a wide berth",
            DIALOG_NO_MONEY = [[
            player:
                My sympathies, but I am not the most flush as well.
                When i get into office, I will make sure this kind of thing doesn't happen again.
            agent:
                sure...
            ]]
        }
        :Fn(function(cxt)
		--these bricks of code here and the other parts are not needed. the main function/thing/rig-a-ma-jig does this work for it without multiple cast roles on one character
		--if who and not AgentUtil.HasPlotArmour(who) and (who:GetFactionID() == "FEUD_CITIZEN" and who:GetRenown() >= 2) or (who:GetFactionID() == "RISE" and who:GetRenown() >= 2)
			--and not (who:GetProprietor()) then
		--cxt:Opt("OPT_GIVE_BREAD")
		--cxt.quest:AssignCastMember("pan", cxt:GetAgent())
		cxt:Dialog("DIALOG_PAN_HANDLE")
		cxt:Opt("OPT_GIVE")
				:Dialog("DIALOG_GIVE")
                :DeliverMoney(100)
				--because video game no like be nice.
				--just...sometimes you have to wonder if code just...got up on the wrong side of the bed whenever it want to run.
                :ReceiveOpinion("paid")
                :CompleteQuest("feed_pan")
            cxt:Opt("OPT_NO_MONEY")
                :Dialog("DIALOG_NO_MONEY")
                :CompleteQuest("feed_pan")
            --end
        end)
--I have probably gotten needlessly fancy with this section. At least compared to the others. 
:State("STATE_POLITICAL")
        :Loc{
		OPT_GIVE_BREAD = "[p] give bread",
	    DIALOG_POLITICAL = [[
		* You find {political} staring at a poster for the Rise.
	    player:
		This oughta be easy support.
		Hello {political}. Care for some Dole Bread?
	    agent:
		Sure. Say, this is rather helpful to the cause
		Are you in support of a UBI? So this kind of thing doesn't have to happen anymore?
		]],
	    OPT_AGREE = "Agree to their ideas.",
	    DIALOG_AGREE = [[
		player:
		Viva la Rise, am I right?
		agent:
		Right you are!
		It's been so long since I met a like-minded politician since Kalandra.
		And what about those taxes? They bleed the common man dry and keep on draining.
		You agree, right?
		]],

	    OPT_DISAGREE = "Respectfully disagree with their opinions.",
	    DIALOG_DISAGREE = [[
		player:
		I don't believe my opinion on the topic is of import to this conversation.
		agent:
		What are you saying?
		Do you mean you HATE welfare in all forms?
		Is that what you mean?
	    ]],
	}
		:Fn(function(cxt)
		--if who and not AgentUtil.HasPlotArmour(who) and (who:GetFactionID() == "FEUD_CITIZEN" and who:GetRenown() >= 2) or (who:GetFactionID() == "RISE" and who:GetRenown() >= 2)
			--and not (who:GetProprietor()) then
			--cxt.quest:AssignCastMember("political", cxt:GetAgent())
			--cxt:Opt("OPT_GIVE_BREAD")
			cxt:Dialog("DIALOG_POLITICAL")
			cxt:Opt("OPT_AGREE")
			:UpdatePoliticalStance("WELFARE", 2, false, true)
			:RecieveOpinion("politic")
			:Dialog("DIALOG_AGREE")
			:GoTo("STATE_AGREE")
			cxt:Opt("OPT_DISAGREE")
			:Dialog("DIALOG_DISAGREE")
			:GoTo("STATE_DISAGREE")
			--end
		end)
:State("STATE_AGREE")
	:Loc{
	    OPT_AGREE_2 = "Agree to their second stance.",
	    DIALOG_AGREE_2 = [[
		* You agree with their second issue.
		* They absolutely love you. You don't know if anyone else will.
	    ]],
	    OPT_DISAGREE_2 = "Tell them you don't agree with the second stance.",
	    DIALOG_DISAGREE_2 = [[
		player:
		Now, now. Let's not get ahead of ourselves.
		agent:
		Why? Why are you deflecting this issue?
		Is it because you HATE labor laws? Do you WANT people to be treated like bog muck?
		]],
	}
	    :Fn(function(cxt)
			cxt:Opt("OPT_AGREE_2")
			:UpdatePoliticalStance("LABOR_LAW", 2, false, true)--random stance. might change once I get a minute to look.
			:RecieveOpinion("political_waffle")
			:Dialog("DIALOG_AGREE_2")
			:CompleteQuest("feed_politic")
			StateGraphUtil.AddLeaveLocation(cxt)
			cxt:Opt("OPT_DISAGREE_2")
			:Dialog("DIALOG_DISAGREE_2")
			:GoTo("STATE_DISAGREE_2")
		end)

:State("STATE_DISAGREE")
	:Loc{
	    OPT_CALM_DOWN = "Tell them how wrong they are.",
	    DIALOG_CALM_DOWN = [[
		player:
		Now that isn't what I meant by it and you know it.
		]],
	    DIALOG_CALM_DOWN_SUCCESS = [[
		player:
		Do my actions not demonstrate my beliefs?
		I risked my neck by nabbing bags of these for the people of Havaria.
		agent:
		I geuss that's true.
		Pardon, I'm not great at taking rejection for my ideas.
		player:
		Well, follow the debates. People'll talk all day long about different ideas.
		agent:
		Can't. I got to get to my next shift.
		player:	
		Well good luck for you, and enjoy the bread
		]],
	    DIALOG_CALM_DOWN_FAIL = [[
		agent:
		Oh, I get it.
		You're just trying to butter up the Rise so we'd lay down our arms.
		You're working with the Barons, aren't you?
		player:
		No, No, you've got it all-
		agent:
		Get out of my face, you filthy capitalist. You'll profit no longer from this mere worker.
		]],
	    OPT_IGNORE = "Ignore their complaints, part 1.",
	    DIALOG_IGNORE = [[
		* You put on the best poker face you can manage.
		* It doesn't help.
		Agent:
		What? Not going to defend yourself?
		Try to excuse yourself from hearing the truth?
		]],
	   }
	:Fn(function(cxt) 
			cxt:Opt("OPT_CALM_DOWN")
			:Dialog("DIALOG_CALM_DOWN")
            :Negotiation{
                on_success = function(cxt)
		cxt:Dialog("DIALOG_CALM_DOWN_SUCCESS")
                    cxt.quest:Complete("feed_politic")
                    StateGraphUtil.AddLeaveLocation(cxt)
				end,
                on_fail = function(cxt)
		cxt:Dialog("DIALOG_CALM_DOWN_FAIL")
        cxt:ReceiveOpinion("political_angry")
		cxt.quest:Complete("feed_politic")
		StateGraphUtil.AddLeaveLocation(cxt)
				end
				}
			cxt:Opt("OPT_IGNORE")
			:Dialog("DIALOG_IGNORE")
			:ReceiveOpinion("political_angry")
			:CompleteQuest("feed_politic")
			
			end)
:State("STATE_DISAGREE_2")
	:Loc{
	OPT_CALM_DOWN_2 = "Elaborate on how wrong they are.",
	    DIALOG_CALM_DOWN_2 = [[
		* You start telling them exactly how wrong they are, to put it bluntly.
		]],
	    DIALOG_CALM_DOWN_2_SUCCESS = [[
		* You successfully defuse their arguments.
		]],
	    DIALOG_CALM_DOWN_2_FAIL = [[
		* You unsuccessfully defuse their arguments. If anything you gave them more ammo.
		]],
	    OPT_IGNORE_2 = "Ignore their complaints.",
	    DIALOG_IGNORE_2 = [[
		* You ignore their verbal bashing.
		* You don't know if they have any influence, because what influence they do have is now against you.
		]],
	   }
	   	:Fn(function(cxt) 
			cxt:Opt("OPT_CALM_DOWN_2")
			:Dialog("DIALOG_CALM_DOWN_2")
            :Negotiation{
                on_success = function(cxt)
		cxt:Dialog("DIALOG_CALM_DOWN_2_SUCCESS")
                    cxt.quest:Complete("feed_politic")
                    StateGraphUtil.AddLeaveLocation(cxt)
				end,
                on_fail = function(cxt)
		cxt:Dialog("DIALOG_CALM_DOWN_2_FAIL")
                    cxt:ReceiveOpinion("political_angry")
		cxt.quest:Complete("feed_politic")
		StateGraphUtil.AddLeaveLocation(cxt)
				end
				}
			cxt:Opt("OPT_IGNORE_2")
			:Dialog("DIALOG_IGNORE_2")
			:ReceiveOpinion("political_angry")
			:CompleteQuest("feed_politic")
			
			end)
:State("STATE_UNGRATEFUL")
        :Loc{
            DIALOG_UNGRATE = [[
                * You approach {agent} and hand them a loaf of bread
                * They look down at it and scowl
                agent:
                    [p] yeah no i'm way too tired for this.
                    blah blah blah screw you.
            ]],
            OPT_CONVINCE = "Try to calm them down",
            DIALOG_CONVINCE = [[
                player:
                    Have you considered not doing that, hm?
            ]], 
            DIALOG_CONVINCE_SUCCESS = [[
                player:
                    LaserDisk.
                agent:
                    I'm sold.
                    Have a great day.
            ]],
            DIALOG_CONVINCE_FAIL = [[
                agent:
                    Your deck could be better.
                    Allow me to remind you of this failure for the rest of the run.
            ]],
            OPT_IGNORE = "Ignore their complaints",
            DIALOG_IGNORE = [[
                player:
                    Belt Buckles and globs of bandaids
                agent:
                    POPULIST!
            ]]
        }
        :Fn(function(cxt)
		--if who and not AgentUtil.HasPlotArmour(who) and (who:GetFactionID() == "FEUD_CITIZEN" and who:GetRenown() >= 2) or (who:GetFactionID() == "RISE" and who:GetRenown() >= 2)
			--and not (who:GetProprietor()) then
			--cxt.quest:AssignCastMember("ungrateful", cxt:GetAgent())
            cxt:Dialog("DIALOG_UNGRATE")
			cxt:Opt("OPT_CONVINCE")
			:Dialog("DIALOG_CONVINCE")
            :Negotiation{
                on_success = function(cxt)
					cxt:Dialog("DIALOG_CONVINCE_SUCCESS")
                    cxt.quest:Complete("feed_ungrate")
                    StateGraphUtil.AddLeaveLocation(cxt)
				end,
                on_fail = function(cxt)
					cxt:Dialog("DIALOG_CONVINCE_FAIL")
                    cxt:ReceiveOpinion("peeved")
					StateGraphUtil.AddLeaveLocation(cxt)
				end
				}
			cxt:Opt("OPT_IGNORE")
			:Dialog("DIALOG_IGNORE")
			:ReceiveOpinion("peeved")
			:CompleteQuest("feed_ungrate")
			--end
			end)
:State("STATE_GRATEFUL")
        :Loc{
            DIALOG_GRATE = [[
                player:
                    [p]Hey. Want some bread?
                agent:
                    Sure. Y'know, you're alright.
                    What can I do to repay you?
            ]],
            OPT_BRING_ALONG = "Let them tag along for a while.",
            DIALOG_BRING_ALONG = [[
                player:
                    Come with me. I shall take you to the promised land.
                agent:
                    Wait...are you jesus?
                player:
                    Don't know who jesus is...come on now.
            ]],
            OPT_DONT = "Don't bring them along.",
            DIALOG_DONT_BRING = [[
                player:
                    [p] I don't like the fact ' break code.
                agent:
                    how did you say apostrophe without saying it?
                player:
                    I don't know. thanks for the offer.
            ]]
        }
        :Fn(function(cxt)
		--if who and not AgentUtil.HasPlotArmour(who) and (who:GetFactionID() == "FEUD_CITIZEN" and who:GetRenown() >= 2) or (who:GetFactionID() == "RISE" and who:GetRenown() >= 2)
			--and not (who:GetProprietor()) then
			--cxt.quest:AssignCastMember("grateful", cxt:GetAgent())
            cxt:Dialog("DIALOG_GRATE")
            cxt:Opt("OPT_BRING_ALONG")
                :RecruitMember( PARTY_MEMBER_TYPE.HIRED )
                :Dialog("DIALOG_BRING_ALONG")
				:ReceiveOpinion("gratitude")
				:CompleteQuest("feed_grateful")
                :Travel()
            cxt:Opt("OPT_DONT")
                :Dialog("DIALOG_DONT_BRING")
			    :CompleteQuest("feed_grateful")
                :Travel()
			--end
        end)
--QDEF:AddConvo("go_to_advisor")
    --:ConfrontState("CONF", function(cxt) return not cxt.quest.param.has_had_post_confront and cxt.location:HasTag("in_transit") end) 
        --:Loc{
			--DIALOG_GOVERNMENT = [[
			--* [p] You're walking home when you're confronted by an admiralty patrol
			--* You have to possibly defend yourself at the cost of seeming violent
			--* You also, likely, just neogitate with them and make them go away.
			--* Finally, you could just throw money at the problem and hope the scary people go away.
			--]],
--}
        --:Fn(function(cxt)

            --local patrol = CreateCombatParty("ADMIRALTY_PATROL", math.min(cxt.quest:GetRank(), 1), cxt.location)
            --cxt.quest.param.has_had_post_confront = true
            --cxt:TalkTo(patrol[1])
            --cxt:Dialog("DIALOG_INTRO")
QDEF:AddConvo("dole_out_three", "primary_advisor")
		:Loc{
			OPT_ADMIT_DEFEAT = "Tell {primary_advisor} you couldn't finish the task",
			DIALOG_ADMIT_DEFEAT = [[
			player:
			I give up.
			agent:
			Why?
			player:
			I simply cannot go on, for reasons that are different depending on the circumstances surrounding it.
			agent:
			Alright then.
			]]
			}
			:Hub(function(cxt, who)
			cxt:Opt("OPT_ADMIT_DEFEAT")
				
				--fuck me why can't anything in this be fuckin' simple
				--cxt.quest made it happen once I started the convo. obviously I don't want that to happen.
				:Fn(function(cxt)
				if not cxt.quest:IsComplete("dole_out_three") then
					cxt:Dialog("DIALOG_ADMIT_DEFEAT")
					cxt.quest:Fail()
				end
				end)
			end)
QDEF:AddConvo("go_to_advisor", "primary_advisor")
		:Loc{
			OPT_GET_PAID = "Show the empty bag to {primary_advisor}.",
			DIALOG_GET_PAID = [[
				player:
					[p]'ey
				agent:
					'ey
					You done?
				player:
					Yup.
				agent:
					cool beans.
			]]
		}
--This final part is where the issue lies.
:Hub(function(cxt) 
        cxt:Opt("OPT_GET_PAID")
            :SetQuestMark()
            :Dialog("DIALOG_GET_PAID")
            :CompleteQuest()
            -- This is kinda redundant, because completequest will cover the reward as well.
            -- :Fn(function() 
            --     ConvoUtil.GiveQuestRewards(cxt)
            -- end)
    end)
