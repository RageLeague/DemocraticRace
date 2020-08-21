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
    opposition_data = require "DemocraticRace:content/opposition_candidates",
}