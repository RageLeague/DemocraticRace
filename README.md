# The Democratic Race

A pioneer campaign mod for the (currently) Early Access game Griftlands, the Democratic Race is a mod for Griftlands that adds a negotiation based campaign mode to the game for ALL characters*, in contrast to the direct combat. Your goal in this campaign is to campaign and gain support among the people so you can be voted in as president. This story is heavily negotiation focused, and combat is only necessary if you failed certain negotiations.

This campaign is designed for experienced players of Griftlands, as it expects you to know the mechanics of the game. Also, you might not get certain references or jokes if you're new.

\*Note: If you have modded characters, it has to be loaded before this mod for it to have this campaign.

Version: 0.2.1(Alpha)

Author: RageLeague

Load order:

* Loads After: Cross Character Campaign (https://steamcommunity.com/sharedfiles/filedetails/?id=2219176890)
* Loads After: Shel's Adventure (https://steamcommunity.com/sharedfiles/filedetails/?id=2217590179) or Shel's Adventure Expansion (https://steamcommunity.com/sharedfiles/filedetails/?id=2245060394)
* Loads After: Rise of Kashio (https://steamcommunity.com/sharedfiles/filedetails/?id=2266976421)

(The load order is specified for certain other mods because these modify the game's code, or add new characters to the game.)

Special thanks to:

* JuniorElder(For helping with side quests)
* WumpusThe19th(For helping with dialogs)
* Minespatch(For helping with drawing some slides and card art)
* Playr10(For helping with side quests)

This mod is based on this post that is now archived: https://forums.kleientertainment.com/forums/topic/120281-democracy-mode/.

Supported Languages: English (Right now Simplified/Traditional Chinese is not supported because this is only an Alpha, and lots are bound to change, but it probably will be supported eventually)

## New Contents

* **Brand new negotiations!** Many negotiations in this campaign are not as straightforward as reducing the opponent's core resolve to 0, and have more strategies to them. In addition, some negotiations have non-binary results. It is possible to win every negotiation but still lose the game, because of your terrible choices!
* **A detailed Support mechanic!** Gain as much support as possible, as it determines many factors in this campaign, from the funding you get each day to how likely someone will vote for you. Gain support from various means, by completing quests, befriending people, and making popular decisions.
* **Know your voter base!** Each person in Griftlands has some allegiance with certain factions, and has different wealth levels. This determines what this person cares about politically. Do you hope to win by getting support from the Admiralty, or will you win by appealing to the lower class? Your choice.
* **Take your stances!** Havaria has many problems, and different people have different opinions on certain subjects. Will you increase funding for the Admiralty to win them over, or support better worker rights? Be careful, if you change your stances too much, you will be seen as hypocritical!
* **Pick your advisor!** You get to choose from 3 unique advisors, each specializes in one area of negotiation, and whose resemblence to any entity in real life, living or dead, is totally coincidental! They will help you with your campaign, but make sure to keep them happy, or they will stop supporting you!
* **Know your rivals!** You are not the only one running for the election. Other Havarian bigshots, like Oolo or Kalandra, are also running for the election. You can choose to work together, or you can run against someone. Be careful who you work with, though, as the candidates more or less hate each other, and will not ally with you if you allied with the wrong person.
* **Spend your time wisely!** You will get free time during certain points in the story, during which you can do whatever you want. Will you spend those time socializing with your supporters, or will you learn the location of the market to buy good grafts?
* **Visit an updated Pearl-on-Foam!** The new campaign takes place in the modified version of Pearl-on-Foam, which contains iconic locations throughout Havaria. Meet familiar people, and visit familiar places. Some places even have added functionalities!
* **Outsmart your enemies!** Directly engaging in combat is bad for your reputation, and so is killing people(duh)! However, there are a new variety of ways to deal with them. Put them out of their jobs, arrest them, or hire someone to hunt them down. The choice is yours.
* Brand new side quests, events, and more!

## Alpha Notice

At the current stage, the mod is far from finished. You can play **3** days out of 5 right now, and many mechanics are planned to be added. Some of these mechanics are:

* More side quests and events.
* More things to do at each locations, and more ways to "deal" with your enemies.

I release this alpha to get feedbacks about this mod before the full release. Some of the valid feedbacks are:

* Suggestions for future contents.
* Bug reports.
* Feedback on balance, communications of mechanics, etc.
* Dialog suggestions.

Of course, other forms of feedbacks are welcome.

You can leave feedbacks either on the Steam workshop page (https://steamcommunity.com/sharedfiles/filedetails/?id=2291214111), Klei's forum (DM me or https://forums.kleientertainment.com/forums/topic/123481-the-democratic-racealpha-available/), or on GitHub (https://github.com/RageLeague/DemocraticRace).

## How to install?

### Directly fron GitHub

With the official mod update, you can read about how to set up mods at https://forums.kleientertainment.com/forums/topic/116914-early-mod-support/.

1. Find `[user]/AppData/Roaming/Klei/Griftlands/` folder on your computer, or `[user]/AppData/Roaming/Klei/Griftlands_testing/` if you're on experimental. Find the folder with all the autogenerated files, log.txt, and `saves` directory. If you are on Steam, open the folder that starts with `steam-`. If you are on Epic, open the folder that contains only hexadecimal code.
2. Create a new folder called `mods` if you haven't already.
3. Clone this repository into that folder.
4. The `modinit.lua` file should be under `.../mods/[insert_repo_name_here]`.
5. Volia! Now the mod should work.

Note: The GitHub version will be constantly updated to keep up with new changes. As such, it will be less stable, but will have the latest content. You can also submit pull requests if you want, if you know coding and knows how to fix certain issues or write dialogs.

### Steam workshop

With the new official workshop support, you can directly install mods from steam workshop. You can read about it at https://forums.kleientertainment.com/forums/topic/121426-steam-workshop-beta/ and https://forums.kleientertainment.com/forums/topic/121488-example-mods/.

1. Subscribe this item.
2. Enable it in-game.
3. Volia!

Note: The Steam workshop version of the game will not be constantly updated. It will only be updated if there are game breaking bugs that need to be fixed, or major balance issues, or a major feature update. As such, it will be more stable.

## Changelog

### 0.2.1

* Allow you to look at the next rally job without accepting it. Added tooltip warning you that selecting a rally job will cause free time to end.
* Added haggle negotiation for your daily fundings, if you have haggle badge.

### 0.2.0 (Day 3 update)

This is a major update that introduces a new day to the campaign, and lots of brand new mechanics!

Major changes:

* Day 3 of the campaign is now playable. It contains a brand new night scenario, and a branching noon event, depending on the current state of your campaign.
* New mechanic: Signature cards! Each advisor has a few trick upon their sleeves, and they are happy to teach you if you have enough shills! Their signature cards will sometimes show up in their shop, in place of a rare card.
* New mechanic: Alliance! Talk to other candidates on potential alliances. If your ideology lines up, and you have lots of support among their faction, you can ally with them, granting you massive boost in support. Be careful who you ally with, though, as it can turn away other potential allies!
* Sometimes you will get request quests from your advisor, which, when completed, can cause them to love you. In the future, actual request quests for the advisors will be added. Right now you get placeholders.
* Brand new events, including the one where you arrest a notorious mettle dealer if you so choose.
* A brand new side quest, available from day 1. Has the potential to introduce a few more named characters into your game.

Minor changes:

* Changed the advisors' bio and lore.
* Reworded "loose stance" to "favoring a particular stance".
* Added special negotiation behaviour for Dronumph.
* Reworked demand stance taking. Instead of a random stacks, it always gets 4 stacks. When you destroy it above 2 stacks, it removes the requirement for stance taking. Otherwise, you are only required to favor a stance.
* Added a new demand: demand drinks. It can occur when someone is patronizing a bar, and you can pay for drinks or offer lumin wine(you can't get it yet).
* Rebalance stances and candidate stances.
* Added a mod option that allows you to customize support requirements. It is tied to each game file, so make your decisions before starting a game.
* Update support screen to include your stances, stances of other candiates, the support requirements for each day, and support change breakdowns. It's a lot more useful now.
* Various modifications to dialogs and strings.
* Only laborers who has work can strike for the starving worker. Convincing them to strike while on duty has a resolve penalty.

### 0.1.7

* Watching someone reading propaganda posters no longer costs free time actions.
* You can no longer play cards from hand when watching someone reading propaganda posters. Evoke and passive effects of cards still trigger though, and it is intended.
* After learning an existing location, asking for a new location costs 1 action instead.
* Removing impatience also causes damage to be reduced on this turn.
* Sometimes a non-artist will tell you who is a potential artist.
* Update the office name of Aellon "the Based". Still a total coincidence that it resembles any person, living or dead, right?
* Fix infinite loop where you enter pearl park in a non-Democratic Race act.

### 0.1.6

* Adjusted size of the slides a bit.
* Fix problem where the day progress grift erroneously display that day 1 is completed.
* Added a tab on the negotiation preview indicating that some negotiations can finish at any time without penalties.
* Fix bug where "loose stances" aren't properly working.
* Added a marker when you go to sleep on day 2.
* Give the quest reward when you complete the propaganda quest.
* Added more variance to random oppositions so that you won't get too many consecutive haters from a faction.
* Gives an upfront reward for quests on day 1.
* Rebalance the preach quest.

### 0.1.5

* [HOTFIX] Fixed the situation where no battle grafts are generated as bonus at the start of the run.
* Actually implement forgo rally option.
* Clarify what you need to do in an interview in the negotiation reason.
* Added cool slides by Minespatch.

### 0.1.4(Misc balance adjustments)

* Filter out combat grafts as rewards and combat cards as gifts.
* Disable cooldowns for negotiations so you won't soft lock.
* Guarantees that every quest offered are different(if there are more available side quests than the number offered).
* Relationship change of the primary advisor no longer causes support change.
* Fix crash when you arrive at an arrest scene with the admiralty defeated. Also added an option to let you abort the escort mission.
* Now loads after Cross Character Campaign (https://steamcommunity.com/sharedfiles/filedetails/?id=2219176890), as it modifies the graft reward code which allows Rook's coin graft to be rewarded as regular grafts.

### 0.1.3

* Fix bug where choosing ignore in a political dilemma causes game to crash.
* (Hopefully) fix bug where game crash after first round of preaching.(I think it's because the max range is smaller than the min range? I'm not sure what caused it.)
* (Hopefully) guarantee a negotiation card when offering an item as a boon.
* Revert the change made to the number of cards played by propaganda each turn.
* Filter out battle cards from gifts and graft pools.
* Tweaked the preach quest a bit. Let me know if the balance is better now.

### 0.1.2

* Rebalance the propagandanda side quest so that more cards are played each turn. Hopefully we can see the player win, and maybe they can keep winning for a few days until needing to take them down.
* Added two new modifiers to propaganda posters: Superficial and Thought-Provoking.
* Clarify wordings of various modifiers.
* Fixed bug where propaganda poster modifiers aren't actually working.
* Fixed strike organizing dialogs.

### 0.1.1(Day 1 hotfix lol)

* Rework Preach quest.
* Make end of day 1 negotiation clearer about what you can do.
