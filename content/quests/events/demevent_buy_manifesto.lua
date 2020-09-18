-- Stolen, I mean, "inspired" by the event in rook's story
local MANIFESTO_COST = 50

local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    precondition = function(quest) 
        return TheGame:GetGameState():GetCaravan():GetMoney() >= MANIFESTO_COST
    end,
}

:AddOpinionEvents{
    
    refused_manifesto = {
        delta = OPINION_DELTAS.DISLIKE,
        txt = "Refused to buy their manifesto",
    },
    suspects_you = {
        delta = OPINION_DELTAS.MAJOR_BAD,
        txt = "Believes you killed a Rise member",
    },
}


local convo = QDEF:AddConvo()
    :ConfrontState("CONFRONT", function(cxt) return cxt.location:HasTag("in_transit")  end)
        :Loc{
            
            DIALOG_INTRO = [[
                * You recognize the colors of a member of the Rise, boldly out and about on the main roads.
                
                player:
                    !left
                agent:
                    !right
                    !interest
                    [p] you're a politicians, right? what do you think of the rise?

            ]],


            OPT_EXPRESS_SUPPORT = "Express support for the Rise",
            DIALOG_EXPRESS_SUPPORT = [[
                player:
                    No need for the sales pitch, friend. I'm already a supporter of your cause.
                agent:
                    !happy
                    $miscRelieved
                    That's a relief. Can't count how many times I've asked that question only to get written up.
                    You want some literature? For a small fee, I mean.
                    If I pay off my demerits, I can keep talking up the shifts. 
            ]],

            OPT_EXPRESS_IGNORANCE = "Pretend you don't know about the Rise",
            DIALOG_EXPRESS_IGNORANCE = [[
                player:
                    !dubious
                    The Rise? Is that a... motivational group?
                    $neutralDubious
                    Or a baking technique, perhaps?
                agent:
                    !crossed
                    [p] Don't play dumb. You're a politician, you should know your target groups.
                    !sigh
                    If you have to know who we are, I guess I'll tell you.
                    You heard of the insurrection in the Bread Fields? Where the laborers striked against the Admiralty occupation?
                player:
                    Yes, that does sound familiar.
                agent:
                    That was the Rise. We're trying to get better worker's rights.
                    !eureka
                    Fair pay for good work: no demerits, no bottomless contracts.
                    Of course... the overhead is killer. We need money to keep operating, and our own members are lacking. 
                    You want some literature? For a small fee, I mean.
            ]],
            
            OPT_EXPRESS_DOUBT = "Express doubt about the Rise",
            DIALOG_EXPRESS_DOUBT = [[
                player:
                    !crossed
                    Spare me the lecture, laborer. I know your movement and I can't say I care for your methods.
                agent:
                    !dubious
                    Our methods? We're just turning the system back in on itself!
                    !permit
                    If you read this manifesto, I'm sure you'll understand what we mean. Why don't you take one for yourself?
                    All I ask is a small donation. It barely covers the printing cost!
            ]],

        }
        :Fn(function(cxt)
            
            if cxt:FirstLoop() then

                cxt.quest:Complete()
                cxt.enc.scratch.rise = TheGame:GetGameState():AddSkinnedAgent( "RISE_PAMPHLETEER" )
                cxt:ReassignCastMember("rise", cxt.enc.scratch.rise)
                cxt.enc:SetPrimaryCast(cxt.enc.scratch.rise)

                cxt:Dialog("DIALOG_INTRO")
            end

            cxt:Opt("OPT_EXPRESS_SUPPORT")
                :Dialog("DIALOG_EXPRESS_SUPPORT")
                :UpdatePoliticalStance("LABOR_LAW", 1, false, true)
                :Fn(function(cxt)cxt.quest.param.support = true end)
                :GoTo("STATE_BUYIT")

            cxt:Opt("OPT_EXPRESS_IGNORANCE")
                :Dialog("DIALOG_EXPRESS_IGNORANCE")
                :DeltaSupport(-2)
                :GoTo("STATE_BUYIT")

            cxt:Opt("OPT_EXPRESS_DOUBT")
                :Dialog("DIALOG_EXPRESS_DOUBT")
                :UpdatePoliticalStance("LABOR_LAW", -1, false, true)
                :Fn(function(cxt)cxt.quest.param.doubt = true end)
                :GoTo("STATE_BUYIT")

        end)

    :State("STATE_BUYIT")
        :Loc{
            OPT_SHOW_CARD = "Show that you already have a {1#card}",
            DIALOG_SHOW_CARD = [[
                player:
                    [p] it's okay, friend, i already have one.
                agent:
                {support?
                    wow. you must be really supportive of the cause.
                    if Kalandra isn't running, i would've voted for you.
                }
                {doubt?
                    hold on, where did you get that?
                    those aren't really readily available in shops.
                    so how? don't tell me...
                }
                {not support and not doubt?
                    hold on, you said you don't know who the Rise are.
                    so why did you tell me that when you clearly have our manifesto?
                    unless...?
                }
            ]],
            OPT_BUY_IT = "Buy {1#card}",
            DIALOG_BUY_IT = [[
                {not doubt?
                    player:
                        !agree
                        Very well. Let's see this literature.
                    agent:
                        Hopefully this answers any questions you might have.
                        !exit
                }
                {doubt?
                    player:
                        [p] i have doubts, but let's see this literature.
                        hopefully i can learn about your goals better.
                    agent:
                        i don't know if that's a good thing or not.
                        but anyway, thanks.
                        !exit
                }
                * {agent} continues down the road, leaving you to your reading.
            ]],
            OPT_NO_BUY = "Politely decline",
            DIALOG_NO_BUY = [[
                player:
                    No, thank you.
                agent:
                    !hips
                    Come on. You wouldn't want folks thinking you're an enemy to the workers, would you?
            ]],

            OPT_NEGOTIATE = "Convince {agent} to leave you alone",
            DIALOG_NEGOTIATE = [[
                player:
                    I said no, laborer. You'd do best to honor that. 
            ]],
            DIALOG_NEGOTIATE_WON = [[
                player:
                    I don't understand why you'd want allies you don't even respect.
                    Or are you merely using the Rise as a ruse for your highway robbery?
                agent:
                    !surprised
                    H-highway...?! 
                    Okay, fine. I see how this looks. The foreman would kill me if I made the Rise look no better than the Spree.
                    !exit
                * {agent} continues down the road, head hanging heavily. 
            ]],
            DIALOG_NEGOTIATE_LOST = [[
                player:
                    Forcing me to buy that makes you no better than the Spark Barons.
                agent:
                    !angry
                    No better? You honestly comparing this to the atrocities the Barons commit?
                    !angry_accuse
                    We call that a false equivalence, friend, and I'm not falling for it. 
            ]],

            OPT_REFUSE = "Forcefully refuse",
            DIALOG_REFUSE = [[
                player:
                    !angry
                    Once more: the answer is no.
                agent:
                    !angry
                    I see you now. Watch your back. 
                    !throatcut
                    The Rise is everywhere.
            ]]

        }

        :SetLooping()
        :Fn(function(cxt)
            
            local card_id = "rise_manifesto"
            if TheGame:GetGameState():GetPlayerAgent():GetAspect("negotiator"):HasCardID(card_id) then
                cxt:Opt("OPT_SHOW_CARD", card_id)
                    :Dialog("DIALOG_SHOW_CARD")
                    :Fn(function(cxt)
                        if cxt.quest.param.support then
                            cxt:GetAgent():OpinionEvent(OPINION.SHARE_IDEOLOGY)
                            StateGraphUtil.AddLeaveLocation(cxt)
                        else
                            cxt:GoTo("STATE_SUSPICION")
                        end
                    end)
            end
            cxt:Opt("OPT_BUY_IT", card_id)
                :Dialog("DIALOG_BUY_IT")
                :DeliverMoney(MANIFESTO_COST, {is_shop = true} )
                :GainCards{card_id}
                :Travel()

            
            if not cxt.enc.scratch_refused_once then
                cxt:Opt("OPT_NO_BUY")
                    :Dialog("DIALOG_NO_BUY")
                    :Fn(function() cxt.enc.scratch_refused_once = true end)
            else
                cxt:Opt("OPT_NEGOTIATE")
                    :Dialog("DIALOG_NEGOTIATE")
                    :Negotiation{
                        on_success = function() 
                            cxt:Dialog("DIALOG_NEGOTIATE_WON")
                            StateGraphUtil.AddLeaveLocation(cxt)
                        end,
                        on_fail = function() 
                            cxt:Dialog("DIALOG_NEGOTIATE_LOST")
                        end,
                    }

                cxt:Opt("OPT_REFUSE")
                    :ReceiveOpinion(cxt.quest:GetQuestDef():GetOpinionEvent("refused_manifesto"))              
                    :Dialog("DIALOG_REFUSE")                 
                    :Travel()
            end

        end)
    
    :State("STATE_SUSPICION")
        :Loc{
            OPT_BRUSH_OFF = "Brush off {agent}'s concern",
            DIALOG_BRUSH_OFF = [[
                player:
                    [p] don't worry about it.
                agent:
                    the fact that you just said that makes me even more concerned!
                    in fact, i believe that you robbed one of our pamphleteers, or even killed them, to get your hands on this!
                    you just made enemies with the rise!
            ]],

            OPT_EXCUSE = "Stay on {agent}'s good side",
            DIALOG_EXCUSE = [[
                player:
                    !placate
                    I can explain...
            ]],
            DIALOG_EXCUSE_SUCCESS = [[
                player:
                    [p] i actually do support the Rise.
                {sal?
                    in fact, my parents are the leader of the Rise movement 10 years ago.
                }
                    it's just that, i'm a politician now, and i have to be careful with what i'm saying.
                    back in the Bog, letting people know you support the Rise is basically a death sentence.
                agent:
                    yeah, i have to agree with that.
                    but you don't have to worry about it now.
                    the time is different, we're trying to have an election.
                    directly killing a politician who support the Rise movement will look bad on whoever was doing it.
                player:
                    even still, you never know, right.
                agent:
                    true.
                    anyway, see you around.
                    !exit
                * Do you truly believe what you're saying? Doesn't matter, because {agent} believed it.
            ]],
            DIALOG_EXCUSE_FAIL = [[
                player:
                    [p] you see, i was testing you before, because i'm afraid you're an Admiralty spy or something.
                agent:
                    are you stupid? everyone knows you're not legally allowed to switch clothes once you join a faction.
                    so how could i be an Admiralty spy?
                {rook?
                player:
                    wait, didn't i dress up as a Spree for the trailer?
                * {agent} is not listening to you.
                }
                agent:
                    you can't pull the wool over my eyes.
                    you killed a pampleteer to get that, didn't you?
                    you just made enemies with the rise!
            ]],
        }
        :Fn(function(cxt)
            cxt.quest.param[string.lower(cxt.player:GetContentID())] = true
            -- print(cxt.player:GetContentID())
            cxt:Opt("OPT_BRUSH_OFF")
                :Dialog("DIALOG_BRUSH_OFF")
                :Fn(function(cxt)
                    cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("suspects_you"))
                    cxt:GoTo("STATE_HOSTILE")
                end)
            cxt:Opt("OPT_EXCUSE")
                :Dialog("DIALOG_EXCUSE")
                :Negotiation{
                    on_success = function(cxt)
                        cxt:Dialog("DIALOG_EXCUSE_SUCCESS")
                        cxt:GetAgent():OpinionEvent(OPINION.SHARE_IDEOLOGY)
                        DemocracyUtil.TryMainQuestFn("UpdateStance", "LABOR_LAW", 1, false, true)
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_EXCUSE_FAIL")
                        cxt:GetAgent():OpinionEvent(cxt.quest:GetQuestDef():GetOpinionEvent("suspects_you"))
                        cxt:GoTo("STATE_HOSTILE")
                    end,
                }
        end)
    :State("STATE_HOSTILE")
        :Loc{
            OPT_LEAVE = "Leave before things heat up",
            DIALOG_LEAVE = [[
                player:
                    !exit
                * You leave, not wanting to heat things up.
            ]],
            DIALOG_ATTACK = [[
                agent:
                    !angry
                    What the Hesh?
                    !fight
                    Oh, I guess we're doing things the old way, huh?
            ]],
            DIALOG_ATTACK_WIN = [[
                {dead?
                    * You killed {agent}.
                    * That is not going to look good on your reputation.
                }
                {not dead?
                    agent:
                        !angry_shrug
                        What was that for?
                        You could've just left, but no! You just wanna beat me up.
                        What good does that do?
                    * You know, that's a really good question.
                    agent:
                        Don't expect the Rise to support you now.
                        !exit
                }
            ]],
        }
        :Fn(function(cxt)
            cxt:Opt("OPT_LEAVE")
                :Dialog("DIALOG_LEAVE")
                :Travel()
            cxt:Opt("OPT_ATTACK")
                :Dialog("DIALOG_ATTACK")
                :Battle{
                    on_win = function(cxt) 
                        cxt:Dialog("DIALOG_ATTACK_WIN")
                        -- if not cxt:GetAgent():IsDead() then
                        -- DemocracyUtil.TryMainQuestFn("DeltaGeneralSupport", -10)
                        DemocracyUtil.TryMainQuestFn("DeltaFactionSupport", -10, "RISE")
                        
                        -- end
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                }
        end)