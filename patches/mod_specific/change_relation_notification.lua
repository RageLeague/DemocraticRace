local old_fn = NOTIFY.RELATIONSHIP_CHANGED.FormatNotification

local function GetReason(txt)
    return LOC("DEMOCRACY.DELTA_SUPPORT_REASON." .. txt)
end
function NOTIFY.RELATIONSHIP_CHANGED:FormatNotification(notification, agent, old_rel, new_rel, ...)
    if not DemocracyUtil.IsDemocracyCampaign() or not TheGame:GetGameState():GetMainQuest().param.enable_support_screen then
        return old_fn(self, notification, agent, old_rel, new_rel, ...)
    else
        local result = old_fn(self, notification, agent, old_rel, new_rel, ...)
        if not (agent == (TheGame:GetGameState():GetMainQuest() and TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor")) or not DemocracyUtil.CanVote(agent)) then
            local t = require "DEMOCRATICRACE:content/quests/main/democratic_race_main"
            local support_delta = t.DELTA_SUPPORT[new_rel] - t.DELTA_SUPPORT[old_rel]
            local general_delta = math.floor(support_delta / 3)
            if support_delta ~= 0 then
                if notification.details and notification.details ~= "" then
                    return
                end
                if support_delta > 0 then
                    notification.details = loc.format(LOC("DEMOCRACY.NOTIFICATION.AGENT_SUPPORT.DETAIL_INCREASE"), math.abs(general_delta), math.abs(support_delta), GetReason("RELATIONSHIP_UP"), agent:GetFaction(), agent)
                else
                    notification.details = loc.format(LOC("DEMOCRACY.NOTIFICATION.AGENT_SUPPORT.DETAIL_DECREASE"), math.abs(general_delta), math.abs(support_delta), GetReason("RELATIONSHIP_DOWN"), agent:GetFaction(), agent)
                end
            end
        end
    end
end
