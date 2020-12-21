local QDEF = QuestDef.Define
{
    title = "Noon Rendezvous",
    desc = "Meet up with your advisor and discuss the plan for the campaign.",
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
        quest:Activate("discuss_plan")
        -- quest:Activate("make_decision")
    end,
}
:AddObjective{
    id = "discuss_plan",
    title = "Discuss plans",
    desc = "Discuss plans with your advisor about the upcoming debate.",
    mark = {"primary_advisor"},
}
DemocracyUtil.AddPrimaryAdvisor(QDEF)

QDEF:AddConvo("go_to_bar")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt.location == cxt.quest:GetCastMember("noodle_shop") end)
        :Loc{
            DIALOG_INTRO = [[
                * [p] you arrived at the shop.
                player:
                    !left
                agent:
                    !right
                    Oh, hi. Look who's here.
                player:
                    I just love this shop. It sells great noodles for great prices.
                agent:
                    I know, right?
                    But that's not why we're here for.
                    We're here to discuss the plan for tonight.
            ]],
        }
        :Fn(function(cxt)
            -- if cxt:FirstLoop() then
            cxt:TalkTo(cxt:GetCastMember("primary_advisor"))
            cxt.quest:Complete("go_to_bar")
            cxt:Dialog("DIALOG_INTRO")
            -- end
            StateGraphUtil.AddEndOption(cxt)
        end)
QDEF:AddConvo("discuss_plan", "primary_advisor")
    :Loc{

    }
    :Hub(function(cxt)
        
    end)