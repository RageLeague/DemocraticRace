OPINION_DELTAS.TO_HATED = {
    relationship_delta =
    {
        [RELATIONSHIP.LOVED] = RELATIONSHIP.NEUTRAL,
        [RELATIONSHIP.LIKED] = RELATIONSHIP.NEUTRAL,
        [RELATIONSHIP.NEUTRAL] = RELATIONSHIP.DISLIKED,
        [RELATIONSHIP.DISLIKED] = RELATIONSHIP.HATED,
    },
    desc = "-> Toward Hated",
}
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
    DISLIKE_IDEOLOGY_II = {
        delta = OPINION_DELTAS.MAJOR_BAD,
        txt = "Extremely dislikes your ideology",
    },
    SHARE_IDEOLOGY = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Shares an ideology with you",
    },
    USED_HEAVY_HANDED = {
        delta = OPINION_DELTAS.TO_DISLIKED,
        txt = "Used <!negotiationcard_heavy_handed>Heavy Handed</> tactics during a negotiation",
    },
    TRIED_TO_PROVOKE = {
        delta = OPINION_DELTAS.BAD,
        txt = "Tried to provoke them into a fight",
    },
    SUGGEST_UNREASONABLE_REQUEST = {
        delta = OPINION_DELTAS.DIMINISH,
        txt = "Suggested an unreasonable request",
    },
    ATTEMPT_TO_RUIN_BUSINESS = {
        delta = OPINION_DELTAS.DISLIKE,
        txt = "Attempted to ruin their business",
    },
    HELP_COMPLETE_DEAL = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Help them complete a deal",
    },
    RID_ANNOYING_CUSTOMER = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Got rid of an annoying customer",
    },
    SUPPORT_EXPECTATION_S = {
        delta = {
            relationship_delta =
            {
                [RELATIONSHIP.NEUTRAL] = RELATIONSHIP.LIKED,
                [RELATIONSHIP.DISLIKED] = RELATIONSHIP.LIKED,
                [RELATIONSHIP.HATED] = RELATIONSHIP.NEUTRAL,
            },
        },
        txt = "Did an exemplary job in gaining support",
    },
    SUPPORT_EXPECTATION_A = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Did a great job in gaining support",
    },
    SUPPORT_EXPECTATION_B = {
        delta = OPINION_DELTAS.NORMALIZING,
        txt = "Did an acceptable job in gaining support",
    },
    SUPPORT_EXPECTATION_C = {
        delta = OPINION_DELTAS.DIMINISH,
        txt = "Did a poor job in gaining support",
    },
    SUPPORT_EXPECTATION_D = {
        delta = OPINION_DELTAS.BAD,
        txt = "Did a terrible job in gaining support",
    },
    SUPPORT_EXPECTATION_F = {
        delta = OPINION_DELTAS.MAJOR_BAD,
        txt = "Completely screwed up the campaign",
    },
    ALLIED_WITH = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Allied with them",
    },
    ALLIED_WITH_ENEMY = {
        delta = OPINION_DELTAS.DISLIKE,
        txt = "Allied with their enemy",
    },
    REJECTED_ALLIANCE = {
        delta = OPINION_DELTAS.DISLIKE,
        txt = "Rejected their alliance",
    },
    PUBLICLY_DENOUNCE = {
        delta = OPINION_DELTAS.BAD,
        txt = "Publicly denounced them",
    },
    REFUSED_TO_DROP_OUT = {
        delta = OPINION_DELTAS.DISLIKE,
        txt = "Refused to drop out of the race when asked to"
    },
    HAD_MEANINGFUL_DISCUSSION = {
        delta = OPINION_DELTAS.LIKE,
        txt = "Had meaningful discussion with them",
    },
}

for id, data in pairs(OPINIONS) do
    AddOpinionEvent(id, data)
end
