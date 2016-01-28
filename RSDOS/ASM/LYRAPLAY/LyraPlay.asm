 *TITL1 "LYRAPLAY/TXT"
*************************************************
*LYRAPLAY for the Tandy Color Computer
*Copyright (C) 1988 by Lester Hands
*All rights reserved.
*Last update: 28-jun-88
*
*Hardware requirements:
*64k RAM
*Mouse (or joystick)
*DOS 1.0 or 1.1 (Radio Shack)
*
*Optional hardware:
*Multipak
**************************************************

VERSION EQU '1
REVISION EQU '0
*
RESTBIT EQU $08 modifiers for NVALU
TRIPBIT EQU $10
TIEBIT EQU $20
DOTBIT EQU $40
*
FLATBIT EQU $80 modifiers for pitch code
SHARPBIT EQU $40

 ORG $182
 JMP START

 ORG $0E00

SERIAL1 FCC "0001" space for serial number
MUPORT FDB $FF20 address of alternate music port
MUSTART FDB 0 address of play routine
 FDB 0 address of pulldown menu item
CMSTAT FDB $FF6E ACIA control/status register
CMDATA FDB $FF6F ACIA data register
SYM12 FCB 0 >0 if Symphony 12 active
NOTE_ONV FDB 0 Symphony 12 patch
 FDB MIDIPLAY
 FDB 0 addr. of routine to set Sym. 12 up

STARTUP FCB 0 flag to indicate first entry
MONOCHR FCB 0 >0 if COCO3 monochrome mode

 RZB 233
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

START CLR $FF02
 LDA $FF00
 ORA #$80
 COMA
 STA MONOCHR,PCR
 BEQ K@
J@ LDA $FF00 wait for key off
 ORA #$80
 CMPA #$FF
 BNE J@
K@ CLRB
 LDA $C003 check DOS version
 CMPA #4 =4 if 1.0
 BEQ E@
 CMPA #8 =8 if 1.1
 BEQ F@
 LEAX a@,PCR DOS not recognized
G@ LDA ,X+
 JSR [$A002]
 TST ,X
 BNE G@
 RTS
F@ ADDB #4 increase offset
E@ STB DOSOFSET,PCR
 ORCC #$50 disable interrupts
 LDX $C000 get ROM id
 STA $FFDF turn 64K RAM on
 PSHS X
 LEAX RESET,PCR set new reset vector
 STX $72
 PULS X
 CMPX #$444B check for disk ROM
 BNE C@
 LBSR DISKHOME
 CLR $FF40 turn disk motor off
C@ LDX #$18E point to error vector
 LDA #$7E JMP opcode
 STA ,X+
 PSHS X
 LEAX DOSERR,PCR set up new error vector
 STX [,S++]
RESET NOP  entry point on reset
 CLR $FF02 check for keypress
 LDA $FF00
 ORA #$80
 CMPA #$FF
 BEQ H@
 CLR $71
 JMP [$FFFE] do cold start if so
H@ ORCC #$50 disable interrupts
 STA $FFDF set all RAM mode
 LEAS STACK,PCR
 LBSR PCLS
 LBSR BORDER
 LBSR GETDIR
 LBSR SETGRA
START2 LEAS STACK,PCR entry after error point
 LDA #$5A check for previous startup
 CMPA STARTUP,PCR
 BEQ D@
 STA STARTUP,PCR
 LBSR COPYR
D@ LBSR DSPDIR
 LBSR MOUSTAT
 LBRA MENU
a@ FCB 13,13
 FCC "RADIO SHACK DOS REQUIRED"
 FCB 13,0

*MENU - Main module that calls other menus
*Exit from main program indicated by setting
* carry flag to 1.
*
MENU JSR DISPCURS
 LDA VPOS test vertical position
 CMPA #6 pull-down menu area
 BHS A@
 JSR PULDOW handle pulldown menus
 BRA MENU
A@ LBSR SELFILE
 CLR CLICK
 BRA MENU

*SETEPTR - set the INSTPTR and ENDPTR pointers
*Not dependent on pointers since starts at code beginning.
*
SETEPTR PSHS B,X
 LDX #V1 point to start of music
 LDB #8 voice counter
A@ TST ,X++ check for end of voice
 BNE A@
 DECB  check for last voice
 BNE A@
 STX INSTPTR
 STX ENDPTR
 PULS B,X,PC

*DISPCURS - Module to control the cursor
*
HPOS FDB 0 horizontal position
VPOS FDB 0 vertical position
HPOSH FCB 0 "half" horizontal position flag
*
CURPTR FDB CURDAT pointer to cursor data
CURDAT FCB 7 number of words in cursor
 FDB $80,$1C0,$3E0
 FDB $770,$3E0,$1C0
 FDB $80
*
OLDCDP FDB 0 previous CURDAT value
OLDVPS FCB 0 previous VPOS value
OLDHPS FCB 0 previous HPOS value
*
DISPCURS JSR READMOUS update HPOS and VPOS
 LDA VPOS
 LDB HPOS
 CMPA OLDVPS see if position has changed
 BNE B@
 CMPB OLDHPS
 BNE B@
 LDX CURPTR
 CMPX OLDCDP see if cursor data has changed
 BEQ D@
B@ LDY OLDCDP see if this is the first time called
 BEQ C@ (if so, no cursor to erase!)
 JSR CURREF erase old cursor
C@ STA OLDVPS update "OLD" variables
 STB OLDHPS
 STX OLDCDP
 CLR CSHIFT
 INC CSHIFT
 INC SHADOW
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
 LDU BUFFER point to cursor refresh stack
 LDA HPOSH save half byte flag on stack
 STA ,U+
 STY ,U++ save starting address
 LDA ,X+ get cursor length
 STA ,U+ save length on stack
A@ PSHS A display/erase cursor
 LDD ,Y get screen data
 STD ,U++ save it in refresh "stack"
 LDD ,X++ get cursor data
 TST CMASK
 BEQ H@
 ANDA CMASK add mask
 ANDB CMASK
 COM CMASK
H@ TST CSHIFT check counter
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
 LDX BUFFER point to cursor refresh stack
 LDA ,X+ get HPOSH flag
 RORA  rotate into carry flag
 LDY ,X++ get address of bottom of cursor
 BEQ Z@ exit if =0
 LDB ,X+ get number of words to refresh
A@ LDU ,X++
 STU ,Y
 BCC B@
 LDA ,X+
 STA 2,Y
B@ LEAY -32,Y
 DECB
 BNE A@
Z@ LDX BUFFER clear refresh address
 CLRA
 CLRB
 STD 1,X
 PULS D,X,Y,U,PC

*REABUT - Read mouse "fire" button
*EXIT: DRAG=$FF if button on
* CLICK=$FF on ON/OFF transition
*
DRAG FCB 0
CLICK FCB 0
*
REABUT PSHS A
 LDA #$FF read joystick button
 STA $FF02
 LDA $FF00
 BITA #1 bit 1=0 if button on
 BNE A@
 LDA #$FF
 STA DRAG
 BRA B@
A@ TST DRAG
 BEQ B@
 LDA #$FF
 STA CLICK
 JSR KEYCLICK
 CLR DRAG
B@ PULS A,PC

*KEYCLICK - produce a click sound when mouse is clicked
*
KEYCLICK PSHS D,X,Y
 LDB #4
 LDY #2
 BRA A@
BEEP PSHS D,X,Y
 LDB #32
 LDY #8
A@ LDX #$FF00
 LDA 1,X turn on D/A sound
 ANDA #$F7
 STA 1,X
 LDA 3,X
 ANDA #$F7
 STA 3,X
 LDA #$3C
 STA $23,X
 LDA $20,X clear D/A bits
 ANDA #3
 STA $20,X
B@ LDA #$3C
 EORA $20,X
 STA $20,X
 PSHS Y
C@ LEAY -1,Y
 BNE C@
 PULS Y
 DECB
 BNE B@
 LDA #$34 turn off sound
 STA $23,X
 LDA #8
 ORA 1,X
 STA 1,X
 LDA #8
 ORA 3,X
 STA 3,X
 LDX #$4000 debounce delay
D@ LEAX -1,X
 BNE D@
 PULS D,X,Y,PC

*READMOUS - Read position of mouse and update
* HPOS and VPOS
*
JOYRTH EQU $15A vertical joystick input
JOYRTV EQU $15B horizontal joystick input
*
READMOUS PSHS D,X,Y,U
 STA $FFDE turn on ROMs
 JSR [$A00A] read joystick port
 STA $FFDF turn off ROMs
 LDA JOYRTV set up VPOS and HPOS
 CMPA #56
 BLE A@
 LDA #56
A@ LSLA  multiply by 3
 ADDA JOYRTV
 STA VPOS
 CLR HPOSH
 LDB JOYRTH
 LSRB
 PSHS CC
 BEQ B@
 DECB
B@ STB HPOS
 PULS CC
 ROL HPOSH set half byte flag
 PULS D,X,Y,U,PC

*CALADR - calculates display address from VPOS,HPOS
*ENTRY: X=VPOS,HPOS
*EXIT:  X is display pointer
*
CALADR PSHS D
 TFR X,D
 PSHS B save HPOS
 LDB #32
 MUL
 ADDB ,S+
 ADCA #0
 ADDD SCREEN
 TFR D,X
 PULS D,PC

*Make the directory area halftone
*
HALFDIR PSHS D,X,Y,U
 LEAU DIRBUF,PCR
 LDX SCREEN,PCR
 LDD #577
 LEAX D,X
 LDY #144
A@ LDB #30 bytes per line
B@ LDA ,X
 STA ,U+
 ORA a@,PCR
 STA ,X+
 DECB
 BNE B@
 COM a@
 LEAX 2,X
 LEAY -1,Y
 BNE A@
 PULS D,X,Y,U,PC
a@ FCB $55 halftone mask

*Restore directory
*
DSPDIR PSHS D,X,Y,U
 LEAU DIRBUF,PCR
 TST ,U
 BEQ Z@
 LDX SCREEN,PCR
 LDD #577
 LEAX D,X
 LDY #144
A@ LDB #30 bytes per line
B@ LDA ,U+
 STA ,X+
 DECB
 BNE B@
 LEAX 2,X
 LEAY -1,Y
 BNE A@
Z@ PULS D,X,Y,U,PC

*Get the next selected directory filename
*EXIT: file loaded into memory, ready to play.
*If at end of directory, A=$FF, else A=0.
*
GETSEL PSHS B,X,Y
 LEAX DIRSTRE,PCR check for end of
 PSHS X directory string first
 LDX LASTFILE,PCR
 BEQ A@ (or uninitialized)
 CMPX ,S
 BLO F@
E@ CLRA
 CLRB
 STD LASTFILE,PCR
 COMA
 BRA Z@
A@ LEAX DIRSTR,PCR at end: reset to start
 STX LASTFILE,PCR
B@ CMPX ,S check for end
 BEQ E@
 TST ,X check for selected file
 BMI C@
F@ LEAX 10,X 10 bytes per entry
 BRA B@
C@ STX LASTFILE save address
 LEAY FILENAME,PCR
 LEAX 1,X skip flag
 LDB #8
D@ LDA ,X+ transfer filename
 STA ,Y+
 DECB
 BNE D@
 LEAX STATLOAD,PCR
 LEAY FILESTAT,PCR
 LDB #4
 LBSR MOVEDATA
 LBSR DSPNAME
 LBSR DISKREA
 TSTA
 BMI Z@
 LEAX STATPLAY,PCR
 LEAY FILESTAT,PCR
 LDB #4
 LBSR MOVEDATA
 LBSR DSPNAME
 LDA TIMESIG+1,PCR calculate value
 SUBA #'0 of MEASURE from
 LDB #$FF TIMESIG
G@ INCB
 LSRA
 BCC G@
 DECB
 LDX b@
 LDA B,X
 LDB TIMESIG,PCR
 SUBB #'0
 MUL
 STD MEASURE,PCR
 CLRA
 CLRB
 STD MEA_STRT,PCR
 LBSR RSETPTR
 CLRA
Z@ LEAS 2,S
 PULS B,X,Y,PC
LASTFILE FDB 0 address last filename
b@ FCB 96,48,24

MOUSTAT BSR DSPSTAT
 FDB 453
 FCB 128+JAM
 FCC "Select Songs with Mouse"
 FCB 0
 RTS

MENSTAT BSR DSPSTAT
 FDB 453
 FCB 128+JAM
 FCC "    Select Menu Item   "
 FCB 0
 RTS

REQSTAT BSR DSPSTAT
 FDB 453
 FCB 128+JAM
 FCC "     Type Response     "
 FCB 0
 RTS

DSPSTAT PSHS D,X,U
 LDX 6,S
 LDU ,X++
 LDD #224
 STD TEXTADJ,PCR
A@ LDA ,X+
 BEQ B@
 LBSR TEXT
 BRA A@
B@ CLRA
 CLRB
 STD TEXTADJ,PCR
 STX 6,S
 PULS D,X,U,PC

*Clear status box
*
CLRSTAT PSHS D,U
 LDU #449
 LDD #224
 STD TEXTADJ,PCR
 LDB #30
 LDA #32
A@ LBSR TEXT
 DECB
 BNE A@
 CLRA
 CLRB
 STD TEXTADJ,PCR
 PULS D,U,PC

*Display file being played in status box
*ENTRY: FILENAME has correct filename
*
DSPNAME PSHS D,X,Y
 LEAX FILENAME,PCR
 LEAY b@,PCR
 LDB #8
 LBSR MOVEDATA
 LDU #456
 LDD #224
 STD TEXTADJ,PCR
 LEAX a@,PCR
A@ LDA ,X+
 BEQ Z@
 LBSR TEXT
 BRA A@
Z@ CLRA
 CLRB
 STD TEXTADJ,PCR
 PULS D,X,Y,PC
a@ FCB JAM+128
FILESTAT FCC "Playing "
 FCB 133 (FAT+JAM)
b@ FCC "         "
 FCB 0
STATPLAY FCC "Play"
STATLOAD FCC "Load"

*Display disk directory on screen
*
GETDIR LEAX FILENAME,PCR
 LBSR DIR
 LEAX REQDIR,PCR
 LDD #192
 STD TEXTADJ,PCR
 LBSR DSPREQ
 CLRA
 CLRB
 STD TEXTADJ,PCR
 CLR DIRBUF,PCR cancel buffer refresh
 RTS

*Select file from displayed directory
*
SELFILE LBSR READMOUS
 LBSR REABUT
 TST CLICK,PCR
 BEQ Z@
 BSR SETFLAG
Z@ RTS

*Set the select flag in the directory requestor and
*invert the filename.
*
SETFLAG PSHS D,X
*convert VPOS to directory line number
 CLRA
 LDB VPOS
 LDX #12
 JSR DIVIDE
 TFR X,D
 CMPB #0 skip top & bottom lines
 BEQ Z@
 CMPB #12 check for bottom line
 BHI Z@
 DECB  adjust B so 0=first
 PSHS B line in directory.
*now calculate which entry in the directory is selected
 LSLB  multiply line number by 3
 ADDB ,S (3 items per line)
 STB ,S
 CLRA
 LDB HPOS
 LDX #11
 JSR DIVIDE
 TFR X,D
 ADDB ,S+
 LDA #10 (10 bytes per entry)
 MUL
 PSHS D keep offset into DIRSTR
*calculate the address of the entry on display screen
 CLRA
 LDB VPOS
 LDX #12
 JSR DIVIDE
 TFR X,D first get the vertical address
 INCB
 LDA #12 12 raster lines per
 MUL  text line.
 LDA #32 32 bytes per line.
 MUL
 ADDD SCREEN
 PSHS D
 LDB HPOS next get horizontal
 CLRA  offset.
 LDX #11
 JSR DIVIDE
 TFR X,D
 LDA #10
 MUL
 ADDD #1
 ADDD ,S++ add VPOS to HPOS
 SUBD #192 adjust up 1/2 text line
 TFR D,X X points to bar address
*lastly invert filename and select flag in directory
 LBSR CURREF
 BSR COMBAR
 LBSR DISPCURS
 PULS D get directory item offset
 LEAX DIRSTR,PCR
 COM D,X complement select flag
Z@ PULS D,X,PC

*Invert directory filename
*ENTRY: X points to display address
*
COMBAR LDA #12 number of lines/bar
A@ LDB #8 bytes/bar (horizontal)
 PSHS A
 LDA ,X
 EORA #3
 STA ,X
 PULS A
B@ COM B,X
 DECB
 BNE B@
 LEAX 32,X move down to next line
 DECA
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

*WAITKEY - wait for any keypress and key off
*
WAITKEY PSHS A,X
 CLR $FF02
A@ LDA $FF00 wait for any keypress
 ANDA #$7F
 CMPA #$7F
 BEQ A@
 LDX #$4000 debounce delay
B@ LEAX -1,X
 BNE B@
C@ LDA $FF00 wait for key off
 ANDA #$7F
 CMPA #$7F
 BNE C@
 PULS A,X,PC

*KEYIN - get keyboard input
*EXIT: register A contains ASCII code (=0 if no keypress)
*
KEYIN STA $FFDE turn on ROMs
 ANDCC #$AF
 JSR [$A000]
 STA $FFDF
 ORCC #$50
 RTS

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

 INCLUDE GRAPHICS.ASM
 INCLUDE PULLDOWN.ASM
 INCLUDE DISKIO.ASM
 INCLUDE REQUEST.ASM
 INCLUDE PLAY.ASM
 INCLUDE TITLE.ASM

DIRBUF FCB 0
 RMB 4319 30*144 (directory refresh buffer)

*Music code - this section is written to disk/tape
*
STARTCOD FCC "2" LYRA version
 FCB $5A used to identify as LYRA file
KEYSIG FCC "0S" key signature
TIMESIG FCC "44" time signature
TEMPO FDB 32 master tempo
DSPMODE FCB 1,0,0,0 display modes
 FCB 0,0,0,0
VOI_PTR FDB V1 pointer to voice 1
 FDB V2 pointer to voice 2
 FDB V3 pointer to voice 3
 FDB V4 pointer to voice 4
 FDB V5 pointer to voice 5
 FDB V6 pointer to voice 6
 FDB V7 pointer to voice 7
 FDB V8 pointer to voice 8
INSTPTR FDB 0 not used in version 2.0
ENDPTR FDB ENDCODE pointer to end of code
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
MIDIDESM FCC "                            " space for synthesizer description
 FCB 0
MIDICHAN FCB 0,0,0,0 MIDI channels assigned
 FCB 0,0,0,0 to each voice
MIDIVOL FCB 64,64,64,64,64,64,64,64 MIDI voice volumes
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

PRGEND EQU *

 END START
