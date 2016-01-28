* TITL1 "REQUEST/TXT"
************************************************
* REQUEST/TXT: INCLUDE FILE FOR LYRABOX
* Last update: 12-19-86
************************************************

*SETREQ - set up requester box
*ENTRY: X points to string for requester
*
SETREQ PSHS D,X,Y,U
 LBSR REQSTAT
 LDU BUFFER point to refresh memory
 LDA ,X+ get VPOS for menu
 LDB #32 convert to address
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
 LEAX 32,X
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
 LEAX 32,X
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
REQCURSF FCB 0 >1 if cursor to be displayed
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
 LDA #32 32 bytes/line
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
 ADDD #32 move to next line
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
K@ JSR KEYIN
 TSTA  wait for keypress
 BEQ K@
 CMPA #10 check for down arrow
 BNE I@
 TST REQEDOK
 BEQ K@
J@ CLRA
 LDA D,Y move forward until
 CMPA #32 space found or end
 BEQ H@
 INCB
 CLRA
 TST D,U
 BNE J@
 BRA E@
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
 BNE A@ against string length
 DECB  don't allow offset to
 BRA A@ go beyond end of string
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
*
REQEDOK FCB 0 if >0 then editing enabled
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
A@ CMPA #'9 check for numeric
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

*SETDRIVE - set disk drive via a requester
*
SETDRIVE LDA $95A get present drive #
 ADDA #'0 convert to ASCII
 STA B@
 LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LDY #d@
 JSR REQINPTE
 CMPA #3 check for BREAK
 BEQ A@
 LDA B@ get drive #
 SUBA #'0 convert to binary
 BMI A@ check for wrong input
 CMPA #3
 BHI A@
 STA $95A set default drive #
 STA $EB
 JSR DISKHOME
A@ CLR $FF40
 LBSR REFMEN
 LBSR GETDIR
D@ RTS
a@ FCB 48 VPOS
 FCB 5 HPOS
 FCB 20 width of requester
 FCB 3 height of requester
 FCB C@-B@ length of input
 FDB B@ address of input area
 FCC "Use Drive # (0-3): "
B@ FCC "0"
C@ FCB 0 end of requester
d@ FCC "3" edit string

*MIDITRAN - set MIDI transposition offset via requester
*
MIDITRAN LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LDY #d@
 JSR REQINPTE
 LDA B@ get offset
 CMPA #'- check for negative sign
 BNE D@
 LDA B@+1
 SUBA #'0
 NEGA
 BRA E@
D@ CMPA #'+ check for positive sign
 BNE F@
 LDA B@+1
F@ SUBA #'0 convert to binary
E@ STA TRANOFFS set default drive #
A@ LBRA REFMEN
a@ FCB 48 VPOS
 FCB 3 HPOS
 FCB 24 width of requester
 FCB 3 height of requester
 FCB C@-B@ length of input
 FDB B@ address of input area
 FCC "Transpose (-9 TO +9): "
B@ FCC "+0"
C@ FCB 0 end of requester
d@ FCC "+9" edit string

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
 LEAX $0E,X point to next ASCII number
 DEC ,S done yet?
 BNE A@
 LEAS 1,S throw away counter
 PULS D,X,Y,PC

MIDINSTB FCB 0,0,0,0,0,0,0,0 binary equivalents
 FCB 0,0,0,0,0,0,0,0 of MIDINST

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

*REQMDELA - set MIDI delay between bytes
*
REQMDELA PSHS D,X,Y
 LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LDY #d@
 JSR REQINPTE
 LDA b@
 SUBA #'0
 LDB #10
 MUL
 PSHS B
 LDB b@+1
 SUBB #'0
 ADDB ,S+
 STB MBREATH
E@ JSR REFMEN
 PULS D,X,Y,PC
a@ FCB 48 REQUESTER:VPOS
 FCB 7 HPOS
 FCB 16 width
 FCB 3 height
 FCB 2 length of input
 FDB b@ address of input area
 FCC " MIDI delay: "
b@ FCC "00"
C@ FCB 0 end of requester
d@ FCC "99" edit string

* amount of "breath" to be inserted between bytes
* sent to MIDI port; for slow synthesizers
MBREATH FCB 0

* check system stack and report error if it is
* about to overflow.
*
STKCHK PSHS X
 CMPS #STACK-120
 BHI Z@
 LDX #a@
 JSR SETREQ
 JSR DSPREQ
 LBSR WAITKEY
 LBSR REFMEN
Z@ PULS X,PC
a@ FCB 48 REQUESTER:VPOS
 FCB 8 HPOS
 FCB 14 width
 FCB 3 height
 FCB 2 length of input
 FDB 0 address of input area
 FCC " Stack Error "
C@ FCB 0 end of requester

* Ask whether operator is sure
* Returns keypress in A
*
SURE PSHS X
 LDX #a@
 JSR SETREQ
 JSR DSPREQ
A@ LBSR KEYIN
 TSTA
 BEQ A@
 LBSR REFMEN
 PULS X,PC
a@ FCB 48 Requester: VPOS
 FCB 8 HPOS
 FCB 15 width
 FCB 3 height
 FCB 2 length of input
 FDB 0 address of input area
 FCC " Are you Sure?"
 FCB 0 end of requester

