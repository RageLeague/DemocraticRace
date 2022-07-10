local FOLLOWUP = "FOLLOWUP_ADMIRALTY_ARREST"

Convo("DEM_ADMIRALTY_ARREST")
    :Loc{
        OPT_INVESTIGATE = "Convince {agent} to investigate someone...",
        TT_INVESTIGATE = "After investigating someone, the target may get arrested, essentially eliminating them.",
        DIALOG_INVESTIGATE = [[
            player:
                Can you investigate someone for me?
            agent:
                Who do you plan to investigate?
        ]],

        REQ_NO_TARGETS = "There are no targets.",
        REQ_CANT_DO = "{agent} isn't at the Admiralty Headquarters and isn't your friend.",

        OPT_CHOOSE = "Investigate {1#agent}",

        DIALOG_BACK = [[
            player:
                Never mind.
        ]],
    }
    :Hub(function(cxt, who)
        if not DemocracyUtil.IsDemocracyCampaign(cxt.act_id) then
            return
        end

        if who and who:GetFactionID() == "ADMIRALTY" and not AgentUtil.HasPlotArmour(who) then
            for i, quest in ipairs(who:GetActiveQuests()) do
                print(quest:GetContentID())
                if quest:GetContentID() == FOLLOWUP and quest:GetCastAgent( "admiralty" ) == who then
                    return
                end
            end

            local all_targets = DemocracyUtil.GetAllPunishmentTargets()
            local is_at_hq = who:GetLocation() and who:GetLocation():GetContentID() == "ADMIRALTY_BARRACKS"
            cxt:Opt("OPT_INVESTIGATE")
                :PreIcon(global_images.order)
                :PostText("TT_INVESTIGATE")
                :ReqCondition(#all_targets > 0, "REQ_NO_TARGETS")
                :ReqCondition(is_at_hq or who:GetRelationship() > RELATIONSHIP.NEUTRAL, "REQ_CANT_DO")
                :Dialog("DIALOG_INVESTIGATE")
                :LoopingFn(function(cxt)
                    for i, agent in ipairs(all_targets) do
                        if agent ~= who then
                            cxt:Opt("OPT_CHOOSE", agent)
                                :SetPortrait(agent)
                                :Fn(function(cxt)
                                    cxt:ReassignCastMember("target", agent)
                                    cxt:GoTo("STATE_SELECT_METHOD")
                                end)
                        end
                    end
                    StateGraphUtil.AddBackButton(cxt)
                        :Dialog("DIALOG_BACK")
                end)
        end
    end)
    :State("STATE_SELECT_METHOD")
        :Loc{
            DIALOG_SELECT = [[
                player:
                    Can you investigate {target} for me?
                agent:
                {hard_investigation or hard_arrest?
                    I don't know, it might be challenging.
                    |
                    Sure. piece of cake.
                    Probably.
                }
                {is_ad?
                    {target} is in the Admiralty, so it might be hard for me to dig up {target.hisher} dirt.
                }
                {is_rival_faction?
                    Our relationship is getting kinda tense with the {rival_id#faction}. We probably don't want to start a war with them.
                    It might hinder our investigation.
                }
                {is_unlawful?
                    {target} is part of a criminal faction. {target.HeShe} is probably guilty.
                    Although it might be hard to arrest {target.himher} because of this tie.
                }
                {not (is_ad or is_rival_faction or is_unlawful)?
                    Everyone's guilty of something.
                player:
                    What about you?
                agent:
                    !angry
                    ...
                    Very funny.
                }
                agent:
                    !neutral
                {high_renown?
                    {is_ad or is_rival_faction or is_unlawful?Also|However}, {target} has powerful influence. {target.HisHer} power will probably block me from my investigation.
                    It would be difficult for me to bring {target.himher} down.
                }
                {high_strength?
                    Additionally, {target} is strong. I don't know if I can bring {target.himher} down on my own.
                player:
                    Then send a squad after {target}. I thought you Admiralty are good at this thing.
                agent:
                    I don't know, the resources are kind of low, now the Admiralty has to protect the election.
                }
            ]],

            OPT_CALL_IN_FAVOR = "Use a favor",
            DIALOG_CALL_IN_FAVOR = [[
                player:
                    Can you do it?
                agent:
                    !placate
                    Look, I'm very busy-
                player:
                    !thumb
                    Look, we're friends, right?
                agent:
                    !dubious
                    And, so?
                player:
                    Can you do it for the sake of our friendship?
                agent:
                    ...
                    !dubious
                    Is that your rea-
                player:
                    !happy
                    Please?
                agent:
                    ...
                    !sigh
                    Okay, you win.
                    !point
                    But you owe me a favor.
                player:
                    Sure.
            ]],
            OPT_USE_AUTHORIZATION = "[{1#graft}] Use an authorization",
            DIALOG_USE_AUTHORIZATION = [[
                player:
                    Can you do it?
                agent:
                    I don't know. Can I?
                player:
                    !point
                    You can. And you should. Considering it an order from {1#agent}.
                agent:
                {liked?
                    Okay, I'll do it.
                }
                {not liked?
                    Guess {1#agent} just hands them out like lollipops, huh?
                    !facepalm
                    Fine, I'll do it.
                }
            ]],
            DIALOG_USE_AUTHORIZATION_SELF = [[
                player:
                    Can you do it?
                agent:
                    I don't know. Can I?
                player:
                    !permit
                    Remember this {1#graft} you gave me?
                agent:
                    So?
                player:
                    !neutral_notepad
                    It says: {2}
                    You are a nearby member of the Admiralty, correct?
                agent:
                    Oh.
                    !surprised
                    Oh!
                player:
                    You see? You gotta help me.
                agent:
                    !thought
                    Wait, the investigation isn't a battle or a negotiation.
                player:
                    Simple.
                    This mod allows more uses of {1#graft} other than asking people to help me.
                    This is a way to buff {1#graft} and make it more useful.
                agent:
                    !shrug
                    I have no idea what you're talking about, but since we're friends, I'll do it.
                player:
                    !happy
                    Thanks.
            ]],
            OPT_NEVER_MIND = "Never Mind",
            DIALOG_NEVER_MIND = [[
                player:
                    Never mind.
                agent:
                    Okay...?
            ]],
        }
        :Fn(function(cxt)
            local target = cxt:GetCastMember("target")
            local arrest_params = {
                guilt_score = 4,
                investigate_difficulty = 5,
                arrest_difficulty = 5,
                additional_dialogs = {},
            }
            if target:GetFactionID() == "ADMIRALTY" then
                cxt.enc.scratch.is_ad = true
                arrest_params.investigate_difficulty = arrest_params.investigate_difficulty + 3
            end
            if target:GetFactionID() == "SPARK_BARON" or target:GetFactionID() == "CULT_OF_HESH" then
                cxt.enc.scratch.is_rival_faction = true
                cxt.enc.scratch.rival_id = target:GetFactionID()
                arrest_params.investigate_difficulty = arrest_params.investigate_difficulty + 2
            end
            arrest_params.investigate_difficulty = arrest_params.investigate_difficulty + RELATIONSHIP.NEUTRAL - cxt:GetAgent():GetRelationship()
            -- if cxt:GetAgent():GetRelationship() >= RELATIONSHIP.LIKED then

            -- end
            if target:GetFaction():IsUnlawful() then
                cxt.enc.scratch.is_unlawful = true
                arrest_params.guilt_score = arrest_params.guilt_score + 3
                arrest_params.investigate_difficulty = arrest_params.investigate_difficulty - 2
                arrest_params.arrest_difficulty = arrest_params.arrest_difficulty + 2
            end
            local renown_delta = target:GetRenown() - cxt:GetAgent():GetRenown()
            arrest_params.investigate_difficulty = arrest_params.investigate_difficulty + renown_delta
            arrest_params.arrest_difficulty = arrest_params.arrest_difficulty + renown_delta
            if renown_delta >= 0 then
                cxt.enc.scratch.high_renown = true
            end

            local strength_delta = target:GetCombatStrength() - cxt:GetAgent():GetCombatStrength()
            arrest_params.arrest_difficulty = arrest_params.arrest_difficulty + strength_delta * 2
            if target:IsBoss() then
                arrest_params.arrest_difficulty = arrest_params.arrest_difficulty + 5
            end
            if strength_delta >= 0 or target:IsBoss() then
                cxt.enc.scratch.high_strength = true
            end

            TheGame:BroadcastEvent( "determine_guilt", target, arrest_params, "admiralty_arrest" )

            if arrest_params.investigate_difficulty > 5 then
                cxt.enc.scratch.hard_investigation = true
            end
            if arrest_params.arrest_difficulty > 5 then
                cxt.enc.scratch.hard_arrest = true
            end

            cxt:Dialog("DIALOG_SELECT")

            for i, dialog in ipairs(arrest_params.additional_dialogs) do
                cxt:RawDialog(dialog)
            end

            local function AddFollowup()
                local overrides = {
                    cast = {
                        admiralty = cxt:GetAgent(),
                        target = target,
                    },
                    parameters = arrest_params,
                }
                QuestUtil.SpawnQuest(FOLLOWUP, overrides)
                StateGraphUtil.AddEndOption(cxt)
            end

            cxt:Opt("OPT_CALL_IN_FAVOR")
                :ReqRelationship( RELATIONSHIP.LOVED )
                :Dialog("DIALOG_CALL_IN_FAVOR")
                :ReceiveOpinion(OPINION.CALL_IN_FAVOUR)
                :Fn(AddFollowup)
            local graft = cxt.player.graft_owner:FindGraft(function(graft)
                if graft.id == "authorization" then
                    return not graft:GetDef().OnCooldown( graft )
                end
                return false
            end)
            if graft then
                local graft_provider = graft.userdata.agents[1]
                cxt:Opt("OPT_USE_AUTHORIZATION", graft)
                    :Fn(function(cxt)
                        if cxt:GetAgent() == graft_provider then
                            cxt:Dialog("DIALOG_USE_AUTHORIZATION_SELF", graft, graft:GetDesc())
                        else
                            cxt:Dialog("DIALOG_USE_AUTHORIZATION", graft_provider)
                        end
                        graft:GetDef().StartCooldown( graft )
                        AddFollowup()
                    end)
            end
            cxt:Opt("OPT_NEVER_MIND")
                :Dialog("DIALOG_NEVER_MIND")
                :Pop()
        end)
