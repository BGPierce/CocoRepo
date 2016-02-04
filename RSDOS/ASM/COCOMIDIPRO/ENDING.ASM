; ENDING.ASM
; (C) 1990 by Lester Hands

%include "cmp.h"

        extern Cls,puts,getchar,STARTUP,MSTAT,MDATA
        extern CPCalc,MASTER_CPERIOD,CPERIOD,CPCOUNT,Reset,Error
        extern NEWIRQ,FIRQmast,ToggleTapeIO,LoadCnfg,STARTMEM
        extern MapDataIn,MapDataOut,ClearCMA

;        defseg INIT_SEG,start=0700h
;        seg INIT_SEG

        global InitialSetup
InitialSetup proc
        pshs cc
        orcc #$50       ;disable interrupts
%if 1 eq 0
        LDD $FFFE       ;check for a CoCo 3
        CMPD #$8C1B
        beq ..b
        ldx #..msg
..a     lbsr Cls
        lbsr puts
        lbsr getchar
        jmp [$fffe]
..msg   fcb 13,13
        fcc "THIS PROGRAM REQUIRES A COCO 3!"
        fcb 0
..msg2  fcb 13,13
        fcc "THIS PROGRAM REQUIRES 512K!"
        fcb 0
; check for 512K memory
..b     clr BUFFER1_BLOCK
        lda #16
        sta BUFFER2_BLOCK
        ldx BUF1ADR
        ldd #$5eaf
        std BUF1ADR
        ldd BUF2ADR
        stx BUF1ADR
        ldx #..msg2
        cmpd #$5eaf
        beq ..a
%endif
; check for Colorchestra MIDI interface
        LDX #$FF66
        lda #3               ;reset interface
        sta ,x
        tst ,x
        BNE ..c
        STX MSTAT
        LEAX 1,X
        STX MDATA
; set up misc variables
..c     ldd #100
        lbsr CPCalc
        std MASTER_CPERIOD
        std CPERIOD
        std CPCOUNT
; set new vectors
        CLR $987        ;disable verify
        ldd #Reset      ;enable reset
        std $72
        LDD #Error      ;set new error vector
        STD $0192
        std $018f       ;set alternate error vector
        lda #$7e        ;JMP opcode
        sta IRQ_VECTOR
        sta FIRQ_VECTOR
        LDX #NEWIRQ     ;set new IRQ vector
        STX IRQ_VECTOR+1
        LDX #FIRQmast   ;set new FIRQ vector
        STX FIRQ_VECTOR+1
;check for disk ROM
        ldd $c000
        cmpd #'DK'
        beq ..d
        lbsr ToggleTapeIO
        bra ..e
..d     LBSR LoadCnfg
; clear buffers only if STARTMEM is not initialized
..e     lbsr MapDataIn
        ldd #$5af3
        cmpd [STARTMEM]
        pshs cc
        std [STARTMEM]
        lbsr MapDataOut
        puls cc
        beq ..done
        clr DATA_BLOCK
        LDD #$FFFF      ;clear buffer1
        STD DAT_ADR
        lda #$10
        sta DATA_BLOCK
        ldd #$ffff
        std DAT_ADR
        lda #$20
        sta DATA_BLOCK
        ldd #$ffff
        std DAT_ADR
        lbsr ClearCMA
..done  puls cc,pc
        endproc

        end

; end of file: ENDING.ASM
