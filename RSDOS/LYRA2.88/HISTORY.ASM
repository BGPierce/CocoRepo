**************************************************
*     LYRA File Modification History
*      Mods written by Robert Gault
* May 14,1990 REQUEST/TXT
*      READBUT2 allows exit from pulldowns with
*      button on joystick or mouse. Button is debounced.
*
*      DISKIO/TXT allows exit from pulldown if not over name or drive.
*
*      LYRA/TXT Move original Coco3 test to START
*      where ROM not RAM is tested. If Coco3, CMP and
*      WIDTH32 are done and COCO3 cleared.
*
* May 17,1990
*      LYRA/TXT adjusted for hard drive display of
*      numbers from 000 to 999
*      DISKIO/TXT adjusted for hard drive numbers
*
* May 18,1990
*      DISKIO/TXT adjusted for hard drive numbers
*      REQUEST/TXT adjusted for hard drive numbers
*
* May 20,1990
*      All Lyra files changed from PIC code to non-PIC code to save
*      space. PIC code not needed as program is never relocated.
*      Saved space can be better used for music data.
*
* May 21,1990
*      DISKIO/TXT adjusted so drive can be increased or decreased
*      from within DIR. Trap for high drive number.
*      Rollover of drive numbers.
*
* May 23,1990
*      LYRA/TXT test for the presence of the RGB hard drive
*      system. If there the maximum drive is set from the
*      RGB parameter. If normal DOS, max drive set at 3.
*      DISKIO/TXT gran report corrected. Was off by +1.
*
* May 24,1990
*      REQUEST/TXT adjusted to permit backups with
*      uparrow and correct cycling with downarrow
*
* May 28,1990
*      REQUEST/TXT adjusted to show/permit GOTOBAR values
*      up to 341.
*
* June 1,1990 DISKIO/TXT adjusted to use DOS output
*      instead of general [$A002] which had caused
*      crashes with hard drive system.
*
*      Display of Anotation during Play-all reinstated.
*
*      PLAY/TXT adjusted so left arrow action correct
*      after BAR overflow until after bar 341. Overflow
*      message changed to indicate right arrow will
*      continue even after overflow.
* June 3,1990 PLAY/TXT adjusted in "playall" routine
*      for correct action in DEMO mode.
* June 24,1990 PLAT/TXT corrected in MIDIPLAY
*      port test was backwards
*      Removed indirect addressing to midipack.
* June 29,1990 DISKIO/TXT changed so leading zeros in
*      DIR locations won't show. COSMETIC
*      REQUEST/TXT compensated for DISKIO change
* Aug. 21,1990 LYRA/TXT changed to send active sensing to
*      SENDMIDI each loop through MENU as well as READBUT
* Apr. 14,1991 all disk I/O is now done in RAM so
*      that hard drives with different OS-9 partitions
*      will function correctly.
* Dec. 09,1992 REQUEST/TXT relocate requester button
*      test. Place before KEYTEST to prevent bounce
*      of button into staff line, creating unwanted
*      note.
* Dec. 18,2011 Restored Coco1&2 Disk I/O by returning to ROM
*      as needed in DISKIO.ASM. Also increased the number of blocks
*      used to copy ROM code so large files will load from floppies.
* Apr. 2012 New version that works with Drivewire4 and uses the DW4
*      MIDI emulation. Only serial tx used, connected to a PC.
* June 21, 2012 Changed REQUEST so that there is a three-way selection
*      among Serial MIDI, COCO MIDI, and Drivewire4. This was done in
*      lyra.asm, request.asm, and play.asm. Search for DWFLG.