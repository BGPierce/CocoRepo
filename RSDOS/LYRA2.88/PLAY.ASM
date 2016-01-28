 TITLE "PLAY"
*************************************************
* PLAY/TXT - INCLUDE FILE FOR LYRA
* CONTAINS THE MUSIC PLAY ROUTINES (MIDI AND TV)
* (C) 1986-1988 by Lester Hands
* Last update: 02-may-90
* Last update: 24-jun-90 modifications (c) R.Gault
*************************************************

*MSG "PLAY=",*

FOLLOW_F FCB 0 =1 when display follows play
NTPG_CTR FCB 10 note page counter

TGLFOLLW PSHS X
 LDX #FOLMENU
 TST FOLLOW_F
 BNE A@
 LDA #1
 STA FOLLOW_F
 LDA #'N
 LDB #32
 BRA B@
A@ CLR FOLLOW_F
 LDD #'F*256+'F
B@ STD 1,X
 PULS X,PC

* Play all files on a disk
*
CNT SET 0
PTR SET 1
*
PLAYALL PSHS X,Y
 LEAS -3,S room for local variables
* BEGIN CONDITIONAL
 IFNE DEMO
 LDX #a@
 LBSR SETREQ
 LBSR DSPREQ
A@ LBSR KEYIN
 TSTA
 BEQ A@
 LBSR REFMEN
 CMPA #3
 LBEQ Z@
 CMPA #'Y
 BEQ B@
 CMPA #'y
 BEQ B@
 LDA #1
 STA CNT,S
 BRA D@ MOD June 3,1990 was after ENDC
 ENDC
* END CONDITIONAL
* to play all files, first get a directory of disk
B@ LDX #FILENAME
 LBSR DIR
 LDB #36 number of entries
 STB CNT,S in directory string
 LDX #DIRSTR-9
 STX PTR,S
* transfer filename from directory string to FILENAME
C@ LDX PTR,S
 LEAX 9,X point to next filename
 STX PTR,S
 LBSR BLNKCHEK if filename is blank
 TSTA  then skip to next one
 BNE E@
 LDY #FILENAME
 LDB #8
 LBSR MOVEDATA
* read in the file and set up various parameters
 LBSR DISKREA
 LBSR RSETPTR
 LDD KEYSIG
 STD KSIGDAT
 LDD TIMESIG
 STA TSIGDAT
 STB TSIGDAT+2
 LBSR SETTSIG
 LBSR RSETPTR
 LBSR DSPFNAME
 LDA #SEL_OK
 STA SAVEOK
 CLR $FF40 turn disk motor off
 CLR CONTFL
 LBSR SET_PTRS
 LBSR BLK_RSET
 TST FOLLOW_F option
 BNE D@    "
 LDX #ANOTPALL    " MOD R.Gault
 LBSR SETREQ    "
 LBSR DSPREQ    "
 LBSR SET_PTRS
* play the file and see if there are more to play
D@ BSR MIDIPLAY
 LBSR KEYIN
 CMPA #3
 BEQ Z@
 LDB CNT,S not "all notes off"
 CMPB #1 if this is the last
 BEQ E@ file played
*        LBSR    MIDIOFF
E@ DEC CNT,S
 BNE C@
Z@ LDA HPOS
 PSHS A
 CLR HPOS
 LBSR BLANK
 PULS A
 STA HPOS
 LBSR WRTSTF
 LBSR DSPMUS
 LBSR VOIBOX
 LEAS 3,S
 PULS X,Y,PC
* MOD June 3,1990 R.Gault not needed if DEMO
 IFNE DEMO
*--START CONDITIONAL
a@ FCB 48 	*Requester: VPOS
 FCB 4 		*HPOS
 FCB 22 	*width
 FCB 3 		*height
 FCB 0 		*length of input
 FDB 0 		*address of input area
 FCC " Lose current music?"
 FCB 0 		*end of requester
b@ FDB 0
 ENDC
*--END CONDITIONAL

PBAKPTR LDX #DSP_STRT back up voice pointers
 LDY #DSP_CURS
 LDB #16
 LBSR MOVEDATA
 LDX #CNT_STRT set up starting counters
 LDY #CNT_CURS
 LDB #8
 LBSR MOVEDATA
 LDD MEA_STRT
 STD MEA_CNT
 LDD BNUM_ST
 STD BAR_NUM
 RTS

*MIDIPLAY - play music through MIDI
*ENTRY: DSP_STRT's must be set up
*
MIDIPLAY PSHS CC,D,X,Y
 ORCC #$50 disable interrupts
 TST DW4FLG
 BEQ b@
 LBSR DWSEND
b@ LDA #40 initialize MTEMPO
 STA MTEMPO
 TST PORTFL
* MOD R.Gault was BNE M@
 BEQ M@
 LDA #3 initialize ACIA
 STA [CMSTAT] master reset
 LDA #$15
 STA [CMSTAT] 8 bits, no par, 1 stop bit
M@ CLR $FF02
A@ LDA $FF00 wait for key off
 ORA #$80
 CMPA #$FF
 BNE A@
 CLR CLICK
 CLR MIDISTAT
 LDB #16
 LDX #MIDILNOT
C@ CLR ,X+
 DECB
 BNE C@
 LDX #MIDIVELO normalize velocity table
 LDD #64*256+8 MOD was LDA LDB
H@ STA ,X+
 DECB
 BNE H@
 LDX #OCTVTABL clear octave transposers
 LDB #8
F@ CLR ,X+
 DECB
 BNE F@
 BSR PBAKPTR back up pointers and counters
 LDD VOI_CNT get voice counter for
 STD a@ voice 1 and save it.
 LDD BUFFER zero MIDI buffer
 STD MBUF_PTR
 LBSR PSET_OPT setup options
 TST CLOCKFL
 BEQ D@
 TST CONTFL
 BEQ J@
 LDA #$FB send MIDI continue signal
 BRA K@
J@ LDA #$FA send MIDI start signal
K@ LBSR SENDMIDI
D@ CLRB  voice counter 0-->7
B@ LBSR MGETNOTE
 INCB  all voices tested?
 CMPB #8
 BNE B@
 LBSR MIDFLUSH
 LBSR GET_SMAL
 TSTB  check for end of all voices
 BEQ E@
 PSHS D
 TFR A,B
 CLRA
 ADDD a@ update voice length counter
 STD a@
 PULS D
 LBSR MIDIDELA
 CLR $FF02
 LDA $FF00 check for keypress
 ORA #$80
 CMPA #$FF
 BNE L@ loop back if not
 TST FOLLOW_F
 BEQ D@
 DEC NTPG_CTR note page counter
 BNE D@
 BRA G@
L@ CLR CONTFL
 LDA #$DF see if "U" key pressed
 STA $FF02
 LDA $FF00
 ORA #$80
 CMPA #$FB
 BNE E@
 INC CONTFL
 LBSR MIDFLUSH flush interrupted notes
G@ TST [DSP_CURS] check for end of music
 BEQ E@
 LBSR RSETPTR
 LDD a@ update display to point
 LBSR ADV_DSP
 CLR NTPG_CTR
 LBSR DSPMUS
 TST FOLLOW_F
 BEQ E@
 LBSR PBAKPTR
 BRA D@
E@ LBSR ALL_OFF
 LBSR MIDFLUSH
 TST CLOCKFL
 BEQ Z@
 LDA #$FC send MIDI stop signal
 LBSR SENDMIDI
Z@ CLR CLOCKFL
 LDD MENCLK
 CMPD #$4F4E
 BNE I@
 COM CLOCKFL
I@ PULS CC,D,X,Y,PC
a@ FDB 0 		*storage for VOI_CNT

* Look for and 'play' all the options in music up
* to current position
*
*
PSET_OPT LDY #VOI_PTR
 LDU #DSP_STRT
 LDD ,Y exit if at start
 CMPD ,U of music
 BEQ Z@
 CLRB
A@ LDX ,Y++
B@ LDA ,X get NVALUE
 BEQ C@ end of voice?
 BPL C@ loop if not option
 CMPA #BYTEOPT ignore midi byte out
 BEQ C@
 LBSR PLAYOPT2
C@ LEAX 2,X
 CMPX ,U loop if not at
 BLS B@ display position
 LBSR MIDFLUSH
 LEAU 2,U
 INCB  advance voice counter
 CMPB #8
 BNE A@
Z@ RTS

*MGETNOTE - MIDI get note and play it
* Handles note on but not note off.
*ENTRY: B=voice number
*EXIT: CNT_CURS updated if note played
* DSP_CURS updated
*Stack offsets:
CURNOT SET 0 		*current note
PRVNOT SET 2 		*previous note pitch
VOI SET 4
*
MGETNOTE PSHS D,X,Y,U
 LEAS -3,S make room for extra variable
 TFR S,U U points to variables
C@ LDX #DSPMODE check for DSPMODE=0
 TST B,X if so, exit
 LBEQ Z@
 LDX #CNT_CURS
 TST B,X check for counter=0
 BNE Z@ note not ready to play if >0
 LSLB  convert voice to word offset
 LDX #DSP_CURS
 TST [B,X] check for end of voice
 BNE A@
 LDB VOI,U
 LBSR NOTE_OFF
 BRA Z@
A@ BPL B@ check for options
 LDB VOI,U
 LBSR PLAY_OPT
 LDB VOI,U
 BRA C@
B@ LDB VOI,U
 LSLB
 LDX B,X get voice pointer
 LDA 2,X get next note NVALU
 ANDA #TIEBIT
 LDY #TIENEXT
 LSRB  byte offset
 STA B,Y
 LDA -1,X get previous note pitch
 STA PRVNOT,U save previous note pitch
 LDY ,X++ get current note,
 STY CURNOT,U save it,
 LDY #DSP_CURS update pointer.
 LSLB  word offset
 STX B,Y
 LDA CURNOT,U get current note
 ANDA #TIEBIT check for tie
 LDX #TIEFLAG
 LSRB  byte offset
 STA B,X
 LDA PRVNOT,U restore prev. note pitch
 ANDA #$3F pitch of previous note same?
 PSHS A if same then don't send note on
 LDA CURNOT+1,U restore cur. note pitch
 ANDA #$3F
 CMPA ,S+
 BEQ F@
 CLR B,X clear tieflag
F@ LDA VOI,U
 STA PLAYVOIC
 LDD CURNOT,U
 LBSR CNV_COMI
 PSHS B save MIDI pitch
 LDB VOI,U
 LDX #CNT_CURS
 STA B,X update counter
 BSR SETNOTF
 PULS A restore note MIDI pitch
 TSTA  check for rest (pitch=0)
 BEQ Z@
E@ LDX #TIEFLAG
 TST B,X check for tie
 BNE Z@
 LBSR NOTE_ON
Z@ LEAS 3,S
 PULS D,X,Y,U,PC

TIENEXT RZB 8	*,0 >0=nxt note tied, note off afcted
TIEFLAG RZB 8	*,0 >0 = note tied, affects note on

*SETNOTF - set fractional note length counter
*ENTRY: A=note length
* B=voice number (0-7)
*
SETNOTF PSHS D,X
 LSRA  divide note length by 8
 LSRA
 LSRA
 LDX #NOTEFRAC
 LDB B,X get fraction
 MUL
 NEGB
 ADDB 0,S
 LDX #MIDINFRA
 LDA 1,S get voice number
 STB A,X
 PULS D,X,PC

MIDINFRA FCB 0,0,0,0
 FCB 0,0,0,0

*PLAY_OPT - play an option
*ENTRY: voice number in B
* X points to DSP_PTR
*
VOI SET 0
NOT SET 1
*
PLAY_OPT PSHS D,X,Y
 LEAS -3,S room for local vars
 STB VOI,S
 LBSR NOTE_OFF
 LSLB
 ABX
 LDY ,X get pointer to voice
 LDD ,Y++ get note
 STY ,X update pointer
 BRA B@
* entry point for B=voice, X=points to code, no update
PLAYOPT2 PSHS D,X,Y
 LEAS -3,S
 STB VOI,S
 LDD ,X
B@ STD NOT,S
 ANDA #$F0
 CMPA #EVNTOPT test for event option
 LBEQ PLAYEVNT
 CMPA #INSTOPT test for instrument
 BEQ PLAYINST  option
 CMPA #TEMPOPT test for tempo option
 BEQ PLAYTEMP
 CMPA #BYTEOPT
 BEQ PLAYBYTE
 CMPA #OCTVOPT
 BEQ PLAYOCTV
 CMPA #LOCOOPT
 BEQ PLAYLOCO
 CMPA #VOL_OPT
 BEQ PLAY_VOL
 CMPA #CLK_OPT
 LBEQ PLAY_CLK
Z@ LEAS 3,S
 PULS D,X,Y,PC
PLAY_VOL LDB FILTER
 BITB #VOL_FL
 BNE Z@
 LDA NOT,S
 ANDA #$0F keep volume number
 LDX #MIDIVOL point to volume table
 LDA A,X get volume
 LDX #MIDIVELO point to velocity table
 LDB VOI,S
 STA B,X new velocity
 BRA Z@
PLAYLOCO LDB VOI,S
 LDX #OCTVTABL
 CLR B,X
 BRA Z@
PLAYOCTV LDB VOI,S
 LDX #OCTVTABL
 ABX
 LDA NOT+1,S get position of marker
 CMPA #$0B if above staff, raise
 BHI A@
 LDB #12
 STB ,X
 BRA Z@
A@ CMPA #$21 if below staff, lower
 BLO Z@
 LDB #-12
 STB ,X
 BRA Z@
PLAYBYTE LDB FILTER
 BITB #BYTE_FL
 BNE Z@
 LDA NOT+1,S get byte to send
 LBSR SENDMIDI
 BRA Z@
PLAYTEMP LDB NOT+1,S get tempo into B
 STB MTEMPO
 BRA Z@
PLAYINST LDB FILTER
 BITB #INST_FL
 BNE Z@
 LDX #MIDICHAN
 LDB VOI,S
 LDA B,X get channel number
 ORA #$C0
 BSR MIDI_OUT
 LDA NOT,S
 ANDA #$0F get instrument number
 LDX #MIDINSTB get program number
 LDA A,X
 BSR MIDI_OUT
 BRA Z@
PLAYEVNT LDB FILTER
 BITB #EVNT_FL
 BNE Z@
 LDA NOT,S get event number
 ANDA #$0F
 PSHS A
 LDB #15 convert to table offset
 MUL  (15 bytes per entry)
 ADDD #EVENTS
 TFR D,X
 PULS A
 LDB ,X+ get # bytes
 LBEQ Z@
 CMPB #15 check for file dump
 BNE C@
 LBSR EVNTFILE
 LBRA Z@
C@ LDA ,X+ get byte to output
 BSR MIDI_OUT
 LDA MBREATH
 BEQ E@
D@ CMPU [$1000,PCR] kill 15 cycles
 DECA
 BNE D@
E@ DECB
 BNE C@
 LBRA Z@
PLAY_CLK LDA NOT+1,S
 STA CLOCKFL
 LBRA Z@

FILTER FCB 0 >0 if filter is on

*MIDI_OUT - output byte to MIDI buffer
*ENTRY: byte to send in A
*
MIDI_OUT PSHS D,X
 LDX MBUF_PTR
 STA ,X+
 STX MBUF_PTR
 PULS D,X,PC

*MIDFLUSH - send MIDI buffer (flush it)
*
MIDFLUSH PSHS A,X
 LDX BUFFER
 PSHS X
A@ CMPX MBUF_PTR
 BEQ B@
 LDA ,X+
******** questionable code for running status
*        BPL     D@
*        CMPA    MIDISTAT,PCR  if a status byte, then
*        BEQ     A@            compare with current one
D@ BSR SENDMIDI
 LDA MBREATH
 BEQ A@
C@ CMPU [$1000,PCR] kill 15 cycles
 DECA
 BNE C@
 BRA A@
B@ PULS X zero buffer
 STX MBUF_PTR
 PULS A,X,PC
MIDISTAT FCB 0 		*current status byte

PORTFL FCB 0 		*=0 if Serial Port
DW4FLG FCB 0		*=0 if standard Serial Port

*SENDMIDI - outputs bytes to MIDI
* (CoCo MIDI and serial port)
*ENTRY: byte to send in A
*

MDAT FCB $8E,0
SENDDW4 STA MDAT+1
 PSHS X,Y
 LEAX MDAT,PCR
 LDY #2
SM2 STA FAST
 LBSR RAM_IO
 IFNE VER
 JSR [$D941]	1.4 HDB-DOS
 ENDC
 IFEQ VER
 JSR $DB21	1.1 HDB-DOS
 ENDC
 LBSR RAM_LYR
 PULS X,Y,PC

SEQ FCB $C4,$0E,$29
DWSEND PSHS X,Y
 LEAX SEQ,PCR
 LDY #3
 BRA SM2


SENDMIDI TST DW4FLG
 BNE SENDDW4
 PSHS D
 STA SLOW
 TST PORTFL
 BEQ G@
 LDB #2 check for empty
A@ BITB [CMSTAT] transmit buffer
 BEQ A@
 STA [CMDATA] output to CoCo MIDI
 BRA Z@
G@ LDB #8 bit counter for
 PSHS B serial port
 LDB $FF20
 ANDB #$FD
 STB $FF20 send start bit
 CMPX [255,X] kill 13 cycles
B@ LSRA  prepare to send bit 2CYC
 BCC C@  3 CYC
 ORB #2  2CYC
 BRA D@  3CYC
C@ ANDB #$FD 2 CYC
 NOP         2 CYC
D@ STB $FF20
 CMPD #0 kill 5 cycles
 DEC 0,S decrement bit counter
 BNE B@
 CMPD $FF00 kill 8 cycles
 ORB #2
 STB $FF20 send stop bit
 PULS B
Z@ TST COCO3
 BNE E@
 STA FAST
E@ LDA #$20 small delay
F@ DECA
 BNE F@
 PULS D,PC

 
MBUF_PTR FDB 0 		*ptr. to current pos. in BUFFER

MIDPITCH FCB $0,$60,$5F,$5D,$5B,$59,$58,$56
 FCB $54,$53,$51,$4F,$4D,$4C,$4A,$48
 FCB $47,$45,$43,$41,$40,$3E,$3C,$3B
 FCB $39,$37,$35,$34,$32,$30,$2F,$2D
 FCB $2B,$29,$28,$26,$24,$23,$21,$1F
 FCB $1D,$1C,$1A,$18,$17,$15,$13,$11
 FCB $10,$E,$C,$B,$9,$7,$5,$4
 FCB $2,$0,$0,$0,$0,$0,$0,$0

 RZB 4	*,0 MOD may not be needed

*CNV_COMI - converts music code to MIDI pitch
*ENTRY: A=note length code (NVALU)
* B=music code pitch
* TRANOFFS is set to the transpose offset
* OCTVTABL indicates octave transposition set by option
*EXIT: A=actual note length
* B=MIDI pitch (=0 if a rest)
*
CNV_COMI PSHS X,Y
 TSTA
 BEQ Z@
 LBSR CONVNVAL convert to actual note length
 TSTB  check for rest (B=0)
 BEQ Z@
 PSHS A save note length in stack
 PSHS B
 LDX #MIDPITCH
 ANDB #$3F discard sharp+flat bits
 LDA B,X
 ADDA TRANOFFS add transpose offset
 LDX #OCTVTABL
 LDB PLAYVOIC add octave up/down
 ADDA B,X
 PULS B restore pitch code
 BITB #FLATBIT
 BEQ E@
 DECA
E@ BITB #SHARPBIT
 BEQ F@
 INCA
F@ TFR A,B
 PULS A restore note length
Z@ PULS X,Y,PC

*MIDIDELA - delay for MIDI play,
* handles note off.
*ENTRY: A=note length
* also MASTEMP and TEMPO must be set up
*
CLOCK FCB 2 		*counter for MIDI clock
CLOCKFL FCB 0 		*>0 if clock enabled
CONTFL FCB 0 		*>0 if play restart is "CONTINUE"
*
MIDIDELA PSHS D,X,Y,U
 STA SLOW
 LDX #MIDINFRA
 LDU #TIENEXT
A@ LDB MTEMPO Delay for TEMPO*note len.
B@ LDY TEMPO
C@ LEAY -1,Y
 BNE C@
 DECB
 BNE B@
D@ TST B,X Check MIDINFRA counters
 BEQ E@
 DEC B,X Note off only when
 BNE E@ counter goes zero.
 TST B,U If next note tied, then
 BNE E@ no note off.
 LBSR NOTE_OFF
 STA SLOW
E@ INCB
 CMPB #8
 BNE D@
 LBSR MIDFLUSH
 STA SLOW
 TST CLOCKFL see if clock is enabled
 BNE I@
 NOP
 BRA F@
I@ DEC CLOCK
 BNE F@
 PSHS A
 LDA #2
 STA CLOCK
 LDA #$F8 send MIDI clock signal
 LBSR SENDMIDI
 STA SLOW
 PULS A
 BRA H@
F@ LDB #13
G@ DECB
 BNE G@
H@ DECA
 BNE A@
 TST COCO3
 BNE J@
 STA FAST
J@ PULS D,X,Y,U,PC

*NOTE_ON - play MIDI note
*ENTRY: pitch in A
* voice # in B
*
NOTE_ON PSHS D,X,Y
 LDY #MIDILNOT
 LSLB
 LEAY B,Y
 LSRB
 LDA FILTER
 BITA #CHAN_FL
 BEQ C@
 CLRA
 BRA B@
C@ LDX #MIDICHAN get MIDI channel #
 LDA B,X
B@ ORA #$90
 LDB ,S
 BSR CHKNTON
 TSTA
 BEQ Z@
 STA ,Y+ put first in MIDILNOT
 LBSR MIDI_OUT send it
 LDA ,S restore note pitch
 STA ,Y save note pitch
 LBSR MIDI_OUT send note pitch
 LDX #MIDIVELO get velocity
 LDB 1,S get voice #
 LDA B,X
 LDX #DSPMODE if voice is not being
 TST B,X displayed, don't play
 BEQ Z@
 LBSR MIDI_OUT send it
Z@ PULS D,X,Y,PC

*CHKNTON - check for a note on of same pitch and channel
*ENTRY: pitch in B, channel+$90 in A
*EXIT:  if duplicate found, A=0
*
CHKNTON PSHS D
 LDX #MIDILNOT
 LDB #8
 PSHS B
 LDD 1,S
A@ CMPD ,X++
 BEQ B@
 DEC ,S
 BNE A@
 BRA Z@
B@ CLRA
Z@ PULS B
 PULS D,PC

*NOTE_OFF - turn MIDI note off
*ENTRY: voice # in B
*
NOTE_OFF PSHS D,X,Y
 LDX #MIDILNOT
 LSLB
 ABX
 TST ,X make sure there is a
 BEQ Z@ note to turn off.
 LDA ,X+
 LBSR MIDI_OUT
 LDA ,X
 LBSR MIDI_OUT
 CLRA  velocity of 0 = note off
 LBSR MIDI_OUT
 CLR -1,X
Z@ PULS D,X,Y,PC

*ALL_OFF - send MIDI note off message for each channel
*
ALL_OFF PSHS B
 LDB #0 	voice counter
A@ BSR NOTE_OFF
 INCB
 CMPB #8
 BNE A@
 PULS B,PC

*MIDIOFF - send note off messages to all notes on
* all MIDI channels
*
CHAN SET 0
NOTE SET 1
*
MIDIOFF PSHS D
 LEAS -3,S
 LDA #15
 STA CHAN,S
A@ CLR NOTE,S
 LDA #$B0 send Yamaha all notes off
 ORA CHAN,S
 LBSR SENDMIDI
 BSR C@
 LDA #$7B
 LBSR SENDMIDI
 BSR C@
 CLRA
 LBSR SENDMIDI
 BSR C@
 LDA #$90
 ORA CHAN,S
 LBSR SENDMIDI
 BSR C@
B@ LDA NOTE,S
 LBSR SENDMIDI
 CLRA
 LBSR SENDMIDI
 INC NOTE,S
 BPL B@
 DEC CHAN,S
 BPL A@
 LEAS 3,S
 PULS D,PC
C@ LDA #32 short delay routine
D@ DECA
 BNE D@
 RTS

MTEMPO FCB 40 		*MIDI tempo
TRANOFFS FCB 0 		*transpose offset
OCTVTABL RZB 8		*,0 octave up/down offsets
MIDILNOT RZB 16		*,0 last note pitch played
PLAYVOIC FCB 0		* voice being played
MIDIVELO FCB 64,64,64,64,64,64,64,64

SCALE FCB 0,2,3,5 	*half step offsets from note A
 FCB 7,8,10

*PLAY - play music in MUSICA II style
*
PLAY PSHS CC
 ORCC #$50 disable interrupts
 LDY #$4000
C@ LEAY -1,Y
 BNE C@
*        LDA     #3
*        STA     $FF20
*        LDX     #$FF00        turn on tv sound port
*        LDA     1,X
*        ANDA    #$F7
*        STA     1,X
*        LDA     3,X
*        ANDA    #$F7
*        STA     3,X
*        LDA     #$3C
*        STA     $23,X
*MOD DEC.11,1992
 STA ROM_ON
 CLRB
 JSR $A9A2 SELECT DAC
 JSR $A976 SOUND ON
 STA ROM_OFF
 LDX #LNOTES
 BSR SETUPLP
 CLR $FF02 prepare for fast keyboard read
 LDD TEMPO
 LDA #3
 MUL
 TST COCO3
 BEQ A@
 LSRA
 RORB
A@ STD MU2TEMPO
L@ BSR GETLCHRD
 TSTA
 BEQ B@
 LBSR MUPLAY
 LDB $FF00 test for keypress
 ORB #$80
 CMPB #$FF
 BNE M@ loop back for next chord
 TSTA
 BNE L@
M@ LBSR WAITKEY
*MOD Dec.11,1992
B@ STA ROM_ON
 JSR $A974
 STA ROM_OFF
*        LDX     #$FF00        turn off sound port.
*        LDA     #$34
*        STA     $23,X
*        LDA     #8
*        ORA     1,X
*        STA     1,X
*        LDA     #8
*        ORA     3,X
*        STA     3,X
*        LDA     #3
*        STA     $20,X
 PULS CC,PC

* Set up LPTRs for use with GETLCHRD
* ENTRY: X points to LPTR
*
COUNT SET 0
*
SETUPLP PSHS D,X,Y,U
 LEAS -1,S room for local variables
 TFR X,U
 LDX #DSP_STRT
 LDY #CNT_STRT
 LDB #8
 STB COUNT,S
A@ LDD ,X++
 STD ,U++
 LDA ,Y+
 STA ,U+
 CLR ,U+
 CLR ,U+
 DEC COUNT,S
 BNE A@
 LEAS 1,S
 PULS D,X,Y,U,PC

*Get a Lyra chord
*ENTRY: X points to a LPTR structure (set up)
*EXIT: A=chord length (0 if end of music)
*
CHRDLEN FCB 0 		*length of chord
LNOTSIZ EQU 5
LNOTES RZB LNOTSIZ*8	*,0 notes: pointer,count,pitch
* struct {
*   cell *ptr;
*   char count;
*   int pitch;
* } lptr;
*
COUNT SET 0
LPTR SET 1
*
GETLCHRD PSHS B,X,Y
 LEAS -3,S local variables
 STX LPTR,S
 CLR -1,X clear CHRDLEN
 LDB #8
 STB COUNT,S
* go through each member of the structure and update
* notes that have a zero counter
*        LDX     LPTR,S        get first pointer
A@ TST 2,X test note count
 BNE D@
 LDY ,X get Lyra pointer
B@ LDD ,Y++ get music code
 BMI B@ skip option codes
 BEQ C@ if at end of code,
 STY ,X dont update pointer
C@ LBSR CNV_COMI
 STA 2,X update count
 LBSR CNV_MIMU
 STD 3,X update pitch
D@ LEAX LNOTSIZ,X move to next note
 DEC COUNT,S
 BNE A@
* find smallest nonzero note count
 LDX LPTR,S
 LDB #8 counter
 LDA #$FF largest count; initializer
E@ TST 2,X
 BEQ F@
 CMPA 2,X check note count
 BLS F@ smaller?
 LDA 2,X
F@ LEAX LNOTSIZ,X move to next member
 DECB
 BNE E@
 CMPA #$FF if still = $FF
 BNE I@ then all notes at end
 CLRA
I@ STA CHRDLEN =smallest count
* decrement each nonzero count by smallest count
 LDX #LNOTES
 LDB #8 counter
 NEGA  -(smallest note)
 STA COUNT,S
G@ TST 2,X check for nonzero count
 BEQ H@
 LDA 2,X
 ADDA COUNT,S
 STA 2,X
H@ LEAX LNOTSIZ,X move to next member
 DECB
 BNE G@
 LDA CHRDLEN return chord length
 LEAS 3,S
 PULS B,X,Y,PC

V1PTR FDB SINE
 FCB 0
V2PTR FDB SINE
 FCB 0
V3PTR FDB SINE
 FCB 0
V4PTR FDB SINE
 FCB 0
V5PTR FDB SINE
 FCB 0
V6PTR FDB SINE
 FCB 0
V7PTR FDB SINE
 FCB 0
V8PTR FDB SINE
 FCB 0
DUR FCB 0
MU2TEMPO FDB $40

* play a chord
* ENTRY: X point to LPTR
*
MUPLAY PSHS D,X,Y,U
 LDD MUPORT set up address for PIA port
 STD PIAOUT+1
 TFR X,U point to start of music
A@ LDA -1,U load duration
 BEQ Z@ test for end of music
 STA DUR
 LDX #V1PTR
B@ LDY MU2TEMPO
C@ LDB [,X] output voices to sound port
 ADDB [3,X]
 ADDB [6,X]
 ADDB [9,X]
 ADDB [12,X]
 ADDB [15,X]
 ADDB [18,X]
 ADDB [21,X]
 ORB #3 prevent serial line change
PIAOUT STB $FF20
 LDD 1,X increment voice pointers.
 ADDD 3,U only the LSB and
 STD 1,X "fractional" bytes change.
 LDD 4,X 2
 ADDD 8,U
 STD 4,X
 LDD 7,X 3
 ADDD 13,U
 STD 7,X
 LDD 10,X 4
 ADDD 18,U
 STD 10,X
 LDD 13,X 5
 ADDD 23,U
 STD 13,X
 LDD 16,X 6
 ADDD 28,U
 STD 16,X
 LDD 19,X 7
 ADDD 33,U
 STD 19,X
 LDD 22,X 8
 ADDD 38,U
 STD 22,X
 LDB $FF00 test for keypress
 ORB #$80
 CMPB #$FF
 BNE Z@
 LEAY -1,Y update tempo counter
 BNE C@
 DEC DUR update duration counter
 BNE B@
Z@ PULS D,X,Y,U,PC

*CNV_MIMU - convert MIDI pitch to MUSICA II pitch
*ENTRY: B=MIDI pitch
*EXIT: D=MUSICA II pitch

CNV_MIMU PSHS X,Y
 CLRA
 TSTB
 BEQ C@
 NEGB
 ADDB #88 	*88=MIDI pitch for E5
 LDX #12 	*get X=octave, D=note of table
 LBSR DIVIDE
 LDY #PITCH
 LSLB
 LDD D,Y get top octave pitch
B@ CMPX #0 lower pitch 1 octave
 BEQ A@ for every count in X
 LEAX -1,X
 LSRA
 RORB
 BRA B@
A@ TST COCO3
 BNE C@
 LSRA
 RORB
C@ PULS X,Y,PC

*PITCH - top octive table for MUSICA II pitches
*
PITCH FDB 23187
 FDB 21886
 FDB 20657
 FDB 19498
 FDB 18404
 FDB 17371
 FDB 16396
 FDB 15476
 FDB 14607
 FDB 13787
 FDB 13013
 FDB 12283
