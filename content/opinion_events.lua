local OPINIONS = {
    DISLIKE_IDEOLOGY = {
        delta = OPINION_DELTAS.OPINION_DOWN,
        txt = "Dislikes your ideology",
    },
    SHARE_IDEOLOGY = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Shares an ideology with you",
    },
    USED_HEAVY_HANDED = {
        delta = OPINION_DELTAS.TO_DISLIKED,
        txt = "Used <!negotiationcard_heavy_handed>Heavy Handed</> tactics during a negotiation.",
    },
}

for id, data in pairs(OPINIONS) do
    AddOpinionEvent(id, data)
end