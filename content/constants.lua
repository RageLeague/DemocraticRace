return {
    icons = {
        support = engine.asset.Texture("DEMOCRATICRACE:assets/support_icon.png"),
    },
    wealth_levels = 4,
    wealth_string = {
        "DEMOCRACY.WEALTH_STRING.LVL_1",
        "DEMOCRACY.WEALTH_STRING.LVL_2",
        "DEMOCRACY.WEALTH_STRING.LVL_3",
        "DEMOCRACY.WEALTH_STRING.LVL_4",
    },
    wealth_icon = {
        engine.asset.Texture("UI/rarity_common.tex"),
        engine.asset.Texture("UI/rarity_uncommon.tex"),
        engine.asset.Texture("UI/rarity_rare.tex"),
        engine.asset.Texture("UI/rarity_unique.tex"),
    },
    wealth_color = {
        0xa5daaaff,
        0xecf2f2ff,
        0xa5cfefff,
        0xe9d64fff,
    },
    opposition_data = require "DEMOCRATICRACE:content/opposition_candidates",
    issue_data = require "DEMOCRATICRACE:content/political_issues",
}