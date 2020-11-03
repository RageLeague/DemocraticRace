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
                DETAIL_INCREASE = "Your support from {2#faction} is increased to {1}.",
                DETAIL_DECREASE = "Your support from {2#faction} is decreased to {1}.",
            },
            GENERAL_SUPPORT =
            {
                TITLE_INCREASE = "Gained {1} Support",
                TITLE_DECREASE = "Lost {1} Support",
                DETAIL_INCREASE = "Your support is increased to {1}.",
                DETAIL_DECREASE = "Your support is decreased to {1}.",
            },
            GROUP_FACTION_SUPPORT = 
            {
                TITLE = "Support From Factions Changed",
                DETAIL_INCREASE = "Your support from {1#faction_list} are increased.",
                DETAIL_DECREASE = "Your support from {1#faction_list} are decreased.",
                DETAIL_BOTH = "Your support from {1#faction_list} are increased, while your support from {2#faction_list} are decreased.",
            },
            GROUP_WEALTH_SUPPORT = 
            {
                TITLE = "Support Among Classes Changed",
                DETAIL_INCREASE = "Your support among {1#wealth_name_list} are increased.",
                DETAIL_DECREASE = "Your support among {1#wealth_name_list} are decreased.",
                DETAIL_BOTH = "Your support among {1#wealth_name_list} are increased, while your support among {2#wealth_name_list} are decreased.",
            },
            UPDATE_STANCE =
            {
                TITLE = "Stance Updated",
                DETAIL_STRICT = "Your stance regarding {1#pol_issue} is updated to {2#pol_stance}.",
                DETAIL_LOOSE = "Your stance regarding {1#pol_issue} is loosely updated to {2#pol_stance}.",
                
            },
            WEALTH_SUPPORT =
            {
                TITLE_INCREASE = "Gained {1} Support Among The {2#wealth_name}",
                TITLE_DECREASE = "Lost {1} Support Among The {2#wealth_name}",
                DETAIL_INCREASE = "Your support among the {2#wealth_name} is increased to {1}.",
                DETAIL_DECREASE = "Your support among the {2#wealth_name} is decreased to {1}.",
            },
        },
        PUNISH_TARGET_REASON =
        {
            HATRED = "you hate this person",
            QUEST_REQ = "one or more quests require you to punish this person",
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
            LVL_2 = "Middle Class",
            LVL_3 = "Upper Class",
            LVL_4 = "Elite Class",
        },
        WIP_SCREEN = 
        {
            TITLE = "End of Demo",
            BODY = "Congratulations! You have now finished what the mod has to offer as of right now. Please leave a feedback at the steam workshop page, on GitHub, or on Klei's forum, so I can improve this mod.",
            BUTTON = "I win!",
        },
        STANCE_FOR_ISSUE = "This is a stance for the issue: {1#pol_issue}.",
        
    },
    UI = {
        RELATIONSHIP_SCREEN = {
            SUPPRESSED = "SUPPRESSED",
        },
    },
    MISC = 
    {
        DO_NOTHING = "do nothing",
    },
})