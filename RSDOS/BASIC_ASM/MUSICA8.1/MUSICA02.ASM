*******************************
*MUSICA02/TXT                 *
*AS OF 10/26/87               *
*******************************

SINTAB FCB $80,$83,$86,$89,$8C,$8F,$92,$95
 FCB $99,$9C,$9F,$A2,$A5,$A8,$AB,$AE
 FCB $B1,$B4,$B6,$B9,$BC,$BF,$C2,$C4
 FCB $C7,$C9,$CC,$CF,$D1,$D3,$D6,$D8
 FCB $DA,$DC,$DF,$E1,$E3,$E5,$E7,$E8
 FCB $EA,$EC,$EE,$EF,$F1,$F2,$F3,$F5
 FCB $F6,$F7,$F8,$F9,$FA,$FB,$FC,$FD
 FCB $FD,$FE,$FE,$FF,$FF,$FF,$FF,$FF
 FCB $FF,$FF,$FF,$FF,$FF,$FE,$FE,$FD
 FCB $FD,$FC,$FB,$FB,$FA,$F9,$F8,$F7
 FCB $F5,$F4,$F3,$F1,$F0,$EE,$ED,$EB
 FCB $E9,$E8,$E6,$E4,$E2,$E0,$DE,$DB
 FCB $D9,$D7,$D5,$D2,$D0,$CD,$CB,$C8
 FCB $C6,$C3,$C0,$BD,$BB,$B8,$B5,$B2
 FCB $AF,$AC,$A9,$A6,$A3,$A0,$9D,$9A
 FCB $97,$94,$91,$8E,$8B,$87,$84,$81
 FCB $7E,$7B,$78,$74,$71,$6E,$6B,$68
 FCB $65,$62,$5F,$5C,$59,$56,$53,$50
 FCB $4D,$4A,$47,$44,$42,$3F,$3C,$39
 FCB $37,$34,$32,$2F,$2D,$2A,$28,$26
 FCB $24,$21,$1F,$1D,$1B,$19,$17,$16
 FCB $14,$12,$11,$F,$E,$C,$B,$A
 FCB $8,$7,$6,$5,$4,$4,$3,$2
 FCB $2,$1,$1,$0,$0,$0,$0,$0
 FCB $0,$0,$0,$0,$0,$1,$1,$2
 FCB $2,$3,$4,$5,$6,$7,$8,$9
 FCB $A,$C,$D,$E,$10,$11,$13,$15
 FCB $17,$18,$1A,$1C,$1E,$20,$23,$25
 FCB $27,$29,$2C,$2E,$30,$33,$36,$38
 FCB $3B,$3D,$40,$43,$46,$49,$4B,$4E
 FCB $51,$54,$57,$5A,$5D,$60,$63,$66
 FCB $6A,$6D,$70,$73,$76,$79,$7C,$7F

FLATDT FDB $7F7F,$7F3F,$1F4F,$1F3F
SHRPDT FDB $FFFF,$FFAF,$07AF,$07AF

REST1 FDB $FFFF,$FFFF,$FFFF,$F00F,$FC3F,$FC3F,$FFFF,$FFFF
REST2 FDB $FFFF,$FFFF,$FFFF,$FC3F,$FC3F,$F00F,$FFFF,$FFFF
REST4 FDB $FEFF,$FF7F,$FF3F,$FE7F,$FCFF,$FE7F,$FE3F,$FDBF
REST8 FDB $F9BF,$F83F,$FCBF,$FFBF,$FFBF,$FFBF,$FFBF,$FFFF

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

DATDSP FDB $FFFF WHOLE NOTE
 FDB $F83F,$F39F,$E7CF,$F39F,$F83F,$FFFF
 FDB $FFEF HALF NOTE
 FDB $F82F,$F38F,$E7CF,$F39F,$F83F,$FFFF
 FDB $FFEF QUARTER NOTE
 FDB $F82F,$F00F,$E00F,$F01F,$F83F,$FFFF
DFLAG FDB $FFEF D (FLAG)
 FDB $FFE7,$FFEB,$FFED,$FFED,$FFE9
DTRIP FDB $F8FF (TRIPLET MARKER)
 FDB $FEFF,$FCFF,$FEFF,$F8FF

TABLE FDB $0 NOTE LENGTHS (MSB USED BY PUT)
 FDB $017F WHOLE NOTE
 FDB $0240 HALF NOTE
 FDB $040B TRIPLET NOTE
 FDB $0320 QUARTER NOTE
 FDB $0505 SIXTEENTH TRIPLET NOTE
 FDB $0508 SIXTEENTH NOTE
 FDB $0604 THIRTY-SECOND NOTE
 FDB $0410 EIGHTH NOTE
 FDB $0702 SIXTY-FOURTH NOTE
 FDB 0,0,0,0,0,0

PITCH FDB $2B67 C6 = 1046
 FDB $28F8 C6F
 FDB $2B66 B6#
 FDB $28F7 B6 = 987
 FDB $26AB B6F
 FDB $26AA A6# = 932
 FDB $247F A6 = 879
 FDB $2273 A6F
 FDB $2272 G5# = 830
 FDB $2084 G5 = 783
 FDB $1E81 G5F
 FDB $1EB0 F5# = 739
 FDB $1CF7 F5 = 698
 FDB $1B58 F5F
 FDB $1CF6 E5#
 FDB $1B57 E5 = 659
 FDB $19CF E5F
 FDB $19CE D5# = 622
 FDB $185B D5 = 587
 FDB $16FE D5F
 FDB $16FD C5# = 554
 FDB $15B3 C5 = 523
 FDB $147C C5F
 FDB $15B2 B5#
 FDB $147B B5 = 493
 FDB $1356 B5F
 FDB $1355 A5# = 466
 FDB $123F A5 = 439
 FDB $113A A5F
 FDB $1139 G4# = 415
 FDB $1042 G4 = 391
 FDB $F59 G4F
 FDB $F58 F4# = 369
 FDB $E7B F4 = 349
 FDB $DAC F4F
 FDB $E7A E4#
 FDB $DAB E4 = 329
 FDB $CE8 E4F
 FDB $CE7 D4# = 311
 FDB $C2D D4 = 293
 FDB $B7F D4F
 FDB $B7E C4# = 277
 FDB $AD9 C4 = 261
 FDB $A3E C4F
 FDB $AD8 B4#
 FDB $A3D B4 = 246
 FDB $9AB B4F
 FDB $9AA A4# = 233
 FDB $91F A4 = 219
 FDB $89D A4F
 FDB $89C G3# = 207
 FDB $821 G3 = 195
 FDB $7AD G3F
 FDB $7AC F3# = 184
 FDB $73D F3 = 174
 FDB $6D6 F3F
 FDB $73E E3#
 FDB $6D5 E3 = 164
 FDB $674 E3F
 FDB $673 D3# = 155
 FDB $616 D3 = 146
 FDB $5C0 D3F
 FDB $5BF C3# = 138
 FDB $56C C3 = 130
 FDB $51F C3F
 FDB $56B B3#
 FDB $51E B3 = 123
 FDB $4D6 B3F
 FDB $4D5 A3# = 116
 FDB $48F A3 = 109
 FDB $44F A3F
 FDB $44E G2# = 103
 FDB $410 G2 = 97
 FDB $3D7 G2F
 FDB $3D6 F2# = 92
 FDB $39E F2 = 87
 FDB $36B F2F
 FDB $39D E2#
 FDB $36A E2 = 82
 FDB $33A E2F
 FDB $339 D2# = 77
 FDB $30B D2 = 73
 FDB $2E0 D2F
 FDB $2DF C2# = 69
 FDB $2B6 C2 = 65

CHTABL FCB $30,$48,$48,$48,$48,$48,$30,$0 *0
 FCB $20,$60,$20,$20,$20,$20,$70,$0 *1
 FCB $70,$88,$8,$30,$40,$80,$F8,$0 *2
 FCB $70,$88,$8,$30,$8,$88,$70,$0 *3
 FCB $10,$30,$50,$90,$F8,$10,$10,$0 *4
 FCB $F8,$80,$F0,$8,$8,$88,$70,$0 *5
 FCB $70,$80,$80,$F0,$88,$88,$70,$0 *6
 FCB $F8,$8,$10,$20,$40,$80,$80,$0 *7
 FCB $70,$88,$88,$70,$88,$88,$70,$0 *8
 FCB $70,$88,$88,$78,$8,$8,$70,$0 *9
 FCB $F0,$88,$88,$F0,$80,$80,$80,0 *P
 FCB $F0,$88,$88,$F0,$A0,$90,$88,0 *R
CHEND EQU *

HRMSTR FCB $83
 FCC "1 9:90000000"
 FCB $82
 FCC "2 9:90000000"
 FCB $86
 FCC "3 9:90000000"
 FCB $82
 FCC "4 9:90000000"
 FCB 0 STRING TERMINATOR

*Basic loader for MUSICA II
*Position independent.

 FCB $00
BASIC FDB LINE20,10
 FCB $95 (CLEAR)
 FCC "24,16127:"
 FCB $B9,$FF,$83 (DEFUSR)
 FCC \0\
 FCB $B3 (=)
 FCC "7680:A$"
 FCB $B3 (=)
 FCC \"&H\
EXECAD FCC \4405":D$\
 FCB $B3 (=)
 FCC \"/MUS":T$\
 FCB $B3 (=)
 FCC \""\
 FCB 0 END OF LINE
LINE20 FDB LINE30,20
 FCB $9E,$3A,$42 (CLS:B=USR0(B))
 FCB $B3,$FF,$83,$30,$28
 FCB $42,$29
 FCB $00 END OF LINE
LINE30 FDB LINE40,30
 FCB $85 (IF)
 FCC \B\
 FCB $B3 (=)
 FCC \76\
 FCB $A7,$BB,$89 (THEN LINEINPUT)
 FCC \"LOAD>";X$:\
LOADM FCB $D3 (LOAD)
 FCC \MX$\
 FCB $AB (+)
 FCC \D$:B\
 FCB $B3 (=)
 FCC \2:\
 FCB $81,$A5 (GOTO)
 FCC \20\
 FCB $00 END OF LINE
LINE40 FDB LINE50,40
 FCB $85 (IF)
 FCC \B\
 FCB $B3 (=)
 FCC \75\
 FCB $A7,$BB,$89 (THEN LINEINPUT)
 FCC \"SAVE>";X$:B\
 FCB $B3,$FF,$89 (=VAL)
 FCC \(A$):\
SAVEM FCB $D8
 FCC \MX$\
 FCB $AB (+)
 FCC \D$,16384,B\
 FCB $AB (+)
 FCC \119,B:B\
 FCB $B3 (=)
 FCC \1:\
 FCB $81,$A5 (GOTO)
 FCC \20\
 FCB $00
LINE50 FDB LINE60,50
 FCB $85 (IF)
 FCC \B\
 FCB $B3 (=)
 FCC \65\
 FCB $A7,$BB,$89 (THEN LINEINPUT)
 FCC \"CMD>";X$:\
 FCB $D3 (LOADM)
 FCC \MX$\
 FCB $AB (+)
 FCC \"/CMD":\
 FCB $A2 (EXEC)
 FCC \:B\
 FCB $B3 (=)
 FCC \1:\
 FCB $81,$A5
 FCC \20\
 FCB 0 END OF LINE
LINE60 FDB LINE70,60
 FCB $95 (CLEAR)
 FCC \100,32640\
 FCB 0 END OF LINE
LINE70 FCB 0,0 END OF BASIC MARKER
BASEND FCB 0

SETBAS PSHS D,X
 LDX #HLPMSG move help command to high memory
 LDY #$8000
 ORCC #$50 disable interrupts
 STA $FFDF select all RAM mode
SETBA1 LDA ,X+
 STA ,Y+
 CMPX #ENDMUS
 BLE SETBA1 loop back until done
 STA $FFDE select RAM/ROM mode
 ANDCC #$AF enable interrupts
 LDX #$19 set up BASIC pointers
 LDD #BASIC
 STD ,X++
 LDD #BASEND
 STD ,X++
 STD ,X++
 STD ,X++
 PULS D,X
 JMP $AE75 RUN PROGRAM

*************************
* HELP/TXT AS OF 8/13/84*
* Relocated to $8000    *
*************************
                         

HLPMSG FCC "MUSICA II COMMAND SUMMARY"
 FDB $0D0D
 FCC "B:GO TO START OF MUSIC"
 FCB 13
 FCC "C:CHANGE TONE TABLES AND TEMPO"
 FCB 13
 FCC "D:DELETE"
 FCB 13
 FCC "E:GO TO END OF MUSIC"
 FCB 13
 FCC "F:FLAT"
 FCB 13
 FCC "G:MAKE NEW TONE TABLES"
 FCB 13
 FCC "H:HIGHLIGHT VOICE"
 FCB 13
 FCC "I:INSERT"
 FCB 13
 FCC "J:JOYSTICK ON/OFF"
 FCB 13
 FCC "K:SAVE MUSIC"
 FCB 13
 FCC "L:LOAD MUSIC"
 FCB 13
 FCC "M:BARLINE"
 FCB 13
 FCC "N:NATURAL"
 FCB 13
 FCC "O:SET OPTIONS"
 FCB 13
 FCC "P:PLAY MUSIC"
 FCB 13
 FCC "Q:QUICK FIND BAR #"
 FCB 13
 FCC "R:REST"
 FCB 13
 FCC "S:SHARP"
 FCB 13
 FCC "T:GO TO NEXT 'C' MARKER"
 FCB 13
 FCC "V:SET VOICE"
 FCB 13
 FCC "W:WRITE MUSIC ON PRINTER"
 FCB 13
 FCC "X:EXCHANGE VOICES"
 FCB 13
 FCC "Y:COPY ONE VOICE TO ANOTHER"
 FCB 13
 FCC "Z:EXIT"
 FCB 13
 FCC "1:WHOLE NOTE"
 FCB 13
 FCC "2:1/2 NOTE"
 FCB 13
 FCC "3:1/8 TRIPLET NOTE"
 FCB 13
 FCC "4:1/4 NOTE"
 FCB 13
 FCC "5:1/16 TRIPLET NOTE"
 FCB 13
 FCC "6:1/16 NOTE"
 FCB 13
 FCC "7:1/32 NOTE"
 FCB 13
 FCC "8:1/8 NOTE"
 FCB 13
 FCC "9:1/64 NOTE"
 FCB 13
 FCC "::REPEAT BARLINE"
 FCB 13
 FCC "*:PLAY ALL (DISK ONLY)"
 FCB 13
 FCC "-:DELETE BLOCK"
 FCB 13
 FCC "@:SELECT TV/ORCH-90"
 FCB 13
 FCC ";:WRITE TITLE LINES"
 FCB 13
 FCC ",:BARLINE # ON/OFF"
 FCB 13
 FCC ".:COPY BLOCK"
 FCB 13
 FCC "<:REPEAT MARKER"
 FCB 13
 FCC ">:PART MARKER"
 FCB 13
 FCC "/:KEY SIGNATURE"
 FDB 0

OPTMSG FCC "SELECT OPTIONS:"
 FDB $0D0D
 FCC " F - FAST PLAY"
 FCB 13
 FCC " L - LOW SPEED PLAY"
 FDB $0D0D
 FCC " O - ORCH-90 OUTPUT"
 FDB $0D0D
 FCC " P - PLAY WITH NOTE ENTRY"
 FCB 13
 FCC " N - NO PLAY WITH ENTRY"
 FDB $0D0D
 FCC " T - TAPE I/O"
 FCB 13
 FCC " D - DISK I/O"
 FCB 0

ENDMUS EQU *

INSTAL PSHS D,X ENTRY POINT
 LBSR CLS
 CLR $6F SET SCREEN OUTPUT
 LDX #INMENU DISPLAY MENU
 LBSR DISPLA
GETKYI LBSR INPUT
 BEQ GETKYI
 CMPA #'0-1
 BLE GETKYI
 CMPA #'6
 BGE GETKYI
 LBSR OUTPUT
 SUBA #'0 CONVERT TO BINARY
 LBEQ SAVET0
 DECA
 LDB #40 NUMBER OF BYTES PER BLOCK OF DATA
 MUL CALCULATE CORRECT CODE ADDRESS
 ADDD #CODE
 TFR D,X
 LDY #MARGIN MOVE CODE TO MUSICA
 LDB #40 NUMBER OF BYTES TO MOVE
 LBSR MOVED
 LBSR CLS CLEAR SCREEN
 LDX #BAUDTX SELECT CORRECT BAUD
 LBSR DISPLA
SELBD1 LBSR INPUT GET KEYPRESS
 BEQ SELBD1
 CMPA #'0 ALLOW VALUES 1-6 ONLY
 BLE SELBD1
 CMPA #'7
 BGE SELBD1
 LBSR OUTPUT
 TFR A,B
 CLRA
 SUBB #'1 CONVERT TO BINARY
 ADDD #BDVALU
 TFR D,X
 LDA ,X
 STA BAUD POKE INTO MUSICA
SAVET0 LDX #INSDES ASK FOR TAPE/DISK
 LBSR DISPLA
SAVETO LBSR INPUT
 CMPA #'T
 BEQ SAVET1
 CMPA #'D
 BNE SAVETO
 BRA SETINS
SAVET1 LDB #$98 (CSAVE TOKEN)
 STB INSAVE MODIFY BASIC PROGRAM

SETINS LBSR OUTPUT
 LDX #$19 SET UP BASIC POINTERS
 LDD #BINS10 FOR INSTALLED PROGRAM
 STD ,X++ SAVE.
 LDD #BINS50+2
 STD ,X++
 STD ,X++
 STD ,X++
 LDD #SETBAS
 STD $602 TRANSFER ADDRESS FOR BASIC SAVEM
 LDD #ENDMUS
 STD $600
 PULS D,X
 JMP $AE75 RUN PROGRAM

INSDES FCB 13,13
 FCC "SAVE TO TAPE OR DISK? "
 FCB 0

INMENU FCC "MUSICA II PRINTER INSTALL"
 FDB $0D0D
 FCC " 1 - RADIO SHACK"
 FCB 13
 FCC " 2 - GEMINI 10X"
 FCB 13
 FCC " 3 - OKIDATA"
 FCB 13
 FCC " 4 - BANNANA/GORILLA"
 FCB 13
 FCC " 5 - PROWRITER/C.ITOH 8510A"
 FDB $0D0D
 FCC "SELECT >"
 FCB 0

BAUDTX FCC "PRINTER BAUD RATE:"
 FDB $0D0D
 FCC " 1 -  600"
 FCB 13
 FCC " 2 - 1200"
 FCB 13
 FCC " 3 - 2400"
 FCB 13
 FCC " 4 - 2400 ALTERNATE"
 FCB 13
 FCC " 5 - 4800"
 FCB 13
 FCC " 6 - 9600"
 FDB $0D0D
 FCC "SELECT >"
 FCB 0

BDVALU FCB 87 BAUD=600
 FCB 41 =1200
 FCB 18 =2400
 FCB 17 =2400
 FCB 6 =4800
 FCB 1 =9600

CODE FCB 112,1,128,7 RADIO SHACK DOT MATRIX
 FCB 1,18,0,0,0,0,0,0,0 INITIALIZE PRINTER
 FCB 0,0,0,0,0,0,0,0,0 START LINE
 FCB 1,13,0,0,0,0,0,0,0 END LINE
 FCB 3,30,12,18,0,0,0,0,0 NEW PAGE

 FCB 112,0,0,8 GEMINI 10X
 FCB 3,27,65,8,0,0,0,0,0 INITIALIZE PRINTER
 FCB 4,27,75,112,1,0,0,0,0 START LINE
 FCB 1,13,0,0,0,0,0,0,0 END LINE
 FCB 1,12,0,0,0,0,0,0,0 NEW PAGE

 FCB 112,1,0,7 OKIDATA 92,93
 FCB 3,24,13,3,0,0,0,0,0 INITIALIZE PRINTER
 FCB 0,0,0,0,0,0,0,0,0 START LINE
 FCB 2,3,14,0,0,0,0,0,0 END LINE
 FCB 4,3,2,12,3,0,0,0,0 NEW PAGE

 FCB 112,1,128,7 BANANA/GORRILA
 FCB 1,8,0,0,0,0,0,0,0 INITIALIZE PRINTER
 FCB 0,0,0,0,0,0,0,0,0 START LINE
 FCB 1,10,0,0,0,0,0,0,0 END LINE
 FCB 0,0,0,0,0,0,0,0,0 NEW PAGE

 FCB $C0,1,0,8 PROWRITER
 FCB 6,$1B,$54,$31,$34,$1B,$3E,0,0 set line feed to 14/144 in.
 FCB 6,$1B,$53,$30,$34,$34,$38,0,0 START LINE
 FCB 1,13,0,0,0,0,0,0,0 END LINE
 FCB 0,0,0,0,0,0,0,0,0 NEW PAGE

* BASIC INSTALLATION SAVE PROGRAM
 FCB 0
BINS10 FDB BINS50,10
 FCC \E\
 FCB $B3,$FF,$86 (=PEEK)
 FCC \(1536)\
 FCB $AD (*)
 FCC \256\
 FCB $AB,$FF,$86 (+PEEK)
 FCC \(1537):T\
 FCB $B3,$FF,$86 (=PEEK)
 FCC \(1538)\
 FCB $AD (*)
 FCC \256\
 FCB $AB,$FF,$86 (+PEEK)
 FCC \(1539):\
INSAVE FCB $D8 (SAVE)
 FCC \M"MUSICA",7680,E,T:\
 FCB $96 (NEW) FCB 0
BINS50 FDB 0
