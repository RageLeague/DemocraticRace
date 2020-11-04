BOON_SERVICES.SOCIALIZE_NO_LOVE =
{
    on_init = function(quest)
        quest.param.restoration = 10
    end,

    name = function(quest)
        return LOC"CONVO.OPPO_FRIEND_BOON.SOCIALIZE.NAME"
    end,

    can_offer = function(agent) 
        return agent:GetRelationship() == RELATIONSHIP.LIKED
    end,
    
    desc = function(quest)
        return loc.format( LOC"CONVO.OPPO_FRIEND_BOON.SOCIALIZE.DESC", nil, quest.param.restoration )
    end,

    txt = 
    {
        NAME = "Socialize with {friend}",
        DESC = "{friend} is feeling friendly. Spending some time with {friend.himher} will restore <#RESOLVE>{2} Resolve</>.",

        DIALOG_INTRO = [[
            agent:
                !greeting
                $happyGreeting
                {player}! I was just thinking about you.
                You busy?
        ]],
        OPT_SOCIALIZE = "Chat with {agent}",
        TT_SOCIALIZE = "Restore <#RESOLVE>{1} Resolve</>",
        DIALOG_SOCIALIZE = [[
            * {agent} chats with you a while.
        ]],
        REQ_NOT_TIRED = "You already have full Resolve",
    },
    icon =  engine.asset.Texture( "icons/quests/oppo_friend_socialize.tex"),
    fn = function(cxt)
        cxt:Dialog("DIALOG_INTRO")
        local resolve, max_resolve = cxt.caravan:GetResolve()
        cxt:Opt("OPT_SOCIALIZE")
            :PreIcon(global_images.like)
            :DeltaResolve( cxt.quest.param.restoration )
            :Dialog( "DIALOG_SOCIALIZE" )
            :Fn( function( cxt )
                if cxt:GetAgent().smalltalk then
                    cxt:Dialog( cxt:GetAgent().smalltalk )
                else
                    cxt.encounter:SayQuip( cxt:GetAgent(), "smalltalk" )
                end
            end )
            -- :ReceiveOpinion(OPINION.SOCIALIZED)
            :Fn(function()
                TheGame:GetEvents():BroadcastEvent( "socialize", cxt.quest.param.restoration, cxt:GetAgent() ) 
            end)
            :DoneConvo()
    end
}