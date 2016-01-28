 TITL1 "PLAY/TXT"
*************************************************
* PLAY/TXT - INCLUDE FILE FOR LYRABOX
* (C) 1988 by Lester Hands
* Last update: 28-jun-88
*************************************************

EVNTOPT EQU $80
INSTOPT EQU $90
TEMPOPT EQU $A0
BYTEOPT EQU $B0
OCTVOPT EQU $C0
LOCOOPT EQU $D0
VOL_OPT EQU $E0
CLK_OPT EQU $F0

ENDPLAY PSHS D
 LBSR CLRSTAT
 CLRA
 CLRB
 STD LASTFILE
 PULS D,PC

*MIDIPLAY - play music through MIDI
*ENTRY: DSP_STRT's must be set up
*EXIT: A=keypress (if any)
*
FILTER FCB 0 =$FF if ignore channels
*
MIDIPLAY NOP
MPLAY CLRA
 LDA #3 initialize ACIA
 STA [CMSTAT] master reset
 LDA #$15
 STA [CMSTAT] 8 bits, no par, 1 stop bit
G@ CMPA #3
 BNE I@
H@ LBRA ENDPLAY
I@ LBSR GETSEL
 TSTA
 BMI H@
 LDX #MIDIVELO initialize velocities
 LDB #8
 LDA #64
J@ STA ,X+
 DECB
 BNE J@
 LDX #OCTVTABL and octave transposes
 LDB #8
K@ CLR ,X+
 DECB
 BNE K@
 LDA #40
 STA MTEMPO and tempo.
 PSHS A,X,Y
 CLR $FF02
A@ LDA $FF00 wait for key off
 ORA #$80
 CMPA #$FF
 BNE A@
 CLR CLICK
 LDX #MIDILNOT
C@ CLR ,X+
 CMPX #MIDILNOT+8
 BNE C@
 LDX #DSP_STRT back up voice pointers
 LDY #DSP_CURS
 LDB #16
 JSR MOVEDATA
 LDX #CNT_STRT set up starting counters
 LDY #CNT_CURS
 LDB #8
 JSR MOVEDATA
 LDD MEA_STRT
 STD MEA_CNT
 LDD BNUM_ST
 STD BAR_NUM
 LDD VOI_CNT get voice counter for
 STD a@ voice 1 and save it.
 LDD BUFFER zero MIDI buffer
 STD MBUF_PTR
 TST CLOCKFL
 BEQ D@
 TST CONTFL
 BEQ D0
 LDA #$FB send MIDI continue signal
 BRA D1
D0 LDA #$FA send MIDI start signal
D1 JSR SENDMIDI
D@ CLRB  voice counter 0-->7
B@ JSR MGETNOTE
 INCB  all voices tested?
 CMPB #8
 BNE B@
 JSR MIDFLUSH
 JSR GET_SMAL
 TSTB  check for end of all voices
 BEQ E@
 PSHS D
 TFR A,B
 CLRA
 ADDD a@ update voice length counter
 STD a@
 PULS D
 JSR MIDIDELA
 CLR $FF02
 LDA $FF00 check for keypress
 ORA #$80
 CMPA #$FF
 BEQ D@ loop back if not
 LBSR KEYIN
 LBSR ALL_OFF
E@ JSR MIDFLUSH
 TST CLOCKFL
 BEQ Z@
 PSHS A
 LDA #$FC send MIDI stop signal
 JSR SENDMIDI
 PULS A
Z@ PULS B,X,Y
 LBRA G@
a@ FDB 0 storage for VOI_CNT

*RSETPTR - reset music pointers to start of music
* Also adjusts pointers if code has become corrupted
*
RSETPTR PSHS D,X,Y,U
 LDX #V1 point to start of code
 LDY #VOI_PTR
C@ STX ,Y++ save start of voice
 CMPY #VOI_PTR+16 done yet?
 BEQ D@
E@ CMPX SCREEN
 BLO F@
 LDX -2,Y corrupt code: erase
 LEAX 2,X
 CLRA
 CLRB
 STD ,X++
 BRA C@
F@ TST ,X++ check for end of voice
 BEQ C@
 BRA E@
D@ STX ,Y++ set INSTPTR and ENDPTR
 STX ,Y
 LDX #VOI_PTR
 LDY #DSP_STRT
 LDB #16
 JSR MOVEDATA
 LBRA CLRCNT

*CONVNVAL - convert NVALU to actual note length
*ENTRY: NVALU in register A, pitch in B
* recognizes rests, dotted & triplet notes
*EXIT: actual length in A
* B=0 if rest, else pitch
*
CONVNVAL PSHS B,X
 TSTA
 BMI Z@ exit if not a note
 BEQ Z@ (>0, <128)
 TFR A,B
 ANDA #$07 mask out modifier bits
 ANDB #$F8 B keeps modifier bits
 BITB #TRIPBIT check for triplet
 BNE A@
 LDX #NOTVAL
 BRA B@
A@ LDX #TRIPVAL
B@ DECA
 LDA A,X get actual note value
 BITB #DOTBIT check dotted note flag
 BEQ C@
 PSHS A
 LSRA  increase note value if set
 ADDA ,S+
C@ BITB #RESTBIT check for rest
 BEQ Z@
 CLR ,S
Z@ PULS B,X,PC

*NOTVAL - table of actual note lengths in order
*of their display codes
*
NOTVAL FCB 192 whole
 FCB 96 half
 FCB 48 quarter
 FCB 24 8th
 FCB 12 16th
 FCB 6 32nd
 FCB 3 64th

*TRIPVAL - same as NOTVAL, except triplet equivalents
*
TRIPVAL FCB 128 whole
 FCB 64 half
 FCB 32 quarter
 FCB 16 8th
 FCB 8 16th
 FCB 4 32nd
 FCB 2 64th

*pointers and counters at start of screen display
DSP_STRT RMB 16,0 display pointers to voices
CNT_STRT RMB 8,0 starting offset for CNT_CURS
MEA_STRT FDB 0 starting measure count
BNUM_ST FDB 0 starting barline number
VOI_CNT RMB 16,0 voice counter from start of music

*pointers and counters at cursor position
DSP_CURS RMB 16,0 cursor display pointers
CNT_CURS RMB 8,0 note value
MEA_CNT FDB 0 measure counter
BAR_NUM FDB 0 barline number
VOI_CCUR FDB 0 VOI_CNT at cursor position
DSP_NXTF FCB 0 >0 when DSP_NXT updated

*pointers and counters at display position + 1
DSP_NXT RMB 16,0
CNT_NXT RMB 8,0
VOI_NXT FCB 0
MEA_NXT FDB 0
BNUM_NXT FDB 0

*GET_SMAL - find smallest note counter (CNT_CURS)
*EXIT: A=smallest note counter
* B=0 if at end of music (all counters=0)
* all counters decremented by A (smallest counter)
* BAR_NUM and MEA_CNT also updated
*
GET_SMAL PSHS X
 JSR FINDSMA
 PSHS D
 TSTB  at end of music?
 BEQ C@
 LDX #CNT_CURS
A@ LDA ,X+ get counter
 BEQ B@ skip if =0
 SUBA ,S subtract smallest
 STA -1,X
B@ CMPX #CNT_CURS+8
 BNE A@
 CLR ,-S change to 16 bit value
 LDD MEA_CNT
 BNE D@
 LDD MEASURE
 PSHS D
 LDD BAR_NUM
 ADDD #1
 STD BAR_NUM
 PULS D
D@ SUBD ,S+
 STD MEA_CNT
C@ PULS D,X,PC

*FINDSMA - find smallest counter (CNT_CURS) <>0
*EXIT: A=smallest counter, B=0 when all voices at end of code
*
FINDSMA PSHS X
 LDX #CNT_CURS
 LDD #$FF08 smallest counter
 PSHS A put on stack
A@ LDA ,X+ find smallest counter
 BNE B@
 DECB  update counter of voices
 BRA C@ at end of music
B@ CMPA ,S
 BHI C@
 STA ,S save it on stack
C@ CMPX #CNT_CURS+8
 BNE A@
 PULS A,X,PC

CNVNFRA PSHS D,X
 LDX #NOTFRACM now convert ASCII numbers
 LDY #NOTEFRAC to binary
 LDB #8 voice counter
A@ LDA #56
 SUBA ,X
 STA ,Y+
 LEAX 4,X
 DECB
 BNE A@
 PULS D,X,PC

NOTEFRAC FCB 0,0,0,0 note fractions to be
 FCB 0,0,0,0 subtracted from whole

SHARP FCB 0 >0 if note to be sharped
FLAT FCB 0 >0 if note to be flatted

MEASURE FDB 192 measure length

CLRCNT LDX #CNT_STRT clear out counters
 LDY #VOI_CNT
 LDB #8 voice counter
 PSHS B
 CLRA
 CLRB
C@ STB ,X+
 STD ,Y++
 DEC ,S
 BNE C@
 LEAS 1,S throw away counter
 STD BNUM_ST
 STD MEA_STRT
 PULS D,X,Y,U,PC
@@
* Look for and 'play' all the options in music up
* to current position
*
VOI SET 0
*
PSET_OPT LEAS -1,S room for local variables
 LDY #VOI_PTR
 LDU #DSP_STRT
 LDD ,Y exit if at start
 CMPD ,U of music
 LBEQ Z@
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
Z@ LEAS 1,S
 RTS

*MGETNOTE - MIDI get note and play it
* Handles note on but not note off.
*ENTRY: B=voice number
*EXIT: CNT_CURS updated if note played
* DSP_CURS updated
*Stack offsets:
CURNOT SET 0 current note
PRVNOT SET 2 previous note pitch
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
 LBNE Z@ note not ready to play if >0
 LSLB  convert voice to word offset
 LDX #DSP_CURS
 TST [B,X] check for end of voice
 BNE A@
 LDB VOI,U
 JSR NOTE_OFF
 LBRA Z@
A@ BPL B@ check for options
 LDB VOI,U
 JSR PLAY_OPT
 LDB VOI,U
 BRA C@
B@ LDB VOI,U
 LSLB  word offset
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
 STA PLAYVOIC,PCR
 LDD CURNOT,U
 JSR CNV_COMI
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
 JSR NOTE_ON
Z@ LEAS 3,S
 PULS D,X,Y,U,PC

TIENEXT RMB 8,0 >0=nxt note tied, note off afcted
TIEFLAG RMB 8,0 >0 = note tied, affects note on

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
 LBEQ PLAYINST  option
 CMPA #TEMPOPT test for tempo option
 LBEQ PLAYTEMP
 CMPA #BYTEOPT
 LBEQ PLAYBYTE
 CMPA #OCTVOPT
 LBEQ PLAYOCTV
 CMPA #LOCOOPT
 LBEQ PLAYLOCO
 CMPA #VOL_OPT
 LBEQ PLAY_VOL
 CMPA #CLK_OPT
 LBEQ PLAY_CLK
Z@ LEAS 3,S
 PULS D,X,Y,PC
PLAY_VOL LDB FILTER
 BITB #VOL_FL
 LBNE Z@
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
PLAYBYTE LDB FILTER,PCR
 BITB #BYTE_FL
 BNE Z@
 LDA NOT+1,S get byte to send
 LBSR SENDMIDI
 BRA Z@
PLAYTEMP LDB NOT+1,S get tempo into B
 STB MTEMPO,PCR
 BRA Z@
PLAYINST LDB FILTER,PCR
 BITB #INST_FL
 BNE Z@
 LDX #MIDICHAN
 LDB VOI,S
 LDA B,X get channel number
 ORA #$C0
 JSR MIDI_OUT
 LDA NOT,S
 ANDA #$0F get instrument number
 LDX #MIDINSTB get program number
 LDA A,X
 JSR MIDI_OUT
 LBRA Z@
 MSG "PLAYEVNT=",*
PLAYEVNT LDB FILTER,PCR
 BITB #EVNT_FL
 LBNE Z@
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
 LBSR MIDI_OUT
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
Z@ PULS D,X,PC

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
MIDISTAT FCB 0 current status byte

*SENDMIDI - outputs bytes to MIDI
* (CoCo MIDI and serial port)
*ENTRY: byte to send in A
*
SENDMIDI PSHS D
 LDB #2 check for empty
A@ BITB [CMSTAT] transmit buffer
 BEQ A@
 STA [CMDATA] output to CoCo MIDI
 LDB #8 bit counter for
 PSHS B serial port
 LDB $FF20
 ANDB #$FD
 STB $FF20 send start bit
 CMPX [255,X] kill 13 cycles
B@ LSRA  prepare to send bit
 BCC C@
 ORB #2
 BRA D@
C@ ANDB #$FD
 NOP
D@ STB $FF20
 CMPD #0 kill 5 cycles
 DEC 0,S decrement bit counter
 BNE B@
 CMPD $FF00 kill 8 cycles
 ORB #2
 STB $FF20 send stop bit
 PULS B
Z@ LDA #$20 small delay
F@ DECA
 BNE F@
 PULS D,PC

MBUF_PTR FDB 0 ptr. to current pos. in BUFFER

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
*first subtract/add octaves until we reach top octave
 LDA #96 MIDI pitch of code=1
 PSHS B save music code pitch
 ANDB #$3F discard upper 2 bits
A@ CMPB #8
 BLO B@
 SUBB #7 subtract one octave
 SUBA #12 add MIDI octave
 BRA A@
*now add scale offset to obtain MIDI pitch
B@ DECB
 LEAX a@,PCR
 LDB B,X get note offset
 PSHS B
 SUBA ,S+
 ADDA TRANOFFS,PCR add transpose offset
 LEAX OCTVTABL,PCR
 LDB PLAYVOIC,PCR add octave up/down
 ADDA B,X
 PULS B restore music code pitch
 BITB #FLATBIT
 BEQ E@
 DECA
E@ BITB #SHARPBIT
 BEQ F@
 INCA
F@ TFR A,B
 PULS A restore note length
Z@ PULS X,Y,PC
a@ FCB 0,1,3,5 note offsets for scale
 FCB 7,8,10 of C (reverse)

*MIDIDELA - delay for MIDI play,
* handles note off.
*ENTRY: A=note length
* also MASTEMP and TEMPO must be set up
*
CLOCK FCB 2 counter for MIDI clock
CLOCKFL FCB 0 >0 if clock enabled
CONTFL FCB 0 >0 if play restart is "CONTINUE"
*
MIDIDELA PSHS D,X,Y,U
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
 JSR NOTE_OFF
E@ INCB
 CMPB #8
 BNE D@
 JSR MIDFLUSH
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
 JSR SENDMIDI
 PULS A
 BRA H@
F@ LDB #13
G@ DECB
 BNE G@
 ORCC #0
H@ DECA
 BNE A@
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
 LDA FILTER,PCR
 BITA #CHAN_FL
 BEQ C@
 CLRA
 BRA B@
C@ LDX #MIDICHAN get MIDI channel #
 LDA B,X
B@ ORA #$90
 LDB ,S
 LBSR CHKNTON
 TSTA
 BEQ Z@
 STA ,Y+ put first in MIDILNOT
 JSR MIDI_OUT send it
 LDA ,S restore note pitch
 STA ,Y save note pitch
 JSR MIDI_OUT send note pitch
 LDX #MIDIVELO get velocity
 LDB 1,S get voice #
 LDA B,X
 JSR MIDI_OUT send it
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
 CLRA
 LDA ,X+
 JSR MIDI_OUT
 LDA ,X
 JSR MIDI_OUT
 CLRA  velocity of 0 = note off
 JSR MIDI_OUT
Z@ PULS D,X,Y,PC

*ALL_OFF - send MIDI note off message for each channel
*
ALL_OFF PSHS B
 LDB #0 voice counter
A@ JSR NOTE_OFF
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
 LEAS -2,S
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
 LEAS 2,S
 PULS D,PC
*
C@ LDA #32 short delay routine
D@ DECA
 BNE D@
 RTS

MTEMPO FCB 40 MIDI tempo
TRANOFFS FCB 0 transpose offset
OCTVTABL RMB 8,0 octave up/down offsets
MIDILNOT RMB 16,0 last note pitch played
PLAYVOIC FCB 0 voice being played
MIDIVELO RMB 8,64

SCALE FCB 0,2,3,5 half step offsets from note A
 FCB 7,8,10

*PLAY - play music in MUSICA II style
*
TVPLAY JMP [MUSTART]
PLAY1 LDA #3
 STA $FF20
 LDX #$FF00 turn on tv sound port
 LDA 1,X
 ANDA #$F7
 STA 1,X
 LDA 3,X
 ANDA #$F7
 STA 3,X
 LDA #$3C
 STA $23,X
 LDX #LNOTES
 LBSR SETUPLP
 CLR $FF02 prepare for fast keyboard read
 LDD TEMPO
 LDA #3
 MUL
 LSRA
 RORB
A@ STD MU2TEMPO
L@ LBSR GETLCHRD
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
B@ LDX #$FF00 turn off sound port.
 LDA #$34
 STA $23,X
 LDA #8
 ORA 1,X
 STA 1,X
 LDA #8
 ORA 3,X
 STA 3,X
 LDA #3
 STA $20,X
 RTS

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
CHRDLEN FCB 0 length of chord
LNOTSIZ EQU 5
LNOTES RMB LNOTSIZ*8,0 notes: pointer,count,pitch
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
 LDX LPTR,S get first pointer
A@ TST 2,X test note count
 BNE D@
 LDY 0,X get Lyra pointer
B@ LDD ,Y++ get music code
 BMI B@ skip option codes
 BEQ C@ if at end of code,
 STY 0,X dont update pointer
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
 LDA #$FF smallest count
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
 BEQ A@
 NEGB
 ADDB #88 88=MIDI pitch for E5
 LDX #12 get X=octave, D=note of table
 JSR DIVIDE
 LDY #PITCH
 LSLB
 LDD D,Y get top octave pitch
B@ CMPX #0 lower pitch 1 octave
 BEQ A@ for every count in X
 LEAX -1,X
 LSRA
 RORB
 BRA B@
A@ PULS X,Y,PC

*PITCH - conversion table for MUSICA II pitches
*
PITCH FDB 23305
 FDB 21889
 FDB 20659
 FDB 19499
 FDB 18406
 FDB 17371
 FDB 16398
 FDB 15476
 FDB 14608
 FDB 13788
 FDB 13014
 FDB 12283

