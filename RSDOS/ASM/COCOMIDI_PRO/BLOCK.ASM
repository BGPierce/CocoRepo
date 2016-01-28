; BLOCK/TXT - part of CMP
; (C) 1988 by Lester Hands
; Adjusted to support 512K extended memory

%include "macros.h"
%include "cmp.h"

		EXTERN ARG1,ARG2,ARG3,ARG4,ATOI,BELL,BINDEC,BLK_END,BLK_STRT
        EXTERN BOXINP,BR_SCALE,BR_SETUP,TIMEBASE
        EXTERN CHKFILT,CLRBOX,CLS,ConvertAsciiTime,CNVNOTE,CNVNOTLN
        EXTERN CPCALC,DIVIDE,DOCMD,GETCHAR,GOTO,MEM_LINE
        EXTERN MOVE,MULT,NEXTEVNT,REMAIN,SETBOX,SNDERR,SNDOK
        EXTERN TRACK,YPOS,EX_TIME1,Working,TRAK_FLG,FILT_FLG
        extern CnvFrac,MultFrac,NextAbsEvent,BlockLoad,BlockSave
        extern RedisplayPage
		extern SndOK,SndErr

; call block commands
; returns current value of X in X
;
        global EK_BLOCK
EK_BLOCK PROC
        pshs y
..A     CALL SetBox,#..aa
        LBSR getchar
        TFR A,B
        LBSR ClrBox
        LDY #..y
        PSHS Y
        LBSR DoCmd
        LEAS 2,S
..Z     puls y,pc
;
..aa    FDB 1,2,30,12,..bb,0
..bb    FDB 1,0,..cc,$+8
		FDB 3,2,..dd,$+8
        FDB 3,3,..ee,$+8
        FDB 3,4,..ff,$+8
        FDB 3,5,..gg,$+8
        FDB 3,6,..hh,$+8
        FDB 3,7,..mm,$+8
        fdb 3,8,..tt,$+8
        fdb 3,9,..vv,$+8
        FDB 14,2,..nn,$+8
        FDB 14,3,..oo,$+8
        FDB 14,4,..pp,$+8
        FDB 14,5,..qq,$+8
        FDB 14,6,..rr,$+8
        FDB 14,7,..ss,$+8
        fdb 14,8,..uu,$+8
        fdb 14,9,..ww,0
..cc    FCC " BLOCK "
        FCB 0
..dd    FCC "cOPY"
        FCB 0
..ee    FCC "CuT"
        FCB 0
..ff    FCC "pASTE"
        FCB 0
..gg    FCC "qUANTIZE"
        FCB 0
..hh    FCC "sCALE"
        FCB 0
..mm    FCC "ChANNEL"
        FCB 0
..tt    fcc "LoAD"
        fcb 0
..vv    fcc "CUlL"
        fcb 0
..nn    FCC "CrEATE"
		FCB 0
..oo    FCC "eXTRACT"
        FCB 0
..pp    FCC "tRANSPOSE"
        FCB 0
..qq    FCC "CLiP VELOCITY"
        FCB 0
..rr    FCC "mAP NOTES"
        FCB 0
..ss    FCC "nOTE LENGTH"
        fcb 0
..uu    fcc "SaVE"
        FCB 0
..ww    fcc "UNdO"
;
..ii    FDB 6,5,20,6,..jj,0
..jj    FDB 2,2,..kk,$+8
        FDB 2,3,..ll,0
..kk    FCC "BLOCK NOT MARKED"
        FCB 0
..ll    FCC "BUFFER IS EMPTY"
        FCB 0
;
..y     FCB 'C'
        FDB BlkCopy
        FCB 'U'
        FDB BlkCut
        FCB 'P'
        FDB BlkPaste
        FCB 'Q'
        FDB Quantize
        FCB 'S'
        FDB Scale
        FCB 'H'
        FDB Channel
		FCB 'R'
        FDB Create
        FCB 'E'
        FDB Extract
        FCB 'T'
        FDB Transpos
        FCB 'I'
        FDB Clip
        FCB 'M'
        FDB ReMap
        FCB 'N'
        FDB NoteFrac
        fcb 'O'
        fdb BlockLoad
        fcb 'A'
        fdb BlockSave
        fcb 'L'
        fdb BlockCull
        fcb 'D'
        fdb BlockUndo
        FCB 0
        ENDPROC

        global ClearBuffer3
ClearBuffer3 proc
        lda BUFFER1_BLOCK
        pshs a
        lda #$20
        sta BUFFER1_BLOCK
        ldd #$ffff
        std BUF1ADR
        puls a
        sta BUFFER1_BLOCK
        rts
        endproc

; copy all events from buffer3 to buffer1
;
        global BlockUndo
BlockUndo proc
        lda BUFFER1_BLOCK
        pshs a
        lda #$20             ;make sure buffer3 isn't empty
        sta BUFFER1_BLOCK
        ldd BUF1ADR
        cmpd #$ffff
        bne ..ok
        call SetBox,#..aa
        lbsr getchar
        lbsr ClrBox
        bra ..done
..ok    lda #1
        lbsr CopyBuf1Buf3
        lbsr RedisplayPage
        lbsr SndOK
..done  puls a
        sta BUFFER1_BLOCK
        rts
..aa    fdb 4,5,24,5,$+12,0
        fdb 2,2,$+8,0
        fcc "UNDO BUFFER IS EMPTY"
        fcb 0
        endproc

; quantize the event times in a block
;
        global Quantize
Quantize PROC
        LOCALVAR l_resolution,l_factor
        char l_Qtime,3
		char l_Qhalf,3
        STACKVAR
;
        LBSR TestBLK
        CMPD #0
        lbeq ..Z
; ask for quantization resolution
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        LBEQ ..Z
        LDX #..ee
        lbsr atoi
        cmpd #0
        lbeq ..X
        cmpd TIMEBASE
        lbhi ..X
        STD l_resolution,s
        lsla
        rorb
        std l_Qhalf+1,s     ;put 0.5 of l_resolution in l_Qhalf
        clr l_Qhalf,s
; make quantized starting time=0
        clra
        clrb
        sta l_Qtime,s
        std l_Qtime+1,s
; convert Percent to l_factor
        ldx #..gg
        lbsr atoi
        cmpd #100            ;allow values of 1-100 only
        lbhi ..X
        cmpd #0
        lbeq ..X
		tfr b,a              ;l_factor = n*256/100
        clrb
        std ARG1
        call Divide,ARG1,#100
        lda REMAIN+1
        cmpa #50
        blo ..g1
        incb
..g1    clra
        std l_factor,s
; put marked block in buffer2
        lbsr Working
        call _blockCopy,#0,#0
        lbsr _blockDelete
; set up register X to point to BUFFER2
        ldx #BUF2ADR
        lda #16
        sta BUFFER2_BLOCK
; start of quantization loop
..loop  com WORKING_ALERT_POSITION
        ldd 0,x
        cmpd #$ffff          ;look for end
        lbeq ..Y
; look for an event that <l_Qhalf
..check_time
        leay l_Qhalf,s
        sty ARG1
        call CompareExTimes,ARG1
        cmpd #-1             ;is the event less than l_Qhalf?
        lbne ..next_time
; the right time slot has been found, compare event time to l_Qtime
        leay l_Qtime,s
        sty ARG1
        call CompareExTimes,ARG1
        cmpd #0              ;if equal, then no need to quantize
		beq ..next_event
        cmpd #1              ;is event greater than l_Qtime?
        beq ..quantize_upper
..quantize_lower
		ldd l_Qtime+1,s
        tst l_factor+1,s     ;if LSB of factor is 0, then actual value is $100
		bne ..ql0            ;and no need to scale
		std 0,x
		bra ..next_event
..ql0   subd 0,x
		lda l_factor+1,s
        mul
        cmpb #$80
        blo ..ql1
        inca
..ql1   clrb
        exg a,b
        addd 0,x
		std 0,x
		bcc ..next_event
		lda 7,x
		adda #$10
        sta 7,x
		bra ..next_event
..quantize_upper
        tst l_factor+1,s
        bne ..qu1
        ldd l_Qtime+1,s
		std 0,x
		bra ..next_event
..qu1   ldd 0,x
		subd l_Qtime+1,s
		lda l_factor+1,s
        mul
        cmpb #$80
		blo ..qu2
        inca
..qu2   clrb
        exg a,b
        addd l_Qtime+1,s
        std 0,x
        bcc ..next_event
		lda 7,x
		adda #$10
		sta 7,x
..next_event
        leax EVNSIZE,x
        cmpx #BUF2ADR+$2000
        lblo ..loop
        ldx #BUF2ADR
        inc BUFFER2_BLOCK
        lbra ..loop
; increment l_Qtime and l_Qhalf
..next_time
        ldd l_Qtime+1,s
        addd l_resolution,s
        std l_Qtime+1,s
        bcc ..nt1
        lda l_Qtime,s
        adda #$10
        sta l_Qtime,s
..nt1   ldd l_Qhalf+1,s
        addd l_resolution,s
        std l_Qhalf+1,s
        bcc ..nt2
        lda l_Qhalf,s
        adda #$10
        sta l_Qhalf,s
..nt2   lbra ..check_time
; error exit
..X     lbsr SndErr
        bra ..Z
; merge buffers and quit
..Y     LBSR MergeBuffers
        lbsr ClearBuffer3
        lbsr RedisplayPage
        stx S.X,s
..Z     ENDS
;
..aa    FDB 1,3,30,10,..bb,..dd
..bb    FDB 4,4,$+8,..cc
        FCC "TICKS="
        FCB 0
..cc    fdb 2,5,$+8,..hh
        fcc "PERCENT="
        fcb 0
..dd    FDB 10,4,..ee,..ff,0 ;input string
..ee    FCC "60 "
        FCB 0
..ff    fdb 10,5,..gg,0,..dd
..gg    fcc "100"
..hh    fdb 15,2,..ii,$+8
        fdb 15,3,..jj,$+8
        fdb 15,4,..kk,$+8
        fdb 15,5,..ll,$+8
        fdb 15,6,..mm,$+8
        fdb 15,7,..nn,0
..ii    fcc "240= QUARTER"
        fcb 0
..jj    fcc "120= EIGHTH"
        fcb 0
..kk    fcc "80 = 1/8 TRP"
        fcb 0
..ll    fcc "60 = 1/16"
        fcb 0
..mm    fcc "40 = 1/16 TRP"
        fcb 0
..nn    fcc "30 = 1/32"
        fcb 0
        ENDPROC

;; Add amount in register D to start time of event pointed to by register X
;; Extended time is supported.
;; The value in register D is preserved
;;
;        global AddExTime
;AddExTime proc
;        pshs d
;        addd 0,x
;        std 0,x
;        bcc ..a
;        lda 7,x
;        adda #$10
;        sta 7,x
;..a     puls d,pc
;        endproc

; create new events: same as first event in block
;
		global Create
Create PROC
        LOCALVAR L_AMT
		char l_event,EVNSIZE
        STACKVAR
;
        LBSR TestBLK
        CMPD #0
        lbeq ..Z
        lda 2,x              ;make sure we aren't trying to duplicate
        cmpa #$f2            ;a message type event
		beq ..bad_ev
        cmpa #$f3
        beq ..bad_ev
        cmpa #$f6
        bne ..ok_ev
..bad_ev call SetBox,#..gg
        lbsr SndErr
        lbsr getchar
        lbsr ClrBox
        lbra ..Z
..ok_ev CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        LBEQ ..Z
        clra
        CALL CnvNotLn,#..ff  ;convert spacing to binary
        STD L_AMT,S
		lbsr FindStart       ;find first event in marked block in BUFFER1
		leay l_event,s       ;copy event to stack
		ldb #EVNSIZE
..A1    lda ,x+
        sta ,y+
		decb
		bne ..A1
; put new events in BUFFER2
        ldy #BUF2ADR         ;Y points to BUFFER2
        lda #16
        sta BUFFER2_BLOCK
..A     ldd l_event,s        ;move to next time
		addd L_AMT,S
		std l_event,s
		bcc ..a2
		lda l_event+7,s
		adda #$10
		sta l_event+7,s
..a2    lda l_event+7,s      ;check for end
        anda #$f0
        cmpa BLK_END
        bhi ..B
		blo ..a3
		ldd l_event,s
        cmpd BLK_END+1
        bhs ..B
..a3    leax l_event,s
		ldd ,x++
		cmpd #$ffff          ;added to prevent premature end marker
		bne $+3
		decb
		std ,y++
		ldb #EVNSIZE-2
..C     lda ,x+
        sta ,y+
        decb
        bne ..C
        cmpy #BUF2ADR+$2000
        blo ..A
		ldy #BUF2ADR
		lda BUFFER2_BLOCK
		cmpa #31
		bhs ..X
		inc BUFFER2_BLOCK
		bra ..A
..B     ldd #$FFFF           ;mark end of buffer
        std ,y
        lbsr MergeBuffers
        lbsr RedisplayPage
        stx S.X,s
        bra ..Z
..X     ldx #BUF2ADR
		lda #16
        sta BUFFER2_BLOCK
        ldd #$ffff
        sta ,x
        lbsr SndErr
..Z     ENDS
;
..aa    fdb 7,5,17,6,..bb,..ee
..bb    fdb 2,2,..cc,$+8 ;text
		fdb 2,3,..dd,0 ;text
..cc    fcc "CREATE EVENTS"
        fcb 0
..dd    fcc "SPACING="
		fcb 0
..ee    fdb 10,3,..ff,0,0 ;input
..ff    fcc "1:0  "
        fcb 0
;
..gg    fdb 2,5,28,5,$+12,0
        fdb 3,2,$+8,0
        fcc "CAN'T COPY THIS EVENT!"
        fcb 0
        ENDPROC

WasAtTime fcb 0,0,0		;extended time of start of last cut or paste

; paste the hold buffer into specified point
; the current track is forced on the buffer data
;
		extern ConvertBinaryTime
		global BlkPaste
BlkPaste PROC
		LOCALVAR l_b1p
		char L_GO,3
		char l_ext,3
		STACKVAR
;
		lda #16
		sta BUFFER2_BLOCK
		ldd BUF2ADR
		cmpd #$ffff
		bne ..a2
		lbsr TestBLK
		lbra ..Z
..a2    lda BUFFER1_BLOCK
		sta l_b1p,s
		LDX MEM_LINE         ;save time at top of page
		lda MEM_LINE+2
		sta BUFFER1_BLOCK
		lda 7,x              ;get extended time
		anda #$f0
		sta L_GO,s
		ldd 0,x
		cmpd #$ffff          ;if top of page is "END OF BUFFER"
		bne ..a1             ;change time to 1/1:0
		clra
		clrb
		clr L_GO,s
..a1    STD L_GO+1,S
; ask user for time to make paste
		call ConvertBinaryTime,#..gg+12,#WasAtTime
		CALL SetBox,#..aa
		CALL BoxInp,#..aa
		LBSR ClrBox
		CMPB #BREAK
		LBEQ ..Z
		lbsr Working
		CALL ConvertAsciiTime,#..ee,#EX_TIME1
		ldd EX_TIME1
		std l_ext,s
		lda EX_TIME1+2
		sta l_ext+2,s
		CALL AddTimeBuffer2,#EX_TIME1
; change BUFFER2 track numbers to the current one
		LDX #0
        lda #16
		sta BUFFER2_BLOCK
..A     LDD BUF2ADR,X        ;check for end
        CMPD #$FFFF
        BEQ ..B
        lda BUF2ADR+7,X      ;change track #
        anda #$f0            ;keep extended time info
        ora TRACK
        sta BUF2ADR+7,x
		LEAX EVNSIZE,X
		cmpx #$2000
        blo ..A
        ldx #0
        inc BUFFER2_BLOCK
        BRA ..A
..B     LBSR MergeBuffers
; restore BUFFER2 times to start with 1/1:0
        lda l_ext,s          ;make negative value of l_ext
        eora #$f0
        sta l_ext,s
		ldd l_ext+1,s
        coma
        comb
        addd #1
		std l_ext+1,s
		bcc ..b1
		lda l_ext,s
		adda #$10
		sta l_ext,s
..b1    leax l_ext,s
		CALL AddTimeBuffer2,REGX
		lbsr ClrBox
		lbsr RedisplayPage
		stx S.X,s
..Z     ENDS
;
..aa    FDB 0,5,32,6,..bb,..dd
..bb    FDB 2,2,..cc,..ff
..cc    FCC "PUT BLOCK AT TIME="
		FCB 0
..dd    FDB 20,2,..ee,0,0
..ee    FCC "1/1:0     "
		FCB 0
..ff	fdb 8,3,..gg,0
..gg	fcc "WAS AT TIME=          "
		fcb 0
		ENDPROC

; add a given amount (pointer to extended time) to event times in buffer2
;
		global AddTimeBuffer2
AddTimeBuffer2 PROC
		stackvar S_AMT
		ldx #0
		lda #16
		sta BUFFER1_BLOCK
		ldy S_AMT,s
..A     ldd BUF1ADR,X        ;check for end
		cmpd #$FFFF
		beq ..Z
		addd 1,y
		pshs cc
		cmpd #$ffff          ;added to prevent premature end marker
		bne $+3
		decb
		puls cc
		std BUF1ADR,X
		lda 0,y
		bcc ..a1
		adda #$10
..a1    adda BUF1ADR+7,x
		sta BUF1ADR+7,x
		leax EVNSIZE,X
		cmpx #$2000
		blo ..A
		ldx #0
		inc BUFFER1_BLOCK
		bra ..A
..Z     ENDS
		ENDPROC

; copy a block to the paste buffer
; no block checking or user feed-back
; s_adr and s_ext are an extended time added to each event time
;
		global _blockCopy
_blockCopy proc
		stackvar s_time,s_ext
		lbsr FindStart
        ldy #BUF2ADR
        lda #16
        sta BUFFER2_BLOCK
..loop  ldd 0,x              ;check for end
        cmpd #$ffff
        beq ..end
        lda 7,x              ;check extended time
        anda #$f0
        cmpa BLK_END
        bhi ..end
        blo ..check
        ldd 0,x              ;get time
        cmpd BLK_END+1       ;check for end
		bhi ..end
..check lbsr CHKFILT
		tsta
		beq ..copy
		lbsr NextAbsEvent
		bra ..loop
..copy  ldd ,x++
		addd s_time,s
		pshs cc
		cmpd #$ffff          ;added to prevent premature end marker
		bne $+3
		decb
		std ,y++
		ldb #EVNSIZE-3
..b     lda ,x+
		sta ,y+
		decb
		bne ..b
		lda ,x+
		puls cc
		bcc ..b2
		adda #$10
..b2    adda s_ext,s
		sta ,y+
		cmpx #BUF1ADR+$2000
		blo ..c
		ldx #BUF1ADR
		inc BUFFER1_BLOCK
..c     cmpy #BUF2ADR+$2000
		blo ..loop
		ldy #BUF2ADR
		inc BUFFER2_BLOCK
		bra ..loop
..end   ldd #$ffff
		std ,y
		ends
		endproc

; copy marked block into hold buffer
; adjust times so the first=1/1:0
; affects only current track; filter checked
; returns -1 if error (block too large)
;
		global BlkCopy
BlkCopy PROC
		LOCALVAR l_b1b
		stackvar
;
		lda BUFFER1_BLOCK
        sta l_b1b,s
        LBSR TestBLK
        CMPD #0
		LBEQ ..Z
		ldd BLK_STRT
		std WasAtTime
		lda BLK_STRT+2
		std WasAtTime+2
		lbsr FindStart
		LDD 0,X              ;get start time
		CMPD #$FFFF
		BEQ ..Z
        coma
        comb
        addd #1
        std ARG1
        lda 7,x              ;extended time
        anda #$f0
        eora #$f0
        bcc ..a
        adda #$10
..a     sta ARG2
        call _blockCopy,ARG1,ARG2
        LBSR SndOK
        lda l_b1b,s
        sta BUFFER1_BLOCK
..Z     ENDS
        ENDPROC

; delete a block without copying to paste buffer
;
        global _blockDelete
_blockDelete proc
        pshs x,y
        lbsr FindStart
        leay BUF2ADR-BUF1ADR,x
        lda BUFFER1_BLOCK
        sta BUFFER2_BLOCK
..loop  ldd 0,x
		cmpd #$ffff
        beq ..end
        lda 7,x              ;check extended memory
        anda #$f0
        cmpa BLK_END
        bhi ..copy
        blo ..check
        ldd 0,x
        cmpd BLK_END+1
        bhi ..copy
..check lbsr CHKFILT
        tsta
        bne ..copy
        lbsr NextAbsEvent
        bra ..loop
..copy  LDB #EVNSIZE
..d     LDA ,X+
		STA ,Y+
        DECB
        BNE ..d
        cmpx #BUF1ADR+$2000
        blo ..e
        ldx #BUF1ADR
        inc BUFFER1_BLOCK
..e     cmpy #BUF2ADR+$2000
        blo ..loop
        ldy #BUF2ADR
        inc BUFFER2_BLOCK
        bra ..loop
..end   ldd #$ffff
        std ,y
        puls x,y,pc
        endproc

; copy marked block to hold buffer
; and delete marked block
; affects only current track; filter checked
; if entry is with D=-1, then the block is cut
; and not copied to the hold buffer, and the
; screen is not updated.
;
		global BlkCut
BlkCut PROC
		LOCALVAR L_MODE,l_b1b
		char l_end,3
		STACKVAR
;
		lda BUFFER1_BLOCK
		sta l_b1b,s
		STD L_MODE,S
		LBSR TestBLK
		CMPD #0
		LBEQ ..Z
		ldd BLK_STRT
		std WasAtTime
		lda BLK_STRT+2
		std WasAtTime+2
		clra
		lbsr CopyBuf1Buf3
		LDD L_MODE,S
		CMPD #-1
		BEQ ..b
        LBSR BlkCopy
..b     lbsr _blockDelete
..Y     LDD L_MODE,S
        CMPD #-1
        BEQ ..Z
        lbsr RedisplayPage
        stx S.X,s
..Z     lda l_b1b,s
        sta BUFFER1_BLOCK
        ENDS
        ENDPROC

; test the block pointers to make sure both
; have valid values
; returns nonzero if ok, else D=0
;
        global TestBLK
TestBLK PROC
        PSHS X
        LDD #$FFFF
        CMPD BLK_STRT+1
        BEQ ..X
        CMPD BLK_END+1
        BNE ..Z
..X     call SetBox,#..a
		lbsr SndErr
		lbsr getchar
        lbsr ClrBox
        CLRA
        CLRB
..Z     PULS X,PC
;
..a     fdb 6,5,20,6,$+12,0
        fdb 2,2,..b,$+8
        fdb 2,3,..c,0
..b     fcc "BLOCK NOT MARKED"
        fcb 0
..c     fcc "BUFFER IS EMPTY"
        fcb 0
        ENDPROC

; ask for type of data to scale
; register X reflects current event address
;
        global Scale
Scale PROC
		STACKVAR
        LBSR TestBLK
        CMPD #0
        BEQ ..Z
..A     ldd BLK_END+1
        subd BLK_STRT+1
        pshs d
        lda BLK_END
		bcc ..a0
		suba #$10
..a0    suba BLK_STRT
        puls d
        bne ..a1
		cmpd #$7780
        blo ..B
..a1    call SetBox,#..nn
        lbsr getchar
        lbsr ClrBox
        bra ..Z
..B     CALL SetBox,#..aa
        LBSR getchar
        TFR A,B
        LBSR ClrBox
        LDY #..mm
        PSHS Y
        LBSR DoCmd
        LEAS 2,S
        STX S.X,S
..Z     ENDS
;
..aa    FDB 8,4,16,8,..bb,0
..bb    FDB 1,0,..cc,$+8
        FDB 3,2,..dd,$+8
        FDB 3,3,..ee,$+8
        FDB 3,4,..ff,$+8
		FDB 3,5,..gg,0
..cc    FCC " SCALE "
        FCB 0
..dd    FCC "VELOCITY"
        FCB 0
..ee    FCC "TEMPO"
        FCB 0
..ff    FCC "PITCH WHL"
        FCB 0
..gg    FCC "CONTROLLER"
        FCB 0
;
..mm    FCB 'V'
        FDB ScaleV
        FCB 'T'
        FDB ScaleT
        FCB 'C'
        FDB ScaleC
        FCB 'P'
        FDB ScaleP
        FCB 0
;
..nn    FDB 6,5,20,5,$+12,0
        FDB 2,2,$+8,0
        fcc "BLOCK TOO LARGE!"
        fcb 0
        ENDPROC

; scale pitch wheel
;
        global ScaleP
ScaleP PROC
        STACKVAR
        LBSR GetScale
        CMPD #0
		BNE ..Z
        CALL DoScale,#$E0,#3,#1
        STX S.X,S
..Z     ENDS
        ENDPROC

; scale a controller
;
        LOCALVAR L_CNT
        global ScaleC
ScaleC PROC
        STACKVAR
        lbsr FindStart       ;set up default controller #
        LDA 2,X
        ANDA #$F0            ;check status byte
        CMPA #$B0
        BNE ..A
        CLRA
        LDB 3,X              ;get controller #
        LDX #..ee
        LBSR BINDEC
..A     CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        LBEQ ..Z
        LDX #..ee
        CALL atoi
        STD L_CNT,S
        LBSR GetScale
        CMPD #0
        BNE ..Z
        LDD L_CNT,S
        STD ARG1
        CALL DoScale,#$B0,#4,#0,ARG1
..Z     ENDS
;
..aa    FDB 6,5,19,5,..bb,..dd
..bb    FDB 2,2,..cc,0
..cc    FCC "CONTROLLER #"
        FCB 0
..dd    FDB 14,2,..ee,0,0
..ee    FCC "1  "
        FCB 0
        ENDPROC

; scale the velocities
;
        global ScaleV
ScaleV PROC
        STACKVAR
        LBSR GetScale
        CMPD #0
        BNE ..Z
        CALL DoScale,#$90,#4,#0
        STX S.X,S
..Z     ENDS
        ENDPROC

; scale tempo
;
        global ScaleT
ScaleT PROC
        STACKVAR
        LBSR GetScale
        CMPD #0
        BNE ..Z
        CALL DoScale,#$F0,#3,#1
        STX S.X,S
..Z     ENDS
		ENDPROC

; ask for start and end scaling values
; also set up Bressenham variables
; This version sets the start value to 0 and adjusts the end value accordingly
; returns 0 if not aborted
;
        global GetScale
GetScale PROC
        STACKVAR
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        BEQ ..Z
        LDX #..hh
        CALL atoi
        PSHS D
        LDX #..ii
        CALL atoi
        STD ARG2
        PULS D
        STD ARG1
		ldd BLK_END+1
		subd BLK_STRT+1
		std ARG4
		clra
		clrb
		std ARG3
		CALL BR_Setup,ARG3,ARG4,ARG1,ARG2
		CLRA
		CLRB
        bra ..Z
..X     ldb #3
..Z     ENDS
;
..aa    FDB 9,4,16,8,..bb,..ff
..bb    FDB 2,2,..cc,$+8 ;text
        FDB 3,4,..dd,$+8 ;text
        FDB 5,5,..ee,0 ;text
..cc    FCC "SCALE VALUES"
        FCB 0
..dd    FCC "START="
        FCB 0
..ee    FCC "END="
        FCB 0
..ff    FDB 9,4,..hh,..gg,0 ;input
..gg    FDB 9,5,..ii,0,..ff ;input
..hh    FCC "64   "
        FCB 0
..ii    FCC "64   "
        FCB 0
        ENDPROC

; do the actual scaling after everything is set up
; the status byte specified by S_EVN
; the byte(s) in the event specified by S_POS
; and the number of bytes-1 (0 or 1) in S_SIZ
; S_CNT is used only when a controller is scaled
;
        global DoScale
DoScale PROC
        localvar L_PWFL
        STACKVAR S_EVN,S_POS,S_SIZ,S_CNT
        clra
        lbsr CopyBuf1Buf3
        CLR L_PWFL,S
        LDA S_EVN+1,S
        CMPA #$E0            ;pitch wheel event?
        BNE ..F
		INC L_PWFL,S
..F     lbsr FindStart
        LEAX -EVNSIZE,X
..E     lbsr NextAbsEvent
        LDD 0,X              ;get event time
        CMPD #$FFFF          ;check for end of music
        BEQ ..Z
        lda 7,x              ;check extended time
        anda #$f0
        cmpa BLK_END
        bhi ..Z
        blo ..e1
        ldd 0,x
        CMPD BLK_END+1       ;check for end of block
        BHI ..Z
..e1    LDA 2,X              ;get event status
        LDB S_EVN+1,S
        CMPB #$F0            ;this is a system event?
        BHS ..C
        ANDA #$F0            ;mask off channel
..C     CMPA S_EVN+1,S       ;look for right event
        BNE ..E
        CMPA #$B0            ;check for control
        BNE ..D
        LDA 3,X              ;get control number
        CMPA S_CNT+1,S       ;right one?
        BNE ..E
..D     LDA 7,X              ;check track
        anda #$0f            ;throw away extended time info
        CMPA TRACK
        BNE ..E
        LDD S_POS,S          ;point Y to data
		LEAY D,X             ;to modify
		ldd 0,x
		subd BLK_STRT+1
		std ARG1
		CALL BR_Scale,ARG1
		TST S_SIZ+1,S
        BEQ ..A
        TST L_PWFL,S
        BEQ ..G
        LSLB                 ;for pitch wheel data,
        ROLA                 ;must adapt to 7 bit
        LSRB                 ;and reverse byte order
        ANDA #$7F
        EXG A,B
..G     STD ,Y
        BRA ..B
..A     STB ,Y
..B     LDD S_EVN,S
        CMPB #$F0           ;check for tempo event
        BNE ..E
        LDD ,Y
        LBSR CPCalc
        STD 5,X
        BRA ..E
; restore the display
..Z     lbsr RedisplayPage
        stx S.X,s
        ENDS
        ENDPROC

; change channel # in a block
;
        LOCALVAR L_CHN
Channel PROC
        global Channel
        stackvar
        LBSR TestBLK
        CMPD #0
		LBEQ ..Z
; ask for channel number
..D     CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        LBEQ ..Z
        LDX #..dd
        CALL atoi
        CMPB #1              ;check max and min
        BLO ..B              ;values
        CMPB #16
        BLS ..C
..B     LBSR SndErr
        LBRA ..Z
..C     DECB
        STD L_CHN,S
        clra
        lbsr CopyBuf1Buf3
; now modify memory
        lbsr FindStart
..A     LDD 0,X              ;get event time
        CMPD #$FFFF          ;look for end of music
        BEQ ..Y
        call CompareExTimes,#BLK_END
        cmpd #1
        beq ..Y
        lda 2,x              ;get status byte
        cmpa #$f0            ;skip if this is a
        bhs ..E              ;system event
        anda #$F0            ;mask off channel
        ora L_CHN+1,S        ;or on new channel
        sta 2,x              ;replace status byte
..E     lbsr NextEvnt
        BRA ..A
..Y     lbsr RedisplayPage
        STX S.X,S            ;return ptr to top
..Z     ENDS
;
..aa    FDB 9,5,14,5,..bb,..cc
..bb    FDB 2,2,$+8,0
        FCC "CHANNEL="
        FCB 0
..cc    FDB 10,2,..dd,0,0 ;input string
..dd    FCC "1 "
        FCB 0
        ENDPROC

; change track assignment for a given channel
;
        global Extract
Extract PROC
        LOCALVAR L_CHN,L_TRK
        STACKVAR
        LBSR TestBLK
        CMPD #0
        LBEQ ..Z
; ask for track and channel numbers
..D     CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        LBEQ ..Z
        LDX #..ff
        LBSR atoi
        CMPD #1              ;check max and min values
        BLO ..X
        CMPD #16
        BHI ..X
        DECB
		STB L_CHN,S
        clra
        lbsr CopyBuf1Buf3
; convert the track number
        ldx #..gg
        lbsr atoi
        cmpd #1              ;check max and min values
        BLO ..X
        CMPD #16
        BHI ..X
        decb
        STB L_TRK,S
; now modify memory
        lbsr FindStart
..A     LDD 0,X              ;get event time
        CMPD #$FFFF          ;look for end
        BEQ ..Y
        lda 7,x              ;check extended time
        anda #$f0
        cmpa BLK_END
        bhi ..Y
        blo ..a1
        ldd 0,x
        CMPD BLK_END+1
        BHI ..Y
..a1    LDA 2,X              ;get status byte
        cmpa #$f0
        bhs ..B              ;skip system events
        ANDA #$0F            ;keep channel #
        CMPA L_CHN,S         ;right one?
        BNE ..B
        lda 7,X              ;set new track #
        anda #$f0            ;keep extended time info
        ora L_TRK,S
        sta 7,x
..B     lbsr NextEvnt
        BRA ..A
..X     LBSR SndErr          ;error exit
        CLRA
        CLRB
        BRA ..Z
..Y     lbsr RedisplayPage
        STX S.X,S            ;return ptr to top
..Z     ENDS
;
..aa    FDB 4,5,23,6,..bb,..ee
..bb    FDB 2,2,..cc,$+8
        FDB 2,3,..dd,0
..cc    FCC "EXTRACT CHANNEL #"
        FCB 0
..dd    FCC "TO TRACK #"
        FCB 0
..ee    FDB 19,2,..ff,$+10,0
        FDB 12,3,..gg,0,$-10
..ff    FCC "1 "
        FCB 0
..gg    FCC "1 "
        FCB 0
        ENDPROC

        global Transpos
Transpos PROC
        LOCALVAR L_AMT
        STACKVAR
        LBSR TestBLK
        CMPD #0
        lbeq ..Z
; ask for transpose amount
..D     CALL SetBox,#..aa
        CALL BoxInp,#..aa
		LBSR ClrBox
        CMPB #BREAK
        LBEQ ..Z
        LDX #..dd+1
        CALL atoi
        LDA ..dd
        CMPA #'-'
        BNE ..B
        NEGB
..B     STB L_AMT,S
        clra
        lbsr CopyBuf1Buf3
; now modify memory
        lbsr FindStart
..A     ldd 0,x
        cmpd #$ffff
        beq ..Y
        lda 7,x              ;check extended time
        anda #$f0
        cmpa BLK_END
        bhi ..Y
        blo ..a1
        ldd 0,x
        CMPD BLK_END+1
        BHI ..Y
..a1    LDA 2,X              ;get status byte
        CMPA #$9F            ;is this a note?
        BHI ..C
        LDA L_AMT,S
        ADDA 3,X             ;add transpose amt.
        ANDA #$7F
        STA 3,X
..C     lbsr NextEvnt
        BRA ..A
..Y     lbsr RedisplayPage
		STX S.X,S            ;return ptr to top
..Z     ENDS
;
..aa    FDB 8,5,17,5,$+12,..cc
        FDB 2,2,..bb,0
..bb    FCC "TRANSPOSE"
        FCB 0
..cc    FDB 12,2,..dd,0,0 ;input string
..dd    FCC "+1 "
        FCB 0
        ENDPROC

; find the first event in BUFFER1 with time equal to or greater
; than value given in extended time structure BLK_STRT.
; Returns address of event in register X.
;
FindStart PROC
        LDX #BUF1ADR
        clr BUFFER1_BLOCK
        LBSR CHKFILT
        TSTA
        BEQ ..B
..A     lbsr NextEvnt
..B     LDA 7,X              ;check for right time
        anda #$f0
        cmpa BLK_STRT
        bhi ..Z
        blo ..A
        ldd 0,x
        CMPD BLK_STRT+1
        BLO ..A
..Z     rts
        ENDPROC

        global Clip
Clip PROC
        LOCALVAR L_MAX,L_MIN,L_INT,L_FRA
        STACKVAR
        LBSR TestBLK
        CMPD #0
        lbeq ..Z
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        LBEQ ..Z
        LDX #..ii
        CALL atoi
        STD L_MAX,S
        LDX #..hh
        CALL atoi
        STD L_MIN,S
        LDX #..jj
        LEAY L_INT,S
        STY ARG2
        CALL CnvFrac,REGX,ARG2
        clra
        lbsr CopyBuf1Buf3
; now modify memory
        LEAY L_INT,S
        lbsr FindStart
..A     LDD 0,X
        CMPD #$FFFF          ;look for end of music
        BEQ ..Y
        lda 7,x              ;check extended time
        anda #$f0
        cmpa BLK_END
        bhi ..Y
        blo ..a1
        ldd 0,x
		CMPD BLK_END+1
        BHI ..Y
..a1    LDA 2,X              ;get status byte
        CMPA #$9F            ;is this a note?
        BHI ..D
        LDB 4,X              ;get velocity
        CLRA
        LBSR MultFrac        ;Y points to L_INT
        CMPB L_MIN+1,S       ;check against
        BHS ..B              ;max and min
        LDB L_MIN+1,S
        BRA ..C
..B     CMPB L_MAX+1,S
        BLS ..C
        LDB L_MAX+1,S
..C     STB 4,X
..D     lbsr NextEvnt
        BRA ..A
..Y     lbsr RedisplayPage
        STX S.X,S            ;return ptr to top
        CLRA
        CLRB
..Z     ENDS
;
..aa    FDB 8,3,17,10,..bb,..gg
..bb    FDB 2,2,..cc,$+8
        FDB 3,4,..dd,$+8
        FDB 3,5,..ee,$+8
        FDB 3,7,..ff,0
..cc    FCC "CLIP VELOCITY"
        FCB 0
..dd    FCC "MIN="
        FCB 0
..ee    FCC "MAX="
        FCB 0
..ff    FCC "FACTOR="
        FCB 0
..gg    FDB 7,4,..hh,$+10,0
        FDB 7,5,..ii,$+10,$-10
        FDB 10,7,..jj,0,$-10
..hh    FCC "0  "
        FCB 0
..ii    FCC "127"
        FCB 0
..jj    FCC "1.00"
        FCB 0
        ENDPROC

; remap notes to another pitch
;
        global ReMap
ReMap PROC
        LOCALVAR L_CNT
        CHAR L_NOT,16
        CHAR L_CHN,16
        STACKVAR
;
        LBSR TestBLK
        CMPD #0
        lbeq ..Z
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        LBEQ ..Z
        clra
        lbsr CopyBuf1Buf3
; first initialize L_NOT and L_CHN arrays to -1
        leax L_NOT,s
        leay L_CHN,s
		lda #16
        ldb #-1
..j     stb ,x+
        stb ,y+
        deca
        bne ..j
; convert the notes to binary
        LDA #16
        STA L_CNT,S
        LDX #..ff
        LEAY L_NOT,S
        leau L_CHN,s
..C     LDA ,X      ;check for valid entry (change the pitch)
        CMPA #'A'
        BLO ..H
        CMPA #'G'
        BLS ..F
..H     cmpa #'0'   ;check for valid entry (change the channel)
        blo ..k
        cmpa #'9'
        bhi ..k
        lbsr atoi
        decb
        bmi ..k
        cmpb #15
        bhi ..k
        stb ,u
        bra ..k
..F     LBSR CNVNOTE
..G     STA ,Y
..k     LEAX 4,X
        leay 1,y
        leau 1,u
        DEC L_CNT,S
        BNE ..C
; now look for a note event
        lbsr FindStart
..A     LDD 0,X      ;check for end
        cmpd #$ffff
        beq ..Y
        lda 7,x      ;check extended time
        anda #$f0
        cmpa BLK_END
        bhi ..Y
        blo ..a1
        ldd 0,x
        CMPD BLK_END+1
        BHI ..Y
..a1    LDA 2,X      ;get status byte
        CMPA #$9F    ;is this a note?
        BHI ..B
; look for a match in table
        LDA #8
        STA L_CNT,S
        LEAY L_NOT,S
        leau L_CHN,s
..D     LDA ,Y++
        leau 2,u
        CMPA 3,X     ;check pitch
        BEQ ..E
        DEC L_CNT,S
        BNE ..D
        BRA ..B
..E     ldb -1,y     ;change pitch or channel?
        bmi ..l
        STB 3,X
        bra ..B
..l     tst -1,u
        bmi ..B
        lda 2,x      ;get status byte
		anda #$f0    ;mask off channel
        ora -1,u
        sta 2,x
; move on to next event
..B     lbsr NextEvnt
        BRA ..A
; all done; update display
..Y     lbsr RedisplayPage
        STX S.X,S            ;return ptr to top
        CLRA
        CLRB
..Z     ENDS
;
..aa    FDB 8,1,17,14,..bb,..ee
..bb    FDB 3,2,..cc,$+8
        FDB 7,4,..dd,$+8
        FDB 7,5,..dd,$+8
        FDB 7,6,..dd,$+8
        FDB 7,7,..dd,$+8
        FDB 7,8,..dd,$+8
        FDB 7,9,..dd,$+8
        FDB 7,10,..dd,$+8
        FDB 7,11,..dd,0
..cc    FCC "REMAP NOTES"
        FCB 0
..dd    FCC "-->"
        FCB 0
..ee    FDB 3,4,..ff,$+10,0
        FDB 11,4,..gg,$+10,$-10
        FDB 3,5,..hh,$+10,$-10
        FDB 11,5,..ii,$+10,$-10
        FDB 3,6,..jj,$+10,$-10
        FDB 11,6,..kk,$+10,$-10
        FDB 3,7,..ll,$+10,$-10
        FDB 11,7,..mm,$+10,$-10
		FDB 3,8,..nn,$+10,$-10
        FDB 11,8,..oo,$+10,$-10
        FDB 3,9,..pp,$+10,$-10
        FDB 11,9,..qq,$+10,$-10
        FDB 3,10,..rr,$+10,$-10
        FDB 11,10,..ss,$+10,$-10
        FDB 3,11,..tt,$+10,$-10
        FDB 11,11,..uu,0,$-10
..ff    FCC "C4 "
        FCB 0
..gg    FCC "C4 "
        FCB 0
..hh    FCC "   "
        FCB 0
..ii    FCC "   "
        FCB 0
..jj    FCC "   "
        FCB 0
..kk    FCC "   "
        FCB 0
..ll    FCC "   "
        FCB 0
..mm    FCC "   "
        FCB 0
..nn    FCC "   "
        FCB 0
..oo    FCC "   "
        FCB 0
..pp    FCC "   "
        FCB 0
..qq    FCC "   "
        FCB 0
..rr    FCC "   "
        FCB 0
..ss    FCC "   "
		FCB 0
..tt    FCC "   "
        FCB 0
..uu    FCC "   "
        FCB 0
        ENDPROC

; modify note lengths by given fraction
;
        global NoteFrac
NoteFrac PROC
        LOCALVAR L_INT,L_FRA,L_ACUM,L_MIN,L_MAX
        STACKVAR
        LBSR TestBLK
        CMPD #0
        lbeq ..Z
; get input from user
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        LBEQ ..Z
; convert integers to binary
        call CnvNotLn,#..hh
        std L_MIN,s
        call CnvNotLn,#..ii
        std L_MAX,s
        ldx #..jj
        LEAY L_INT,S
        STY ARG2
        CALL CnvFrac,REGX,ARG2
        clra
        lbsr CopyBuf1Buf3
; find start of marked block
        lbsr FindStart
; start of loop
..A     LDD 0,X
        CMPD #$FFFF          ;look for end
        BEQ ..Y
        lda 7,x              ;check extended time
        anda #$f0
        cmpa BLK_END
        bhi ..Y
        blo ..a1
        ldd 0,x
        CMPD BLK_END+1
        BHI ..Y
..a1    LDA 2,X              ;get status byte
        CMPA #$9F            ;is this a note?
        BHI ..C
        LDD 5,X              ;get note length
        LEAY L_INT,S
        LBSR MultFrac
        cmpd L_MIN,s
        bhs ..minOK
        ldd L_MIN,s
..minOK cmpd L_MAX,s
        bls ..maxOK
        ldd L_MAX,s
; update note length and loop back for next
..maxOK STD 5,X
..C     lbsr NextEvnt
        BRA ..A
; all done, update display
..Y     lbsr RedisplayPage
        STX S.X,S            ;return ptr to top
        CLRA
        CLRB
..Z     ENDS
;
..aa    FDB 8,3,18,10,..bb,..gg
..bb    FDB 3,2,..cc,$+8
        FDB 3,4,..dd,$+8
        FDB 3,5,..ee,$+8
        FDB 3,7,..ff,0
..cc    FCC "NOTE LENGTHS"
        FCB 0
..dd    FCC "MIN="
        FCB 0
..ee    FCC "MAX="
        FCB 0
..ff    FCC "FACTOR="
        FCB 0
..gg    FDB 7,4,..hh,$+10,0
        FDB 7,5,..ii,$+10,$-10
        FDB 10,7,..jj,0,$-10
..hh    FCC "0:0  "
        FCB 0
..ii    FCC "1:0  "
        FCB 0
..jj    FCC "1.00"
        FCB 0
        ENDPROC

; clear the block pointers
;
        global ClrBlock
ClrBlock LDD #$FFFF
        STD BLK_STRT
        sta BLK_STRT+2
        STD BLK_END
        sta BLK_END+2
        RTS

; Return with register X pointing to last event in BUFFER1
; BUFFER1_BLOCK set correctly
; If an invalid event is found, it is changed to an end event.
;
        global FindEndBuffer1
FindEndBuffer1 proc
        ldx #BUF1ADR
        clr BUFFER1_BLOCK
..a     ldd ,x
        cmpd #$ffff
        beq ..c
;        tst 2,x              ;make sure this is a valid event
;        bmi ..b
;        ldd #$ffff
;        std ,x
;        bra ..c
..b     leax EVNSIZE,x
        cmpx #BUF1ADR+$2000
        blo ..a
        ldx #BUF1ADR
        inc BUFFER1_BLOCK
        bra ..a
..c     rts
        endproc

; Return with register X pointing to last event in BUFFER2
; BUFFER2_BLOCK set correctly
;
FindEndBuffer2 proc
        ldx #BUF2ADR
        clr BUFFER2_BLOCK
..a     ldd ,x
        cmpd #$ffff
        beq ..b
        leax EVNSIZE,x
        cmpx #BUF2ADR+$2000
		blo ..a
        ldx #BUF2ADR
        inc BUFFER2_BLOCK
        bra ..a
..b     rts
        endproc

; Given FROM (X) and TO (U) pointers, copy an event.
; Updates (advances by EVNSIZE) the extended addresses.
; If "from" is pointing to an event that is filtered out,
;   then that pointer is updated but no copying is done.
;   This effectively deletes all filtered out events.
;
CopyEvent proc
        lbsr CHKFILT
        tsta
        beq ..ok
        leax EVNSIZE,x
        bra ..adjust
;copy event
..ok    ldb #EVNSIZE
..a     lda ,x+
        sta ,u+
        decb
        bne ..a
;now adjust the pointers for page over-run
..adjust cmpx #BUF3ADR+$2000  ;check register X
        blo ..b
        ldx #BUF3ADR
        inc BUFFER3_BLOCK
        bra ..c
..b     cmpx #BUF3ADR
        bhi ..c
        cmpx #BUF2ADR+$2000  ;since X may be pointing to either buffer 2 or 3
        blo ..c              ;we have to check addresses for both
		ldx #BUF2ADR
        inc BUFFER2_BLOCK
..c     cmpu #BUF1ADR+$2000  ;check register U
        blo ..done
        ldu #BUF1ADR
        inc BUFFER1_BLOCK
..done  rts
        endproc

; copy all events from buffer1 to buffer3
; if register A is nonzero, then do the reverse
;
        global CopyBuf1Buf3
CopyBuf1Buf3 proc
        pshs a,x,y
        ldd BUFFER1_BLOCK
        pshs d
        clr BUFFER1_BLOCK
        lda #$20
        sta BUFFER2_BLOCK
        ldx #BUF1ADR
        ldy #BUF2ADR
        tst 2,s
        beq ..loop
        exg x,y
..loop  ldd ,x++             ;check for end
        std ,y++
        cmpd #$ffff
        beq ..done
        ldb #EVNSIZE-2
..copy  lda ,x+              ;copy an event
        sta ,y+
        decb
        bne ..copy
        tst 2,s
		beq ..chk0
        cmpx #BUF2ADR+$2000  ;check pointers for page over-run
        blo ..chk1
        ldx #BUF2ADR
        inc BUFFER2_BLOCK
..chk1  cmpy #BUF1ADR+$2000
        blo ..loop
        ldy #BUF1ADR
        inc BUFFER1_BLOCK
        bra ..loop
..chk0  cmpx #BUF1ADR+$2000  ;check pointers for page over-run
        blo ..chky
        ldx #BUF1ADR
        inc BUFFER1_BLOCK
..chky  cmpy #BUF2ADR+$2000
        blo ..loop
        ldy #BUF2ADR
        inc BUFFER2_BLOCK
        bra ..loop
..done  puls d
        std BUFFER1_BLOCK
        puls a,x,y,pc
        endproc

; merge the two buffers into BUFFER1
; returns with register X pointing to last event in buffer1
;
        global MergeBuffers
MergeBuffers PROC
        localvar l_filt,l_cc
        STACKVAR
;
        tfr cc,a
        sta l_cc,s
        orcc #$50            ;disable interrupts
		lda TRAK_FLG
        ldb FILT_FLG
        std l_filt,s
        lda #1
        sta TRAK_FLG
        clr FILT_FLG
        clra
        lbsr CopyBuf1Buf3
;set X to point to buffer3, Y to point to buffer2, and U to buffer1
        ldx #BUF3ADR
        ldy #BUF2ADR
        ldu #BUF1ADR
        lda #$20
        sta BUFFER3_BLOCK
        lda #$10
        sta BUFFER2_BLOCK
        clr BUFFER1_BLOCK
;decide whether an event from buffer3 or from buffer2 should be copied
..loop  com WORKING_ALERT_POSITION
        ldd #$ffff           ;first check for end of each buffer
        cmpd ,x
        bne ..not3
        cmpd ,y
        beq ..end
        bra ..copy2
..not3  cmpd ,y
        bne ..not2
        bra ..copy3
..not2  lda 7,y              ;not at end of either buffer
        anda #$f0            ;check extended time bytes
        pshs a
        lda 7,x
        anda #$f0
        cmpa ,s+
        bhi ..copy2
		blo ..copy3
        ldd ,x
        cmpd ,y
        bhs ..copy2
..copy3 inc FILT_FLG         ;filter operative only for BUFFER2!
        lbsr CopyEvent
        bra ..chk
..copy2 exg x,y
        lbsr CopyEvent
        exg x,y
..chk   clr FILT_FLG
        lda BUFFER1_BLOCK
        cmpa #$20
        blo ..loop
..error lbsr SndErr
        lbsr ClrBox
        call SetBox,#..aa
        lbsr getchar
        lbsr ClrBox
        lda #$1f
        sta BUFFER1_BLOCK
        ldx #BUF1ADR+$2000-EVNSIZE
;write a ending event
..end   ldd #$ffff
        std ,u
        ldd l_filt,s
        sta TRAK_FLG
        stb FILT_FLG
        lda #$3e
        sta BUFFER3_BLOCK
        lda l_cc,s
        tfr a,cc
        clra
        clrb
        ENDS
..aa    fdb 3,5,25,5,$+12,0
        fdb 2,2,$+8,0
        fcc "EDIT BUFFER TOO FULL!"
        fcb 0
        ENDPROC

; Compare current event extended time (pointed to by register X)
; with extended time structure pointed to by S_PTR.
; Returns 0 if equal, 1 if greater than, and -1 if less than.
;
        global CompareExTimes
CompareExTimes proc
        stackvar s_ptr
        ldy s_ptr,s
        lda 7,x
        anda #$f0
        cmpa 0,y
        bhi ..gr
        blo ..less
        ldd 0,x
        cmpd 1,y
        bhi ..gr
        blo ..less
..equ   ldd #0
        bra ..end
..gr    ldd #1
        bra ..end
..less  ldd #-1
..end   ends
        endproc

; change events to note off events ($8X) in a block
; used for punching in/out
;
        global MakeNoteOff
MakeNoteOff proc
        localvar l_b1b
        stackvar
        lda BUFFER1_BLOCK
        sta l_b1b,s
        lbsr TestBLK
        cmpd #0
        lbeq ..done
        lbsr FindStart
..loop  ldd 0,x              ;get event time
        cmpd #$ffff          ;look for end of music
        beq ..done
        call CompareExTimes,#BLK_END
        cmpd #1
        beq ..done
        lda 7,x              ;get track byte
        anda #$0f
        cmpa TRACK
        bne ..next
        lda #$80
        sta 2,x              ;replace status byte
..next  lbsr NextEvnt
        bra ..loop
..done  lda l_b1b,s
        sta BUFFER1_BLOCK
        ends
        endproc

; Remove note with lengths less than given time
;
        global BlockCull
BlockCull PROC
        localvar l_len
        stackvar
        LBSR TestBLK
        CMPD #0
        LBEQ ..Z
; ask for event length to cull
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        LBSR ClrBox
        CMPB #BREAK
        LBEQ ..Z
        clra
        lbsr CopyBuf1Buf3
        LDX #..ff
        CALL atoi
        std l_len,s
; start deleting short notes
        lbsr FindStart
        leay BUF2ADR-BUF1ADR,x
        lda BUFFER1_BLOCK
        sta BUFFER2_BLOCK
..loop  ldd 0,x
        cmpd #$ffff
        beq ..end
        lda 7,x              ;check extended memory
        anda #$f0
        cmpa BLK_END
        bhi ..copy
        blo ..check
        ldd 0,x
        cmpd BLK_END+1
        bhi ..copy
..check lbsr CHKFILT
        tsta
        bne ..copy
        lda 2,x              ;make sure this is a note of the right length
        cmpa #$9f
        bhi ..copy
        ldd 5,x
        cmpd l_len,s
        bhi ..copy
        lbsr NextAbsEvent
        bra ..loop
..copy  LDB #EVNSIZE
..d     LDA ,X+
        STA ,Y+
        DECB
        BNE ..d
        cmpx #BUF1ADR+$2000
        blo ..e
        ldx #BUF1ADR
        inc BUFFER1_BLOCK
..e     cmpy #BUF2ADR+$2000
        blo ..loop
        ldy #BUF2ADR
        inc BUFFER2_BLOCK
        bra ..loop
..end   ldd #$ffff
        std ,y
        lbsr RedisplayPage
        STX S.X,S            ;return ptr to top
..Z     ENDS
;
..aa    FDB 7,5,18,6,..bb,..ee
..bb    FDB 2,2,..cc,$+8
        fdb 2,3,..dd,0
..cc    FCC "CUT NOTES LESS"
        fcb 0
..dd    fcc "THAN     TICKS"
        FCB 0
..ee    FDB 7,3,..ff,0,0
..ff    FCC "10 "
        FCB 0
        ENDPROC

        end

; end of file: BLOCK/TXT
