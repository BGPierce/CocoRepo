 TITLE "DSPMUS"
*************************************************
* DSPMUS/TXT - INCLUDE FILE FOR LYRA
* (C) 1988 by Lester Hands
* CONTAINS MOST OF THE MUSIC DISPLAY ROUTINES
* Last update: 17-aug-88
* Last update: 15-jun-90 modifications (c) R.Gault
*************************************************

*MSG "DSPMUS=",*

*EDITNOTE - Allow note entry/editing of music
*
INSERTFL FCB 0
KEYFLAG FCB 0 		*key pressed
*
EDITNOTE PSHS D,X,Y,U
* check for keypress
 LBSR GETUPC
 STA KEYFLAG
 CMPA #'1 check for 1-8
 BLO G@
 CMPA #'8
 BHI G@
 LBSR HIVOICE
 LBRA F@
* make sure a voice is selected, and that a note is displayed
G@ LDB VOICE
 CMPB #$FF exit if no voice selected
 LBEQ Z@
 LSLB
 LDX #VOI_CNT make sure voice count
 LDD B,X is >= than that
 CMPD VOI_CNT for voice 1.
 LBLO Z@
 CLR NATURAL
 CLR FLAT
 CLR SHARP
 TST CLICK
 BNE R@
 TST KEYFLAG
 BEQ Z@
* do a 'edit display' to update DSP_CURS pointers
R@ LDA #1
 STA DSPEDIT set start edit mode
 LBSR DSPMUS
 CLR DSPEDIT
 TST COPYFLAG (no copy in demo version)
 BEQ O@
 LBSR BLK_COPY
 BRA Z@
* set up register X so it points to desired note
O@ LDB VOICE set up X to point to
 LSLB  current voice
 LDX #DSP_CURS
 LDX B,X
* check for end of voice (must insert if so)
 TST ,X check for end of voice
 BNE S@
 LDA #1
 STA INSERTFL must insert if at end
S@ TST CLICK skip if mouse has
 BNE C@ been clicked
* perform key function by looking it up in a table
 LDA KEYFLAG get keypress
 LDY #a@ point to table
J@ TST ,Y check for end of table
 BEQ Z@
 CMPA ,Y+ check for match
 BEQ V@
 LEAY 2,Y
 BRA J@
V@ JSR [,Y] match found, do it
* either enter or insert a note at cursor position
C@ TST CLICK
 BEQ F@
 LBSR INSERT
P@ LDB VPOS
 TST NATURAL
 BNE N@
 LBSR CHKKSIG
 LDA DFLAT
 TST SHARP
 BNE L@
 ORA FLAT
 STA FLAT
L@ LDA DSHARP
 TST FLAT
 BNE N@
 ORA SHARP
 STA SHARP
N@ LBSR CNV_DICO
 LDA NVALU
 STD ,X store note data in memory
F@ LBSR DSPMUS
Z@ PULS D,X,Y,U,PC
** Here follow the simple keypress routines;
** all assume X points to the desired note.
*set natural flag
D@ DEC NATURAL natural
A@ LDA #$FF set CLICK flag so
 STA CLICK a note will be entered
 RTS
*set sharp flag
M@ DEC SHARP sharp
 BRA A@
*set flat flag
Q@ DEC FLAT flat
 BRA A@
 RTS
*tie a note, X points to note
B@ LDA ,X get NVALU
 BEQ b@ exit if =0
 ORA #TIEBIT set tie bit
 STA ,X
b@ RTS
*delete a note, X points to note
K@ LBRA DELETE
*mark a block
E@ LBRA BLK_MARK
*dot a note, X points to note
I@ LDA ,X dot
 BEQ c@ exit if NVALU=0
 TFR A,B make sure we are not
 ANDB #7 dotting a whole note
 CMPB #1
 BEQ c@
 ORA #DOTBIT set dot bit
 STA ,X
c@ RTS
*make a note triplet, X points to note
H@ LDA ,X triplet
 BEQ d@ exit if NVALU = 0
 TFR A,B don't triplet a whole
 ORB #7 note.
 CMPB #1
 BEQ d@
 ORA #TRIPBIT set triplet bit
 STA ,X
d@ RTS
* keypress/subroutine table
a@ FCB 'N 	natural
 FDB D@
 FCB 'S 	sharp
 FDB M@
 FCB 'F 	flat
 FDB Q@
 FCB 'T 	tie
 FDB B@
 FCB 'D 	delete
 FDB K@
 FCB '. 	dot
 FDB I@
 FCB '# 	triplet
 FDB H@
 FCB 'B 	block mark
 FDB E@
 FCB 'R 	tempo change
 FDB SOPTTEMP
 FCB 'I 	instrument option
 FDB SOPTINST
 FCB 'M 	MIDI byte out
 FDB SOPTBYTE
 FCB 'C 	MIDI clock on/off
 FDB SOPTCLK
 FCB 'E 	MIDI event
 FDB SOPTEVNT
 FCB 'O 	Octave option
 FDB SOPTOCTV
 FCB 'L 	loco option
 FDB SOPTLOCO
 FCB 'V 	Volume option
 FDB SOPTVOL
 FCB 'G 	Goto bar #
 FDB GOTOBAR
 FCB 0 		end of table

*HIVOICE - set desired voice to black, all others
* to halftone or blank
*ENTRY: A=ASCII number 1-8
*
HIVOICE PSHS D,X
 SUBA #'1 convert to binary
 LDX #DSPMODE
 PSHS A,X
 LDD #$0108
A@ CMPA ,X+
 BNE B@
 INC -1,X
B@ DECB
 BNE A@
 PULS B,X
 STA B,X
 LBSR VOIBOX
 PULS D,X,PC

*CHKKSIG - check key signature for accidentals
*ENTRY: B=VPOS
*EXIT: DSHARP, and DFLAT set appropriately
*
CHKKSIG PSHS D,X,Y
 TST DSPEDIT
 BNE Z@
 CLR DSHARP
 CLR DFLAT
 LDA KSIGDAT do we need to adjust for
 CMPA #'0 key signature?
 BEQ Z@
 SUBA #'0 convert key # to binary
 PSHS A put counter on stack
 TFR B,A put VPOS in A
 JSR CNVDIS convert VPOS to note of
 LDB KSIGDAT+1 check for sharp/flat
 LDX #a@
 CMPB #'S
 BEQ A@
 LEAX 7,X
A@ PULS B restore key # counter
C@ CMPA ,X+
 BEQ D@
 DECB
 BNE C@
 BRA Z@
D@ CMPX #b@
 BHI E@
 DEC DSHARP
 BRA Z@
E@ DEC DFLAT
Z@ PULS D,X,Y,PC
a@ FCB 5,2,6,3,0,4,1 	notes in sharp keys
b@ FCB 1,4,0,3,6,2,5 	notes in flat keys
DSHARP FCB 0 		sharp as per key signature
DFLAT FCB 0 		flat as per key signature

*SETACDNT - set accidentals for display
*ENTRY: SHARP,DSHARP and FLAT,DFLAT already set up
* B=VPOS
*EXIT: SHARP, FLAT, NATURAL set correctly for key signature
*
SETACDNT PSHS D
 TST DSPEDIT
 BNE D@
 LDA SHARP
 CMPA DSHARP
 BNE A@
 CLR SHARP
 BRA B@
A@ TSTA
 BNE B@
 DEC NATURAL
B@ LDA FLAT
 CMPA DFLAT
 BNE C@
 CLR FLAT
 BRA D@
C@ TSTA
 BNE D@
 DEC NATURAL
D@ PULS D,PC

*DSPMUS - Display a screenful of music
*EXIT: A=HPOS on entry; B=HPOS that was "backed up"
*
*pointers and counters at start of screen display
DSP_STRT RZB 16		*,0 display pointers to voices
CNT_STRT RZB 8		*,0 starting offset for CNT_CURS
MEA_STRT FDB 0 		starting measure count
BNUM_ST FDB 0 		starting barline number
VOI_CNT RZB 16		*,0 voice counter from start of music
VOI_OVFL RMB 2 		temp. storage of last
*                              position R.Gault
*pointers and counters at cursor position
DSP_CURS RZB 16		*,0 cursor display pointers
CNT_CURS RZB 8		*,0 note value
MEA_CNT FDB 0 		measure counter
BAR_NUM FDB 0 		barline number
VOI_CCUR FDB 0 		VOI_CNT at cursor position
*some flags
DSPEDIT FCB 0 		*1=display edit mode
DSP_NXTF FCB 0 		*>0 when DSP_NXT updated
*pointers and counters at display position + 1
DSP_NXT RZB 16		*,0
CNT_NXT RZB 8		*,0
VOI_NXT FCB 0
MEA_NXT FDB 0
BNUM_NXT FDB 0
*misc.
MEASURE FDB 192 	measure length
*
DSPMUS PSHS X,Y,U
 CLR NTPG_CTR
 CLR DSP_NXTF
 CLR VOI_NXT
 LDD MEA_STRT
 STD MEA_CNT
 LDD BNUM_ST
 STD BAR_NUM
 TST OLDCDP see if cursor has
 BEQ B@ already been erased.
 CLRA
 CLRB
 STD OLDCDP
 JSR CURREF
B@ LDX #DSP_STRT set up pointers
 LDY #DSP_CURS
 LDB #16
 JSR MOVEDATA
 LDX #CNT_STRT set up voice counters
 LDY #CNT_CURS
 LDB #8
 JSR MOVEDATA
 LDD VOI_CNT
 STD VOI_CCUR
 LDA HPOS save current HPOS
 STA HPOS+1
 LDA #3 set start of display
 STA HPOS
 JSR DSPKSIG
 JSR DSPTSIG
D@ LDD MEA_CNT see if a barline is needed
 BNE E@
 JSR BLANK
 JSR BARLINE
 JSR INVERT1
 LDD MEASURE
 STD MEA_CNT
 PSHS B
 LDD BAR_NUM
 ADDD #1
 STD BAR_NUM
 PULS B
 LDA HPOS
 INCA
 STA HPOS
 CMPA #28
 BHI I@
* if this is an edit display, see if we're done
E@ TST DSPEDIT check for display edit
 BEQ C@
 LDA HPOS compare display with
 SUBA HPOS+1 cursor position
 STA INSERTFL
 LSRA  exit if =1 OR 0
 BNE C@
 LDX #CNT_CURS added code to allow
 LDB VOICE inserts when cursor
 LDA B,X is between notes
 ORA INSERTFL
 STA INSERTFL
 BRA Z@
C@ JSR BLANK
F@ JSR NEWNOT
 TSTB  check for end of music
 BEQ G@ (set by NEWNOT)
 JSR INVERT
G@ PSHS B
 TST DSP_NXTF see if "next" pointers
 BNE H@ and constants need updating.
 TST [DSP_CURS] see if voice 1 is at end
 BNE J@
 CLRA
 CLRB
 STD DSP_NXT
 BRA H@
J@ LDX #DSP_CURS
 LDY #DSP_NXT
 LDB #16
 JSR MOVEDATA
 LDX #CNT_CURS
 LDY #CNT_NXT
 LDB #8
 JSR MOVEDATA
 LDD MEA_CNT
 STD MEA_NXT
 LDD BAR_NUM
 STD BNUM_NXT
 INC DSP_NXTF
H@ PULS B
 TSTB  check for end of music
 BEQ I@
 INC NTPG_CTR
 LDA HPOS advance display HPOS
 ADDA #2
 STA HPOS
 CMPA #28 check for end of screen
 LBLE D@
I@ TST DSPEDIT
 BNE Z@
A@ LDA LINEWIDE
 SUBA #2
 PSHS A
 LDA HPOS blank out end of staff
 CMPA ,S+
 BHS Z@
 JSR BLANK
 INC HPOS
 BRA A@
Z@ LDD HPOS restore original HPOS
 STB HPOS
 PULS X,Y,U,PC

*NEWNOT - Get and display a new note
*EXIT: A=smallest note value
* B=0 if at end of music
*
DSPCNT FCB 0 		number of voices displayed
CHOPTFL FCB 0 		>$7F if options to display
*
NEWNOT PSHS X,Y,U
* first check for TEMPO,BYTE,EVENT and CLOCK options in voice 1
 LDX #DSP_CURS
 LDY #CNT_CURS
 LDU #DSPMODE
A@ TST ,Y skip if new note not
 BNE B@  ready in voice 1
 LDD [,X] skip if not an option
 BPL B@  in voice 1
 CMPA #TEMPOPT
 BEQ D@
 CMPA #CLK_OPT
 BEQ D@
 CMPA #EVNTOPT
 BEQ D@
 CMPA #BYTEOPT
 BNE B@
D@ LBSR DSP_ADV
 INC NTPG_CTR
 LBRA Z@
* look for any other options
B@ LDA #INSTOPT
 LBSR OPT_DSP
 TSTA
 BEQ G@
 INC NTPG_CTR
 LBRA Z@
G@ LDA #VOL_OPT
 LBSR OPT_DSP
 TSTA
 BEQ M@
 INC NTPG_CTR
 LBRA Z@
M@ CLRA
K@ TST ,Y+ OR NVALUs of all voices
 BNE L@ together that have
 ORA [,X] CNT_CURS=0
L@ LEAX 2,X
 CMPX #DSP_CURS+16
 BNE K@
 STA CHOPTFL
* now look for notes to display
 LDX #DSP_CURS time to display if at
 LDY #CNT_CURS least one counter=0
 LDU #DSPMODE
C@ TST ,Y if counter>0 then not
 BNE I@ ready to display new note yet
 LDA [,X] get new note's value
 BEQ I@ if NVALU=0 then end of this voice
 BMI E@ check for option
 TST CHOPTFL see if note display permitted
 BMI I@
 JSR CONVNVAL
 STA ,Y update counter
E@ LDA ,U get display mode
 BEQ H@ skip if not selected
 CLRB
 CMPA #1 if =2 then half tone display
 BEQ F@
 ADDB #$80
F@ STB DSPFLAG
 LDD [,X] get music code and pitch for note
 JSR CNV_CODI
 TSTA  check for option
 BMI J@
 JSR CHKKSIG
 JSR SETACDNT
J@ JSR DSPNOT
 INC DSPCNT
H@ LDD ,X update pointer
 ADDD #2
 STD ,X
I@ LEAY 1,Y
 LEAU 1,U
 LEAX 2,X move to next pointer
 CMPX #DSP_CURS+16
 BNE C@
 TST CHOPTFL
 BMI Z@
 JSR GET_SMAL
 PSHS D
 TFR A,B
 CLRA
 ADDD VOI_CCUR
 STD VOI_CCUR
 PULS D
 TST VOI_NXT
 BNE Z@
 STA VOI_NXT now update VOI_NXT
Z@ PULS X,Y,U,PC

* Look for specified option and display used by NEWNOT
* ENTRY: A=option
*        X=music pointer
*        Y=note counts pointer
*        U=DSPMODE pointer
* EXIT:  A=number of displays
*
OPT SET 0
COUNT SET 1
DSP SET 2
MOD SET 3
*
OPT_DSP PSHS X,Y,U
 LEAS -4,S make room for local variables
 STA OPT,S
 CLR COUNT,S
 CLR DSP,S
A@ TST ,Y+ look for zero counter
 BNE B@
 LDA ,U skip if voice not displayed
 BEQ B@
 STA MOD,S
 LDD [,X] get note
 ANDA #$F0 test for right option
 CMPA OPT,S
 BNE B@
 CLR DSPFLAG set up DSPFLAG
 DEC MOD,S
 BEQ C@
 LDA #$80
 STA DSPFLAG
C@ LDA [,X]
 BSR DSP_ADV
 INC DSP,S
B@ LEAX 2,X
 LEAU 1,U
 INC COUNT,S
 LDA COUNT,S
 CMPA #8
 BNE A@
Z@ LDA DSP,S
 TFR A,B
 LEAS 4,S
 PULS X,Y,U,PC

* Simple display and advance used by NEWNOT
* ENTRY: D=note, X=pointer to music
*
DSP_ADV LBSR CNV_CODI simple display+advance
 LBSR DSPNOT D=note,X=pointer
 INC DSPCNT
 LDD ,X
 ADDD #2
 STD ,X
 RTS  all done

*GET_SMAL - find smallest note counter (CNT_CURS)
*EXIT: A=smallest note counter
* B=0 if at end of music (all counters=0)
* all counters decremented by A (smallest counter)
* BAR_NUM and MEA_CNT also updated
*
GET_SMAL PSHS X
 JSR FINDSMA
 PSHS D
 TSTB  at end of music?
 BEQ C@
 LDX #CNT_CURS
A@ LDA ,X+ get counter
 BEQ B@ skip if =0
 SUBA ,S subtract smallest
 STA -1,X
B@ CMPX #CNT_CURS+8
 BNE A@
 CLR ,-S change to 16 bit value
 LDD MEA_CNT
 BNE D@
 LDD MEASURE
 PSHS D
 LDD BAR_NUM
 ADDD #1
 STD BAR_NUM
 PULS D
D@ SUBD ,S+
 STD MEA_CNT
C@ PULS D,X,PC

*FINDSMA - find smallest counter (CNT_CURS) <>0
*EXIT: A=smallest counter, B=0 when all voices at end of code
*
FINDSMA PSHS X
 LDX #CNT_CURS
 LDD #$FF08 smallest counter
 PSHS A put on stack
A@ LDA ,X+ find smallest counter
 BNE B@
 DECB  update counter of voices
 BRA C@ at end of music
B@ CMPA ,S
 BHI C@
 STA ,S save it on stack
C@ CMPX #CNT_CURS+8
 BNE A@
 PULS A,X,PC

*MOVECURS - move cursor beyond edges of screen
*EXIT: DSP_STRT pointers updated
*
MOVECURS PSHS D,X,Y,U
 CLR CLICK
 TST DRAG
 BEQ I@
 JSR CURREF erase cursor
 CLRA
 CLRB
 STD OLDCDP
 LDA HPOS determine which side
 CMPA #1 of the screen we are on
 BHI F@
 BSR MOVBAK
 BRA I@
F@ LDD DSP_NXT see if there is a valid
 BEQ I@ next position
 LDA #SEL_NOK disable changing time
 STA CHNGTSIG signature.
 BSR MOVFWD
 LDU #FORWICON
 JSR ICOFLI
 JSR DSPMUS update display
G@ JSR ICOWRI restore icon
I@ PULS D,X,Y,U,PC

MOVFWD PSHS D,X,Y,U
 LDD MEA_NXT
 STD MEA_STRT
 LDD BNUM_NXT
 STD BNUM_ST
 LDX #DSP_NXT
 LDY #DSP_STRT
 LDB #16
 JSR MOVEDATA
 LDX #CNT_NXT
 LDY #CNT_STRT
 LDB #8
 JSR MOVEDATA
 LDB VOI_NXT
 CLRA
 PSHS D
 LDX #DSP_STRT
 LDY #VOI_CNT
A@ TST [,X++] see if voice is at
 BEQ I@ it's end.
 LDD ,Y get counter
 ADDD ,S add difference
 STD ,Y
I@ LEAY 2,Y
 CMPX #DSP_STRT+16
 BNE A@
 PULS D
 PULS D,X,Y,U,PC

MOVBAK PSHS D,X,Y,U
 LDU #BACKICON
 LBSR ICOFLI
 LDD VOI_CNT at start of music (=0)?
 BNE B@
 LDA #SEL_OK if at start of music then
 STA CHNGTSIG enable time signature
 CLR CONTFL
 LBRA Z@
*get smallest counter (return in A)
B@ LDX #CNT_STRT
 LDD #$FF08
 PSHS A
C@ LDA ,X+
 BEQ D@ skip if counter=0
 CMPA ,S
 BHS D@
 STA ,S
D@ DECB
 BNE C@
 PULS A
*decrement counters with value in A
 LDX #CNT_STRT
 LDB #8
 PSHS A
E@ LDA ,X+
 BEQ A@ no decrement if counter=0
 SUBA ,S
 STA -1,X
A@ DECB
 BNE E@
 LEAS 1,S
*decrement pointers that have a zero counter
 LDX #DSP_STRT
 LDY #CNT_STRT
 LDB #8
F@ LDU ,X
 TST ,Y+ look for zero counter
 BNE H@
 TST ,U no decrement if at end
 BEQ H@
G@ LEAU -2,U decrement pointer
 TST ,U
 BMI G@ decrement again if option
H@ STU ,X++ update pointer
 DECB
 BNE F@
*get note lengths for zero counters, return smallest
 LDX #CNT_STRT
 LDY #DSP_STRT
 LDD #$FF08
 PSHS A
I@ TST ,X+ look for zero counter
 BNE J@
 LDA [,Y] get NVALU
 BEQ J@ skip if end of voice
 PSHS B
 LBSR CONVNVAL
 PULS B
 CMPA ,S look for smallest
 BHS J@
 STA ,S
J@ LEAY 2,Y
 DECB
 BNE I@
*        PULS    B             smallest note in B
*set new VOI_CNT and re-display to that point
 CLRA
 PSHS A MOD see * PULS B
 LDD VOI_CNT
 SUBD ,S++
 BCC K@
 CLRA
 CLRB
K@ LBSR RSETPTR
 LBSR ADV_DSP
*clean up and exit
 LDA #SEL_NOK disable time signature
 STA CHNGTSIG
 LBSR DSPMUS
Z@ LDU #BACKICON restore icon
 LBSR ICOWRI
 PULS D,X,Y,U,PC

*DSPKSIG - display key signature
*Advances HPOS by appropriate amount
*
DSPKSIG PSHS D,X,Y,U
 CLR CSHIFT
 LDD KEYSIG
 CMPA #'0
 BEQ Z@
 SUBA #'0 convert to binary
 PSHS A save counter on stack
 CMPB #'S
 BNE A@
 LDU #a@
 LDX #c@
 BRA B@
A@ LDU #b@
 LDX #d@
B@ CLR HPOSH
 JSR BLANK
E@ LDA ,U+ get VPOS
 LDB HPOS
 JSR CURSOR display treble clef
 LDA ,U+ get VPOS
 LDB HPOS
 JSR CURSOR display bass clef
 LDA #1
 EORA HPOSH
 STA HPOSH
 BNE C@
 INC HPOS
 JSR BLANK
C@ DEC ,S check counter
 BNE E@
 TST HPOSH
 BEQ D@
 INC HPOS
D@ INC HPOS
 PULS A
Z@ PULS D,X,Y,U,PC
*Sharp key signature VPOS
a@ FCB 60,102,69,111,57,99,66,108,75,96,63,105,72,93
*Flat key signature VPOS
b@ FCB 72,114,63,105,75,117,66,108,78,120,69,111,81,123
*Sharp data
c@ FCB 8 number of words
 FDB $5000,$5000,$F800,$5000,$5000
 FDB $F800,$5000,$5000
*Flat data
d@ FCB 9
 FDB $8000,$C000,$A000,$A000
 FDB $A000,$C000,$8000,$8000,$8000

*DSPTSIG - display time signature
*ENTRY: TSIGDAT, HPOS set up
*
DSPTSIG JSR BLANK
 LDD #192
 ADDB HPOS
 TFR D,U
 LDA #FAT+JAM 	set FAT/JAM mode
 STA TMODE
 LDB LINEWIDE 	adjust text up a line
 NEGB
 SEX
 STD TEXTADJ
 BSR A@
 LEAU 63,U 	move down to bass staff
 BSR A@
 CLRA
 CLRB
 STD TEXTADJ
 INC HPOS
 RTS
A@ LDA TSIGDAT
 JSR TEXT
 LDA LINEWIDE
 DECA
 LEAU A,U move down 1 line
 LDA TSIGDAT+2
 JMP TEXT

NOTDAT EQU *
NOT1 FCB 9 	whole note
 FDB 0
 FDB $780,$C40,$820,$420,$3C0
 FDB 0,0,0
NOT2 FCB 19 	half note
 FDB 0
 FDB $7C0,$C60,$830,$670,$3D0
 FDB $10,$10,$10,$10,$10,$10
 FDB $10,$10,$10,$10,$10,$10,$10
NOT4 FCB 19 	quarter note
 FDB 0
 FDB $7C0,$FE0,$FF0,$7F0,$1D0
 FDB $10,$10,$10,$10,$10
 FDB $10,$10,$10,$10,$10
 FDB $10,$10,$10
NOT8 FCB 19 	eighth note
 FDB 0
 FDB $7C0,$FE0,$FF0,$7F0,$1D0
 FDB $10,$10,$10,$10,$14,$12,$12
 FDB $12,$12,$14,$14,$18,$10
NOT16 FCB 19 	1/16th note
 FDB 0
 FDB $7C0,$FE0,$FF0,$7F0,$1D0
 FDB $10,$10,$14,$12,$12,$16,$16
 FDB $1A,$12,$14,$14,$18,$10
NOT32 FCB 19 32nd note
 FDB 0
 FDB $7C0,$FE0,$FF0,$7F4,$1D2
 FDB $12,$16,$16,$1A,$12,$16
 FDB $16,$1A,$12,$14,$14,$18,$10
NOT64 FCB 19 	64th note
 FDB 0
 FDB $7C4,$FE2,$FF6,$7F6,$1DA
 FDB $12,$16,$16,$1A,$12,$16
 FDB $16,$1A,$12,$14,$14,$18,$10

RES1 FCB 7 	whole rest
 FDB 0,0,0,0
 FDB $3C0,$3C0,$FF0
RES2 FCB 6 	half rest
 FDB 0,0,0
 FDB $FF0,$3C0,$3C0
RES4 FCB 14 	quarter rest
 FDB 0
 FDB $0080,$0300,$0600,$0600
 FDB $0300,$01C0,$0180,$0300,$0300
 FDB $0180,$00C0,$0080,$0100,$0100
RES8 FCB 8 	8th rest
 FDB 0
 FDB $40,$40,$40,$40
 FDB $340,$7C0,$640
RES16 FCB 10 	16th rest
 FDB 0
 FDB $40,$40,$40,$340
 FDB $7C0,$640,$340,$7C0,$640
RES32 FCB 14 	32nd rest
 FDB 0
 FDB $40,$40,$40
 FDB $40,$340,$7C0,$640,$340
 FDB $7C0,$640,$340,$7C0,$640
RES64 FCB 16 	64th rest
 FDB 0
 FDB $40,$40
 FDB $40,$340,$7C0
 FDB $640,$340,$7C0,$640,$340
 FDB $7C0,$640,$340,$7C0,$640

SHRPDT FDB $5050,$F850,$50F8,$5050,0
 FDB 0,0,0,0,0
FLATDT FDB $80C0,$A0A0,$A0C0,$8080,$8000
 FDB 0,0,0,0,0
NATDAT FDB $1010,$F090,$90F0,$8080,$8080
 FDB 0,0,0,0,0

TIEDAT FCB 4 	number of words
 FDB $3FFC,$9FF9
 FDB $C3C3,$F00F
TRIPDAT FCB 5 	number of words
 FDB $F8FF,$FEFF
 FDB $FCFF,$FEFF
 FDB $F8FF

*Lookup tables of addresses of the
*notes and rests
*
NOTTAB FDB NOT1,NOT2
 FDB NOT4,NOT8
 FDB NOT16,NOT32
 FDB NOT64
 FDB RES1,RES2
 FDB RES4,RES8
 FDB RES16,RES32
 FDB RES64

ACCIDNTL FCB 0 		>0 if accidental to be displayed
NATURAL FCB 0 		>0 if natural to be displayed
SHARP FCB 0 		>0 if note to be sharped
FLAT FCB 0 		>0 if note to be flatted

*INVERT - invert music display when DSP_CURS>BLK_ST
*
INVERT PSHS D,X
 BRA C@
INVERT1 PSHS D,X
 INC a@
C@ TST DSPEDIT
 BNE Z@
 TST BLK_ST see if marker set
 BEQ Z@
 LDD DSP_CURS compare pointers
 CMPD BLK_ST for just voice #1
 BLS Z@
 TST BLK_END
 BEQ A@
 CMPD BLK_END
 BHI Z@
A@ LDD SCREEN
 ADDD #1184
 ADDB HPOS
 TFR D,X
 LDB #114
 PSHS B
B@ LDD ,X
 COMA
 COMB
 TST a@
 BEQ D@
 STA ,X
 BRA E@
D@ STD ,X
E@ LDB LINEWIDE
 ABX
 DEC ,S
 BNE B@
 PULS B
Z@ CLR a@
 PULS D,X,PC
a@ FCB 0 =1 when 1 byte invert desired

*INSERT - inserts a 2-byte word into music code as
*specified by VOICE and DSP_CURS
*INSERTFL must be set to nonzero
*EXIT: updates pointer areas VOI_PTR,DSP_CURS,DSP_STRT
*
INSERT PSHS D,X
 TST INSERTFL
 BEQ Z@
 CLR INSERTFL
 LBSR BLK_RSET
 LBSR SET_PTRS set end pointer
 LDB VOICE B=offset to pointers
 LSLB  adjust for word offset
 LDX #DSP_CURS (voice pointers)
 LDX B,X voice pointer
 PSHS X save start of insert
 LDX ENDPTR end of code pointer
 LEAX 3,X
B@ LDA ,-X move data up 2 bytes
 STA 2,X
 CMPX ,S done yet?
 BNE B@
 PULS X get start of insert pointer
 LDD #$100
 STD ,X set nonzero for DSPMUS
 LDD #2 set BUFFER as needed
IDUPDCNT STD [BUFFER] for BLKADJPT
 LDB VOICE start update with next voice
 CMPB #7
 BEQ F@
 LDX #VOI_PTR
 LBSR BLKADJPT
 LDX #DSP_STRT
 LBSR BLKADJPT
 LDX #DSP_CURS
 LBSR BLKADJPT
F@ LDD ENDPTR update ENDPTR
 ADDD [BUFFER]
 STD ENDPTR
Z@ PULS D,X,PC

*DELETE - deletes a 2-byte word from music code as
*specified by VOICE and DSP_STRT
*EXIT: updates pointer areas VOI_PTR,DSP_STRT,DSP_CURS
*
DELETEFL FCB 0 =$FF when delete to be done
*
DELETE PSHS D,X
 LBSR BLK_RSET
 BSR SETEPTR
 LDB VOICE B=offset to pointers
 LSLB  adjust for word offset
 LDX #DSP_CURS (voice pointers)
 LDX B,X voice pointer
 TST ,X make sure we're not
 BNE A@ at end of this voice
 CLR DELETEFL
 PULS D,X,PC
A@ LEAX 2,X
B@ LDA ,X+ move data down 2 bytes
 STA -3,X
 CMPX ENDPTR
 BLO B@
 LDD #-2
 BRA IDUPDCNT

*SETEPTR - set the ENDPTR pointer
*
SETEPTR PSHS X
 LDX VOI_PTR+14 point to start of voice 8
A@ TST ,X++ check for end of voice
 BNE A@
 STX ENDPTR
 PULS X,PC

*BARMOVE - move through music according to bar position
*
BARMOVE PSHS D,X,Y
 TST DRAG
 LBEQ Z@
 JSR CURREF erase cursor
 CLRA  cancel normal cursor erase
 CLRB
 STD OLDCDP
A@ JSR REABUT
 JSR READMOUS
 TST DRAG
 LBEQ Z@
 LDA HPOS make sure position
 ADDA HPOSH has changed
 CMPA HPOS+1
 BEQ A@
 STA HPOS+1
 LDA #2
 CMPA HPOS
 BLO M@
 STA HPOS
 CLR HPOSH
 LDA LINEWIDE
 SUBA #3
 CMPA HPOS
 BHI M@
 STA HPOS
 LDA #1
 STA HPOSH
M@ JSR VERTBAR
*now find out how many bars in part 1
* MOD R.Gault
 LDX VOI_CNT save last good position
 STX VOI_OVFL in case of overflow
 JSR RSETPTR
 LDX #0 measure counter
 PSHS X measure accumulator
 LDY #V1 point to start of voice #1
E@ LDA ,Y++ get NVALU
 BEQ G@ check for end of music
 BMI E@ check for option
I@ JSR CONVNVAL
 TFR A,B convert to 16 bit value
 CLRA
 ADDD ,S
 CMPD MEASURE
 BLO F@
 LEAX 1,X increment bar counter
 SUBD MEASURE
F@ STD ,S
 BRA E@
*calculate which bar number is desired from HPOS
G@ LEAS 2,S throw away accumulator
 CLRA
 LDB HPOS calculate (bar#)(HPOS)/59
 SUBB #2 X has measure count
 BEQ L@
 LSLB  include HPOSH
 ADDB HPOSH
 JSR MUL2X1
 TSTB  check for overflow
 BEQ K@
* MOD R.Gault
H@ LDX VOI_OVFL get temp. store of position
 STX VOI_CNT save it
 CLR CONTFL
 COM CONTFL
 LDB #$81 new was $80;report overflow error
 JMP DOSERR
K@ TFR X,D
 CMPD #0 if at start, clear CONTFL
 BNE K1
 CLR CONTFL
K1 LDX #55
 JSR DIVIDE
 LDD MEASURE convert bar # to total count
 JSR MUL2X1
 TSTB  check for overflow
 BNE H@
 LDA LINEWIDE
 SUBA #3
 PSHS A
 LDA HPOS check for end of bar
 CMPA ,S+
 BLO N@
 LDY VOI_PTR+2 get last note in voice #1
 LDD -4,Y
 JSR CONVNVAL
 TFR A,B decrement count by
 NEGB  NVALU of last note
 SEX
 LEAX D,X
N@ TFR X,D
*now go through music until desired count is reached
 JSR ADV_DSP
*clean up and exit
 LDA #SEL_NOK
 STA CHNGTSIG
L@ JSR DSPMUS
 LBRA A@
Z@ PULS D,X,Y,PC
*
VERTBAR LDA #NOTES+5 display vertical bar at HPOS
 LDB #32 calculate display position
 MUL
 ADDD SCREEN
 TFR D,X
 LDB #2
B@ CMPB HPOS
 BNE C@
 TST HPOSH
 BNE J@
 LDA #$9F
 BRA D@
J@ LDA #$F9
 BRA D@
C@ LDA #$FF
D@ BSR a@
 INCB
 CMPB #29
 BLS B@
 RTS
a@ PSHS D,X put bar on screen
 ABX
 LDB #9
b@ STA ,X
 LEAX 32,X
 DECB
 BNE b@
 PULS D,X,PC


*ADV_DSP - advance DSP_STRT pointers until VOI_CNT
* equals D.
*
ADV_DSP PSHS D,X,Y,U
 CMPD #0
 BEQ Z@
 LDX MEASURE
 JSR DIVIDE
 CMPD #0
 BEQ D@
 LEAX 1,X
 PSHS D
 LDD MEASURE
 SUBD ,S++
D@ STD MEA_STRT
 STX BNUM_ST
 LDX #DSP_STRT
 LDY #CNT_STRT
 LDU #VOI_CNT
A@ CLRA
 CLRB
 PSHS D,U put accumulator on stack
 LDU ,X++ get pointer for voice
B@ LDA ,U++
 BMI B@ ignore options
 BNE F@ exit if at end of music
 LEAU -2,U
 BRA C@
F@ JSR CONVNVAL
 TFR A,B
 CLRA
 ADDD ,S add note length to accumulator
 STD ,S
 CMPD 4,S is it same as desired count?
 BLO B@
E@ LDD ,S calculate CNT_STRT
 SUBD 4,S
 STB ,Y
 LDD 4,S
 STD ,S
C@ STU -2,X update pointer
 PULS D,U
 STD ,U++
 LEAY 1,Y
 CMPX #DSP_STRT+16 have all voices been done?
 BNE A@
Z@ PULS D,X,Y,U,PC

*CNV_DICO - convert display (VPOS) to music code
*ENTRY: B=VPOS, SHARP and FLAT flags set
*EXIT: B=music code, SHARP and FLAT flags cleared
* structure of music code: lower 6 bits=pitch code (0-63)
* bit 6=sharp, bit 7=flat
*
CNV_DICO PSHS A,X
 TST DSPEDIT
 BNE Z@
 CLRA
 SUBB #24
 LDX #3 divide by 3
 JSR DIVIDE
 TFR X,D
 TST SHARP move SHARP flag into
 BEQ A@
 ORB #SHARPBIT
A@ TST FLAT and FLAT flag into
 BEQ B@
 ORB #FLATBIT
B@ CLR FLAT
 CLR SHARP
Z@ PULS A,X,PC

*CNV_CODI - convert music code to display code (VPOS)
*ENTRY: B=music code
*EXIT: B=VPOS, SHARP, FLAT set appropriately
*
CNV_CODI PSHS A
 TSTA  no conversion if an
 BMI Z@ option
 TST DSPEDIT
 BNE Z@
 CLRA
 BITB #FLATBIT test flat bit
 BEQ A@
 DECA
A@ STA FLAT
 CLRA
 BITB #SHARPBIT test sharp bit
 BEQ B@
 DECA
B@ STA SHARP
 ANDB #$3F discard upper 2 bits
 LDA #3
 MUL
 ADDB #24
Z@ PULS A,PC

