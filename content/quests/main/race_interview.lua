local INTERVIEWER_BEHAVIOR = {
    OnInit = function( self, difficulty )
		-- self.bog_boil = self:AddCard("bog_boil")
		self:SetPattern( self.BasicCycle )
        local modifier = self.negotiator:AddModifier("INTERVIEWER")
        -- modifier.agents = shallowcopy(self.agents)
        -- modifier:InitModifiers()
        self.cont_question_card = self:AddCard("contemporary_question_card")
        self.modifier_picker = self:MakePicker()
            :AddArgument("LOADED_QUESTION", 2)
            :AddCard(self.cont_question_card, 1)
    end,
    available_issues = copyvalues(DemocracyConstants.issue_data),
	-- Duplicated from Bandits. Needs revision
	BasicCycle = function( self, turns )
		-- Double attack every 2 rounds; Single attack otherwise.
		if self.difficulty >= 4 and turns % 2 == 0 then
			self:ChooseGrowingNumbers( 3, -1 )
		elseif turns % 2 == 0 then
			self:ChooseGrowingNumbers( 2, 0 )
		else
			self:ChooseGrowingNumbers( 1, 1 )
        end
        self.modifier_picker:ChooseCard()
	end,
}


local QDEF = QuestDef.Define
{
    title = "Interview",
    desc = "Do the interview and gain support.",

    qtype = QTYPE.STORY,
    collect_agent_locations = function(quest, t)
        table.insert(t, { agent = quest:GetCastMember("primary_advisor"), location = quest:GetCastMember('backroom'), role = CHARACTER_ROLES.VISITOR})
        table.insert(t, { agent = quest:GetCastMember("host"), location = quest:GetCastMember('theater')})
    end,
    -- on_start = function(quest)
        
    -- end,
}
:AddCast{
    cast_id = "host",
    cast_fn = function(quest, t) 
        if quest:GetCastMember("theater"):GetProprietor() then
            table.insert(t, quest:GetCastMember("theater"):GetProprietor())
        end
    end,
    when = QWHEN.MANUAL,
    events = 
    {
        agent_retired = function( quest, agent )
            -- if quest:IsActive( "get_snail" ) then
                -- If noodle chef died before we even got the snail, cast someone new.
                quest:UnassignCastMember( "host" )
                quest:AssignCastMember( "host" )
            -- end
        end,
    },
}
:AddCastFallback{
    cast_fn = function(quest, t)
        quest:GetCastMember("theater"):GetWorkPosition("host"):TryHire()
        if quest:GetCastMember("theater"):GetProprietor() then
            table.insert(t, quest:GetCastMember("theater"):GetProprietor())
        end
    end,
}
:AddLocationCast{
    cast_id = "theater",
    cast_fn = function(quest, t)
        table.insert(t, TheGame:GetGameState():GetLocation("GRAND_THEATER"))
    end,
    on_assign = function(quest, location)
        quest:SpawnTempLocation("BACKROOM", "backroom")
        quest:AssignCastMember("host")
    end,
    no_validation = true,
}
:AddLocationCast{
    cast_id = "backroom",
    no_validation = true,
    on_assign = function(quest, location)
        location:SetMapPos( quest:GetCastMember("theater"):GetMapPos() )
    end,
    when = QWHEN.MANUAL,
}
:AddObjective{
    id = "go_to_interview",
    title = "Go to interview",
    desc = "Meet up with {primary_advisor} at the Grand Theater.",
    mark = {"backroom"},
    state = QSTATUS.ACTIVE,
}
:AddObjective{
    id = "do_interview",
    title = "Do the interview",
    desc = "Try not to embarrass yourself.",
    mark = {"theater"},
    -- state = QSTATUS.ACTIVE,
}

:AddLocationDefs{
    BACKROOM = {
        name = "Grand Theater Back Room",
        plax = "INT_Auction_Backroom_1",
        map_tags = {"city"},
        indoors = true,
    },
}

DemocracyUtil.AddPrimaryAdvisor(QDEF, true)

QDEF:AddConvo("go_to_interview")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt.location == cxt.quest:GetCastMember("backroom") end)
        :Loc{
            DIALOG_INTRO = [[
                * [p] you arrive at the Grand Theater, and you see that {primary_advisor} is waiting for you.
                player:
                    !left
                primary_advisor:
                    !right
                    are you ready?
                player:
                    aye aye, captain.
                primary_advisor:
                    i can't heeeear you!
                player:
                    AYE AYE CAPTAIN!
                primary_advisor:
                    oooooo!
            ]],
        }
        :Fn(function(cxt)
            cxt:Dialog("DIALOG_INTRO")
            cxt.quest:Complete("go_to_interview")
            cxt.quest:Activate("do_interview")
            cxt:Opt("OPT_LEAVE_LOCATION")
                :Fn(function(cxt)
                    cxt.encounter:DoLocationTransition(cxt.quest:GetCastMember("theater"))
                end)
                :MakeUnder()
        end)
QDEF:AddConvo("do_interview")
    :ConfrontState("STATE_CONFRONT", function(cxt) return cxt.location == cxt.quest:GetCastMember("theater") end)
        :Loc{
            DIALOG_INTRO = [[
                * [p] when you enter the room, you see a bunch of people
                * Looks liek lots of people wants to watch your interview.
                agent:
                    let's welcome our special guest tonight, {player}!
                * everyone clapped.
                * try to survive the interview, i guess?
            ]],
            OPT_DO_INTERVIEW = "Do the interview",
        }
        :Fn(function(cxt)
            cxt.enc:SetPrimaryCast(cxt.quest:GetCastMember("host"))
            cxt:Dialog("DIALOG_INTRO")
            cxt:GetAgent().temp_negotiation_behaviour = INTERVIEWER_BEHAVIOR
            cxt:Opt("OPT_DO_INTERVIEW")
                :Negotiation{

                }
        end)