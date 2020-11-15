local QDEF = QuestDef.Define{
    title = "Dole out",
    desc = "Give Bread to the poor to gain support",
    qtype = QTYPE.SIDE,
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"RALLY_JOB"},
    on_start = function(quest)
        quest:Activate("dole_out_three")
    end,
}

:AddDefCastSpawn("political", "HEAVY_LABORER")
:AddDefCastSpawn("pan", "POOR_MERCHANT")
:AddDefCastSpawn("grateful", "LABORER")
:AddDefCastSpawn("ungrateful", "RISE_REBEL")
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
    mark = { "pan" },
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
}
-- Added true to make primary advisor mandatory.
-- Otherwise the game will softlock.
DemocracyUtil.AddPrimaryAdvisor(QDEF, true)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
            *[p] Temp dialogue, although i do have a basic structure thought up already.
            *{primary_advisor} gives you a bag of dole loaves and tells you to pass them out.
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
                [p] Tuba sander.
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
                [p] a load of hooey.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
QDEF:AddConvo("feed_pan", "pan")
    :ConfrontState("STATE_CONF")
        :Loc{
            DIALOG_PAN_HANDLE = [[
                * [p] You find a poor merchant sitting on the side of the road, sullen.
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
            local PAN_AMOUNT = 100
            cxt:Dialog("DIALOG_PAN_HANDLE")
            cxt:Opt("OPT_GIVE")
                :DeliverMoney(PAN_AMOUNT)
                :ReceiveOpinion("paid")
                :Dialog("DIALOG_GIVE")
                :CompleteQuest("feed_pan")
                
            cxt:Opt("OPT_NO_MONEY")
                :Dialog("DIALOG_NO_MONEY")
                :CompleteQuest("feed_pan")
                
        end)
QDEF:AddConvo("feed_ungrate","ungrateful")
    :ConfrontState("STATE_CONF")
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
			
			end)
QDEF:AddConvo("feed_grateful","grateful")
    :ConfrontState("STATE_CONF")
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
                    I don't like the fact ' break code.
                agent:
                    how did you say apostrophe without saying it?
                player:
                    I don't know. thanks for the offer.
            ]]
        }
        :Fn(function(cxt) 
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
					cool beans. lukewarm beans.
					I could go for some hot beans right around now.
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
