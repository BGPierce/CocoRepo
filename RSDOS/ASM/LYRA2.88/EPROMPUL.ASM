 NAME "EPROMPUL"
 TITLE "EPROM PULLER for Lyra by Robert Gault (c) Oct. 1990"

 ORG $D8D0

START CLRB
a@ LDA #32 test for the break key
 STA $FF02 if pushed go normal
 LDA $FF00
 LSRA
 LSRA
 LBEQ $A0E2
 DECB
 BNE a@
 ORCC #$50
 LDS #$7FFE set stack
 LDA #%11000100
 STA $FF90
 STA $FFDE ROM
 LDX #$D900 move some code
 LDU #$E00
A@ LDD ,X++
 STD ,U++
 CMPX #$FF00
 BLO A@
