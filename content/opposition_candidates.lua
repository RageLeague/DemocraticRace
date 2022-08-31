local t = {
    candidate_admiralty = {
        cast_id = "candidate_admiralty",
        character = "MURDER_BAY_ADMIRALTY_CONTACT",
        workplace = "ADMIRALTY_BARRACKS",
        main_supporter = "ADMIRALTY",
        mini_negotiator = "ADMIRALTY_MINI_NEGOTIATOR",
        faction_core = "POWER_ABUSE",

        -- main = "Security for all",
        -- desc = "Oolo plans to improve the safety of Havaria by improving the security. Powered by the Admiralty, of course. Popular among middle class who cannot afford private security, not popular among upper class(because of increased tax rate) and lower class.",
        platform = "SECURITY",
        stances = {
            SECURITY = 2,
            INDEPENDENCE = -2,
            FISCAL_POLICY = 0,
            LABOR_LAW = -1,
            RELIGIOUS_POLICY = 0,
            SUBSTANCE_REGULATION = 1,
            -- WELFARE = 0,
        },
        faction_support = {
            ADMIRALTY = 10,
            FEUD_CITIZEN = 3,
            BANDITS = -8,
            RISE = -4,
            SPARK_BARONS = 1,
            CULT_OF_HESH = 5,
            JAKES = -7,
            BILEBROKERS = -1,
            BOGGERS = -1,
        },
        wealth_support = {
            -4,
            2,
            -2,
            4,
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
        faction_core = "SHORT_FUSE",

        platform = "INDEPENDENCE",

        stances = {
            SECURITY = -2,
            INDEPENDENCE = 2,
            FISCAL_POLICY = 1,
            LABOR_LAW = 0,
            RELIGIOUS_POLICY = 0,
            SUBSTANCE_REGULATION = -2,
            -- WELFARE = 1,
        },
        -- main = "Havaria Independence",
        -- desc = "Nadan wants to cut the ties of Havaria with Deltree. Popular among poorer people, but unpopular among the rich, Admiralty, and the Cult.",
        faction_support = {
            ADMIRALTY = -10,
            FEUD_CITIZEN = 0,
            BANDITS = 10,
            RISE = 2,
            SPARK_BARONS = -2,
            CULT_OF_HESH = -6,
            JAKES = 6,
            BILEBROKERS = 0,
            BOGGERS = 2,
        },
        wealth_support = {
            5,
            -2,
            2,
            -5,
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
        faction_core = "APPROPRIATOR",

        -- main = "Tax cut",
        -- desc = "Reduce taxes for all. That's it. That's their plan. Fellemo isn't really that bright. Popular among rich people(and some poor people), but unpopular among those who care about equality and those who have plans for utilizing the taxes.",
        platform = "FISCAL_POLICY",

        stances = {
            SECURITY = 1,
            INDEPENDENCE = 1,
            FISCAL_POLICY = -2,
            LABOR_LAW = -2,
            RELIGIOUS_POLICY = -2,
            SUBSTANCE_REGULATION = 0,
            -- WELFARE = -1,
        },

        faction_support = {
            ADMIRALTY = 4,
            FEUD_CITIZEN = 2,
            BANDITS = -2,
            RISE = -10,
            SPARK_BARONS = 10,
            CULT_OF_HESH = -8,
            JAKES = 4,
            BILEBROKERS = 2,
            BOGGERS = -2,
        },
        wealth_support = {
            -4,
            -1,
            2,
            3,
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
        faction_core = "CALL_TO_RISE",

        stances = {
            SECURITY = -1,
            INDEPENDENCE = 0,
            FISCAL_POLICY = 2,
            LABOR_LAW = 2,
            RELIGIOUS_POLICY = -1,
            SUBSTANCE_REGULATION = 0,
            -- WELFARE = 2,
        },
        faction_support = {
            ADMIRALTY = -5,
            FEUD_CITIZEN = 2,
            BANDITS = 4,
            RISE = 10,
            SPARK_BARONS = -10,
            CULT_OF_HESH = -5,
            JAKES = 4,
            BILEBROKERS = 1,
            BOGGERS = 0,
        },
        wealth_support = {
            6,
            2,
            -3,
            -5,
        },
    },
    candidate_cult = {
        cast_id = "candidate_cult",
        -- we confirmed that the bishop is just vix's right hand man. so the only real candidate really is vix.
        character = "VIXMALLI",
        workplace = "PEARL_CULT_COMPOUND",
        main_supporter = "CULT_OF_HESH",
        mini_negotiator = "CULT_MINI_NEGOTIATOR",
        faction_core = "ZEAL",

        platform = "RELIGIOUS_POLICY",

        stances = {
            SECURITY = 0,
            INDEPENDENCE = -1,
            FISCAL_POLICY = 0,
            LABOR_LAW = -2,
            RELIGIOUS_POLICY = 2,
            SUBSTANCE_REGULATION = 2,
            -- WELFARE = 0,
        },
        faction_support = {
            CULT_OF_HESH = 10,
            SPARK_BARONS = -8,
            FEUD_CITIZEN = 3,
            JAKES = -4,
            BANDITS = -3,
            ADMIRALTY = 7,
            RISE = -5,
            BILEBROKERS = -3,
            BOGGERS = 1,
        },
        wealth_support = {
            -3,
            0,
            -1,
            4,
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
        faction_core = "DOUBLE_EDGE",

        -- main = "Deregulation",
        -- desc = "Drops many regulation to allow a healthier economy.",
        platform = "SUBSTANCE_REGULATION",

        stances = {
            SECURITY = -1,
            INDEPENDENCE = 0,
            FISCAL_POLICY = -1,
            LABOR_LAW = 1,
            RELIGIOUS_POLICY = 0,
            SUBSTANCE_REGULATION = -2,
            -- WELFARE = 0,
        },
        faction_support = {
            ADMIRALTY = -10,
            FEUD_CITIZEN = 2,
            BANDITS = 5,
            RISE = -1,
            SPARK_BARONS = 3,
            CULT_OF_HESH = -9,
            JAKES = 10,
            BILEBROKERS = 2,
        },
        wealth_support = {
            0,
            -3,
            3,
            0,
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
