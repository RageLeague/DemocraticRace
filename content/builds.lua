local new_builds = {
    female_benni_build = CreatePersonBuild{
        gender = GENDER.FEMALE,
        file = "anim/med_female_tei_utaro_build.zip",
        gloves = GLOVES.SIMPLE,
        colours={base_glove = 0x312926ff},
        -- no_hand_swap = true,
        glow = { colour = 0x11FFFEFF, bloom = 0.15, threshold = 0.02 }
    },
    cognitive_hesh_build = CreateCreatureBuild({

        dialog_build = "DEMOCRATICRACE:assets/anim/hesh.png.zip",
        dialog_anim = "DEMOCRATICRACE:assets/anim/hesh.png.zip",
        combat_anims = { "DEMOCRATICRACE:assets/anim/hesh.png.zip", },
        portrait_anim = "DEMOCRATICRACE:assets/anim/hesh.png.zip",
    })
}

Content.AddCharacterBuilds(new_builds)
