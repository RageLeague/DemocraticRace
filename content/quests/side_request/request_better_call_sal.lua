-- Outline:
-- The defendant is accused of stealing something valuable from the plaintiff.
-- Potential evidence:
--   * Witness saw accused leaving the estate.
--     * If innocent, either witness misremembered or witness fabricated testimony
--   * Accused left a ring behind.
--     * If innocent, someone stole the earings from the accused.
-- You can forge or find alibi, replace evidence, or "deal" with witness/plaintiff/prosecutor before the trial.

local QDEF = QuestDef.Define
{
    title = "Better Call {1}",
    title_fn = function(quest, str)
        local name
        if TheGame:GetGameState() and TheGame:GetGameState():GetPlayerAgent() then
            name = TheGame:GetGameState():GetPlayerAgent():GetName()
        else
            name = LOC(Content.GetCharacterDef("SAL"):GetLocNameKey())
        end
        return loc.format(str, name)
    end,
    desc = "Represent {giver} in a court of law.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/better_call_sal.png"),

    qtype = QTYPE.SIDE,

    act_filter = DemocracyUtil.DemocracyActFilter,
    focus = QUEST_FOCUS.NEGOTIATION,
    tags = {"REQUEST_JOB"},
    reward_mod = 0,
    can_flush = false,
    cooldown = EVENT_COOLDOWN.LONG,

    events = {
        base_difficulty_change = function(quest, new_diff, old_diff)
            quest:SetRank(new_diff)
        end,
        quests_changed = function(quest, event_quest)

        end,
        phase_change = function(quest)
            if Now() > (quest.param.trial_time or 0) then
                quest:Fail()
            elseif Now() == (quest.param.trial_time or 0) then
                quest:Complete("prepare_trial")
            end
        end,
    },
    precondition = function(quest)
        local current_time = Now()
        local max_time = 2 * 4
        local wait_period = 2
        if current_time + wait_period > max_time then
            return false
        end
        quest.param.trial_time = math.random(current_time + wait_period, max_time)
        return true
    end,

    postcondition = function(quest)
        -- Whether the accused is actually guilty of the crime
        quest.param.actually_guilty = math.random() < 0.3

        -- Must have at least witness or evidence. Otherwise no case.
        while (not quest.param.have_witness) and (not quest.param.have_evidence) do
            quest.param.have_witness = math.random() < 0.65
            quest.param.have_evidence = math.random() < 0.65
        end

        if quest.param.have_witness then
            quest:AssignCastMember("witness")
        end

        if not quest.param.have_evidence then
            quest.param.defendant_has_ring = true
        elseif not quest.param.actually_guilty then
            quest.param.defendant_has_ring = true
            quest.param.pros_forged_evidence = true
        end

        if not quest.param.actually_guilty then
            quest.param.have_alibi = math.random() < 0.3
        end

        -- Generate a random name for the spouse of the defendant to put on the ring
        local name, nameid = Content.GenerateCharacterName( "NAMES" )
        quest.param.spouse_name_id = nameid
        quest.param.spouse_name, quest.param.spouse_name_declensions = Content.GetCharacterName( "NAMES", quest.param.spouse_name_id )

        return true
    end,

    on_post_load = function(quest)
        quest.param.spouse_name, quest.param.spouse_name_declensions = Content.GetCharacterName( "NAMES", quest.param.spouse_name_id )
    end,

    on_start = function(quest)
        quest:Activate("prepare_trial")
        quest:Activate("talk_to_defendant")
    end,

    on_complete = function(quest)
        local giver = quest:GetCastMember("giver")
        if not (quest.param.sub_optimal or quest.param.poor_performance) then
            giver:OpinionEvent(OPINION.DID_LOYALTY_QUEST)
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 4, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 10, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 5, giver:GetFactionID(), "COMPLETED_QUEST_REQUEST")
        elseif quest.param.sub_optimal then
            DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", 3, "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 8, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 4, giver:GetFactionID(), "COMPLETED_QUEST_REQUEST")
        elseif quest.param.poor_performance then
            DemocracyUtil.TryMainQuestFn("DeltaWealthSupport", 5, DemocracyUtil.GetWealth(giver), "COMPLETED_QUEST_REQUEST")
            DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", 3, giver:GetFactionID(), "COMPLETED_QUEST_REQUEST")
        end
    end,

    collect_agent_locations = function(quest, t)
        if quest:IsActive("prepare_trial") then
            table.insert(t, { agent = quest:GetCastMember("prosecutor"), location = quest:GetCastMember("hq")})
        elseif quest:IsActive("attend_trial") then
            local agents = {"giver", "prosecutor", "plaintiff", "witness", "judge"}
            for i, id in ipairs(agents) do
                if quest:GetCastMember(id) and not quest:GetCastMember(id):IsRetired() then
                    table.insert(t, { agent = quest:GetCastMember(id), location = quest:GetCastMember("courtroom")})
                end
            end
        end
    end,

    AddEvidenceList = function(quest, evidence)
        quest.param.evidence_list = quest.param.evidence_list or {}
        table.insert_unique(quest.param.evidence_list, evidence)
    end,
    HasEvidence = function(quest, evidence)
        quest.param.evidence_list = quest.param.evidence_list or {}
        return table.arraycontains(quest.param.evidence_list, evidence)
    end,
    CanSellFalseEvidence = function(quest, agent)
        return (agent:GetContentID() == "JAKES_SMUGGLER" or agent:GetContentID() == "POOR_MERCHANT") and not agent:IsCastInQuest(quest)
    end,
}
:AddCast{
    cast_id = "giver",
    no_validation = true,
    provider = true,
    unimportant = true,
    condition = function(agent, quest)
        if agent:HasTag("curated_request_quest") then
            return false
        end
        if DemocracyUtil.GetWealth(agent) > 2 then
            return false
        end
        if agent:GetFactionID() == "ADMIRALTY" then
            return false
        end
        if agent:GetFaction():IsLawful() or agent:GetFactionID() == "RISE" then
            return true
        end
        return false
    end,
}
:AddCast{
    cast_id = "plaintiff",
    condition = function(agent, quest)
        return agent:GetFaction():IsLawful() and DemocracyUtil.GetWealth(agent) >= 3
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( "WEALTHY_MERCHANT" ) )
    end,
}
:AddDefCast("prosecutor", "ADMIRALTY_INVESTIGATOR")
:AddDefCast("judge", "ADMIRALTY_CLERK")
:AddCast{
    cast_id = "witness",
    when = QWHEN.MANUAL,
    condition = function(agent, quest)
        return agent:GetFaction():IsLawful()
    end,
}
:AddCastFallback{
    cast_fn = function(quest, t)
        table.insert( t, quest:CreateSkinnedAgent( "WEALTHY_MERCHANT" ) )
    end,
}
:AddLocationCast{
    cast_id = "hq",
    no_validation = true,
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("ADMIRALTY_BARRACKS"))
    end,
}
:AddLocationDefs{
    COURTROOM = {
        name = "The Courtroom",
        plax = "INT_SMITH_HESHTEMPLE",
        map_tags = {"barracks"},
        indoors = true,
        show_agents = true,
    },
}
:AddLocationCast{
    cast_id = "courtroom",
    cast_fn = function(quest, t)
        table.insert(t,  quest:SpawnTempLocation("COURTROOM"))
    end,
}
:AddObjective{
    id = "prepare_trial",
    title = "Prepare for the trial ({1#relative_time})",
    title_fn = function(quest, str)
        return loc.format(str, (quest.param.trial_time or 0) - Now())
    end,
    desc = "Make enough preparations before the trial begins.",
    on_complete = function(quest)
        quest:Activate("attend_trial")
        local side_quests = {"talk_to_defendant", "talk_to_plaintiff", "talk_to_prosecutor", "talk_to_witness", "acquire_false_evidence"}
        for i, quest_id in ipairs(side_quests) do
            if quest:IsActive(quest_id) then
                quest:Complete(quest_id)
            end
        end
    end,
}
:AddObjective{
    id = "talk_to_defendant",
    title = "Talk to {giver}, the defendant",
    desc = "Talk to {giver}, the defendant, to learn more about the case.",
    mark = function(quest, t, in_location)
        if in_location or DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("giver"))
        end
    end,
}
:AddObjective{
    id = "talk_to_plaintiff",
    title = "Talk to {plaintiff}, the plaintiff",
    desc = "Talk to {plaintiff}, the plaintiff, to learn more about the case.",
    mark = function(quest, t, in_location)
        if in_location or DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("plaintiff"))
        end
    end,
}
:AddObjective{
    id = "talk_to_prosecutor",
    title = "Talk to {prosecutor}, the prosecutor",
    desc = "Talk to {prosecutor}, the prosecutor, to learn more about the case.",
    mark = function(quest, t, in_location)
        if in_location or DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("prosecutor"))
        end
    end,
}
:AddObjective{
    id = "talk_to_witness",
    title = "Talk to {witness}, the witness",
    desc = "Talk to {witness}, the witness, to learn more about the case.",
    mark = function(quest, t, in_location)
        if in_location or DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("witness"))
        end
    end,
}
:AddObjective{
    id = "acquire_false_evidence",
    title = "(Optional) Acquire false evidence",
    desc = "The prosecutor has {giver}'s ring. It might be best to replace it with another one that doesn't implicate {giver.himher}.",
    mark = function(quest, t, in_location)
        if in_location then
            local location = TheGame:GetGameState():GetPlayerAgent():GetLocation()
            for i, agent in location:Agents() do
                if quest:DefFn("CanSellFalseEvidence", agent) then
                    table.insert(t, agent)
                end
            end
        end
    end,
}
:AddObjective{
    id = "attend_trial",
    title = "Attend the trial",
    desc = "The trial is about to start! Don't be late.",
    mark = function(quest, t, in_location)
        if DemocracyUtil.IsFreeTimeActive() then
            table.insert(t, quest:GetCastMember("courtroom"))
        end
    end,
}

QDEF:AddIntro(
    --attract spiel
    [[
        agent:
            [p] I've been accused of a crime, and I need someone represent me in court.
            I know you are a politician and not a lawyer, but I don't know who else to rely on.
            Besides, I neither have the money nor the time to hire a lawyer. Can you represent me in court?
    ]],

    --on accept
    [[
        player:
            [p] That can be done.
        agent:
            Excellent!
    ]])

QDEF:AddConvo("talk_to_defendant", "giver")
    :Loc{
        OPT_ASK = "Ask about the case",
        DIALOG_ASK = [[
            player:
                I would like to learn about the case.
            agent:
                What would you like to know?
        ]],
        OPT_FORGE_ALIBI = "Ask {agent} to falsify an alibi",
        DIALOG_FORGE_ALIBI = [[
            player:
                [p] Why don't you falsify an alibi?
            agent:
                What? But that's perjury!
        ]],
        DIALOG_FORGE_ALIBI_SUCCESS = [[
            player:
                [p] As long as you don't get caught.
                Besides, just keep your story straight, and have someone back it up.
                It's better than getting convicted.
            agent:
                If you say so.
        ]],
        DIALOG_FORGE_ALIBI_FAILURE = [[
            agent:
                [p] I thought you are a lawyer?
                That was terrible advice. I'm not doing it.
        ]],
        OPT_GIVE_RING_BACK = "Return {agent}'s ring",
        DIALOG_GIVE_RING_BACK = [[
            player:
                [p] Here's your ring.
            agent:
                Thanks.
        ]],
        DIALOG_GIVE_RING_BACK_FALSE = [[
            player:
                [p] Here's your ring.
            agent:
                My... ring?
            {defendant_has_ring?
                But I'm already wearing mine?
                It's a wedding ring belonging to me and my partner, {spouse_name}.
                Look! It has the engraving of our names on it!
            player:
                {not asked_ring?
                    But the prosecutor said it's yours!
                    Hesh dang it. All these effort to get this ring, and turns out this itself is forged.
                }
                {asked_ring?
                    Right. I forgot.
                }
            }
            {not defendant_has_ring?
                But this isn't my ring?
                It doesn't have the names of me and my partner, {spouse_name}.
            player:
                {not asked_ring?
                    But the prosecutor said it's yours!
                    Hesh dang it. All these effort to get this ring, and turns out this itself is forged.
                }
                {asked_ring?
                    Right. I forgot.
                }
            }
        ]],
        OPT_GIVE_FAKE_RING = "Convince {agent} to take the fake ring",
        DIALOG_GIVE_FAKE_RING = [[
            player:
                [p] Take this ring.
                If anyone asks, that is your ring, and nothing else.
            agent:
                What? Why?
        ]],
        DIALOG_GIVE_FAKE_RING_SUCCESS = [[
            player:
                [p] If you say your actual ring is yours, you will implicate yourself since they have it to prove your guilt.
                So just pretend this ring is yours. At least until the trial is over.
            agent:
                If you say so...
        ]],
        DIALOG_GIVE_FAKE_RING_FAILURE = [[
            agent:
                [p] No. Absolutely not.
                This is absurd.
        ]],
        SELECT_TITLE = "Select a card",
        SELECT_DESC = "Choose the item to give to this person, removing it from your deck.",
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_ASK")
            :SetQuestMark()
            :Dialog("DIALOG_ASK")
            :GoTo("STATE_QUESTIONS")

        if cxt.quest.param.asked_defendant_alibi and not cxt.quest.param.have_alibi and not cxt.quest.param.try_forge_alibi then
            cxt:BasicNegotiation("FORGE_ALIBI")
                :OnSuccess()
                    :Fn(function(cxt)
                        cxt.quest.param.try_forge_alibi = true
                        cxt.quest:DefFn("AddEvidenceList", "forged_alibi")
                    end)
                :OnFailure()
                    :Fn(function(cxt)
                        cxt.quest.param.try_forge_alibi = true
                    end)
        end

        local cards = {}
        for i, card in ipairs(cxt.player.negotiator.cards.cards) do
            print(card.id)
            if card.id == "dem_incriminating_evidence" then
                table.insert(cards, card)
            end
        end

        if #cards > 0 and cxt.quest.param.def_forged_evidence and not cxt.quest.param.tried_return_ring then
            cxt:Opt("OPT_GIVE_RING_BACK")
                :SetQuestMark()
                :Fn(function(cxt)
                    cxt:Wait()
                    DemocracyUtil.InsertSelectCardScreen(
                        cards,
                        cxt:GetLocString("SELECT_TITLE"),
                        cxt:GetLocString("SELECT_DESC"),
                        Widget.NegotiationCard,
                        function(card)
                            cxt.enc:ResumeEncounter( card )
                        end
                    )
                    local card = cxt.enc:YieldEncounter()
                    if card then
                        if not cxt.quest.param.pros_forged_evidence then
                            cxt.player.negotiator:RemoveCard( card )
                            cxt:Dialog("DIALOG_GIVE_RING_BACK")
                            cxt.quest.param.defendant_has_ring = true
                        else
                            cxt:Dialog("DIALOG_GIVE_RING_BACK_FALSE")
                            cxt.quest.param.asked_ring = true
                            cxt.quest.param.tried_return_ring = true
                        end
                    end
                end)
        end

        if cxt.quest.param.got_false_evidence and not cxt.quest.param.defendant_has_ring and not cxt.quest.param.defendant_has_false_ring and not cxt.quest.param.tried_give_false_ring then
            cxt:BasicNegotiation("GIVE_FAKE_RING", {})
                :OnSuccess()
                    :Fn(function(cxt)
                        cxt.quest.param.got_false_evidence = false
                        cxt.quest.param.defendant_has_false_ring = true
                    end)
                :OnFailure()
                    :Fn(function(cxt)
                        cxt.quest.param.tried_give_false_ring = true
                    end)
        end
    end)
    :State("STATE_QUESTIONS")
        :Loc{
            OPT_SUMMARY = "Ask for a summary of the case",
            DIALOG_SUMMARY = [[
                player:
                    [p] What are you accused of?
                agent:
                    Apparently stealing {plaintiff}'s expensive jewelry.
                    Honestly, I didn't do it!
                    I mean, that's what they all say, but I genuinely didn't do it.
            ]],
            OPT_ALIBI = "Ask about Saturday afternoon",
            DIALOG_ALIBI = [[
                player:
                    [p] Turns out, the accusation against you is that you stole the jewelry at Saturday afternoon.
                agent:
                    But I didn't!
                player:
                    Do you happen to have an alibi during that time? That would certainly help.
                {have_alibi?
                    agent:
                        Actually, I do.
                        I was working the entire afternoon.
                        You can easily verify it by talking to everyone at the worksite.
                    player:
                        That is perfect, thanks.
                    *** {agent} has an airtight alibi when the crime occurred.
                }
                {not have_alibi?
                    agent:
                        No, I don't.
                    player:
                        Ahh... We will figure something out.
                }
            ]],
            OPT_ASK_RING = "Ask about {agent}'s ring",
            DIALOG_ASK_RING = [[
                player:
                    [p] Do you have a ring, by any chance?
                agent:
                    I do.
                {defendant_has_ring?
                    agent:
                        It's right here with me.
                        This is an engagement ring with my partner, {spouse_name}.
                        Why do you ask?
                    player:
                        That's strange. {plaintiff} said that the prosecutor has your ring as evidence.
                    agent:
                        Well that's just false.
                        I only have one ring.
                    player:
                        It seems like we are dealing with a prosecutor who is willing to forge evidence to win a case.
                        Don't worry. We will prove your innocence in court.
                }
                {not defendant_has_ring?
                    agent:
                        It's... Oh Hesh, where is it?
                        It's an expensive engagement ring with my partner, {spouse_name}.
                    player:
                    {not seen_ring?
                        From what {plaintiff} told me, {plaintiff.heshe} said that the prosecutor has your ring as evidence.
                        According to them, you left it while trying to steal {plaintiff}'s jewelry.
                        {actually_guilty?
                            agent:
                                Ah, Hesh.
                                Get it back.
                            player:
                                What?
                            agent:
                                Get the ring back. The ring is mine.
                            player:
                                I'll... see what I can do.
                        }
                        {not actually_guilty?
                            agent:
                                What? That's impossible.
                                I am certain that I have my ring on Monday morning.
                            {asked_defendant_alibi?
                                agent:
                                    <i>After</> the time of the theft.
                            }
                            player:
                                Well... Maybe they're bluffing.
                                I haven't seen the ring myself, so they could be lying.
                            {asked_defendant_alibi?
                                player:
                                    But if they have your ring... That means they stole it. To frame you.
                                agent:
                                    Those bastards...
                            }
                        }
                    }
                    {seen_ring?
                        {pros_forged_evidence or def_forged_evidence?
                            According to {plaintiff}, the prosecutor has it as evidence against you.
                            But from what I've seen, the ring doesn't match the description you provided.
                            Do you have any other ring, by any chance?
                        agent:
                            No, rings are expensive, you know?
                            Besides, no other rings matter compared to the one from my love.
                        {not actually_guilty?
                            I distinctly remember still having the ring on Monday.
                        }
                        player:
                            It seems like we are dealing with a prosecutor who is willing to forge evidence to win a case.
                            Don't worry. We will prove your innocence in court.
                            And hopefully find your ring in the process.
                        }
                        {not (pros_forged_evidence or def_forged_evidence)?
                            It's with the prosecutor as evidence.
                            I've seen it with my own eyes. It matches the exact description you have provided.
                            {actually_guilty?
                                agent:
                                    Ah, Hesh.
                                    Get it back.
                                player:
                                    What?
                                agent:
                                    Get the ring back. The ring is mine.
                                player:
                                    I'll... see what I can do.
                            }
                            {not actually_guilty?
                                agent:
                                    What? That's impossible.
                                    I am certain that I have my ring on Monday morning.
                                {asked_defendant_alibi?
                                    agent:
                                        <i>After</> the time of the theft.
                                }
                                {knows_timeframe?
                                    player:
                                        But if they have your ring... That means they stole it. To frame you.
                                    agent:
                                        Those bastards...
                                }
                                {not knows_timeframe?
                                    player:
                                        Things are not looking good...
                                }
                            }
                        }
                    }
                }
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            cxt:Question("OPT_SUMMARY", "DIALOG_SUMMARY", function()
                if cxt.quest:IsInactive("talk_to_plaintiff") then
                    cxt.quest:Activate("talk_to_plaintiff")
                end
            end)
            if cxt.quest.param.knows_timeframe then
                cxt:Question("OPT_ALIBI", "DIALOG_ALIBI", function()
                    if cxt.quest.param.have_alibi then
                        cxt.quest:DefFn("AddEvidenceList", "airtight_alibi")
                    end
                    cxt.quest.param.asked_defendant_alibi = true
                end)
            end
            if cxt.quest.param.learned_about_evidence then
                cxt:Question("OPT_ASK_RING", "DIALOG_ASK_RING", function()
                    cxt.quest:DefFn("AddEvidenceList", "ring_desc")
                    cxt.quest.param.asked_ring = true
                    if not cxt.quest.param.actually_guilty and not cxt.quest.param.defendant_has_ring then
                        cxt.quest:DefFn("AddEvidenceList", "ring_loss_timeline")
                    end
                end)
            end
            StateGraphUtil.AddBackButton(cxt)
        end)

QDEF:AddConvo("talk_to_plaintiff", "plaintiff")
    :Loc{
        OPT_ASK = "Ask for information about the case",
        DIALOG_ASK = [[
            {first_time?
                player:
                    You are the one accusing {giver} of theft?
                {not liked?
                    agent:
                        So I am. What's it to you?
                    player:
                        It just so happens that I am representing {giver.himher} in court.
                    agent:
                        Oh, great. You are helping that leech.
                    player:
                        You haven't proved that in court yet.
                        Which is exactly why I am here. To learn about the case.
                }
                {liked?
                    agent:
                        So I am. What about it?
                    player:
                        It just so happens that I am representing {giver.himher} in court.
                    agent:
                        Why? Why are you representing that leech, {player}?
                    player:
                        Well, everyone deserves representation.
                        Besides, you haven't proved that in court yet.
                        Which is exactly why I am here. To learn about the case.
                }
            }
            {not first_time?
                player:
                    Let's talk about the case once more.
            }
        ]],
        DIALOG_ASK_SUCCESS = [[
            agent:
                Fine. You can ask {info_count} {info_count*question|questions}.
                What do you wish to know?
        ]],
        DIALOG_ASK_FAILURE = [[
            agent:
                No. I'm not obligated to tell you anything.
                This conversation is over.
        ]],
    }
    :Hub(function(cxt)
        cxt.quest.param.plaintiff_questions_asked = cxt.quest.param.plaintiff_questions_asked or {}
        if #cxt.quest.param.plaintiff_questions_asked < 3 then
            cxt:Opt("OPT_ASK")
                :SetQuestMark()
                :Dialog("DIALOG_ASK")
                :Negotiation{
                    on_start_negotiation = function(minigame)
                        local count = 3 - #cxt.quest.param.plaintiff_questions_asked - 1
                        for i = 1, count do
                            minigame:GetOpponentNegotiator():CreateModifier( "secret_intel", 1 )
                        end
                    end,
                    on_success = function(cxt, minigame)
                        local count = minigame:GetPlayerNegotiator():GetModifierStacks( "secret_intel" )
                        cxt.enc.scratch.info_count = count + 1
                        cxt:Dialog("DIALOG_ASK_SUCCESS")
                        cxt:GoTo("STATE_QUESTIONS")
                    end,
                    on_fail = function(cxt, minigame)
                        cxt:Dialog("DIALOG_ASK_FAILURE")
                        -- cxt.quest:Fail("talk_to_plaintiff")
                    end,
                }
        end
    end)
    :State("STATE_QUESTIONS")
        :Loc{
            OPT_SUMMARY = "Ask for a summary of the case",
            DIALOG_SUMMARY = [[
                player:
                    [p] Tell me what happened.
                agent:
                    I planned to go to a party Saturday night.
                    Turns out I can't find my expensive jewelry!
                    I'm sure that I had it the previous day, and I stayed at home during the morning, so {giver} must have stolen it during the afternoon.
                *** According to {agent}, the theft happened at Saturday afternoon.
            ]],
            OPT_EVIDENCE = "Ask for evidence",
            DIALOG_EVIDENCE = [[
                player:
                {not (asked_plaintiff_witness and not have_witness)?
                    [p] Do you have evidence proving {giver} has stolen your jewelry?
                }
                {asked_plaintiff_witness and not have_witness?
                    [p] You mentioned that you have decisive evidence against {giver}?
                }
                {have_evidence?
                    agent:
                        As a matter of fact, I do.
                        {giver}'s ring, left behind by {giver}.
                        If you want to take a look, {prosecutor} has the evidence.
                }
                {not have_evidence?
                    agent:
                        {prosecutor} is trying to find decisive evidence against {giver}.
                        You can talk to {prosecutor.himher} about it.
                    player:
                        The keyword here is "trying".
                        Sounds like your accusation against my client has no basis.
                    agent:
                        That's not true.
                        We have witness testimony that proves {giver}'s guilt.
                }
            ]],
            OPT_WITNESS = "Ask for witness",
            DIALOG_WITNESS = [[
                player:
                {not (asked_plaintiff_evidence and not have_evidence)?
                    [p] Do you have witnesses that saw {giver} stealing your jewelry?
                }
                {asked_plaintiff_evidence and not have_evidence?
                    [p] You mentioned that you have witness testimony against {giver}?
                }
                {have_witness?
                    agent:
                        As a matter of fact, I do.
                        {witness} saw {giver} stealing the jewelry.
                        Go ask {witness} about it, if you are curious.
                }
                {not have_witness?
                    agent:
                        Unfortunately, I do not.
                    player:
                        Sounds like your accusation against my client has no basis.
                    agent:
                        That's not true.
                        We have decisive evidence that proves {giver}'s guilt.
                }
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt.enc.scratch.info_count <= 0 then
                cxt:Pop()
                return
            end
            if not table.arraycontains(cxt.quest.param.plaintiff_questions_asked, "summary") then
                cxt:Question("OPT_SUMMARY", "DIALOG_SUMMARY", function()
                    table.insert_unique(cxt.quest.param.plaintiff_questions_asked, "summary")
                    cxt.enc.scratch.info_count = cxt.enc.scratch.info_count - 1
                    cxt.quest.param.knows_timeframe = true
                end)
            end
            if not table.arraycontains(cxt.quest.param.plaintiff_questions_asked, "evidence") then
                cxt:Question("OPT_EVIDENCE", "DIALOG_EVIDENCE", function()
                    table.insert_unique(cxt.quest.param.plaintiff_questions_asked, "evidence")
                    cxt.enc.scratch.info_count = cxt.enc.scratch.info_count - 1
                    cxt.quest:Activate("talk_to_prosecutor")
                    if cxt.quest.param.have_evidence then
                        cxt.quest.param.learned_about_evidence = true
                        cxt.quest:Activate("acquire_false_evidence")
                    end
                end)
            end
            if not table.arraycontains(cxt.quest.param.plaintiff_questions_asked, "witness") then
                cxt:Question("OPT_WITNESS", "DIALOG_WITNESS", function()
                    table.insert_unique(cxt.quest.param.plaintiff_questions_asked, "witness")
                    cxt.enc.scratch.info_count = cxt.enc.scratch.info_count - 1
                    if cxt.quest.param.have_witness then
                        cxt.quest:Activate("talk_to_witness")
                    end
                end)
            end
            StateGraphUtil.AddBackButton(cxt)
        end)

QDEF:AddConvo("talk_to_witness", "witness")
    :Loc{
        OPT_CAST_DOUBT = "Cast doubt on {agent}'s testimony",
        SIT_MOD_ALIBI = "Your client has an alibi",
        DIALOG_CAST_DOUBT = [[
            player:
                [p] Are you certain your memory isn't faulty?
            {alibi?
                {giver} has an alibi, you know.
            }
        ]],
        DIALOG_CAST_DOUBT_SUCCESS = [[
            {alibi?
                player:
                    [p] Even after hearing my client's alibi, can you still say it's {giver.himher}?
            }
            agent:
                [p] I suppose I can't say for certain that it's {giver}.
        ]],
        DIALOG_CAST_DOUBT_FAILURE = [[
            agent:
                [p] I know what I saw.
            {alibi?
                You are probably lying about the alibi.
            }
        ]],

        OPT_INTIMIDATE = "Intimidate {agent} to prevent {agent.himher} from testifying",
        DIALOG_INTIMIDATE = [[
            player:
                [p] Here's what's going to happen.
                You are not going to testify. If you know what's good for you.
        ]],
        DIALOG_INTIMIDATE_SUCCESS = [[
            agent:
                [p] Fine, fine! It's too much trouble anyway.
        ]],
        DIALOG_INTIMIDATE_FAILURE = [[
            agent:
                [p] No! You can't scare me!
        ]],

        OPT_BRIBE = "Bribe {agent} to prevent {agent.himher} from testifying",
        DIALOG_BRIBE = [[
            player:
                [p] How much do you get compensated for your effort of testifying?
            agent:
                Nothing, in fact.
            player:
                How about a counteroffer? A bit for your effort to... not put in any effort.
            agent:
                Now we're talking.
                I love getting paid for doing nothing.
        ]],
    }
    :Hub(function(cxt)
        if cxt.quest:DefFn("HasEvidence", "airtight_alibi") or cxt.quest:DefFn("HasEvidence", "forged_alibi") then
            cxt.enc.scratch.alibi = true
        end
        if not cxt.quest.param.tried_cast_doubt_witness then
            cxt:BasicNegotiation("CAST_DOUBT", {
                situation_modifiers =
                {
                    cxt.enc.scratch.alibi and { value = -20, text = cxt:GetLocString("SIT_MOD_ALIBI") } or nil
                },
            })
                :OnSuccess()
                    :CompleteQuest("talk_to_witness")
                    :Fn(function(cxt)
                        cxt.quest:DefFn("AddEvidenceList", "doubtful_testimony")
                    end)
                :OnFailure()
                    :Fn(function(cxt)
                        cxt.quest.param.tried_cast_doubt_witness = true
                    end)
        end
        if not cxt.quest.param.tried_intimidate_witness then
            cxt:BasicNegotiation("INTIMIDATE", { flags = NEGOTIATION_FLAGS.INTIMIDATION })
                :OnSuccess()
                    :CompleteQuest("talk_to_witness")
                    :Fn(function(cxt)
                        cxt.quest.param.witness_unavailable = true
                        cxt.quest.param.witness_intimidated = true
                    end)
                :OnFailure()
                    :Fn(function(cxt)
                        cxt.quest.param.tried_intimidate_witness = true
                    end)
        end
        local bribe_cost = 100
        cxt:Opt("OPT_BRIBE")
            :DeliverMoney( bribe_cost )
            :Dialog("DIALOG_BRIBE")
            :CompleteQuest("talk_to_witness")
            :Fn(function(cxt)
                cxt.quest.param.witness_unavailable = true
                cxt.quest.param.witness_bribed = true
            end)
    end)
    :AttractState("STATE_ATTRACT", function(cxt) return not cxt.quest.param.talked_to_witness end)
    :Loc{
        DIALOG_INTRO = [[
            player:
                [p] You are a witness to the theft case, yes?
            agent:
                Yes.
                I'm telling you! {giver} did it!
                I saw it with my own eyes! {giver} leaving {plaintiff}'s estate at the time of the theft!
            *** {agent} saw {giver} leaving {plaintiff}'s estate at the time of the theft.
        ]],
    }
    :Fn(function(cxt)
        cxt:Dialog("DIALOG_INTRO")
        cxt.quest.param.talked_to_witness = true
    end)

QDEF:AddConvo("talk_to_prosecutor", "prosecutor")
    :Loc{
        OPT_INTIMIDATE = "Intimidate {agent} to prevent {agent.himher} from representing {plaintiff}",
        SIT_MOD = "Don't tell me you're actually threatening a prosecutor actively against your client?",
        DIALOG_INTIMIDATE = [[
            player:
                [p] Here's what's going to happen.
                You are not going to represent {plaintiff}. If you know what's good for you.
            agent:
                Are you kidding me? Do you have any idea what the consequences of interfering with justice is?
        ]],
        DIALOG_INTIMIDATE_SUCCESS = [[
            player:
                [p] Well? Do you know the consequence of pissing me off?
            agent:
                Hesh, if you are that insistent about it, fine, I will leave.
                It's not like this actually improves your client's chance.
                With that much evidence against your client, any third-rate lawyer can prove your clients guilt.
        ]],
        DIALOG_INTIMIDATE_FAILURE = [[
            agent:
                [p] Really, that's it?
                Honestly, you just seem like a desperate vroc.
        ]],
        OPT_ASK_EVIDENCE = "Ask for evidence",
        DIALOG_ASK_EVIDENCE = [[
            player:
                [p] You have evidence to prove {giver}'s guilt?
                May I see it?
        ]],
        DIALOG_ASK_EVIDENCE_SUCCESS = [[
            agent:
                [p] Fine. Go take a look, then.
        ]],
        DIALOG_ASK_EVIDENCE_NO = [[
            agent:
                [p] I don't know what to show you.
                We don't have anything to show you.
            player:
                Are you serious? Why are you so certain of my client's guilt?
            agent:
                I know {giver}'s guilty.
                I will find concrete evidence. Mark my words.
        ]],
        DIALOG_ASK_EVIDENCE_FAILURE = [[
            agent:
                [p] I am not obligated to show you the evidence.
                You will have plenty of opportunity to see the evidence in court.
        ]],
    }
    :Hub(function(cxt)
        if not cxt.quest.param.tried_intimidate_prosecutor then
            cxt:BasicNegotiation("INTIMIDATE", {
                flags = NEGOTIATION_FLAGS.INTIMIDATION,
                situation_modifiers =
                {
                    { value = 30, text = cxt:GetLocString("SIT_MOD") }
                },
            })
                :OnSuccess()
                    :CompleteQuest("talk_to_prosecutor")
                    :Fn(function(cxt)
                        if cxt.quest:IsActive("acquire_false_evidence") then
                            cxt.quest:Complete("acquire_false_evidence")
                        end
                        cxt.quest:UnassignCastMember("prosecutor")
                        cxt.quest.param.prosecutor_intimidated = true
                    end)
                :OnFailure()
                    :Fn(function(cxt)
                        cxt.quest.param.tried_intimidate_prosecutor = true
                    end)
        end
        if not cxt.quest.param.tried_evidence_prosecutor then
            cxt:Opt("OPT_ASK_EVIDENCE")
                :Dialog("DIALOG_ASK_EVIDENCE")
                :Fn(function(cxt)
                    cxt.quest.param.tried_evidence_prosecutor = true
                end)
                :Negotiation{

                }
                    :OnSuccess()
                        :Fn(function(cxt)
                            if cxt.quest.param.have_evidence then
                                cxt:Dialog("DIALOG_ASK_EVIDENCE_SUCCESS")
                                cxt:GoTo("STATE_CHECK_EVIDENCE")
                            else
                                cxt:Dialog("DIALOG_ASK_EVIDENCE_NO")
                            end
                        end)
                    :OnFailure()
                        :Dialog("DIALOG_ASK_EVIDENCE_FAILURE")
        end
    end)
    :State("STATE_CHECK_EVIDENCE")
        :Loc{
            DIALOG_INTRO = [[
                * [p] You examine the ring.
                {pros_forged_evidence?
                    {asked_ring?
                        * A fairly unique design, but it doesn't match the description provided by {giver}.
                        * Did the prosecutor forge this evidence?
                    }
                    {not asked_ring?
                        * A fairly unique design, though nothing suggests that it belongs to {giver}.
                        * If it does belong to {giver}, though, this could be real bad for your client.
                    }
                }
                {not pros_forged_evidence?
                    * A fairly unique design.
                    * The inside of the ring displays the text "{giver}+{spouse_name}".
                    {asked_ring?
                        * Hesh. Doesn't it exactly match the description provided by {giver}?
                    }
                    {not asked_ring?
                        * You have no idea who this "{spouse_name}" is, but the ring definitely belongs to {giver}.
                    }
                    * This looks really bad for your client.
                }
            ]],
            OPT_RETURN_EVIDENCE = "Return the evidence",
            DIALOG_RETURN_EVIDENCE = [[
                player:
                    [p] Here is the evidence. Thank you for letting me see it.
                agent:
                    Anything else you need from me?
            ]],
            OPT_SWAP = "Swap the ring with a less incriminating one",
            DIALOG_SWAP = [[
                {pros_forged_evidence and asked_ring?
                    * [p] Even though you know this is not {giver}'s ring, you took it regardless.
                    * After all, you spend money on this fake ring. It would be a shame to let it go to waste.
                }
                * You quickly swapped the evidence without {agent} noticing.
                player:
                    Here is the evidence. Thank you for letting me see it.
                agent:
                    Anything else you need from me?
            ]],
            OPT_TAKE = "Forcefully take the evidence from {agent}",
            DIALOG_TAKE = [[
                player:
                    Thanks for the ring.
                agent:
                    ...
                    Are you joking?
                    Are you actually trying to take the evidence?
                    Right here? Under broad daylight? In the witness of so many Admiralty officers?
                {night?
                    player:
                        !dubious
                        But it's night time?
                    agent:
                        Bah, it's a figure of speech.
                }
            ]],
            OPT_TAKE_AGAIN = "Take it",
            DIALOG_TAKE_AGAIN = [[
                player:
                    [p] Yes.
                agent:
                    ...
                * Before you can make any move, sirens sound across the building.
                * All exits lock themselves, as squads of Admiralty patrol quickly close on your location.
                agent:
                    You shouldn't have made an enemy of the Admiralty.
            ]],
            DIALOG_RETURN_EVIDENCE_AGAIN = [[
                player:
                    [p] Nah I'm just messing with you.
                    Here is the evidence.
                agent:
                    Please do not do that again.
            ]],
            OPT_SURRENDER = "Surrender",
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")

            cxt.quest.param.seen_ring = true

            cxt:Opt("OPT_RETURN_EVIDENCE")
                :Dialog("DIALOG_RETURN_EVIDENCE")

            if cxt.quest.param.got_false_evidence then
                cxt:Opt("OPT_SWAP")
                    :Dialog("DIALOG_SWAP")
                    :Fn(function(cxt)
                        cxt.quest.param.def_forged_evidence = true
                        cxt:ForceTakeCards{"dem_incriminating_evidence"}
                        if cxt.quest:IsActive("acquire_false_evidence") then
                            cxt.quest:Complete("acquire_false_evidence")
                        end
                        cxt.quest.param.got_false_evidence = false
                    end)
                    :CompleteQuest("talk_to_prosecutor")
            end
            cxt:Opt("OPT_TAKE")
                :Dialog("DIALOG_TAKE")
                :Fn(function(cxt)
                    cxt:Opt("OPT_TAKE_AGAIN")
                        :Dialog("DIALOG_TAKE_AGAIN")
                        :Fn(function(cxt)
                            cxt:Opt("OPT_SURRENDER")
                                :Fn(function(cxt)
                                    local flags = {
                                        interfere_justice = true,
                                    }
                                    DemocracyUtil.DoEnding(cxt, "arrested", flags)
                                end)
                        end)

                    cxt:Opt("OPT_RETURN_EVIDENCE")
                        :Dialog("DIALOG_RETURN_EVIDENCE_AGAIN")
                end)
        end)
    :AttractState("STATE_ATTRACT", function(cxt) return not cxt.quest.param.talked_to_prosecutor end)
    :Loc{
        DIALOG_INTRO = [[
            player:
                [p] You are the prosecutor of the theft case, yes?
            agent:
                Yes.
                I'm representing {plaintiff} in this case.
                I presume you are the defense lawyer representing {giver}?
            player:
                Indeed.
            agent:
                Your client stands no chance.
            {have_evidence and not have_witness?
                We have concrete evidence proving your client's guilt.
            }
            {not have_evidence and have_witness?
                We have a witness that can testify against your client.
            }
            {have_evidence and have_witness?
                We have evidence. And witness.
            }
        ]],
    }
    :Fn(function(cxt)
        cxt:Dialog("DIALOG_INTRO")
        cxt.quest.param.talked_to_prosecutor = true
    end)

QDEF:AddConvo("acquire_false_evidence")
    :Loc{
        OPT_GET = "Buy a cheap ring",
        DIALOG_GET = [[
            player:
                [p] Do you have a ring that is extremely cheap, made of the cheapest materials?
            agent:
                Why would you ever-
            player:
                Don't ask.
                Here's the money.
            agent:
                You know what? Sure.
                Here you go.
            * Now that you have a cheap ring, perhaps you can try to swap it with the evidence with {prosecutor}.
        ]],
    }
    :Hub(function(cxt, who)
        if who and cxt.quest:DefFn("CanSellFalseEvidence", who) then
            cxt:Opt("OPT_GET")
                :SetQuestMark()
                :DeliverMoney(25)
                :Dialog("DIALOG_GET")
                :CompleteQuest("acquire_false_evidence")
                :Fn(function(cxt)
                    cxt.quest.param.got_false_evidence = true
                end)
        end
    end)

QDEF:AddConvo("attend_trial")
    :ConfrontState("STATE_CONF", function(cxt) return cxt.location == cxt:GetCastMember("courtroom") end)
        :Loc{
            DIALOG_INTRO_RING = [[
                * [p] You visit the courtroom.
                giver:
                    !right
                player:
                    !left
                giver:
                    Ah, you arrived, just before the trial.
                    I hope you prepared enough for this.
                {asked_ring?
                    player:
                        Ah, I see you are wearing your ring.
                    giver:
                        Of course. How could I not? It's important to me.
                    player:
                        Well, this is going to make things easier.
                }
                {not asked_ring?
                    player:
                        Ah, I see you are wearing a ring.
                        It looks pretty.
                    giver:
                        Thanks!
                        It's my engagement ring with my partner, {spouse_name}.
                    player:
                        I see.
                }
                player:
                    Well, let's get you free.
            ]],
            DIALOG_INTRO_NO_RING = [[
                * [p] You visit the courtroom.
                giver:
                    !right
                player:
                    !left
                giver:
                    Ah, you arrived, just before the trial.
                    I hope you prepared enough for this.
                    I have also just arrived. I couldn't find my ring anywhere.
                {asked_ring?
                    player:
                    {seen_ring and not (pros_forged_evidence or def_forged_evidence)?
                        That's because the prosecutor has it as evidence.
                    }
                    {not (seen_ring and not (pros_forged_evidence or def_forged_evidence))?
                        Presumably the prosecutor has it as evidence.
                    }
                    giver:
                        Right, those bastards.
                    player:
                        Let's get you free, first.
                }
                {not asked_ring?
                    player:
                        Your... ring?
                    giver:
                        Yeah! My engagement ring with my partner, {spouse_name}.
                    {seen_ring and not (pros_forged_evidence or def_forged_evidence)?
                        * Ah, Hesh. Isn't that the same name you saw on the ring that the prosecutor has?
                    }
                    player:
                        Well... Let's focus on the trial first.
                }
            ]],
            DIALOG_INTRO_FAKE_RING = [[
                * [p] You visit the courtroom.
                giver:
                    !right
                player:
                    !left
                giver:
                    Ah, you arrived, just before the trial.
                    I hope you prepared enough for this.
                player:
                    Ah, I see you are wearing "your ring".
                giver:
                    Right. Right.
                    ...
                player:
                    Well, the trial is about to begin.
                    Let's get you free, first.
            ]],
            OPT_CONTINUE = "Continue on to the trial",
        }
        :Fn(function(cxt)
            if not cxt:GetCastMember("judge") or cxt:GetCastMember("judge"):IsRetired() then
                cxt.quest:UnassignCastMember("judge")
                cxt.quest:AssignCastMember("judge")
            end
            if not cxt:GetCastMember("witness") or cxt:GetCastMember("witness"):IsRetired() then
                cxt.quest.param.witness_unavailable = true
            end
            if cxt.quest.param.defendant_has_false_ring then
                cxt:Dialog("DIALOG_INTRO_FAKE_RING")
                cxt.quest:DefFn("AddEvidenceList", "defendant_has_false_ring")
            elseif cxt.quest.param.defendant_has_ring then
                cxt:Dialog("DIALOG_INTRO_RING")
                cxt.quest:DefFn("AddEvidenceList", "defendant_has_ring")
            else
                cxt:Dialog("DIALOG_INTRO_NO_RING")
            end
            cxt.quest:DefFn("AddEvidenceList", "ring_desc")

            cxt:Opt("OPT_CONTINUE")
                :Fn(function(cxt)
                    cxt.enc:RemoveAllAgents()
                end)
                :GoTo("STATE_TRIAL")
        end)
    :State("STATE_TRIAL")
        :Loc{
            DIALOG_INTRO_NO_PLAINTIFF = [[
                * [p] The trial begins.
                * No one showed up as the plaintiff.
                * Seems like there is not going to be a trial, and your client is automatically found not guilty.
                {pros_available?
                    * The prosecutor is mad, but {prosecutor.gender:he's|she's|they're} in charge of the theft case only, and a plaintiff is required for the trial to proceed by law, {prosecutor.heshe} can't do anything about it.
                }
                player:
                    !left
                giver:
                    !right
                    Well, I guess we won the trial.
                    That was anti-climatic.
                    Not sure what you did to make them unable to show up to the trial, but I'm grateful regardless.
            ]],
            DIALOG_INTRO_NO_PROS = [[
                * [p] The trial begins.
                plaintiff:
                    !left
                judge:
                    !right
                    Where is your attorney, plaintiff?
                plaintiff:
                    They left me hanging. I have to represent myself today.
                judge:
                    Very well. I presume you are ready, then?
                plaintiff:
                    Yes, your honour.
                player:
                    !left
                judge:
                    Is the defense ready?
                player:
                    Yes, your honour.
                judge:
                    Very well, then. Plaintiff, please begin your opening statement.
            ]],
            DIALOG_INTRO = [[
                * [p] The trial begins.
                prosecutor:
                    !left
                judge:
                    !right
                    Is the plaintiff ready?
                prosecutor:
                    Yes, your honour.
                player:
                    !left
                judge:
                    Is the defense ready?
                player:
                    Yes, your honour.
                judge:
                    Very well, then. Plaintiff, please begin your opening statement.
            ]],

            OPT_TRIAL = "Begin Trial",
            DIALOG_TRIAL_SUCCESS = [[
                * [p] You win the trial!
            ]],
            DIALOG_TRIAL_FAILURE = [[
                * [p] You lose the trial!
            ]],
            DIALOG_TRIAL_PERJURY = [[
                * [p] Not only did you lose the trial, you are found with forged evidence!
            ]],
            OPT_DEFEAT = "Accept your defeat",
            DIALOG_DEFEAT = [[
                * [p] You gave up, and {giver} was arrested.
            ]],
            OPT_ARREST = "Accept your arrest",
            DIALOG_ARREST = [[
                * [p] You and your client are both arrested.
            ]],
            OPT_FIGHT = "Fight your way out",
            DIALOG_FIGHT = [[
                * [p] You aren't just going to take it lying down! You ain't respecting the trial.
            ]],
            DIALOG_FIGHT_WIN = [[
                * [p] You won the fight and broke out of the courtroom!
                * {giver} was kinda fussy about making the Admiralty mad, but you reminded {giver.himher} that {giver.gender:he's|she's|they're} technically not arrested.
            ]],
            DIALOG_FIGHT_RUNAWAY = [[
                * [p] You alone escaped the courtroom, but {giver} was left behind and arrested instead.
                * Oh well. At least you are free.
            ]],
        }
        :Fn(function(cxt)
            cxt.enc.scratch.plaintiff_available = cxt:GetCastMember("plaintiff") and not cxt:GetCastMember("plaintiff"):IsRetired()
            cxt.enc.scratch.pros_available = cxt:GetCastMember("prosecutor") and not cxt:GetCastMember("prosecutor"):IsRetired()

            if cxt.enc.scratch.plaintiff_available then
                if cxt.enc.scratch.pros_available then
                    cxt:TalkTo("prosecutor")
                    cxt:Dialog("DIALOG_INTRO")
                else
                    cxt:TalkTo("plaintiff")
                    cxt:Dialog("DIALOG_INTRO_NO_PROS")
                end
            else
                cxt:Dialog("DIALOG_INTRO_NO_PLAINTIFF")
                cxt.quest:Complete()
                ConvoUtil.GiveQuestRewards(cxt)
                StateGraphUtil.AddEndOption(cxt)
                return
            end

            cxt:Opt("OPT_TRIAL")
                :Fn(function(cxt)
                    local BEHAVIOR = shallowcopy(DemocracyUtil.BEHAVIOURS.COURT_OF_LAW)
                    BEHAVIOR.plaintiff_arguments = {}
                    if cxt.quest.param.have_evidence then
                        if cxt.quest.param.pros_forged_evidence or cxt.quest.param.def_forged_evidence then
                            table.insert(BEHAVIOR.plaintiff_arguments, "evidence_ring_fake")
                        else
                            table.insert(BEHAVIOR.plaintiff_arguments, "evidence_ring_real")
                        end
                    end
                    if cxt.quest.param.have_witness and not cxt.quest.param.witness_unavailable then
                        table.insert(BEHAVIOR.plaintiff_arguments, "testimony")
                    end
                    cxt:GetAgent():SetTempNegotiationBehaviour(BEHAVIOR)
                end)
                :Negotiation{
                    cooldown = 0,
                    on_start_negotiation = function(minigame)
                        for i, id in ipairs(cxt.quest.param.evidence_list or {}) do
                            local card = Negotiation.Card( "dem_court_objection", minigame.player_negotiator.agent, { argument_id = id } )
                            card.show_dealt = true
                            card:TransferCard(minigame:GetDrawDeck())
                        end
                    end,
                    on_success = function(cxt, minigame)
                        cxt:Dialog("DIALOG_TRIAL_SUCCESS")
                        cxt.quest:Complete()
                        ConvoUtil.GiveQuestRewards(cxt)
                        StateGraphUtil.AddEndOption(cxt)
                    end,
                    on_fail = function(cxt, minigame)
                        if minigame.false_evidence then
                            cxt.quest.param.guilty_of_forgery = true
                        end
                        if cxt.quest.param.guilty_of_forgery then
                            cxt:Dialog("DIALOG_TRIAL_PERJURY")
                            cxt:Opt("OPT_ARREST")
                                :Dialog("DIALOG_ARREST")
                                :Fn(function(cxt)
                                    local flags = {
                                        interfere_justice = true,
                                    }
                                    DemocracyUtil.DoEnding(cxt, "arrested", flags)
                                end)
                        else
                            cxt:Dialog("DIALOG_TRIAL_FAILURE")
                            cxt:Opt("OPT_DEFEAT")
                                :Dialog("DIALOG_DEFEAT")
                                :FailQuest()
                                :Fn(function(cxt)
                                    cxt.quest:GetCastMember("giver"):GainAspect("stripped_influence", 5)
                                    cxt.quest:GetCastMember("giver"):Retire()
                                end)
                                :DoneConvo()
                        end
                        cxt.enc.scratch.opfor = CreateCombatParty("ADMIRALTY_PATROL", cxt.quest:GetRank() + 1, cxt.location, true)
                        cxt:Opt("OPT_FIGHT")
                            :DeltaSupport(-3, "ADMIRALTY")
                            :Dialog("DIALOG_FIGHT")
                            :Battle{
                                enemies = cxt.enc.scratch.opfor,
                                allies = {cxt:GetCastMember("giver")},
                                on_win = function(cxt)
                                    cxt:Dialog("DIALOG_FIGHT_WIN")
                                    cxt.quest.param.poor_performance = true
                                    cxt.quest:Complete()
                                    ConvoUtil.GiveQuestRewards(cxt)
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                end,
                                on_runaway = function(cxt, battle)
                                    cxt:Dialog("DIALOG_FIGHT_RUNAWAY")
                                    StateGraphUtil.DoRunAwayEffects( cxt, battle )
                                    cxt.quest:GetCastMember("giver"):GainAspect("stripped_influence", 5)
                                    cxt.quest:GetCastMember("giver"):Retire()
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                end,
                            }
                    end,
                }
        end)
