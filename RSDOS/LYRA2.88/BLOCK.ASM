 TITLE "BLOCK"
************************************************
* BLOCK/TXT: include file for LYRA
* Contains the block commands
* Last update: 18-aug-88
* Display mode taken into account
* Last update:  3-jun-90 modifications (c) R.Gault
************************************************

*MSG "BLOCK=",*

*BLK_MARK - mark beginning/end of block
*ENTRY: from EDITNOTE
*EXIT: BLK_ST/BLK_END pointers set up
*
BLK_STVC FDB 0 		VOI_CNT at start of block
BLK_ST RZB 16		*,0 pointers to start of block
BLK_ENVC FDB 0 		VOI_CNT at end of block
BLK_END RZB 16		*,0 pointers to end of block
*
BLK_MARK PSHS D,X,Y
 LDD ENDPTR
 LDA #SEL_OK
 STA BLOCKSET
D@ LDX #DSP_CURS
 LDD BLK_ST see if start has been set
 BNE A@
 LDY #BLK_ST
 LDD VOI_CNT
 STD BLK_STVC
 BRA B@
A@ LDD ,X make sure this mark
 CMPD BLK_ST is past first mark
 BLS Z@
 LDY #BLK_END
 LDD VOI_CNT
 STD BLK_ENVC
 LDA #SEL_OK
 STA BLOCKOK
B@ LDB #16
 JSR MOVEDATA
Z@ PULS D,X,Y,PC

*BLK_RSET - reset (cancel) block markers, restore cursor
*
BLK_RSET PSHS A
 LDA BLOCKSET
 CMPA #SEL_OK
 BNE Z@
 BSR BLK_CLR
 LDA #SEL_NOK
 STA BLOCKOK
 STA BLOCKSET
 TST COPYFLAG
 BEQ A@
 CLR COPYFLAG
 LDD OCPSAV
 BEQ A@
 STD STFCUR
A@ JSR DSPMUS
Z@ PULS A,PC

BLK_CLR PSHS D,X,Y
 LDB #8
 PSHS B
 CLRA
 CLRB
 LDX #BLK_ST
 LDY #BLK_END
A@ STD ,X++
 STD ,Y++
 DEC ,S
 BNE A@
 LEAS 1,S throw away counter
 STD BLK_STVC
 STD BLK_ENVC
 PULS D,X,Y,PC

*BLK_DEL - block delete
*ENTRY: BLK_STVC, BLK_ST, BLK_END already set up
*EXIT: display updated to start of block
*
BLK_DEL PSHS D,X,Y,U
 LBSR SET_PTRS
 LDA BLOCKOK make sure we can do
 CMPA #SEL_OK a block command
 BNE Z@
 LDX #DSPMODE
 CLRB  B is the voice counter
A@ TST ,X+ skip if voice not displayed
 BEQ B@
 BSR CLOSEBLK
B@ INCB
 CMPB #8
 BNE A@
 JSR RSETPTR update screen to start
 LDD BLK_STVC of copy
 JSR ADV_DSP
 JSR DSPMUS
 JSR BLK_RSET
 LBSR SET_PTRS
Z@ PULS D,X,Y,U,PC

*CLOSEBLK - close a block of music code (one voice)
*ENTRY: BUFFER already set up
* B = voice number (0 to 7)
*
CLOSEBLK PSHS D,X,Y
*first calculate size of block, put in BUFFER
 TFR B,A change voice to word offset
 LSLA
 LDY #BLK_ST calculate size of block
 LDX #BLK_END (make result negative)
 LEAX A,X
 LEAY A,Y
 LDD ,Y
 SUBD ,X
 STD [BUFFER] -(block size) in buffer
 BEQ Z@ quit if nothing to delete
*set up pointers for delete
 LDX ,X
 LDY ,Y
*do the delete
B@ LDD ,X++
 STD ,Y++
 CMPX ENDPTR done yet?
 BNE B@
*update pointers
 LDB 1,S restore voice #
 LDX #VOI_PTR
 JSR BLKADJPT
 LDX #DSP_STRT get start of close start
 JSR BLKADJPT
 LDX #BLK_ST adjust pointers for
 JSR BLKADJPT
 LDX #BLK_END this voice
 JSR BLKADJPT
 LDD ENDPTR
 ADDD [BUFFER]
 STD ENDPTR
Z@ PULS D,X,Y,PC

*BLK_COPY - copy block of music
*
BLK_COPY PSHS D,X,Y
 LBSR SET_PTRS
 LDY #DSPMODE
 CLRB  B is the voice counter
A@ TST ,Y+ skip if voice not displayed
 BEQ B@
 BSR COPYBUFF
 LDX #BLK_ST adjust pointers for this voice
 JSR BLKADJPT
 LDX #BLK_END
 JSR BLKADJPT
 JSR OPENBLK
B@ INCB
 CMPB #8
 BNE A@
 JSR RSETPTR update screen to start
 LDD BLK_STVC of copy
 JSR ADV_DSP
 LBSR BLK_RSET
 JSR DSPMUS
 LBSR SET_PTRS
Z@ PULS D,X,Y,PC

*COPYBUFF - copy block to buffer (one voice)
*ENTRY: BLK_ST and BLK_END set up
* B=voice number (0 to 7)
*EXIT: first word=size of block, last byte in buffer = 0.
*
COPYBUFF PSHS D,X,Y,U
 LSLB
 LDX #BLK_ST
 LDY #BLK_END
 ABX
 LEAY B,Y
 LDD ,Y calculate size of block
 SUBD ,X
 CMPD #$17E0 see if there is enough space
 BLS A@
 LDB #$80 display overflow error
 JMP DOSERR
A@ LSRB  make sure number is even
 LSLB
 LDX ,X point to start of music code
 TFR D,Y Y is counter block size
 LDU BUFFER
 STD ,U++ put size on buffer
B@ CMPY #0
 BEQ C@
 LDD ,X++ copy data to buffer
 STD ,U++
 LEAY -2,Y are we at end of block?
 BRA B@
C@ CLR ,U+ set end of block marker
 PULS D,X,Y,U,PC

*OPENBLK - open up a block of music code (one voice)
* and copy BUFFER into opened area.
*ENTRY: BUFFER already set up
* B = voice number (0 to 7)
* DSP_CURS point to start of "move to"
*EXIT: DSP_CURS pointers updated,
* ENDPTR updated.
*
OPENBLK PSHS D,X,Y,U
 LDX [BUFFER] exit if nothing to copy
 BEQ Z@
 LDX #DSP_CURS get start of "move to"
 TFR B,A
 LSLA  (word offset)
 LDY A,X point to start of this voice
 PSHS Y save on stack for comparison later
 BSR BLKADJPT adjust DSP_CURS
 LDX #VOI_PTR
 BSR BLKADJPT
 LDD ENDPTR
 TFR D,X
 ADDD [BUFFER] add block size
 STD ENDPTR
 TFR D,Y
 LEAX 2,X compensate for predecrement
 LEAY 2,Y
D@ LDD ,--X open up block in code
 STD ,--Y
 CMPX ,S at start of this voice?
 BNE D@
 PULS U get start of this voice
 LDX BUFFER
 LDY ,X++ get length of buffer
C@ LDD ,X++ move buffer into code
 STD ,U++
 LEAY -2,Y
 BNE C@
Z@ PULS D,X,Y,U,PC

*BLKADJPT - add amount in BUFFER to pointers
*ENTRY: X points to first pointer
* B = voice number (0-7)
* BUFFER set up by COPYBUFF
*
BLKADJPT PSHS D,X
 INCB
 CMPB #8 no need to adjust
 BEQ Z@ if last pointer
 TFR B,A
 LSLB
 ABX
 NEGA  make counter
 ADDA #8
 PSHS A
A@ LDD ,X
 ADDD [BUFFER]
 STD ,X++
 DEC ,S
 BNE A@
 LEAS 1,S throw away counter
Z@ PULS D,X,PC

*COPY_SET - set up copy cursor, copy flag
*
COPY_SET PSHS D
 LDA BLOCKOK make sure we can do
 CMPA #SEL_OK a block command
 BNE Z@
 TST COPYFLAG
 BNE Z@
 INC COPYFLAG
 LDD STFCUR save old cursor pointer
 STD OCPSAV
 LDD #COPYCUR
 STD STFCUR
 LDA #SEL_NOK
 STA BLOCKOK
Z@ PULS D,PC

OCPSAV FDB 0 		*old cursor pointer
COPYFLAG FCB 0 		*>1 if ready to copy
COPYCUR FCB 35
 FDB $1FF0
 FDB $2008,$2188,$2188,$2188
 FDB $2188,$23C8,$2668,$2668
 FDB $2008,$2608,$2608,$2608
 FDB $27C8,$2668,$2668,$27C8
 FDB $2008,$27E8,$2668,$2668
 FDB $2668,$2668,$2668,$27E8
 FDB $2008,$23C8,$2668,$2608
 FDB $2608,$2608,$2668,$23C8
 FDB $2008,$1FF0

* transpose selected block of music
*
 IFEQ 1
 LVAR
 BYTE L_VCNT
 BYTE L_OFFS
 PTR L_BST
 PTR L_BEN
 PTR L_EPTR
 ENDLVAR 
 ENDC                                                                        
*
BLK_TRNS LDA BLOCKOK
 CMPA #SEL_OK
 BEQ A@
 RTS
A@ PSHS D,X,Y,U
 LEAS -LOCAL,S
 LDX #a@
 LBSR SETREQ
 LBSR DSPREQ
 LDY #d@
 LBSR REQINPTE
 CMPA #3
 BEQ Z@
 LDA b@
 CMPA #'S check for correct input
 BEQ B@
 CMPA #'A
 BEQ B@
 LDA #'F
 STA b@
B@ LDD c@ convert number of
 SUBB #'0 steps to binary
 CMPA #'+
 BEQ C@
 NEGB
C@ STB L_OFFS,S
 CLR L_VCNT,S
 LDX #BLK_ST
 STX L_BST,S
 LDX #BLK_END
 STX L_BEN,S
D@ LDX [L_BST,S]
 LDD [L_BEN,S]
 STD L_EPTR,S
 LDB L_VCNT,S skip this voice if
 LDY #DSPMODE it is not displayed
 TST B,Y
 BEQ G@
* do the actual transposing now--ABSOLUTE
E@ LDD 0,X
 TSTA  skip options
 BMI F@
 BEQ G@
 BITA #RESTBIT skip rests
 BNE F@
 LBSR CNVCODE
 ADDB L_OFFS,S
 LDA b@
 CMPA #'F
 BNE H@
 CLRA
 BRA I@
H@ LDA #$FF
I@ PSHS X
 PSHS D
 BSR CNV_MICO
 LEAS 2,S
 PULS X
 STB 1,X
F@ LEAX 2,X
 CMPX L_EPTR,S
 BLO E@
* see if we're done yet
G@ LDX L_BST,S
 LEAX 2,X
 STX L_BST,S
 LDX L_BEN,S
 LEAX 2,X
 STX L_BEN,S
 INC L_VCNT,S
 LDA L_VCNT,S
 CMPA #8
 BNE D@
Z@ LBSR REFMEN
 LBSR DSPMUS
 LEAS LOCAL,S
 PULS D,X,Y,U,PC
*
a@ FCB 48,3,24,4,e@-d@
 FDB b@
 FCC " Transpose mode (F/S):"
b@ FCC "F"
 FCB 13
 FCC " Number of steps: "
c@ FCC "+0"
 FCB 0
d@ FCC "@ "
 FCC "                  +9"
e@ FCB 0

* convert MIDI pitch in to display code
* returns display code in D
*
 IFEQ 1
 LVAR
 BYTE L_MODE
 ENDLVAR                                                                         
*
 SVAR
 INT S_MID
 ENDSVAR  
 ENDC                                                                       
*
CNV_MICO LEAS -LOCAL2,S
 LDA S_MID,S
 STA L_MODE,S
 CLR S_MID,S
 LDX #MIDPITCH
 CLRA
A@ LDB S_MID+1,S
 CMPB A,X
 BEQ C@
 INCA
 CMPB A,X
 BEQ C@
 DECA
 SUBB A,X
 CMPB #$FF
 BNE B@
 TST L_MODE,S
 BNE E@
 ORA #FLATBIT
 BRA C@
E@ INCA
 ORA #SHARPBIT
 BRA C@
B@ INCA
 CMPA #64
 BLO A@
C@ TFR A,B
Z@ LEAS LOCAL,S
 RTS

* do a code to MIDI conversion but ignore octave
* and transpose values
* ENTRY: pitch in B
* EXIT: MIDI pitch in B, other registers preserved
*
CNVCODE PSHS A,X
 PSHS B
 LDX #MIDPITCH
 ANDB #$3F discard sharp+flat bits
 LDA B,X
 PULS B restore pitch code
 BITB #FLATBIT
 BEQ E@
 DECA
E@ BITB #SHARPBIT
 BEQ F@
 INCA
F@ TFR A,B
 PULS A,X,PC

* copy one voice to another
*
 IFEQ 1
 LVAR
 ENDLVAR                                                                         
*
 SVAR
 ENDSVAR 
 ENDC
LOCAL2	SET	2                                                                        
*
VOICOPY PSHS D,X,Y,U
 LEAS -LOCAL2,S
 LDA BLOCKOK
 CMPA #SEL_OK
 BNE Z@
 LDX #a@
 LBSR SETREQ
 LBSR DSPREQ
 LDY #d@
 LBSR REQINPTE
 LBSR REFMEN
 CMPA #3
 BEQ Z@
 LDB b@ get "from" voice number
 SUBB #'1
 BMI Z@
 LBSR COPYBUFF
 LDB c@ get "to" voice number
 SUBB #'1
 BMI Z@
 LDX #BLK_ST
 LBSR BLKADJPT
 LDX #BLK_END
 LBSR BLKADJPT
 LBSR OPENBLK
 LBSR RSETPTR
 LDD BLK_STVC
 LBSR ADV_DSP
 LBSR BLK_RSET
 LBSR DSPMUS
Z@ LEAS LOCAL,S
 PULS D,X,Y,U,PC
*
a@ FCB 48,5,20,4,e@-d@
 FDB b@
 FCC " Copy from voice: "
b@ FCC "1"
 FCB 13
 FCC " Copy to voice: "
c@ FCC "2"
 FCB 0
d@ FCC "8 "
 FCC "                8"
e@ FCB 0

