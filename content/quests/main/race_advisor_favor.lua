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
    function(quest)
        return quest:GetCastMember("primary_advisor"):GetRelationship() == RELATIONSHIP.LIKED
    end,
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
    title = "Visit the Noodle Shop",
    desc = "Visit the noodle shop and talk to your advisor about the upcoming plan.",
    mark = {"noodle_shop"},
    state = QSTATUS.ACTIVE,

    on_complete = function(quest)
        -- quest:Activate("discuss_plan")
        quest:Activate("make_decision")
    end,
}
DemocracyUtil.AddPrimaryAdvisor(QDEF)

QDEF:AddConvo("go_to_bar")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt.location == cxt.quest:GetCastMember("noodle_shop") end)
        :Loc{
            DIALOG_INTRO = [[
                * [p] you arrived at the shop.
                player:
                    !left
                primary_advisor:
                    !right
                    I know you're working hard to campaign, but I want you to do something for me.
                    Of course, you don't have to accept it.
                    I want you to focus on the campaign if you need to, but if you think you have time to spare, maybe you can help me.
                player:
                    What do I get out of this?
                primary_advisor:
                    I will love you, and will help you as much as I can.
            ]],
        }
        :Fn(function(cxt)

            cxt.quest:Complete("go_to_bar")
            cxt:Dialog("DIALOG_INTRO")
        end)