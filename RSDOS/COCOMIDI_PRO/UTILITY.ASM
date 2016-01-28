; UTILITY/TXT
; (C) 1988 by Lester Hands

%include "macros.h"
%include "cmp.h"

; make a bell-like tone
;
        GLOBAL Bell
Bell PROC
        STACKVAR S_PITCH
        PSHS CC
        ORCC #INT_OFF ;disable interrupts
        STA SLOW
        LDA #150
..A     LDB S_PITCH+2,S
..B     DECB
        NOP
        BNE ..B
        TFR A,B
        ANDB #$F7
        ORB #2
        STB $FF20
        LDB S_PITCH+2,S
..C     DECB
        BNE ..C
        LDB #2
        STB $FF20
        DECA
        DECA
        CMPA #18
        BHS ..A
        sta FAST
        PULS CC
        ENDS
        ENDPROC

; turn on the DAC to TV (enable sound output)
;
        GLOBAL TVON
TVON    LDA $FF23
        ORA #8
        STA $FF23
        LDA $FF01
        ANDA #$F7
        STA $FF01
        LDA $FF03
        ANDA #$F7
        STA $FF03
        RTS

; clear the screen, home the cursor
;
        GLOBAL CLS
        EXTERN XPOS,YPOS
CLS PROC
        PSHS X
        LDX #$0400
        STX >CURSADR ;home cursor
        LDD #$6060
..A     STD ,X++
        CMPX #$0600
        BNE ..A
        CLR XPOS
        CLR YPOS
        PULS X,PC
        ENDPROC

; move cursor to XPOS, YPOS position
;
        GLOBAL MOVE
MOVE proc
        LDB YPOS
        LDA #32
        MUL
        ADDB XPOS
        ADCA #0
        ADDD #$400
        STD >CURSADR
        RTS
        endproc

; Convert address at CURSADR to XPOS, YPOS
;
        GLOBAL GETPOS
GETPOS PROC
        PSHS X
        LDD >CURSADR
        SUBD #$400
        LDX #0
..A     LEAX 1,X
        SUBD #32
        BCC ..A
        LEAX -1,X
        ADDD #32
        STB XPOS,PCR
        TFR X,D
        STB YPOS,PCR
        PULS X,PC
        ENDPROC

; put (print) a string on the screen
; ENTRY: X points to start of string
; EXIT:  X points to end of string
;
        GLOBAL PUTS
PUTS PROC
        LDA ,X+
        BEQ ..A
        LBSR ChrOut
        BRA PUTS
..A     RTS
        ENDPROC

; wait for all keys released
;
        GLOBAL WAIT
WAIT PROC
        PSHS B,X
        LDX #$1000
..A     LEAX -1,X
        BNE ..A
        CLR $FF02
..B     LDB $FF00
        ANDB #$7F
        CMPB #$7F
        BNE ..B
        PULS B,X,PC
        ENDPROC

; convert binary number in A to ASCII hex
; string stored in area pointed to by X
;
        GLOBAL BINHEX
BINHEX PROC
        PSHS A,X
        LSRA
        LSRA
        LSRA
        LSRA
        BSR ..A
        PULS A
        ANDA #$0F
        BSR ..A
        CLR ,X ;end of string
        PULS X,PC
..A     CMPA #9
        BLS ..B
        ADDA #7
..B     ADDA #'0'
        STA ,X+
        RTS
        ENDPROC

%if 1 eq 0
        global PrintSignedBinary
PrintSignedBinary proc
        localvar l_sign
        char l_ptr,7
        stackvar
        leax l_ptr,s
        sta l_sign,s
        bpl ..a
        pshs a
        lda #'-'
        sta ,x+
        puls a
        coma
        comb
        addd #1
..a     lbsr BINDEC
        tst l_sign,s
        bpl ..b
        leax -1,x
..b     lbsr PUTS
        ends
        endproc

        global ConvertSignedBinary
ConvertSignedBinary proc
        pshs a,x
        tsta
        bpl ..a
        coma
        comb
        addd #1
        leax 1,x
..a     lbsr BINDEC
        puls a,x
        tsta
        bpl ..z
        lda #'-'
        sta ,x
..z     rts
        endproc
%endif

; convert binary number in D to ASCII decimal
; leading zeros are omitted
; store string in area pointed to by X
;
        GLOBAL BINDEC
        LOCALVAR L_FLAG,L_CNT,L_TMP
BINDEC PROC
        STACKVAR
        CMPD #0
        BNE ..G
        LDA #'0' ;quickie if D=0
        CLRB
        STD ,X
        LBRA ..Z
..G     STX ..cc,PCR
        LDX #0
        STX L_FLAG,S
        LDX #5
        STX L_CNT,S
        LDY #4
        LDX #..aa ;point to powers of 10
..A     LDU #0
..B     SUBD ,X ;count number of times
        BCS ..C ;this power of 10 can be
        LEAU 1,U ;subtracted from value
        BRA ..B
..C     ADDD ,X++
        STD L_TMP,S
        TFR U,D
        TSTB
        BNE ..E
        TST L_CNT+1,S
        BEQ ..E
        TST L_FLAG,S
        BEQ ..F
..E     BSR ..D
        INC L_FLAG,S
..F     DEC L_CNT+1,S
        LDD L_TMP,S
        LEAY -1,Y ;see if last power has
        BNE ..A ;been done yet
        BSR ..D
        CLR [..cc,PCR] ;end of string
..Z     ENDS
;
..D     TFR B,A ;print the power
        ADDA #'0'
        STA [..cc,PCR]
        LDD ..cc,PCR
        ADDD #1
        STD ..cc,PCR
        RTS
;
..aa    FDB 10000 ;powers of 10
        FDB 1000
..bb    FDB 100
        FDB 10
;
..cc    FDB 0 ;pointer to output
        ENDPROC

; Clear a string (fill with spaces)
; X contains pointer to string
;
        GLOBAL ClrStr
ClrStr PROC
        PSHS X
        LDA #32
..A     TST ,X
        BEQ ..Z
        STA ,X+
        BRA ..A
        LDX 0,S
        LBSR PUTS
..Z     PULS X,PC
        ENDPROC

; Get a string from the keyboard
; Pointer to input string and maximum length (not
; including 0 terminator) are required parameters.
; Returns last key pressed.
; Pressing the up or down arrow key terminates input.
;
        GLOBAL GetStr
        LOCALVAR L_POS,L_CA,L_KEY
GetStr PROC
        STACKVAR S_PTR,S_LEN
        LDX S_PTR,S
        LDY >CURSADR
        STY L_CA,S
        LBSR PUTS
        STY >CURSADR
        CLR L_POS,S
        LDX S_PTR,S
; get keyboard input
..G     LDA [CURSADR] ;set 6th bit to 0
        ANDA #$BF ;(turn cursor on)
        STA [CURSADR]
..A     LBSR getchar
        STA L_KEY,S
        LDB [CURSADR] ;set 6th bit to 1
        ORB #$40 ;(erase cursor)
        STB [CURSADR]
        CMPA #BREAK
        BEQ ..Z
        CMPA #UP
        BEQ ..Z
        CMPA #DOWN
        BEQ ..Z
        CMPA #13
        BEQ ..Z
; process backspace
        CMPA #LEFT
        BNE ..B
        TST L_POS,S ;do nothing if already
        BEQ ..G ;at start of string
        DEC L_POS,S
        LEAX -1,X
        LDD >CURSADR
        SUBD #1
        STD >CURSADR
        BRA ..G
; process right arrow
..B     CMPA #RIGHT
        BNE ..D
        LDA L_POS,S
        INCA
        CMPA S_LEN+1,S
        BHS ..G
        STA L_POS,S
        LEAX 1,X
        LDD >CURSADR
        ADDD #1
        STD >CURSADR
        BRA ..G
..D     CMPA #127
        BHI ..G
        CMPA #32
        BLO ..G
        STA ,X+
        LBSR ChrOut
        INC L_POS,S
        LDB L_POS,S
        CMPB S_LEN+1,S
        LBLO ..G
..E     LEAX -1,X
        DEC L_POS,S
        SYNC
        LDD >CURSADR
        SUBD #1
        STD >CURSADR
        LBRA ..G
..Z     TFR A,B
        CLRA
        ENDS
        ENDPROC

; convert ASCII hex string to binary byte
; string MUST have two characters
; ENTRY: X points to string
; EXIT:  A contains binary byte
;
        GLOBAL htbyte
htbyte PROC
        STACKVAR
        LDA ,X+
        BSR ..aa
        LSLA
        LSLA
        LSLA
        LSLA
        PSHS A
        LDA ,X
        BSR ..aa
        ORA ,S+
        ENDS
..aa    SUBA #'0'
        CMPA #9
        BLS ..bb
        SUBA #7
..bb    RTS
        ENDPROC

; convert ASCII string to binary integer (handles + and - leaders)
; ENTRY: X=pointer to string
; EXIT:  D=binary equivalent
;
        EXTERN ARG1,ARG2
        GLOBAL atoi
atoi PROC
        LOCALVAR L_SPTR,L_POWR,L_ACCUM,l_sign
        STACKVAR
; zero the accumulator
        CLRA
        CLRB
        STD L_ACCUM,S
; skip any leading spaces
..D     LDA ,X+
        CMPA #32
        BEQ ..D
; look for leading '+' or '-'
        leax -1,x
        clr l_sign,s
        lda ,x
        cmpa #'+'
        beq ..a1
        cmpa #'-'
        bne ..a3
        lda #-1
        bra ..a2
..a1    lda #1
..a2    sta l_sign,s
        lda #' '
        sta ,x+
..a3    stx L_SPTR,S         ;remember start address.
; find first non-numeric character
..A     LDB ,X+
        CMPB #'0'
        BLO ..B
        CMPB #'9'
        BLS ..A
; X now is pointing to last digit+1
..B     LDD #1
        STD L_POWR,S
        LEAX -1,X
..C     CMPX L_SPTR,S
        BEQ ..Z
        LDB ,-X
        SUBB #'0'
        CLRA
        STD ARG1
        LDD L_POWR,S
        STD ARG2
        CALL Mult,ARG1,ARG2
        ADDD L_ACCUM,S
        STD L_ACCUM,S
        LDD L_POWR,S
        STD ARG1
        CALL Mult,ARG1,#10
        STD L_POWR,S
        BRA ..C
..Z     LDD L_ACCUM,S
        tst l_sign,s
        bpl ..z1
        coma
        comb
        addd #1
..z1    ENDS
        ENDPROC

; integer multiply; result returned in register D
; one parameter is 16 bit and the other must be 8 bit
;
        GLOBAL Mult
        LOCALVAR L_ACCUM
Mult PROC
        STACKVAR S_M1,S_M2
        LDA S_M1+1,S
        LDB S_M2+1,S
        MUL
        STD L_ACCUM,S
;
        LDA S_M1,S
        LDB S_M2+1,S
        MUL
        TFR B,A
        CLRB
        ADDD L_ACCUM,S
        STD L_ACCUM,S
;
        LDA S_M1+1,S
        LDB S_M2,S
        MUL
        TFR B,A
        CLRB
        ADDD L_ACCUM,S
        ENDS
        ENDPROC

; Divide dividend by divisor, return quotient in D
; return remainder in REMAIN
; divide by zero error returns zero
;
        GLOBAL Divide,REMAIN
REMAIN  FDB 0
%if 1 eq 0
Divide  proc
        stackvar s_dividend,s_divisor
        ldd s_divisor,s
        beq ..end
        ldd s_dividend,s
        pshs b,a
        ldd s_divisor,s
        lbsr _ccudiv
        stx REMAIN
..end   ends
        endproc

l_acum  set 0
l_dividend set 2
l_divisor set 6
;
_ccudiv proc
        pshs  b,a
        leas  -2,s
;
        clr   l_acum,s
        clr   l_acum+1,s
        lda   #1
L01D0   inca
        lsl   l_dividend+1,s
        rol   l_dividend,s
        bpl   L01D0
        sta   l_acum,s
;
        ldd   l_divisor,s
        clr   l_divisor,s
        clr   l_divisor+1,s
L01DF   subd  l_dividend,s
        bcc   L01E9
        addd  l_dividend,s
        andcc #$FE
        bra   L01EB
L01E9   orcc  #1
L01EB   rol   l_divisor+1,s
        rol   l_divisor,s
        lsr   l_dividend,s
        ror   l_dividend+1,s
        dec   l_acum,s
        bne   L01DF
        std   l_dividend,s
;
        tst   l_acum+1,s
        beq   L0205
        ldd   l_divisor,s
        nega
        negb
        sbca  #0
        std   l_divisor,s
L0205   ldx   4,s
        ldd   6,s
        std   4,s
        stx   6,s
        ldx   2,s
        ldd   4,s
        leas  6,s
        rts                 ;return with quotient in D, remainder in X
        endproc
%else
        LOCALVAR L_ACCUM
Divide PROC
        STACKVAR S_DIVD,S_DIVS
        LDX #0
        LDD S_DIVS,S
        BEQ ..Z
        LDX #0
        LDD S_DIVD,S
..A     LEAX 1,X
        SUBD S_DIVS,S
        BCC ..A
        ADDD S_DIVS,S
        STD REMAIN
;        STD S.X,S
        LEAX -1,X
        TFR X,D
..Z     ENDS
        ENDPROC
%endif

; Multiply extended time (pointer to structure in S_EXT) by S_AMT
; Result returned in extended time structure
; Overflow is ignored!
;
        global MultExTime
MultExTime proc
        localvar
        char l_acum,3
        stackvar S_PTR,S_AMT
        ldx S_PTR,s
        lda 0,x
        lsra
        lsra
        lsra
        lsra
        sta 0,x
        clr l_acum,s
;
        lda S_AMT+1,s
        ldb 2,x
        mul
        std l_acum+1,s
;
        lda S_AMT+1,s
        ldb 1,x
        mul
        addd l_acum,s
        std l_acum,s
;
        lda S_AMT+1,s
        ldb 0,x
        mul
        addb l_acum,s
        stb l_acum,s
;
        lda S_AMT,s
        ldb 2,x
        mul
        addd l_acum,s
        std l_acum,s
;
        lda S_AMT,s
        ldb 1,x
        mul
        addb l_acum,s
;
        lslb
        lslb
        lslb
        lslb
        stb 0,x
        ldd l_acum+1,s
        std 1,x
        ends
        endproc

; divide extended time (pointer to structure in S_EXT) by S_AMT
; it is assumed that the result will be a 16 bit number, returned in D
;
        global DivideExTime
DivideExTime proc
        localvar
        char l_ext,3
        stackvar S_EXT,S_AMT
        ldy S_EXT,s
        lda 0,y
        lsra
        lsra
        lsra
        lsra
        sta l_ext,s
        ldd 1,y
        std l_ext+1,s
        ldx #0
..a     ldd l_ext+1,s
..b     leax 1,x
        subd S_AMT,s
        bcc ..b
        std l_ext+1,s
        lda l_ext,s
        suba #1
        sta l_ext,s
        bcc ..a
        leax -1,x
        tfr x,d
        ends
        endproc

%if 1 eq 0
; A very quick keyboard scan to check for BREAK
; or spacebar. If register A is nonzero, then
; $FF00 will be read directly; otherwise KEYINP
; will be read. Returns the ASCII value in A, or
; zero if neither. $FF02 is cleared for fast read
;
        EXTERN KEYINP
        GLOBAL QuickIn
QuickIn PROC
        PSHS X
        TSTA  ;OK to read $FF00
        BEQ ..B ;directly only if not
        LDX #$FF00 ;using the HSYNC IRQ
        BRA ..C ;interrupt
..B     LDX #KEYINP
..C     LDA #$FB ;check for BREAK
        STA $FF02
        LDA ,X
        CMPA #$3F
        BNE ..A
        LDA #3
        BRA ..Z
..A     LDA #$7F ;check for SPACE
        STA $FF02
        LDA ,X
        CMPA #$77
        BNE ..D
        LDA #32
        BRA ..Z
..D     CLRA  ;return not found code
..Z     CLR $FF02
        PULS X,PC
        ENDPROC
%endif

; get a character from the keyboard
; waits until a key is pressed
; returns ASCII value in register A
;
        GLOBAL getchar
getchar BSR INKEY
        TSTA
        BEQ getchar
        RTS

; The keyboard read routine also contains auto -
; repeat.  Also, shift with A-Z just gives opposite
; case from what is set by shift-0.
; Joystick button is the same as ENTER
;
KEYTAB  fdb 0,0,0,0,0,0,0,0
        fcb 0
;
        GLOBAL INKEY
INKEY PROC
        PSHS B,X,Y,U
        LDX #KEYTAB     ;rollover table
        LEAU 8,X        ;keyboard status
        LDY #$FF00      ;keyboard matrix
        LDB #1          ;1=shift; 0=no shift
        LDA #$7F        ;enable column 7
        STA 2,Y         ;to enable port
        LDA ,Y          ;read back matrix
        ANDA #$40       ;shift pressed?
        BEQ ..A         ;yes, set to shifted
        CLRB            ;no, un-shifted
..A     STB ,U          ;SAVE STATUS
        CLR 6,U         ;start column zero
        LDB #$FE        ;command byte
        STB 2,Y         ;to pia
NXTCOL  BSR READKY      ;read keys pressed
        STA 7,U         ;save for rollover
        EORA ,X         ;test if any key was
        ANDA ,X         ;pressed last time
        LDB 7,U         ;get keys pressed
        STB ,X+         ;save to rollover
        TSTA            ;any new keys?
        BNE DEBNCE      ;yes! go debounce it
        INC 6,U         ;next column
        COMB            ;set carry
        ROL 2,Y         ;enable next column
        BCS NXTCOL      ;all columns done?
        TST 1,U         ;any auto repeat?
        BMI ..E         ;no, forget
        LEAX -8,X       ;get start rollover
        LDA 2,U         ;get repeat data
        LDA A,X         ;get entry of rollov
        COMA            ;invert, and if they
        ANDA 3,U        ;cancel each other-
        BNE ..F         ;we have a repeat
NOKEY   LDB #$FF        ;set to no new keys
        STB 1,U         ;and no repeaters
..E     CLRA            ; no key found
        PULS B,X,Y,U,PC
..F     LDX 4,U         ;repeat count
        LEAX -1,X       ;count it down
        STX 4,U
        BNE ..E         ;no repeat yet?
        LDX #$40        ;reset repeat count
        STX 4,U
..G     LDB 1,U GET KEY CODE
        BRA TRNSLT      ;translate to ascii
READKY  LDA ,Y          ;read key switches
        ORA #$80        ;kill joystick compar
        TST 2,Y         ;at shift keys?
        BMI ..L         ;no, done
        ORA #$40        ;kill shift key
..L     RTS
DEBNCE  LDB 6,U         ;get column read
        STB 2,U         ;save for repeater
        LDB #$F8        ;set for first add
..H     ADDB #8         ;add 8 for each row
        LSRA            ;corect row yet?
        BCC ..H         ;when set, done
        ADDB 6,U        ;add in column number
        LDX #$2FF       ;repeat delay
        STX 4,U         ;repeat counter
        STB 1,U         ;save keycode
        LDX #$100       ;keybounce count
..I     LEAX -1,X       ;delay this long then
        BNE ..I         ;test same key again
        BSR READKY      ;read it again
        CMPA 7,U        ;same key?
        BNE NOKEY       ;no, forget this mess
        LDA 7,U         ;get row data
        COMA
        STA 3,U         ;use for repeat check
        LDB 1,U         ;get key code
        ENDPROC

TRNSLT PROC
        LDA ,U          ;get shift/no shift
        TSTB            ;0 becomes `@' sign
        BEQ ..A
        CMPB #$1A       ;higher than `z'?
        BHI ..B         ;yes, translate table
        ORB #$40        ;make uppercase ascii
        TSTA            ;shift?
        BEQ ..C         ;no, leave upper
        ORB #$20        ;make lower case
..C     PSHS B          ;save for keybeep
KEYKLK  LDD #$020A      ;bit 2 set; 10 times
..H     EORA #$FC       ;set/reset upper 6
        STA $FF20       ;to dac
        LDX #36         ;timer for keybeep
..E     LEAX -1,X
        BNE ..E
        DECB            ;all 10?
        BNE ..H
..I     PULS A          ;get ascii code
        TSTA            ;test for return
        PULS B,X,Y,U,PC
..A     LDB #$31        ;make ascii `@'
..B     LDX #ASCTAB     ;conversion table
        TSTA            ;shift table?
        BEQ ..D         ;no regular
        LEAX 24,X       ;go to shift table
..D     SUBB #$1B       ;make zero offset
        LDB B,X         ;get ascii code
        CMPB #$FF       ;do we change uprlow?
        BNE ..C         ;no use code as ascii
        CLRB            ;no key returned
        BRA ..C         ;do keybeep
        ENDPROC

ASCTAB  FCB 94,10,8,9,32,48,49
        FCB 50,51,52,53,54,55,56,57,58
        FCB 59,44,45,46,47,13,12,3

        FCB 95,91,21,93,32,$FF,33
        FCB 34,35,36,37,38,39,40,41,42
        FCB 43,60,61,62,63,13,92,3

; put a character on the text screen (32 column)
; lower case is displayed in inverted colors
; character passed in register A
; Output is to printer if $6F=-2
;
        EXTERN TINVERT
        GLOBAL ChrOut
ChrOut PROC
        PSHS D
        CMPA #13
        BNE ..A
        LDD >CURSADR
        ANDB #$E0
        ADDD #$20
        STD >CURSADR
        inc YPOS
        clr XPOS
        BRA ..Z
..A     CMPA #'@'
        BHS ..B
        ADDA #$40
        BRA ..C
..B     CMPA #'a'
        BLO ..C
        SUBA #$60
..C     TST TINVERT
        BEQ ..D
        EORA #$40
..D     STA [CURSADR]
        LDD >CURSADR
        ADDD #1
        CMPD #$600
        BEQ ..Z
        STD >CURSADR
        inc XPOS
..Z     PULS D,PC
        ENDPROC

; return length of string in D
;
        GLOBAL StrLen
StrLen PROC
        STACKVAR S_PTR
        LDX S_PTR,S
        CLRA
        CLRB
..A     TST ,X+
        BEQ ..B
        INCB
        ADCA #0
        BRA ..A
..B     ENDS
        ENDPROC

; a general routine for handling command tables
; ENTRY: B=lookup value
;        table pointer is on stack (+2 offset)
; the command table has the following format:
; 1 byte -  lookup value (keypress or whatever)
; 2 bytes - subroutine address
; end of table indicated by lookup value=0
; routine is transparent to registers X,Y,U
; D is returned from subroutine intact
;
        GLOBAL DoCmd
DoCmd PROC
        PSHS X
        LDX 4,S
..A     TST ,X
        BNE ..B
        CLRA
        CLRB
        PULS X,PC
..B     CMPB ,X
        BEQ ..C
        LEAX 3,X
        BRA ..A
..C     LDD 1,X
        PULS X
        PSHS D
        RTS
        ENDPROC

; erase a display line
; assumes cursor is at start of current line
; for the 32 column screen
;
        GLOBAL EraseLine
EraseLine PROC
        PSHS D,X
        LDX >CURSADR
        TST TINVERT
        BEQ ..B
        LDA #$20
        BRA ..C
..B     LDA #$60
..C     LDB #SCRNWIDE
..A     STA ,X+
        DECB
        BNE ..A
        PULS D,X,PC
        ENDPROC

; scroll the display up (add blank line at bottom)
;
        GLOBAL SCROLUP
SCROLUP PROC
        PSHS X,Y
        LDX #$420
        LDY #$400
..A     LDD ,X++
        STD ,Y++
        CMPX #$600
        BNE ..A
        LDX #$5E0
        LDD #$6060
..B     STD ,X++
        CMPX #$600
        BNE ..B
        PULS X,Y,PC
        ENDPROC

; scroll the display down (add blank line at top)
;
        GLOBAL SCROLDWN
SCROLDWN PROC
        PSHS cc,X,Y
        orcc #$50
        LDX #$5E0
        LDY #$600
..A     LDD ,--X
        STD ,--Y
        CMPX #$400
        BNE ..A
        LDX #$400
        LDD #$6060
..B     STD ,X++
        CMPX #$420
        BNE ..B
        PULS cc,X,Y,PC
        ENDPROC

; display on screen results of converting binary
; number in D to decimal
;
        GLOBAL pBINDEC
pBINDEC
        LOCALVAR
        CHAR L_PTR,6
        STACKVAR
        LEAX L_PTR,S
        LBSR BINDEC
        LBSR PUTS
        ENDS

; invert a line of text
;
        GLOBAL LineInv
        LOCALVAR L_CURS
LineInv PROC
        LDD >CURSADR
        STD L_CURS,S
        CLR XPOS,PCR
        LBSR MOVE
        LDB #SCRNWIDE
        LDX >CURSADR
..A     LDA ,X
        EORA #$40
        STA ,X+
        DECB
        BNE ..A
        LDD L_CURS,S
        STD >CURSADR
        LBSR GETPOS
        ENDPROC

; assemble a string of hex numbers into binary bytes
; all hex numbers must be upper case, 2 numbers long
; and may or may not have a separating space.
; binary data is written byte by byte to S_BIN.
; Max # of bytes to assemble in S_CNT+1
;
        GLOBAL HexSBin
HexSBin PROC
        STACKVAR S_HEX,S_BIN,S_CNT
        LDX S_HEX,S
        LDY S_BIN,S
..A     LDA ,X
        BEQ ..Z ;check for end
        CMPA #32 ;check for space
        BNE ..B
        LEAX 1,X
        BRA ..A
..B     LDD ,X++
        LBSR HEXBIN
        STA ,Y+
        DEC S_CNT+1,S
        BNE ..A
..Z     ENDS
        ENDPROC

; convert an ASCII hex number in D to binary in A
;
        GLOBAL HEXBIN
HEXBIN PROC
        PSHS B
        BSR ..A
        LDB #16
        MUL
        PULS A
        BSR ..A
        PSHS B
        ADDA ,S+
        RTS
..A     CMPA #'9'+1
        BLO ..B
        SUBA #7
..B     SUBA #'0'
        RTS
        ENDPROC

; pad end of a string with blanks
;
        GLOBAL StrPad
StrPad PROC
        STACKVAR S_PTR,S_LEN
        LDX S_PTR,S
        LDD S_LEN,S
        BEQ ..Z
..A     LDA ,X+
        BEQ ..B
        DECB
        BNE ..A
        BRA ..Z
..B     LEAX -1,X
        LDA #32
..C     STA ,X+
        DECB
        BNE ..C
        CLR ,X ;set end marker
..Z     ENDS
        ENDPROC

; strip blanks off the end of a string
;
        GLOBAL StrTrim
StrTrim PROC
        STACKVAR S_PTR
        LDX S_PTR,S
        TST ,X
        BEQ ..Z
..A     LDA ,X+
        BNE ..A
        LEAX -1,X
        LDA #32
..C     CMPA ,-X
        BEQ ..C
        LEAX 1,X
        CMPX S_PTR,S
        BLO ..Z
        CLR ,X ;set end marker
..Z     ENDS
        ENDPROC

; enable the MultiPak at slot #3
;
        global MPI_SLOT
MPI_SLOT        FCB $33
;
        GLOBAL MPI3,MPI4
MPI3 PROC
        LDA MPI_SLOT    ;enable CMI IRQ
..A     STA $FF7F
        RTS
MPI4    LDA #$33        ;same for slot 4
        BRA ..A         ;enable disk controller
        ENDPROC

; convert ASCII fraction to binary
; S_PTR: pointer to ASCII string
; S_BIN: pointer to memory for 4 bytes (INT,FRACTION)
;        first 2 bytes=integer part (0-255)
;        last  2 bytes=fractional part (0-255)
;
        global CnvFrac
CnvFrac PROC
        STACKVAR S_PTR,S_BIN
        LDY S_BIN,S ;set default fraction
        CLRA
        CLRB
        STD 2,Y
; convert integer part
        LDX S_PTR,S
        LBSR atoi
        STD 0,Y
; convert fraction (look for ".")
        CLRB
..A     LDA ,X+
        BEQ ..Z
        CMPA #'.'
        BNE ..A
        LBSR atoi
; count the number of decimal places (up to 2)
..B     LDA 1,X
        CMPA #'0'
        BLO ..C
        CMPA #'9'
        BLS ..D
..C     LDA #10
        MUL
; normalize to base 256
..D     CLRA
        EXG A,B
        STD ARG1
        CALL Divide,ARG1,#100
        LDA REMAIN+1
        CMPA #50
        BLO ..Z
        INCB
..Z     CLRA
        STD 2,Y
        ENDS
        ENDPROC

; multiply a fraction by a word value
; register Y points to binary fraction (see CnvFrac
;   for format)
; register D contains 2 byte word
; RETURNS value in register D
;
        LOCALVAR L_ACUM,L_VAL
        global MultFrac
MultFrac PROC
        STACKVAR
        STD L_VAL,S
; multiply value by integer part first
        LDA 1,Y
        MUL
        STD L_ACUM,S
        LDA 1,Y
        LDB L_VAL,S
        MUL
        TFR B,A
        CLRB
        ADDD L_ACUM,S
        STD L_ACUM,S
; multiply value by fraction
        LDA L_VAL,S
        LDB 3,Y
        MUL
        ADDD L_ACUM,S
        STD L_ACUM,S
        LDA L_VAL+1,S
        LDB 3,Y
        MUL
        CMPB #128
        BLO ..B
        INCA
..B     TFR A,B
        CLRA
        ADDD L_ACUM,S
        ENDS
        ENDPROC

%if 1 eq 0
; Multiply a 16 bit integer by a fraction (256 base, must be 0-256)
; Fraction value of 256 is the same as 1.0; 128 is 0.5, etc.
; Return result in register D
;
Fraction proc
        localvar
        char l_acum,3
        stackvar s_int,s_frac
        ldd s_frac,s
        cmpd #$100
        bne ..a
        ldd s_int,s
        bra ..z
..a     clr l_acum,s
        lda s_int+1,s        ;multiply fraction by LSB of integer
        ldb s_frac+1,s
        mul
        std l_acum+1,s
        lda s_int,s          ;multiply fraction by MSB of integer
        ldb s_frac+1,s
        mul
        addd l_acum,s
        std l_acum,s
        lda l_acum+2,s       ;if lsb is >128, then round up middle byte
        cmpa #128
        blo ..b
        ldd l_acum,s
        addd #1
        bra ..z
..b     ldd l_acum,s         ;return first two bytes of accumulator,
..z     ends                 ;in effect dividing multiplicand by 256
        endproc
%endif

        global memcpy
memcpy proc
        pshs d
..loop  cmpd #0
        beq ..done
        lda ,x+
        sta ,y+
        ldd 0,s
        subd #1
        std 0,s
        bra ..loop
..done  puls d,pc
        endproc

        end
; end of file: UTILITY/TXT
