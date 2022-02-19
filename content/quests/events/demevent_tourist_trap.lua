local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
}

:AddCastByAlias{
  cast_id = "rento",
  alias = "BORDENKRA",
  no_validation = true,
}

:AddOpinionEvents{
    belief_in_democracy =
    {
        delta = OPINION_DELTAS.MAJOR_GOOD,
        txt = "Strengthened their belief in Havarian Democracy",
    },
    disappointed_them =
    {
        delta = OPINION_DELTAS.DISLIKE,
        txt = "Disappointed them",
    },
}
local GOOD_POSTERS = {"PROP_PO_INSPIRING", "PROP_PO_THOUGHT_PROVOKING", "PROP_PO_MEDIOCRE"}
local BAD_POSTERS = {"PROP_PO_SUPERFICIAL", "PROP_PO_MESSY"} --rento likes good posters and dislikes bad posters.

function CheckPoster(card)
    return card.userdata.prop_mod
end

QDEF:AddConvo()
    :ConfrontState("CONFRONT", function() return true end)
        :Loc{
            DIALOG_INTRO_RENTORIAN = [[
                * As you are walking down the road, you see someone dressed in a weird suit.
                * You can tell that {rento.heshe} clearly isn't local.
                * {rento.HeShe} sees you, and approaches you.
                player:
                    !left
                rento:
                    !right
                    !happy
                    You look like you are one of those candidates in the upcoming Havarian election.
                player:
                    !think
                    Do I really stand out that much?
                    But yes. I am, in fact, campaigning for the election.
                rento:
                    I just want to say that I am glad that Havaria is finally transitioning into a democracy.
                    You might have a long way to go, but this is a start.
                    Now, I want to see how competent you are.
                    Are you capable of leading a country in a democracy?
            ]],

            OPT_NEGOTIATE = "Show off your leadership skills",

            DIALOG_NEGOTIATE_RENTO = [[
                player:
                    Don't worry. I can lead a country alright.
            ]],

            --[[You sound less like you're running for kicks and more like you're going to make landmark changes. She respects that]]

            DIALOG_NEGOTIATE_RENTO_SUCCESS = [[
                agent:
                    !agree
                    I think I've heard enough.
                    You clearly know what your goal is, and you know how to achieve that goal.
                    Havaria's future will be bright under your lead.
                player:
                    !bashful
                    Thanks for the complement, I guess?
                    Just... Who are you? Exactly?
                agent:
                    I am just someone travelling in Havaria to see the election first-hand.
                    And it seems it is going well.
                    I can't directly support you, of course, because I am not from here.
                    But... All I can say is, good luck with your campaign.
                    For a brighter future for both Havaria, and Rentoria.
                    !exit
                * You are making friends with so many different kinds of people.
                * Aren't you proud of yourself?
            ]],

            --[[You accidentally sound too corrupt. Rento-girl is worried about Havarian democracy and thinks it's hogwash.]]

            DIALOG_NEGOTIATE_RENTO_FAILURE = [[
                agent:
                    !bashful
                    That sounds good and all, but if I may ask...
                    !dubious
                    What is your endgame, exactly?
                player:
                    ...
                    !bashful
                    Well, you see, uh... It is a very important question that we should ask ourselves often.
                agent:
                    ...
                    !facepalm
                    You don't have a goal once you get elected, do you?
                player:
                    !bashful
                    ...
                agent:
                    !angry
                    Look, democracy is a very important process, alright?
                    It is an incredible privilege that you are finally starting to enjoy!
                    The least you could do is taking it seriously!
                    !sigh
                    If all candidates in Havaria take it as seriously as you, democracy in Havaria still has a long way to go.
                    !exit
                * You messed up a great opportunity to show your strong leadership.
                * {agent.HeShe} did ask a good question, though. Do you actually have an endgame?
                * Think this through a bit more, lest you run into another opportunity like this one.
            ]],

            OPT_SHOW_POSTER = "Show {agent} a poster",
            DIALOG_BAD_POSTER = [[
            player:
                !happy
                Why tell you my campaign speech when I've got it on paper!
                * You push a poster into {agent.hisher} hands. {agent.HeShe} scans it.
            agent:
                Well, I uhm...
            player:
                It's good, right?
            agent:
                You misspelled vote right here. You wrote "vot" instead.
                And the artist's interpretation of your face isn't very good.
                And did you make this in crayon?
            player:
                !bashful
                Hey, I don't think you should knock something for just being in crayon.
                It can still look official!
            agent:
                There's an apple juice stain on the paper.
                !palm
                If this is the breed of politicians we're dealing with, I'm just going back to Rentoria.
                You all have fun.
            ]],

            DIALOG_GOOD_POSTER = [[
                * [p] You show {agent} a good poster.
                * She is happy.
            ]],

            OPT_IGNORE = "Ignore {agent}",

            DIALOG_IGNORE_RENTORIAN = [[
                player:
                    !shrug
                    I don't just give a speech on a random person about how great a leader I am, you know?
                agent:
                    !dubious
                    You are literally running for presidency.
                    Any competent leader would take whatever chances they can get to gather more support.
                    !sigh
                    If all candidates in Havaria are as amateur as you, democracy in Havaria still has a long way to go.
                    !exit
                * It seems you passed up a great opportunity to show off your leadership skills.
                * I hope the opportunity cost is worth it.
            ]],

            SELECT_TITLE = "Select a poster",
            SELECT_DESC = "Choose a poster to post on this location, consuming 1 use on it.",
        }
        :Fn(function(cxt)
            cxt.quest:Complete()
            local posters = {}
                for i, card in ipairs(cxt.player.negotiator.cards.cards) do
                    if card.id == "propaganda_poster" then
                        table.insert(posters, card)
                    end
                end
            cxt:TalkTo(cxt:GetCastMember("rento"))
            cxt:Dialog("DIALOG_INTRO_RENTORIAN")
            cxt:Opt("OPT_NEGOTIATE")
                :Dialog("DIALOG_NEGOTIATE_RENTO")
                :Negotiation{
                    on_success = function(cxt)
                        cxt:Dialog("DIALOG_NEGOTIATE_RENTO_SUCCESS")
                        cxt.quest:OpinionEvent("rento", "belief_in_democracy")
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,
                    on_fail = function(cxt)
                        cxt:Dialog("DIALOG_NEGOTIATE_RENTO_FAILURE")
                        cxt.quest:OpinionEvent("rento", "disappointed_them")
                        StateGraphUtil.AddLeaveLocation(cxt)
                    end,}
            if #posters > 0 then
                cxt:Opt("OPT_SHOW_POSTER")
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
                                print("Poster good")
                                cxt:Dialog("DIALOG_GOOD_POSTER")
                                cxt.quest:OpinionEvent("rento", "belief_in_democracy")
                                StateGraphUtil.AddLeaveLocation(cxt)
                            else
                                print("Poster bad")
                                cxt:Dialog("DIALOG_BAD_POSTER")
                                cxt.quest:OpinionEvent("rento", "disappointed_them")
                                StateGraphUtil.AddLeaveLocation(cxt)
                            end
                        end
                    end)
            end
            cxt:Opt("OPT_IGNORE")
                :Dialog("DIALOG_IGNORE_RENTORIAN")
                :ReceiveOpinion("disappointed_them")
                :Travel()
        end)
