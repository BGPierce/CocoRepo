; Disassembly of Orchestra-90CC Cartridge ROM
; Assembles to the exact CRC of the original Orch90 ROM
; using Roger Taylor's RainbowIDE & his CCASM cross-assembler
;
; Orchestra 90 is unique in Color Computer software in that
; it includes a text editor, scoring (compiling), & playing
; of 5 voice music, Printer, Cassette, & Disk I/O as well as
; built in Telecommuitcations software.
; requiring only 16k and COLOR BASIC, it only uses 5 calls
; to the COLOR BASIC ROM. These are:
;
; [$A002] - CHROUT - Writes a character to a device
; [$A004] - CSRDON - Turns on the cassette motor
; [$A006] - BLKIN  - Reads a block from the cassette
; [$A008] - BLKOUT - Writes a block to the cassette
; [$A00C] - WRTLDR - Turns motor on and writes a Leader on
;					 the cassette
; These calls only appear once each in the Orch90 code.
; CHROUT is only used for the LIST to printer function. All 
; other 'screen printing' is done by the Orch90 code.
; Orch90 does it's own keyboard matrix reads as well as it own
; Disk I/O. It also has it's own telecommunitcations program
; built in. All of this, along with song editing, song scoring,
; and song playing is all contained in one 8k ROM.
; Considering all of this is done in 8k, and the whole program
; will run on a 16k COLOR BASIC machine, Orchestra90 is a
; pretty amazing piece of software.
;
; I would like to thank Pere, Tony, and Stewy from the Dragon
; forums for sending me their efforts in converting the Orch90
; code to use Dragon disk systems. Combined with my efforts,
; their sources with comments completed quite a few things I
; could not have figured out on my own. Anyone interested in
; their efforts to incorporate the Dragon disk system into
; Orchestra90 can contact them on the Dragon forum.
;
; This disassembly is still a work in progress and I will
; update it as I get a chance. I still have a few variables to
; sort out and label as well as quite a bit of commenting
; to complete.
; As it stands now, this source will assemble to an exact
; duplicate of the original Orchestra90 ROM
;
; Enjoy!
; Bill Pierce

SBUFSTRT	EQU	$5E		; Address of the beginning of the song buffer
DEVNUM		EQU	$6F		; Device number -2 = printer
SBUFEND		EQU	$74		; Address of the end of current buffer
FLGPLAY		EQU $5A		; Flags that a file is to play
FLGFAST		EQU $5C		; Flag for fast CPU play
FLGDSK		EQU $A9		; Cassette/disk flag, 0=cass 1=disk	
FLGV5		EQU $AA		; 4 or 5 voice flag, 0=4, 1=5

; Error numbers (ASCII)
ERR1		EQU '1'+$40	; Error 1 $71 : Memory overflow
ERR2		EQU '2'+$40	; Error 2 $72 : Symbol out of context
ERR3		EQU '3'+$40	; Error 3 $73 : Parameter error
ERR4		EQU '4'+$40	; Error 4 $74 : Invalid part number
ERR5		EQU '5'+$40	; Error 5 $75 : Measure overflow
ERR6		EQU '6'+$40	; Error 6 $76 : Note Overflow
ERR7		EQU '7'+$40	; Error 7 $77 : File I/O error; translate A using table at X

PLAYRAM		EQU $08B4

			ORG	#$C000
			; Entry
START		LDS   #$00FA		; $C000
JSRINIT		JSR   INIT			; $C004 JSRINIT $DF21 initialise
; (jsr puts address of start up message on stack)

;Start up message, music data
TITLE		FCC	"ORCHESTRA-90/CC (TM)"	; $C007
			FCB $0D
			FCC	"SOFTWARE AFFAIR, LTD."
			FCB $0D
			FCC	"COPYRIGHT 1984 JON BOKELMAN"
			FCB $0D
			FCC "LICENSED TO TANDY CORPORATION"
			FCB $0D
			FCC	"ALL RIGHTS RESERVED"
			FCB $0D
			FCC	"VERSION 01.01.00"
			; 
; demo song
; All lines begin with character code plus 128
; This eliminates the need for CRs in the score
; Any char read +=128, is presumed to be a new line
DEMOSNG		FCB	$AF					; $C090 '/' = 47+128
			FCC	' WILLIAM TELL OVERTURE'
			FCB $AF
			FCC	' BY ROSSINI'
			FCB	$A0					; ' ' = 32+128
			FCB	$A0					; ' ' = 32+128
			FCB	$A0					; ' ' = 32+128
			FCB	$A0					; ' ' = 32+128
			FCB	$A0					; ' ' = 32+128
			FCB	$A0					; ' ' = 32+128
			FCB	$CE					; 'N' = 78+128
			FCC	'Q=66Z2K4#<3O1'
			FCB	$CD					; 'M' = 77+128
			FCB	$D9					; 'Y' = 89+128
			FCC	'A(Q.6,S6;6;)1I6;4;2;4;6;4;6;9;'
			FCB	$CD					; 'M' = 77+128
			FCB	$B6					; '6' = 54+128
			FCC	';4;2;4;6;4;6;9;'
			FCB	$D6					; 'V' = 86+128
			FCC	'2YAQ.2,S2;2;Q.2,S4;4;'
			FCB	$D6					; 'V' = 86+128
			FCC	'3YEH..$S2;2;'
			FCB	$CD					; 'M' = 77+128
			FCB	$A8					; '(' = 40+128
			FCC	'Q.6,S6;6;)3'
			FCB	$D6					; 'V' = 86+128
			FCC	'2I4;3;2;3;4;6;5;4;3;4;3;5;4;3;2;4;'
			FCB	$D6					; 'V' = 86+128
			FCC	'32;@1;3;1;*2;4;3;2;-1;2;-1;3;2;-1;-3;2;'
			FCB	$D0					; 'P' = 80+128
			FCC	'03'
			FCB	$B6					; '6' = 54+128
			FCC	';S(6;6;I)1'
			FCB	$D6					; 'V' = 86+128
			FCC	'23;S(3;3;I)1'
			FCB	$D6					; 'V' = 86+128
			FCC	'3(1;S1;1;I1;1;'
			FCB	$C0					; '@' = 64+128
			FCC	'V4YA)1'
			FCB	$A8					; '(' = 40+128
			FCC	'R03)2'
			FCB	$D0					; 'P' = 80+128
			FCC	' '
			FCB	$AA					; '*' = 42+128
			FCC	'W6'
			FCB	$D6					; 'V' = 86+128
			FCC	'23'
			FCB	$D6					; 'V' = 86+128
			FCC	'31'	
			FCB	$C0					; '@' = 64+128
			FCC	'V4FH$'
			FCB	$D0					; 'P' = 80+128
			FCC	'05'
			FCB	$D5					; 'U' = 85+128
			FCC	'+7S1;1;'
			FCB	$D6					; 'V' = 86+128
			FCC	'3YB3;3;'
			FCB	$D6					; 'V' = 86+128
			FCC	'45;5;'
			FCB	$D0					; 'P' = 80+128
			FCC	'06'
			FCB	$A8					; '(' = 40+128
			FCC	'M'
			FCB	$B1					; '1' = 49+128
			FCC	'1,1;1;'
			FCB	$D6					; 'V' = 86+128
			FCC	'333,3;3;'
			FCB	$D6					; 'V' = 86+128
			FCC	'455,5;5;)1'
			FCB	$D0					; 'P' = 80+128
			FCC	'07'
			FCB	$AA					; '*' = 42+128
			FCC	'I2,3,4,@S1;1;'
			FCB	$D6					; 'V' = 86+128
			FCC	'2I(1,)2'
			FCB	$D6					; 'V' = 86+128
			FCC	'3(3,)2S3;3;'
			FCB	$D6					; 'V' = 86+128
			FCC	'4I(5,)2S5;5;'
			FCB	$CD					; 'M' = 77+128
			FCB	$B1					; '1' = 49+128
			FCC	'1,1;1;*22,4;4;'
			FCB	$C0					; '@' = 64+128
			FCC	'V2Q$I(1;S)2'
			FCB	$A8					; '(' = 40+128
			FCC	'V333,3;3;'
			FCB	$D6					; 'V' = 86+128
			FCC	'455,5;5;)1'
			FCB	$CD					; 'M' = 77+128
			FCB	$AA					; '*' = 42+128
			FCC	'I3,1,@1,S1;1;'
			FCB	$D6					; 'V' = 86+128
			FCC	'2I(1,)2'
			FCB	$D6					; 'V' = 86+128
			FCC	'3(4,)2S3;3;'
			FCB	$D6					; 'V' = 86+128
			FCC	'4I(6,)2S5;5;'
			FCB	$D2					; 'R' = 82+128
			FCC	'06'
			FCB	$D0					; 'P' = 80+128
			FCC	'08'
			FCB	$AA					; '*' = 42+128
			FCC	'I2,3,4,S24'
			FCB	$C0					; '@' = 64+128
			FCC	'V2I(1,)2S1;1;'
			FCB	$D6					; 'V' = 86+128
			FCC	'3I(3,)2S3;3;'
			FCB	$D6					; 'V' = 86+128
			FCC	'4I(5,)2S5;5;'
			FCB	$CD					; 'M' = 77+128
			FCB	$AA					; '*' = 42+128
			FCC	'Q6S6543'
			FCB	$C0					; '@' = 64+128
			FCC	'(V222,2;2;'
			FCB	$D6					; 'V' = 86+128
			FCC	'366,6;6;'
			FCB	$D6					; 'V' = 86+128
			FCC	'488,8;8;)1'
			FCB	$CD					; 'M' = 77+128
			FCB	$AA					; '*' = 42+128
			FCC	'I2;4;2;'
			FCB	$C0					; '@' = 64+128
			FCC	'V2$1;1;'
			FCB	$A8					; '(' = 40+128
			FCC	'V33;'
			FCB	$D6					; 'V' = 86+128
			FCC	'45;)2'
			FCB	$D2					; 'R' = 82+128
			FCC	'05YEV3YER06R07R06R08'
			FCB	$D0					; 'P' = 80+128
			FCC	' '
			FCB	$AA					; '*' = 42+128
			FCC	'U0YASB;B;'
			FCB	$D6					; 'V' = 86+128
			FCC	'29;9;'
			FCB	$C0					; '@' = 64+128
			FCC	'V3YA0;0;'
			FCB	$D6					; 'V' = 86+128
			FCC	'47;7;'
			FCB	$D0					; 'P' = 80+128
			FCC	'13'
			FCB	$A8					; '(' = 40+128
			FCC	'M'
			FCB	$AA					; '*' = 42+128
			FCC	'BB,B;B;'
			FCB	$D6					; 'V' = 86+128
			FCC	'299,9;9;'
			FCB	$D6					; 'V' = 86+128
			FCC	'300,0;0;'
			FCB	$C0					; '@' = 64+128
			FCC	'V477,7;7;)1'
			FCB	$A8					; '(' = 40+128
			FCC	'M'
			FCB	$AA					; '*' = 42+128
			FCC	'IB;E;'
			FCB	$D6					; 'V' = 86+128
			FCC	'29;7;'
			FCB	$D6					; 'V' = 86+128
			FCC	'30;$'
			FCB	$D6					; 'V' = 86+128
			FCC	'4-7;$)1'
			FCB	$D0					; 'P' = 80+128
			FCC	'14'
			FCB	$C2					; 'B' = 66+128
			FCC	';E;B;A;9;8;7;SB;B;'
			FCB	$D6					; 'V' = 86+128
			FCC	'2I9;7;9;8;7;7;4;S9;9;'
			FCB	$C0					; '@' = 64+128
			FCC	'V3I0;$3;$3;4;5;S0;0;'
			FCB	$D6					; 'V' = 86+128
			FCC	'4I7;$A;$(7;)2S7;7;'
			FCB	$D2					; 'R' = 82+128
			FCC	'13'
			FCB	$D0					; 'P' = 80+128
			FCC	'15'
			FCB	$AA					; '*' = 42+128
			FCC 'IB;E;D;C#;'
			FCB	$D6					; 'V' = 86+128
			FCC '29;7;A;9;'
			FCB	$D6					; 'V' = 86+128
			FCC '30;$1;0;'
			FCB	$C0					; '@' = 64+128
			FCC 'V47;$4;4;'
			FCB	$D0					; 'P' = 80+128
			FCC ' '
			FCB	$AA					; '*' = 42+128
			FCC 'D;C#;D;SB#;B;'
			FCB	$D6					; 'V' = 86+128
			FCC '2I8;7;8;S9;9;'
			FCB	$C0					; '@' = 64+128
			FCC 'V3I1;2#;1;S0;0;'
			FCB	$D6					; 'V' = 86+128
			FCC '4I(8;)2S7;7;'
			FCB	$D2					; 'R' = 82+128
			FCC '13R14R13R15'
			FCB	$D0					; 'P' = 80+128
			FCC ' '
			FCB	$AA					; '*' = 42+128
			FCC '(D;C#;E;C;)3'
			FCB	$D6					; 'V' = 86+128
			FCC '28;'
			FCB	$D6					; 'V' = 86+128
			FCC '3YCI-1;$$(S3;3;I3;)14;'
			FCB	$C0					; '@' = 64+128
			FCC 'V48;$$(S1;1;11,)1*2;'
			FCB	$CD					; 'M' = 77+128
			FCB	$A8					; '(' = 40+128
			FCC 'D;C#;E;C;)3'
			FCB	$D6					; 'V' = 86+128
			FCC '3I5;33"5;4;22"4;'
			FCB	$D6					; 'V' = 86+128
			FCC '43;-1-1"3;2;-3-3"2;'
			FCB	$CD					; 'M' = 77+128
			FCB	$D3					; 'D' = 83+128
			FCC 'D;C#;E;C;ID,'
			FCB	$C0					; '@' = 64+128
			FCC 'V2$1;1;'
			FCB	$D6					; 'V' = 86+128
			FCC '3$4;4;'
			FCB	$D6					; 'V' = 86+128
			FCC '4+3;6;6;'
			FCB	$D0					; 'P' = 80+128
			FCC ' '
			FCB	$A8					; '(' = 40+128
			FCC 'M'
			FCB	$AA					; '*' = 42+128
			FCC 'YBSA;A;AA,'
			FCB	$D6					; 'V' = 86+128
			FCC '2YC6;6;66,'
			FCB	$D6					; 'V' = 86+128
			FCC '33;3;33,'
			FCB	$C0					; '@' = 64+128
			FCC 'V41;1;I1;)1'
			FCB	$CD					; 'M' = 77+128
			FCB	$AA					; '*' = 42+128
			FCC 'B;C,AA"C;B,99"B;A,S6;6;I6;'
			FCB	$D6					; 'V' = 86+128
			FCC '29;A,66"A;9,44"9;8,'
			FCB	$D6					; 'V' = 86+128
			FCC '42;'
			FCB	$D6					; 'V' = 86+128
			FCC '34;@(+5,8,7,6,5,4,3,2,1,'
			FCB	$D6					; 'V' = 86+128
			FCC '4)1'
			FCB	$D2					; 'R' = 82+128
			FCC '05YAV2YAV3YAR06R07R06R08'
			FCB	$D2					; 'R' = 82+128
			FCC '05YEV3YER06R07R06R08'
			FCB	$D0					; 'P' = 80+128
			FCC ' Z1'
			FCB	$AA					; '*' = 42+128
			FCC 'YAS(6;6;'
			FCB	$D6					; 'V' = 86+128
			FCC '2)1'
			FCB	$C0					; '@' = 64+128
			FCC 'V41;1;'
			FCB	$A8					; '(' = 40+128
			FCC 'M'
			FCB	$AA					; '*' = 42+128
			FCC '66,6;6;'
			FCB	$D6					; 'V' = 86+128
			FCC '266,6;6;'
			FCB	$C0					; '@' = 64+128
			FCC 'V411,1;1;)1'
			FCB	$CD					; 'M' = 77+128
			FCB	$AA					; '*' = 42+128
			FCC 'I(B;C;D;$9;A;B;'
			FCB	$D6					; 'V' = 86+128
			FCC '2)1'
			FCB	$D6					; 'V' = 86+128
			FCC '44;5;6;$2;3;4;$'
			FCB	$CD					; 'M' = 77+128
			FCB	$C2					; 'B' = 66+128
			FCC ';C;D;'
			FCB	$D6					; 'V' = 86+128
			FCC '24;5;6;'
			FCB	$C0					; '@' = 64+128
			FCC 'V43;2;1;H$'
			FCB	$CD					; 'M' = 77+128
			FCB	$AA					; '*' = 42+128
			FCC 'S66#78%8#99#A'
			FCB	$C0					; '@' = 64+128
			FCC '(V2S4;1;'
			FCB	$D6					; 'V' = 86+128
			FCC '3YA6;$'
			FCB	$D6					; 'V' = 86+128
			FCC '48;$)3'
			FCB	$CD					; 'M' = 77+128
			FCB	$AA					; '*' = 42+128
			FCC 'U+7S4%4#55#66#78'
			FCB	$C0					; '@' = 64+128
			FCC '(V2S4;1;'
			FCB	$D6					; 'V' = 86+128
			FCC '36;$'
			FCB	$D6					; 'V' = 86+128
			FCC '48;$)3'
			FCB	$A8					; '(' = 40+128
			FCC 'M'
			FCB	$AA					; '*' = 42+128
			FCC 'YCS98A8'
			FCB	$D6					; 'V' = 86+128
			FCC '2YD98A8'
			FCB	$C0					; '@' = 64+128
			FCC 'V3I3;2;'
			FCB	$D6					; 'V' = 86+128
			FCC '45;8;)7'
			FCB	$CD					; 'M' = 77+128
			FCB	$AA					; '*' = 42+128
			FCC 'U0G;S(G9)2'
			FCB	$C0					; '@' = 64+128
			FCC 'V2YAQ$S(1;+2;)1'
			FCB	$D6					; 'V' = 86+128
			FCC '3YEI3;$S3;$3;'
			FCB	$D6					; 'V' = 86+128
			FCC '4I5;$S5;$5'
			FCB	$CD					; 'M' = 77+128
			FCB	$AA					; '*' = 42+128
			FCC 'IG;S(D6)2ID;S(B4)2IB;S(92)2'
			FCB	$C0					; '@' = 64+128
			FCC 'V2(I1;S1;1;I1;+2;)1'
			FCB	$A8					; '(' = 40+128
			FCC 'V33;S3;3;I3;1;'
			FCB	$D6					; 'V' = 86+128
			FCC '45;S5;5;I5;3;)2'
			FCB	$CD					; 'M' = 77+128
			FCB	$AA					; '*' = 42+128
			FCC '(9;S9;9;I9;9;9;S6;6;I6;6;6;'
			FCB	$D6					; 'V' = 86+128
			FCC '2)1'
			FCB	$C0					; '@' = 64+128
			FCC 'V33;(+2;)3(1;)3'
			FCB	$D6					; 'V' = 86+128
			FCC '4(5;)4(8;)3'
			FCB	$CD					; 'M' = 77+128
			FCB	$AA					; '*' = 42+128
			FCC '(S4;4;I4;4;4;S2;2;I2;2;'
			FCB	$D6					; 'V' = 86+128
			FCC '2)1'
			FCB	$C0					; '@' = 64+128
			FCC 'V3(3;)3(5;)2'
			FCB	$D6					; 'V' = 86+128
			FCC '4(A;)3(C;)2'
			FCB	$CD					; 'M' = 77+128
			FCB	$A8					; '(' = 40+128
			FCC '*V12;-1;'
			FCB	$D6					; 'V' = 86+128
			FCC '22;-1;'
			FCB	$C0					; '@' = 64+128
			FCC 'V35;8;)1'
			FCB	$D6					; 'V' = 86+128
			FCC '4U7C;8;5;8;'
			FCB	$CD					; 'M' = 77+128
			FCB	$AA					; '*' = 42+128
			FCC '(4;2;6;4;9;6;B;9;D;B;'
			FCB	$D6					; 'V' = 86+128
			FCC '2)1'
			FCB	$C0					; '@' = 64+128
			FCC 'V3(3;5;1;3;5;8;3;5;1;3;'
			FCB	$D6					; 'V' = 86+128
			FCC '4)1'
			FCB	$CD					; 'M' = 77+128
			FCB	$AA					; '*' = 42+128
			FCC 'Q.G,SG;G;'
			FCB	$D6					; 'V' = 86+128
			FCC '2Q.B,SB;B;'
			FCB	$D6					; 'V' = 86+128
			FCC '3U7Q.9,S9;9;'
			FCB	$D6					; 'V' = 86+128
			FCC '4Q.2,S2;2;'
			FCB	$CD					; 'M' = 77+128
			FCB	$A8					; '(' = 40+128
			FCC 'V1IG;'
			FCB	$D6					; 'V' = 86+128
			FCC '2B;'
			FCB	$D6					; 'V' = 86+128
			FCC '39;)3'
			FCB	$D6					; 'V' = 86+128
			FCC '42@131'
			FCB	$CD					; 'M' = 77+128
			FCB	$AA					; '*' = 42+128
			FCC 'Q.G,S$G;Q.G,S$9;W9'
			FCB	$D6					; 'V' = 86+128
			FCC '2Q.B,S$B;Q.B,S$-3;W-3'
			FCB	$D6					; 'V' = 86+128
			FCC '3Q.9,S$6;Q.6,@S$1;W1'
			FCB	$D6					; 'V' = 86+128
			FCC '4Q.5,S$5;Q.5,S$C;WC'

RETURN    RTS

; "command mode" command L : List to printer
; occupies 60 bytes
CMDLIST		JSR   GETPARM	; $C862 find command parameter $D70D
	    	BMI   C87C		; no parameter
			LDX   #TBLBAUD	; translation table $CFE2
	    	JSR   READTABL	; translate A using table at X $D650
	    	BCS   DSPERR	; $C8AD	display ?? on 2nd line
	    	STA   <$96		; CoCo baud rate
	    	LDA   1,U
	    	SUBA  #$57		; check for W parameter
	    	BEQ   C879		; set EOL delay approx 1s
	    	LDA   #$FF		; no EOL delay
C879    	COMA
	    	STA   <$97		; CoCo EOL delay
C87C    	LDA   #$FE		; device number for printer
	    	STA   <DEVNUM	; DEVN (device number)
	    	LDX   <$60
C882    	TST   ,X
	    	BPL   C88A
	    	LDA   #$0D
	    	BSR   C89A		; output character to DEVN
C88A    	LDA   ,X+
	    	ANDA  #$7F
	    	BEQ   RETURN
	    	CMPA  #$60   
	    	BCS   C896
	    	SUBA  #$40   
C896    	BSR   C89A		; output character to DEVN
	    	BRA   C882
C89A    	JMP  [$A002]	; BASIC vector - output character to DEVN

; "EDIT mode" command shift up: Deletes an end of line
; (joins two rows) works only at the begining of the row
; joining that line with previous one
CMDSUP		JSR   CADF		; $C89E
			LDX   <$62
 			ROL   ,X
			CLRA
			ROR   ,X
			JSR   CAC2
			BRA   C8E3

; display ?? on 2nd line
DSPERR		JMP   PRNTWHAT	; $C8AD display ?? on 2nd line $CC02

; "command mode" command '/' (6F): Goto string (down in score)
CMDGODWN	LDB   #$02		; $C8B0

; "command mode" command '-' (6D): Goto string (up in score)
CMDGOUP		DECB			; $C8B2
			STB   <$58
			LDX   <$62
C8B7		LDA   <$58
			LEAX  A,X
			CMPX  <SBUFEND	; end of song data $74
			BHI   DSPERR	; $C8AD	display ?? on 2nd line
			CMPX  <SBUFSTRT	; start of song data $5E
			BCS   DSPERR	; $C8AD	display ?? on 2nd line
			PSHS  X
			LEAU  1,Y
C8C7		LDA   ,U+
			BMI   C8E1
			EORA  ,X+
			ASLA
			BEQ   C8C7
			PULS  X
			BRA   C8B7

; "command mode" command <shift> <ENT>: Double Speed play
CMDFAST		TST   <$B9		; $C8D4
			BNE   CMDENTR	; $C8DA "command mode" command ENT
			INC   <FLGFAST	; fast mpu rate flag $5C

; "command mode" command ENT: send entered command
CMDENTR		STY   ,S		; $C8DA
			BSR   CLRLN2	; $C908 green fill 2nd line
			PULS  X,PC

C8E1		PULS  X
C8E3		STX   <$62
			LEAX  1,X
C8E7		TST   ,-X
			BPL   C8E7
C8EB		JSR   CABB
			LEAU  30,X
			CMPU  <$62
			BCC   C936
			LDA   ,X
			ASLA
			BEQ   C934
			LDB   #$1F
C8FD		LEAX  1,X
			TST   ,X
			BMI   C8EB
			DECB
			BNE   C8FD
			BRA   C8EB

; green fill 2nd line
CLRLN2		LDX   #$0420	; $C908 point to 1st char second line
			BRA   CLR2END	; green fill to end of line starting from X

C90D		LDX   <SBUFEND	; end of song data $74
C90F		STX   <$5D	
			STX   <SBUFSTRT	; start of song data $5E
C913		JMP   CAB9

; clear top line to green
CLRTOP		LDX   #$0400	; $C916
	
; green fill to end of line starting from X
CLR2END		LDA   #$01		; $C919

; green fill A lines starting from X
CLRALNS		LDB   #$8F		; $C91B green semigraphic full bloc
C91D		STB   ,X+		; put a green bloc
			EXG   X,D		; save D, get X
			BITB  #$1F		; reached end of line?
			EXG   X,D		; restore D
			BNE   C91D		; keep going until end of line
			DECA			; decrement line counter
			BNE   C91D		; do another line
			RTS				; return

; "command mode" command N : New
CMDNEW		LDX   <SBUFEND	; $C92B end of song data $74
C92D		BSR   C90F

; "command mode" command T : Top
CMDTOP		LDX   <SBUFSTRT	; $C92F start of song data $5E
			FCB   $8C 		; CMPX # ; NOP

; "command mode" command B : Bottom
CMDBOT		LDX  <SBUFEND	; FDB   $9E00+SBUFEND	; $C932  end of song data) $74
C934		BSR   C913
C936		LDA   #$06
			LDU   <$60
C93A		LDB   #$1F
			CMPU  <SBUFSTRT	; start of song data $5E
			BEQ   C94B
C941		TST   ,-U
			BMI   C948
			DECB
			BNE   C941
C948		DECA
			BNE   C93A
C94B		LDX   #$0440
			LDB   -1,X
			STB   <$6B
			TSTA
			BEQ   C957
			BSR   CLRALNS	; green fill A lines starting from X
C957		LEAX  -1,X
C959		LDB   <$6B
			STB   $043F
			TFR   X,D
			ORB   #$E0
			INCB
			BEQ   C969
			TST   ,U
			BPL   C974
C969		ROL   ,U
			COMB
			ROR   ,U
			BSR   CLR2END	; green fill to end of line starting from X
			CMPX  <$AD		; top of screen
			BEQ   C99A
C974		LDB   ,U
			ANDB  #$7F
			BNE   C97C
			LDB   #$8F
C97C		CMPU  <$62
			BNE   C98D
			STX   <$88		; cursor position
			TST   <$55
			BNE   C98D
			EORB  #$40   
			BPL   C98D
			EORB  #$4F   
C98D		STB   ,X+
			LDB   ,U+
			ASLB
			BNE   C959
C994		BSR   CLR2END	; green fill to end of line starting from X
			CMPX  <$AD		; top of screen
			BNE   C994
C99A		RTS

; "??? mode" command lookup table
C99B 		FCB	$03
			FDB	$CBE1	; BRK
	 		FCB	$0A
	 		FDB	$CA84	; down
	  		FCB	$0B
	  		FDB	$CA70	; up
	 		FCB	$0D
	 		FDB	$CA80	; ENT
	 		FCB	$1A
	 		FDB	$CAA7	; shift down
	 		FCB	$1B
	 		FDB	CMDSUP	; $C89E	shift up
	 		FCB	$1D
	 		FDB	$CA80	; shift ENT
	 		FCB	$21
	 		FDB	$CAD1	; !
	 		FCB	$3F
	 		FDB	$CA7C	; ?
	 		FCB	$FF

C9B7		LDA   1,X
			STA   ,X+

; "command mode" command shift left
C9BB		TST   ,X
			BPL   C9B7
			RTS

; "??? mode" command shift right
C9C0		LEAX  31,Y
C9C3		CMPX  <$88		; cursor position
			BEQ   C9CD
			LDA   ,-X
			STA   1,X
			BRA   C9C3
C9CD		LDA   #$60   
			STA   ,X
			RTS

; "??? mode" command lookup table
C9D2 		FCB	$03			; BREAK
			FDB	CMDBREAK	; $DDA4
	 		FCB	$08			; left
	 		FDB	$CA62
	 		FCB	$09			; right
	 		FDB	$CA5B
	 		FCB	$0C			; CLR
	 		FDB	$CB2C
	 		FCB	$0D			; ENTER
	 		FDB	CMDENTR		; $C8DA
	 		FCB	$13			; shift BRK
	 		FDB	$CA12
	 		FCB	$18			; shift left
	 		FDB	$C9BB
	 		FCB	$19			; shift right
	 		FDB	$C9C0
	 		FCB	$1C			; shift CLR
	 		FDB	$CB3C
	 		FCB	$1D			; shift ENTER
	 		FDB	CMDFAST		; $C8D4
	 		FCB	$FF

; clear 10 bytes starting at $0053
C9F1		LDX   #$0053
			LDB   #$0A

; clear B bytes starting at X
C9F6		CLR   ,X+
			DECB
			BNE   C9F6
			RTS

C9FC		LDY   #$0400
	    	TST   <$58
	    	BNE   CA07
	    	JSR   CLRTOP	; clear top line to green
CA07		STY   <$88		; cursor position
	    	BSR   C9F1		; clear 10 bytes starting at $0053
	    	BRA   CA22

; "command mode" command E : Edit
CMDEDIT		JSR   CLRTOP	; $CA0E clear top line to green
			DECB

; "??? mode" command shift BRK
CA12		INCB
			STB   <$58
			JSR   CLRLN2	; green fill 2nd line
			LDY   #$0500
			LDB   #$08
			STB   <$55
			STB   <$54
CA22    	STB   $FF22
CA25    	TST   <$54
			BEQ   CA2C
			JSR   C936
CA2C    	LDB   #$8F
			STB   31,Y
			JSR   CC09
			BSR   CA38
	    	BRA   CA25
CA38    	STA   <$54
	    	TST   <$55
	    	BEQ   CA44
	    	LDX   #$C99B
	    	JSR   GETCMD	; command lookup A in table at X $CBD1
CA44    	CLR   <$54	
	    	LDX   #$C9D2
	    	JSR   GETCMD	; command lookup A in table at X $CBD1
	    	CMPA  #$20
	    	BCS   CA5A
	    	ORA   #$40   
	    	STA   ,X+
	    	TFR   X,D
	    	BITB  #$20
	    	BEQ   CA6D
CA5A    	RTS

; "EDIT mode" command right: Move cursor to next char in the row
; at the end of the row goes to beginning again (wraps)
CA5B		TST   ,X+
			BPL   CA6D
			CLR   <$89
CA61		RTS

; "EDIT mode" command left: Move cursor to previous char in the row
; at the beginning of the row goes to the end again (wraps)
CA62		DEC   <$89
			BPL   CA61
			FCB	$8C			; CMPX  
CA67		LEAX 1,X
			TST   ,X
			BPL   CA67
CA6D		STX   <$88		; cursor position
			RTS

; "EDIT mode" command up:
; Goes to prior row (nothing on first row)
CA70		BSR   CADF	
CA72		CMPX  <SBUFSTRT	; start of song data $5E
			BEQ   CA94
			TST   ,-X
			BPL   CA72
			BRA   CA94

; "command mode" command '?' (7F):
; Display voicing at current position
CA7C		LDX   <SBUFEND	; end of song data $74
			BSR   CAB9

; "EDIT mode" command ENT:
; accepts current line  ...  / shift ENT  ??? what does this command do? 
CA80		TFR   Y,X
			STX   <$88		; cursor position

; "EDIT mode" command down:
; Goes to next row (nothing on last row)
CA84		BSR   CADF
CA86		CMPX  <SBUFEND	; end of song data $74
			BEQ   CAB9
			LEAX  1,X
			TST   ,X
			BPL   CA86
			CMPX  <SBUFEND	; end of song data $74
			BEQ   CAB9
CA94		BSR   CABB
			CLRB
CA97		CMPB  <$89
			BEQ   CAA1
			INCB
			TST   B,X
			BPL   CA97
			DECB
CAA1		ABX
			STX   <$62
			LDX   <$60
			RTS

; "EDIT mode" command shift down: Adds a newline at actual position
; so it creates an empty row at the beginning of a row
; and splits a row in any other position
CAA7		BSR   CADF
CAA9		LDX   <$62
			LDB   <$89
			BNE   CABB
			LDB   #$01
			BSR   CB10
			LDX   <$62
			LDB   #$60   `
			STB   ,-X
CAB9		STX   <$62
CABB		STX   <$60
			ROL   ,X
			COMB
			ROR   ,X
CAC2		LDB   #$80
			STB  [$0074]
			ORB  [$005E]
			STB  [$005E]
			RTS

; "EDIT mode" command ! (61):
; Move one line UP (full line goes one row up)
CAD1		CLR   <$89
			LDX   #$0800
			JSR   CLR2END	; green fill to end of line starting from X
			BSR   CA70		; "??? mode" command up
			BSR   CAA9
			TFR   Y,X
CADF		TFR   X,D
			CLRB
			TFR   D,X
			DECB
CAE5		INCB
			TST   B,X
			BPL   CAE5
			PSHS  A,B
			CLRA
			LDX   <$60
			CMPX  <SBUFEND	; end of song data $74
			BEQ   CAFA
CAF3		INCA
			TST   A,X
			BPL   CAF3
			LEAX  A,X
CAFA		PSHS  A,B,X
			SUBB  ,S+
			BEQ   CB02
			BSR   CB10
CB02		PULS  B,X,U
			TSTB
			BEQ   CA94
CB07		LDA   ,-U
			STA   ,-X
			DECB
			BNE   CB07
			BRA   CA94
CB10		STB   <$5D
			NEGB
			BPL   CB4B
			LDX   <SBUFSTRT	; start of song data $5E
			LEAU  B,X
			CMPU  #$1064
			LBLS  D219
			STU   <SBUFSTRT	; start of song data $5E
CB23		LDA   ,X+
			STA   ,U+
			CMPX  <$60
			BCS   CB23
			RTS

; "EDIT mode" command CLR:
; clears (blanks) till the end of actual editing row
CB2C		JSR   CLR2END	; green fill to end of line starting from X
			TST   <$55
			BEQ   CB3B
			TST   <$89
			BNE   CB3B
			LDB   #$60   `
			STB   ,Y
CB3B		RTS

; "EDIT mode" command shift CLR:
; deletes actual editing row
CB3C			TFR   Y,X
			STX   <$88		; cursor position
			JSR   CLR2END	; green fill to end of line starting from X
			TST   <$55
			BEQ   CB3B
			INC   <$54
			BRA   CADF

CB4B		LDX   <$60
			LEAU  B,X
CB4F		LDA   ,-X
			STA   ,-U
			CMPX  <SBUFSTRT	; start of song data $5E
			BHI   CB4F
			BEQ   CB5B
 			LEAU  1,U
CB5B		STU   <SBUFSTRT	; start of song data $5E
CB5D		RTS

; "command mode" command lookup table
CMDTABLE 	FCB	'@'			; $CB5E @ $40 move to last played note after <BREAK>
			FDB	CMDLAST	; $D48D
	 		FCB	'A'			; A $41 <filename> Append another file to the beginning of the current
	 		FDB	CMDAPEND	; $D170
	 		FCB	'B'			; B $42 Bottom - go to end of file
	 		FDB	CMDBOT		; $C932
	 		FCB	'C'			; C $43 Casseete Mode, puts orch90 in cassette mode
	 		FDB	CMDCASS		; $D021
	 		FCB	'D'			; D $44 Dir <num> - list directory of disk
	 		FDB	CMDDIR		; $D32D
	 		FCB	'E'			; E $45 Enter Edit mode
	 		FDB	CMDEDIT		; $CA0E
	 		FCB	'G'			; G $47 Get<fname1><fname2><etc> - load,score,play fnames
	 						;   G* plays all * wildcard supported in fnames
	 		FDB	CMDGET		; $CBB9
	 		FCB	'K'			; K $4B Kill <fname> (disk only)
	 		FDB	CMDKILL		; $D2F8
	 		FCB	'L'			; L $4C List file to printer
	 		FDB	CMDLIST		; $C862
	 		FCB	'M'			; M $4D Same as G, but starts over after last song
	 		FDB	CMDMULTI	; $CBAA
	 		FCB	'N'			; N $4E New -clears the music buffer
	 		FDB	CMDNEW		; $C92B
	 		FCB	'O'			; O $4F Optimize the current file
	 		FDB	CMDOPTMZ	; $DCAC
	 		FCB	'P'			; P $50 Play <num> Play alone will play complete file
	 						;	Play<num> plays from part #
	 		FDB	CMDPLAY		; $D85B
	 		FCB	'R'			; R $52 Read file 
	 		FDB	CMDREAD		; $D169
	 		FCB	'S'			; S $53 Score file for playing
	 		FDB	CMDSCORE	; $D4B9
	 		FCB	'T'			; T $54 Top, go to beginning of file
	 		FDB	CMDTOP		; $C92F
	 		FCB	'V'			; V $56 Verify <fname> Verifies cassette file
	 		FDB	CMDVERFY	; $D162
	 		FCB	'W'			; W $57 Write <fname> to cass or disk 
	 		FDB	CMDWRITE	; $D0A8
	 		FCB	'X'			; X $58 Transfer mode for telecommunications
	 		FDB	CMDTRFER	; $DDAB
	 		FCB	'!'+$40		; 97 - $21+$40=$61 ! $61 Play file from curren Pos
	 		FDB	CMDPLYC		; $DA1F
	 		FCB	'-'+$40		; 109 - $2D+$40=$6D - $6D <string> finds string up
	 		FDB	CMDGOUP		; $C8B2
	 		FCB	'/'+$40		; 111 - $2F+$40=$6F / $6F <string> finds string down
	 		FDB	CMDGODWN	; $C8B0
	 		FCB	'4'+$40		; 116 - $34+$40=$74 4 $74 Sets, & scroes in 4 voice mode
	 		FDB	CMD4V		; $D4D3
	 		FCB	'5'+$40		; 117 - $35+$40=$75 5 $75 Sets, & scores in 5 voice mode
	 		FDB	CMD4V		; $D4D3 (falls through to next instruction
	 		FCB	'?'+$40		; 127 - $3F+$40=$7F ? $7F Display voicing at current pos
	 		FDB	CMDVOCD	; $DA23
	 		FCB	$FF

; "command mode" command M : Multi
CMDMULTI	JSR   GETPARM	; $CBAA find command parameter $D70D
			BMI   CBE0
			STA   <$58
CBB1		LDA   <$58
			BEQ   REINIT	; $CBE9 Reinit the system
			LDY   #$0400

; "command mode" command G : Get
CMDGET		STY   <$64		; $CBB9
			STA   <$57
			LEAS  2,S
CBC0		LDY   <$64
			JSR   CMDREAD	; $D169
			JSR   INITHW	; $CEB7 initialise hardware
			JSR   CMDSCORE	; Score the file $D4B9
			JSR   JMPPLAY	; play the file $D869
			BRA   CBC0

; command lookup A in table at X
; doesn't return if command found
GETCMD		LEAX  3,X		; $CBD1 point to next entry
			CMPA  -3,X		; is A = code of previous entry?
			BCS   CBDD		; if code greater than A, exit
			BNE   GETCMD	; if not equal loopback $CBD1
			LDX   -2,X		; found! get address
			STX   ,S		; put onto stack (to jump there)
CBDD		LDX   <$88		; cursor position
			CLRB			; clear B
CBE0		RTS				; return if not found, else jump to found address

; "EDIT mode" command BRK:
; exits edit mode and goes to Command Mode
CBE1		JSR   CADF		; $CBE1
			CLR   <$55
CBE6		JSR   C936
REINIT		LDS   #$00FA	; $CBE9 Reset stack back to $FA
			JSR   INITHW	; initialise hardware $CEB7
			BSR   CMDLOOP	; $CBF4 Start the command loop again
			BRA   REINIT	; $CBE9 Reinit the system after cmd loop returns error
							; or after cmd has processed. Main loop.

; Command Loop - polls keyboard until input,
; if cmd is found, it never returns from GETCMD.
; If it returns, there was an error and falls through to
; PRNTWHAT
CMDLOOP		BSR   POLLKEY	; $CBF4 scan keyboard $CC5B
			JSR   C9FC
			LDA   ,Y
			BMI   REINIT	; $CBE9 Reinit the system
			LDX   #CMDTABLE	; "command mode" lookup table $CB5E
			BSR   GETCMD	; command lookup A in table at X $CBD1

; display ?? on 2nd line
PRNTWHAT		LDD   #$7F7F	; $CC02 Put "??" in D
			STD   $0420		; Print it on the beginning of the 2nd line
			RTS				; Return

CC09		CLR   <$6A
			LDX   <$88		; cursor position
			LDB   ,X
			STB   <$AF		; saved character under cursor
CC11		BSR   CC1F
			TST   <$B0
			BEQ   CC11
			LDA   <$87
			ASL   <$94
			BCS   CC11
			BRA   CC44

CC1F		LDX   <$88		; cursor position
			LDB   ,X
			TST   <$6A
			BNE   CC2D
			EORB  #$40   
			BPL   CC2D
			EORB  #$4F   
CC2D		STB   ,X
			BSR   POLLKEY	; scan keyboard $CC5B
			BNE   CC3C
			DEC   <$6A
			LDB   <$6A
			BITB  #$3F   
			BNE   CC1F
			RTS

CC3C		LEAS  2,S
			STA   <$87
			LDB   #$FC
			STB   <$94
CC44		LDB   <$AF		; saved character under cursor
			STB  [$0088]
			RTS

CC4B		LDX   #$045E	; set up for approx 10ms delay
			TST   <$70		; transfer mode flag
			LBEQ  D408		; delay X*8 cycles
			LDB   #$9D
CC56		SYNC
			DECB
			BNE   CC56
			RTS

; scan keyboard
; first gets scan code of pressed key
; then converts to character code modified by shift
POLLKEY		LDU   #$FF00	; $CC5B
			LDX   #$00B0
			CLR   ,X+
			CLRA
			DECA
			PSHS  A,X
			STA   2,U		; initialise $ff02 (keyboard)
CC69		ROL   2,U		; select next keyboard col
			BCC   CCAB		; all cols done. go to exit.
			INC   ,S
			BSR   CCEC
			STA   1,S
			TFR   A,B
			EORA  ,X
			STB   ,X
			ORB   <$B0
			STB   <$B0
			ANDA  ,X+
			BEQ   CC69
			LDB   2,U
			STB   2,S
			LDB   #$F8
CC87		ADDB  #$08
			LSRA
			BCC   CC87
			ADDB  ,S
CC8E		CMPB  #$1A
			BHI   CCAF		; not @-Z
			TST   <$70		; transfer mode flag
			BEQ   CC9A
			BSR   CCDC		; check for down arrow pressed
			BNE   CC9C
CC9A		ADDB  #$40		; convert @-Z to character code
CC9C		STB   ,S
			BSR   CC4B
			LDA   2,S
			BSR   CCEA
			CMPA  1,S
			BNE   CCAB
			LDB   ,S
			FCB   $8C		; CMPX  #		; NOP
CCAB		CLR	  ,S
			PULS  A,X,PC
CCAF		LDX   #$CCDE
			CMPB  #$21   
			BLO   CCCC		; up dn lft rgt spc 0
			LDX   #$CCC0
			CMPB  #$30   
			BHS   CCCC		; ENT CLR BRK . . . . SHFT
			BSR   CCE3		; check for shift key pressed
			CMPB  #$2B
			BLS   CCC5		; 1 2 3 4 5 6 7 8 9 : ; (not , - . /)
			EORA  #$40		; invert shift flag
CCC5		TSTA
			BNE   CC9C
			ADDB  #$10
			BRA   CC9C
CCCC		ASLB
			TST   <$70		; transfer mode flag
			BEQ   CCD3
			ADDB  #$12
CCD3		BSR   CCE3		; check for shift key pressed
			BEQ   CCD8		; no shift
			INCB			; adjust for shifted key
CCD8		LDB   B,X
			BRA   CC9C

; check for down arrow pressed
; requires U = $ff00
CCDC		LDA   #$EF
			BSR   CD04		; read keyboard col
			ANDA  #$08
			RTS

; check for shift pressed
; requires U = $ff00
CCE3		LDA   #$7F
			BSR   CD04		; read keyboard col
			ANDA  #$40   
			RTS

CCEA		STA   2,U
CCEC		BSR   CD06
			TST   2,U
			BMI   CCF5
			ANDA  #$3F   
			RTS
CCF5		TST   <$70		; transfer mode flag
			BEQ   CD01
			LDB   2,U
			CMPB  #$EF
			BNE   CD01
			ANDA  #$77   
CD01		ORCC  #$01
			RTS

; read keyboard col
; value to write in A
; returns inverted keyboard output in A
; requires U = $ff00
CD04		STA   2,U
CD06		TST   <$70		; transfer mode flag
			BEQ   CD0E
			SYNC
			LDA   <$6A
			FCB   $8C		; CMPX  #; NOP
CD0E 		LDA   ,U
			COMA
			ANDA  #$7F		; mask off comparator bit
			RTS

; scan code to character code lookup table
; normal code followed by shifted code
CD14 		FCB   $0B,$1B	; up
	 		FCB   $0A,$1A	; down
	 		FCB   $08,$18	; left
	 		FCB   $09,$19	; right
	 		FCB   $20,$20	; space
	 		FCB   $30,$5F	; 0

; scan code to character code lookup table
; normal code followed by shifted code
CD20 		FCB   $0D,$1D	; ENT
	 		FCB   $0C,$1C	; CLR
	 		FCB   $03,$13	; BRK


; alternate scan code lookup table (transfer mode)
; normal code followed by shifted code
CD26 		FCB   $5E,$5C	; up
	 		FCB   $00,$00	; down
	 		FCB   $08,$5B	; left
	 		FCB   $09,$5D	; right
	 		FCB   $20,$20	; space
	 		FCB   $30,$5F	; 0

; alternate scan code lookup table (transfer mode)
; normal code followed by shifted code
CD32 		FCB   $0D,$0D	; ENT
	 		FCB   $1B,$80	; CLR
	 		FCB   $FF,$8F	; BRK

; data
CD38 		FCB   $20,$3F,$54,$50    	;    ?  T  P
	 		FCB   $4D,$4F,$52,$50    	; M  O  R  P
MSGOLAP 	FCB   $4F,$56,$45,$52   	; $CD40 O  V  E  R
	 		FCB   $4C,$41,$50,$3F    	; L  A  P  ?

; munge high nybbles at X from 4 bytes into 2
CD48		BSR   CD4C
			TFR   B,A
CD4C		LDB   1,X
			LSRB
			LSRB
			LSRB
			LSRB
			ORB   ,X++
			RTS

; Division: (,X) = D/(1,S) rem D ?
CD55		CLR   ,X
			FCB	$8C			; CMPX  
CD58		INC ,X
			SUBD  3,S
			BCC   CD58
			ADDD  3,S
			RTS
CD61		LDA   9,U
			ADDA  #$0F
			LDB   <$66
			MUL
			STA   <$1C
			LEAX  1,U
			BSR   CD48		; munge high nybbles at X from 4 bytes into 2
			STD   <$18
			BSR   CD48		; munge high nybbles at X from 4 bytes into 2
			STD   <$1A
CD74		LDD   <$18
			BNE   CD7C
			LDD   <$1A
			STD   <$18
CD7C		ADDD  <$18
			BCC   CD84
			EORA  <$1A
			EORB  <$1B
CD84		STD   <$18
			ANDA  #$80
			BEQ   CD8C
			LDA   <$1C
CD8C		STA  [$0016]
			INC   <$17
			BNE   CD74
			JMP   CE5A

; Division: D = D / X ?
CD97		PSHS  B,X
			LDX   #$006B
			TFR   A,B
			CLRA
			BSR   CD55		; Division: (,X) = D/(1,S) rem D ?
			TFR   B,A
			LDB   ,S
			LEAX  1,X
			BSR   CD55		; Division: (,X) = D/(1,S) rem D ?
			PULS  B,X
			LDD   <$6B
			RTS

CDAE		JSR   DAE4
			LDX   #$CEE2
			LDU   #$0800
			JSR   D4AA		; copy bytes from X to U. (Length at -1,X)
			PULS  Y
			LDB   #$80		; construct -ve half of sine wave
			LEAX  B,X		;
CDC0		LDA   ,X+		;
			NEGA			;
			STA   ,U+		;
			DECB			;
			BNE   CDC0		;
			CLR   <$56
			LDY   #$0F00	; Point to wave data
			LDA   #$0A		; number of bytes to test
CDD0		STA   <$16		; save at own variable
			LDD   #$0A04	; A=numbytes - B=control value (Zero flag in CCR set to 1)
			STA   <$6C		; save numbytes at counter
CDD7		LDA   ,Y+		; get a byte from wave data
			CMPA  49,Y		; is it the same as 'old' data copy'?
			PSHS  CC		; save CCR onto stack
			ANDB  ,S+		; AND with stacked CCR. If stacked flag was 0, B value is zero too
			STA   49,Y		; update 'copy of data'
			DEC   <$6C		; decrement counter
			BNE   CDD7		; if not zero, compare next byte
			TSTB			; is B zero (different data)?
			BNE   CE5A		; NO, skip section (don't recalculate waves)
			CLR   <$17
			LEAU  -10,Y
			TST   ,U
			LBEQ  CD61
			LDA   #$08
			LDX   <$8A		; zero
			STX   <$14
CDFA		LDB   A,U
			ABX
			DECA
			BNE   CDFA
			LDA   #$08
CE02		PSHS  A
			CLRB
			LDA   A,U
			BEQ   CE10
			BSR   CD97		; Division: D = D / X ?
			DECA
			BMI   CE10
			LDB   #$FF
CE10		PULS  A
			STB   A,U
			DECA
			BNE   CE02
CE17		BSR   CE83
			TSTA
			BPL   CE1E
			BSR   CE75
CE1E		CMPD  <$14
			BCS   CE25
			STD   <$14
CE25		INC   <$17
			BPL   CE17
			LDD   <$14
			BSR   CE7C		; signed divide D by 16
			PSHS  A,B
			LDX   ,S++
			BEQ   CE39
			LDA   <$67
			CLRB
			JSR   CD97		; Division: D = D / X ?
CE39		STB   <$14
			CLR   <$17
CE3D		BSR   CE83
			LDB   <$14
			BSR   CE70		; signed multiply D = A x B
			BSR   CE7C		; signed divide D by 16
			TFR   B,A
			LDB   9,U
			ADDB  #$0F
			BSR   CE70		; signed multiply D = A x B
			ADDA  <$67
			BPL   CE52
			CLRA
CE52		STA  [$0016]
			INC   <$17
			BNE   CE3D
CE5A		LDA   <$16
			INCA
			CMPA  #$0F
			LBLO  CDD0
			TST   <FLGPLAY	; IS file to be played? $5A
			BNE   CEAF
			TST   <$59
			BEQ   CEAC
			JSR   C90D
			BRA   CEAF

; signed multiply D = A x B
CE70		TSTA
			BPL   CEDF		; MUL RTS
			NEGA
			MUL
CE75		COMB
			COMA
			ADCB  #$00
			ADCA  #$00
			RTS

; signed divide D by 16
CE7C		BSR   CE7E
CE7E		BSR   CE80
CE80		ASRA
			RORB
			RTS

CE83		CLR   ,-S
			CLR   ,-S
			LDA   #$08
CE89		PSHS  A
			LDB   A,U
			BEQ   CEA5
			PSHS  B
			CLRB
CE92		ADDB  <$17
			DECA
			BNE   CE92
			LDX   #$0800
			ABX
			LDA   ,X
			PULS  B
			BSR   CE70		; signed multiply D = A x B
			ADDD  1,S
			STD   1,S
CEA5		PULS  A
			DECA
			BNE   CE89
			PULS  A,B,PC

CEAC		JSR   CMDTOP
CEAF		CLR   <$5D
			CLR   <$59
CEB3		LDS   #$00F8

; Initialise hardware
INITHW		ORCC  #$FF		; $CEB7
			TFR   CC,DP		; DP points to $ff00
			CLR   <$D8		; set slow MPU rate 
			CLR   <$D6		; set slow MPU rate
			CLR   <$C6		; set screen base address to $400
			LDD   #$353C	; set up PIAs
			STA   <$01		;; $FF01=%b0011 0101 enable HS irq	*** WHAT DO WE NEED IT FOR?
			STB   <$03		;
			DECA			;
			STA   <$21		;
			STB   <$23		;
			TST   <$02		;
			CLR   <$22		; set VDG to flat char screen: 512 bytes
			LDD   #$0003	; floppies must be at slot 4
			ORB   <$7F
			STB   <$7F
			CLR   <$40		; disk output latch ($ff40)
			TFR   A,DP		; DP points to $0000
			CLR   <$A0		; disk output latch value ($ff40)
			RTS

; called by 8x8 signed multiply
CEDF		MUL
			RTS


; +ve half of sine wave. Amplitude 2A
; length of data
			FCB   $80
; data copied to $0800
CEE2 		FCB   $00,$01
	  		FCB   $02,$03,$04,$05
	 		FCB   $06,$07,$08,$09
	 		FCB   $0A,$0B,$0C,$0D
	 		FCB   $0E,$0F,$10,$11
	 		FCB   $12,$13,$14,$15
	 		FCB   $16,$17,$18,$18
	 		FCB   $19,$1A,$1B,$1C
	 		FCB   $1C,$1D,$1E,$1F
	 		FCB   $1F,$20,$21,$21
	 		FCB   $22,$23,$23,$24
	 		FCB   $24,$25,$25,$26
	 		FCB   $26,$27,$27,$27
	 		FCB   $28,$28,$29,$29
	 		FCB   $29,$29,$2A,$2A
	 		FCB   $2A,$2A,$2A,$2A
	 		FCB   $2A,$2A,$2A,$2A
	 		FCB   $2A,$2A,$2A,$2A
	 		FCB   $2A,$2A,$2A,$29
	 		FCB   $29,$29,$29,$28
	 		FCB   $28,$27,$27,$27
	 		FCB   $26,$26,$25,$25
	 		FCB   $24,$24,$23,$23
	 		FCB   $22,$21,$21,$20
	 		FCB   $1F,$1F,$1E,$1D
	 		FCB   $1C,$1C,$1B,$1A
	 		FCB   $19,$18,$18,$17
	 		FCB   $16,$15,$14,$13
	 		FCB   $12,$11,$10,$0F
	 		FCB   $0E,$0D,$0C,$0B
	 		FCB   $0A,$09,$08,$07
	 		FCB   $06,$05,$04,$03
	 		FCB   $02,$01

; +ve half of sine wave. Amplitude 3F
; data copied to $0800
CF62 		FCB   $00,$02
	  		FCB   $03,$05,$06,$08
	  		FCB   $09,$0B,$0C,$0E
	  		FCB   $0F,$11,$12,$14
	  		FCB   $15,$17,$18,$1A
	 		FCB   $1B,$1D,$1E,$1F
	 		FCB   $21,$22,$23,$25
	 		FCB   $26,$27,$28,$29
	 		FCB   $2B,$2C,$2D,$2E
	 		FCB   $2F,$30,$31,$32
	 		FCB   $33,$34,$35,$36
	 		FCB   $36,$37,$38,$39
	 		FCB   $39,$3A,$3B,$3B
	 		FCB   $3C,$3C,$3D,$3D
	 		FCB   $3E,$3E,$3E,$3F
	 		FCB   $3F,$3F,$3F,$3F
	 		FCB   $3F,$3F,$3F,$3F
	 		FCB   $3F,$3F,$3F,$3F
	 		FCB   $3F,$3F,$3E,$3E
	 		FCB   $3E,$3D,$3D,$3C
	 		FCB   $3C,$3B,$3B,$3A
	 		FCB   $39,$39,$38,$37
	 		FCB   $36,$36,$35,$34
	 		FCB   $33,$32,$31,$30
	 		FCB   $2F,$2E,$2D,$2C
	 		FCB   $2B,$29,$28,$27
	 		FCB   $26,$25,$23,$22
	 		FCB   $21,$1F,$1E,$1D
	 		FCB   $1B,$1A,$18,$17
	 		FCB   $15,$14,$12,$11
	 		FCB   $0F,$0E,$0C,$0B
	 		FCB   $09,$08,$06,$05
	 		FCB   $03,$02

; translation table for L command
; (baud rate selection)
TBLBAUD 	FCB   '1'+$40,$29		;  $CFE2 1 = previous rate (600 default)
	 		FCB   '2'+$40,$12		; 2 = 2400 baud
	 		FCB   '3'+$40,$B4		; 3 = 300 baud
	 		FCB   '6'+$40,$57		; 6 = 600 baud
	 		FCB   $FF

; data
CFEB 		FCB   $01,$E0,$F0,$A0,$50
	 		FCB   $40,$40,$00,$00,$E0
	 		FCB   $01,$40,$80,$F0,$80
	 		FCB   $F0,$20,$00,$00,$F0
	 		FCB   $01,$E0,$00,$50,$00
	 		FCB   $F0,$00,$00,$00,$A0
	 		FCB   $01,$F0,$40,$00,$80
	 		FCB   $00,$00,$00,$00,$B0
	 		FCB   $01,$40,$F0,$20,$80
	 		FCB   $10,$40,$00,$00,$D0

; disk select table for drives 1-4
; (value to write to $ff40)
D01D		FCB   $29,$2A,$2C,$68

; "command mode" command C : Cassette
CMDCASS 	CLR <FLGDSK	; $D021 disk mode flag $A9
			RTS

D024		JMP  ERROR7	; Error 7 : File I/O error $D206

D027		CLR   <$8E
			LDD   #$0120
			STA   <$A1
D02E		LDA   B,Y
			INCA
			BNE   D050
			STB   ,U
			LEAU  B,Y
			LDA   #$C0
			STA   ,U
D03B		PSHS  B
			TFR   B,A
			LSRA
			CMPA  #$11
			BCS   D045
			INCA
D045		ANDB  #$01
			BEQ   D04B
			LDB   #$09
D04B		INCB
			STD   <$A3		; disk track & sector numbers
			PULS  B,PC

D050		ADDB  <$A1
			BMI   D024		; Error 7 : File I/O error
			CMPB  #$44   
			BNE   D02E
			NEG   <$A1
			LDB   #$1F
			BRA   D02E

; write file to disk
D05E		INC   <$5B
			JSR   D2FB
			JSR   D389		; open disk directory
D066		JSR   D370		; point to next directory entry
			BCS   D024		; Error 7 : File I/O error
			LDA   ,X
			BEQ   D072
			INCA
			BNE   D066
D072		LDU   #$000D
			BSR   D027
			LDD   <SBUFSTRT	; start of song data $5E
			STD   <$7E		; tape/disk data pointer
			LDA   #$20
			STA   <$9F		; disk r/w flag 0=r $20=w
D07F		LDA   #$08
			CMPA  <$8E
			BCC   D087
			BSR   D027
D087		JSR   D3AB
			INC   <$7E		; tape/disk data pointer
			INC   <$A4		; disk sector number
			INC   <$8E
			DEC   <$0E
			BPL   D07F
			INC   <$0E
			LDA   <$8E
			ORA   #$C0
			STA   ,U
			LDX   <$8A		; zero
			LDU   <$8C		; current directory entry in sector buffer
			LDB   #$10
			JSR   D4B1		; copy B bytes from X to U
			JMP   D322	

; "command mode" command W : Write
CMDWRITE	LDX   <SBUFSTRT	; $D0A8 start of song data $5E
			BSR   D0F1		; get filename
			LBMI  CBB1
			LDD   <SBUFEND	; end of song data $74
			SUBD  <SBUFSTRT	; start of song data $5E
			STD   <$0E
			TST   <FLGDSK	; disk mode flag #A9
			BNE   D05E		; write file to disk
			JSR  [$A00C]	; BASIC vector - Write leader
D0BE		BSR   D0ED		; Write block
			LDD   #$50FF	; delay between blocks
D0C3		DECA
			BNE   D0C3
			INCA			; D = $01ff  (data block, length = $ff)
			STD   <$7C		; cassette block type/length
			LDX   <$12		; start of data to write
			LDU   #$0802	; write buffer address
			STU   <$7E		; tape/disk data pointer
			JSR   D4B1		; copy B bytes from X to U
			STX   <$12		; start of data to write
			LDD   #$FF01	; -255
			ADDD  <$0E		; subtract 255 from length of data
			STD   <$0E		; length of data to write
			BPL   D0BE		; more data to write
			ADDD  #$00FF	; correction
			STB   <$7D		; tape block length
			BEQ   D0E8		; no more data
			TSTA
			BPL   D0BE		; write last data block
D0E8		LDD   #$FF00	; zero length EOF block
			STD   <$7C		; Block type & length
D0ED		JMP  [$A008]	; BASIC vector - Write block

; get filename
D0F1		STX   <$12
			JSR   CLRLN2	; green fill 2nd line
			JSR   GETPARM	; find command parameter $D70D
			STU   <$64
			LDX   <$8A		; zero
			STX   <$A1
			LDD   #$000F	; filename block, length 15
			STD   <$7C		; cassette block type & length
			LDA   #$20		; initialise filename block to $20 x 15
D106		STA   ,X+
			DECB
			BPL   D106
			LDA   #$01
			STD   <$0B		; <$0b = $01ff (data, ASCII)
			CLR   <$0D		; ungapped
			LDX   <$8A		; zero
			TST   <FLGDSK	; disk mode flag $A9
			BNE   D119		; if disk, jump next one
			LEAX  3,X
D119		STX   <$7E		; tape/disk data pointer
			STB   ,X
			LDB   #$08
D11F		LDA   ,U+
			BMI   D154
			CMPA  #$60   
			BEQ   D154
			CMPA  #$7A		; :
			BEQ   D148
			CMPA  #$6F		; /
			BEQ   D140
			BITA  #$20
			BEQ   D135
			ANDA  #$BF
D135		STA   ,X+
			CMPA  #$2A   
			BNE   D13D
			STA   <$A1
D13D		DECB
			BNE   D11F
D140		LDA   ,U+
			BMI   D154
			CMPA  #$7A   
			BNE   D140
D148		LDA   ,U+
			SUBA  #$70   
			CMPA  #$04
			STA   <$A2		; drive number
			LBCC  ERROR7	; Error 7 : File I/O error $D206
D154		LDA   <$03
			ORA   <$00
			BMI   D160
			TST   <$A1
			BNE   D160
			CLR   <$A7
D160		TSTA
			RTS

; "command mode" command V : Verify
CMDVERFY	TST   <FLGDSK	; $D162 disk mode flag $A9
	    	LBNE  PRNTWHAT	; display ?? on 2nd line $CC02
	  		FCB   $21		; BRN	 exposes LDD <$8A

; "command mode" command R : Read
CMDREAD		FCB   $CC		; $D169 LDD #$DC8A	
	 		LDD   <$8A		; zero
			LDX   <SBUFEND	; end of song data $74
			BRA   D174

; "command mode" command A : Append
CMDAPEND	LDX   <SBUFSTRT	; $D170 start of song data $5E
			CLRA
			INCB
D174		STD   <$6B		; read & verify flags
			JSR   D0F1		; get filename
			LBMI  CBB1
			LDX   #$0802
			STX   <$7E		; tape/disk data pointer
			TST   <$6B		; read flag
			BEQ   D189		; not reading - skip New
			JSR   CMDNEW	; command N : New
D189		TST   <FLGDSK	; disk mode flag $a9
			LBNE  D254		; disk mode read or append
			LDX   #$0420
			LDD   #$0F13
			STB   ,X+
			JSR   CLRALNS	; green fill A lines starting from X
D19A		JSR  [$A004]	; BASIC vector - Read leader
			BSR   D20A		; Flash cursor, read block, point X to data
			TST   <$7C		; cassette block type
			BMI   D189		; EOF
			BNE   D19A		; loop until filename block found
			LDU   #$0422
			JSR   D308		; copy 8 characters from X to display at U
			LEAX  -8,X
			LDU   #$0003	; point to specified filename
			LDB   #$08		; 8 characters in filename
D1B3		LDA   ,U+
			CMPA  #$2A   
			BEQ   D1C0		; no filename was specified. load this file.
			CMPA  ,X+
			BNE   D19A		; filename doesn't match. get next file.
			DECB
			BNE   D1B3		; loop for 8 characters in filename
D1C0		ABX				; move X to 1st byte after filename
			LDU   ,X		; check file type
			CMPU  <$0B		; <$0b = $01ff (data, ASCII)
			BNE   D19A		; file not correct type, get next file
			TST   <$81		; cassette error flag
			BNE   ERROR7	; Error 7 : File I/O error $D206
			LDU   3,X		; get length of file
			STU   <$0E		; length of data
			LDD   <$12		; load end address
			SUBD  <$0E		; calculate load start address
			BCS   D219		; Error 1 : Memory overflow
			CMPD  #$1064	; lowest allowed address
			BLS   D219		; Error 1 : Memory overflow
			TFR   D,U
			TST   <$6C		; verify
			BEQ   D1E4		; verify: don't store new start address

			STU   <SBUFSTRT	; start of song data $5E
D1E4		CMPU  <SBUFSTRT	; start of song data $5E
			BNE   ERROR7	; Error 7 : File I/O error $D206
			LDA   #$46   	; 'F'
			STA   $0420		; Put it on the 2nd screen line
D1EE		STU   <$12		; current load address
			BSR   D20A		; Flash cursor, read block, point X to data
			TSTA
			BNE   ERROR7	; Error 7 : File I/O error $D206
			TST   <$7C		; cassette block type
			BEQ   ERROR7	; filename block... Error 7 : I/O error $D206
			BMI   D240		; EOF
			LDU   <$12
			LDB   <$7D		; copy or compare data just loaded
			BEQ   D1EE
			JSR   D495
			BEQ   D1EE

; Error 7 : File I/O error
ERROR7		LDA   #ERR7   	; $D206 Error 7 : File I/O error
			BRA   PRNTERROR	; Error message $D221

; Flash cursor, read block, point X to data
D20A		LDA   $0420
			EORA  #$40  
			STA   $0420
			JSR  [$A006]	; BASIC vector - Read block
			LDX   <$7E		; tape/disk data pointer
			RTS
		   
; Error 1 : Memory overflow		   
D219		LDA   #ERR1
			TST   <$59
			BEQ   PRNTERROR	; Error message $D221
			CLR   <$56
PRNTERROR	STA   $043E		;$D221 Print "ER #" 
			LDD   #$4552	; 'ER'
			STB   $043C
			STD   $043A
			TST   <$56
			BEQ   D236
			LEAX  -1,U
D233		JSR   C8E3
D236		TST   <$59
			BEQ   D23D
			JSR   C90D
D23D		JMP   CMDBREAK	; "??? mode" command BRK $DDA4
D240		LDX   <SBUFSTRT	; start of song data $5E
D242		LDA   #$8F
			STA   $0420
			JMP   C92D
D24A		TST   <$58
			BEQ   ERROR7	; Error 7 : File I/O error $D206
			TST   <$A7
			BEQ   ERROR7	; Error 7 : File I/O error $D206
			CLR   <$A7

; Disk mode read or append
D254		BSR   D2C1
			BCS   D24A
			LDB   #$03
			BSR   D2BC
			LEAX  -16,X
			LDU   #$0422
			JSR   D308		; copy 8 characters from X to display at U
			TFR   U,X	
			JSR   CLR2END	; green fill to end of line starting from X
			LDX   #$0F64
			STX   <$02
D26E		LDB   <$0D
			BMI   D29B
			JSR   D03B
			LDA   #$09
			LDB   B,Y
			STB   <$0D
			BPL   D283
			TFR   B,A
			ANDA  #$0F
			BEQ   ERROR7	; Error 7 : File I/O error $D206
D283		STA   <$8E
D285		LDD   <$02
			INCA
			CMPD  <$12
			BCC   D219		; Error 1 : Memory overflow
			CLRB
			BSR   D2B8
			JSR   D3AB
			INC   <$A4		; disk sector number
			DEC   <$8E
			BNE   D285
			BRA   D26E
D29B		LDD   <$0E
			BEQ   D2A1
			BSR   D2B8
D2A1		LDX   #$1064
			STX   <SBUFSTRT	; start of song data $5E
			LDX   <$12
			BSR   D2AC
			BRA   D242
D2AC		LDA   ,-U
			ORA   #$40   
			STA   ,-X
			CMPU  <SBUFSTRT	; start of song data $5E
			BHI   D2AC
			RTS
D2B8		LDX   <$7E		; tape/disk data pointer
			LDU   <$02
D2BC		BSR   D2F5
			STU   <$02
			RTS
D2C1		COMB
			ROR   <$5B
D2C4		JSR   D38B
D2C7		JSR   D370		; point to next directory entry
			BCS   D313
			TST   ,X
			BLE   D2C7
			LDU   #$0008
			LEAX  8,X
			LDB   #$05
			JSR   D499
			BNE   D2C7
			LDU   <$8A		; zero
			LEAX  -13,X
			LDB   #$0D
			JSR   D499
			BEQ   D313
			TST   <$5B
			BPL   D2C7
			CMPA  #$2A   
			BNE   D2C7
			STA   <$A7
			LEAX  -1,X
			LEAU  -1,U
D2F5		JMP   D4B1		; copy B bytes from X to U

; "command mode" command K : Kill
CMDKILL		JSR   D0F1		; $D2F8 get filename
D2FB		CLR   <$A7
			BSR   D2C4
			BCC   D314
			TST   <$5B
			BNE   D313
			JMP   ERROR7		; Error 7 : File I/O error $D206

; copy 8 characters from X to display at U
D308		LDB   #$08
D30A		LDA   ,X+
			ORA   #$40   
			STA   ,U+
			DECB
			BNE   D30A
D313		RTS

D314		LDA   ,X
			LDB   A,Y
			CLR   A,Y
			DEC   A,Y
			STB   ,X
			BPL   D314
			CLR   -13,X
D322		BSR   D39C		; write sector to directory track
			LDA   #$20		; $20 = write sector

; r/w disk granule map sector
; A=0 for read. A=$20 for write.
D326		LDX   #$0900
			LDB   #$02		; sector 2 = granule map
			BRA   D3A3		; read/write directory track 17

; "command mode" command D : Dir
CMDDIR		INCB			; $D32D
			STB   <FLGDSK	; disk mode flag $A9
			CLR   <$A2		; drive number
			JSR   GETPARM	; find command parameter $D70D
			BMI   D33A		; no parameter
			JSR   D0F1		; get filename
D33A		BSR   D389		; open disk directory
D33C		LDX   #$0440	; start from 3rd line on screen
			TFR   X,U
			LDA   #$0E
			JSR   CLRALNS	; green fill A lines starting from X
D346		BSR   D370		; point to next directory entry
			BCS   D313
			LDA   ,X		; 1st character of filename
			BLE   D346		; empty entry. find another
			LDA   8,X		; 1st character of extension
			LDB   11,X		; file type
			ANDB  12,X		; ascii flag ($ff = ascii)
			CMPD  #$2001	; looking for no extension & ascii data file
			BNE   D346		; no match. find another.
			BSR   D308		; copy 8 characters from X to display at U
			TFR   U,D
			BITB  #$1F
			BEQ   D364
			LEAU  4,U
D364		CMPU  <$AD		; top of screen
			BLO   D346
D369		JSR   POLLKEY	; scan keyboard $CC5B
			BEQ   D369		; wait until key pressed
			BRA   D33C		; continue listing on new screen

; point to next directory entry
D370		LDX   <$8C		; current directory entry in sector buffer
			LEAX  32,X
			CMPX  #$0900
			BLO   D385
			INC   <$A6		; current sector on directory track
			LDB   <$A6		; current sector on directory track
			CMPB  #$0C
			BCC   D396		; the original had BCC, but this version had BLO .... (?)
			CLRA
			BSR   D39E
D385		CLRA
			STX   <$8C		; current directory entry in sector buffer
			RTS

; open disk directory
D389		CLR   <$A7
D38B		CLRA			; A=0 to read sector
			BSR   D326		; r/w disk granule map sector
			TFR   X,Y
			TST   <$A7
			BNE   D39E
			STX   <$8C		; current directory entry in sector buffer
D396		LDA   #$02
			STA   <$A6		; current sector on directory track
			COMA
			RTS

; write sector to directory track
D39C		LDA   #$20
D39E		LDX   #$0800
			LDB   <$A6		; current sector on directory track

; read/write directory track
D3A3		STA   <$9F		; disk r/w flag 0=r $20=w
			LDA   #$11		; 17 = directory track
			STD   <$A3		; disk track & sector numbers
			STX   <$7E		; tape/disk data pointer
D3AB		PSHS  B,X,Y,U
			LDU   #$FF40	; disk registers
			LDB   #$04		; 4 retries
			STB   <$6B		; retry counter
D3B4		LDD   <$A2		; drive number & track number
			LDX   #$D01D	; disk select table (drives 1-4)
			LDA   A,X		; get register value for drive
			CMPB  #$16
			BLO   D3C1		; track < 22
			ORA   #$10		; enable write precompensation
D3C1		STA   ,U		; $ff40 disk output latch
			TST   <$A0		; disk output latch value ($ff40)
			BNE   D3CB
			BSR   D408		; delay X*8 cycles (approx 480ms)
			BSR   D408		; delay X*8 cycles (approx 590ms)
D3CB		STA   <$A0		; disk output latch value ($ff40)
			BSR   D3F8		; wait for disk op complete
			BNE   D3D5
			CLR   <$A5		; disk error flags
			BSR   D41E		; seek track & r/w disk sector
D3D5		LDA   <$A5		; disk error flags
			BEQ   D3E5		; no error
			DEC   <$6B		; retry counter
			LBEQ  ERROR7	; Error 7 : File I/O error $D206
			BSR   D3E7		; restore current disk drive
			BNE   D3D5
			BRA   D3B4
D3E5		PULS  B,X,Y,U,PC

; restore current disk drive
D3E7		LDX   #$00FC	; current tracks for drives 1-4
			LDB   <$A2		; drive number
			CLR   B,X		; set current track to zero
			LDA   #$03		; disk command: restore
			BSR   D3F6		; disk command with timeout
			ANDA  #$10
			BRA   D41B

; disk command with timeout (approx 1.3s)
D3F6		BSR   D40D		; write command to disk controller

; wait for disk op complete (approx 1.3s)
D3F8		LDX   <$8A		; zero
D3FA		LEAX  -1,X
			BEQ   D413		; cancel disk operation
			LDA   8,U		; $ff48 disk status
			BITA  #$01
			BNE   D3FA		; until command complete
			RTS

; approx 81ms delay
D405		LDX   #$2345

; delay X*8 cycles
D408		LEAX  -1,X
			BNE   D408
			RTS

; write command to disk controller
D40D		STA   8,U		; $ff48 disk command
D40F		PSHS  A,B
D411		PULS  A,B,PC

; cancel disk operation
D413		LDA   #$D0		; disk command: terminate without interrupt
			BSR   D40D		; write command to disk controller
			LDA   8,U		; $ff48 disk status
			ORA   #$80
D41B		STA   <$A5		; disk error flags
D41D		RTS

; seek track & r/w disk sector
D41E		LDX   #$00FC	; current tracks for drives 1-4
			LDB   <$A2		; drive number
			LDA   B,X		; get track for current drive
			STA   9,U		; $ff49 disk track
			CMPA  <$A3		; disk track number
			BEQ   D43D		; already on the right track
			LDA   <$A3		; disk track number
			STA   11,U		; $ff4b disk data
			STA   B,X		; update current track number	 
			LDA   #$17		; disk command: seek track with verify
			BSR   D3F6		; disk command with timeout
			BNE   D41D		; disk command failed
			BSR   D405		; approx 81ms delay
			ANDA  #$18
			BNE   D41B
D43D		LDB   <$A4		; disk sector number
			STB   10,U		; $ff4a disk sector
			LDX   <$7E		; tape/disk data pointer
			LDY   <$8A		; zero
			TST   8,U		; $ff48 disk status
			LDD   #$8080	; sector command, halt enable
			ADDD  <$9F		; disk r/w flag 0=r $20=w, disk output latch value
			CMPA  #$A0
			BSR   D40D		; write command to disk controller
			LDA   #$02
			STA   <$A8		; nmi flag
			BLO   D46B		; read sector

; write sector
D457		BITA  8,U		; $ff48 disk status
			BNE   D463
			LEAY  -1,Y
			BNE   D457
D45F		CLR   <$A8		; nmi flag
			BRA   D413		; cancel disk operation
D463		LDA   ,X+
			STA   11,U		; $ff4b disk data
			STB   ,U		; $ff40 disk output latch
			BRA   D463
; read sector
D46B		BITA  8,U		; $ff48 disk status
			BNE   D475
			LEAY  -1,Y
			BNE   D46B
			BRA   D45F
D475		LDA   11,U		; $ff4b disk data
			STA   ,X+
			STB   ,U		; $ff40 disk output latch
			BRA   D475

; nmi handler
NMIHNDL		TST   >$00A8	; $D47D nmi flag
			BNE   D483
			RTI

D483		LEAS  12,S
			CLR   <$A8		; nmi flag
			LDA   8,U		; $ff48 disk status
			ANDA  #$7C
			BRA   D41B

; "command mode" command @ :
; Pinpoint passage just played
CMDLAST		LEAS  2,S		; $D48D
			CLRA
			BSR   D4DC
			JMP   CBE6

D495		TST   <$6C		; verify flag
			BNE   D4B1		; copy B bytes from X to U
D499		LDA   ,U+
			CMPA  ,X+
			BNE   D4A2
			DECB
			BNE   D499
D4A2		RTS

; INCORRECT!!!!
; "programming mode" command (6F):
; '/' = at the beginning of a line makes it a comment line
; INCORRECT!!!!
;
; This routine actually scans the current score line until
; it finds ANY 'first character' in a line, and returns.
; I.E beginning of next line. ALL lines start with the first
; character + 128 ($80)
; though, this does allow it to 'jump' over comment lines
; by the calling routine.
D4A3		TST   ,U+		; is byte negative?
			BPL   D4A3		; no, read next
			LEAU  -1,U		; set pointer to that negative byte
			RTS				; return

; copy from X to U.
; length at -1,X. If <$AA set then copy from X+length
D4AA		LDB   -1,X		; get length of 5 voices player
			TST   <FLGV5	; voices flag: 0=4V, 1=5V $AA
			BNE   D4B1		; copy B bytes from X to U
			ABX				; to point to the 4 voices player

; copy B bytes from X to U
D4B1		LDA   ,X+
			STA   ,U+
			DECB
			BNE   D4B1
			RTS

; "command mode" command S : Score
; This loop only loops through the entire score until "V5"
; is found. If not found, 4 voice is assumed. If found, it jumps
; from the loop to $D4D5 and marks 5 voice.
CMDSCORE	LDU   <SBUFSTRT	; $D4B9 start of song data $5E
D4BB		BSR   D4A3		; search for 1st 'negative' byte
							; which is the 1st byte in each score line
D4BD		LDA   ,U+		; get byte
			ANDA  #$7F		; reset bit 7
			BEQ   CMD5V		; if zero jump to 4 voices $D4D5
			CMPA  #'/'+$40 	; equals $6F (Comment line)?
			BEQ   D4BB		; yes, back for another negative byte
			CMPA  #'V'   	; equals $56 (Voice)?
			BNE   D4BD		; no, get another byte
			LDA   ,U		; get next byte
			ANDA  #$7F		; reset bit 7
			CMPA  #'5'+$40 	; equals $75 (5 voices)?
			BNE   D4BD		; no, get another byte

; "command mode" command (74): score 4 voices only
; "command mode" command (75): score all 5 voices
; If 'fall through from 'S' above, will set voice count to
; the highest voice found while scanning (4 or 5)
CMD4V		SUBA  #'4'+$40	; $D4D3 subtract $74 '4'
CMD5V		STA   <FLGV5	; $D4D5 voices flag: 0=4V, 1=5V $AA
; At this point, 4 or 5 voice has been decided, now the scoring
; is continued to set up the ram buffers and proper play routine.
			CLRA			; A=0
D4D8		CLR   <$78
			DEC   <$78		; $78 = $FF
D4DC		STD   <$76		; $76-$77 = $0000
			INC   <$56
			LDX   #$D522
			LDU   #$0066
			BSR   D4AA		; copy bytes from X to U. (Length at -1,X)
			LDX   #$CFEB
			LDU   #$0F00
			LDB   #$32   	; to copy 50 bytes
			LDA   <FLGV5	; get voices flag: 0=4V, 1=5V $AA
			CMPA  <$AB		; equals previous voices flag?
			BEQ   D4F9		; yes, so no changes
			ASLB			; no, copy 100 bytes
			STA   <$AB		; save actual voices flag to previous voices flag: 0=4V, 1=5V
D4F9		BSR   D4B1		; copy B bytes from X to U
			JSR   DC88
			EXG   U,X
			LDB   #$39   
			JSR   C9F6		; clear B bytes starting at X
			LDU   #$D52A
			EXG   X,U
			LDB   #$0A
			BSR   D4B1		; copy B bytes from X to U
			LDX   #$0F64
			STX   <$51
			STX   2,U
			LEAX  12,X
			STX   <$7A
			STX   ,U
			LDU   <SBUFSTRT	; start of song data $5E
D51D		BSR   D543
			BRA   D51D

; data copied to $0066
D521 		FCB	$04					; number of bytes to copy
D522		FCB	$55,$2A,$0A,$05		; bytes to copy (4 voices)
			FCB	$7f,$40,$06,$04		; bytes to copy (5 voices)

; 10 bytes copied to ram as part of scoring
D52A		FCB	$00,$00,$00,$0D,$0D,$0D,$0D,$0D,$02,$60 

; translation table
D534 		FCB   $48,$60		; 'H'
	  		FCB   $49,$18		; 'I'
	 		FCB   $51,$30		; 'Q'
	 		FCB   $53,$0C		; 'S'
	 		FCB   $54,$06		; 'T'
	 		FCB   $57,$C0		; 'W'
	 		FCB   $58,$03		; 'X'
	 		FCB   $FF

D543		BSR   D5A5
			TSTA
			LBEQ  CDAE
			LDX   #$D669	; "programming mode" command lookup table
			JSR   GETCMD	; command lookup A in table at X $CBD1
			TST   <$53
			BNE   D543
			LDX   #$D534
			JSR   READTABL	; translate A using table at X $D650
			BCS   D58A
			TFR   A,B
			STB   <$0E
			BSR   D5A5
		   CMPA  #$7A   
			BNE   D576
			ASLB
			BCS   D580
			CLRA
D56A		SUBB  #$03
			INCA
			BCC   D56A
			DECA
			TFR   A,B
			STB   <$0E
D574		BSR   D5A5
D576		CMPA  #$6E   
			BNE   D585
			LSR   <$0E
			ADDB  <$0E
			BCC   D574
D580		LDA   #ERR6		; Error 6 : Note Overflow
			JMP   PRNTERROR	; print Error message $D221
D585		STB   <$0E
			LEAU  -1,U
			RTS
D58A		LDB   <$12
			JSR   D6B4
			STB   <$6C
			BSR   D5F1
			BSR   D5F1
			EORB  #$10
			PSHS  B
			ORB   #$70   
			CMPB  ,S
			PULS  B
			BNE   D5C1
			LDB   <$6C
			BRA   D5C1
D5A5		STU   <$62
			LDA   ,U+
			BPL   D5BB
			LEAU  -1,U
			STU   <$60
			CMPU  <$76
			BNE   D5B7
			JSR   DA11
D5B7		LDA   ,U+
			ANDA  #$7F
D5BB		RTS
		   
D5BC		LEAS  2,S
			FCB   $8C		; CMPX  #		; NOP

; "programming mode" command (64) '$' :
; could represent a REST (?)
D5BF		LDB		#$70
D5C1		LDA		#$FF
			STA   <$6C
			LDX   <$8A		; zero
			LDA   <$10
			LEAY  A,X
			LDX   ,Y
			STB   <$6B
			LDA   -1,X
			CMPA  <$6B
			BEQ   D5E3
			ANDA  #$8F
			CMPA  <$6B
			BNE   D5FB
			LDA   #$60   
			ANDA  -1,X
			CMPA  #$60   
			BEQ   D5FB
D5E3		LDA   -2,X
			ADDA  <$0E
			BCS   D5FB
			CMPA  #$FF
			BEQ   D5FB
			STA   -2,X
			BRA   D605
D5F1		LDX   #$D659
			BSR   D646
			BCS   D5BC
			ORB   -1,X
D5FA		RTS
D5FB		LDA   <$0E
			STA   ,X+
			LDA   ,X
			STA   <$6C
			STB   ,X+
D605		PSHS  X
			LDX   #$D660
			BSR   D646
			PULS  X
			BCS   D63B
			LSRA
			BCC   D61B
			TFR   A,B
			LDA   <$0E
D617		LSRA
			DECB
			BNE   D617
D61B		TFR   A,B
			NEGA
			BEQ   D63B
			ADDA  -2,X
			STA   -2,X
			LDA   <$12
			ASLA
			BEQ   D62F
			LDA   -2,X
			STB   -2,X
			TFR   A,B
D62F		STB   ,X+
			LDA   ,X
			LDB   #$70   
			STB   ,X+
			ANDA  <$6C
			STA   <$6C
D63B		STX   ,Y
			INC   <$6C
			BEQ   D5FA
			LDA   #ERR5   	; Error 5 : Measure overflow
			JMP   PRNTERROR	; Error message $D221
D646		JSR   D5A5
			BSR   READTABL		; translate A using table at X $D650
			BCC   D658
			LEAU  -1,U
			RTS
; Reads table by match A with 1st table byte.
; If match is found, next byte is load into A and returned
READTABL	CMPA  ,X++		; $D650 Compare A with table
			BCS   RDTBOUT	; exit if carry set $D658
			BNE   READTABL	; no match, loop $D650
			LDA   -1,X		; match found, get previous byte
RDTBOUT		RTS				; $D658 return

; translation table
D659 		FCB   $63,$20
	 		FCB   $65,$10
	 		FCB   $66,$40
	 		FCB   $FF

; translation table
D660 		FCB   $62,$04
	 		FCB   $67,$02
	 		FCB   $6C,$03
	 		FCB   $7B,$05
	 		FCB   $FF

; "programming mode" command lookup table
D669 		FCB   $40,$D6,$DB	; @
	 		FCB   $4A,$D7,$D4	; J
	 		FCB   $4B,$D7,$2B	; K
	 		FCB   $4D,$D6,$F4	; M
	 		FCB   $4E,$D7,$87	; N
	 		FCB   $4F,$D7,$9D	; O
	 		FCB   $50,$D8,$3D	; P
	 		FCB   $52,$D8,$2D	; R
	 		FCB   $55,$D6,$E2	; U
	 		FCB   $56,$D7,$C7	; V
	 		FCB   $59,$D7,$59	; Y
	 		FCB   $5A,$D7,$B3	; Z
	 		FCB   $5F,$D6,$D8	; shift 0
	 		FCB   $60,$D7,$86	; space
	 		FCB   $64,$D5,$BF	; $
	 		FCB   $68,$D7,$71	; (
	 		FCB   $69,$D7,$78	; )
	 		FCB   $6A,$D6,$DE	; *
	 		FCB   $6F,$D4,$A3	; /
	 		FCB   $7C,$D7,$AE	; <
	 		FCB   $7D,$D7,$BF	; =
	 		FCB   $7E,$D7,$98	; >
	 		FCB   $FF

; translation table
D6AC 		FCB   $6B,$00	; + (treble clef)
	 		FCB   $6D,$80	; - (bass clef)
	 		FCB   $FF


D6B1		JSR   D5A5
D6B4		PSHS  B
			LDX   #$D6AC
			BSR   READTABL	; translate A using table at X $D650
			BCS   D6C2
			STA   ,S
			JSR   D5A5
D6C2		CMPA  #$47   
			BNE   D6CA
			TST   ,S
			BPL   D6D6
D6CA		JSR   D7FB
			TSTA
			BNE   D6D2
			ORA   #$80
D6D2		ORA   ,S
			STA   ,S
D6D6		PULS  B,PC

; "programming mode" command shift 0
; = next notes are in percussion clef
D6D8		LDA   #$E0
			FCB   $8C		; CMPX  #	; NOP

; "programming mode" command @:
; next notes bass clef
D6DB 		FDB 	$8680	; LDA #$80
			FCB	$21			; BRN		   ; NOP

; "programming mode" command (6A):
; '*' = notes play in treble clef
D6DE 		FCB 	$4F		; CLRA
			STA   <$12
			RTS

; "programming mode" command 'U':
; transpose a signed hex number (up or down)
D6E2		LDB   #$80
			BSR   D6B1
			LDX   #$000D
			LDA   <$10
			TSTB
			BPL   D6F1
			EORB  #$7F
			INCB
D6F1		STB   A,X
			RTS

; "programming mode" command 'M':
; define beginning of a measure 
D6F4		PSHS  U
			JSR   $DB25
			TST   <$17
			BNE   D708
			LDX   #$0019
			LDU   #$0020
			LDB   #$23   
			JSR   D4B1		; copy B bytes from X to U
D708		PULS  U
			CLR   <$17
			FCB	$8C			; CMPX  #		; NOP

;find command parameter
; Get's one (A) parameter from Y and returns
; U pointing to the next, or end of line  
GETPARM 	LEAU 1,Y		; $D70D
D70F		LDA   ,U+		; find end of command
			BMI   D71D		;
			CMPA  #$60   	;
			BNE   D70F		;
D717		LDA   ,U+		; skip over spaces
			CMPA  #$60		; until start of parameter
			BEQ   D717		; or end of line
D71D		TST   ,-U
			RTS

; translation table
D720 		FCB   $48,$01
	 		FCB   $49,$04
	 		FCB   $51,$02
	 		FCB   $53,$08
	 		FCB   $54,$10
	 		FCB   $FF

; "programming mode" command 'K':
; define key signature
D72B		LDX   #$0019
			LDB   #$07
			JSR   C9F6		; clear B bytes starting at X
			JSR   D5A5
			SUBA  #$70   
			CMPA  #$08
			BCC   D793
			TFR   A,B
			JSR   D5A5
			CMPA  #$66   
			BEQ   D752
			LEAX  -7,X
			CMPA  #$63   
			BNE   D793
D74B		DECB
			BMI   D765
			INC   ,X+
			BRA   D74B
D752		DECB
			BMI   D765
			DEC   ,-X
			BRA   D752

; "programming mode" command 'Y':
; set part voice to register
D759		BSR   D766
			ADDA  #$0A
			LDB   <$10
			LSRB
			LDX   #$0046
			STA   B,X
D765		RTS
D766		JSR   D5A5
			SUBA  #$41   
			CMPA  #$05
			BCS   D786
			BRA   D793

; "programming mode" command (68):
; '(' = repetition definition beginning
D771		STU   <$0A
			LDA   #$FF
			STA   <$0C
			RTS

; "programming mode" command (69):
; ')' = repetition definition end
D778		BSR   D7F9
			TST   <$0C
			BEQ   D786
			BPL   D782
			STA   <$0C
D782		DEC   <$0C
			LDU   <$0A

; "programming mode" command (60) ' ':
; end of programming sequence
D786		RTS

; "programming mode" command 'N':
; define time signature
D787		LDX   #$D720
			JSR   D646
			STA   <$4B
			BCC   D7AD
			LEAU  1,U
D793		LDA   #$73   	; Error 3 : Parameter error
			JMP   PRNTERROR	; Error message $D221

; "programming mode" command '>' (7E):
; indicates notes to be transposed up
D798		BSR   D7F9
			STA   <$14
			RTS

; "programming mode" command 'O':
; set options
D79D		BSR   D7F9
			TFR   A,B
			BEQ   D7AB
			ORA   <$16
			ANDA  #$01
			ORB   <$17
			ANDB  #$02
D7AB		STD   <$16
D7AD		RTS

; "programming mode" command '<' (7C):
; indicates notes to be transposed down
D7AE		BSR   D798
			NEG   <$14
			RTS

; "programming mode" command 'Z':
; map stereo channels
D7B3		BSR   D7F9
			CMPA  <$68
			BCC   D793
			LDB   #$05
			MUL
			STB   <$18
			RTS

; "programming mode" command '=' (7D):
; set tempo 
D7BF		BSR   D80C
			LSRA
			BEQ   D793
			STA   <$4C
			RTS

; "programming mode" command 'V':
; add notes to a voice in a measure
D7C7		JSR   D5A5
			SUBA  #$71   
			CMPA  #$05
D7CE		BCC   D793
			ASLA
			STA   <$10
			RTS

; "programming mode" command 'J':
; define named register
D7D4		BSR   D766
			LDB   #$0A
			MUL
			LDX   #$0F00
			ABX
			JSR   D5A5
			SUBA  #$52   
			CMPA  #$02
			BCC   D7CE
			STA   ,X+
			LDB   #$09
D7EA		BSR   D7F9
			ASLA
			ASLA
			ASLA
			ASLA
			STA   ,X+
			DECB
			BNE   D7EA
			RTS
D7F6		ANDCC #$FB
			RTS
D7F9		LDA   ,U+
D7FB		ANDA  #$3F   
			SUBA  #$30   
			CMPA  #$0A
			BCS   D80B
			ADDA  #$2F   
			CMPA  #$06
			BCC   D856
			ADDA  #$0A
D80B		RTS

D80C		JSR   D5A5
D80F		LEAU  -1,U
D811		BSR   D7F9
			ASLA
			ASLA
			ASLA
			ASLA
			PSHS  A
			BSR   D7F9
			ORA   ,S+
			RTS

D81E		LDX   #$0F64
			FCB	$8C			; CMPX   - to skip the next one  
D822		LDX	  ,X
			BEQ   D7F6
			STX   <$7C		; cassette block type/length
			CMPA  2,X
			BNE   D822
			RTS

; "programming mode" command 'R':
; repeat named part
D82D		JSR   DAE4
			BSR   D80C
			BEQ   D853
			BSR   D81E
			BNE   D853
			LDX   10,X
			STX   <$4D
D83C		RTS

; "programming mode" command 'P':
; define beginning of named part
D83D		JSR   DAE4
			JSR   D5A5
			CLR   <$45
			CMPA  #$60   
			BEQ   D83C
			BSR   D80F
			STA   <$45
			BEQ   D83C
			BSR   D81E
			BNE   D83C
D853		LDA   #ERR4
			FCB	  $8C		; CMPX  
D856		LDA   #ERR2
			JMP   PRNTERROR	; Error message $D221
; "command mode" command P : Play
; Can be alone or followed by <num> for
; the part number to start at
CMDPLAY		CLR   <$56		; $D85B
			TST   <$5D
			BNE   D853
			JSR   GETPARM	; find command parameter $D70D
			BMI   JMPPLAY	; if no more parms, play $D869
			BSR   D811
			FCB	$21			; BRN   
JMPPLAY		CLRA			; $D869 cmds jump here to play without parms
			BSR   D81E
			BNE   D853
			LDX   #$DA7A	; frequency table
			LDU   #$089A	; frequency table copied to RAM
			TST   <FLGFAST	; fast mpu rate flag $5C
			BEQ   D87B
			LEAU  24,U
D87B		TFR   U,Y
			JSR   D4AA		; copy bytes from X to U. (Length at -1,X)
D880		LDD   22,Y
			LSRA
			RORB
			STD   ,--Y
			CMPY  #$0822
			BNE   D880
			CLR   ,-Y
			CLR   ,-Y
			LDD   -2,X
			TST   <FLGFAST	; fast mpu rate flag $5C
			BEQ   D899
			ASRA
			RORB
D899		STD   ,--Y
			ASRA
			RORB
			ADDD  ,Y
			CMPY  #$0800
			BNE   D899
			LDD   #$7FEC
			STD   ,Y
			LDU   #PLAYRAM	; player core in RAM $08B4
			LDX   #PLAY5	; player core $D8E9
			JSR   D4AA		; copy bytes from X to U. (Length at -1,X)
			TFR   U,X		; point X to next address after player
			LDU   #$DAAE
D8B8		LDA   <FLGV5		; $AA
			ASLA
			LDA   A,U
			PSHS  B
			MUL
			PULS  B
			TST   <FLGFAST	; fast mpu rate flag $5C
			BEQ   D8C7
			ASLA
D8C7		STA   B,X
			BNE   D8CD		; ensure non-zero
			INC   B,X		;
D8CD		INCB
			BPL   D8B8		; for B = 0 to 127
			LDY   #$007C
			LDD   #$08FB
			STB   $FF02		; select key col containing BJRZ2:<BRK>
			TST   <FLGFAST	; fast mpu rate flag $5C
			TFR   A,DP		; DP now starts at $0800
			BEQ   D8E6
			INC   $FFD7		; fast MPU rate
			INC   $FFD9		; fast MPU rate
D8E6		JMP   <$B4		; player core in RAM

; 5 voice player core routine copied to $08b4
; number of bytes to copy
PLYLEN5		FCB   $9C		; $D8E8
; code to copy
PLAY5		BRA   D94C		; $D8E9
D8EB		LDA   #$00
D8ED		LDA   A,X
			STA   <$B2
D8F1		LDD   <$20
			ADDD  #$0000
			STD   <$BF
			STA   <$EB
			LDD   <$20
			ADDD  #$0000
			STD   <$C8
			STA   <$EE
			LDD   <$20
			ADDD  #$0000
			STD   <$D1
			STA   <$F1
			LDD   <$20
			ADDD  #$0000
			STD   <$DA
			STA   <$F4
			LDD   <$20
			ADDD  #$0000
			STD   <$E3
			STA   <$F7
			LDA   $0A00		; get data for voice 1
			ADDA  $0A00		; add data for voice 2
			LDB   $0A00		; get data for voice 3
			ADDB  $0A00		; add data for voice 4
			ADDB  $0A00		; add data for voice 5
			STD   $FF7A		; send to L+R DAC registers
			DEC   <$B2
			BNE   D8F1
			DEC   <$B3
			BNE   D940
			DEC   <$B4
			BEQ   D96A
D93C		LDA   <$B5
			STA   <$B3
D940		LDA   $FF00		; read keyboard
			COMA
			ASLA			; lose comparator bit
			BEQ   D8EB		; none of BJRZ2:<BRK> pressed
			BPL   D8ED		; one of BJRZ2: pressed
			JMP   DD87		; break key handler
D94C		LDY   ,Y

			BNE   D954
			JMP   CEB3
D954		LDD   3,Y
			STA   <$EA
			STB   <$ED
			LDD   5,Y
			STA   <$F0
			STB   <$F3
			LDA   7,Y
			STA   <$F6
			LDA   9,Y
			STA   <$B7
			LDU   10,Y
D96A		PULU  A,B
			STA   <$B5
			INCA
			BEQ   D94C
			STB   <$BD
			PULU  A,B
			STA   <$C6
			STB   <$CF
			PULU  A,B
			STA   <$D8
			STB   <$E1
			LDA   8,Y
			STA   <$B4
			BRA   D93C
; end of $9c bytes copied to $08b4

; 4 voice player core routine copied to $08b4
PLAY4		BRA   D9F5		; $D985
D987		LDA   #$00
			STA   <$B3
D98B		LDA   $FF00		; read keyboard
			COMA
			ASLA			; lose comparator bit
			BEQ   D997		; none of BJRZ2:<BRK> pressed
			BPL   D999		; one of BJRZ2: pressed
			JMP   DD87		; break key handler
D997		LDA   #$00
D999		LDA   A,X
			STA   <$B2
D99D		LDD   <$20
			ADDD  #$0000
			STD   <$CF
			STA   <$F2
			LDD   <$20
			ADDD  #$0000
			STD   <$D8
			STA   <$F5
			LDD   <$20
			ADDD  #$0000
			STD   <$E1
			STA   <$F8
			LDD   <$20
			ADDD  #$0000
			STD   <$EA
			STA   <$FB
			LDA   $0A00
			ADDA  $0A00
			LDB   $0A00
			ADDB  $0A00
			STD   $FF7A		; L+R DAC registers
			DEC   <$B2
			BNE   D99D
			DEC   <$B3
			BNE   D98B
			DEC   <$B4
			BNE   D987
D9DC		LDA   8,Y
			STA   <$B4
			PULU  A,B
			STA   <$B7
			INCA
			BEQ   D9F5
			STB   <$CD
			PULU  A,B
			STA   <$D6
			STB   <$DF
			PULU  A
			STA   <$E8
			BRA   D987
D9F5		LDY   ,Y
			BNE   D9FD
			JMP   CEB3
D9FD		LDD   3,Y
			STA   <$F1
			STB   <$F4
			LDD   5,Y
			STA   <$F7
			STB   <$FA
			LDA   9,Y
			STA   <$C7
			LDU   10,Y
			BRA   D9DC
; play4 ends here
; extra bytes are copied to ram to match 9C count,
; but not called or used from ram play routine

DA11		PSHS  A,B,X,Y,U
			JSR   DB25
			PULS  A,B,X,Y,U
			CLR   <$53
			TST   <FLGPLAY	; IS file to be played? $5A
			BEQ   DA3D
			RTS

; "command mode" command (61) '!':
; plays from the current cursor position forward   
CMDPLYC		INC   <FLGPLAY	; $DA1F Set 'playing' flag $5A
			CLR   <FLGFAST	; clear fast mpu rate flag $5C

; "command mode" command (7F) '?':
; displays voicing at cursor
CMDVOCD		INC   <$53		; $DA23
			LEAS  4,S
			LDD   <$60
			PSHS  A,B
			JSR   D4D8
			LDX   ,S
			JSR   C934
			TST   <FLGPLAY	; Is file to be played? $5A
			BEQ   DA3A		; No, the skip playing
			JSR   JMPPLAY	; yes, then go play it $D869
DA3A		JMP   CMDBREAK	; "??? mode" command BRK $DDA4
DA3D		LDU   #$000D
			LDY   #$0046
			LDX   #$0420
			LDB   <$69
			PSHS  B
			LDD   #$4374
			ADDD  <$A9		; disk mode flag & ???
			STD   ,X++
DA52		LDD   #$6059
			STD   ,X++
			LDD   #$3755
			ADDA  ,Y+
			STD   ,X++
			LDB   #$6B   
			LDA   ,U++
			BPL   DA67
			LDB   #$6D   
			NEGA
DA67		STB   ,X+
			ADDA  #$90
			DAA
			ADCA  #$40   
			DAA
			ORA   #$40   
			STA   ,X+
			DEC   ,S
			BNE   DA52
			BRA   DA3A

; frequency lookup data copied to $089a or $08b2
; length of data
DA79		FCB   $1A
; data to be copied
DA7A 		FDB   $26EA
	 		FDB   $293B
	 		FDB   $2BAF
	 		FDB   $2E48
	 		FDB   $3108
	 		FDB   $33F3
	 		FDB   $370A
	 		FDB   $3A50
	 		FDB   $3DC8
	 		FDB   $4174
	 		FDB   $4558
	 		FDB   $4978
	 		FDB   $004E

; alternate frequency table
DA94 		FDB   $2008
	 		FDB   $21EF
	 		FDB   $23F4
	 		FDB   $2618
	 		FDB   $285C
	 		FDB   $2AC2
	 		FDB   $2D4D
	 		FDB   $2FFF
	 		FDB   $32D9
	 		FDB   $35DF
	 		FDB   $3914
	 		FDB   $3C78
	 		FDB   $0040
					
DAAE 		FDB   $A54A
	 		FDB   $8542

; Stereo mapping table
DAB2 		FCB   $00,$01,$02,$03,$04
	 		FCB   $00,$02,$01,$03,$04
	 		FCB   $02,$00,$01,$03,$04
	 		FCB   $00,$02,$03,$01,$04	
	 		FCB   $02,$00,$03,$01,$04
	 		FCB   $02,$03,$00,$01,$04
	 		FCB   $00,$02,$03,$04,$01
	 		FCB   $02,$00,$03,$04,$01
	 		FCB   $02,$03,$00,$04,$01
	 		FCB   $02,$03,$04,$00,$01


DAE4		PSHS  U
			BSR   DB25
			LDU   <$4F
			STU  [$0051]
			STU   <$51
			LDX   #$0043
			LDB   #$03
			JSR   D4B1		; copy B bytes from X to U
			LDA   <$18
			LDY   #$DAB2	; Stereo mapping table
			LEAY  A,Y
			LDA   #$05
			STA   <$AC
DB04		LDA   ,X+
			LDB   ,Y+
			STA   B,U
			DEC   <$AC
			BNE   DB04	 
			LEAU  5,U
			LDB   #$04
			JSR   D4B1		; copy B bytes from X to U
			LDX   <$7A
			LDD   #$FF0C
			STA   ,X+
			STX   <$4F
			ABX
			STX   <$4D
			STX   <$7A
			PULS  U,PC
		   
DB25		LDX   <$8A		; zero
			LDU   #$0802
			LDB   #$05
DB2C		STU   ,X++
			LEAU  66,U
			DECB
			BNE   DB2C
			TST   <$53
			LBNE  DC88
			LDY   <$7A
DB3D		CMPY  <$78
			LBHI  CEB3
			LEAX  31,Y
			CMPX  <SBUFSTRT	; start of song data $5E
			BLS   DB72
			TST   <$59
			BNE   DB72
			LDX   #MSGOLAP	; $CD40 "OVERLAP?"
			LDU   #$042E
			JSR   D308		; copy 8 characters from X to display at U
			LEAU  1,U
			STU   <$88		; cursor position
			LDA   #$59   
			TST   <$57
			BNE   DB65
			JSR   CC09
DB65		STA   $0437
			LDX   <$60
			CMPA  #$59   
			LBNE  D233
			INC   <$59
DB72		LEAX  $00A0,Y
			CMPX  <$60
			LBCC  D219		; Error 1 : Memory overflow
			LDD   #$FF05
			PSHS  A,B
			LDX   <$8A		; zero
DB83		LDA  [,X++]
			CMPA  ,S
			BCC   DB8B
			STA   ,S
DB8B		DECB
			BNE   DB83
			PULS  A,B
			CMPA  #$FF
			LBEQ  DC85
			STA   ,Y+
DB98		PSHS  A,B
			LDB   #$05
			SUBB  1,S
			ASLB
			STB   <$10
			LDX   <$8A		; zero
			ABX
			LDU   ,X
			LDD   ,U
			CMPA  #$FF
			BEQ   DBB8
			SUBA  ,S
			STA   ,U
			BNE   DBB6
			LEAU  2,U
			STU   ,X
DBB6		CMPB  #$70   
DBB8		BEQ   DC31
			PSHS  B
			ANDB  #$70   
			CMPB  #$60   
			PULS  B
			BEQ   DC2B
			STB   <$6B
			ANDB  #$8F
			BNE   DBCC
			ORB   #$10
DBCC		BPL   DBD1
			EORB  #$7F
			INCB
DBD1		ADDB  #$0E
			LDX   #$000D
			LDA   <$10
			ADDB  A,X
			FCB	$8C			; CMPX
DBDB		SUBB #$0E
DBDD		ADDB  #$07
			BMI   DBDD
			CMPB  #$2A   
			BCC   DBDB
			LDX   #$DC5B
			ABX
			PSHS  X
DBEB		SUBB  #$07
			BPL   DBEB
			LDX   #$DC5B
			LDB   B,X
			PSHS  B
			LDB   <$16
			BEQ   DC00
			LDA   <$10
			ASRA
			LDB   #$07
			MUL
DC00		ADDB  ,S+
			LDX   #$0020
			ABX
			LDA   #$70   
			ANDA  <$6B
			BEQ   DC16
			JSR   CE7C		; signed divide D by 16
			LDU   #$DC4E
			LDB   A,U
			STB   ,X
DC16		LDA   <$14
			ADDA  ,X
			PULS  X
			ADDA  ,X
			FCB	$8C			; CMPX  
DC1F		SUBA #$18
DC21		ADDA  #$0C
			BLE   DC21
			CMPA  #$48   
			BCC   DC1F
			BRA   DC32
DC2B		TFR   B,A
			ANDA  #$0F
			COMA
			FCB	$21			; BRN  - to skip the next one   
DC31		CLRA
DC32		ASLA
			ADDA  #$20
			LDB   <$10
			ASRB
			ADDB  <$18
			LDX   #$DAB2	; Stereo mapping table
			LDB   B,X
			STA   B,Y
			PULS  A,B
			DECB
			LBNE  DB98
			LDA   <$69
			LEAY  A,Y
			JMP   DB3D
; data
DC4F		FCB	$00,$01,$02,$FF,$FE,$01,$03,$05
			FCB	$00,$02,$04,$06
DC5B		FCB $F5,$F7,$F9,$FA,$FC,$FE
			FCB $00,$01,$03,$05,$06,$08
			FCB	$0A,$0C,$0D,$0F,$11,$12
			FCB	$14,$16,$18,$19,$1B,$1D
			FCB	$1E,$20,$22,$24,$25,$27
			FCB	$29,$2A,$2C,$2E,$30,$31
			FCB $33,$35,$36,$38,$3A,$3C

DC85		STY   <$7A
DC88		LDA   #$06
DC8A		STA   <$AC
			CLR   <$10
			LDX   #$0800
			LDU   <$8A		; zero
DC93		LDD   #$FF60
			STD   ,X++
			DEC   <$AC
DC9A		BEQ	DCAB		; BEQ
DC9B		EQU   *-1		; CLR <$AF		; (direct)
			STX   ,U++
			LDB   #$40   
DCA0		STA   ,X+
			DECB
			BNE   DCA0
DCA5		BRA   DC93
DCA7		LDA   ,X+
			STA   ,U+
DCAB		RTS

; "command mode" command O : Optimise
CMDOPTMZ	LDX   <SBUFSTRT	; $DCAC start of song data $5E
			TFR   X,U
			FCB	$8C			; CMPX  
DCB1		BSR DCA7
DCB3		BSR   DCA7
			BPL   DCCE
			ANDA  #$7F
			LBEQ  DD77
			CMPA  #$60   
			BNE   DCCE
			LEAU  -1,U
			TST   -1,X
			BPL   DCB3
			ROL   ,X
			COMA
			ROR   ,X
			BRA   DCB3
DCCE		CMPA  #$6F   
			BEQ   DCE2
			CMPA  #$4D   
			BEQ   DCEA
			CMPA  #$50   
			BEQ   DCB1
			CMPA  #$60   
			BNE   DCB3
			LEAU  -1,U
			BRA   DCB3
DCE2		LDA   ,X
			BMI   DCB3
			BSR   DCA7
			BRA   DCE2
DCEA		LDA   ,X
			BMI   DCB3
			BSR   DCA7
			CMPA  #$60   
			BEQ   DCB3
			LEAU  -1,U
			BRA   DCEA
DCF8		BSR   DD08		; display character in B at X
DCFA		LDB   ,-U
			BPL   DCF8
DCFE		TST   <$14
			BEQ   DD4B
			BSR   DD4D
			BEQ   DCFE
			STB   <$18
DD08		JMP   DF7C		; display character in B at X
		   
DD0B		TST   <$14
			BNE   DD40		; screen colour set 0
			INC   <$14
			LDU   #MSGOLAP	; $CD40 "OVERLAP?"
			BSR   DCFA
			LDB   <$14
			BEQ   DD40		; screen colour set 0
			LDX   <SBUFSTRT	; start of song data $5E
			STX   <$04
			BRA   DD3D		; screen colour set 1
DD20		TST   <$14
			BMI   DD40		; screen colour set 0
			RTS
DD25		TST   <$14
			BNE   DD40		; screen colour set 0
			DEC   <$14
			BRA   DD31
DD2D		TST   <$14
			BNE   DD4B
DD31		JSR   C90D
			LDX   #$1064
			STX   <$02
			STX   <$12
			STB   ,X

; screen colour set 1
DD3D		LDA   #$08
			FCB	$8C			; CMPX  #$DC8A

; screen colour set 0
DD40		LDD   <$8A		;zero
			STA   $FF22
			STB   <$14
DD47		LDB   #$0D
			BSR   DD08		; display character in B at X
DD4B		CLRB
			RTS

DD4D		JSR   POLLKEY	; scan keyboard $CC5B
			BEQ   DD4B
			TSTB
			BMI   DD5C
			CMPB  #$60   
			BCS   DD5B
			SUBB  #$40   
DD5B		RTS
DD5C		ASLB
			BEQ   DD25
			BPL   DD0B
DD61		ORCC  #$FF
			BSR   DD47
			STX   <$6D
			LDX   <SBUFSTRT	; start of song data $5E
			LDU   #$1064
			CMPU  <$02
			BCC   DD7E
			STU   <SBUFSTRT	; start of song data $5E
			LDU   <$02
			LEAU  1,U
DD77		LDX   <SBUFEND	; end of song data $74
			LEAX  1,X
			JSR   D2AC
DD7E		JSR   C92D
			TST   <$70		; transfer mode flag
			BEQ   CMDBREAK	; "??? mode" command BRK $DDA4
			CLR   <$70		; transfer mode flag

; break key handler (during playback)

DD87		STU   >$0078

; soft reset handler

DD8A		NOP
			LDS   #$00FA
			JSR   INITHW	; $CEB7 initialise hardware
			JSR   CLRLN2	; green fill 2nd line
			LDX   <SBUFSTRT	; start of song data $5E
			TST   <$70		; transfer mode flag
			BNE   DD61
			LDX   #$DD8A	; soft reset handler
			STX   <$72		; soft reset vector
			LDB   #$55   
			STB   <$71		; cold boot flag

; "command mode" command BRK: while playing  = Stops the music
CMDBREAK	CLR   <$58		; $DDA4
			JMP   REINIT	; $CBE9 Reinit the system

DDA9		BRA   $DD40		; screen colour set 0

; "command mode" command X : Transfer mode
CMDTRFER	LDX   <$8A		; $DDAB zero
			LDB   #$19
			JSR   C9F6		; clear B bytes starting at X
			DEC   <$16
			LDD   #$0802
			STA   <$06
			STA   <$0A
			INCA
			STA   <$08
			STA   <$0C
			LDY   #$FF20
			STB   ,Y
			LDX   <$6D
			STX   <$88		; cursor position
			INC   <$70		; transfer mode flag
			INC   $FFC7
			ANDCC #$EF
DDD1		TST   <$14
			BLE   DDD7
			BSR   DDDD
DDD7		BSR   DE39
			BSR   DE26
			BRA   DDD1
DDDD		TST   <$01
			BNE   DE25
			LDX   <$04
			CMPX  <SBUFEND	; end of song data $74
			BHI   DDA9		; screen colour set 0
			LDB   ,X+
			STX   <$04
			ANDB  #$7F
			BEQ   DDA9		; screen colour set 0
			CMPB  #$6F   
			BNE   DDFD
			TST   -1,X
			BPL   DDFD
			LDB   #$60   
			BSR   DE2B
			LDB   #$6F   
DDFD		BSR   DE2B
			TST  [$0004]
			BPL   DE25
			LDB   #$0D
			BSR   DE2B
			FCB	$8C			; CMPX  
DE0A		BSR DE39
DE0C		BSR   DE26
			LDB   <$18
			BEQ   DE1C
			TST   <$00
			BEQ   DE0C
			CMPB [$0006]
			BNE   DE0A
DE1C		BSR   DE39
			BSR   DE26
			SYNC
			TST   <$00
			BNE   DE1C
DE25		RTS
		   
DE26		JSR   DD4D
			BEQ   DE25
DE2B		CMPB  #$60   
			BCS   DE31
			SUBB  #$40   
DE31		INC   <$09
			STB  [$0008]
			INC   <$01
DE39		LDB   <$00
			BEQ   DE25
			LDB  [$0006]
			INC   <$07
			DEC   <$00
			CMPB  #$12
			LBEQ  DD2D
			CMPB  #$14
			LBEQ  DD20
			JSR   DF7C		; display character in B at X
			TST   <$14
			BEQ   DE25
			BPL   DE75
			LDX   <$02
			CMPX  <SBUFEND	; end of song data $74
			LBCC  DD40		; screen colour set 0
			CMPB  #$0D
			BNE   DE8E
			CLR   <$15
			LDD   #$80E0
			CMPA  ,X
			BNE   DE71
			STB   ,X+
DE71		STX   <$12
			BRA   DEA9
DE75		CMPB  #$13
			BNE   DE8D
DE79		JSR   DD4D
			TST   <$14
			BLE   DE8D
			LDD   <$06
			ADDB  <$00
			DECB
			TFR   D,X
			LDB   ,X
		   CMPB  #$11
			BNE   DE79
DE8D		RTS
		   
DE8E		CMPB  #$40   
			BCS   DE8D
			CMPB  #$6F   
			BNE   DEA4
			DEC   <$15
			LDA   -1,X
			CMPA  #$E0
			BNE   DEA4
			LEAX  -1,X
DEA0		LDA   #$80
			STA   ,X
DEA4		ORB   ,X
			STB   ,X+
			CLRA
DEA9		STA   ,X
			STX   <$02
			TFR   X,D
			SUBD  <$12
			CMPB  #$20
			BNE   DE8D
			LDB   ,-X
			STX   <$12
		   TST   <$15
			BEQ   DEA0
			LDA   #$EF
			STA   ,X+
			CLR   ,X
			BRA   DEA4

; irq handler

IRQHNDL		LDB   2,Y		; $DEC5
			LSRB
			LDD   <$0E
			BMI   DED5
			BNE   DED9
			BCS   DEF3
			LDD   #$0827
			BRA   DEF1
DED5		BCC   DEF3
			BRA   DEF0
DED9		DECB
			BNE   DEF1
			ROR  [$000A]
			LDB   #$1A
			DECA
			BNE   DEF1
			LDX   <$0A
			ASL   ,X
			CLRB
			ROR   ,X
			INC   <$0B
			INC   <$00
DEF0		COMA
DEF1		STD   <$0E
DEF3		LDD   <$10
			BEQ   DF0B
			DECB
			BNE   DF19
			COMB
			ROR  [$000C]
			ROLB
			ROLB
			ANDB  #$02
			STB   ,Y
			CLRB
			DECA
			BEQ   DF19
			BRA   DF17
DF0B		TST   <$01
			BEQ   DF1B
			INC   <$0D
			DEC   <$01
			LDA   #$0B
			CLR   ,Y
DF17		LDB   #$1A
DF19		STD   <$10
DF1B		LDA   $FF00
			STA   <$6A
			RTI

; Initialise
; Requires address of startup message on stack

INIT		JSR   INITHW	; $DF21 initialise hardware $CEB7
			STD   <$AA		; (A = 0, B = $ff7f or 3)
			CLRB			; D = 0000 now
			STD   <$70		; transfer mode flag & ??
			STD   <$A8		; nmi flag & disk mode flag
			STD   <$8A		; zero
			LDA   #$7E		; jmp opcode
			LDX   #IRQHNDL	; irq handler $DEC5
			LDU   #$010F
			PSHU  A,X		; setup irq vector
			LDX   #NMIHNDL	; nmi handler $D47D
			PSHU  A,X		; setup nmi vector
			BSR   CLRSCRN	; clear screen $DF71
			INC   <$88		; cursor position
			JSR   DD3D		; screen colour set 1
			PULS  U			; start up message
			FCB	$8C			; CMPX  #; NOP
DF46 		BSR   $DF7C		; display character in B at X)
			LDB   ,U+
			BPL   DF46
			LDX   <$AD		; top of screen
DF4E		LDA   ,X+
			ORA   #$40   
			STA   -513,X
			CMPX  #$0800
			BNE   DF4E
			JSR   CC09
			SUBA  #$1D
			STA   <$B9
			BSR   CLRSCRN	; clear screen $DF71
			LDX   #DEMOSNG	; demo song
			LDU   #CMDLIST	; $C862
			STX   <SBUFSTRT	; start of song data $5E
			INC   <$70		; transfer mode flag
			JMP   DD77

; clear screen
CLRSCRN		LDX   #$0600	; $DF71
			STX   <$88		; cursor position
			STX   <$6D
			STX   <$AD		; top of screen
			BRA   DFF4		; clear from X to end of screen

; display character in B at X

DF7C		BSR   DF99		; invert cursor
			CMPB  #$20
			BLO   DFC7		; handle control character
			CMPB  #$60   
			BLO   DF88
			SUBB  #$20
DF88		ANDB  #$BF
			STB   ,X+
			ORB   #$40   
DF8E		CLR   <$17
			DEC   <$17
DF92		STX   <$88		; cursor position
			CMPX  #$0800	; bottom of screen?
			BHS   DFE3		; scroll (insert new line at bottom of screen)

; invert cursor

DF99		LDX   <$88		; cursor position
			LDA   ,X
			EORA  #$40   
			STA   ,X
			RTS

; handle TAB

DFA2		EXG   X,D
			ANDB  #$F8
			EXG   X,D
			LEAX  8,X
			BRA   DF8E

; handle LF

DFAC		INC   <$16
			BEQ   DF99		; invert cursor
DFB0		INC   <$17
			LDA   <$89
			ANDA  #$1F
			ORA   <$17
			BEQ   DF99		; invert cursor
			LEAX  33,X

; handle backspace

DFBD		CMPX  <$AD		; top of screen
			BLS   DF99		; invert cursor
			LDA   #$20
			STA   ,-X
			BRA   DF92

; handle control character

DFC7		CMPB  #$09		; TAB?
			BEQ   DFA2		; handle tab
			CMPB  #$0A			; LF?
			BEQ   DFAC		; handle LF
			CMPB  #$08		; backspace?
			BEQ   DFBD		; handle backspace
			CMPB  #$0D		; CR?
			BNE   DF99		; invert cursor
			EXG   X,D
			ANDB  #$E0
			EXG   X,D
			CLR   <$16
			DEC   <$16
			BRA   DFB0

; scroll (insert new line at bottom of screen)

DFE3		LEAX  -32,X
			STX   <$88		; cursor position
			LDX   <$AD		; top of screen
DFEA		LDA   32,X
			STA   ,X+
			CMPX  #$07E0	; start of bottom line?
			BLO   DFEA

; clear from X to end of screen

DFF4		LDA   #$20
DFF6		STA   ,X+
			CMPX  #$0800
			BCS   DFF6
			BRA   DF99		; invert cursor

DFFF		FCB   $FF
