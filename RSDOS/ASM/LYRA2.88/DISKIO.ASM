 TITLE "DISKIO"
*************************************************
* DISKIO/TXT: INCLUDE FILE FOR LYRA
* CONTAINS THE DISK I/O ROUTINES
* (C) 1986,1988 by Lester Hands
* Last update: 17-aug-88
* Last update: 14-apr-91 modifications (c) R.Gault
*************************************************

*MSG "DISKIO=",*

DSKERR EQU $70

DSKOPC EQU $EA 		DSKCON variables
DSKDRV EQU $EB 		drive
DSKTRK EQU $EC 		track
DSKSEC EQU $ED 		sector
DSKBUF EQU $EE 		buffer address
DSKSTA EQU $F0 		error code (status)

DNAMBUF EQU $094C 	DOS filename buffer
DEFDRIV EQU $095A 	location of default drive

 IFNE DEMO
* ---CONDITIONAL START
*DSKWRT writes music code to disk
*ENTRY: set up FILENAME
*
DSKWRT PSHS D,X
 LDA SAVEOK
 CMPA #SEL_OK
 BNE Z@
 LDX #FILENAME
 LDA #'O set output mode
 JSR OPEN
 LDD ENDPTR
 PSHS D
 LDX #VOI_PTR convert pointers to
A@ LDD ,X relative offsets
 SUBD #STARTCOD
 STD ,X++
 CMPX #ENDPTR+2
 BNE A@
 LDX #STARTCOD now write data to file
B@ LDA ,X+
 JSR DOUTPUT
 CMPX ,S
 BNE B@
 LDX #EVNTHDR
 LDY #EVNTLEN
 LDU #MIDIEVNT
 BSR WRTBLK
 LDX #ANNOHDR
 LDY #ANNOLEN
 LDU #ANNOT
 BSR WRTBLK
 LEAS 2,S
 JSR CLOSE
 BSR CNV_REL
Z@ PULS D,X,PC
 ENDC
*  ---CONDITIONAL END

EVNTHDR FCC "EVNT"
 FDB EVNTLEN
ANNOHDR FCC "ANNO"
 FDB ANNOLEN

 IFNE DEMO
*---CONDITIONAL START
*WRTBLK - write a data block
*ENTRY - X=pointer to 4 byte header tag
* Y=number of bytes in data block
* U=pointer to data
*
WRTBLK PSHS D,X,Y
 LDB #4
A@ LDA ,X+
 LBSR DOUTPUT
 DECB
 BNE A@
 TFR Y,D
 LBSR DOUTPUT
 TFR B,A
 LBSR DOUTPUT
B@ LDA ,U+
 LBSR DOUTPUT
 LEAY -1,Y
 BNE B@
 PULS D,X,Y,PC
 ENDC
*  ---CONDITIONAL END

* convert "relative" VOI_PTR pointers to absolute
*
CNV_REL LDX #VOI_PTR 	convert pointers back
A@ LDD ,X 		to actual addresses
 ADDD #STARTCOD
 STD ,X++
 CMPX #ENDPTR+2
 BLO A@ 		MOD BNE
 RTS

*DISKREA reads a LYRA file into memory
*ENTRY: set up FILENAME
*
FILVER FCB 0 		version of file being loaded
*
DISKREA PSHS D,X,Y,U
 LDX #FILENAME
 LDA #'I 		set input mode
 LBSR OPEN
* check first 2 bytes in file for right values
 LBSR DINPUT
 CMPA #VERSION 		make sure we have the
 BEQ G@ 		right version
H@ LBSR NOTVALID
 BRA Z@
G@ LBSR DINPUT
 CMPA #$5A 		double check for a
 BNE H@ valid file
* now read in the rest of the file
 LDX #STARTCOD+2
C@ LBSR DINPUT 		now get rest of file
 LDB $70 		any errors?
 BNE A@
 STA ,X+
 BRA C@
* check for end of file or I/O errors
A@ CMPB #$FF 		end of file?
 BEQ Y@
 LDB #40 		report I/O error
 LBRA DOSERR
Y@ TST COCO3
 BNE B@
 STA FAST
B@ BSR CNV_REL
* finally look for data blocks
 LDX ENDPTR
 LDY #EVNTHDR 		look for event table
 BSR FINDHDR
 CMPX #0
 BEQ E@
 LDY ,X++ 		get length
 CMPY #EVNTLEN
 BHI E@
 LDU #MIDIEVNT 		copy it over to requester
F@ LDA ,X+
 STA ,U+
 LEAY -1,Y
 BNE F@
 LBSR CNVEVNT 		convert it to binary
E@ LDX ENDPTR
 LDY #ANNOHDR 		look for annotation
 BSR FINDHDR
 CMPX #0
 BEQ D@
 LDY ,X++
 CMPY #ANNOLEN
 BNE D@
 LDU #ANNOT
I@ LDA ,X+
 STA ,U+
 LEAY -1,Y
 BNE I@
D@ LBSR SET_PTRS
 LBSR CNVMINST 		make binary MIDI instrumet
 LBSR CNVNFRA 		and note fraction numbers.
Z@ LBSR CLOSE
 PULS D,X,Y,U,PC

NOTVALID PSHS X
 LBSR REFMEN
 LDX #A@ 		display error message
 JSR SETREQ
 JSR DSPREQ
 JSR WAITKEY
 JSR REFMEN
 PULS X,PC
A@ FCB 48,5,19,3,0,0
 FCC "  Not a valid file!"
 FCB 0

*FINDHDR - find a data header in music code
* ENTRY: X points to music code
*        Y points to 4 byte ASCII header
* EXIT:  X points to header length
*          if not found, then X=0
*
FINDHDR PSHS D
A@ CLRB
B@ LDA ,X+
 CMPX SCREEN
 BHS E@
 CMPA B,Y
 BNE A@
 INCB
 CMPB #4
 BLO B@
Z@ PULS D,PC
E@ LDX #0
 BRA Z@

* MOD May 16,1990 for hard drive R.Gault
FILEDRIV FCC "000:" drive number
* EMOD
FILENAME FCC "        LYR" 	use for LYRA files
 FCB 0
FILENAMI FCC "        INS" 	use for midi instrument files
 FCB 0
FILENAMP FCC "        PLA" 	use for alternate play filess
 FCB 0
FILENMEV FCC "        EVN" 	use for event files
 FCB 0

*Open a disk file
*ENTRY: A=file mode ("I" or "O")
* X points to filename
*
OPEN LBSR INITDRIV
 LDB #1 		device #
 PSHS D
 LDY #DNAMBUF 		transfer filename
 LDB #11
 LBSR MOVEDATA 		to DOS area
 LDA #1 		set file type
 STA $0957
 CLR $0958
 PULS D 		MOD was LDB #1
 STB $6F set output device #
*        PULS    D
 STB SLOW
 JSR RAM_IO
* check to see which
 TST DOSVER 		ROM version we have
 BNE A@
 JSR $C468 		open 1.0
 BRA B@
A@ JSR $C48D 		open 1.1
B@ ORCC #$50
 JMP RAM_LYR

*Close disk file
*
CLOSE PSHS D,X,Y,U
 STA SLOW
 JSR RAM_IO
 LDD #$0101 		A=path b=file #
 JSR $A42D
 ORCC #$50
 TST COCO3
 BNE D@
 STA FAST
D@ JSR RAM_LYR
 CLR $FF40 		turn disk motor off
 CLR $6F 		set device number
 PULS D,X,Y,U,PC

*Read a character from a disk file
*Returns character in A
*
DINPUT ORCC #$50
 JSR RAM_IO
 STA SLOW
*        JSR     $A176         general console in
* MOD June 4,1990 R.Gault disk specific
 TST DOSVER
 BNE A@
 JSR $C597 		DOS1.0
 BRA B@
A@ JSR $C5C4 		DOS1.1
* EMOD
B@ ORCC #$50
 JMP RAM_LYR

 IFNE DEMO
* ---CONDITIONAL START
*Write a character in A to disk file
*
DOUTPUT JSR RAM_IO
 STA SLOW
* MOD May 31,1990 R.Gault was [$A002] to work
* with a hard disk must be as follows
 TST DOSVER
 BNE A@
 JSR $CB52 		send CHR to disk
 BRA B@ 		DOS 1.0
A@ JSR $CC24 		send CHR to disk
B@ ORCC #$50 		DOS 1.1
 TST COCO3
 BNE C@
 STA FAST
C@ JMP RAM_LYR
 ENDC
* ---CONDITIONAL END

*DISKHOME - restore disk to track 0
*
DISKHOME PSHS D
 LDB DEFDRIV 		get default drive #
 CLRA
 STD $EA 		set restore to track 0 code
 STA SLOW
 JSR RAM_IO
 JSR [$C004] call DSKCON
 JSR RAM_LYR
 PULS D,PC

*BCDOUT - convert byte in A to BCD word in D
*
BCDOUT PSHS X
 TFR A,B
 CLRA
 LDX #10
 LBSR DIVIDE
 PSHS D
 TFR X,D
 TFR B,A
 CLRB
 ADDD ,S++
 PULS X,PC

*HEXOUT - convert byte in A to ASCII hex word in D
*
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
DOSERR ORCC #$50
 JSR RAM_LYR
 CLR $FF40
 PSHS B B=error code
 LSRB
 TFR B,A
 CMPA #21 	check for error code
 BNE C@ 	#22 (file open)
 LBSR CLOSE
C@ BSR BCDOUT
 ADDD #$3031
 STD OTHERERR put it reqester if needed
 LBSR REFMEN
 LDA $018E disable error vector
 PSHS A
 LDA #$39 	RTS opcode
 STA $018E
 LBSR CLOSE
 PULS A 	enable error reporting
 STA $018E
 LDX #ERRTBL
 PULS B
A@ TST ,X 	check for end of table
 BEQ B@
 CMPB ,X 	error codes match?
 BEQ B@
 LEAX 3,X 	move to next entry
 BRA A@
B@ LDX 1,X 	point to desired requester
 LBSR SETREQ 	display error code
 LBSR DSPREQ 	in a requester
 LBSR WAITKEY 	wait for any keypress
 LBSR REFMEN
 LBRA RESTART

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
*MOD R.Gault
 FCB 129 bar overflow
 FDB REQERR81
*EMOD
 FCB 0
 FDB REQERR0
REQERR21 FCB 60 	VPOS
 FCB 6 			HPOS
 FCB 18 		width of requester
 FCB 3 			height of requester
 FCB 0 			length of input
 FDB 0 			address of input area
 FCC "INPUT/OUTPUT ERROR"
 FCB 0 			end of requester
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
REQERR81 FCB 60,8,14,5,0
 FDB 0
 FCC "OVERFLOW ERROR"
 FCB 13
 FCC "USE R.ARROW TO"
 FCB 13
 FCC "   PROCEED"
 FCB 0
REQERR0 FCB 60,11,8,3,0
 FDB 0
 FCC "ERROR "
OTHERERR FCC "  "
 FCB 0

* MOD May 17,1990 for hard drive R.Gault
*     June 29,1990
* HDDRIVE
* ENTRY: A=drive # in hex$; Y=store location
* EXIT:  3 digit ASCII # at Y
DRSTACK SET 0
DRNUMBR SET 2
HDDRIVE PSHS D,X,Y
 LEAS -5,S room for local variables
 TFR A,B
 CLRA
 LEAX DRSTACK,S
 JSR BINASC
 LEAX DRNUMBR,S 	ignore first 2 digits
 LDB #3
 JSR MOVEDATA 		transfer 3 bytes
 LEAS 5,S 		clear stack
 LDY 4,S 		get goto location
 LDB #32 		space
 BSR A@ 		leading zero?
 BNE Z@
 BSR A@   		 "      "
Z@ PULS D,X,Y,PC
A@ LDA ,Y+ 		replace leading zeros
 CMPA #'0
 BNE B@
 STB -1,Y 		with spaces
 CLRA
B@ RTS
* EMOD

*DIR - get directory of disk
*ENTRY: X points to filename string
*EXIT - DIRSTR set up with directory contents
*
FNAME SET 5
BPTR SET 3
DSTR SET 1
COUNT SET 0
*
DIR PSHS D,X,Y,U
 LEAS -7,S
 STX FNAME,S
 LDX #DIRSTR 	clear directory string
 STX DSTR,S
*first fill directory string with spaces
 LDA #32 	ASCII ' ' code
 LDB #36 	counter of entries
 STB COUNT,S
I@ LDB #8 	counter of bytes/entry
J@ STA ,X+
 DECB
 BNE J@
 LEAX 1,X 	skip CR/space between
 DEC COUNT,S
 BNE I@
 LBSR INITDRIV
*read in the FAT sector to see how much free space
M@ LDA DEFDRIV get default drive #
 STA DSKDRV
* MOD May 16,1990 R.Gault
* Convert drive # to ASCII
 PSHS Y
 LDY #FSDRIVE
 BSR HDDRIVE 	adapt for hard drive
 PULS Y
* EMOD
 LDA #2
 STA DSKSEC 	select sector 2
 LDA #2 	set read operation
 STA DSKOPC
 LDA #17
 STA DSKTRK 	select track 17
 LDD #$0600
 STD DSKBUF 	set buffer to $600
 STA SLOW
 JSR RAM_IO
 JSR [$C004] 	call DSKCON
 ORCC #$50
 JSR RAM_LYR
 TST DSKSTA 	test for errors
 LBNE X@ 	exit if error found
 LDX #$0600
 CLRA
F@ LDB ,X+
 CMPB #$FF 	is granule free?
 BNE G@
 INCA
G@ CMPX #$0644
 BLO F@
 LBSR BCDOUT
 ADDD #$3030 	MOD May 22,1990 R.Gault was $3031
 CMPA #'0
 BNE K@
 LDA #32
K@ STD FGRAN
*now read a directory sector from the disk
 LDA #3
 STA DSKSEC 	select sector 3
A@ LDA #2 	set read operation
 STA DSKOPC
 LDA DEFDRIV 	get default drive #
 STA DSKDRV
 LDA #17
 STA DSKTRK 	select track 17
 LDD #$600 	reset buffer pointer
 STD BPTR,S
 STD DSKBUF 	set buffer to $600
 JSR RAM_IO
 JSR [$C004] 	call DSKCON
 ORCC #$50
 JSR RAM_LYR
 TST DSKSTA 	test for errors
 BNE X@ 	exit if error found
*now transfer filenames to the directory string
B@ LDD BPTR,S
 CMPD #$700 	test for end of buffer
 BHS E@
 LDD DSTR,S
 CMPD #DIRSTRE test for end of DIRSTR
 BHS Z@
 LDA [BPTR,S]
 BEQ D@ 	test for erased file
 CMPA #$FF	test for last directory entry
 BEQ Z@
 LDB #3
 LDX BPTR,S
 LEAX 8,X 	point to extension
 LDY FNAME,S
 LEAY 8,Y
C@ LDA ,X+ 	test for the right extension
 CMPA ,Y+ 	Y points to FILENAME
 BNE D@
 DECB
 BNE C@
 LDX BPTR,S 	transfer from buffer
 LDY DSTR,S
 LDB #8
H@ LDA ,X+ 	to DIRSTR
 STA ,Y+
 DECB
 BNE H@
 LDD DSTR,S
 ADDD #9
 STD DSTR,S
D@ LDD BPTR,S
 ADDD #$20 	point to next filename
 STD BPTR,S
 BRA B@
*have come to end of buffer, prepare to read another sector
E@ LDA DSKSEC 	increment sector number
 INCA
 CMPA #$11 	check whether we are at the end of directory
 BHI Z@
 STA DSKSEC
 BRA A@
Z@ CLR $FF40 	turn disk motor off
 LEAS 7,S
 TST COCO3
 BNE L@
 STA FAST
L@ PULS D,X,Y,U,PC
X@ CLR $FF40 	ERROR:
 LEAS 7,S
 PULS D,X,Y,U
 LBSR REFMEN
 CLR DEFDRIV 	set default drive #
 LDB #40 	DOS error code (I/O)
 JMP DOSERR

REQDIR FCB 6 	VPOS
 FCB 2 		HPOS
 FCB 26 	width of requester
 FCB 15 	height of requester
 FCB 0 		length of input
 FDB 0 		address of input area
DIRSTR FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32
 FCB 13
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32
 FCB 13
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32
 FCB 13
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32
 FCB 13
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32
 FCB 13
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32
 FCB 13
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32
 FCB 13
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32
 FCB 13
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32
 FCB 13
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32
 FCB 13
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32
 FCB 13
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32,32,32,32,32
 FCB 32,32,32,32,32,32
DIRSTRE FCB 13
DIRDRIVE FCC "drive:0  "
 FCC "increase "
 FCC "decrease"
 FCB 13,THIN+JAM+$80
 FCC "Free space DIR "
FSDRIVE FCC "000:"
FGRAN FCC "48 gran"
 FCB 0

*DOLOAD - load file from disk using a directory requester
*
DOLOAD LDX #FILENAME
 JSR GETFILE
 CMPA #3
 BEQ A@
 LBSR CLRANNOT
 LBSR PLSWAIT
 JSR DISKREA
 LBSR REFMEN
 JSR VOIBOX
 LDD KEYSIG
 STD KSIGDAT
 LDD TIMESIG
 STA TSIGDAT
 STB TSIGDAT+2
 JSR SETTSIG
 JSR RSETPTR
 JSR DSPFNAME
 LDA #SEL_OK
 STA SAVEOK
A@ CLR $FF40 turn disk motor off
 CLR CONTFL
 LBSR SET_PTRS
 LBSR BLK_RSET
 LBRA DSPMUS

 IFNE DEMO
* ---CONDITIONAL START
DOSAVE LBSR PLSWAIT
 LBSR DSKWRT
 LBRA REFMEN

DOSAVEAS LDX #REQFILE
 JSR SETREQ
 LDU #FILENAME
 JSR GETNAME
 JSR REFMEN
 CMPA #3
 BEQ Z@
 LDX #FILENAME 		check for a blank filename
 LBSR BLNKCHEK
 TSTA
 BNE Z@
 JSR DSPFNAME
 LDA #SEL_OK
 STA SAVEOK
 LBSR FINDNAME
 TSTA
 BEQ Z@
 LBSR PLSWAIT
 LBSR DSKWRT
 LBSR REFMEN
Z@ RTS

* Delete a file
*
FN SET 0
DN SET 11
*
DODELETE PSHS D,X,Y,U
 LEAS -12,S
 LDX #FILENAME
 LEAY FN,S
 LDB #11
 LBSR MOVEDATA
 LDA DEFDRIV
 STA DN,S
 LDX #FILENAME
 LBSR GETFILE
 CMPA #3
 BEQ Z@
 LDY #DNAMBUF transfer filename
 LDB #11 to DOS area
 LBSR MOVEDATA
 STB SLOW
 JSR RAM_IO
 TST DOSVER check ROM version
 BNE A@
 JSR $C6C8 kill 1.0
 BRA B@
A@ JSR $C6F5 kill 1.1
B@ ORCC #$50 kill interrupts
 CLR $FF40 disk motor off
 JSR RAM_LYR
Z@ LEAX FN,S
 LDY #FILENAME
 LDB #11
 LBSR MOVEDATA
 LDA DN,S
 STA DEFDRIV
 LEAS 12,S
 PULS D,X,Y,U,PC

*INST_LO - load midi instrument table from disk
*
INST_LO LDX #FILENAMI
 LBSR GETFILE
 CMPA #3
 BEQ Z@
 LDX #FILENAMI
 LDA #'I set input mode
 LBSR OPEN
 LDB #224
 LDX #MIDINSTM
 PSHS B
B@ LBSR DINPUT
 STA ,X+
 DEC ,S
 BNE B@
 LDX #MIDIDESM
 LDB #29
 STB ,S
C@ LBSR DINPUT
 STA ,X+
 DEC ,S
 BNE C@
 PULS B
 LBSR CLOSE
 LBSR CNVMINST
Z@ RTS

*INST_SA - save midi instrument table to disk
*
INST_SA PSHS D,X,Y,U
 LDX #REQFILE
 JSR SETREQ
 LDU #FILENAMI
 JSR GETNAME
 PSHS U save filename pointer
 JSR REFMEN
 PULS X
 CMPA #3
 BEQ Z@
 LDA #'O set output mode
 JSR OPEN
 LDX #MIDINSTM now write data to file
 LDB #224
 PSHS B
A@ LDA ,X+
 JSR DOUTPUT
 DEC ,S
 BNE A@
 LDX #MIDIDESM
 LDB #29
 STB ,S
B@ LDA ,X+
 JSR DOUTPUT
 DEC ,S
 BNE B@
 PULS B
Z@ JSR CLOSE
 PULS D,X,Y,U,PC

*OUTSTR - output to disk string pointed to by X
*
OUTSTR LDA ,X+
 PSHS A
 JSR DOUTPUT
 PULS A
 TSTA
 BNE OUTSTR
 RTS
 ENDC
* ---CONDITIONAL END

*BLNKCHEK - check for blank filename
*ENTRY: X points to filename (8 characters)
*EXIT: A=0 if not blank, else A=$FF
*
BLNKCHEK PSHS B,X
 LDB #8 # letters in name
A@ LDA ,X+
 CMPA #32
 BNE B@
 DECB
 BNE A@
 LDA #$FF abort if all blanks
 BRA Z@
B@ CLRA
Z@ PULS B,X,PC

*INSTR - input from disk string pointed to by X
*
INSTR JSR DINPUT
 STA ,X+
 BNE INSTR
 RTS

 IFNE DEMO
* ---START CONDITIONAL
*DOAPPEND - append a file to code in memory
*
FNAM SET 0
VOI SET 8
CNT SET 9
SIZ SET 10
PTRS SET 12
*
* first set DSP_CURS pointers to end of each voice
DOAPPEND LEAS -34,S allocate local variables
 LDX #VOI_PTR set DSP_CURS to end of voices
 LDY #DSP_CURS
 LDB #8 voice counter
 STB VOI,S
N@ LDU ,X++ point to start of voice
M@ TST ,U++ look for end of voice
 BNE M@
 LEAU -2,U
 STU ,Y++ set DSP_CURS
 DEC VOI,S
 BNE N@
* open diskfile
 LDX #FILENAME save current filename
 LEAY FNAM,S
 LDB #8
 LBSR MOVEDATA
 LDX #FILENAME
 JSR GETFILE
 CMPA #3
 LBEQ F@
 LDA #'I set input mode
 JSR OPEN
* check for valid file version
 LBSR DINPUT
 CMPA #VERSION make sure we have the
 BEQ E@ right version
I@ JSR NOTVALID
 LBRA Z@
E@ JSR DINPUT
 CMPA #$5A check for valid file
 BNE I@
* skip initial file header
 LDB #14 skip until VOI_PTR
 STB CNT,S
A@ JSR DINPUT
 DEC CNT,S
 BNE A@
* get voice pointers+end pointer
 LDB #20
 STB CNT,S
 LEAX PTRS,S
H@ JSR DINPUT get VOI_PTR for voice 1
 STA ,X+ (start of music code)
 DEC CNT,S
 BNE H@
* skip rest of the header
 LDD PTRS,S
 SUBD #36
 TFR D,X
K@ JSR DINPUT
 LEAX -1,X
 BNE K@
* convert pointers to # bytes per voice
 CLRA
 CLRB
 STD SIZ,S
 LDB #7
 STB CNT,S
 LEAX PTRS,S
L@ LDD 2,X
 SUBD ,X
 CMPD #$15F0 check for size
 BLS Q@
J@ BSR REQAMEM if too big, abort
 BRA Z@
Q@ STD ,X++
 ADDD SIZ,S
 STD SIZ,S
 DEC CNT,S
 BNE L@
 LDD 4,X get ENDPTR
 SUBD ,X calculate voice 8
 CMPD #$15F0 check size
 BHI J@
C@ STD ,X
 ADDD SIZ,S
 ADDD ENDPTR
 CMPD SCREEN will appended file
 BHS J@ exceed memory available?
* now get music one voice at a time into BUFFER
 CLR VOI,S voice counter (0->7)
 LEAU PTRS,S
G@ LDX BUFFER
 LDY ,U++ get length of voice
 STY ,X++
B@ JSR DINPUT
 STA ,X+
 LEAY -1,Y decrement voice length counter
 BNE B@ check for end of voice
 CLR ,X+ set end of buffer marker
 CLR ,X+
* now put buffer into music code
 LDD [BUFFER] don't move the end marker
 SUBD #2
 STD [BUFFER]
 LDB VOI,S
 JSR OPENBLK
D@ INC VOI,S
 LDB VOI,S
 CMPB #8
 BNE G@
 JSR RSETPTR
Z@ LBSR CLOSE
F@ LEAX FNAM,S restore filename
 LDY #FILENAME
 LDB #8
 LBSR MOVEDATA
 JSR DSPMUS
O@ LEAS 34,S deallocate local variable
 RTS

*REQAMEM - display a warning message when an appended
* file is too big to fit in BUFFER memory
*
REQAMEM PSHS X
 LDX #a@
 LBSR SETREQ
 LBSR DSPREQ
 LBSR WAITKEY
 LBSR REFMEN
 PULS X,PC
a@ FCB 48 		VPOS
 FCB 2 			HPOS
 FCB 26 		width of requester
 FCB 3 			height of requester
 FCB 0 			length of input
 FDB 0 			address of input area
 FCC "File too large; aborting."
 FCB 0 			end of requester
 ENDC
*  ---CONDITIONAL END

* If drive has not been accessed, home it first
*
INITDRIV PSHS B,X
 LDB DEFDRIV
* MOD May 19,1990 R.Gault
*     protect from hard drive system crash
*     caused by CLR B,X when B larger than 3
 CMPB #3
 BHI Z@
* EMOD
 LDX #a@
 TST B,X
 BEQ Z@
 CLR B,X
 LBSR DISKHOME
Z@ PULS B,X,PC
a@ FCB 1,1,1,1 		=0 if drive has been accessed

*GETFILE - get filename through directory requester
*ENTRY: X points to filename/extension
*EXIT: A=3 if BREAK pressed
* X=pointer to filename requested
*
FNAM SET 1 		stack variable
*
GETFILE PSHS B,X
E@ LDX #REQDIR
 LBSR SETREQ
C@ LDX FNAM,S
 LBSR DIR
 LDX #REQDIR
 LBSR DSPREQ
O@ CLR CLICK
A@ LBSR READMOUS
 LBSR REABUT
 LDA VPOS
 CMPA #12 check top and bottom
 BHI G@ limits for VPOS
 LDA #12
G@ CMPA #168
 BLO H@
 LDA #168
H@ STA VPOS
 LDB HPOS
 CMPB #3 check left and right
 BHI I@ bounds for HPOS
 LDB #3
I@ CMPB #27
 BLS J@
 LDB #27
J@ STB HPOS
 CMPD a@
 BEQ F@
*        PSHS    D
*        LDD     a@
*        LBSR    DSPBAR
*        PULS    D
 STD a@
*        LBSR    DSPBAR
 PSHS D
 LBSR CURREF
 LDA #1
 STA CSHIFT
 STA SHADOW
 PULS D
 LDX #CPOINTER
 LBSR CURSOR
F@ LBSR KEYIN
 CMPA #3
 LBEQ Z@
 TST CLICK
 BEQ A@
 LDD a@
*        LBSR    DSPBAR
* from cursor position, calculate position of filename
 CLRA
 LDB VPOS
 ADDB #3
 LDX #12
 LBSR DIVIDE
 TFR X,D
 DECB
 LDA #3
 MUL
 PSHS D
 CLRA
 LDB HPOS
 SUBB #3
 LDX #9
 LBSR DIVIDE
 TFR X,D
 ADDD ,S++
 LDA #9
 MUL
 ADDD #DIRSTR
 TFR D,X
 CMPD #DIRDRIVE
 BLO D@
 TFR X,D convert address to
 SUBD #DIRDRIVE drive number
* MOD May 21,1990 R.Gault
* Select drive0 or increase / decrease drive number
* Drive numbers roll over
 LDA DEFDRIV
 TSTB
 BNE B@
M@ CLR DEFDRIV
N@ PSHS Y
 LDY #FILEDRIV
 JSR HDDRIVE
 PULS Y
 LBRA C@
B@ CMPB #9
 BHI L@
 INC DEFDRIV
 CMPA RGBDRMAX
 BLO N@
 BRA M@
L@ CMPB #27 past the drive line
 LBHS O@ no action
 DEC DEFDRIV
 SUBA #1
 BCC N@
 LDA RGBDRMAX
 STA DEFDRIV
 BRA N@
* EMOD
D@ LBSR BLNKCHEK X already pointing to filename
 TSTA
* MOD May 14,1990 R.Gault exit if not aimed at file name
 BNE K@
 LDY FNAM,S move filename
 LDB #8
 LBSR MOVEDATA
Z@ LBSR CURREF
 LBSR REFMEN
 PSHS D,X,Y
 LBSR DSPFNAME
 PULS D,X,Y
 CLR CLICK
 LDX 1,S
 PULS B,X,PC
a@ FDB 0
K@ LDA #3 MOD imitate break key
 BRA Z@

 IFEQ 1
**** CONDITIONAL
*Display a bar over filename
*ENTRY: A=VPOS, B=HPOS
*
CNTV SET 0
CNTH SET 1
PRVX SET 2
*
DSPBAR PSHS D,X
 CMPD #0
 BEQ Z@
* first calculate display position of the bar
 TFR A,B
 CLRA
 LDX #12
 LBSR DIVIDE
 TFR X,D
 LDA #12
 MUL
 LDA #32
 MUL
 PSHS D
 LDB 3,S get HPOS
 SUBB #3
 CLRA
 LDX #9
 LBSR DIVIDE
 TFR X,D
 LDA #9
 MUL
 ADDD #3
 ADDD ,S++
 ADDD SCREEN
 TFR D,X
* now display the bar
 LEAS -4,S
 LDB #8
 STB CNTH,S
A@ STX PRVX,S
 LDB #12
 STB CNTV,S
B@ COM ,X
 LEAX 32,X
 DEC CNTV,S
 BNE B@
 LDX PRVX,S
 LEAX 1,X
 DEC CNTH,S
 BNE A@
 LEAS 4,S
Z@ PULS D,X,PC
 ENDC
 **** CONDITIONAL

 IFNE DEMO
* ---CONDITIONAL START
* check directory for FILENAME
* if user wishes to over-write, A=$FF, else A=0
*
FINDNAME PSHS B,X,Y,U
 LDX #FILENAME transfer filename
 LDY #DNAMBUF to DOS area
 LDB #11
 LBSR MOVEDATA
 JSR RAM_IO
 STA SLOW
 TST DOSVER
 BNE A@
 JSR $C65F scan directory for file
 BRA B@
A@ JSR $C68C
B@ ORCC #$50
 JSR RAM_LYR
 CLR $FF40
 LDA #$FF
 TST $0973 =0 if file not found
 BEQ Z@
 LDX #a@
 LBSR SETREQ
 LBSR DSPREQ
E@ LBSR KEYIN
 TSTA
 BEQ E@
 LBSR REFMEN
 CMPA #'Y
 BNE C@
D@ LDA #$FF
 BRA Z@
C@ CMPA #'y
 BEQ D@
 CLRA
Z@ PULS B,X,Y,U,PC
a@ FCB 60,6,18,3,0
 FDB 0
 FCC " Over-write file?"
 FCB 0
 ENDC
*  ---CONDITIONAL END

* EVNTFILE - output an event file to MIDI
* ENTRY: A=event number
*
EVNTFILE PSHS D,X,Y,U
 LDB #56 number of bytes per event
 MUL
 ADDD #MIDIEVNT+2
 TFR D,X
 LDY #FILENMEV
 LDB #8
 LBSR MOVEDATA
 LDX #FILENMEV
 LDA #'I
 LBSR OPEN
A@ LBSR DINPUT
 TST $70 check for errors
 BNE B@
 LBSR SENDMIDI
 BRA A@
B@ LBSR CLOSE
 PULS D,X,Y,U,PC

RAM_IO TST COCO3
 BNE A@
 PSHS D
 LDA #$35
 STA $FFA4
 LDD #$3637	This MMU block $37 is a copy of block $3E
 STD $FFA5
 PULS D,PC
A@ STA ROM_ON
 RTS

RAM_LYR TST COCO3
 BNE A@
 PSHS D
 LDA #$3C
 STA $FFA4
 LDD #$3D3E
 STD $FFA5
 STA FAST
 PULS D,PC
A@ STA ROM_OFF
 RTS