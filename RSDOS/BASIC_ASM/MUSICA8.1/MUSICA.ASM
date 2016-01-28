* MUSICA.TXT
* MUSICA SOURCE CODE 19-sep-88
* REQUIRES OTHER FILES:
* MUSKEY/TXT, MUSICA01/TXT, and MUSICA02/TXT.

*Added features:
* 64K memory required
* Repeat sections
* Fast play does not destroy music code if 64K available
* Play all files command
* Options command
* Piano keyboard interface
* True musical rest signs
*XVAR has been changed from 8 bit to 5 bit
*Print routine verified on the PROWRITER

VERSIN EQU '8 version number
VERSNS EQU '1 version sub-number
DPAGE EQU $07 direct page value
 SETDP DPAGE
LIMMEM EQU $7F78 address of last available memory
SCREEN EQU $0E00 pointer to start graphics display
MSGADR EQU SCREEN+$20 start of messages address
MEMADR EQU SCREEN+$A0 start memry left indicator
BEGINS EQU SCREEN+$100 start of graphics shift
ENDSH EQU SCREEN+$FFE end of graphics shift
OUTTAB EQU $3F00 output table (synthesized)
BASEWV EQU $40 start of waveform tables
BASWAV EQU BASEWV*256
STAMUS EQU BASWAV+$405 start of music code
KEYIN EQU $A000
KEYOUT EQU $A002
JOYIN EQU $A00A
INTCNV EQU $B3ED
KBDPIA EQU $FF64 Keyboard PIA location

 ORG $0700 (disk buffer #2)

*Pointers used by CMD files
FINISH RMB 2 end of music code
ADDRES RMB 2 address of current memory pointer
STFLAG RMB 2 start flag

*Storage for SDUMP
COUNTS RMB 1 screen counter (KEYW)
SCOUNT RMB 1 number of screens per page
SBLANK RMB 1 SBLANK line flag
SENDBY RMB 1 byte to be printed
BUFFER RMB 2

*Storage for "SINE"
HRMAMP RMB 8 harmonic amplitudes
HRMCNT RMB 1 harmonic counter
SINPNT RMB 1 sine table pointer
MULT RMB 4 holds results of 32 bit multiply

*storage for bin/dec conversion
DIGCNT RMB 1
PWRCNT RMB 1

STACK RMB 2 storage for stack pointer
OLDRES RMB 2 original reset vector
RESIRQ RMB 2 original IRQ vector

HRMPNT RMB 4*13+1 harmonic pointers
TITLE RMB 2*32+1 string for title

*Storage for DIR
OLDBPT RMB 2 old buffer pointer
BUFPNT RMB 2 buffer pointer
BUFEND RMB 2 buffer end pointer
OUTRDY RMB 1 output ready flag
SECTOR RMB 1 sector for DSKCON

*Variables associated with "PLAY"
V1PT RMB 3
V2PT RMB 3
V3PT RMB 3
V4PT RMB 3
DUR RMB 1
TEMPO RMB 2
FIRSTP RMB 2
KBDCON RMB 1 initial contents of KBDPIA location

*The next 8 variables must not be moved!
NVALU RMB 1 current note value (quarter, etc)
VOICE RMB 1 current voice number
STEREO RMB 1
JSTFLG RMB 1 joystick input flag
VDISP RMB 1 voice to display on selective display
FSTFLG RMB 1
UFLAG RMB 1 flag for corrective update after fastplay
EPLFLG RMB 1 flag for entry play
TAPEIO RMB 1 flag for tape I/O (if =0, then disk)
XVAR RMB 1 screen cursor position (horizontal)
YVAR RMB 1 screen cursor position (vertical)

SHARP RMB 1 sharp flag
FLAT RMB 1 flat flag
NATURL RMB 1 natural flag
XVAR1 RMB 1
YVAR1 RMB 1
YVAR2 RMB 1
CURADR RMB 2 calculated cursor address
TEMP RMB 2 scratch storage
TEMP1 RMB 2
TEMP2 RMB 2
MARK1 RMB 2 beginning of block move
MARK2 RMB 2 end of block move
RPTADR RMB 2 Repeat section return address
COUNT RMB 1
COUNT0 RMB 1
COUNT1 RMB 1
TFLAG RMB 1 triplet flag
FFLAG RMB 1 note flag flag (flag in top voice only)
VDMASK RMB 1 mask for selective display
HIRES RMB 1 =0 if hires
BARMRK RMB 1 =1 if bar numbers displayed
PALFLG RMB 1 =1 if play all in effect
PNOFLG RMB 1 =1 if 4 octave keyboard
POSFLG RMB 1 =0 if lower staff on 2 octave keyboard
ENTCOD RMB 2 entry code

 ORG $1E00
START BRA STARTA

*Printer codes
MARGIN FCB 112 amount of blank margin
SBTYPE FCB 0 print byte type (1=reverse bit order)
OFFSET FCB 0 offset to be added to sendbyte
BITS FCB 8 number of bits per column
SETLNF FCB 3,27,65,8,0,0,0,0,0 set linefeed to 8/72"
SSTGRA FCB 4,27,75,112,1,0,0,0,0 set graphics mode
SETCR FCB 1,13,0,0,0,0,0,0,0 print 'cr' at end of line
SETFF FCB 1,12,0,0,0,0,0,0,0 print formfeed at end of page
BAUD FCB 1 printer baud rate

STARTA JSR INTCNV get entry code from basic
 STD >ENTCOD save entry code
STARTB LDX >$72 save old reset vector
 STX >OLDRES
 LDX #RESET set reset vector
 STX >$72
 CLR $987 disable disk verify (make sure buffer #2 is available)
 STS >STACK save stack pointer
RESET NOP  reset entry point
 LDA #DPAGE set DP register
 TFR A,DP
 LDS >STACK
 LDX #$FF70 turn on stereo port
 CLR 1,X
 CLR 3,X
 LDA #$FF
 STA ,X
 STA 2,X
 LDA #4
 STA 1,X
 STA 3,X
 LDD ENTCOD get entry code
 CMPD #2
 LBEQ START2
 LDD STFLAG check start flag
 CMPD #$5A5A
 LBEQ START1
 LDX $10D get original irq pointer
 STX RESIRQ and save it
ST00 LDU #BASWAV
ST01 LDX #SINTAB set up tone tables
ST02 LDA ,X+
 LSRA
 STA ,U+
 CMPX #SINTAB+$FF
 BLE ST02
 CMPU #BASWAV+$3FF
 BLE ST01
 LDX #HRMSTR move harmonic descriptor
 LDY #HRMPNT strings into appropriate memory
 LDB #53 (4*13+1)
 JSR MOVED
 JSR CLRTTL
 LDD #STAMUS cold start
 STD FINISH
 LDD #$402 set default note length (quarter)
 STD NVALU and default voice (1)
 LDA #100 set default tempo
 STA STAMUS-5
 LDD #BASWAV+BASEWV set default table pointers
 STD STAMUS-4
 STD STAMUS-2
 LDD #0 CLEAR variable pairs
 STD STEREO turn stereo, joystick off
 STD VDISP clear vdisp, fstflg
 STD SHARP clear sharp, flat
 CLR NATURL clear natural
 CLR MARK1
 CLR MARK2
 CLR UFLAG
 CLR FSTFLG
 CLR EPLFLG
 CLR BARMRK
 CLR PALFLG
 LDA #'0
 STA KSIGM1
 LDD #SIGTBS-1
 STD KEYTYP
 CLR KEYNUM
 LDA #$AA
 STA VDMASK
 LDA KBDPIA save initial value of
 STA KBDCON keyboard PIA
 LDD $C000 check for disk ROM
 CMPD #$444B (="DK")
 BNE NOTDSK
 CLR TAPEIO
 LDA #1
 STA PNOFLG
 BRA CONTIN
NOTDSK LDA #1
 STA TAPEIO
CONTIN LDD #STAMUS reset variables after music load
 STD ADDRES set cursor to start of music
 LDD #$43A set cursor to origin
 STD XVAR (X=4, Y=58)
 JSR PCLS
 JSR CLEF
 JSR SETGRA
 LDD STFLAG test start flag
 CMPD #$5A5A
 BEQ NWAIT
 LDU #CPRMSG
 LDX #SCREEN
 JSR GETMSG display copyright notice
 CLRB
 EXG DP,B
WAITS SYNC
 JSR [KEYIN] wait for keypress
 BEQ WAITS
 EXG B,DP
 JSR CLRMES
 LDD #$5A5A
 STD STFLAG
NWAIT JSR PRTMEM display the current available memory
 JSR PRTVOI display the current voice
 JSR SETSTA display stereo marker
 JSR UPDATE display music
START1 JSR CLRMES
 JSR ENDMRK write an "end of music" marker
 JSR SETGRA set up vdg chip for high-res display
 JMP MENU

START2 CLR ENTCOD+1
 JSR CLRMES entry point after loading new music
 LDY #HRMPNT
 LDB #53+65 (53=4*13+1,65=bytes in title)
 LDX $9D
 STX FINISH "exec" address is end of music marker
 LDA 1,X test for correct format
 CMPA #$39
 BNE STRT2A
 LEAX 2,X
 JSR MOVED
 CLR TITLE+64
 BRA CONTIN
STRT2A LDX #HRMSTR
 JSR MOVED
 JSR CLRTTL
 BRA CONTIN

CLRMES LDX #MSGADR CLEAR MESSAGE AREA
 LDD #$607F
 JSR CLRTL0
 STA ,X
 RTS

CLRTTL LDX #TITLE CLEAR OUT TITLE
 LDD #$2040 (A=#' ,B=64)
CLRTL0 STA ,X+
 DECB
 BNE CLRTL0
 CLR ,X MARK END OF TITLE STRING
 RTS

CPRMSG FCC "          MUSICA 2.8            "
 FCC "                                "
 FCC "                                "
 FCC "                                "
 FCC "                                "
 FCC "    (C) 1987 BY LESTER HANDS    "
 FCB 0

ENDMRK PSHS X,D
 LDX FINISH write an "end of music" marker
 LDB #9 at position pointed to by FINISH
 CLRA
ENDMK1 STA B,X
 DECB
 BPL ENDMK1
 PULS X,D,PC

PCLS LDX #SCREEN+(32*6) CLEAR GRAPHICS
 LDD #$FFFF
PCLS1 STD ,X++
 CMPX #SCREEN+$FFE
 BLE PCLS1
 RTS

CLEF LDX #CLFDAT WRITE CLEVES AND STAVES
 LDY #SCREEN+$4A0
CLEF1 LDD ,X++
 STD ,Y
 LEAY $20,Y
 CMPY #SCREEN+$CE0
 BLE CLEF1
 LDA #2
 STA XVAR1
CLEF2 BSR BLANK
 LDA XVAR1
 ADDA #2
 STA XVAR1
 CMPA #31
 BLE CLEF2
 RTS

BLANK LDB XVAR1 write a blank section of score at
 CLRA
 ADDD #SCREEN+$200 the position pointed to by xvar1
 TFR D,X
 LDD #SCREEN+$560
 BSR BLANK0
 BSR STAFF
 LDD #SCREEN+$9E0
 BSR BLANK0
 BSR STAFF
 LDD #SCREEN+$EC0
BLANK0 STD TEMP
 LDD #$FFFF
BLANK1 STD ,X
 LEAX $20,X
 CMPX TEMP
 BLO BLANK1
 RTS

STAFF LDD #0 WRITE STAFFS
 STD ,X
 LEAX $20,X
 LDA #4
 STA COUNT1
STAFF0 BSR STAFF1
 DEC COUNT1
 BNE STAFF0
 RTS
STAFF1 LDA #5
 STA COUNT0
 LDD #$FFFF
STAFF2 STD ,X
 LEAX $20,X
 DEC COUNT0
 BNE STAFF2
 LDD #0
 STD ,X
 LEAX $20,X
 RTS

MENU JSR SETDPA
 CLR UFLAG
 JSR CURSOR
JOYSTK TST JSTFLG check if joystick selected
 BEQ MENU0
 CLR SHARP
 CLR FLAT
 JSR CLRDPA
 JSR [JOYIN] get joystick input
 JSR SETDPA
 LDA $15B get left up/down
 LDB #85 multiply by 1.33
 MUL
 ADDA $15B
 LSLB round off msbyte
 ADCA #0
 CLRB
JOYST1 INCB
 SUBA #3 divide by 3
 BHS JOYST1
 DECB
 LDA #3 multiply by 3
 MUL
 ADDB #16
 CMPB #16 test for upper limit
 BHI JOYST2
 LDB #16
JOYST2 STB YVAR
 LDA $15A test for right/left
 CMPA #16 set flat if <16
 BGE JOYST4
 CLR SHARP
 DEC FLAT
JOYST4 LDA $15A
 CMPA #48 set sharp if >48
 BLE JOYST5
 CLR FLAT
 DEC SHARP
JOYST5 LDA #$FF
 STA $FF02
 LDA $FF00 test for "FIRE"
 ORA #$80
 CMPA #$FE
 BNE MENU0
 LDX #$800 debounce delay
 JSR DELAY
JOYST7 LDA #$FF
 STA $FF02
 LDA $FF00 wait for off
 ORA #$80
 CMPA #$FF
 BNE JOYST7
 JSR DRAW0 enter note
 JSR CURSAD advance cursor
MENU0 JSR GETKEY get keyboard input
 LBEQ MENU wait if no input
 CMPA #'9 change note value (1-9)?
 BHI MENU0A
 CMPA #'0
 BLE MENU0A
 SUBA #'0
 JSR NOTVAL
 LBRA MENU
MENU0A LDX #MENTAB search table for entry
MENU0B CMPA ,X+ that corresponds to keypress
 BNE MENU0C
 JSR [,X] do command
 LBRA MENU
MENU0C LEAX 2,X advance to next entry in table
 TST ,X test for end of table
 BNE MENU0B
 LBRA MENU

STOREV LDX #EXECAD STORE ENDING ADDRESS
 LDD FINISH IN A$ VARIABLE IN BASIC
CONV BSR CONV1
 TFR B,A
CONV1 PSHS A
 LSRA CONVERT TO ASCII
 LSRA
 LSRA
 LSRA
 BSR CNVHEX
 PULS A
 ANDA #$0F
CNVHEX ADDA #$90 BINARY TO HEX (ALLISON)
 DAA
 ADCA #$40
 DAA
 STA ,X+
 RTS
 SETDP DPAGE

FNDPNT LDX #STAMUS-9 find last used wave
FNDPT0 LEAX 9,X table pointers and tempo
 CMPX ADDRES
 BGT FNDPT2
 LDA ,X
 CMPA #$FE
 BEQ FNDPT1
 BRA FNDPT0
FNDPT1 LDD 1,X transfer new pointers to
 STD STAMUS-4 start of music
 LDD 3,X
 STD STAMUS-2
 LDA 5,X
 STA STAMUS-5
 BRA FNDPT0
FNDPT2 RTS

* Draw note on graphics screen
DRAW0 LDD ADDRES test if memory limit is reached
 CMPD #LIMMEM
 BHI DRAW0A
 TST [ADDRES] do not allow entry if an option is
 BPL DRAW already entered
DRAW0A RTS
DRAW JSR TSTKEY check for key
 LDB VOICE DRAW NOTE ON STAFF
 LDX ADDRES CALCULATE ADDRESS OF NOTE VALUE
 DECB IN MUSIC CODE
 ABX X=ADDRESS+VOICE-1
 LDD ,X GET PRESENT NOTE VALUE
 BEQ L815 IF ZERO, POSITION EMPTY
L811 PSHS X ERASE NOTE
 LDX #PITCH
 JSR TBLSR1 CONVERT NOTE PITCH TO SCREEN POS.
 CMPD #$FFFF IS NOTE INVALID?
 BNE L811A
 LDB #58
L811A STB YVAR
L812 JSR FACDNT ADJUST FOR ACCIDENTALS
 CMPA #2
 BNE DRAW1
 DEC YVAR
 BRA L814
DRAW1 CMPA #1
 BNE L814
 INC YVAR
L814 PULS X
 CLR ,X
 CLR 1,X
 JMP SCRLCH
L815 PSHS X
 LDX ADDRES test for rest
 LEAX 1,X
 LDB #4
L815A LDY ,X++
 BNE L815B
 DECB
 BNE L815A
 LDA XVAR a rest is present; first erase it
 STA XVAR1
 JSR BLANK
L815B PULS X
 TST FLAT
 BEQ DRAW3
 INC YVAR
 BRA L820
DRAW3 TST SHARP
 BEQ L820
 DEC YVAR
L820 CLRA
 LDB YVAR
 PSHS X
 JSR LOOKUP
 PULS X
 STD ,X
L830 LDD ADDRES
 CMPD FINISH
 BLO L860
 ADDD #9
 STD FINISH
 JSR ENDMRK
L860 JSR TBLSR0
 TSTB
 BNE L875
 CLRA
 LDB NVALU
 JSR LOOKUP
 STB [ADDRES]
L875 TST FLAT
 BEQ L875A
 DEC YVAR
L875A TST SHARP
 BEQ L875B
 INC YVAR
L875B LDB VOICE set up COUNT0 for partial display if in effect
 ASRB
 STB COUNT0
DRNOTE TST FLAT draw note on screen
 BEQ DRNOTA
 LDY #FLATDT
 BRA PUTSF
DRNOTA TST SHARP
 BEQ L877
 LDY #SHRPDT
PUTSF LDD XVAR
 STD XVAR1
 JSR CURCAL
 LEAX $140,X
 LDB #8
PUTSF1 LDA ,Y+
 ANDA ,X
 STA ,X
 LEAX $20,X
 DECB
 BNE PUTSF1
L877 CLR FLAT
 CLR SHARP
 JSR TBLSR0 convert to keyboard code
 LDA ,X
L881 CLR TFLAG
 CMPB #3 check for triplet note
 BEQ L885A
 CMPB #5 check for 16th triplet
 BNE L885
L885A INC TFLAG
L885 DECA
PUT PSHS A save note code
 CMPA #2 if note>3 (quarter note), will need flag(s)
 BLE PUT0
 LDA #2
PUT0 LDB #14 calculate address of data to display
 MUL TABLE
 ADDD #DATDSP
 TFR D,Y Y is the data pointer
 LDD XVAR calculate display address
 STD XVAR1
 JSR CURCAL
LEDGER PSHS D,X write ledger lines
 LDD CURADR check for the top line
 PSHS D
 ADDD #480
 STD CURADR
 CMPD #$1360
 BHI LEDGA
 LDD #-32*6 D=increment
 STD TEMP
 LDX #$1360 X=starting address
 BRA LEDGAA
LEDGA CMPD #$17E0 check for bottom line
 BLO LEDGD
 LDD #32*6 B=increment
 STD TEMP
 LDX #$17E0 X=starting address
LEDGAA LDB XVAR
 LEAX B,X
LEDGB CLRA
 CLRB
 STD ,X
 LDD TEMP
 LEAX D,X
 CMPX CURADR
 PSHS CC
 TSTA
 BPL LEDGC
 PULS CC
 BGE LEDGB
 BRA LEDGD
LEDGC PULS CC
 BLE LEDGB
LEDGD PULS D
 STD CURADR
 PULS D,X
 PSHS X save display address
 LDB #18 number of lines to check
 CLR FFLAG check for flags already written
PUT1 LDA 1,X
 BEQ PUT1A
 CMPA #$FF
 BEQ PUT1A
 INC FFLAG
PUT1A LEAX 32,X
 DECB
 BNE PUT1
 LDX CURADR
 BSR PUT3 display note
 PULS X restore display address
 PULS A restore note value
 SUBA #2
 BLE PUT2 if quarter note or less, done
 TST FFLAG check if other flags
 BNE PUT2 have already been displayed
 STA COUNT1 number of flags to display
 PSHS X save display address
PUT1B LDB #6 6=number of words in flag
 STB COUNT
 STB TEMP
 LDY #DFLAG Y points to flag data
 BSR PUT4
 LEAX -$40,X
 DEC COUNT1
 BNE PUT1B
 PULS X restore display address
 TST TFLAG test triplet flag
 BEQ PUT2
 LEAX $20,X
PUT1C LDB #5 5=number of words in triplet marker
 STB COUNT
 STB TEMP
 LDY #DTRIP Y points to marker data
 BSR PUT4
PUT2 RTS
PUT3 LDB #12 set up counter
 STB COUNT
 CLR TEMP
 BSR PUT4
 LDB #6 display body of note
 STB COUNT
 INC TEMP
PUT4 LDD ,Y put data on screen
 TST TEMP check for single word display
 BEQ PUT4A
 LEAY 2,Y
PUT4A TST VDISP test for partial display
 BEQ PUT5
 PSHS A partial display in effect;
 LDA VDISP test whether the emphasized voice
 CMPA COUNT0 is to be displayed
 PULS A
 BEQ PUT5
 COM VDMASK reverse partial display mask
 ORA VDMASK or mask onto data
 ORB VDMASK
PUT5 ANDA ,X
 ANDB 1,X
 STD ,X
PUT5B LEAX $20,X  move screen pointer to next line
 DEC COUNT
 BNE PUT4 loop back if not done
 RTS

CURSOR LDA YVAR blink cursor
 ADDA #13
 STA YVAR1
 LDA XVAR
 STA XVAR1
 BSR CURSCH
CURSCH JSR CURCAL
 LDA #5
 STA TEMP
CURSC0 TST JSTFLG
 BEQ CURSC1
 LDD #$540 (alternate cursor when joystick on)
 BRA CURSC2
CURSC1 LDD #$FE0
CURSC2 EORA ,X
 STA ,X
 EORB 1,X
 STB 1,X
 LEAX $20,X
 DEC TEMP
 BNE CURSC0
 LDX #$600 time delay for blinking
 JMP DELAY

* calculate cursor screen address
* screen address returned in X

CURCAL LDA XVAR1
 STA TEMP
 LDA YVAR1
 LDB #$20
 MUL
 ADDD #SCREEN
 ADDB TEMP
 ADCA #0
 STD CURADR
 TFR D,X
 RTS

* Scroll graphics screen if necessary
TSTSCR LDA XVAR test for scroll
 CMPA #2 are we at the left edge
 BEQ L1200
 CMPA #30 are we at the right edge
 BEQ L1240
 RTS
L1200 LDY #BEGINS shift display forward
LOOP0 LDD #$1A1C
LOOP1 LDX A,Y
 STX B,Y
 SUBD #$202
 CMPA #1
 LBHI LOOP1
 LEAY $20,Y
 CMPY #ENDSH
 BLO LOOP0
 LDA #4
 STA XVAR
 JMP L1310
L1240 LDY #BEGINS shift display backwards
LOOPA LDD #$604
LOOPB LDX A,Y
 STX B,Y
 ADDD #$202
 CMPA #$20
 BNE LOOPB
 LEAY $20,Y
 CMPY #ENDSH
 BLO LOOPA
 LDA #28
 STA XVAR
 JMP SCRLCH

*Delete 9 bytes at current pointer
DELETE LDX ADDRES X is the address pointer (USR6)
 CMPX FINISH prevent delete if at end of text
 BLO DELET0
 RTS
DELET0 LEAY 9,X start of next cell
DELET1 LDA ,Y+
 STA ,X+
 CMPY FINISH done yet?
 BLE DELET1 move next cell if NVALU>0
 LDD FINISH
 SUBD #9
 STD FINISH
 JSR ENDMRK
 JMP UPDATE

*Insert 9-byte cell at current pointer
INSERT LDX FINISH
 CLR ,X
 LEAX 1,X
 LEAY 9,X Y points to cell above X
 CMPY #LIMMEM+18 make sure we have enough memory
 BLS INSRT3
 RTS
INSRT3 LDA ,-X move data from X
 STA ,-Y to Y pointers
 CMPX ADDRES
 BHI INSRT3 loop back if not done
 LDD FINISH
 ADDD #9
 STD FINISH
 JMP ENDMRK

TBLSR0 CLRA
 LDB [ADDRES]
TBLSR LDX #TABLE find entry in table equal to register D
TBLSR1 CMPD #0
 BEQ TBLSR3
 TSTA IF A=0 do LSB compare only
 BNE TBLS1A
 LEAX 2,X increment pointer so it doesn't
 CMPB -1,X interfere with comparison
 BRA TBLS2A
TBLS1A CMPD ,X++ compare D with table value
TBLS2A BEQ TBLSR2 value found
 STD TEMP1
 TST UFLAG check if corrective search
 BEQ TBLS2C
 SUBD -2,X value not found,
 CMPD #$FFFF but does it differ by 1?
 BEQ TBLS2B (only happens from fast play)
 CMPD #1
 BNE TBLS2C
TBLS2B LDD -2,X value found
 STD TEMP keep correct value in temp
TBLS2C LDD TEMP1
 CMPX #PITCH+$AA check for end of table
 BLE TBLSR1
 LDU #TBSERR
 JSR DSPMSG
 LDD #$FFFF not found, D=FFFF
 RTS
TBLSR2 LEAX -2,X value found, adjust X
 TFR X,D
 SUBD #TABLE
 ASRA divide address by 2
 RORB
TBLSR3 STD TEMP1 save to be used by USR4
 RTS
TBSERR FCC "UNRECOGNIZED PITCH"
 FDB $AE00

*Table look-up for value in D
LOOKUP ASLB MULTIPLY BY 2
 LDX #TABLE
 ABX ADD B OFFSET TO X
 LDD ,X LOAD TABLE VALUE INTO D
 RTS

FACDNT LDB YVAR find accidentals
 CLRA
 TFR D,Y
 CLR FLAT
 CLR SHARP
 EXG B,A
 SUBA #13
DIV SUBA #3
 BLE DIV0
 BRA DIV
DIV0 NEGA
 RTS

SCRLCH LDA YVAR DISPLAY SCROLLED CHORD
 STA YVAR2 ADDRES,XVAR,YVAR must be set
 LDA XVAR
 STA XVAR1
 JSR BLANK ERASE AREA OF STAFF
L1310 LDA #1
 STA COUNT0 NUMBER OF NOTES IN A CHORD COUNTER
 LDX ADDRES
 LDA ,X+ TEST FOR MSBIT=1 (OPTION)
 BMI OPTION
 BEQ L1350A test for end of music
L1320A PSHS X
 LDB #4
L1320B LDY ,X++ TEST FOR REST
 BNE L1320
 DECB
 BNE L1320B
 PULS X
 JMP KEYR1 DISPLAY REST IF PRESENT
L1320 PULS X
 LDD ,X++
 PSHS X
 LDX #PITCH find screen position
 JSR TBLSR1 CODE FROM PITCH TABLE
 CMPD #$FFFF TEST FOR INVALID NOTE VALUE
 BEQ L1350
L1320F STB YVAR
 TSTB
 BEQ L1350
 JSR FACDNT SET/FLAT SHARP FLAGS
 TSTA
 BEQ L1340
 CMPA #2
 BNE L1337
 DEC FLAT
 DEC YVAR
L1337 CMPA #1
 BNE L1340
 DEC SHARP
 INC YVAR
L1340 JSR DRNOTE DRAW NOTE ON SCREEN
L1350 INC COUNT0 TEST TO SEE WHETHER ALL
 LDA COUNT0 4 VOICES HAVE BEEN DISPLAYED
 CMPA #4
 BLE L1320
 PULS X
 LDA YVAR2
 STA YVAR
L1350A RTS

NOTVAL TST [ADDRES] CHECK FOR OPTION
 BMI NOTVL1 IF OPTION, ABORT
 TFR A,B
 CLRA
 STB NVALU
 JSR LOOKUP
 STB [ADDRES]
 JMP SCRLCH
NOTVL1 RTS

OPTION LDA [ADDRES]
 CMPA #$FF
 LBEQ KEYM
 CMPA #$FE
 LBEQ NEWPNT
 CMPA #$FD
 LBEQ REPEAT
 CMPA #$FC
 LBEQ RPTMR0
 CMPA #$FB
 LBEQ PRTMR0
 RTS

* Count option
* Register A contains option code on entry
* On exit, register A contains number of times this option is
*  present in the music code up to and including the current cursor

CNTOPT PSHS B,X
 STA TEMP
 CLRB B is the counter
 LDX #STAMUS
CNTOP1 LDA ,X test chord descriptor
 BEQ CNTOP3 test for end of music
 BMI CNTOP4 test for option
CNTOP2 LEAX 9,X move to next chord
 CMPX ADDRES loop back if we have not passed
 BLE CNTOP1 the current cursor position
CNTOP3 TFR B,A put count in A
 PULS B,X,PC
CNTOP4 CMPA TEMP is this the right option?
 BNE CNTOP2
 INCB desired option found, so increment counter
 BRA CNTOP2

CNTOPM FCB 0,0,0

UPDATE JSR CLRMES update the display
 LDA XVAR update the display
 LDX ADDRES
 PSHS A,X save XVAR and addres
L1757 LDD ADDRES
 CMPD FINISH
 BNE L1760
 LDA XVAR
 STA XVAR1
 JSR BLANK
 BRA L1790
L1760 JSR SCRLCH
 LDD ADDRES
 ADDD #9
 STD ADDRES
L1790 LDA XVAR
 ADDA #2
 STA XVAR
 CMPA #30 test for end of screen
 BLO L1757
 PULS A,X restore xvar and addres
 STA XVAR
 STX ADDRES
 RTS

DSPTTL LDU #TITLE
 LDX #MSGADR+(2*32)
 BRA GETMSG
DSPMSG LDX #MSGADR DISPLAY MESSAGE SUBROUTINE

* ALPHA-NUMERICS GENER.
* U MUST POINT TO THE
* DESIRED MESSAGE.
* X MUST POINT TO THE DESIRED
* DISPLAY ADDR.

GETMSG LDA #1 TURN OFF HI RES
 STA HIRES
GETMS1 LDA ,U+
 BEQ GETMS2 0 IS THE END OF MESSAGE MARKER
 BMI PRTSPA IF MSBIT=1 THEN PRINT SPACES
 JSR PRINT
 BRA GETMS1
GETMS2 RTS DONE: RETURN
PRINT TST HIRES
 BNE PRINTT
 SUBA #'0 CONVERT TO HEX
 BMI GETMS2 CONTROL CHARACTERS NOT DISPLAYED
PRNT0 LDB #8
 MUL
 ADDD #CHTABL ADD TABLE OFFSET
 CMPD #CHEND IS POINTER BEYOND
 BGE GETMS2 END OF TABLE?
 TFR D,Y Y IS THE TABLE POINTER
 LDB #$80
PRINT1 LDA ,Y+
 LSRA
 COMA
 STA B,X
 ADDB #32
 CMPB #$80
 BNE PRINT1
 LEAX 1,X
 TFR X,D
 ANDB #$1F TEST FOR END OF LINE
 BEQ NXTLIN
 RTS
NXTLIN LEAX $120,X
 RTS
PRINTT CMPA #1 CHECK FOR CURSOR
 BEQ PRNTT1
 CMPA #$40 LORES PRINT
 BGE PRNTT2 CONVERT TO SCREEN CODE
 ADDA #$40
 BRA PRNTT2
PRNTT1 LDA #$AF
PRNTT2 STA ,X+
 RTS
PRTSPA ANDA #$7F PRINT UP TO 127 SPACES
 STA COUNT
PRTSP1 LDA #32
 JSR PRINT
 DEC COUNT
 BNE PRTSP1
 JMP GETMS1

* Binary to decimal convert
* 2-byte data in "D";
* output pointed to by X.
* X,Y,D,CC modified.

POWERS FDB 10000
 FDB 1000
 FDB 100
 FDB 10

HEXBCD CLR DIGCNT
 CLR PWRCNT
 LDX #OUTDEC
 LDY #POWERS
 PSHS D
SUBTR LDD ,S
SUBTR1 SUBD ,Y
 BMI SUBTR2
 INC PWRCNT
 STD ,S
 BRA SUBTR1
SUBTR2 LDA PWRCNT
 LDB DIGCNT
 ADDA #'0
 STA B,X
 LEAY 2,Y
 CLR PWRCNT
 INC DIGCNT
 LDB DIGCNT
 CMPB #4
 BLE SUBTR
 LDA 1,S
 ADDA #'0
 DECB
 STA B,X
ERAZER LDA ,X
 CMPA #'0
 BNE COMPLT
 LDA #' 
 STA ,X+
 BRA ERAZER
COMPLT LEAS 2,S
 RTS

OUTDEC RMB 5 output decimal string
 FCC "=MEMORY"
 FDB $8500

PRTMEM LDD #LIMMEM+27 calculate memory free
 SUBD FINISH
 LDU #0 DIVIDE BY 9
PTMEM1 SUBD #9
 BLO PTMEM2
 LEAU 1,U
 BRA PTMEM1
PTMEM2 TFR U,D
 SUBD #2
 JSR HEXBCD convert to decimal
 LDX #MEMADR
 LDA OUTDEC+4 test for zero memory
 CMPA #' 
 BNE PTMEM3
 LDA #'0
 STA OUTDEC+4
PTMEM3 LDU #OUTDEC+1 U points to number string
 JMP GETMSG write string to display

PRTVOI LDA VOICE display the voice number
 LSRA
 ADDA #$30
 STA DECVOI
 LDX #MEMADR+17
 LDU #VOIMSG
 JMP GETMSG
VOIMSG FCB $88
DECVOI RMB 1
 FCC "=VOICE"
 FCB 0

NEWPNT LDA XVAR display voice table pointers
 STA XVAR1
 JSR BLANK
 LDA XVAR
 STA XVAR1
 LDA #43
 STA YVAR1
 JSR CURCAL
 LEAX $120,X
 STX CURADR
 JSR DISPNT
 JSR CNVDEC convert tempo to decimal string
 LDU #VTBSTR-1 transfer to new string
 STD 0,U
 LDX CURADR display string on staff
 LEAX $120,X skip a line
 CLR HIRES
 JMP GETMS1
PRNTVT PSHS D,X
 LDX CURADR
 LDU #VTBSTR
 CLR HIRES
 JSR GETMS1
 LDD #$120
 ADDD CURADR
 STD CURADR
 PULS D,X,PC
DISPNT LDX ADDRES print voice table numbers
 LDB #1 B is the number of voices counter
DISPT1 LDA B,X display the pointers
 SUBA #BASEWV
 ADDA #'1
 STA VTBSTR
 JSR PRNTVT
 INCB
 CMPB #5
 BLO DISPT1
 RTS
 FCB 0
VTBSTR FDB 0
CNVDEC LDX ADDRES convert tempo to decimal
 LDB 5,X load tempo then display it
CNVDC0 LSRB divide by 2
 CLRA
 JSR HEXBCD convert to decimal string
 LDU #OUTDEC+3 change spaces in string to "0"
 LDD 0,U
 CMPA #' 
 BNE CNVDC1
 LDA #'0 
CNVDC1 CMPB #' 
 BNE CNVDC2
 LDB #'0
CNVDC2 RTS

SETDPA PSHS A
 LDA #DPAGE
SETDP1 TFR A,DP
 PULS A,PC
CLRDPA PSHS A
 CLRA clear DP register
 BRA SETDP1
 SETDP DPAGE

* Key input
* cancel operation if BREAK is detected
GETKEY JSR CLRDPA
 SYNC
 JSR [KEYIN]
 JSR SETDPA
 CMPA #3 test for BREAK
 BEQ BREAK
 TSTA
 RTS
BREAK JSR CLRMES
 LDS >STACK
 JMP MENU

* Get hex input from keyboard (0-9, A-F)

GETVCE JSR GETKEY get voice number input (1-4)
 CMPA #'1
 BLO GETVCE
 CMPA #'4
 BHI GETVCE
 RTS

* delay subroutine; X=delay value
DELAY LEAX -1,X
 BNE DELAY
 RTS

DOTBLS LDX #HRMPNT+5+(3*13) resynthesize tablets
 LDU #BASWAV+$300
DOTBL1 PSHS X,U
 JSR SINE
 PULS X,U
 LDA -2,X
 PSHS X,U
 TFR U,X
 JSR SCALET
 PULS X,U
 LEAU -$100,U
 LEAX -13,X
 CMPU #BASWAV
 BGE DOTBL1
 RTS

* scale tablee* A=ASCII volume
* X contains address of table to scale down
SCALET SUBA #'0
SCALE0 LDB #27
 MUL convert to a factor
 STB TEMP store factor in TEMP
 CLR COUNT
SCALE1 LDA ,X perform scaling of table
 LDB TEMP
 MUL
 STA ,X+
 DEC COUNT
 BNE SCALE1
 RTS

* SINE requires that U points to target tone table and X
* points to ASCII descriptor string                    

SINE LDA #1 make new tone table
 STA HRMCNT set harmonic count=1
 PSHS X save pointer
 LDX #OUTTAB clear output table
 LDD #0
SINE0 STD ,X++
 CMPX #OUTTAB+$200
 BLO SINE0
 PULS X
 LDY #HRMAMP Y points to binary amplitudes
 PSHS Y
 LDB #8
 STB COUNT
SINE0A LDA ,X+ get ASCII value
 SUBA #'0 and convert it to binary
 CMPA #9
 BLE SINE0B
 SUBA #7
SINE0B LDB #16 scale 0-9 to 0-252
 MUL
 TFR B,A
 STA ,Y+ save binary amplitude
 DEC COUNT test to see if all is done
 BNE SINE0A
 PULS Y
 LDX #SINTAB X points to sine table
 PSHS U
SINE1 LDU #OUTTAB U points to output table
SINE2 LDB SINPNT
 CLRA
 LDA D,X load sine table element
 LDB ,Y load harmonic amplitude
 BEQ SINE3
 MUL calculate table value
 TFR A,B
 CLRA
 ADDD ,U add to output table
 STD ,U++ store in table
 LDB HRMCNT update sine pointer
 ADDB SINPNT
 STB SINPNT
 CMPU #OUTTAB+$200
 BLO SINE2 loop back if not done
SINE3 INC HRMCNT increment harmonic counter
 LEAY 1,Y increment amplitude pointer
 CMPY #HRMAMP+8 done?
 BLO SINE1
 LDX #OUTTAB find largest element in output table
 CLR TEMP
 CLR TEMP+1
SINE4 LDD ,X++
 CMPX #OUTTAB+$200
 BGE SINE5
 CMPD TEMP
 BLE SINE4
 STD TEMP
 BRA SINE4
SINE5 LDU #0 U will hold quotient
 LDD #$FFFF
SINE6 SUBD TEMP TEMP=maximum value
 LEAU 1,U
 BCC SINE6 is carry flag clear?
 LDX #OUTTAB+$1FE
 LDY #OUTTAB+$200
 STU TEMP1
SINE8 LDD #0 16X16 bit multiply
 STD MULT
 LDA 1,X
 LDB TEMP1+1
 MUL
 STD MULT+2
 LDA 0,X
 LDB TEMP1+1
 MUL
 ADDD MULT+1
 STD MULT+1
 LDA 1,X
 LDB TEMP1
 MUL
 ADDD MULT+1
 STD MULT+1
 BCC SINE9
 INC MULT
SINE9 LDA 0,X
 LDB TEMP1
 MUL
 ADDD MULT
 STD MULT
 LDD MULT+1
 LSRA scale all table values to 0-$7F
 RORB
SINE9A STB ,-Y store result (only msb) in table
 LEAX -2,X
 CMPX #OUTTAB done yet?
 BGE SINE8
 PULS U U points to new table location
 LDX #BASWAV move basewave table
SIN10A LDD ,X++ to desired location
 STD ,U++
 CMPX #BASWAV+$100
 BLO SIN10A
 RTS DONE; return

* Play all music files on current drive

PLYALL LDA #1 set flag to indicate
 STA PALFLG that play all is in effect
 CLR OUTRDY
 LDX $C006
 LDD 4,X get current buffer pointer
 STD OLDBPT and save it
 LDD #$01DA (area for cassette buffer)
 STD BUFPNT
 LDD #STAMUS
 STD ADDRES
 LDD #$43A set cursor to origin
 STD XVAR
NXTFIL JSR LOWRES
 LDY #EXT
 JSR DIR
 BCC PLYAL3 done; return
 LDB #8
 LDY #LODNAM
GETNAM LDA ,X+
 STA ,Y+
 DECB
 BNE GETNAM
 LDX $C006
 LDY 4,X
 LDD OLDBPT restore old buffer pointer
 STD 4,X
 LDD $A6 save program pointer
 PSHS D,X,Y
 JSR CLRDPA
 LDX #LOAD
 STX $A6
 LDA ,X
 ANDCC #$FE make flag "not a line #"
 JSR $ADC6 call BASIC
 PULS D,X,Y
 STD $A6
 STY 4,X
 CLR $FF40 stop disk motor
 JSR SETDPA
 LDY #HRMPNT set up pointers after load
 LDB #53+65 (53=4*13+1,65=bytes in title)
 LDX $9D
 STX FINISH
 CLR [FINISH]
 LDA 1,X
 CMPA #$39
 BNE PLYAL1
 LEAX 2,X
 JSR MOVED
 CLR TITLE+64
 BRA PLYAL2
PLYAL1 LDX #HRMSTR
 JSR MOVED
 JSR CLRTTL
PLYAL2 JSR KEYP play music
 CMPA #3 test for BREAK
 BEQ PLYAL3 return if pressed
 BRA NXTFIL
PLYAL3 LDX $C006 done; put old buffer
 LDD OLDBPT pointer back
 STD 4,X
 CLR PALFLG
 JSR UPDATE
 JMP SETGRA

LOAD FCB $D3 LOAD token
 FCC /M"/
LODNAM FCC "        /"
EXT FCC "MUS"
 FCB 0

* Read directory
* ENTRY:
*  Y points to desired extension
*  OUTRDY must be set to 0 on first entry
*  BUFPNT must point to disk buffer
* EXIT:
*  X points to desired filename if Carry =1

DIR TST OUTRDY check for ready output
 BNE TEST0
 LDX $C006 prepare DSKCON parameters
 LDA #2
 STA 0,X read sector
 LDA $95A get default drive #
 STA 1,X
 LDA #17
 STA 2,X select track 17
 LDA #3
 STA 3,X select sector 3
 STA SECTOR
 LDD BUFPNT
 STD 4,X set buffer to $600
 ADDD #$100
 STD BUFEND
 INC OUTRDY
READ JSR CLRDPA
 JSR [$C004] call DSKCON
 JSR SETDPA
 TST 6,X test for errors
 BNE DIRDNE
TEST0 LDX BUFPNT X points to read data
 CMPX BUFEND test for end of buffer
 BEQ NEXT1
 LDA ,X test for last directory entry
 CMPA #$FF
 BEQ DIRDNE
 LDB #2
 LEAU 8,X point to file extension
TEST1 LDA B,U test for the right extension
 CMPA B,Y Y contains address of desired extension
 BNE NEXT
 DECB
 BPL TEST1
 TST ,X test for erased file
 BEQ NEXT
 PSHS X file found; set buffer pointer
 LEAX $20,X X to point to next filename
 STX BUFPNT
 PULS X
 ORCC #1 set carry flag to =1 (file found)
 RTS return with X pointing to filename
NEXT LEAX $20,X move to next
 STX BUFPNT
 BRA TEST0
NEXT1 LEAX -$100,X reset buffer pointer to start
 STX BUFPNT
 LDX $C006
 LDA SECTOR increment sector number
 INCA
 CMPA #11 check whether we are at the end of directory
 BHI DIRDNE
 STA SECTOR
 STA 3,X
 LDA #17
 STA 2,X reset to track 17
 BRA READ
DIRDNE ANDCC #$FE set carry flag to =0 (no file)
 RTS done; return

* performs directory of files
* extension pointed to by Y

DIRECT JSR CLS
 JSR LOWRES
 CLR OUTRDY
 LDD #$600
 STD BUFPNT
GNEXT PSHS Y
 JSR DIR
 PULS Y
 BCC DIREC1
 BSR PRTSP
 LDB #8
PRNT LDA ,X+
 BSR PRTSS
 DECB
 BNE PRNT
 BSR PRTSP
 BRA GNEXT
DIREC1 LDA #$0D
 JMP PRTSS

PRTSP PSHS D
 LDA #' 
 LDB #4
PRTS1 BSR PRTSS
 DECB
 BNE PRTS1
 PULS D,PC

PRTSS JSR CLRDPA
 JSR [$A002]
 JMP SETDPA

* clear low-res screen, set BASIC cursor to home
CLS LDX #$400
 STX >$88
 LDD #$6060
CLS1 STD ,X++
 CMPX #$600
 BNE CLS1
 RTS

* Interrupt routine to generate split mode display
IRQ LDA $FF00 clear horz sync
 LDA #8 set red text mode
 STA $FF22
 STA $FFC0
 STA $FFC2
 STA $FFC4
 LDB #37+12
 BSR SCRCNT do 1 line
 CLR $FF22
 LDB #12*4 do 4 green text lines
 BSR SCRCNT
 LDA #8 do one red text line
 STA $FF22
 LDB #12
 BSR SCRCNT
 LDA #$F0 set pmode 4
 STA $FF22
 STA $FFC3
 STA $FFC5
 NOP
OLDIRQ JMP 0 return through old irq
SYNC LDA $FF01 wait for sync
 BPL SYNC
 LDA $FF00
 PSHS X,Y,B time delay
 PULS X,Y,B
 RTS
SCRCNT BSR SYNC
 DECB
 BNE SCRCNT
 RTS

* set up vdg chip for high-res display at $0E00 
SETGRA STA $FFC9
 STA $FFC7
 STA $FFCB
 LDA #$36 disable horizontal sync
 STA $FF01
 STA $FF03 disable vert sync
 ORCC #$50 disable interrupts
 LDX #IRQ store new address
 STX $10D in irq hook
 LDX RESIRQ
 STX OLDIRQ+1
 LDA #$37 enable vert sync
 STA $FF03
 ANDCC #$AF enable interrupts
 RTS

* move data routine
* Move data from X to Y, number of bytes in B
MOVED LDA ,X+
 STA ,Y+
 DECB
 BNE MOVED
 RTS

* set low res graphics
LOWRES ORCC #$50
 STA $FFC2
 STA $FFC4
 CLR $FF22
 STA $FFC6 AT $400
 STA $FFCA
 LDD RESIRQ restore old irq address
 STD $10D
 ANDCC #$AF
 RTS

* Play routine
* Registers used:
*  X=points to music code
*  U=points to voice pointers
*  Y=tempo counter

PLAY LDA $FF01 turn on tv sound port
 ANDA #$F7
 STA $FF01
 LDA $FF03
 ANDA #$F7
 STA $FF03
 LDA #$3C
 STA $FF23
 CLR TEMPO
 CLR TEMP clear 1st repeat flag
 CLR TEMP1 clear 2nd repeat flag
 JSR LOWRES
 ORCC #$50 disable interrupts
 CLRA
 CLRB
 STD FIRSTP clear first part pointer
 LDX FINISH locate all the repeat part markers
 LEAX 9,X
FNDPRT LEAX -9,X start at the end of music and work back
 CMPX #STAMUS
 BLO PLAYA1
 LDA ,X
 CMPA #$FB
 BEQ FNDPR1
 BRA FNDPRT
FNDPR1 LDD FIRSTP write address of next marker in this one
 STD 1,X
 STX FIRSTP
 BRA FNDPRT
PLAYA1 CLR $FF02 prepare for fast keyboard read
 LDU #V1PT used for table look ups (faster)
 TST STEREO
 BNE PLAY2
 LDX #MAINTV
 BRA PLAY3
PLAY2 LDA $FF03 turn cartridge sound on
 ORA #8
 STA $FF03
 LDX #MAINST
PLAY3 LDY #MAIN1
 LDB #17
 JSR MOVED
PLAY0 LDX #STAMUS-5 X=note pointer
 LDA ,X+ load tempo
 STA TEMPO+1
 LDD ,X++ load tone table high addresses
 STA <V1PT
 STB <V2PT
 LDD ,X++
 STA <V3PT
 STB <V4PT
 CLRA
 CLRB
 STD RPTADR
 LDX ADDRES get starting play address
 BRA NEWNT1
OPTINP CMPA #$FC test for section repeat ($FB marks sections)
 BNE SECREP
 LDD RPTADR check for a return address from $FB repeat code
 CMPD #0 if not zero, treat this as a marker ($FB)
 BNE SECRE1
 LDD FIRSTP get address of first part
 BEQ NEWNOT
 PSHS U
 TFR D,U
 STX RPTADR save current music pointer
 LDB 1,X get get section repeat number
LOCPAR DECB
 BEQ LOCPA1
 LDU 1,U get next address
 BEQ LOCPA2
 BRA LOCPAR
LOCPA1 TFR U,X now we have the right part
LOCPA2 PULS U
 BRA NEWNOT start playing from new address
SECREP CMPA #$FB test for repeat section marker
 BNE RPTP
 LDD RPTADR check for a return address from $FB repeat code
 CMPD #0 if zero, no return address
 BEQ NEWNOT go get next chord
SECRE1 TFR D,X otherwise get return address
 CLRA
 CLRB
 STD RPTADR
 BRA NEWNOT and play
RPTP CMPA #$FD test for repeat
 BNE OPTINQ
 TST TEMP check to see if previous repeat encountered
 BEQ RPTP1
 LDX TEMP load repeat address
 CLR TEMP
 INC TEMP1 mark this bar so it wont be re-read
 BRA NEWNT1
RPTP1 TST TEMP1 is this the 2nd repeat bar?
 BNE SKIPRP if so, skip
 TFR X,D
 ADDD #9
 STD TEMP first repeat; save address
 BRA NEWNOT
SKIPRP CLR TEMP1
 BRA NEWNOT
OPTINQ CMPA #$FE test for new wave table pointers
 BNE NEWNOT
 LDD 1,X update wave table pointers
 STA <V1PT
 STB <V2PT
 LDD 3,X
 STA <V3PT
 STB <V4PT
 LDA 5,X update tempo
 STA <TEMPO+1
NEWNOT LEAX 9,X update note pointer
NEWNT1 LDA ,X load duration
 BGT NEWNT2 skip tests if a note
 BMI OPTINP if duration>$7f, not a note
 BEQ PLAY4
NEWNT2 STA <DUR
 LDY <TEMPO
MAIN CLRA
 LDB [0,U] output voices to sound port
 ADDB [6,U]
MAIN1 STB $FF70 this section modified for
 LDB [3,U] TV or stereo output
 ADDB [9,U] *
 STB $FF72 *
 STB $FF72 *
 ANDA #$FF *
 LDD #0 add 3 cycles to correct pitch
 LDD <V1PT+1 increment voice pointers
 ADDD 1,X
 STD <V1PT+1 only the lsb and "fractional" bytes change
 LDD <V2PT+1
 ADDD 3,X
 STD <V2PT+1
 LDD <V3PT+1
 ADDD 5,X
 STD <V3PT+1
 LDD <V4PT+1
 ADDD 7,X
 STD <V4PT+1
 LEAY -1,Y update tempo counter
 BNE TSTKBD
 DEC <DUR update duration counter
 BEQ NEWNOT
 LDY <TEMPO restore tempo counter
 BRA MAIN
TSTKBD CMPX ,S (to equalize loop times)
 LDA $FF00 test for keypress
 ORA #$80
 CMPA #$FF
 BEQ MAIN
PLAY4 PSHS X
 LDX #$FF00
 LDA #$34 turn off sound port
 STA $FF23
 LDA #8
 ORA 1,X
 STA 1,X
 LDA #8
 ORA 3,X
 STA 3,X
 PULS X,PC

MAINST STB $FF70
 LDB [3,U]
 ADDB [9,U]
MAINS1 STB $FF72
 LDD #0 (space filler)
 ANDA #$FF (space filler)

MAINTV ADDB [3,U]
 ADCA #0 allow for carry
 ADDB [9,U]
 ADCA #0
 LSRA adjust for tv output
 RORB
 ANDB #$FC protect printer
 STB $FF20

OUTKEY JSR CLRDPA
 JSR [KEYOUT]
 JMP SETDPA

 INCLUDE MUSKEY
 INCLUDE MUSICA01
 INCLUDE MUSICA02

 END INSTAL
