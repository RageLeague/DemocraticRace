local val =  {
    SECURITY = {
        name = "Universal Security",
        desc = "Security is a big issue in Havaria. On the one hand, improving security can drastically reduce crime and improve everyone's lives. On the other hand, it can leads to corruption and abuse of power.",
        stances = {
            [-2] = {
                name = "Defund the Admiralty",
                desc = "The Admiralty has always abused their power and made many false arrests. It's better if the Admiralty is defunded, and measures must be put in place to prevent anyone else from taking this power.",
            },
            [-1] = {
                name = "Cut Funding for the Admiralty",
                desc = "While it's important to have some sort of public security, at the current state, the Admiralty has too much power and is abusing it. By cutting their funding, their influence will be reduced.",
            },
            [0] = {
                name = "No Change",
                desc = "The current system works just fine. There's no need to change it.",
            },
            [1] = {
                name = "Increase Funding for the Admiralty",
                desc = "Havaria is overrun with criminals of all kind. That's why we need to improve the security by increasing funding for the Admiralty. This way, the people can live in peace.",
            },
            [2] = {
                name = "Universal Security for All",
                desc = "Havaria is overrun with criminals of all kind, and the only way to fix it is through drastic measures.",
            },
        },
    },
    INDEPENDENCE = {
        name = "Deltrean-Havarian Annex",
        desc = "The annexation of Havaria into Deltree has stroke controversies across Havaria. On the one hand, a full integration of Havaria to Deltree will likely improve Havaria's prosperity. On the other hand, it is a blatant disregard to Havaria's sovereignty.",
        stances = {
            [-2] = {
                name = "Total Annexation",
                desc = "Havaria and Deltree become one country, with no special treatment.",
            },
            [-1] = {
                name = "Havarian Special Administration",
                desc = "Havaria is part of Deltree by name, but Deltree must not intervene with Havaria's internal affairs too much to allow better integration.",
            },
            [0] = {
                name = "I don't care",
                desc = "[p] i just want to grill for hesh sake",
            },
            [1] = {
                name = "Vassal State",
                desc = "Havaria become a vassal state of Deltree. However, they are still different nations, and Deltree must respect the autonomy of Havaria.",
            },
            [2] = {
                name = "Havaria Independence",
                desc = "Havaria will become completely independent of Deltree, and Deltree should recognize the independence and respect Havaria's autonomy.",
            },
        },
    },
}
for id, data in pairs(val) do
    data.id = id
end
return val