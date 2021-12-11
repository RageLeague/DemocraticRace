function DoPromoteAdmiralty(cxt)
    if cxt.quest.param.high_bounty then
        if cxt.quest:GetCastMember("admiralty"):GetContentID() ~= "ADMIRALTY_PATROL_LEADER" then
            DemocracyUtil.DoSentientPromotion(cxt.quest:GetCastMember("admiralty"), "ADMIRALTY_PATROL_LEADER")
        else
            -- do something to patrol leader. Haven't figured out what
        end
    end
end

-- this is a followup of a convo option. Can't automatically spawn
local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    on_destroy = function(quest)
        if quest:GetCastMember("admiralty"):IsInPlayerParty() then
            quest:GetCastMember("admiralty"):Dismiss()
        end
        if quest:GetCastMember("target"):IsInPlayerParty() then
            quest:GetCastMember("target"):Dismiss()
        end
    end,
    on_init = function(quest)
        if not quest.param.arrest_difficulty then
            quest.param.arrest_difficulty = math.random(3,7) -- too lazy to implement the full one in the convo
        end
    end,
}
:AddCast{
    cast_id = "admiralty",
    -- no_validation = true,
    
    -- The admiralty kinda has to work on this quest. it should be important for them.
    -- otherwise our quest detector won't detect it.
    -- unimportant = true,
    condition = function(agent, quest)
        return agent:GetFactionID() == "ADMIRALTY"
    end,
    -- cast_fn = function(quest, t)
    --     -- can't automatically spawn
    -- end,
    events = {
        agent_retired = function(quest, agent)
            quest:Fail()
        end,
    },
}
:AddCast{
    cast_id = "target",
    -- no_validation = true,
    unimportant = true,
    -- cast_fn = function(quest, t)
    --     -- can't automatically spawn
    -- end,
    on_assign = function(quest, agent)
        quest.param.target_faction = agent:GetFactionID()
        if agent:GetRenown() + agent:GetCombatStrength() >= math.random(3,8) then
            quest.param.high_bounty = true
        end
        if agent:GetFactionID() == "ADMIRALTY" then
            quest.param.is_ad = true
        end
        if agent:GetFactionID() == "SPARK_BARON" or agent:GetFactionID() == "CULT_OF_HESH" then
            quest.param.rival_faction = true
            
        end
        if agent:GetFaction():IsUnlawful() then
            quest.param.unlawful = true
        end
    end,
    events = {
        agent_retired = function(quest, agent)
            quest:Complete()
        end,
    },
}
:AddLocationCast{
    cast_id = "station",
    cast_fn = function(quest, t)
        table.insert( t, TheGame:GetGameState():GetLocation("ADMIRALTY_BARRACKS"))
    end,
}
:AddObjective{
    id = "wait",
    hide_in_overlay = true,
    state = QSTATUS.ACTIVE,

    events = 
    {
        action_clock_advance = function(quest, location)
            -- if quest.param.dormant_start_time ~= Now() then
            quest.param.dormant_timer = (quest.param.dormant_timer or 0) - 1
            if math.random() < 0.3 then
                quest.param.dormant_timer = quest.param.dormant_timer + 1
            end
            if quest.param.dormant_timer <= 0 then
                quest:Complete("wait")
                -- if math.random(1, 10) <= quest.param.guilt_score then
                    quest:Activate("action")
                -- else
                --     quest:Activate("innocent")
                -- end
            end

            -- end
        end,
    },

    on_activate = function(quest)
        quest:SetHideInOverlay(true)
        if not quest.param.investigate_difficulty then
            quest.param.unplanned = true
            quest:Complete("wait")
            quest:Activate("action")
        else
            quest.param.dormant_timer = quest.param.investigate_difficulty - math.random(0,5)
            -- if wait_for_next_time then
            quest.param.dormant_start_time = Now()
        end
        -- end
    end,
}
:AddObjective{
    id = "action",
    on_activate = function(quest)
        local score = (quest.param.arrest_difficulty or 5) + math.random(-3,3)
        if score <= 3 then
            quest.param.dominate = true
        elseif score >= 7 then
            quest.param.defeated = true
        else
            quest.param.impasse = true
        end
    end,
}
:AddObjective{
    id = "innocent",
}
:Loc{
    DESC_AD_AND_TARGET = "Follow {admiralty} and bring {target} to {station#location}",
    DESC_AD = "Follow {admiralty} to {station#location}",
    DESC_TARGET = "Bring {target} to {station#location}"
}
:AddObjective{
    id = "escort",
    title = "Go to the station",
    desc = "Go to {station}",
    desc_fn = function(quest, fmt_str)
        if quest.param.ad_dead then
            if not quest.param.target_dead then
                return quest:GetLocalizedStr( "DESC_TARGET" )
            end
        else
            if quest.param.target_dead then
                return quest:GetLocalizedStr( "DESC_AD" )
            else
                return quest:GetLocalizedStr( "DESC_AD_AND_TARGET" )
            end
        end
        return fmt_str
    end,
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/followup_admiralty_arrest.png"),
    on_activate = function(quest)
        quest:SetHideInOverlay(false)
        if quest:GetCastMember("admiralty"):IsAlive() then
            quest:GetCastMember("admiralty"):Recruit(PARTY_MEMBER_TYPE.ESCORT)
        end
        if quest:GetCastMember("target"):IsAlive() then
            quest:GetCastMember("target"):Recruit(PARTY_MEMBER_TYPE.CAPTIVE)
        end
    end,
    mark = {"station"},
    
}
:AddOpinionEvents{
    
    wasted_their_time = {
        delta = OPINION_DELTAS.DIMINISH,
        txt = "Wasted their time on a false lead",
    },
    suspects_setup = {
        delta = OPINION_DELTAS.BAD,
        txt = "Suspects you set them up",
    },
    saved_from_arrest = {
        delta = OPINION_DELTAS.MAJOR_GOOD,
        txt = "Saved them from Admiralty arrest",
    },
    helped_arrested = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Helped them arrested a criminal",
    },
    helped_arrested_bounty = {
        delta = OPINION_DELTAS.MAJOR_GOOD,
        txt = "Helped them capture a notorious criminal",
    },
    helped_arrested_bounty_interrupted = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Lead them to capture a notorious criminal, but you tried to intervene",
    },
    abandoned = {
        delta = OPINION_DELTAS.DISLIKE,
        txt = "Abandoned them",
    },
    saved_them = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Saved their life, but let a criminal go",
    },
}

QDEF:AddConvo("action")
    :Confront(function(cxt)
        if cxt.location:HasTag("in_transit") and TheGame:GetGameState():CanSpawnTravelEvent() then
            local target = cxt.quest:GetCastMember("target")
            local target_rank = TheGame:GetGameState():GetCurrentBaseDifficulty() - 2 + math.floor(target:GetRenown() / 2)
            if target_rank > 0 then
                CreateCombatBackup(target, target.combat_backup or "MERCENARY_BACKUP", target_rank)
            end
            local admiralty = cxt.quest:GetCastMember("admiralty")
            local ad_rank = TheGame:GetGameState():GetCurrentBaseDifficulty() - 3 + math.ceil(admiralty:GetRenown() / 2)
            if ad_rank > 0 then
                CreateCombatBackup(admiralty, "ADMIRALTY_PATROL_BACKUP", ad_rank)
            end
            if cxt.quest.param.dominate then
                return "STATE_DOMINATE"
            elseif cxt.quest.param.defeated then
                return "STATE_DEFEATED"
            else
                return "STATE_IMPASSE"
            end
        end
    end)
    :Loc{
        OPT_RECONSIDER = "Convince {admiralty} to reconsider",

        DIALOG_RECONSIDER = [[
            admiralty:
                !right
            player:
                !left
                Alright, you two have had your fun.
                how about you let {agent} go and you can all go home?
            admiralty:
            {not unplanned?
                !surprised
                Wait, what? This isn't part of the plan!
                |
                !crossed
                Why should I?
            }
        ]],

        DIALOG_RECONSIDER_SUCCESS = [[
            player:
            {is_ad?
                It's probably not a good idea to in-fight.
                You can probably let whatever did slide, right?
            }
            {rival_faction?
                I've been reconsidering my positions in the last few days.
                Then I realized now it's not a good time to start a war with the {target_faction#faction}.
                That's what the election is trying to <i>prevent</>.
            }
            {not (is_ad or rival_faction)?
                {not impasse?
                    The elections are coming soon, and we don't want to start arresting people now.
                    People will think we are blocking votes or something. That's bad for our reputation.
                }
                {impasse?
                    This fight, if it goes on, will surely end in bloodshed.
                    I'm sure no one would like that.
                }
            }
            admiralty:
                Fine, you win.
                You're free to go.
            target:
                !left
                What, really?
            admiralty:
                Just go. Forget this ever happened.
                I have enough trouble as it is.
                !exit
                Stupid grifters and their elections.
            * {admiralty} left.
        ]],

        DIALOG_RECONSIDER_FAILURE = [[
            player:
                You should probably let {target.himher} go.
            admiralty:
                Why should I, {player}?
            {not unplanned?
                You told me to investigate {target} and I did.
            target:
                !right
                !surprised
                You what?
            }
            admiralty:
                !right
                This took me way too much time. I'm not going to back away just because you said so.
                Just, stay out of my way until I bring this scum to the station.
        ]],
        SIT_MOD_BASE = "{admiralty} worked really hard to arrest {target}!",
        SIT_MOD_AD = "{target} is an Admiralty.",
        SIT_MOD_RIVAL = "{target} is a rival faction to the admiralty.",
        SIT_MOD_UNLAWFUL = "{target} is a criminal faction.",
        OPT_AD_FIGHT = "Free {target} by force",
        DIALOG_AD_FIGHT = [[
            admiralty:
                !right
            player:
                !left
                !fight
                I wasn't asking for permission.
            admiralty:
                What? How dare you?
        ]],
        DIALOG_AD_FIGHT_WIN = [[
            {ad_dead?
                * Great. {admiralty}'s dead.
            }
            {not ad_dead?
                admiralty:
                    !injured
                {not target_dead?
                    {not unplanned?
                        You treacherous scum.
                    }
                    !angry_accuse
                    I won't forget this!
                }
                {target_dead?
                    Would you look at that?
                    {target}'s dead.
                    {unplanned?
                        Now no one's happy.
                        |
                        Was it worth it, betraying someone only to fail your goal?
                    }
                }
                    !exit
            }
            {target_dead?
                * Nothing else to do here but leave.
            }
        ]],

        OPT_DEMORALIZE = "Demoralize {target}",

        SIT_MOD_TARGET = "{1#agent} is not going to give up that easily!",

        DIALOG_DEMORALIZE = [[
            agent:
                !right
            player:
                It's over, {agent}.
                You don't stand a chance against us.
            agent:
                I doubt it.
        ]],

        DIALOG_DEMORALIZE_SUCCESS = [[
            player:
                You might be able to take on {admiralty}, but us both? You won't stand a chance.
            agent:
                Oh no I'm scared.
                Okay, you win.
                I'll take my chances.
            admiralty:
                !right
                Wow, that actually worked.
        ]],

        DIALOG_DEMORALIZE_FAILURE = [[
            player:
                So? You wanna try me?
            agent:
                !dubious
                You don't look so fit.
                When was the last time you actually fought, huh?
            player:
                !thought
                Well, uhh...
            agent:
                That's what I thought.
        ]],
    }
    :State("STATE_DOMINATE")
        :Loc{
            DIALOG_INTRO = [[
                * You see {admiralty} has {agent} in cuffs.
                agent:
                    !right
                    !injured
                admiralty:
                    !left
                    !angry
                agent:
                {is_ad?
                    Must've been eyeing that promotion pretty hard, if you're stooping this low.
                admiralty:
                    !angryshrug
                    If you don't want me stooping this low, don't be such an easy target.
                }
                {rival_faction?
                    This is violating our truce! You'll be sorry!
                admiralty:
                    You're talking to the wrong person if you think I didn't cover my tracks.
                    The most they'll be able to do is get lost in the paperwork if they want to make a war out of an arrest.
                }
                {unlawful?
                    Just you wait, switch. You lock me up, and I'll be bounced out by lunch.
                    And then my friends and I will be coming for you.
                admiralty:
                    !notepad
                    Uh huh. Now, would you like to tell me who these "friends" are now or during the interrogation?
                }
                {not (is_ad or rival_faction or unlawful)?
                    What did I do? I've done nothing wrong.
                admiralty:
                    !chuckle
                    That's not what your file says.
                }
                admiralty:
                    !angry_accuse
                    You'll be coming with me, back to the station.
                * As you watch, {agent} flicks {agent.hisher} head at you.
                player:
                    !left
                agent:
                {not disliked?
                    Grifter! I need help! Just get me away from this cop!
                }
                {disliked?
                    !injuredpalm
                    I swear, icing on the Heshing cake...
                    What do <i>you</> want, {player}?
                }

            ]],
            --not disliked, planned; I thought of the player and admiralty being as aggressively tounge in cheek as possible.
            OPT_TAUNT = "{unplanned?Stand Aside|Taunt {target}}",
            DIALOG_TAUNT = [[
                {disliked?
                player:
                    !angry
                    {not unplanned?
                        Yes. That is exactly how I feel when I asked {admiralty} to investigate you.
                    agent:
                        !surprised
                        What? YOU are the one that caused this?
                        !angry_accuse
                        I always have a feeling it is you.
                        {unlawful?
                        player:
                            How, exactly do you know it's me when you keep engage in illegal activities?
                            Pretty sure you are on someone's bounty list anyway.
                            Eventually, your deeds are going to bite you in the back.
                        agent:
                            Oh, they're going to bite your back all right.
                        |
                        player:
                            So what, Captain Hindsight? What are you going to do about it?
                        }
                    }
                    {unplanned?
                        That's exactly it.
                        Would you look at that? How the {high_bounty?mighty|"mighty"} has fallen.
                    agent:
                        Guess so.
                    }
                }
                {not disliked?
                player:
                    {not unplanned?
                        !wave 
                        Hello officer! I see you're doing your civic duty today.
                    admiralty:
                        !right
                        Yep. Just clearing a bit of the...
                        !burp
                        A bit of the rabble, you could say.
                    agent:
                        Hey! I'm a part of this conversation too! 
                        {player}, help me!
                    player:
                        Well I'll just leave you to it, {admiralty}.
                        !salute
                        Hail to the admiralty.
                    admiralty:
                        !salute
                        Hail to the admiralty.
                    * With that, {admiralty} hauls {agent} away, {agent} knitting {agent.hisher}'s brow in conspiratorial thought.
                    }
                    {unplanned?
                        Why should I?
                        I'm more scared of the Admiralty than I'm scared of <i>you</>.
                    admiralty:
                        !right
                        I don't know if I like the sound of that, but at least it gets the meaning across.
                    agent:
                        !right
                        Oh, you want a reason for you to be scared?
                    }
                }
                agent:
                    I won't forget this.
                    If I ever got out of jail, I <i>will</> find you, and you <i>will</> regret the day you did this.
                admiralty:
                    !left
                    Witness intimidation, that's going to be a few more years, buddy.

            ]],

            -- OPT_RECONSIDER = "Convince {admiralty} to reconsider",

            -- DIALOG_RECONSIDER = [[
            --     admiralty:
            --         !right
            --     player:
            --         !left
            --         Can you reconsider?
            --     admiralty:
            --         !surprised
            --         Wait, what? This isn't part of the plan!
            -- ]],

            -- DIALOG_RECONSIDER_SUCCESS = [[
            --     player:
            --     {is_ad?
            --         It's probably not a good idea to in-fight.
            --         You can probably let whatever did slide, right?
            --     }
            --     {rival_faction?
            --         I've been reconsidering my positions in the last few days.
            --         Then I realized now it's not a good time to start a war with the {target_faction#faction}.
            --         That's what the election is trying to <i>prevent</>.
            --     }
            --     {not (is_ad or rival_faction)?
            --         The elections are coming soon, and we don't want to start arresting people now.
            --         People will think we are blocking votes or something. That's bad for our reputation.
            --     }
            --     admiralty:
            --         Fine, you win.
            --         You're free to go.
            --     target:
            --         !left
            --         What, really?
            --     admiralty:
            --         Just go. Forget this ever happened.
            --         I have enough trouble as it is.
            --         !exit
            --         Stupid grifters and their elections.
            --     * {admiralty} left.
            -- ]],

            -- DIALOG_RECONSIDER_FAILURE = [[
            --     player:
            --         You should probably let {target.himher} go.
            --     admiralty:
            --         Why should I, {player}?
            --         You told me to investigate {target} and I did.
            --     target:
            --         !right
            --         !surprised
            --         You what?
            --     admiralty:
            --         !right
            --         This took me way too much time. I'm not going to back away just because you said so.
            --         Just, stay out of my way until I bring this scum to the station.
            -- ]],

            OPT_ACCEPT = "Allow {admiralty} to take {target}",
            DIALOG_ACCEPT = [[
                player:
                    I'm sorry.
                    Just keep doing what you're doing.
                admiralty:
                    That's more like it.
                target:
                    !left
                admiralty:
                    Now, stop resisting. You're coming with me.
                player:
                    !left
                target:
                    !right
                    I can't believe you set me up!
                    You're going to regret it.
                admiralty:
                    !left
                    Witness intimidation, that's going to be a few more years, buddy.
            ]],
        }
        :Fn(function(cxt)
            local function ArrestFn(opt)
                if not cxt.quest.param.unplanned then
                    opt:ReceiveOpinion(OPINION.SOLD_OUT_TO_ADMIRALTY, nil, "target")
                end
                opt:GoTo("STATE_PROMOTION")
            end
            cxt.quest:GetCastMember("target"):ClearParty()
            cxt.quest:GetCastMember("target").health:SetPercent(math.random() * 0.2 + 0.4)
            cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("target"))
            cxt:Dialog("DIALOG_INTRO")

            ArrestFn(cxt:Opt("OPT_TAUNT")
                :Dialog("DIALOG_TAUNT")
                -- :Fn(ArrestFn)
            )
            local sitmod = {
                { value = 15, text = cxt:GetLocString("SIT_MOD_BASE") }
            }
            if cxt.quest.param.is_ad then
                table.insert(sitmod, { value = -10, text = cxt:GetLocString("SIT_MOD_AD") })
            elseif cxt.quest.param.rival_faction then
                table.insert(sitmod, { value = -5, text = cxt:GetLocString("SIT_MOD_RIVAL") })
            elseif cxt.quest.param.unlawful then
                table.insert(sitmod, { value = 10, text = cxt:GetLocString("SIT_MOD_UNLAWFUL") })
            end
            cxt:BasicNegotiation("RECONSIDER", {
                target_agent = cxt.quest:GetCastMember("admiralty"),
                situation_modifiers = sitmod,
                helpers = {"target"},
            }):OnSuccess()
                :Fn(function(cxt)
                    cxt.quest:GetCastMember("admiralty"):OpinionEvent(OPINION.WASTED_TIME)
                    cxt:GoTo("STATE_SAVE_TARGET")
                end)
            :OnFailure()
                :Fn(function(cxt)
                    cxt.quest.param.interrupted = true
                    local admiralty = cxt.quest:GetCastMember("admiralty")
                    local target = cxt.quest:GetCastMember("target")
                    -- ArrestFn(cxt)
                    ArrestFn(cxt:Opt("OPT_ACCEPT")
                        :Dialog("DIALOG_ACCEPT")
                    )
                        -- :Fn(ArrestFn)
                    local opt = cxt:Opt("OPT_AD_FIGHT", admiralty)
                        :Dialog("DIALOG_AD_FIGHT")
                    if not cxt.quest.param.unplanned then
                        opt:ReceiveOpinion(OPINION.BETRAYED, nil, "admiralty")
                    end
                    opt:Battle{
                            allies = target:GetParty() and target:GetParty():GetMembers() or {target},
                            enemies = admiralty:GetParty() and admiralty:GetParty():GetMembers() or {admiralty},
                        }
                        :OnWin()
                            :Fn(function(cxt)
                                cxt.quest.param.target_dead = target:IsDead()
                                cxt.quest.param.ad_dead = admiralty:IsDead()
                                cxt:Dialog("DIALOG_AD_FIGHT_WIN")
                                if not cxt.quest.param.ad_dead then
                                    admiralty:MoveToLimbo()
                                end
                                if not cxt.quest.param.target_dead then
                                    cxt:GoTo("STATE_SAVE_TARGET")
                                else
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                end
                            end)
                end)
        end)
    :State("STATE_IMPASSE")
        :Loc{
            DIALOG_INTRO = [[
                * You see {admiralty} and {agent} is about to start a fight.
                agent:
                    !right
                admiralty:
                    !left
                    Are you going to come quiet or not?
                agent:
                    Fat chance.
                * Suddenly, they saw you.
                player:
                    !left
                agent:
                {disliked?
                    What do <i>you</> want?
                    |
                    Grifter! Help me!
                }
                admiralty:
                    !right
                {unplanned?
                    Grifter! Help me capture a dangerous criminal!
                    |
                    Just in time, {player}. Let's finish this.
                }
            ]],

            OPT_STAND_ASIDE = "Stand aside and watch",

            DIALOG_STAND_ASIDE = [[
                player:
                    I'll let you guys figure it out.
                admiralty:
                    !right
                    Wait, where are you going?
                player:
                    !exit
                    !wait
                admiralty:
                    !fight
                    Alright then.
                agent:
                    !left
                    Catch me if you can!
                * The two stand off and launch into a bloody fight.
            ]],

            DIALOG_STAND_ASIDE_WIN = [[
                * Eventually, {admiralty} puts a large, government issue boot down on {agent}'s throat and claps handcuffs onto {agent.himher}.
                player:
                    !left
                admiralty:
                    !right
                    !angry
                {unplanned?
                    Why are you just standing there?
                    |
                    Why did you leave me?
                }
                player:
                    I don't do combats. Not anymore.
                admiralty:
                {not unplanned?
                    You are the one who wanted {agent} gone, and when it's actually happening, you're just going to do nothing?
                agent:
                    !right
                    !surprised
                    You what?
                }
                {unplanned?
                    Don't you have a duty as a citizen to apprehend criminals?
                player:
                    I don't remember that being a duty of a citizen.
                    That sounds more like the Admiralty's duty, which is a word that applies to you.
                }
                admiralty:
                    !right
                    I'm taking {agent} to the station.
                {high_bounty and not unplanned?
                    The Admiralty will remember that <i>I</> single-handedly apprehended a notorious criminal, while <i>you</> did nothing.
                }
                {liked?
                    Thanks for the help, <i>friend</>.
                    |
                    Goodbye.
                }
                    !exit
                * {admiralty.HeShe} left, leaving you wonder whether you did the right thing.
            ]],

            DIALOG_STAND_ASIDE_LOSE = [[
                * It comes to a close, though, with one bone crunching punch to the jaw.
                * {admiralty} lies on the ground either dead or unconscious. {agent} puts a quick end to that question with one last attack.
                agent:
                    !right
                {disliked?
                    Wasn't expecting that, were ya {is_ad?bloody traitor|switch}?
                    Well, if I've already got blood on my shoes, might as well make the dry cleaners earn my shills.
                    * {agent} whips {agent.hisher} weapons towards you.
                }
                {not disliked?
                    Thanks for nothing, grifter!
                    !exit
                    * That was a rather horrible turn of event.
                }
            ]],

            OPT_STAND_ASIDE_FIGHT = [[
                player:
                    !fight
                {disliked?
                    As you wish.
                }
                {not disliked?
                    We're not done here.
                }
            ]],

            DIALOG_DEFEND_WIN = [[
                {dead?
                    * The body's piling up today around you. That's not going to be good for your reputation.
                }
                {not dead?
                    agent:
                        !injured
                    player:
                        Are you done now?
                    agent:
                        Guess so.
                    player:
                        Now what do I do with you?
                }
            ]],

            OPT_TARGET_FIGHT = "Attack {1#agent}",

            DIALOG_TARGET_FIGHT = [[
                agent:
                    !right
                player:
                    !left
                    !fight
                    
                    Fine, let's rumble.
            ]],
            DIALOG_TARGET_FIGHT_WON = [[
                {target_dead?
                    {not ad_dead?
                        admiralty:
                            !right
                            Well, {target.heshe}'s dead.
                            We'll just say that {target} resisted arrest, which is literally what {target.heshe} did.
                    }
                    {ad_dead?
                        * Everyone's dying left and right today.
                    }
                }

                {not target_dead?
                    {not ad_dead?
                        target:
                            !right
                            !injured
                        admiralty:
                            !left
                            Now, are you going to come or not?
                        target:
                            Fine, I'll comply.
                    }
                    {ad_dead?
                        target:
                            !right
                            !injured
                            What now?
                            Your Admiralty friend is dead. What will you do?
                    }
                }
            ]],

            OPT_LET_GO = "Let {target} go",
            DIALOG_LET_GO = [[
                player:
                    Go.
                target:
                    !surprised
                    What?
                player:
                    It's not my job to arrest you.
                target:
                    Seriously?
                player:
                    Seriously.
                target:
                    You made a huge mistake, letting me go.
                    !exit
            ]],
            OPT_BRING_TO_STATION = "Bring {target} to {station} on your own",
            REQ_KNOWS_STATION = "You don't know the location of {station}",
            DIALOG_BRING_TO_STATION = [[
                player:
                    You are coming with me!
                target:
                    To where?
                player:
                    To {station}.
                target:
                    !dubious
                    Do you even know where it is?
                player:
                    Conveniently, I do.
                    !throadcut
                    As I was saying, you are coming with me!
            ]],
            OPT_FINISH_OFF = "Finish off {target}",
            DIALOG_FINISH_OFF = [[
                player:
                    A life for a life.
                target:
                    !exit
                * The job was quick.
            ]]
        }
        :RunLoopingFn(function(cxt)
            local target = cxt.quest:GetCastMember("target")
            local admiralty = cxt.quest:GetCastMember("admiralty")
            if cxt:FirstLoop() then
                cxt.enc:SetPrimaryCast(target)

                cxt:Dialog("DIALOG_INTRO")
            end
            if not cxt.quest.param.tried_negotiate_target then
                cxt:BasicNegotiation("DEMORALIZE",{
                    flags = NEGOTIATION_FLAGS.INTIMIDATION,
                    target_agent = target,
                    situation_modifiers = {{ value = 10, text = cxt:GetLocString("SIT_MOD_TARGET", target) }},
                    helpers = {"admiralty"},
                }):OnSuccess()
                    :Fn(function(cxt)
                        target:OpinionEvent(OPINION.SOLD_OUT_TO_ADMIRALTY)
                        -- target:GainAspect("stripped_influence", 5)
                    end)
                    :GoTo("STATE_PROMOTION")
                :OnFailure()
                    :Fn(function(cxt)
                        cxt.quest.param.tried_negotiate_target = true
                    end)
            else
                cxt:Opt("OPT_TARGET_FIGHT", target)
                    :Dialog("DIALOG_TARGET_FIGHT")
                    :Battle{
                        enemies = target:GetParty() and target:GetParty():GetMembers() or {target},
                        allies = admiralty:GetParty() and admiralty:GetParty():GetMembers() or {admiralty},
                    }
                    :OnWin()
                        :Fn(function(cxt)
                            cxt.quest.param.target_dead = target:IsDead()
                            cxt.quest.param.ad_dead = admiralty:IsDead()
                            cxt:Dialog("DIALOG_TARGET_FIGHT_WON")
                            if not cxt.quest.param.ad_dead then
                                cxt:GoTo("STATE_PROMOTION")
                            else
                                if cxt.quest.param.target_dead then
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                else
                                    cxt:Opt("OPT_LET_GO")
                                        :Dialog("DIALOG_LET_GO")
                                        :CompleteQuest()
                                        :Travel()
                                    cxt:Opt("OPT_BRING_TO_STATION")
                                        :ReqCondition(DemocracyUtil.LocationUnlocked("ADMIRALTY_BARRACKS"), "REQ_KNOWS_STATION")
                                        :Dialog("DIALOG_BRING_TO_STATION")
                                        :CompleteQuest("action")
                                        :ActivateQuest("escort")
                                        :Travel()
                                    cxt:Opt("OPT_FINISH_OFF")
                                        :Dialog("DIALOG_FINISH_OFF")
                                        :Fn(function(cxt)
                                            AgentUtil.CommitMurder(target) 
                                            target:Kill()
                                        end)
                                        :CompleteQuest()
                                        :Travel()
                                end
                            end
                        end)
            end
            if not cxt.quest.param.interrupted then
                local sitmod = {
                    { value = 5, text = cxt:GetLocString("SIT_MOD_BASE") }
                }
                if cxt.quest.param.is_ad then
                    table.insert(sitmod, { value = -10, text = cxt:GetLocString("SIT_MOD_AD") })
                elseif cxt.quest.param.rival_faction then
                    table.insert(sitmod, { value = -5, text = cxt:GetLocString("SIT_MOD_RIVAL") })
                elseif cxt.quest.param.unlawful then
                    table.insert(sitmod, { value = 10, text = cxt:GetLocString("SIT_MOD_UNLAWFUL") })
                end
                cxt:BasicNegotiation("RECONSIDER", {
                    target_agent = cxt.quest:GetCastMember("admiralty"),
                    situation_modifiers = sitmod,
                    helpers = {"target"},
                }):OnSuccess()
                    :Fn(function(cxt)
                        cxt.quest:GetCastMember("admiralty"):OpinionEvent(OPINION.WASTED_TIME)
                        cxt:GoTo("STATE_SAVE_TARGET")
                    end)
                :OnFailure()
                    :Fn(function(cxt)
                        -- cxt.quest.param.tried_negotiate_ad = true
                        cxt.quest.param.interrupted = true
                        -- ArrestFn(cxt)
                    end)
            else
                local opt = cxt:Opt("OPT_AD_FIGHT", admiralty)
                    :Dialog("DIALOG_AD_FIGHT")
                if not cxt.quest.param.unplanned then
                    opt:ReceiveOpinion(OPINION.BETRAYED, nil, "admiralty")
                end
                opt:Battle{
                        allies = target:GetParty() and target:GetParty():GetMembers() or {target},
                        enemies = admiralty:GetParty() and admiralty:GetParty():GetMembers() or {admiralty},
                    }
                    :OnWin()
                        :Fn(function(cxt)
                            cxt.quest.param.target_dead = target:IsDead()
                            cxt.quest.param.ad_dead = admiralty:IsDead()
                            cxt:Dialog("DIALOG_AD_FIGHT_WIN")
                            admiralty:MoveToLimbo()
                            if not cxt.quest.param.target_dead then
                                cxt:GoTo("STATE_SAVE_TARGET")
                            else
                                StateGraphUtil.AddLeaveLocation(cxt)
                            end
                        end)
            end

            cxt:Opt("OPT_STAND_ASIDE")
                :Dialog("DIALOG_STAND_ASIDE")
                :Fn(function(cxt)
                    if math.random() < 0.5 then
                        cxt:Dialog("DIALOG_STAND_ASIDE_WIN")
                        cxt.quest:GetCastMember("target"):OpinionEvent(cxt.quest.param.unplanned and cxt.quest:GetQuestDef():GetOpinionEvent("abandoned") or OPINION.SOLD_OUT_TO_ADMIRALTY)
                        cxt.quest:GetCastMember("target"):GainAspect("stripped_influence", 5)
                        cxt.quest:GetCastMember("target"):Retire()
                        cxt.quest:GetCastMember("admiralty"):OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("abandoned"))
                        cxt.quest:Complete()
                        StateGraphUtil.AddLeaveLocation(cxt)
                    else
                        cxt:Dialog("DIALOG_STAND_ASIDE_LOSE")
                        cxt.quest:GetCastMember("admiralty"):Kill()
                        DemocracyUtil.DeltaAgentSupport(-5, cxt.quest:GetCastMember("admiralty"), "NEGLIGENCE")
                        
                        -- if  then
                            -- cxt.quest:GetCastMember("target"):OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("abandoned"))
                        cxt:Opt(cxt:GetAgent():GetRelationship() < RELATIONSHIP.NEUTRAL and "OPT_DEFEND" or "OPT_ATTACK")
                            :Dialog("OPT_STAND_ASIDE_FIGHT")
                            :Battle{
                                flags = cxt:GetAgent():GetRelationship() < RELATIONSHIP.NEUTRAL and BATTLE_FLAGS.SELF_DEFENCE,
                            }
                            :OnWin()
                                :Dialog("DIALOG_DEFEND_WIN")
                                :Fn(function(cxt)
                                    cxt:Opt("OPT_LET_GO")
                                        :Dialog("DIALOG_LET_GO")
                                        :CompleteQuest()
                                        :Travel()
                                    cxt:Opt("OPT_BRING_TO_STATION")
                                        :ReqCondition(DemocracyUtil.LocationUnlocked("ADMIRALTY_BARRACKS"), "REQ_KNOWS_STATION")
                                        :Dialog("DIALOG_BRING_TO_STATION")
                                        :CompleteQuest("action")
                                        :ActivateQuest("escort")
                                        :Travel()
                                    cxt:Opt("OPT_FINISH_OFF")
                                        :Dialog("DIALOG_FINISH_OFF")
                                        :Fn(function(cxt)
                                            AgentUtil.CommitMurder(target) 
                                            target:Kill()
                                        end)
                                        :CompleteQuest()
                                        :Travel()
                                
                                end)
                        -- else
                        --     cxt.quest:GetCastMember("target"):OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("abandoned"))
                        --     StateGraphUtil.AddLeaveLocation(cxt)
                        -- end
                    end
                end)
        end)
    :State("STATE_DEFEATED")
        :Loc{
            DIALOG_INTRO = [[
                {is_unlawful?
                    * You find an ironic scene, an officer of the Admiralty underneath the foot of {target}.
                admiralty:
                    !left
                    !injured
                target:
                    !right
                    !angry
                    Made a damn big mistake, crossing me, switch.
                }
                {is_ad?
                    * You find {admiralty} dealing with some..."special clerical work".
                admiralty:
                        !left
                        !injured
                    target:
                        !right
                        !angry
                        How's that promotion looking now? I bet it's looking mighty fine now.
                }
                {rival_faction?
                    * You come across {target} speaking power to power with {admiralty}. 
                    admiralty:
                        !left
                        !injured
                    target:
                        !right
                        !angry
                        Shouldn't of tried to break the truce that sloppily. Look at where it's gotten you.
                }
                {not (is_ad or rival_faction or unlawful)?
                    * In a surprise twist, you find the ordinary citizen has won out against the Admiralty.
                admiralty:
                    !left
                    !injured
                target:
                    !right
                    !angry
                    Y'see, Big Brother? Y'see what happens when you mess with the little guys like me?
                }
                * Fortunately, {target}'s monologuing has given you a chance to strike or a chance to leave.
            ]],
            --
            OPT_SLIP_AWAY = "Slip away before anyone notices",
            DIALOG_SLIP_AWAY = [[
                * As quickly as you came, you sneak away to let those two bury the hatchet.
                * <i>Violently</> bury the hatchet. Most likely, in {admiralty}'s face.
            ]],

            SIT_MOD_HIGH_MORALE = "{target} just won a battle against {admiralty}",
            OPT_CONVINCE_SPARE = "Convince {target} to spare {admiralty}",

            DIALOG_CONVINCE_SPARE = [[
                player:
                    !left
                    Look buddy. I get it. You're gloating.
                    But you might want to wrap it up before the rest of the admiralty catches wind.
                target:
                    What?
                    Why should I?
                    Give me a good reason?
            ]],

            DIALOG_CONVINCE_SPARE_SUCCESS = [[
                player:
                {is_ad?
                    I get that all of you switches are one big happy family out in those cramped barracks of yours.
                    !point
                    But if you kill {admiralty}, something's going to come back to you.
                    And someone's going to come for your badge all the same as {admiralty} did.
                target:
                    !sigh
                    True.
                }
                {not is_ad?
                    If the blood, broken bones, and whimpering hasn't clued you in yet, {admiralty}'s learned {admiralty.hisher} lesson.
                    Let {admiralty} go, and the lesson oughta spread. Spread like the plague.
                    The law's not going to mess with you if you can mess up the law.
                target:
                    Convincing argument you've got there.
                }
                admiralty:
                    !left
                    !injured
                target:
                    Look, if it makes you both shut up, I'll cut a deal.
                    You stay away from me. You tell people about how I'm not to be messed with.
                    It's an "You scratch my back, I don't scratch your back like a starving lumicyte." system I want here. Do you understand?
                admiralty:
                    I've got nothing else to understand.
                target:
                    Good. Let's shake on it.
                    !give
                admiralty:
                    !give
                * With that, your chances of removing {target} were sacrificed for {admiralty}'s life.
                * Maybe this is for the best.
            ]],
            DIALOG_CONVINCE_SPARE_FAILURE = [[
                player:
                    Don't think about catharsis. Think...
                    !interest
                    Think about your <i>soul</>.
                target:
                    !wave
                    Oh please.
                    I have no soul.
            ]],

            OPT_LEAVE = "Leave",

            DIALOG_LEAVE = [[
                player:
                    Sorry for bothering you. I'll see my self out.
                target:
                    You'd better be.
                admiralty:
                    !right
                    Wait, where you're going.
                player:
                    Leaving.
                    I don't want to be caught up in this mess.
                    !exit
                * You left. Immediately after, {target} killed {admiralty}.
                * At least you're still alive... and you haven't attacked anyone...
                * ...but was it worth it?
            ]],

            OPT_ATTACK = "Attack {target} to save {admiralty}",
            DIALOG_ATTACK = [[
                player:
                    !fight
                    Fine, you want to do this the hard way, then.
            ]],
            DIALOG_ATTACK_WIN = [[
                {dead?
                    admiralty:
                        !right
                        {target.HeShe}'s dead, huh?
                    player:
                        !shrug
                        Guess so.
                    admiralty:
                        Thanks for saving me.
                        And taking down a criminal.
                }
                {not dead?
                    target:
                        !right
                        !injured
                    player:
                    {pleaded?
                        You should've quit while you're ahead.
                        Look where you've ended up now.
                        |
                        I tried to talk some sense to you, but you wouldn't listen.
                        I guess you need some bruises to come to your senses, huh?
                    }
                    target:
                        You win.
                        What do you want from me now.
                    admiralty:
                        !left
                        You come with me, to the station.
                }
            ]],
        }
        :Fn(function(cxt)
            local target = cxt.quest:GetCastMember("target")
            local admiralty = cxt.quest:GetCastMember("admiralty")
            local function AttackPhase(cxt)
                cxt:Opt("OPT_ATTACK")
                    :Dialog("DIALOG_ATTACK")
                    :Battle{
                        enemies = target:GetParty() and target:GetParty():GetMembers() or {target},
                    }:OnWin()
                        :Fn(function(cxt) cxt.quest.param.target_dead = target:IsDead() end)
                        :Dialog("DIALOG_ATTACK_WIN")
                        :GoTo("STATE_PROMOTION")
                if cxt.quest:GetCastMember("target"):GetRelationship() > RELATIONSHIP.HATED then
                    cxt:Opt("OPT_LEAVE")
                        :Dialog("DIALOG_LEAVE")
                        :Fn(function(cxt)
                            cxt.quest:GetCastMember("admiralty"):Kill()
                            DemocracyUtil.DeltaAgentSupport(-5, cxt.quest:GetCastMember("admiralty"), "NEGLIGENCE")
                        end)
                        :FailQuest()
                        :Travel()
                end
            end
            cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("target"))
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_SLIP_AWAY")
                :Dialog("DIALOG_SLIP_AWAY")
                :Fn(function(cxt)
                    cxt.quest:GetCastMember("admiralty"):Kill()
                end)
                :FailQuest()
                :Travel()
            cxt:BasicNegotiation("DEMORALIZE",{
                    flags = NEGOTIATION_FLAGS.INTIMIDATION,
                    target_agent = target,
                    situation_modifiers = {{ value = 25, text = cxt:GetLocString("SIT_MOD_HIGH_MORALE") }},
                    helpers = {"admiralty"},
                }):OnSuccess()
                    -- :Fn(function(cxt)
                    --     target:OpinionEvent(OPINION.SOLD_OUT_TO_ADMIRALTY)
                    --     -- target:GainAspect("stripped_influence", 5)
                    -- end)
                    :ReceiveOpinion(OPINION.SOLD_OUT_TO_ADMIRALTY, nil, "target")
                    :GoTo("STATE_PROMOTION")
                :OnFailure()
                    :Fn(function(cxt)
                        AttackPhase(cxt)
                    end)
            cxt:BasicNegotiation("CONVINCE_SPARE",{
                -- flags = NEGOTIATION_FLAGS.INTIMIDATION,
                target_agent = target,
                -- situation_modifiers = {{ value = 25, text = cxt:GetLocString("SIT_MOD_HIGH_MORALE") }},
                helpers = {"admiralty"},
                }):OnSuccess()
                    :Fn(function(cxt)
                        -- target:OpinionEvent(OPINION.SOLD_OUT_TO_ADMIRALTY)
                        -- target:GainAspect("stripped_influence", 5)
                    end)
                    :ReceiveOpinion("saved_them", nil, "admiralty")
                    :CompleteQuest()
                    :Travel()
                :OnFailure()
                    :Fn(function(cxt)
                        cxt.quest.param.pleaded = true
                        AttackPhase(cxt)
                    end)
        end)
    :State("STATE_PROMOTION")
        :Loc{
            DIALOG_PROMOTION = [[
                agent:
                    This one's got a big head on {target.hisher} shoulders. Big head means big bounty.
                {unplanned?
                    Thanks for your help back there?
                    {dominate?
                    player:
                        But I didn't do anything!
                    agent:
                        Exactly.
                    }
                    |
                    It's all thanks to your lead, {player}.
                }
                {interrupted?
                    Even though you tried to interfere in the end.
                    I have no idea what you're thinking.
                }
                ** {agent} will be promoted to an Admiralty Patrol Leader if {agent.heshe} isn't one already.
            ]],
            DIALOG_LEAVE = [[
                player:
                    !left
                agent:
                    !right
                {target_dead?
                    Well, I'm going to the station.
                }
                {not target_dead?
                    Well, I'm bringing this guy to the station.
                }
            ]],
            DIALOG_LEARN_STATION = [[
                player:
                    Wait, I've never been to the Admiralty Headquarters before.
                    Can you show me the way?
                agent:
                    Oh, I guess you've never been there before.
                    Wanna come?
            ]],
            OPT_ACCEPT_INVITE = "Accept {admiralty}'s offer",
            DIALOG_ACCEPT_INVITE = [[
                player:
                    Sure, why not.
                agent:
                    Follow me.
            ]],
            OPT_DECLINE_INVITE = "Decline {admiralty}'s offer",
            DIALOG_DECLINE_INVITE = [[
                player:
                    Nah, I have better places to be.
                agent:
                    Oh well. Maybe next time.
            ]],

            DIALOG_END = [[
            agent:
            {interrupted?
                I was quite disappointed with what you did back there.
                Oh well. All's well that Maxwell.
                I mean, ends well.
            }
                See you!
                !exit
            {interrupted?
                That was real weird.
            }
            {not target_dead?
                * You left {agent} to escort {target}.
                * Hopefully you'll never see {target} again.
            }
            {target_dead?
                * You left {agent}, who will report {target}'s death.
            }
            ]],
        }
        :Fn(function(cxt)
            cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("admiralty"))
            
            if cxt.quest.param.high_bounty then
                cxt:Dialog("DIALOG_PROMOTION")
                if cxt.quest.param.interrupted then
                    cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("helped_arrested_bounty_interrupted"))
                else
                    cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("helped_arrested_bounty"))
                end
            else
                cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("helped_arrested"))
            end

            cxt:Dialog("DIALOG_LEAVE")
            if not DemocracyUtil.LocationUnlocked("ADMIRALTY_BARRACKS") and not cxt.quest.param.interrupted then
                cxt:Dialog("DIALOG_LEARN_STATION")
                -- DemocracyUtil.DoLocationUnlock(cxt, "ADMIRALTY_BARRACKS")
                cxt:RunLoopingFn(function(cxt)
                    cxt:Opt("OPT_ACCEPT_INVITE")
                        :Dialog("DIALOG_ACCEPT_INVITE")
                        :CompleteQuest("action")
                        :ActivateQuest("escort")
                        :Travel()

                    cxt:Opt("OPT_DECLINE_INVITE")
                        :Dialog("DIALOG_DECLINE_INVITE")
                        :Pop()
                end)
            end
            if cxt.quest:IsActive("action") then
                cxt:Dialog("DIALOG_END")
                if not cxt.quest:GetCastMember("target"):IsDead() then
                    cxt.quest:GetCastMember("target"):GainAspect("stripped_influence", 5)
                    cxt.quest:GetCastMember("target"):Retire()
                end
                cxt.quest:GetCastMember("admiralty"):MoveToLocation(cxt.quest:GetCastMember("station"))
                cxt.quest:Complete()
                DoPromoteAdmiralty(cxt)
                StateGraphUtil.AddLeaveLocation(cxt)
            end
        end)
    :State("STATE_SAVE_TARGET")
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
                agent:
                    !right
                {disliked?
                    Why did you do that?
                    You could've just sat aside and do nothing, yet you chose to save me.
                player:
                    I don't know. Maybe I want to help you, that's all.
                    {not unplanned?
                    agent:
                        Nah. I don't trust you. There's got to be more to this.
                        Care to explain what is this "plan" that {admiralty} mentioned?
                    }
                }
                {not disliked?
                    Thanks, mate.
                    I was in a real pickle there.
                player:
                    I can't just stand around here and do nothing, seeing innocent people getting arrested.
                    {unlawful?
                        "Relatively" innocent, anyway.
                    }
                    {not unplanned?
                    agent:
                        I would've believed you, if {admiralty} didn't mention a plan, that you are a part of.
                        Care to explain it?
                    }
                }
                {unplanned?
                agent:
                    Well, I guess I should just accept that.
                    See you around, grifter!
                    !exit
                }
            ]],
            OPT_BRUSH_OFF = "Brush off {agent}'s concern",
            DIALOG_BRUSH_OFF = [[
                player:
                    !handwave
                    [p] Don't worry about it.
                agent:
                    Now worrying is all I care about.
                    !angry_accuse
                    I'm starting to think you set me up!
                    !throatcut
                    Watch your back, grifter.
                    !exit
                * {agent.HeShe} leaves, and so should you.
            ]],
            OPT_EXCUSE = "Make an excuse",
            DIALOG_EXCUSE = [[
                player:
                    There's a simple reason for it.
                agent:
                    Oh yeah?
                    !clap
                    Let's hear it.
            ]],
            DIALOG_EXCUSE_SUCCESS = [[
                agent:
                    You talked a lot, and I think I heard enough.
                    {admiralty} was probably just finding someone to blame.
                player:
                    Sure, let's go with that.
                agent:
                {disliked?
                    Looks like I misjudged you.
                    |
                    Thanks again for saving me.
                }
                    Be seeing you around, {player}.
                    !exit
            ]],
            DIALOG_EXCUSE_FAILURE = [[
                agent:
                    That just sounds like a poor excuse.
                    I don't buy your story.
                    You were trying to set me up, aren't you?
                player:
                    Uhh...
                agent:
                {disliked?
                    I knew you were up to no good.
                    Here I thought you actually did a good thing for once.
                    That would be too ideal, wouldn't it?
                    |
                    Here I thought there's finally good in Havaria.
                    Of course not. Why would there be good in Havaria? That's ridiculous.
                player:
                    Well, you <i>are</> a criminal who committed a crime. I wouldn't exactly call helping you "good".
                agent:
                    So you revealed your true colors, huh?
                }
                    !throatcut
                    Watch your back, grifter.
                    !exit
                * {agent.HeShe} leaves, and so should you.
            ]]
        }
        :Fn(function(cxt)
            cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("target"))
            cxt:Dialog("DIALOG_INTRO")
            if cxt.quest.param.unplanned then
                cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("saved_from_arrest"))
                StateGraphUtil.AddLeaveLocation(cxt)
                return
            end

            cxt:Opt("OPT_BRUSH_OFF")
                :Dialog("DIALOG_BRUSH_OFF")
                :ReceiveOpinion("suspects_setup")
                :CompleteQuest()
                :Travel()

            cxt:BasicNegotiation("EXCUSE")
                :OnSuccess()
                    :ReceiveOpinion("saved_from_arrest")
                    :CompleteQuest()
                    :Travel()
                :OnFailure()
                    :ReceiveOpinion("suspects_setup")
                    :CompleteQuest()
                    :Travel()
        end)

QDEF:AddConvo("innocent", "admiralty")
    :Loc{
        OPT_ASK = "Ask about {agent}",
        DIALOG_ASK = [[
            player:
                So any updates on {target}?
            agent:
                I...I can't do it.
            player:
                !dubious
                Can't arrest someone for the private citizen?
            agent:
                Oh no, it's not that.
                It's that I've tried <i>Everything</> to arrest {target}!
                I've tried getting a warrant, I've planted evidence on {target.himher}, I've even tried just flat out dogging {target} in case {target.heshe} littered! 
                Grifter, either this target's a saint or Hesh itself. Either way, I can't do anything.
                I've spent too much time on {target.himher}. I'm going to do something that might actually get me promoted.
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_ASK")
            :Dialog("DIALOG_ASK")
            :ReceiveOpinion("wasted_their_time")
            :FailQuest()
    end)

QDEF:AddConvo("wait", "admiralty")
    :Priority(CONVO_PRIORITY_LOWEST)
    :AttractState("STATE_GREETING")
        :Fn(function(cxt)
            cxt:Quip(cxt.enc:GetPlayer(), "investigation_greeting", "player")
            cxt:Quip(cxt:GetAgent(), "investigation_greeting", "agent")
        end)
QDEF:AddConvo("escort")
    :Priority(CONVO_PRIORITY_HIGHEST)
    :Confront(function(cxt)
        if not cxt.location:HasTag("in_transit") then
            if cxt.location == cxt.quest:GetCastMember("station") then
                return "STATE_ARRIVE"
            else
                return "STATE_OTHER_LOCATION"
            end
        end
    end)
    :State("STATE_OTHER_LOCATION")
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
                {not ad_dead?
                    admiralty:
                        !right
                        Wait, this isn't {station#location}.
                        Do you have anything better to do?
                    {not target_dead?
                        If so, I can take it from here.
                    }
                    {target_dead?
                        If so, I'll leave.
                    }
                }
                {ad_dead?
                    target:
                        !right
                        !injured
                        What is this? This isn't {station#location}.
                        What do you want from me?
                }
            ]],
            OPT_LEAVE_AD = "Leave {admiralty}",
            DIALOG_LEAVE_AD = [[
                player:
                    Yeah, I'm really busy.
                {target_dead?
                    You can leave now. Do your Admiralty stuff or whatever.
                    |
                    You can take it from here. Take {target} to the station.
                }
                admiralty:
                    Alright then.
                    !exit
            ]],
            OPT_LET_TARGET_GO = "Let {target} go",
            DIALOG_LET_GO = [[
                player:
                    I'm not the Admiralty, so I really have no place to arrest you.
                agent:
                    Seriously?
                    After all that, and you're just lettimg me go?
                player:
                    Well, yeah.
                agent:
                    You are a weird one, {player}.
                    But just because you let me go, doesn't mean I'll forgive you.
                    You caused me way too much trouble that I otherwise don't have.
                    !exit
                * You wonder if you made the right decision.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            if cxt:GetCastMember("admiralty"):IsDead() then
                cxt:Opt("OPT_LET_TARGET_GO")
                    :Dialog("DIALOG_LET_GO")
                    :CompleteQuest()
                    :DoneConvo()
            else
                cxt:Opt("OPT_LEAVE_AD")
                    :Dialog("DIALOG_LEAVE_AD")
                    :Fn(function(cxt)
                        local target = cxt.quest:GetCastMember("target")
                        if not target:IsDead() then
                            target:GainAspect("stripped_influence", 5)
                            target:OpinionEvent(OPINION.SOLD_OUT_TO_ADMIRALTY)
                            target:Retire()
                        end
                        cxt.quest:GetCastMember("admiralty"):MoveToLocation(cxt.quest:GetCastMember("station"))
                        DoPromoteAdmiralty(cxt)
                        cxt.quest:Complete()
                        StateGraphUtil.AddEndOption(cxt)
                    end)
            end
            StateGraphUtil.AddLeaveLocation(cxt)
        end)
    :State("STATE_ARRIVE")
        :Loc{
            DIALOG_INTRO = [[
                player:
                    !left
                agent:
                    !right
                {ad_dead?
                    {not target_dead?
                        agent:
                            [p]Who's this?
                        player:
                            A criminal. {admiralty} and I captured {target.himher} together.
                        agent:
                            Speaking of which, where's {admiralty}?
                        player:
                            Well, {admiralty.heshe}'s dead.
                        agent:
                            What a shame.
                            We'll handle it from here.
                    }
                }
                {not ad_dead?
                    {target_dead?
                        agent:
                            [p] What's going on?
                        admiralty:
                            !left
                            We killed {target}.
                        agent:
                            Oh nice!
                        {high_bounty?
                            [p] {admiralty}, you're hearby promoted.
                        admiralty:
                            !left
                            Sweet!
                        }
                    }
                    {not target_dead?
                        agent:
                            [p] Who's this?
                        player:
                            A criminal that {admiralty} and I captured.
                        agent:
                            Well done!
                        {high_bounty?
                            [p] We've had our eyes on {target} for a while now. I'm glad you can bring {target.himher} in alive.
                            {admiralty}, you're hearby promoted.
                        admiralty:
                            !left
                            Sweet!
                        }
                        agent:
                            We'll handle it from here.
                    }
                    player:
                        !left
                    admiralty:
                        !right
                        Thanks for your help, {player}!
                }
            ]],
        }
        :Fn(function(cxt)
            local ad = cxt.location:FindAgentIf(function(agent)
                return agent:GetFactionID() == "ADMIRALTY" and agent:GetBrain():IsOnDuty()
            end)
            if not ad then
                ad = cxt.location:FindAgentIf(function(agent)
                    return agent:GetFactionID() == "ADMIRALTY"
                end)
            end
            if not ad then
                -- this really shouldn't happen.
                ad = cxt.quest:CreateSkinnedAgent( "ADMIRALTY_CLERK" )
                ad:MoveToLocation(cxt.quest:GetCastMember("station"))
            end
            cxt:TalkTo(ad)
            cxt:Dialog("DIALOG_INTRO")
            local target = cxt.quest:GetCastMember("target")
            if not target:IsDead() then
                target:GainAspect("stripped_influence", 5)
                target:OpinionEvent(OPINION.SOLD_OUT_TO_ADMIRALTY)
                target:Retire()
            end
            DoPromoteAdmiralty(cxt)
            cxt.quest:Complete()
            StateGraphUtil.AddEndOption(cxt)
        end)
