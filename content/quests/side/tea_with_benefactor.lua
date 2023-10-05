local score_fn = function(agent, quest)
    local score = DemocracyUtil.SupportScore(agent)
    return score + math.random() * 120
end

local FOLLOWUP

local QDEF = QuestDef.Define
{
    title = "Tea With A Benefactor",
    desc = "An influential citizen has taken interest in your campaign and invited you for a cup of tea. See if you can turn some of that support into cash.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/tea_with_benefactor.png"),

    qtype = QTYPE.SIDE,
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"RALLY_JOB"},
    reward_mod = 0,
    extra_reward = false,
    precondition = function(quest)
        return TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor")
    end,
    on_init = function(quest)
        -- quest.param.debated_people = 0
        -- quest.param.crowd = {}
        -- quest.param.convinced_people = {}
        -- quest.param.unconvinced_people = {}
    end,
    on_start = function(quest)
        -- quest:Activate("go_to_diner")
    end,
    collect_agent_locations = function(quest, t)
        -- if quest:IsActive("contact_informant") or quest:IsActive("extract_informant") then
        table.insert (t, { agent = quest:GetCastMember("benefactor"), location = quest:GetCastMember('diner'), role = CHARACTER_ROLES.PATRON } )
        -- end
    end,
    on_complete = function( quest )
        DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", quest.param.funds and math.max(math.round(quest.param.funds / 10), 5) or 5, "COMPLETED_QUEST" )
    end,
}
:AddLocationCast{
    cast_id = "diner",
    -- when = QWHEN.MANUAL,
    -- no_validation = true,
    condition = function(location, quest)
        local allowed_locations = {"PEARL_FANCY_EATS", "MOREEF_BAR"}
        return table.arraycontains(allowed_locations, location:GetContentID())
    end,
}
:AddObjective{
    id = "go_to_diner",
    title = "Go to {diner#location}",
    desc = "Go to {diner#location} to meet the benefactor.",
    mark = { "benefactor" },
    state = QSTATUS.ACTIVE,

    on_activate = function( quest)
        -- local location = Location( LOCATION_DEF.id )
        -- assert(location)
        -- TheGame:GetGameState():AddLocation(location)
        -- quest:AssignCastMember("diner", location )
    end,
}
:AddCast{
    cast_id = "benefactor",
    condition = function(agent, quest)
        return DemocracyUtil.BEHAVIOURS.TEA_BENEFACTOR.BENEFACTOR_DEFS[agent:GetContentID()] ~= nil and agent:GetRelationship() >= RELATIONSHIP.NEUTRAL -- might generalize it later
    end,
    score_fn = score_fn,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        local options = copykeys(DemocracyUtil.BEHAVIOURS.TEA_BENEFACTOR.BENEFACTOR_DEFS)
        local def = table.arraypick(options)
        table.insert( t, quest:CreateSkinnedAgent(def) )
    end,
}
:AddOpinionEvents{
    convinced_benefactor =
    {
        delta = OPINION_DELTAS.LIKE,
        txt = "Confident in your leadership abilities.",
    },
    disappointed_benefactor = {
        delta = OPINION_DELTAS.DIMINISH,
        txt = "Skeptical about your leadership abilities.",
    },
}
DemocracyUtil.AddPrimaryAdvisor(QDEF, true) -- make primary advisor mandatory because that's how you get that info

QDEF:AddConvo("go_to_diner")

    :Confront(function(cxt)
        if cxt.location == cxt.quest:GetCastMember("diner") and not cxt.quest.param.visited_diner then
            return "STATE_INTRO"
        end
    end)
    :State("STATE_INTRO")
        :Loc{
            DIALOG_INTRO = [[
                * You arrive at the diner looking for the benefactor.
                * One person watches you intensely and points to an empty chair.
            ]],

        }
        :Fn(function(cxt)

            cxt:Dialog("DIALOG_INTRO")
            cxt.quest.param.visited_diner = true

        end)
QDEF:AddConvo("go_to_diner", "benefactor")
    :Loc{
        OPT_TALK = "Start the meeting",
        DIALOG_TALK = [[
            * {agent} flags down a waiter and puts in 2 orders for tea as you sit down.
            player:
                I don't mind free drinks, but I'm going to wager that isn't why we're here today.
            agent:
                Afraid not. I hear that you're running for president.
		        And I didn't amass my wealth by ignoring opportunities.
	    	    Lets get down to brass tacks. Tell me why my shills of indiscriminate origin should go to you.
	        * The drinks arrive.
        ]],

        REASON_TALK = "Secure as much shills as you can!",

        DIALOG_BENEFACTOR_CONVINCED = [[
            * {agent} pauses for a moment, taking one last taste of {agent.hisher} tea.
            agent:
                We are in business, {player}.
                None of the other candidates have shown as much promise for my bank account as you have.
            player:
                Hey, Biggest shill gets the shills, am I right?
            agent:
                Right you are.
                !give
                Here's {funds#money}.
            * [p] You have secured additional financial support.
        ]],
        DIALOG_BENEFACTOR_POOR = [[
            agent:
                You show promise...but atop that promise is much bluster.
		        I can't give you Havaria, but I'm willing to give you {funds#money}.
            player:
                I guess this is better than nothing.
            * You have secured a bit of financial support, though it could be a lot better.
        ]],
        DIALOG_BENEFACTOR_UNCONVINCED = [[
            player:
                300 shills down, then 400 shills every day after.
                I go no lower.
            agent:
                That's really greedy of you, and frankly, I don't like that.
                Your opposition is willing to lobby laws for much, much less.
                Good day, dear {player}.
	      * {agent} downs the rest of the cup and shoos you away.
        ]],

        DIALOG_REGULAR_FUNDING = [[
            agent:
                [p] Since I like you, I will provide additional funding for you each morning.
                I'll give you half of what I gave you today every morning, as long as I am happy.
            player:
                Okay, thanks.
        ]],
    }
    :Hub(function(cxt)
        -- cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("benefactor"))
        cxt:Opt("OPT_TALK")
            :SetQuestMark(cxt.quest)
            :Dialog("DIALOG_TALK")
            :Fn(function(cxt)
                cxt:GetAgent():SetTempNegotiationBehaviour(DemocracyUtil.BEHAVIOURS.TEA_BENEFACTOR)
            end)
            :Negotiation{
                cooldown = 0,
                -- flags = NEGOTIATION_FLAGS.NO_BYSTANDERS,
                reason_fn = function(minigame)
                    return cxt:GetLocString("REASON_TALK")
                end,

                on_start_negotiation = function(minigame)
                    -- just so you get at least something on win instead of nothing.
                    minigame.player_negotiator:CreateModifier("SECURED_FUNDS", 5)
                    minigame.opponent_negotiator:CreateModifier("INVESTMENT_OPPORTUNITY", 5)
                    minigame.opponent_negotiator:CreateModifier("INVESTMENT_OPPORTUNITY", 10)
                    minigame.opponent_negotiator:CreateModifier("INVESTMENT_OPPORTUNITY", 20)
                end,

                on_success = function(cxt, minigame)
                    cxt.quest.param.funds = minigame:GetPlayerNegotiator():GetModifierStacks( "SECURED_FUNDS" )
                    cxt.quest.param.poor_performance = cxt.quest.param.funds < 20 + 10 * cxt.quest:GetRank()
                    if cxt.quest.param.poor_performance then
                        cxt:Dialog("DIALOG_BENEFACTOR_POOR")
                    else
                        cxt:Dialog("DIALOG_BENEFACTOR_CONVINCED")
                    end
                    cxt.enc:GainMoney( cxt.quest.param.funds )
                    cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("convinced_benefactor"))
                    cxt.quest:Complete()
                    ConvoUtil.GiveQuestRewards(cxt)
                    if not cxt.quest.param.poor_performance and cxt:GetAgent():GetRelationship() > RELATIONSHIP.NEUTRAL then
                        cxt:Dialog("DIALOG_REGULAR_FUNDING")
                        cxt.quest:SpawnFollowQuest(FOLLOWUP.id)
                    end
                end,
                on_fail = function(cxt, minigame)
                    cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("disappointed_benefactor"))
                    cxt:Dialog("DIALOG_BENEFACTOR_UNCONVINCED")
                    cxt.quest:Fail()
                end,
            }
    end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
            {has_primary_advisor?
            agent:
                I have received an invitation from someone named {benefactor}.
            player:
                An invitation to what?
            agent:
                !notepad
                It's hard to read, but it says:
            }
            {not has_primary_advisor?
            * A Jake runs up to you, handing you a well made envelope before doubling back.
            player:
                A message, huh?
            * Inside is a letter, written in such a thick cursive it gives you a dull headache.
            player:
                Let's see...
            }
                "{player}, I have a vested interest in your political career."
                "Please arrive at the {diner#location}, so we may discuss further."
                Doesn't say anything else.
            {has_primary_advisor?
                Maybe they want to fund your campaign?
            }
            {not has_primary_advisor?
                Maybe they want to fund my campaign?
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
                !thought
                Well, it's worth a shot.
                !happy
                Best case scenario, free drinks.
                Can't see anything wrong with that.
            {has_primary_advisor?
            agent:
                !palm
                I can't believe that free drinks is only what you care about.
                Anyway, don't keep our host waiting!
            }
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Activate("go_to_diner")
        end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.DECLINED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                I don't know. Seems way too sketchy for me.
                No one writes like this and expects to be believed.
		        This is probably a scam. Next time let them come to me.
            agent:
                Fair enough.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)




FOLLOWUP = QDEF:AddFollowup()

FOLLOWUP:GetCast("benefactor").unimportant = true
FOLLOWUP:AddObjective{
    id = "wait",
    state = QSTATUS.ACTIVE,
    events = {
        do_sleep = function(quest)
            quest.param.ready = true
        end,
        morning_mail = function(quest, cxt)
            if quest.param.ready then
                quest.param.ready = false
                cxt:PlayQuestConvo( quest, "MorningMail" )
            end
        end,
    }
}

FOLLOWUP.on_init = function(quest)
    quest.param.regular_funds = math.floor(quest.param.funds / 2)
    quest:UnassignCastMember("diner")
end

FOLLOWUP:AddConvo(nil, nil, "MorningMail")
    :Loc{
        DIALOG_GOOD = [[
            * You received a mail in the morning.
            * It contains {regular_funds#money} and a message:
            * Here's your funding for the day. Keep up the good work!
            * Signed, {benefactor}.
        ]],
        DIALOG_BAD = [[
            * You received a mail in the morning.
            * It contains {regular_funds#money} and a message:
            * Due to your failing as a politician, I shall now stop funding your campaign.
            * This is the final money I will send you. After this, you will get nothing.
            * Signed, {benefactor}.
        ]]
    }
    :State("START")
        :Fn(function(cxt)
            if cxt.quest:GetCastMember("benefactor"):GetRelationship() > RELATIONSHIP.NEUTRAL then
                cxt:Dialog("DIALOG_GOOD")
                cxt.enc:GainMoney( cxt.quest.param.regular_funds )
            else
                cxt:Dialog("DIALOG_BAD")
                cxt.enc:GainMoney( cxt.quest.param.regular_funds )
                cxt.quest:Cancel()
            end
        end)
