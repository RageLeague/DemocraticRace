local unlocks = require "DEMOCRATICRACE:content/get_location_unlock"

local function PickLocationUnlockForAgent(agent, unlock_type)
    if not TheGame:GetGameState():GetMainQuest().param.unlocked_locations then
        return
    end
    local all_locations = unlocks.GetLocationUnlockForAgent(agent, unlock_type)

    local knows_location = {}

    for i = 1, 2 do
        local location = weightedpick(all_locations)
        if not location then
            break
        end
        table.insert(knows_location, location)
        all_locations[location] = nil
    end

    table.sort( knows_location, function(a, b)
        return (DemocracyUtil.LocationUnlocked(a) and 1 or 0) < (DemocracyUtil.LocationUnlocked(b) and 1 or 0)
    end )

    return knows_location[1]
end

local QDEF = QuestDef.Define
{
    qtype = QTYPE.STORY,
}
:AddObjective{
    id = "start",
    state = QSTATUS.ACTIVE,
}
:AddConvo()
    :Loc{
        OPT_ASK_ABOUT_LOCATION = "Ask for a place to visit...",
        TT_REDUCED_ACTION_COST = "<#BONUS>This option has reduced action cost because you asked for an invalid location today.</>",

        REQ_NOT_SOCIALIZED = "You can only ask a person about new locations once per day.",
        REQ_NO_COMPETITOR = "{agent} will not recommend a competitor location.",

        OPT_BAR = "Ask for a restaurant or bar",
        DIALOG_BAR = [[
            player:
                You know a good bar I can visit? Or a restaurant?
        ]],
        OPT_SHOP = "Ask for a shop",
        DIALOG_SHOP = [[
            player:
                You know a good shop I can visit?
        ]],
        OPT_ENTERTAINMENT = "Ask for a place of entertainment",
        DIALOG_ENTERTAINMENT = [[
            player:
                You know a fun place to visit?
        ]],
        OPT_WORK = "Ask for a workplace",
        DIALOG_WORK = [[
            player:
                You know any workplaces?
        ]],
        OPT_OFFICE = "Ask for an office",
        DIALOG_OFFICE = [[
            player:
                You know any offices?
        ]],
        OPT_ANY = "Ask for any location",
        DIALOG_ANY = [[
            player:
                You know any good place I can visit?
        ]],

        DIALOG_ALREADY_UNLOCKED = [[
            agent:
                Have you heard of {loc_to_unlock#location}?
            player:
                Unfortunately, I have.
            agent:
                Oh. I see.
            player:
                Well, thanks anyway.
        ]],

        DIALOG_NO_MORE_LEFT = [[
            agent:
                Unfortunately, I know nothing of the sort.
                I'm sorry.
            player:
                Well, thanks anyway.
        ]],
    }
    :Hub(function(cxt, who)
        if not (DemocracyUtil.IsDemocracyCampaign() and who and who:IsSentient()) then
            return
        end
        if (cxt.location and cxt.location:GetProprietor() == who and who:GetRelationship() >= RELATIONSHIP.NEUTRAL) or (who:GetRelationship() > RELATIONSHIP.NEUTRAL or who == TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor")) then
            cxt:Opt("OPT_ASK_ABOUT_LOCATION")
                :ReqCondition(not who:HasMemoryFromToday("OFFERED_LOCATION"), "REQ_NOT_SOCIALIZED")
                :RequireFreeTimeAction(2, true)
                :LoopingFn(function(cxt)
                    local function AddLocationOption(opt_id, unlock_type, preicon)
                        if who:HasMemory("ASKED_OPT_" .. opt_id) then
                            return
                        end
                        local workplace = who:GetBrain() and who:GetBrain():GetWorkplace()
                        local opt = cxt:Opt("OPT_"..opt_id)
                            -- :ReqCondition(not unlock_type or not workplace or not table.arraycontains(unlocks.UNLOCK_LOCATIONS[unlock_type], workplace:GetContentID()), "REQ_NO_COMPETITOR")
                            :Dialog("DIALOG_"..opt_id)
                        if preicon then
                            opt:PreIcon(preicon)
                        end
                        -- if who:HasMemoryFromToday("WASTED_LOCATION_UNLOCK") then
                        --     opt:PostText("TT_REDUCED_ACTION_COST")
                        -- end
                        opt:Fn(function(cxt)
                            who:Remember("ASKED_OPT_" .. opt_id)
                            cxt.quest.param.loc_to_unlock = PickLocationUnlockForAgent(who, unlock_type)

                            if cxt.quest.param.loc_to_unlock then
                                if DemocracyUtil.LocationUnlocked(cxt.quest.param.loc_to_unlock) then
                                    cxt:Dialog("DIALOG_ALREADY_UNLOCKED")
                                    cxt:GetAgent():Remember("WASTED_LOCATION_UNLOCK")
                                else
                                    cxt:GetAgent():Remember("OFFERED_LOCATION")
                                    local unlock_location = TheGame:GetGameState():GetLocation(cxt.quest.param.loc_to_unlock)
                                    local location_tags = unlock_location:FillOutQuipTags()
                                    location_tags = table.map(location_tags, function(str) return "unlock_" .. str end)
                                    -- TheGame:GetDebug():CreatePanel(DebugTable(location_tags))

                                    cxt.quest.param.prop = unlock_location:GetProprietor()

                                    cxt:Quip(cxt:GetAgent(), "unlock_location", cxt.player:GetContentID(), table.unpack(location_tags))
                                    DemocracyUtil.DoLocationUnlock(cxt, cxt.quest.param.loc_to_unlock)
                                    local freetimeevents = DemocracyUtil.GetFreeTimeQuests()
                                    freetimeevents[1]:DefFn("DeltaActions", -2)
                                    StateGraphUtil.AddEndOption(cxt)
                                end
                            else
                                cxt:Dialog("DIALOG_NO_MORE_LEFT")
                                cxt:GetAgent():Remember("WASTED_LOCATION_UNLOCK")
                            end
                        end)
                    end
                    local TYPE = unlocks.UNLOCK_TYPE
                    AddLocationOption("BAR", TYPE.BAR)
                    AddLocationOption("SHOP", TYPE.SHOP)
                    AddLocationOption("ENTERTAINMENT", TYPE.ENTERTAINMENT)
                    AddLocationOption("WORK", TYPE.WORK)
                    AddLocationOption("OFFICE", TYPE.OFFICE)
                    AddLocationOption("ANY", nil)
                    StateGraphUtil.AddBackButton(cxt)
                end)
        end
    end)
