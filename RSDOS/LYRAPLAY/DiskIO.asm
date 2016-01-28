* TITL1 "DISKIO/TXT"
*************************************************
* DISKIO/TXT: INCLUDE FILE FOR LYRABOX
* CONTAINS THE DISK I/O ROUTINES
* Last update: 12-18-86
*************************************************

*DISKREA reads a LYRA file into memory (version 1 OR 2)
*ENTRY: set up FILENAME
*EXIT: A=0 for successful read, otherwise A=$FF.
*
FILVER FCB 0 version of file being loaded
*
DISKREA PSHS B,X,Y,U
 LDX #FILENAME
 JSR FILES
 LDA #'I set input mode
 JSR OPEN
 LDX #STARTCOD+2
 JSR DINPUT
 CMPA #'2 make sure we have the
 BLS G@ right version
H@ JSR NOTVALID
 LDA #$FF
 LBRA Z@
G@ STA FILVER save version #
 JSR DINPUT
 CMPA #$5A double check for a
 BNE H@ valid file
C@ JSR DINPUT now get code up to
 STA ,X+ NOTFRACM.
 CMPX #NOTFRACM
 BNE C@
 LDY #STARTCOD =offset to add to pointers
 LDA FILVER
 CMPA #'2 no adjust for ver 2
 BEQ E@
 LEAY 285,Y adjust pointers for ver 1
E@ PSHS Y
 LDY #VOI_PTR convert pointers to
B@ LDD ,Y actual addresses
 ADDD ,S
 STD ,Y++
 CMPY #ENDPTR+2
 BNE B@
 LEAS 2,S throw away adjust.
D@ LDA FILVER rest of file differs
 CMPA #'2 for two versions
 BNE A@
 BSR GETVER2
 BRA Y@
A@ BSR GETVER1
Y@ JSR CLOSE
 JSR CNVMINST make binary MIDI instrumet
 JSR CNVNFRA and note fraction numbers.
 JSR SETEPTR
 CLRA
Z@ PULS B,X,Y,U,PC

GETVER2 JSR DINPUT
 STA ,X+
 CMPX ENDPTR done yet?
 BNE GETVER2
 RTS

GETVER1 LDX #B@ display conversion message
 JSR SETREQ
 JSR DSPREQ
 LDX #V1 skip NOTFRACM area
A@ JSR DINPUT get NVALU
 STA ,X+
 JSR DINPUT get pitch
 STA ,X+
 BSR VERCNV convert NVALU
 CMPX ENDPTR done yet?
 BNE A@
 JSR REFMEN
 RTS
B@ FCB 48,2,26,3,0,0
 FCC " Converting Version 1 to 2"
 FCB 0

*VERCNV - convert version 1 NVALU to version 2
*
VERCNV PSHS U
 LDA -2,X get NVALU
 BMI Z@ test for option
 BEQ Z@ test for end of voice
 TFR A,B
 ANDA #$1F discard status bits
 ANDB #$60 keep status bits
 CMPA #8 check for rest
 BLE A@
 SUBA #8
 ORB #RESTBIT
A@ DECA
 PSHS B
 LDU #a@ do table look up
B@ LDA A,U
 ORA ,S+ add status bits
 STA -2,X put converted note in memory
 BITA #RESTBIT
 BEQ Z@ if rest, then adjust
 INC -1,X pitch
Z@ PULS U,PC
a@ FCB 1,2,3,19 version 2 notes
 FCB 4,20,5,6

NOTVALID PSHS X
 LDX #A@ display error message
 JSR SETREQ
 JSR DSPREQ
 JSR WAITKEY
 JSR REFMEN
 PULS X,PC
A@ FCB 48,5,19,3,0,0
 FCC "  Not a valid file!"
 FCB 0

FILENAME FCC "        LYR" use for LYRA files
 FCB 0

*FILES - Initialize disk variables
*ENTRY: X points to filename
*
FILES PSHS D,X,Y,U
 LDX 2,S transfer file name string
 LDY #$94C to disk area
 LDB #11
B@ LDA ,X+
 STA ,Y+
 DECB
 BNE B@
 LDB #1 set number of buffers
 STB $95B
 LDX #$989
 CLR ,X clear status flag
 STX $928 set pointer to first FCB
 LDB #1 set disk file type
 STB $957
 CLR $958 ASCII flag=0 (binary)
 LDA #1
 STA $6F set device number
 PULS D,X,Y,U,PC

*Open a disk file
*ENTRY: A=file mode ("I" or "O")
*
OPEN LDB #1 set device number
 LDU #0 DOS routine #
 BRA DODOS

*Close disk file
*
CLOSE LDU #1
 BSR DODOS
 CLR $FF40 turn disk motor off
 CLR $6F set device number
 RTS

*Read a character from a disk file
*Returns character in A
*
DINPUT LDU #$A176
 BRA DOROM

*DISKHOME - restore disk to track 0
*
DISKHOME LDB $95A get default drive #
 CLRA
 STD $EA set restore to track 0 code
 STA $FFDE turn ROMs on
 LDU $C004 call DSKCON
 BRA DOROM

*DODOS - do DOS routine address for 1.0 or 1.1 DOS
*ENTRY: routine number in U
*EXIT: routine address in U
*
DOSOFSET FCB 0 =4 if DOS 1.1
*
DODOS PSHS D
 TFR U,D
 LSLB
 ADDB DOSOFSET
 LDU #DOSTBL
 LDU B,U
 PULS D (continue with DOROM)
*
*DOROM - do ROM subroutine
*ENTRY: address in U
*
DOROM STA $FFDE turn ROMs on
 ANDCC #$AF enable interrupts
 JSR ,U
 ORCC #$50 disable interrupts
 STA $FFDF turn ROMs off
 RTS

DOSTBL FDB $C468 open 1.0
 FDB $CA53 close 1.0
 FDB $C48D open 1.1
 FDB $CB01 close 1.1

HEXOUT PSHS A
 LSRA
 LSRA
 LSRA
 LSRA
 BSR A@
 TFR A,B
 PULS A
 ANDA #$0F
 BSR A@
 EXG A,B
 RTS
A@ CMPA #9
 BLS B@
 ADDA #7
B@ ADDA #'0
 RTS

*DOSERR - handle DOS errors (called from ROMs)
*ENTRY: error code in B
*
DOSERR PSHS B B=error code
 TFR B,A
 LBSR HEXOUT
 STD OTHERERR put it reqester if needed
 JSR CLOSE
 LDX #ERRTBL
 PULS B
A@ TST ,X check for end of table
 BEQ B@
 CMPB ,X error codes match?
 BEQ B@
 LEAX 3,X move to next entry
 BRA A@
B@ LDX 1,X point to desired requester
 JSR SETREQ display error code
 JSR DSPREQ in a requester
 JSR WAITKEY wait for any keypress
 JSR REFMEN
 JMP START2

ERRTBL FCB 40
 FDB REQERR21
 FCB 52
 FDB REQERR27
 FCB 56
 FDB REQERR29
 FCB 60
 FDB REQERR31
 FCB 32
 FDB REQERR32
 FCB 64
 FDB REQERR33
 FCB 72
 FDB REQERR37
 FCB 128
 FDB REQERR80
 FCB 0
 FDB REQERR0

REQERR21 FCB 60 VPOS
 FCB 6 HPOS
 FCB 18 width of requester
 FCB 3 height of requester
 FCB 0 length of input
 FDB 0 address of input area
 FCC "INPUT/OUTPUT ERROR"
 FCB 0 end of requester
REQERR27 FCB 60,8,14,3,0
 FDB 0
 FCC "FILE NOT FOUND"
 FCB 0
REQERR29 FCB 60,10,9,3,0
 FDB 0
 FCC "DISK FULL"
 FCB 0
REQERR31 FCB 60,5,20,3,0
 FDB 0
 FCC "DISK WRITE PROTECTED"
 FCB 0
REQERR32 FCB 60,9,12,3,0
 FDB 0
 FCC "BAD FILENAME"
 FCB 0
REQERR33 FCB 60,6,17,3,0
 FDB 0
 FCC "DAMAGED DIRECTORY"
 FCB 0
REQERR37 FCB 60,9,12,3,0
 FDB 0
 FCC "VERIFY ERROR"
 FCB 0
REQERR80 FCB 60,8,14,3,0
 FDB 0
 FCC "OVERFLOW ERROR"
 FCB 0
REQERR0 FCB 60,11,8,3,0
 FDB 0
 FCC "ERROR "
OTHERERR FCC "  "
 FCB 0

*DIR - get directory of disk
*ENTRY: X points to filename string
*EXIT - DIRSTR set up with directory contents
*
DIR PSHS D,X,Y,U
 LEAX DIRSTR,PCR clear directory string
 LDA #32
 LDB #3*12 counter of entries
I@ PSHS B
 LDB #9 counter of bytes/entry
J@ STA ,X+
 DECB
 BNE J@
 LEAX 1,X skip CR/space between
 PULS B
 DECB
 BNE I@
 STA $FFDE enable ROMs
 ANDCC #$AF enable interrupts
 LDA #2 set read operation
 STA <$EA
 LDA $95A get default drive #
 STA <$EB
 LDA #17
 STA <$EC select track 17
 LDA #3
 STA <$ED select sector 3
 LDX #DIRSTR
 LDY 2,S get filename pointer
A@ LDU #$600
 STU <$EE set buffer to $600
 JSR [$C004] call DSKCON
 TST <$F0 test for errors
 BNE G@ exit if error found
B@ CMPU #$700 test for end of buffer
 BEQ E@
 CMPX #DIRSTRE test for end of DIRSTR
 BEQ F@
 LDA ,U
 BEQ D@ test for erased file
 CMPA #$FF test for last directory entry
 BEQ F@
 LDB #8
C@ LDA B,U test for the right extension
 CMPA B,Y Y points to FILENAME
 BNE D@
 INCB
 CMPB #11
 BLO C@
 CLRB  transfer from buffer
H@ LDA B,U to DIRSTR
 INCB
 STA B,X
 CMPB #8
 BLO H@
 LEAX 10,X
D@ LEAU $20,U point to next filename
 BRA B@
E@ LDA <$ED increment sector number
 INCA
 CMPA #11 check whether we are at the end of directory
 BHI F@
 STA <$ED
 BRA A@
F@ ORCC #$50 disable interrupts
 CLR $FF40 turn disk motor off
 STA $FFDF turn ROMs off
 PULS D,X,Y,U,PC
G@ LDB #40 DOS error code (I/O)
 JMP DOSERR

REQDIR FCB 6 VPOS
 FCB 0 HPOS
 FCB 28 width of requester
 FCB 14 height of requester
 FCB 0 length of input
 FDB 0 address of input area
DIRSTR FCB 0 select flag
 FCC "        " file name
 FCC " " space between names
 FCC " "
 FCC "        "
 FCC " "
 FCC " "
 FCC "        "
 FCB 13 end of line 1
 FCC " " select flag
 FCC "        " file name
 FCC " " space between names
 FCC " "
 FCC "        "
 FCC " "
 FCC " "
 FCC "        "
 FCB 13 end of line 2
 FCC " " select flag
 FCC "        " file name
 FCC " " space between names
 FCC " "
 FCC "        "
 FCC " "
 FCC " "
 FCC "        "
 FCB 13 end of line 3
 FCC " " select flag
 FCC "        " file name
 FCC " " space between names
 FCC " "
 FCC "        "
 FCC " "
 FCC " "
 FCC "        "
 FCB 13 end of line 4
 FCC " " select flag
 FCC "        " file name
 FCC " " space between names
 FCC " "
 FCC "        "
 FCC " "
 FCC " "
 FCC "        "
 FCB 13 end of line 5
 FCC " " select flag
 FCC "        " file name
 FCC " " space between names
 FCC " "
 FCC "        "
 FCC " "
 FCC " "
 FCC "        "
 FCB 13 end of line 6
 FCC " " select flag
 FCC "        " file name
 FCC " " space between names
 FCC " "
 FCC "        "
 FCC " "
 FCC " "
 FCC "        "
 FCB 13 end of line 7
 FCC " " select flag
 FCC "        " file name
 FCC " " space between names
 FCC " "
 FCC "        "
 FCC " "
 FCC " "
 FCC "        "
 FCB 13 end of line 8
 FCC " " select flag
 FCC "        " file name
 FCC " " space between names
 FCC " "
 FCC "        "
 FCC " "
 FCC " "
 FCC "        "
 FCB 13 end of line 9
 FCC " " select flag
 FCC "        " file name
 FCC " " space between names
 FCC " "
 FCC "        "
 FCC " "
 FCC " "
 FCC "        "
 FCB 13 end of line 10
 FCC " " select flag
 FCC "        " file name
 FCC " " space between names
 FCC " "
 FCC "        "
 FCC " "
 FCC " "
 FCC "        "
 FCB 13 end of line 11
 FCC " " select flag
 FCC "        " file name
 FCC " " space between names
 FCC " "
 FCC "        "
 FCC " "
 FCC " "
 FCC "        "
 FCB 13 end of line 12
DIRSTRE FCB 0 end of requester
