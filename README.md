# HangMan in Assembly68K
Hangman game created in assembly.

The game goes as follows:

-	You have 6 wrong tries to guess all the letter of a phrase.
-	If you get a letter right it is displayed, and you get another try.
-	If you get a letter wrong a piece of the hangman image is displayed and you lose a try.
-	Phrases are chosen randomly from a list of ten.
-	The game is played by inputting letters on the keyboard.
-	Letters that the player has already tried are displayed to stop them from choosing the same letter again.
-	At the end of the game, you get the choice to play again or not.
-	The game stops the user from inputting capital letters and symbols. All phrases are lower case.
-	The game works my manipulating 2 strings. One being the correct phrase that is hidden at the start of the game one is the phrase that has been transformed into underscores.
-	When the player inputs a letter, it loops through the phrase to see if any letters match and if so, update the underscore string at the corresponding indexes that the letters are.
-	I have made all the phrases equal sizes in memory so that the distance between them is the same value (0x17). This is done so that I may take a random number between 0 and 9 and multiply it by this distance to pick a random phrase every game.

![Start Screen](/Images/startScreen.PNG)
![Gameplay](/Images/gameplay.PNG)
