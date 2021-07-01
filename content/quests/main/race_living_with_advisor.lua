
local QDEF = QuestDef.Define
{
    title = "Go To Your Advisor",
    icon = engine.asset.Texture("icons/quests/rook_story_living_at_bar.tex"),
    qtype = QTYPE.STORY,
    home = true,
    on_start = function(quest)
        quest:AssignCastMember("primary_advisor" )
        if quest:GetCastMember("primary_advisor") then
            quest:AssignCastMember("home")
            quest:AssignCastMember("player_room")
            print(quest:GetCastMember("player_room"))
        end
    end,
}
-- :AddCast{
--     cast_id = "primary_advisor",
--     when = QWHEN.MANUAL,
--     cast_fn = function(quest, t)
--         table.insert(t, TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor"))
--     end,
--     no_validation = true,
-- }
-- :AddLocationCast{
--     cast_id = "home",
--     when = QWHEN.MANUAL,
--     cast_fn = function(quest, t)
--         table.insert(t, quest:GetCastMember("primary_advisor"):GetHomeLocation())
--     end,
-- }
-- :AddLocationCast{
--     cast_id = "player_room",
--     when = QWHEN.MANUAL,
--     cast_fn = function(quest, t)
--         table.insert(t, TheGame:GetGameState():GetLocation(quest:GetCastMember("home").content_id .. ".inn_room"))
--     end,
-- }
:AddObjective{
    id = "visit",
    title = "Visit {primary_advisor}",
    desc = "{primary_advisor} provides help with your negotiation.",
    state = QSTATUS.ACTIVE,
    hide_in_overlay = true,
    low_priority = true,
    mark = {"home"},
}
DemocracyUtil.AddAdvisors(QDEF)
DemocracyUtil.AddPrimaryAdvisor(QDEF)
DemocracyUtil.AddHomeCasts(QDEF)

QDEF:AddConvo(nil, "primary_advisor")
    :Priority(CONVO_PRIORITY_LOW)
    :Loc{
        DIALOG_REMOVE = [[
            agent:
                Getting overwhelmed? Let me help you focus...
        ]],
        OPT_CHECK_SUPPORT = "Check support...",
        DIALOG_CHECK_SUPPORT = [[
            agent:
                !give
                Here's the analysis of your support level.
        ]],
        OPT_CHANGE_OUTFIT = "Go to your room",
        TT_OUTFIT = "Change into another of {player}'s outfits.",
        TT_PET = "Play with {1#agent}.",
        TT_PETS = "Play with your pets.",
        TT_OUTFITPET = "Change into another of {player}'s outfits or play with {1#agent}.",
        TT_OUTFITPETS = "Change into another of {player}'s outfits or play with your pets.",

        DIALOG_CHANGE_OUTFIT = [[
            player:
                I need to access my room.
            agent:
                !handwave
                I ain't going to stop you.
                !exit
        ]],
    }
    :Hub(function(cxt)
        cxt:Opt("OPT_CHECK_SUPPORT")
            :PreIcon(DemocracyConstants.icons.support_transparent)
            :Dialog("DIALOG_CHECK_SUPPORT")
            :Fn(function(cxt)
                cxt:Wait()
                TheGame:FE():InsertScreen( DemocracyClass.Screen.SupportScreen(nil, function(screen)
                    cxt.enc:ResumeEncounter()
                end) )
                cxt.enc:YieldEncounter()
            end)

        if not cxt:GetAgent():GetBrain():IsOnDuty() then
            return
        end

        StateGraphUtil.AddRemoveNegotiationCardOption( cxt, "DIALOG_REMOVE" )


        local unlocked_outfits = 1
        for k,v in ipairs( Content.GetOutfitsForCharacter(cxt.player.id) ) do
            if v.unlocked or TheGame:GetGameProfile():HasUnlock( v.id ) then
                unlocked_outfits = unlocked_outfits + 1
            end
        end
        local num_pets = #cxt.caravan:GetPets()
        local tt = ""

        if unlocked_outfits > 1 and num_pets == 1 then
            tt = loc.format( cxt:GetLocString( "TT_OUTFITPET" ), cxt.caravan:GetPets()[1] )
        elseif unlocked_outfits > 1 and num_pets > 1 then
            tt = loc.format( cxt:GetLocString( "TT_OUTFITPETS" ) )
        elseif unlocked_outfits > 1 then
            tt = cxt:GetLocString( "TT_OUTFIT" )
        elseif num_pets == 1 then
            tt = loc.format( cxt:GetLocString( "TT_PETS" ) )
        elseif num_pets > 0 then
            tt = loc.format( cxt:GetLocString( "TT_PET" ), cxt.caravan:GetPets()[1] )
        end
        if unlocked_outfits > 1 or num_pets > 0 then
            cxt:Opt("OPT_CHANGE_OUTFIT")
                :PreIcon( global_images.backpack )
                :PostText( tt )
                :Dialog( "DIALOG_CHANGE_OUTFIT" )
                :Fn(
                    function(cxt)
                        if not cxt.quest:GetCastMember("player_room") and cxt.quest:GetCastMember("primary_advisor") then
                            if not cxt.quest:GetCastMember("home") then
                                cxt.quest:AssignCastMember("home")
                            end
                            cxt.quest:AssignCastMember("player_room")
                        end
                        cxt.encounter:DoLocationTransition( cxt.quest:GetCastMember("player_room") )
                        cxt:End()
                    end
                )
        end
    end)