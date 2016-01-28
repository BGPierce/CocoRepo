; display.asm
; For CoCo MIDI 3
; (C) 1988 by Lester Hands

%include "macros.h"
%include "cmp.h"

        extern SNDERR,KEY,MIDI_OUT,MIDISTAT,MESSAGES
        extern HEXSBIN,GETSTR,STRPAD,BINHEX,PBINDEC,REMAIN
        extern NOTEPOS,TINVERT,BLK_END,BLK_STRT,CHKFILT
        extern GETPOS,EraseLine,NEXTEVNT,YPOS,MOVE,XPOS
        extern MEASURE,MULT,ATOI,BAR,EX_TIME1,EX_TIME2,MultExTime
        extern ARG1,ARG2,ARG3,PUTS,BINDEC,DIVIDE,TIMEBASE
        extern CompareExTimes,ChrOut,MapDataOut,MapDataIn

; extended memory address of top display line
;
        global MEM_LINE
MEM_LINE fdb BUF1ADR         ;extended address
        fcb 0
        fcb 0                ;extended time
        fdb 0

; update MEM_LINE
; assumes that register X points to the event displayed
; at the top of the display
;
        global UpdateMEM_LINE
UpdateMEM_LINE proc
        stx MEM_LINE
        lda BUFFER1_BLOCK
        sta MEM_LINE+2
        lda 7,x
        anda #$f0
        sta MEM_LINE+3
        ldd 0,x
        std MEM_LINE+4
        rts
        endproc

; make ascii note length: X points to a note event
; if S_STR=0 then print it,
; else store letters in S_STR
;
        global NoteLen
NoteLen PROC
        LOCALVAR L_TIK,L_PTR
        CHAR L_STR,7
        STACKVAR S_PTR
        LDY S_PTR,S          ;decide where ascii
        BNE ..C              ;letters will be put
        LEAY L_STR,S
..C     STY L_PTR,S
        LDX 5,X              ;get note length
        CALL Divide,REGX,TIMEBASE
        ldx REMAIN
        STX L_TIK,S          ;remainder is # ticks
        LDX L_PTR,S
        LBSR BINDEC          ;convert # beats
..D     TST ,X+              ;look for end of string
        BNE ..D
        LDA #':'
        STA -1,X
        LDD L_TIK,S
        LBSR BINDEC          ;convert # ticks
        LDX L_PTR,S
        CLRB
..A     INCB
        TST ,X+              ;Look for end of string
        BNE ..A
        LDX L_PTR,S
        CMPB #6
        BLS ..B
        LDA #'+'
        CLRB
        STD 4,X
..B     LDD S_PTR,S          ;are we supposed to
        BNE ..Z              ;print this?
        LBSR PUTS
..Z     ENDS
        ENDPROC

; Print time as ASCII string (bar/beat:tick format)
; S_EXT is the address of the extended time structure (3 bytes)
;
        global PrintTime
PrintTime PROC
        localvar
        CHAR L_STR,10
        STACKVAR S_EXT
        ldd S_EXT,S
        std ARG2
        LEAX L_STR,S
        CALL ConvertBinaryTime,REGX,ARG2
..c     LBSR PUTS
        ENDS
        ENDPROC

; convert time to ASCII string (bar/beat:tick)
; S_EXT is a pointer to an extended time structure
; pointer to string storage space (S_PTR) required
;
        global ConvertBinaryTime
ConvertBinaryTime PROC
        LOCALVAR L_TK,L_BT
        char l_ext,3
        STACKVAR S_PTR,S_EXT
        ldx S_EXT,s
        lda 0,x
        lsra
        lsra
        lsra
        lsra
        sta l_ext,s
        ldd 1,x
        std l_ext+1,s
        ldy #0
..a1    leay 1,y             ;do an extended divide
        ldd l_ext+1,s
        subd TIMEBASE
        std l_ext+1,s
        bcc ..a1
        dec l_ext,s
        bpl ..a1
..a2    leay -1,y
        ldd l_ext+1,s
        addd TIMEBASE
        std L_TK,S           ;put ticks (remainder) in L_TK
        sty ARG1             ;put beats in ARG1
        CLRA
        LDB BAR
        STD ARG2
        CALL Divide,ARG1,ARG2
        ldx REMAIN
        STX L_BT,S           ;put beats in L_BT
        LDX S_PTR,S
        addd #1              ;bar # starts with 1
        LBSR BINDEC
..A     TST ,X+              ;move X to point to
        BNE ..A              ;first zero byte
        LDA #'/'
        STA -1,X
        LDD L_BT,S
..C     INCB                 ;beat # starts with 1
        LBSR BINDEC
..B     TST ,X+
        BNE ..B
        LDA #':'
        STA -1,X
        LDD L_TK,S
        LBSR BINDEC
        ENDS
        ENDPROC

; convert ASCII note length string (beat:tick)
; alternate formats are "beat" and ":tick"
; value returned in D
;
        global CnvNotLn
CnvNotLn PROC
        LOCALVAR L_ACUM
        STACKVAR S_PTR
        CLRA
        CLRB
        STD L_ACUM,S
..A     LDX S_PTR,S
        LBSR atoi
        STD ARG1
        BEQ ..B
        CALL Mult,ARG1,TIMEBASE
        ADDD L_ACUM,S
        STD L_ACUM,S
; look for ":"
..B     LDX S_PTR,S
..C     LDA ,X+
        BEQ ..Z
        CMPA #':'
        BNE ..C
        LBSR atoi
        ADDD L_ACUM,S
        STD L_ACUM,S
..Z     LDD L_ACUM,S
        ENDS
        ENDPROC

; convert ASCII time string (measure/beat:tick); S_PTR points to string
; value returned in extended time pointed to by S_EXT
;
        global ConvertAsciiTime
ConvertAsciiTime PROC
        stackvar S_PTR,S_EXT
        ldx S_EXT,s
        clra
        clrb
        std 0,x
        sta 2,x
; look for "/" in time
        LDX S_PTR,S
        tfr x,y
..A     LDA ,Y+
        BEQ ..B
        CMPA #'/'
        BNE ..A
        STY S_PTR,S
        LBSR atoi
        cmpd #0
        beq ..a1
        subd #1              ;measure number starts with 1
..a1    std ARG1
        clra
        ldb BAR
        std ARG2
        call Mult,ARG1,ARG2
        ldx S_EXT,s
        std 1,x
; convert beat #
..B     LDX S_PTR,S
        LBSR atoi
        cmpd #0
        BEQ ..b1
        subd #1              ;beat # starts with 1
..b1    ldx S_EXT,s
        addd 1,x
        std 1,x
        CALL MultExTime,REGX,TIMEBASE
; look for ":"
        ldx S_PTR,s
..C     lda ,X+
	beq ..Z
	cmpa #':'
	bne ..C
	lbsr atoi
        ldx S_EXT,s
	addd 1,x
        std 1,x
        bcc ..Z
        lda #$10
        adda 0,x
        sta 0,x
..Z     ldd 1,x
        cmpd #$ffff          ;added to prevent premature end marker
        bne $+3
        decb
        std 1,x
        ENDS
        ENDPROC


; display page of events starting at cursor position
;
        global DspPage
DspPage PROC
        LOCALVAR L_CURS,l_b1b
        STACKVAR s_ptr
        lda BUFFER1_BLOCK
        sta l_b1b,s
        lda XPOS             ;save current
        ldb YPOS             ;cursor position
        std L_CURS,s
        CLR XPOS
..A     LBSR MOVE
        CALL Note,<s_ptr,s>
        CMPD #0              ;make sure an event was displayed
        BEQ ..B
..A1    LDD <[s_ptr,s]>      ;check for end of music
        CMPD #$FFFF
        BEQ ..C
        LDA YPOS             ;check for end of screen
        INCA
        CMPA #16
        BEQ ..Z
        STA YPOS
..B     pshs x
        ldx s_ptr+2,s
        lbsr NextEvnt
        stx s_ptr+2,s
        puls x
        BRA ..A
..C     clr XPOS
..C1    LDA YPOS            ;if end of music found
        INCA                ;make sure bottom of
        CMPA #16            ;display is blank
        BHS ..Z
        STA YPOS
        LBSR MOVE
        LBSR EraseLine
        BRA ..C1
..Z     LDD L_CURS,S        ;restore cursor
        sta XPOS
        stb YPOS
        lbsr MOVE
        lda l_b1b,s
        sta BUFFER1_BLOCK
        ENDS
        ENDPROC

; display event information in English
; s_ptr points to event in MIDI buffer
; returns 0 if nothing displayed
; returns 1 if event displayed
;
        global Note
Note PROC
        LOCALVAR L_FILT,l_acum
        STACKVAR s_ptr
        LDX s_ptr,s          ;register X points to current event
; check filter
..A     LDD ,X
        CMPD #$FFFF
        BEQ ..C
        LBSR CHKFILT
        CMPB #8
        LBHI ..X
        TSTA
        LBNE ..X
        STD L_FILT,S
; check block markers, set invert flag if needed
..C     ldd #$ffff
        cmpd BLK_END+1
        beq ..D
        cmpd 0,x
        beq ..D
        call CompareExTimes,#BLK_STRT
        cmpd #-1
        beq ..D
        call CompareExTimes,#BLK_END
        cmpd #1
        beq ..D
        lda #$ff
        sta TINVERT
; update MEM_LINE
..D     tst YPOS
        bne ..D1
        lbsr UpdateMEM_LINE
; display time
..D1    LDA NOTEPOS
        STA XPOS
        LBSR MOVE
        LBSR EraseLine
        LDD ,X               ;get time
        CMPD #$FFFF
        BNE ..B              ;check for ending
        LDX #..jj
        LBSR PUTS
        BRA ..Y
..B     lda 7,x
        anda #$f0
        sta EX_TIME1
        ldd 0,x
        std EX_TIME1+1
        clra
        CALL PrintTime,#EX_TIME1
; lookup address of display routine
        LDD L_FILT,S
        LDU #..aa
        LSLB                 ;convert event #
        LSLB                 ;to offset
        LEAU B,U
; display the event identifier
        lda NOTEPOS+1
        sta XPOS
        lbsr Move
        LDA ,U+
        lbsr ChrOut
        lda ,u+
        lbsr ChrOut
        lda #'='
        lbsr ChrOut
        JSR [,U]
        BRA ..Y
..X     CLRA
        CLRB
        BRA ..Z
..Y     LDD #1
..Z     CLR TINVERT
        ENDS
;
; table of data routine addresses (absolute)
..aa    FDB 'NF',DSPNOFF     ;Note off
        FDB 'NO',DSPNON      ;Note on
        FDB 'KP',DSPKPRE     ;Key pressure
        FDB 'CC',DSPCTRL     ;Control change
        FDB 'PC',DSPEVN1     ;Program change
        FDB 'CP',DSPEVN1     ;Channel pressure
        FDB 'PW',DSPPWHL     ;Pitch wheel
        FDB 'SE',DSPSYS      ;System event
;
..jj    FCC "END OF BUFFER"
        FCB 0
        ENDPROC

; display a system event
; ENTRY: X=pointer to MIDI event
; FORMAT: time,status byte (channel=ID)
;        data (2 bytes) such as metronome tempo
;        raw data (2 bytes) such as CPERIOD or ptr.
;        and track #
; ID byte assignments:
;        0=TEMPO 1=CLOCK 2=LINK 3=MESSG 4=PAUSE
;        5=BYTES 6=SYX   7=GOTO
;
        global DSPSYS
DSPSYS PROC
        localvar
        CHAR L_STR,6
        STACKVAR
; display identifier
        LDB 2,X
        ANDB #$0F
        CMPB #MAXSYS         ;check for maximum
        BHI ..A              ;supported type #
        LDX #..aa
        LDA #7
        MUL
        ABX
        BRA ..B
..A     LDX #..bb
..B     pshs x
        LBSR PUTS
        puls y
; now display data portion
        LDA NOTEPOS+3
        STA XPOS
        LBSR MOVE
        ldx S.X,s
        jsr [5,y]
..Z     ENDS
;
..aa    FCC "TMPO"
        FCB 0
        fdb DspTEMPO
        FCC "CLCK"
        FCB 0
        fdb DspCLOCK
        FCC "LNK"
        FCB 0,0
        fdb DspMESSG
        FCC "MSG"
        FCB 0,0
        fdb DspMESSG
        FCC "PAUS"
        FCB 0
        fdb DspNothing
        FCC "BYTE"
        FCB 0
        fdb DspBYTES
        FCC "SYX"
        FCB 0,0
        fdb DspMESSG
%if GOTO_VERSION eq 1
        fcc "GOTO"
        fcb 0
        fdb DspGOTO
%endif
..bb    FCC "UNDF"
        FCB 0
        fdb DspNothing
        ENDPROC

DspTEMPO proc
DspCLOCK
        LDD 3,X
        LBSR pBINDEC
        rts
        endproc

DspNothing proc
        rts
        endproc

; convert number of bytes in B pointed to by Y
; to a hex string pointed to by X. $FF is an end
; marker for the byte array.
;
        LOCALVAR L_CNT
        global CnvBytes
CnvBytes PROC
        STACKVAR
        STB L_CNT,S
..A     LDA ,Y+ ;get byte
        CMPA #$FF ;quit if end marker
        BEQ ..B
        LBSR BINHEX
        LEAX 2,X
        LDA #32 ;insert a space
        STA ,X+
        DEC L_CNT,S
        BNE ..A
..B     CLR ,X ;end of string marker
        ENDS
        ENDPROC

%if GOTO_VERSION eq 1
DspGOTO proc
        pshs x
        leax 3,x
        lda #-1
        call PrintTime,REGX
;        lda NOTEPOS+5
;        sta XPOS
;        lbsr MOVE
;        clra
;        ldb 6,x
;        lbsr pBINDEC
        puls x,pc
        endproc
%endif

; display the MIDI bytes of a BYTES system event
; ENTRY: X points to event
;
        global DspBYTES
DspBYTES PROC
        LOCALVAR
        CHAR L_PTR,13
        STACKVAR
        LEAY 3,X ;point to bytes
        STY ARG2
        LEAX L_PTR,S
        CALL CnvBytes,#4,ARG2,REGX
        LBSR PUTS
        ENDS
        ENDPROC

; display a message for an event/link event
; ENTRY: X points to event
;
        global DspMESSG
DspMESSG PSHS X
        dec XPOS
        lbsr Move
        LDA 3,X              ;get message #
        LDB #16
        MUL
        LDX MESSAGES
        LEAX D,X
        lbsr MapDataIn
        LBSR PUTS
        lbsr MapDataOut
        inc XPOS
        lbsr Move
        PULS X,PC

; display note off
; ENTRY: X=pointer to MIDI event
;
        global DSPNOFF
DSPNOFF LDA 3,X ;get MIDI pitch
        LBSR pCNVPTCH
        LBRA DSPCHAN

; display note on
; ENTRY: X=pointer to MIDI event
;
        global DSPNON
DSPNON  PSHS X
        LDA 3,X ;get MIDI pitch
        LBSR pCNVPTCH
        LBSR DSPCHAN
        LBSR DSPE3
; display length of note
        LDA NOTEPOS+5
        STA XPOS
        LBSR MOVE
        CALL NoteLen,#0
        PULS X,PC

; display key pressure
; ENTRY: X=pointer to MIDI event
;
        global DSPKPRE
DSPKPRE LDA 3,X ;get MIDI pitch
        LBSR pCNVPTCH
        LBSR DSPCHAN
        LBRA DSPE3

; display control change
; ENTRY: X=pointer to MIDI event
;
        global DSPCTRL
DSPCTRL PSHS X
        CLRA
        LDB 3,X ;get MIDI pitch
        LBSR pBINDEC
        LBSR DSPCHAN
        LBSR DSPE3
        PULS X,PC

; display pitch wheel event
; ENTRY: X points to the MIDI event
;
        global DSPPWHL
DSPPWHL LDB 3,X ;get LSB value
        LSLB
        LDA 4,X ;get MSB value
        LSRA
        RORB
        LBSR pBINDEC
        LBRA DSPCHAN

; display an event that has only a single data byte
; ENTRY: X points to the MIDI event
;
        global DSPEVN1
DSPEVN1 PSHS X
        CLRA
        LDB 3,X
        LBSR pBINDEC
        LDX 0,S
        LBSR DSPCHAN
        PULS X,PC

; display the channel number
; ENTRY: X points to the MIDI event
;
        global DSPCHAN
DSPCHAN PSHS X
        LDA NOTEPOS+3
        STA XPOS
        LBSR MOVE
        LDB 2,X ;get status byte
        ANDB #$0F ;keep channel #
        INCB
        CLRA
        LBSR pBINDEC
        PULS X,PC

; display 3rd item in an event
; ENTRY: X=pointer to MIDI event
;
        global DSPE3
DSPE3   PSHS X
        LDA NOTEPOS+4
        STA XPOS
        LBSR MOVE
        CLRA
        LDB 4,X ;get (velocity)
        LBSR pBINDEC
        PULS X,PC

; Play a single note; s_ptr points to an event
;
        LOCALVAR L_CNT
        global PlayNote
PlayNote PROC
        STACKVAR s_ptr
        LDX s_ptr,S
        LEAX 2,X
        LDA #3
        STA L_CNT,S
..A     CLR MIDISTAT
        LDA ,X+
        CMPA #$F0 ;ignore system events
        BHS ..Z
        CMPA #$C0 ;check status byte
        BLO ..F ;to determine number
        CMPA #$DF ;of bytes to send
        BHI ..F
        DEC L_CNT,S
..F     LBSR MIDI_OUT
        CLRB
..B     DECB
        BNE ..B
        DEC L_CNT,S
        BNE ..A
        LDX s_ptr,S
        LDA 2,X ;did we play a note on?
        CMPA #$9F
        BHI ..Z
; note length delay
        LDD #$5000
..C     SUBD #1
        NOP
        BNE ..C
; note off
        LEAX 2,X
        LDA ,X+
        LBSR MIDI_OUT
        LDB #2
..D     CLRA
..E     DECA
        BNE ..E
        LDA ,X+
        CMPB #1
        BNE ..G
        CLRA
..G     PSHS B
        LBSR MIDI_OUT
        PULS B
        DECB
        BNE ..D
..Z     ENDS
        ENDPROC

; print converted MIDI pitch
; input in A
;
        global pCNVPTCH
pCNVPTCH:
        pshs x
        leas -4,s
        tfr s,x
        LBSR CNVPITCH
        LBSR PUTS
        leas 4,s
        puls x,pc

; Convert MIDI pitch to keyboard (ASCII) representation
; Input in register A
; ASCII string written to memory pointed to by X
;
        global CNVPITCH
CNVPITCH PROC
        PSHS X,Y
        CLRB
..A     INCB
        SUBA #12 ;count the # of octaves
        BCC ..A
..B     ADDA #12
        DECB
        PSHS A ;multiply note # by 3
        LSLA
        ADDA ,S+
        PSHS B
        LDB KEY
        CMPB #'S'
        BEQ ..K
        LDY #..bb
        BRA ..L
..K     LDY #..aa
..L     LEAY A,Y
        LDA ,Y+
        STA ,X+
        LDA ,Y
        BEQ ..C
        STA ,X+
..C     PULS A
        ADDA #'0'
        STA ,X+
..Z     CLR ,X
        PULS X,Y,PC
;
..aa    FCC "C"
        fcb 0,0
        FCC "C#"
        FCB 0
        FCC "D"
        FCB 0,0
        FCC "D#"
        FCB 0
        FCC "E"
        FCB 0,0
        FCC "F"
        FCB 0,0
        FCC "F#"
        FCB 0
        FCC "G"
        FCB 0,0
        FCC "G#"
        FCB 0
        FCC "A"
        FCB 0,0
        FCC "A#"
        FCB 0
        FCC "B"
        FCB 0,0
;
..bb    FCC "C"
        FCB 0,0
        FCC "D-"
        FCB 0
        FCC "D"
        FCB 0,0
        FCC "E-"
        FCB 0
        FCC "E"
        FCB 0,0
        FCC "F"
        FCB 0,0
        FCC "G-"
        FCB 0
        FCC "G"
        FCB 0,0
        FCC "A-"
        FCB 0
        FCC "A"
        FCB 0,0
        FCC "B-"
        FCB 0
        FCC "B"
        FCB 0,0
;
; convert ASCII pitch representation to binary
; ENTRY: X=pointer to ASCII string
; EXIT:  A=binary equivalent
;
        global CNVNOTE
CNVNOTE PSHS X,Y
        LDA ,X+
        CMPA #'A' ;check for valid entry
        BLO ..G
        CMPA #'G'
        BHI ..G
        LDB ,X
        CMPB #'-'
        BNE ..I
        LDY #..bb
        LDB #1
        BRA ..D
..I     LDY #..aa
        CLRB
; find entry in table
..D     CMPA ,Y
        BEQ ..E
        INCB
        LEAY 3,Y
        BRA ..D
..E     LDA ,X+
        CMPA #32
        BEQ ..E
        CMPA #'#' ; check for sharp
        BNE ..F
        INCB
        LDA ,X
        BRA ..M
..F     CMPA #'-' ;check for flat
        BNE ..M
        DECB
        LDA ,X
..M     PSHS B
        SUBA #'0' ;convert octave to binary
        LDB #12
        MUL
        ADDB ,S+
        TFR B,A
        BRA ..H
..G     LBSR SndErr
        LDA #64
..H     PULS X,Y,PC
        ENDPROC

%if 1 eq 0
; Display debugging info
; S_PTR points to a display structure
; Format of debug structure:
;   XPOS,YPOS: byte
;   DataCount: byte
;   DataPointer: word
;
        extern EraseLine,getchar,ChrOut
        global DebugDisplay
DebugDisplay proc
        localvar l_cnt,l_pos
        char l_ptr,3
        stackvar S_PTR
;
        lda XPOS
        ldb YPOS
        std l_pos,s
        ldx S_PTR,s
        lda ,x+
        sta XPOS
        lda ,x+
        sta YPOS
        lbsr Move
        lbsr EraseLine
        lda ,x+
        sta l_cnt,s
        ldy ,x
..a     lda ,y+
        leax l_ptr,s
        lbsr BINHEX
        lbsr PUTS
        lda #' '
        lbsr ChrOut
        dec l_cnt,s
        bne ..a
        ldd l_pos,s
        sta XPOS
        stb YPOS
        lbsr Move
;        lbsr getchar
        ends
        endproc
%endif

        end

; end of file: DISPLAY.ASM
