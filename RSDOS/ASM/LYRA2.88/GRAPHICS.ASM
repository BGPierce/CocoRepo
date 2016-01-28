 TITLE "GRAPHICS"
*************************************************
* GRAPHICS/TXT: INCLUDE FILE FOR LYRA
* CONTAINS MOST OF THE GRAPHICS ROUTINES
* Last update: 12-jul-88
* Last update:  3-jun-90 modifications (c) R.Gault
*************************************************

*MSG "GRAPHICS=",*

LINEWIDE FCB 32 width of graphics display
SCREEN FDB $D000
BUFFER FDB $E800

*Module to set graphics mode
*It is assumed that on first entry text mode is on
*
SETGRA STA $FFD3 set offset to $D000.
 STA $FFD1
 STA $FFCD
 STA $FFC8
 IFNE DEMO
* ---CONDITIONAL START
 LDA STYPE
 CMPA #'2
 BEQ B@
 LDA #$F8 set color set 1
 BRA C@
 ENDC
*---CONDITIONAL END
B@ LDA #$F0 set graphics mode to G6R
C@ STA $FF22
 STA $FFC3
 STA $FFC5
 RTS

*Clear the graphics screen module
*
PCLS LDX SCREEN clear graphics
 LDD #$FFFF screen
 LDY #$0C00
A@ STD ,X++
 LEAY -1,Y
 BNE A@
 RTS

*Module to set up musical staff
*
WRTSTF LDX SCREEN
 LEAX $800,X
 LDY #CLFDAT
 LDA #67
 PSHS A
A@ LDD ,Y++
 STD ,X
 LDB LINEWIDE
 ABX
 DEC ,S
 BNE A@
 PULS A
 LDA #2
 STA HPOS
 LDA LINEWIDE
 DECA
 PSHS A
B@ BSR BLANK
 LDA HPOS
 ADDA #2
 STA HPOS
 CMPA ,S
 BLE B@
 LEAS 1,S
 LBSR BORDER
 LBSR DSPFNAME
 LBSR VOIBOX
 LBSR NOTMEN
 LDA #2 write bar in fast move gadget
 STA HPOS
 LBSR VERTBAR
 RTS

*BLANK - write blank section of staff at HPOS position
*
BLANK PSHS D,X,Y
 TST DSPEDIT
 BNE Z@
 LDY #CLFDAT
 LDD SCREEN
 ADDD #$4A0
 ADDB HPOS
 TFR D,X
 LDA #27
 BSR C@
 LDA #67
 PSHS A
A@ LDD ,Y++
 BEQ B@
 LDD #$FFFF
B@ STD ,X
 LDB LINEWIDE
 ABX
 DEC ,S
 BNE A@
 PULS A
 LDA #25
 BSR C@
Z@ PULS D,X,Y,PC
C@ PSHS A
 LDD #$FFFF clear lines above/below staff
D@ STD ,X
 PSHS B
 LDB LINEWIDE
 ABX
 PULS B
 DEC ,S
 BNE D@
 PULS A,PC

CLFDAT FDB $FFFF,$FF9F,$FF6F,$FF6F,$FF6F,$FF5F,$0
 FDB $FF3F,$FF3F,$FF7F,$FE7F,$FE7F,$0
 FDB $FD7F,$FB7F,$F37F,$F77F,$E77F,$0
 FDB $CE0F,$9C07,$9963,$9B73,$9B73,$0
 FDB $9B73,$DD73,$CF67,$E767,$F14F,$0
 FDB $FF7F,$F97F,$F17F,$F17F,$F27F,$F8FF
 FDB $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$0
 FDB $E03F,$C71F,$CF9C,$9F8C,$9FCF,$0
 FDB $98E7,$98E4,$CCE4,$C1E7,$E3E7,$0
 FDB $FFCF,$FFCF,$FF9F,$FF9F,$FF3F,$0
 FDB $FE7F,$FCFF,$F1FF,$FFFF,$FFFF,$0

*Module to write a border around screen
*                                                 
BORDER LDX SCREEN
 BSR BAR
 PSHS X
 LDX #TOPLIN
 LDU #0
 LDA #FAT+EOR select "FAT EOR" mode
 STA TMODE
A@ LDA ,X+ display top line
 BEQ B@
 LBSR TEXT
 BRA A@
B@ PULS X
 LDB #179 now write sides of screen
C@ LDA #$7F
 ANDA ,X
 STA ,X
 LDA LINEWIDE
 DECA
 LEAX A,X
 LDA #$FE
 ANDA ,X
 STA ,X+
 DECB
 BNE C@
D@ LDB LINEWIDE
 LDA #0
E@ STA ,X+
 DECB
 BNE E@
 RTS
BAR LDB #12
F@ PSHS B
 BSR D@
 PULS B
 DECB
 BNE F@
 RTS

*BARLINE - display a barline at HPOS
*
BARLINE TST DSPEDIT
 BNE Z@
 PSHS D,X
 LDD SCREEN
 ADDD #$8C0
 ADDB HPOS
 TFR D,X
 LDB #61 number of bytes to alter
A@ LDA #$F7 display byte
 ANDA ,X
 STA ,X store it in display
 LDA LINEWIDE
 LEAX A,X move to next line down
 DECB  all bytes displayed?
 BNE A@
 PULS D,X
 PSHS D,X display bar number
 LDD BAR_NUM
 ADDD #1
 LEAS -6,S put ASCII string on stack
 TFR S,X
 LBSR BINASC
 CLR TMODE
 LDD #96 set up display position
 ADDB HPOS
 TFR D,U
 LDD #256
 STD TEXTADJ
 LEAX 2,X point to first ASCII number
 LDD ,X+
 CMPA #'0 erase leading zeros
 BNE C@
 LDA #32
 CMPB #'0
 BNE C@
 LDB #32
C@ STB ,X
 LBSR TEXT
 LDA LINEWIDE
 DECA
 LEAU A,U
 LDA LINEWIDE
 LDB #4
 MUL
 STD TEXTADJ
 LDA ,X+
 LBSR TEXT
 LDA LINEWIDE
 DECA
 LEAU A,U
 CLRA
 CLRB
 STD TEXTADJ
 LDA ,X
 LBSR TEXT
 LEAS 6,S
 PULS D,X
Z@ RTS

*Module to display notes and rests
*
NOTES EQU 153 top VPOS of the notes menu
*
NOTMEN PSHS D,X
 CLR HPOSH clear half position flag
 LDB #NOTES+3 first write a bar above note menu
 BSR LINE
 ADDB #12 another line 12 lines down
 BSR LINE
D@ LDU #BACKICON do left move box
 LBSR ICOWRI
 LDU #FORWICON
 LBSR ICOWRI
 LDA #NOTES+23 now display notes
 LDB #2 =HPOS
 LDY #NOTTAB
A@ LDX ,Y++
 LBSR CURSOR
 ADDB #2 increment horizontal position
 CMPB #29 see if we are done yet
 BLE A@
 PULS D,X,PC

*LINE - write a line across screen
*ENTRY: VPOS in B
*
LINE PSHS D,X
 LDA LINEWIDE
 MUL
 ADDD SCREEN
 TFR D,X
 LDB LINEWIDE bytes/line
A@ CLR ,X+
 DECB
 BNE A@
 PULS D,X,PC

BACKICON FCB NOTES+4 	*VPOS for icon
 FCB 0 			*HPOS for icon
 FDB $7FFE 		*EOR data for icon
 FCB 11 		*number of words
 FDB $7E7E,$7C7E,$787E
 FDB $7002,$6002,$4002
 FDB $6002,$7002
 FDB $787E,$7C7E,$7E7E

FORWICON FCB NOTES+4 	*VPOS for icon
 FCB 30 		*HPOS for icon
 FDB $7FFE 		*EOR data for icon
 FCB 11 		*number of bytes
 FDB $7E7E,$7E3E,$7E1E
 FDB $400E,$4006,$4002
 FDB $4006,$400E
 FDB $7E1E,$7E3E,$7E7E

*TEXT - alphanumerics generator
*ENTRY: ASCII character in A, position in U (0-511)
* Bits of TMODE determine type of display:
* 0:THIN/FAT
* 1:OR/EOR
* 2:-/JAM (disable OR, stored straight on screen)
* 3:SOLID/HALF TONE
* 4:NORMAL/INVERSE
*TMODE may be set by putting its value+128 in A
*EXIT: U advanced 1
*
TMODE FCB 0 		*display mode
TEXTADJ FDB 0 		*offset for line adjust
*
SEL_NOK EQU 9+128 	*always used as part of a
SEL_OK EQU 1+128 	*string, so 8th bit set
THIN EQU 0
FAT EQU 1
EOR EQU 2
JAM EQU 4
HALFTONE EQU 8
INVERSE EQU 16
*
TEXT TSTA  check for TMODE
 BPL C@ control character
 SUBA #128
 STA TMODE
 RTS
C@ PSHS D,X,Y
 PSHS A save letter to display
 LDA #$55 	set MASK
 STA MASK
 TFR U,D
 LSLB  calculate display address
 ROLA  move upper 3 bits into A
 LSLB
 ROLA
 LSLB
 ROLA
 PSHS A save line number (0-15)
 LDB #$80 1 byte by 2 bytes multiply
 MUL  multiply number by 384 or 3*$80)
 ADDA ,S+  or 3*$80)
 ADDD SCREEN
 ADDD #64
 ADDD TEXTADJ
 TFR D,X
 TFR U,D now get column number (0-31)
 ANDB #$1F
 ABX  now X points to screen address
 PULS A restore ASCII character
 SUBA #32 convert A to binary offset
 LDB #8 # bytes/character
 MUL
 ADDD #CHTABLE now D contains table address
 TFR D,Y
 EXG X,Y
 LDB #8 number of bytes to display
A@ PSHS B
 LDA ,X+ get display data
 LDB TMODE check type of display desired
 BITB #1 THIN/FAT test
 BEQ B@
 PSHS A OR display data against
 LSRA  itself to increase width
 ORA ,S+
B@ BITB #8 check SOLID/HALF TONE
 BEQ G@
 ANDA MASK
 COM MASK
G@ BITB #2 check OR/EOR bit
 BNE E@
 COMA
 BITB #4 check JAM flag
 BNE D@
 ANDA ,Y
 BRA D@
E@ EORA ,Y
D@ BITB #$10 check INVERSE flag
 BEQ F@
 COMA
F@ STA ,Y store data into display
 LDB LINEWIDE
 LEAY B,Y move down to next line
 PULS B
 DECB  update counter
 BNE A@
 LEAU 1,U
 PULS D,X,Y,PC

 FCB $55,$AA,$55,$AA,$55,$AA,$55,$AA
CHTABLE FCB 0,0,0,0,0,0,0,0 * 
 FCB $20,$20,$20,$20,$20,0,$20,0 *!
 FCB $48,$48,$48,0,0,0,0,0 *"
 FCB $50,$50,$F8,0,$F8,$50,$50,0 *#
 FCB $20,$78,$80,$70,$8,$F0,$40,0 *$
 FCB $C8,$C8,$10,$20,$40,$98,$98,0 *%
 FCB $10,$78,$80,$60,$80,$78,$10,0 *&
 FCB $20,$20,$20,0,0,0,0,0 *'
 FCB $10,$20,$40,$40,$40,$20,$10,0 *(
 FCB $40,$20,$10,$10,$10,$20,$40,0 *)
 FCB 0,$88,$50,$F8,$50,$88,0,0 **
 FCB 0,$20,$20,$F8,$20,$20,0,0 *+
 FCB 0,0,0,0,$30,$30,$10,$20 *,
 FCB 0,0,0,$F8,0,0,0,0 *-
 FCB 0,0,0,0,0,$30,$30,0 *.
 FCB $8,$8,$10,$20,$40,$80,$80,0 */
 FCB $30,$48,$48,$48,$48,$48,$30,0 *0
 FCB $20,$60,$20,$20,$20,$20,$70,0 *1
 FCB $70,$88,$8,$30,$40,$80,$F8,0 *2
 FCB $70,$88,$8,$30,$8,$88,$70,0 *3
 FCB $10,$30,$50,$90,$F8,$10,$10,0 *4
 FCB $F8,$80,$F0,$8,$8,$88,$70,0 *5
 FCB $70,$80,$80,$F0,$88,$88,$70,0 *6
 FCB $F8,$8,$10,$20,$40,$80,$80,0 *7
 FCB $70,$88,$88,$70,$88,$88,$70,0 *8
 FCB $70,$88,$88,$78,$8,$8,$70,0 *9
 FCB 0,$40,$40,0,$40,$40,0,0 *:
 FCB 0,$30,$30,0,$30,$10,$20,0 *;
 FCB $8,$10,$20,$40,$20,$10,$8,0 *<
 FCB 0,0,$F8,0,$F8,0,0,0 *=
 FCB $80,$40,$20,$10,$20,$40,$80,0 *>
 FCB $70,$88,$08,$10,$20,0,$20,0 *?
 FCB $70,$88,$8,$68,$9A,$88,$70,0 *@
 FCB $20,$50,$88,$88,$F8,$88,$88,0 *A
 FCB $F0,$48,$48,$70,$48,$48,$F0,0 *B
 FCB $70,$88,$80,$80,$80,$88,$70,0 *C
 FCB $F0,$48,$48,$48,$48,$48,$F0,0 *D
 FCB $F8,$80,$80,$F0,$80,$80,$F8,0 *E
 FCB $F8,$80,$80,$F0,$80,$80,$80,0 *F
 FCB $78,$80,$80,$98,$88,$88,$78,0 *G
 FCB $88,$88,$88,$F8,$88,$88,$88,0 *H
 FCB $70,$20,$20,$20,$20,$20,$70,0 *I
 FCB $08,$08,$08,$08,$08,$88,$70,0 *J
 FCB $88,$90,$A0,$C0,$A0,$90,$88,0 *K
 FCB $80,$80,$80,$80,$80,$80,$F8,0 *L
 FCB $88,$D8,$A8,$A8,$88,$88,$88,0 *M
 FCB $88,$C8,$A8,$98,$88,$88,$88,0 *N
 FCB $F8,$88,$88,$88,$88,$88,$F8,0 *O
 FCB $F0,$88,$88,$F0,$80,$80,$80,0 *P
 FCB $70,$88,$88,$88,$A8,$90,$68,0 *Q
 FCB $F0,$88,$88,$F0,$A0,$90,$88,0 *R
 FCB $70,$88,$40,$20,$10,$88,$70,0 *S
 FCB $F8,$20,$20,$20,$20,$20,$20,0 *T
 FCB $88,$88,$88,$88,$88,$88,$70,0 *U
 FCB $88,$88,$88,$50,$50,$20,$20,0 *V
 FCB $88,$88,$88,$A8,$A8,$D8,$88,0 *W
 FCB $88,$88,$50,$20,$50,$88,$88,0 *X
 FCB $88,$88,$50,$20,$20,$20,$20,0 *Y
 FCB $F8,$8,$10,$20,$40,$80,$F8,0 *Z
 FCB $70,$40,$40,$40,$40,$40,$70,0 *[
 FCB $80,$80,$40,$20,$10,8,8,0 *\
 FCB $70,$10,$10,$10,$10,$10,$70,0 *]
 FCB $20,$70,$A8,$20,$20,$20,$20,0 *^
 FCB 0,0,0,0,0,0,0,$FF *_
 FCB $80,$40,$20,0,0,0,0,0 *`
 FCB 0,0,$70,8,$78,$88,$74,0 *a
 FCB $80,$80,$B0,$C8,$88,$88,$F0,0 *b
 FCB 0,0,$78,$80,$80,$80,$78,0 *c
 FCB 4,4,$74,$8C,$84,$84,$7C,0 *d
 FCB 0,0,$70,$88,$F0,$80,$70,0 *e
 FCB $30,$48,$40,$E0,$40,$40,$40,0 *f
 FCB 0,0,$70,$88,$88,$78,8,$70 *g
 FCB $80,$80,$B0,$C8,$88,$88,$88,0 *h
 FCB $20,0,$60,$20,$20,$20,$70,0 *i
 FCB 0,$10,0,$10,$10,$10,$50,$20 *j
 FCB $80,$80,$90,$A0,$C0,$A0,$90,0 *k
 FCB $60,$20,$20,$20,$20,$20,$70,0 *l
 FCB 0,0,$D0,$A8,$A8,$A8,$88,0 *m
 FCB 0,0,$B0,$48,$48,$48,$48,0 *n
 FCB 0,0,$70,$88,$88,$88,$70,0 *o
 FCB 0,0,$F0,$88,$88,$F0,$80,$80 *p
 FCB 0,0,$78,$88,$88,$78,8,8 *q
 FCB 0,0,$B0,$C8,$80,$80,$80,0 *r
 FCB 0,0,$70,$80,$70,8,$F0,0 *s
 FCB $20,$20,$70,$20,$20,$20,$30,0 *t
 FCB 0,0,$90,$90,$90,$90,$68,0 *u
 FCB 0,0,$88,$88,$50,$50,$20,0 *v
 FCB 0,0,$88,$88,$A8,$A8,$50,0 *w
 FCB 0,0,$88,$50,$20,$50,$88,0 *x
 FCB 0,0,$88,$88,$88,$78,8,$F0 *y
 FCB 0,0,$F8,$10,$20,$40,$F8,0 *z

*ICOWRI - display an icon on the screen
*ENTRY: U points to the icon data
*The icon data is in the following format:
*VPOS,HPOS,EOR word,# of words to display
*The maximum width is 16 bits.
*
ICOWRI PSHS D,X,U
 LDX ,U++ get VPOS,HPOS
 LBSR CALADR
 LEAU 2,U skip EOR word
 LDB ,U+ get # of bytes to display
 PSHS B
A@ LDD ,U++
 STD ,X
 LEAX 32,X move to next line down
 DEC ,S
 BNE A@
 LEAS 1,S
 PULS D,X,U,PC

*ICOFLI inverts an icon
*ENTRY: U points to icon data (see ICOWRI for structure)
*
ICOFLI PSHS D,X,Y,U
 LDX ,U++ get VPOS,HPOS
 LDY ,U++ get EOR bytes
 LDB ,U+ get # of bytes
 PSHS B
 LBSR CALADR
A@ TFR Y,D
 EORA ,U+ get icon bytes and
 EORB ,U+ invert them
 STD ,X
 LDB LINEWIDE
 ABX  move to next line
 DEC ,S
 BNE A@
 LEAS 1,S
 PULS D,X,Y,U,PC

*VOIBOX - Set up voice selection icons
* and select correct voice from DSPMODE
*
VOICE FCB 0 		*current voice
*
BDYDSP FDB $FBFE 	*normal body
 FDB $F800 		*inverse body
 FDB $FAAA 		*shaded body #1
 FDB $F954 		*shaded body #2
VBOX FDB 0 		*address for boxes
*
VOIBOX PSHS D,X,Y,U
 LDD SCREEN set up VBOX
 ADDD #$02EF
 STD VBOX
 LDX #DSPMODE
 CLRA  determine which part is "VOICE"
 CLRB
 PSHS A
G@ LDA B,X check each part for =1
 CMPA #1
 BNE H@
 STB VOICE
 INC ,S keep track of how many parts=1
H@ INCB
 CMPB #8
 BNE G@
 PULS A if there are more than 1 part=1
 DECA
 BEQ I@
 LDA #$FF then set voice to -1
 STA VOICE
I@ LDU VBOX pointer to display area
 LDB #0 voice counter
A@ PSHS U
 LDY #$FC01 display top of box
 STY ,U
 LDA LINEWIDE
 LEAU A,U
 LDA #11
 PSHS A
 LDX #DSPMODE
B@ LDA B,X
 LDY #BDYDSP
 LSLA
 LDY A,Y get display byte
 LSRA
 CMPA #1
 BLE C@
 EORA #1
 STA B,X
C@ STY ,U
 LDA LINEWIDE
 LEAU A,U
 DEC ,S
 BNE B@
 LDA B,X get display mode
 CMPA #1
 BLE F@
 EORA #1 if >1 flip it once more
 STA B,X
F@ PULS A
 LDY #$FC01 display bottom of box
 STY ,U
 PULS U
 LEAU 2,U move over to next box
 INCB
 CMPB #8
 BNE A@
*Now display voice numbers in each box
 LDU #80 put voice numbers into boxes
 LDA #'1 ASCII "1"
D@ PSHS D
 LDB #EOR set "EOR/THIN" display mode
 STB TMODE
 SUBA #'1
 LDA A,X get display mode
 CMPA #2 check for halftone
 BNE E@
 CLR TMODE
E@ PULS D
 LBSR TEXT
 LEAU 1,U move to next position
 INCA  increment voice number
 CMPA #'9
 BNE D@
 PULS D,X,Y,U,PC

*DSPNOT - Display note
*ENTRY: A=NVALU, B=VPOS; HPOS set up
* X indirect points to code
*
*DSPFLAG - bits used to control display
*Bit 8 - half tone display
DSPFLAG FCB 0
MASK FCB $AA
*
DSPNOT PSHS D,X,Y,U
 TST DSPEDIT
 LBNE Z@
 TSTA  test for options on NVALU
 BPL Q@
 LBSR DSP_OPT
 LBRA I@
Q@ CMPB #40 test VPOS for upper
 LBLO Z@
 CMPB #141 and lower bounds
 LBHI Z@
 LDB #$AA
 STB MASK
 TFR A,B
 ANDB #$78 keep status bits
 ORB DSPFLAG
 STB DSPFLAG
 ANDA #7 discard status bits
 BITB #RESTBIT test for rest
 BEQ G@
 ADDA #8
 BRA L@
G@ TST NATURAL
 BEQ M@
 DEC ACCIDNTL
 LDU #NATDAT
 BRA L@
M@ TST FLAT
 BEQ K@
 LDU #FLATDT point to flat data
 DEC ACCIDNTL
 BRA L@
K@ TST SHARP
 BEQ L@
 LDU #SHRPDT
 DEC ACCIDNTL
L@ DECA  decrement NVALU
 CMPA #8
 BLO H@
 DECA
H@ LSLA  multiply NVALU by 2
 LDX #NOTTAB point to table of addresses
 LDX A,X point to note data
 LDA 1,S get VPOS
 LDB HPOS
 LBSR CURCAL
 TFR D,Y Y points to screen
 LDB ,X+ get number of words to display
B@ PSHS B
 LDD ,X++
 TST ACCIDNTL
 BEQ J@
 ORA ,U+
J@ COMA
 COMB
 TST DSPFLAG check for halftone display
 BPL C@
 ORA MASK
 ORB MASK
 COM MASK
C@ ANDA ,Y
 ANDB 1,Y
 STD ,Y
 LDB LINEWIDE
 NEGB
 LEAY B,Y
 PULS B
 DECB
 BNE B@
 LDD ,S restore NVALU and VPOS
 LDA DSPFLAG
 BITA #DOTBIT check for dotted note
 BEQ P@
 LDA 1,S move VPOS into A
 LDB HPOS calculate display position
 LBSR CURCAL
 SUBD #96
 TFR D,X
 LDD #$FFF9
 ANDA ,X
 ANDB 1,X
 STD ,X
 LDB LINEWIDE
 ABX
 LDD #$FFF9
 ANDA ,X
 ANDB 1,X
 STD ,X
P@ LDA DSPFLAG
 BITA #TRIPBIT check for triplet
 BEQ R@
 LDX #TRIPDAT
 LDA 1,S move VPOS into A
 LDB HPOS calculate display position
 LBSR CURCAL
 SUBD #447
 TFR D,Y Y points to display
 BSR DSPMOD display tie
R@ LDA DSPFLAG
 BITA #TIEBIT check for tie
 BEQ A@
 LDX #TIEDAT
 LDA 1,S move VPOS into A
 LDB HPOS calculate display position
 LBSR CURCAL
 ADDD #64
 TFR D,Y Y points to display
 BSR DSPMOD display tie
A@ LDD ,S restore NVALU and VPOS
 BITA #RESTBIT if >8 then rest, no need
 BNE I@ for ledger lines
 TFR B,A
 CMPA #$36 check for ledger lines
 BHI E@ value of high a
 LDA #$36
D@ BSR WRTLEG
 SUBA #6 move up a line
 CMPA 1,S
 BHS D@
 BRA I@
E@ CMPA #$7E value of low e
 BLO I@
 LDA #$7E
F@ BSR WRTLEG
 ADDA #6 move down a line
 CMPA 1,S
 BLS F@
I@ CLR DSPFLAG
 CLR SHARP
 CLR FLAT
 CLR NATURAL
 CLR ACCIDNTL
Z@ PULS D,X,Y,U,PC
*
WRTLEG PSHS D write ledger lines
 SUBA #2 calculate address
 LDB HPOS
 LBSR CURCAL
 SUBB LINEWIDE
 SBCA #0
 TFR D,Y
 LDD #$C007 write line
 ANDA ,Y
 ANDB 1,Y
 STD ,Y
 PULS D,PC

*DSPMOD - display modifier (tie, triplet)
*
DSPMOD PSHS D
 LDB ,X+ get # of byte pairs
 PSHS B put counter on stack
A@ LDD ,X++ get display word
 TST DSPFLAG test for half tone display
 BPL B@
 ORA MASK
 ORB MASK
 COM MASK
B@ ANDA -1,Y
 ANDB ,Y
 STD -1,Y put on display
 LDA LINEWIDE
 LEAY A,Y move to next display line down
 DEC ,S done yet?
 BNE A@
 LEAS 1,S restore stack
 PULS D,PC
