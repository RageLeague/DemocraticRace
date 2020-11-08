Content.AddStringTable( "DEM_CONVO", {
    CONVO_COMMON = {
        OPT_ACCEPT_FAILURE = "Accept your failure",

        OPT_DEBUG_BYPASS_HARD_CHECK = "[Debug] Bypass hard check",
        TT_DEBUG_BYPASS_HARD_CHECK = "This will bypass a hard check in the game for debug purpose. Choosing this makes this run illegitimate.",

        DIALOG_CHOOSE_FREE_TIME = [[
            player:
                I think instead of rallying, I'll just do whatever I want.
            agent:
            {disliked?
                I wouldn't do that if I were you, considering how low our support was.
            }
            {not disliked and not liked?
                I don't know if that's a good idea. We need those support.
            }
            {liked?
                I won't stop you or anything, but we really need the support.
            }
        ]],
        OPT_INSIST_FREE_TIME = "Insist on choosing free time",
        DIALOG_INSIST_FREE_TIME = [[
            player:
                I'm doing it.
            agent:
                As you wish.
        ]],
        OPT_NEVER_MIND = "Never mind",
        DIALOG_NEVER_MIND_FREE_TIME = [[
            player:
                You may have a point.
            agent:
            {advisor_manipulate?
                Glad that you can see logic.
            }
            {not advisor_manipulate?
                Very well.
            }
        ]],

        REQ_FREE_TIME = "You don't have free time to choose this action.",
        REQ_FREE_TIME_ACTIONS = "You don't have enough free time actions to choose this action.",
        TT_FREE_TIME_ACTION_COST = "This option requires {1} free time {1*action|actions}.",

        OPT_NEGOTIATE_TERMS = "Negotiate the terms",
        TT_NEGOTIATE_TERMS = "Negotiate the terms of your deal with {agent}, to hopefully reduce your commitments.",
        DIALOG_NEGOTIATE_TERMS = [[
            player:
                I don't know, you're driving a hard bargain...
        ]],
        DIALOG_NEGOTIATE_TERMS_SUCCESS = [[
            agent:
                Fine. I'll lower my demands.
                Now you just need to {1#demand_list}.
                Take it, or leave it.
        ]],
        DIALOG_NEGOTIATE_TERMS_PERFECT_SUCCESS = [[
            agent:
                Okay, okay. You made your point.
                Tell you what, I agree to do what you want. No strings attached.
        ]],
        DIALOG_NEGOTIATE_TERMS_NO_REDUCTION = [[
            player:
                This is what I'll do, {1#demand_list}. Final offer.
            agent:
                Isn't that just the origi-
                I mean, sure. Deal.
                Now uphold your end of the bargain.
        ]],
        DIALOG_NEGOTIATE_TERMS_CHEATER_FACE = [[
            agent:
                !angry_shrug
                Oh come on! You can't just say "screw it, you aren't getting anything" and expect it to work!
            player:
                !handwring
                Haha, {1#card} goes brrr.
            agent:
                !dubious
                ...
            player:
                !happy
                ...
            agent:
                !scared
                ...
            player:
                !cruel
                ...
            agent:
                !sigh
                Fine you win.
        ]],
        DIALOG_NEGOTIATE_TERMS_FAIL = [[
            agent:
                No, the original deal stands.
                Take it, or leave it.
        ]],

        OPT_UNLOCK_NEW_LOCATION = "Unlock new location: {1#location}",
        TT_UNLOCK_NEW_LOCATION = "You can now visit this location during your free time.",
        
        TT_UPDATE_STANCE = "Your stance regarding <b>{1#pol_issue}</> will be updated to <b>{2#pol_stance}</>.",
        TT_UPDATE_STANCE_OLD = "Your stance regarding <b>{1#pol_issue}</> will be updated from <b>{3#pol_stance}</> to <b>{2#pol_stance}</>.",
        TT_UPDATE_STANCE_LOOSE = "Your stance regarding <b>{1#pol_issue}</> will be loosely updated to <b>{2#pol_stance}</>.",
        TT_UPDATE_STANCE_LOOSE_OLD = "Your stance regarding <b>{1#pol_issue}</> will be loosely updated from <b>{3#pol_stance}</> to <b>{2#pol_stance}</>.",
        TT_UPDATE_STANCE_SAME = "You stance regarding <b>{1#pol_issue}</> will be reinforced.(<b>{2#pol_stance}</>)",

        TT_UPDATE_STANCE_WARNING = "<#PENALTY>Warning: Frequent change of stance might cause you to lose support!</>",
        TT_UPDATE_STANCE_BONUS = "<#BONUS>Having a consistent stance boosts your support.</>"
    }
} )