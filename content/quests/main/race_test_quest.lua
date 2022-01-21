local QDEF = QuestDef.Define
{

    qtype = QTYPE.STORY,

}

QDEF:AddConvo( nil, nil, QUEST_CONVO_HOOK.INTRO )
    :Loc{
        DIALOG_INTRO = [[
            player:
                !left
            * Testing inline notation:
                quest_true={quest_true?true|false}
                quest_false={quest_false?true|false}
                scratch_true={scratch_true?true|false}
                scratch_false={scratch_false?true|false}
                param[1]={1}
                param[2]={2}
            * Testing multiline notation:
            {quest_true?
                quest_true=true
                |
                quest_true=false
            }
            {quest_false?
                quest_false=true
                |
                quest_false=false
            }
            {scratch_true?
                scratch_true=true
                |
                scratch_true=false
            }
            {scratch_false?
                scratch_false=true
                |
                scratch_false=false
            }
        ]],
    }
    :State("START")
        :Fn(function(cxt)
            cxt.quest.param.quest_true = true
            cxt.enc.scratch.scratch_true = true
            cxt:Dialog("DIALOG_INTRO", true, false)
            print("Testing loc.format")
            print(loc.format("{1?true|false}", true, false))
            print(loc.format("{1}", true, false))
            print("Testing cxt:GetLocString")
            print(cxt:GetLocString("DIALOG_INTRO", true, false))
            -- cxt.quest:Activate("go_to_junction")
            -- StateGraphUtil.AddEndOption(cxt)
        end)
