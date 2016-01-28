 TITLE "REQUEST/TXT"
************************************************
* REQUEST/TXT: INCLUDE FILE FOR LYRA
* CONTAINS MOST OF THE REQUESTER ROUTINES
* (C) 1988 by Lester Hands
* Last update: 12-aug-88
* Last update: 29-jun-90 modifications (c) R.Gault
*************************************************

*MSG "REQUEST=",*

*SETREQ - set up requester box
*ENTRY: X points to string for requester
*
SETREQ PSHS D,X,Y,U
 LDU BUFFER point to refresh memory
 LDA ,X+ get VPOS for menu
 LDB LINEWIDE convert to address
 MUL
 ADDB ,X+ add HPOS
 ADDD SCREEN
 STD ,U++ save starting address of BUFFER
 LDD ,X get width & length of menu
 STA WIDTH
 STB LENGTH
 ADDA #2 adjust for sides of menu
 STA ,U+ save width of BUFFER
 LDD #0
 STD ,U++ reset length of BUFFER
 TFR D,Y length counter=Y
 LDX [BUFFER] point to starting address
 LDB WIDTH do a line at top of box
 ADDB #2
 CLRA
D@ JSR STORE
 DECB
 BNE D@
 LDA #1 allow for shading on top line
 STA -1,X
 LDX [BUFFER] move down 1 line
 LDA LINEWIDE
 LEAX A,X
A@ JSR LINE2
 DEC LENGTH
 BNE A@
 LDA WIDTH do 2 bottom border lines
 ADDA #2
 STA WIDTH+1
 PSHS X
B@ CLRA
 JSR STORE
 DEC WIDTH+1
 BNE B@
 PULS X
 LDA LINEWIDE
 LEAX A,X
 LDA #$80
 JSR STORE
 INC WIDTH
C@ CLRA
 JSR STORE
 DEC WIDTH
 BNE C@
 LDX BUFFER
 LEAX 3,X
 STY ,X update length counter
 PULS D,X,Y,U,PC return

*DSPREQ - display text on requester
*ENTRY: X points to requester string
* if REQCURSF>0 then cursor displayed in input string
* and B holds current cursor offset position
*
REQCURSF FCB 0 		>1 if cursor to be displayed
*
DSPREQ PSHS D,X,Y,U
 PSHS B
 TFR X,D get address of start of
 ADDD #7 requester text
 PSHS D and put it on stack
 LDD 5,X get address of input string
 SUBD ,S++ find difference
 ADDB ,S+ add to cursor offset
 PSHS B put offset on stack
 LDB ,X+ get VPOS
 CLRA  convert to screen position
 PSHS X
 LDX #12 divide by 12
 JSR DIVIDE (12 video lines/line of text)
 TFR X,D
 PULS X restore requester string pointer
 LDA LINEWIDE
 MUL
 ADDB ,X+ add HPOS
 ADCA #0
 ADDD #33 move down 1 line+1 letter
 TFR D,U screen position set up
 CLRA  save HPOS number
 ANDB #$1F (lowest 5 bits)
 PSHS D
 LEAX 5,X skip input area parameters
 LDA #FAT+JAM set FAT/JAM mode
 STA TMODE
 CLRB  position offset
A@ TST REQCURSF
 BEQ D@
 CMPB 2,S are we at cursor?
 BNE D@
 LDA TMODE
 ORA #INVERSE set inverse mode
 STA TMODE
D@ LDA ,X+ get letter
 BEQ C@ end if =0
 CMPA #13 check for CR
 BEQ B@
 JSR TEXT
 INCB
 TST REQCURSF
 BEQ A@
 LDA TMODE cancel inverse mode
 ANDA #$EF
 STA TMODE
 BRA A@
B@ PSHS B
 TFR U,D move to next line down
 ANDB #$E0 save top 3 bits (line #)
 ADDD 1,S
 ADDB LINEWIDE move to next line
 ADCA #0
 TFR D,U
 PULS B
 INCB
 BRA A@
C@ LEAS 3,S clean up stack
 PULS D,X,Y,U,PC

*REQINPUT - get input for a requester
*ENTRY: X points to requester string
* Y points to edit string
*EXIT: Y points to input string
* A contains last keypress (useful for checking for BREAK)
* B contains length of string (maximum as in requester string)
*
REQINPUT PSHS X,U
 LDB 4,X get length of input string
 PSHS B save on stack
 CLRB  string offset counter
 LDU 5,X point to input string area
A@ TST REQEDOK
 BEQ E@
H@ CLRA
 LDA D,Y if editing enabled, then
 CMPA #32 check edit string for
 BNE E@ spaces (no entry allowed);
 INCB  advance cursor if present.
 CLRA
 TST D,U
 BNE H@
E@ JSR DSPREQ redisplay requester
*MOD Dec 09,1992 R.Gault test for button; relocate
K@ JSR READBUT2 do first to prevent
 BNE S@
 JSR KEYIN wait for keypress
 TSTA
 BEQ K@
S@ CMPA #UPARROW
 BEQ M@ MOD was K@(no action)
 CMPA #10 check for down arrow
 BNE I@
 TST REQEDOK
 BEQ K@
* MOD May 24,1990 R.Gault routine moved into subroutine
* to enable backup with least amount of code
J@ BSR R@
 BEQ H@
 INCB
 CLRA
 TST D,U
 BNE J@
* MOD May 24,1990 R.Gault enable propper restart
 CLRB
 BRA H@
*MOD May 24,1990 R.Gault enable backup
M@ BSR P@ backup until spaces
 BNE M@
O@ BSR P@ then skip over spaces
 BEQ O@
N@ BSR P@ then move
 BNE N@
 INCB
 BRA E@ to start of entry
*
P@ DECB  backup subroutine
 BEQ Q@
R@ CLRA  skip forward
 LDA D,Y
 CMPA #32
 RTS
Q@ LEAS 2,S yank return
 BRA H@
* EMOD
I@ CMPA #3 check for BREAK
 BEQ B@
 CMPA #13 check for ENTER
 BEQ B@
 CMPA #8 check for backspace
 BNE C@
 DECB  move back 1 space
 BPL D@
 CLRB  check for "roll over"
D@ BRA A@
C@ CMPA #9 check for forward arrow
 BNE F@
 BRA G@
F@ TSTA  wait for keypress
 BEQ A@
 JSR REQEDIT
 TSTA
 BEQ G@
 PSHS A,U
 CLRA
 LEAU D,U
 PULS A
 STA ,U save in string if OK
 PULS U
G@ INCB
 CMPB ,S check current offset
 BNE L@ against string length
 DECB  don't allow offset to
L@ LBRA A@ go beyond end of string
B@ PULS B
 TFR U,Y
 PULS X,U,PC

*REQEDIT - edits requester input
*ENTRY: Y points to edit string
* A contains input
* B contains input string offset
* REQEDOK set to >0
*EXIT: A=0 if invalid input else input value
*EDIT STRING: 9 = 0 through 9 ok
* Z = A through Z ok
* " " = no input
* + = + or - ok
* @ = any input ok
* $ = hex number (0-9, A-F)
*
REQEDOK FCB 0 	*if >0 then editing enabled
*
REQEDIT PSHS A
 TST REQEDOK see if edit is enabled
 BEQ D@
 CMPA #32 check for control character
 BLO E@
F@ CLRA
 LDA D,Y get edit character
 CMPA #32 check for space (no input)
 BEQ E@
C@ CMPA #'@ check for no edit
 BEQ D@
 CMPA #'+ check for sign
 BNE A@
 LDA ,S
 CMPA #'+
 BEQ D@
 CMPA #'-
 BEQ D@
 BRA E@
A@ CMPA #'$ check for hex
 BNE G@
 LDA ,S restore input
 CMPA #'0 check lower limit
 BLO E@
 CMPA #'9+1
 BLO D@
 CMPA #'A
 BLO E@
 CMPA #'F check upper limit
 BHI E@
 BRA D@
G@ CMPA #'9 check for numeric
 BHI B@
 CMPA ,S
 BLO E@
 LDA ,S
 CMPA #'0
 BLO E@
 BRA D@
B@ CMPA #'Z check for alpha
 BHI D@
 CMPA ,S restore input
 BLO E@
 LDA ,S
 CMPA #'A
 BHS D@
E@ CLR ,S clear input (invalid)
D@ PULS A,PC

*HELP - brief list of key commands via a requester
*
HELP LDX #a@
 JSR SETREQ
 JSR DSPREQ
 JSR WAITKEY
 JMP REFMEN
a@ FCB 6 	VPOS
 FCB 3 		HPOS
 FCB 24 	width of requester
 FCB 15 	height of requester
 FCB 0 		length of input
 FDB 0 		address of input area
 FCB THIN+128
 FCC " B-Block mark set"
 FCB 13
 FCC " D-Delete note"
 FCB 13
 FCC " F-Flat note enter"
 FCB 13
 FCC " I-Instrument set"
 FCB 13
 FCC " L-End octave transpose"
 FCB 13
 FCC " N-Natural note enter"
 FCB 13
 FCC " O-Octave transpose"
 FCB 13
 FCC " R-Tempo change"
 FCB 13
 FCC " S-Sharp note enter"
 FCB 13
 FCC " T-Tie note"
 FCB 13
 FCC " U-Play update"
 FCB 13
 FCC " V-Volume set"
 FCB 13
 FCC " .-Dotted note value"
 FCB 13
 FCC " #-Triplet note value"
 FCB 0 end of requester

*MIDITEMP - set MIDI tempo via a requester
*
MIDITEMP LDD TEMPO transfer from music code
 LEAS -5,S put string on stack
 TFR S,X
 JSR BINASC
 LDD 3,S
 LEAS 5,S
 STD B@
 LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LDY #d@
 JSR REQINPTE
 LDX #B@ point to tempo string
 LDB #C@-B@ length of string
 JSR ASCBIN convert to binary
 STB TEMPO+1 set MIDI tempo
A@ JMP REFMEN
a@ FCB 48 		VPOS
 FCB 3 			HPOS
 FCB 24 		width of requester
 FCB 3 			height of requester
 FCB C@-B@ 		length of input
 FDB B@ 		address of input area
 FCC "Master tempo (1-99): "
B@ FCC "32"
C@ FCB 0 		*end of requester
d@ FCC "99" 		edit string

* MOD May 14,1990 R.Gault Dec1992 add delay
* READBUT2 Permit exit from pulldown with button
* ENTRY: none
* EXIT A=0 no button; A=3 button
READBUT2 LDA #$FF no keys
 STA $FF02
 LDA $FF00
 BITA #1 right port button
 BNE A@
B@ LDA $FF00 wait for release
 BITA #1
 BEQ B@
 LDA #$F8
 JSR SENDMIDI
 LDA #3 		simulate a BREAK
 RTS
A@ CLRA
 RTS
* EMOD

*SETDRIVE - set disk drive via a requester
*
*MOD May 1990 R.Gault for hard drive and floppies
*    June 29,1990
SETDRIVE LDA DEFDRIV
 PSHS B
 PSHS A,Y
 CMPA #3
 BHI F@
 ADDA #'0
 STA B@+2
 BRA G@
F@ LDY #B@ set current drive
 JSR HDDRIVE
G@ LDA RGBDRMAX
 LDY #E@ show maximum drive #
 JSR HDDRIVE available
 PULS A,Y
 LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LDY #d@
 JSR REQINPTE
 CMPA #3 BREAK or button
 BEQ A@
 LDX #B@
 LDB #3
 JSR ASCBIN
 CMPB RGBDRMAX
 BHI A@
 STB DEFDRIV
 STB $EB
A@ JSR REFMEN
 PSHS D,X,Y
 JSR DSPFNAME MOD R.Gault update dir
 PULS D,X,Y
D@ PULS B,PC
a@ FCB 48 		VPOS
 FCB 5 			HPOS
 FCB 19 		WIDTH
 FCB 3 			HEIGHT
 FCB C@-B@ 		LENGTH
 FDB B@ 		ADDRESS OF INPUT
 FCC "Max Drive #"
E@ FCC "nnn: "
B@ FCC "000"
C@ FCB 0
d@ FCC "299"

*MIDITRAN - set MIDI transposition offset via requester
*
TRNSPOSE FCB 0 		master transpose flag
*
MIDITRAN LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LDY #d@
 JSR REQINPTE
 CLR TRNSPOSE
 LDX #B@
 LDB 1,X
 LDA #'0
 LBSR HEXBIN
 LDB ,X
 CMPB #'-
 BNE D@
 NEGA
D@ STA TRANOFFS
 ORA TRNSPOSE
 STA TRNSPOSE
 LDX #MENTRANS
 LBSR CHGMENU
 JMP REFMEN
a@ FCB 48 	*VPOS
 FCB 3 		*HPOS
 FCB 24 	*width of requester
 FCB 3 		*height of requester
 FCB C@-B@ 	*length of input
 FDB B@ 	*address of input area
 FCC "Transpose (-F TO +F): "
B@ FCC "+0"
C@ FCB 0 	*end of requester
d@ FCC "+$" 	*edit string

*REQTSIG - set time signature
*
REQTSIG LDA CHNGTSIG
 CMPA #SEL_OK
 BEQ B@
 RTS
B@ LDD TIMESIG transfer from music code
 STA TSIGDAT
 STB TSIGDAT+2
 LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LDY #d@
 JSR REQINPTE
 CMPA #3
 BEQ E@
 BSR SETTSIG
 TST MEASURE check for overflow
 BEQ D@
 JSR REFMEN
 LDB #$80
 JMP DOSERR
D@ LDA TSIGDAT
 LDB TSIGDAT+2
 STD TIMESIG
E@ JSR REFMEN
 JMP DSPMUS
SETTSIG PSHS D,X
 LDA TSIGDAT+2 convert to MEA_CNT
 SUBA #'0
 LDB #$FF
A@ INCB  count powers of 2
 LSRA
 BCC A@
 DECB
 LDX #F@
 LDA B,X
 LDB TSIGDAT
 SUBB #'0
 MUL
 STD MEASURE
 CLRA
 CLRB
 STD MEA_STRT
 PULS D,X,PC
*
F@ FCB 96 	*NOTE TABLE:half
 FCB 48 	*quarter
 FCB 24 	*8th
*
a@ FCB 48 	*REQUESTER:VPOS
 FCB 4 		*HPOS
 FCB 22 	*width
 FCB 3 		*height
 FCB C@-TSIGDAT *length of input
 FDB TSIGDAT 	*address of input area
 FCC " Time signature:  "
TSIGDAT FCC "4/4"
C@ FCB 0 	*end of requester
d@ FCC "9 8" 	*edit string

*REQKSIG - set key signature via requester
*
REQKSIG LDD KEYSIG transfer from music code
 STD KSIGDAT
 LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LDY #d@
 JSR REQINPTE
 CMPA #3
 BEQ E@
 LDD KSIGDAT
 STD KEYSIG
E@ JSR REFMEN
 JMP DSPMUS
a@ FCB 48 	*REQUESTER:VPOS
 FCB 5 		*HPOS
 FCB 20 	*width
 FCB 3 		*height
 FCB C@-KSIGDAT *length of input
 FDB KSIGDAT 	*address of input area
 FCC " Key signature:  "
KSIGDAT FCC "0S"
C@ FCB 0 	*end of requester
d@ FCC "7S     " *edit string

*REQMCHAN - set MIDI channels via a requester
*
REQMCHAN LDX #MIDICHAN transfer from music code
 LDY #B@
 LDB #8
 PSHS B
F@ LDA ,X+
 LBSR HEXOUT convert to ASCII
 STB ,Y+
 DEC ,S
 BNE F@
 LEAS 1,S
 LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LDY #d@
 JSR REQINPTE
 LDX #B@ point to channel string
 LDY #MIDICHAN
D@ LDB ,X+ get number
 LDA #'0
 LBSR HEXBIN
 STA ,Y+
E@ TST ,X
 BNE D@
A@ JMP REFMEN
a@ FCB 48 	*VPOS
 FCB 1 		*HPOS
 FCB 28 	*width of requester
 FCB 3 		*height of requester
 FCB C@-B@ 	*length of input
 FDB B@ 	*address of input area
 FCC "MIDI Channels (0-F):"
B@ FCC "00000000"
C@ FCB 0 	*end of requester
d@ FCC "$$$$$$$$" *edit string

*REQMINST - set MIDI instruments via a requester
*
REQMINST LDX #MIDINSTM
 LDY #MIDINST
 JSR COPYSTR
 LDX #MIDINSTR
 JSR SETREQ
 JSR DSPREQ
 LDY #d@
 JSR REQINPTE
 CMPA #3
 BEQ Z@
 LDX #MIDINST
 LDY #MIDINSTM
 JSR COPYSTR
 JSR CNVMINST
Z@ JMP REFMEN
MIDINSTR FCB 30 	*VPOS
 FCB 1 			*HPOS
 FCB 28 		*width of requester
 FCB 11 		*height of requester
 FCB c@-MIDINST 	*length of input
 FDB MIDINST 		*address of input area
 FCC "MIDI Instruments:"
 FCB 13,13
MIDINST FCC "0:000         "
 FCC "1:000        "
 FCB 13
 FCC "2:000         "
 FCC "3:000        "
 FCB 13
 FCC "4:000         "
 FCC "5:000        "
 FCB 13
 FCC "6:000         "
 FCC "7:000        "
 FCB 13
 FCC "8:000         "
 FCC "9:000        "
 FCB 13
 FCC "A:000         "
 FCC "B:000        "
 FCB 13
 FCC "C:000         "
 FCC "D:000        "
 FCB 13
 FCC "E:000         "
 FCC "F:000        "
c@ FCB 0 		*end of requester
d@ FCC "  299 @@@@@@@ "
 FCC "  299 @@@@@@@ "
 FCC "  299 @@@@@@@ "
 FCC "  299 @@@@@@@ "
 FCC "  299 @@@@@@@ "
 FCC "  299 @@@@@@@ "
 FCC "  299 @@@@@@@ "
 FCC "  299 @@@@@@@ "
 FCC "  299 @@@@@@@ "
 FCC "  299 @@@@@@@ "
 FCC "  299 @@@@@@@ "
 FCC "  299 @@@@@@@ "
 FCC "  299 @@@@@@@ "
 FCC "  299 @@@@@@@ "
 FCC "  299 @@@@@@@ "
 FCC "  299 @@@@@@@"

CNVMINST PSHS D,X,Y
 LDX #MIDINSTM+2 convert instrument
 LDB #16 numbers to binary
 PSHS B
 LDY #MIDINSTB
A@ LDB #3
 PSHS X
 JSR ASCBIN
 PULS X
 DECB
 STB ,Y+ save binary number
 LEAX 14,X point to next ASCII number
 DEC ,S done yet?
 BNE A@
 LEAS 1,S throw away counter
 PULS D,X,Y,PC

MIDINSTB FCB 0,0,0,0,0,0,0,0 binary equivalents
 FCB 0,0,0,0,0,0,0,0 of MIDINST

*TFRMURE - transfer binary data to ASCII requester
*ENTRY: Y points to music code binary data
* U points to requester string
* requester string must be in the format of 8 groups
* of 4 bytes as in REQMVELO and REQMINST
*
TFRMURE PSHS D,X,Y,U
 LEAS -5,S put converted string on stack
 TFR S,X
 LDB #8 voice counter
 STB B@
A@ LDB ,Y+
 CLRA
 JSR BINASC
 LDA 2,X
 STA ,U+
 LDD 3,X
 STD ,U++
 LEAU 1,U
 DEC B@
 BNE A@
 LEAS 5,S
 PULS D,X,Y,U,PC
B@ FCB 0

*TFRREMU - perform reverse of TFRMURE
*ENTRY: X points to ASCII string
* Y points to binary data area
*
TFRREMU PSHS B,X,Y
 LDB #8
 PSHS B
A@ LDB #3
 JSR ASCBIN
 STB ,Y+
 LEAX 4,X
 DEC ,S
 BNE A@
 LEAS 1,S
 PULS B,X,Y,PC

*REQINPTE - same as REQINPUT except editing included
*ENTRY: X points to requester string
* Y points to edit string
*
REQINPTE INC REQEDOK
 INC REQCURSF
 JSR REQINPUT
 CLR REQEDOK
 CLR REQCURSF
 RTS

* MOD May 16,1990 R.Gault adjusted for hard drive #s
*GETNAME - get filename using requester string
*NOTE: requester box must already be set up and
* REFMEN is not called here!
* U points to filename string
*EXIT: A=3 if BREAK pressed
* otherwise filename transferred to FILENAME
*
GETNAME PSHS X,Y,U
 LDX #a@ clear out filename
 LDA #32
 LDB #8
C@ STA ,X+
 DECB
 BNE C@
 LDA $95A set default drive
* MOD
 LDY #DRIVE
 JSR HDDRIVE
* EMOD
 LDX #REQFILE
 INC REQCURSF
 LDY #c@
 JSR REQINPTE
 CLR REQCURSF
 CMPA #3 check for BREAK
 BEQ B@
 LDX #a@ transfer input to filename
 LDB #8
A@ LDA ,X+
 STA ,U+
 DECB
 BNE A@
* MOD
 LDX #DRIVE set drive #
 LDB #3
 JSR ASCBIN
 STB $95A
 STB $EB
* EMOD
 CLRA
B@ PULS X,Y,U,PC
REQFILE FCB 48 		*VPOS
 FCB 2 			*HPOS
 FCB 28 		*width of requester
 FCB 3 			*height of requester
 FCB b@-a@ 		*length of input
 FDB a@ 		*address of input area
 FCC "Enter Filename: "
a@ FCC "        :" 	*string input area
DRIVE FCC "000"
b@ FCB 0 		*end of requester
c@ FCC "@@@@@@@@ 299"

*MEMORY - display memory available through a requester
*
MEMORY LDX #b@
 LDD SCREEN calculate amount of free memory
 SUBD ENDPTR
 LSRA  divide by 2
 RORB
 JSR BINASC
 LDX #a@ now display requester
 JSR SETREQ
 JSR DSPREQ
 JSR WAITKEY
 JMP REFMEN
a@ FCB 48 		*VPOS
 FCB 4 			*HPOS
 FCB 23 		*width of requester
 FCB 3 			*height of requester
 FCB 0 			*length of input
 FDB 0 			*address of input area
 FCC "Available Memory: "
b@ FCC "00000" 		*string input area
 FCB 0 			*end of requester

*REQMDESC - set instrument descriptor
*
REQMDESC LDX #MIDIDESM
 LDY #MIDIDESC
 JSR COPYSTR
 LDX #a@
 JSR SETREQ
 JSR DSPREQ
 INC REQCURSF
 JSR REQINPUT
 CMPA #3
 BEQ Z@
 LDX #MIDIDESC
 LDY #MIDIDESM
 JSR COPYSTR
Z@ CLR REQCURSF
 JMP REFMEN
a@ FCB 48 		*VPOS
 FCB 1 			*HPOS
 FCB 28 		*width of requester
 FCB 3 			*height of requester
 FCB C@-MIDIDESC 	*length of input
 FDB MIDIDESC address of input area
MIDIDESC FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32	*32 space for synthesizer description
C@ FCB 0 		*end of requester

ANNOLEN EQU 116

*REQANNOT - get annotation information
*
REQANNOT LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LDY #b@
 JSR REQINPTE
 CMPA #3
 BEQ Z@
Z@ JMP REFMEN
ANOTPALL EQU * 		*MOD R.Gault
a@ FCB 48 		*VPOS
 FCB 1 			*HPOS
 FCB 28 		*width of requester
 FCB 6 			*height of requester
 FCB C@-ANNOT 		*length of input
 FDB ANNOT 		*address of input area
ANNOT FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32
 FCB 13
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32
 FCB 13
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32
 FCB 13
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32
C@ FCB 0 		*end of requester
b@  FCB '@,'@,'@,'@,'@,'@,'@,'@,'@,'@
 FCB '@,'@,'@,'@,'@,'@,'@,'@,'@,'@
 FCB '@,'@,'@,'@,'@,'@,'@,'@
 FCB 32
 FCB '@,'@,'@,'@,'@,'@,'@,'@,'@,'@
 FCB '@,'@,'@,'@,'@,'@,'@,'@,'@,'@
 FCB '@,'@,'@,'@,'@,'@,'@,'@
 FCB 32
 FCB '@,'@,'@,'@,'@,'@,'@,'@,'@,'@
 FCB '@,'@,'@,'@,'@,'@,'@,'@,'@,'@
 FCB '@,'@,'@,'@,'@,'@,'@,'@
 FCB 32
 FCB '@,'@,'@,'@,'@,'@,'@,'@,'@,'@
 FCB '@,'@,'@,'@,'@,'@,'@,'@,'@,'@
 FCB '@,'@,'@,'@,'@,'@,'@,'@
CLRANNOT PSHS D,X,Y
 LDX #ANNOT 		*clear the annotation
 LDY #b@
 LDA #32
A@ TST ,X+ 		*check for end of ann.
 BEQ B@
 LDB ,Y+ 		*check edit for '@'
 CMPB #'@
 BNE A@
 STA -1,X
 BRA A@
B@ PULS D,X,Y,PC

*REQNFRAC - set MIDI note fractions
*
REQNFRAC LDX #NOTFRACM
 LDY #NOTFRACA
 JSR COPYSTR
 LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LDY #d@
 JSR REQINPTE
 CMPA #3
 BEQ Z@
 LDX #NOTFRACA
 LDY #NOTFRACM
 JSR COPYSTR
 BSR CNVNFRA
Z@ JMP REFMEN
a@ FCB 48 		*VPOS
 FCB 7 			*HPOS
 FCB 15 		*width of requester
 FCB 6 			*height of requester
 FCB c@-NOTFRACA 	*length of input
 FDB NOTFRACA 		*address of input area
 FCC "Note lengths:"
 FCB 13,13
NOTFRACA FCC "8/8 8/8 8/8 8/8"
 FCB 13
 FCC "8/8 8/8 8/8 8/8"
c@ FCB 0 		*end of requester
d@ FCC "8   8   8   8   "
 FCC "8   8   8   8   "
*
CNVNFRA PSHS D,X
 LDX #NOTFRACM now convert ASCII numbers
 LDY #NOTEFRAC to binary
 LDB #8 voice counter
A@ LDA #56
 SUBA ,X
 STA ,Y+
 LEAX 4,X
 DECB
 BNE A@
 PULS D,X,PC

NOTEFRAC FCB 0,0,0,0 	*note fractions to be
 FCB 0,0,0,0 		*subtracted from whole

*REQMDELA - set MIDI delay between bytes
*
REQMDELA PSHS D,X,Y
 LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LDY #d@
 JSR REQINPTE
 CMPA #3
 BEQ Z@
 LDA b@
 SUBA #'0
 LDB #10
 MUL
 PSHS B
 LDB b@+1
 SUBB #'0
 ADDB ,S+
 STB MBREATH
Z@ JSR REFMEN
 PULS D,X,Y,PC
a@ FCB 48 		*REQUESTER:VPOS
 FCB 7 			*HPOS
 FCB 16 		*width
 FCB 3 			*height
 FCB 2 			*length of input
 FDB b@ 		*address of input area
 FCC " MIDI delay: "
b@ FCC "00"
C@ FCB 0 		*end of requester
d@ FCC "99" 		*edit string

* amount of "breath" to be inserted between bytes
* sent to MIDI port; for slow synthesizers
MBREATH FCB 0

* Ask whether operator is sure
* Returns keypress in A
*
SURE PSHS X
 LDX #a@
 JSR SETREQ
 JSR DSPREQ
A@ LBSR GETUPC
 TSTA
* MOD May 16,1990 R.Gault exit on button
 BNE B@
 JSR READBUT2
 BEQ A@
* EMOD
B@ LBSR REFMEN
 PULS X,PC
a@ FCB 48 		*Requester: VPOS
 FCB 8 			*HPOS
 FCB 15 		*width
 FCB 3 			*height
 FCB 2 			*length of input
 FDB 0 			*address of input area
 FCC " Are you Sure?"
 FCB 0 			*end of requester

*REQFILLV - fill a voice with rests
*
REQFILLV PSHS D,X,Y,U
 LDX #a@
 LBSR SETREQ
 LBSR DSPREQ
 LDY #c@
 LBSR REQINPTE
 LBSR REFMEN
 LDB VOICE save current voice
 PSHS B
 CMPA #3 check for break
 BEQ Z@
 LDB b@ determine which voice
 SUBB #'1 needs to be filled.
 BLS Z@ abort if voice < 2
 STB VOICE
 LDB TIMESIG+1 determine rest value
 SUBB #'0
 LSRB
 LDA #1 	set up note code
 PSHS A
 LDA #192 	actual value of whole note
A@ INC ,S
 LSRA
 LSRB
 BNE A@
 PSHS A
 LDB VOICE
 LSLB  		get pointer to desired
 LDX #DSP_STRT 	voice.
 ABX
 PSHS B
 CLR z@
 LDY ,X 	get previous note
 LDD -2,Y
 TSTA  		skip if not a note
 BMI D@
 STB z@ 	set pitch of rests
D@ PULS B
 LDY #VOI_CNT
 LEAY B,Y
B@ CLRA  	increment VOI_CNT
 LDB ,S 	get rest value
 ADDD ,Y
 CMPD VOI_CNT 	compare to voice 1
 BHI C@
 STD ,Y 	update this voice's count
 LDA #1
 STA INSERTFL
 LBSR INSERT
 LDA 1,S 	get rest code
 ORA #RESTBIT
 LDB z@
 BNE E@
 LDB #18 	set position
E@ STD [,X] 	put rest into music memory
 BRA B@
C@ LEAS 2,S
 LBSR MOVBAK
Z@ PULS A
 STA VOICE
 PULS D,X,Y,U,PC
*
z@ FCB 0 	*previous pitch value
*
a@ FCB 48 	*REQUESTER:VPOS
 FCB 7 		*HPOS
 FCB 15 	*width
 FCB 3 		*height
 FCB 1 		*length of input
 FDB b@ 	*address of input area
 FCC " Fill voice #"
b@ FCC "2"
 FCB 0 		*end of requester
c@ FCC "8" 	*edit string

*REQMVOL - set MIDI volume values
*
REQMVOL PSHS D,X,Y
 BSR CNVMVOL
 LDX #MIDIVOLR
 LBSR SETREQ
 LBSR DSPREQ
 LDY #d@
 LBSR REQINPTE
 CMPA #3
 BEQ Z@
 LDB #8 counter of levels to convert
 PSHS B
 LDX #b@+6 point to ASCII decimal value
 LDY #MIDIVOL point to binary table
B@ BSR a@ convert
 CMPB #127 check for maximum of 127
 BLS A@
 LDB #127
A@ STB ,Y+
 LEAX 10,X move to next entry
 DEC ,S done yet?
 BNE B@
 LEAS 1,S
Z@ LBSR REFMEN
 PULS D,X,Y,PC
a@ LDA ,X convert 3 digit
 SUBA #'0 ASCII decimal to binary
 LDB #100
 MUL
 PSHS D
 LDA 1,X
 SUBA #'0
 LDB #10
 MUL
 ADDD ,S
 STD ,S
 LDB 2,X
 SUBB #'0
 CLRA
 ADDD ,S++
 RTS
CNVMVOL LDX #MIDIVOL convert MIDI volumes to ASCII
 LDY #b@+6
 LDA #8
C@ LDB ,X+ get binary value
 PSHS X,A
 CLRA
 LEAS -6,S
 TFR S,X
 LBSR BINASC
 LDA 2,X
 STA ,Y+
 LDD 3,X
 STD ,Y++
 LEAY 7,Y
 LEAS 6,S
 PULS X,A
 DECA
 BNE C@
 RTS
MIDIVOLR FCB 48 	*VPOS
 FCB 5 			*HPOS
 FCB 19 		*width of requester
 FCB 8 			*height of requester
 FCB c@-b@ 		*length of input
 FDB b@ 		*address of input area
 FCC "MIDI Volumes:"
 FCB 13,13
b@ FCC "ppp = 016  pp = 032"
 FCB 13
 FCC "  p = 048  mp = 064"
 FCB 13
 FCC " mf = 080   f = 096"
 FCB 13
 FCC " ff = 112 fff = 127"
c@ FCB 0
d@ FCC "      199       199 "
 FCC "      199       199 "
 FCC "      199       199 "
 FCC "      199       199"

*"Please Wait" requester
* Set up, but calling routine must erase!
*
PLSWAIT PSHS X
 LDX #a@
 LBSR SETREQ
 LBSR DSPREQ
 PULS X,PC
a@ FCB 48 		*VPOS
 FCB 5 			*HPOS
 FCB 20 		*width of requester
 FCB 3 			*height of requester
 FCB 0 			*length of input
 FDB 0 			*address of input area
 FCC "   Please Wait..."
 FCB 0 			*end of requester

* Change MIDI filter
*
CHGMFILT BSR REQMFILT
 PSHS D change MIDI filter flag
 LDA FILTER
 LDX #MENFILT
 LBSR CHGMENU
Z@ PULS D,PC

*REQMFILT - set MIDI filter
*
CNT SET 0
*
REQMFILT PSHS D,X,Y
 LEAS -1,S
* first clear out MIDI filter ASCII translation
 LDX #b@
 LDB #5
 LDA #32
E@ STA ,X+
 DECB
 BNE E@
* now translate FILTER bits into ASCII
 LDB FILTER
 LDX #b@
 BITB #BYTE_FL
 BEQ J@
 LDA #'B
 STA ,X+
J@ BITB #CHAN_FL
 BEQ F@
 LDA #'C
 STA ,X+
F@ BITB #EVNT_FL
 BEQ K@
 LDA #'E
 STA ,X+
K@ BITB #INST_FL
 BEQ G@
 LDA #'I
 STA ,X+
G@ BITB #VOL_FL
 BEQ H@
 LDA #'V
 STA ,X+
* now open requester
H@ LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LDY #d@
 JSR REQINPTE
 CMPA #3
 BEQ Z@
* translate the ASCII flags into binary
 LDB #5
 STB CNT,S
 LDX #b@
 CLRB
A@ LDA ,X+
 CMPA #'B
 BNE B@
 ORB #BYTE_FL
B@ CMPA #'I
 BNE C@
 ORB #INST_FL
C@ CMPA #'E
 BNE L@
 ORB #EVNT_FL
L@ CMPA #'V
 BNE I@
 ORB #VOL_FL
I@ CMPA #'C
 BNE D@
 ORB #CHAN_FL
D@ DEC CNT,S
 BNE A@
 STB FILTER
Z@ JSR REFMEN
 LEAS 1,S
 PULS D,X,Y,PC
a@ FCB 48 		*REQUESTER:VPOS
 FCB 2 			*HPOS
 FCB 26 		*width
 FCB 3 			*height
 FCB 5 			*length of input
 FDB b@ 		*address of input area
 FCC "MIDI filter (BCEIV): "
b@ FCC "     "
 FCB 0 			*end of requester
d@ FCC "@@@@@" 		*edit string

 IF 0=1
SELPORT COM PORTFL
 BEQ A@
 LDX #b@
 BRA B@
A@ LDX #a@
B@ LDY #MPORT
C@ LDA ,X+
 STA ,Y+
 TST ,X
 BNE C@
 RTS
a@ FCC " Serial Port"
   FCB 0
b@ FCC " CoCo MIDI  "
   FCB 0
 ENDC
 

SELPORT COM PORTFL
 BEQ A@
 LDX #b@
 BRA B@
A@ LDX #a@
 COM DW4FLG
 BEQ B@
 LDX #c@
B@ LDY #MPORT
C@ LDA ,X+
 STA ,Y+
 TST ,X
 BNE C@
 RTS
a@ FCC " Serial Port"
   FCB 0
b@ FCC " CoCo MIDI  "
   FCB 0
c@ FCC " Drivewire4 "
   FCB 0


CHGMCLCK COM CLOCKFL
 LDA CLOCKFL
 LDX #MENCLK
 BRA CHGMENU

*Change pulldown menu flag according to value in
* register A: if =0, make 'OFF', else 'ON'
* register X contains address of where to put flag
*
CHGMENU TSTA
 BNE A@
 LDD #$4F46 	'OF'
 STD ,X++
 LDA #'F
 STA ,X+
 RTS
A@ LDD #$4F4E 	'ON'
 STD ,X++
 LDA #$20 	' '
 STA ,X+
 RTS

EVNTLEN EQU 224 length of an EVENT table (ASCII)

REQEVENT PSHS D,X,Y,U
 LDX #RMIDEVNT
 LBSR SETREQ
 LBSR DSPREQ
 LDY #d@
 LBSR REQINPTE
 CMPA #3
 BEQ Z@
 LBSR CNVEVNT
Z@ LBSR REFMEN
 PULS D,X,Y,U,PC
RMIDEVNT FCB 30 	*VPOS
 FCB 1 			*HPOS
 FCB 28 		*width of requester
 FCB 11 		*height of requester
 FCB c@-MIDIEVNT 	*length of input (not used)
 FDB MIDIEVNT 		*address of input area
 FCC "MIDI Events:"
 FCB 13,13
MIDIEVNT FCC "0:         0-              "
 FCB 13
 FCC "                           "
 FCB 13
 FCC "1:         0-              "
 FCB 13
 FCC "                           "
 FCB 13
 FCC "2:         0-              "
 FCB 13
 FCC "                           "
 FCB 13
 FCC "3:         0-              "
 FCB 13
 FCC "                           "
c@ FCB 0 		*end of requester
d@ FCC "  @@@@@@@@ $ $$ $$ $$ $$ $$ "
 FCC " $$ $$ $$ $$ $$ $$ $$ $$ $$ "
 FCC "  @@@@@@@@ $ $$ $$ $$ $$ $$ "
 FCC " $$ $$ $$ $$ $$ $$ $$ $$ $$ "
 FCC "  @@@@@@@@ $ $$ $$ $$ $$ $$ "
 FCC " $$ $$ $$ $$ $$ $$ $$ $$ $$ "
 FCC "  @@@@@@@@ $ $$ $$ $$ $$ $$ "
 FCC " $$ $$ $$ $$ $$ $$ $$ $$ $$"

*EVENTS table--contains actual MIDI event data
* format: number of bytes, then 14 bytes
*
EVENTS FCB 0 		*event #0 count
 FCB 0,0,0,0,0,0,0 	*event #0 data
 FCB 0,0,0,0,0,0,0
 FCB 0 			*event #1 count
 FCB 0,0,0,0,0,0,0
 FCB 0,0,0,0,0,0,0
 FCB 0 			*event #2 count
 FCB 0,0,0,0,0,0,0
 FCB 0,0,0,0,0,0,0
 FCB 0 			*event #3 count
 FCB 0,0,0,0,0,0,0
 FCB 0,0,0,0,0,0,0

*CNVEVNT - convert ASCII events table to binary
*
ECNT SET 0
UCNT SET 1
CNT SET 2
*
CNVEVNT PSHS D,X,Y
 LEAS -3,S
 LDX #MIDIEVNT
 LDY #EVENTS
 LDB #4 number of events
 STA ECNT,S
A@ LEAX 11,X
 LDB ,X++ get # of bytes
 LDA #'0
 LBSR HEXBIN
 STA ,Y+
 STA UCNT,S
 LDB #5 # bytes in 1st row
 BSR b@
 LEAX 1,X skip CR
 LDB #9 #bytes in 2nd row
 BSR b@
*        DEC     ECNT,S
*        BNE     A@
 CMPY #CNVEVNT-15 *********
 BLS A@ *********
 LEAS 3,S
 PULS D,X,Y,PC
*
b@ STB CNT+2,S
B@ TST UCNT+2,S
 BNE D@
 LDD #$2020
 STD ,X++
 BRA E@
D@ LDD ,X++
 DEC UCNT+2,S
E@ LBSR HEXBIN
 STA ,Y+
 LEAX 1,X skip space
 DEC CNT+2,S
 BNE B@
 RTS

 IFEQ DEMO
* ---CONDITIONAL START
* Notifies user that this is a demo version
*
NOTAVAIL PSHS X
 LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LBSR WAITKEY
 LBSR REFMEN
 PULS X,PC
a@ FCB 48 		Requester: VPOS
 FCB 1 			HPOS
 FCB 28 		width
 FCB 3 			height
 FCB 0 			length of input
 FDB 0 			address of input area
 FCC "Not available: Demo Version"
 FCB 0 			end of requester
 ENDC
* ---CONDITIONAL END

GOTOBAR LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LDY #d@
 JSR REQINPTE
 CMPA #3
 BEQ Z@
 LBSR RSETPTR
 LDX #b@
 LDB #3
 LBSR ASCBIN
* MOD May 28,1990 R.Gault allow goto up to bar 341
 CMPD #341
 BHI Z@
 PSHS A save MSB
 CMPD #0 start of music?
 PSHS CC save result
 LDA #SEL_OK
 PULS CC recover result
 PSHS CC resave it
 BEQ A@
 LDA #SEL_NOK not start
A@ STA CHNGTSIG
 PULS A,CC recover MSB and test result
 BEQ B@
 SUBD #1 not at start
B@ TFR D,X
 LDD MEASURE
* EMOD
 LBSR MUL2X1
 TFR X,D
 LBSR ADV_DSP
Z@ LBSR REFMEN
 LBSR DSPMUS
 RTS
a@ FCB 48 		*REQUESTER:VPOS
 FCB 4 			*HPOS
 FCB 22 		*width
 FCB 3 			*height
 FCB 5 			*length of input
 FDB b@ 		*address of input area
 FCC "Go To Bar (1-341): "
b@ FCC "001"
 FCB 0 			*end of requester
d@ FCC "399" 		*edit string

