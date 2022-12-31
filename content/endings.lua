local FAIL_ENDINGS = {
    arrested = {
        slides = "democracy_fail_arrested",
        name = "Arrested",
    },
    no_more_advisors = {
        slides = "democracy_fail_no_more_advisors",
        name = "No more advisors",
    },
    broken_mind = {
        slides = "democracy_fail_broken_mind",
        name = "Broken Mind",
    },
    disappearance = {
        slides = "democracy_fail_disappearance",
        name = "Disappearance",
    },
}
local SUCCESS_ENDING = {

}
local function FillOutEndingFlags(flags)
    local advisor = TheGame:GetGameState():GetMainQuest():GetCastMember("primary_advisor")
    if advisor then
        flags[string.lower(advisor:GetContentID())] = true
        if advisor:GetRelationship() == RELATIONSHIP.LOVED then
            flags.advisor_loved = true
        end
    end
    local player = TheGame:GetGameState():GetPlayerAgent()
    flags[string.lower(player:GetContentID())] = true
end
local function DoEnding(cxt, ending, flags)
    flags = flags or {}
    local ending_data = FAIL_ENDINGS[ending]
    local is_win
    if not ending_data then
        ending_data = SUCCESS_ENDING[ending]
        is_win = true
    end
    assert(ending_data, "Invalid ending: " .. tostring(ending))
    FillOutEndingFlags(flags)

    local slides = ending_data.slides
    if type(slides) == "function" then
        slides = slides(cxt, flags)
    end
    assert(type(slides) == "string", "Invalid ending slides")
    cxt.enc:ShowSlides(slides, flags, function()

        -- TheGame:AddGameplayStat("democracy_get_ending_" .. ending, 1)
        if is_win then
            TheGame:Win()
        else
            TheGame:Lose()
        end
    end )
end

return {
    FAIL_ENDINGS = FAIL_ENDINGS,
    SUCCESS_ENDING = SUCCESS_ENDING,
    DoEnding = DoEnding,
}
