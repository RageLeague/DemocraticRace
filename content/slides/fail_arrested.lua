return 
{
    -- This slideshow plays if the player skips the prologue completely!
    
    --sound_event = "event:/vo/narrator/cutscene/sal_intro",
    music = "event:/music/slideshow_sal",
    script=
    {
        {
            mov = 'movies/smith_act1_slide_04.ogv',
            txt = "You were put into admiralty custody. While you technically under investigation, in the admiralty it's never that simple.",
        },
        {
            img = 'DEMOCRATICRACE:assets/slides/arrested_1.png',
            txt = "The investigation was quick, or at least it should've been. However, due to your political and past affiliations.\n\n" ..
            "You were kept for much longer as the higher ups tacked item after item onto the list of reasons to keep you locked up.\n\n" ..
            "During this time, you were held in a jail cell, unable to go around and promote your platform as you had done before.\n\n" ..
            "Even after you left, the scandal tainted your image for the rest of your political career.",
        },
        {
            mov = 'movies/rook_act4_slide_03c.ogv',
            txt = "Not to say there's much for a political career outside of the cell.\n\n" ..
            "The election had ended by the time you left the jail, and some other big name became the president of Havaria.\n\n" ..
            "Retired from your campaign, you silently slink back into your life as a roving grifter, never belonging, or trying to belong.\n\n" ..
            "This is where your journey as a politician ends.",
        },
       
    }
}    

