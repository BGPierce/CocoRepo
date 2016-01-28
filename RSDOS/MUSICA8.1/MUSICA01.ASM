*******************************
*MUSICA01/TXT                 *
*as of 9/17/85                *
*******************************

*SCREEN DUMP ROUTINE for MUSICA II As of 8-10-85

XLEN EQU 32 number of horizontal bytes
YLEN EQU 112 number of lines per page
SSCREN EQU $1000 start of display screen

SDUMP LBSR CLS
 CLR $6F SET output to screen
 LDX #PRNMSG
 LBSR DISPLA
 LDA #$FE set output device to printer
 STA $6F
 LDA BAUD set baud
 STA 150
 TST TITFLG check if we have already
 BNE SDUMP5 printed the title
 INC TITFLG
 LDX #TITLE
 LBSR SDPTTL print 1 line of title
 LBSR SDPTTL print last line of title
 LDD #$0D02 print 2 blank lines
SDUMP4 LBSR OUTPUT
 DECB
 BNE SDUMP4
SDUMP5 LDY #SETLNF set linefeed size
 LBSR SPRNTS
 LDX #SSCREN X points to screen data
SNEXTS TFR X,U
 TFR X,D
 ADDD #XLEN
 STD >TEMP2
 CMPX #SSCREN+XLEN*YLEN check if done yet
 LBGE DONE
 LDA #XLEN
 LDB BITS
 MUL
 TFR D,Y Y=#XLEN*BITS (counter of bytes to move)
 CLR >TEMP
SLOOP LDA ,X+ test for blank line
 CMPA #$FF
 BEQ SLOOP1
 DEC >TEMP
SLOOP1 LEAY -1,Y at end of screen yet?
 BNE SLOOP
 TST >TEMP is line blank?
 LBEQ PRNTCR if so, print a 'cr'
NTBLNK LDY #SSTGRA set printer start line mode
 LBSR SPRNTS
 LDB >MARGIN print left margin
PMARG LDA >OFFSET
 LBSR SPRINT
 DECB
 BNE PMARG
SNEXTL LDB >BITS B=number of bits/print byte
 LDA #8 A=count 8 bits/byte
 STU >BUFFER
 STA >COUNT
 LDA #$FF
 STA >SENDBY
MAKBYT LDA ,U
 LSLA
 PSHS CC
 ROL ,U shift msb into flag
 PULS CC
 TST >SBTYPE check for byte type
 BNE MKBYT1
 ROL >SENDBY shift flag into byte to be printed
 BRA MKBYT2
MKBYT1 ROR >SENDBY shift flag into byte
MKBYT2 LEAU XLEN,U advance to next line
 DECB check if all printer bits loaded
 BNE MAKBYT
 LDA >SENDBY
 TST >SBTYPE if bit type=1 then
 BEQ MKBYT4 shift data right in sendbyte
 LDB #8
 SUBB >BITS
MKBYT3 BEQ MKBYT4
 LSRA
 DECB
 BRA MKBYT3
MKBYT4 COMA
 ORA >OFFSET
 BSR SPRINT send start line byte to printer
*******************************
*ADDED FOR OKIDATA: If printer*
*uses 7 bits and no offset the*
*graphics code must be dupli- *
*cated during printing        *
*THE START LINE CODE MUST BE 1*
*BYTE IN THE SETLNF STRING    *
*******************************
 TST OFFSET if OFFSET=0 and BITS=7
 BNE BYTEOK
 LDB BITS
 CMPB #7
 BNE BYTEOK then resend start line on
 CMPA SETLNF+1 if present
 BNE BYTEOK
 BSR SPRINT resend byte if=start line control code
BYTEOK LDB >BITS
 LDU >BUFFER restore U
 LDA #$FF
 STA >SENDBY
 DEC >COUNT have all bits of each byte been printed?
 BNE MAKBYT
 LEAU 1,U move to next byte
 CMPU >TEMP2
 BLO SNEXTL loop back if not at end of line
PRNTCR LDY #SETCR send "CR" to printer
 LBSR SPRNTS
 LBRA SNEXTS get next line of start line
DONE DEC >SCOUNT
 BNE DONE1
 LDY #SETFF end of page; do formfeed
 BSR SPRNTS
 LDA #6
 STA >SCOUNT
DONE1 CLR $6F output device set to screen
 RTS
SPRNTS LDB ,Y+ B is counter for items to print
 BEQ PRNTS2
PRNTS1 LDA ,Y+
 BSR SPRNT
 DECB
 BNE PRNTS1
PRNTS2 RTS
SPRINT BSR SPRNT
 RTS
SPRNT BSR OUTPUT
 PSHS A,Y,U
 BSR INPUT check for "break"
 CMPA #3
 PULS A,Y,U
 BNE PRNTS2
 CLR $6F set output to screen
 LDA #3 if break, then cancel return
 PULS X,Y,PC and return to keyw

INPUT PSHS B
 CLRB
 EXG DP,B
 JSR [$A000]
 EXG B,DP
 PULS B,PC

OUTPUT PSHS A,B
 CLRB
 EXG DP,B
 JSR [$A002]
 EXG B,DP
 PULS A,B,PC

TITFLG RMB 1 title print flag

DISPLA LDA ,X+
 TSTA
 BEQ DISPEN
 LBSR OUTPUT
 BRA DISPLA
DISPEN RTS

PRNMSG FCC "PRINTING..."
 FCB 0

SDPTTL LDA #'  print 24 spaces
 LDB #24
SDPTT2 LBSR OUTPUT
 DECB
 BNE SDPTT2
 LDB #32 number of letters in line
SDPTT3 LDA ,X+ get letter
 LBSR OUTPUT print it
 DECB check for end
 BNE SDPTT3
 LDA #13 print CR
 LBRA OUTPUT

