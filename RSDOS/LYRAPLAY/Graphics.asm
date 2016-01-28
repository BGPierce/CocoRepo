* TITL1 "GRAPHICS/TXT"
*************************************************
* GRAPHICS/TXT: INCLUDE FILE FOR LYRABOX
* Last update: 12-18-86
*************************************************

*Module to set graphics mode
*It is assumed that on first entry,
* text mode is on
*
SCREEN FDB $D000
BUFFER FDB $E800
*
SETGRA STA $FFD3 set offset to $D000.
 STA $FFD1
 STA $FFCD
 STA $FFC8
 TST MONOCHR check for COCO3 monochrome mode
 BEQ A@
 LDA #$F8 set color set 1
 BRA B@
A@ LDA #$F0 set graphics mode to G6R
B@ STA $FF22
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

*Module to write a border around screen
*                                                 
BORDER LDX SCREEN display double line
 LEAX $1500,X near bottom of screen
 BSR D@
 LEAX 32,X
 BSR D@
 LDX SCREEN
 BSR BAR
 PSHS X
 LDX #TOPLIN
 LDU #0
 LDA #FAT+EOR select "FAT EOR" mode
 STA TMODE
A@ LDA ,X+ display top line
 BEQ B@
 JSR TEXT
 BRA A@
B@ PULS X
 LDB #179 now write sides of screen
C@ LDA #$7F
 ANDA ,X
 STA ,X
 LEAX 31,X
 LDA #$FE
 ANDA ,X
 STA ,X+
 DECB
 BNE C@
D@ LDB #32
 CLRA
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

*LINE - write a line across screen
*ENTRY: VPOS in B
*
LINE PSHS D,X
 LDA #32
 MUL
 ADDD SCREEN
 TFR D,X
 LDB #32 bytes/line
A@ CLR ,X+
 DECB
 BNE A@
 PULS D,X,PC

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
TMODE FCB 0 display mode
TEXTADJ FDB 0 offset for line adjust
MASK FCB 0
*
SEL_NOK EQU 9+128 always used as part of a
SEL_OK EQU 1+128 string, so 8th bit set
THIN EQU 0
FAT EQU 1
EOR EQU 2
JAM EQU 4
HALFTONE EQU 8
INVERSE EQU 16
*
TEXT TSTA  check for TMODE
 BPL C@ control character
 ANDA #$7F
 STA TMODE
 RTS
C@ CMPA #32 check for control character
 BHS H@
 RTS
H@ PSHS D,X,Y
 PSHS A save letter to display
 LDA #$55 set MASK
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
 LDB TMODE if TMODE = JAM
 ANDB #JAM clear 2 bytes above
 BEQ I@ and below letter
 PSHS X
 LDA #$FF
 LEAX -2*32,X
 STA ,X
 LEAX 32,X
 STA ,X
 LEAX 9*32,X
 STA ,X
 LEAX 32,X
 STA ,X
 PULS X
I@ PULS A restore ASCII character
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
 LEAY $20,Y move down to next line
 PULS B
 DECB  update counter
 BNE A@
 LEAU 1,U
 PULS D,X,Y,PC

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
 FCB 0,0,0,$30,$30,$10,$20,0 *,
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
 JSR CALADR
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
 JSR CALADR
A@ TFR Y,D
 EORA ,U+ get icon bytes and
 EORB ,U+ invert them
 STD ,X
 LEAX 32,X move to next line
 DEC ,S
 BNE A@
 LEAS 1,S
 PULS D,X,Y,U,PC

