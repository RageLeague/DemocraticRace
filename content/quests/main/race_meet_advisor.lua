local OPPO_COUNT = 1
local ADVISOR_ID = {
    "advisor_diplomacy", "advisor_hostile", "advisor_manipulate"
}
local CleanUpFn = function(quest)
    if quest:GetCastMember("primary_advisor"):IsInPlayerParty() then
        quest:GetCastMember("primary_advisor"):Dismiss()
    end
end
local QDEF = QuestDef.Define
{
    title = "A Good Advice",
    desc = "Get an advisor to help you with your campaign.",
    icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/meet_advisor.png"),

    qtype = QTYPE.STORY,

    on_start = function(quest)
        -- Remove the patrons when the quest starts so that the location don't get overfull
        LocationUtil.SendPatronsAway( quest:GetCastMember("noodle_shop") )
    end,
    collect_agent_locations = function(quest, t)
        if quest:IsActive("go_to_bar") or quest:IsActive("choose_advisor") then
            table.insert (t, { agent = quest:GetCastMember("advisor_diplomacy"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.PATRON} )
            table.insert (t, { agent = quest:GetCastMember("advisor_hostile"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.PATRON} )
            table.insert (t, { agent = quest:GetCastMember("advisor_manipulate"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.PATRON} )
        elseif quest:IsActive("discuss_plan") then
            table.insert (t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.PATRON} )
        end

    end,
    on_fail = CleanUpFn,
    on_complete = CleanUpFn,
    on_cancel = CleanUpFn,
}
:AddObjective{
    id = "go_to_bar",
    title = "Visit the noodle shop",
    desc = "It's noon. Time to go to your favorite noodle shop!",
    mark = {"noodle_shop"},
    state = QSTATUS.ACTIVE,

}
:AddObjective{
    id = "choose_advisor",
    title = "Choose an advisor",
    desc = "Choose an advisor for your campaign.",
    mark = {"advisor_diplomacy", "advisor_hostile", "advisor_manipulate"}
}
:AddObjective{
    id = "discuss_plan",
    title = "Discuss a plan",
    desc = "Come up with a plan for the campaign.",
    mark = {"primary_advisor"}
}
:AddObjective{
    id = "visit_office",
    title = "Visit the office",
    desc = "{primary_advisor} told you to visit {primary_advisor.hisher} office. You can stay there for the campaign.",
    mark = {"home"},
    on_activate = function(quest)
        quest:GetCastMember("primary_advisor"):Recruit( PARTY_MEMBER_TYPE.ESCORT )
    end,
}
:AddLocationCast{
    cast_id = "noodle_shop",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("MURDERBAY_NOODLE_SHOP"))
    end,
}
:AddCast{
    cast_id = "primary_advisor",
    when = QWHEN.MANUAL,
    no_validation = true,
}
:AddLocationCast{
    cast_id = "home",
    when = QWHEN.MANUAL,
    cast_fn = function(quest, t)
        table.insert(t, quest:GetCastMember("primary_advisor"):GetHomeLocation())
    end,
}
DemocracyUtil.AddAdvisors(QDEF)

local COMMON_LOC = {
    OPT_QUESTION = "Ask about {agent}'s angle",
    OPT_PICK = "Choose {agent} as your main advisor",
    OPT_LATER = "Later",

    DIALOG_PICK_PST2 = [[
        * Other advisors left, and you're left with {agent}.
    ]],
}

local function GetAdvisorFn(advisor_id, signature_id)
    return function(cxt)
        if cxt:FirstLoop() then
            cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember(advisor_id))
            cxt:Dialog("DIALOG_INTRO")
        end
        cxt:Question("OPT_QUESTION", "DIALOG_QUESTION")
        cxt:Opt("OPT_PICK")
            :PreIcon(global_images.accept)
            :Dialog("DIALOG_PICK")
            :Fn(function(cxt)
                -- Signature card draft
                local cards = DemocracyUtil.GetSignatureCardsDraft(signature_id, 3, cxt.player)
                cxt.enc:OfferCards( cards )
                cxt:Dialog("DIALOG_PICK_PST")

                -- Set chosen advisor
                cxt.quest.param.chosen_advisor = advisor_id
                local not_chosen_advisor = {}
                for i, val in ipairs(ADVISOR_ID) do
                    if val ~= advisor_id then
                        table.insert(not_chosen_advisor, val)
                    end
                end
                cxt.quest.param.bad_advisor = table.arraypick(not_chosen_advisor)

                DemocracyUtil.UpdateAdvisor(cxt:GetAgent(), "NEW_ADVISOR")
                -- TheGame:GetGameState():GetMainQuest():AssignCastMember("primary_advisor", cxt:GetAgent())
                cxt.quest:AssignCastMember("primary_advisor", cxt:GetAgent())

                for i, val in ipairs(not_chosen_advisor) do
                    cxt:Quip(
                        cxt.quest:GetCastMember(val),
                        "reject_advisor",
                        val,
                        val == cxt.quest.param.bad_advisor and "bad_relation" or "good_relation"
                    )
                    if val == cxt.quest.param.bad_advisor then
                        cxt.quest:GetCastMember(val):OpinionEvent(OPINION.DID_NOT_HELP)
                    end
                    cxt.quest:GetCastMember(val):GetBrain():MoveToHome()
                end
                cxt:Dialog("DIALOG_PICK_PST2")
                cxt.quest:Complete("choose_advisor")
                cxt.quest:Activate("discuss_plan")
                StateGraphUtil.AddEndOption(cxt)
            end)
        cxt:Opt("OPT_LATER")
            :PreIcon(global_images.reject)
            :Dialog("DIALOG_LATER")
            :DoneConvo()
    end
end

local function ShowRaceTutorial()
    local screen = TheGame:FE():GetTopScreen()
    TheGame:GetGameProfile():SetHasSeenMessage("democracy_tutorial_support")
    TheGame:FE():InsertScreen( Screen.YesNoPopup(LOC"DEMOCRACY.TUTORIAL.TUTORIAL_SUPPORT_TITLE", LOC"DEMOCRACY.TUTORIAL.TUTORIAL_SUPPORT_BODY", nil, nil, LOC"UI.NEGOTIATION_PANEL.TUTORIAL_NO" ))
        :SetFn(function(v)
            if v == Screen.YesNoPopup.YES then
                local coro = screen:StartCoroutine(function()
                    local advance = false
                    TheGame:FE():PushScreen( Screen.SlideshowScreen( "democracy_tutorial_support", function() advance = true end ):SetAutoAdvance(false) )
                    while not advance do
                        coroutine.yield()
                    end
                end )
            end
        end)
end

QDEF:AddConvo("go_to_bar")
    :Confront(function(cxt)
        if cxt.location == cxt.quest:GetCastMember("noodle_shop") then
            -- Reset patron capacities
            cxt.quest:GetCastMember("noodle_shop"):SetCurrentPatronCapacity()
            LocationUtil.PopulateLocation( cxt.quest:GetCastMember("noodle_shop") )
            if cxt.quest.param.parent_quest.param.recent_job:IsComplete() then
                return "STATE_CONFRONT"
            else
                return "STATE_FAILURE"
            end
        end
    end)
    :State("STATE_FAILURE")
        :Loc{
            DIALOG_INTRO = [[
                * You arrive at the shop.
                * Sitting at a table, you think about your failure of your political rally.
                * Perhaps you aren't fit for the job. Perhaps you are never meant to be a leader.
                * As your noodle order come in, you chow it down quickly, swallowing your failure and shame.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            DemocracyUtil.AddAutofail(cxt, function() cxt:GoTo("STATE_CONFRONT") end)
        end)
    :State("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * You walk into the restaurant.
                * You see a person walking up to you.
                player:
                    !left
                advisor_diplomacy:
                    !right
                    !permit
                    How do you do, fellow grifter?
                    I've heard you were running for leadership.
                player:
                    Yeah, that's me. What do you want?
                advisor_diplomacy:
                    I can offer you my help.
                    !thumb
                    If you even want to think about winning, you need my Speech 100 skills.
                    So what do you sa-
                * One of the other patrons shoves {advisor_diplomacy} aside.
                advisor_hostile:
                    !right
                    Listen, if you want to win, you have to pick me.
                    'Cause nobody knows how to run a campaign better than me.
                    I can help you win. Win bigly. Win tremendously.
                * {advisor_diplomacy} recovers from the shock, and it's not long before {advisor_diplomacy.himher} and {advisor_hostile} start arguing.
                * You feel a light tap on your back, and turn around to see {advisor_manipulate}.
                advisor_manipulate:
                    !right
                    You see these two clowns. Do you REALLY want them to help you run your campaign?
                    Let's say, hypothetically, you wanna win, right?
                    So if you wanna win, you need to have a competent advisor, someone who can own these idiots with FACTS and LOGIC.
                    And let's say hypothetically, I am that person. Which means that you need me to help you campaign.
                player:
                    What kind of logic-
                advisor_hostile:
                    !right
                    !angry_accuse
                    Don't listen to that Boasting {advisor_manipulate}!
                advisor_manipulate:
                    !left
                    !dubious
                    You came up with a name for me already?
                advisor_diplomacy:
                    !right
                    !sigh
                    Bunch of normies.
                player:
                    !left
                    Can any of you explain what's happening?
                advisor_hostile:
                    !right
                    Look, you pick one of us to be your advisor.
                advisor_manipulate:
                    !right
                    Factually and logically speaking, I'm the best choice for you.
                advisor_diplomacy:
                    !right
                    Take your time, this isn't a decision to take lightly.
            ]]
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Complete("go_to_bar")
            cxt.quest:Activate("choose_advisor")
            StateGraphUtil.AddEndOption(cxt)
        end)
QDEF:AddConvo("choose_advisor", "advisor_diplomacy")
    :AttractState("STATE_TALK")
        :Loc(COMMON_LOC)
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    Are you ready to make a decision yet, my fellow grifter?
            ]],
            DIALOG_QUESTION = [[
                player:
                    !neutral
                    Why should I pick you and not anyone else?
                agent:
                    !handwave
                    Look, I'm a people's person.
                    With my Charisma 100, I can convince anyone of anything.
                    !nod
                    And if you choose me, I can show you the way.
                player:
                    !dubious
                    That doesn't sound very convincing.
                agent:
                    !crossed
                    Look, if you don't want a based people person's help, why did you even ask in the first place?
                player:
                    !placate
                    That's not what I mean.
                agent:
                    Besides, you want a based person as your advisor.
                    Someone who is not motivated by cringe normie things like money. Someone who has a goal beyond a common grift.
                player:
                    That... Sure is an interesting point.
                ** {agent} will provide more diplomatic cards in {agent.hisher} card shop, is what {agent.gender:he's|she's|they're} saying.
            ]],
            DIALOG_PICK = [[
                player:
                    !agree
                    I guess you can be my advisor.
                agent:
                    !happy
                    Sweet!
                    That is a wholesome 100 moment.
                    !give
                    As promised, I will show you the way of the based.
            ]],
            DIALOG_PICK_PST = [[
                player:
                    !take
                    Not sure what that means, but I'll take it.
            ]],
            DIALOG_LATER = [[
                player:
                    I need to think about it for a bit longer.
                agent:
                    Alright.
                    But you know there is only one person who can get you to where you want.
            ]],
        }
        :SetLooping()
        :Fn(GetAdvisorFn("advisor_diplomacy", "ADVISOR_DIPLOMACY"))
QDEF:AddConvo("choose_advisor", "advisor_hostile")
    :AttractState("STATE_TALK")
        :Loc(COMMON_LOC)
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    Nobody knows debating better than me.
                    So you better pick me as your advisor. You don't want to miss this opportunity.
            ]],
            DIALOG_QUESTION = [[
                player:
                    Why should I pick you and not anyone else?
                agent:
                    I already told you.
                    !thumb
                    Nobody knows political campaigns better than me, so I'm your best option.
                player:
                    Really? I find that hard to believe.
                agent:
                    You're wrong.
                player:
                    Excuse me?
                agent:
                    I am the best advisor I know. The best advisor you would ever meet.
                    Of course, you would never reach my level. Which is why I can help you improve.
                player:
                    Well, I appreciate your confidence at least.
                agent:
                    Ha! Confidence comes naturally when you are competent like me.
                ** {agent} will provide more hostile cards in {agent.hisher} card shop, is what {agent.gender:he's|she's|they're} saying.
            ]],

            DIALOG_PICK = [[
                player:
                    I guess I'll pick you.
                agent:
                    Glad you made the correct choice.
                    Nobody knows debating more than me, so let me give you some free pointers.
            ]],
            DIALOG_PICK_PST = [[
                player:
                    !take
                    If you say so.
            ]],
            DIALOG_LATER = [[
                player:
                    Let me think.
                agent:
                    Do you not want to win?
            ]],
        }
        :SetLooping()
        :Fn(GetAdvisorFn("advisor_hostile", "ADVISOR_HOSTILE"))
QDEF:AddConvo("choose_advisor", "advisor_manipulate")
    :AttractState("STATE_TALK")
        :Loc(COMMON_LOC)
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    Have you made up your mind?
                    If you are logical, there is only one person to choose from.
            ]],
            DIALOG_QUESTION = [[
                player:
                    Why should I pick you and not anyone else?
                agent:
                    Because factually speaking, I'm your best choice.
                    The reason for that is logical:
                    If you have facts and logic on your side, you will always win.
                    Since I am so good at logic and facts, I'm your best choice.
                player:
                    What if facts and logic isn't on my side? Will you still help me?
                agent:
                    If facts and logic isn't on your side, it's your problem, not mine.
                    Make sure your objective aligns with facts and logic, or make facts and logic align with your objective, whichever is easier.
                    Logically, if you choose me as your advisor, I can help you with that.
                ** {agent} will provide more manipulative cards in {agent.hisher} card shop, is what {agent.gender:he's|she's|they're} saying.
            ]],

            DIALOG_PICK = [[
                player:
                    I'll choose you.
                agent:
                    Glad you can think logically.
                    As promised, I will teach you how to argue based on FACTS and LOGIC.
            ]],
            DIALOG_PICK_PST = [[
                player:
                    !take
                    These sounds less "logical" and more "manipulative".
                agent:
                    Please, logic is basically the manipulation of facts to get them on your side.
            ]],

            DIALOG_LATER = [[
                player:
                    Don't hassle me.
                agent:
                    Not everyone can understand logic instantly. Take your time to figure out the logical course of action.
            ]],
        }
        :SetLooping()
        :Fn(GetAdvisorFn("advisor_manipulate", "ADVISOR_MANIPULATE"))
QDEF:AddConvo("discuss_plan", "primary_advisor")
    :AttractState("STATE_TALK")
        :Loc{
            DIALOG_INTRO = [[
                {advisor_diplomacy?
                    agent:
                        You are running for leadership, yes?
                    player:
                        Yes, that's me.
                    agent:
                        A based objective, indeed.
                    player:
                        !dubious
                        Is... that a good thing?
                    agent:
                        Oh, yes. You want to be based, of course.
                        And from what I've seen, you really are based.
                        Your words certainly reached the normies, I can tell.
                    player:
                        That... sounds good?
                }
                {advisor_manipulate?
                    agent:
                        So, am I right to conclude that you are running for leadership?
                    player:
                        You don't need to conclude anything, but yes.
                    agent:
                        So, having established that, we can assume that you need strong logical skills in order to convince the masses.
                        From what I've see in the morning, you certainly have strong rhetorical skills. The masses are convinced by your facts and logic.
                        I'm sure that my husband, who is a doctor, can agree as well.
                        !<unlock_agent_info;ADVISOR_MANIPULATE;lore_husband>
                    player:
                        Thanks, I guess.
                        Not sure if the last remark is necessary, but thanks anyway.
                }
                {advisor_hostile?
                    agent:
                        So, you must be running for leadership?
                    player:
                        Yes, that's me.
                    agent:
                        Good stuff.
                        I saw what you did earlier. Good stuff. Tremendous stuff.
                        Of course, nobody knows debate better than me, but you come very close.
                    player:
                        I'm never getting a compliment better than this, am I?
                }
                {not (advisor_diplomacy or advisor_manipulate or advisor_hostile)?
                    agent:
                        I saw what you did this morning.
                        You have a way with your words, I'll give you that.
                    player:
                        Really? Thanks.
                }
                agent:
                    Well, I didn't offer to become your advisor because I want to compliment you.
                    There are many things I want to talk about with you.
                    Do you have any idea how to campaign?
            ]],
            OPT_YES = "Yes",
            REQ_PLAYED_ONCE = "Don't lie to me. You have no idea what you're doing.",
            OPT_NO = "No",
            DIALOG_YES = [[
                player:
                    Yes, actually.
                    I think I was a politician in a past life.
                {advisor_manipulate?
                    agent:
                        Well, in that case, logically speaking, I don't need to go over the tedious explanation.
                    player:
                        Wait, aren't you even going to question if I am joking or not?
                    agent:
                        Wait, you're joking?
                    player:
                        Well... No, but I would expect you to at least question it.
                        Just... forget it.
                    agent:
                        Anyway... As I was saying, you know all of these stuff.
                        Random people disliking you, unlocking the bar. Excellent. Glad we got that over.
                }
                {advisor_hostile?
                    agent:
                        Yeah, right.
                        Even if that's the case, you still won't be as good at campaigning as me.
                    player:
                        !crossed
                        Well, I am good enough to not need your explanation.
                    agent:
                        !crossed
                        Hmph.
                        If you are good enough, you should know what comes next.
                        Random people disliking you, unlocking the bar. Let's just get this over with.
                }
                {not (advisor_manipulate or advisor_hostile)?
                    agent:
                        !dubious
                        Uh huh, very funny.
                    player:
                        No, seriously, I did this a few time before already.
                    agent:
                        !shrug
                        If you say so.
                        So you know the drill, right?
                        Random people disliking you, unlocking the bar. Let's just get this over with.
                }
            ]],
            DIALOG_NO = [[
                player:
                    Uhh... No, actually.
                agent:
                    Very well. Ask me whatever questions you have.
            ]],
        }
        :Fn(function(cxt)
            local unlocks = {
                ADVISOR_DIPLOMACY = "GB_NEUTRAL_BAR",
                ADVISOR_MANIPULATE = "MOREEF_BAR",
                ADVISOR_HOSTILE = "GROG_N_DOG",
            }
            cxt.quest.param.free_bar_location = unlocks[cxt:GetAgent():GetContentID()] or "GROG_N_DOG"
            cxt:Dialog("DIALOG_INTRO")
            local profile = TheGame:GetGameProfile()
            cxt:Opt("OPT_YES")
                :ReqCondition(profile:HasUnlock("DONE_POLITICS_OPPOSITION") and profile:HasUnlock("DONE_POLITICS_FUNDING")
                    and profile:HasUnlock("DONE_POLITICS_FREE_TIME"), "REQ_PLAYED_ONCE")
                :Dialog("DIALOG_YES")
                :Fn(function(cxt)
                    DemocracyUtil.TryMainQuestFn("DoRandomOpposition", OPPO_COUNT)
                    DemocracyUtil.DoLocationUnlock(cxt, cxt.quest.param.free_bar_location)
                    TheGame:GetGameState():GetMainQuest().param.enable_support_screen = true
                end)
                :GoTo("STATE_COMPLETE_DIALOG")
            cxt:Opt("OPT_NO")
                :Dialog("DIALOG_NO")
                :GoTo("STATE_QUESTIONS")
        end)
    :State("STATE_QUESTIONS")
        :Loc{
            OPT_SUPPORT = "Ask about support",
            DIALOG_SUPPORT = [[
                player:
                    How do I know how popular I am, or if people will vote for me or not?
                agent:
                    Well here's the thing.
                {advisor_diplomacy?
                    The general public is cringe.
                    They will dislike you, simply because you are popular.
                }
                {advisor_manipulate?
                    Logically speaking, as you get more popular, more people will start to dislike you because you are popular.
                }
                {advisor_hostile?
                    Some people are naturally jealous.
                    They will dislike you because they have no talents of their own, and envy your skills.
                }
                {not (advisor_diplomacy or advisor_manipulate or advisor_manipulate)?
                    They will dislike you, simply because you are popular.
                }
                * As if on cue, you see a notification showing people disliking you.
            ]],
            DIALOG_SUPPORT_PST = [[
                player:
                    What is this? That seems very arbitrary.
                agent:
                    It may seem arbitrary, but it is what you have to deal with as a politician.
                    Which is why in order to get people to vote for you, you need to get people on your side.
                    How popular you are among the people is measured by your support.
                {advisor_diplomacy?
                    If you want to get people to vote for you, you need to ratio your opponent's support.
                }
                {advisor_manipulate?
                    Hypothetically speaking, the more support you have, the more likely that the people will vote for you.
                }
                {not (advisor_diplomacy or advisor_manipulate)?
                    The more support you have, the more likely that the people will vote for you.
                }
                    !permit
                    Here's more information about support. You should take a look.
                player:
                    !take
                    Thanks.
            ]],
            OPT_FUNDING = "Ask about funding",
            DIALOG_FUNDING = [[
                player:
                    I can't help but notice that I am not actively making money when I am rallying for support.
                    How am supposed to get funding for the campaign?
                agent:
                    You don't have to worry about that.
                {advisor_diplomacy?
                    The people love a based candidate, someone who speaks to them personally.
                    They will donate money to their favorite candidate just so they can win.
                    If you are popular, especially if people supporting you are loaded, you will get a griftillion shills.
                }
                {advisor_manipulate?
                    Logically, if you have more support, more people will want to donate to your campaign to make sure you succeed.
                    And the higher their social standings are, the more money they have to spare, and the more you will get from donations.
                }
                {advisor_hostile?
                    Nobody knows about gathering funding more than me.
                    And if you are as popular as me? People will throw money at you willingly.
                    Especially those who have money to spare.
                }
                {not (advisor_diplomacy or advisor_manipulate or advisor_hostile)?
                    If your support is high, people will donate you money.
                    Especially if you are popular among the wealthy.
                }
                    I will be managing those funding, of course. I will give them to you by the end of each day.
                player:
                    You sure you aren't pocketing some money for yourself?
                {advisor_diplomacy?
                    agent:
                        !crossed
                        Hey, what are you insinuating?
                        As a based {agent.gender:man|woman|person}, I don't care about normie stuff like cheating your campaign money out of you.
                    player:
                        !suspicious
                        Yes, of course you don't.
                }
                {advisor_manipulate?
                    agent:
                        Naturally.
                        I mean, I am providing you with a service. Logically speaking, I should get paid for that.
                    player:
                        Well, duh. Of course. How could I have think otherwise.
                    agent:
                        !agree
                        Glad you understand facts and logic.
                        But don't worry. I will only take out what is necessary for myself.
                        Logically, the rest goes to you and the campaign.
                    player:
                        !shrug
                        Well, at least you are straightforward about it.
                }
                {advisor_hostile?
                    agent:
                        Ha! You think I care about your measly campaign funds?
                        I can give you a small loan of a million shills if I want. Although I doubt you can pay it back.
                    player:
                        !placate
                        You know what? I'm not even going to question it.
                }
                {not (advisor_diplomacy or advisor_manipulate or advisor_hostile)?
                    agent:
                        !bashful
                        ...No?
                    player:
                        !dubious
                        Uh huh.
                }
            ]],
            OPT_FREE_TIME = "Ask about free time",
            DIALOG_FREE_TIME = [[
                player:
                    Do I get some free time when I am not campaigning?
                agent:
                    Yeah. You will get some free time when you are done.
                    During that time, you can visit many places, talk to many people, and do various things.
                    You can relax, or you can spend this time socializing with other people and get more support.
                player:
                    That sounds good and all, but I don't know where anything is, given that I just got here.
                {player_smith?
                    I mean, I was born here, but everything changed so much, and I don't remember where anything is.
                * That, or you are extremely drunk and forgot everything about the Pearl.
                }
                agent:
                    !handwave
                    Don't worry. As you talk to people, you will gradually learn where everything is.
                {not unlocked_grog?
                    {advisor_manipulate?
                        Let's say, that hypothetically, that you don't know where the Hideaway.
                    player:
                        !crossed
                        It's not really a hypothetical, as I really don't know where it is.
                    agent:
                        !handwave
                        Doesn't matter.
                        And let's say, hypothetically, you talk to me, and I know where it is.
                        I know this because I frequent it, as it provides humid air and superb drinks.
                        Then, when you ask me about where to find it, I will tell you to go past the Heshian compound, walk towards the Sea, until you see a bar sitting near a cliff.
                        !shrug
                        Now, you would know where it is.
                    player:
                        !dubious
                        You know, you can just drop the hypotheticals and just tell me about it.
                        Like normal people.
                    agent:
                        ...
                    }
                    {advisor_diplomacy?
                        !point
                        I know of a place that you should visit.
                        It's called the Last Stand.
                        The drinks are chill, and the people there are based. Mostly.
                        That would be a good place for you to start.
                    }
                    {advisor_hostile?
                        !hips
                        Luckily, nobody knows about locations more than me.
                    player:
                        !humoring
                        If you know so much about locations, why don't you recommend me one.
                    agent:
                        Alright.
                        !permit
                        There is a bar called the Grog n' Dog.
                        All kinds of people, from different faction visits there.
                        It's a good place to visit if you want to expand your campaign horizon.
                    }
                    {not (advisor_diplomacy or advisor_manipulate or advisor_hostile)?
                        !permit
                        There is a bar called the Grog n' Dog.
                        All kinds of people, from different faction visits there.
                        It's a good place to visit if you want to expand your campaign horizon.
                    }
                }
            ]],
            -- OPT_NEW_LOCATION = "Unlock new location: {1#location}",
            -- TT_NEW_LOCATION = "You can now visit this location during your free time.",
            DIALOG_SKIP_OPPOSITION = [[
                agent:
                    What a shame that a bunch of random people arbitrarily dislikes you.
                    That's what you have to deal with when you are a politician.
            ]],
        }
        :SetLooping()
        :Fn(function(cxt)
            local bar_location = cxt.quest.param.free_bar_location
            if not cxt.quest.param.did_opposition then
                cxt:Opt("OPT_SUPPORT")
                    :Dialog("DIALOG_SUPPORT")
                    :Fn(function(cxt)
                        DemocracyUtil.TryMainQuestFn("DoRandomOpposition", OPPO_COUNT)
                        cxt.quest.param.did_opposition = true
                        TheGame:GetGameProfile():AcquireUnlock("DONE_POLITICS_OPPOSITION")
                    end)
                    :Dialog("DIALOG_SUPPORT_PST")
                    :Fn(function(cxt)
                        TheGame:GetGameState():GetMainQuest().param.enable_support_screen = true
                        ShowRaceTutorial()
                    end)
            end
            if not cxt.quest.param.did_funding then
                cxt:Opt("OPT_FUNDING")
                    :Dialog("DIALOG_FUNDING")
                    :Fn(function(cxt)
                        cxt.quest.param.did_funding = true
                        TheGame:GetGameProfile():AcquireUnlock("DONE_POLITICS_FUNDING")
                    end)
                    -- :Dialog("DIALOG_SUPPORT_PST")
            end
            cxt.quest.param.unlocked_grog = table.arraycontains(TheGame:GetGameState():GetMainQuest().param.unlocked_locations, bar_location)
            if not cxt.quest.param.did_free_time then
                cxt:Opt("OPT_FREE_TIME")
                    :Dialog("DIALOG_FREE_TIME")
                    :Fn(function(cxt)
                        cxt.quest.param.did_free_time = true
                        if not cxt.quest.param.unlocked_grog then
                            DemocracyUtil.DoLocationUnlock(cxt, bar_location)
                        end
                        TheGame:GetGameProfile():AcquireUnlock("DONE_POLITICS_FREE_TIME")
                    end)
            end
            cxt:Opt("OPT_DONE")
                :MakeUnder()
                :Fn(function(cxt)
                    if not cxt.quest.param.did_opposition then
                        DemocracyUtil.TryMainQuestFn("DoRandomOpposition", OPPO_COUNT)
                        cxt.quest.param.did_opposition = true
                        cxt:Dialog("DIALOG_SKIP_OPPOSITION")
                        TheGame:GetGameState():GetMainQuest().param.enable_support_screen = true
                    end
                    cxt:GoTo("STATE_COMPLETE_DIALOG")
                end)
        end)
    :State("STATE_COMPLETE_DIALOG")
        :Loc{
            DIALOG_ADDRESS = [[
                agent:
                    Oh, one more thing.
                    Follow me to my office. It shall be the base of our operation.
                * It's actually {agent} following you. {agent.HeShe} just tell you where you should go on the map.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_ADDRESS")
            cxt.quest:Complete("discuss_plan")
            if not cxt.quest:GetCastMember("home") then
                cxt.quest:AssignCastMember("home")
            end
            cxt.quest:Activate("visit_office")
            StateGraphUtil.AddEndOption(cxt)
            -- TheGame:GetGameProfile():IncNarrativeProgress("done_politics")
        end)
QDEF:AddConvo("visit_office")
    :ConfrontState("STATE_ARRIVE", function(cxt) return cxt.location == cxt.quest:GetCastMember("home") end)
        :Loc{
            DIALOG_INTRO = [[
                primary_advisor:
                    !right
                    We're here.
                player:
                    !left
                    It looks like an okay place.
                primary_advisor:
                {advisor_hostile?
                    !hips
                    Ha! This is the best office in the history of offices, ever.
                }
                    !thought
                    I guess you don't have a place to sleep, huh?
                    Well, you can use the office backroom as a bedroom.
                player:
                    !happy
                    Thanks. That's very generous of you.
                primary_advisor:
                    There's still some time before we need to continue our campaign, so feel free to do whatever you want.
                    Once you're ready for the afternoon, talk to me about the next step.
                *** {home} is now your new base of operation. Return to {primary_advisor} after the free time.
            ]],
        }
        :Fn(function(cxt)
            cxt:TalkTo("primary_advisor")
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Complete()
            QuestUtil.SpawnQuest("RACE_LIVING_WITH_ADVISOR")
            StateGraphUtil.AddEndOption(cxt)
        end)
