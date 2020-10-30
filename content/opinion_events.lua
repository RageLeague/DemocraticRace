local OPINIONS = {
    CONVINCE_SUPPORT = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Convinced them to support you",
    },
    FAIL_CONVINCE_SUPPORT = {
        delta = OPINION_DELTAS.DISLIKE,
        txt = "Fail to convince them to support you",
    },
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
    TRIED_TO_PROVOKE = {
        delta = OPINION_DELTAS.BAD,
        txt = "Tried to provoke them into a fight.",
    },
}

for id, data in pairs(OPINIONS) do
    AddOpinionEvent(id, data)
end