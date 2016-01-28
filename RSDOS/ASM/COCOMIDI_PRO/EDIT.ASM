; EDIT.asm
; Edit the MIDI buffer
; For CoCo MIDI Pro
; (C) 1988 by Lester Hands

%include "macros.h"
%include "cmp.h"

        extern SNDOK,BLK_END,BLK_STRT,STRTRIM,NOTELEN
        extern CNVBYTES,HEXSBIN,CPCALC,ATOI,BINDEC,CNVNOTE,CNVPITCH
        extern GETSTR,STRPAD,ConvertBinaryTime,GETCHAR,SNDERR,CNVNOTLN
        extern ConvertAsciiTime,CLRBOX,BOXINP,SETBOX,SCROLDWN,SCROLUP
        extern PLAYNOTE,KILLNOTE,EK_BLOCK,MFILTER,MESSAGES
        extern TRACK,XPOS,YPOS,_PLAY,ARG2,DIVIDE,TIMEBASE
        extern MEM_LINE,_RECORD,ARG1,FILT_FLG
        extern DOCMD,INKEY,MOVE,XPOS,TRAK_FLG,NOTE,DIRECTORY
        extern DSPPAGE,GETPOS,CLS,CompareExTimes
        extern SetFiltr,EX_TIME1,DivideExTime,MultExTime,FindEndBuffer1
        extern Working,_blockCopy,_blockDelete,MergeBuffers,UpdateMEM_LINE
        extern MapDataIn,MapDataOut,SetAnnotation,FileInfo,ClearBuffer3

; editing positions (XPOS) for events
;
        global NOTEPOS
NOTEPOS FCB 0,11,14,19,22,26,$FF

; edit MIDI buffer
;
        global Edit
Edit PROC
        pshs x
        clr XPOS
        clr YPOS
        lbsr DisplayEntirePage
        ldx MEM_LINE
        lda MEM_LINE+2
        sta BUFFER1_BLOCK
; display and edit event
..A     CALL Note,REGX ;display note event
        CMPD #0
        BNE ..D
        lbsr NextEvnt
        BRA ..A
..D     CALL EdEvnt,REGX
        TFR D,X
        CMPD #$FFFF ;check for BREAK
        BNE ..A
        CLR TRAK_FLG ;enable filter
..Z     ldd #1 ;request screen update
        puls x,pc
        ENDPROC

; Edit a displayed event
; Returns -1 if BREAK is pressed
; otherwise returns current event address
;
        global EdEvnt
EdEvnt PROC
        LOCALVAR L_CNT,l_pos
        STACKVAR S_PTR
; set cursor position to first editing position
        LDY #NOTEPOS
        LDB ED_POS
        LDA B,Y
        STA XPOS
; get keyboard input
..A     LBSR MOVE
..B     LBSR INKEY
        DEC ..aa
        BNE ..C
        LDB #10              ;flashing cursor
        STA ..aa
        LDB [CURSADR]
        EORB #$40
        STB [CURSADR]
..C     TSTA
        BEQ ..B
        LDY >CURSADR
        LDB 1,Y
        ANDB #$40
        PSHS B
        LDB ,Y
        ANDB #$BF
        ORB ,S+
        STB ,Y
; check for break
        CMPA #BREAK
        BNE ..D
        LDD #$FFFF
        STD S_PTR,S
        BRA ..Z
; do command
..D     tfr a,b              ;put look-up value into register B
        ldy #ED_KEYS
        pshs y               ;put address of look-up table on stack
        LBSR DoCmd
        LEAS 2,S
        CLR FILT_FLG
        STX S_PTR,S
        STX ED_ADR
; redisplay current line
        CALL Note,REGX
; check cursor position
        LBSR CHKPOS
        LDY #NOTEPOS
        LDB ED_POS
        LDA B,Y
        STA XPOS
        BRA ..A
..Z     LDD S_PTR,S
        ENDS
..aa    FCB 10               ;cursor flash count
        ENDPROC

; table for keypress routines when editing
ED_KEYS FCB LEFT
        FDB EK_LEFT
        FCB RIGHT
        FDB EK_RIGHT
        FCB 'P'
        FDB EK_PLAY
        FCB 'R'
        FDB EK_RECRD
        FCB 32
        FDB EK_SPACE
        FCB UP
        FDB EK_UP
        FCB 'I'
        FDB EK_INSRT
        FCB 'D'
        FDB EK_DEL
        FCB 13
        FDB EK_ENTER
        FCB DOWN
        FDB EK_DOWN
        FCB 'M'
        FDB BlkMark
        FCB 'C'
        FDB BlkClr
        FCB SHFTDOWN
        FDB EK_SDWN
        FCB SHFTUP
        FDB EK_SUP
        FCB '/'
        FDB EK_HELP
        FCB '?'
        FDB EK_HELP
        FCB 'B'
        FDB EK_BLOCK
        FCB 'G'
        FDB EK_GOTO
        FCB 'S'
        FDB EK_SLIDE
        FCB 'A'
        FDB EK_ALL
        FCB 'K'
        FDB KillNote
        fcb 'F'
        fdb EK_FILTER
        fcb 'E'
        fdb DIRECTORY
        fcb 'L'
        fdb EK_MarkAll
        FCB 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; All of the following routines that start with
; EK_ are called from EdEvnt through DoCmd. They
; all expect that register X points to the current
; MIDI event, and they all return that pointer.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        global EK_DOWN
EK_DOWN PROC
        pshs x
        lbsr NextEvnt
        CMPX ,S++
        BEQ ..Z
        lda YPOS
        cmpa #15
        BNE ..Y
        LBSR SCROLUP
        lda BUFFER1_BLOCK
        pshs a,x
        lda MEM_LINE+2
        sta BUFFER1_BLOCK
        ldx MEM_LINE
        lbsr NextEvnt
        lbsr UpdateMEM_LINE
        puls a,x
        sta BUFFER1_BLOCK
        bra ..Z
..Y     inc YPOS
..Z     rts
        ENDPROC

EK_UP PROC
        pshs x
        lbsr PrevEvent
        cmpx ,s++
        BEQ ..Z
        tst YPOS
        bne ..A
        lbsr SCROLDWN
        bra ..Z
..A     dec YPOS
..Z     rts
        ENDPROC

        global EK_LEFT
EK_LEFT PROC
        PSHS X
        LDB ED_POS
        BEQ ..Z
        DECB
        STB ED_POS
        LDX #NOTEPOS
        LDA B,X
        STA XPOS
..Z     PULS X,PC
        ENDPROC

        global EK_RIGHT
EK_RIGHT PROC
        PSHS X
        INC ED_POS
        LBSR CHKPOS
        LDX #NOTEPOS
        LDA ED_POS
        LDB A,X
        BMI ..Z
        STB XPOS
..Z     PULS X,PC
        ENDPROC

EK_FILTER proc
        lbsr SetFiltr
        lbsr RedisplayPage
        rts
        endproc

EK_RECRD PROC
        lda FILT_FLG
        ldb TRAK_FLG
        pshs d
        lda BUFFER1_BLOCK
        pshs a
        ldd 0,x
        cmpd #$ffff
        bne ..A
        clra
        clrb
        std EX_TIME1
        clr EX_TIME1+1
        ldx #BUF1ADR
        bra ..B
..A     std EX_TIME1+1
        lda 7,x
        anda #$f0
        sta EX_TIME1
..B     CALL _Record,REGX,#EX_TIME1
        puls a
        sta BUFFER1_BLOCK
        call DspPage,REGX
        puls d
        sta FILT_FLG
        stb TRAK_FLG
        rts
        ENDPROC

        global EK_PLAY
EK_PLAY PROC
        lda BUFFER1_BLOCK
        pshs a,x
;save current extended time in EX_TIME1
        ldd 0,x
        std EX_TIME1+1
        lda 7,x
        anda #$f0
        sta EX_TIME1
;round off EX_TIME1 to nearest beat
        call DivideExTime,#EX_TIME1,TIMEBASE
        std EX_TIME1+1
        clr EX_TIME1
        call MultExTime,#EX_TIME1,TIMEBASE
;done with calculating start time so get on with playing!
        CALL _Play,REGX,#EX_TIME1
        TFR D,X
;update display only if a key is pressed
        lda $ff00
        anda #$7f
        cmpa #$7f
        beq ..d
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        LDA ..cc
        CMPA #'Y'
        beq ..d1
..d     lda 0,s
        sta BUFFER1_BLOCK
        bra ..z
..d1    lbsr PrevEvent
        lda BUFFER1_BLOCK
        sta MEM_LINE+2
        CLR XPOS
        CLR YPOS
        LBSR MOVE
        CALL DspPage,REGX
        stx 1,s
..z     puls b,x,pc
;
..aa    FDB 6,5,21,5,$+12,..bb
        FDB 2,2,$+8,0
        FCC "UPDATE DISPLAY?"
        FCB 0
..bb    FDB 18,2,..cc,0,0
..cc    FCC "Y"
        FCB 0
        ENDPROC

EK_SPACE PROC
        LDD ,X
        CMPD #$FFFF
        BEQ ..Z
        CALL PlayNote,REGX
        LBSR EK_DOWN
..Z     RTS
        ENDPROC

EK_INSRT PROC
        CALL Insert,REGX
        CALL DspPage,REGX
        LDA #1               ;request screen update
..Z     rts
        ENDPROC

EK_DEL PROC
        LBSR CHKFILT        ;D key (delete)
        TSTA
        BEQ ..B
        lbsr NextEvnt
..B     CALL Delete,REGX
        LBSR CHKFILT
        TSTA
        BEQ ..A
        lbsr NextEvnt
..A     CALL DspPage,REGX
        RTS
        ENDPROC

EK_ENTER CLRA
        LDB ED_POS
        STD ARG2
        CALL EdENTER,REGX,ARG2
        RTS

EK_SDWN CALL ShftMov,#EVNSIZE
        TFR D,X
        RTS

EK_SUP  CALL ShftMov,#-EVNSIZE
        TFR D,X
        RTS

        LOCALVAR L_CNT
        global ShftMov
ShftMov PROC
        STACKVAR L_DIR
        LDA #16
        STA L_CNT,S
..A     LDD L_DIR,S
        BMI ..B
        lbsr NextEvnt
        BRA ..C
..B     lbsr PrevEvent
..C     DEC L_CNT,S
        BNE ..A
        CLR XPOS
        CLR YPOS
        LBSR MOVE
        CALL DspPage,REGX
        TFR X,D
        ENDS
        ENDPROC

        global EK_GOTO
EK_GOTO PROC
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        BEQ ..Z
        ldd ..dd
        cmpa #'B'
        bne ..b
        pshs d
        ldd BLK_END+1
        cmpd #$ffff
        puls d
        bne ..a1
        lbsr SndErr
        bra ..Z
..a1    cmpb #'S'
        bne ..a
        ldx #BLK_STRT
        bra ..Y
..a     cmpb #'E'
        bne ..d
        ldx #BLK_END
        bra ..Y
..b     cmpa #'S'
        beq ..d
..c     cmpa #'E'
        bne ..d
        lbsr FindEndBuffer1
        lbsr PrevEvent
        ldd 0,x
        std EX_TIME1+1
        lda 7,x
        anda #$f0
        sta EX_TIME1
        bra ..d1
..d     call ConvertAsciiTime,#..dd,#EX_TIME1
..d1    ldx #EX_TIME1
..Y     call GoTo,REGX
        TFR D,X
		lbsr NextEvnt
		lbsr PrevEvent
..Y1    LBSR CLS
		CALL DspPage,REGX
..Z     rts
;
..aa    FDB 4,3,24,10,$+12,..bb
        FDB 2,2,..cc,..ee    ;text string
..bb    FDB 12,2,..dd,0,0    ;input string
..cc    FCC "GOTO TIME="
        FCB 0
..dd    FCC "1/1:0     "
        FCB 0
..ee    fdb 3,4,..ff,$+8
        fdb 3,5,..gg,$+8
        fdb 3,6,..hh,$+8
        fdb 3,7,..ii,0
..ff    fcc "S  = START"
        fcb 0
..gg    fcc "E  = END"
        fcb 0
..hh    fcc "BS = BLOCK START"
        fcb 0
..ii    fcc "BE = BLOCK END"
        fcb 0
        ENDPROC

EK_SLIDE PROC
        LOCALVAR l_abs
        char l_time,3
        char l_st,3
        char l_en,3
        STACKVAR
; ask user for slide time
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        lbeq ..Z
; check for negative sign
        clrb
        LDX #..dd
        LDA ,X
        CMPA #'-'
        BNE ..F
        leax 1,x
        ldb #$f0
..F     stb l_time,s
; convert ASCII time to binary
        CALL CnvNotLn,REGX
        CMPD #0              ;abort if time=0
        lbeq ..X
        tsta                 ;slide time >32767 not allowed!
        lbmi ..X
        std l_abs,s
        tst l_time,s
        bpl ..f1
        coma
        comb
        addd #1
..f1    std l_time+1,s
; check for maximum negative shift
        tst l_time,s
        bpl ..save
        ldx S.X,s            ;point X to current event
        lda 7,x
        anda #$f0
        bne ..save
        ldd l_abs,s
        cmpd 0,x
        lbhi ..X
; save block markers
..save  lda BLK_STRT
        sta l_st,s
        ldd BLK_STRT+1
        std l_st+1,s
        lda BLK_END
        sta l_en,s
        ldd BLK_END+1
        std l_en+1,s
; set new markers
        ldx S.X,s
        lda 7,x
        anda #$f0
        sta BLK_STRT
        ldd 0,x
        std BLK_STRT+1
        call FindEndBuffer1
        lbsr PrevAbsEvent
        lda 7,x
        anda #$f0
        sta BLK_END
        ldd 0,x
        std BLK_END+1
; cut track to paste buffer
        lbsr Working
        ldd l_time+1,s
        std ARG1
        lda l_time,s
        sta ARG2
        call _blockCopy,ARG1,ARG2
        lbsr _blockDelete
        lbsr MergeBuffers
        lbsr ClearBuffer3
        lda l_st,s
        sta BLK_STRT
        ldd l_st+1,s
        std BLK_STRT+1
        lda l_en,s
        sta BLK_END
        ldd l_en+1,s
        std BLK_END+1
        lbsr ClrBox
        lbsr RedisplayPage
        stx S.X,s
        bra ..Z
..X     lbsr SndErr
..Z     ends
;
..aa    FDB 5,5,23,5,$+12,..bb
        FDB 2,2,..cc,0
..bb    FDB 13,2,..dd,0,0
..cc    FCC "SLIDE TIME="
        FCB 0
..dd    FCC "0:0     "
        FCB 0
        ENDPROC

EK_ALL  LDA #1
        STA TRAK_FLG
        lbsr RedisplayPage
        RTS

EK_MarkAll PROC
        lda BUFFER1_BLOCK
        pshs a,x
        LDX #BUF1ADR
        clr BUFFER1_BLOCK
        LDD 0,X              ;get start time
        STD BLK_STRT+1
        lda 7,x              ;get extended time
        anda #$f0
        sta BLK_STRT
        CALL FindEndBuffer1
        lbsr PrevAbsEvent
        LDD ,X               ;get end time
        STD BLK_END+1
        lda 7,x              ;get extended time
        anda #$f0
        sta BLK_END
        lbsr DisplayEntirePage
        LBSR SndOK
        puls a,x
        sta BUFFER1_BLOCK
        rts
        ENDPROC

; Find event time; S_PTR points to extended time structure
; return address of event in D and BUFFER1_BLOCK is set correctly
;
        global GoTo
GoTo PROC
        stackvar S_PTR
        ldy S_PTR,s
        ldx #BUF1ADR
        clr BUFFER1_BLOCK
..loop  ldd 0,x
        cmpd #$ffff
        beq ..done
        lda 7,x             ;compare extended times
        anda #$f0
        cmpa 0,y
        bhi ..done
        blo ..next
        ldd 0,x
        cmpd 1,y
        bhs ..done
..next  lbsr NextEvnt
        bra ..loop
..done  tfr x,d
        ends
        ENDPROC

EK_HELP PROC
        lda XPOS
        ldb YPOS
        std ..zz
        CALL SetBox,#..aa
..A     LBSR getchar
        LBSR ClrBox
        pshs a
        ldd ..zz
        sta XPOS
        stb YPOS
        lbsr MOVE
        LDD #ED_KEYS
        PSHS D
        ldb 2,s
        LBSR DoCmd
        LEAS 3,S
        rts
..aa    FDB 2,2,28,13,..bb,0
..bb    FDB 1,0,..cc,$+8
        FDB 2,2,..dd,$+8
        FDB 2,3,..ee,$+8
        FDB 2,4,..ff,$+8
        FDB 2,5,..gg,$+8
        fdb 2,6,..qq,$+8
        FDB 2,7,..hh,$+8
        fdb 2,8,..rr,$+8
        FDB 16,2,..ii,$+8
        fdb 16,3,..jj,$+8
        FDB 16,4,..kk,$+8
        FDB 16,5,..ll,$+8
        FDB 16,6,..mm,$+8
        FDB 16,7,..nn,$+8
        fdb 16,8,..ss,$+8
        FDB 5,9,..oo,$+8
        FDB 5,10,..pp,0
..cc    FCC " HELP "
        FCB 0
..dd    FCC "aLL TRACKS"
        FCB 0
..ee    FCC "bLOCK MENU"
        FCB 0
..ff    FCC "cLEAR BLOCK"
        FCB 0
..gg    FCC "dELETE"
        FCB 0
..qq    fcc "fILTER"
        fcb 0
..hh    FCC "gO TO"
        FCB 0
..ii    FCC "iNSERT"
        FCB 0
..jj    FCC "kILL NOTES"
        FCB 0
..kk    FCC "mARK BLOCK"
        FCB 0
..ll    FCC "pLAY"
        FCB 0
..mm    FCC "rECORD"
        FCB 0
..nn    FCC "sLIDE"
        FCB 0
..rr    fcc "DIReCTORY"
        fcb 0
..ss    fcc "MARK AlL"
        fcb 0
..oo    FCC "ENTER - BEGIN EDIT"
        FCB 0
..pp    FCC "BREAK - EXIT"
        FCB 0
..zz    fdb 0                ;temporary storage for cursor position
        ENDPROC

        global ED_POS
ED_POS  FCB 0 ;editing position
        global ED_ADR
ED_ADR  FDB 0 ;editing address

; check horizontal position for event display cursor
; ENTRY: X=pointer to MIDI code
;
        global CHKPOS
CHKPOS PROC
        PSHS Y
        LDD ,X ;get time
        CMPD #$FFFF ;end?
        BNE ..A
        CLR ED_POS
        BRA ..Z
..A     LBSR CHKFILT ;B=event number
        LEAY ..aa,PCR
        LDA B,Y ;get max position
        CMPA ED_POS ;compare with current
        BHS ..Z
        STA ED_POS
..Z     PULS Y,PC
..aa    FCB 3,5,4,4 ;max pos for events
        FCB 3,3,3,3 $80-$F0
        ENDPROC

ChangeEventType proc
        pshs x
        lda YPOS
        cmpa #5
        bls ..a1
        lda #5
..a1    sta ..aa+3
        call SetBox,#..aa
        lbsr getchar
        cmpa #3              ;check for BREAK
        beq ..x
        ldx #..table
        ldb #$90
..a     tst ,x               ;check for end of table
        beq ..x
        cmpa ,x+             ;look for match
        beq ..y
        addb #$10
        bra ..a
..x     lbsr SndErr
        ldd #-1
        bra ..z
..y     tfr b,a
..z     pshs d
        lbsr ClrBox
        puls d,x,pc
;
..aa    FDB 9,6,12,11,$+12,0
        FDB 2,2,..cc,$+8
        fdb 2,3,..dd,$+8
        fdb 2,4,..ee,$+8
        fdb 2,5,..ff,$+8
        fdb 2,6,..gg,$+8
        fdb 2,7,..hh,$+8
        fdb 2,8,..ii,0
..cc    FCC "nOTE"
        FCB 0
..dd    FCC "kEY PRES"
        FCB 0
..ee    FCC "cTRL CHG"
        FCB 0
..ff    FCC "pROG CHG"
        FCB 0
..gg    FCC "CHN PrES"
        FCB 0
..hh    FCC "PCH wHL"
        FCB 0
..ii    FCC "sYS EVNT"
        FCB 0
;
..table fcb 'N','K','C','P','R','W','S',0
        endproc

; start actual modification of events
; S_MPTR: pointer to MIDI event
; S_POS:  edit position
;
        global EdENTER
EdENTER PROC
        localvar l_b1b
        char L_STR,10
        stackvar S_MPTR,S_POS
        LDD S_POS,S
        TSTB
        LBNE ..B
; position 0: event time
        ldx S_MPTR,s
        ldd 0,x
        cmpd #$FFFF         ;check for end
        lbeq ..Z
        lbsr ChangeEventTime
        stx S.X,s
        lbra ..Z
..B     CMPB #1
        BNE ..C
; position 1: change event type
        LDX S_MPTR,S
        lda 2,x              ;if a message event, erase message
        cmpa #$f2
        beq ..I2
        cmpa #$f3
        beq ..I2
        cmpa #$f6
        bne ..I
..I2    lda 3,x
        ldb #16
        mul
        ldy MESSAGES
        lbsr MapDataIn
        clr b,y
        lbsr MapDataOut
..I     lbsr ChangeEventType
        cmpd #-1
        lbeq ..Z
..A     STA 2,X
        LBSR CHKFILT
        TSTA
        BNE ..I
        lda 2,x              ;check for message events
        cmpa #$f2
        beq ..A1
        cmpa #$f3
        beq ..A1
        cmpa #$f6
        lbne ..Z
..A1    pshs x
        ldx MESSAGES
        clrb
        lbsr MapDataIn
..A2    tst ,x               ;check for an available message slot
        beq ..A3
        leax 16,x
        incb
        cmpb #16
        blo ..A2
        puls x
        lda #$f1             ;if none available, change to clock event
        sta 2,x
        lbsr SndErr          ;low beep and quit
        bra ..A4
..A3    lda #' '             ;mark this message as 'taken'
        sta ,x
        puls x               ;restore pointer to current event
        stb 3,x
..A4    lbsr MapDataOut
        LBRA ..Z
; position 2: event value
..C     CMPB #2
        LBNE ..D
        LDX S_MPTR,S
        LDA 2,X
        CMPA #$F0
        BLO ..L
        LBSR EdSysID
        LBRA ..Z
..L     CMPA #$E0            ;check for pitch wheel
        BLO ..E
        LDD #5               ;number of editable digits
        STD ARG2
        LDB 3,X              ;get LSB value
        LSLB
        LDA 4,X              ;get MSB value
        LSRA
        RORB
        BRA ..G
..E     CMPA #$9F            ;check for note on/off
        BHI ..K
        LDA 3,X              ;get pitch
        PSHS X
        LEAX L_STR+2,S
        LBSR CNVPITCH
        CALL GetStr,REGX,#3
        LBSR CNVNOTE
        PULS X
        STA 3,X
        LBRA ..Z
..K     LDD #3
        STD ARG2
        CLRA
        LDB 3,X
..G     LEAX L_STR,S
        LBSR BINDEC
        CALL GetStr,REGX,ARG2
        LBSR atoi
        LDX S_MPTR,S
        PSHS A
        LDA 2,X
        ANDA #$F0
        CMPA #$E0
        PULS A
        BNE ..H
        LSLB
        ROLA
        LSRB
        STB 3,X
        STA 4,X
        LBRA ..Z
..H     STB 3,X
        LBRA ..Z
..D     CMPB #3
        LBNE ..F
; position 3: channel (or data)
        LDX S_MPTR,S
        LDB 2,X              ;get status byte
        CMPB #$F0            ;check for system msg
        BHS ..M
        ANDB #$0F            ;keep channel #
        INCB
        CLRA
        LEAX L_STR,S
        LBSR BINDEC
        CALL StrPad,REGX,#2
        CALL GetStr,REGX,#2
        LBSR atoi
        CMPD #0
        BHI ..P
..Q     LBSR SndErr
        LBRA ..Z
..P     CMPD #16
        BHI ..Q
        DECB
        ANDB #$0F
        LDX S_MPTR,S
        LDA 2,X
        ANDA #$F0
        PSHS A
        ORB ,S+
        STB 2,X
        LBRA ..Z
..M     andb #$0f            ;system event
        cmpb #MAXSYS
        lbhi ..Z
        lslb
        ldy #..aa
        jsr [b,y]
        lbra ..Z
..F     CMPB #4
        BNE ..J
; position 4
        LDX S_MPTR,S
        CLRA
        LDB 4,X
        LEAX L_STR,S
        LBSR BINDEC
        CALL StrPad,REGX,#3
        CALL GetStr,REGX,#3
        LBSR atoi
        LDX S_MPTR,S
        STB 4,X
        BRA ..Z
..J     CMPB #5
        BNE ..Z
; position 5 (note length)
        LEAX L_STR,S
        STX ARG1
        LDX S_MPTR,S
        CALL NoteLen,ARG1
        LEAX L_STR,S
        CALL StrPad,REGX,#5
        CALL GetStr,REGX,#5
        CMPD #BREAK
        BEQ ..Z
        CALL CnvNotLn,REGX
        LDX S_MPTR,S
        STD 5,X
        BRA ..Z
..X                          ;error exit
..Z     ENDS
;
..aa    fdb EdTempo,EdClock,EdMsg,EdMsg,EdNothing,EdBytes,EdMsg
%if GOTO_VERSION eq 1
        fdb EdGoto
%endif
        ENDPROC

; Change the current event time (pointed to by register X)
; If the resulting time is out of sequence, correct the sequence
;
ChangeEventTime proc
        localvar
        char L_STR,11
        stackvar
;
        lda 7,x
        anda #$f0
        sta EX_TIME1
        ldd 0,x
        std EX_TIME1+1
        leax L_STR,s
        CALL ConvertBinaryTime,REGX,#EX_TIME1
        CALL StrPad,REGX,#10
        CALL GetStr,REGX,#10
        CMPD #BREAK
        LBEQ ..Z
        CALL ConvertAsciiTime,REGX,#EX_TIME1
        ldx S.X,s
        ldd EX_TIME1+1
        std 0,x              ;set new event time
        lda 7,x
        anda #$0f
        ora EX_TIME1
        sta 7,x
        clra
        clrb
        std PREVIOUS_EVENT
        sta PREVIOUS_EVENT+7
        lbsr GetPreviousEvent
        lda PREVIOUS_EVENT+7
        anda #$f0
        sta EX_TIME1
        ldd PREVIOUS_EVENT
        std EX_TIME1+1
        call CompareExTimes,#EX_TIME1
        cmpd #-1             ;is the time in the right sequence?
        beq ..B
        lbsr GetNextEvent
        lda NEXT_EVENT+7
        anda #$f0
        sta EX_TIME1
        ldd NEXT_EVENT
        std EX_TIME1+1
        cmpd #$ffff
        bne ..A
        sta EX_TIME1
..A     call CompareExTimes,#EX_TIME1
        cmpd #0
        lbeq ..Z
        cmpd #-1
        lbeq ..Z
;
..B     leay L_STR,s         ;time out of order:
        ldb #EVNSIZE         ;save this event in L_STR
        ldx S.X,s
..C     LDA ,x+
        STA ,y+
        decb
        bne ..C
;
        ldx S.X,s            ;restore pointer to current event
        lda #$90
        sta 2,x              ;prevent message events from being lost
        call Delete,REGX     ;delete the out-of-order event
;
        lda L_STR+7,s        ;get extended time from changed event
        anda #$f0            ;and put it in EX_TIME1
        sta EX_TIME1
        ldd L_STR,s
        std EX_TIME1+1
;
        inc FILT_FLG         ;disable the filter
        call GoTo,#EX_TIME1  ;find where changed event goes
        TFR D,X
        CLR FILT_FLG         ;enable the filter
        CALL Insert,REGX     ;insert the event
        LEAY L_STR,S
        LDB #EVNSIZE
..D     LDA ,Y+
        STA ,X+
        DECB
        BNE ..D
;
        lbsr RedisplayPage
        stx S.X,s
..Z     ends
        endproc

EdNothing proc
        rts
        endproc

EdTempo proc
EdClock
        localvar
        char l_str,6
        stackvar
        LDD 3,X
        LEAX l_str,s
        LBSR BINDEC
        CALL StrPad,REGX,#5
        CALL GetStr,REGX,#5
        LBSR atoi
        LDX S.X,s
        STD 3,X
        LBSR CPCalc          ;calculate CPERIOD
        STD 5,X              ;(just in case!)
        ends
        endproc

; edit the data part of a system message event
;
        global EdMsg
EdMsg PROC
        pshs x,y
        dec XPOS
        lbsr Move
        tfr x,y
        lbsr MapDataIn
        LDX MESSAGES
        LDB 3,Y              ;get message #
        LDA #16              ;bytes/message
        MUL
        LEAX D,X
        CALL StrPad,REGX,#14
        CALL GetStr,REGX,#14
        LDA 2,Y              ;is this a LINK?
        CMPA #$F2            ;no trim if not
        BNE ..Z
        CALL StrTrim,REGX
..Z     lbsr MapDataOut
        inc XPOS
        lbsr Move
        puls x,y,pc
        ENDPROC

; edit a BYTES system event. ENTRY: X points to event
;
        global EdBytes
EdBytes PROC
        LOCALVAR
        CHAR L_PTR,13
        STACKVAR
        LEAY 3,X
        STY ARG2
        LEAX L_PTR,S
        CALL CnvBytes,#4,ARG2,REGX
        CALL StrPad,REGX,#12
        CALL GetStr,REGX,#12
        STY ARG2
        CALL HexSBin,REGX,ARG2,#4
        ENDS
        ENDPROC

%if GOTO_VERSION eq 1
        global EdGoto
EdGoto proc
        localvar l_y
        char l_str,11
        stackvar
        leay 3,x
        sty ARG2
        leax l_str,s
        CALL ConvertBinaryTime,REGX,ARG2
        CALL StrPad,REGX,#10
        CALL GetStr,REGX,#10
        CMPD #BREAK
        BEQ ..Z
        sty ARG2
        tfr x,y              ;delete any ticks
..a     lda ,y+
        beq ..c
        cmpa ':'
        bne ..a
        leay -1,y
        lda #' '
..b     sta ,y+
        tst ,y
        bne ..b
..c     CALL ConvertAsciiTime,REGX,ARG2
..Z     ends
        endproc
%endif

ChangeSystemEvent proc
        pshs x
        lda YPOS
        cmpa #4
        bls ..a1
        lda #4
..a1    sta ..aa+3
        call SetBox,#..aa
        lbsr getchar
        cmpa #3              ;check for BREAK
        beq ..x
        ldx #..table
        clrb
..a     tst ,x               ;check for end of table
        beq ..x
        cmpa ,x+             ;look for match
        beq ..y
        incb
        bra ..a
..x     lbsr SndErr
        ldd #-1
        bra ..z
..y     tfr b,a
..z     pshs d
        lbsr ClrBox
        puls d,x,pc
;
%if GOTO_VERSION eq 1
..aa    FDB 12,5,9,12,$+12,0
%else
..aa    fdb 12,5,9,11,$+12,0
%endif
        FDB 2,2,..bb,$+8
        fdb 2,3,..cc,$+8
        fdb 2,4,..dd,$+8
        fdb 2,5,..ee,$+8
        fdb 2,6,..ff,$+8
        fdb 2,7,..gg,$+8
%if GOTO_VERSION eq 1
        fdb 2,8,..hh,$+8
        fdb 2,9,..ii,0
%else
        fdb 2,8,..hh,0
%endif
..bb    fcc "tEMPO"
        fcb 0
..cc    fcc "cLOCK"
        fcb 0
..dd    fcc "lINK"
        fcb 0
..ee    fcc "mESSG"
        fcb 0
..ff    fcc "pAUSE"
        fcb 0
..gg    fcc "bYTES"
        fcb 0
..hh    fcc "sYX"
        fcb 0
%if GOTO_VERSION eq 1
..ii    fcc "gOTO"
        fcb 0
%endif
;
..table fcb 'T','C','L','M','P','B','S'
%if GOTO_VERSION eq 1
        fcb 'G'
%endif
        fcb 0
        endproc

; edit a system event byte (just id byte)
; assigns a new message # to a message event
; ENTRY: X=pointer to event
;
        global EdSysID
EdSysID PROC
        STACKVAR
        LDA 2,X
        ANDA #$0F
;if we're starting out with a message event, first deallocate its message
        cmpa #2
        beq ..A1
        cmpa #3
        beq ..A1
        cmpa #6
        bne ..A2
..A1    pshs a
        ldb 3,x
        lda #16
        mul
        ldy MESSAGES
        lbsr MapDataIn
        clr b,y
        lbsr MapDataOut
        puls a
..A2    lbsr ChangeSystemEvent
;if the new SYS ID is a message event, allocate an empty message
..A     cmpa #-1
        beq ..Z
        CMPA #2
        beq ..E
        CMPA #3
        beq ..E
        cmpa #6
        bne ..B
..E     LDY MESSAGES        ;find an empty message
        lbsr MapDataIn
        CLRB
..C     TST ,Y
        BEQ ..D
        LEAY 16,Y
        INCB
        CMPB #16
        blo ..C
        cmpa #6              ;if no space advance to next non-message event
        bne ..C1
        clra
        bra ..B
..C1    inca
        cmpa #3
        bne ..B
        inca
        bra ..B
..D     STB 3,X              ;put message # in event
        ldb #' '             ;mark message as taken
        stb ,y
..B     ORA #$F0
        STA 2,X
        lbsr MapDataOut
..Z     ENDS
        ENDPROC

; set block markers
; ENTRY: X points to current MIDI event
;
        global BlkMark
BlkMark PROC
        pshs y
        LDD 0,X              ;check for end of music
        CMPD #$FFFF
        LBEQ ..Z
..D     LDY BLK_STRT+1
        CMPY #$FFFF
        BNE ..A
        STD BLK_STRT+1
        lda 7,x
        anda #$f0            ;extended time byte
        sta BLK_STRT
        BRA ..E
..A     LDY BLK_END+1
        CMPY #$FFFF
        BNE ..X
        STD BLK_END+1
        lda 7,x              ;extended time byte
        anda #$f0
        sta BLK_END
;flip markers if END > START
..B     lda BLK_STRT         ;check extended time byte first
        cmpa BLK_END
        blo ..C
        LDD BLK_STRT+1
        CMPD BLK_END+1
        BLO ..C
        LDD BLK_END
        pshs d
        lda BLK_END+2
        pshs a
        ldd BLK_STRT
        std BLK_END
        lda BLK_STRT+2
        sta BLK_END+2
        puls a
        sta BLK_STRT+2
        puls d
        std BLK_STRT
..C     lbsr DisplayEntirePage
..E     lbsr SndOK
        bra ..Z
..X     lbsr ModifyBlockMarkers
..Z     puls y,pc
        endproc

; display a page of events without changing the current cursor position
; can be used only when music memory has NOT be modified
;
DisplayEntirePage proc
        lda BUFFER1_BLOCK
        pshs a,x
        lda XPOS
        ldb YPOS
        pshs d
        lbsr Cls
        lda MEM_LINE+2
        sta BUFFER1_BLOCK
        call DspPage,MEM_LINE
        puls d
        sta XPOS
        stb YPOS
        lbsr Move
        puls a,x
        sta BUFFER1_BLOCK
        rts
        endproc

ModifyBlockMarkers proc
        call ConvertBinaryTime,#..ff,#BLK_STRT
        call ConvertBinaryTime,#..gg,#BLK_END
        call StrPad,#..ff,#10
        call StrPad,#..gg,#10
        call SetBox,#..aa
        call BoxInp,#..aa
        lbsr ClrBox
        cmpb #BREAK
        beq ..Z
        call ConvertAsciiTime,#..ff,#BLK_STRT
        call ConvertAsciiTime,#..gg,#BLK_END
        lbsr DisplayEntirePage
..Z     rts
;
..aa    fdb 6,4,21,8,$+12,..ee
        fdb 3,2,..bb,$+8
        fdb 2,4,..cc,$+8
        fdb 4,5,..dd,0
..bb    fcc "CHANGE MARKERS"
        fcb 0
..cc    fcc "START:"
        fcb 0
..dd    fcc "END:"
        fcb 0
..ee    fdb 9,4,..ff,$+10,0
        fdb 9,5,..gg,0,$-10
..ff    fcc "1/1:0     "
        fcb 0
..gg    fcc "1/1:0     "
        fcb 0
        ENDPROC

; clear block markers
;
        global BlkClr
BlkClr PROC
        LDD #$FFFF
        sta BLK_STRT
        STD BLK_STRT+1
        sta BLK_END
        STD BLK_END+1
        lbsr DisplayEntirePage
        rts
        ENDPROC

        global GetPreviousEvent,PREVIOUS_EVENT
PREVIOUS_EVENT fcb 0,0,0,0,0,0,0,0
;
GetPreviousEvent proc
        localvar l_b1b
        stackvar
        lda BUFFER1_BLOCK
        sta l_b1b,s
        bne ..a1
        cmpx #BUF1ADR
        beq ..x
..a1    leax -EVNSIZE,x
        cmpx #BUF1ADR
        bhs ..a
        leax $2000,x
        lda BUFFER1_BLOCK
        deca
        bmi ..x
        sta BUFFER1_BLOCK
..a     ldb #EVNSIZE
        ldy #PREVIOUS_EVENT
..b     lda ,x+
        sta ,y+
        decb
        bne ..b
        ldx #0
        bra ..z
..x     ldx #-1
..z     lda l_b1b,s
        sta BUFFER1_BLOCK
        tfr x,d
        ends
        endproc

        global GetNextEvent,NEXT_EVENT
NEXT_EVENT fcb 0,0,0,0,0,0,0,0
GetNextEvent proc
        localvar l_b1b
        stackvar
        lda BUFFER1_BLOCK
        sta l_b1b,s
        leax EVNSIZE,x
        cmpx #BUF1ADR+$2000
        blo ..a
        ldx #BUF1ADR
        inc BUFFER1_BLOCK
..a     ldb #EVNSIZE
        ldy #NEXT_EVENT
..b     lda ,x+
        sta ,y+
        decb
        bne ..b
        clra
..z     lda l_b1b,s
        sta BUFFER1_BLOCK
        ends
        endproc

; insert (duplicate) an event at given pointer S_PTR
;
        global Insert
Insert PROC
        LOCALVAR l_b1b,l_x
        STACKVAR S_PTR
;first save the current block # and address of X translated to BUF2ADR
        lda BUFFER1_BLOCK
        sta l_b1b,s
        tfr x,d
        subd #BUF1ADR
        addd #BUF2ADR
        std l_x,s
;find the end of BUFFER1
        lbsr FindEndBuffer1
        lbsr NextAbsEvent
        leay BUF2ADR-BUF1ADR,x
        lda BUFFER1_BLOCK
        sta BUFFER2_BLOCK
        lbsr NextAbsEvent
;move BUFFER1 up
..g     ldb #EVNSIZE
..f     lda ,-y
        sta ,-x
        decb
        bne ..f
        lda BUFFER2_BLOCK
        cmpa l_b1b,s
        bhi ..e
        cmpy l_x,s
        beq ..h
..e     cmpx #BUF1ADR
        bhi ..d
        leax $2000,x
        dec BUFFER1_BLOCK
..d     cmpy #BUF2ADR
        bhi ..g
        leay $2000,y
        dec BUFFER2_BLOCK
        bra ..g
;if we're at an end of music marker, then make it a note event
..h     ldx S_PTR,s
        LDD ,X
        CMPD #$FFFF
        BNE ..I
;set time to 0 if at the start of the buffer
        lbsr GetPreviousEvent
        cmpd #-1
        bne ..a
        clr PREVIOUS_EVENT+7
        clra
        clrb
        BRA ..B
;else get previous time
..A     LDD PREVIOUS_EVENT
..B     STD 0,X              ;set event time
        LDD #$9040
        STD 2,X              ;set status+pitch
        STB 4,X              ;set velocity
        LDD TIMEBASE         ;set length
        STD 5,X
        lda PREVIOUS_EVENT+7 ;set track
        anda #$f0
        ora TRACK
        STA 7,X
;check for message events and allocate message
..I     lda 2,x
        cmpa #$f2
        beq ..J
        cmpa #$f3
        beq ..J
        cmpa #$f6
        bne ..Z
..J     ldy MESSAGES
        lbsr MapDataIn
        clrb
..J1    tst ,y
        beq ..J2
        leay 16,y
        incb
        cmpb #16
        blo ..J1
        lda #$f1
        sta 2,x
        lbsr MapDataOut
        bra ..Z
..J2    stb 3,x
        lda #' '
        ldb #14
..j3    sta ,y+
        decb
        bne ..j3
        clr ,y
        lbsr MapDataOut
..Z     ENDS
        ENDPROC

; delete an event at given pointer
; also delete a message if a system message
;
        global Delete
Delete PROC
        localvar l_b1b,l_tim
        STACKVAR S_MPTR
        lda BUFFER1_BLOCK
        sta l_b1b,s
        LDX S_MPTR,S
        LDD ,X               ;check for end
        CMPD #$FFFF
        BEQ ..Z
        LDA 2,X              ;check for message event
        CMPA #$F2
        BEQ ..A1
        CMPA #$F3
        BEQ ..A1
        cmpa #$f6            ;syx event?
        bne ..A
..A1    lbsr MapDataIn
        LDA 3,X              ;get message #
        LDB #16
        MUL
        LDY MESSAGES
;        leay d,y
        CLR D,Y              ;delete message
        lbsr MapDataOut
..A     lda BUFFER1_BLOCK
        sta BUFFER2_BLOCK
        tfr x,d
        subd #BUF1ADR
        addd #BUF2ADR+EVNSIZE
        tfr d,y
        cmpy #BUF2ADR+$2000
        blo ..b
        ldy #BUF2ADR
        inc BUFFER2_BLOCK
..b     ldd ,y
        std l_tim,s
        ldb #EVNSIZE
..c     lda ,y+
        sta ,x+
        decb
        bne ..c
        cmpx #BUF1ADR+$2000
        blo ..d
        ldx #BUF1ADR
        inc BUFFER1_BLOCK
..d     cmpy #BUF2ADR+$2000
        blo ..e
        ldy #BUF2ADR
        inc BUFFER2_BLOCK
..e     ldd l_tim,s
        cmpd #$ffff
        bne ..b
..Z     lda l_b1b,s
        sta BUFFER1_BLOCK
        ENDS
        ENDPROC

; return pointer to next MIDI event
; register X is the pointer to current MIDI event
;
        global NextEvnt
NextEvnt PROC
        pshs y
        tfr x,y
..A     cmpx #BUF1ADR        ;check for 1 before buffer start
        blo ..B
        LDD ,X               ;check for end
        CMPD #$FFFF
        BEQ ..Y              ;if advancing
..B     LEAX EVNSIZE,X
        cmpx #BUF1ADR+$2000
        blo ..c
        ldx #BUF1ADR
        inc BUFFER1_BLOCK
..c     LDD ,X
        CMPD #$FFFF          ;check for end
        BEQ ..D
        LDA 2,X
        LDB 7,X
        LBSR CHKFILT
        TSTA
        BEQ ..D
        CMPX #BUF1ADR
;        BHI ..B ;check for start
;        BRA ..Y
        bra ..B
..D     TFR X,D
        BRA ..Z
..Y     tfr y,x              ;error so restore X to starting value
..Z     puls y,pc
        ENDPROC

; return with register X pointing to previous MIDI event
; register X: pointer to current MIDI event
;
        global PrevEvent
PrevEvent PROC
        lda BUFFER1_BLOCK
        pshs a,x
..a     tst BUFFER1_BLOCK
        bne ..b
        CMPX #BUF1ADR        ;check for start
        BEQ ..x
..b     LEAX -EVNSIZE,X
        cmpx #BUF1ADR
        bhs ..c
        leax $2000,x
        dec BUFFER1_BLOCK
..c     LBSR CHKFILT
        TSTA
        bne ..a
        leas 3,s
        bra ..z
..x     puls a,x
        sta BUFFER1_BLOCK
..z     rts
        ENDPROC

; check the MIDI filter and report
; disabled if FILT_FLG>0
; track not checked if TRAK_FLG>0
; ENTRY: X=MIDI event pointer
; EXIT:  A=0 if not filtered out
;        A>0 if event is filtered out
;        A=$FF if error (not a status byte)
;        B=event number (1-7)
;
        global CHKFILT
CHKFILT PROC
        PSHS X
        LDA 2,X ;get status byte
        TSTA
        BPL ..X
        TST FILT_FLG
        BNE ..A
        TST TRAK_FLG
        BNE ..A
        ldb 7,X
        andb #$0f
        cmpb TRACK
        BNE ..X
..A     LDX #..aa
        LSRA
        LSRA
        LSRA
        LSRA
        ANDA #7
        TFR A,B
        LDA A,X
        ANDA MFILTER
        TST FILT_FLG
        BEQ ..Z
        CLRA
        BRA ..Z
..X     LDD #$FFFF
..Z     PULS X,PC
..aa    FCB 1,2,4,8,$10,$20,$40,$80
        ENDPROC

        global NextAbsEvent
NextAbsEvent proc
        leax EVNSIZE,x
        cmpx #BUF1ADR+$2000
        blo ..z
        ldx #BUF1ADR
        inc BUFFER1_BLOCK
..z     rts
        endproc

        global PrevAbsEvent
PrevAbsEvent proc
        leax -EVNSIZE,x
        cmpx #BUF1ADR
        bhs ..z
        leax $2000,x
        dec BUFFER1_BLOCK
..z     rts
        endproc

; display a page of events, starting with time in [MEM_LINE]
; also 'remembers' cursor position
; returns with X pointing to cursor position (BUFFER1_BLOCK also set)
; This routine assumes that MEM_LINE is valid!
;
        global RedisplayPage
RedisplayPage proc
        localvar l_ypos
        stackvar
        lda YPOS
        sta l_ypos,s
;        lbsr Cls
        clr YPOS
        clr XPOS
        lda MEM_LINE+3
        sta EX_TIME1
        ldd MEM_LINE+4
        std EX_TIME1+1
        call GoTo,#EX_TIME1
        std ARG1
        call DspPage,ARG1
        ldx MEM_LINE
        lda MEM_LINE+2
        sta BUFFER1_BLOCK
        clr YPOS
..loop  lda YPOS
        cmpa l_ypos,s
        beq ..done
        lbsr EK_DOWN
        ldd 0,x              ;check for end of music
        cmpd #$ffff
        bne ..loop
..done  stx S.X,s
        ends
        endproc

        end

; end of file: edit.asm
