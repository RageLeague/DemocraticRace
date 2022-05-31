local SNAIL_COUNT = 3

local TRAITS = {
    CHAMPION = {
        bets_min = 1500,
        bets_max = 2500,
        win = "CHAMPION",
        lose = "CHAMPION_BLUNDER",
    },
    NEWCOMER = {
        bets_min = 1000,
        bets_max = 2000,
        win = "CHAMPION",
    },
    UNDERDOG_GOOD = {
        bets_min = 1000,
        bets_max = 2000,
        win = "NEWCOMER",
    },
    UNDERDOG = {
        bets_min = 500,
        bets_max = 1500,
        win = "NEWCOMER",
    },
    CHAMPION_BLUNDER = {
        bets_min = 1000,
        bets_max = 2000,
        win = "CHAMPION",
    },
    SMITH = {
        bets_min = 500,
        bets_max = 1500,
        win = "UNDERDOG_GOOD",
    },
}

local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,

    GenerateSnails = function(quest)
        quest.param.snails = quest.param.snails or {}
        quest.param.snail_traits = quest.param.snail_traits or {}
        for i = 1, SNAIL_COUNT do
            if not quest.param.snails[i] or quest.param.snails[i]:IsRetired() then
                -- Generate a snail
                quest.param.snails[i] = quest:CreateSkinnedAgent("RACING_SNAIL")
                quest.param.snails[i]:GenerateRandomName()
                quest.param.snails[i]:AddTag("NO_AUTO_CULL")

                local trait
                -- Make sure the trait is different from all the traits the oshnus already have, to increase variety in dialog.
                while not trait or table.arraycontains(quest.param.snail_traits, trait) do
                    trait = table.arraypick(copykeys(TRAITS))
                end
                quest.param.snail_traits[i] = trait
            end
        end
    end,

    RetireSnail = function(quest, snail)
        quest.param.retired_snails = quest.param.retired_snails or {}
        quest.param.snails[snail]:Retire()
        table.insert(quest.param.retired_snails, quest.param.snails[snail])
        quest.param.snails[snail] = nil
    end,
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}
:AddLocationCast{
    cast_id = "oshnudrome",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("PEARL_OSHNUDROME"))
    end,
}

QDEF:AddConvo()
    :Loc{
        OPT_WATCH_RACES = "Watch the oshnu races",
        TT_WATCH_RACES = "Watching oshnu races will cause time to pass, but will restore some resolve.",
        REQ_WATCHED = "You already watched the race. Come back later for another one.",
    }
    :Hub(function(cxt, who)
        if who and cxt.location == cxt:GetCastMember("oshnudrome") and cxt.location:GetProprietor() == who then
            cxt:Opt("OPT_WATCH_RACES")
                :PostText("TT_WATCH_RACES")
                :RequireFreeTimeAction(2)
                :ReqCondition(not cxt.location:HasMemory("WATCHED_RACES"), "REQ_WATCHED")
                :Fn(function(cxt)
                    cxt.location:Remember("WATCHED_RACES")
                end)
                :GoTo("STATE_GAME")
        end
    end)
    :State("STATE_GAME")
        :Loc{
            --Moving the player and agent out of frame until needed.
            DIALOG_INTRO = [[
                player:
                    !exit
                agent:
                    !exit
                * You find the nearest empty seat and survey the competitors saddling up to the starting line.
            ]],
            DIALOG_INTRO_CHAMPION = [[
                * There is {1#agent}, a long time champion, and many in the audience is rooting for {1.himher}.
            ]],
            DIALOG_INTRO_NEWCOMER = [[
                * {1#agent}, although a newcomer, has already won a few races before, and many in the audience hope that {1.heshe} wins again.
            ]],
            DIALOG_INTRO_UNDERDOG_GOOD = [[
                * {1#agent} may not have a history as impressive as the other oshnus, but {1.heshe} has shocked everyone with {1.hisher} performance in recent races.
                * Perhaps {1.heshe} can pull off the same stunt as the previous race.
            ]],
            DIALOG_INTRO_UNDERDOG = [[
                * {1#agent} is a newcomer eager to make a name for {1.himher}self. You can see {1.hisher} zeal from up here in the gallery.
            ]],
            DIALOG_INTRO_CHAMPION_BLUNDER = [[
                * {1#agent} may have been a long time champion, but {1.hisher} recent performances has left much to be desired. Many hope that it was just a blunder, rather than a repeated pattern.
            ]],
            DIALOG_INTRO_SMITH = [[
                * {1#agent} is rumored to descent from a long line of oshnu race champions, but {1.hisher} background has yet to pay off in an actual race.
                {player_smith?
                    * You felt an odd kinship with this particular oshnu.
                }
                {not player_smith?
                    * This might finally be the race where {1#agent} shines.
                }
            ]],

        }
        :Fn(function(cxt)
            cxt.quest:DefFn("GenerateSnails")
            cxt:Dialog("DIALOG_INTRO")
            for i, snail in ipairs(cxt.quest.param.snails) do
                cxt:Dialog("DIALOG_INTRO_" .. cxt.quest.param.snail_traits[i], snail)
                --assigning them a role just so they can be used in the quips later.
                cxt:ReassignCastMember("snail" .. i, snail)
            end
            cxt:GoTo("STATE_BET")
        end)
    :State("STATE_BET")
        :Loc{
            DIALOG_BETTING = [[
                * Before you get too comfy, you hear the bookie for this race calling for bets.
                * You could throw some money on the line, if you're feeling confident. 
            ]],
            OPT_NO_BET = "Don't bet on anyone",
            DIALOG_NO_BET = [[
                * You stay firmly in your seat, your cash more worth holding on to than gambling away.
            ]],
            OPT_BET = "Bet on {1#agent}",
            TT_ODDS = "Estimated payout: {1}/1",

            DIALOG_BET = [[
                * You throw down your cash, and get a ticket in return. Nothing left to do than sit back.
            ]],

            POPUP_TITLE = "Place a bet",
            POPUP_SUBTITLE = "Enter a positive integer representing the shills you want to bet, up to all the money you have ({1}).",

            CONFIRM_TITLE = "Confirm bet?",
            CONFIRM_DESC = "Betting {1#money} on {2#agent} will cause you to win {3#money} if {2.heshe} wins the race.",

            DIALOG_NO_MONEY = [[
                * You hear the race's bookie calling out for bets, though you only blankly notice it.
                * You're fairly certain they won't take bets in pocket lint and sandwich crumbs.  
            ]],

            POPUP_TITLE_INVALID = "Invalid input",
            POPUP_DESC_INVALID = "Please enter a valid number.",
        }
        :SetLooping()
        :Fn(function(cxt)
            if cxt.caravan:GetMoney() <= 0 then
                cxt:Dialog("DIALOG_NO_MONEY")
                cxt:GoTo("STATE_RACE")
                return
            end
            if cxt:FirstLoop() then
                cxt:Dialog("DIALOG_BETTING")
                cxt.enc.scratch.bet_pool = {}
                cxt.enc.scratch.total_bet = 0
                for i, trait in ipairs(cxt.quest.param.snail_traits) do
                    cxt.enc.scratch.bet_pool[i] = math.randomGauss( TRAITS[trait].bets_min, TRAITS[trait].bets_max )
                    cxt.enc.scratch.total_bet = cxt.enc.scratch.total_bet + cxt.enc.scratch.bet_pool[i]
                end
            end
            for i, snail in ipairs(cxt.quest.param.snails) do
                cxt:Opt("OPT_BET", snail)
                    :PostText("TT_ODDS", string.format("%.2f", cxt.enc.scratch.total_bet / cxt.enc.scratch.bet_pool[i] - 1))
                    :Fn(function(cxt)
                        UIHelpers.EditString(
                            cxt:GetLocString( "POPUP_TITLE" ),
                            cxt:GetLocString( "POPUP_SUBTITLE", cxt.caravan:GetMoney() ),
                            "",
                            function( val )
                                cxt.enc:ResumeEncounter( val )
                            end )
                        local raw_bet = cxt.enc:YieldEncounter()
                        local bet = raw_bet and tonumber(raw_bet)
                        if bet and bet <= cxt.caravan:GetMoney() and bet > 0 then
                            local win_money = math.ceil((cxt.enc.scratch.total_bet - cxt.enc.scratch.bet_pool[i]) * bet / (bet + cxt.enc.scratch.bet_pool[i]))
                            TheGame:FE():PushScreen( Screen.YesNoPopup( cxt:GetLocString("CONFIRM_TITLE"), cxt:GetLocString("CONFIRM_DESC", bet, snail, win_money), nil ) )
                                :SetFn( function(v)
                                    cxt.enc:ResumeEncounter( v )
                                end )
                            local v = cxt.enc:YieldEncounter()
                            if v == Screen.YesNoPopup.YES then
                                cxt:Dialog("DIALOG_BET", bet, snail)
                                cxt.caravan:PayMoney( bet )
                                cxt.enc.scratch.placed_bet = bet
                                cxt.enc.scratch.placed_bet_snail = snail
                                cxt.enc.scratch.win_money = win_money
                                cxt:GoTo("STATE_RACE")
                            end
                        elseif raw_bet then
                            UIHelpers.InfoPopup( cxt:GetLocString( "POPUP_TITLE_INVALID" ), cxt:GetLocString( "POPUP_DESC_INVALID" ), LOC"UI.DIALOGS.OK" )
                        else
                        end
                    end)
            end
            cxt:Opt("OPT_NO_BET")
                :Dialog("DIALOG_NO_BET")
                :GoTo("STATE_RACE")
        end)
    :State("STATE_RACE")
        :Quips{
            {
                tags = "race_pt1",
                [[
                    agent:
						!clap
                        And there off! This is one exciting race we have!
                        {snail1} pulls ahead, {snail2} in close competition.
                ]],
                [[
                    agent:
						!intrigue
                        The race starts, though it appears {snail3}'s rider is asleep at the reins.
						...
                        Folks, it appears the {snail3} is tired of waiting and is just starting the race themself.
                ]],
                [[
                    agent:
						!angry
                        On your mark, get set-
						!surprised
                        Wait, {snail3} is already speeding ahead of the others!
                        The other racers are quick to catch up though. This cheat didn't earn them that much of a lead. 
                ]],
			},
			{
                tags = "race_pt2",
                [[
                    agent:
                        While we let the racers coast, it's a good time to talk about this Race's sponsor.
						!neutral
                        This race was sponsored by Rai-
                        !point
                        Hold that thought, folks! There's been an upset in the race!
                ]],
                [[
                    agent:
						!eureka
                        {snail1} seems to be falling back, but not out of the race yet!
                        {snail2} is taking that chance, and going ahead-
						!happy
                        Oh, and streaking up to the front is {snail3} by turning on the rocket thrusters!
                ]],
                [[
                    agent:
						!point
                        It appears the race is going steady, except wait!
                        It seems {snail2}'s racer has stopped their snail to eat a sandwich! 
						!intrigue
                        And it looks like they're done, and have lost a surprisingly small amount of distance on the other races.
                ]],
			},
			{
                tags = "race_pt3",
                [[
                    agent:
						!happy
                        All of the snails crossed the finish at the same time! I can't believe it myself, folks!
                        Our referees are determining the victor now...
                        And, by just an eye stalk, the winner is...
                ]],
                [[
                    agent:
						!point
                        {snail3} has the impressive advantage but wait, what's this?
                        !scared
                        {snail3} has seen a bird and is chasing after it! Their rider is corraling them back, but this will cost them.
						!happy
                        It's close, but the winner is crossing the line now, and it's...
                ]],
                [[
                    agent:
                        We're in the home stretch now, and it's still anyone's game!
                        Or it would be, if {snail2}'s rider wasn't racing away last night's drink.
                        !flinch
                        Oh, and it's a snail crash into the wall. That's gonna cost them distance.
						!happy
                        All of them are pulling into the finish line, and the winner is...
                ]],
            },
        }
        :Loc{
            DIALOG_INTRO = [[
                * A flag, a whistle, and the crackle of a microphone signal the start of the race.
                agent:
                    !right
            ]],
            DIALOG_RESULT = [[
                %race_pt1
                %race_pt2
                %race_pt3
                agent:
                    !clap
                    {winner}! Give it up for the snail, everyone!
            ]],
            DIALOG_LOST = [[
                * You become painfully aware of the lightness in your pocket.
                *** The snail you bet on lost! You don't get any money.
            ]],
            DIALOG_WIN = [[
                * You stride over to the booth and turn your ticket into tons of cash.
                *** The snail you bet on won! You got your bet and then some!
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            local weights = {}
            for i, trait in ipairs(cxt.quest.param.snail_traits) do
                weights[i] = TRAITS[trait].bets_min + TRAITS[trait].bets_max
            end
            local winner = weightedpick(weights)
            cxt:ReassignCastMember("winner", cxt.quest.param.snails[winner])
            cxt:Dialog("DIALOG_RESULT")
            if cxt.enc.scratch.placed_bet_snail then
                if cxt.enc.scratch.placed_bet_snail == cxt.quest.param.snails[winner] then
                    cxt:Dialog("DIALOG_WIN")
                    cxt.caravan:AddMoney(cxt.enc.scratch.placed_bet + cxt.enc.scratch.win_money)
                    ConvoUtil.DoResolveDelta(cxt, 15)
                else
                    cxt:Dialog("DIALOG_LOST")
                    ConvoUtil.DoResolveDelta(cxt, 9)
                end
            else
                ConvoUtil.DoResolveDelta(cxt, 12)
            end
            -- Winner's traits gets changed
            cxt.quest.param.snail_traits[winner] = TRAITS[cxt.quest.param.snail_traits[winner]].win or "CHAMPION"
            -- One of the losers gets their traits lowerd
            local loser
            while not loser or loser == winner do
                loser = math.random(1, SNAIL_COUNT)
            end
            cxt.quest.param.snail_traits[loser] = TRAITS[cxt.quest.param.snail_traits[loser]].lose
            -- If no traits, we "retire" the loser
            if not cxt.quest.param.snail_traits[loser] then
                cxt.quest:DefFn("RetireSnail", loser)
            end
            StateGraphUtil.AddEndOption(cxt)
        end)
