* TITL1 "TITLE/TXT"
***********************************************
* TITLE/TXT: INCLUDE FILE FOR LYRABOX
* Last update: 28-jun-88
***********************************************

*COPYR - display copyright message
*
COPYR LEAX a@,PCR
 LBSR SETREQ
 LBSR DSPREQ
 LBSR WAITKEY
 LBSR REFMEN
 LDA #$5A set startup flag
 STA STARTUP,PCR
 CLR CLICK,PCR
 RTS
a@ FCB 42 VPOS
 FCB 5 HPOS
 FCB 20 width of requester
 FCB 9 height of requester
 FCB 0 length of input
 FDB 0 address of input area
 FCB 13 space for graphics
 FCB FAT+128
 FCC "      LYRAPLAY"
 FCB 13,13
 FCB 128 set TMODE to thin
 FCC " Copyright (C) 1988"
 FCB 13
 FCC "by Rulaford Research"
 FCB 13,13
 FCC "    Version  "
 FCB VERSION,48,REVISION
 FCB 0 end of requester

