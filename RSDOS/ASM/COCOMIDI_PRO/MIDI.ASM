; MIDI/TXT
; the MIDI play and record routines for CMP
; (C) 1990 by Lester Hands

%include "macros.h"
%include "cmp.h"

        EXTERN ARG1,ARG2,ARG3,BAR,BAR_CNT,BEAT_CNT,BELL,BINDEC
        EXTERN BLK_END,BLK_STRT,BOXINP,CHKFILT,MASTER_CPERIOD
        EXTERN CHROUT,CLOCK,CLOCKSLV,CLOCK_FLAG,CLRBOX,CLS,ConvertAsciiTime
        EXTERN CPCOUNT,CPCSLAVE,CPERIOD,DIVIDE,DONE,DSPMESSG,FILT_FLG
        EXTERN GETCHAR,GOTO,INKEY,IRQACTIV,KEYINP,LINKPTR,LOADLINK
        EXTERN MBUFPTR,MCOUNT,MDATA,MERGEBUFFERS,METCOUNT,METRONOM,MIDISTAT
		EXTERN MPI3,MPI4,MSTAT,MSTATUS,NEWIRQ,PLAYPTR,PLNTBUFE,PLNTBUFR
        EXTERN PNCH_FLG,POSNFLAG,PUTS,RECPTR,SETBOX,SLAVE,SNGPOSPT
        EXTERN SPP_FL,STOP,SYNCFLAG,TFLAGS,TICKS,TICKSLAV,TIMEBASE
        EXTERN TRACK,TVON,WAIT,REMAIN,DivideExTime,PlaySyx,XPOS,YPOS
        extern NextAbsEvent,PrevAbsEvent,EX_TIME1,EX_TIME2,MakeNoteOff
        extern Move,MultExTime
        extern METRONOME_PITCH,METRONOME_CHANNEL,METRONOME_VELOCITY

SIMULTANEOUS_NOTES_MAX fcb 0

; macro for outputting MIDI data in register A
; used only in situations where speed is critical
;
MOUT    %MACRO
        %GENSYM ma,mb
        TSTA            ;check for a status byte
        BPL ma
        CMPA #$F8
        bhs ma
        CMPA MIDISTAT
        BEQ mb
        STA MIDISTAT
ma      LDB [MSTAT]     ;make sure ACIA
        BITB #2         ;is ready to accept data
        BEQ ma
        STA [MDATA]
mb
        %ENDM

; set PIAs for the high speed IRQ (HSYNC)
;
        global SetHIRQ
SetHIRQ proc
;        LDA #$34
;        STA $FF03
;        INCA
;        STA $FF01
        lda $ff01            ;disable PIA interrupts
        anda #$fe
        sta $ff01
        lda $ff03
        anda #$fe
        sta $ff03
        lda #$20             ;select GIME clock (and task #0)
        sta $ff91
        lda #$20             ;select GIME timer IRQ interrupt
        sta $ff92
        ldd #250             ;set timer interrupt period
        std $ff94
        RTS
        endproc

; ask for starting time for play or record
; return -1 if error else extended time is in EX_TIME1
;
StartAtTime PROC
        PSHS X
        clr EX_TIME1
        clra
        clrb
        std EX_TIME1+1
        tst SLAVE            ;don't ask for time if in slave mode
        bne ..Z
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        BEQ ..X
; make sure user has not entered a tick (:xx) value
; since playback must start on a whole beat
        LDX #..cc
..B     LDA ,X+
        BEQ ..C
        CMPA #':'
        BNE ..B
        LDA #32              ;pad from : to end
..E     STA -1,X             ;of string with spaces
        TST ,X+
        BNE ..E
..C     CALL ConvertAsciiTime,#..cc,#EX_TIME1
        clra
        clrb
        BRA ..Z
..X     LDD #-1
..Z     PULS X,PC
;
..aa    FDB 6,5,20,5,$+12,..bb
        FDB 2,2,$+8,0
        FCC "START AT:"
        FCB 0
..bb    FDB 12,2,$+10,0,0
..cc    FCC "1/1   "
        FCB 0
        ENDPROC

        global PLAY
PLAY PROC
        LBSR StartAtTime
        CMPD #-1
        BEQ ..Z
..D     CLRA
        CLRB
        STD LINKPTR
..A     LDB #1               ;disable the filter
        STB FILT_FLG
        call GoTo,#EX_TIME1
        STD ARG1
        CALL _Play,ARG1,#EX_TIME1
;;;        LBSR WAIT            ;wait for key off
        CLR FILT_FLG         ;enable filter
        LDD LINKPTR
        BEQ ..Z
        CALL LoadLink,LINKPTR
        CMPD #$FFFF          ;check for error
        beq ..Z
        clra
        clrb
        std EX_TIME1
        clr EX_TIME1+2
        bra ..D
..Z     CLRA
        CLRB
        rts
        ENDPROC

; Play recorded MIDI data until keypress or end of recording.
; Data in BUFFER1 is played and it is assumed that S_MPTR and BUFFER1_BLOCK
; correctly point to the first event.
; The extended time at which to start playing is pointed to by s_extime.
; Returns address of current event in register D.
;
        global _Play
_Play PROC
        localvar L_POS
        char l_extime,3
        stackvar S_MPTR,s_extime
;
        lbsr ChkSOLO
        call SendSPP,<s_extime,s>
        lbsr WAIT
        ldx s_extime,s
        LDD 0,x
        STD CLOCK       ;reset clock
        STD CLOCKslv
        lda 2,x
        sta CLOCK+2
        sta CLOCKslv+2
        ldd MASTER_CPERIOD
        std CPERIOD
        CLR MIDISTAT
        LDD S_MPTR,S    ;reset buffer pointer
        STD PLAYPTR
        LDA #$FF
        STA DONE
        CLR STOP
        LDA #1
        STA SYNCFLAG
        LBSR ClrPNB
        ORCC #$50       ;disable interrupts
        TST SLAVE
        BNE ..E
        LDX #IRQmast
        LDY #FIRQmast
        BRA ..O
..E     LDX #IRQslave
        LDY #FIRQslav
..O     STX IRQ_VECTOR+1 ;set up new IRQ vector
        STY FIRQ_VECTOR+1
        LBSR SetHIRQ
        LDD #1
        STD CPCOUNT
        STB METCOUNT
        clr TICKS
        clr SIMULTANEOUS_NOTES_MAX
        CLR IRQACTIV
        LBSR TVON
        CLR $FF02       ;prepare for fast keyboard read
        TST SLAVE
        BEQ ..J
        LDX #PLAYBOXS
        BRA ..K
..J     LDX #PLAYBOXM
..K     CALL SetBox,REGX
        CALL SetBarBeat,#CLOCK
%if VAL_BURKE eq 1
        lbsr SetTimer
%endif
        sta FAST
        TST SLAVE
        BEQ ..D
        CLR POSNFLAG
        CLR SYNCFLAG
        LDA #3          ;initialize ACIA
        STA [MSTAT]     ;master reset
        LDA #$95        ;set 8 bits, no parity
        STA [MSTAT]     ;enable receiv
        LBSR MPI3       ;enable MPI
        ANDCC #$BF      ;enable FIRQ
..H     LDA $FF00       ;wait until a song pos.
        ANDA #$7F       ;ptr. or start signal
        CMPA #$7F       ;has been received.
        BNE ..done
        TST POSNFLAG
        BEQ ..H
        CALL GoTo,#SNGPOSPT
        STD PLAYPTR
        CALL SetBarBeat,#SNGPOSPT
        INC SYNCFLAG
..D     ANDCC #$AF      ;enable interrupts
..loop  TST STOP
        BNE ..done
        lda $ff00
        ANDA #$7F
        CMPA #$7F
        BNE ..done
        TST DONE        ;check for end of recording
        BNE ..loop
; all done playing
..done  lbsr MIDI_Off
        LBSR ClrBox
        andcc #$ef      ;enable IRQ
        LDD PLAYPTR
        ENDS
        ENDPROC

MIDI_Off proc
		clr $ff92            ;disable GIME interrupts
		LBSR MPI4			 ;enable disk ROM
		LDA #$15             ;disable CMI interrupts
		STA [MSTAT]
		ORCC #$50            ;disable interrupts
		LDD #NEWIRQ
		STD IRQ_VECTOR+1
		LDA #$34             ;enable 60 hz PIA interrupt
		STA $FF01
		INCA
		STA $FF03
		LBSR ALLOFF
		LBSR ChkSOLO
		TST SLAVE
		BEQ ..a
		LDA #1
		STA SLAVE
		STA SYNCFLAG
..a     rts
		endproc

PLAYBOXS PROC
        FDB 6,5,20,9,$+12,0
        FDB 5,2,..cc,$+8
        FDB 7,4,..ee,$+8
        FDB 3,7,..dd,0
..cc    FCC "PLAYING..."
        FCB 0
..ee    FCC "001/01"
        FCB 0
..dd    FCC "AS:  CL:  IN:"
        FCB 0
        ENDPROC

RECORDBOXS PROC
        FDB 6,5,20,9,$+12,0
        FDB 5,2,..cc,$+8
        FDB 7,4,..dd,$+8
        fdb 8,6,..ee,$+8
        FDB 3,7,..ff,0
..cc    FCC "RECORD ON"
        FCB 0
..dd    FCC "001/01"
        FCB 0
..ee    fcc "16384"
        fcb 0
..ff    FCC "AS:  CL:  IN:"
        FCB 0
        ENDPROC

PLAYBOXM PROC
        FDB 6,5,20,7,$+12,0
        FDB 5,2,..bb,$+8
        FDB 7,4,..cc,0
..bb    FCC "PLAYING..."
        FCB 0
..cc    FCC "001/01"
        FCB 0
        ENDPROC

RECORDBOXM PROC
        FDB 6,5,20,8,$+12,0
        FDB 5,2,..bb,$+8
        FDB 7,4,..cc,$+8
        fdb 8,6,..dd,0
..bb    FCC "RECORD ON"
        FCB 0
..cc    FCC "001/01"
        FCB 0
..dd    fcc "16384"
        fcb 0
        ENDPROC

; check the SOLO bit of the TFLAGS
; if one is set, then flip all top 2 bits
;
ChkSOLO PROC
        PSHS X
        LDX #TFLAGS
        LDB #16              ;number of tracks
..A     LDA ,X+
        BITA #$40            ;check SOLO bit
        BNE ..B
        DECB
        BNE ..A
        PULS X,PC
..B     LDX #TFLAGS
        LDB #16              ;number of tracks
        PSHS B
..C     LDA ,X
        LSLA                 ;flip top 2 bits
        RORB
        LSLA
        RORB
        ANDB #$C0
        PSHS B
        LDA ,X
        ANDA #$3F
        ORA ,S+
        STA ,X+
        DEC ,S
        BNE ..C
        PULS B,X,PC
        ENDPROC

; FIRQ routine that is called when the ACIA
; receives a MIDI byte (slave version)
;
        global FIRQslav
FIRQslav PROC
        PSHS D
        LDA [MDATA]          ;get MIDI byte
; check for clock message
        CMPA #$F8            ;clock?
        BNE ..B
        COM $0591            ;Y=12, X=17 on screen
        TST SLAVE            ;ignore clock if start
        LBPL ..Z             ;or cont. not yet received
        LDD CLOCKslv+1
        addd #TICKS_PER_BEAT/24
        std CLOCKslv+1
        std CLOCK+1
        BCC ..A
        lda CLOCKslv
        adda #$10
        sta CLOCKslv
        sta CLOCK
..A     LDD CPCslave         ;convert ints/clock to ints/tick
        pshs x
        ldx #0
..a1    subd #100            ;divide by 10 (TICKS_PER_BEAT/24)
        bcs ..a2
        leax 10,x
        bra ..a1
..a2    addd #100
..a3    subd #10
        bcs ..a4
        leax 1,x
        bra ..a3
..a4    stx CPERIOD
        puls x
        LDD #1
        STD CPCOUNT
        STB TICKslav
        CLRB
        STD CPCslave
        LBRA ..Z
; process A0-EF events
..B     CMPA #$F0
        BHS ..D
        COM $0596            ;Y=12, X=22 on screen
        TST SLAVE
        LBPL ..Z             ;no input until started
..C     STA [MBUFPTR]
        INC MBUFPTR+1
        LBRA ..Z
; check for song position pointer message
..D     CMPA #$F2
        BNE ..F
        LDB #2
..E     LDA [MSTAT]          ;wait for next two bytes
        BITA #1
        BEQ ..E
        LDA [MDATA]
        PSHS A
        DECB
        BNE ..E
        PULS D
        LSLB                 ;convert two 7 bit bytes to 16 bit word
        LSRA
        RORB
        std SNGPOSPT+1
        clr SNGPOSPT
        call MultExTime,#SNGPOSPT,#6*(TICKS_PER_BEAT/24)
        INC POSNFLAG
        BRA ..Z
..F     CMPA #$F8
        BLO ..C
; check for start clock message
        CMPA #$FA            ;start?
        BNE ..G
        INC POSNFLAG
        clr CLOCK
        clr CLOCKslv
        CLRA
        CLRB
        clr SNGPOSPT
        std SNGPOSPT+1
        STD CLOCK+1
        STD CLOCKslv+1
        LDA #$80             ;set slave flag to
        STA SLAVE            ;indicate ready to play
        BRA ..Z
; check for continue clock message
..G     CMPA #$FB            ;continue?
        BNE ..I
        lda SNGPOSPT
        sta CLOCK
        sta CLOCKslv
        LDD SNGPOSPT+1
        STD CLOCK+1
        STD CLOCKslv+1
        LDA #$80             ;set slave flag to
        STA SLAVE            ;indicate ready to play
        BRA ..Z
; check for stop clock message
..I     CMPA #$FC
        BNE ..J
        TST SLAVE            ;ignore if not started
        BPL ..Z
        LDA #1
        STA STOP
        STA SLAVE
; check for active sensing
..J     CMPA #$FE
        BNE ..Z
        COM $058C            ;Y=12, X=12 on screen
..Z     TST $FF22            ;acknowlege interrupt
        clr $ff93            ;disable cartridge FIRQ
        lda #1               ;enable cartridge FIRQ
        sta $ff93
        PULS D
        RTI
        ENDPROC

%if VAL_BURKE eq 1
SetTimer proc
        ldd #'00'
        std $4a8
        std $4ab
        lda #':'
        sta $4aa
        lda #' '
        sta $4a7
        sta $4ad
        rts
        endproc
%endif

; FIRQ routine that is called when the ACIA
; receives a MIDI byte (master version)
;
        global FIRQmast
FIRQmast PROC
        PSHS A
        LDA [MSTAT]          ;check for errors
        ANDA #$24
        BNE ..Z
        LDA [MDATA]          ;get MIDI byte
        CMPA #$F8            ;ignore all real time
        BHS ..Z              ;messages
        STA [MBUFPTR]
        INC MBUFPTR+1
..Z     clr $ff93            ;disable cartridge FIRQ
        lda #1               ;enable cartridge FIRQ
        sta $ff93
        PULS A
        TST $FF22            ;acknowlege interrupt
        RTI
        ENDPROC

        global IRQslave
IRQslave PROC
        tst SLAVE
        lbpl ..Z
        INC CPCslave+1
        BNE IRQmast
        INC CPCslave
; Timing interrupt.
; Keeps track of the MIDI clock and system clock.
; The first part is re-entrant, allowing timing
; to be updated and music to be played simultaneously.
; The non-reentrant part plays music. It is assumed that playback is
; from BUFFER1 and BUFFER1_BLOCK, and that PLAYPTR points to it and
; BUFFER1_BLOCK is already set.
;
; Update the CPCOUNT: this is the number of HSYNC
; interrupts needed to make 1 system "tick"
        global IRQmast
IRQmast
%if VAL_BURKE equ 1
        ldd ..ticks
        subd #1
        std ..ticks
        bne ..noclk
        ldd #15686
        std ..ticks
        inc $4ac
        lda $4ac
        cmpa #'9'+1
        blo ..noclk
        lda #'0'
        sta $4ac
        inc $4ab
        lda $4ab
        cmpa #'6'
        blo ..noclk
        lda #'0'
        sta $4ab
        inc $4a9
        lda $4a9
        cmpa #'9'+1
        blo ..noclk
        lda #'0'
        sta $4a9
        inc $4a8
        bra ..noclk
..ticks fdb 15686
..noclk
%endif
        LDD CPCOUNT
        SUBD #1
        BEQ ..M
        STD CPCOUNT
..Z     LDA $FF00
        STA KEYINP
        lda $ff92            ;acknowlege interrupt
        RTI
; We're ready to increment the main CLOCK
..M     LDD CPERIOD
        STD CPCOUNT
        INC CLOCK+2
        BNE ..V
        INC CLOCK+1
        BNE ..V
        lda CLOCK            ;keep track of extended time
        adda #$10
        sta CLOCK
..V     INC TICKS
        TST IRQACTIV
        BNE ..Z
; start of non-reentrant part of interrupt
        INC IRQACTIV
        ANDCC #$EF           ;enable IRQ
; check if we're ready for a MIDI clock
..L     TST SLAVE
        BEQ ..Y
        TST TICKslav
        LBEQ ..J
        CLR TICKslav
        BRA ..K
..Y     LDA TICKS
        suba #TICKS_PER_BEAT/24
        lblo ..J
        STA TICKS
        TST CLOCK_FLAG
        BEQ ..K
        LDA #$F8
        lbsr MIDI_OUT
; if a MIDI clock was sent, see if metronome
; should be clicked (24 MIDI clocks/beat)
..K     DEC METCOUNT
        BNE ..L
; update the bar/beat display every beat
; this routine works directly with data on the screen
; to save time
        LDX #$052D           ;Y=9, X=13 on screen
        LDA BEAT_CNT
        inca
        CMPA BAR
        BHI ..cc
        STA BEAT_CNT
        LDD 4,X
        INCB
        CMPB #$7A
        BLO ..bb
        LDB #$70
        INCA
..bb    STD 4,X
        BRA ..ee
..cc    LDD #$7071           ;beat overflow
        STD 4,X              ;set beat # to 01
        LDD 1,X              ;increment bar #
        INCB
        CMPB #$7A
        BNE ..dd
        LDB #$70
        INCA
        CMPA #$7A
        BNE ..dd
        LDA #$70
        INC ,X
..dd    STD 1,X
        LDA #1
        STA BEAT_CNT
; make the click for the metronome
..ee    tst METRONOME_PITCH
        beq ..ff
        lda METRONOME_CHANNEL
        lbsr MIDI_OUT
        lda METRONOME_PITCH
        lbsr MIDI_OUT
        lda METRONOME_VELOCITY
        lbsr MIDI_OUT
        bra ..gg
..ff    LDA ..aa
        ORA #3
        STA $FF20
        COM ..aa
..gg    LDA METRONOM
        STA METCOUNT
        LBRA ..L
; now do the actual work of playing music
..J     TST SYNCFLAG         ;abort if the sync
        BNE ..T              ;flag is clear (slave
        CLR IRQACTIV         ;mode, waiting for
        LBRA ..Z             ;synchronization)
; go through the storage area, compare times
; when time matches current, send note off
..T     ldd [PLAYPTR]
        cmpd #$ffff
        bne ..T1
        clra
        bra ..T2
..T1    lda #1
..T2    sta DONE
        LDX #PLNTBUFR
        clr ..sncnt          ;clear simultaneous note counter
..G     tst 3,x              ;skip if empty
        beq ..H
        inc ..sncnt
        inc DONE
        lda 0,x              ;check extended time
        cmpa CLOCK
        bhi ..H
        blo ..g1
        ldd 1,x
        cmpd CLOCK+1
        bhi ..H
..g1    lda 3,x              ;get status byte
        lbsr MIDI_OUT
        lda 4,X              ;get pitch
        lbsr MIDI_OUT
        clra                 ;zero velocity
        lbsr MIDI_OUT
        clr 3,X              ;release for next note
..H     leax 5,x             ;move to next one
        cmpx #PLNTBUFE       ;at the end yet?
        blo ..G
; the next section updates the simultaneous note counter
;        ldb ..sncnt
;        cmpb SIMULTANEOUS_NOTES_MAX
;        blo ..h1
;        stb SIMULTANEOUS_NOTES_MAX
;        clra
;        inca
;        subb #10
;        bcc ..h1
;        adda #'0'-1
;        addb #'0'+10
;        std $41e
; now examine the current event to be played
; and see if the time is right
..h1    ldx PLAYPTR
..A     tst DONE
        beq ..E
        ldd 0,x              ;get event clock
        cmpd #$FFFF
        bne ..B              ;check for end
;;;        clr DONE
..E     stx PLAYPTR          ;update pointer
        clr IRQACTIV
        lbra ..Z
..B     lda 7,x              ;check extended time
        anda #$f0
        cmpa CLOCK
        bhi ..E
        blo ..b1
        ldd 0,x
        cmpd CLOCK+1         ;compare with actual clock
        bhi ..E
; check mute flags before trying to play anything
..b1    lda 7,x              ;get track #
        anda #$0f            ;ignore extended time info
        ldu #TFLAGS          ;check for mute flag
        tst a,u
        lbpl ..D
; play first two MIDI bytes (minimum number)
; if not a system event
        lda 2,x              ;get first byte
        cmpa #$F0            ;check for system event
        lbhs ..C
        cmpa #$90            ;if this is a note off event, don't play it!
        lblo ..D
        lbsr MIDI_OUT
        lda 3,x              ;get second byte
        lbsr MIDI_OUT
; process notes if present
        lda 2,x
        cmpa #$9F
        bhi ..O
        lda 4,x              ;get velocity
        lbsr MIDI_OUT
        ldu #PLNTBUFR
..F     tst 3,u              ;look for a place
        beq ..I              ;in storage area
        leau 5,u
        cmpu #PLNTBUFE
        blo ..F
        inc $05FF            ;indicate overflow
        bra ..D
..I     ldd 2,x              ;get status and pitch
        std 3,u
        ldd 5,x              ;get note length
        addd 0,x             ;convert to time of
        std 1,u              ;note off, save it
        lda 7,x
        anda #$f0
        bcc ..I2
        adda #$10
..I2    sta 0,u
        bra ..D
; now process A0-EF events
..O     CMPA #$C0            ;see how many bytes follow
        BLO ..Q              ;program change and
        CMPA #$E0            ;channel pressure use
        BLO ..D              ;only 2 bytes
..Q     LDA 4,X
        lbsr MIDI_OUT
; advance pointer to next event and loop back
..D     leax EVNSIZE,x
        cmpx #BUF1ADR+$2000
        lblo ..A
        ldx #BUF1ADR
        inc BUFFER1_BLOCK
        LBRA ..A
; process system events
..C     anda #$0f
        cmpa #MAXSYS
        bhi ..D
        lsla
        ldy #..aa1
        jsr [a,y]
        bra ..D
..aa    FCB 0                ;Metronome click flag
;
..aa1   fdb PlayTEMPO,PlayCLOCK,PlayLINK,PlayMESSG
        fdb PlayPAUS,PlayBYTE,PlaySyx
%if GOTO_VERSION eq 1
        fdb PlayGOTO
%endif
..sncnt fcb 0
        ENDPROC

PlayTEMPO proc
        TST SLAVE
        BNE ..P
        LDD 5,x
        STD CPERIOD
        LDD #1
        STD CPCOUNT
..P     rts
        endproc

PlayCLOCK proc
        TST SLAVE
        BNE ..W
        LDB 4,X
        STB CLOCK_FLAG
        BEQ ..R
        LDA #$FB             ;continue
        BRA ..S
..R     LDA #$FC             ;stop
..S     lbsr MIDI_OUT
..W     rts
        endproc

PlayLINK proc
        STX LINKPTR
        CLR DONE
        rts
        endproc

PlayMESSG proc
        lda XPOS
        ldb YPOS
        pshs d
        ldd >CURSADR
        PSHS D
        lda #9
        sta XPOS
        lda #8
        sta YPOS
        LBSR DspMESSG
        PULS D
        std >CURSADR
        puls d
        sta XPOS
        stb YPOS
        rts
        endproc

; display the BAR/BEAT on the playbox
; and set up BAR_CNT and BEAT_CNT
;
SetBarBeat PROC
        STACKVAR S_EXT
        ldd #'00'            ;zero out time
        std $0531
        std $052d
        LDX S_EXT,S
        CALL DivideExTime,REGX,TIMEBASE
        STD ARG1
        LDB BAR
        CLRA
        STD ARG2
        CALL Divide,ARG1,ARG2
        addd #1              ;bar # starts at 1
        STD BAR_CNT
        ldd REMAIN           ;remainder=beat
        STB BEAT_CNT
        LDX #$0531           ;Y=9, X=17 on screen
        CMPB #9
        BHI ..A
        LEAX 1,X
..A     LBSR BINDEC
        LDX #$052D           ;Y=9, X=13 on screen
        LDD BAR_CNT
        CMPD #99
        BHI ..B
        LEAX 1,X
        CMPB #9
        BHI ..B
        LEAX 1,X
..B     LBSR BINDEC
        LDX #$052D           ;Y=9, X=13 on screen
        LDB #6
..C     LDA ,X               ;convert ascii to display letters
        ORA #$40             ;on the screen.
        STA ,X+
        DECB
        BNE ..C
        LDA #'/'+$40
        STA -3,X
        LDA #$60
        STA ,X
        ENDS
        ENDPROC

%if GOTO_VERSION eq 1
        global PlayGOTO
PlayGOTO proc
        pshs cc
        tst SLAVE
        bne ..Z
        orcc #$50
        lbsr ALLOFF
        lbsr ClrPNB
        LDD 3,x
        STD CLOCK       ;reset clock
        lda 5,x
        sta CLOCK+2
        leax 3,x
        call GoTo,REGX
        std PLAYPTR
        CALL SetBarBeat,#CLOCK
;        call SendSPP,#CLOCK
        ldx PLAYPTR
..Z     puls cc,pc
        endproc
%endif

        global PlayBYTE
PlayBYTE PROC
        PSHS X
        LEAX 3,X
        LDB #4
..A     LDA ,X+
        CMPA #$FF
        BEQ ..Z
        LBSR MIDI_OUT
        DECB
        BNE ..A
..Z     PULS X,PC
        ENDPROC

        global PlayPAUS
PlayPAUS PROC
        PSHS X,CC
        TST SLAVE
        BNE ..Z
        ORCC #$50            ;disable interrupts
        LDD >CURSADR
        PSHS D
        LDD #SCRNWIDE*8+8+$400
        STD >CURSADR
        LEAX ..aa,PCR
        LBSR PUTS
        LBSR getchar
        LBSR WAIT
        LDD #SCRNWIDE*8+8+$400
        STD >CURSADR
        LEAX ..bb,PCR
        LBSR PUTS
        PULS D
        STD >CURSADR
        LDA #$95             ;set 8 bits, no parity
        STA [MSTAT]          ;enable receiv
..Z     PULS X,CC,PC
;
..aa    FCC "PAUSED-TAP A KEY"
        FCB 0
..bb    FCC "                "
        FCB 0
        ENDPROC

; clear the play note buffer
;
ClrPNB PROC
        PSHS X
        LDX #PLNTBUFR
..A     CLR ,X+
        CMPX #PLNTBUFE
        BLO ..A
        PULS X,PC
        ENDPROC

; output to MIDI the byte in A
;
        global MIDI_OUT
MIDI_OUT PSHS B
        MOUT
        PULS B,PC

        extern TRAK_FLG
        global RECORD
RECORD PROC
        lda FILT_FLG
        ldb TRAK_FLG
        pshs d
        LBSR StartAtTime
        CMPD #-1
        BEQ ..Z
        LDB #1               ;disable the filter
        STB FILT_FLG
        CALL GoTo,#EX_TIME1
        STD ARG1
        CALL _Record,ARG1,#EX_TIME1
        CLR FILT_FLG
..Z     puls d
        sta FILT_FLG
        stb TRAK_FLG
        rts
        ENDPROC

; record MIDI data until keypress
; S_PTR is a pointer to BUFFER1
; S_EXT is a pointer to an extended time starting for recording
;
        global _Record
_Record PROC
        localvar L_ABRT,l_pos
        char l_extime,3
        stackvar S_PTR,S_EXT
        lda XPOS
        ldb YPOS
        std l_pos,s
; send a song position pointer message if the clock is enabled
        ldx S_EXT,s
        ldd ,x
        std l_extime,s
        lda 2,x
        sta 2+l_extime,s
        leax l_extime,s
        call SendSPP,REGX
; ask user if punch in/out is desired if block markers are set
        clr PNCH_FLG
        ldd BLK_END+1
        cmpd #$FFFF
        beq ..set_clock
        CALL SetBox,#..ee
        lbsr getchar
        lbsr ClrBox
        cmpa #3
        lbeq ..O
        cmpa #'Y'
        bne ..set_clock
        lbsr MakeNoteOff
        inc PNCH_FLG
; set up clock related variables
..set_clock
        lbsr WAIT
        ldy S_EXT,s
        LDD 0,y
        STD CLOCK
        STD CLOCKslv
        lda 2,y
        sta CLOCK+2
        sta CLOCKslv+2
        ldd MASTER_CPERIOD
        std CPERIOD
; set up pointers
        LDX #MIDIBUF
        STX MBUFPTR
        LDD S_PTR,S          ;set play buff
        STD PLAYPTR
        LDY #BUF2ADR         ;zero buffer2
        lda #16
        sta BUFFER2_BLOCK
        LDD #$FFFF
        STD ,Y
        leay -EVNSIZE,y
        STY RECPTR
; set up miscellaneous variables
        lbsr ChkSOLO
        CLR L_ABRT,S
        LBSR ClrPNB
        CLR MIDISTAT
        CLR MCOUNT
        CLR STOP
        LDA #1
        STA SYNCFLAG
        lda #$ff
        sta DONE
        LDA #$90             ;set default status
        STA MSTATUS          ;byte=note on
        LDA #$FF
        STA KEYINP
; set up hardware
        ORCC #$50            ;disable interrupts
        TST SLAVE
        BNE ..H
        LDX #IRQmast         ;set new IRQ vector
        LDY #FIRQmast
        BRA ..T
..H     LDX #IRQslave
        LDY #FIRQslav
..T     STX IRQ_VECTOR+1
        STY FIRQ_VECTOR+1
        LBSR SetHIRQ
        LDD #1
        STD CPCOUNT
        STB METCOUNT
        clr TICKS
        clr SIMULTANEOUS_NOTES_MAX
        CLR IRQACTIV
        LBSR TVON
        LDA #3               ;initialize ACIA
        STA [MSTAT]          ;master reset
        LDA #$95             ;set 8 bits, no parity
        STA [MSTAT]          ;enable receive int.
        LBSR MPI3            ;enable MPI
        CLR $FF02            ;prepare for fast key read
; put "recording" notice on screen
        TST SLAVE
        BEQ ..Y
        LDX #RECORDBOXS
        BRA ..I
..Y     LDX #RECORDBOXM
..I     CALL SetBox,REGX
        CALL SetBarBeat,#CLOCK
%if VAL_BURKE eq 1
        lbsr SetTimer
%endif
        LBSR ChkPunch
        TST SLAVE
        BEQ ..J
; in slave mode, wait here until we receive a
; position indicator or until a key is pressed
        CLR POSNFLAG
        CLR SYNCFLAG
        ANDCC #$BF           ;enable FIRQ
..R     lda $ff00
;        LDA KEYINP
        ANDA #$7F
        CMPA #$7F
        LBNE ..Z
        TST POSNFLAG
        BEQ ..R
        INC FILT_FLG
        CALL GoTo,#SNGPOSPT
        STD PLAYPTR
        CLR FILT_FLG
        CALL SetBarBeat,#SNGPOSPT
        INC SYNCFLAG
..J     LDX MBUFPTR
        LDY RECPTR
        ANDCC #$AF           ;enable interrupts
; loop to get input from input buffer,
; timestamp it, and put it in the main buffer
; X points to input buffer, Y to the event buffer
..A     TST STOP
        LBNE ..Z
;        LDA KEYINP           ;check for key
        lda $ff00
        ANDA #$7F
        CMPA #$7F
        LBNE ..Z
        LBSR ChkPunch
        CMPX MBUFPTR         ;wait until data
        BEQ ..A              ;is available
; now get data from MIDI buffer
        LDA ,X               ;is this a status byte?
        LBPL ..E
; check for end of system exclusive message
        CMPA #$F2            ;song position ptr?
        BEQ ..X
        CMPA #$F7
        BNE ..U
..X     CLR MSTATUS
        LBRA ..G
; check for start of system exclusive message
..U     STA MSTATUS          ;keep status byte
        CMPA #$F0            ;check for sys excl.
        LBEQ ..G
; now enter an event
..C     TST PNCH_FLG
        BMI ..W
; first update the on-screen event counter
        ldy #$400+(11*32)+19 ;X=19, Y=11 on screen
        ldb #5
..C1    dec ,-y
        lda ,y
        cmpa #$6f
        bhi ..C2
        lda #$79
        sta ,y
        decb
        bne ..C1
; continue with advancing record buffer pointer
..C2    LDY RECPTR
        leay EVNSIZE,y       ;advance to next event
        cmpy #BUF2ADR+$2000
        blo ..a1
        ldy #BUF2ADR
        inc BUFFER2_BLOCK
..a1    lda BUFFER2_BLOCK    ;check for end
        cmpa #32
        BLO ..K
        INC L_ABRT,S
        LBRA ..Z
..K     lda CLOCK            ;merge extended time with track byte
        ora TRACK            ;set track byte
        STA 7,Y              ;previous event
        STY RECPTR
        LDD CLOCK+1
        cmpd #$ffff          ;added to prevent premature end marker
        bne $+3
        decb
        STD ,Y++
        LDA MSTATUS
        STA ,Y+
..W     LDA MSTATUS
        LDB #2               ;determine number of
        CMPA #$C0            ;bytes needed
        BLO ..D
        CMPA #$DF
        BHI ..D
        DECB
..D     STB MCOUNT
        BRA ..G
; byte detected <128; check for system exclusive
..E     LDB MSTATUS
        BEQ ..G
        CMPB #$F0
        BEQ ..G
; check for running status
        TST MCOUNT           ;check for end
        BNE ..F              ;message
        TST MSTATUS
        BEQ ..G
        EXG X,D              ;increment just the
        DECB                 ;LSB of X
        EXG D,X
        LBRA ..C
..F     TST PNCH_FLG
        BMI ..cc
        STA ,Y+
..cc    DEC MCOUNT
; update input buffer pointer (just LSB)
..G     TFR X,D              ;update just LSB
        INCB                 ;so buffer
        TFR D,X              ;will be circular
        LBRA ..A             ;event entry complete; now get next one
; all done; clean up
..Z     lbsr MIDI_Off
        LBSR ClrBox
; display abort message if appropriate
        TST L_ABRT,S
        BEQ ..M
        LBSR Bell
        LEAX ..aa,PCR
        CALL SetBox,REGX
..L     LBSR getchar
        LBSR ClrBox
; ask user if he wants to keep this take
..M     CALL SetBox,#..dd
..N     LBSR INKEY
        CMPA #'Y'
        BEQ ..P
        CMPA #'N'
        BEQ ..O
        BRA ..N
; massage recorded data and merge into main buffer
..P     lbsr ClrBox
        lbsr Working
        LDX RECPTR
        leax EVNSIZE,x
        cmpx #BUF2ADR+$2000
        blo ..P1
        ldx #BUF2ADR
        inc BUFFER2_BLOCK
..P1    LDD #$FFFF           ;end of record
        STD ,X++             ;set end of music
        std ,x++
        std ,x++
        LBSR CheckNoteOff
        LBSR GetNoteLength
        LBSR MergeBuffers
..O     LBSR ClrBox
        ldd l_pos,s
        sta XPOS
        stb YPOS
        lbsr Move
        ANDCC #$EF              ;enable IRQ
        ENDS
;
..aa    FDB 8,5,16,5,$+12,0
        FDB 2,2,$+8,0
        FCC "BUFFER FULL!"
        FCB 0
;
..bb    FCC "RECORD ON "
        FCB 0
;
..dd    FDB 6,5,19,5,$+12,0
        FDB 2,2,$+8,0
        FCC "KEEP THIS TAKE?"
        FCB 0
;
..ee    FDB 7,5,17,5,$+12,0
        FDB 2,2,$+8,0
        FCC "PUNCH IN/OUT?"
        FCB 0
        ENDPROC

; check punch in/out times and change the display
; if necessary
;
ChkPunch PROC
        TST PNCH_FLG
        BNE ..B
        RTS
..B     PSHS X
        LDD CLOCK
        CMPD BLK_STRT
        BLO ..A
        CMPD BLK_END
        BHI ..A
; punch should be "ON"
        TST PNCH_FLG
        BPL ..zz
        LDA #1
        STA PNCH_FLG
        LDD #$04F2      ;Y=7, X=18 on screen
        STD >CURSADR
        LEAX ..aa,PCR
        LBSR PUTS
        BRA ..zz
; punch should be "OFF"
..A     TST PNCH_FLG
        BMI ..zz
        LDA #$81
        STA PNCH_FLG
        LDD #$04F2      ;Y=7, X=18 on screen
        STD >CURSADR
        LEAX ..bb,PCR
        LBSR PUTS
..zz    PULS X,PC
;
..aa    FCC "ON "
        FCB 0
..bb    FCC "OFF"
        FCB 0
        ENDPROC

; convert all note off events ($8X) to note on ($9X) with zero velocity
; in record buffer
;
CheckNoteOff PROC
        pshs x
        LDX #BUF1ADR
        lda #16
        sta BUFFER1_BLOCK
..A     LDD ,X
        CMPD #$FFFF
        BEQ ..Z
        LDA 2,X         ;get status byte
        CMPA #$90       ;note off?
        BHS ..B
        ORA #$90        ;make note on
        STA 2,X
        CLR 4,X         ;zero velocity
..B     lbsr NextAbsEvent
        com WORKING_ALERT_POSITION
        BRA ..A
..Z     puls x,pc
        ENDPROC

; get note lengths and store them in the event buffer
;
GetNoteLength PROC
        localvar L_NOTE
        stackvar
        LDX #BUF1ADR-EVNSIZE
        lda #16
        sta BUFFER1_BLOCK
; first look for a note on event
..A     lbsr NextAbsEvent
        com WORKING_ALERT_POSITION
        LDD ,X               ;check for end
        CMPD #$FFFF
        BEQ ..Z
        LDD 2,X              ;get status byte and pitch
        CMPA #$9F            ;note on?
        BHI ..A
        TST 4,X              ;check velocity
        BEQ ..A
; now find corresponding note off event
        STD L_NOTE,S
        lda BUFFER1_BLOCK
        sta BUFFER2_BLOCK
        leay BUF2ADR-BUF1ADR,x
..B     leay EVNSIZE,y
        com WORKING_ALERT_POSITION
        cmpy #BUF2ADR+$2000
        blo ..b1
        ldy #BUF2ADR
        inc BUFFER2_BLOCK
        lda BUFFER2_BLOCK
        cmpa #32
        blo ..b1
        clra                 ;if note off is not found, make length=0
        clrb
        bra ..c1
..b1    ldd #$ffff
        cmpd ,y              ;check for end
        bne ..b2
        clra                 ;if note off is not found, make length=0
        clrb
        bra ..c1
..b2    LDD 2,y              ;get status byte
        CMPD L_NOTE,S        ;compare
        BNE ..B
        TST 4,y              ;check velocity
        BNE ..B
; note found
..C     ldd 0,y              ;we're ignoring extended time here
        subd 0,x             ;but that should not be a problem
..c1    std 5,x              ;as long as note length is less than $ffff ticks
        lda #$80             ;change note off event status byte to $8X
        sta 2,y              ;so it will be deleted during buffer merging
        BRA ..A
..Z     ENDS
        ENDPROC

; FIRQ routine that is called when the ACIA
; receives a MIDI byte (monitor version)
;
FIRQmon PROC
        PSHS A
        LDA [MDATA]          ;get MIDI byte
        STA [MBUFPTR]
        INC MBUFPTR+1
..Z     TST $FF22            ;acknowlege interrupt
        puls a
        RTI
        ENDPROC

; display the incoming MIDI bytes in hex format
; new line at each status byte
;
        extern TINVERT
        global MONITOR
MONITOR PROC
        pshs cc
        lbsr WAIT
        ldd MBUFPTR
        std ..bb
        clr $ff02       ;enable fast keyboard read
        ORCC #$50
        ldd #FIRQmon
        std FIRQ_VECTOR+1 ;set up new FIRQ vector to receive MIDI data
        lda #3
        sta [MSTAT]
        LDA #$95        ;set 8 bits, no parity
        STA [MSTAT]     ;enable receive interrupt
        LBSR MPI3       ;enable MPI
        ANDCC #$bf      ;enable FIRQ
..clear LBSR CLS
        clr TINVERT
        LDX #..aa
        LBSR PUTS
        lbsr Wait
..A     ldd ..bb
        cmpd MBUFPTR    ;is data available?
        BEQ ..C
        lda [..bb]
        inc ..bb+1
        tst ..clock_filter
        bne ..h
        cmpa #$f8       ;is this a clock byte?
        bne ..h
        com $41a
        bra ..C
..h     cmpa #$fe       ;is this an active sensing byte?
        bne ..i
        com $41e
        bra ..C
..i     PSHS A          ;print it
        clrb
        tsta            ;print status bytes in reverse
        bpl ..j
        incb
..j     stb TINVERT
        LSRA
        LSRA
        LSRA
        LSRA
        BSR ..E
        PULS A
        ANDA #$0F
        BSR ..E
        BRA ..G
..E     CMPA #9
        BLS ..F
        ADDA #7
..F     ADDA #'0'
        LBRA ChrOut
..G     LDD >CURSADR
        ADDD #2
        STD >CURSADR
        CMPD #$600
        BLO ..C
        bsr MonitorScroll
..C     LDA $FF00       ;check for keypress
        ANDA #$7F
        CMPA #$7F
        BEQ ..A
..B     lbsr getchar
        lbsr WAIT
        CMPA #BREAK
        beq ..Z
        cmpa #'C'
        bne ..k
        com ..clock_filter
        bra ..A
..k     cmpa #'R'
        LBNE ..A
        lbra ..clear
..Z     clr TINVERT
        LDA #$15        ;disable ACIA interrupt
        STA [MSTAT]
		lbsr MPI4
        puls cc,pc      ;restore interrupt masks
;
..clock_filter fcb 0
;
..aa    FCC "MIDI MONITOR            F8  FE"
        FCB 13,0
..bb    fdb 0           ;MIDI receive buffer pointer
        ENDPROC

MonitorScroll proc
        pshs x,y
        ldx #$440
        ldy #$420
..a     ldd ,x++
        std ,y++
        cmpx #$600
        bne ..a
        sty >CURSADR
        ldd #$6060
..b     std ,y++
        cmpy #$600
        bne ..b
        puls x,y,pc
        endproc

; send song position pointer message
; extended time pointer in s_extime
;
SendSPP PROC
        localvar
        char l_extime,3
        stackvar s_extime
        tst CLOCK_FLAG
        beq ..Z
        ldy s_extime,s
        tst 0,y
        bne ..a
        LDD 1,y
        BNE ..a
        LDA #$FA        ;if at start of music, send start byte instead
        BRA ..D
..a     TST SPP_FL      ;is SPP is enabled?
        BMI ..C
        LDA #$F2
        LBSR MIDI_OUT
        lda 0,y
        leax l_extime,s
        sta 0,x
        ldd 1,y
        std 1,x
        call DivideExTime,REGX,#6*(TICKS_PER_BEAT/24)
        LSLB                 ;convert 16 bit number to two 7 bit numbers
        ROLA
        LSRB
..B     PSHS A
        TFR B,A              ;send LSB first
        LBSR MIDI_OUT
        PULS A
        LBSR MIDI_OUT
        CLRA
        LDD SPP_FL
        LBSR Delay60
..C     LDA #$FB             ;continue command
..D     LBSR MIDI_OUT
..Z     ends
        ENDPROC

; delay for number of 60ths of second in D
;
        global Delay60
Delay60 PROC
        STACKVAR L_AMT,L_IRQ,L_CC
        STD L_AMT,S
        BEQ ..Z
        TFR CC,A
        STA L_CC,S
        ORCC #$50       ;disable interrupts
        LDX IRQ_VECTOR+1;set new IRQ vector
        STX L_IRQ,S
        LDX #NEWIRQ
        STX IRQ_VECTOR+1
        LDD L_AMT,S
        ANDCC #$EF      ;enable IRQ
..A     SYNC
        SUBD #1
        BNE ..A
        ORCC #$50       ;restore IRQ vector
        LDD L_IRQ,S
        STD IRQ_VECTOR+1
        LDA L_CC,S
        TFR A,CC
..Z     ENDS
        ENDPROC

; kill all notes (note off messages on all channels)
; useful for synths that don't implement the "all
; notes off" controller
;
        extern INKEY
        global KILLNOTE
KillNote PROC
        LOCALVAR L_NOT,L_CHN,l_adr
        STACKVAR
        lbsr Working
        std l_adr,s
        LDA #$90
        STA L_CHN,S
..A     LDA #0
        STA L_NOT,S
..B     LDA L_CHN,S
        LBSR MIDI_OUT
        LDA L_NOT,S
        LBSR MIDI_OUT
        CLRA
        LBSR MIDI_OUT
        com [l_adr,s]
;        ldd #$1000
;..c     subd #1
;        bne ..c
        lbsr INKEY
        cmpa #3
        beq ..done
        INC L_NOT,S
        LDA L_NOT,S
        CMPA #$80
        BLO ..B
        INC L_CHN,S
        LDA L_CHN,S
        CMPA #$A0
        BLO ..A
..done  lbsr ClrBox
        clra
        clrb
        ENDS
        ENDPROC

; send all notes off command to MIDI
;
ALLOFF PROC
        LOCALVAR L_CNT
        STACKVAR
; first send note off messages for all notes in PLNTBUFR
        LDX #PLNTBUFR
..E     tst 3,x
        beq ..F
        lda 3,x
        lbsr MIDI_OUT
        lda 4,x
        lbsr MIDI_OUT
        clra
        lbsr MIDI_OUT
..F     leax 5,x
        cmpx #PLNTBUFE
        bne ..E
; now send data in ALLOFFDT on all channels
        ldb #15
        stb L_CNT,s
..A     ldx #ALLOFFDT
..D     lda ,x+              ;set channel
        cmpa #$FF            ;check for end
        beq ..C
        bpl ..B
        ora L_CNT,S          ;status bytes
..B     lbsr MIDI_OUT        ;have channel fixed
        bra ..D
..C     dec L_CNT,s
        bpl ..A
; send clock end if clock is enabled
        tst CLOCK_FLAG
        beq ..Z
        lda #$FC             ;send clock end
        lbsr MIDI_OUT
..Z     clra
        clrb
        ENDS
        endproc

        global ALLOFFDT
ALLOFFDT FCB $B0,$7B,$40     ;MIDI all notes off
        FCB $B0,$79,$00      ;reset all controllers
        FCB $FF,0,0,0,0      ;end of data marker

        extern SaveSyx,MapBasicOut,MapBasicIn,SndErr
        global SysExclusive
SysExclusive proc
        pshs x
        lbsr MapBasicOut
        call SetBox,#..aa
        lbsr getchar
        lbsr WAIT
        lbsr ClrBox
        cmpa #BREAK
        beq ..X
        cmpa #'Y'
        bne ..X
        lbsr RecordSysEx
        cmpb #-1
        beq ..X
        tfr x,d
        subd #BUF1ADR-8
        std ARG1
        clra
        ldb BUFFER1_BLOCK
        std ARG2
;        lbsr MapBasicIn
        call SaveSyx,ARG1,ARG2
; erase BUFFER2
        lda #16
        sta BUFFER1_BLOCK
        ldd #$ffff
        std BUF1ADR
        bra ..Z
..X     lbsr SndErr
..Z     clra
        clrb
        puls x,pc
;
..aa    FDB 0,5,32,6,..bb,0
..bb    FDB 2,2,$+8,..cc
        FCC "THIS CLEARS THE PASTE BUFFER"
        FCB 0
..cc    fdb 4,3,$+8,0
        fcc "DO YOU WISH TO CONTINUE?"
        fcb 0
        endproc

        extern TVOn
RecordSysEx proc
        pshs cc
        lbsr Working
        lbsr TVOn
        clr $ff02       ;enable fast keyboard read
        lda #16
        sta BUFFER1_BLOCK
        ldx #BUF1ADR
        orcc #$50
        ldd FIRQ_VECTOR+1
        std ..old_firq
        ldd #FIRQmon
        std FIRQ_VECTOR+1 ;set up new FIRQ vector to receive MIDI data
        lda #3
        sta [MSTAT]
        lda #$95        ;set 8 bits, no parity
        sta [MSTAT]     ;enable receive interrupt
        lbsr MPI3       ;enable MPI
        andcc #$bf      ;enable FIRQ
..A     lbsr GetSyx
        com WORKING_ALERT_POSITION
        tstb
        beq ..A
        clr ,x
        orcc #$50       ;disable interrupts
        lda #$15        ;disable ACIA interrupt
        sta [MSTAT]
		lbsr MPI4
        ldd ..old_firq
        std FIRQ_VECTOR+1
..z     lbsr ClrBox
        clrb
        puls cc,pc    ;restore interrupt masks
;
..old_firq fdb 0
        endproc

GetSyx proc
..wait_for_syx
        bsr ..get_byte
        cmpb #-1
        bne ..a0
        ldb #1
        bra ..z
..a0    tstb
        beq ..wait_for_syx
        cmpa #$f0
        bne ..wait_for_syx
        sta ,x+
..get_syx
        cmpx #BUF1ADR+$2000
        blo ..b
        ldx #BUF1ADR
        inc BUFFER1_BLOCK
        lda BUFFER1_BLOCK
;        inc WORKING_ALERT_POSITION
        cmpa #32
        beq ..x
..b     bsr ..get_byte
        cmpb #-1
        beq ..x
        tstb
        beq ..b
        ldb $ff20            ;click the speaker
        eorb #$80
        stb $ff20
        sta ,x+
        cmpa #$f7
        bne ..get_syx
        bra ..y
..get_byte
        ldd ..in_ptr
        bne ..a
        ldd MBUFPTR
        std ..in_ptr
..a     cmpd MBUFPTR    ;is data available?
        beq ..chk_key
        lda [..in_ptr]
        inc ..in_ptr+1
        cmpa #$fe       ;if this is an active sensing byte
        beq ..get_byte  ;discard it and wait for next byte
        ldb #1
        bra ..z
..chk_key
        ldb $FF00       ;check for keypress
        andb #$7F
        cmpb #$7F
        beq ..y
        lbsr getchar
..x     ldb #-1
        bra ..z
..y     clrb
..z     rts
..in_ptr fdb 0
        endproc

; Returns address of status character in register D
;
        global Working
Working proc
        lbsr ClrBox
        CALL SetBox,#..aa
        ldd #WORKING_ALERT_POSITION
        rts
..aa    FDB 8,6,16,5,$+12,0
        FDB 2,2,$+8,0
        FCC "WORKING  [ ]"
        FCB 0
        endproc

        end

%if 1 eq 0
NoteOffBuffer:
        fcb 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
        fcb 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
        fcb 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
        fcb 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
        fcb 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
        fcb 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
        fcb 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
        fcb 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0

CompileMusic proc
        localvar l_count,l_d,l_x,l_time
        stackvar
        lbsr ..clearNoteOffBuffer
        clr BUFFER1_BLOCK
        ldx #BUF1ADR
        lda #32
        sta BUFFER2_BLOCK
        ldy #BUF2ADR
..next  lbsr ..checkNoteOffs
        ldd ,x++             ;check for end of music
        cmpd #$ffff
        beq ..Z
        std ,y++
        ldd ,x++
        std ,y++
        pshs d
        bsr ..update_pointers
        puls d
        cmpa #$f0            ;is this a system event?
        bhs ..handle_sys
        cmpa #$9f            ;is this a note event?
        bls ..handle_note
        cmpa #$c0
        blo ..two_bytes
        cmpa #$df
        bls ..next
..two_bytes
        clra
        clrb
        std ,y++             ;relative time=0
        lda ,x+              ;get the last data byte
        std ,y++             ;(last byte is not used)
        bsr ..update_pointers
        bra ..next
..handle_note
        std l_d,s
        ldd 5,x
        std l_time,s
        stx l_x,s
        lda #32
        sta l_count,s
        ldx #NoteOffBuffer
..D     ldd ,x               ;find an empty slot
        beq ..E
        leax 4,x
        bra ..D
..E     ldd l_time,s
        std ,x
        ldd l_d,s            ;save status byte and pitch
        std 2,x
        ldx l_x,s
        bra ..next
..handle_sys
        ldd ,x++
        std ,y++
        ldd ,x++
        std ,y++
        bsr ..update_pointers
        bra ..next
..Z     ends
;
..update_pointers
        cmpx BUF1ADR+$2000
        blo ..up1
        ldx #BUF1ADR
        inc BUFFER1_BLOCK
..up1   cmpy BUF2ADR+$2000
        blo ..up2
        ldy #BUF1ADR
        inc BUFFER2_BLOCK
..up2   rts
;
..clearNoteOffBuffer
        ldx #NoteOffBuffer
        ldb #128
..cNOB  clr ,x+
        decb
        bne ..cNOB
        rts
;
..checkNoteOffs
        ldd ,x               ;get next event time
        std l_time,s
        stx l_x,s
        ldx #NoteOffBuffer
        lda #32
        sta l_count,s
..cNO2  ldd ,x
        beq ..cNO3
        subd l_time,s
        bcs ..cNO4
        std ,x
..cNO3  leax 4,x
        dec l_count,s
        bne ..cNO2
        rts
..cNO4  ldd ,x
        std ,y++
        ldd 2,x
        std ,y++
        bsr ..update_pointers
        clra
        clrb
        std ,y++
        clra
        clrb
        std ,y++
        bsr ..update_pointers
        bra ..cNO2
;
        endproc

DeCompileMusic proc
        rts
        endproc
%endif

; end of file: MIDI/TXT
