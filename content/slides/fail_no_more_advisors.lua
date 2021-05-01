return 
{
    -- This slideshow plays if the player skips the prologue completely!
    
    --sound_event = "event:/vo/narrator/cutscene/sal_intro",
    music = "event:/music/slideshow_sal",
    script=
    {
        {
            flag = "advisor_dead",
            mov = 'movies/smith_act1_slide_04.ogv',
            txt = "With the death of your advisor, there is no one left to help you in your campaign.",
        },
        {
            flag = "advisor_retired",
            mov = 'movies/smith_act1_slide_04.ogv',
            txt = "With the disappearance of your advisor, there is no one left to help you in your campaign.",
        },
        {
            flag = "advisor_rejected",
            mov = 'movies/smith_act1_slide_04.ogv',
            txt = "The last advisor available to you decided that you are not worth the trouble, as you lost the trust of the final person who is willing to help you.",
        },
        {
            flag = function(flags)
                return not (flags["advisor_dead"] or flags["advisor_retired"] or flags["advisor_rejected"])
            end,
            mov = 'movies/smith_act1_slide_04.ogv',
            txt = "There is no one left for you to rely on for your campaign.",
        },
        {
            txt = "With that, your campaign cannot continue, and you are forced to end your campaign.\n\n"
                .. "Any effort you put into your campaign are all for nothing.",
        },
       
    }
}    

