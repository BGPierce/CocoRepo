; CMP/TXT
; CoCo MIDI PRO
; (C) 1988 by Lester Hands, all rights reserved

; Assumptions about programming style:
; - All subroutines preserve registers X,Y,U unless
;   otherwise stated (rare exceptions!)
; - Passing of parameters is generally done via the
;   CALL macro; if a register is used, only X may
;   be used!
; - Return value from a subroutine is passed in
;   register D; rarely in another register (almost
;   always register X).
; - A memory map with the full 64K is generally
;   assumed; subroutines that enable the ROMs must
;   disable them as quickly as possible.

%include "macros.h"
%include "cmp.h"

        EXTERN CLOSE,DSKCON,OPEN,READ,KILL,ERROR
        EXTERN ALLOFFDT,ATOI,BELL,BINDEC,pBINDEC,BINHEX,BOXINP
        EXTERN CHROUT,CLRBOX,CLS,DIVIDE,DOCMD,EDIT,SAVE,LOAD,DISKOFF
        EXTERN FINDENDBUFFER1,FIRQMAST,FIRQSLAV,FileKill,GETCHAR
        EXTERN GETSTR,HEXSBIN,KILLNOTE,MONITOR,MOVE
        EXTERN MPI_SLOT,MULT,PLAY,PUTS,RECORD,MEM_LINE
        EXTERN SETBOX,STRPAD,TVON,WRITE,SetAnnotation
        extern SysExclusive,PrevAbsEvent,FILENAME,FileInfo,Working
        extern ConvertFile,FindFileName,TAPE_IO_FLAG,TAPE_SPEED
        extern MapDataIn,MapDataOut,memcpy,InitialSetup,StrPad
        extern BlockUndo,CopyBuf1Buf3,CNVNOTE
;        extern MakeTape

        DEFSEG autoexec,start=0182h
        seg autoexec
        JMP START

        seg code
        JMP START

; hardware addresses put here so they can be patched
        global MSTAT,MDATA
MSTAT   FDB $FF6E            ;ACIA control/status register
MDATA   FDB $FF6F            ;ACIA data register

; used by the record/play routines
        global PLAYPTR,RECPTR
PLAYPTR FDB BUF1ADR          ;pointer to MIDI buffer for play routine
RECPTR  FDB BUF2ADR          ;ptr to record buffer

        global MSTATUS,MIDISTAT
MSTATUS FCB 0                ;MIDI running status byte
MIDISTAT FCB 0               ;MIDI status byte

        global MCOUNT
MCOUNT  FCB 0 ;number of bytes in message

        global DONE,MFILTER,FILT_FLG,TRAK_FLG,TRACK,TOP_TRACK
DONE    FCB 0                ;flag for playback
MFILTER FCB MF_NOTOF         ;MIDI filter
FILT_FLG FCB 0               ;filter flag
TRAK_FLG FCB 0               ;track filter flag
TRACK   FCB 0                ;current edit/record track
TOP_TRACK fcb 0              ;track at top of display (allows scrolling)

        global KEY
KEY     FCB 'F'              ;display notes as sharp/flat
        global LINKPTR
LINKPTR FDB 0                ;<>0 when a file link

        global MBUFPTR
MBUFPTR FDB MIDIBUF ;input buffer pointer

; the slave flag = 0 when in master mode;
;                = 1 in slave but not started
;                = -1 when start or continue received
        global SLAVE,STOP,SNGPOSPT,POSNFLAG
SLAVE   FCB 0                ;<>1 when in slave mode
STOP    FCB 0                ;<>0 when MIDI stop received
SNGPOSPT fcb 0,0,0           ;song position pointer (extended time)
POSNFLAG FCB 0               ;<>0 when song pos. calculated

        global CLOCK,MASTER_CPERIOD,CPERIOD,CPCOUNT,CLOCKslv,CPCslave
CLOCK   fcb 0,0,0            ;master clock (ticks), extended time
MASTER_CPERIOD fdb 49        ;master clock period (determines tempo)
CPERIOD FDB 49               ;clock period
CPCOUNT FDB 49               ;HIRQ ints/tick
CLOCKslv fcb 0,0,0           ;slave clock (extended time)
CPCslave FDB 0               ;slave CP counter

        global METRONOME_PITCH,METRONOME_CHANNEL,METRONOME_VELOCITY
METRONOME_PITCH fcb 0        ;if zero, speaker click, else note on
METRONOME_CHANNEL fcb 0
METRONOME_VELOCITY fdb 0

        global METRONOM,METCOUNT,TICKS,TICKslav,TIMEBASE,MEASURE,SYNCFLAG
METRONOM FCB 24              ;number of MIDI clocks per beat
METCOUNT FCB 0               ;clocks/beat
TICKS    FCB 2               ;# ticks to make 1 clock
TICKslav FCB 0
TIMEBASE FDB TICKS_PER_BEAT
MEASURE  FDB TICKS_PER_BEAT*4 ;4 ticks/measure
SYNCFLAG FCB 1               ;<>0 when ok to play

        global BAR,BAR_CNT,BEAT_CNT
BAR     FCB 4                ;number of beats in a bar
BAR_CNT FDB 0                ;current bar # (play)
BEAT_CNT FCB 0               ;current beat # (play)

        global IRQACTIV,STROBE,CLOCK_FLAG,KEYINP
IRQACTIV FCB 0               ;>0 when IRQ already active
STROBE  FCB 0                ;raw keyboard input
CLOCK_FLAG FCB 1             ;>0 when MIDI clock on
KEYINP  FCB $FF              ;value of $FF00

        global BLK_STRT,BLK_END
BLK_STRT fcb $ff,$ff,$ff     ;block markers (extended times)
BLK_END  fcb $ff,$ff,$ff

        global EX_TIME1,EX_TIME2
EX_TIME1 fcb 0,0,0           ;extended time1
EX_TIME2 fcb 0,0,0           ;extended time2

        global PNCH_FLG
PNCH_FLG FCB 0               ;=1 when punch in/out

; SPPFL=$FFFF when SPP should not be sent
; otherwise, it is the number of 60ths of a second
; that should elapse between SPP and continue mssg.
        global SPP_FL
SPP_FL  FDB 0                ;song position pointer flag

        global YPOS,XPOS,TINVERT
YPOS    FCB 0                ;vertical position
XPOS    FCB 0                ;horizontal position
TINVERT FCB 0                ;>0 if text invert

; used by MACROS
        global ARG1,ARG2,ARG3,ARG4
ARG1    FDB 0
ARG2    FDB 0
ARG3    FDB 0
ARG4    FDB 0

; play note buffer
; Storage area for notes being played.
; First word is the note length count.
; Second word is the status byte and pitch.
; When a count word is zero, it is available for a
; new note.
;
        global PLNTBUFR,PLNTBUFE
PLNTBUFR RMB 5*24            ;space for 24 notes
PLNTBUFE EQU $               ;buffer end

        global DR40TRK
DR40TRK FCB 0                ;=0 if 40 track drives

        global STARTUP,DISKLOAD
STARTUP FDB 0                ;=$5AF0 if already started
DISKLOAD FCB 0               ;=$AF if error on load file

; flag for status/comment fields on main screen
; =0 for status, =1 for comment field.
        global SCFIELD
SCFIELD FCB 0

; A set of 16 bytes used as track flags
; bit 8: 1=on 0=off (mute)
; bit 7: 1=solo (mute all tracks not solo'd)
;
        global TFLAGS
TFLAGS  fcb $80,$80,$80,$80,$80,$80,$80,$80
        fcb $80,$80,$80,$80,$80,$80,$80,$80

        global STARTMEM,COMMENTS,MESSAGES,ANNOTATION
STARTMEM fdb DAT_ADR+$1000 ;set to $5af0 if already initialized
COMMENTS fdb DAT_ADR+$1002 ;address of start of comments
MESSAGES fdb DAT_ADR+$1002+(16*COMMENT_SIZE) ;address of start of messages
ANNOTATION fdb DAT_ADR+1002+(16*COMMENT_SIZE)+(16*16) ;address of start of annotation

;**************************************************
;
; Beginning of program
;
;**************************************************

START PROC
        global RESET
Reset   NOP
        LDS #STACK
        lbsr SETUP
..A     LBSR CLS
        COM TINVERT
        LDX #..aa
        LBSR PUTS
        CLR TINVERT
        LBSR PUTS
..B     call Status,#1
        ldd #$3c3d           ;restore MMU registers
        std $ffa4
        ldd #$3e3f
        std $ffa6
;        lda #$34             ;reset PIAs
;        sta $ff01
;        sta $ff03
;        sta $ff21
;        sta $ff23
..C     LBSR getchar         ;wait for selection
;        cmpa #'L'            ;check for special tape write routine
;        bne ..notL
;        lbsr MakeTape
;        bra ..C
..notL  LBSR SelTrk
        CMPD #1
        BEQ ..C
        TFR A,B
        LDX #..bb
        PSHS X
        LBSR DoCmd
        LEAS 2,S
        CMPD #0
        BEQ ..B
        BRA ..A
;
..aa    FCC "         COCO MIDI PRO          "
        FCB 0
        FCB 13
        FCC "TR SIZE  MODE      COMMENT"
        FCB 13
        FCC "-- ----- ---- ------------------"
        FCB 0
;
..bb    FCB 'F'
        FDB FileMenu
        FCB 'P'
        FDB PerformMenu
        FCB 'E'
        FDB EditMenu
;%if DEBUG eq 1
        FCB 'H'
        FDB RAW
;%endif
        FCB 0
        ENDPROC

        global DoMenu
DoMenu PROC
        STACKVAR S_MPTR,S_CPTR
        CALL SetBox,<S_MPTR,S>
        LBSR getchar
        TFR A,B
        LBSR ClrBox
        CMPA #BREAK
        BEQ ..X
        LDX S_CPTR,S
        PSHS X
        LBSR DoCmd
        LEAS 2,S
        BRA ..Z
..X     CLRA
        CLRB
..Z     ENDS
        ENDPROC

FileMenu PROC
        CALL DoMenu,#..aa,#..jj
        rts
;
..aa    FDB 10,2,12,11,$+12,0
        fdb 1,0,..bb,$+8
        FDB 3,2,..cc,$+8
        FDB 3,3,..dd,$+8
        FDB 3,4,..ee,$+8
        fdb 3,5,..ff,$+8
        FDB 3,6,..gg,$+8
        fdb 3,7,MENU_IO,$+8
		FDB 3,8,..ii,0
..bb    fcc " FILE "
        fcb 0
..cc    FCC "LOAD"
        FCB 0
..dd    FCC "SAVE"
        FCB 0
..ee    FCC "KILL"
        FCB 0
..ff    fcc "INFO"
        fcb 0
..gg    FCC "CONFIG"
        FCB 0
MENU_IO fcc "DISK"
        fcb 0
..ii    FCC "EXIT"
        FCB 0
;
..jj    FCB 'L'
        FDB Load
        fcb 'l'
        fdb ConvertFile
        FCB 'S'
        FDB Save
        FCB 'K'
        FDB FileKill
        fcb 'D'
        fdb ToggleTapeIO
        fcb 'T'
        fdb ToggleTapeIO
        fcb 'I'
        fdb FileInfo
        FCB 'C'
        FDB Config
		FCB 'E'
        FDB EXIT
        FCB 0
        ENDPROC

PerformMenu PROC
        CALL DoMenu,#..aa,#..jj
        rts
;
..aa    FDB 8,2,16,12,$+12,0
        fdb 1,0,..kk,$+8
        FDB 3,2,..bb,$+8
        FDB 3,3,..cc,$+8
        FDB 3,4,..dd,$+8
        FDB 3,5,..ee,$+8
        FDB 3,6,..ff,$+8
        FDB 3,7,..gg,$+8
        FDB 3,8,..hh,$+8
        fdb 3,9,..ii,0
..kk    fcc " PERFORM "
        fcb 0
..bb    FCC "RECORD"
        FCB 0
..cc    FCC "PLAY"
        FCB 0
..dd    FCC "KILL NOTES"
        FCB 0
..ee    FCC "CLOCK"
        FCB 0
..ff    FCC "BEATS/BAR"
        FCB 0
..gg    FCC "FILTER"
        FCB 0
..hh    FCC "MONITOR"
        FCB 0
..ii    fcc "SYS EXCL."
        fcb 0
;
..jj    FCB 'R'
        FDB RECORD
        FCB 'P'
        FDB PLAY
        FCB 'K'
        FDB KillNote
        FCB 'C'
        FDB SetClock
        FCB 'B'
        FDB SetMeasure
        FCB 'F'
        FDB SetFiltr
        FCB 'M'
        FDB MONITOR
        fcb 'S'
        fdb SysExclusive
        FCB 0
        ENDPROC

EditMenu PROC
        CALL DoMenu,#..aa,#..pp
        rts
;
..aa    FDB 8,2,17,11,$+12,0
        fdb 1,0,..kk,$+8
        FDB 3,2,..bb,$+8
        FDB 3,3,..ee,$+8
        FDB 3,4,..ff,$+8
        fdb 3,5,..gg,$+8
        fdb 3,6,..jj,$+8
        FDB 3,7,..dd,$+8
        fdb 3,8,..ll,0
..kk    fcc " EDIT "
        fcb 0
..bb    FCC "EDIT TRACK"
        FCB 0
..ee    FCC "TRACK ERASE"
        FCB 0
..ff    FCC "CLEAR ALL"
        FCB 0
..gg    fcc "RESTORE"
        fcb 0
..jj    fcc "BEATS/BAR"
        fcb 0
..dd    FCC "KEY"
        FCB 0
..ll    fcc "ANNOTATION"
        fcb 0
;
..pp    FCB 'E'
        FDB Edit
        FCB 'K'
        FDB SetKey
        FCB 'T'
        FDB TrackKill
        FCB 'C'
        FDB ClearAll
        FCB 'R'
        fdb BlockUndo
        FCB 'B'
        FDB SetMeasure
        fcb 'A'
        fdb SetAnnotation
        fcb 0
        ENDPROC

; number of events in each track
;
TRACK_SIZE fdb 0,0,0,0,0,0,0,0
        fdb 0,0,0,0,0,0,0,0
        global TOTAL_EVENTS
TOTAL_EVENTS fdb 0

CountTracks proc
        pshs x,y
; clear out the count table
        ldx #TRACK_SIZE
        LDB #32
..clear CLR ,X+
        DECB
        BNE ..clear
; count the events in each track and total number of events
        LDX #BUF1ADR         ;X points to start of BUFFER1
        clr BUFFER1_BLOCK
..B     LDD ,X               ;check for end
        CMPD #$FFFF
        BEQ ..done
;        tst 2,x              ;check for an invalid event
;        bmi ..b1
;        ldd #$ffff
;        std ,x
;        bra ..done
..b1    LDB 7,X              ;get the track #
        andb #$0f
        LSLB
        ldy #TRACK_SIZE
        leay b,y
        LDD ,y
        ADDD #1
        STD ,y
..F     lbsr NextAbsEvent
        bra ..B
..done  ldx #TRACK_SIZE
        ldb #16
        pshs b
        clra
        clrb
..count addd ,x++
        dec 0,s
        bne ..count
        std TOTAL_EVENTS
        leas 1,s
        puls x,y,pc
        endproc

; display the status of the 16 tracks
; if S_FLAG=0, then tracks and memory are not counted
;
        extern NextAbsEvent
Status PROC
        localvar l_trk,l_pos
        stackvar s_flag
        lda TOP_TRACK
        STA L_TRK,S
        ldd S_FLAG,s
        beq ..A
        bsr CountTracks
        lda #13
        sta XPOS
        lda #4
        sta YPOS
..A     lda XPOS
        ldb YPOS
        std l_pos,s
        LDA #4
        STA YPOS
; display track number
..D     LDA #0
        STA XPOS
        LBSR MOVE
        LDA L_TRK,S
        cmpa #9
        blo ..D1
        pshs a
        lda #'1'
        lbsr ChrOut
        puls a
        suba #10
..D1    ADDA #'1'
        LBSR ChrOut
        lda #' '
        lbsr ChrOut
; display track size
        LDA #3
        STA XPOS
        LBSR MOVE
        ldb #5
        pshs b
..D2    lda #' '
        lbsr ChrOut
        dec ,s
        bne ..D2
        puls b
        lda #3
        sta XPOS
        lbsr MOVE
        LDB L_TRK,S
        LSLB
        ldx #TRACK_SIZE
        LDD B,X
        LBSR pBINDEC
; display track status
        LDB L_TRK,S
        LBSR PrtStat
; display comment
        LDB L_TRK,S
        LBSR PrtCmnt
; loop back for next track
        INC L_TRK,S
        INC YPOS
        ldb YPOS
        CMPB #14
        BLO ..D
; display memory size
        LDA #15
        STA YPOS
        CLR XPOS
        LBSR MOVE
        lda #1
        sta TINVERT
        LDX #..aa
        LBSR PUTS
        ldd #16384           ;maximum number of events in 16 blocks
        subd TOTAL_EVENTS
        LBSR pBINDEC
..E     lda #' '
        lbsr ChrOut
        lda XPOS
        cmpa #15
        bne ..E
;menu prompts
        lda #15
        sta YPOS
        lda #15
        sta XPOS
        lbsr Move
        ldx #..dd
        lbsr puts
        clr TINVERT
..Z     ldd l_pos,s
        sta XPOS
        stb YPOS
        lbsr Move
        ENDS
;
..aa    FCC "FREE:"
        FCB 0
..bb    FCC "B-"
        FCB 0
..cc    FCC "E-"
        FCB 0
..dd    fcc "fILE pERFORM eDIT"
        fcb 0
;
        ENDPROC

; Print track MUTE/PLAY information, given track
; number in register B. It is assumed that YPOS is already set up.
;
PrtStat PROC
        PSHS B
        LDA #9
        STA XPOS
        LBSR MOVE
        LDX #TFLAGS
        PULS B               ;restore track #
        TST SCFIELD          ;check for the right column
        BNE ..A
        CMPB TRACK           ;is this the current track?
        BNE ..A
        COM TINVERT
..A     LDA B,X
        BMI ..B
        LDX #..aa
        BRA ..C
..B     CMPA #$C0            ;check for SOLO
        BLO ..D
        LDX #..cc
        BRA ..C
..D     LDX #..bb
..C     LBSR PUTS
        CLR TINVERT
..Z     RTS
;
..aa    FCC "MUTE"
        FCB 0
..bb    FCC "PLAY"
        FCB 0
..cc    FCC "SOLO"
        FCB 0
        ENDPROC

; Print the comment for the track # in register B.
; It is assumed that YPOS is already set up.
;
PrtCmnt PROC
        PSHS B               ;save track
        LDA #14
        STA XPOS
        LBSR MOVE
        PULS B               ;restore track
        TST SCFIELD
        BEQ ..A
        CMPB TRACK
        BNE ..A
        COM TINVERT
..A     LDA #COMMENT_SIZE
        MUL
        LDX COMMENTS
        LEAX D,X
        lbsr MapDataIn
        LBSR PUTS
        lbsr MapDataOut
        CLR TINVERT
        RTS
        ENDPROC

; part of main loop: select the current track
; the keyboard input is in register A
;
SelTrk PROC
        LOCALVAR L_D
        STACKVAR
        STD L_D,S
        ldb TRACK
        subb TOP_TRACK
        addb #4
        cmpb #13
        bls ..A2
        ldb #13
..A2    stb YPOS
        LDB TRACK
        CMPA #UP
        BNE ..B
        tstb
        lbeq ..K
        DEC TRACK
        ldb YPOS
        cmpb #4
        beq ..A1
        dec YPOS
        BRA ..D
..A1    dec TOP_TRACK
        bra ..D
..B     CMPA #DOWN
        BNE ..C
        CMPB #15
        beq ..K
        inc TRACK
        ldb YPOS
        cmpb #13
        beq ..B1
        inc YPOS
        bra ..D
..B1    inc TOP_TRACK
        bra ..D
..C     CMPA #LEFT
        BNE ..A
        TST SCFIELD
        BEQ ..K
        CLR SCFIELD
        BRA ..D
..A     CMPA #RIGHT
        BNE ..F
        TST SCFIELD
        BNE ..K
        INC SCFIELD
..D     call Status,#0
        bra ..K
..F     CMPA #ENTER
        BNE ..L
        TST SCFIELD
        BEQ ..G
        LBSR EdCmnt
        BRA ..E
..G     LDX #TFLAGS          ;toggle mute/play flag
        LDA B,X
        CMPA #$80
        BLO ..H
        CMPA #$C0
        BLO ..J
        EORA #$C0
        BRA ..I
..J     ORA #$40
        BRA ..I
..H     EORA #$80
..I     STA B,X
..E     LDB TRACK
        LBSR PrtStat
        LBSR PrtCmnt
..K     LDD #1               ;action taken flag
        STD L_D,S            ;change D return value
        bra ..Z
..L     cmpa #SHFTUP
        bne ..M
        clr TOP_TRACK
        clr TRACK
        bra ..Z
..M     cmpa #SHFTDOWN
        bne ..Z
        lda #6
        sta TOP_TRACK
        sta TRACK
..Z     LDD L_D,S
        ENDS
        ENDPROC

; edit a track comment; track number in register B
;
EdCmnt PROC
        STACKVAR
        PSHS B
        ADDB #4
        subb TOP_TRACK
        STB YPOS
        LDB #14
        STB XPOS
        LBSR MOVE
        lbsr MapDataIn
        PULS B               ;restore track number
        LDA #COMMENT_SIZE
        MUL
        ADDD COMMENTS
        STD ARG1
        pshs d
        call StrPad,ARG1,#COMMENT_SIZE-1
        puls d
        std ARG1
        CALL GetStr,ARG1,#COMMENT_SIZE-1
        lbsr MapDataOut
        ENDS
        ENDPROC

; set up correct configuration
;
        LOCALVAR L_DEF
        global Config
Config PROC
        STACKVAR
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        BEQ ..Z
        LBSR CnvCnfig
        tst TAPE_IO_FLAG
        bne ..Z
%IF DEMO
        CALL SetBox,#..rr
        LBSR getchar
        LBSR ClrBox
        CMPA #'Y'
        BNE ..Z
        LDA DEFDRIVE
        STA L_DEF,S
        LDX #..ss
        ldd #'W '
        LBSR Open
        tsta
        beq ..Z
        CALL Write,#..hh,#58
        LBSR Close
        LDA L_DEF,S
        STA DEFDRIVE
%ENDIF
..Z     CLRA
        CLRB
        ENDS
;
..aa    FDB 2,0,27,16,$+12,..gg
        FDB 3,2,..bb,$+8 ;text strings
        FDB 3,4,..cc,$+8
        FDB 3,5,..dd,$+8
        FDB 3,6,..ee,$+8
        FDB 3,7,..ff,$+8
        FDB 3,8,..nn,$+8
        FDB 3,9,..oo,$+8
        FDB 3,10,..qq,$+8
        fdb 3,11,..uu,$+8
        fdb 3,12,..ww,$+8
        fdb 3,13,..yy,0
..bb    FCC "NOTES OFF:"
        FCB 0
..cc    FCC "40 TRACK DRIVE?:"
        FCB 0
..dd    FCC "BACKGROUND COLOR:"
        FCB 0
..ee    FCC "FOREGROUND COLOR:"
        FCB 0
..ff    FCC "BORDER COLOR:"
        FCB 0
..nn    FCC "COLOR/MONOCHROME:"
        FCB 0
..oo    FCC "SONG POSN POINTER:"
        FCB 0
..qq    FCC "MULTIPAK SLOT #:"
        FCB 0
..uu    fcc "SCREEN BLANK:"
        fcb 0
..ww    fcc "HIGH SPEED TAPE:"
        fcb 0
..yy    fcc "METRONOME:"
        fcb 0
..gg    FDB 4,3,..hh,$+10,0 ;input strings
        FDB 22,4,..ii,$+10,$-10
        FDB 22,5,..jj,$+10,$-10
        FDB 22,6,..kk,$+10,$-10
        FDB 22,7,..ll,$+10,$-10
        FDB 22,8,..mm,$+10,$-10
        FDB 22,9,..pp,$+10,$-10
        FDB 22,10,..tt,$+10,$-10
        fdb 19,11,..vv,$+10,$-10
        fdb 22,12,..xx,$+10,$-10
        fdb 14,13,..zz,$+10,$-10
        fdb 18,13,..zz2,$+10,$-10
        fdb 21,13,..zz3,0,$-10
..hh    FCC "B0 7B 40 B0 79 00 FF"
        FCB 0
..ii    FCB 'N',0
..jj    FCC "13"
        FCB 0
..kk    FCC "62"
        FCB 0
..ll    FCC "5 "
        FCB 0
..mm    FCB 'C',0
..pp    FCC "N  "
        FCB 0
..tt    FCB '3',0
..vv    fcc "60000"
        fcb 0
..xx    fcb 'Y',0
..zz    fcc "0  "
        fcb 0
..zz2   fcc "0 "
        fcb 0
..zz3   fcc "0  "
        fcb 0
;
%IF DEMO
..rr    FDB 5,5,22,5,$+12,0
        FDB 2,2,$+8,0
        FCC "SAVE THESE VALUES?"
        FCB 0
;
..ss    FCC "CONFIG/DAT:0"
        FCB 0
%ENDIF
;
        global CnvCnfig
CnvCnfig PSHS X
        CALL HexSBin,#..hh,#ALLOFFDT,#10
        LDA ..ii             ;drive size
        STA DR40TRK
        CMPA #'Y'
        BNE ..D
        CLR DR40TRK
..D     LDX #..jj            ;foreground color
        LBSR atoi
        STB $FFBD
        LDX #..kk            ;background color
        LBSR atoi
        STB $FFBC
        LDX #..ll            ;border color
        LBSR atoi
        STB $FFB8
        LDA ..mm             ;monochrome on/off
        CMPA #'M'
        BNE ..C
        LDA #$16             ;set monochrome
        STA $FF98
..C     LDX #..pp            ;set SPP_FL
        LDA ,X               ;check for "no"
        CMPA #'N'
        BNE ..E
        LDD #$FFFF
        BRA ..F
..E     LDA ,X               ;check for digit
        CMPA #'0'
        BLO ..G
        CMPA #'9'
        BHI ..G
        LBSR atoi
..F     STD SPP_FL
..G     LDA ..tt             ;get MPI slot #
        SUBA #'1'
        BMI ..H
        CMPA #3
        BHI ..H
        PSHS A
        LSLA
        LSLA
        LSLA
        LSLA
        ORA ,S+
        STA MPI_SLOT
..H     ldx #..vv
        lbsr atoi
        std SCREEN_BLANK_DELAY
        lda ..xx
        cmpa #'Y'
        bne ..h1
        clra
..h1    sta TAPE_SPEED
        ldx #..zz            ;convert metronome pitch
        lda ,x
        cmpa #'0'
        bne ..h2
        clra
        bra ..h3
..h2    lbsr CNVNOTE
..h3    sta METRONOME_PITCH
        beq ..h5
        ldx #..zz2           ;convert metronome channel
        lbsr atoi
        tstb
        beq ..h4
        decb
..h4    orb #$90
        stb METRONOME_CHANNEL
        ldx #..zz3
        lbsr atoi
        stb METRONOME_VELOCITY
..h5    PULS X,PC
;
        global LoadCnfg
LoadCnfg PSHS X
%IF DEMO
        tst ..redo
        bne ..B
        inc ..redo
        ldd #'R '
        ldx #..ss
        LBSR Open
        tsta
        beq ..B
        CALL Read,#..hh,#58
        LBSR Close
;        LBSR CnvCnfig
%ENDIF
..B     PULS X,PC
..redo  fcb 0
        ENDPROC

; set the MIDI clock (assumes use of HSYNC timing)
SetClock PROC
        STACKVAR
        LDX #..ii
        LDA CLOCK_FLAG
        BEQ ..C
        LDD #'ON'
        STD ,X++
        LDA #32
        STA ,X
        BRA ..D
..C     LDD #'OF'
        STD ,X++
        LDA #'F'
        STA ,X
..D     ldd MASTER_CPERIOD
        lbsr CPCalc
        LDX #..ee
        LBSR BINDEC
        CALL StrPad,REGX,#3
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        BEQ ..Z
        LDX #..ee
        LBSR atoi
        lbsr CPCalc
        STD MASTER_CPERIOD
        std CPERIOD
        LDD ..ii             ;set clock flag
        CMPD #'ON'
        BEQ ..G
        CLRA
        BRA ..B
..G     LDA #1
..B     STA CLOCK_FLAG
        LDX #FIRQmast
        LDA ..kk             ;set slave flag
        CMPA #'S'
        BNE ..E
        LDX #FIRQslav
        CLR CLOCK_FLAG
        LDA #1
        BRA ..F
..E     CLRA
..F     STA SLAVE
        STX FIRQ_VECTOR+1    ;set FIRQ vector
..Z     CLRA
        CLRB
        ENDS
;
..aa    FDB 6,4,21,7,..bb,..cc
..bb    FDB 2,2,..dd,$+8 ;text
        FDB 2,3,..hh,$+8
        FDB 2,4,..jj,0
..cc    FDB 13,2,..ee,$+10,0 ;input
        FDB 14,3,..ii,$+10,$-10
        FDB 16,4,..kk,0,$-10
..dd    FCC "METRONOME:"
        FCB 0
..ee    FCC "100"
        FCB 0
..hh    FCC "MIDI CLOCK:"
        FCB 0
..ii    FCC "ON "
        FCB 0
..jj    FCC "MASTER/SLAVE:"
        FCB 0
..kk    FCC "M"
        FCB 0
        ENDPROC

; calculate CPERIOD given value in D
; returns value in D (does not modify CPERIOD!)
; there are 96 system "ticks" per beat, which
; means there are 4 ticks per MIDI clock
; Formula used:
;     clock period = 60/(48(tempo)(63.5xE-6))
; the clock period is the number decremented by
; the IRQ routine; tempo is beats per minute.
;
        global CPCalc
CPCalc  PSHS X
        STD ARG2
;        CALL Divide,#9840,ARG2
;        call Divide,#1764,ARG2 ;for 192 tpb
;        call Divide,#1376,ARG2 ;for 240 tpb
        call Divide,#3574,ARG2
        PULS X,PC

; Clear all music, messages, and comments; leave paste buffer intact.
;
        global ClearCMA
ClearAll PROC
        pshs x
        LBSR Sure
        CMPD #0
        BNE ..X
        lbsr SndOK
        lbsr CopyBuf1Buf3
        LDD #$FFFF           ;clear the block markers
        STD BLK_STRT+1
        STD BLK_END+1
        lda #' '             ;clear the filename
        ldb #8
        ldx #FILENAME
..E     sta ,x+
        decb
        bne ..E
        ldd #BUF1ADR         ;clear out MEM_LINE
        std MEM_LINE
        clr MEM_LINE+2
        LDX #TFLAGS          ;set the status
        LDB #16              ;flags to PLAY
        LDA #$80
..D     STA ,X+
        DECB
        BNE ..D
        clr BUFFER1_BLOCK
        LDD #$FFFF
        STD BUF1ADR
        puls x
ClearCMA
        pshs x
        lbsr MapDataIn
        LDX COMMENTS         ;clear out the comments
        LDB #16
        pshs b
..A     ldb #COMMENT_SIZE-1
        LDA #' '
..B     sta ,x+
        decb
        bne ..B
        clr ,x+
        dec 0,s
        bne ..A
        puls b
        ldx MESSAGES         ;clear the messages
        clrb
..C     clr ,x+
        decb
        bne ..C
;clear the annotation
        ldx ANNOTATION
        ldb #12
        pshs b
..f     ldb #28
        lda #' '
..g     sta ,x+
        decb
        bne ..g
        clr ,x+
        dec 0,s
        bne ..f
        puls b
        lbsr MapDataOut
        bra ..Y
..X     clra
        clrb
        bra ..Z
..Y     LDA #1               ;ask for screen update
..Z     puls x,pc
        ENDPROC

; Delete a track
;
TrackKill PROC
        LOCALVAR L_B2
        STACKVAR
        LBSR Sure
        CMPD #0
        BNE ..X
        lbsr CopyBuf1Buf3
        LDX #BUF1ADR
        ldy #BUF2ADR
        clr BUFFER1_BLOCK
        clr BUFFER2_BLOCK
..A     LDD 0,X              ;check for end
        CMPD #$FFFF
        BEQ ..D
        LDA 7,X              ;check track #
        anda #$0f            ;ignore extended time info
        CMPA TRACK
        BEQ ..C
        clrb
..B     LDA b,X
        STA b,Y
        incb
        cmpb #EVNSIZE
        BNE ..B
        leay EVNSIZE,y
        cmpy #BUF2ADR+$2000
        blo ..C
        ldy #BUF2ADR
        inc BUFFER2_BLOCK    ;get the next extended memory block
..C     LEAX EVNSIZE,X
        cmpx #BUF1ADR+$2000
        blo ..A
        ldx #BUF1ADR
        inc BUFFER1_BLOCK    ;get the next extended memory block
        BRA ..A
..D     LDD ,X               ;transfer the end mark
        STD ,Y
        ldd #BUF1ADR         ;clear out MEM_LINE
        std MEM_LINE
        clr MEM_LINE+2
        bra ..Y
..X     clra
        clrb
        bra ..Z
..Y     LBSR SndOK
        LDA #1               ;ask for screen update
..Z     ENDS
        ENDPROC

        global EXIT
EXIT PROC
        LBSR Sure
        CMPD #0
        BNE ..Z
        STA SLOW
        lda #$38
        ldb #8
        ldx #$ffa0
..a     sta ,x+
        inca
        decb
        bne ..a
        clr TASK_REGISTER
        CLRA
        TFR A,DP
        CLR $71
        JMP [$FFFE]
..Z     CLRA
        CLRB
        RTS
        ENDPROC

        global SndOK
SndOK   CALL Bell,#60
        RTS

        global SndErr
SndErr  CALL Bell,#255
        RTS

; Ask whether the user is sure
; Returns 0 if Yes, else $FFFF
;
        global Sure
Sure PROC
        LOCALVAR L_KEY
        STACKVAR
        CALL SetBox,#..aa
        LBSR SndErr
..A     LBSR getchar
        CMPA #'Y'
        BNE ..X
        CLRA
        CLRB
        STD L_KEY,S
        BRA ..Z
..X     LDD #$FFFF
        STD L_KEY,S
..Z     LBSR ClrBox
        LDD L_KEY,S
        ENDS
..aa    FDB 7,5,17,5,..bb,0
..bb    FDB 2,2,..cc,0
..cc    FCC "ARE YOU SURE?"
        FCB 0
        ENDPROC

; perform general setup chores
;
        global SETUP
SETUP PROC
        PSHS X,Y
        ORCC #$50       ;disable interrupts
        ldd STARTUP
        cmpd #$5af0
        beq ..a
        lbsr InitialSetup
; configure the MMU
..a     clr $ff92       ;disable all GIME interrupts for now
        lda #$ec        ;CoCo compatible, MMU enabled, GIME IRQ enabled
        sta $ff90       ;RAM at XFEXX constant, Standard SCS
        ldd #$3c3d      ;restore MMU registers
        std $ffa4
        ldd #$3e3f
        std $ffa6
        sta ROM_OFF
; initialize PIA for FIRQ
        LDA $FF23
        ORA #1          ;to enable FIRQ
        ANDA #$FD       ;set flag on falling edge
        STA $FF23
        LDA $FF21       ;disable CD interrupt
        ANDA #$FE
        STA $FF21
; check for Colorchestra
        lda #3          ;reset both CoCo MIDI and Colorchestra locations
        ldx #$ff66
        sta ,x
        tst ,x
        bne ..not_colorchestra
        stx MSTAT
        leax 1,x
        stx MDATA
..not_colorchestra
        lda #3               ;initialize MIDI pack
        sta [MSTAT]
        lda #$15
        sta [MSTAT]
        lbsr CnvCnfig
;        LBSR DiskOff
        sta FAST
        LBSR TVON
        ANDCC #$EF      ;enable IRQ
        PULS X,Y,PC
        ENDPROC

; display BUFFER1 in raw hex format
;
        extern MEM_LINE
RAW PROC
        LOCALVAR L_CNT
        CHAR L_PTR,3
        STACKVAR
%if DEBUG eq 1
;
        ldy MEM_LINE
        lda MEM_LINE+2
        sta BUFFER1_BLOCK
        LBSR CLS
..E     CLR YPOS
..A     CLR XPOS
        LBSR MOVE
        lda BUFFER1_BLOCK    ;print block number
        LBSR ..pBINHEX
        lda #':'
        lbsr ChrOut
        TFR Y,D              ;print address
        subd #BUF1ADR
        PSHS B
        LBSR ..pBINHEX
        PULS A
        LBSR ..pBINHEX
        LDA #32
        LBSR ChrOut
        LDA #EVNSIZE
        STA L_CNT,S
..B     LDA ,Y+
        LBSR ..pBINHEX
        LDA #32
        LBSR ChrOut
        DEC L_CNT,S
        BNE ..B
        LDA YPOS
        INCA
        CMPA #16
        BEQ ..C
        STA YPOS
        BRA ..A
..C     LBSR getchar
        CMPA #UP
        BNE ..D
        LEAY -$100,Y
        cmpy #BUF1ADR
        bhs ..E
        leay $2000,y
        dec BUFFER1_BLOCK
        BRA ..E
..D     CMPA #DOWN
        BNE ..F
        cmpy #BUF1ADR+$2000
        lblo ..E
        leay -$2000,y
        inc BUFFER1_BLOCK
        LBRA ..E
..F
%if 1 eq 0
		cmpa #'1'            ;select buffer1
		bne ..G
		lda BUFFER1_BLOCK
		anda #$0f
		sta BUFFER1_BLOCK
		bra ..w
..G     cmpa #'2'            ;select buffer2
        bne ..H
        lda BUFFER1_BLOCK
        anda #$0f
        ora #$10
        sta BUFFER1_BLOCK
        bra ..w
..H     cmpa #'3'            ;select buffer3
        bne ..Z
        lda BUFFER1_BLOCK
        anda #$0f
        ora #$20
        sta BUFFER1_BLOCK
..w     leay -$80,y
        lbra ..E
%endif
..Z     LDA #1               ;request screen update
        ENDS
..pBINHEX
        LEAX L_PTR,S
        LBSR BINHEX
        LBSR PUTS
%endif
        ENDS
        ENDPROC

        global NEWIRQ
NEWIRQ  proc
        ldb $ff02
        clr $ff02
; check for a keypres
        lda $ff00
        stb $ff02
        anda #$7f
        cmpa #$7f
        beq ..nokey
; keypress detected
        tst ..blank_flag     ;don't restore if already restored
        bne ..a
; screen is blank, so restore screen
        ldx #..palette
        ldy #$ffb0
        ldb #16
..a1    lda ,x+
        sta ,y+
        decb
        bne ..a1
        lda #1
        sta ..blank_flag
;        clr ..palette+12
; set timer delay back to maximum and exit
..a     ldd SCREEN_BLANK_DELAY
        std ..timer
        bra ..z
..nokey ldd ..timer
        beq ..b
        subd #1
        std ..timer
        bra ..z
..b     tst ..blank_flag
        beq ..z
        ldx #$ffb0
        ldy #..palette
        ldb #16
..b1    lda ,x               ;get current register value
        clr ,x+              ;clear register
        sta ,y+              ;save previous value
        decb
        bne ..b1
        clr ..blank_flag
..z     lda $ff00            ;clear IRQ interrupt flag
        sta KEYINP
;        lda 10,s ;*** put program counter on screen
;        ldx #$5e0 ;***
;        LBSR BINHEX ;***
;        lda 11,s ;***
;        ldx #$5e2 ;***
;        LBSR BINHEX ;***
        lda $ff92            ;clear GIME interrupt flag
        rti
;
..timer fdb $ffff
..palette fdb 0,0,0,0,0,0,0,0
..blank_flag fcb 1           ;equals 0 when the screen is blanked
        endproc

SCREEN_BLANK_DELAY fdb 6000  ;number of interrupts till screen blank

; set the MIDI filter
;
        global SetFiltr
SetFiltr proc
        LOCALVAR L_BIT,l_go,l_pos
        STACKVAR
        lda XPOS
        ldb YPOS
        std l_pos,s
; set up the box to show current filter state
        LDX #..qq
        LDA MFILTER
        LSRA
..C     LSRA
        BCS ..D
        LDB #32
        BRA ..E
..D     LDB #'X'
..E     STB [4,X]
        LDX 6,X
        BNE ..C
; get user input
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        CMPD #BREAK
        BEQ ..Z
        LDA #2
        STA L_BIT,S
        LDA #'X'
        LDB #1               ;set note off filter on
        LDX #..qq            ;point to first input
..A     CMPA [4,X]
        BNE ..B
        ORB L_BIT,S
..B     LSL L_BIT,S
        LDX 6,X
        BNE ..A
        STB MFILTER
..Z     LBSR ClrBox
        ldd l_pos,s
        sta XPOS
        stb YPOS
        lbsr MOVE
        CLRA
        CLRB
        ENDS
..aa    FDB 4,2,24,13,..bb,..qq
..bb    FDB 6,2,..cc,$+8
        FDB 2,4,..dd,$+8
        FDB 2,5,..ee,$+8
        FDB 2,6,..ff,$+8
        FDB 2,7,..gg,$+8
        FDB 2,8,..hh,$+8
        FDB 2,9,..ii,$+8
        FDB 2,10,..jj,0
..cc    FCC "MIDI FILTER"
        FCB 0
..dd    FCC "[ ] NOTE ON/OFF"
        FCB 0
..ee    FCC "[ ] KEY PRESSURE"
        FCB 0
..ff    FCC "[ ] CONTROL CHANGE"
        FCB 0
..gg    FCC "[ ] PROGRAM CHANGE"
        FCB 0
..hh    FCC "[ ] CHANNEL PRESSURE"
        FCB 0
..ii    FCC "[ ] PITCH WHEEL"
        FCB 0
..jj    FCC "[ ] SYSTEM 'EVENT'"
        FCB 0
..qq    FDB 3,4,..rr,$+10,0
        FDB 3,5,..ss,$+10,$-10
        FDB 3,6,..tt,$+10,$-10
        FDB 3,7,..uu,$+10,$-10
        FDB 3,8,..vv,$+10,$-10
        FDB 3,9,..ww,$+10,$-10
        FDB 3,10,..xx,0,$-10
..rr    FCC " "
        FCB 0
..ss    FCC " "
        FCB 0
..tt    FCC " "
        FCB 0
..uu    FCC " "
        FCB 0
..vv    FCC " "
        FCB 0
..ww    FCC " "
        FCB 0
..xx    FCC " "
        FCB 0
        ENDPROC

; ask for number of beats/measure
;
SetMeasure PROC
        STACKVAR
        clra
        ldb BAR
        ldx #..dd
        lbsr BINDEC
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        BEQ ..Z
; convert beats/measure to ticks
        LDX #..dd
        LBSR atoi
        STB BAR
        STD ARG1
        CALL Mult,ARG1,TIMEBASE
        STD MEASURE
        CLRA
        CLRB
..Z     ENDS
;
..aa    FDB 6,5,20,5,$+12,..bb
        FDB 2,2,..cc,0
..bb    FDB 16,2,..dd,0,0 ;input string
..cc    FCC "BEATS/MEASURE="
        FCB 0
..dd    FCC "4 "
        FCB 0
        ENDPROC

SetKey PROC
        STACKVAR
        lda KEY
        sta ..cc
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        BEQ ..Z
        LDA ..cc
        CMPA #'S'
        BEQ ..A
        CMPA #'F'
        BEQ ..A
        LBSR SndErr
        LDA #'S'
..A     STA KEY
..Z     CLRA
        CLRB
        ENDS
;
..aa    FDB 6,5,20,5,$+12,..bb
        FDB 2,2,$+8,0
        FCC "FLAT OR SHARP?"
        FCB 0
..bb    FDB 17,2,..cc,0,0
..cc    FCC "F"
        FCB 0
        ENDPROC

About PROC
        rts
%if 0
        CALL SetBox,#..aa
        LBSR getchar
        LBSR ClrBox
        CLRA
        CLRB
        rts
..aa    FDB 0,1,32,15,..bb,0
..bb    FDB 7,2,..cc,$+8
        FDB 7,3,..dd,$+8
        FDB 7,4,..ee,$+8
        FDB 7,6,..ff,$+8
        FDB 7,7,..gg,$+8
        FDB 7,8,..hh,$+8
        fdb 7,9,..ii,$+8
        fdb 7,11,..jj,$+8
        fdb 7,12,..kk,0
..cc    FCC "PROGRAM WRITTEN BY"
        FCB 0
..dd    FCC "   LESTER HANDS"
        FCB 0
..ee    fcc "  COPYRIGHT 1990"
        fcb 0
..ff    FCC "  MANY THANKS TO"
        FCB 0
..gg    fcc "    MIKE  WARD"
        fcb 0
..hh    fcc "   MIKE BRIDGES"
        FCB 0
..ii    FCC "    VAL  BURKE"
        fcb 0
..jj    FCC "PLEASE DON'T  GIVE"
        FCB 0
..kk    FCC "   COPIES AWAY!"
        FCB 0
%endif
        ENDPROC

; copy from string X to string Y, maximum of B bytes
        global strncpy
strncpy proc
        tstb
        beq ..done
..loop  lda ,x+
        sta ,y+
        beq ..done
        decb
        bne ..loop
..done  rts
        endproc

        global ToggleTapeIO
ToggleTapeIO proc
        ldy #MENU_IO
        ldb #4
        tst TAPE_IO_FLAG
        beq ..tape
        lda #$3e
        sta $ffa6
        ldd $c000
        cmpd #'DK'
        bne ..error
        ldx #..tmsg
        lbsr strncpy
        clra
        bra ..done
..error lbsr SndErr
        clra
        clrb
        rts
..tape  ldx #..dmsg
        lbsr strncpy
        lda #1
..done  sta TAPE_IO_FLAG
        lbsr SndOK
        clra
        clrb
        rts
;
..tmsg  fcc "DISK"
        fcb 0
..dmsg  fcc "TAPE"
        fcb 0
        endproc

        global STACK
STACK   EQU $7ffe

        END START

; end of file: CMP/TXT
