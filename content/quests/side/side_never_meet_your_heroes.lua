local QDEF = QuestDef.Define
{
    title = "Never Meet Your Heroes",
    desc = "Manufacture a scandal for one of your political opponents. Show their supporters who they are really supporting.",
    icon = engine.asset.Texture("icons/quests/side_smith_delicate_negotiations.tex"),

    qtype = QTYPE.SIDE,
    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"RALLY_JOB"},
    reward_mod = 0,
    extra_reward = false,

    on_start = function(quest)
        -- quest:Activate("spread_rumor")
        -- quest:Activate("time_countdown")
    end,

    on_complete = function( quest )
        if quest:GetCastMember("target") then
            quest:GetCastMember("target"):OpinionEvent(quest:GetQuestDef():GetOpinionEvent("spread_rumors"))
        end
        if quest.param.convinced_factions then
            local score = quest.param.poor_performance and 3 or 4
            score = score * #quest.param.convinced_factions
            DemocracyUtil.DeltaGeneralSupport(score, "COMPLETED_QUEST")
        end
    end,
    on_fail = function(quest)
        if quest:GetCastMember("target") then
            quest:GetCastMember("target"):OpinionEvent(quest:GetQuestDef():GetOpinionEvent("spread_rumors"))
        end
        DemocracyUtil.DeltaGeneralSupport(-5, "FAILED_QUEST")
    end,
    precondition = function(quest)
        return TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor") and TheGame:GetGameState():GetMainQuest().param.day >= 2
    end,
    GenerateRumor = function(quest)
        local chosen = math.random(1,5)
        return quest:GetLocalizedStr("RUMOR_" .. chosen)
    end,
}
:AddCast{
    cast_id = "target",
    when = QWHEN.MANUAL,
}
:Loc{
    RUMOR_1 = "{target} is suspicious.",
    RUMOR_2 = "{target} hunts baby yotes for fun.",
    RUMOR_3 = "{target} supports Rentoria's invasion against Havaria.",
    RUMOR_4 = "{target}'s parents bought {target}'s way into a position of power.",
    RUMOR_5 = "{target} wants to meddle with the election.",
}
:AddObjective{
    id = "spread_rumor",
    title = "Spread the rumor",
    desc = "Spread your rumor about {target} through different factions and locations to increase the credibility of your claim.",
    mark = function(quest, t, in_location)
        if in_location then
        else
            DemocracyUtil.AddUnlockedLocationMarks(quest, t, function(location)
                return not (quest.param.convinced_locations and table.arraycontains(quest.param.convinced_locations, location))
            end)
        end
    end,
}
:AddFreeTimeObjective{
    desc = "Use this time to spread your rumor.",
    action_multiplier = 1.5,
    on_complete = function(quest)
        quest:Complete("spread_rumor")
        quest:Activate("out_of_time")
    end,
}
:AddObjective{
    id = "out_of_time",
    mark = {"primary_advisor"},
    title = "Report to {primary_advisor}",
    desc = "You ran out of time. Return to {primary_advisor} on your progress.",
    on_activate = function(quest)
        if quest:IsActive("spread_rumor") then
            quest:Cancel("spread_rumor")
        end
        if quest:IsActive("time_countdown") then
            quest:Cancel("time_countdown")
        end
    end,
}
:AddOpinionEvents{
    spread_rumors =
    {
        delta = OPINION_DELTAS.DIMINISH,
        txt = "Spread rumors about them",
    },
}
DemocracyUtil.AddPrimaryAdvisor(QDEF, true)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
            primary_advisor:
                !hips
                Y'know, most voters don't choose the president because they like them.
                They do it to keep the other people out of office.
                !handwring
                How would you like to do some political mud slinging?
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
                !shrug
                You know what? I'm down for a little defamation.
            primary_advisor:
                Great! Who do you want to target today?
        ]],
        OPT_TARGET = "Target {1#agent}",
        DIALOG_TARGET = [[
            player:
                I would say {target}.
            primary_advisor:
                !shrug
                If you say so.
                Now, if we want to defame {target}, we need to show the people what kind of person {target} truly is.
                {not can_manipulate_truth and not white_liar?
                    !point
                    Doesn't necessarily have to be true. We just need to get the word out.
                }
                {can_manipulate_truth?
                    !thought
                    After all, if people believe it's true, then to the world, it might as well be true!
                }
                {not can_manipulate_truth and white_liar?
                    !handwring
                    The masses love a juicy gossip, so let's tell them what they want to hear!
                }
                !give
                Now, <i>what</> that terrible something is, I'll leave up to you.
        ]],
        DIALOG_TARGET_PST = [[
            * {agent} carefully reads what you've just wrote.
            {advisor_diplomacy?
            * Then, {agent} hands the note back to you.
            agent:
                Wow, that was certainly a cringe thing for {target} to do, huh?
                You are going to be so based revealing this information to the world.
            }
            {not advisor_diplomacy?
            agent:
                !sigh
            * Then, {agent.heshe} gives up.
            agent:
                Man, you really need to work on your handwriting.
                I don't think whatever you wrote is even Havarian.
            player:
                !crossed
                Hey! That's uncalled for.
            agent:
                !sigh
                I'm sure whatever you wrote is at least a good enough rumor to hopefully sow doubts in the voter base.
            }
        ]],
        -- Might use this later
        DIALOG_TARGET_PST_HAVARIAN = [[
            * {agent} carefully reads what you've just wrote.
            {not advisor_diplomacy?
            agent:
                !chuckle
                Oh ho ho! {target}, you naughty yote!
                !give
                This is a potent story you've got here. It'd be a shame if it got out.
            player:
                !handwring
                Yes, a shame indeed.
            }
        ]],
        DIALOG_TARGET_PST_NO_ENTRY = [[
            * {agent} glances over the blank card you wrote on.
            agent:
                !hips
                I wasn't expecting nothing.
                !think
                Okay... Let me think of a believable rumor.
                !eureka
                Oh! I got this.
                {1}
            player:
                !chuckle
                Ooh, that's a good one.
            agent:
                !happy
                I know, right?
        ]],
        DIALOG_TARGET_PST_2 = [[
            agent:
                !point
                Now go tell as many people as you can.
                But be sure to get a varied audience, and keep the story straight!
        ]],

        POPUP_TITLE = "Make a scandal!",
        POPUP_SUBTITLE = "Write something down that might be condemning to {target}! Use full sentence, including punctuations.",
    }
    :State("START")
        :Fn(function(cxt)
            cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
            cxt:Dialog("DIALOG_INTRO")

            for i, id, data in sorted_pairs(DemocracyConstants.opposition_data) do
                local opponent = TheGame:GetGameState():GetMainQuest():GetCastMember(data.cast_id)
                if opponent and not opponent:IsRetired() then
                    cxt:Opt("OPT_TARGET", opponent)
                        :Fn(function(cxt)
                            cxt.quest:AssignCastMember("target", opponent)
                        end)
                        :Dialog("DIALOG_TARGET")
                        :Fn(function(cxt)
                            local screen = Screen.EditStringPopup( cxt:GetLocString( "POPUP_TITLE" ),
                                loc.format( cxt:GetLocString( "POPUP_SUBTITLE" ) ),
                                "",
                                function( val )
                                    cxt.enc:ResumeEncounter( val )
                                end )
                            screen.inputbox.lines = 3
                            screen.inputbox:SetSize(720)
                            TheGame:FE():PushScreen(screen)

                            local val = cxt.encounter:YieldEncounter()

                            if val and val ~= "" then
                                cxt.quest.param.rumor = val
                                cxt:Dialog("DIALOG_TARGET_PST")
                            else
                                cxt.quest.param.rumor = cxt.quest:DefFn("GenerateRumor")
                                cxt:Dialog("DIALOG_TARGET_PST_NO_ENTRY", cxt.quest.param.rumor)
                            end
                            cxt:Dialog("DIALOG_TARGET_PST_2")

                            cxt.quest:Activate("spread_rumor")
                            cxt.quest:Activate("time_countdown")
                        end)
                end
            end

        end)
QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.DECLINED )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !shrug
                I dunno. I don't really like getting dirty.
                I just had these clothes dry-cleaned, after all.
            agent:
                !intrigue
                Wait, are we talking about the same type of mud slinging?
            player:
                !thought
                I'm pretty sure. I just don't want to get covered in mud.
                Let's try something else.
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
        end)
QDEF:AddConvo("spread_rumor")
    :Quips{
        {
            tags = "need_convincing",
            [[
                !hips
                Big if true. That is a BIG if, though.
            ]],
            [[
                !thought
                I find this hard to believe. Please enlighten me on this topic.
            ]],
            [[
                !dubious
                Wait, is that supposed to be a bad thing? Can you elaborate on that?
            ]],
            [[
                {is_supporter?
                    !angry_accuse
                    You're lying! You can't just say things without proof!
                }
                {not is_supporter?
                    !crossed
                    I'll admit I don't like {target} that much, but what you are saying sounds way over the top.
                }
            ]],
            [[
                !crossed
                And people die when they are killed. What's your point?
            ]],
            [[
                !dubious
                Is that true? Tell me more about it.
            ]],
        },
    }
    :Loc{
        OPT_CONVINCE = "Convince {agent} that your rumor about {target} is true",
        TT_CONVINCE = "The more people you convince, the bigger the story gets, and the bigger the holes in your story gets.",
        DIALOG_CONVINCE = [[
            {is_supporter?
            player:
                !point
                You're one of {target}'s supporters, aren't you?
            agent:
                !crossed
                Maybe I am, maybe I'm not. What about it?
            player:
                !chuckle
                Oh, I'm sure you won't be once you hear this about {target}.
            }
            {not is_supporter?
            player:
                !cagey
                Hey, have you been keeping up with the election? Nasty rumor going around about {target}.
            agent:
                !intrigue
                There's a rumor going around? What's it about?
            }
            player:
                {1}
            agent:
                %need_convincing
        ]],
        DIALOG_CONVINCE_SUCCESS = [[
            player:
                It all lines up, doesn't it? {target}'s guilty as Hesh!
            agent:
            {is_supporter?
                !spit
                Hesh dammit- To think I ever supported {target}.
            }
            {not is_supporter?
                !crossed
                I didn't think there were more reasons to not support {target}, but this...
            }
                Thanks for showing me what kind of person {target} truly is.
            * You've got one more person moving your gossip around their faction.
            * {target}'s reputation is definitely going to be stained after this.
        ]],
        DIALOG_CONVINCE_FAILURE = [[
            agent:
                Wait a second!
                !angry_accuse
                There is a contradiction in what you just said!
                Just what are you trying to pull?
            player:
                Well, uh...
            agent:
            {not is_supporter?
                And here I though you finally found some dirt on {target}.
                It turns out just to be more baseless rumor.
            }
            {is_supporter?
                Hearing you out was a mistake. I knew I should trust {target} more than you.
            }
            * Oops, the holes in your story gets exposed.
            {not failed_once?
                * Not to worry. As long as you convince enough people of your story, it will make {agent} look like the fool here.
                * You have one more chance of making it right. Don't screw this up.
            }
            {failed_once?
                * People are going to catch on, and your rumor will dissipate.
                * This does not look good for you.
            }
        ]],
        SIT_MOD_POS = "{agent} supports {target}",
        SIT_MOD_NEG = "{agent} opposes {target}",
        SIT_MOD = "Baseless allegation",

        REQ_DIFFERENT_FACTION = "You already spread this rumor among {agent}'s faction",
        REQ_DIFFERENT_LOCATION = "You already spread this rumor at this location",
    }
    :Hub(function(cxt)
        cxt.quest.param.convinced_factions = cxt.quest.param.convinced_factions or {}
        cxt.quest.param.convinced_locations = cxt.quest.param.convinced_locations or {}
        if cxt:GetAgent() and not cxt:GetAgent():IsCastInQuest(cxt.quest) then

            local opposition_data = DemocracyUtil.GetOppositionData(cxt:GetCastMember("target"))
            local support = 0
            if opposition_data then
                support = support + (opposition_data.faction_support[cxt:GetAgent():GetFactionID()] or 0)
                support = support + (opposition_data.wealth_support[DemocracyUtil.GetWealth(cxt:GetAgent())] or 0)
            end
            cxt.enc.scratch.target_support = support
            if cxt.enc.scratch.target_support > 0 then
                cxt.enc.scratch.is_supporter = true
            end

            local sit_mod = { { value = 20, text = cxt:GetLocString("SIT_MOD") } }
            if cxt.enc.scratch.target_support ~= 0 then
                table.insert(sit_mod, { value = 2 * cxt.enc.scratch.target_support, text = cxt:GetLocString(cxt.enc.scratch.target_support > 0 and "SIT_MOD_POS" or "SIT_MOD_NEG") })
            end

            cxt:Opt("OPT_CONVINCE")
                :PostText("TT_CONVINCE")
                :ReqCondition(not table.arraycontains(cxt.quest.param.convinced_factions, cxt:GetAgent():GetFactionID()), "REQ_DIFFERENT_FACTION")
                :ReqCondition(not table.arraycontains(cxt.quest.param.convinced_locations, cxt.location), "REQ_DIFFERENT_LOCATION")
                :Dialog("DIALOG_CONVINCE", cxt.quest.param.rumor)
                :Negotiation{
                    on_start_negotiation = function(minigame)
                        local count = #cxt.quest.param.convinced_factions
                        if count >= 2 then
                            minigame.player_negotiator:AddModifier("FATIGUED")
                        end
                        for k = 1, count do
                            local card = Negotiation.Card( "supporting_rumor", minigame.player_negotiator.agent )
                            card.show_dealt = true
                            card:TransferCard(minigame:GetDrawDeck())
                        end
                        if cxt.quest.param.failed_once then
                            local card = Negotiation.Card( "conflicting_rumor", minigame.player_negotiator.agent )
                            card.show_dealt = true
                            card:TransferCard(minigame:GetDrawDeck())
                        end
                    end,
                    situation_modifiers = sit_mod,
                }
                    :OnSuccess()
                        :Dialog("DIALOG_CONVINCE_SUCCESS")
                        :Fn(function(cxt)
                            table.insert(cxt.quest.param.convinced_factions, cxt:GetAgent():GetFactionID())
                            table.insert(cxt.quest.param.convinced_locations, cxt.location)
                        end)
                    :OnFailure()
                        :Dialog("DIALOG_CONVINCE_FAILURE")
                        :Fn(function(cxt)
                            if cxt.quest.param.failed_once then
                                cxt.quest:Fail()
                            else
                                cxt.quest.param.failed_once = true
                            end
                        end)
        end
    end)

QDEF:AddConvo("spread_rumor", "primary_advisor")
    :Loc{
        OPT_END_EARLY = "Finish quest early",
        DIALOG_END_EARLY = [[
            player:
                I'm done.
            agent:
                Wait, really?
                But there's still plenty of time!
            player:
                Nothing else I can do.
            agent:
                Suit yourself, I guess.
        ]],
    }
    :Hub(function(cxt, who)
        cxt:Opt("OPT_END_EARLY")
            :SetQuestMark(cxt.quest)
            :Dialog("DIALOG_END_EARLY")
            :Fn(function(cxt)
                cxt.quest:Complete("time_countdown")
            end)
    end)

QDEF:AddConvo("out_of_time", "primary_advisor")
    :Loc{
        OPT_TALK_PROGRESS = "Talk about your progress",
        DIALOG_TALK_PROGRESS = [[
            agent:
                So? How did you do?
        ]],
        DIALOG_NO_CONVINCE = [[
            player:
                !bashful
                Well, I thought my wordcraft and ability to move the rumor mill was impeccable.
            {failed_once?
                But my silver coated tongue couldn't convince the first person I talked to.
            agent:
                !palm
                So the rumor's dead in the water? Great.
            }
            {not failed_once?
                !scared_shrug
                But it turns out that thought-beam tech is pretty far off in the future. Who knew, right?
            agent:
                !angry
                You didn't even try to talk to people? But you had such an important story!
            }
        ]],
        DIALOG_ONE_CONVINCE = [[
            player:
                I got the idea in one person's head, at least.
            {not failed_once?
            agent:
                !palm
                That's not going to be a big enough rumor for {target}'s reputation to be dragged down.
            player:
                !point
                Hey! It's still someone spreading it. Doesn't every voter count?
            agent:
                !chuckle
                Ha! Good one, {player}. If only you were as good at rumor milling as telling jokes.
            }
            {failed_once?
                At the cost of someone else refusing to believe it.
            agent:
                !angry
                So the two cancel out, and we're back to square one. That was a productive use of your time.
            }
        ]],
        DIALOG_MORE_CONVINCE = [[
            player:
                !hips
                You'll be happy to know I've gotten {1} people talking about it.
            {not failed_once?
            agent:
                !happy
                Yes, yes! Enough factions dispersing the rumor will give it a lot of credibility.
                !thought
                I can already see it now. A night down at the Slurping Snail, and the thought on everyone's mind, on the tip of every tongue.
                "{2}"
            }
            {failed_once?
                Although there is a dissenter among them. Don't know how much that'll impact it's credibility.
            agent:
                !wave
                That oughta be fine. One or two people who don't believe it won't hurt the rumor too much.
                !thought
                Just think, everyone will be talking about it. {target} won't be able to escape such a powerful rumor that...
                {2}
            }
        ]],
    }
    --This final part is where the issue lies.
    :Hub(function(cxt)
        cxt:Opt("OPT_TALK_PROGRESS")
            :SetQuestMark()
            :Dialog("DIALOG_TALK_PROGRESS")
            :Fn(function(cxt)
                cxt.quest.param.convinced_factions = cxt.quest.param.convinced_factions or {}
                local count = #cxt.quest.param.convinced_factions
                if count == 0 then
                    cxt:Dialog("DIALOG_NO_CONVINCE")
                    cxt.quest:Fail()
                elseif count == 1 then
                    cxt:Dialog("DIALOG_ONE_CONVINCE")
                    if cxt.quest.param.failed_once then
                        cxt.quest:Fail()
                    else
                        cxt.quest.param.poor_performance = true
                        cxt.quest:Complete()
                    end
                else
                    cxt:Dialog("DIALOG_MORE_CONVINCE", count, cxt.quest.param.rumor)
                    cxt.quest.param.poor_performance = cxt.quest.param.failed_once
                    cxt.quest:Complete()
                end
            end)
            :DoneConvo()
    end)
