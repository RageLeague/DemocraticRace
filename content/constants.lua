return {
    icons = {
        support = engine.asset.Texture("DemocraticRace:assets/support_icon.png"),
    },
    wealth_levels = 4,
    wealth_string = {
        "Lower Class",
        "Lower-Middle Class",
        "Middle Class",
        "Upper Class",
    },
    wealth_icon = {
        engine.asset.Texture("UI/rarity_basic.tex"),
        engine.asset.Texture("UI/rarity_common.tex"),
        engine.asset.Texture("UI/rarity_uncommon.tex"),
        engine.asset.Texture("UI/rarity_rare.tex"),
    },
    wealth_color = {
        0xa5daaaff,
        0xecf2f2ff,
        0xa5cfefff,
        0xe9d64fff,
    },
    opposition_data = require "DemocraticRace:content/opposition_candidates",
}