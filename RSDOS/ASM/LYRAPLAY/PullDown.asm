* TITL1 "PULLDOWN/TXT"
*************************************************
* PULLDOWN/TXT: INCLUDE FILE FOR LYRABOX
* Last update: 28-jun-88
*************************************************

*SETMEN - set up background for pulldown menu
*ENTRY: A=menu number
* X=pointer to menu text
* Menu text format: HPOS,length, width, #items, text
*EXIT: registers D,X,Y,U preserved
*
*Structure of BUFFER:
*Starting address (2 bytes), width (1 byte), length (2bytes)
*
WIDTH FDB 0 width counter
LENGTH FCB 0 number of text lines
*
SETMEN PSHS D,X,Y,U
 LBSR HALFDIR make directory half tone
 LDU BUFFER point to refresh memory
 LDB -1,X get HPOS for menu
 CLRA
 ADDD #32*12
 ADDD SCREEN
 STD ,U++ save starting address of BUFFER
 LDD 1,X get width & length of menu
 STA WIDTH
 STB LENGTH
 ADDA #2 adjust for sides of menu
 STA ,U+ save width of BUFFER
 PSHS U
 LDD #0
 STD ,U++ reset length of BUFFER
 TFR D,Y length counter=Y
 LDX [BUFFER] point to starting address
A@ BSR LINE2
 DEC LENGTH
 BNE A@
 LDA WIDTH do 2 bottom border lines
 ADDA #2
 STA WIDTH+1
 PSHS X
B@ CLRA
 BSR STORE
 DEC WIDTH+1
 BNE B@
 PULS X
 LEAX 32,X
 LDA #$80
 BSR STORE
 INC WIDTH
C@ CLRA
 BSR STORE
 DEC WIDTH
 BNE C@
 STY [,S]
 PULS U
 PULS D,X,Y,U,PC return

LINE2 LDA #12 number of lines/text line
 PSHS A
A@ PSHS X
 LDA WIDTH
 STA WIDTH+1
 LDA #$7F do left border
 BSR STORE
B@ LDA #$FF erase interior
 BSR STORE
 DEC WIDTH+1
 BNE B@
 LDA #$FC do right border
 BSR STORE
 PULS X
 LEAX $20,X move to next line
 DEC ,S
 BNE A@
 LEAS 1,S
 RTS

STORE PSHS B
 LDB ,X save in refresh memory
 STB ,U+
 STA ,X+
 LEAY 1,Y
 PULS B,PC

*DSPMEN - display text on pulldown menu
*ENTRY: X points to text data
*
DSPMEN PSHS D,X,Y
 LDA #FAT set FAT mode
 STA TMODE
 CLRA
 LDB -1,X get HPOS for menu
 PSHS D
 TFR D,U
 LEAU 32,U move to next text line
 LEAX 3,X skip header bytes
A@ LDA ,X+
 BEQ C@
 CMPA #13
 BEQ B@
 JSR TEXT
 BRA A@
B@ TFR U,D
 ANDB #$E0 save top 3 bits
 ADDD ,S
 ADDD #32 move to next line
 TFR D,U
 BRA A@
C@ PULS D
 PULS D,X,Y,PC

*REFMEN - erase menu from BUFFER
*EXIT: registers D,X,Y,U preserved
*
REFMEN PSHS D,X,Y,U
 LBSR CLRSTAT
 LDU BUFFER point to refresh memory
 LDX ,U++ get screen pointer
 LDB ,U+ get width
 LDY ,U++ get length
A@ PSHS B,X
B@ LDA ,U+ get data
 STA ,X+ store it back on screen
 LEAY -1,Y
 DECB
 BNE B@
 PULS B,X
 LEAX $20,X move down to next line
 CMPY #0
 BNE A@
 LDX BUFFER,PCR cancel cursor refresh
 CLRA
 CLRB
 STD 1,X
 PULS D,X,Y,U,PC

*SELMEN - select pulldown menu item
*ENTRY: X points to 2nd item of menu string
*HPOS and VPOS have just been updated
*
BARADR FDB 0 address of bar
ITEMN FCB 0 item of menu selected
SELFLA FCB 0 flags for SELMEN:
* bit 7: new menu=1
*
SELMEN PSHS D,X,Y
 LDA VPOS calculate address
 LDB #$FF
A@ INCB
 SUBA #12
 BCC A@
 STB ITEMN
 BEQ C@
 LDA #12 number of lines/bar
 MUL
 LDA #32 number of bytes/line
 MUL
 ADDD SCREEN
 ADDB -1,X add HPOS
 CMPD BARADR exit if no change in address
 BEQ C@
 PSHS D
 LDA SELFLA check for new menu flag
 BMI B@
 BSR FLIPLINE erase present bar
B@ LDA SELFLA
 ANDA #$7F
 STA SELFLA
 PULS D restore new address
 STD BARADR
 BSR FLIPLINE
C@ PULS D,X,Y,PC

*FLIPLINE - invert a line on a pulldown menu
*
FLIPLINE LDY BARADR
 LDB #12 number of lines to flip
A@ PSHS B,Y
 LDA ,Y flip left side
 EORA #$7F
 STA ,Y+
 LDB 1,X get menu width
B@ LDA ,Y
 EORA #$FF
 STA ,Y+
 DECB
 BNE B@
 LDA ,Y
 EORA #$FC flip right side
 STA ,Y
 PULS B,Y
 LEAY $20,Y move down to next line
 DECB
 BNE A@
 RTS

*PULDOW - module to handle pulldown menus
*
HMIN FCB 0 left side of pulldown menu
HMAX FCB 0 right side of pulldown menu
VMAX FCB 0 bottom of pulldown menu
MENUN FCB 0 selected menu number
*
PULDOW JSR CURREF erase cursor
 LDY #0 cancel normal cursor erase
 STY OLDCDP
 LBSR MENSTAT
 LDX #PULMEN
 LDA #$FF
 STA MENUN
A@ INC MENUN
 LDA HPOS
 TST ,X+ get left HPOS for menu
 LBMI H@ check for end of menus marker
 CMPA -1,X see if cursor is in the right position
 BLO B@
 CMPA ,X test right HPOS for menu
 BLO C@
B@ LDB ,X+ look for end of menu
 BNE B@
 BRA A@
C@ LDA -1,X get HPOS of left side
 STA HMIN
 LDA ,X get HPOS of right side
 STA HMAX
 LDB 2,X get menu # lines
 LDA #12 convert to VPOS
 MUL
 ADDB #3 give a little extra room
 STB VMAX
 JSR SETMEN set up background
 JSR DSPMEN display text of menu
 LDA SELFLA set flag to indicate
 ORA #$80 new menu
 STA SELFLA
D@ JSR READMOUS update mouse position
 LDB HPOS check horizontal bounds
 CMPB HMIN
 BLO G@
 CMPB HMAX
 BHI G@
 LDB VPOS
 CMPB VMAX
 BHI G@
 JSR SELMEN select menu item
 JSR REABUT check for button press
 TST DRAG
 BEQ D@
E@ JSR REABUT wait until button
 TST DRAG is released
 BMI E@
 CLR BARADR (variable used by SELMEN)
 LDX #$200 short delay after
K@ LEAX -1,X button press
 BNE K@
 JSR REFMEN erase menu
* here goes the menu selection logic
* MENUN and ITEMN tell where you are
 LDA MENUN
 LDB ITEMN
 PSHS D
 LDX #MENADR
I@ LDD ,X check for end of table
 BEQ J@
 CMPD ,S check our selection
 BEQ F@ against table entry
 LEAX 4,X move to next item
 BRA I@
F@ LBSR CLRSTAT
 JSR [2,X]
J@ PULS D
 BRA H@
G@ JSR REFMEN erase menu
H@ CLR CLICK
 LBSR DSPDIR
 LBSR MOUSTAT restore status line
 RTS

DOQUIT LBSR SURE
 CMPA #'Y
 BEQ A@
 RTS
A@ LBSR DISKHOME
 STA $FFDE turn ROMs ON
 CLR $71 set cold start
 JMP [$FFFE] return to BASIC

CHGMCLCK PSHS D change MIDI clock flag
 TST CLOCKFL
 BEQ A@
 CLR CLOCKFL
 LDD #$4F46 ('OF')
 STD MENCLK
 LDA #$46 ('F')
 STA MENCLK+2
 BRA Z@
A@ INC CLOCKFL
 LDD #$4F4E ('ON')
 STD MENCLK
 LDA #$20 (' ')
 STA MENCLK+2
Z@ PULS D,PC

CHGFILT PSHS D change MIDI FILTER mode
 COM FILTER,PCR
 BMI A@
 LDD #$4F46 ('OF')
 STD MENFILT,PCR
 LDA #$46 ('F')
 STA MENFILT+2,PCR
 BRA Z@
A@ LDD #$4F4E ('ON')
 STD MENFILT,PCR
 LDA #$20 (' ')
 STA MENFILT+2,PCR
Z@ PULS D,PC

*MENADR - table of menu selections and jump address
*
MENADR FDB 1,GETDIR
 FDB 2,SETDRIVE
 FDB 3,DOQUIT
 FDB $101,MIDIPLAY
 FDB $102,TVPLAY
 FDB $201,CHGFILT
 FDB $202,MIDITRAN
 FDB $203,CHGMCLCK
 FDB $204,REQMDELA
 FDB 0 end of table marker

TOPLIN FCC " DISK" top line of menus
 FCC " PLAY"
 FCC " PARAMETERS"
 FCB 0

PULMEN FCB 0 starting HPOS
 FCB 5 ending HPOS
 FCB 9 width-1
 FCB 3 number of items
 FCC " New disk" files menu
 FCB 13
 FCC " Set drive"
 FCB 13
 FCC " Quit"
 FCB 0 end of menu marker

 FCB 5,10,9,2 PLAY menu
 FCC " MIDI play"
 FCB 13
 FCC " TV Play"
 FCB 0

 FCB 10,20,10,4 Parameters menu
 FCC " Filter "
MENFILT FCC "OFF"
 FCB 13
 FCC " Transpose"
 FCB 13
 FCC " Clock "
MENCLK FCC "OFF"
 FCB 13
 FCC " Delay"
 FCB 0

 FCB $FF end of menus marker
