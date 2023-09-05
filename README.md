# Scrabble Variant
Everyone likes camels and scrabble. A terminal based scrabble like game with some customization such as board sizing, number of players, bonus rules, and bonus points for camel based words!

This project was written for for a CS 3110 and submitted for a Final Project. Project was completed by:

Sophia Chen (MSE 23')

Sunwook Kim (CS 22')

Tia Vu (CS 22')

Sprint Goals are outlined below.

# Rough object sketch
Game object
* Objects  
** Board  
** Player  
*** Hand (Owned word Tiles)
** Word tile pool
** Dictionary
** Points (player)
** Display
** Turn
* Methods
** Run
** Play a Turn
** Check move validity
** End
Virtual board
* N x N board (N=15)
* Board Tile information (points)
* Word Tile status (which tiles are placed where)
Displayer (inputs boards, outputs display)


## MS2 Goals
User input interaction (change board by input)

Implement Turn mechanism
Draw from limited word pool
Point tracking 
Ending game when no more moves can be made

## MS3 Goals

Multiplayer
Change display for each player’s hand
Bonus Rules (?)
Add bonus point for words (camels, lambda, etc…)
Game customization


# Reference
dictionary.json and dictionary_compact.json are brought from the [WebstersEnglishDictionary](https://github.com/matthewreagan/WebstersEnglishDictionary) github project
