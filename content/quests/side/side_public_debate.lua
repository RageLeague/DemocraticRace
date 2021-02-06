local LOCATION_DEF =
{
    id = "POPULOUS_JUNCTION",
    name = "Populous Junction",
    desc = "A junction which many people crosses by. Good place for any sort of political activity.",
    icon = engine.asset.Texture("icons/quests/at_the_crossroad.tex"),
    map_tags = {"intersection"},
    plax = "EXT_door_slums1",
    indoors = false,
}
if not Content.GetLocationContent(LOCATION_DEF.id) then
    Content.AddLocationContent(LOCATION_DEF)
end

local QDEF = QuestDef.Define
{
    title = "Public Debate",
    qtype = QTYPE.SIDE,
    desc = [[{opponent} is hosting a public debate, you might be able to make use of the large audience by swaying them to your side.]],
    rank = {1, 5},
    icon = engine.asset.Texture("icons/quests/handler_admiralty_find_bandit_informant.tex"),
    
    tags = {"RALLY_JOB"},
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,

    collect_agent_locations = function(quest, t)
        table.insert(t, { agent = quest:GetCastMember("opponent"), location = quest:GetCastMember('junction'), role = CHARACTER_ROLES.VISITOR})
        table.insert(t, { agent = quest:GetCastMember("laughing_stock"), location = quest:GetCastMember('junction'), role = CHARACTER_ROLES.VISITOR})
        
    end,
    
    on_start = function(quest)
        local location = Location( LOCATION_DEF.id )
        assert(location)
        TheGame:GetGameState():AddLocation(location)
        quest:AssignCastMember("junction", location )
        quest:Activate("meet_opponent")
    end,
    on_destroy = function( quest )
        if quest:GetCastMember("junction") then
            TheGame:GetGameState():MarkLocationForDeletion(quest:GetCastMember("junction"))
        end
        for i, agent in ipairs( quest.param.crowd or {}) do
            agent:RemoveAspect("bribed")
        end
    end,
}

:AddObjective{
    id = "meet_opponent",
    title = "Attend {opponent}'s debate.",
    desc = "{opponent} is debating random strangers. See if you can use it to your advantage.",
    mark = { "junction" },
}

-- :AddObjective{
--     id = "win_audience",
--     title = "Win over the audience and win the debate.",
--     desc = [[]],
--     mark = { "junction" },
-- }

-- :AddObjective{
--     id = "finish",
--     title = "Return. (placeholder)",
--     desc = [[]],
--     mark = { "giver" },
-- }

:AddCast{
    cast_id = "opponent",
    -- when = QWHEN.MANUAL,
    no_validation = true,
    cast_fn = function(quest, t)
        local has_candidate = false
        for id, data in pairs(DemocracyConstants.opposition_data) do
            local candidate = TheGame:GetGameState():GetMainQuest():GetCastMember(data.cast_id)
            if candidate:GetRelationship() < RELATIONSHIP.NEUTRAL or DemocracyUtil.GetFactionEndorsement(data.main_supporter) < RELATIONSHIP.NEUTRAL then
                table.insert(t, candidate)
                has_candidate = true
            end
        end
        if not has_candidate then
            local GENERIC_OPPOSITION = DemocracyUtil.GenerateGenericOppositionTable()
            while not has_candidate and #GENERIC_OPPOSITION > 0 do
                local chosen_id = table.arraypick(GENERIC_OPPOSITION)
                table.arrayremove(GENERIC_OPPOSITION, chosen_id)
                local agent = TheGame:GetGameState():GetAgentOrMemento( chosen_id )
                if not agent then
                    agent = TheGame:GetGameState():AddSkinnedAgent(chosen_id)
                end
                if agent and not agent:IsRetired() then
                    table.insert(t, agent)
                    has_candidate = true
                end
            end
        end
    end,
    on_assign = function(quest, agent)
        quest:AssignCastMember("laughing_stock")
    end,
}
:AddCast{
    cast_id = "laughing_stock",
    condition = function(agent, quest)
        return quest:GetCastMember("opponent"):GetFactionRelationship(agent:GetFactionID()) <= RELATIONSHIP.NEUTRAL
    end,
    when = QWHEN.MANUAL,
}
:AddCast{
    cast_id = "crowd",
    when = QWHEN.MANUAL,
    condition = function(agent, quest)
        return DemocracyUtil.RandomBystanderCondition(agent)
            and (quest.param.crowd == nil or not table.arrayfind(quest.param.crowd, agent))
    end,
    score_fn = function(agent, quest)
        return (agent:GetFactionRelationship(quest:GetCastMember("opponent"):GetFactionID()) * 20) + math.random() * 60 + (agent:HasAspect("bribed") and 45 or 0)
    end,
}

:AddLocationCast{
    cast_id = "junction",
    when = QWHEN.MANUAL,
    no_validation = true,
}

:AddOpinionEvents{
    disliked_debate = {
        delta = OPINION_DELTAS.DISLIKE,
        txt = "Watched your unconvincing debate",
    },

    liked_debate = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Was impressed by your debate",
    },
}
        
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
                !thought
                I've heard that {opponent} is supposed to be running a public debate right now.
            {not has_primary_advisor?
                They won't be willing to someone who can't entertain them...
                !happy
                But obviously, I'm charismatic enough!
                !thought
                Right?
            }
            {has_primary_advisor?
                primary_advisor:
                    Are you thinking of attending? You know they aren't going to listen to you unless you put on a really good show.
                    Do you think you can do that?
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
            {not has_primary_advisor?
                !happy
                Yeah, piece of cake.
            }
            {has_primary_advisor?
                !shrug
                It's a big risk, but I might be able to sway the crowd to support me.
            primary_advisor:
                !palm
                If you say so. Just don't make a fool out of yourself, okay?
            }
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            -- cxt.quest:Activate("go_to_junction")
        end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.DECLINED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
            {not has_primary_advisor?
                !sigh
                $neutralResigned
                I'm too optimistic for my own good.
            }
            {has_primary_advisor?
                !point
                That would probably be a no from me.
            }
        ]],
    }

--DemocracyUtil.AddPrimaryAdvisor(QDEF)
QDEF:AddConvo("meet_opponent")
    
    :Confront(function(cxt)
        if cxt.location == cxt.quest:GetCastMember("junction") then
            return "STATE_INTRO"
        end
    end)
    :State("STATE_INTRO")
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
                    * You arrive a few minutes before {opponent}'s debate with {laughing_stock} ends.
                    * It's very clear that {laughing_stock} is not doing very well, and the audience is booing {laughing_stock.himher} off the stage.
                    !exit
                laughing_stock:
                    !left
                    !scared
                opponent:
                    !right
                    !chuckle
                    haha your argument bad, mine good
                laughing_stock:
                    !scared
                    ...I'll take my leave now.
                    !exit
                    * {laughing_stock} sulks off the stage.
                player:
                    !left
                    * Undaunted by this, you walk up to the other microphone.
                    Got time for one more?
                    * Already, the audience is riled up and angry.
                    !wince
                    * One member even manages to throw an empty bowl of noodles directly against your forehead.
                    * Such aim.
                    * This is clearly going to be an uphill battle.
            ]],
            
            OPT_DEBATE = "Try to win over the audience",
            
            DIALOG_DEBATE = [[
                player:
                    !point
                    Your opinions are laughable!
                    !cruel
                    Here's why you're wrong.
            ]],
        }
        :Fn(function(cxt)
            cxt:TalkTo(cxt:GetCastMember("opponent"))
            cxt.quest.param.crowd = {}
            for i = 1, 4 do
                cxt.quest:AssignCastMember("crowd")
                cxt.quest:GetCastMember("crowd"):MoveToLocation(cxt.location)
                table.insert(cxt.quest.param.crowd, cxt.quest:GetCastMember("crowd"))
                cxt.quest:UnassignCastMember("crowd")
            end
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest.param.audience_stage = 0       --This needs to range from 0-4, changing depending on your negotiation and resulting in different rewards afterwards. See bottom for description of quest
            cxt.quest.param.lost_negotiation = false
            cxt:Opt("OPT_DEBATE")
                :Dialog("DIALOG_DEBATE")
                :Negotiation{
                    on_start_negotiation = function(minigame)
                        minigame:GetOpponentNegotiator():CreateModifier("CROWD_OPINION", 1)
                        minigame:GetOpponentNegotiator():CreateModifier("INSTIGATE_CROWD", 1)
                    end,
                    on_success = function(cxt,minigame)
                        cxt.quest.param.audience_stage = minigame:GetOpponentNegotiator():GetModifierStacks("CROWD_OPINION") - 1
                        cxt:GoTo("STATE_RESULTS")
                    end,
                    on_fail = function(cxt,minigame)
                        cxt.quest.param.lost_negotiation = true
                        cxt:GoTo("STATE_RESULTS")
                    end,
                }
            -- cxt.quest:Complete()
            -- ConvoUtil.GiveQuestRewards(cxt)
        end)
    :State("STATE_RESULTS")
        :Loc{
            DIALOG_LOSS = [[
                player:
                    !angry
                    * Your argument is extremely unconvicing.
                    * This doesn't look good for you.
                opponent:
                    !chuckle
                    Clearly, your arguments don't hold up against even the slightest critique!
                player:
                    No, that's not-
                opponent:
                    !chuckle
                    Look at this grifter. They have no idea what they're saying.
                    Must be sad to be you.
                player:
                    !scared
                    * The audience is eating it up, best to get out of here.
            ]],
    
            DIALOG_HOSTILE = [[
                player:
                    !left
                    !angry
                    How can you say I'm wrong when-
                opponent:
                    !cruel
                    This grifter was raised by a vroc!
                player:
                    No, that's not-
                opponent:
                    !chuckle
                    Look at this grifter. They have no idea what they're saying.
                    Must be sad to be you.
                player:
                    !scared
                    * The audience is eating it up. Clearly you tried your best, but it wasn't enough to win the audience.
            ]],
            
            DIALOG_SKEPTICAL = [[
                player:
                    !left
                    !angry
                    * Your reception is better than when you first walked on stage, but clearly the audience is still angry.
                opponent:
                    !point
                    I don't have to listen to someone who decided they were a politican like a day ago!
                player:
                    !dubious
                    And when did you start?
                opponent:
                    !chuckle
                    Look at this grifter. They have no idea what they're saying.
                    Must be sad to be you.
                player:
                    !scared
                    * The audience is eating it up. Clearly you tried your best, but it wasn't enough to win the audience.
            ]],
            
            DIALOG_NEUTRAL = [[
                player:
                    !left
                    !crossed
                    * Half the audience is stunned, the others seem a lot more meek than before.
                opponent:
                    !angry
                    * {opponent} is still headstrong, however.
                    You think you can come to <i>my</i> debate panel and beat <i>me</i>?
                player:
                    !dubious
                    I'd like to think I have.
                opponent:
                    !palm
                    Ugh. You're a handful and a half. I'm done for tonight.
                player:
                    !happy
                    * Even if not everyone is satisfied with your performance, it could have gone worse.
            ]],
            
            DIALOG_FRIENDLY = [[
                player:
                    !left
                    !crossed
                    * Maybe you were just hearing things, but it sounded like some members of the audience really liked your performance.
                opponent:
                    !angry
                    * {opponent} is still headstrong, however.
                    You think you can come to <i>my</i> debate panel and beat <i>me</i>?
                player:
                    !dubious
                    I'd like to think I have.
                opponent:
                    !palm
                    Ugh. You're a handful and a half. I'm done for tonight.
                player:
                    !happy
                    * Even if not everyone is satisfied with your performance, it could have gone worse.
            ]],
            
            DIALOG_SYMPATHETIC = [[
                player:
                    !left
                    !crossed
                    * Surprisingly, the audience is rooting for you now.
                opponent:
                    !scared
                    * {opponent} knows when to cut {opponent.hisher} losses, and subsequently finds the quickest way to leave.
                    I've got a doctor's appointment with my laundry- I mean I-
                    !exit
                    * {opponent} leaves, being as subtle as a vroc in heat. 
                player:
                    !happy
                    * The audience is on your side. Clearly, this is a huge win.
            ]],
        }
        :Fn(function(cxt)
            local gain_supporter, lose_supporter = 0, 0
			if cxt.quest.param.lost_negotiation == true then
				cxt.quest.param.audience_stage = -1
                cxt:Dialog("DIALOG_LOSS")
                gain_supporter, lose_supporter = 0, 4
			end
			if cxt.quest.param.audience_stage <= 0 then
                cxt:Dialog("DIALOG_HOSTILE")
                gain_supporter, lose_supporter = 0, 3
			elseif cxt.quest.param.audience_stage == 1 then
                cxt:Dialog("DIALOG_SKEPTICAL")
                gain_supporter, lose_supporter = 1, 2
			elseif cxt.quest.param.audience_stage == 2 then
                cxt:Dialog("DIALOG_NEUTRAL")
                gain_supporter, lose_supporter = 2, 2
			elseif cxt.quest.param.audience_stage == 3 then
                cxt:Dialog("DIALOG_FRIENDLY")
                gain_supporter, lose_supporter = 2, 1
			elseif cxt.quest.param.audience_stage >= 4 then
                cxt:Dialog("DIALOG_SYMPATHETIC")
                gain_supporter, lose_supporter = 3, 0
            end
            for i, agent in ipairs(cxt.quest.param.crowd or {}) do
                if i <= gain_supporter then
                    agent:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("liked_debate"))
                elseif #(cxt.quest.param.crowd or {}) - i < lose_supporter then
                    agent:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("disliked_debate"))
                end
            end
            if cxt.quest.param.lost_negotiation or cxt.quest.param.audience_stage <= 0 then
                cxt.quest:Fail()
            else
                if cxt.quest.param.audience_stage <= 2 then
                    cxt.quest.param.poor_performance = true
                end
                cxt.quest:Complete()
                DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", cxt.quest.param.audience_stage * 4, "COMPLETED_QUEST")
                ConvoUtil.GiveQuestRewards(cxt)
            end
            StateGraphUtil.AddLeaveLocation(cxt)
            -- ConvoUtil.GiveQuestRewards(cxt)
        end)
            
--[[
Public Debate - “{opponent} is hosting a public debate, you might be able to make use of the large audience by swaying them to your side.”

When the player arrives at the location, the opponent finishes debating and verbally smacking down someone else. The opponent then calls out to the audience if anyone else will debate them before they wrap it up. 
The player steps up and takes the mic, and then the negotiation starts.

The negotiation plays around a special mechanic: Audience Reception. This comes in the form of a core argument on the opponent, and has 5 stages. 
Hostile Audience, Skeptical Audience, Neutral Audience, Friendly Audience, and Sympathetic Audience. 

The negotiation always starts with a Hostile Audience, and can be upgraded through destroying bounties that occasionally pop up as well as with an incepted 2 cost card, Wisecrack. The audience will also be degraded by enemy 
arguments that are not destroyed in time.

A Hostile Audience and Skeptical Audience will incept 1 Heckler to your opponent each turn. A Friendly Audience and Sympathetic Audience will incept 1 Vulnerability to your opponent each turn.

When the negotiation is completed, the results will be dependent on which stage of Audience Reception you finished with, but if you lost, the Audience Reception instantly becomes Hostile.

Example reward table:
Hostile Audience - 3 Dislike
Skeptical Audience - 2 Dislike, 1 Like
Neutral Audience - 2 Dislike, 2 Like
Friendly Audience - 1 Dislike, 3 Like
Sympathetic Audience - 4 Like
--]]