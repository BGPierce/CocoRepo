; BR.asm
; Implementation of Bresenham's algorithm
; (line drawing algorithm)
;  for scaling MIDI values
; (C) 1988 by Lester Hands

%include "macros.h"
%include "cmp.h"

; The Bresenham algorithm is used to scale a value
; To start, 4 values are passed to BR_Setup (the
; start and end points of a line). Then the desired
; X value which is between the two previously declared
; points is passed to BR_Scale. The scaled value,
; which is the equivalent of the corresponding Y
; value, is returned in register D.

BR_DX    FDB 0
BR_DY    FDB 0
BR_IX    FDB 0
BR_IY    FDB 0
BR_INC   FDB 0
BR_PLOTX FDB 0
BR_PLOTY FDB 0
BR_I     FDB 0
BR_X     FDB 0
BR_Y     FDB 0

; set up variables for the Bresenham algorithm
;
        global BR_Setup
BR_Setup PROC
        STACKVAR S_X1,S_X2,S_Y1,S_Y2
; calculate DX,DY,IX,IY,INC
        LDD S_X2,S
        SUBD S_X1,S
        STD BR_DX
        TSTA
        BPL ..B
        COMA
        COMB
        ADDD #1
..B     STD BR_IX
        LDD S_Y2,S
        SUBD S_Y1,S
        STD BR_DY
        TSTA
        BPL ..C
        COMA
        COMB
        ADDD #1
..C     STD BR_IY
        CMPD BR_IX
        BGT ..A
        LDD BR_IX
..A     STD BR_INC
; set up PLOTX,PLOTY,X,Y,I
        LDD S_X1,S
        STD BR_PLOTX
        LDD S_Y1,S
        STD BR_PLOTY
        CLRA
        CLRB
        STD BR_X
        STD BR_Y
        STD BR_I
        ENDS
        ENDPROC

; scale an X value
; or, do BR_Iter until PLOTX value is reached
; return PLOTY value
;
        global BR_Scale
BR_Scale PROC
        STACKVAR S_X
..A     LDD BR_PLOTX
        CMPD S_X,S
        bhs ..Z
        LDD BR_I
        CMPD BR_INC
        BGT ..Z
        BSR BR_Iter
        BRA ..A
..Z     LDD BR_PLOTY
        ENDS
        ENDPROC

; do one iteration of the Bresenham algorithm
;
        global BR_Iter
BR_Iter PROC
        LOCALVAR L_PLOT
        STACKVAR
; do while i is less than inc
..G     LDD BR_I
        CMPD BR_INC
        bhi ..Z
; increment x using ix
        LDD BR_X
        ADDD BR_IX
        STD BR_X
; increment y using iy
        LDD BR_Y
        ADDD BR_IY
        STD BR_Y
; plot is false
        LDA #FALSE
        STA L_PLOT,S
; if x is greater than inc
        LDD BR_X
        CMPD BR_INC
        BLE ..C
;    plot is true
        LDA #TRUE
        STA L_PLOT,S
;    decrement x using inc
        LDD BR_X
        SUBD BR_INC
        STD BR_X
;    if dx is positive, increment plotx
        LDD BR_PLOTX
        TST BR_DX
        BMI ..A
        ADDD #1
        BRA ..B
;    if dx is negative, decrement plotx
..A     SUBD #1
..B     STD BR_PLOTX
; if y is greater than inc
..C     LDD BR_Y
        CMPD BR_INC
        BLE ..F
;    plot is true
        LDA #TRUE
        STA L_PLOT,S
;    decrement y using inc
        LDD BR_Y
        SUBD BR_INC
        STD BR_Y
;    if dy is positive, increment ploty
        LDD BR_PLOTY
        TST BR_DY
        BMI ..D
        ADDD #1
        BRA ..E
;    if dy is negative, decrement ploty
..D     SUBD #1
..E     STD BR_PLOTY
; increment i
..F     LDD BR_I
        ADDD #1
        STD BR_I
; if plot is true, plot point (done)
        LDA L_PLOT,S
        CMPA #TRUE
        LBNE ..G
..Z     ENDS
        ENDPROC

        end

; end of file: BR.asm
