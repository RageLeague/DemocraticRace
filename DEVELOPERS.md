# Developers Notice

By: RageLeague

**Important!** If you are a developer working on this project, you need to read this to know what is going on. But before you do that, you should read the README file to learn what is going on about this project. It's long, and you don't really need to read them all. It's just there for reference.

## Golden rules

* Don't directly commit to master. Only **I** am allowed to do that. Fork a branch and submit a pull request, so I know what changed from your edit.
* Try to affect the base game or other mods as little as possible.
  * Use IDs that has low chance of colliding with other IDs, same for defining global variables.
  * Try not to change existing cards/grafts/functions, and if you have to, do it in a way that won't affect gameplay for the base game/other mods.
  * Don't declare cards/grafts that belong in the general series that are not unique or basic, because it will show up in the card/graft pools in the base game.
  * Don't add convos that doesn't check for act IDs. You know what happens with the Shel mod.
* Try to use a standard naming convention for variables or functions that are meant to be used repeatedly. A good naming convention allows others to read your code easily, and saves you time commenting. Don't use "a", "foo", "test" for variable names that are used repeatedly. Klei's naming convention is basically this:
  * UpperCamelCase for class names, function names, and method names.
  * lower_snake_case for local variables, card IDs, region IDs, table fields, etc.
  * UPPER_SNAKE_CASE for constants/constant tables, enums, most IDs.
  * Nobody has any idea what the naming convention for plax IDs are.
  * Names and IDs should be easily readable in English, and shouldn't contain acronyms unless you know everyone knows what that means.
* If you have any questions, ask! I basically never leave my computer anyways.

## What you can work on

Here lists all the different things you can work on.

* Rally jobs. Rally jobs are jobs you get periodically. Each rally job applies to all ideology, and is a way to gain support or funding. See `change_my_mind.lua` for an example of a rally job. I haven't figured out the balance yet, but each rally job should hopefully give you 10~20 general support stats, as well as 2 people who likes you(on average). Some people may also dislike you on rally jobs if you did not so well.
* Random events. These events randomly shows up when you travel. Because of the structure of this campaign, it is probably best if these random events tie to the fact that you're a politician, and affects the support level in various groups in some ways. If you want to start, you can copy the code from existing events and start there. Generally, random events in this campaign should focus on negotiation, with combat heavily discouraged(such as only showing up if you fail a negotiation).
* Replacing placeholder dialogs. A lot of the dialogs right now are placeholder. These dialogs can be identified by a "[p]" at the start, and/or has improper spelling of words or grammar. Be sure that if you want to replace dialogs, they fit the lore or the characterization of important characters. You can add extra fluff to the dialogs if you know how to set up conditionals, but if you don't know how, you can always ask me and I might be able to answer.
* Tweaking stances and support for oppositions. A lot of issue, stances and opposition support have placeholder description and/or support deltas. Feel free to tweak them, just follow some general guidelines. Every stance you take has a sum of support less than 0(although not by much), because just like in real life, every time you take a stance, people hate you than they like you. The number of factions/wealth levels that has a positive/negative support for each stances should be roughly equal, unless it's the neutral stance.
* Adding arts to card/modifiers. If you want. It would probably be more efficient if everything is done at the end, but if you want to, you can. The only guideline is that the art has to fit the card/modifier, and does not break the game's rating.
* You can do more complicated things such as writing main stories, adding new locations, adding convos for new/existing locations, or add ways you can "deal" with certain(read "hated") characters without provoke-killing(maybe something like a criminal investigation, or hire assassination services). Make sure you actually know what you're doing, and you let me know beforehand what you're doing.

## Lore

It's important that anyone who works on dialogs, quests or stories should know the lore of this campaign. It's basically an AU of Griftlands where different factions simultaneously decide to determine who rules Havaria through democracy. Here are some details.

### The Grand Scheme of Things

* There hasn't been a reason they decide to have democracy. All you need to know is that the election is on day 5 of the campaign and a lot of people will vote.
* Some people might not like the idea of voting and would rather solve problems with fists, but majority aren't this way.
* There are many polarized issues in Havaria. See political_issues.lua for more details. Your job as a politician is to campaign on some of these issues so you can gain support.
* Each faction in Havaria may or may not be just pretending to agree to the election, and once the election resolve, if the result is not in their favour, they may or may not show their true colors.(Why is there both British and American spelling of words? Good question, probably because English is not my first language.)

### Characters

***Advisors***

All three advisors are arrogant, self-centered, and uses bad debate tactics that only works if said debate is political, which is the case in this campaign. Each represents a negotiation card type, and they will be more likely to sell you a card of that type if you choose them as your advisor. When you write their dialog, keep their personality in mind. Although they uses character defs from the game, they should have no connections to them other than what they sell. I plan to add custom defs for these characters in the future.

* **Diplomacy Advisor(Endo TBD)**: Inspired by Elon Musk and Reddit, their character is about being "relatable". The "fellow kids" type, who may or may not likes old and/or bad memes. Their way of debating is by being relatable, and appeal to emotions, but once you crossed them, they will harass you and/or guilt trip you. A good way to write their dialog is to write it normally, and force a meme here and there, sprinkled across. If you want capture the Reddit personality, use languages such as "wholesome 100", "downvote", "r/whoosh", and make it so that they are looking down on whomever they are talking to. Their personality is an afterthought, after I determined the next two advisors'.
  * Catchphrases:
    * "Wholesome 100"
    * "That's cringe. That's going to be a downvote for me."
* **Manipulate Advisor(Plocka TBD)**: Inspired by Ben Sharpiro, their character is about sounding smart by using big words, using straw man arguments, and nitpick minor details. He often say things like "hypothetically", or "um, actually". A good way to write their dialog is by finding the argument part, build a false premise with "hypothetically" and a conclusion that they want you to believe, connect them with non-sequiturs, nitpick on minor details, and sprinkle some "FACTS and LOGIC" here and there. If you want to mention their wife is a doctor, you can, but try not to add too much unnecessary words.
  * Catchphrases:
    * "... owns ... with FACTS and LOGIC."
    * "Hypothetically speaking..."
* **Hostile Advisor(Rake TBD)**: Inspired by Donald Trump, their character is about shutting down the opposition and show how good they are at everything. They often resort to boasting, name calling, and bragging, and is even more hostile than other advisors. A good way to write their dialogs is to add "huge", "tremendous", "bigly", and other words like that. They also often call their oppositions names they made up on the spot, often with alliteration, and shifting blames on them. They also often stop their train of thought midway through the sentence, and go on a tangent.
  * Catchphrases:
    * "Nobody knows ... better than me."
    * "Big success, tremendous success."

***Oppositions***

Oppositions are other candidates that are also participating in this election. They are existing characters, and are prominent members of each faction. Their character should be very close to the original ones from the game.

* **Admiralty Candidate(Oolo)**
* **Spree Candidate(Nadan)**
* **Spark Baron Candidate(Fellemo)**
* **Rise Candidate(Kalandra)**
* **Cult Candidate(Vixmalli/Tei?)**
* **Jakes Candidate(I have no idea)**

Potential meme candidates:

They may or may not be added. It might be too much work. If they were to be added, they should be added way later.

* **Bogger Candidate(Glofriam)**
* **Shel**

***Other notable NPCs***

* **Fssh**
* **Interviewer(The auctioneer)**
