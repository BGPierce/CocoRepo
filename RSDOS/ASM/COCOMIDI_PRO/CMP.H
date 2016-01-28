; cm3.h

GOTO_VERSION equ 0
LEWIS_STEPPE equ 0
VAL_BURKE equ 0

TAPE  TEQ 1 ;=0 when a tape version
DEMO  TEQ 1 ;=0 when a demo version
DEBUG TEQ 0 ;=1 when in debug mode

FALSE EQU $FF
TRUE  EQU 0

TICKS_PER_BEAT equ 240

; this is the pointer used by the [$A002] routine
; to point to the cursor
;
CURSADR EQU $88 ;cursor position address

; A 256 byte buffer used by the FIRQ record routine
; Same area as the disk buffer, but should cause
; no conflicts. Also used as a general purpose
; temporary storage area.
;
MIDIBUF EQU $0600 ;MIDI input buffer

DEFDRIVE EQU $95A ;DOS default drive #
DBUFFER  EQU $989 ;buffer for direct disk

WORKING_ALERT_POSITION equ $514

FIRQ_VECTOR equ $fef4
IRQ_VECTOR  equ $fef7

BUFFER1_BLOCK equ $ffa4      ;extended memory MMU register addresses
BUFFER2_BLOCK equ $ffa5
BUFFER3_BLOCK equ $ffa6
DATA_BLOCK equ $ffa5

BUF1ADR EQU $8000
BUF2ADR EQU $A000
BUF3ADR EQU $C000
DAT_ADR equ $A000

TOPMEM  EQU $FDF0

SLOW    EQU $FFD8 ;clock speed hardware
FAST    EQU $FFD9 ;addresses
ROM_ON  EQU $FFDE ;enable ROMs
ROM_OFF EQU $FFDF ;enable 64K RAM

TASK_REGISTER equ $ff91

INT_ON  EQU $AF ;interrupts enable
INT_OFF EQU $50 ;interrupts disable

LEFT     EQU 8 ;cursor key values
RIGHT    EQU 9
DOWN     EQU 10
UP       EQU 94
ENTER    EQU 13
SHFTUP   EQU 95
SHFTDOWN EQU 91
SHFTRGHT EQU 93
SHFTLEFT EQU 21
BREAK    EQU 3

; MIDI filter bit definitions
MF_NOTOF EQU 1 ;note off
MF_NOTON EQU 2 ;note on
MF_KEYPR EQU 4 ;key pressure
MF_CTRL  EQU 8 ;control change
MF_PROG  EQU $10 ;program change
MF_CHPRE EQU $20 ;channel pressure
MF_PIWHE EQU $40 ;pitch wheel

EVNSIZE EQU 8 ;# bytes in an event
COMMENT_SIZE equ 19 ;number of bytes in a track comment (including terminator)

; event structure
; 2 bytes: event time ($FFFF=end)
; 3 bytes: MIDI event
; 2 bytes: note length
; 1 byte:  track number

SCRNWIDE EQU 32 ;width of screen in bytes

%if GOTO_VERSION eq 1
MAXSYS  EQU 7
%else
MAXSYS  EQU 6 ;max. # of sys. events
%endif

; end of file: cm3.h

