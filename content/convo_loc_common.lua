Content.AddStringTable( "DEM_CONVO", {
    CONVO_COMMON = {
        OPT_ACCEPT_FAILURE = "Accept your failure",

        DIALOG_ALLIANCE_TALK_INTRO = [[
            player:
                [p] There's a lot of similarities between us.
                Perhaps we can join forces.
        ]],
        DIALOG_ALLIANCE_TALK_INVALID = [[
            agent:
                [p] {player.gender:Sir|Ma'am|Excuse me}, this is a Wendy's.
        ]],
        DIALOG_ALLIANCE_TALK_UNCONDITIONAL = [[
            agent:
                [p] Sounds like a great idea!
                Let's do this!
            {opposite_spectrum?
                As long as we fix a small problem first.
            player:
                What?
            agent:
                I support {1#pol_stance}, and you support the opposite.
                We can't really have that.
                That is, of course, unless you decide to change your mind on the topic.
            }
        ]],
        DIALOG_ALLIANCE_TALK_CONDITIONAL = [[
            agent:
                [p] I doubt your ability.
                You have high potential, but you aren't there yet.
            {opposite_spectrum?
                And there's the problem that I support {1#pol_stance}, and you support the opposite.
                So we have to fix that first.
            }
            {not opposite_spectrum?
                So you need to convince me first.
            player:
                Who would've guess something like this would happen?
            }
        ]],
        DIALOG_ALLIANCE_TALK_BAD_ALLY = [[
            agent:
                [p] That sounds good, but actually it's not.
            player:
                Why?
            {is_problem_ally?
                You see, you have {1#agent} as your ally.
                And that is a problem.
                Because we hate each other.
            player:
                Understandable.
            }
            {not is_problem_ally?
                You see, you just made the wrong enemy, that is all.
                {1#agent} and I look out for each other, and you made {1.himher} mad.
                So we can't be allies.
            player:
                In that case, can I ship you two in my OC?
            agent:
                Hesh off!
            }
        ]],
        DIALOG_ALLIANCE_TALK_REJECT = [[
            agent:
                [p] A funny joke.
                You know what, I may consider it if you suck less.
            player:
                Well, screw you too.
        ]],
        OPT_ALLIANCE_TALK_ACCEPT = "Accept alliance",
        DIALOG_ALLIANCE_TALK_ACCEPT = [[
            player:
                [p] We have a deal.
            agent:
                Great!
        ]],
        OPT_ALLIANCE_TALK_AGREE_STANCE = "Opt to support {agent}'s stance",
        DIALOG_ALLIANCE_TALK_AGREE_STANCE = [[
            player:
                [p] You know what? I agree with you.
            agent:
                Yeah, yeah.
                But this time, it's for real. Don't try to change your stance to the opposition.
            player:
                Sure, pinky promise.
        ]],
        OPT_ALLIANCE_TALK_HERE_DEMANDS = "Hear out {agent}'s demands",
        DIALOG_ALLIANCE_TALK_HERE_DEMANDS = [[
            player:
                Alright, then, what do you want?
            agent:
                What I want is simple.
                If you can {1#demand_list}, then we're in business.
        ]],
        OPT_ALLIANCE_TALK_REJECT_ALLIANCE = "Reject alliance",
        DIALOG_ALLIANCE_TALK_REJECT_ALLIANCE = [[
            player:
                [p] You know what? I reconsider.
            agent:
                What a waste of my time.
        ]],

        OPT_DEBUG_BYPASS_HARD_CHECK = "[Debug] Bypass hard check",
        TT_DEBUG_BYPASS_HARD_CHECK = "This will bypass a hard check in the game for debug purpose. Choosing this makes this run illegitimate.",

        OPT_SKIP_RALLY = "Skip Rally",
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

        OFFER_TRINKET_GRAFT = "<b>Souvenir Trinket</>: Install {1#graft}",

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