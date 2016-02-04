; BOX.asm - part of CMP
; (C) 1988 by Lester Hands

; Box structure: (all 16-bit words)
;   X,Y - upper left hand position
;   Width,Height
;   TextPointer
;   InputPointer

; Text structure: (all 16-bit words)
;   X,Y - position relative to box upper left hand
;   TxtPtr - pointer to null terminated string
;   NxtPtr - pointer to next Text structure

; Input structure (all 16-bit words)
;   X,Y - position relative to box upper left hand
;   InpPtr - pointer to null terminated strng that
;            will accept input
;   NxtPtr - pointer to next Input structure
;   PrvPtr - pointer to previous Input structure

%include "macros.h"
%include "cmp.h"

        EXTERN ARG1,ARG2,CHROUT,GETPOS,GETSTR,MOVE,STRLEN,STRPAD
        EXTERN XPOS,YPOS,TINVERT,puts

        global BOXBUFR
BOXBUFR fdb BUF1ADR ;box buffer (512 bytes)

        global ACOLOR
ACOLOR  FCB $60
        global BCOLOR
BCOLOR  FCB $60

; Display a dialog box on the text screen
;
        LOCALVAR L_CURS
        global SetBox
SetBox PROC
        STACKVAR S_BPTR
        LDD >CURSADR
        STD L_CURS,S
        LDX S_BPTR,S
        LDD 0,X              ;get X position
        STB XPOS
        LDD 2,X              ;get Y position
        STB YPOS
        LBSR MOVE
        CALL SaveBox,<4,X>,<6,X>,BOXBUFR
        CALL ClearBox,<4,X>,<6,X>
        CALL BoxBordr,<4,X>,<6,X>
        CALL BText,<8,X>
        CALL BText,<10,X>
        LDD L_CURS,S
        STD >CURSADR
        LBSR GETPOS
        ENDS
        ENDPROC

%if 1 eq 0
; Display a menu box on the text screen
;
        LOCALVAR L_CURS
        global SetMenu
SetMenu PROC
        STACKVAR S_BPTR
        LDD >CURSADR
        STD L_CURS,S
        LDX S_BPTR,S
        LDD 0,X ;get X position
        STB XPOS
        LDD 2,X ;get Y position
        STB YPOS
        LBSR MOVE
        CALL SaveBox,<4,X>,<6,X>,BOXBUFR
        CALL ClearBox,<4,X>,<6,X>
        CALL MenuBord,<4,X>,<6,X>
        CALL BText,<8,X>
        CALL BText,<10,X>
        LDD L_CURS,S
        STD >CURSADR
        LBSR GETPOS
        ENDS
        ENDPROC
%endif

; Restore the screen after a box display.
; Unlike most routines, this one preserves D.
; This is done so input from getchar or BoxInp
; is preserved.
;
        global ClrBox
ClrBox  PSHS D
        CALL RestBox,BOXBUFR
        PULS D,PC

; display box text
; the cursor is positioned at the upper left corner
; S_PTR is the address of a text or input structure
;
        LOCALVAR L_CURS
        global BText
BText PROC
        STACKVAR S_PTR
        LDD >CURSADR
        STD L_CURS,S
        LDX S_PTR,S
        BEQ ..Z
..A     LDD L_CURS,S
        STD >CURSADR
        ldd 2,x              ;if Y=0 then this is a title
        bne ..A1
        lda #1
        sta TINVERT
..A1    CALL TRMove,<0,X>,<2,X>
        pshs x
        LDX 4,X              ;get TxtPtr
        lbsr puts
        clr TINVERT
        puls x
        LDX 6,X              ;get NxtPtr
        BNE ..A
        LDD L_CURS,S
        STD >CURSADR
..Z     clr TINVERT
        ENDS
        ENDPROC

; Text screen cursor relative move
;
        global TRMove
TRMove PROC
        STACKVAR S_X,S_Y
        LDD S_Y,S
        LDA #SCRNWIDE
        MUL
        ADDD S_X,S
        ADDD >CURSADR
        STD >CURSADR
        ENDS
        ENDPROC

; Save a rectangular area of the text screen
; Cursor is positioned at upper left hand corner
; SaveBox(wide,high,bufr)
;
        global SaveBox
SaveBox PROC
        LOCALVAR L_XCNT,L_YCNT,L_CURS,l_b1b
        STACKVAR S_WIDE,S_HIGH,S_BUFR
        lda BUFFER1_BLOCK
        sta l_b1b,s
        lda #$37
        sta BUFFER1_BLOCK
        LDD >CURSADR
        STD L_CURS,S
        LDY S_BUFR,S
        STD ,Y++
        LDD S_WIDE,S
        STD ,Y++
        LDD S_HIGH,S
        STD ,Y++
        STB L_YCNT,S
..A     LDX >CURSADR
        LDD S_WIDE,S
        STB L_XCNT,S
..B     LDA ,X+
        STA ,Y+
        DEC L_XCNT,S
        BNE ..B
        CALL TRMove,#0,#1
        DEC L_YCNT,S
        BNE ..A
..Z     LDD L_CURS,S
        STD >CURSADR
        lda l_b1b,s
        sta BUFFER1_BLOCK
        ENDS
        ENDPROC

; Restore text screen from buffer
; RestBox(bufr)
;
        global RestBox
RestBox PROC
        LOCALVAR L_WIDE,L_HIGH,L_Y,L_CURS,l_b1b
        STACKVAR S_BUFR
        lda BUFFER1_BLOCK
        sta l_b1b,s
        lda #$37
        sta BUFFER1_BLOCK
        LDD >CURSADR
        STD L_CURS,S
        LDX S_BUFR,S
        LDD ,X
        BEQ ..Z
        STD >CURSADR
        CLRA
        CLRB
        STD ,X++
        LDD ,X++
        STB L_WIDE,S
        LDD ,X++
        STB L_HIGH,S
..A     LDB L_WIDE,S
        LDY >CURSADR
..B     LDA ,X+
        STA ,Y+
        DECB
        BNE ..B
        PSHS X
        CALL TRMove,#0,#1
        PULS X
        DEC L_HIGH,S
        BNE ..A
..Z     LDD L_CURS,S
        STD >CURSADR
        lda l_b1b,s
        sta BUFFER1_BLOCK
        ENDS
        ENDPROC

; Clear a rectangular area of text
; Cursor is positioned at upper left corner
; ClearBox(wide,high)
;
        LOCALVAR L_XCNT,L_YCNT,L_CURS
        global ClearBox
ClearBox PROC
        STACKVAR S_WIDE,S_HIGH
        LDD >CURSADR
        STD L_CURS,S
        LDD S_HIGH,S
        DECB
        STB L_YCNT,S
..A     LDX >CURSADR
        LDD S_WIDE,S
        STB L_XCNT,S
..B     LDA BCOLOR
        STA ,X+
        DEC L_XCNT,S
        BNE ..B
        CALL TRMove,#0,#1
        DEC L_YCNT,S
        BNE ..A
..Z     LDD L_CURS,S
        STD >CURSADR
        ENDS
        ENDPROC

; put a border on a box
; cursor at upper left corner
;
        LOCALVAR L_CURS,L_HIGH
        global BoxBordr
BoxBordr PROC
        STACKVAR S_WIDE,S_HIGH
        LDD >CURSADR
        STD L_CURS,S
; top line
        LDX >CURSADR
        LDD S_WIDE,S
        LDA #$8E
        STA ,X+
        DECB
        LDA #$8C
..A     STA ,X+
        DECB
        BNE ..A
        LDA #$8D
        STA -1,X
; sides
        LDD S_HIGH,S
        SUBB #2
        STB L_HIGH,S
..B     PSHS B
        CALL TRMove,#0,#1
        PULS B
        LDX >CURSADR
        LDD S_WIDE,S
        DECB
        LDA #$8A
        STA ,X
        LDA #$85
        STA B,X
        DEC L_HIGH,S
        BNE ..B
; bottom
        CALL TRMove,#0,#1
        LDX >CURSADR
        LDD S_WIDE,S
        LDA #$8B
        STA ,X+
        DECB
        LDA #$83
..C     STA ,X+
        DECB
        BNE ..C
        LDA #$87
        STA -1,X
        LDD L_CURS,S
        STD >CURSADR
        ENDS
        ENDPROC

%if 1 eq 0
; put a border on a menu box
; cursor at upper left corner
;
        LOCALVAR L_CURS,L_HIGH
        global MenuBord
MenuBord PROC
        STACKVAR S_WIDE,S_HIGH
        LDD >CURSADR
        STD L_CURS,S
; sides
        LDD S_HIGH,S
        SUBB #1
        STB L_HIGH,S
..B     LDX >CURSADR
        LDD S_WIDE,S
        DECB
        LDA #$85
        STA ,X
        LDA #$8A
        STA B,X
        CALL TRMove,#0,#1
        DEC L_HIGH,S
        BNE ..B
; bottom
        LDX >CURSADR
        LDD S_WIDE,S
        LDA #$84
        STA ,X+
        DECB
        LDA #$8C
..C     STA ,X+
        DECB
        BNE ..C
        LDA #CURSADR
        STA -1,X
        LDD L_CURS,S
        STD >CURSADR
        ENDS
        ENDPROC
%endif

; get input for a box structure
; returns the last keypress
;
        LOCALVAR L_CURS,L_X,L_Y,L_KEY,L_LEN
        global BoxInp
BoxInp PROC
        STACKVAR S_PTR
        LDD >CURSADR
        STD L_CURS,S
        LDX S_PTR,S
        LDD 0,X              ;get box XPOS
        STD L_X,S
        LDD 2,X              ;get box YPOS
        STD L_Y,S
        LDX 10,X             ;get input ptr.
..A     LDD 0,X
        ADDD L_X,S
        STB XPOS
        LDD 2,X
        ADDD L_Y,S
        STB YPOS
        LBSR MOVE
        CALL StrLen,<4,X>
        STD ARG2
        STD L_LEN,S
        CALL GetStr,<4,X>,ARG2
        STD L_KEY,S
        LDD L_LEN,S
        STD ARG1
        CALL StrPad,<4,X>,ARG1
        LDD L_KEY,S
        CMPB #BREAK
        BEQ ..Z
        CMPB #UP
        BNE ..B
        LDD 8,X
        CMPD #0
        BEQ ..A
        TFR D,X
        BRA ..A
..B     CMPB #DOWN
        BNE ..C
        LDD 6,X
        CMPD #0
        BEQ ..A
        TFR D,X
        BRA ..A
..C     CMPB #13
        BNE ..A
..Z     LDD L_CURS,S
        STD >CURSADR
        LBSR GETPOS
        LDD L_KEY,S
        ENDS
        ENDPROC

        end

; end of file: BOX.asm
