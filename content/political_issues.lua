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
                faction_support = {
                    ADMIRALTY = -6,
                    FEUD_CITIZEN = -5,
                    BANDITS = 6,
                    RISE = 5,
                    CULT_OF_HESH = -3,
                    JAKES = 2,
                },
                wealth_support = {
                    2,
                    -2,
                    -1,
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
                    1,
                    -1,
                    0,
                    0,
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
                    0,
                    1,
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
                    -1,
                    1,
                    0,
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
                    -2,
                    2,
                    -1,
                    -1,
                },
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
                desc = "There is no point in distinguish between Havaria and Deltree. The Admiralty more or less controls Havaria anyway, so things won't change much. Plus, annexing Havaria can make trading andadministration easier, as well as improving Havarian's living conditions.",
                faction_support = {
                    ADMIRALTY = 5,
                    FEUD_CITIZEN = -4,
                    BANDITS = -5,
                    CULT_OF_HESH = 3,
                    JAKES = -3,
                },
                wealth_support = {
                    -3,
                    -2,
                    0,
                    3,
                },
            },
            [-1] = {
                name = "Havarian Special Administration",
                desc = "Many locals won't like the annexation of Havaria. However, Havaria is better off if it is part of Deltree. As a compromise, Havaria is part of Deltree by name, but Havaria has partial autonomy to allow better integration.",
                faction_support = {
                    ADMIRALTY = 3,
                    FEUD_CITIZEN = -2,
                    BANDITS = -3,
                    CULT_OF_HESH = 2,
                    JAKES = -1,
                },
                wealth_support = {
                    -2,
                    0,
                    0,
                    1,
                },
            },
            [0] = {
                name = "Turn A Blind Eye",
                desc = "The tension between Deltree and Havaria is too high, that no one will benefit if a decision is made immediately. It's probably better to not touch on this issue.",
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
                desc = "It is undeniable that Havarian lives will be better under Deltrean protection. However, it is also important to Havarian autonomy that Havaria and Deltree are separate nations. Therefore, Havaria should become a vassal state of Deltree, but Deltree should respect Havaria's sovereignty.",
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
                desc = "Deltree wants to conquer Havaria, and we won't allow that. Havaria will become completely independent of Deltree, and Deltree should recognize the independence and not interfere with Havarian politics.",
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
                    -4,
                },
            },
        },
    },
    TAX_POLICY = {
        name = "Tax Policy",
        desc = "Taxes are huge issues in society. On the one hand, increasing taxes means more funding for important infrastructures that benefits everyone. On the other hand, it adds toll to the people's wealth, and can lead to high corruption.",
        importance = 9,
        stances = {
            [-2] = {
                name = "Abolish Taxes",
                desc = "Taxes are tools invented by those in power to legally steal people's hard work, therefore all taxes should be abolished. The people can find better uses for the money than giving them up to the coffers of those in power.",
                faction_support = {
                    SPARK_BARONS = 5,
                    ADMIRALTY = -5,
                    RISE = -2,
                    CULT_OF_HESH = -4,
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
                desc = "While it is important that public infrastructure to be funded, at the current state, the taxes are just going to corrupted officials. The taxes has taken a huge toll on the people, therefore it should be reduced.",
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
                desc = "The amount of taxes is balanced at the current state, so it is not necessary to change it.",
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
                desc = "While lots of people don't like taxes, taxes are important tools to maintain public services and infrastructures, as well as reduce the huge wealth inequality that is rampant in Havaria. Therefore, it should be increased.",
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
                desc = "It is important to keep the ruling people funded so that they can provide their services for the people. The taxes collected are all eventually given back to the people. Therefore, taxes should be increased as high as possible, so that public services are properly funded.",
                faction_support = {
                    SPARK_BARONS = -6,
                    ADMIRALTY = 6,
                    CULT_OF_HESH = 5,
                    RISE = -1,
                    FEUD_CITIZEN = -4,
                    JAKES = -3,
                    BANDITS = -3,
                },
                wealth_support = {
                    -3,
                    2,
                    -1,
                    -5,
                },
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
                faction_support = {
                    SPARK_BARONS = 5,
                    ADMIRALTY = 1,
                    CULT_OF_HESH = 3,
                    RISE = -5,
                    FEUD_CITIZEN = -2,
                    JAKES = -4,
                },
                wealth_support = {
                    -4,
                    -2,
                    2,
                    3,
                },
            },
            [-1] = {
                name = "Pro-Employer",
                desc = "While the worker's rights should be respected, their rights cannot interfere with the productivity of the workplace. The government should provide the tools necessary for employers to enforce their rights, such as passing a law allowing employers to bust down strikes.",
                faction_support = {
                    SPARK_BARONS = 3,
                    -- ADMIRALTY = 1,
                    CULT_OF_HESH = 2,
                    RISE = -4,
                    FEUD_CITIZEN = -1,
                    JAKES = -2,
                },
                wealth_support = {
                    -2,
                    -1,
                    0,
                    2,
                },
            },
            [0] = {
                name = "Laissez Faire",
                desc = "When regarding labor laws, Laissez Faire is the best way to treat it. By that, I mean completely ignore the issue and let the market decide. If the workers want better rights, they can find a better place to work, forcing the employers to improve their working conditions.",
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
                desc = "While it is the employers' job to maintain the efficiency of the worksite, they cannot do so while infringing upon the rights of the workers. The government should pass laws that gives workers more rights and powers to fight against poor working conditions.",
                faction_support = {
                    SPARK_BARONS = -3,
                    ADMIRALTY = -2,
                    CULT_OF_HESH = -3,
                    RISE = 3,
                    FEUD_CITIZEN = 2,
                    JAKES = 2,
                },
                wealth_support = {
                    2,
                    1,
                    -2,
                    -3,
                },
            },
            [2] = {
                name = "Socialism",
                desc = "The workers are the ones doing the job, so why should the employers profit from it? By cutting out the middle man, the workers can enjoy better working conditions and better wages, as well as working more efficiently. Therefore, the means of production should fall under the hands of the workers.",
                faction_support = {
                    SPARK_BARONS = -5,
                    ADMIRALTY = -3,
                    CULT_OF_HESH = -4,
                    RISE = 5,
                    FEUD_CITIZEN = 2,
                    JAKES = -1,
                },
                wealth_support = {
                    4,
                    2,
                    -3,
                    -5,
                },
            },
        },
    },
    ARTIFACT_TREATMENT = {
        name = "Artifact Treatment",
        desc = "There are a plenty of artifacts in Havaria, left over from the Vagrant Age. There are dividing opinions on what should we do about them. The Cult thinks that they should be preserved, while the Barons think they should be researched and used.",
        importance = 6,
        stances = {
            [-2] = {
                name = "Extensive Research & Use",
                desc = "The Vagrant Age has left us lots of powerful tools, and it would be a shame if they are not used. That's why we need to extensively research and use all the artifacts we dig up, and we need to dig up more artifacts for us to use.",
                faction_support = {
                    SPARK_BARONS = 5,
                    BILEBROKERS = 3,
                    JAKES = 2,
                    CULT_OF_HESH = -5,
                    BOGGERS = -4,
                    FEUD_CITIZEN = -2,
                },
                wealth_support = {
                    -5,
                    2,
                    3,
                    1,
                },
            },
            [-1] = {
                name = "Commercial Use",
                desc = "It might be too costly to extensively research all the artifacts, but it would be a waste if the artifacts just sat there. By encouraging commercial use of the artifacts, we encourage people to look for useful artifacts, and it will strengthen the economy.",
                faction_support = {
                    SPARK_BARONS = 3,
                    BILEBROKERS = 1,
                    CULT_OF_HESH = -4,
                    BOGGERS = -2,
                    JAKES = 3,
                },
                wealth_support = {
                    -3,
                    1,
                    1,
                    0,
                },
            },
            [0] = {
                name = "Do Nothing",
                desc = "The government shouldn't decide what to do with the artifact. It is not their job. The people can figure out what to do on their own.",
                faction_support = {
                    BILEBROKERS = -1,
                    CULT_OF_HESH = -1,
                    JAKES = 1,
                },
                wealth_support = {
                    -1,
                },
            },
            [1] = {
                name = "Restrict Research & Use",
                desc = "The artifacts shouldn't be touched by just anyone. They are dangerous, and we don't want to lose any artifacts because they are important to Havarian history. That's why the research and use of artifacts must be approved first.",
                faction_support = {
                    SPARK_BARONS = -3,
                    BILEBROKERS = -2,
                    CULT_OF_HESH = 3,
                    BOGGERS = 2,
                    JAKES = -2,
                },
                wealth_support = {
                    2,
                    -1,
                    -3,
                    0,
                },
            },
            [2] = {
                name = "Artifact Preservation",
                desc = "The artifacts are holy, and should not be used by anyone. Ever. They should be preserved and displayed in a museum, not used as weapons or other tools. Any research into the uses of the artifacts should be forbidden.",
                faction_support = {
                    SPARK_BARONS = -5,
                    BILEBROKERS = -4,
                    CULT_OF_HESH = 5,
                    BOGGERS = 3,
                    JAKES = -3,
                    FEUD_CITIZEN = 2,
                },
                wealth_support = {
                    3,
                    -1,
                    -4,
                    1,
                },
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
                faction_support = {
                    JAKES = 5,
                    ADMIRALTY = -5,
                    BANDITS = 3,
                    CULT_OF_HESH = -4,
                    FEUD_CITIZEN = 2,
                    SPARK_BARONS = -2,
                },
                wealth_support = {
                    1,
                    -3,
                    3,
                    -2,
                },
            },
            [-1] = {
                name = "Relax Restriction",
                desc = "While some substances are indeed dangerous, plenty of people have been arrested falsely because they are carrying harmless substances. It's better to let them be. Not only does this lead to less people getting arrested for no reason, it can also make the economy flow by expanding trades.",
                faction_support = {
                    JAKES = 3,
                    ADMIRALTY = -3,
                    BANDITS = 2,
                    CULT_OF_HESH = -2,
                    FEUD_CITIZEN = 1,
                    SPARK_BARONS = 1,
                },
                wealth_support = {
                    2,
                    -2,
                    1,
                    -1,
                },
            },
            [0] = {
                name = "Keep Unchanged",
                desc = "The current policy is good enough for now. There is no need to change it.",
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
                desc = "Illegal trading of illicit substances has been going on for so long, and it is not going to end unless we do something. We should tighten the restrictions on illicit substances to stop these illegal tradings.",
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
                    2,
                    -2,
                    2,
                },
            },
            [2] = {
                name = "Heavily Enforced Restriction",
                desc = "There are way too many illegal trading of substances, and it negatively impacts the health and morale of the people. To deal with such crisis, we need to increase restrictions on them, and ensure that we send people to properly enforce them.",
                faction_support = {
                    JAKES = -5,
                    ADMIRALTY = 5,
                    BANDITS = -4,
                    CULT_OF_HESH = 3,
                    FEUD_CITIZEN = -2,
                    SPARK_BARONS = -2,
                },
                wealth_support = {
                    -2,
                    3,
                    -4,
                    1,
                },
            },
        },
    },
    -- small issues
    WELFARE = {
        name = "Welfare Policy",
        desc = "A way to address the widespread poverty in Havaria is through welfare. It can help those in need by giving them breathing rooms, so they can recover from poverty. However, critics argue that it encourages laziness, and puts a toll on the taxpayers.",
        importance = 4,
        stances = {
            [-2] = {
                name = "Welfare Ban",
                desc = "Welfare will only encourage laziness, and will be exploited by those who don't work. Therefore, all forms of welfare should be illegal, to encourage those who are in poverty to actually work their way out.",
                faction_support = {
                    SPARK_BARONS = 3,
                    ADMIRALTY = 1,
                    FEUD_CITIZEN = -3,
                    RISE = -3,
                },
                wealth_support = {
                    -5,
                    -3,
                    1,
                    5,
                },
            },
            [-1] = {
                name = "No Welfare",
                desc = "While we should help those in need, it is not the place of the state to do so. It will cost too much taxpayer money. If someone wants to help the poor, let them do that, but the state will do nothing.",
                faction_support = {
                    SPARK_BARONS = 2,
                    ADMIRALTY = 1,
                    FEUD_CITIZEN = -2,
                    RISE = -2,
                },
                wealth_support = {
                    -3,
                    -2,
                    0,
                    2,
                },
            },
            [0] = {
                name = "Token Effort",
                desc = "To show the generosity of the state, we should implement basic welfare programs. However, we shouldn't put too much money in it, because it is not necessary.",
                faction_support = {
                    -- SPARK_BARONS = 2,
                    ADMIRALTY = 1,
                    FEUD_CITIZEN = -1,
                    -- RISE = -2,
                },
                wealth_support = {
                    -1,
                    -1,
                    0,
                    0,
                },
            },
            [1] = {
                name = "Social Safety Net",
                desc = "It is very devastating if someone loses a job in Havaria. As such, we should implement a program that helps those who lose their jobs, to help them recover.",
                faction_support = {
                    SPARK_BARONS = -2,
                    ADMIRALTY = -2,
                    FEUD_CITIZEN = 2,
                    RISE = 1,
                },
                wealth_support = {
                    2,
                    1,
                    0,
                    -3,
                },
            },
            [2] = {
                name = "Universal Basic Income",
                desc = "Everyone should have the opportunity to work towards a future instead of needing to worry about what their next meal should be. Therefore, we should implement UBI, where the government gives everyone what they need to survive.",
                faction_support = {
                    SPARK_BARONS = -4,
                    ADMIRALTY = -3,
                    FEUD_CITIZEN = 3,
                    RISE = 2,
                },
                wealth_support = {
                    4,
                    2,
                    -3,
                    -5,
                },
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