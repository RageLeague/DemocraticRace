local weary = "dem_weary_negotiation"
local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,

    events =
    {
        base_difficulty_change = function(quest, new_diff, old_diff)
            quest:SetRank(new_diff)
        end,
    },

    LABOUR_LOCATIONS = {"MURDERBAY_LUMIN_DOCKS", "MURDER_BAY_HARBOUR"},
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}
QDEF:AddConvo()
    :Loc{
        OPT_WORK = "Work manual labour",
        REQ_TOO_WEARY = "You are too tired to work!",
        DIALOG_WORK = [[
            {first_work?
                player:
                    [p] So, can I work here?
                agent:
                    Sure.
                * You work and earn a bunch of money.
                * You get paid way too much money for the amount of work you put in.
                * Like, canonically a common laborer gets paid 180 shills a month, and you earned a fourth of that within like an hour.
                * But you know, you are a politician now. You get special treatments.
                * Also you know, game balance and all that.
            }
            {not first_work?
                player:
                    [p] Let's work here.
            }
        ]],
    }
    :Hub(function(cxt, who)
        if table.arraycontains(cxt.quest:GetQuestDef().LABOUR_LOCATIONS, cxt.location:GetContentID()) and who and who == cxt.location:GetProprietor() then
            local weary_cards = TheGame:GetGameState():GetPlayerAgent().negotiator:GetCardCount(weary)
            cxt.enc.scratch.first_work = not who:HasMemory("WORKED_LABOUR")
            cxt:Opt("OPT_WORK")
                :ReqCondition(weary_cards < 2, "REQ_TOO_WEARY")
                :RequireFreeTimeAction(3)
                :PostText("OPT_FORCE_GAIN_NEGOTIATION_CARD", weary )
                :PostCard(weary, true)
                :Dialog("DIALOG_WORK")
                :ReceiveMoney(50)
                :DeltaSupport(1, 1)
                :Fn( function( cxt )
                    cxt:ForceTakeCards{ weary }
                    who:Remember("WORKED_LABOUR")
                end )
        end
    end)
