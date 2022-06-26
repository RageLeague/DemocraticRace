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
    return loc.format(LOC"DEMOCRACY.STANCE_FOR_ISSUE", self.issue_id) .. "\n\n" .. self:GetLocalizedDesc()
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
    -- oppositions have their unique stances defined
    local opdata = DemocracyUtil.GetOppositionData(agent)
    if opdata and opdata.stances and opdata.stances[self.id] then
        return opdata.stances[self.id]
    end


    local stance_score = {}
    local has_vals = false
    for id, data in pairs(self.stances) do
        stance_score[id] = math.max (0, data:GetAgentSupport(agent))
        if math.abs(id) >= 2 then
            stance_score[id] = math.max(0, stance_score[id] - 3)
        end
        if math.abs(id) == 1 then
            stance_score[id] = math.floor(stance_score[id] / 2)
        end

        if stance_score[id] > 0 then has_vals = true end

    end
    -- print(loc.format("Score for {1#agent}: {2},{3},{4},{5},{6}", agent, stance_score[-2], stance_score[-1], stance_score[0], stance_score[1], stance_score[2] ))
    if has_vals then
        -- we want an agent's stance to be consistent throughout a playthough
        local val = agent:CalculateProperty(self.id, function(agent)
            local total = 0
            for id, data in pairs(stance_score) do
                total = total + data
            end
            local chosen_val = math.random() * total
            -- print("Chosen val lul: " .. chosen_val)
            for i = -2, 2 do
                chosen_val = chosen_val - stance_score[i]
                -- print("After round " .. i .. ":" .. chosen_val)
                if chosen_val <= 0 then
                    return i
                end
            end
            assert(false, "we screwed up with weighted rng")
        end)
        return val
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
    if not issue then
        print("Warning: issue is nil")
        return self
    end
    if not newval then
        print("Warning: newval is nil")
        return self
    end
    -- assert(issue, "issue must be non-nil")
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
        name = "Security Funding",
        desc = "Security is a big issue in Havaria. On the one hand, improving security can drastically reduce crime and improve everyone's lives. On the other hand, it can leads to corruption and abuse of power.",
        importance = 10,
        stances = {
            [-2] = {
                name = "Defund the Admiralty",
                desc = "The Admiralty has always abused their power and made many false arrests. It's better if the Admiralty is defunded, and measures must be put in place to prevent anyone else from taking this power.",
            },
            [-1] = {
                name = "Cut Funding for the Admiralty",
                desc = "While it's important to have some sort of public security, at the current state, the Admiralty has too much power and is abusing it. By cutting their funding, their influence will be reduced.",
            },
            [0] = {
                name = "No Change",
                desc = "The current system works just fine. There's no need to change it.",
            },
            [1] = {
                name = "Increase Funding for the Admiralty",
                desc = "Havaria is overrun with criminals of all kind. That's why we need to improve the security by increasing funding for the Admiralty. This way, the people can live in peace.",
            },
            [2] = {
                name = "Security for All",
                desc = "Havaria is overrun with criminals of all kind, and the only way to fix it is through drastic measures. By funding for Security for All, everyone, regardless of social status, can be protected from criminals.",
            },
        },
    },
    INDEPENDENCE = {
        name = "Deltrean-Havarian Annex",
        desc = "The annexation of Havaria into Deltree has stroke controversies across Havaria. On the one hand, a full integration of Havaria to Deltree will likely improve Havaria's living conditions, and makes paperworks easier. On the other hand, it is a blatant disregard to Havaria's sovereignty.",
        importance = 8,
        stances = {
            [-2] = {
                name = "Total Annexation",
                desc = "There is no point in distinguish between Havaria and Deltree. The Admiralty more or less controls Havaria anyway, so things won't change much. Plus, annexing Havaria can make trading easier, as well as improving Havarian's living conditions.",
            },
            [-1] = {
                name = "Havarian Special Administration",
                desc = "Many locals won't like the annexation of Havaria. However, Havaria is better off if it is part of Deltree. As a compromise, Havaria is part of Deltree by name, but Havaria has partial autonomy to allow better integration.",
            },
            [0] = {
                name = "Turn A Blind Eye",
                desc = "The tension between Deltree and Havaria is too high, that no one will benefit if a decision is made immediately. It's probably better to not touch on this issue.",
            },
            [1] = {
                name = "Vassal State",
                desc = "It is undeniable that Havarian lives will be better under Deltrean protection. However, it is also important to Havarian autonomy that Havaria and Deltree are separate nations. Therefore, Havaria should become a vassal state of Deltree, but Deltree should respect Havaria's sovereignty.",
            },
            [2] = {
                name = "Havaria Independence",
                desc = "Deltree wants to conquer Havaria, and we won't allow that. Havaria will become completely independent of Deltree, and Deltree should recognize the independence and not interfere with Havarian politics.",
            },
        },
    },
    FISCAL_POLICY = {
        name = "Fiscal Policy",
        desc = "Fiscal policies describes how much the government intervenes with the economy. To little intervention will cause those in need to be unable to get the support they need from the government, while too much intervention will cause an increase in governmental spending and taxes.",
        importance = 9,
        stances = {
            [-2] = {
                name = "Laissez Faire",
                desc = "The government should completely leave the economy alone. The invisible hand will make the market efficient, and any intervention will only cause problems. Taxes should be reduced to a minimum, and the government should not support anyone financially.",
            },
            [-1] = {
                name = "Reduced Intervention",
                desc = "While it's sometimes beneficial for the government to intervene with the economy, it isn't something that the government should do often. As such, the government should reduce some of its programs, such as welfare, and in turn, it reduces taxes.",
            },
            [0] = {
                name = "Keep As It Is",
                desc = "The current economic situation in Havaria is very stable. There is no need to change either way.",
            },
            [1] = {
                name = "Increased Intervention",
                desc = "Not everyone is fortunate enough to be wealthy, so the government needs to increase its welfare programs. It will increase taxes for some people, but it will level the playing field between the rich and the poor.",
            },
            [2] = {
                name = "Planned Economy",
                desc = "Free market will only cause the rich to become richer and the poor to become poorer. The government should control lots of aspects of the economy, such as the prices of goods and wealth distribution.",
            },
        },
    },
    LABOR_LAW = {
        name = "Labor Laws",
        desc = "There are a lot of conflicts in workplaces, so it is an important issue to set up laws that regulates them. On the one hand, laws that are pro-employer can ensure that the efficiency of the workplace aren't disrupted by random elements, but it can lead to discontent among the workers.",
        importance = 9,
        stances = {
            [-2] = {
                name = "State-Enforced Employer Protection",
                desc = "Employers' rights should be protected at all cost to ensure the efficiency of workplaces. All organized attempt to disrupt the harmony of the workplaces must be eliminated, therefore the state should pass laws that bans trade unions and enforce these laws through the state.",
            },
            [-1] = {
                name = "Pro-Employer",
                desc = "While the worker's rights should be respected, their rights cannot interfere with the productivity of the workplace. The government should provide the tools necessary for employers to enforce their rights, such as passing a law allowing employers to bust down strikes.",
            },
            [0] = {
                name = "Laissez Faire",
                desc = "When regarding labor laws, Laissez Faire is the best way to treat it. By that, I mean completely ignore the issue and let the market decide. If the workers want better rights, they can find a better place to work, forcing the employers to improve their working conditions.",
            },
            [1] = {
                name = "Pro-Worker",
                desc = "While it is the employers' job to maintain the efficiency of the worksite, they cannot do so while infringing upon the rights of the workers. The government should pass laws that gives workers more rights and powers to fight against poor working conditions.",
            },
            [2] = {
                name = "Socialism",
                desc = "The workers are the ones doing the job, so why should the employers profit from it? By cutting out the middle man, the workers can enjoy better working conditions and better wages, as well as working more efficiently. Therefore, the means of production should fall under the hands of the workers.",
            },
        },
    },
    RELIGIOUS_POLICY = {
        name = "Religious Policy",
        desc = "The Cult of Hesh is the dominant religion in Havaria, and naturally, policy maker need to be aware of it when making policies. Making policies around the religion can make those religious happy, but it can obstruct activities that are otherwise not a problem like free trade.",
        importance = 8,
        stances = {
            [-2] = {
                name = "Atheism",
                desc = "There is no proof that Hesh really exist, and if it does, it shouldn't be worshipped. When making policies, we should not worry about what the Cult or Hesh thinks, and do whatever we want.",
            },
            [-1] = {
                name = "Secular Focus",
                desc = "While we need to worry about Hesh when making policies, we cannot let it interfere with normal activities. Small transgressions against Hesh should be tolerated, if it gives more benefits in the long run.",
            },
            [0] = {
                name = "Balanced",
                desc = "While making policies, we need to find a balance between religion and practicality, as such, the policies needs to be balanced around that.",
            },
            [1] = {
                name = "Religious Focus",
                desc = "While we don't have to follow the religion of Hesh to the exact point, we need to focus on policy on it. Doing so will appeal to the religious.",
            },
            [2] = {
                name = "Fanaticism",
                desc = "Hesh is to be feared, and its will must be exercised. Any heretical activities shall not be tolerated.",
            },
        },
    },
    SUBSTANCE_REGULATION = {
        name = "Substance Regulation",
        desc = "Certain substances are more problematic than others, and it is important to figure out what to do with them. On the one hand, the government has the responsibility to protect the citizens from harmful substances. On the other hand, having too much restriction means more money spent on enforcements, and it makes many people unhappy.",
        importance = 8,
        stances = {
            [-2] = {
                name = "Legalize Everything",
                desc = "There's no point in banning any substances. If a person really wants something, they will get it no matter what. Substance regulation is just a way for those in power to arrest people on false charges. Therefore, all substances should be legalized.",
            },
            [-1] = {
                name = "Relax Restriction",
                desc = "While some substances are indeed dangerous, plenty of people have been arrested falsely because they are carrying harmless substances. It's better to let them be. Not only does this lead to less people getting arrested for no reason, it can also make the economy flow by expanding trades.",
            },
            [0] = {
                name = "Keep Unchanged",
                desc = "The current policy is good enough for now. There is no need to change it.",
            },
            [1] = {
                name = "Tighten Restriction",
                desc = "Illegal trading of illicit substances has been going on for so long, and it is not going to end unless we do something. We should tighten the restrictions on illicit substances to stop these illegal tradings.",
            },
            [2] = {
                name = "Heavily Enforced Restriction",
                desc = "There are way too many illegal trading of substances, and it negatively impacts the health and morale of the people. To deal with such crisis, we need to increase restrictions on them, and ensure that we send people to properly enforce them.",
            },
        },
    },
    -- small issues
}
for id, data in pairs(val) do
    data.id = id
    val[id] = IssueLocDef(id, data)
end

do
    local faction_stances = DemocracyUtil.LoadCSV("DEMOCRATICRACE:content/stances/stance_faction.csv")

    assert(faction_stances, "Fail to load faction stances")

    local first_row = faction_stances[1]

    local current_issue
    local current_stance

    for i, row in ipairs(faction_stances) do
        if i ~= 1 then
            for j, entry in ipairs(row) do
                if j == 1 then
                    if entry:sub(1,1) == "!" then
                        current_issue = entry:sub(2,-1)
                        break
                    else
                        current_stance = tonumber(entry)
                        if current_stance == nil then
                            break
                        end
                    end
                else
                    local label = first_row[j]
                    if label == "" or string.find(label, ":.*:") then
                    else
                        if entry == "" then
                            entry = "0"
                        end
                        local entry_value = tonumber(entry) or 0
                        assert(current_issue, "Current issue must be non-nil")
                        assert(current_stance, "Current stance must be non-nil")
                        val[current_issue].stances[current_stance].faction_support = val[current_issue].stances[current_stance].faction_support or {}
                        val[current_issue].stances[current_stance].faction_support[label] = entry_value
                    end
                end
            end
        end
    end
end
do
    local wealth_stances = DemocracyUtil.LoadCSV("DEMOCRATICRACE:content/stances/stance_wealth.csv")

    assert(wealth_stances, "Fail to load wealth stances")

    local first_row = wealth_stances[1]

    local current_issue
    local current_stance

    for i, row in ipairs(wealth_stances) do
        if i ~= 1 then
            for j, entry in ipairs(row) do
                if j == 1 then
                    if entry:sub(1,1) == "!" then
                        current_issue = entry:sub(2,-1)
                        break
                    else
                        current_stance = tonumber(entry)
                        if current_stance == nil then
                            break
                        end
                    end
                else
                    local label = first_row[j]
                    -- print("\"" .. label .. "\"")
                    -- print(type(label))
                    -- print(string.find(label, "^[:].*[:]$"))
                    -- if label == ":Total:" then
                    --     print(":Total: found")
                    -- end
                    if label == "" or string.find(label, ":.*:") then
                    else
                        if entry == "" then
                            entry = "0"
                        end
                        local entry_value = tonumber(entry) or 0
                        assert(current_issue, "Current issue must be non-nil")
                        assert(current_stance, "Current stance must be non-nil")
                        val[current_issue].stances[current_stance].wealth_support = val[current_issue].stances[current_stance].wealth_support or {}
                        assert(tonumber(label), label)
                        val[current_issue].stances[current_stance].wealth_support[tonumber(label)] = entry_value
                    end
                end
            end
        end
    end
end

Content.internal.POLITICAL_ISSUE = val
return val
