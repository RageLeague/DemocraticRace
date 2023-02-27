local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    rank = {3},
    cooldown = EVENT_COOLDOWN.LONG,
    events = {
        base_difficulty_change = function(quest, new_diff, old_diff)
            quest:SetRank(new_diff)
        end,
    },
}
:AddCast{
    cast_id = "infected",
    cast_fn = function(quest, t)
        -- Some random guy we don't know about, if it's just a random event.
        table.insert(t, quest:CreateSkinnedAgent())
    end,
    no_validation = true,
    events = {
        agent_retired = function(quest, agent)
            if not quest.param.event_in_action then
                quest:Cancel()
            end
        end,
    }
}
:AddObjective{
    id = "wait",
    hide_in_overlay = true,
    state = QSTATUS.ACTIVE,

    events =
    {
        action_clock_advance = function(quest, location)
            if quest.param.dormant_start_time ~= Now() then
                quest.param.dormant_timer = (quest.param.dormant_timer or 0) - 1
                if math.random() < 0.5 then
                    quest.param.dormant_timer = quest.param.dormant_timer + 1
                end
                if quest.param.dormant_timer <= 0 then
                    quest:Complete("wait")
                    quest:Activate("action")
                end
            end
        end,
    },

    on_activate = function(quest)
        quest:SetHideInOverlay(true)
        if not quest.param.spawned_from_quest then
            quest:Complete("wait")
            quest:Activate("action")
        else
            quest.param.dormant_timer = math.random(3,7)
            -- if wait_for_next_time then
            quest.param.dormant_start_time = Now()
        end
        -- end
    end,
}
:AddObjective{
    id = "action",
    on_activate = function(quest)
    end,
    events =
    {
        card_added = function( quest, card )
            print(card)
            print(card.id)
            if card.id == "dem_random_rare_parasite" then
                quest.param.took_parasites = true
            end
        end
    },
}
:AddOpinionEvents{
    reassured = {
        delta = OPINION_DELTAS.MAJOR_GOOD,
        txt = "Reassured them that everything is going to be alright",
    },
    saved = {
        delta = OPINION_DELTAS.OPINION_UP,
        txt = "Saved them from a bog monster attack",
    },
}

local function TransformBeast(cxt)
    local beast = TheGame:GetGameState():AddSkinnedAgent("DEM_MUTANT_BOG_MONSTER")
    beast.head = cxt:GetCastMember("infected").head
    beast.hair_colour = cxt:GetCastMember("infected").hair_colour
    beast.skin_colour = cxt:GetCastMember("infected").skin_colour
    beast.eye_colour = cxt:GetCastMember("infected").eye_colour
    beast.health:SetPercent(0.25 + 0.75 * cxt:GetCastMember("infected").health:GetPercent())

    cxt:ReassignCastMember("beast", beast)
    cxt:GetCastMember("infected"):Kill()
end

local function SimulateBeastFight(beast, team)
    local beast = beast
    local survivors = team
    local dead_people = {}
    local turn_count = 1
    while #survivors > 0 and beast.health:Get() > 0 do
        for i, agent in ipairs(survivors) do
            beast.health:Delta(-math.random(0, 12))
            if beast.health:Get() == 0 then
                beast:Kill()
                break
            end
        end
        if beast:IsRetired() then
            break
        end
        local new_survivors = {}
        local primary = table.arraypick(survivors)
        for i, agent in ipairs(survivors) do
            if turn_count % 2 == 1 then
                agent.health:Delta(-math.random(0, 6))
            elseif primary == agent then
                agent.health:Delta(-math.random(0, 12))
            end
            if agent.health:Get() > 0 then
                table.insert(new_survivors, agent)
            else
                agent:Kill()
                table.insert(dead_people, agent)
            end
        end
        survivors = new_survivors
        turn_count = turn_count + 1
    end
    return survivors, dead_people
end

local CROWD_FOREMAN = {"ADMIRALTY_CLERK", "FOREMAN", "WEALTHY_MERCHANT", "PRIEST"}
local CROWD_MEMBER = {"LABORER", "HEAVY_LABORER", "OSHNU_WRANGLER", "RISE_REBEL", "LUMINITIATE", "ADMIRALTY_GOON", "BANDIT_GOON", "BANDIT_GOON2", "SPARK_BARON_GOON", "CHEMIST", "JAKES_RUNNER"}

QDEF:AddConvo("action")
    :Confront(function(cxt)
        if cxt.location:HasTag("in_transit") then
            cxt.quest.param.event_in_action = true
            if cxt:GetCastMember("infected"):IsInPlayerParty() then
                return "STATE_PARTY"
            else
                return "STATE_ROAD"
            end
        end
    end)
    :State("STATE_PARTY")
        :Loc{
            DIALOG_INTRO = [[
                * Everything changes in a minute.
                * before, you had been walking with a deteriorating but still functional {infected}.
                * Now, {infected} is on {infected.hisher} knees, sitting in a puddle of vomit, {infected.hisher} skin turning a sickly color.
                * Passerbys, before giving you space, now stare dumbfoundedly as you cradle {infected}'s head in your arms.
                * That minute has passed. Now you only have another minute before something <i>truly</> terrible happens.
            ]],
            OPT_KILL = "Kill {infected} before {infected.heshe} can transform!",
            DIALOG_KILL = [[
                player:
                    !fight
                * You brandish your weapon, aligning it with {infected}'s throat.
                * However, {infected} suddenly gets up with a sudden, struggling strength, and swats you away.
                * {infected.HeShe} produces {infected.hisher} weapon, prepared to fight you to both your deaths.
            ]],
            DIALOG_KILL_DEAD = [[
                * {infected} curls up into an unnatural position as {infected.heshe} dies, coughing a variety of fluids and viscera.
                * The fascination of the bystanders turns to confusion, then whispers. Accusations of betrayal permeate the air.
                * For your part, there isn't much you can do. You'll go down as a minor hero or a minor villain for this act. 
                * All you really can do is wipe what's left of {infected} off of your weapon and walk away, eyes burning into the back of your neck.
            ]],
            DIALOG_KILL_SPARED = [[
                * Before the fighting can continue, {infected} knocks you over with a sudden gust of strength before collapsing into a heap.
                beast:
                    !right
                * By the time you're upright, {infected} is no longer there. 
            ]],
            DIALOG_KILL_RUNAWAY = [[
                * You leave your half-finished work where {infected.heshe} lays, exhausted and squirming with protruding pain.
                * A choir of screams reward your half-measures. 
            ]],
            OPT_REASSURE = "Reassure {infected} that everything is going to be alright",
            DIALOG_REASSURE = [[
                player:
                    [p] Hold on, {infected}. Everything is going to be alright.
            ]],
            DIALOG_REASSURE_SUCCESS = [[
                infected:
                    [p] Thanks, {player}, I appreciate your confidence.
                    !happy
                * {infected} let out a agonizing smile.
                {not player_drunk?
                    * Despite everything, you can see that {infected} still has hope, and thank you for the courage you gave {infected.himher}.
                }
            ]],
            DIALOG_REASSURE_SUCCESS_PST = [[
                {not player_drunk?
                    * [p] Unfortunately that's not how it works at all.
                    * Hope doesn't prevent someone from transforming into a terrifying bog monster.
                    beast:
                        !right
                    * Before your very eyes, {infected} transforms into a huge monster!
                }
                {player_drunk?
                    beast:
                        !right
                    * [p] Just as you thought everything is going to be alright, {infected} transforms into a huge monster!
                    player:
                        !drunk
                    * Dang. You really hoped that would work.
                }
            ]],
            DIALOG_REASSURE_FAILURE = [[
                infected:
                    !injured
                player:
                    !hips
                    Now I'm not saying you're going to transform into a monster fueled by fruit flys and rage...
                    But if you happen to, I want you to remember one thing.
                    !point
                    Don't eat my face. 
                    I need it for my campaign.
                infected:
                    I...don't...AAAAHH!
                    !exit
            ]],
            DIALOG_REASSURE_FAILURE_PST = [[
                beast:
                    !right
                * Before your very eyes, {infected} transforms into a huge monster!
                player:
                    !placate
                    {infected}? Remember what I told you.
                    My face. Don't eat it.
                * {beast} lurches towards you, evidently discarding your advice.
            ]],
            OPT_LEAVE = "Leave {infected}",
            DIALOG_LEAVE = [[
                * You turn tail and run, to the demeaning stares of the bystanders.
                * However, you stop. As you look back, {infected} has turned into a warped beast, ravaging the people previously focused on you.
                * It was the screams that brought you back. Something in you couldn't live with yourself if you left them now.
            ]],
            REASON_TXT = "Kill {infected} within <#PENALTY>{1} {1*turn|turns}!</>",
        }
        :Fn(function(cxt)
            cxt.quest.param.monster_in_party = true
            cxt.enc.scratch.know_infected = cxt:GetCastMember("infected"):KnowsPlayer()
            cxt:TalkTo("infected")
            cxt:Dialog("DIALOG_INTRO")

            local turns_left = 6

            cxt:Opt("OPT_KILL")
                :Dialog("DIALOG_KILL")
                :Battle{
                    enemies = { "infected" },
                    flags = BATTLE_FLAGS.NO_SURRENDER,
                    reason_fn = function(battle)
                        return cxt:GetLocString("REASON_TXT", turns_left)
                    end,
                    on_start_battle = function(battle)
                        local fighter = battle:GetFighterForAgent(cxt:GetAgent())
                        if fighter then
                            fighter:AddCondition("IMPAIR", turns_left)
                            fighter:AddCondition("WOUND", turns_left)
                        end
                    end,
                    on_player_turn_start = function(battle)
                        if battle.turns > 1 then
                            turns_left = turns_left - 1
                            if turns_left <= 0 then
                                battle:Win()
                            end
                        end
                    end,
                    on_win = function(cxt)
                        local killed = cxt:GetCastMember("infected"):IsDead()
                        if killed then
                            cxt:Dialog("DIALOG_KILL_DEAD")
                            cxt.quest:Complete()
                            cxt.player:Remember("PUT_OUT_BOG_MISERY", cxt:GetCastMember("infected"))
                            StateGraphUtil.AddLeaveLocation(cxt)
                        else
                            cxt.enc.scratch.close_to_beast = true
                            TransformBeast(cxt)
                            cxt:Dialog("DIALOG_KILL_SPARED")
                            cxt:GoTo("STATE_MONSTER")
                        end
                    end,
                    on_runaway = function(cxt)
                        TransformBeast(cxt)
                        cxt.enc.scratch.tried_leaving = true
                        cxt:Dialog("DIALOG_LEAVE")
                        cxt:GoTo("STATE_MONSTER")
                    end,
                }

            cxt:BasicNegotiation("REASSURE", {})
                :OnSuccess()
                    :ReceiveOpinion("reassured")
                    :Fn(function(cxt)
                        cxt.enc.scratch.close_to_beast = true
                        TransformBeast(cxt)
                    end)
                    :Dialog("DIALOG_REASSURE_SUCCESS_PST")
                    :GoTo("STATE_MONSTER")
                :OnFailure()
                    :Fn(function(cxt)
                        cxt.enc.scratch.close_to_beast = true
                        TransformBeast(cxt)
                    end)
                    :Dialog("DIALOG_REASSURE_FAILURE_PST")
                    :GoTo("STATE_MONSTER")


            cxt:Opt("OPT_LEAVE")
                :Fn(function(cxt)
                    TransformBeast(cxt)
                    cxt.enc.scratch.tried_leaving = true
                end)
                :Dialog("DIALOG_LEAVE")
                :GoTo("STATE_MONSTER")
        end)
    :State("STATE_ROAD")
        :Loc{
            DIALOG_INTRO = [[
                * A small flurry of harried hands and voices push past you as you pass through another busy intersection.
                beast:
                    !right
                * One look up the road tells you why.
                {know_infected?
                    * Wait, that face... Is that {infected}?
                }
                {not know_infected?
                    * There seems to some sort of humanoid face to the monster, but you don't recognize them.
                }
            ]],
        }
        :Fn(function(cxt)
            cxt.enc.scratch.know_infected = cxt:GetCastMember("infected"):KnowsPlayer()
            TransformBeast(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt:GoTo("STATE_MONSTER")
        end)
    :State("STATE_MONSTER")
        :Loc{
            OPT_GATHER = "Gather panicking crowd to fight back the monster",
            DIALOG_GATHER = [[
                foreman:
                    !right
                    !scared
                player:
                    !left
                    Form up, soldiers!
            ]],
            DIALOG_GATHER_SUCCESS = [[
                * [p] You gathered a bunch of people who are willing to fight.
                * Now you need to decide if you want to let them fight, or join in on the battle.
            ]],
            DIALOG_GATHER_FAILURE = [[
                * [p] Dammit! You didn't gather anyone to fight by your side!
            ]],
            OPT_ATTACK = "Fight the monster",
            DIALOG_ATTACK = [[
                beast:
                    !right
                player:
                    !left
                    !fight
                    Alright! Let's settle this Grout Bog style!
            ]],
            DIALOG_ATTACK_WIN = [[
                player:
                    !left
                * [p] You killed the beast!
                {took_parasites?
                    * Don't know why you took the parasites and purposefully infect yourself, though. I thought you would know better.
                }
                {has_survivor?
                    player:
                        !left
                    agent:
                        !right
                        That was horrifying.
                        Let's hope we don't have more of these things attacking.
                    {know_infected and spawned_from_quest?
                        * [p] You fear that it is not likely going to be the case.
                        * The bog parasites are already here, in the Pearl, and they're spreading.
                        * It's only a matter of time before such incident occurs again.
                    }
                        Thanks again.
                        Without your help, the monster would probably kill us all.
                    {monster_in_party and not player_drunk?
                        * Sure, you are the <i>hero</> saving everyone here.
                        * Never mind the fact that it is your own indecisiveness that puts everyone in danger in the first place.
                        * Your own indecisiveness, or perhaps your own selfish desire to be seen as a hero? Only you know yourself.
                    }
                }
                {not has_survivor?
                    * The dawning silence sticks to the air like a fly to the ointment.
                    {not took_parasites?
                        * Too bad there is no one here to notice your heroic deed.
                        {not player_drunk?
                            {tried_order?
                                * Was it truly heroic if it is your own cowardice that killed everyone?
                            }
                            {not tried_order and monster_in_party?
                                * Was it truly heroic if it is your own indecisiveness that killed everyone?
                            }
                        }
                    }
                    {took_parasites?
                        * You wipe the gunk and viscera off your weapons, already sure you've been infected. 
                    }
                }
            ]],
            OPT_ORDER = "Stay back while others fight the monster",
            DIALOG_ORDER = [[
                left:
                    !exit
                right:
                    !exit
                * You send {1*{2}your ally to fight the monster|the small squad to fight the monster}.
            ]],
            DIALOG_ORDER_SUCCESS = [[
                * You watch your allies beat down on the beast with pipe, pike, and pamphlet alike. 
                * Eventually, the monster goes still, lying on the ground and oozing numerous fluids.
                {people_died?
                    * You take the time to count the newly dead.
                    * {1#agent_list} died during battle.
                }
                player:
                    !left
                agent:
                    !right
                    Phew! That was a tough battle.
                    Good thing we took it down, though.
                    Let's hope we don't have more of these things attacking.
                {know_infected and spawned_from_quest?
                    * [p] You fear that it is not likely going to be the case.
                    * The bog parasites are already here, in the Pearl, and they're spreading.
                    * It's only a matter of time before such incident occurs again.
                }
                    Thanks again.
                    Without you encouraging us, the monster would probably kill us all.
                {monster_in_party and not player_drunk?
                    * Sure, you are the <i>hero</> saving everyone here.
                    * Never mind the fact that it is your own indecisiveness that puts everyone in danger in the first place.
                    * Your own indecisiveness, or perhaps your own selfish desire to be seen as a hero? Only you know yourself.
                }
            ]],
            DIALOG_ORDER_FAILURE = [[
                * You've sent them to a meat grinder. 
                * One by one, the beast put each of them down, leaving you the only one left to fight it.
                player:
                    !left
                    !scared
                * You watch from your spot in the gore soaked road, as it looks up at you, dripping blood from it's jaw.
            ]],
            OPT_RUN_AWAY = "Run away from the scene",
            DIALOG_RUN_AWAY = [[
                * You put as much distance as you can between you and the monster, and then some. 
                {tried_order?
                    * A deep feeling of shame blooms in your chest as you think of the people who died following your hasty orders.
                }
                * [p] To save your own skin, you decided to run away.
                * You don't want to imagine what happens to the people left behind.
                * You hope that the monster gets taken down, and such attack does not happen again.
                {know_infected and spawned_from_quest?
                    * But deep down, you fear that you aren't so lucky.
                    * You've seen the bog parasites first hand, and they're spreading fast.
                }
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt.player:Remember("CROWD_SAW_BOG_MONSTER")
                cxt.enc.scratch.crowd_people = {}
                table.insert(cxt.enc.scratch.crowd_people, AgentUtil.GetFreeAgent(table.arraypick(CROWD_FOREMAN)))
                for i, id in ipairs(table.multipick(CROWD_MEMBER, 2)) do
                    local agent = AgentUtil.GetFreeAgent(id)
                    table.insert(cxt.enc.scratch.crowd_people, agent)
                end
                cxt:TalkTo(cxt.enc.scratch.crowd_people[1])
            end
            local convince_crowd = shallowcopy( cxt.enc.scratch.crowd_people )
            table.insert(convince_crowd, 1, false) -- Because ally grab specifically ignores the first element
            cxt:Opt("OPT_GATHER")
                :Dialog("DIALOG_GATHER")
                :Negotiation{
                    flags = NEGOTIATION_FLAGS.ALLY_GRAB | NEGOTIATION_FLAGS.NO_CORE_RESOLVE,
                    fight_allies = convince_crowd,
                    reason_txt = cxt:GetLocString("NEGOTIATION_REASON")
                }
                    :OnFailure()
                        :Dialog("DIALOG_GATHER_FAILURE")
                    :OnSuccess()
                        :Fn(function(cxt, minigame)
                            cxt.enc.scratch.fight_allies = {}
                            for i, modifier in minigame:GetPlayerNegotiator():Modifiers() do
                                if modifier.id == "FIGHT_ALLY_WON" and modifier.ally_agent then
                                    table.insert_unique( cxt.enc.scratch.fight_allies, modifier.ally_agent )
                                end
                            end
                            if #cxt.enc.scratch.fight_allies > 0 then
                                cxt:Dialog("DIALOG_GATHER_SUCCESS")
                            else
                                cxt:Dialog("DIALOG_GATHER_FAILURE")
                            end
                        end)
            cxt:Opt("OPT_ATTACK")
                :Dialog("DIALOG_ATTACK")
                :Fn(function(cxt)
                    cxt.quest.param.took_parasites = nil
                end)
                :Battle{
                    allies = cxt.enc.scratch.fight_allies,
                    enemies = {"beast"},
                    flags = BATTLE_FLAGS.SELF_DEFENCE | BATTLE_FLAGS.BOSS_FIGHT,
                    on_runaway = function( cxt, battle )
                        cxt.quest:Complete()
                        cxt:Dialog("DIALOG_RUN_AWAY")
                        DemocracyUtil.TryMainQuestFn("DeltaSupport", -3)
                        if not cxt:GetCastMember("beast"):IsRetired() then
                            for i, agent in ipairs(cxt.enc.scratch.crowd_people) do
                                if not agent:IsRetired() then
                                    agent:Kill()
                                end
                            end
                            cxt:GetCastMember("beast"):Retire()
                        end
                        StateGraphUtil.DoRunAwayEffects( cxt, battle )
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                }:OnWin()
                    :Fn(function(cxt)
                        for i, agent in ipairs(cxt.enc.scratch.crowd_people) do
                            if not agent:IsRetired() then
                                cxt:TalkTo(agent)
                                cxt.enc.scratch.has_survivor = true
                                break
                            end
                        end
                    end)
                    :Dialog("DIALOG_ATTACK_WIN")
                    :Fn(function(cxt)
                        cxt:Wait()
                        for i, agent in ipairs(cxt.enc.scratch.crowd_people) do
                            if not agent:IsRetired() then
                                agent:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("saved"))
                            end
                        end
                        cxt.quest:Complete()
                    end)
                    :Travel()
            if cxt.enc.scratch.fight_allies and #cxt.enc.scratch.fight_allies > 0 then
                cxt:Opt("OPT_ORDER")
                    :Dialog("DIALOG_ORDER", #cxt.enc.scratch.fight_allies, cxt.enc.scratch.fight_allies[1])
                    :Fn(function(cxt)
                        local dead_people
                        cxt.enc.scratch.fight_allies, dead_people = SimulateBeastFight(cxt:GetCastMember("beast"), cxt.enc.scratch.fight_allies)
                        if #cxt.enc.scratch.fight_allies > 0 then
                            cxt.enc.scratch.people_died = #dead_people > 0
                            cxt:TalkTo(cxt.enc.scratch.fight_allies[1])
                            cxt:Dialog("DIALOG_ORDER_SUCCESS", dead_people)
                            cxt:Wait()
                            for i, agent in ipairs(cxt.enc.scratch.crowd_people) do
                                if not agent:IsRetired() then
                                    agent:OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("saved"))
                                end
                            end
                            cxt.quest:Complete()
                            StateGraphUtil.AddLeaveLocation(cxt)
                        else
                            cxt.enc.scratch.tried_order = true
                            cxt:Dialog("DIALOG_ORDER_FAILURE", dead_people)
                        end
                    end)
            end
            cxt:Opt("OPT_RUN_AWAY")
                :Dialog("DIALOG_RUN_AWAY")
                :DeltaSupport(-3)
                :Fn(function(cxt)
                    if cxt.enc.scratch.fight_allies and #cxt.enc.scratch.fight_allies > 0 then
                        cxt.enc.scratch.fight_allies = SimulateBeastFight(cxt:GetCastMember("beast"), cxt.enc.scratch.fight_allies)
                    end
                    if not cxt:GetCastMember("beast"):IsRetired() then
                        for i, agent in ipairs(cxt.enc.scratch.crowd_people) do
                            if not agent:IsRetired() then
                                agent:Kill()
                            end
                        end
                        cxt:GetCastMember("beast"):Retire()
                    end
                    cxt.quest:Complete()
                end)
                :Travel()
        end)
