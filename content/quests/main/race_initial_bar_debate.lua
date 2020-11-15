
local HECKLER_ID = {
    LABORER = {"LABORER_BAD_OPINION", "GENERIC_BAD_OPINION"},
    HEAVY_LABORER = {"LABORER_BAD_OPINION", "GENERIC_BAD_OPINION"},
    WEALTHY_MERCHANT = {"WEALTHY_BAD_OPINION", "BROKER_BAD_OPINION"},
    ADMIRALTY_GOON = {"AUTHORITY_BAD_OPINION", "WORSHIPPER_BAD_OPINION"},
    BANDIT_GOON = {"UNLAWFUL_BAD_OPINION", "GENERIC_BAD_OPINION", "BROKER_BAD_OPINION"},
    SPARK_BARON_GOON = {"WEALTHY_BAD_OPINION", "AUTHORITY_BAD_OPINION"},
    JAKES_RUNNER = {"UNLAWFUL_BAD_OPINION", "BROKER_BAD_OPINION"},
    RISE_REBEL = {"LABORER_BAD_OPINION", "UNLAWFUL_BAD_OPINION"},
    LUMINARI = {"WORSHIPPER_BAD_OPINION", "BROKER_BAD_OPINION"},
    -- BOG_BURR_BOSS = {"CRYPTIC_BAD_OPINION"},
}
local insult_card = "insult"

local BONUSES = {
    function(cxt, idx)
        return cxt:Opt( "OFFER_BATTLE_UPGRADE" ):PreIcon( global_images.upgradecombat )
            -- :Quip( cxt:GetAgent(), "chum_bonus", "battle" )
            :Fn( function( cxt )
                cxt:Wait()

                AgentUtil.UpgradeBattleCard( function( card )
                    cxt.enc:ResumeEncounter( card )
                end )
                
                local card = cxt.enc:YieldEncounter()
                if card then
                    -- cxt:Pop()
                    cxt.enc.scratch.chum_got[idx] = true
                end
            end )
    end,
    function(cxt, idx)
        return cxt:Opt( "OFFER_COMPRESSION_GEAR" )
            :PreIcon( global_images.health )
            :PostText( "OFFER_UPGRADE_HEALTH", 10 )
            -- :PostText( "OFFER_UPGRADE_RESOLVE", 2 )
            -- :Quip( cxt:GetAgent(), "chum_bonus", "compression_gear" )
            :Fn( function( cxt )
                cxt.caravan:UpgradeHealth( 10 )
                -- cxt.caravan:UpgradeResolve( 2 )
                cxt.enc.scratch.chum_got[idx] = true
            end )
    end,
    function(cxt, idx)
        return cxt:Opt( "OFFER_BATTLE_DRAFT", 2 )
            :PreIcon( global_images.buycombat )
            -- :Quip( cxt:GetAgent(), "chum_bonus", "battle" )
            :Fn( function( cxt )
                cxt:Wait()

                for i = 1, 2 do
                    local draft_popup = Screen.DraftChoicePopup()
                    local function OnDone()
                        cxt.encounter:ResumeEncounter()
                    end
                    local cards = RewardUtil.GetBattleCards( 1, 3, cxt.player )
                    draft_popup:DraftCards( cxt.player, Battle.Card, cards, OnDone )
                    TheGame:FE():InsertScreen( draft_popup )

                    cxt.enc:YieldEncounter()
                end
                cxt.enc.scratch.chum_got[idx] = true
            end )
    end,
    function(cxt, idx)
        local function IsGrenade( def )
            return CheckBits(def.item_tags or 0, ITEM_TAGS.GRENADE)
        end

        local cards = {}
        for i = 1, 2 do
            local def = BattleCardCollection.AllLocalItems( IsGrenade ):Pick(1)[1]
            if def then
                table.insert( cards, def.id )
            end
        end

        return cxt:Opt( "OFFER_BOOM_BOX", cards )
            :PreIcon( global_images.giving )
            -- :Quip( cxt:GetAgent(), "chum_bonus", "boom_box" )
            :GainCards(cards)
            :Fn(function(cxt)
                cxt.enc.scratch.chum_got[idx] = true
            end)
    end,
    function(cxt, idx)
        return cxt:Opt( "OFFER_TRIAGE_KIT", "healing_vapors" )
            :PreIcon( global_images.giving )
            -- :Quip( cxt:GetAgent(), "chum_bonus", "triage_kit" )
            :GainCards{"healing_vapors", "healing_vapors"}
            :Fn(function(cxt)
                cxt.enc.scratch.chum_got[idx] = true
            end)
    end,
    function(cxt, idx)
        local owner = TheGame:GetGameState():GetPlayerAgent()
        local collection = GraftCollection.Rewardable(owner):Rarity(CARD_RARITY.COMMON)
            :Filter(function(graft_def) return graft_def.type == GRAFT_TYPE.COMBAT end)
        local grafts = collection:Generate(1)

        return cxt:Opt("OFFER_TRINKET_GRAFT", grafts[1])
            :PreIcon(global_images.graft)
            :Fn(function(cxt)
                ConvoUtil.GiveGraft(cxt, grafts[1])

                -- local popup = Screen.PickGraftScreen(grafts, false, function(...) cxt.enc:ResumeEncounter(...) end)
                -- TheGame:FE():InsertScreen( popup )
                -- local chosen_graft = cxt.enc:YieldEncounter()
                -- if chosen_graft then
                --     cxt:Dialog("DIALOG_PLAYER_INSTALL_GRAFT", chosen_graft)
                --     return chosen_graft
                -- end
                cxt.enc.scratch.chum_got[idx] = true
            end)
    end,
}
local QDEF = QuestDef.Define
{
    title = "Drunk Politics",
    desc = "Your first taste of political debate is at {noodle_shop}, where people have many divisive opinions.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/bar_debate.png"),

    qtype = QTYPE.STORY,
    collect_agent_locations = function(quest, t)
        -- if quest:IsActive("contact_informant") or quest:IsActive("extract_informant") then
        table.insert (t, { agent = quest:GetCastMember("heckler"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.PATRON } )
        -- end
    end,
}

:AddObjective{
    id = "win_argument",
    title = "Win This Argument",
    desc = "Convince {heckler} that {heckler.hisher} opinion is trash.",
    state = QSTATUS.ACTIVE,
}
:AddLocationCast{
    cast_id = "noodle_shop",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("MURDERBAY_NOODLE_SHOP"))
    end,
}
:AddCast{
    cast_id = "heckler",
    cast_fn = function(quest, t)
        table.insert(t, quest:CreateSkinnedAgent(table.arraypick(copykeys(HECKLER_ID))))
    end,
    no_validation = true,
}
QDEF:AddConvo("win_argument")
    :Confront(function(cxt)
        if TheGame:GetLocalSettings().FAST_STARTUP then
            cxt.quest:Complete()
        else
            return "STATE_START"
        end
    end)
    :State("STATE_START")
        :Loc{
            GENERIC_BAD_OPINION = [[
                Everyone here all suck!
                Wake up sheeple!
                You all have no idea behind the big picture!
                Don't listen to what they tell you!
            ]],
            LABORER_BAD_OPINION = [[
                The laborers have been oppressed for so long!
                Time to fight back, people!
                !throatcut
                Kill all those who exploit the fruit of our labor!
                Grifters, switches, cultists, barons, bandits, they are all the same!
                They don't deserve to live!
            ]],
            WEALTHY_BAD_OPINION = [[
                You all should be working, not gorging yourselves on fine dining!
                !angry_accuse
                If you had worked harder, you wouldn't have been in so much debt!
                It's all your fault if you're indebted.
                Just pull yourselves up by your bootstraps! What's so hard about that?
            ]],
            AUTHORITY_BAD_OPINION = [[
                You keep complaining about us arresting you, but have you considered not committing crimes?
                The law isn't that hard to follow, is it?
                !angry_shrug
                Of course all of our actions are lawful.
                What do you mean we can't do whatever we want just because we have the authority?
                We are the law!
            ]],
            UNLAWFUL_BAD_OPINION = [[
                The authority is too corrupt! And they always will be!
                !angry_accuse
                Let's get rid of authority altogether!
                No more laws, everyone can do whatever the Hesh they want!
                The society is better off if it is in complete anarchy!
            ]],
            WORSHIPPER_BAD_OPINION = [[
                !hesh_greeting
                All shall tremble before the mighty Hesh!
                Believe in Hesh, and your life will be happy and propserous!
                Disregard Hesh, and your life will be filled with misery!
                We must devote every hour of our life to Hesh!
                All heretics must be executed!
            ]],
            BROKER_BAD_OPINION = [[
                What do you mean debt breaking should be illegal?
                It's perfectly fine if you agreed to it!
                !angry_shrug
                Can't pay it back? Just don't borrow money!
                You should've known the consequences before you agree to do anything!
            ]],
            CRYPTIC_BAD_OPINION = [[
                MũSt cŌnSųMe
                I ŕEqŮiRe ThÍnE sAcRïFicË
                cŌmE Tŏ mE, mØrTaĽ
                
            ]],

            DIALOG_INTRO_BG = [[
                * You arrive at the first shop you see in the Pearl.
                player:
                    !left
                * The past few days on the road has been rough, but it was all worth it in the end.
                * You've got some shills under your name, and maybe you've learned a few moves or two.
            ]],

            DIALOG_INTRO = [[
                * Hopefully you can find some work here, and maybe even find a place to live in.
                * Just as you start to get comfortable, you hear a rather loud patron causing a commotion at the bar.
                agent:
                    !right
                    !angry
                
            ]],
            DIALOG_INTRO_PST = [[
                * You feel like it's your moral obligation to correct {agent.hisher} opinion.
            ]],
            OPT_DEBATE = [[Make {agent} stop]],
            TT_DEBATE = "You will start with some {1#card} in your deck.",
            DIALOG_DEBATE = [[
                player:
                    !left
                    {agent.gender:Sir|Ma'am|Excuse me}, this is a Wendy's.
                agent:
                    !dubious
                    Uhh, no? This is the Slurping Snail.
                player:
                    That's not the point.
                    !cruel
                    The point is how wrong and stupid your opinion is.
            ]],
            DIALOG_DEBATE_WIN = [[
                player:
                    And that's why your opinion is stupid.
                    You sound like a baby having a tantrum problem.
                    Your idea's are too out of touch with reality.
                    Many people are suffering, and you choose to spout useless drivel in the middle of a restaurant?
                agent:
                    ...
                    !sigh
                    Alas, you're right. My opinion is too extreme.
                    That's the nature of ideas, isn't it?
                    If you don't speak out about it, the society won't change.
                    !exit
                * {agent} left the shop. You hope that {agent} actually learned {agent.hisher} lesson, and not just finding trouble at another shop.
            ]],
            DIALOG_DEBATE_LOST = [[
                player:
                    Your opinion is stupid.
                agent:
                    And yet, you haven't provided an alternate opinion.
                    Seriously? You just said "your opinion is stupid" the entire time.
                    It's because people like you, who can't think for themselves, that there are so many problems in Havaria.
                * Utterly humiliated, you return to your bowl and drink, covering your face from the entire bar of people laughing at you.
                * Wow, that was an utter failure.
                * You are never able to recover from that failure.
                * You can never gather enough resolve to pursue politics.
                * Seriously, you suck at this game. This is the first negotiation, and you already failed.
                * Full resolve, WEAKEST ENEMY.
                * Just...start a new run already. This time maybe watch the tutorial beforehand.
            ]],

            OPT_IGNORE = [[Ignore {agent.himher}. {agent.HeShe} isn't worth your time.]],
            DIALOG_IGNORE = [[
                * You leave {agent} be.
                * You are never the one that are interested in politics.
                * Then why did you select this mode, then?
                * For the sheer novelty of it?
                * Well, good job. You failed, ya dingus.
            ]],
        }
        :Fn(function(cxt)
            if cxt:FirstLoop() then
                cxt:Dialog("DIALOG_INTRO_BG")
                cxt.enc.scratch.chum_got = {}
                local chum_options = table.multipick(BONUSES, 3)
                cxt:RunLoop(function(cxt)
                    local has_chum = false
                    for i, fn in ipairs(chum_options) do
                        if not cxt.enc.scratch.chum_got[i] then
                            fn(cxt, i)
                            has_chum = true
                        end
                    end
                    if has_chum then
                        cxt:Opt("OPT_SKIP_BONUS")
                            :MakeUnder()
                            :Pop()
                    else
                        cxt:Pop()
                    end
                end)
                cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("heckler"))
                local primaryCastID = cxt.enc:GetPrimaryCast().id
                cxt:Dialog("DIALOG_INTRO")
                cxt:Dialog(HECKLER_ID[primaryCastID] and table.arraypick(HECKLER_ID[primaryCastID]) or "GENERIC_BAD_OPINION")
                cxt:Dialog("DIALOG_INTRO_PST")
            end
            cxt:Opt("OPT_DEBATE")
                :PostText("TT_DEBATE", insult_card)
                :PostCard(insult_card, true)
                :Dialog("DIALOG_DEBATE")
                :Negotiation{
                    on_start_negotiation = function(minigame)
                        local n = math.max(1, math.round( minigame.player_negotiator.agent.negotiator:GetCardCount() / 5 ))
                        for k = 1, n do
                            local card = Negotiation.Card( "insult", minigame.player_negotiator.agent )
                            card.show_dealt = true
                            card:TransferCard(minigame:GetDrawDeck())
                        end
                    end,
                    on_success = function(cxt) 
                        cxt:Dialog("DIALOG_DEBATE_WIN")
                        cxt.quest:GetCastMember("heckler"):OpinionEvent(OPINION.INSULT)
                        cxt.enc:GetPrimaryCast():GetBrain():MoveToHome()
                        -- cxt:GoTo("STATE_PICK_SIDE")
                        cxt:GoTo("STATE_DEVELOP_IDEA")
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_DEBATE_LOST")
                        DemocracyUtil.AddAutofail(cxt, false)
                    end,
                }

            cxt:Opt("OPT_IGNORE")
                :Dialog("DIALOG_IGNORE")
                :Fn(function(cxt)
                    DemocracyUtil.AddAutofail(cxt, function(cxt)
                        print("you ran?")
                        cxt:GoTo("STATE_DEVELOP_IDEA") end)
                end)
        end)
    :State("STATE_DEVELOP_IDEA")
        :Loc{
            DIALOG_INTRO = [[
                * You considered the encounter you had with {heckler}.
                player:
                    !thought
                    Wow, I can't believe how good I am at political debates.
                    Maybe I should use my power for good.
                    Like running for the president.
                * Wait...is there ANY democracy in Havaria?
                * Let's just say there is one.
                * Do you really want a lore justification?
                * Let's just say that the people in power decide to let the people vote for a president instead of constantly fighting for power.
                player:
                    Now, if I were to run for president, first I need to establish myself in the political world.
                    I need to let people know that I'm running for president.
                    And I also have to gain support while doing so.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Complete()
        end)
