local patch_id = "MOD_AUDIO_BANK"
if rawget(_G, patch_id) then
    return
end
rawset(_G, patch_id, true)
print("Loaded patch:"..patch_id)

-- AUDIO.bank_alias_map = {}

function AudioSystem:MountModdedAudioBank(alias, bank_id)
    if not self.bank_alias_map then
        self.bank_alias_map = {}
    end
    if not self.bank_alias_map[alias] then
        local audiobank = AUDIO:LoadBank(bank_id, false)
        print("Audio info:", AUDIO.enabled, audiobank)
        -- AUDIO:FinalizeBankLoad(audiobank)
        self.bank_alias_map[alias] = bank_id
    end
end

-- Example:
-- DemocraticRace|event:/...
function AudioSystem:ConvertAudioEventFormat(str)
    local namespace, eventname = str:match("^(.-)|(.*)$")
    if namespace and eventname then
        if not self.bank_alias_map[namespace] then
            return str, nil
        end
        return eventname, self.bank_alias_map[namespace]
    end

    -- By default, do nothing with it.
    return str, nil
end

local old_fn = AudioSystem.CreateEventInstance
function AudioSystem:CreateEventInstance(str, bank_name, ...)
    local newstr, bank_data = self:ConvertAudioEventFormat(str)
    return old_fn(self, newstr, bank_data or bank_name, ...)
end