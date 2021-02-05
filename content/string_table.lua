Content.AddStringTable("DEMOCRACY", {
    DEMOCRACY =
    {
        ADVANCEMENT =
        {
            LEVEL_0_NAME = "Level 0: Law school",
            LEVEL_0_DESC = "For those who just wants to enjoy the story.\nNegotiations are significantly easier.\nYour advisor has more faith in you.",
            LEVEL_1_NAME = "Level 1: The first real test",
            LEVEL_1_DESC = "The default experience for the Democratic Race.\nDefault negotiation difficulty.\nYour advisors will abandon you if you don't have much support.",
            LEVEL_2_NAME = "Level 2: The Griftlands strikes back",
            LEVEL_2_DESC = "You cannot restart the day after losing.\nNon-boss enemies have upgraded abilities, and have a chance to spawn as a promoted version.\nNegotiation opponents have improved arguments.",
            LEVEL_3_NAME = "Level 3: Hostile population",
            LEVEL_3_DESC = "Negotiation opponents have increased resolve and damage.\nChallenge negotiations are more challenging.\nYour advisor has higher expectations.",
            LEVEL_4_NAME = "Level 4: Keep your hands clean",
            LEVEL_4_DESC = "Resolve is no longer restored after battle.\nOnly heal 50% of your health and resolve when sleeping.\nEngaging in battle hurts your reputation.",
            LEVEL_5_NAME = "Level 5: Tricky enemies",
            LEVEL_5_DESC = "Challenge negotiations are even more challenging.\nMore people dislike you on principle.",
            LEVEL_6_NAME = "Level 6: Strive for perfection",
            LEVEL_6_DESC = "Start with 20% less maximum health and maximum resolve.\nYour advisor has even higher expectations.",
            LEVEL_7_NAME = "Level 7: Do more with less",
            LEVEL_7_DESC = "Everything costs 25% more shills.\nStart with 1 fewer battle graft slots and negotiation graft slots.",
            LEVEL_8_NAME = "Level 8: Test your mettle",
            LEVEL_8_DESC = "You no longer earn Mettle, and your Mettle upgrades are disabled.",
        },
        DELTA_SUPPORT_REASON =
        {
            DEFAULT_UP = "favorable action",
            DEFAULT_DOWN = "unfavorable action",
            
            COMPLETED_QUEST = "quest completed",
            FAILED_QUEST = "quest failed",
            POOR_QUEST = "poor quest result",

            RELATIONSHIP_UP = "improved relationship",
            RELATIONSHIP_DOWN = "bad relationship",

            ATTACK = "unprovoked attack",
            MURDER = "murder",
            SUSPICION = "suspicion of murder",
            ACCOMPLICE = "accomplice to murder",
            NEGLIGENCE = "negligence",

            CONSISTENT_STANCE = "consistent stance",
            INCONSISTENT_STANCE = "hypocrisy",
        },
        NOTIFICATION = 
        {
            AGENT_SUPPORT =
            {
                TITLE_INCREASE = "Gained {1} Support From {2#agent}",
                TITLE_DECREASE = "Lost {1} Support From {2#agent}",
                DETAIL_INCREASE = "General support, support from {3#faction} and among {4#wealth_name} " ..
                    "are increased by {1} due to {2}.",
                DETAIL_DECREASE = "General support, support from {3#faction} and among {4#wealth_name} " ..
                    "are decreased by {1} due to {2}.",
            },
            FACTION_SUPPORT =
            {
                TITLE_INCREASE = "Gained {1} Support From {2#faction}",
                TITLE_DECREASE = "Lost {1} Support From {2#faction}",
                DETAIL_INCREASE = "Your support from {2#faction} is increased to {1} due to {3}.",
                DETAIL_DECREASE = "Your support from {2#faction} is decreased to {1} due to {3}.",
            },
            GENERAL_SUPPORT =
            {
                TITLE_INCREASE = "Gained {1} Support",
                TITLE_DECREASE = "Lost {1} Support",
                DETAIL_INCREASE = "Your support is increased to {1} due to {2}.",
                DETAIL_DECREASE = "Your support is decreased to {1} due to {2}.",
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
                DETAIL_LOOSE = "Your stance regarding {1#pol_issue} is updated to favoring {2#pol_stance}.",
                
            },
            WEALTH_SUPPORT =
            {
                TITLE_INCREASE = "Gained {1} Support Among The {2#wealth_name}",
                TITLE_DECREASE = "Lost {1} Support Among The {2#wealth_name}",
                DETAIL_INCREASE = "Your support among the {2#wealth_name} is increased to {1} due to {3}.",
                DETAIL_DECREASE = "Your support among the {2#wealth_name} is decreased to {1} due to {3}.",
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
            TITLE = "End of Alpha",
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
        ME = "me",
    },
})