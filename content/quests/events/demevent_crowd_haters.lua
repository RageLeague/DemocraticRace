local QDEF = QuestDef.Define
{
    qtype = QTYPE.EVENT,
    act_filter = DemocracyUtil.DemocracyActFilter,
    spawn_event_mask = QEVENT_TRIGGER.TRAVEL,
    on_init = function(quest)

    end,
    postcondition = function(quest)
        quest.param.other_haters = {}
        local hater_count = math.random(math.ceil(quest:GetDifficulty() / 2), 1 + quest:GetDifficulty())
        for i = 1, hater_count do
            quest:AssignCastMember("hater")
            if not quest:GetCastMember("hater") then
                break
            end
            table.insert(quest.param.other_haters, quest:GetCastMember("hater"))
            quest:UnassignCastMember("hater")
        end
        return #quest.param.other_haters > 0
    end,
}
:AddCast{
    cast_id = "hater_leader",
    condition = function(agent, quest)
        return agent:GetRelationship() < RELATIONSHIP.NEUTRAL or DemocracyUtil.GetAgentEndorsement(agent) < RELATIONSHIP.NEUTRAL
    end,
}
:AddCast{
    cast_id = "hater",
    when = QWHEN.MANUAL,
    optional = true,
    condition = function(agent, quest)
        if agent:GetFaction():GetFactionRelationship( quest:GetCastMember("hater_leader"):GetFactionID() ) < RELATIONSHIP.NEUTRAL then
            return false, "Bad faction relation"
        end
        if not (agent:GetRelationship() < RELATIONSHIP.NEUTRAL or DemocracyUtil.GetAgentEndorsement(agent) < RELATIONSHIP.NEUTRAL) then
            return false, "Not bad relationship"
        end
        if agent == quest:GetCastMember("hater_leader") or quest.param.other_haters and table.arraycontains(quest.param.other_haters, agent) then
            return false, "Already casted"
        end
        return true
    end,
}

local NICK_MAP =
{
    SAL = "BAD_NICK_SAL",
    ROOK = "BAD_NICK_ROOK",
    SMITH = "BAD_NICK_SMITH",
    PC_SHEL = "BAD_NICK_SHEL",
    PC_ARINT = "BAD_NICK_ARINT",
}

QDEF:AddConvo()
    :ConfrontState("STATE_CONFRONT")
        :Loc{
            DIALOG_INTRO = [[
                * As you're traveling, you run into a group of people on the way to where you're headed.
                * Upon getting closer, one of them noticed you, pointing at your direction.
                * You can see the look of disapproval in {hater_leader.hisher} face.
                player:
                    !left
                hater_leader:
                    !right
                    !angry_accuse
                    Hey everyone! Look! It's {bad_nick}!
                player:
                    !surprised
                    What? Me?
                * Not a good look admitting that you are {bad_nick}, but it's not like they don't know who this name refers to.
            ]],
            DIALOG_INTRO_PST = [[
                * The crowd starts jeering at you. A public gathering this big with this kind of attitude towards you will not reflect well on your image.
            ]],
            OPT_IGNORE = "Ignore the crowd and move on",
            DIALOG_IGNORE = [[
                * You don't have time for this. You duck your head and try not to show a reaction as you move past them.
                hater_leader:
                    !right
                    Look everyone, {bad_nick} thinks {player.heshe}'s too good for us! Isn't that right, {bad_nick}?
                * You tell yourself that if you campaign successfully, you'll earn yourself devoted supporters who'll speak louder than these hecklers can.
                * Still, you can't help but feel yourself losing resolve after such an intense encounter with so many haters.
            ]],
            OPT_APPEAL = "Appeal to the crowd",
            DIALOG_APPEAL = [[
                player:
                    Hello! If I may just make a case for myself...
                hater_leader:
                    !right
                    It looks like {bad_nick} has something to say! This should be rich.
            ]],
            DIALOG_APPEAL_SUCCESS = [[
                player:
                    I'm honestly just trying to make Havaria a better place.
                hater_face2:
                    !right
                    I just feel bad now. I'm leaving.
                    !exit
                hater_face:
                    !right
                    But, but, it's {bad_nick}!
                player:
                    Are you done yet?
                hater_face:
                    Haha... I was just kidding, yeah?
                    !exit
            ]],
            DIALOG_APPEAL_PARTIAL_SUCCESS = [[
                player:
                    I'm honestly just trying to make Havaria a better place.
                hater_face2:
                    !right
                    I just feel bad now. I'm leaving.
                hater_face:
                    !right
                    Don't think that your honeyed words can fool the rest of us, {bad_nick}. We're onto you.
            ]],
            DIALOG_APPEAL_FAILURE = [[
                player:
                    I'm not so bad, see?
                hater_face:
                    Look at {bad_nick} stumbling over {player.hisher} own words! What a buffoon!
                * The crowd erupts into laughter, and they're not laughing with you. You have no choice but to slink away with your tail between your legs.
            ]],
            OPT_USE_BODYGUARD = "Have your bodyguard disperse the crowd",
            DIALOG_USE_BODYGUARD = [[
                {guard_human?
                    player:
                        !hips
                        {guard}. Clear this crowd for me, thank you.
                    hired:
                        !left
                        Yes {player.honorific}.}
                {not guard_human?
                    player:
                        !point
                        {guard}, sic 'em!
                    hired:
                        !left
                        Grrrr!}
                * {guard} efficiently scatters the crowd. That should keep them from talking.
            ]],
            OPT_FIGHT = "Disperse the crowd yourself",
            WARNING_FIGHT = "Remember: You are a politician, not a trained warrior. This could end poorly.",
            DIALOG_FIGHT = [[
                * You let out a bloodcurdling scream and rush at the crowd.
                hater_face:
                    !right
                    !scared
                    Look out, {bad_nick}'s gone mad! Fend for your lives!
            ]],
            BAD_NICK_SAL = "Recount Dracula",
            BAD_NICK_ROOK = "{player} the Crook",
            BAD_NICK_SMITH = "Flotsam Banquod",
            BAD_NICK_SHEL = "Miss Shills-for-Brains",
            BAD_NICK_ARINT = "Spark Karen",
            BAD_NICK_OTHER = "the spoiler",
        }
        :Fn(function(cxt)
            cxt.quest:Complete()
            --character-specific nicks
            cxt.quest.param.bad_nick = cxt:GetLocString("BAD_NICK_OTHER")
            if NICK_MAP[cxt.player:GetContentID()] then
                cxt.quest.param.bad_nick = cxt:GetLocString(NICK_MAP[cxt.player:GetContentID()])
            end

            cxt:Dialog("DIALOG_INTRO")

            cxt:Dialog("DIALOG_INTRO_PST")

            cxt:Opt("OPT_IGNORE")
                :Dialog("DIALOG_IGNORE")
                --lose support and resolve
                :Travel()

            --negotiate
            DemocracyUtil.AddBodyguardOpt(cxt, function(cxt, agent)
                cxt:ReassignCastMember("guard", agent)
                cxt.quest.param.guard_human = not agent:IsPet()
                cxt:Dialog("DIALOG_USE_BODYGUARD")
                    :Travel()
            end, "OPT_USE_BODYGUARD")

            --FIGHT
        end)
