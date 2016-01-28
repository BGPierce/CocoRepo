 TITLE "LYRA"
*************************************************
* LYRA for the Tandy Color Computer
* Copyright (C) 1986-1989 by Lester Hands
* All rights reserved.
* Last update: 12-apr-90
* Last update: 29-JUN-90 modifications (c) R.Gault
**************************************************

*****************
* Define for a Drivewire MIDI version
*
* See the Play.asm code
* It was best to use an HDBDOS ROM routine.
HDBDOS11 SET 0
HDBDOS14 SET 1
VER   SET HDBDOS14

* START MACROS SECTION ***************************
*
* macro for initiating a block of variables local
* to a subroutine. these variables are put on the
* stack after making room for them. each variable
* is declared using the CHAR and INT macros.
 IFEQ 1
LVAR MACRO
SOFFSET SET 0
 ENDM

* terminate a block of local variables. the variable
* LOCAL is the size of the block and is used to
* allocate space on the stack
ENDLVAR MACRO
LOCAL SET SOFFSET
 ENDM

* set up locations on the stack for variables passed
* on the stack. these declarations ALWAYS come after
* declaring local variables.
SVAR MACRO
SOFFSET SET LOCAL+2
 ENDM

* terminate a block of stack variable declarations.
* does nothing at this point
ENDSVAR MACRO
 ENDM

* a macro for use in declaring "structures".
STRUCT MACRO
|0 SET 0
SOFFSET SET 0
 ENDM

ENDSTR MACRO
 ENDM

* a macro used with structure, local, or stack variables
* variable length
CHAR MACRO
|0 SET SOFFSET
SOFFSET SET SOFFSET+|1
 ENDM

BYTE MACRO
|0 SET SOFFSET
SOFFSET SET SOFFSET+1
 ENDM

* a macro used with structure, local, or stack variables
* two bytes long
INT MACRO
|0 SET SOFFSET
SOFFSET SET SOFFSET+2
 ENDM

PTR MACRO  same as INT, used as a pointer
|0 SET SOFFSET
SOFFSET SET SOFFSET+2
 ENDM

* Macros to simulate "C" function calls

CALL1 MACRO  1 parameter is a word
 LDD |1
 PSHS D
 LBSR |0
 LEAS 2,S
 ENDM

CALL2 MACRO  2 word parameters
 LDD |2
 PSHS D
 LDD |1
 PSHS D
 LBSR |0
 LEAS 4,S
 ENDM

CALL3 MACRO
 LDD |3
 PSHS D
 LDD |2
 PSHS D
 LDD |1
 PSHS D
 LBSR |0
 LEAS 4,S
 ENDM

* Macro to facilitate converting a relative to absolute
* pointer. Pointer is at a given offset from X.

CABS MACRO
 LEAX |0,X
 PSHS D
 LDD ,X
 LEAX D,X
 PULS D
 ENDM
 ENDC
*
* END OF MACROS SECTION ***************************
* REPLACEMENT FOR MACROS
	ORG	0
L_VCNT	RMB	1	BYTE
L_OFFS	RMB	1	BYTE
L_BST	RMB	2	POINTER
L_BEN	RMB	2	POINTER
L_EPTR	RMB	2	POINTER
LOCAL	EQU	*

	ORG	0
L_MODE	RMB	1	BYTE
S_MID	RMB	2	INTEGER
LOCAL2	EQU	*

DEMO EQU 1 not a demo version if =1
ERRCHK EQU 0 omit error checking if =1
DEBUGFL EQU 1 do not include debugging if =1

VERSION EQU '2
REVISION EQU '8
* COND VER=DW4
REVISN2 EQU '8
* ENDC
* COND VER=STOCK
*REVISN2 EQU '6
* ENDC
*
RESTBIT EQU $08 modifiers for NVALU
TRIPBIT EQU $10
TIEBIT EQU $20
DOTBIT EQU $40
*
FLATBIT EQU $80 modifiers for pitch code
SHARPBIT EQU $40

BYTE_FL EQU $80 MIDI filter bit definitions
CHAN_FL EQU $40
INST_FL EQU $20
VOL_FL EQU $10
EVNT_FL EQU $08

RGBDRMAX EQU $150 contains max drive # in RGB DOS

SLOW EQU $FFD8 clock speed hardware
FAST EQU $FFD9 addresses
ROM_ON EQU $FFDE
ROM_OFF EQU $FFDF

LFTARROW EQU 8 cursor key values
RGTARROW EQU 9
DWNARROW EQU 10
UPARROW EQU 94
SHFTUP EQU 95
SHFTDOWN EQU 91
SHFTRGHT EQU 93
SHFTLEFT EQU 21

 ORG $182
 JMP START

 ORG $0E00

*DEFAULT VALUES
SERIAL1 FCC "0000" space for serial number
MUPORT FDB $FF20 address of alternate music port
MUSTART FDB PLAY address of play routine
 FDB TVMENU address of pulldown menu item
CMSTAT FDB $FF6E ACIA control/status register
CMDATA FDB $FF6F ACIA data register
SYM12 FCB 0 >0 if Symphony 12 active
NOTE_ONV FDB 0 Symphony 12 patch
 FDB MIDIPLAY
 FDB 0 addr. of routine to set Sym. 12 up

* These get changed by program
STARTUP FCB 0
STYPE FCB 0 screen type
COCO3 FCB 1 =0 if CoCo 3
DOSVER FCB 0 DOS version =1 if 1.1

 ORG $0F00
STACK EQU *-1

*SINE must start on page break!
*
SINE FCB $11,$11,$11,$11
 FCB $14,$14,$14,$14
 FCB $18,$18,$18,$18
 FCB $1A,$1A,$1A,$1A
 FCB $1C,$1C,$1C,$1C
 FCB $1D,$1D,$1D,$1D
 FCB $1E,$1E,$1E,$1E
 FCB $1E,$1E,$1E,$1E
 FCB $1D,$1D,$1D,$1D
 FCB $1C,$1C,$1C,$1C
 FCB $1A,$1A,$1A,$1A
 FCB $19,$19,$19,$19
 FCB $18,$18,$18,$18
 FCB $17,$17,$17,$17
 FCB $17,$17,$17,$17
 FCB $17,$17,$17,$17
 FCB $17,$17,$17,$17
 FCB $17,$17,$17,$17
 FCB $17,$17,$17,$17
 FCB $17,$17,$17,$17
 FCB $16,$16,$16,$16
 FCB $14,$14,$14,$14
 FCB $13,$13,$13,$13
 FCB $11,$11,$11,$11
 FCB $F,$F,$F,$F
 FCB $E,$E,$E,$E
 FCB $C,$C,$C,$C
 FCB $C,$C,$C,$C
 FCB $C,$C,$C,$C
 FCB $C,$C,$C,$C
 FCB $D,$D,$D,$D
 FCB $F,$F,$F,$F
 FCB $11,$11,$11,$11
 FCB $13,$13,$13,$13
 FCB $14,$14,$14,$14
 FCB $16,$16,$16,$16
 FCB $16,$16,$16,$16
 FCB $16,$16,$16,$16
 FCB $15,$15,$15,$15
 FCB $14,$14,$14,$14
 FCB $12,$12,$12,$12
 FCB $11,$11,$11,$11
 FCB $F,$F,$F,$F
 FCB $D,$D,$D,$D
 FCB $C,$C,$C,$C
 FCB $B,$B,$B,$B
 FCB $B,$B,$B,$B
 FCB $A,$A,$A,$A
 FCB $A,$A,$A,$A
 FCB $A,$A,$A,$A
 FCB $A,$A,$A,$A
 FCB $A,$A,$A,$A
 FCB $9,$9,$9,$9
 FCB $9,$9,$9,$9
 FCB $7,$7,$7,$7
 FCB $6,$6,$6,$6
 FCB $5,$5,$5,$5
 FCB $4,$4,$4,$4
 FCB $4,$4,$4,$4
 FCB $4,$4,$4,$4
 FCB $6,$6,$6,$6
 FCB $8,$8,$8,$8
 FCB $A,$A,$A,$A
 FCB $E,$E,$E,$E


START CLR $71
* MOD May 14,1990 test for Coco3 and do CMP Width32 if yes
* R.Gault
 LDX $C00A DOS vector in RSDOS
 CMPX #$D8D0
 BEQ J@
 LDA #3 no it's a standard DOS
 STA RGBDRMAX only 4 drives allowed
J@ LDX $FFFE Reset vector
 CMPX #$8C1B = Coco3
 BNE C@
 CLR COCO3
 JSR $E606 CMP default colors
 JSR $F652 WIDTH 32
 ORCC #$50
 LDA #$35	This is critical to preserve RGBDOS offsets
 STA $FFA2
 LDX #$8000 copy ROMS
 LDY #$4000
 LBSR MOVEMEM
 LDA #$36
 STA $FFA2
 LDX #$A000
 LDY #$4000
 LBSR MOVEMEM
 LDA #$37
 STA $FFA2
 LDX #$C000
 LDY #$4000
 LBSR MOVEMEM
 LDA #$3A
 STA $FFA2
 ANDCC #$AF
C@ EQU *
* EMOD
*---CONDITIONAL START
 IFNE DEMO
 LDX #a@
B@ LDA ,X+
 BEQ G@
 JSR [$A002]
 BRA B@
G@ JSR [$A000]
 CMPA #'1
 BLO G@
 CMPA #'2
 BHI G@
A@ STA STYPE
 ENDC
*---CONDITIONAL END
I@ CLRA
 LDB $C003 check for DOS version
 CMPB #4
 BEQ E@
 LDA #1
E@ STA DOSVER
 CLR $FF40 turn disk motor off
* check for CoCo MIDI/Colorchestra
*
* MOD R.Gault
*== QUESTIONABLE CODE ==
 IFNE 0
 LDA #3
 STA $FF66
 STA $FF6E
 LDD #$FF6E set default-CoCo MIDI
 STD CMSTAT
 INCB
 STD CMDATA This code only works
 LDX #$FF66 if pullup resistors
 LDD ,X are in place. New model
 CMPD #$FFFF MPIs won't work.
 BEQ H@
 TSTA
 BNE H@
 STX CMSTAT ORCH90 PACK
 LEAX 1,X
 STX CMDATA      "
 ENDC
*== END CONDITIONAL ==
* EMOD
H@ LDA #3 initialize ACIA
 STA [CMSTAT] master reset
 LDA #$15
 STA [CMSTAT] 8 bits, no par, 1 stop bit
* MOD May 14,1990 remove Coco3 test; done above
* R.Gault
* EMOD
 ORCC #$50 disable interrupts
 TST COCO3
 BNE F@
 STA FAST
F@ STA ROM_OFF turn 64K RAM on
 LDX #$18E point to error vector
 LDA #$7E JMP opcode
 STA ,X+
 LDY #DOSERR set up new error vector
 STY ,X
*---CONDITIONAL START
 IFEQ DEBUGFL
 STA $0106 set up SWI vector
 LDX #DEBUG for debugging
 STX $0107
 ENDC
*---CONDITIONAL END
 LBSR PCLS
 LBSR SETGRA
 LBSR COPYR display copyright message
*        LDA     $FF6E         check for CoCo MIDI
*        TSTA                  see above R.Gault
*        BMI     RESET
*        LBSR    SELPORT
RESET NOP  (entry point on reset)
 BSR WRITSCRN
 LDA #1
 STA STARTUP
 LBSR RSETPTR
 LBSR ALL_OFF turn off all notes
RESTART EQU *
START2 LDS #STACK entry after error point
 TST COCO3
 BNE D@
 STA FAST
D@ LBRA MENU
*
a@ FCB 13,13
 FCC "ENTER SCREEN TYPE:"
 FCB 13
 FCC "1=BUFF"
 FCB 13
 FCC "2=GREEN"
 FCB 0

*WRITSCRN - do a complete screen display
*
WRITSCRN PSHS D,X,Y,U
 TST STARTUP
 BNE A@
 LDX SCREEN
 PSHS X
 LEAX -$1800,X set up pseudo screen
 STX SCREEN
A@ LBSR PCLS
 LBSR WRTSTF
 LBSR DSPMUS
 TST STARTUP
 BNE Z@
 LDX ,S
 LEAX -$1800,X
 PSHS X
 LDA #16 # words/display line
 PSHS A
 LDY 3,S restore pointer to acutal screen
 LEAY $0C00,Y middle of screen
 LEAX $0C00,X middle of pseudo screen
 PSHS X,Y
 TFR S,U
 PSHU X,Y
B@ DEC 4,S check line counter
 BNE D@
 LDX #$0800 delay
C@ LEAX -1,X
 BNE C@
 LDA #16
 STA 4,S
D@ PULS X,Y
 LDD ,X++
 STD ,Y++
 PSHS X,Y
 PULU X,Y
 LDD ,--X
 STD ,--Y
 PSHU X,Y
 CMPX 5,S done yet?
 BNE B@
 LEAS 7,S clean up stack
 PULS X
 STX SCREEN
Z@ PULS D,X,Y,U,PC

*INIT - initialize music code pointers (erase music)
*
INIT PSHS D,X,Y,U
 LDU #V1 set up pointers to music code
 LDX #DSP_STRT
 LDY #VOI_PTR
 LDB #8 voice counter
 PSHS B
 CLRA
 CLRB
A@ STU ,X++
 STU ,Y++
 STD ,U++
 DEC ,S
 BNE A@
 LEAS 1,S throw away counter
 STU INSTPTR
 STU ENDPTR
 CLR CLICK
 LDX #FILENAME clear out filename
 LDA #32
 LDB #8
B@ STA ,X+
 DECB
 BNE B@
 JSR BLK_RSET
 LDA #SEL_NOK disable SAVE command
 STA SAVEOK (no filename)
CLRCNT LDA #SEL_OK
 STA CHNGTSIG
 LDX #CNT_STRT clear out counters
 LDY #VOI_CNT
 LDB #8 voice counter
 PSHS B
 CLRA
 CLRB
C@ STB ,X+
 STD ,Y++
 DEC ,S
 BNE C@
 LEAS 1,S throw away counter
 STD BNUM_ST
 STD MEA_STRT
 PULS D,X,Y,U,PC

*RSETPTR - reset music pointers to start of music
*
RSETPTR PSHS D,X,Y,U
 LDX #VOI_PTR
 LDY #DSP_STRT
 LDB #16
 JSR MOVEDATA
 BRA CLRCNT

*MENU - Main module that calls other menus
*Exit from main program indicated by setting
* carry flag to 1.
*
MENU JSR DISPCURS
* AUG 21,1990
*        LDA     #$FE          send active sensing
*        LDA     #$F8          SEND TIMING CLOCK OCT.3,1990
*        LBSR    SENDMIDI
* EMOD
*---CONDITIONAL START
 IFEQ DEBUGFL
 LDA #$FB test for BREAK
 STA $FF02
 LDA $FF00
 ORA #$80
 CMPA #$BF
 BNE H@
 SWI
 ENDC
*---CONDITIONAL END
H@ LDA VPOS test vertical position
 CMPA #6 pull-down menu area
 BHS A@
 JSR PULDOW handle pulldown menus
 BRA MENU
A@ CMPA #12 check for voice boxes
 BLO F@ VPOS>12 and <24
 CMPA #24
 BHI B@ HPOS>15 and <30
 LDB HPOS
 CMPB #15
 BLO F@
 CMPB #30
 BHI F@
 JSR SELVOI
 BRA F@
B@ CMPA #40 is cursor in staff
 BLS F@ menu area?
 CMPA #NOTES-12
 BHS C@
 LDA HPOS check horizontal
 CMPA #3 bounds
 BLE F@
 CMPA #30
 BHS F@
 JSR EDITNOTE edit/enter notes
 BRA F@
C@ CMPA #NOTES-10 check for cursor
 BLO F@ movement squares
 CMPA #NOTES
 BHI E@
 LDA HPOS
 CMPA #29
 BHI D@
 CMPA #2
 BHS G@
D@ JSR MOVECURS
 BRA F@
G@ JSR BARMOVE
 BRA F@
E@ JSR SELNOT
F@ CLR CLICK
 CLR SHARP
 CLR FLAT
 BRA MENU

*SELNOT - select note/rest from note menu
*
NVALU FCB 3 note length selected (1-8)
LASNOT FDB 0 address of last note flipped
*
SELNOT PSHS D,X,Y
 TST COPYFLAG
 BNE Z@
 LDA HPOS check for corners
 CMPA #2
 BLO Z@
 CMPA #29
 BHI Z@
 JSR CURREF erase cursor
 CLRA  cancel normal cursor erase
 CLRB
 STD OLDCDP
A@ JSR READMOUS
 LDA HPOS check for corners
 CMPA #2
 BLO G@
 CMPA #29
 BHI G@
 LDA #NOTES+3 check vertical position
 CMPA VPOS
 BHI G@
 ADDA #7
 LDB #32 calculate display address
 MUL
 ADDD SCREEN
 ADDD #$60
 ADDB HPOS
 ANDB #$FE
 CMPD LASNOT has note position changed?
 BEQ C@ wait for change if not
 TST LASNOT see if a prior note has been selected
 BEQ B@
 BSR FLINOT
B@ STD LASNOT
 BSR FLINOT
C@ JSR REABUT
 TST DRAG check for note and rest menu
 BEQ A@
D@ JSR REABUT
 TST DRAG
 BNE D@
 LDA HPOS
 PSHS A keep raw note value
 LSRA
 CMPA #8 check for rests
 BLO H@
 INCA
H@ STA NVALU save note value
 PULS B restore raw note value
 SUBB #2
 ANDB #$FE
 LDX #NOTTAB point to note data
 LDD B,X
F@ STD STFCUR save pointer in staff cursor pointer
 BRA A@
G@ JSR FLINOT
 CLR LASNOT
Z@ PULS D,X,Y,PC

FLINOT PSHS D,X
 LDX LASNOT flip a note
 LEAX 96,X
 LDB #$16 number of 2-bytes
A@ PSHS B
 LDD ,X
 EORA #$7F
 EORB #$FE
 STD ,X
 LDB #32
 ABX  move down 1 line
 PULS B
 DECB
 BNE A@
 PULS D,X,PC

*DISPCURS - Module to control the cursor
*
HPOS FDB 2 horizontal position
VPOS FDB 84 vertical position
HPOSH FCB 0 "half" horizontal position flag
*
CURPTR FDB CURDAT pointer to cursor data
STFCUR FDB NOT4 cursor when in staff area
MENCUR FDB CURDAT cursor when in menu area
CURDAT FCB 7 number of words in cursor
 FDB $80,$1C0,$3E0
 FDB $770,$3E0,$1C0
 FDB $80
*
CPOINTER FCB 10
 FDB $0060,$00E0,$01C0
 FDB $0380,$4700,$6E00
 FDB $7C00,$7800,$7C00
 FDB $7E00
*
CURBUF RZB 38 refresh buffer
*
OLDCDP FDB 0 previous CURDAT value
OLDVPS FCB 0 previous VPOS value
OLDHPS FCB 0 previous HPOS value
*
DISPCURS LBSR READMOUS update HPOS and VPOS
 LDA VPOS
 LDB HPOS
 CMPA #40 set up cursor depending
 BLS E@ on the area of the screen
 LDB HPOS
 CMPA #NOTES-12 see if we are in staff menu
 BHS E@
 CMPB #3
 BLE E@
 CMPB #30
 BHS E@
 CLRA
 LDX STFCUR
 PSHS B
 CLRB
 TST VOICE
 BPL G@
 LDB #$AA
G@ STB CMASK
 PULS B
 BRA A@
E@ LDA #$FF erase note name
 LDX MENCUR change cursor
A@ PSHS A check for rest NVALU
 LDA NVALU
 CMPA #9
 PULS A
 BLO F@
 LDA #$FF
F@ STX CURPTR
 LBSR NOTNAM
 LDA VPOS
 CMPA OLDVPS see if position has changed
 BNE B@
 CMPB OLDHPS
 BNE B@
 CMPX OLDCDP see if cursor data has changed
 BEQ D@
B@ LDY OLDCDP see if this is the first time called
 BEQ C@ (if so, no cursor to erase!)
 LBSR CURREF erase old cursor
C@ STA OLDVPS update "OLD" variables
 STB OLDHPS
 STX OLDCDP
 PSHS A
 LDA #1
 STA CSHIFT
 STA SHADOW
 PULS A
 BSR CURSOR
 CLR CSHIFT
D@ JMP REABUT

*Display multipurpose cursor
*ENTRY: A=VPOS, B=HPOS, HPOSH set
* X=pointer to cursor data
* CShift: >0 if cursor to be shifted left 1 bit
*EXIT: registers D,X,Y,U preserved
*
CSHIFT FDB 0 bit shift flag
SHADOW FCB 0 >0 when shadow on cursor
CMASK FCB 0 mask for when VOICE=$FF
*
CURSOR PSHS D,X,Y,U
 LBSR CURCAL
 TFR D,Y
 LDU CURBUF point to cursor refresh stack
 LDA HPOSH save half byte flag on stack
 STA ,U+
 STY ,U++ save starting address
 LDA ,X+ get cursor length
 STA ,U+ save length on stack
A@ PSHS A display/erase cursor
 LDD ,Y get screen data
 STD ,U++ save it in buffer
 LDD ,X++ get cursor data
 TST CMASK
 BEQ H@
 ANDA CMASK add mask
 ANDB CMASK
 COM CMASK
H@ TST CSHIFT
 BEQ B@
 LSLB
 ROLA
B@ TST HPOSH test half byte flag
 BEQ D@
 PSHS X,D
 LDA 2,Y
 STA ,U+
 CLR 2,S prepare shift byte
 LDB #4 and counter in stack
 STB 3,S
 PULS D
C@ LSRA
 RORB
 ROR ,S
 DEC 1,S
 BNE C@
 COM ,S
D@ TST SHADOW
 BEQ F@
 PSHS D make shadow
 LSLA
 ROLB
 ORA ,S
 ORB 1,S
 EORA ,S
 EORB 1,S
 PSHS D
 LDD 2,S
F@ COMA
 COMB
 ANDA ,Y
 ANDB 1,Y
 TST SHADOW
 BEQ G@
 ORA ,S+
 ORB ,S+
 LEAS 2,S
G@ STD ,Y
 TST HPOSH
 BEQ E@
 PULS D
 ANDA 2,Y
 STA 2,Y
E@ LEAY -32,Y
 PULS A
 DECA
 BNE A@
 CLR SHADOW
 CLR CMASK
 PULS D,X,Y,U,PC

*CURCAL requires HPOS in B, VPOS in A
*Returns bottom of cursor address in D
*
CURCAL PSHS B calculate cursor address
 LDB #32
 MUL
 ADDB ,S+
 ADDD SCREEN
 ADDD #416
 RTS

*CURREF - Cursor refresh: restore memory altered by cursor
*ENTRY: cursor saved in BUFFER
*EXIT: registers D,X,Y,U preserved
*
CURREF PSHS D,X,Y,U
 LDX CURBUF point to cursor refresh stack
 LDA ,X+ get HPOSH flag
 RORA  rotate into carry flag
 LDY ,X++ get address of bottom of cursor
 BEQ Z@ *NEW
 LDU #0 *NEW
 STU -2,X *NEW
 LDB ,X+ get number of words to refresh
A@ LDU ,X++
 STU ,Y
 BCC B@
 LDA ,X+
 STA 2,Y
B@ LEAY -32,Y
 DECB
 BNE A@
Z@ PULS D,X,Y,U,PC

*REABUT - Read mouse "fire" button
*EXIT: DRAG=$FF if button on
* CLICK=$FF on ON/OFF transition
*
DRAG FCB 0
CLICK FCB 0
*
REABUT PSHS D
 LDA #$FF read joystick button
 STA $FF02
 LDA $FF00
 BITA #1 bit 1=0 if button on
 BNE A@
 LDA #$FF
 STA DRAG
 BRA Z@
A@ TST DRAG
 BEQ Z@
 LDA #$FF
 STA CLICK
 JSR KEYCLICK
 TST DW4FLG
 BNE Y@
 TST PORTFL
 BNE Y@
* MOD Oct. 1990 R.Gault change wakeup call
 LDA #$F8 send clock timing
*        LDA     #$FE          send "active sensing"
* EMOD
 LBSR SENDMIDI MIDI message
 LDD #$2000	This was $1000 but should not matter. Interval.
B@ SUBD #1
 BNE B@
Y@ CLR DRAG
Z@ PULS D,PC

*KEYCLICK - produce a click sound when mouse is clicked
*
KEYCLICK PSHS D,X
 LDB #$60
 BRA A@
BEEP PSHS D,X
 LDB #$FF
A@ LDX #$FF00
 LDA 1,X turn on D/A sound
 ANDA #$F7
 STA 1,X
 LDA 3,X
 ANDA #$F7
 STA 3,X
 LDA #$3C
 STA $23,X
 LDA #$E3 click on
 STA $20,X
 LDD #$1000
B@ SUBD #1 delay
 BNE B@
 LDA #3 click off
 STA $20,X
 LDA #$34 turn off sound
 STA $23,X
 LDA #8
 ORA 1,X
 STA 1,X
 LDA #8
 ORA 3,X
 STA 3,X
 PULS D,X,PC

*READMOUS - Read position of mouse and update
* HPOS and VPOS
*
READMOUS PSHS D,Y,U
 LDA $FF23 MOUSE INPUT
 LDB $FF20
 TFR D,Y
 ANDA #$F7
 STA $FF23
 LDA $FF01
 LDB $FF03
 TFR D,U
 ORA #8
 STA $FF01
 ANDB #$F7
 STB $FF03
 BSR JOYIN
 ADDB a@ average with last value
 RORB
 STB a@
 CMPB #56
 BLE A@
 LDB #56
A@ LDA #3
 MUL
 STB VPOS
 LDA $FF01
 ANDA #$F7
 STA $FF01
 BSR JOYIN
 ADDB b@ average with last value
 RORB
 STB b@
 CLR HPOSH
 LSRB
 PSHS CC
 BEQ B@
 DECB
B@ STB HPOS
 PULS CC
 ROL HPOSH set half byte flag
 TFR U,D
 STB $FF03
 STA $FF01
 TFR Y,D
 STB $FF20
 STA $FF23
Z@ PULS D,Y,U,PC
a@ FCB 0
b@ FCB 0

*JOYIN - read the right joystick port
* calling routine must set correct MUX select
* returns value in register B
*
JOYIN LDD #$4080
A@ PSHS A
 ORB #2
 STB $FF20
 EORB #2
 LDA $FF00
 BMI B@
 SUBB ,S
 BRA C@
B@ ADDB ,S
C@ PULS A
 LSRA
 CMPA #1
 BNE A@
 LSRB
 LSRB
 RTS

*NOTNAM - write note name of VPOS above staff
*ENTRY: if A=0 display note name
* if A<>0 then erase note name
*
NOTNAMF FCB $5A previous value of A on entry
*
NOTNAM PSHS D,U
 LDB #JAM set JAM/THIN mode
 STB TMODE
 LDU #$81
 TSTA
 BEQ A@
 CMPA NOTNAMF
 BEQ Z@
 LDD #$2003
F@ JSR TEXT erase 3 bytes
 DECB
 BNE F@
 BRA Z@
A@ LDB VPOS convert screen position
 JSR CHKKSIG check for accidentals
 TFR B,A
 JSR CNVDIS
B@ PSHS B
 ADDA #'A convert to ASCII
 JSR TEXT
 TST DSHARP
 BEQ C@
 LDA #'#
 BRA D@
C@ TST DFLAT
 BEQ E@
 LDA #'b
D@ JSR TEXT
E@ PULS A restore octave counter
 ADDA #'0 convert to ASCII
 JSR TEXT
 LDA #32
 JSR TEXT
Z@ PULS D,U
 STA NOTNAMF
 RTS

*Convert VPOS to note of scale code
*ENTRY: A=VPOS
*EXIT: A=note of scale B=octave
* if A=0 then note="A"
* if A=1 then note="B"
* if B=1 then octave=1
*
CNVDIS LDB #3
 STB DIV1+1
 BSR DIV
 LDA #7
 STA DIV1+1
 ADDB #2
 EXG B,A
 BSR DIV
 COMA
 NEGB
 ADDB #7
 RTS
DIV CLRB
DIV1 SUBA #7
 BCS A@
 INCB
 BRA DIV1
A@ RTS

*SELVOI - select current voice
*
SELVOI PSHS D,X,Y,U
 TST CLICK
 BEQ E@
 LDA HPOS
 SUBA #15
 LSRA
 LDX #DSPMODE set display type
 LDB A,X
 INCB
 CMPB #2
 BLE A@
 CLRB
A@ STB A,X
D@ JSR DSPMUS
 JSR VOIBOX
E@ PULS D,X,Y,U,PC

*CALADR - calculates display address from VPOS,HPOS
*ENTRY: X=VPOS,HPOS
*EXIT:  X is display pointer
*
CALADR PSHS D
 TFR X,D
 PSHS B save HPOS
 LDB LINEWIDE
 MUL
 ADDB ,S+
 ADCA #0
 ADDD SCREEN
 TFR D,X
 PULS D,PC

*CONVNVAL - convert NVALU to actual note length
*ENTRY: NVALU in register A, pitch in B
* recognizes rests, dotted & triplet notes
*EXIT: actual length in A
* B=0 if rest, else pitch
*
CONVNVAL PSHS B,X
 TSTA
 BMI Z@ exit if not a note
 BEQ Z@ (>0, <128)
 TFR A,B
 ANDA #$07 mask out modifier bits
 ANDB #$F8 B keeps modifier bits
 BITB #TRIPBIT check for triplet
 BNE A@
 LDX #NOTVAL
 BRA B@
A@ LDX #TRIPVAL
B@ DECA
 LDA A,X get actual note value
 BITB #DOTBIT check dotted note flag
 BEQ C@
 PSHS A
 LSRA  increase note value if set
 ADDA ,S+
C@ BITB #RESTBIT check for rest
 BEQ Z@
 CLR ,S
Z@ PULS B,X,PC

*NOTVAL - table of actual note lengths in order
*of their display codes
*
NOTVAL FCB 192 whole
 FCB 96 half
 FCB 48 quarter
 FCB 24 8th
 FCB 12 16th
 FCB 6 32nd
 FCB 3 64th

*TRIPVAL - same as NOTVAL, except triplet equivalents
*
TRIPVAL FCB 128 whole
 FCB 64 half
 FCB 32 quarter
 FCB 16 8th
 FCB 8 16th
 FCB 4 32nd
 FCB 2 64th

*ALLNOTON - sets all parts to halftone
*
ALLNOTON PSHS A,X
 LDX #DSPMODE
 LDA #2
A@ STA ,X+
 CMPX #DSPMODE+8
 BNE A@
 DEC DSPMODE set voice 1 to 1
 CLR VOICE
 JSR DSPMUS
 JSR VOIBOX
 PULS A,X,PC

*DSPFNAME - display current filename on screen
*
*DSPFNAME LDX     #FILEDRIV     put filename on screen
*        LDA     $95A          get default drive #
*        ADDA    #'0
*        STA     ,X

* MOD May 17,1990 R.Gault Hard drive patch for numbers
* up to 999
DSPFNAME LDA $95A get default drive #
 LDX #FILEDRIV
 PSHS Y
 LDY #FILEDRIV
 JSR HDDRIVE convert for filedrive
 PULS Y
 LDB #12 number of letters; was 10
* EMOD
 LDA #JAM
 STA TMODE set THIN/JAM mode
 LDU #65 screen position
A@ LDA ,X+
 JSR TEXT
 DECB
 BNE A@
 RTS

*BINASC - convert binary number in D to decimal ASCII
*ENTRY: data in D, X points to output string
*EXIT: ASCII decimal string at string pointed to by X
* output string is 5 bytes long
*
BINASC PSHS D,X,Y
 LDA #'0 fill string with 0s
 LDB #4
A@ STA B,X
 DECB
 BPL A@
 LDD ,S
 LDY #a@ point to powers of 10
B@ SUBD ,Y count number of times
 BMI C@ this power of 10 can be
 INC ,X subtracted from value
 BRA B@
C@ ADDD ,Y
 LEAX 1,X move to next digit
 LEAY 2,Y move to next power of 10
 CMPY #a@+8 see if last power has
 BNE B@ been done yet
 ADDB #'0 convert to ASCII
 STB ,X remainder is 1's count
 PULS D,X,Y,PC return
a@ FDB 10000 powers of 10
 FDB 1000
 FDB 100
 FDB 10

*ASCBIN - convert decimal ASCII to binary
*ENTRY: X points to ASCII string
* B=length of string (1-3)
* Leading blanks are ignored
*EXIT: B contains binary equivalent
*
ASCBIN PSHS B
 ABX  point X to end of string
 CLRA
 CLRB
 PSHS D accumulator
 LDB #1 power of 10
 PSHS B
A@ LDA ,-X get number
 CMPA #32 check for space
 BEQ B@
 SUBA #'0 convert to binary
 LDB ,S get power of 10
 MUL
 ADDD 1,S add to accumulator
 STD 1,S
 LDA ,S make 10*power of ten
 LDB #10
 MUL
 STB ,S
 DEC 3,S check counter
 BNE A@
B@ LDD 1,S get result
 LEAS 4,S
 RTS

*HEXBIN - convert ASCII hex number in D to binary
* byte in A
*
HEXBIN PSHS B
 BSR A@
 LDB #16
 MUL
 PULS A
 BSR A@
 PSHS B
 ADDA ,S+
 RTS
A@ CMPA #32 check for space
 BNE C@ (treat as zero)
 LDA #'0
C@ CMPA #'9+1
 BLO B@
 SUBA #7
B@ SUBA #'0
 RTS

*WAITKEY - wait for any keypress and key off
*
WAITKEY PSHS A,X
 CLR $FF02
A@ LDA $FF00 wait for any keypress
 ANDA #$7F includes buttons
 CMPA #$7F
 BEQ A@
 LDX #$2000 debounce delay
B@ LEAX -1,X
 BNE B@
C@ LDA $FF00 wait for key off
 ANDA #$7F
 CMPA #$7F
 BNE C@
 LDX #$2000 debounce delay
D@ LEAX -1,X
 BNE D@
 PULS A,X,PC

*KEYIN - get keyboard input
*EXIT: register A contains ASCII code (=0 if no keypress)
* lowercase converted to upper.
*
KEYIN STA $FFDE turn on ROMs
 JSR [$A000]
 STA $FFDF turn off ROMs
 RTS

*GETUPC - get uppercase key input
*EXIT: register A contains ASCII code
* does not wait for keypress.
*
GETUPC BSR KEYIN
 CMPA #3
 BEQ Z@
 CMPA #'a
 BLO Z@
 CMPA #'z
 BHI Z@
 SUBA #$20
Z@ RTS

*GETHEX - get hex key input
*EXIT: register A contains ASCII code, waits for keypress
*
GETHEX BSR GETUPC
 TSTA
 BEQ GETHEX
 CMPA #3
 BEQ A@
 CMPA #'0
 BLO GETHEX
 CMPA #'F
 BHI GETHEX
 CMPA #'9
 BLS A@
 CMPA #'A
 BHS A@
 BRA GETHEX
A@ RTS

*DIVIDE - divide D by X, dividend in X, remainder in D
*
DIVIDE PSHS X
 LDX #0
A@ LEAX 1,X
 SUBD ,S
 BCC A@
 ADDD ,S++
 LEAX -1,X
 RTS

*MUL2X1 - perform 2x1 multiply
*ENTRY: values in X,B
*EXIT: 3 byte result in B,X
*
MUL2X1 PSHS D,X
 LDA 3,S
 MUL
 STB 3,S
 PSHS A
 CLR ,-S
 LDD 3,S
 MUL
 ADDD ,S++
 STD 1,S
 PULS D,X,PC

*MOVEDATA - move data
*ENTRY: X=from pointer
* Y=to pointer
* B=number of bytes to move
*EXIT: registers preserved
*
MOVEDATA PSHS D,X,Y
A@ LDA ,X+
 STA ,Y+
 DECB
 BNE A@
 PULS D,X,Y,PC

*COPYSTR - copy string from X to Y. String terminates with 0.
*
COPYSTR PSHS A,X,Y
A@ LDA ,X+
 STA ,Y+
 BNE A@
 PULS A,X,Y,PC

*SET_PTRS - check VOI_PTRs, report errors, repair if possible
*
VOI SET 0
*
SET_PTRS PSHS D,X,Y
 *---CONDITIONAL START
 IFEQ 1
 LEAS -1,S make room for stack variables
 LDB #8 number of voices
 STB VOI,S
 LDX #VOI_PTR
 LDD ,X++ test first pointer
 CMPD #V1 (value should be fixed)
 BEQ A@
*        LDD     #V1
*        STD     VOI_PTR       error:
*        BRA     J@            go on to correction
A@ DEC VOI,S
 BEQ B@
 LDY ,X++ get pointer to voice
 TST -1,Y check for end of music marker
 BEQ A@ of previous voice
 BRA J@ error: go to correction
B@ LDB #7
 STB VOI,S
 LDX #VOI_PTR now check to see that
C@ LDD ,X++ pointers go from small to high
 CMPD ,X
 BHS J@ error: goto to correction
 DEC VOI,S
 BNE C@
 LDD ,X see if voice 8 is less
 CMPD ENDPTR than the end pointer
 BLO Z@
 LBSR BEEP
 BRA D@ do not report error (minor)
J@ LBSR REQERRPT
D@ LDX #V1 attempt pointer correction
 LDY #VOI_PTR+2
 LDB #8
 STB VOI,S
F@ CMPX SCREEN
 BLO G@
 LBRA REQERREN
G@ LDD ,X++ look for end of voice
 TSTA
 BNE F@
 TSTB  check for end marker
 BEQ E@ that is only 1 byte
 LEAX -1,X long
 STX ,Y++
 BRA H@
E@ STX ,Y++
H@ DEC VOI,S
 BNE F@
 STX ENDPTR
Z@ LEAS 1,S clean up stack
 ENDC
*---CONDITIONAL END
 PULS D,X,Y,PC

* convert ASCII string pointed to by X to binary;
* return value in D
*
L_X SET 0
L_P10 SET 2
L_ACCUM SET 4
*
ATOI LEAS -6,S
 STX L_X,S
 CLRA
 CLRB
 STD L_ACCUM,S zero accumulator
A@ LDA ,X+ skip any blanks
 CMPA #32
 BEQ A@
B@ CMPA #'0 check for non-numeric
 BLO C@ character
 CMPA #'9
 BHI C@
 LDA ,X+
 BRA B@
C@ LDB #1 set power of 10
E@ STB L_P10,S
 LDA ,-X convert digit
 CMPX L_X,S quit if at start of string
 BLO Z@
 CMPA #32 quit if a space
 BEQ Z@
 SUBA #'0
 LDB L_P10,S
 MUL
 ADDD L_ACCUM,S
 STD L_ACCUM,S
 LDB L_P10,S
 LDA #10
 MUL
 BRA E@
Z@ LDD L_ACCUM,S
 LEAS 6,S
 RTS

MOVEMEM LDD ,X++
 STD ,Y++
 CMPY #$6000
 BNE MOVEMEM
 RTS

 INCLUDE PLAY.ASM
 INCLUDE GRAPHICS.ASM
 INCLUDE DSPMUS.ASM
 INCLUDE BLOCK.ASM
 INCLUDE PULLDOWN.ASM
 INCLUDE DISKIO.ASM
 INCLUDE REQUEST.ASM
 INCLUDE OPTION.ASM
*---CONDITIONAL START
 IFEQ DEBUGFL
 INCLUDE DEBUG.ASM
 ENDC
*---CONDITIONAL END

*Music code - this section is written to disk/tape
*
STARTCOD FCB VERSION
 FCB $5A 		used to identify as LYRA file
KEYSIG FCC "0S" 	key signature
TIMESIG FCC "44" 	time signature
TEMPO FDB 32 		master tempo
DSPMODE FCB 1,0,0,0 	display modes
 FCB 0,0,0,0
VOI_PTR FDB V1 		pointers to voices
 FDB V2
 FDB V3
 FDB V4
 FDB V5
 FDB V6
 FDB V7
 FDB V8
INSTPTR FDB 0 		not used
ENDPTR FDB ENDCODE 	pointer to end of code
MIDINSTM FCC "0:000         "
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
 FCB 0
MIDIDESM FCC "          " 	space for synthesizer description
 FCC "          "
 FCC "        "
 FCB 0
MIDICHAN FCB 0,0,0,0 		MIDI channels assigned
 FCB 0,0,0,0 			to each voice
MIDIVOL FCB 16,32,48,64 	binary values of volumes
 FCB 80,96,112,127 		ordered ppp to fff.
NOTFRACM FCC "8/8 8/8 8/8 8/8"
 FCB 13
 FCC "8/8 8/8 8/8 8/8"
 FCB 0
V1 FDB 0 (blank voices)
V2 FDB 0 "
V3 FDB 0 "
V4 FDB 0 "
V5 FDB 0 "
V6 FDB 0 "
V7 FDB 0 "
V8 FDB 0 "
ENDCODE EQU *

 INCLUDE TITLE.ASM (will be wiped out by music code)

*MSG "START=",START," END=",*
 PAGE
 TITLE "LYRA/TXT"
 END
