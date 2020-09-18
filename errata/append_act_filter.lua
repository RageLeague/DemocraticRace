-- This patch adds a new function that allows the appending of act_filter to existing qdefs.
-- Arguments:
-- qdef: (String) the id of the quest def in content
--       (QuestDef object) the quest def to modify
-- additional_options: (String) the act id to append to.
--                     (Function) the function to filter out.
-- The result is a "or" relationship of the old filter and the new one.
-- If successfully executed, the act_filter of qdef will be replaced by the new one.
-- Returns two values:
-- 1) true if act_filter changed, false if not.
-- 2) messaging for debug purposes.

function AppendActFilterToQuest(qdef, additional_options)
    
    if type(qdef) == "string" then -- that tells me it's an id to quest.
        qdef = Content.GetQuestDef(qdef)
    end

    if not qdef.act_filter then
        qdef.act_filter = additional_options
        return false, "already allows everything"--true, loc.format("add an act filter {1}",additional_options)
    local old_filter = qdef.act_filter
    if type(old_filter) == "function" then
        if type(additional_options) == "function" then
            qdef.act_filter = function(self, act_id)
                return old_filter(self, act_id) or additional_options(self, act_id)
            end
            return true, loc.format("add new function {1} to old function {2}", additional_options, old_filter)
        else
            qdef.act_filter = function(self, act_id)
                return old_filter(self, act_id) or act_id == additional_options
            end
            return true, loc.format("add new string '{1}' to old function {2}", additional_options, old_filter)
        end
    else
        if type(additional_options) == "function" then
            qdef.act_filter = function(self, act_id)
                return act_id == old_filter or additional_options(self, act_id)
            end
            return true, loc.format("add new function {1} to old string '{2}'", additional_options, old_filter)
        else
            qdef.act_filter = function(self, act_id)
                return act_id == old_filter or act_id == additional_options
            end
            return true, loc.format("add new string '{1}' to old string '{2}'", additional_options, old_filter)
        end
    end
    return false, "unidentified data type"
end