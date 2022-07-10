# Full Changelog

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
