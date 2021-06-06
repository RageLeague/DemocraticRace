local QDEF = QuestDef.Define
{
    title = "A Small Request",
    desc = "Your advisor have something to ask for you.",
    -- icon = engine.asset.Texture("DEMOCRATICRACE:assets/quests/meet_opposition.png"),

    qtype = QTYPE.STORY,
    collect_agent_locations = function(quest, t)
        table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.VISITOR})
        -- table.insert(t, { agent = quest:GetCastMember("potential_ally"), location = quest:GetCastMember('noodle_shop'), role = CHARACTER_ROLES.VISITOR})
    end,
    on_complete = function(quest)
        if quest:GetCastMember("primary_advisor") then
            quest:GetCastMember("primary_advisor"):GetBrain():SendToWork()
        end
    end,
    postcondition = function(quest)
        if not quest:GetCastMember("primary_advisor") then
            return false, "No primary advisor"
        end
        if quest:GetCastMember("primary_advisor"):GetRelationship() ~= RELATIONSHIP.LIKED then
            return false, "Not liked"
        end
        if DemocracyUtil.HasRequestQuest(quest:GetCastMember("primary_advisor")) then
            return false, "Already has request"
        end
        quest.param.request_quest = DemocracyUtil.SpawnRequestQuest(quest:GetCastMember("primary_advisor"))
        if not quest.param.request_quest then
            return false, "No request quest spawned"
        end
        return true
    end,
    events = {
        agent_retired = function(quest, agent)
            if agent == quest:GetCastMember("primary_advisor") then
                local replacement = QuestUtil.SpawnQuest( "RACE_DAY_3_NOON_GENERIC" )
                if replacement then
                    quest.param.parent_quest.param.noon_event = replacement
                    replacement.param.parent_quest = quest.param.parent_quest
                end
                quest:Cancel()
            end
        end,
    },
    -- on_start = function(quest)

    -- end,
}
:AddLocationCast{
    cast_id = "noodle_shop",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("MURDERBAY_NOODLE_SHOP"))
    end,

}
:AddObjective{
    id = "go_to_bar",
    title = "Visit the noodle shop",
    desc = "Visit the noodle shop and talk to your advisor about the upcoming plan.",
    mark = {"noodle_shop"},
    state = QSTATUS.ACTIVE,

    on_complete = function(quest)
        -- quest:Activate("discuss_plan")
        -- quest:Activate("make_decision")
    end,
}
DemocracyUtil.AddPrimaryAdvisor(QDEF)

QDEF:AddConvo("go_to_bar")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt:GetCastMember("primary_advisor") and cxt.location == cxt.quest:GetCastMember("noodle_shop") end)
        :Loc{
            DIALOG_INTRO = [[
                * [p] you arrived at the shop.
                player:
                    !left
                agent:
                    !right
                    I know you're working hard to campaign, but I want you to do something for me.
                    Of course, you don't have to accept it.
                    I want you to focus on the campaign if you need to, but if you think you have time to spare, maybe you can help me.
                player:
                    What do I get out of this?
                agent:
                    I will love you, and will help you as much as I can.
                player:
                    Sounds appealing.
                    Tell me what you want me to do, then.
            ]],
            DIALOG_REJECT = [[
                player:
                    I'm sorry, but I need to focus on the campaign.
                    I believe the campaign is surely more important than whatever you're doing.
                agent:
                    You're right, of course.
                    Forget I ever asked anything.
                    When you're done eating lunch, see me at my office and start campaigning.
                    There's plenty to do today.
            ]],
            DIALOG_ACCEPT = [[
                agent:
                    Anyway, if you want to do it with your free time, that is okay.
                    I don't want you to abandon the campaign for me.
                player:
                    Sure thing.
                agent:
                    When you're done eating lunch, see me at my office and start campaigning.
                    There's plenty to do today.
            ]],
        }
        :RunLoopingFn(function(cxt)
            if cxt:FirstLoop() then
                cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
                cxt.quest:Complete("go_to_bar")
                cxt:Dialog("DIALOG_INTRO")
            end
            cxt:QuestOpt( cxt.quest.param.request_quest )
                :Fn(function(cxt)
                    cxt:PlayQuestConvo(cxt.quest.param.request_quest, QUEST_CONVO_HOOK.INTRO)
                    DemocracyUtil.PresentRequestQuest(cxt, cxt.quest.param.request_quest, function(cxt,quest)
                        cxt:PlayQuestConvo(quest, QUEST_CONVO_HOOK.ACCEPTED)
                        cxt:Dialog("DIALOG_ACCEPT")
                        cxt.quest:Complete()
                        StateGraphUtil.AddEndOption(cxt)
                    end, function(cxt, quest)
                        cxt:Dialog("DIALOG_REJECT")
                        cxt.quest:Complete()
                        StateGraphUtil.AddEndOption(cxt)
                    end)

                end)
        end)