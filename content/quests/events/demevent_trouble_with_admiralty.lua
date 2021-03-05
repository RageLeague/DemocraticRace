local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    precondition = function(quest)
        local canspawn = false

        quest.param.assaulted_officer = TheGame:GetGameState():GetPlayerAgent():HasMemory("ASSAULTED_ADMIRALTY")
        if quest.param.assaulted_officer then
            quest.param.assaulted = true
            
            canspawn = true
        end
        if DemocracyUtil.GetFactionEndorsement("ADMIRALTY") < RELATIONSHIP.NEUTRAL then
            quest.param.unpopular = true
            canspawn = true
        end
        return canspawn --or true
    end,
}
:AddOpinionEvents{

    resist_arrest =  
    {
        delta = OPINION_DELTAS.DISLIKE,
        txt = "Resisted Arrest",
    },
}
QDEF:AddConvo()
    :ConfrontState("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * You wince at the sight of the admiralty patrol sitting up the street.
                * One of them, {agent}, looks at you with an angered sneer on {agent.hisher} face
                player:
                    !left
                agent:
                    !right
                    !cruel
                    Well, well, well, well, well.
                    If it isn't {player}?
                    {assaulted?
                    You've got a lot of gall to beat up an officer of the law, i'll give you that.
                    Unfortunately, that bravado won't hold up in court.
                    I cannot wait to bring down your entire political career in one slam of a gavel. You're under arrest.
                    }
                    {not assaulted?
                    You've got quite the following with you, lot of supporters.
                    But you made one real mistake. You never gave the admiralty OUR cut of the policies.
                    You're being put in the slammer 'till you learn to "see our ways" of running this Havaria.
                    }
                ** This event happened because you {assaulted?are wanted by the Admiralty for committing a crime|are unpopular among the Admiralty}.
            ]],
            OPT_PAY = "Pay the court a fine",
            DIALOG_PAY = [[
                player:
                You ever heard of how politicians have deep pockets?
                agent:
                Indeed I have.
                player:
                !give
                Want a glimpse into how deep those pockets are?
                agent:
                !take
                Indeed I would.
                A misunderstanding, {player}. I'm sure you'll win in due time.
                Take care!
            ]],
            OPT_CONVINCE = "Convince {agent} that they got the wrong person",
            DIALOG_CONVINCE = [[
                player:
                    {assaulted?
                    Now let's calm down a little. There's a lot of people in Havaria with grievances towards the Admiralty.
                    I'd like to see some proof of this, or do you just not agree with me?
                    }
                    {not assaulted?
                    I see you've bought into the smear campaign of my opposition.
                    Let me dispel some of those myths for you.
                    }
            ]],
            SIT_MOD = "The Admiralty is cautious of you",
            DIALOG_CONVINCE_SUCCESS = [[
                player:
                    {not assaulted?
                    Y'see? The admiralty'll get their cut eventually.
                    If nothing else, I can be the counter balance to the other less than lawful candidates and make your guys look better in comparison.
                agent:
                    !think
                    You do make a bit of sense
                    Very well, but just remember I, or whoever comes after you next, might not be as lenient.
                    !exit
                player:
                    !salute
                    }
                    {assaulted?
                    Check with my advisor. I wasn't anywhere near the scene of the crime!
                    Next time, try to have a more solid base of evidence before you go accusing politicians like that.
                agent:
                    !think
                    Hmm. If you actually have an alabi, I guess we can't do much.
                    Though I don't think your advisor would be particularly truthful in this endeavor.
                    But it's a lead. And the law says we have to follow it 'till were sure it's a dead end.
                    Just know that the other officers might not be as willing to listen to that kind of vroc-wash.
                    !exit
                player:
                    !salute
                    }
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                player:
                    {assaulted?
                    If I actually did hurt an officer, why can't you bring them here to testify?
                agent:
                    Because they're in the infirmary and getting a lot of their blood on the floor.
                    Not a convincing argument you have there.
                    }
                    {not assaulted?
                    I thought this was a democracy? with democratic free speech?
                agent:
                    Oh. You poor, poor fool.
                    !chuckle
                    The last thing you've done before being imprisoned is making me feel sorry for your naivety
                    }
            ]],
            OPT_INTIMIDATE = "Scare {agent} away",
            DIALOG_INTIMIDATE = [[
                player:
                    {assaulted?
                    Y'know, you came up to me with a warrant for assault.
                    !throatcut
                    Yet you seem to lapse on the fact that i'm completely willing to do the same to you.
                    }
                    {not assaulted?
                    Oh. you used the word "cut".
                    !throatcut
                    How ironic your terminology is in this instance.
                    }
            ]],
            DIALOG_INTIMIDATE_SUCCESS_SOLO = [[
                player:
                    What'll it be, switch? Want to be sent home in a body bag?
                agent:
                    !scared
                    ...Alright! You win!
                    Aah!
                    !exit
                * {agent} drops a few papers in {agent.hisher} panic. They seem to pertain to your arrest.
                * You quickly confiscate them and walk away like nothing happened.
            ]],
            DIALOG_INTIMIDATE_SUCCESS = [[
                player:
                    Try your luck, I dare you.
                    None of you will walk away if you test me.
                * The words carry a force that chills {agent}'s followers to the bone.
                * They scurry away without a look back.
                agent:
                    !angry
                    Rrgh, hesh damn it.
                    I am reporting half of that patrol to the higher ups, I swear.
                player:
                    What, you want to try your luck? Prove how hard you are?
                agent:
                    !scared
                    No thanks. I-i'm good.
                * {agent} takes to the wind as well.
            ]],
            DIALOG_INTIMIDATE_OUTNUMBER = [[
                player:
                    Remember, I still know how to use my weapons.
                    I'll take you all on!
                * A few of the more skittish members of {agent}'s group back up
                * Still though, they outnumber you, and {agent} is unfazed.
                agent:
                    !fight
                    Come on, that the toughest you can pull off?
            ]],
            DIALOG_INTIMIDATE_FAILURE = [[
                player:
                    You want your insides to be eviserated? Be my guest.
                agent:
                    Pssh, as if you could pull that off.
                {some_ran?
                * {agent} looks back to see some people ran off.
                agent:
                    Oh come on, people. Earn your shill!
                * The routed followers came back, shaking off the nervousness.
                }
            ]],
            DIALOG_FIGHT_WIN = [[
                {dead?
                    * {agent} lies at your feet, their soul being consumed by Hesh as you stand.
                    {assaulted?
                    * Well, you can now add 2 to the score of government workers you murdered.
                    * A bit ironic, considering you're running for a government office.
                    }
                    {not assaulted?
                    * The admiralty will definitely be after your head now.
                    * But maybe once you're in office you can clear your name.
                    * You make a mental note to burn your records before shoving the body into a dark corner.
                    }
                }
                {not dead?
                    agent:
                        !injured
                    {assaulted?
                    player:
                        You really didn't think that through, did you?
                    agent:
                        Alright, alright, you win!
                        Just know that i'm filing a report on this!
                        !exit
                    }
                    {not assaulted?
                    }
                }
            ]],
            OPT_RESIST = "Resist Arrest",
            DIALOG_RESIST = [[
                player:
                    !fight
                    You'll never get me alive!
            ]],
            OPT_ARREST = "Serve your sentence",
            DIALOG_ARREST = [[
                player:
                    Fine, I'll come.
                    But you'll be hearing from my lawyers!
                agent:
                    Yeah, sure. Whatever.
            ]],
        }
        :SetLooping(true)
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.quest:Complete()
                cxt.enc.scratch.opfor = CreateCombatParty("ADMIRALTY_PATROL", cxt.quest:GetRank() + 1, cxt.location, true)
                cxt:TalkTo(cxt.enc.scratch.opfor[1])
                cxt:Dialog("DIALOG_INTRO")
            end
            local function PostFight(cxt)
                cxt:Dialog("DIALOG_FIGHT_WIN")
                cxt.player:Remember("ASSAULTED_ADMIRALTY", cxt:GetAgent())
                if not cxt:GetAgent():IsDead() then
                    cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("resist_arrest"))
                end
                StateGraphUtil.AddLeaveLocation(cxt)
            end
            local pay_cost = 50 + 25 * cxt.quest:GetRank()
            cxt:Opt("OPT_PAY")
                :DeliverMoney(pay_cost)
                :Travel()
            if not cxt.quest.param.tried_convince then
                cxt:Opt("OPT_CONVINCE")
                    :ReqRelationship( RELATIONSHIP.NEUTRAL )
                    :Dialog("DIALOG_CONVINCE")
                    :Negotiation{
                        cooldown = 0,
                        situation_modifiers =
                        {
                            { value = 5 + 5 * math.floor(cxt.quest:GetRank()/2), text = cxt:GetLocString("SIT_MOD") }
                        },
                    }
                        :OnSuccess()
                            :Dialog("DIALOG_CONVINCE_SUCCESS")
                            :Travel()
                        :OnFailure()
                            :Dialog("DIALOG_CONVINCE_FAILURE")
                            :Fn(function(cxt) cxt.quest.param.tried_convince = true end)
            else
                cxt:Opt("OPT_RESIST")
                    :Dialog("DIALOG_RESIST")
                    :Battle{
                        flags = BATTLE_FLAGS.SELF_DEFENCE,
                        on_win = PostFight,
                    }
            end
            if not cxt.quest.param.tried_intimidate then
                if #cxt.enc.scratch.opfor == 1 then
                    cxt:Opt("OPT_INTIMIDATE")
                        :Dialog("DIALOG_INTIMIDATE")
                        :Negotiation{
                            cooldown = 0,
                            flags = NEGOTIATION_FLAGS.INTIMIDATION,
                        }
                            :OnSuccess()
                                :Dialog("DIALOG_INTIMIDATE_SUCCESS_SOLO")
                                :Travel()
                            :OnFailure()
                                :Dialog("DIALOG_INTIMIDATE_FAILURE")
                                :Fn(function(cxt)
                                    cxt.quest.param.tried_intimidate = true
                                    cxt:Opt("OPT_DEFEND")
                                        :Battle{
                                            flags = BATTLE_FLAGS.SELF_DEFENCE,
                                            on_win = PostFight,
                                        }
                                end)
                else
                    local allies = {}
                    for i, ally in ipairs(cxt.enc.scratch.opfor) do
                        if i ~= 1 then
                            table.insert(allies, ally)
                        end
                    end
                    cxt:Opt("OPT_INTIMIDATE")
                        :Dialog("DIALOG_INTIMIDATE")
                        :Negotiation{
                            cooldown = 0,
                            flags = NEGOTIATION_FLAGS.INTIMIDATION | NEGOTIATION_FLAGS.ALLY_SCARE,
                            enemy_resolve_required = 8 + cxt.quest:GetRank() * 10,
                            fight_allies = allies,
                            on_success = function(cxt, minigame)
                                local keep_allies = {}
                                for i, modifier in minigame:GetOpponentNegotiator():Modifiers() do
                                    if modifier.id == "FIGHT_ALLY_SCARE" and modifier.ally_agent then
                                        table.insert( keep_allies, modifier.ally_agent )
                                    end
                                end

                                for k,v in pairs(allies) do
                                    if not table.arrayfind(keep_allies, v) then
                                        v:MoveToLimbo()
                                    end
                                end
                                if #keep_allies == 0 or (DemocracyUtil.CalculatePartyStrength(cxt.player:GetParty()) >= DemocracyUtil.CalculatePartyStrength(cxt:GetAgent():GetParty()) ) then
                                    cxt:Dialog("DIALOG_INTIMIDATE_SUCCESS")
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                else
                                    cxt:Dialog("DIALOG_INTIMIDATE_OUTNUMBER")
                                    cxt:Opt("OPT_DEFEND")
                                        :Battle{
                                            flags = BATTLE_FLAGS.SELF_DEFENCE,
                                            on_win = PostFight,
                                        }
                                end
                                -- print("Party members you have: ", TheGame:GetGameState():GetCaravan():GetPartyCount())
                                -- if #keep_allies <= TheGame:GetGameState():GetCaravan():GetPartyCount() then
                                --     cxt:Dialog("DIALOG_INTIMIDATE_SUCCESS")
                                -- else

                                -- end
                            end,
                            on_fail = function(cxt,minigame)
                                cxt.enc.scratch.some_ran = not (minigame:GetOpponentNegotiator():FindCoreArgument() and minigame:GetOpponentNegotiator():FindCoreArgument():GetShieldStatus())
                                cxt:Dialog("DIALOG_INTIMIDATE_FAILURE")
                                cxt.quest.param.tried_intimidate = true
                                cxt:Opt("OPT_DEFEND")
                                    :Battle{
                                        flags = BATTLE_FLAGS.SELF_DEFENCE,
                                        on_win = PostFight,
                                    }
                            end,
                        }
                end
            end
            cxt:Opt("OPT_ARREST")
                :Dialog("DIALOG_ARREST")
                :Fn(function(cxt)
                    local flags = {
                        suspicion_of_crime = true,
                    }
                    DemocracyUtil.DoEnding(cxt, "arrested", flags)
                end)
        end)
