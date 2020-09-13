Content.AddStringTable("DEMOCRACY", {
    DEMOCRACY =
    {
        NOTIFICATION = 
        {
            AGENT_SUPPORT =
            {
                TITLE_INCREASE = "Gained {1} Support From {2#agent}",
                TITLE_DECREASE = "Lost {1} Support From {2#agent}",
                DETAIL_INCREASE = "General support increased by {1}.(To {2})\n"..
                    "Support from {3#faction} and among {4#wealth_name} are increased.\n"..
                    "Check your advisor for more info.",
                DETAIL_DECREASE = "General support decreased by {1}.(To {2})\n"..
                    "Support from {3#faction} and among {4#wealth_name} are decreased.\n"..
                    "Check your advisor for more info.",
            },
            FACTION_SUPPORT =
            {
                TITLE_INCREASE = "Gained {1} Support From {2#faction}",
                TITLE_DECREASE = "Lost {1} Support From {2#faction}",
                DETAIL_INCREASE = "Your support level from {2#faction} is increased to {1}.",
                DETAIL_DECREASE = "Your support level from {2#faction} is decreased to {1}.",
            },
            GENERAL_SUPPORT =
            {
                TITLE_INCREASE = "Gained {1} Support",
                TITLE_DECREASE = "Lost {1} Support",
                DETAIL_INCREASE = "Your support level is increased to {1}.",
                DETAIL_DECREASE = "Your support level is decreased to {1}.",
            },
            GROUP_FACTION_SUPPORT = 
            {
                TITLE = "Support Among Factions Changed",
                DETAIL_INCREASE = "Your support levels from {1#faction_list} are increased.",
                DETAIL_DECREASE = "Your support levels from {1#faction_list} are decreased.",
                DETAIL_BOTH = "Your support levels from {1#faction_list} are increased, while your support levels from {2#faction_list} are decreased.",
            },
            WEALTH_SUPPORT =
            {
                TITLE_INCREASE = "Gained {1} Support Among The {2#wealth_name}",
                TITLE_DECREASE = "Lost {1} Support Among The {2#wealth_name}",
                DETAIL_INCREASE = "Your support level among the {2#wealth_name} is increased to {1}.",
                DETAIL_DECREASE = "Your support level among the {2#wealth_name} is decreased to {1}.",
            },
        },
        SUPPORT_ENTRY = 
        {
            FACTION_SUPPORT = "{1#faction}: {2}",
            GENERAL_SUPPORT = "General Support: {1}",
            WEALTH_SUPPORT = "{1#wealth_name}: {2}",
        },
        SUPPORT_SCREEN = 
        {
            TITLE = "Support Analysis",
            DESC = "To get elected, you need to have high support among the people. Your advisor has compiled the support breakdown for your campaign. Use this to carefully plan your campaign.",
        },
        WEALTH_STRING =
        {
            LVL_1 = "Lower Class",
            LVL_2 = "Lower-Middle Class",
            LVL_3 = "Middle Class",
            LVL_4 = "Upper Class",
        },
    },
})