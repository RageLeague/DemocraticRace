local GOOD_POSTERS = {"PROP_PO_SUPERFICIAL", "PROP_PO_MESSY"} --delto likes bad posters and dislikes good posters.
local BAD_POSTERS = {"PROP_PO_INSPIRING", "PROP_PO_THOUGHT_PROVOKING", "PROP_PO_MEDIOCRE"}

local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}
:AddCastByAlias{
  cast_id = "delto",
  alias = "DELTREAN_DIGNITARY",
  no_validation = true,
}
:AddOpinionEvents{
    democracy_is_funny_joke =
    {
        delta = OPINION_DELTAS.LIKE,
        txt = "Convinced them Havarian Democracy is a ruse.",
    },
    ugh_democracy =
    {
        delta = OPINION_DELTAS.DISLIKE,
        txt = "Convinced them Havarian Democracy is the end of the status quo.",
    },
}

QDEF:AddConvo()
    :ConfrontState("CONFRONT", function() return true end)
        :Loc{
            DIALOG_INTRO_DELTREAN = [[
                * You are minding your own business when you hear a commotion.
                * You see everyone's second favorite dignitary, yelling at {delto.hisher} companion in the public.
                delto:
                    !right
                    !angry_shrug
                    Unbelievable. Unbelievable!
                    !angry_accuse
                    Who do these Havarians think they are? Thinking they can democratically elect a leader?
                    Do they think Deltree is a joke? Making political decisions without our input?
                * This does not like something you would like to be involved in, but {delto} doesn't seem to care about your opinion on this matter.
                * {delto.HeShe} confronts you.
                player:
                    !left
                delto:
                    !angry_accuse
                    You there!
                player:
                    !surprised
                    What? Me?
                delto:
                    You look like one of those politicians running for presidency.
                    Who do you think you are? Rebelling against us Deltrean?
                    There is no order in this place!
                * An angry diplomat on foreign soil is never a good thing.
                * One wrong move, and the conflict can escalate into a war.
                ]],

            OPT_NEGOTIATE = "Placate {agent}",
            DIALOG_NEGOTIATE_DELTO = [[
                player:
                    !placate
                    Hey, calm down. We don't seek independence.
                ]],

            DIALOG_NEGOTIATE_DELTO_SUCCESS = [[
                player:
                    Don't worry.
                    !permit
                    The election is simply an attempt to settle things peacefully, to end the endless conflicts between factions.
                    !placate
                    We aren't really seeking independence from Deltree.
                    If anything, stabilizing Havaria through peaceful means will ensure that we serve Deltree better.
                agent:
                    !thought
                    Hmm... This is unprecedented, and it's too early to tell if what you proposed work or not.
                    Alright, we will give it a try.
                    !throatcut
                    If anything happens that we don't like, well...
                player:
                    Yeah, I get your point.
                    I will do my best to ensure a favorable outcome for both Havaria and Deltree.
                agent:
                    !agree
                    Very well. Glad to see some manners in Havaria.
                * You might be seen as weak by the voters, but at least acting weak in front of a foreign dignitary is better than causing a war.
                * You leave {agent} alone, hoping to never deal with {agent.himher} again.
            ]],

            DIALOG_NEGOTIATE_DELTO_FAILURE = [[
                player:
                    !placate
                    Look, we are simply choosing our leader via democracy.
                    You shouldn't be concerned about it.
                agent:
                    !angry_accuse
                    Who gives you the right to choose your own leader?
                    Of course Deltree is going to be concerned! Havaria thinks it's an independent country and thinks it can choose its own leader!
                player:
                    !placate
                    I wasn't-
                agent:
                    What other reason could you possibly have!
                    !angry_shrug
                    Unbelievable! These Havarians.
                * You really could have handled this situation better.
                * Now you have an angry Deltrean dignitary to deal with.
                player:
                    !thought
                * Although you reasoned that {agent} is just constantly angry, and if Havaria hasn't been invaded by Deltree already, it's not going to now.
                * You leave {agent} alone, hoping to never deal with {agent.himher} again.
            ]],

    --[[You show him a half-compotent poster. He gets genuinely worried about the fate of Havarian-Deltrean relations.]]

            OPT_SHOW_POSTER = "Show {agent} a poster",
            DIALOG_BAD_POSTER = [[
                player:
                    Now I'd say we're on track to keeping Havaria right under Deltree's thumb.
                    !give
                    Just look at some of the material they're using to get elected.
                delto:
                    This is...
                    !neutral
                    Wow.
                    This is actually rather inspiring now that I look at it.
                    !angry
                    It shouldn't be!
                    It's going to make people want to keep this democracy and not go back to Deltrean rule!
                    Unbelievable. You politicians are going to cause a war, just you wait.
                ]],

    --[[You show him a bad poster. He's reassured in his superiority complex over Havarians]]

            DIALOG_GOOD_POSTER = [[
                player:
                    !chuckle
                    You think this is a real democracy? Just look at the kind of material the politicans are passing out.
                    !give
                delto:
                    !take
                    What is this? Did you draw this on the back of a cocktail napkin?
                player:
                    !hips
                    I drew it on the hopes it would get me elected.
                    !happy
                    And people just eat this stuff up! It's incredible!
                delto:
                    Wow. I thought Deltree was bad.
                    This kind of shabby oughta give us leverage when we force this whole "democracy" into the abyss.
                    !give
                    Say...here's some money that says you keep Havaria on this kind of downward spiral. Whatdya say?
                player:
                    !take
                    I say "Long live Deltree!".
                delto:
                    !happy
                    Right you are!
                    !exit
                ]],

            OPT_IGNORE = "Ignore {agent}.",
            DIALOG_IGNORE_DELTREAN = [[
                player:
                    !shrug
                    I really have no say in this situation.
                agent:
                    You are a politician! You can say a lot of things!
                player:
                    Later!
                    !exit
                * You hastily leave the scene, not want to deal with this for any longer.
                * As you leave, you hear {agent} continue to ramble.
                agent:
                    !crossed
                    These Havarians are unbelievably rude.
            ]],

            OPT_INSULT = "Stand up for Havarian independence and insult {agent}",

            DIALOG_INSULT = [[
                player:
                    !angry_shrug
                    What if we are? What are you going to do about it?
            ]],

            DIALOG_INSULT_SUCCESS = [[
                player:
                    !angry_accuse
                    You think just because you are a Deltrean, you are above us?
                    You think you can just do whatever the Hesh you want like you own the place?
                    !angry_shrug
                    Well guess what? Havaria is an independent nation, and you should recognize it as such.
                    You have no power here!
                agent:
                    This is an insult to the Deltrean Empire!
                player:
                    !crossed
                    Wow, genius. How long did <i>you</> take to figure it out?
                agent:
                    !angry_accuse
                    Know this, <i>Havarian</>. You will rue the day you insulted us.
                    This will not go unpunished! Deltree will hear about this!
                player:
                    Fine! See if I care.
                * You are 70% sure that being angry is just {agent}'s default state, that nothing serious will happen.
                * Yet 30% of you feel like you have started something uncontrollable, like a wildfire.
                * There is no taking back what you've just said now.
                * At least at the moment it felt good, and the voters will see you as a hero standing up to Deltrean oppression.
            ]],
            }
            :Fn(function(cxt)
                cxt.quest:Complete()
                local posters = {}
                for i, card in ipairs(cxt.player.negotiator.cards.cards) do
                    if card.id == "propaganda_poster" then
                        table.insert(posters, card)
                    end
                end

                cxt:TalkTo(cxt:GetCastMember("delto"))
                cxt:Dialog("DIALOG_INTRO_DELTREAN")
                cxt:Opt("OPT_NEGOTIATE")
                    :Negotiation{
                        on_success = function(cxt)
                            cxt:Dialog("DIALOG_NEGOTIATE_DELTO_SUCCESS")
                            cxt.quest:OpinionEvent("delto", "democracy_is_funny_joke")
                            cxt.encounter:GainMoney( 100 )
                            StateGraphUtil.AddLeaveLocation(cxt)
                        end,
                        on_fail = function(cxt)
                            cxt:Dialog("DIALOG_NEGOTIATE_DELTO_FAILURE")
                            cxt.quest:OpinionEvent("delto", "ugh_democracy")
                            StateGraphUtil.AddLeaveLocation(cxt)
                        end,}
                if #posters > 0 then
                    cxt:Opt("OPT_SHOW_POSTER")
                                -- local cards = agent.negotiator:GetCards()
                        :Fn(function(cxt)
                            cxt:Wait()
                            DemocracyUtil.InsertSelectCardScreen(
                                posters,
                                cxt:GetLocString("SELECT_TITLE"),
                                cxt:GetLocString("SELECT_DESC"),
                                nil,
                                function(card)
                                    cxt.enc:ResumeEncounter( card )
                                end
                            )
                            local card = cxt.enc:YieldEncounter()
                            if card then
                                --mini block for item usage.
                                card:ConsumeCharge()
                                if card:IsSpent() then
                                    cxt.player.negotiator:RemoveCard( card )
                                end
                                if table.contains(GOOD_POSTERS, CheckPoster(card)) then
                                    cxt:Dialog("DIALOG_GOOD_POSTER")
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                else
                                    cxt:Dialog("DIALOG_BAD_POSTER")
                                    StateGraphUtil.AddLeaveLocation(cxt)
                                end
                            end
                        end)
                end
                cxt:Opt("OPT_IGNORE")
                    :Dialog("DIALOG_IGNORE_DELTREAN")
                    :ReceiveOpinion("ugh_democracy")
                    :Travel()
            end)
