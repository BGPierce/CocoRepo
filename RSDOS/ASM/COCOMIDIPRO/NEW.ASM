; new.asm

%include "macros.h"
%include "cmp.h"

        extern CHROUT,PUTS,FILENAME,CLRBOX,GETCHAR,PBINDEC
        extern MOVE,XPOS,YPOS,SETBOX,BLK_END,BLK_STRT,ARG1
        extern PREVABSEVENT,NEXTABSEVENT,BINDEC,TOTAL_EVENTS
        extern BOXBUFR,SAVEBOX,CLS,PrintTime,EX_TIME1,BoxInp,StrPad
        extern ANNOTATION,TRACK,TINVERT,MOVE

        global MapDataIn,MapDataOut
MapDataIn proc
        pshs d
        lda DATA_BLOCK
        sta ..save
        lda #$37
        sta DATA_BLOCK
        puls d,pc
..save  fcb -1
MapDataOut
        pshs d
        lda ..save
        cmpa #-1
        beq ..z
        sta DATA_BLOCK
        lda #-1
        sta ..save
..z     puls d,pc
        endproc

        global SetAnnotation
SetAnnotation proc
        pshs x
        ldx #..bb+4
        ldb #12
        pshs b
        ldd ANNOTATION
..loop  std ,x
        leax 10,x
        addd #29
        dec 0,s
        bne ..loop
        puls b
        lbsr MapDataIn
        CALL SetBox,#..aa
        CALL BoxInp,#..aa
        lbsr MapDataOut
        LBSR ClrBox
        clra
        clrb
        puls x,pc
;
..aa    fdb 0,0,32,16,$+12,..bb
        fdb 1,0,$+8,0
        fcc " ANNOTATION "
        fcb 0
..bb    fdb 2,2,0,$+10,0
        fdb 2,3,0,$+10,$-10
        fdb 2,4,0,$+10,$-10
        fdb 2,5,0,$+10,$-10
        fdb 2,6,0,$+10,$-10
        fdb 2,7,0,$+10,$-10
        fdb 2,8,0,$+10,$-10
        fdb 2,9,0,$+10,$-10
        fdb 2,10,0,$+10,$-10
        fdb 2,11,0,$+10,$-10
        fdb 2,12,0,$+10,$-10
        fdb 2,13,0,0,$-10
        endproc

        global SavePosition,RestorePosition
SavePosition proc
;        pshs x
;        stx ..x
;        lda BUFFER1_BLOCK
;        sta ..blk
;        lda XPOS
;        ldb YPOS
;        std ..POS
;        puls x,pc
;
RestorePosition
;        lda ..blk
;        cmpa #-1
;        beq ..z
;        sta BUFFER1_BLOCK
;        ldx ..x
;        ldd ..POS
;        sta XPOS
;        stb YPOS
;        lbsr MOVE
;        lda #-1
;        sta ..blk
..z     rts
;
;..x     fdb 0
;..blk   fcb -1
;..POS   fdb 0
        endproc

        global FileInfo
FileInfo proc
        localvar l_x,l_trk,l_xpos
        char l_tracks,48
        stackvar
;        lbsr SavePosition
;save screen and clear it
        clr XPOS
        clr YPOS
        lbsr Move
        CALL SaveBox,#32,#16,BOXBUFR
        lbsr Cls
;print filename
        lda #1
        sta XPOS
        sta YPOS
        lbsr Move
        ldx #..bb
        lbsr puts
        ldx #FILENAME
        lbsr puts
;set up number of events
        lda #1
        sta XPOS
        inc YPOS
        lbsr Move
        ldx #..cc
        lbsr puts
        ldd TOTAL_EVENTS
        ldx #..dd
        lbsr pBinDec
;set up length (time)
        lda #1
        sta XPOS
        inc YPOS
        lbsr Move
        ldx #..ee
        lbsr puts
        ldx #BUF1ADR
        clr BUFFER1_BLOCK
        ldd #$ffff
..a     cmpd ,x
        beq ..b
        lbsr NextAbsEvent
        bra ..a
..b     cmpx #BUF1ADR
        bhi ..b00
        tst BUFFER1_BLOCK
        beq ..b0
..b00   lbsr PrevAbsEvent
        lda 7,x
        anda #$f0
        sta EX_TIME1
        ldd 0,x
        std EX_TIME1+1
        clra
        call PrintTime,#EX_TIME1
;set up blocks
..b0    lda #1
        sta XPOS
        inc YPOS
        lbsr Move
        ldx #..gg
        lbsr puts
        ldd #$ffff
        cmpd BLK_STRT+1
        beq ..b1
        ldd BLK_STRT
        std EX_TIME1
        lda BLK_STRT+2
        std EX_TIME1+2
        clra
        call PrintTime,#EX_TIME1
..b1    ldd #$ffff
        cmpd BLK_END+1
        beq ..b2
        lda #19
        sta XPOS
        lbsr Move
        ldd BLK_END
        std EX_TIME1
        lda BLK_END+2
        std EX_TIME1+2
        clra
        call PrintTime,#EX_TIME1
;set up track channels
..b2    leax l_tracks,s
        ldb #48
..b3    clr ,x+              ;clear the array first
        decb
        bne ..b3
        ldx #BUF1ADR
        clr BUFFER1_BLOCK
..c     ldd ,x
        cmpd #$ffff
        beq ..e
        stx l_x,s            ;save register X
        ldb 7,x              ;get track
        andb #$0f
        lda #3
        mul
        leay l_tracks,s      ;point Y to track array
        leay b,y
        ldb 2,x              ;check for a system event
        cmpb #$f0
        blo ..c1
        lda #1
        ora 2,y
        sta 2,y
        bra ..d
..c1    andb #$0f
        lslb
        ldx #BIT_CHANNELS    ;point X to lookup table
        ldd b,x
        ora ,y               ;update track array
        sta ,y
        orb 1,y
        stb 1,y
        ldx l_x,s            ;restore register X
..d     lbsr NextAbsEvent
        bra ..c
;now print the track channels
..e     lda #1
        sta XPOS
        inc YPOS
        inc YPOS
        lbsr Move
        ldx #..jj
        lbsr puts
        clra
        clrb
        std l_trk,s
        lda #7
        sta YPOS
        lda #2
        sta l_xpos,s
        leay l_tracks,s
..f     lda l_xpos,s
        sta XPOS
        lbsr Move
        lda TRACK
        cmpa l_trk+1,s
        bne ..f1
        lda #1
        sta TINVERT
..f1    ldd l_trk,s
        incb
        lbsr pBINDEC
        clr TINVERT
        lda l_xpos,s
        adda #3
        sta XPOS
        lbsr Move
        ldb l_trk+1,s
        lda #3
        mul
        leay l_tracks,s
        leay d,y
        lbsr PrintTrackChannels
        inc l_trk+1,s
        ldb l_trk+1,s
        cmpb #8
        bne ..g
        lda #16
        sta l_xpos,s
        lda #6
        sta YPOS
..g     inc YPOS
        cmpb #16
        bne ..f
..end   lbsr getchar
        LBSR ClrBox
;        lbsr RestorePosition
        CLRA
        CLRB
..Z     ENDS
;
..bb    FCC "FILE NAME: "
        FCB 0
..cc    fcc "TOTAL EVENTS: "
        FCB 0
..dd    fcc "0    "
        fcb 0
..ee    fcc "LENGTH: "
        fcb 0
..gg    fcc "BLOCK: "
        fcb 0
..jj    fcc "TRK CHANNELS  TRK CHANNELS"
        fcb 0
        endproc

BIT_CHANNELS
        fdb 1,2,4,8,$10,$20,$40,$80
        fdb $100,$200,$400,$800,$1000,$2000,$4000,$8000

; Enter with register Y pointing to 3 byte number
; (each bit represents a channel)
;
PrintTrackChannels proc
        localvar l_d,l_chan,l_xpos
        stackvar
        ldd 0,y
        std l_d,s
        lda XPOS
        adda #8
        sta l_xpos,s
        lda #-1
        sta l_chan,s
        tst 2,y
        beq ..a
        lda #'S'
        lbsr ChrOut
        lda #' '
        lbsr ChrOut
..a     lda XPOS
        cmpa l_xpos,s
        bhs ..x
        inc l_chan,s
        ldb l_chan,s
        cmpb #16
        beq ..z
        lsr l_d,s
        ror l_d+1,s
        bcc ..a
        clra
        incb
        lbsr pBINDEC
        lda #' '
        lbsr ChrOut
        bra ..a
..x     deca
        sta XPOS
        lbsr Move
        lda #'+'
        lbsr ChrOut
..z     ends
        endproc

        end

; end of file: NEW.ASM
