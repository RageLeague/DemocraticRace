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

    -- on_start = function(quest)
        
    -- end,
    collect_agent_locations = function(quest, t)
        if quest:IsActive("go_to_bar") or quest:IsActive("choose_advisor") then
            table.insert (t, { agent = quest:GetCastMember("advisor_diplomacy"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.VISITOR} )
            table.insert (t, { agent = quest:GetCastMember("advisor_hostile"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.VISITOR} )
            table.insert (t, { agent = quest:GetCastMember("advisor_manipulate"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.VISITOR} )
        elseif quest:IsActive("discuss_plan") then
            table.insert (t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.VISITOR} )
        end

    end,
    on_fail = CleanUpFn,
    on_complete = CleanUpFn,
    on_cancel = CleanUpFn,
}
:AddObjective{
    id = "go_to_bar",
    title = "Visit the bar",
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
    -- no_validation = true,
}
:AddLocationCast{
    cast_id = "home",
    when = QWHEN.MANUAL,
    cast_fn = function(quest, t)
        table.insert(t, quest:GetCastMember("primary_advisor"):GetHomeLocation())
    end,
}
DemocracyUtil.AddAdvisors(QDEF)


local function GetAdvisorFn(advisor_id)
    return function(cxt)
        cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember(advisor_id))
        cxt:Dialog("DIALOG_INTRO")
        cxt:Opt("OPT_PICK")
            :PreIcon(global_images.accept)
            :Dialog("DIALOG_PICK")
            :Fn(function(cxt)
                cxt.quest.param.chosen_advisor = advisor_id
                local not_chosen_advisor = {}
                for i, val in ipairs(ADVISOR_ID) do
                    if val ~= advisor_id then
                        table.insert(not_chosen_advisor, val)
                    end
                end
                cxt.quest.param.bad_advisor = table.arraypick(not_chosen_advisor)
                TheGame:GetGameState():GetMainQuest():AssignCastMember("primary_advisor", cxt:GetAgent())
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
                cxt:Dialog("DIALOG_PICK_PST")
                cxt.quest:Complete("choose_advisor")
                cxt.quest:Activate("discuss_plan")
            end)
        cxt:Opt("OPT_LATER")
            :PreIcon(global_images.reject)
            :Dialog("DIALOG_LATER")
            :DoneConvo()
    end
end

QDEF:AddConvo("go_to_bar")
    :Confront(function(cxt)
        if cxt.location == cxt.quest:GetCastMember("noodle_shop") then
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
                * You arrived at the shop.
                * You ordered a bowl of noodles, thinking about today's failure.
                * Perhaps you shouldn't run for president after all.
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
                    How do you do, fellow grifter?
                    I've heard you were running for president.
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
                    Dont't listen to that Parasitic {advisor_manipulate}!
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
                    Can any of you explain what's happenening?
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
        end)
QDEF:AddConvo("choose_advisor", "advisor_diplomacy")
    :AttractState("STATE_TALK")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    [p] choose me plz
            ]],
            OPT_PICK = "Choose {agent} as your main advisor.",
            DIALOG_PICK = [[
                agent:
                    [p] wow thanks.
            ]],
            DIALOG_PICK_PST = [[
                * Other advisors left, and you're left with {agent}.
            ]],
            OPT_LATER = "Later",
            DIALOG_LATER = [[
                agent:
                    [p] take your time
            ]],
        }
        :Fn(GetAdvisorFn("advisor_diplomacy"))
QDEF:AddConvo("choose_advisor", "advisor_hostile")
    :AttractState("STATE_TALK")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    [p] the other's suck. choose me
            ]],
            OPT_PICK = "Choose {agent} as your main advisor.",
            DIALOG_PICK = [[
                agent:
                    [p] wow thanks.
            ]],
            DIALOG_PICK_PST = [[
                * Other advisors left, and you're left with {agent}.
            ]],
            OPT_LATER = "Later",
            DIALOG_LATER = [[
                agent:
                    [p] not like i want to help you anyway, baka
            ]],
        }
        :Fn(GetAdvisorFn("advisor_hostile"))
QDEF:AddConvo("choose_advisor", "advisor_manipulate")
    :AttractState("STATE_TALK")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    [p] i know you want to pick me
            ]],
            OPT_PICK = "Choose {agent} as your main advisor.",
            DIALOG_PICK = [[
                agent:
                    [p] wow thanks.
            ]],
            DIALOG_PICK_PST = [[
                * Other advisors left, and you're left with {agent}.
            ]],
            OPT_LATER = "Later",
            DIALOG_LATER = [[
                agent:
                    [p] you will come back no matter what.
            ]],
        }
        :Fn(GetAdvisorFn("advisor_manipulate"))
QDEF:AddConvo("discuss_plan", "primary_advisor")
    :AttractState("STATE_TALK")
        :Loc{
            DIALOG_INTRO = [[
                agent:
                    You're running for president, yes?
                    I saw what you did this morning. You are very talented at this kind of stuff.
                    You have a way with your words. I can give you that.
                player:
                    Really? Thanks.
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
                agent:
                    !dubious
                    Uh huh, very funny.
                player:
                    No, seriously, I did this a few time before already.
                agent:
                    !placate
                    Okay, geez! I got your point.
                    So you know the drill, right?
                    Random people disliking you, unlocking the grog. Let's just get this over with.
            ]],
            DIALOG_NO = [[
                player:
                    Uhh... No, actually.
                agent:
                    Very well. Ask me whatever questions you have.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_YES")
                :ReqCondition(TheGame:GetGameProfile():HasUnlock("DONE_POLITICS_BEFORE"), "REQ_PLAYED_ONCE")
                :Dialog("DIALOG_YES")
                :Fn(function(cxt)
                    DemocracyUtil.TryMainQuestFn("DoRandomOpposition", OPPO_COUNT)
                    DemocracyUtil.DoLocationUnlock(cxt, "GROG_N_DOG")
                end)
                :GoTo("STATE_COMPLETE_DIALOG")
            cxt:Opt("OPT_NO")
                :Dialog("DIALOG_NO")
                :GoTo("STATE_QUESTIONS")
                -- :Fn(function()DemocracyUtil.TryMainQuestFn("DoRandomOpposition", 2)end)
                -- :Dialog("DIALOG_NO_CONT")
            -- StateGraphUtil.AddEndOption(cxt.hub)
            
            -- cxt:GetAgent():GetBrain():MoveToHome()
            -- QuestUtil.SpawnQuest("RACE_LIVING_WITH_ADVISOR")
        end)
    :State("STATE_QUESTIONS")
        :Loc{
            OPT_SUPPORT = "Ask about support level",
            DIALOG_SUPPORT = [[
                agent:
                    The first step of running a campaign is to realize that being a polititian is a hard job.
                    There are different ways of apporaching problems in the society, and people have different opinions on these approaches.
                    Natually, some people will dislike you simply because of your ideology.
                * As if on cue, you see a notification showing people disliking you.
            ]],
            DIALOG_SUPPORT_PST = [[
                player:
                    What is this? That seems very arbitrary.
                agent:
                    It may seem arbitrary, but you have to deal with these people.
                    You need gain support level to increase the popularity among the people.
                    Remember, people who like you or love you will always vote for you, and people who dislike or hate you will always vote against you.
                    But the support level affects your popularity among swing voters.
                    At the same time, you should make people like you more, since they will help your with negotiation and solidifies their votes for you.
            ]],
            OPT_FUNDING = "Ask about funding",
            DIALOG_FUNDING = [[
                agent:
                    Your support level determines how much funding you get.
                    Additionally, richer people provides more funding for you than poorer people, so it might be a good idea to gain more support from the rich.
                    I'll help you collect funding, and give it to you by the end of each day.
                    Then you can focus on the actual campaign.
                player:
                    I bet you're doing that just because you can pocket extra money without letting me know.
                agent:
                    !happy
                    ...
                player:
                    !sigh
                    Fine, have it your way, then.
                agent:
                    You can spend your funding on improving your negotiation skills, advertise your campaign, and even buying shills and manipulating the voter base.
                player:
                    I thought our currency is shills. How does buying shills with shills work?
                agent:
                    You know how it works.
            ]],
            OPT_FREE_TIME = "Ask about free time",
            DIALOG_FREE_TIME = [[
                agent:
                    After spending some time campaigning, you will have some free time.
                    You can go visit locations you have learned through various means and socialize with your supporters once per day.
                    Sometimes you will learn new locations from them, sometimes they will provide a random benefit for you.
                {not unlocked_grog?
                    To show you how it works, I'll tell you a location you don't know yet.
                    A great place to visit is the Grog n' Dog.
                    All kinds of people visit there, so you can make friends from different factions easily there.
                    The owner, Fssh, is very friendly, and doesn't mind who visits her bar.
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
            if not cxt.quest.param.did_opposition then
                cxt:Opt("OPT_SUPPORT")
                    :Dialog("DIALOG_SUPPORT")
                    :Fn(function(cxt)
                        DemocracyUtil.TryMainQuestFn("DoRandomOpposition", OPPO_COUNT)
                        cxt.quest.param.did_opposition = true
                    end)
                    :Dialog("DIALOG_SUPPORT_PST")
            end
            if not cxt.quest.param.did_funding then
                cxt:Opt("OPT_FUNDING")
                    :Dialog("DIALOG_FUNDING")
                    :Fn(function(cxt)
                        cxt.quest.param.did_funding = true
                    end)
                    -- :Dialog("DIALOG_SUPPORT_PST")
            end
            cxt.quest.param.unlocked_grog = table.arraycontains(TheGame:GetGameState():GetMainQuest().param.unlocked_locations, "GROG_N_DOG")
            if not cxt.quest.param.did_free_time then
                cxt:Opt("OPT_FREE_TIME")
                    :Dialog("DIALOG_FREE_TIME")
                    :Fn(function(cxt)
                        cxt.quest.param.did_free_time = true
                        if not cxt.quest.param.unlocked_grog then
                            DemocracyUtil.DoLocationUnlock(cxt, "GROG_N_DOG")
                        end
                    end)
            end
            cxt:Opt("OPT_DONE")
                :MakeUnder()
                :Fn(function(cxt)
                    if not cxt.quest.param.did_opposition then
                        DemocracyUtil.TryMainQuestFn("DoRandomOpposition", OPPO_COUNT)
                        cxt.quest.param.did_opposition = true
                        cxt:Dialog("DIALOG_SKIP_OPPOSITION")
                        
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
                    There's still some time before we need to continue our campaign, so feel free to do whatever you want.
                    Once you're ready for the afternoon, talk to me about the next step.
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Complete()
            QuestUtil.SpawnQuest("RACE_LIVING_WITH_ADVISOR")
        end)
