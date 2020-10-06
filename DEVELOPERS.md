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

## Dev Tools

* Press ~ on the main screen, and at the bottom, you can quick start a campaign of Democratic Race.

## Mechanics

Here are the mechanics present in this campaign. If you want to make new quests, try to incorporate a lot of them.

* **Wealth Level**: In addition to grouping voter groups by factions, I also decided to group voter groups by wealth. The wealth level of a character determines how much wealth they have(duh), and determines what political stance they will be likely to take.
  * It is determined by a character's "renown", a hidden stat in game that determines a person's social standing.
  * It is represented with an integer, and has 4 levels: Lower, Middle, Upper, and Elite Class.
  * Anyone with a renown above 4 is in the upper class. I might make civilians with the tag "wealthy" a level higher, since that will align with their voting groups more.
  * To query, use `DemocracyUtil.GetWealth(a)`, where `a` is either an Agent or a number representing the renown.
* **Support**: The big selling point of this mod, although legally I'm not allowed to "sell" this mod.
  * There are 3 categories related to this:
    * General Support: Everyone's opinion about you. Involved in certain hard-checks, and is used as the base level to calculate other types of support.
    * Faction Support: A faction's opinion about you. Affects your standing in a faction, and may affect how likely you can ally with other candidates of that faction.
    * Wealth Support: A wealth class' opinion about you. Affects your standing in a faction, and is used to calculate the funding you get at the end of each day.
  * Faction Support and Wealth Support are stored as a relative value, the difference from general support. This means that if your general support increases, your apparent faction support and wealth support also increases.
  * There's another type of support called Compund Support. It factors in both the faction and wealth of a character, and is used to determine how likely this character will support you. Used to calculate scores in quest casts. The higher that agent's support is, the more likely they will show up as casts that require supporters, and the lower that agent's support is, the more likely they will show up as casts that require oppositions.
  * Support can be affected by various means:
    * Completing quests(increase general support by a lot).
    * Getting characters to change their relationship with you(affects all three support stats).
    * Murdering a character(high decrease in all three stats, but less if done so in an isolated environment). Being an accomplice of killing or letting your teammate die will also reduce the stats. Note killing will not get rid of support loss from getting a character to hate you.
    * Taking stances on issues(affects faction/wealth support). Note: taking a consistent stance on issues will increase support slightly, while constantly changing stances will decrease support.
    * Choosing certain options in quests.
* **Issues and Stances**: As a politician, your main job is supposed to be solving people's problems. You are able to take stances on certain issues, which have various effects.
  * Each issue has a name, a description about it, and stances on this issue ranging from -2 ~ 2. The magnitude of the stance represent how extreme your opinion on this issue is, while the sign represents which general side you're on. Generally, the more extreme you are, the more support you will gain/lose from individual factions/wealth levels.
  * The sum of support gain/loss of a certain stance is always slightly negative, because people will hate you more than they like you.
  * If you take a consistant stance(stance that is the same as/similar to your old stance), you will be rewarded with a little bit of support. But if you switch stances, you might lose support, depending on how much you changed. This encourages you to not easily take stances to appease people, and if you do, at least stick to it.
  * When you take a stance, it can be "strict" or not. For a strict stance to be consistent, it must be the exactly the same as your old stance. For a non-strict stance to be consistent, it just needs to be the same sign as your old stance.
  * Each NPC can also take a stance on an issue. This is useful when casting characters, where only someone with a certain stance is allowed. Use `IssueLocDef:GetAgentStanceIndex(agent)` to deterimine an agent's stance on an issue.
* **Advisors**: Some time during day 1, you will get a primary advisor. Their office is your home location, and you can buy cards, remove cards, check support level, etc.
* **Special Negotiation**: Because negotiations are a big focus of this campaign, a lot of the negotiations have special quirks to them. Feel free to add some quirks to negotiations. I also encourages the results of some negotiations to be non-binary, which means that other than win/lose, depending on how well you do on this negotiation, there are some other effects.
* **Free Time**: This mod gets rid of the opportunity system in favour of the free time system. During a free time event, you are given action points(8) that you can spend on various activities.
  * You can spend action points on:
    * Travelling to new locations by road(1).
    * Doing a negotiation or battle(2).
    * Spend time with your friends(3).
* **Spend Time With Friends**: This is an action you can take during your free time. Spend 3 actions to choose someone who at least likes you, and they will give you a random boon service, or tell you a random location(that is appropriate for their faction). You can do this once per day for each person.
* **Funding Gain**: At the end of each day, you will get funding for you to spend on various activities. Just look at the CalculateFunding function under the main quest file.
* **Shilling**: In place of the bribery system in regular quests, we have paying for shills. You spend money on people who are free to shill for you, which means that they will have the "bribed" status, and people with "bribed" status will be more likely to show up in rally jobs.
  * The shill cost is determined by that agent's renown.
  * You can bribe anyone with relationship dislike or up. The cost will also be affected.
  * People who are bribed might also turn an otherwise unfavourable situation into a less unfavourable situation.
  * The "bribed" status is removed at the end of the quest if they are involved in that quest.
* **Bodyguard**: You can hire a free person to protect you. Basically that means they are a hired mercenary, and follows the same rule as in the base game. Slightly cheaper, though.
* **Rally Quest**: You periodically get rally quests. They are your primary means of gaining support levels. The result of these quests are non-binary for the purpose of the effect on your campaign, because depending on how well you do, you get higher support levels and more people to like you. You don't get money from those quests, except as extra reward, or directly gained from the quest. I might make it so that in place of a rally quest, you can get a free time.
* **Request Quest**: During certain events, you will occasionally encounter request quests from NPCs. They ask you to solve a problem that they can't solve themself, but you as a politician and a grifter can solve it. They may or may not provide money for you, but most importantly, they provide a huge support boost and a person loving you. They are only solvable during your free time, and there are various ways to solve it.

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

* **Fssh** The barkeep at Grog n' Dog, she is not participating in the election, thanks for asking.
* **Interviewer(The auctioneer)** The guy who works at the Grand Theater as a host there. It used to be just an auction house, but now it has been expanded and is used for other activities as well.
