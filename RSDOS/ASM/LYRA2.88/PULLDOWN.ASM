 TITLE "PULLDOWN"
*************************************************
* PULLDOWN/TXT: INCLUDE FILE FOR LYRA
* CONTAINS MOST OF THE PULLDOWN MENU ROUTINES
* (C) 1986-1988 by Lester Hands
* Last update: 02-may-90
* Last update:  3-jun-90 modifications (c) R.Gault
*************************************************

*MSG "PULLDOWN=",*

*SETMEN - set up background for pulldown menu
*ENTRY: A=menu number
* X=pointer to menu text
* Menu text format: HPOS,length, width, #items, text
*EXIT: registers D,X,Y,U preserved
*
*Structure of BUFFER:
*Starting address (2 bytes), width (1 byte), length (2bytes)
*
WIDTH FDB 0 		width counter
LENGTH FCB 0 		number of text lines
*
SETMEN PSHS D,X,Y,U
 LDU BUFFER point to refresh memory
 LDB LINEWIDE
 LDA #12
 MUL
 PSHS D
 LDB -1,X get HPOS for menu
 CLRA
 ADDD ,S++
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
 LDA LINEWIDE
 LEAX A,X
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
 LDA LINEWIDE
 LEAU A,U move to next text line
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
 ADDB LINEWIDE move to next line
 ADCA #0
 TFR D,U
 BRA A@
C@ PULS D
 PULS D,X,Y,PC

*REFMEN - erase menu from BUFFER
*EXIT: registers D,X,Y,U preserved
*
REFMEN PSHS D,X,Y,U
 LDU BUFFER point to refresh memory
 LDX ,U++ get screen pointer
 BEQ Z@
 LDB ,U+ get width
 LDY ,U++ get length
A@ PSHS B,X
B@ LDA ,U+ get data
 STA ,X+ store it back on screen
 LEAY -1,Y
 DECB
 BNE B@
 PULS B,X
 LDA LINEWIDE
 LEAX A,X move down to next line
 CMPY #0
 BNE A@
 CLRA
 CLRB
 STD [BUFFER]
Z@ PULS D,X,Y,U,PC

*SELMEN - select pulldown menu item
*ENTRY: X points to 2nd item of menu string
*HPOS and VPOS have just been updated
*
BARADR FDB 0 		address of bar
ITEMN FCB 0 		item of menu selected
SELFLA FCB 0 		flags for SELMEN:
* bit 7: new menu=1
*
SELMEN PSHS D,X,Y
 LDA VPOS check whether we are
 SUBA VMAX at the bottom of the menu
 BLS D@ if so, allow 3 lines
 CMPA #36 to prevent "falling off"
 BHI C@
 LDA VMAX
 BRA E@
D@ LDA VPOS calculate address
E@ LDB #$FF
A@ INCB
 SUBA #12
 BCC A@
 STB ITEMN
 BEQ C@
 LDA #12 number of lines/bar
 MUL
 LDA LINEWIDE number of bytes/line
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
HMIN FCB 0 		left side of pulldown menu
HMAX FCB 0 		right side of pulldown menu
VMAX FCB 0 		bottom of pulldown menu
MENUN FCB 0 		selected menu number
*
PULDOW JSR CURREF erase cursor
 LDY #0 cancel normal cursor erase
 STY OLDCDP
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
 CMPB VMAX check for bottom of menu
 BLS L@
 SUBB VMAX allow 3 lines to prevent
 CMPB #36 "falling off"
 BHI G@
L@ JSR SELMEN select menu item
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
F@ JSR [2,X]
J@ PULS D
 BRA H@
G@ JSR REFMEN erase menu
H@ CLR CLICK
 ANDCC #$FE clear carry flag
 RTS

DONEW LBSR SURE
 CMPA #'Y
 BEQ A@
 RTS
A@ LBSR INIT
 LBSR CLRANNOT
 LDX #$4000
B@ NOP
 LEAX -1,X
 BNE B@
 CLR $FF02 wait for key off
C@ LDA $FF00
 ORA #$80
 CMPA #$FF
 BNE C@
 LBRA RESET

DOQUIT LBSR SURE
 CMPA #'Y
 BEQ EXIT
 RTS
EXIT LBSR DISKHOME
 STA ROM_ON turn ROMs ON
 STA SLOW
 JMP [$FFFE] return to BASIC

*MENADR - table of menu selections and jump address
*
MENADR FDB 1,DONEW
 FDB 2,DOLOAD
 IFNE DEMO
* ---CONDITIONAL START
 FDB 3,DOSAVE
 FDB 4,DOSAVEAS
 FDB 5,DOAPPEND
 FDB 6,DODELETE
 FDB 7,INST_LO
 FDB 8,INST_SA
 ENDC
*  ---CONDITIONAL END
 IFEQ DEMO
* ---CONDITIONAL START
 FDB 3,NOTAVAIL
 FDB 4,NOTAVAIL
 FDB 5,NOTAVAIL
 FDB 6,NOTAVAIL
 FDB 7,NOTAVAIL
 FDB 8,NOTAVAIL
 ENDC
*  ---CONDITIONAL END
 FDB 9,SETDRIVE
 FDB 10,DOQUIT
 FDB $101,ALLNOTON
 FDB $102,REQTSIG
 FDB $103,REQKSIG
 FDB $104,REQNFRAC
 FDB $105,REQFILLV
 FDB $106,BLK_RSET
 FDB $107,BLK_DEL
 FDB $108,COPY_SET
 FDB $109,BLK_TRNS
 FDB $10A,VOICOPY
 FDB $10B,GOTOBAR
 FDB $201,REQMCHAN
 FDB $202,CHGMFILT
 FDB $203,CHGMCLCK
 FDB $204,REQMDELA
 FDB $205,REQMDESC
 FDB $206,REQMINST
 FDB $207,REQMVOL
 FDB $208,REQEVENT
 FDB $209,SELPORT
 FDB $301,MIDIPLAY
 FDB $302,PLAYALL
 FDB $303,TGLFOLLW
 FDB $304,PLAY
 FDB $305,MIDITRAN
 FDB $306,MIDITEMP
 FDB $307,MIDIOFF
 FDB $308,MEMORY
 FDB $309,HELP
 FDB $30A,REQANNOT
 FDB 0 		end of table marker

TOPLIN FCC " FILE" 	top line of menus
 FCC " EDIT"
 FCC " MIDI"
 FCC " PLAY"
 FCB 0

PULMEN FCB 0 		starting HPOS
 FCB 5 			ending HPOS
 FCB 10 		width-1
 FCB 10 		number of items
 FCC " New"		files menu
 FCB 13
 FCC " Load"
 FCB 13
SAVEOK FCB SEL_NOK 	*=SEL_OK if selectable
 FCC " Save"
 FCB 13
 FCB SEL_OK
 FCC " Save As"
 FCB 13
 FCC " Append"
 FCB 13
 FCC " Delete"
 FCB 13
 FCC " Load instr"
 FCB 13
 FCC " Save instr"
 FCB 13
 FCC " Set Drive"
 FCB 13
 FCC " Quit"
 FCB 0 			end of menu marker

 FCB 5,10,15,11 	edit menu
 FCC " All Voices On"
 FCB 13
CHNGTSIG FCB SEL_NOK
 FCC " Time Signature"
 FCB SEL_OK
 FCB 13
 FCC " Key Signature"
 FCB 13
 FCC " Note lengths"
 FCB 13
 FCC " Fill Voice"
 FCB 13
BLOCKSET FCB SEL_NOK
 FCC " Reset block"
 FCB 13
BLOCKOK FCB SEL_NOK
 FCC " Block delete"
 FCB 13
 FCC " Block copy"
 FCB 13
 FCC " Block Transpose"
 FCB 13
 FCC " Voice Copy"
 FCB 13,SEL_OK
 FCC " Go To Bar"
 FCB 0

 FCB 10,15,13,9 		MIDI menu
 FCC " Channels"
 FCB 13
 FCC " Filter "
MENFILT FCC "OFF"
 FCB 13
 FCC " Clock "
MENCLK FCC "OFF"
 FCB 13
 FCC " Delay"
 FCB 13
 FCC " Description"
 FCB 13
 FCC " Instruments"
 FCB 13
 FCC " Volume Set"
 FCB 13
 FCC " Events"
 FCB 13
MPORT FCC " Serial Port"
 FCB 0

 FCB 15,20,13,10 		play menu
 FCC " MIDI play"
 FCB 13
 FCC " MIDI Play All"
 FCB 13
 FCC " Follow "
FOLMENU FCC "OFF"
 FCB 13
TVMENU FCC " TV Play      "
 FCB 13
 FCC " Transpose "
MENTRANS FCC "OFF"
 FCB 13
 FCC " Master Tempo"
 FCB 13
 FCC " All notes off"
 FCB 13
 FCC " Memory"
 FCB 13
 FCC " Key Commands"
 FCB 13
 FCC " Annotation"
 FCB 0

 FCB $FF 		end of menus marker
