 TITLE "OPTION"
************************************
* OPTION/TXT
* Part of Lyra for the CoCo
* (C) 1986, 1987 by Lester Hands
* Last update: 07-aug-88
* Last update:  3-jun-90 modifications (c) R.Gault
************************************

*MSG "OPTION=",*

EVNTOPT EQU $80
INSTOPT EQU $90
TEMPOPT EQU $A0
BYTEOPT EQU $B0
OCTVOPT EQU $C0
LOCOOPT EQU $D0
VOL_OPT EQU $E0
CLK_OPT EQU $F0

*SOPTOCTV - set octave up transpose marker
*ENTRY: called from EDITNOTE
*EXIT: appropriate code inserted into current voice
* and display updated.
*
SOPTOCTV PSHS D,X
 LBSR INSERT
A@ LDX #DSP_CURS
 LDB VOICE
 LSLB
 ABX
 LDA #OCTVOPT
 LDB VPOS
 LBSR CNV_DICO
 STD [,X]
 PULS D,X,PC
OCTVDAT FCB 10 number of words in cursor
 FDB 0,0,0
 FDB $620D,$9311 "8va"
 FDB $9293,$644D
 FDB $9000,$9000
 FDB $6000

*SOPTLOCO - cancel octave
*ENTRY: called from EDITNOTE
*EXIT: appropriate code inserted into current voice
* and display updated.
*
SOPTLOCO PSHS D,X
 LBSR INSERT
A@ LDX #DSP_CURS
 LDB VOICE
 LSLB
 ABX
 LDA #LOCOOPT
 LDB VPOS
 LBSR CNV_DICO
 STD [,X]
 PULS D,X,PC
LOCODAT FCB 10 number of words in cursor
 FDB 0,0,0
 FDB $C464,$AA8A "loco"
 FDB $8A8A,$8464
 FDB $8000,$8000
 FDB $8000

*SOPTCLK - set MIDI clock
*ENTRY: called from EDITNOTE
*EXIT: appropriate code inserted into voice 1
* and display updated.
*
SOPTCLK PSHS D,X,Y
 LDX #a@ display requester
 LBSR SETREQ
 LBSR DSPREQ
 LDY #d@
 LBSR REQINPTE
 LBSR REFMEN erase requester
 CMPA #3 check for BREAK
 BEQ Z@
 LDB VOICE insert into voice 1
 PSHS B
 CLR VOICE
 LBSR INSERT
 PULS B
 STB VOICE
A@ LDB b@
 SUBB #$2D if B<>0 then clock is ON
 LDA #CLK_OPT set option code
 STD [DSP_CURS] put in voice 1
 CLR DSPEDIT update display
Z@ PULS D,X,Y,PC
a@ FCB 48 VPOS
 FCB 5 HPOS
 FCB 23 width of requester
 FCB 3 height of requester
 FCB 2 length of input
 FDB b@ address of input area
 FCC "MIDI clock on+ off-:  "
b@ FCC "-"
 FCB 0 end of requester
d@ FCC "+" edit string

*SOPTBYTE - set MIDI byte
*ENTRY: called from EDITNOTE
*EXIT: appropriate code inserted into voice 1
* and display updated.
*
SOPTBYTE PSHS D,X,Y
 LDX #a@ display requester
 LBSR SETREQ
 LBSR DSPREQ
 LDY #d@
 LBSR REQINPTE
 LBSR REFMEN erase requester
 CMPA #3 check for BREAK
 BEQ Z@
 LDB VOICE insert into voice 1
 PSHS B
 CLR VOICE
 LBSR INSERT
 PULS B
 STB VOICE
A@ LDD b@ get ASCII hex to convert
 LBSR HEXBIN
 TFR A,B
 LDA #BYTEOPT set option code
 STD [DSP_CURS] put in voice 1
 CLR DSPEDIT update display
Z@ PULS D,X,Y,PC
a@ FCB 48 VPOS
 FCB 5 HPOS
 FCB 23 width of requester
 FCB 3 height of requester
 FCB 2 length of input
 FDB b@ address of input area
 FCC "MIDI byte (00-FF): "
b@ FCC "00"
 FCB 0 end of requester
d@ FCC "$$" edit string

*SOPTVOL - set MIDI volume
*
SOPTVOL PSHS D,X
 LDX #a@ display list of volumes
 LBSR SETREQ
 LBSR DSPREQ
A@ LBSR KEYIN get volume number
 CMPA #3
 BEQ Z@
 CMPA #'1
 BLO A@
 CMPA #'8
 BHI A@
 LBSR REFMEN erase volumes list
 LDX #DSP_CURS
 LDB VOICE
 LSLB
 ABX
 SUBA #'1 convert to binary
 ORA #VOL_OPT
 LDB VPOS
 LBSR CNV_DICO
 LBSR INSERT
 STD [,X]
Z@ PULS D,X,PC
a@ FCB 48 VPOS
 FCB 7 HPOS
 FCB 16 width of requester
 FCB 6 height of requester
 FCB 0 length of input
 FDB 0 address of input area
 FCC "ppp : 1   mf : 5"
 FCB 13
 FCC " pp : 2    f : 6"
 FCB 13
 FCC "  p : 3   ff : 7"
 FCB 13
 FCC " mp : 4  fff : 8"
 FCB 0

VOLPTRS FDB b@,c@,d@,e@ pointers to volume
 FDB f@,g@,h@,i@ graphics
b@ FCB 8 number of words in graphic
 FDB $8420,$8420 "ppp"
 FDB $4210,$5AD6,$2529
 FDB $2529,$35AD,$6B5A
c@ FCB 8 "pp"
 FDB $4080,$2040
 FDB $1020,$162C,$1932
 FDB $0891,$0C99,$1B36
d@ FCB 8 "p"
 FDB $0800,$0400
 FDB $0200,$02C0,$0320
 FDB $0110,$0190,$0360
e@ FCB 8 "mp"
 FDB $0080,$0040
 FDB $0020,$492C,$4932
 FDB $2491,$2499,$DB36
f@ FCB 10 "mf"
 FDB $00C0,$0020,$4920
 FDB $4920,$2490,$2490
 FDB $DB3E,$0008,$0008
 FDB $0006
g@ FCB 10 "f"
 FDB $0C00,$0200
 FDB $0200,$0100,$0100
 FDB $03E0,$0080,$0080
 FDB $0080,$0060
h@ FCB 10 "ff"
 FDB $3180,$0840
 FDB $0840,$0420,$0420
 FDB $0FFC,$0210,$0210
 FDB $0210,$018C
i@ FCB 10 "fff"
 FDB $6660,$1110
 FDB $1110,$0888,$0888
 FDB $3FFE,$0444,$0444
 FDB $0444,$0333

*SOPTTEMP - set tempo option
*ENTRY: called from EDITNOTE
*EXIT: appropriate option code inserted into
* voice 1 and display updated.
*
SOPTTEMP PSHS D,X,Y
 LDX #a@ display requester
 LBSR SETREQ
 LBSR DSPREQ
 LDY #d@
 LBSR REQINPTE
 LBSR REFMEN erase requester
 CMPA #3 check for <BREAK>
 BEQ Z@
 LDB VOICE insert space in voice 1
 PSHS B save current voice
 CLR VOICE
 LBSR INSERT
 PULS B restore current voice
 STB VOICE
 LDX #b@ point to ASCII to convert
 LDB #2 number of digits
 LBSR ASCBIN
 LDA #TEMPOPT set option code
 STD [DSP_CURS] put in voice 1
 CLR DSPEDIT
Z@ PULS D,X,Y,PC
a@ FCB 48 VPOS
 FCB 4 HPOS
 FCB 23 width of requester
 FCB 3 height of requester
 FCB 2 length of input
 FDB b@ address of input area
 FCC "Music Tempo (01-99): "
b@ FCC "40"
 FCB 0 end of requester
d@ FCC "99" edit string

*SOPTINST - set instrument option
*
SOPTINST PSHS D,X
 LDX #MIDINSTM
 LDY #MIDINST
 LBSR COPYSTR
 LDX #MIDINSTR display list of instruments
 LBSR SETREQ
 LBSR DSPREQ
A@ LBSR GETHEX get instrument number
 LBSR REFMEN erase instrument list
 CMPA #3 check for <BREAK>
 BEQ Z@
 SUBA #'0 convert to binary
 CMPA #9
 BLS B@
 SUBA #7
B@ ORA #INSTOPT
 LDX #DSP_CURS
 LDB VOICE
 LSLB
 ABX
 LDB VPOS
 LBSR CNV_DICO
 LBSR INSERT
 STD [,X]
Z@ PULS D,X,PC
INSTDAT FCB 13 number of words in cursor
 RZB 26	*,0

*SETCINST - set instrument option data table up
*ENTRY: instrument # (ASCII) in A
*
SETCINST PSHS D,X,Y,U
 LDB #26
 LDX #a@
 LDY #INSTDAT+1
A@ LDA ,X+
 STA ,Y+
 DECB
 BNE A@
 LDA 0,S get instrument #
 SUBA #32 convert to table offset
 LDB #8
 MUL
 ADDD #CHTABLE+7
 TFR D,X
 LDY #INSTDAT+9 set up new cursor
 LDB #7
C@ LDA ,-X move character table data
 LSRA
 ORA ,X
 ORA ,Y
 STA ,Y++ into cursor data
 DECB  (every other byte)
 BNE C@
 PULS D,X,Y,U,PC
a@ FDB $3000,$2800,$1600
 FDB $900,$A80,$540,$2A0
 FDB $150,$8E,$52,$22
 FDB $24,$38

*SOPTEVNT - set event option, store in voice 1
*
SOPTEVNT PSHS D,X
 LDX #RMIDEVNT display list of instruments
 LBSR SETREQ
 LBSR DSPREQ
A@ LBSR GETHEX get instrument number
 LBSR REFMEN erase instrument list
 CMPA #3 check for <BREAK>
 BEQ Z@
 SUBA #'0 convert to binary
 CMPA #4
 BHS Z@
 LDB VOICE insert into voice 1
 PSHS B
 CLR VOICE
 LBSR INSERT
 PULS B
 STB VOICE
 ORA #EVNTOPT
 LDX #DSP_CURS
 LDB VPOS
 LBSR CNV_DICO
 STD [DSP_CURS]
Z@ PULS D,X,PC
EVNTDAT FCB 9 number of words in cursor
 FDB 0,0
 FCB $3E,0,$30,0
 FCB $30,0,$3C,0
 FCB $30,0,$30,0
 FCB $3E,0

*SETCEVNT - set instrument option data table up
*ENTRY: instrument # (ASCII) in A
*
SETCEVNT PSHS D,X,Y
 SUBA #32 convert to table offset
 LDB #8
 MUL
 ADDD #CHTABLE+7
 TFR D,X
 LDY #EVNTDAT+6 set up new cursor
 LDB #7
C@ LDA ,-X move character table data
 STA ,Y++ into cursor data
 DECB  (every other byte)
 BNE C@
 PULS D,X,Y,PC

*DSP_OPT - display option 
*ENTRY: NVALU in A, unconverted pitch in B
*
DSP_OPT PSHS D,X,Y,U
 ANDA #$F0
 CMPA #EVNTOPT
 LBEQ DSPEVNTO
 CMPA #INSTOPT
 LBEQ DSPINSTO
 CMPA #TEMPOPT
 LBEQ DSPTEMPO
 CMPA #BYTEOPT
 BEQ DSPBYTEO
 CMPA #OCTVOPT
 BEQ DSPOCTVO
 CMPA #LOCOOPT
 BEQ DSPLOCOO
 CMPA #VOL_OPT
 LBEQ DSPVOLOP
 CMPA #CLK_OPT
 BEQ DSPCLKOP
Z@ PULS D,X,Y,U,PC
DSPLOCOO LDX #LOCODAT
 CLRA
 LBSR DSPOCUR
 BRA Z@
DSPOCTVO LDX #OCTVDAT
 CLRA
 LBSR DSPOCUR
 BRA Z@
DSPCLKOP PSHS B clock on/off option
 CLRA
 LDB #6
 LDX #CLOKDAT
 LBSR DSPOCUR
 LDD #160 set text position
 ADDB HPOS
 TFR D,U
 CLR TMODE
 LDD #-96
 STD TEXTADJ
 LDA #'-
 TST ,S
 BEQ D@
 LDA #'+
D@ LBSR TEXT
 CLRA
 CLRB
 STD TEXTADJ
 PULS B
 BRA Z@
DSPBYTEO PSHS B MIDI byte out option:
 LDD #128 set text position
 ADDB HPOS
 TFR D,U
 CLR TMODE
 LDA #'M
 LBSR TEXT
 LDB LINEWIDE
 DECB
 LEAU B,U move to next line
 LDD #-96
 STD TEXTADJ
 PULS A get byte to convert
 LBSR HEXOUT convert to ASCII hex
 LBSR TEXT display it 
 TFR B,A get 2nd letter
 LBSR TEXT
 CLRA
 CLRB
 STD TEXTADJ
 BRA Z@
DSPTEMPO LDX #10 TEMPO OPTION:
 CLRA  convert tempo
 LBSR DIVIDE to ASCII
 ADDB #'0
 PSHS B
 TFR X,D 
 ADDB #'0
 PSHS B
 CLRA
 LDB #6
 LDX #TEMPDAT
 BSR DSPOCUR
 LDD #160 set text position
 ADDB HPOS
 TFR D,U
 CLR TMODE
 LDD #-96
 STD TEXTADJ
 PULS A get first letter
 LBSR TEXT display it
 PULS A get 2nd letter
 LBSR TEXT
 CLRA
 CLRB
 STD TEXTADJ
 LBRA Z@
DSPINSTO LDA ,S INSTRUMENT OPTION: 
 ANDA #$0F get instrument #
 ADDA #'0 convert to ASCII hex
 CMPA #'9
 BLS B@
 ADDA #7
B@ LBSR SETCINST
 LDA 1,S get display "pitch"
 LDX #INSTDAT
 BSR DSPOCUR
 LBRA Z@
DSPEVNTO LDA ,S EVENT OPTION:
 ANDA #$0F get event #
 ADDA #'0 convert to ASCII
 LBSR SETCEVNT
 LDA 1,S
 LDX #EVNTDAT
 BSR DSPOCUR
 LBRA Z@
DSPVOLOP LDA ,S VOLUME OPTION:
 ANDA #$0F get level
 LSLA  word offset
 LDX #VOLPTRS get address of new cursor
 LDX A,X
 BSR DSPOCUR
 LBRA Z@
DSPOCUR LBSR CNV_CODI convert B to VPOS
 TFR B,A
 LDB HPOS
 JSR CURCAL
 ADDD #2*32
 TFR D,Y
 LDB ,X+ get display height
 PSHS B
 LDA #$AA
 STA MASK 
A@ LDD ,X++
 COMA
 COMB
 TST DSPFLAG
 BPL C@
 ORA MASK
 ORB MASK
 COM MASK
C@ STD ,Y
 LDB LINEWIDE
 NEGB
 LEAY B,Y
 DEC ,S
 BNE A@
 PULS B
 RTS

TEMPDAT FCB 11
 FDB $7FF0,$4210,$4710
 FDB $4710,$2220,$2220
 FDB $1240,$1240,$0880
 FDB $0880,$0700

CLOKDAT FCB 11
 FDB $1F00,$2080,$4040,$81A0
 FDB $8320,$8620,$8420,$8420
 FDB $4440,$2480,$1F00
