*-----------------------------------------------------------
* Title      : Hang Man
* Written by : Jak Waterfall
* Date       : 03/04/2021
* Description: The old game of hangman.
*-----------------------------------------------------------
    ORG    $1000
START:
                move.b  #12,d0
                clr     d1                          ;turn off keyboard echo
                trap    #15
                
                move.b #33,D0
                move.l #1200*$10000+720,D1          ;Set screen to 1024 x 768
                trap   #15
                
                move.b  #14,d0
                lea     title,a1                    ;Display title text
                trap    #15
                
                move.b  #21,d0
                move.l  #$00FFFFFF,d1               ;Set Font style and size
                move.l  #$06140000,d2
                trap    #15
                
                move.b  #14,d0
                lea     welcomeMsg,a1               ;Display Welcome msg
                trap    #15
restart:        jsr     SETUP
                
gameLoop:                               
                jsr     TAKE_TURN                   ;Take turn   
                jsr     CLEAR_SCREEN                ;Clear screen     
                
                lea     GuessString,a1              ;Display guess string (underscore string)
                move.b  #13,d0  
                trap    #15     
             
                jsr     UPDATE_TRIES                ;Update tries left
                
                jsr     DISPLAY_HM 
                
                move.b  #14,d0
                lea     lettersFoundMsg,a1          ;Display letters Found Msg
                trap    #15
                lea     triedLetters,a1             ;Display letters player has tried
                trap    #15
                
                jsr     TEST_WIN                    ;Test if player won
                
                lea     underScrHits,a5             ;if no underscores are found in guess string the player has won
                tst.b   (a5)
                bne     noWinner
                
                move.b  #14,d0
                lea     winMsg,a1                   ;Display winner message!
                trap    #15
                
playAgain:      
                move.b  #14,d0
                lea     playAgainMsg,a1             ;Display play again message
                trap    #15
      
                move.b  #0,tries                    ;Reset tries
                move.b  #0,triedLetters             ;Reset tried letter array
                
                move.b  #5,d0                       ;Read char
                trap    #15
                
                exg     d1,d2
                jsr     CLEAR_SCREEN                ;Clear screen and swap registers to maintain inputed char
                exg     d2,d1
                cmp.b   #$79,d1                     ;If player inputs 'y' restart else exit game
                beq     restart
                bra     exit
                
noWinner:       
                move.b  #0,(a5)                     ;Reset underScrHits for next loop
                
                cmp.b   #maxTries,tries             ;If players is not out of tries contiue to next game loop
                bne     gameLoop
                
                move.b  #14,d0
                lea     triesOver,a1                ;Display out of tries game message
                trap    #15
                bra     playAgain
exit:
                move.b  #14,d0
                lea     GameOverMsg,a1              ;Display gameover message
                trap    #15
    SIMHALT                                         ; halt simulator

* subroutines
*---------------------------------------------------------------------------------------------------      
SETUP:          
                jsr     RAN_PHRASE
                move.l  a6,a0                       ;load phrase from a6 to a0
                lea     GuessString,a1  
            
  strcpy:       tst.b  (a0)
                beq     NULLstring
                move.b (a0)+,(a1)+                  ;copy phrase into guessString variable
                bra     strcpy
  NULLstring:   move.b  #0,(a1)   
     
  UdrScr:       lea     GuessString,a0
  nxtUdrScr:    
                tst.b   (a0)
                beq     doneSETUP
                cmp.b   #$20,(a0)                     ;change all letters of guessString into underscores 
                beq     updateUdrScr
                move.b  #$5F,(a0)
  updateUdrScr: addq.l  #1,a0
                bra     nxtUdrScr                              
  doneSETUP:    
                move.b  #14,d0
                lea     guessString,a1                   ;display guess string
                trap    #15
                rts

*---------------------------------------------------------------------------------------------------
RAN_PHRASE:
                move.b  #8,d0                   
                trap    #15
                and.l   #$7FFFF,d1              
                divu    #10,d1
                swap    d1                      ;create a random number from 0 to 9
                clr.l   d2
                move.w  d1,d2
                
                muls.w  #phraseIndexVar,d2      ;multiply the random number by the phrase index variable
                
                lea     phrase1,a6              ;load first phrase into a6
                add.l   d2,a6                   ;add new phrase index to a6 to make a6 point to a random phrase
                
                rts
*---------------------------------------------------------------------------------------------------
TAKE_TURN:      
                move.b  #14,d0
                lea     instr1,a1           ;display instruction msg
                trap    #15
                
                move.l  a6,a0               ;load phrase from a6
                lea     GuessString,a1
                
                jsr     GET_LETTER
                
  nxtPLAY:      
                tst.b   (a0)                ;test if end of string
                beq     donePLAY
                            
                cmp.b   (a0),d1             ;compare current char to input
                bne     updatePLAY          ;if guess correct update guess string and increment the strings
                move.b  d1,(a1)
                addq.b  #1,letterHit        ;letters hit++
                     
  updatePLAY:   addq.l  #1,a0
                addq.l  #1,a1
                bra     nxtPLAY

  donePLAY:     
                jsr     UPDATE_FOUND_LETTERS
                rts
*---------------------------------------------------------------------------------------------------  
GET_LETTER:    
                move.b  #5,d0               ;read char
                trap    #15             
                
                cmp.b   #$30,d1             ;if 0 goto exit
                beq     exit
                
                cmp.b   #$61,d1
                blt     incorrect           ;check letter is within bounds of a to z lowercase
                cmp.b   #$7A,d1
                bgt     incorrect
                rts     
  incorrect:    
                move.b  #14,d0
                lea     wrongLetter,a1         ;display incorrect letter msg
                trap    #15
                bra     GET_LETTER                

*---------------------------------------------------------------------------------------------------  
UPDATE_FOUND_LETTERS:
                lea     triedLetters,a3
  nextTest:     tst.b   (a3)
                ble     addLetter           ;branch if Z or NV are differnt so it will branch if 0 or -1 on tst
                cmp.b   (a3),d1             ;compare inputted letter with founbd letter array
                beq     foundLetterExit
                addq.l  #1,a3
                bra     nextTest
  addLetter:
                move.b  #$20,(a3)+          ;add spaces between letters
                move.b  d1,(a3)+
                move.b  #0,(a3)            ;always keep -1 at end of array so I can reset it my making the first element -1 on next game. this makes it so I dont have to NULL the whole space
  foundLetterExit:
                rts                
*---------------------------------------------------------------------------------------------------  
UPDATE_TRIES:   
                cmp.b   #0,letterHit        ;if letter found dont decrement tries
                bne     letterFound  
                                  
                addq.b  #1,tries            ;tries++
                
  letterFound: 
                lea     triesMsg,a1         ;display tries msg
                
                clr.l   d1                  ;display tries
                move.b  tries,d1            ;move number of tries into d1
                neg.b   d1                  ;negate the value
                add.b   #maxTries,d1        ;add the max tries(6) to d1
                
                move.b  #17,d0               ;display the number of tries the player had left
                trap    #15
                
                move.b  #0,letterHit        ;reset letterHit for next iteration
                rts
*---------------------------------------------------------------------------------------------------                
CLEAR_SCREEN:                
                move.w  #$FF00,d1       
                move.b  #11,d0              ;CLEAR SCREEN
                trap    #15
                rts
*---------------------------------------------------------------------------------------------------  
DISPLAY_HM:     
                move.b  tries,d4             ;tries times 4C to work out which hangman image is needed from memory (4C is the distance between image memory locations)
                move.l  #hangIndexVar,d3
                muls.w  d4,d3
                
                lea     hang1,a1             ;add the vatiable to the hangman memory location
                add.l   d3,a1
                
                move.b  #14,d0
                trap    #15                   ;display hangman image
                rts
*---------------------------------------------------------------------------------------------------
TEST_WIN:
                lea     GuessString,a1
                
  testStart:    
                tst.b   (a1)
                beq     testEnd
                
                cmp.b   #$5F,(a1)
                bne     testNext
                addq.b  #1,underScrHits
  testNext:     addq.l  #1,a1               ;a1+
                bra     testStart
  testEnd:
                rts             
*---------------------------------------------------------------------------------------------------
* Put variables and constants here
CR	            EQU	    $0D
LF              EQU	    $0A

tries           dc.b    0
maxTries        EQU     6

triedLetters    ds.b    40  ;40 letters worth of space

phraseIndexVar  EQU     $17
phrase1         dc.b    'batteries not included',0
phrase2         dc.b    'knowledge is power',0,0,0,0,0
phrase3         dc.b    'cradle of civilization',0
phrase4         dc.b    'change of heart',0,0,0,0,0,0,0,0
phrase5         dc.b    'forgive and forget',0,0,0,0,0      ;Zeros to make all the data equal size to index it easily and cut down on code for accessing it. I can access it like an array.
phrase6         dc.b    'in broad daylight',0,0,0,0,0,0
phrase7         dc.b    'fools paradise',0,0,0,0,0,0,0,0,0
phrase8         dc.b    'achilles heel',0,0,0,0,0,0,0,0,0,0
phrase9         dc.b    'like it or lump it',0,0,0,0,0
phrase10        dc.b    'pull out all the stops',0

GuessString     ds.b    24                           ;holds the guess strings
letterHit       dc.b    0                            ;holds whether a letter was found or not
underScrHits    dc.b    0                            ;holds whether a underscore was found or not

instr1          dc.b    CR,LF,CR,LF,'Guess a Letter a to z (Enter 0 to Quit):',CR,LF,CR,LF,0

lettersFoundMsg dc.b    CR,LF,'Tried Letters:',0

triesMsg        dc.b    CR,LF,'Number Of Tries Left: ',0
triesOver       dc.b    CR,LF,'Sorry you ran out of Tries!',0

wrongLetter     dc.b    CR,LF,'Incorrect Letter Chosen. Please choose a lower case letter from a to z:',CR,LF,0

winMsg          dc.b    CR,LF,'Congratulations! You Win!',CR,LF,0
playAgainMsg    dc.b    CR,LF,'Would you like to play again? y or n ?',CR,LF,CR,LF,0


welcomeMsg	    dc.b	    CR,LF
	            dc.b    'Guess a letter until you solve the message',CR,LF
	            dc.b    '       You have 6 tries, GoodLuck!',CR,LF
	            dc.b    '            Enter a 0 to Quit',CR,LF,CR,LF,0
	        
GameOverMsg     dc.b    CR,LF,'Game Over!',0

                                            
title   dc.b                '              _    _                     __  __             ',CR,LF
        dc.b                '             | |  | |                   |  \/  |            ',CR,LF
        dc.b                '             | |__| | __ _ _ __   __ _  | \  / | __ _ _ __  ',CR,LF
        dc.b                '             |  __  |/ _` |  _ \ / _` | | |\/| |/ _` |  _ \ ',CR,LF
        dc.b                '             | |  | | (_| | | | | (_| | | |  | | (_| | | | |',CR,LF
        dc.b                '             |_|  |_|\__,_|_| |_|\__, | |_|  |_|\__,_|_| |_|',CR,LF
        dc.b                '                                  __/ |                     ',CR,LF
        dc.b                '                                 |___/ ',CR,LF,CR,LF
        dc.b                '                              By Jak Waterfall',0
        
hangIndexVar    EQU $78
   
hang1   dc.b    CR,LF,'        +---+  ',CR,LF
        dc.b          '        |   |  ',CR,LF
        dc.b          '            |  ',CR,LF
        dc.b          '            |  ',CR,LF
        dc.b          '            |  ',CR,LF
        dc.b          '            |  ',CR,LF
        dc.b          '      =========',0
        
hang2   dc.b    CR,LF,'        +---+  ',CR,LF
        dc.b          '        |   |  ',CR,LF
        dc.b          '        O   |  ',CR,LF
        dc.b          '            |  ',CR,LF
        dc.b          '            |  ',CR,LF
        dc.b          '            |  ',CR,LF
        dc.b          '      =========',0

hang3   dc.b    CR,LF,'        +---+  ',CR,LF
        dc.b          '        |   |  ',CR,LF
        dc.b          '        O   |  ',CR,LF
        dc.b          '        |   |  ',CR,LF
        dc.b          '            |  ',CR,LF
        dc.b          '            |  ',CR,LF
        dc.b          '      =========',0
     
hang4   dc.b    CR,LF,'        +---+  ',CR,LF
        dc.b          '        |   |  ',CR,LF
        dc.b          '        O   |  ',CR,LF
        dc.b          '       /|   |  ',CR,LF
        dc.b          '            |  ',CR,LF
        dc.b          '            |  ',CR,LF
        dc.b          '      =========',0     
        
hang5   dc.b    CR,LF,'        +---+  ',CR,LF
        dc.b          '        |   |  ',CR,LF
        dc.b          '        O   |  ',CR,LF
        dc.b          '       /|\  |  ',CR,LF
        dc.b          '            |  ',CR,LF
        dc.b          '            |  ',CR,LF
        dc.b          '      =========',0    

hang6   dc.b    CR,LF,'        +---+  ',CR,LF
        dc.b          '        |   |  ',CR,LF
        dc.b          '        O   |  ',CR,LF
        dc.b          '       /|\  |  ',CR,LF
        dc.b          '       /    |  ',CR,LF
        dc.b          '            |  ',CR,LF
        dc.b          '      =========',0        
        
hang7   dc.b    CR,LF,'        +---+  ',CR,LF
        dc.b          '        |   |  ',CR,LF
        dc.b          '        O   |  ',CR,LF
        dc.b          '       /|\  |  ',CR,LF
        dc.b          '       / \  |  ',CR,LF
        dc.b          '            |  ',CR,LF
        dc.b          '      =========',0         
 
    END    START        ; last line of source




    



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
