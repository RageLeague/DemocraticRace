local IssueStanceLocDef = class("DemocracyClass.IssueStanceLocDef", BasicLocalizedDef)

function IssueStanceLocDef:init(issue_id, stance_intensity, data)
    IssueStanceLocDef._base.init(self, issue_id .. "_" .. stance_intensity, data)
    self.issue_id = issue_id
    self.stance_intensity = stance_intensity
    self:SetModID(CURRENT_MOD_ID)
end
function IssueStanceLocDef:GetLocalizedTitle()
    return self:GetLocalizedName()
end
function IssueStanceLocDef:GetLocalizedBody()
    return self:GetLocalizedDesc()
end
function IssueStanceLocDef:GetLocPrefix()
    return "POLITICAL_ISSUE." .. string.upper(self.issue_id) .. ".STANCE_" .. self.stance_intensity
end
function IssueStanceLocDef:GetAgentSupport(agent)
    local score = 0
    if self.faction_support and self.faction_support[agent:GetFactionID()] then
        score = score + self.faction_support[agent:GetFactionID()]
    end
    if self.wealth_support and self.wealth_support[DemocracyUtil.GetWealth(agent)] then
        score = score + self.wealth_support[DemocracyUtil.GetWealth(agent)]
    end
    return score
end

local IssueLocDef = class("DemocracyClass.IssueLocDef", BasicLocalizedDef)

function IssueLocDef:init(id, data)
    if data.stances then
        for stance_id, data2 in pairs(data.stances) do
            if not is_instance(data2, IssueStanceLocDef) then
                data.stances[stance_id] = IssueStanceLocDef(id, stance_id, data2)
            end
        end
    end
    IssueLocDef._base.init(self, id, data)
    self:SetModID(CURRENT_MOD_ID)
end
function IssueLocDef:GetLocalizedTitle()
    return self:GetLocalizedName()
end
function IssueLocDef:GetLocalizedBody()
    return self:GetLocalizedDesc()
end
function IssueLocDef:HarvestStrings(t)
    IssueLocDef._base.HarvestStrings(self, t)
    for stance_id, data in pairs(self.stances) do
        data:HarvestStrings(t)
    end
end
function IssueLocDef:GetLocPrefix()
    return "POLITICAL_ISSUE." .. string.upper(self.id)
end
function IssueLocDef:GetAgentStanceIndex(agent)
    if agent:IsPlayer() then
        return DemocracyUtil.TryMainQuestFn("GetStance", self)
    end
    local stance_score = {}
    local has_vals = false
    for id, data in pairs(self.stances) do
        stance_score[id] = math.max (0, data:GetAgentSupport(agent))
        if math.abs(id) >= 2 and stance_score[id] < 5 then stance_score[id] = 0 end
        if math.abs(id) == 1 and stance_score[id] < 2 then stance_score[id] = 0 end

        if stance_score[id] > 0 then has_vals = true end
        
    end
    if has_vals then
        return weightedpick(stance_score)
    else
        return 0
    end
end
function IssueLocDef:GetStance(idx)
    return self.stances[idx]
end
function IssueLocDef:GetAgentStance(agent)
    return self.stances[self:GetAgentStanceIndex(agent)]
end
function IssueLocDef:GetImportance(agent)
    local delta = 0
    if agent then
        local abs_val = math.abs( self:GetAgentStanceIndex(agent) )
        if abs_val == 0 then
            delta = -2
        elseif abs_val >= 2 then
            delta = 3 * (abs_val - 1)
        end
    end
    return math.max(0, (self.importance or 6) + delta) -- some middle point if there's nothing defined
end

function ConvoOption:UpdatePoliticalStance(issue, newval, strict, autosupport, for_show)
    if type(issue) == "string" then
        issue = DemocracyConstants.issue_data[issue]
    end
    assert(issue, "issue must be non-nil")
    local old_stance = DemocracyUtil.TryMainQuestFn("GetStance", issue)
    local new_stance_data = issue.stances[newval]
    if old_stance then
        local old_stance_data = issue.stances[old_stance]

        if not strict or DemocracyUtil.TryMainQuestFn("GetStanceChangeFreebie", issue) then
            if (old_stance < 0) == (newval < 0) and (old_stance > 0) == (newval > 0) then
                self:PostText("TT_UPDATE_STANCE_SAME", issue, old_stance_data)
                self:PostText("TT_UPDATE_STANCE_BONUS")
            else
                self:PostText("TT_UPDATE_STANCE_LOOSE_OLD", issue, new_stance_data, old_stance_data)
                self:PostText("TT_UPDATE_STANCE_WARNING")
            end
        else
            if old_stance == newval then
                self:PostText("TT_UPDATE_STANCE_SAME", issue, old_stance_data)
                self:PostText("TT_UPDATE_STANCE_BONUS")
            else
                self:PostText("TT_UPDATE_STANCE_OLD", issue, new_stance_data, old_stance_data)
                self:PostText("TT_UPDATE_STANCE_WARNING")
            end
        end
    else
        if strict then
            self:PostText("TT_UPDATE_STANCE", issue, new_stance_data)
        else
            self:PostText("TT_UPDATE_STANCE_LOOSE", issue, new_stance_data)
        end
    end
    if not for_show then
        self:Fn(function()
            DemocracyUtil.TryMainQuestFn("UpdateStance", issue, newval, strict, autosupport)
        end)
    end
    return self
end

local val =  {
    SECURITY = {
        name = "Universal Security",
        desc = "Security is a big issue in Havaria. On the one hand, improving security can drastically reduce crime and improve everyone's lives. On the other hand, it can leads to corruption and abuse of power.",
        importance = 10,
        stances = {
            [-2] = {
                name = "Defund the Admiralty",
                desc = "The Admiralty has always abused their power and made many false arrests. It's better if the Admiralty is defunded, and measures must be put in place to prevent anyone else from taking this power.",
                faction_support = {
                    ADMIRALTY = -5,
                    FEUD_CITIZEN = -4,
                    BANDITS = 5,
                    RISE = 3,
                    CULT_OF_HESH = -3,
                    JAKES = 2,
                },
                wealth_support = {
                    5,
                    -4,
                    -2,
                    -1,
                },
            },
            [-1] = {
                name = "Cut Funding for the Admiralty",
                desc = "While it's important to have some sort of public security, at the current state, the Admiralty has too much power and is abusing it. By cutting their funding, their influence will be reduced.",
                faction_support = {
                    ADMIRALTY = -3,
                    FEUD_CITIZEN = -2,
                    BANDITS = 3,
                    RISE = 1,
                    SPARK_BARONS = 2,
                    CULT_OF_HESH = -2,
                    JAKES = 1,
                },
                wealth_support = {
                    2,
                    -2,
                    -1,
                    1,
                },
            },
            [0] = {
                name = "No Change",
                desc = "The current system works just fine. There's no need to change it.",
                faction_support = {
                    ADMIRALTY = 1,
                    RISE = -1,
                    BANDITS = -1,
                },
                wealth_support = {
                    0,
                    -1,
                },
            },
            [1] = {
                name = "Increase Funding for the Admiralty",
                desc = "Havaria is overrun with criminals of all kind. That's why we need to improve the security by increasing funding for the Admiralty. This way, the people can live in peace.",
                faction_support = {
                    ADMIRALTY = 3,
                    FEUD_CITIZEN = 2,
                    BANDITS = -3,
                    RISE = -2,
                    SPARK_BARONS = -1,
                    JAKES = -1,
                },
                wealth_support = {
                    -2,
                    2,
                    1,
                    -1,
                },
            },
            [2] = {
                name = "Universal Security for All",
                desc = "Havaria is overrun with criminals of all kind, and the only way to fix it is through drastic measures.",
                faction_support = {
                    ADMIRALTY = 5,
                    FEUD_CITIZEN = 3,
                    BANDITS = -5,
                    RISE = -4,
                    SPARK_BARONS = -2,
                    CULT_OF_HESH = 2,
                    JAKES = -2,
                },
                wealth_support = {
                    -4,
                    4,
                    2,
                    -3,
                },
            },
        },
    },
    INDEPENDENCE = {
        name = "Deltrean-Havarian Annex",
        desc = "The annexation of Havaria into Deltree has stroke controversies across Havaria. On the one hand, a full integration of Havaria to Deltree will likely improve Havaria's prosperity. On the other hand, it is a blatant disregard to Havaria's sovereignty.",
        importance = 8,
        stances = {
            [-2] = {
                name = "Total Annexation",
                desc = "Havaria and Deltree become one country, with no special treatment.",
                faction_support = {
                    ADMIRALTY = 5,
                    FEUD_CITIZEN = -4,
                    BANDITS = -5,
                    CULT_OF_HESH = 3,
                    JAKES = -3,
                },
                wealth_support = {
                    -5,
                    -2,
                    0,
                    5,
                },
            },
            [-1] = {
                name = "Havarian Special Administration",
                desc = "Havaria is part of Deltree by name, but Havaria has partial autonomy to allow better integration.",
                faction_support = {
                    ADMIRALTY = 3,
                    FEUD_CITIZEN = -2,
                    BANDITS = -3,
                    CULT_OF_HESH = 2,
                    JAKES = -1,
                },
                wealth_support = {
                    -3,
                    0,
                    0,
                    2,
                },
            },
            [0] = {
                name = "I don't care",
                desc = "[p] i just want to grill for hesh sake",
                faction_support = {
                    ADMIRALTY = -1,
                    FEUD_CITIZEN = -1,
                },
                wealth_support = {
                    -1,
                },
            },
            [1] = {
                name = "Vassal State",
                desc = "Havaria become a vassal state of Deltree. However, they are still different nations, and Deltree must respect the autonomy of Havaria.",
                faction_support = {
                    ADMIRALTY = -4,
                    FEUD_CITIZEN = 2,
                    BANDITS = 3,
                    CULT_OF_HESH = -2,
                },
                wealth_support = {
                    1,
                    0,
                    0,
                    -2,
                },
            },
            [2] = {
                name = "Havaria Independence",
                desc = "Havaria will become completely independent of Deltree, and Deltree should recognize the independence and respect Havaria's autonomy.",
                faction_support = {
                    ADMIRALTY = -5,
                    FEUD_CITIZEN = 3,
                    BANDITS = 5,
                    CULT_OF_HESH = -4,
                    JAKES = 2,
                },
                wealth_support = {
                    3,
                    0,
                    -2,
                    -5,
                },
            },
        },
    },
    TAX_POLICY = {
        name = "Tax Policy",
        desc = "Taxes are huge issues in society. [p] seriously, i'm lazy, you know what tax is right",
        importance = 9,
        stances = {
            [-2] = {
                name = "Minimum Taxes",
                desc = "tax kept to min",
                faction_support = {
                    SPARK_BARONS = 5,
                    ADMIRALTY = -5,
                    RISE = -2,
                    CULT_OF_HESH = -3,
                    FEUD_CITIZEN = 1,
                    JAKES = 2,
                },
                wealth_support = {
                    2,
                    -5,
                    -3,
                    5,
                },
            },
            [-1] = {
                name = "Reduced Taxes",
                desc = "low tax",
                faction_support = {
                    SPARK_BARONS = 3,
                    ADMIRALTY = -4,
                    CULT_OF_HESH = -2,
                    RISE = -1,
                    FEUD_CITIZEN = 1,
                    JAKES = 1,
                },
                wealth_support = {
                    1,
                    -3,
                    -2,
                    3,
                },
            },
            [0] = {
                name = "Keep As It Is",
                desc = "tax is good for now",
                faction_support = {
                    SPARK_BARONS = 1,
                    ADMIRALTY = -1,
                    RISE = -1,
                    FEUD_CITIZEN = -1,
                },
                wealth_support = {
                    0,
                    -2,
                    0,
                    1,
                },
            },
            [1] = {
                name = "Increase Taxes",
                desc = "more taxes",
                faction_support = {
                    SPARK_BARONS = -4,
                    ADMIRALTY = 2,
                    CULT_OF_HESH = 2,
                    RISE = 1,
                    FEUD_CITIZEN = -1,
                    JAKES = -1,
                },
                wealth_support = {
                    -2,
                    2,
                    1,
                    -3,
                },
            },
            [2] = {
                name = "Max Taxes",
                desc = "no one likes that, but you don't know that for sure.",
                faction_support = {
                    SPARK_BARONS = -6,
                    ADMIRALTY = 5,
                    CULT_OF_HESH = 4,
                    RISE = -1,
                    FEUD_CITIZEN = -3,
                    JAKES = -2,
                },
                wealth_support = {
                    -3,
                    4,
                    -1,
                    -5,
                },
            },
        },
    },
    LABOR_LAW = {
        name = "Labor Laws",
        desc = "pro-employer? pro-workers?",
        importance = 9,
        stances = {
            [-2] = {
                name = "Laissez Faire",
                desc = "i can never remember how to spell this.",
                faction_support = {
                    SPARK_BARONS = 5,
                    ADMIRALTY = 1,
                    CULT_OF_HESH = 3,
                    RISE = -5,
                    FEUD_CITIZEN = -2,
                    JAKES = -4,
                },
                wealth_support = {
                    -5,
                    -4,
                    3,
                    5,
                },
            },
            [-1] = {
                name = "Pro-Employer",
                desc = "Employers have more rights than workers.",
                faction_support = {
                    SPARK_BARONS = 3,
                    -- ADMIRALTY = 1,
                    CULT_OF_HESH = 2,
                    RISE = -4,
                    FEUD_CITIZEN = -1,
                    JAKES = -2,
                },
                wealth_support = {
                    -3,
                    -2,
                    1,
                    3,
                },
            },
            [0] = {
                name = "Balanced",
                desc = "how do you even define 'balanced' in this situation?",
                faction_support = {
                    SPARK_BARONS = -1,
                    RISE = -1,
                },
                wealth_support = {
                    -1,
                    0,
                    0,
                    1,
                },
            },
            [1] = {
                name = "Pro-Worker",
                desc = "laws protects workers.",
                faction_support = {
                    SPARK_BARONS = -3,
                    ADMIRALTY = -2,
                    CULT_OF_HESH = -3,
                    RISE = 3,
                    FEUD_CITIZEN = 1,
                    JAKES = 1,
                },
                wealth_support = {
                    3,
                    1,
                    -2,
                    -3,
                },
            },
            [2] = {
                name = "Socialism",
                desc = "Seize the means of production.",
                faction_support = {
                    SPARK_BARONS = -5,
                    ADMIRALTY = -3,
                    CULT_OF_HESH = -4,
                    RISE = 5,
                    FEUD_CITIZEN = 2,
                    JAKES = -1,
                },
                wealth_support = {
                    5,
                    2,
                    -3,
                    -5,
                },
            },
        },
    },
    ARTIFACT_TREATMENT = {
        name = "Artifact Treatment",
        desc = "if you have a better name, help me out here",
        importance = 6,
        stances = {
            [-2] = {
                name = "Extensive Research & Use",
                desc = "Research all the artifacts extensively and utilize them to restore the former glory of the Vagrant Age",
                faction_support = {
                    SPARK_BARONS = 5,
                    BILEBROKERS = 3,
                    CULT_OF_HESH = -5,
                    BOGGERS = -4,
                },
                wealth_support = {
                    -4,
                    0,
                    3,
                    0,
                },
            },
            [-1] = {
                name = "Commercial Use",
                desc = "Sell the artifacts as weapons, idk",
                faction_support = {
                    SPARK_BARONS = 3,
                    BILEBROKERS = 2,
                    CULT_OF_HESH = -4,
                    BOGGERS = -2,
                },
                wealth_support = {
                    -3,
                    0,
                    1,
                    0,
                },
            },
            [0] = {
                name = "Don't care",
                desc = "Why would I care?",
                faction_support = {
                    BILEBROKERS = -1,
                    CULT_OF_HESH = -1,
                },
                wealth_support = {
                    -1,
                },
            },
            [1] = {
                name = "Restrict Research & Use",
                desc = "Research and use of artifacts are regulated.",
                faction_support = {
                    SPARK_BARONS = -3,
                    BILEBROKERS = -2,
                    CULT_OF_HESH = 3,
                    BOGGERS = 1,
                },
                wealth_support = {
                    2,
                    0,
                    -3,
                    0,
                },
            },
            [2] = {
                name = "Artifact Preservation",
                desc = "Forbid anyone from using them or researching them. For religious reasons.",
                faction_support = {
                    SPARK_BARONS = -5,
                    BILEBROKERS = -4,
                    CULT_OF_HESH = 5,
                    BOGGERS = 3,
                },
                wealth_support = {
                    3,
                    0,
                    -4,
                    0,
                },
            },
        },
    },
    SUBSTANCE_REGULATION = {
        name = "Substance Regulation",
        desc = "Policies regarding the restriction of certain items.",
        importance = 8,
        stances = {
            [-2] = {
                name = "Legalize Everything",
                desc = "everything, yeah",
                faction_support = {
                    JAKES = 5,
                    ADMIRALTY = -5,
                    BANDITS = 3,
                    CULT_OF_HESH = -4,
                    FEUD_CITIZEN = 2,
                    SPARK_BARONS = -3,
                },
                wealth_support = {
                    3,
                    -5,
                    4,
                    -3,
                },
            },
            [-1] = {
                name = "Relax Restriction",
                desc = "save some resources",
                faction_support = {
                    JAKES = 3,
                    ADMIRALTY = -3,
                    BANDITS = 2,
                    CULT_OF_HESH = -2,
                    FEUD_CITIZEN = 1,
                    SPARK_BARONS = -2,
                },
                wealth_support = {
                    1,
                    -3,
                    3,
                    -2,
                },
            },
            [0] = {
                name = "Keep Unchanged",
                desc = "Policy good enough",
                faction_support = {
                    JAKES = 1,
                    ADMIRALTY = -1,
                    CULT_OF_HESH = -1,
                },
                wealth_support = {
                    0,
                    -1,
                    1,
                    -1,
                },
            },
            [1] = {
                name = "Tighten Restriction",
                desc = "liek relax restriction, but reverse",
                faction_support = {
                    JAKES = -3,
                    ADMIRALTY = 3,
                    BANDITS = -3,
                    CULT_OF_HESH = 2,
                    FEUD_CITIZEN = -1,
                    SPARK_BARONS = 1,
                },
                wealth_support = {
                    -2,
                    3,
                    -3,
                    1,
                },
            },
            [2] = {
                name = "Heavily Enforced Restriction",
                desc = "not only are you adding restriction, you're also actually enforcing it.",
                faction_support = {
                    JAKES = -5,
                    ADMIRALTY = 5,
                    BANDITS = -4,
                    CULT_OF_HESH = 3,
                    FEUD_CITIZEN = -2,
                    SPARK_BARONS = 2,
                },
                wealth_support = {
                    -3,
                    4,
                    -5,
                    2,
                },
            },
        },
    },
    -- small issues
    WELFARE = {
        name = "Welfare Policy",
        desc = "[p] it's obvious to everyone what that is",
        importance = 4,
        stances = {
            [-2] = {
                name = "Welfare Ban",
                desc = "pull yourself up by your bootstrap.",
            },
            [-1] = {
                name = "No Welfare",
                desc = "just no",
            },
            [0] = {
                name = "Token Effort",
                desc = "pretend you are the good guy",
            },
            [1] = {
                name = "Social Safety Net",
                desc = "In case you lost your job.",
            },
            [2] = {
                name = "Universal Basic Income",
                desc = "yang gang",
            },
        },
    },
}
for id, data in pairs(val) do
    data.id = id
    val[id] = IssueLocDef(id, data)
end
Content.internal.POLITICAL_ISSUE = val
return val