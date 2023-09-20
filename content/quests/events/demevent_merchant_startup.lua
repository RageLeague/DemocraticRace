local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    act_filter = DemocracyUtil.DemocracyActFilter,
    postcondition = function(quest)
        quest.param.investment_cost = table.arraypick{ 50, 100, 150, 200 }
        local cost, reason = CalculatePayment(quest:GetCastMember("merchant"), quest.param.investment_cost, 1, {})
        return cost <= TheGame:GetGameState():GetCaravan():GetMoney()
    end,
    events =
    {
        action_clock_advance = function(quest, location)
            quest.param.timer = (quest.param.timer or 0) - 1
        end
    }
}

QDEF:AddCast{
    cast_id = "merchant",
    condition = function( agent, quest )
        return agent:GetContentID() == "POOR_MERCHANT" and not agent:KnowsPlayer()
    end,
    events =
    {
        agent_retired = function(quest, agent)
            quest:Cancel()
        end,
    }
}
:AddCastFallback( "POOR_MERCHANT" )

 QDEF:AddObjective{
    id = "startup",
    state = QSTATUS.ACTIVE,
}

 QDEF:AddObjective{
    id = "followup",
    state = QSTATUS.ACTIVE,
    on_activate = function( quest )
        quest.param.timer = math.random( 10, 20 )
    end,
}

-------------------------------------------------------------------
QDEF:AddConvo( "startup" )
    :ConfrontState("CONF", function(cxt) return cxt.location:HasTag("in_transit") end )
        :Loc{
            DIALOG_INTRO = [[
                merchant:
                    Greetings, my good {player.gender:sir|madam|friend}.
                    These are strange times, yes?
                player:
                    Stranger still the way you're talking to me.
                merchant:
                    Oh, forgive me! I'm just looking for someone who might be interested in a business opportunity.
                    Would you be interested in a business opportunity?
                player:
                    Opportunity? Or scam?
                merchant:
                    Ah, your skepticism does you credit.
                    I have here a prototype for the most uncanny creation, a device so cunning only the Vagrant Age could have spawned it.
                player:
                    What, you talking Spark Baron tech? Here, in the Foam?
                merchant:
                    Don't be so small-minded: the past belongs to each of us, doesn't it?
                    And with a bit of venture capital, it could belong to you, as well.
            ]],

            OPT_INVEST = "Invest in the venture",
            DIALOG_INVEST = [[
                player:
                    !happy
                    Why not? Might be fun to shake things up a little.
                    I give you shills, and you keep developing the prototype? Is that how it works?
                merchant:
                    Yes! And when the product is ready, you partake of the sales.
                    Think of it like putting the "venture" in "adventure".
                player:
                    I do like adventure.
                    !give
                merchant:
                    You won't regret it!
            ]],

            OPT_CONVINCE = "Convince {merchant} that {merchant.hisher} venture is going nowhere",
            DIALOG_CONVINCE = [[
                player:
                    [p] Your venture is going nowhere. You should stop it.
            ]],
            DIALOG_CONVINCE_SUCCESS = [[
                merchant:
                    [p] Okay, fine.
            ]],
            DIALOG_CONVINCE_FAILURE = [[
                merchant:
                    [p] No way.
                    You Heshians are going to be swept way by progress, with your close-mindedness.
            ]],

            DIALOG_LEAVE = [[
                player:
                    !thumb
                    Sorry, bub. I'm fresh out of gumption.
                    You'll have to keep your venture to yourself.
                merchant:
                    A shame. But hindsight will be your reward.
            ]],
        }
        :Fn(function(cxt)
            cxt.enc:SetPrimaryCast(cxt.quest:GetCastAgent("merchant"))
            cxt.enc:PresentDefault()
            cxt:Dialog("DIALOG_INTRO")

            cxt:Opt("OPT_INVEST")
                :UpdatePoliticalStance("RELIGIOUS_POLICY", -1)
                :DeliverMoney( cxt.quest.param.investment_cost )
                :Dialog("DIALOG_INVEST")
                :ActivateQuest("followup")
                :CompleteQuest("startup")
                :Travel()

            cxt:Opt("OPT_CONVINCE")
                :UpdatePoliticalStance("RELIGIOUS_POLICY", 1)
                :Dialog("DIALOG_CONVINCE")
                :Negotiation{

                }
                    :OnSuccess()
                        :Dialog("DIALOG_CONVINCE_SUCCESS")
                        :DeltaSupport(3, "CULT_OF_HESH")
                        :CancelQuest()
                        :Travel()
                    :OnFailure()
                        :Dialog("DIALOG_CONVINCE_FAILURE")
                        :ReceiveOpinion(OPINION.DISLIKE_IDEOLOGY)
                        :CancelQuest()
                        :Travel()

            cxt:Opt("OPT_LEAVE")
                :Dialog("DIALOG_LEAVE")
                :CancelQuest()
                :Travel()
        end)





QDEF:AddConvo( "followup" )
    :ConfrontState("CONF", function(cxt) return (cxt.quest.param.timer or 0) <= 0 and cxt.location:HasTag("in_transit") end )
        :Loc{
            DIALOG_INTRO = [[
                merchant:
                    {disliked?
                        Ah... {player}.
                        I am here to honor our original agreement, as much as I'd prefer not to.
                    }
                    {not disliked?
                        !wave
                        Ah, {player}! There you are!
                        You're a hard {player.gender:man|woman|person} to find when rewards are ready for reaping.
                        Thanks to your help, our prototype has blossomed into a beautiful butterfly!
                        Figuratively, of course.
                    }
            ]],

            OPT_RECEIVE_PRODUCT = "Receive the final product",
            DIALOG_RECEIVE_PRODUCT = [[
                player:
                    Can I get one of those figurative butterflies for myself, maybe?
                merchant:
                    !happy
                    Of course! The least I can do to repay your faith.
                    Here you are. May it bring you as much happiness as it has brought me.
            ]],

            OPT_LOAN_REPAYMENT = "Receive your loan repayment with interest",
            DIALOG_LOAN_REPAYMENT = [[
                player:
                    Great! I'll take my profits now, then.
                merchant:
                    As promised, your loan with interest.
                    !wave
                player:
                    !hips
                    This business stuff is easier than I thought!
            ]],

            OPT_NO_REWARD = "Leave without repayment",
            DIALOG_NO_REWARD = [[
                player:
                    My what? Huh?
                    To be honest, I'd forgotten about it. And I don't much got an interest for this kind of thing.
                    Maybe buy me a drink sometime, yeah? And we'll call it even.
                merchant:
                    !happy
                    {disliked?
                        I... really? If you're sure.
                        Perhaps I was wrong about you. Maybe you give back more than you let on.
                    }
                    {not disliked?
                        You, {player.gender:sir|ma'am|my friend}, are a true philanthropist!
                    }
            ]],
        }
    :Fn(function(cxt)
        cxt.enc:SetPrimaryCast(cxt.quest:GetCastAgent("merchant"))
        cxt.enc:PresentDefault()
        cxt.quest:Complete()
        cxt:Dialog("DIALOG_INTRO")

        cxt:Opt("OPT_RECEIVE_PRODUCT")
            :Dialog("DIALOG_RECEIVE_PRODUCT")
            :Fn(function(cxt)
                TheGame:GetGameProfile():SetSeenGraft("neural_braid")
                cxt.enc:AwardLoot( { grafts = {"neural_braid_plus"} })
            end )
            :Travel()

        cxt:Opt("OPT_LOAN_REPAYMENT")
            :Dialog("DIALOG_LOAN_REPAYMENT")
            :ReceiveMoney( cxt.quest.param.investment_cost * 2 )
            :Travel()

        cxt:Opt("OPT_NO_REWARD")
            :Dialog("DIALOG_NO_REWARD")
            :ReceiveOpinion( OPINION.DEEPENED_RELATIONSHIP )
            :Travel()

    end)

