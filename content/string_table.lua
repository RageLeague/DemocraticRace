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
        COLLECT_DECK =
        {
            SUCCESS = "Success!",
            SUCCESS_DESC = "Your deck is copied onto your clipboard. Visit https://forms.gle/2YWzmuUgN8KmTcJj9 to submit your deck.",
            NOT_IN_GAME = "Error: Not In a Game",
            NOT_IN_GAME_DESC = "You are currently not in a campaign.",
            WRONG_CAMPAIGN = "Error: Wrong Campaign",
            WRONG_CAMPAIGN_DESC = "You are playing in a campaign other than the Democratic Race.",
        },
        CONTROLS =
        {
            SWITCH_MODE = "{1#binding} Switch Mode",
        },
        DELTA_SUPPORT_REASON =
        {
            DEFAULT_UP = "Favorable Action",
            DEFAULT_DOWN = "Unfavorable Action",

            COMPLETED_QUEST = "Rally Quest Completed",
            COMPLETED_QUEST_MAIN = "Main Quest Completed",
            COMPLETED_QUEST_REQUEST = "Request Quest Completed",
            FAILED_QUEST = "Quest Failed",
            POOR_QUEST = "Poor Quest Result",

            RELATIONSHIP_UP = "Improved Relationship",
            RELATIONSHIP_DOWN = "Bad Relationship",

            ATTACK = "Unprovoked Attack",
            MURDER = "Murder",
            SUSPICION = "Suspicion of Murder",
            ACCOMPLICE = "Accomplice to Murder",
            NEGLIGENCE = "Negligence",

            PAID_SHILLS = "Paid Shills",

            STANCE_TAKEN = "Stance Taken",
            ALLIANCE_FORMED = "Alliance Formed",
            ENEMY_MADE = "Enemy Made",

            CONSISTENT_STANCE = "Consistent Stance",
            INCONSISTENT_STANCE = "Inconsistent Stance",
        },
        MAIN_OVERLAY = {
            VIEW_SUPPORT = "<#TITLE>View Support</>\nGeneral support: {1}",
        },
        METRICS =
        {
            TITLE = "Metric Collection Enabled",
            DESC = "Since the last update, the Democratic Race mod now has a metrics collection system in place. It helps us imrpove the mod. You may choose to continue with metrics collecction enabled, or, if you don't want to, you can disable it in the mod options menu.\nOh yeah we figured out how to do metrics collection in mods, I guess that is important.",
        },
        NOTIFICATION =
        {
            AGENT_SUPPORT =
            {
                TITLE_INCREASE = "Gained Support From {1#agent}",
                TITLE_DECREASE = "Lost Support From {1#agent}",
                DETAIL_INCREASE = "Gained {1} general support, {2} support from {4#faction} and among {5#wealth_name} {2} due to {3}.",
                DETAIL_DECREASE = "Lost {1} general support, {2} support from {4#faction} and among {5#wealth_name} {2} due to {3}.",
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
            TIME_PASSED =
            {
                TITLE = "{1} {1*Action|Actions} Spent",
                DETAIL = "You have spent {1} {1*action|actions} on {2}. You have {3} {3*action|actions} left for this free time.",
                DETAIL_NO_FREE = "You have spent {1} {1*action|actions} on {2}. You have no more free time.",
                REASON =
                {
                    ACTION = "performing a task",
                    NEGOTIATION = "negotiation",
                    BATTLE = "battle",
                    TRAVEL = "travelling",
                },
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
            SUPPORT_EXPECTATION = "Expected Support: {1}/{2}",
        },
        SUPPORT_SCREEN =
        {
            TITLE = "Support Analysis",
            DESC = "To get elected, you need to have high support among the people. Your advisor has compiled the support breakdown for your campaign. Use this to carefully plan your campaign.",


            CURRENT_STANCE = "{1#agent}'s current stance is {2#pol_stance}",
            CURRENT_STANCE_LOOSE = "{1#agent}'s current stance is favoring {2#pol_stance}",

            GENERAL_SUPPORT_TITLE = "General Support",
            GENERAL_SUPPORT_DESC = "This indicates how popular you are among the people. The more support you have, the more likely it is for someone to vote for you.\n\nChange to the general support also indirectly affects your support among factions and wealth levels.",

            FACTION_SUPPORT_DESC = "This indicates how popular you are among {1#faction}. The more support you have among this faction, the more likely someone from this faction will vote for you, and the more likely their main candidate will ally with you.",

            WEALTH_SUPPORT_DESC = "This indicates how popular you are among {1#wealth_name}. The more support you have among this wealth level, the more likely someone from it will vote for you, and the more funding you will get from this wealth level.",

            EXPECTED_SUPPORT_TITLE = "Expected Support",
            EXPECTED_SUPPORT_DESC = "This indicates the baseline used to calculate how popular you are among the people. Having your support above the expectation means people are more likely to vote for you, while having your support below the expectation means people are more likely to vote for your opposition.\n\n" ..
                "The first value indicates the expected support at the moment, while the second value indicates the expected support at the end of today. The advisor will judge your support level at the end of each day, so be prepared!",

            GAIN_SOURCE = "Source Of Gain:",
            LOSS_SOURCE = "Source Of Loss:",

            SWITCH_MODE = "Switch mode",
            SWITCH_MODE_TT = "The current mode: <#HILITE>{1}</>\n\n{2}\n\nClick on this button or press {3#binding} to switch to another mode.",
            MODE = {
                DEFAULT_TITLE = "Default",
                DEFAULT_DESC = "Shows the absolute value of your support level.",
                RELATIVE_GENERAL_TITLE = "Relative to General Support",
                RELATIVE_GENERAL_DESC = "Shows the support level relative to your general support level. Useful for determining how much you've done to specifically boost your support among certain demographics.",
                RELATIVE_CURRENT_TITLE = "Relative to Current Expectation",
                RELATIVE_CURRENT_DESC = "Shows the support level relative to your current support expectation(1st value). Useful for determining your current support among certain demographics.",
                RELATIVE_GOAL_TITLE = "Relative to Daily Goal",
                RELATIVE_GOAL_DESC = "Shows the support level relative to your support goal of today(2nd value). Useful for not getting kicked out by your advisor.",
            },
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
        MAINMENU = {
            RACE_TUTORIAL = "The Democratic Race",
        },
        PAUSEMENU = {
            RACE_TUTORIAL = "DEMOCRATIC RACE",
        },
        RACE_TUTORIAL_TITLE = "Democratic Race Tutorial: Support",
        RACE_TUTORIAL_BODY = "Would you like to see a quick tutorial on support levels? You can review it at any time from the pause menu.",
    },
    MISC =
    {
        DO_NOTHING = "do nothing",
        ME = "me",
    },
})
