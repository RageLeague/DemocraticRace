return 
{
    -- This slideshow plays if the player skips the prologue completely!
    
    --sound_event = "event:/vo/narrator/cutscene/sal_intro",
    music = "event:/music/slideshow_sal",
    script=
    {
        {
            mov = 'movies/sal_act1_slide_02.ogv',
            -- img = 'DEMOCRATICRACE:assets/slides/intro_1.png',
            
            txt = "Havaria has never been a peaceful place.\n\n" ..
                "Major factions fought for the influence over the land, while many people are caught within the crossfire.",
            
        },

        {
            img = 'DEMOCRATICRACE:assets/slides/intro_1.png',
            
            txt = "One day, in an unprecedented event, the leaders of major factions decided to sit together and negotiate a deal.\n\n" ..
                "They have decided to settle the situation peacefully with an election, where the most popular candidate gets to rule over Havaria.",
            
        },


        {
            mov = 'movies/rook_act1_slide_02.ogv',
            
            txt = "Having heard of the news, many people flooded to Pearl-on-Foam, the location where the election shall take place in.\n\n" ..
                "You are among one of those people, seeking for opportunities to make a few shills out of this unprecedented situation.",
            
        },
        {
            mov = 'movies/sal_act4_slide_07.ogv',
            
            txt = "Now, a brand new Havaria awaits you, in the form of a Democratic Race!\n\n" ..
            "(Hey! That's the name of this mod!)",
            
        },

       
    }
}    

