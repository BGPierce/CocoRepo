* UTILITY/TXT* (C) 1988 by Lester Hands* make a bell-like tone*Bell PROC S_PITCH PSHS CC ORCC #INT_OFF disable interrupts STA SLOW LDA #150A@ LDB S_PITCH+2,SB@ DECB NOP BNE B@ TFR A,B ANDB #$F7 ORB #2 STB $FF20 LDB S_PITCH+2,SC@ DECB BNE C@ LDB #2 STB $FF20 DECA DECA CMPA #18 BHS A@ LBSR SetSpd PULS CC ENDP* turn on the DAC to TV (enable sound output)*TVON LDA $FF23 ORA #8 STA $FF23 LDA $FF01 ANDA #$F7 STA $FF01 LDA $FF03 ANDA #$F7 STA $FF03 RTS* clear the screen, home the cursor*CLS PSHS X LDX #$0400 STX CURSADR home cursor LDD #$6060A@ STD ,X++ CMPX #$0600 BNE A@ CLR XPOS,PCR CLR YPOS,PCR PULS X,PC* move cursor to XPOS, YPOS position*MOVE LDB YPOS LDA #32 MUL ADDB XPOS ADCA #0 ADDD #$400 STD CURSADR RTS* Convert address at CURSADR to XPOS, YPOS*GETPOS PSHS X LDD CURSADR SUBD #$400 LDX #0A@ LEAX 1,X SUBD #32 BCC A@ LEAX -1,X ADDD #32 STB XPOS,PCR TFR X,D STB YPOS,PCR PULS X,PC* put (print) a string on the screen* ENTRY: X points to start of string* EXIT:  X points to end of string*PUTS LDA ,X+ BEQ A@ LBSR ChrOut BRA PUTSA@ RTS* wait for all keys released*WAIT PSHS B,X LDX #$1000A@ LEAX -1,X BNE A@ CLR $FF02B@ LDB $FF00 ANDB #$7F CMPB #$7F BNE B@ PULS B,X,PC* convert binary number in A to ASCII hex* string stored in area pointed to by X*BINHEX PSHS A,X LSRA LSRA LSRA LSRA BSR A@ PULS A ANDA #$0F BSR A@ CLR ,X end of string PULS X,PCA@ CMPA #9 BLS B@ ADDA #7B@ ADDA #'0 STA ,X+ RTS* convert binary number in D to ASCII decimal* leading zeros are omitted* store string in area pointed to by X* LOCAL L_FLAG,L_CNT,L_TMPBINDEC PROC CMPD #0 BNE G@ LDA #'0 quickie if D=0 CLRB STD ,X LBRA Z@G@ STX c@,PCR LDX #0 STX L_FLAG,S LDX #5 STX L_CNT,S LDY #4 LEAX a@,PCR point to powers of 10A@ LDU #0B@ SUBD ,X count number of times BCS C@ this power of 10 can be LEAU 1,U subtracted from value BRA B@C@ ADDD ,X++ STD L_TMP,S TFR U,D TSTB BNE E@ TST L_CNT+1,S BEQ E@ TST L_FLAG,S BEQ F@E@ BSR D@ INC L_FLAG,SF@ DEC L_CNT+1,S LDD L_TMP,S LEAY -1,Y see if last power has BNE A@ been done yet BSR D@ CLR [c@,PCR] end of stringZ@ ENDP*D@ TFR B,A print the power ADDA #'0 STA [c@,PCR] LDD c@,PCR ADDD #1 STD c@,PCR RTS*a@ FDB 10000 powers of 10 FDB 1000b@ FDB 100 FDB 10*c@ FDB 0 pointer to output* check for a CoCo 3, set to double speed if present*SetSpd LDD $FFFE CMPD #$8C1B BNE A@ STA FAST BRA Z@A@ STA SLOWZ@ RTS* Clear a string (fill with spaces)* X contains pointer to string*ClrStr PSHS X LDA #32A@ TST ,X BEQ Z@ STA ,X+ BRA A@ LDX 0,S LBSR PUTSZ@ PULS X,PC* Get a string from the keyboard* Pointer to input string and maximum length (not* including 0 terminator) are required parameters.* Returns last key pressed.* Pressing the up or down arrow key terminates input.* LOCAL L_POS,L_CA,L_KEYGetStr PROC S_PTR,S_LEN LDX S_PTR,S LDY CURSADR STY L_CA,S LBSR PUTS STY CURSADR CLR L_POS,S LDX S_PTR,S* get keyboard inputG@ LDA [CURSADR] set 6th bit to 0 ANDA #$BF (turn cursor on) STA [CURSADR]A@ LBSR getchar STA L_KEY,S LDB [CURSADR] set 6th bit to 1 ORB #$40 (erase cursor) STB [CURSADR] CMPA #BREAK BEQ Z@ CMPA #UP BEQ Z@ CMPA #DOWN BEQ Z@ CMPA #13 BEQ Z@* process backspace CMPA #LEFT BNE B@ TST L_POS,S do nothing if already BEQ G@ at start of string DEC L_POS,S LEAX -1,X LDD CURSADR SUBD #1 STD CURSADR BRA G@* process right arrowB@ CMPA #RIGHT BNE C@ LDA L_POS,S INCA CMPA S_LEN+1,S BHS G@ STA L_POS,S LEAX 1,X LDD CURSADR ADDD #1 STD CURSADR BRA G@* process CLEARC@ CMPA #12*        BNE     D@*        LDX     S_PTR,S*        LBSR    ClrStr*        CLR     L_POS,S*        LDX     S_PTR,S*        LDD     L_CA,S*        STD     CURSADR*        BRA     G@* legal characterD@ CMPA #127 BHI G@ CMPA #32 BLO G@ STA ,X+ LBSR ChrOut INC L_POS,S LDB L_POS,S CMPB S_LEN+1,S LBLO G@E@ LEAX -1,X DEC L_POS,S SYNC LDD CURSADR SUBD #1 STD CURSADR LBRA G@Z@ TFR A,B CLRA ENDP* convert ASCII hex string to binary byte* string MUST have two characters* ENTRY: X points to string* EXIT:  A contains binary byte*htbyte PROC LDA ,X+ BSR a@ LSLA LSLA LSLA LSLA PSHS A LDA ,X BSR a@ ORA ,S+ ENDPa@ SUBA #'0 CMPA #9 BLS b@ SUBA #7b@ RTS* convert ASCII string to binary integer* ENTRY: X=pointer to string* EXIT:  D=binary equivalent* LOCAL L_SPTR,L_POWR,L_ACCUMatoi PROC* zero the accumulator CLRA CLRB STD L_ACCUM,S* skip any leading spacesD@ LDA ,X+ CMPA #32 BEQ D@ LEAX -1,X STX L_SPTR,S remember start addrs.* find first non-numeric characterA@ LDB ,X+ CMPB #'0 BLO B@ CMPB #'9 BLS A@* X now is pointing to last digit+1B@ LDD #1 STD L_POWR,S LEAX -1,XC@ CMPX L_SPTR,S BEQ Z@ LDB ,-X SUBB #'0 CLRA STD ARG1 LDD L_POWR,S STD ARG2 CALL Mult,ARG1,ARG2 ADDD L_ACCUM,S STD L_ACCUM,S LDD L_POWR,S STD ARG1 CALL Mult,ARG1,#10 STD L_POWR,S BRA C@Z@ LDD L_ACCUM,S ENDP* integer multiply; result returned in register D* one parameter is 16 bit and the other must be 8 bit* LOCAL L_ACCUMMult PROC S_M1,S_M2 LDA S_M1+1,S LDB S_M2+1,S MUL STD L_ACCUM,S* LDA S_M1,S LDB S_M2+1,S MUL TFR B,A CLRB ADDD L_ACCUM,S STD L_ACCUM,S* LDA S_M1+1,S LDB S_M2,S MUL TFR B,A CLRB ADDD L_ACCUM,S ENDP* Divide dividend by divisor, return quotient in D* return remainder X* divide by zero error returns zero* LOCAL L_ACCUMDivide PROC S_DIVD,S_DIVS LDX #0 LDD S_DIVS,S BEQ Z@ LDX #0 LDD S_DIVD,SA@ LEAX 1,X SUBD S_DIVS,S BCC A@ ADDD S_DIVS,S STD REMAIN STD S.X,S LEAX -1,X TFR X,DZ@ ENDP* A very quick keyboard scan to check for BREAK* or spacebar. If register A is nonzero, then* $FF00 will be read directly; otherwise KEYINP* will be read. Returns the ASCII value in A, or* zero if neither. $FF02 is cleared for fast read*QuickIn PSHS X TSTA  OK to read $FF00 BEQ B@ directly only if not LDX #$FF00 using the HSYNC IRQ BRA C@ interruptB@ LDX #KEYINPC@ LDA #$FB check for BREAK STA $FF02 LDA ,X CMPA #$3F BNE A@ LDA #3 BRA Z@A@ LDA #$7F check for SPACE STA $FF02 LDA ,X CMPA #$77 BNE D@ LDA #32 BRA Z@D@ CLRA  return not found codeZ@ CLR $FF02 PULS X,PC* get a character from the keyboard* waits until a key is pressed* returns ASCII value in register A*getchar BSR INKEY TSTA BEQ getchar RTS* The keyboard read routine also contains auto -* repeat.  Also, shift with A-Z just gives opposite* case from what is set by shift-0.* Joystick button is the same as ENTER* KEYTAB is a section of 17 zero bytes*INKEY PSHS B,X,Y,U LDX #KEYTAB ROLLOVER TABLE LEAU 8,X KEYBOARD STATUS LDY #$FF00 KEYBOARD MATRIX LDB #1 1=SHIFT; 0=NO SHIFT LDA #$7F ENABLE COLUMN 7 STA 2,Y TO ENABLE PORT LDA ,Y READ BACK MATRIX ANDA #$40 SHIFT PRESSED? BEQ A@ YES, SET TO SHIFTED CLRB  NO, UN-SHIFTEDA@ STB ,U SAVE STATUS CLR 6,U START COLUMN ZERO LDB #$FE COMMAND BYTE STB 2,Y TO PIANXTCOL BSR READKY READ KEYS PRESSED STA 7,U SAVE FOR ROLLOVER EORA ,X TEST IF ANY KEY WAS ANDA ,X PRESSED LAST TIME LDB 7,U GET KEYS PRESSED STB ,X+ SAVE TO ROLLOVER TSTA  ANY NEW KEYS? BNE DEBNCE YES! GO DEBOUNCE IT INC 6,U NEXT COLUMN COMB  SET CARRY ROL 2,Y ENABLE NEXT COLUMN BCS NXTCOL ALL COLUMNS DONE? TST 1,U ANY AUTO REPEAT? BMI E@ NO, FORGET LEAX -8,X GET START ROLLOVER LDA 2,U GET REPEAT DATA LDA A,X GET ENTRY OF ROLLOV COMA  INVERT, AND IF THEY ANDA 3,U CANCEL EACH OTHER- BNE F@ WE HAVE A REPEATNOKEY LDB #$FF SET TO NO NEW KEYS STB 1,U AND NO REPEATERSE@ CLRA  NO KEY FOUND PULS B,X,Y,U,PCF@ LDX 4,U REPEAT COUNT LEAX -1,X COUNT IT DOWN STX 4,U BNE E@ NO REPEAT YET? LDX #$40 RESET REPEAT COUNT STX 4,UG@ LDB 1,U GET KEY CODE BRA TRNSLT TRANSLATE TO ASCIIREADKY LDA ,Y READ KEY SWITCHES ORA #$80 KILL JOYSTICK COMPAR TST 2,Y AT SHIFT KEYS? BMI L@ NO, DONE ORA #$40 KILL SHIFT KEYL@ RTSDEBNCE LDB 6,U GET COLUMN READ STB 2,U SAVE FOR REPEATER LDB #$F8 SET FOR FIRST ADDH@ ADDB #8 ADD 8 FOR EACH ROW LSRA  CORECT ROW YET? BCC H@ WHEN SET, DONE ADDB 6,U ADD IN COLUMN NUMBER LDX #$2FF REPEAT DELAY STX 4,U REPEAT COUNTER STB 1,U SAVE KEYCODE LDX #$100 KEYBOUNCE COUNTI@ LEAX -1,X DELAY THIS LONG THEN BNE I@ TEST SAME KEY AGAIN BSR READKY READ IT AGAIN CMPA 7,U SAME KEY? BNE NOKEY NO, FORGET THIS MESS LDA 7,U GET ROW DATA COMA STA 3,U USE FOR REPEAT CHECK LDB 1,U GET KEY CODETRNSLT LDA ,U GET SHIFT/NO SHIFT TSTB  0 BECOMES `@' SIGN BEQ A@ CMPB #$1A HIGHER THAN `Z'? BHI B@ YES, TRANSLATE TABLE ORB #$40 MAKE UPPERCASE ASCII TSTA  SHIFT? BEQ C@ NO, LEAVE UPPER ORB #$20 MAKE LOWER CASEC@ PSHS B SAVE FOR KEYBEEP*KEYKLK   BRA     I@            MAKE BRN FOR BEEPKEYKLK LDD #$020A BIT 2 SET; 10 TIMESH@ EORA #$FC SET/RESET UPPER 6 STA $FF20 TO DAC LDX #36 TIMER FOR KEYBEEPE@ LEAX -1,X BNE E@ DECB  ALL 10? BNE H@I@ PULS A GET ASCII CODE TSTA  TEST FOR RETURN PULS B,X,Y,U,PCA@ LDB #$31 MAKE ASCII `@'B@ LDX #ASCTAB CONVERSION TABLE TSTA  SHIFT TABLE? BEQ D@ NO REGULAR LEAX 24,X GO TO SHIFT TABLED@ SUBB #$1B MAKE ZERO OFFSET LDB B,X GET ASCII CODE CMPB #$FF DO WE CHANGE UPRLOW? BNE C@ NO USE CODE AS ASCII CLRB  NO KEY RETURNED BRA C@ DO KEYBEEPASCTAB FCB 94,10,8,9,32,48,49 FCB 50,51,52,53,54,55,56,57,58 FCB 59,44,45,46,47,13,12,3 FCB 95,91,21,93,32,$FF,33 FCB 34,35,36,37,38,39,40,41,42 FCB 43,60,61,62,63,13,92,3* put a character on the text screen (32 column)* lower case is displayed in inverted colors* character passed in register A* Output is to printer if $6F=-2*ChrOut TST $6F BEQ E@ STA ROM_ON JSR [$A002] STA ROM_OFF RTSE@ PSHS D CMPA #13 BNE A@ LDD CURSADR ANDB #$E0 ADDD #$20 STD CURSADR BRA Z@A@ CMPA #'@ BHS B@ ADDA #$40 BRA C@B@ CMPA #'a BLO C@ SUBA #$60C@ TST TINVERT BEQ D@ EORA #$40D@ STA [CURSADR] LDD CURSADR ADDD #1 CMPD #$600 BEQ Z@ STD CURSADRZ@ PULS D,PC* return length of string in D*StrLen PROC S_PTR LDX S_PTR,S CLRA CLRBA@ TST ,X+ BEQ B@ INCB ADCA #0 BRA A@B@ ENDP* a general routine for handling command tables* ENTRY: B=lookup value*        table pointer is on stack (+2 offset)* the command table has the following format:* 1 byte -  lookup value (keypress or whatever)* 2 bytes - subroutine address* end of table indicated by lookup value=0* routine is transparent to registers X,Y,U* D is returned from subroutine intact*DoCmd PSHS X LDX 4,SA@ TST ,X BNE B@ CLRA CLRB PULS X,PCB@ CMPB ,X BEQ C@ LEAX 3,X BRA A@C@ LDD 1,X PULS X PSHS D RTS* erase a display line* assumes cursor is at start of current line* for the 32 column screen*ERALIN PSHS D,X LDX CURSADR TST TINVERT BEQ B@ LDA #$20 BRA C@B@ LDA #$60C@ LDB #SCRNWIDEA@ STA ,X+ DECB BNE A@ PULS D,X,PC* scroll the display up (add blank line at bottom)* also update MEM_LINE*SCROLUP PSHS X,Y,U LDX #$420 LDY #$400A@ LDD ,X++ STD ,Y++ CMPX #$600 BNE A@ LDX #$5E0 LDD #$6060B@ STD ,X++ CMPX #$600 BNE B@ LEAX MEM_LINE+2,PCR LEAY MEM_LINE,PCR LDB #15C@ LDU ,X++ STU ,Y++ DECB BNE C@ PULS X,Y,U,PC* scroll the display down (add blank line at top)* also update MEM_LINE*SCROLDWN PSHS X,Y,U LDX #$5E0 LDY #$600A@ LDD ,--X STD ,--Y CMPX #$400 BNE A@ LDX #$400 LDD #$6060B@ STD ,X++ CMPX #$420 BNE B@ LEAX MEM_LINE+30,PCR LEAY MEM_LINE+32,PCR LDB #15C@ LDU ,--X STU ,--Y DECB BNE C@ PULS X,Y,U,PC* display on screen results of converting binary* number in D to decimal* LOCAL CHAR L_PTR,6pBINDEC PROC LEAX L_PTR,S LBSR BINDEC LBSR PUTS ENDP* move down one line on the display, scrolling if* necessary*LINEDOWN LDA YPOS,PCR INCA CMPA #16 BNE A@ LBSR SCROLUP BRA B@A@ STA YPOS,PCRB@ LBRA MOVE* invert a line of text* LOCAL L_CURSLineInv PROC LDD CURSADR STD L_CURS,S CLR XPOS,PCR LBSR MOVE LDB #SCRNWIDE LDX CURSADRA@ LDA ,X EORA #$40 STA ,X+ DECB BNE A@ LDD L_CURS,S STD CURSADR LBSR GETPOS ENDP* assemble a string of hex numbers into binary bytes* all hex numbers must be upper case, 2 numbers long* and may or may not have a separating space.* binary data is written byte by byte to S_BIN.* Max # of bytes to assemble in S_CNT+1*HexSBin PROC S_HEX,S_BIN,S_CNT LDX S_HEX,S LDY S_BIN,SA@ LDA ,X BEQ Z@ check for end CMPA #32 check for space BNE B@ LEAX 1,X BRA A@B@ LDD ,X++ LBSR HEXBIN STA ,Y+ DEC S_CNT+1,S BNE A@Z@ ENDP* convert an ASCII hex number in D to binary in A*HEXBIN PSHS B BSR A@ LDB #16 MUL PULS A BSR A@ PSHS B ADDA ,S+ RTSA@ CMPA #'9+1 BLO B@ SUBA #7B@ SUBA #'0 RTS* pad end of a string with blanks*StrPad PROC S_PTR,S_LEN LDX S_PTR,S LDD S_LEN,S BEQ Z@A@ LDA ,X+ BEQ B@ DECB BNE A@ BRA Z@B@ LEAX -1,X LDA #32C@ STA ,X+ DECB BNE C@ CLR ,X set end markerZ@ ENDP* strip blanks off the end of a string*StrTrim PROC S_PTR LDX S_PTR,S TST ,X BEQ Z@A@ LDA ,X+ BNE A@ LEAX -1,X LDA #32C@ CMPA ,-X BEQ C@ LEAX 1,X CMPX S_PTR,S BLO Z@ CLR ,X set end markerZ@ ENDP* enable the MultiPak at slot #3*MPI3 LDA MPI_SLOT enable CMI IRQA@ STA $FF7F RTSMPI4 LDA #$33 same for slot 4 BRA A@ enable disk controller* end of file: UTILITY/TXT