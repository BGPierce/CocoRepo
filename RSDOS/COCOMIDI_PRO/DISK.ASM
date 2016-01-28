; DISK/TXT - part of CoCoMIDI 3
; (C) 1988 by Lester Hands
;
; These disk routines use only two ROM entry points:
; $ADC6 in the Basic interpreter, and the DSKCON
; routine. This should maximize compatibility.

%include "cmp.h"
%include "macros.h"

        EXTERN ARG1,ARG2,BINDEC,BOXINP,CHROUT
        EXTERN CLRBLOCK,CLRBOX,CLS,COMMENTS,CPCALC,MASTER_CPERIOD,CPERIOD
        EXTERN DISKLOAD,DIVIDE,DR40TRK,EraseLine,FINDENDBUFFER1,GETCHAR
        EXTERN GETPOS,GETSTR,MESSAGES,ANNOTATION,MOVE,PUTS,RESET,CPCalc
        EXTERN SETBOX,SNDERR,STACK,TFLAGS,XPOS,YPOS,RedisplayPage
        extern Mult,Working,NextAbsEvent,SndOK,TIMEBASE,BAR,KEY
        extern MapDataIn,MapDataOut,ClearCMA

        global TAPE_IO_FLAG
TAPE_IO_FLAG fcb 0           ;>0 if tape I/O desired
DISK_ACCESS_MODE fdb 0       ;0=read, >0=write, 2nd byte='V' for verbose

DBUFPTR FDB DBUFFER          ;ptr to position in buffer
DBUFEND FDB DBUFFER+$100     ;end of buffer
DBRDFLG FCB 0                ;=0 if no sector read

        global SECTOR,MAXSECT
SECTOR  fdb 0                ;current sector number
MAXSECT fdb 0                ;max # of sectors in file

        global FILENAME
FILENAME FCC "        /CMP:0"
        FCB 0

DSKOPC  EQU $EA ;DSKCON variables
DSKDRV  EQU $EB ;drive
DSKTRK  EQU $EC ;track
DSKSEC  EQU $ED ;sector
DSKBUF  EQU $EE ;buffer address
DSKSTA  EQU $F0 ;error code (status)

ResetDrive proc
        pshs x,y,u
        tst TAPE_IO_FLAG
        bne ..z
        clr DSKOPC
        lda DEFDRIVE
        sta DSKDRV
        clr DSKTRK
        lda #1
        sta DSKSEC
        lbsr DSKCON
..z     puls x,y,u,pc
        endproc

; if error, returns 0 in register A; otherwise nonzero.
;
        global DSKCON
DSKCON proc
        pshs dp
        CLRA
        TFR A,DP
        lbsr MapBasicIn
        sta SLOW
        JSR [$C004]
        lda >DSKSTA
        sta FAST
        lbsr MapBasicOut
        puls dp,pc
        endproc

; execute a tokenized Basic string pointed to by X.
; ROMs are enabled; it is assumed that all interrupt
; routines are in RAM to prevent memory conflicts.
;
        global BASIC
BASIC   PSHS X,Y,U,DP
        sta SLOW
        CLRA
        EXG A,DP
        lbsr MapBasicIn
        STX $A6
        LDA ,X
        ANDCC #$FE
        JSR $ADC6
        lbsr MapBasicOut
        sta FAST
        PULS X,Y,U,DP,PC

; error handling routine for ROM errors
;
        global Error
Error PROC
        ORCC #$50
        lbsr MapBasicOut
        LDS #STACK
        PSHS B               ;B=error code
        LDD #DBUFFER         ;clear disk buffer
        STD DBUFPTR
        LBSR Close
        LBSR ClrBox
        PULS B
        LSRB
        CLRA
        LDX #..dd
        LBSR BINDEC
        LDX #..aa
        CALL SetBox,REGX
..A     LBSR getchar
        LBSR ClrBox
        sta FAST
        JMP Reset
;
..aa    FDB 9,5,14,5,..bb,0
..bb    FDB 2,2,..cc,0
..cc    FCC "ERROR #"
..dd    FCC "   "
        FCB 0
        ENDPROC

        global MapBasicIn,MapBasicOut
MapBasicIn proc
        pshs d
        ldd $ffa4
        std ..save
        ldd $ffa6
        std ..save+2
        ldd #$3c3d
        std $ffa4
        ldd #$3e3f
        std $ffa6
        puls d,pc
MapBasicOut
        pshs d
        ldd ..save
        std $ffa4
        ldd ..save+2
        std $ffa6
        puls d,pc
..save  fdb 0,0
        endproc

; turn the disk drive or tape motor off
;
        global DiskOff
DiskOff proc
        tst TAPE_IO_FLAG
        beq ..a
        LDA $FF21
        ANDA #$F7
        STA $FF21
        RTS
..a     STA SLOW
        pshs cc
        ORCC #$50            ;disable FIRQ,IRQ
        lbsr MapBasicIn
        CLR $FF40
        SYNC                 ;wait for NMI
        lbsr MapBasicOut
        sta FAST
        puls cc,pc
        endproc

; save current music to disk
;
        LOCALVAR L_CNT
        global Save
Save PROC
        STACKVAR
; get the filename
%IF DEMO eq 0
        lbsr NotAvailable
%else
        lda #':'
        sta FILENAME+12
        tst TAPE_IO_FLAG
        beq ..a1
        LDA $FF21       ;turn tape motor on
        ORA #8
        STA $FF21
        clr FILENAME+12
..a1    CALL SetBox,#..aa
        CALL BoxInp,#..aa
        CMPB #BREAK
        LBEQ ..Z
        tst TAPE_IO_FLAG
        bne ..a
        LDA FILENAME+13      ;get drive #
        SUBA #'0'            ;convert to binary
        LBMI ..Z
        CMPA #9
        LBHI ..Z
        STA DSKDRV
        STA DEFDRIVE
..a     LDX #FILENAME
        ldd #'WV'
        LBSR Open
        tsta
        lbeq ..Z
; write the headers first to the disk file
..B     lbsr FindEndBuffer1
        lbsr NextAbsEvent
        tfr x,d
        subd #BUF1ADR
        pshs d
        lda #$20
        ldb BUFFER1_BLOCK
        mul
        clr ..j
        sta ..j+1
        tfr b,a
        clrb
        addd ,s++
        std ..j+2
        lbsr ClrBox
        lbsr Working
        LDX #FHEADR          ;main header
        ldd TIMEBASE
        std 8,x
        lda #16
        sta 10,x
        lda BAR
        sta 11,x
        lda KEY
        sta 12,x
        clr 13,x
        clra
        clrb
        std 14,x
        CALL Write,REGX,#16
        LEAX 16,x            ;tempo header
        ldd CPERIOD
        lbsr CPCalc
        STD 8,X
        CALL Write,REGX,#10
        LEAX 10,X            ;status header
        CALL Write,REGX,#8
        CALL Write,#TFLAGS,#16
        LEAX 8,X             ;comment header
        CALL Write,REGX,#8
        lbsr MapDataIn
        CALL Write,COMMENTS,#16*COMMENT_SIZE
        LEAX 8,X             ;messages header
        CALL Write,REGX,#8
        CALL Write,MESSAGES,#256
        leax 8,x             ;annotation header
        call Write,REGX,#8
        call Write,ANNOTATION,#29*14
        lbsr MapDataOut
        LEAX 8,X             ;events header
        CALL Write,REGX,#8
        CALL WriteEvents
        leax 8,x
        call Write,REGX,#4
        LBSR Close
%ENDIF
..Z     LBSR ClrBox
        CLRA
        CLRB
        ENDS
;
%IF DEMO
..aa    FDB 4,5,24,5,..bb,..dd
..bb    FDB 2,2,..cc,0
..cc    FCC "SAVE:"
        FCB 0
..dd    FDB 8,2,FILENAME,0,0
;
%ENDIF
;
        global FHEADR
FHEADR  FCC "CMP0"           ;first header in file
        FDB 0,8              ; length of header
        fdb 240              ; ticks per beat
        fcb 16               ; number of tracks
        fcb 4                ; beats/bar
        fcb 'F'              ; key ('F' or 'S')
        fcb 0                ; reserved
        fdb 0                ; reserved
        FCC "TMPO"           ;tempo header
        FDB 0,2              ; # bytes in data
        FDB 100              ; the actual tempo (beats per minute)
        FCC "STAT"           ;status header
        FDB 0,16             ; status bytes for 16 tracks
        FCC "CMNT"           ;comment header
        FDB 0,16*COMMENT_SIZE
        FCC "MSGS"           ;messages header
        FDB 0,256
        fcc "ANNO"           ;annotation header
        fdb 0,29*14
        FCC "EVNT"           ;event header
..j     FDB 0,0              ; # bytes to follow
        fcc "END0"           ;end of file marker
        ENDPROC

; Write the body of the EVNT block
;
WriteEvents proc
        localvar
        char l_end,3
        stackvar
        lbsr FindEndBuffer1
        lbsr NextAbsEvent
        lda BUFFER1_BLOCK
        sta l_end+2,s
        tfr x,d
        subd #BUF1ADR
        std l_end,s
        clr BUFFER1_BLOCK
..a     lda BUFFER1_BLOCK
        cmpa l_end+2,s
        beq ..b
        call Write,#BUF1ADR,#$2000
        inc BUFFER1_BLOCK
        bra ..a
..b     ldd l_end,s
        std ARG1
        call Write,#BUF1ADR,ARG1
        ends
        endproc

CONVERT_CM3 fcb 0
CONVERT_192 fcb 0
CM3_ERRORS fcb 0

        global ConvertFile
ConvertFile proc
        lda #'3'
        sta FILENAME+11
        lbsr Load
        lda #'P'
        sta FILENAME+11
        rts
        endproc

GetFileName proc
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        rts
;
..aa    FDB 1,5,29,5,..bb,..dd
..bb    FDB 2,2,..cc,0
..cc    FCC "FILE NAME:"
        FCB 0
..dd    FDB 13,2,FILENAME,0,0
        endproc

; load disk file into memory
;
		EXTERN MEM_LINE
        LOCALVAR L_CNT,L_SEC,L_PTR
        global Load
Load PROC
        STACKVAR
        tst TAPE_IO_FLAG
        bne ..a0
        LBSR GetDrive
        CMPB #BREAK
        LBEQ ..Z
        STB FILENAME+13
        SUBB #'0'
        LBMI ..Z
        CMPB #9
        LBHI ..Z
        STB DSKDRV
        STB DEFDRIVE         ;set default drive #
; get a disk directory and ask for filename
..a0    tst TAPE_IO_FLAG
        beq ..a1
        LDA $FF21       ;turn tape motor on
        ORA #8
        STA $FF21
        LDA $FF01       ;enable tape sound
        ora #8
        sta $ff01
        lbsr GetFileName
        bra ..a2
..a1    CALL Dir,#FILENAME+9
        LDA #15
        STA YPOS
        CLR XPOS
        LBSR MOVE
;        LBSR EraseLine
        LDX #..aa
        LBSR PUTS
        LDX #FILENAME
        CALL GetStr,#FILENAME,#8
        CMPB #BREAK
        LBEQ ..Z
; open the file
..a2    LDX #FILENAME
        ldd #'RV'
        LBSR Open
        tsta
        lbeq ..Z
; read the file into memory
..B     lbsr ClrBox
        lbsr Working
        LDA #$AF
        STA DISKLOAD
        lbsr ClearCMA
        lbsr ReadFile
        LBSR Close
		ldd #BUF1ADR
		std MEM_LINE
		clr MEM_LINE+2
        CLR DISKLOAD
..Z     LDA #1               ;request screen update
        ENDS
;
..aa    FCC "  LOAD:"
        FCB 0
;
..ff    FDB 3,5,25,5,..gg,0
..gg    FDB 2,2,..hh,0
..hh    FCC "ERROR: FILE NOT FOUND"
        FCB 0
        ENDPROC

;        extern ConvertBinaryTime,EX_TIME1
;FileError proc
;        lda 7,x
;        sta EX_TIME1
;        ldd 0,x
;        std EX_TIME1+1
;        call ConvertBinaryTime,#..cc+8,#EX_TIME1
;        lbsr ClrBox
;        call SetBox,#..aa
;        lbsr SndErr
;        lbsr getchar
;        lbsr ClrBox
;        rts
;..aa    FDB 3,5,25,6,$+12,0
;        FDB 2,2,$+8,..bb
;        FCC "ERROR: FILE CORRUPTED"
;        FCB 0
;..bb    fdb 7,3,$+8,..cc
;        fcc "AT"
;        fcb 0
;..cc    fdb 10,3,$+8,0
;        fcc "          "
;        fcb 0
;        ENDPROC

; Read an entire CMP file.
; Checks for tags and reads into appropriate areas of memory.
;
        extern PUTS,XPOS,YPOS,MOVE,CLS
        global ReadFile
ReadFile proc
        localvar
        char l_tag,8
        stackvar
;get a block tag and length (8 bytes)
..a     leax l_tag,s
        clr BUFFER1_BLOCK
        call Read,REGX,#8
;compare the tag with the list of tags
        ldy #..aa
..d     clrb
..b     lda b,x
        cmpa b,y
        bne ..c
        incb
        cmpb #4
        bne ..b
;if all 4 bytes compare, then get do routine
        jsr [4,y]
        tsta
        bmi ..z
        bra ..a
;tag not found, move to next one in list
..c     leay 6,y
        cmpy #..zz
        blo ..d
..z     ends
;
..aa    FCC "CMP0"
        FDB GetHeaderBlock
        fcc "CM30"
        fdb Get3HeaderBlock
        FCC "TMPO"
        FDB GetTempoBlock
        FCC "STAT"
        FDB GetStatBlock
        FCC "CMNT"
        FDB GetCommentBlock
        FCC "EVNT"
        FDB GetEventBlock
        FCC "MSGS"
        FDB GetMessagesBlock
        fcc "ANNO"
        fdb GetAnnotationBlock
..zz    set $
        endproc

GetHeaderBlock proc
        ldd 6,x
        std ARG2
        clr BUFFER1_BLOCK
        call Read,#BUF1ADR,ARG2
        ldx #BUF1ADR
        ldd 0,x              ;check ticks per beat resolution
        cmpd #240
        beq ..not192
        lda #1
        bra ..a
..not192 clra
..a     sta CONVERT_192
        clr CONVERT_CM3
        lda 3,x
        sta BAR
        lda 4,x
        sta KEY
        clra
        rts
        endproc

Get3HeaderBlock proc
        lda #1
        sta CONVERT_CM3
        clr CONVERT_192
        clra
        rts
        endproc

GetTempoBlock proc
        pshs d,x
        sts ARG1
        call Read,ARG1,#2
        ldd 0,s
        lbsr CPCalc
..a     std MASTER_CPERIOD
        std CPERIOD
        leas 2,s
        clra
        puls x,pc
        endproc

GetStatBlock proc
        call Read,#TFLAGS,<6,x>
        clra
        rts
        endproc

        extern REMAIN,StrPad
GetCommentBlock proc
        localvar l_ptr,l_size,l_cnt
        stackvar
        ldd COMMENTS
        subd #COMMENT_SIZE
        std l_ptr,s
        ldd #16
        tst CONVERT_CM3
        beq ..not
        ldb #10
..not   std ARG2
        stb l_cnt,s
        call Divide,<6,x>,ARG2
        std l_size,s
        lbsr MapDataIn
..loop  ldd l_ptr,s
        addd #COMMENT_SIZE
        std l_ptr,s
        std ARG1
        ldd l_size,s
        std ARG2
        call Read,ARG1,ARG2
;        ldd l_ptr,s
;        std ARG1
;        call StrPad,ARG1,#COMMENT_SIZE
        dec l_cnt,s
        bne ..loop
        lbsr MapDataOut
        clra
        ends
        endproc

        global ConvertEvents
ConvertEvents proc
;        clra
;        clrb
;        std ..last
        pshs x
        clr BUFFER1_BLOCK
        ldx #BUF1ADR
..loop  ldd 0,x
        cmpd #$ffff
        lbeq ..done
;        tst 2,x              ;check for status byte < 128 (invalid)
;        bmi ..ok1
;        inc WORKING_ALERT_POSITION
;        lda #$80             ;status byte is invalid, so change it
;        sta 2,x              ;to a note off event (ALWAYS filtered out)
;        sta CONVERT_CM3      ;change flag to nonzero (true)
;        clr 7,x              ;make sure track is 1
;        bra ..ok2
..ok1   lda 7,x              ;check the track byte
        cmpa #16             ;if it is >15 then the event is invalid
        blo ..ok2
..notok lda #$80             ;change invalid event to a note off event
        sta 2,x
        lda #1
        sta CM3_ERRORS       ;make flag nonzero (true)
        clr 7,x              ;change track to 1
..ok2   ldd 0,x
        bra ..not192
..notCM3 tst CONVERT_192
        beq ..not192
        pshs d
        lsra
        rorb
        lsra
        rorb
        bcc ..a
        addd #1
..a     addd ,s++
        bra ..b
..not192 lslb                ;convert 96 tpb to 240 tpb timebase
        rola
        pshs d
        ldd 0,x
        lsra
        rorb
        addd ,s++
..b     std 0,x
        bcc ..chkt
        lda 7,x
        adda #$10
        sta 7,x
..chkt  lda 2,x
        cmpa #$9f
        bls ..note
        cmpa #$f0            ;check for tempo event
        bne ..chseq
        ldd 3,x              ;convert beats/minute to CPERIOD
        lbsr CPCalc
        std 5,x
        bra ..chseq
..note  ldd 5,x              ;convert note length
        tst CONVERT_192
        beq ..a96
        lsra                 ;this code looks suspicious!!
        rorb                 ;should be simple one shift left
        lsra                 ;*******************************
        rorb
        bcc ..c
        addd #1
..c     addd 5,x
        bra ..d
..a96   lslb
        rola
        pshs d
        ldd 5,x
        lsra
        rorb
        addd ,s++
..d     std 5,x
..chseq
;        tst CONVERT_CM3
;        beq ..next
;        ldd 0,x              ;check time sequence
;        cmpd ..last
;        bhs ..timok
;        ldd #$ffff
;        std 0,x
;        bra ..done
;..timok std ..last
..next  lbsr NextAbsEvent
        lbra ..loop
..done  puls x,pc
;
..last  fdb 0
        endproc

; Goes through BUFFER1 and deletes all note off ("invalid") events
;
CheckEvents proc
        localvar l_b12
        stackvar
        lda BUFFER1_BLOCK
        ldb BUFFER2_BLOCK
        std l_b12,s
;        tst CONVERT_CM3
;        beq ..done
        tst CM3_ERRORS
        beq ..done
        lbsr SndErr
        clr BUFFER1_BLOCK
        clr BUFFER2_BLOCK
        ldx #BUF1ADR
        ldy #BUF2ADR
..loop  ldd 0,x
        cmpd #$ffff
        beq ..done
        lda 2,x
        cmpa #$90
        blo ..skip
..copy  ldb #EVNSIZE
..copy2 lda ,x+
        sta ,y+
        decb
        bne ..copy2
        bra ..check
..skip  leax EVNSIZE,x
..check cmpx #BUF1ADR+$2000
        blo ..chk2
        ldx #BUF1ADR
        inc BUFFER1_BLOCK
..chk2  cmpy #BUF2ADR+$2000
        blo ..loop
        ldy #BUF2ADR
        inc BUFFER2_BLOCK
        bra ..loop
..done  std ,y
        ldd l_b12,s
        sta BUFFER1_BLOCK
        stb BUFFER2_BLOCK
        ends
        endproc

        extern getchar,chrout,cls,BINHEX ;***
GetEventBlock proc
        localvar
        char l_length,4
        stackvar
;
        ldd 4,x
        std l_length,s
        ldd 6,x
        std l_length+2,s
        clr BUFFER1_BLOCK
;is l_length greater than $2000?
..a     ldd l_length,s
        bne ..b
        ldd l_length+2,s
        cmpd #$2000
        bls ..c
;l_length is greater than $2000, so read in $2000 bytes
..b     call Read,#BUF1ADR,#$2000
        inc BUFFER1_BLOCK
;make sure we haven't over-run the end of BUFFER1
        lda BUFFER1_BLOCK
        cmpa #16
        bhs ..error
;subtract $2000 from l_length
        ldd l_length+2,s
        subd #$2000
        std l_length+2,s
        bcc ..a
        ldd l_length,s
        subd #1
        std l_length,s
        bra ..a
;l_length is <= $2000
..c     std ARG2
        pshs d
        call Read,#BUF1ADR,ARG2
        puls y
        ldx #BUF1ADR
..d     ldd 0,x              ;check for end of music marker
        cmpd #$ffff
        beq ..d1
        leax 8,x
        leay -8,y
        bne ..d
..d0    call Read,REGX,#8    ;no end found, so keep reading
        ldd 0,x              ;an event at a time until one is found.
        cmpd #$ffff
        beq ..d1
        leax 8,x
        bra ..d0
..d1    lda CONVERT_CM3
        ora CONVERT_192
        beq ..e
        lbsr ConvertEvents
..e     lbsr CheckEvents
        clra
        bra ..done
..error lda #-1
..done  ends
        endproc

GetMessagesBlock proc
        lbsr MapDataIn
        call Read,MESSAGES,<6,x>
        lbsr MapDataOut
        clra
        rts
        endproc

GetAnnotationBlock proc
        lbsr MapDataIn
        call Read,ANNOTATION,<6,x>
        lbsr MapDataOut
        clra
        rts
        endproc

; load a file as requested by a system link event
; returns -1 when error occurs, else 0
;
        global LoadLink
LoadLink PROC
        localvar
        char l_name,16
        STACKVAR S_PTR
        LDX S_PTR,S
        LDA 2,X
        CMPA #$F2
        BNE ..X
        lbsr Working
        LDA 3,X
        cmpa #16
        bhs ..X
        LDB #16
        MUL
        LDX MESSAGES
        LEAX D,X
        leay l_name,s
        lbsr MapDataIn
        ldb #16
        lbsr strncpy
        lbsr MapDataOut
; open the file
        leax l_name,s
        ldd #'R '
        LBSR Open
        tsta
        beq ..X
; read the file into memory
        LDA #$AF
        STA DISKLOAD
        lbsr ReadFile
        LBSR Close
        CLRA
        CLRB
        bra ..Z
..X     lbsr SndErr
        ldd #$ffff
..Z     pshs d
        lbsr ClrBox
        CLR DISKLOAD
        puls d
        ENDS
        ENDPROC

; erase a file (display disk directory first)
;
        global FileKill
FileKill PROC
        PSHS X
%if DEMO eq 0
        lbsr NotAvailable
        bra ..Z
%else
        tst TAPE_IO_FLAG
        bne ..Z
        LBSR GetDrive
        CMPB #BREAK
        LBEQ ..Z
        STB ..cc
        SUBB #'0'
        LBMI ..Z
        CMPB #9
        LBHI ..Z
        STB DSKDRV
        STB DEFDRIVE         ;set default drive #
        call Dir,#..dd
        LDA #15
        STA YPOS
        CLR XPOS
        LBSR MOVE
;        LBSR EraseLine
        LDX #..aa
        LBSR PUTS
        LDX #..bb
        CALL GetStr,REGX,#12
        CMPB #BREAK
        LBEQ ..Z
        LDA ..cc
        SUBA #'0'
        STA DSKDRV
        LDX #..bb
        ldd #'RV'
        LBSR Open
        tsta
        beq ..Z
        LBSR Close
        LBSR Kill
%ENDIF
..Z     LBSR ClrBox
        LDB #1
        PULS X,PC
;
%IF DEMO eq 1
..aa    FCC "  KILL:"
        FCB 0
..bb    FCC "        /CMP:"
..cc    FCC "0"
        FCB 0
;
..dd    fcb '*',0
%ENDIF
        ENDPROC

ParseFileName proc
        stackvar s_name,s_store
; first erase storage area
        ldx s_store,s
        lda #' '
        ldb #12
..erase sta ,x+
        decb
        bne ..erase
; now transfer name
        ldb #8
        ldx s_name,s
        ldy s_store,s
..name  lda ,x+
        beq ..done
        cmpa #'/'
        beq ..ext
        cmpa #'.'
        beq ..ext
        sta ,y+
        decb
        bne ..name
..ext   ldb #3
        ldy s_store,s
        leay 8,y
..loop  lda ,x+
        beq ..done
        cmpa #'/'
        beq ..loop
        cmpa #':'
        beq ..drive
        sta ,y+
        decb
        bne ..loop
..drive lda ,x+              ;get drive number
        beq ..done
        cmpa #':'
        beq ..drive
        SUBA #'0'            ;convert to binary
        BMI ..done
        CMPA #9
        BHI ..done
        STA DSKDRV
        STA DEFDRIVE
..done  ends
        endproc

; go through directory and look for given filename.
; if found, returns 1 in register A; else 0.
;
        global FindFileName
FindFileName proc
        localvar
        char l_fname,12
        stackvar s_ptr
;
        ldx s_ptr,s
        stx ARG1
        leax l_fname,s
        call ParseFileName,ARG1,REGX
        lbsr GetFirstDirectoryEntry
..loop  ;bsr ..a ;***
        tsta
        beq ..error
        leay l_fname,s
        sty ARG2
        call strncmp,REGX,ARG2,#11
        tsta
        beq ..done
        lbsr GetNextDirectoryEntry
        bra ..loop
..error clra
        bra ..z
..done  lda #1
..z     ends
;
%if 1 eq 0
..a     pshs d,x,y    ;*
        ldy #$400   ;*
;        leay d,y    ;*
        ldb #12     ;*
..b     lda ,x+     ;*
        std ,y+     ;*
        decb        ;*
        bne ..b     ;*
        lbsr SndOK  ;*
        lbsr getchar ;*
        puls d,x,y,pc ;*
%endif
        endproc

strncmp proc
        stackvar l_ptr1,l_ptr2,l_num
        ldd l_num,s
        beq ..equal
        ldx l_ptr1,s
        ldy l_ptr2,s
..loop  lda ,x+
        beq ..not
        tst ,y
        beq ..not
        cmpa ,y+
        bne ..not
        ldd l_num,s
        subd #1
        std l_num,s
        bne ..loop
..equal clra
        clrb
        bra ..z
..not   ldd #-1
..z     ends
        endproc

; return pointer to next directory entry in register X
; register A contains 1 on success, 0 on error (or end of directory).
;
GetFirstDirectoryEntry proc
        lbsr ResetDrive
        lbsr ReadFirstDirectorySector
        tsta
        beq ..error
        leax -32,x
        stx ..pointer
GetNextDirectoryEntry
        ldx ..pointer
..loop  leax 32,x
        cmpx #$700
        bhs ..next
        lda ,x               ;check first byte of entry
        beq ..loop           ;erased?
        cmpa #$ff            ;check for end of directory
        beq ..error
        bra ..done
        bra ..loop
..next  lbsr ReadDirectorySector
        tsta
        beq ..error
        leax -32,x
        bra ..loop
..error clra
        bra ..z
..done  lda #1
        stx ..pointer
..z     rts
..pointer fdb 0
        endproc

; return with address of first directory entry in register X
;
ReadFirstDirectorySector proc
        lda DEFDRIVE         ;directory has not been read, so set up variables
        sta >DSKDRV
        lda #3
        sta >DSKSEC          ;select sector 3
        lda #17
        sta >DSKTRK          ;select track 17
        ldd #$600            ;reset buffer pointer
        std >DSKBUF          ;set buffer to $600
        lda #2               ;set read operation
        sta >DSKOPC
ReadDirectorySector
        lbsr DSKCON
        tsta                 ;test for errors
        bne ..error          ;exit if error found
;prepare for next read
        lda $600             ;see if the end of the directory
        cmpa #$ff            ;has been reached
        beq ..error
        lda >DSKSEC          ;increment sector number
        inca
        cmpa #19             ;check whether we are at the end of directory
        bhi ..error
        sta >DSKSEC
        bra ..ok
..error clra
        bra ..done
..ok    lda #1
        ldx #$600
..done  rts
        endproc

        global Dir
Dir proc
        LOCALVAR L_CNT,L_FIL,l_mode
        STACKVAR S_EXT
;transfer extension to title string
        LDX S_EXT,S
        LDY #..ff
        clrb
        lda ,x
        cmpa #'*'            ;check for a wildcard extension "*"
        bne ..a0
        incb
        ldx #..gg
..a0    stb l_mode,s
        LDD ,X++
        STD ,Y++
        LDA ,X
        STA ,Y
; set up screen
        LBSR CLS
        LDX #..dd
        LBSR PUTS
; set up counters
        tst l_mode,s
        beq ..a1
        lda #2
        bra ..a2
..a1    LDA #3
..a2    STA L_CNT,S
        CLR L_FIL,S
; read a directory sector from the disk
        lbsr GetFirstDirectoryEntry
..B     tsta
        lbeq ..E
; print the filename
        LDB #8
        LDY S_EXT,S
        tst l_mode,s
        bne ..c1
..C     LDA B,X              ;test for the right extension
        CMPA ,Y+             ;Y points to FILENAME
        BNE ..D
        INCB
        CMPB #11
        BNE ..C
..c1    LDA #' '             ;valid filename, so
        LBSR ChrOut          ;print it
        LDA #' '
        LBSR ChrOut
        tst l_mode,s
        beq ..c2
        LDA #' '
        LBSR ChrOut
        lda 10,x
        clrb
        std 11,x
        ldd 8,x
        std 9,x
        lda #'.'
        sta 8,x
        bra ..c3
..c2    CLR 8,X              ;make an end of string marker
..c3    PSHS X
        LBSR PUTS            ;and print name
        PULS X
        INC L_FIL,S
        DEC L_CNT,S
        BNE ..D
        LDA #13
        LBSR ChrOut
        tst l_mode,s
        beq ..c4
        lda #2
        bra ..c5
..c4    LDA #3
..c5    STA L_CNT,S
..D     lbsr GetNextDirectoryEntry
        bra ..B
; directory display done
..E     TST L_FIL,S
        BNE ..I
        LDX #..ee            ;if no files, say so
        LBSR PUTS
; read in the FAT sector to see how much free space
..I     LBSR GETPOS
        TST XPOS
        BEQ ..J
        LDA #13
        LBSR ChrOut
..J     LDA #2
        STA >DSKSEC          ;select sector 2
        LDA #2               ;set read operation
        STA >DSKOPC
        LDA #17
        STA >DSKTRK          ;select track 17
        LDD #$0600
        STD >DSKBUF          ;set buffer to $600
        LBSR DSKCON
        TSTA                 ;test for errors
        LBNE ..X             ;exit if error found
        LDX #$0600
        CLRB
..F     LDA ,X+
        CMPA #$FF            ;is granule free?
        BNE ..G
        INCB                 ;read enough for 40 track disks
..G     TST DR40TRK
        BEQ ..K
        CMPX #$0644
        BLO ..F
        BRA ..L
..K     CMPX #$0678
        BLO ..F
..L     CLRA
        LDX #..cc
        LBSR BINDEC
        lda #15
        sta YPOS
        lda #23
        sta XPOS
        lbsr Move
        LDX #..bb
        LBSR PUTS
        LDA #13
        LBSR ChrOut
..Z     LBSR DiskOff ;turn disk motor off
        sta FAST
        ENDS
..X     LDB #40 ;DOS error code (I/O)
        LBRA Error
;
..aa    FCC "  "
        FCB 0
..bb    FCC "FREE: "
..cc    FCC "   "
        FCB 0
..dd    FCC "  DIRECTORY OF "
..ff    FCC "CMP FILES:"
        FCB 13,13
        FCB 0
..ee    FCC "  NO FILES"
        FCB 0
;
..gg    fcc "ALL"
        fcb 0
        ENDPROC

; ask user for drive number
; returns drive number (ASCII) in B
; if BREAK is pressed, returns 3 in B
;
        global GetDrive
GetDrive PROC
        PSHS X
        LDX #..aa
        CALL SetBox,REGX
        CALL BoxInp,REGX
        LBSR ClrBox
        CMPB #BREAK
        LBEQ ..Z
        LDB ..cc
..Z     PULS X,PC
;
..aa    FDB 8,5,15,5,$+12,..bb
        FDB 3,2,$+8,0 ;text string
        FCC "DRIVE #"
        FCB 0
..bb    FDB 10,2,..cc,0,0 ;input string
..cc    FCC "0"
        FCB 0
        ENDPROC

; save paste buffer to disk
;
        global BlockSave
BlockSave PROC
        localvar l_b1b
        char l_end,3
        stackvar
;
        lda BUFFER1_BLOCK
        sta l_b1b,s
        lda #16
        sta BUFFER1_BLOCK
        LDD BUF1ADR          ;is buffer empty?
        CMPD #$FFFF
        LBEQ ..X
; ask user for file name
        CALL SetBox,#..bb
        CALL BoxInp,#..bb
        lbsr ClrBox
        CMPB #BREAK
        LBEQ ..X
        LDA PASTE_FILE+13
        SUBA #'0'
        LBMI ..X
        CMPA #9
        LBHI ..X
        STA DSKDRV
        STA DEFDRIVE
;count the number of events in paste buffer
        ldy #0
        lda #16
        sta BUFFER1_BLOCK
        ldx #BUF1ADR
..a     ldd ,x
        lbsr NextAbsEvent
        leay 1,y
        cmpd #$ffff
        beq ..b
        bra ..a
..b     lda BUFFER1_BLOCK
        cmpa #16
        lblo ..x
        cmpa #32
        lbhs ..x
        sta l_end+2,s
        tfr x,d
        subd #BUF1ADR
        std l_end,s
;set up file header (convert event count to number of bytes)
        LDX #..aa            ;header address
        STY 6,X
        ldb #3
..c     lsl 7,x              ;multiply by 8 (EVNSIZE)
        rol 6,x
        rol 5,x
        decb
        bne ..c
; open the file, checking for already existing file
        LDX #PASTE_FILE
        ldd #'WV'
        LBSR Open
        tsta
        beq ..X
; write the "EVNT" header to the disk file
        lbsr Working
        CALL Write,#..aa,#8
        lda #16
        sta BUFFER1_BLOCK
..d     lda BUFFER1_BLOCK
        cmpa l_end+2,s
        beq ..e
        call Write,#BUF1ADR,#$2000
        inc BUFFER1_BLOCK
        bra ..d
..e     ldd l_end,s
        beq ..f
        std ARG2
        call Write,#BUF1ADR,ARG2
..f     call Write,#..ff,#4
        LBSR Close
        bra ..Z
..X     lbsr SndErr
..Z     LBSR ClrBox
        lda l_b1b,s
        sta BUFFER1_BLOCK
        CLRA
        CLRB
        ends
;
..aa    FCC "EVNT"
        FDB 0,0
;
..bb    FDB 4,5,24,5,..cc,..ee
..cc    FDB 2,2,..dd,0
..dd    FCC "SAVE:"
        FCB 0
..ee    FDB 8,2,PASTE_FILE,0,0
;
..ff    fcc "END!"
        endproc

PASTE_FILE FCC "PASTE   /CUT:0"
        fcb 0

        global BlockLoad
BlockLoad proc
        lda XPOS
        ldb YPOS
        pshs d,x
        tst TAPE_IO_FLAG
        beq ..a0
        lbsr GetFileName
        bra ..a1
..a0    LBSR GetDrive
        CMPB #BREAK
        LBEQ ..X
        STB PASTE_FILE+13
        SUBB #'0'
        LBMI ..X
        CMPB #9
        LBHI ..X
        STB DSKDRV
        STB DEFDRIVE
; get a disk directory and ask for filename
        CALL Dir,#PASTE_FILE+9
        LDA #15
        STA YPOS
        CLR XPOS
        LBSR MOVE
;        LBSR EraseLine
        LDX #..aa
        LBSR PUTS
        CALL GetStr,#PASTE_FILE,#8
        CMPB #BREAK
        LBEQ ..X
; open the file
..a1    LDX #PASTE_FILE
        ldd #'RV'
        LBSR Open
        tsta
        lbeq ..X
; read the file header
..A     lbsr ClrBox
        lbsr Working
        lda #16
        sta BUFFER1_BLOCK
        ldx #BUF1ADR
        CALL Read,REGX,#8
; make sure we have a real paste file
        LDD 0,x
        CMPD #'EV'
        BNE ..X
        LDD 2,x
        CMPD #'NT'
        BNE ..X
; read the file into memory
..b     call Read,REGX,#EVNSIZE
        ldd ,x
        cmpd #$ffff
        beq ..c
        lbsr NextAbsEvent
        bra ..b
..c     LBSR Close
        lbsr SndOK
        BRA ..Z
..X     LBSR SndErr
..Z     puls d
        sta XPOS
        stb YPOS
        lbsr RedisplayPage
        puls x,pc
;
..aa    FCC "  LOAD:"
        fcb 0
        endproc

        global SaveSyx
SaveSyx proc
        stackvar s_end,s_blk
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        CMPB #BREAK
        LBEQ ..X
        LDA ..fname+13       ;get drive #
        SUBA #'0'            ;convert to binary
        LBMI ..X
        CMPA #9
        LBHI ..X
        STA DSKDRV
        STA DEFDRIVE
; open the file, checking for already existing file
        LDX #..fname
        ldd #'WV'
        LBSR Open
        tsta
        beq ..X
..A     lbsr ClrBox
        lbsr Working
        lda #16
        sta BUFFER1_BLOCK
..B     lda BUFFER1_BLOCK
        cmpa s_blk+1,s
        beq ..C
        call Write,#BUF1ADR,#$2000
        inc BUFFER1_BLOCK
        bra ..B
;write the last block (<$2000 bytes)
..C     ldd s_end,s
        std ARG2
        call Write,#BUF1ADR,ARG2
        bra ..Y
..X     lbsr SndErr
        bra ..Z
..Y     lbsr Close
..Z     lbsr ClrBox
        ends
..aa    FDB 4,5,24,5,$+12,..bb
        FDB 2,2,$+8,0
        FCC "SAVE:"
        FCB 0
..bb    FDB 8,2,$+10,0,0
..fname fcc "DUMP    /SYX:0"
        fcb 0
        endproc

        global IRQ_Empty
IRQ_Empty proc
        lda $ff00
        lda $ff02
        rti
        endproc

        extern MIDI_Out,MPI3,MPI4,SetHIRQ,MSTAT,CLOCK_FLAG
        global PlaySyx
PlaySyx proc
        localvar l_oldwap,l_oldirq,l_read
        char l_fname,15
        stackvar
        pshs cc
        orcc #$50            ;disable main clock interrupt
        TST CLOCK_FLAG
        BEQ ..b2
;        LDA #$fc
;        lbsr MIDI_Out
..b2    ldd IRQ_VECTOR+1
        std l_oldirq+1,s
        ldd #IRQ_Empty
        std IRQ_VECTOR+1
        LDA #$34             ;enable 60 hz PIA interrupt
        STA $FF01
        INCA
        STA $FF03
        clr $ff92            ;disable GIME interrupts
        lbsr MPI4
        ldb 3,x              ;get message #
        lda #16
        mul
        ldx MESSAGES
        leax d,x
        leay l_fname,s
        lbsr MapDataIn
; truncate the filename after the first space
..b     lda ,x+
        sta ,y+
        beq ..b1
        cmpa #' '
        bne ..b
        clr -1,y
..b1    lbsr MapDataOut
; open the file
        leax l_fname,s
        ldd #'R '
        lbsr Open
        tsta
        beq ..X
..A     lda WORKING_ALERT_POSITION
        sta l_oldwap+1,s
        leax l_read+1,s
..a1    call Read,REGX,#1    ;read the first $f0
        lda ,x
        bpl ..Y              ;abort if byte < 128 is found instead
..a2    lbsr MIDI_Out
..a3    call Read,REGX,#1    ;read the bytes < 128
        lda ,x
        bpl ..a2
        lbsr MIDI_Out        ;output the last byte in the block
        bra ..a1
..Y     lbsr Close
        lda l_oldwap+1,s
        sta WORKING_ALERT_POSITION
        bra ..Z
..X     lbsr SndErr
..Z     orcc #$50
        ldd l_oldirq+1,s
        std IRQ_VECTOR+1
        LDA #3               ;initialize ACIA
        STA [MSTAT]          ;master reset
        LDA #$95             ;set 8 bits, no parity
        STA [MSTAT]          ;enable receive int.
        LBSR MPI3            ;enable MPI
        lbsr SetHIRQ
        TST CLOCK_FLAG
        BEQ ..a4
;        LDA #$fb
;        lbsr MIDI_Out
..a4    puls cc
        ends
        endproc

        extern BOXBUFR,SaveBox
        global DIRECTORY
DIRECTORY proc
        pshs x
        tst TAPE_IO_FLAG
        beq ..b
        lbsr NotAvailable
        bra ..z
;save screen and clear it
..b     lbsr GetDrive
        CMPB #BREAK
        LBEQ ..Z
        SUBB #'0'
        LBMI ..Z
        CMPB #9
        LBHI ..Z
        STB DSKDRV
        STB DEFDRIVE         ;set default drive #
        lda XPOS
        ldb YPOS
        pshs d
        clr XPOS
        clr YPOS
        lbsr Move
        CALL SaveBox,#32,#16,BOXBUFR
        lbsr Cls
        ldx #..a
        call Dir,REGX
        lbsr getchar
        puls d
        sta XPOS
        stb YPOS
        lbsr Move
        lbsr ClrBox
..z     puls x,pc
..a     fcc "*  "
        fcb 0
        endproc

        global NotAvailable
NotAvailable proc
        call SetBox,#..aa
        lbsr getchar
        lbsr ClrBox
        rts
..aa    FDB 7,5,17,5,$+12,0
        FDB 2,2,$+8,0
        FCC "NOT AVAILABLE"
        FCB 0
        endproc

; delete a file
; file name ptr. (max of 12 characters) in X
;
        global Kill
Kill PROC
        tst TAPE_IO_FLAG
        beq ..c
        rts
..c     PSHS X,Y
        LDY #..bb
        LDB #12
..A     LDA ,X+
        STA ,Y+
        BEQ ..B
        DECB
        BNE ..A
..B     LDX #..aa
        LBSR BASIC
        LBSR DiskOff
        PULS X,Y,PC
;
..aa    FCB $D2,$22 KILL token
..bb    FCC \            "\
        FCB 0
        ENDPROC

; Read S_CNT number of bytes from disk into
; memory pointed by S_PTR.
;
        global Read
Read PROC
        tst TAPE_IO_FLAG
        lbne TapeRead
        STACKVAR S_PTR,S_CNT
        LDY S_CNT,S
        BEQ ..Z
        TST DBRDFLG
        BNE ..C
        LBSR ReadRaw
        INC DBRDFLG
..C     LDU S_PTR,S
        LDX DBUFPTR
..A     LDA ,X+
        STA ,U+
        CMPX #$A89
        BLO ..B
        LBSR ReadRaw
        LDX #$989
..B     LEAY -1,Y
        BNE ..A
        STX DBUFPTR
..Z     ENDS
        ENDPROC

%IF DEMO
; Write S_CNT number of bytes to disk from
; memory pointed to by S_PTR.
;
        global Write
Write PROC
        tst TAPE_IO_FLAG
        lbne TapeWrite
        STACKVAR S_PTR,S_CNT
        LDY S_CNT,S
        BEQ ..Z
        LDX S_PTR,S
        LDU DBUFPTR
..A     LDA ,X+
        STA ,U+
        CMPU #$A89
        BNE ..B
        LBSR WriteRaw
        LDU #$989
..B     LEAY -1,Y
        BNE ..A
        STU DBUFPTR
..Z     ENDS
        ENDPROC
%ENDIF

; Read a sector from a direct access file
; Current sector number used
; Data read into direct access buffer
; Sector number incremented
;
        global ReadRaw
ReadRaw PROC
        com WORKING_ALERT_POSITION
        PSHS X
        LDD SECTOR
        LDX #..bb
        LBSR BINDEC
        LDX #..aa
        LBSR BASIC
        ldd SECTOR
        addd #1
        std SECTOR
..Z     PULS X,PC
;
..aa    FCB $C4,$23,$31,$2C ;GET#1,
..bb    FCB $31,0,0,0 ;space for 3 digits
        ENDPROC

%IF DEMO
; Write a sector to a direct access file
; Data is already in buffer, current sector is used.
; Sector number incremented
;
        global WriteRaw
WriteRaw PROC
        com WORKING_ALERT_POSITION
        PSHS X
        LDD SECTOR
        LDX #..bb
        LBSR BINDEC
        LDX #..aa
        LBSR BASIC
        ldd SECTOR
        addd #1
        std SECTOR
..Z     PULS X,PC
;
..aa    FCB $C5,$23,$31,$2C ;PUT#1,
..bb    FCB $31,0,0,0 ;space for 3 digits
        ENDPROC
%ENDIF

; Close all disk files
;
        global Close
Close PROC
        tst TAPE_IO_FLAG
        lbne TapeClose
        PSHS X
%IF DEMO
        tst DISK_ACCESS_MODE
        beq ..A
        LDD DBUFPTR ;see if there is anything in the buffer
        CMPD #DBUFFER
        BEQ ..A
        LBSR WriteRaw
%ENDIF
..A     LDX #..aa
        LBSR BASIC
        LBSR DiskOff ;turn drive motor off
        PULS X,PC
;
..aa    FCB $9A ;CLOSE token
        FCC "#1"
        FCB 0
        ENDPROC

; open direct access file
; Access mode in register A ('R' or 'W'), flag in B ('V' for verbose)
; file name ptr. (max of 12 characters) in X
; Returns 1 on success, 0 on error (file not found or over-write not wanted).
;
        global Open
Open PROC
        tst TAPE_IO_FLAG
        lbne TapeOpen
        PSHS X,Y
        cmpa #'R'
        bne ..a1
        clra
..a1    std DISK_ACCESS_MODE
;check for file of same name
        lbsr FindFileName
        tst DISK_ACCESS_MODE
        bne ..c
        tsta
        bne ..open
        lda DISK_ACCESS_MODE+1
        cmpa #'V'            ;READ: if file does not already exist, abort
        bne ..X
        lbsr ClrBox
        CALL SetBox,#..dd
        lbsr getchar
        lbsr ClrBox
        bra ..X
..c     tsta                 ;WRITE: if file already exists, ask user if
        beq ..open           ;he wants to replace it
        lda DISK_ACCESS_MODE+1
        cmpa #'V'
        bne ..d
        lbsr DiskOff
        lbsr ClrBox
        call SetBox,#..cc
        lbsr getchar
        lbsr ClrBox
        CMPA #'Y'
        LBNE ..X
..d     LDX 0,s              ;restore pointer to filename
        LBSR Kill
..open  LDY #..bb
        LDB #12
..A     LDA ,X+
        STA ,Y+
        BEQ ..B
        DECB
        BNE ..A
..B     LDX #..aa
        LBSR BASIC
        LDD #DBUFFER         ;zero the direct access disk buffer
        STD DBUFPTR
        LDD #1
        STD SECTOR
        CLR DBRDFLG
        bra ..Y
..X     lbsr DiskOff
        clra                 ;return error code
        bra ..Z
..Y     lda #1
..Z     PULS X,Y,PC
;
..aa    FCB $99 ;OPEN token
        FCC \"D",#1,"\
..bb    FCC \            "\
        FCB 0
;
..cc    FDB 6,5,20,5,$+12,0
        FDB 2,2,$+8,0
        FCC "OVER-WRITE FILE?"
        FCB 0
;
..dd    FDB 3,5,25,5,$+12,0
        FDB 2,2,$+8,0
        FCC "ERROR: FILE NOT FOUND"
        fcb 0
        ENDPROC

; NOW FOLLOW TAPE I/O ROUTINES ****************************************

TAPE_BLOCK equ $ffa6
TAPEADR equ $c000

TAPE_BUFR_PTR fdb TAPEADR
TAPE_BUFR_EMPTY fcb 1   ;=1 if buffer is empty
       global TAPE_SPEED
TAPE_SPEED fdb 0        ;=1 if high speed tape IO
TAPE_READ fcb 0         ;=1 if tape is being read

        extern strncpy
TapeOpen proc
        tst TAPE_SPEED
        beq ..a0
        sta SLOW
..a0    cmpa #'R'
        beq ..a
        clra
..a     sta TAPE_READ
        lda #1
        sta TAPE_BUFR_EMPTY
        ldd #TAPEADR
        std TAPE_BUFR_PTR
        tst TAPE_READ
        lbeq TapeOpenWrite
TOpenRead lda TAPE_BLOCK
        pshs a,dp,x,y
        LDA $FF01       ;enable tape sound
        ora #8
        sta $ff01
        clra
        tfr a,dp
        lbsr MapBasicIn
        lda #$36
        sta TAPE_BLOCK
        LDD #TAPEADR
        STD >$7E        ;CBUFAD
        JSR [$A004]     ;CSRDON
..loop  JSR [$A006]     ;BLKIN
        tst >$7C        ;BLKTYP
        bne ..loop      ;header block?
        ldd $88         ;display current filename on screen
        pshs d
        ldd #$50e
        std $88
        ldx #TAPEADR
        clr 12,x
        lbsr puts
        puls d
        std $88
        lda FILENAME    ;do a name check only if first letter is not a space
        cmpa #' '
        beq ..done
        call strncmp,#TAPEADR,#FILENAME,#12
        cmpd #0
        bne ..loop
..done  ldx #TAPEADR
        ldy #FILENAME
        ldb #12
        lbsr strncpy
        lbsr MapBasicOut
        puls a
        sta TAPE_BLOCK
        lda #1
        puls dp,x,y,pc
        endproc

TapeOpenWrite proc
        pshs dp,x,y
        ldd #512        ; set new tape SYNCLEN
        std $92
        ldd #FILENAME
        std >$7E        ; CBUFAD
        clr >$7C        ; BLKTYP
        lda #12
        sta >$7D        ; BLKLEN
        clra
        tfr a,dp
        lbsr MapBasicIn
        JSR [$A00C]     ; write leader sync signal
        JSR [$A008]     ; write FILENAME header
        lbsr MapBasicOut
        ldd #128
        std $92         ; restore old tape SYNCLEN
        lda #1
        puls dp,x,y,pc
        endproc

TapeRead proc
        localvar l_tblk
        STACKVAR S_PTR,S_CNT
        lda TAPE_BLOCK
        sta l_tblk,s
        LDY S_CNT,S
        BEQ ..Z
        TST TAPE_BUFR_EMPTY
        beq ..C
        LBSR TapeReadRaw
        clr TAPE_BUFR_EMPTY
..C     LDU S_PTR,S
        LDX TAPE_BUFR_PTR
        lda #$36
        sta TAPE_BLOCK
..A     LDA ,X+
        STA ,U+
        CMPX #TAPEADR+$2000
        BLO ..B
        LBSR TapeReadRaw
        LDX #TAPEADR
..B     LEAY -1,Y
        BNE ..A
        STX TAPE_BUFR_PTR
..Z     lda l_tblk,s
        sta TAPE_BLOCK
        ENDS
        endproc

TapeReadRaw proc
        lda TAPE_BLOCK
        pshs a,dp,x,y
        LDD #TAPEADR
        std TAPE_BUFR_PTR
        STD >$7E        ;CBUFAD
        clra
        tfr a,dp
        lbsr MapBasicIn
        lda #$36
        sta TAPE_BLOCK
        JSR [$A004]     ;CSRDON
..loop  JSR [$A006]     ;BLKIN
        com WORKING_ALERT_POSITION
        lda >$7C        ;BLKTYP
        cmpa #$ff       ;end of file?
        beq ..done
        ldd >$7e        ;CBUFAD
        addb >$7d       ;BLKLEN
        adca #0
        std >$7e        ;CBUFAD
        cmpd #TAPEADR+$2000
        blo ..loop
..done  puls a
        sta TAPE_BLOCK
        lbsr MapBasicOut
        puls dp,x,y,pc
        endproc

; Write $2000 bytes (1 block) to tape.
; Each block is preceded by a sync signal.
;
TapeWriteRaw proc
        lda TAPE_BLOCK
        pshs a,dp,x,y,u
        LDD #TAPEADR
        STD >$7E        ;CBUFAD
        LDA #1
        STA >$7C        ;BLKTYP
        LDA #$FF
        STA >$7D        ;BLKLEN
        clra
        tfr a,dp
        lbsr MapBasicIn
        lda #$36
        sta TAPE_BLOCK
        JSR [$A00C]     ; write sync signal
..loop  jsr [$A008]     ; write a block
        lbsr CheckForKey
        cmpa #3
        beq ..error
        com WORKING_ALERT_POSITION
        ldd >$7e        ;get CBUFAD
        addd #255
        std >$7e
        cmpd #TAPEADR+$1fe0
        blo ..loop
        ldb #32
        STB >$7D        ;BLKLEN
        jsr [$a008]
        lda #1
        bra ..done
..error clra
..done  lbsr MapBasicOut
        puls b
        stb TAPE_BLOCK
        puls dp,x,y,u,pc
        endproc

        global INKEY
CheckForKey proc
        clr $ff02
        lda $ff00
        anda #$7f
        cmpa #$7f
        bne ..a
        clra
        bra ..done
..a     lbsr INKEY
..done  rts
        endproc

TapeWrite proc
        localvar l_tblk
        STACKVAR S_PTR,S_CNT
        LDY S_CNT,S
        BEQ ..Z
        lda TAPE_BLOCK
        sta l_tblk,s
        lda #$36
        sta TAPE_BLOCK
        LDX S_PTR,S
        LDU TAPE_BUFR_PTR
..A     LDA ,X+
        STA ,U+
        CMPU #TAPEADR+$2000
        BNE ..B
        LBSR TapeWriteRaw
        tsta
        beq ..error
        LDU #TAPEADR
..B     LEAY -1,Y
        BNE ..A
        STU TAPE_BUFR_PTR
        lda l_tblk,s
        sta TAPE_BLOCK
        lda #1
        bra ..Z
..error clra
..Z     ENDS
        endproc

        extern TVOn
TapeClose proc
        pshs dp,x,y
        tst TAPE_READ
        bne ..done
        clra
        tfr a,dp
        lbsr MapBasicIn
        lda #$36
        sta TAPE_BLOCK
        JSR [$A00C]     ; write sync signal
        LDA #1
        STA >$7C        ;BLKTYP
        LDD #TAPEADR
..loop  cmpd TAPE_BUFR_PTR
        bhs ..last
        STD >$7E        ;CBUFAD
        ldd #TAPEADR+$2000
        subd >$7e
        cmpd #$ff
        blo ..l2
        LDB #$FF
..l2    STB >$7D        ;BLKLEN
        jsr [$A008]     ; write a block
        com WORKING_ALERT_POSITION
        ldd >$7e        ;get CBUFAD
        addd #255
        bra ..loop
..last  ldd TAPE_BUFR_PTR
        subd >$7e       ;CBUFAD
        stb >$7d        ;BLKLEN
        lda #$ff
        sta >$7c        ;BLKTYP=end
        jsr [$a008]
..done  lda #$3e
        sta TAPE_BLOCK
        lbsr MapBasicOut
        lbsr DiskOff
        lbsr TVOn
        sta FAST
        puls dp,x,y,pc
        endproc

%if 1 eq 0
; routine to write program memory as a continuous tape file
;
        extern getchar,STARTUP
        global MakeTape
MakeTape proc
        pshs dp,x,y,u
        ldx #..aa
..next  lbsr getchar
        cmpa ,x+
        bne ..done
        tst ,x
        bne ..next
        clra
        clrb
        std STARTUP
        clra
        tfr a,dp
        lbsr MapBasicIn
        tst TAPE_SPEED
        beq ..a
        sta SLOW
..a     LDA #$FF
        STA >$7D        ;BLKLEN
        ldd #$0700
        std >$7e        ;CBUFAD
        clr >$7c        ;BLKTYP=header
        jsr [$a00c]     ;write sync leader
        jsr [$a008]     ;write block
        ldd #$0e00
        std >$7E        ;CBUFAD
        LDA #1
        STA >$7C        ;BLKTYP
..loop  jsr [$A008]     ;write a block
        stx >$7e        ;CBUFAD
        cmpx #$7e80
        blo ..loop
        ldd #$7f70
        pshs x
        subd ,s++
        stb >$7d        ;BLKLEN
        lda #$ff
        sta >$7c        ;BLKTYP
        jsr [$A008]     ;write a block
..done  sta FAST
        LDA $FF21       ;turn tape motor off
        ANDA #$F7
        STA $FF21
        ldd #$5af0
        std STARTUP
        puls dp,x,y,u,pc
;
..aa    fcc "OG"
        fcb 0
        endproc
%endif

        end

; end of file: DISK/TXT
