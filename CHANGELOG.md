# Full Changelog

### 0.11.0

* Reworked how Public Debate works: there are no damage scaling anymore from Crowd Opinion, and you gain and lose crowd opinion by destroying each other's arguments.
* Reworked the final negotiation of Night 1. It is shorter, but the impatience ramps up a lot quicker, so each turn is a lot more meaningful.
* Added temporary art for signature cards.
* Reduced max resolve for Instigate Crowd.
* Implement "Merchant Startup" and "Loan Shark" event into the Democratic Race.
* Added a dialog case for stripping the foreman's influence in "Revenge Starving Worker".
* Added meal sharing dialog at several restaurants, as well as healing options at different locations.
* Replaced temporary art for "Mask Off" and "False Dichotomy".
* Support change notification is disabled until after support mechanic is unlocked.
* Fixed Stripped Influence crash.
* Fixed upgraded Cognitive Dissonance crashing.
* Added special cases for when timer modifiers gets removed by other means (for example, when they get removed due to argument limit).
* Added special dialog cases.
* Fixed some dialogs.
* Fixed crash during Dole Out if the player didn't gift anyone.
* Fixed (hopefully for the last time) the opposition duplication bug.
* Fixed the game thinking you beat up the foreman in Revenge Starving Worker even if you don't fight them, as long as you win a fight.
* Slightly reworked crowd opinion negotiation because it was too easy after the previous rework, especially if the opponent creates a lot of arguments.
* Updated art for Virtue Signal.
* Reworked crowd opinion negotiation again. The goal is to destroy arguments again, but arguments get more resolve when they enter play, and crowd opinion is a lot more granular. However, you start with a higher crowd opinion.
* Updated plax for main map and Grand Theater.
* Fixed crash at start of day 4 if you get way too few votes and the opponents have way too many votes.
* Fixed incorrect meal sharing options.
* Fixed public debate casting issues.

### 0.10.0

* Added new side quest: "Fundraising".
* Renamed "Secured Investments" to "Secured Funds" in order to make it quest-agnostic.
* Reworked description for "Potential Interest".
* Reworked restrictions for request quest spawning. Now, if your primary advisor has a special request quest, that request quest won't be spawned for a generic person so that the advisor can get it.
* Made Connected Line work better with argument duplication.
* Fixed debate issue not saving correctly in Political Dilemma.
* Escorting the delivery person in Gift From the Bog will now force you to gain bog parasite cards.
* Changed how to gain info about Hesh in Ctenophorian Mystery. Now you can ask anyone about Hesh, but not everyone actually know anything about it.
* Minor dialog changes.
* Refactored special negotiation behaviours into one single file.
* Added Chemists and Ximmon to the list of available healers for "Gift from the Bog".
* Updated some dialogs.
* If you already have an alliance by day 3 morning, you will no longer be offered an alliance that morning.
* Fixed crash on night 3's encounter.

### 0.9.0

* Added new request quest: "Gift From the Bog", and accompanying quests, "Parasite Killer" and "Rampaging Bog Monster".
* Reworked Day 3 debate negotiation music.
* Hid "Question Answer" card from the compendium.
* Bonus scaling for boss arguments now uses level 2 for non-boss negotiation instead of level 1.
* Added cooldowns to request quest spawns, so hopefully a particular request quest only shows up once in a run.
* The hunter cast of "Unlawful Attack" no longer requires validation.
* The benefactor in "Tea With a Benefactor" requires relationship to be neutral or above.
* Added a couple of smalltalks.
* Cleaned up "Dole Out" quest dialogs.
* Capitalize some quest names properly.
* Added an upgraded version of Dole Loaves, and added negotiation versions for both of them. Upgraded Dole Loaves gives a resolve bonus when used, and gifting them to people will cause them more likely to be satisfied.
* Dole Loaves no longer replenishes.
* Added four new advisor signature cards. Removed "Gaslighting" and its upgrades.
* Changed xp requirement for signature cards.
* You can draft a signature card from your advisor whenever you accept an advisor.
* Fixed crash in the event where an Admiralty is defeated by another person and you intimidate the other person into being arrested.
* Removed xp upgrades to dole loaves.
* Fixed incorrect targeting for False Dichotomy.
* Changed Sequencer to match the battle version.
* Changed Limited Time and Long Lecture arguments so they are countdowns, similar to Help Underway!
* Renamed "Faith in Hesh" argument trait to "Devotion".
* Fixed bug of advisor dialog not playing during Public Debate side quest.
* Changes to Ctenophorian Mystery quest (spoilers): fanatics now have a special negotiation behavior, quest progress now shows what Hesh could be, and there are changes to the Hesh dialogs.
* Added cases for Gift From the Bog dialog where the delivery person is dead when you hand in the package.
* Killing a person does not remove their room if that room is casted as a member of a quest.
* Replaced temporary art.
* Added negotiation version of Injury.
* You can no longer visit the Grand Theater during your free time if something is going on at the theater.
* Changed the structure of the start of day 4 a bit.
* Day 3's end summary is immediately activated after the debate.
* Battle card boons at the start of campaign can no longer be skipped, and no longer offer draft bounties.
* An Admiralty can no longer be arrested by the Admiralty during Change My Mind.
* You can no longer travel to locations you've already spread rumors at during Never Meet Your Heroes.
* Winning a negotiation against Hesh during a quest now counts for boss defeated.
* Couple of minor balance/dialog changes.
* Propaganda posters now also record the custom data on the cards.
* Fixed the source of propaganda poster creation.
* Cleaned up code for Connected Line.
* The convo about health loss and its consequences will no longer pop up while traveling.
* Slightly tweaked how the start of day 4 works.
* Some campaign options now correctly scale with the current difficulty.
* Improved dole loaves convo now plays correctly if the target is grateful.
* You can only deliver the package during free time in Gift From the Bog.

### 0.8.0

* Day 4 of the campaign is added. It's a rough skeleton. It is subject to heavy changes.
* Improved debug testing a particular day.
* Added a system for opponent support and opponent dropping out of the race.
* Relationship changes with opponents now causes regular support changes instead of a special one. That one might be used for alliance support change in the future.
* Added additional parameters for negotiation behaviour (technical).
* Added placeholder behaviours for opponents.
* Added test decks.
* Added a new negotiation music for the day 1 end negotiation.
* Added a brand new system for voting. This is used to calculate how each individual character votes, and determine an outcome based on these factors.
* Day 4 now has a poll at the beginning of the day that uses this system. It will determine which candidates will drop the race, and what will happen at the end of day 4.
* Forming or breaking alliances now changes support significantly.
* Debug spawning on day 3+ now correctly spawns some option quests.
* Fixed day 3 start dialog.
* Fixed invalid location for GB_CAFFY.
* Added Fellemo's wordsmith negotiation behaviour.
* Added a new event, where one of your supporters is abhorred by your terrible opinion.
* Talk over now expends.
* Some debug options are locked behind debug mode.
* Updated dialog for lumin wine, oshnudrome races, and the party supply place.
* Fixed voter intention index not considering general support.
* Penalty for inconsistent stance reduced, but inconsistent stance penalty reduction for consistent stances are also reduced.
* Added Vixmalli's wordsmith negotiation.
* Refactored boss scale calculation logic (internal).
* Fixed bug of request quest activating even if you decline.
* When an opposition candidate hinders you at the end of day 4, they now create their faction core instead of the default heckler argument.
* Fixed grammar issue in hinder quip.
* Added Kalandra's wordsmith negotiation.
* Reduced strength for wordsmith behaviour for Fellemo and Vixmalli.
* Fixed description for Desperation for Faith.
* Added new icons for arguments (most are temporary).
* Fixed convo ending prematurely after sleep of night 3.
* Fixed crash in the Jakes vs Rise event.
* Updated dialog for Admiralty arrest.
* Pausing while custom music is playing will slightly less likely cause you to go insane (will mute the custom music and play the soothing deck music instead).
* Fixed minor issue with the day 1 end negotiation music.
* Add wordsmith behaviour for Andwanette.
* Changed old "Etiquette" to "Hospitality".
* Intimidating blaster now specifies that it also counts as a Hostility card.
* Change the wording for cards that cares about Hostility cards.
* Replaced some temporary arts.
* Added unique smalltalk for some skinned generic characters.
* Added two bosses to day 1 end.
* Added more variations for day 1 end. The variation changes depends on the advisor you have, and whether or not your advisor kicked you out on day 1.
* You can only play Appeal to the Crowd if the crowd opinion is less than 5.
* Removed some punctuation for situation modifiers.
* Refusing to drop out of the race on day 4 will cause the person to dislike you, thus preventing them from allying with you again.
* Turned of validation for unlawful attack so you can attack the same target twice using different people. If one succeeds, the money for the other one is refunded.
* Added a new event, where a bunch of people that dislikes you gang up on you.
* Added some more stance quips, and a new category of stance quips: heckle.
* Stance quips can be done without passing in any stances. Doing so will fill out the tags for all the stances the agent has, so that they can find something that contradicts you.
* Added a custom bad nickname system for calling the player a bad nickname.
* Added a side objective for those who likes lore and have too much free time to be wasted on a random negotiation.
* In debate scrum, arguments no longer contribute to scoring (except when candidate explicitly create or destroy arguments with cards).
* The team with less people gets bonus points every turn for each turn they survive while there are more opponents.
* Splash damage are now removed for debate scrum, because splash damage has extremely sketchy source, which interfere with scoring.
* Fixed some issues with certain quips.
* Added count for how many times you arrested people. This will sometimes affect dialog.
* Simplify events where you need to bring someone to the Admiralty station. Now, you don't need to physically go to the Admiralty headquarters. Instead, you just bring them to a local patrol instead. Note: This might break backward compatibility if you have one of these events active in your save file.
* Followup admiralty arrest should now spawn as normal events. Haven't tested it yet, though.
* Remove day 3 noon generic quest. It has been deprecated for a long time, and since I am breaking backward compatibility, I am removing this as well.
* Some events are now marked as negative.
* Made balance changes to some arrest events.
* Remove Gorgula from day 1 boss pool. Her wordsmith negotiation is a bit too strong.
* You can no longer ask the giver of Battle of Wits to play Flip 'Em with themselves.
* Added a new event, where a luminitiate tries to preach to you.
* Reduced support gain during the rise/jakes event if you call off the deal.
* Fixed issue where player religious policy gets overwritten on load even there is nothing to overwrite it with.
* Stance tooltips now includes the support changes of the different groups. Removed notification telling you which factions/wealth classes changed support when your stance changed.
* Use one notification for relationship support change when the notification doesn't have other text (such as graft added/removed).
* Decreased support penalty for murder.
* Added a new event, where a Jakes tries to sell you various illicit substances.
* Added negotiation form of Vapor Vial.
* Minor changes to some dialog.
* Reworked Never Meet Your Heroes quest.
* Increase renown gain from business card.
* Added Oolo's Wordsmith behaviour.
* Fixed bug with Vix's behaviour.
* Balanced Vix and Andwanette's behaviour.
* Fixed missing nil check in bad nicknames.
* Added options to intimidate when Heshians collect tithe from you.
* Added music for day 3 debate.
* Renamed "Virtue Signal" to "Holier Than Thou" (I have another idea for "Virtue Signal" that's not implemented yet). Reduced threshold for triggering destroy effect, and destroy target afterwards instead of replacing damage.
* Interview arguments now always applies with 3 stacks instead of scaling with boss difficulty, to address the difficulty curve.
* Adjusted faction/wealth supports and stances for oppositions.
* Replaced temp art for some modifiers.
* Added special dialog for when Plundak tries to sell mettle to Plundak (might need to wait for the Plundak mod to be updated first for this to be fully working).
* Fixed alliance convo not triggering on day 3.
* democratic_race tag for smalltalk quips now counts as one point during scoring, so you are more likely to see custom smalltalk when playing the campaign.
* Added story mode for Democratic Race.
* Fixed Oshnudrome not refreshing even after time passed.
* Added custom patron logic for Democratic Race.
* Reworked tutorial for support. Added tutorial for stances.
* Disable first mettle event in Democratic Race.
* Stances formed during interview are now "strict".
* Fixed bug on day 2 of spawning duplicate oppositions.
* Fixed bug of a side quest incorrectly spawning when accepting "Never Meet Your Heroes".
* Stances on support screen now shows "favored" stances as between two stances.
* Changed dialog.
* Fixed issues with Duckspeak.
* Cleaned up temp art for the fervor overlay.
* Adjusted Spark of Revolution.
* Added description for going to sleep.
* Fixed bug when convincing an ally to drop out.
* More people can make posters in Information Warfare.

### 0.7.0

* Added a new stance quip system: In certain scenarios, a person will try to argue for their position using actual arguments instead of a generic statement. Current affected events are: "Fanatic Supporter" and "Political Dilemma".
* (Technical) Convo dialog substitution now works on cxt.enc.scratch.
* Nerfed general support changes from relationship changes.
* Merged tax and welfare policies into one policy: fiscal policy.
* Reduced attack and killing penalties.
* Stance data are loaded from a csv file now.
* Separated the alliance with an opposition candidate with your relationship with them (UI, consequences needs to be fleshed out).
* Faction relationships are reverted to the base game's relationship. Added relationship between opposition candidates instead.
* Limited the number of request quest an agent can spawn to one across the entire game.
* Reduced the support requirements at the start of days because of general support nerf.
* Increased unconditional alliance requirement.
* Fix dialog issue with the lobbying event.
* Battle of wits now excludes the giver in a certain fight.
* Added a new game over for Benni's request.
* Fixed issue of mini-negotiator not working.
* Added option buttons for game overs, to not accidentally skip some dialogs.
* Added lots of fluff dialogs (that depends on player character and the person they are talking to).
* Changed some dialogs.
* Added two options for Change My Mind if you fail the debate, or if you have a target that you need to screw over.
* Added negotiation reasons for certain special negotiations.
* Reworked interview questions. Instead of dealing damage per turn, it now deals a larger damage after a few turns if it is not removed (via address question or normal argument destruction).
* Reduced the number of questions during the debate from 5 to 3 (as there are less political issues).
* Etiquette now works similarly to Suspicion (it destroys itself after a few turns if not dealt with).
* Cautious spender now only heals one of the bounties, and the amount healed scales based on difficulty.
* Added default negotiation behaviour for Vix and Hundruthor, which only shows up in a Democratic Race campaign.
* Added a source for contemporary question argument.
* Fixed UI issue for decrementing stacks of interview questions.
* Changed resolve scaling for interview questions.
* Fixed a potential issue that may occur when doing multiple interviews in the same sitting.
* Added new rally quest.
* Fixed business card not working properly.
* Fixed interviewer behaviour.
* Added fatigued to propaganda poster making negotiation.
* Changed some quip tags for quests.
* Separated support reason for quests into different categories.
* Added a marginal support bonus every time you pay someone to shill for you.
* Change the cost of bribes.
* Remove unnecessary tooltip for asking for new locations (after you failed to get a location).
* You can now always unlock new locations from your advisor or proprietors of locations.
* Separated once-per-day limit for socializing and unlocking locations.
* People working at a location will not give you an option to unlock another location of the same type.
* Different advisors now unlocks different bars.
* Day 2 opponent will always give you their location when asked, regardless whether you agree with them or not.
* Increased weightings of locations belonging to the same faction when deciding which location to unlock.
* You can now watch oshnu races at the Oshnudrome! You will restore some resolve, and you can bet money on the oshnus if you so choose.
* Park actions are now location hub options.
* Fixed potential issue for rally quest dialog when not having an advisor on day 2+.
* Changed various dialogs.
* Added questions for day 3 main quest.
* Added a few advisor specific dialogs.
* Added debug functions (wip).
* Added nil check for player room on day 2.
* At the start of day 2, if you ask a question about candidates and you exit the hub, you are allowed to re-enter the hub.
* Entering the Grand Theater from the front during the interview or debate now forces you to go to the back first.
* Pets no longer provide support during the interview or debate. It is sad, I know, but we have to make compromise, otherwise Oolo will just blast everyone in the theater with Bertha.
* You can now access the backroom of the party supply store and talk to Steven! Steven will sell you cards and grafts.
* Fixed the plax for the region. Now there is one less gigantic jellyfish and a lot more regular sized jellyfish.
* Removed duplicate party supply store proprietor.
* You can no longer provoke non-sentient characters.
* Added new arts.
* Changed Promote Product's flavor text.
* Democratic Race's custom provoke negotiation now correctly works with Everyone Dies (https://steamcommunity.com/sharedfiles/filedetails/?id=2596124635)
* Your max resolve is now limited by the proportion of health you have. A special dialog will show up the first time you lose health, teaching you about the mechanic.
* You can now ACTUALLY find Steven.
* Mandatory quests are added on post load if you don't have them already (for backwards compatibility).
* Added new quest icons for rally and request quests.
* Modified the quest icon for Debate Scrum to stay consistent with other main quests.
* Changed smalltalk dialog for laborers according to Flange Finnegan's suggestion on Discord.
* Added brand new negotiation music for the interview (first draft, subject to change).
* Removed extra mark during the interview quest.
* Added a new ending to the Ctenophorian Mystery quest.
* Ctenophorian Mystery now always gives a mystery card reward as a bonus. The card depends on the ending you get.
* Replaced placeholder dialog in Ctenophorian Mystery.
* Advisor's requests now no longer give cash reward, just like the only other request quest.
* Added another debug function that spawns a request for someone.
* Fixed issues of some quests unable to give awards when you complete them.
* Proprietors now only give new locations if they are at least neutral to you.
* Increased cards needed for Aellon to play an argument (4/3 to 5/4).
* Renamed "Relatable (Argument)" to "Fellow Grifter".
* Minor change to Aellon's and Benni's negotiation behaviour.
* Increased uses on certain negotiation items.
* Fixed quest description for "Dole Out".
* Day 1 end negotiation now uses Sal's night negotiation theme (subject to change).
* Added new dynamic music logic for the day 1 end negotiation.
* Connected line now returns call for help if it's removed, not just when it's destroyed.
* Added a lot more quips.
* Added temporary Hesh build.
* Changed Hesh's title.
* Fixed dialog in the Admiralty extortion event.
* Fixed extra Call For Help when help is underway.
* Fixed stacks on Talk Over keep increasing when you take damage.
* Intimidating Blaster counts as a Hostile card (to deal with intimidated decreasing immediately).
* Removed Rook finding extra coins (he has flourishes now, so he doesn't need this source of coins).
* Having an assassination at the end of day now affects sleep dialogs.
* Changed Debate Scrum dialog.
* You can now also feed working people in Dole Out.
* Console is given based on your deck size instead of a fixed amount.
* Hundruthor now counts as a bystander.
* Fixed agent scoring for Tea With Benefactor.
* Fixed Debate Scrum missing nil check.
* Fixed quip tags not working when no agent is present.
* Reduced skinned character spawns. The number of skinned character spawns is cut by half, but they are not culled.
* Changed the pessimist negotiation behaviour in minor ways.
* Console now also gives composure before transferring composure.
