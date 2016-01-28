 TITLE "TITLE"
***********************************************
* TITLE/TXT: INCLUDE FILE FOR LYRA
* Last update: 7:27:30 PM  Apr 10, 1990
* Last update: 3-jun-90 midifications (c) R.Gault
***********************************************

*MSG "TITLE=",*

*COPYR - display copyright message
*
COPYR LDD #13
 ADDD SCREEN
 TFR D,Y Y points to screen
 LDX #TITLE X points to data
 LDA #15 number of lines counter
 PSHS A
A@ PSHS Y
 LDB #5 width counter
B@ LDA ,X+ get data
 STA ,Y+ put it on screen
 DECB  update width counter
 BNE B@
 PULS Y
 LEAY 32,Y move down to next line
 DEC ,S
 BNE A@
 PULS A
 LDD #5*32
 STD TEXTADJ
 LDU #42
 LDX #TITLMSG display text
C@ LDA ,X+
 BEQ D@
 CMPA #13
 BNE E@
 TFR U,D
 ADDD #32
 ANDB #$E0
 TFR D,U
 BRA C@
E@ LBSR TEXT
 BRA C@
D@ LBSR WAITKEY
 CLRA
 CLRB
 STD TEXTADJ
 RTS

*TITLE - display data that is discarded after initial display
*
TITLE FCB $FF,$DF,$FF,$FF,$FF
 FCB $F8,$3F,$FF,$FF,$FF
 FCB $F4,$FF,$FF,$FF,$FF
 FCB $FC,$FF,$FF,$FF,$FF
 FCB $FC,$FE,$73,$26,$0F
 FCB $FC,$FC,$72,$1C,$E7
 FCB $FC,$FE,$73,$3C,$E7
 FCB $FC,$FE,$73,$3C,$E7
 FCB $FC,$FA,$63,$3C,$C5
 FCB $FC,$F6,$53,$1C,$A3
 FCB $F8,$0F,$33,$3E,$67
 FCB $FF,$FF,$F3,$FF,$FF
 FCB $FF,$FF,$F7,$FF,$FF
 FCB $FF,$FE,$E7,$FF,$FF
 FCB $FF,$FF,$1F,$FF,$FF

TITLMSG FCC "Version "
 FCB VERSION,46,REVISION,REVISN2
 FCB 13,13
 FCC "A MIDI Music Composition Program"
 FCC "  for the Tandy Color Computer"
 IFNE DEMO
 FCB 13,13
 ENDC
 IFEQ DEMO
 FCB 13
 ENDC
 FCC " Copyright 1988 by Lester Hands"
 FCB 13
 FCC "Updates (c) 1991 by Robert Gault"
 IFNE DEMO
* ---CONDITIONAL START
 FCC " With special thanks to C. Houk"
 FCB 13,13
 FCC "      ALL RIGHTS RESERVED"
 FCB 13
 FCC " This program may not be copied"
 FCB 13
 FCC " for any purpose other than for"
 FCB 13
 FCC "    the personal use of the"
 FCB 13
 FCC "        registered user."
 ENDC
 IFEQ DEMO
 FCC "         DEMO VERSION"
 FCB 13
 FCC "   Please give copies of this"
 FCB 13
 FCC "    program to your friends."
 FCB 13,13
 FCC "   Write for information from:"
 FCB 13
 FCC "   Rulaford Research"
 FCB 13
 FCC "   P.O. BOX 143"
 FCB 13
 FCC "   Imperial Beach, CA 92032"
 ENDC
*  ---CONDITIONAL END
 FCB 0
