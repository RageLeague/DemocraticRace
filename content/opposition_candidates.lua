local t = {
    candidate_admiralty = {
        cast_id = "candidate_admiralty",
        character = "MURDER_BAY_ADMIRALTY_CONTACT",
        workplace = "ADMIRALTY_BARRACKS",
        main_supporter = "ADMIRALTY",
        mini_negotiator = "ADMIRALTY_MINI_NEGOTIATOR",

        -- main = "Security for all",
        -- desc = "Oolo plans to improve the safety of Havaria by improving the security. Powered by the Admiralty, of course. Popular among middle class who cannot afford private security, not popular among upper class(because of increased tax rate) and lower class.",
        platform = "SECURITY",
        stances = {
            SECURITY = 2,
            INDEPENDENCE = -2,
            FISCAL_POLICY = 2,
            LABOR_LAW = -1,
            RELIGIOUS_POLICY = 0,
            SUBSTANCE_REGULATION = 1,
            -- WELFARE = 0,
        },
        faction_support = {
            ADMIRALTY = 10,
            FEUD_CITIZEN = 7,
            BANDITS = -10,
            RISE = -7,
            SPARK_BARONS = -3,
            CULT_OF_HESH = 3,
            JAKES = -2,
            BILEBROKERS = 3,
            BOGGERS = -3,
        },
        wealth_support = {
            -7,
            7,
            4,
            -4,
        },
        relationship = {
            candidate_spree = RELATIONSHIP.HATED,
            candidate_rise = RELATIONSHIP.DISLIKED,
            candidate_baron = RELATIONSHIP.LIKED,
        },
    },
    candidate_spree = {
        cast_id = "candidate_spree",
        character = "MURDER_BAY_BANDIT_CONTACT",
        workplace = "SPREE_INN",
        main_supporter = "BANDITS",
        mini_negotiator = "SPREE_MINI_NEGOTIATOR",

        platform = "INDEPENDENCE",

        stances = {
            SECURITY = -2,
            INDEPENDENCE = 2,
            FISCAL_POLICY = 0,
            LABOR_LAW = 0,
            RELIGIOUS_POLICY = 0,
            SUBSTANCE_REGULATION = -2,
            -- WELFARE = 1,
        },
        -- main = "Havaria Independence",
        -- desc = "Nadan wants to cut the ties of Havaria with Deltree. Popular among poorer people, but unpopular among the rich, Admiralty, and the Cult.",
        faction_support = {
            ADMIRALTY = -10,
            FEUD_CITIZEN = 4,
            BANDITS = 10,
            RISE = -2,
            SPARK_BARONS = -4,
            CULT_OF_HESH = -7,
            JAKES = 7,
            BILEBROKERS = -2,
            BOGGERS = 4,
        },
        wealth_support = {
            7,
            3,
            -3,
            -7,
        },
        relationship = {
            candidate_baron = RELATIONSHIP.DISLIKED,
            candidate_jakes = RELATIONSHIP.LIKED,
        },
    },
    candidate_baron = {
        cast_id = "candidate_baron",
        character = "SPARK_CONTACT",
        workplace = "GB_BARON_HQ",
        main_supporter = "SPARK_BARONS",
        mini_negotiator = "BARON_MINI_NEGOTIATOR",

        -- main = "Tax cut",
        -- desc = "Reduce taxes for all. That's it. That's their plan. Fellemo isn't really that bright. Popular among rich people(and some poor people), but unpopular among those who care about equality and those who have plans for utilizing the taxes.",
        platform = "FISCAL_POLICY",

        stances = {
            SECURITY = 0,
            INDEPENDENCE = 0,
            FISCAL_POLICY = -2,
            LABOR_LAW = -2,
            RELIGIOUS_POLICY = -2,
            SUBSTANCE_REGULATION = 0,
            -- WELFARE = -1,
        },

        faction_support = {
            ADMIRALTY = -10,
            FEUD_CITIZEN = 3,
            BANDITS = 5,
            RISE = -5,
            SPARK_BARONS = 10,
            CULT_OF_HESH = -10,
            JAKES = 7,
            BILEBROKERS = 2,
            BOGGERS = 2,
        },
        wealth_support = {
            -4,
            -8,
            6,
            2,
        },
        relationship = {
            candidate_rise = RELATIONSHIP.HATED,
            candidate_cult = RELATIONSHIP.DISLIKED,
            candidate_jakes = RELATIONSHIP.LIKED,
        },
    },
    candidate_rise = {
        cast_id = "candidate_rise",
        character = "KALANDRA",
        workplace = "GB_LABOUR_OFFICE",
        -- main = "Universal Rights",
        -- desc = "Grant rights to every citizen of Havaria, I don't know, read the Declaration of Rights or something. That mostly means slavery is illegal! Popular among the workers, but unpopular among the Cult, Barons, and all those who exploit the labour of the people.",
        platform = "LABOR_LAW",
        main_supporter = "RISE",
        mini_negotiator = "RISE_MINI_NEGOTIATOR",

        stances = {
            SECURITY = -1,
            INDEPENDENCE = 0,
            FISCAL_POLICY = 1,
            LABOR_LAW = 2,
            RELIGIOUS_POLICY = 0,
            SUBSTANCE_REGULATION = 0,
            -- WELFARE = 2,
        },
        faction_support = {
            ADMIRALTY = -5,
            FEUD_CITIZEN = 6,
            BANDITS = 4,
            RISE = 10,
            SPARK_BARONS = -10,
            CULT_OF_HESH = -7,
            JAKES = 7,
            BILEBROKERS = -2,
            BOGGERS = 0,
        },
        wealth_support = {
            10,
            -3,
            -5,
            -7,
        },
    },
    candidate_cult = {
        cast_id = "candidate_cult",
        -- we confirmed that the bishop is just vix's right hand man. so the only real candidate really is vix.
        character = "VIXMALLI",
        workplace = "PEARL_CULT_COMPOUND",
        main_supporter = "CULT_OF_HESH",
        mini_negotiator = "CULT_MINI_NEGOTIATOR",

        platform = "RELIGIOUS_POLICY",

        stances = {
            SECURITY = 1,
            INDEPENDENCE = -1,
            FISCAL_POLICY = 0,
            LABOR_LAW = -2,
            RELIGIOUS_POLICY = 2,
            SUBSTANCE_REGULATION = 2,
            -- WELFARE = 0,
        },
        faction_support = {
            CULT_OF_HESH = 10,
            SPARK_BARONS = -10,
            FEUD_CITIZEN = 4,
            BOGGERS = 7,
            JAKES = -4,
            BILEBROKERS = -7,
            BANDITS = -2,
            ADMIRALTY = 3,
            RISE = -1,
        },
        wealth_support = {
            7,
            -3,
            -7,
            3,
        },
        relationship = {
            candidate_jakes = RELATIONSHIP.DISLIKED,
        },
    },
    candidate_jakes = {
        cast_id = "candidate_jakes",
        -- temp character
        character = "ANDWANETTE",
        workplace = "PEARL_PARTY_STORE",
        main_supporter = "JAKES",
        mini_negotiator = "JAKES_MINI_NEGOTIATOR",

        -- main = "Deregulation",
        -- desc = "Drops many regulation to allow a healthier economy.",
        platform = "SUBSTANCE_REGULATION",

        stances = {
            SECURITY = 0,
            INDEPENDENCE = 1,
            FISCAL_POLICY = -2,
            LABOR_LAW = 1,
            RELIGIOUS_POLICY = -1,
            SUBSTANCE_REGULATION = -2,
            -- WELFARE = 0,
        },
        faction_support = {
            ADMIRALTY = -10,
            FEUD_CITIZEN = 2,
            BANDITS = 7,
            RISE = 0,
            SPARK_BARONS = 3,
            CULT_OF_HESH = -10,
            JAKES = 10,
            BILEBROKERS = 3,
        },
        wealth_support = {
            3,
            -4,
            3,
            -7,
        },
    },
}
for id, data in pairs(t) do
    if not data.cast_id then
        data.cast_id = id
    end
    if not data.main_supporter then
        data.main_supporter = Content.GetCharacterDef(data.character).faction_id
    end
end
return t
