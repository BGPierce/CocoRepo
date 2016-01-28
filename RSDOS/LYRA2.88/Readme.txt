The Lyra source code by Lester Hands was written for the EDT MAS editor assembler set of programs. Without extensive modification it will not compile using EDTASM+ by Tandy nor my patch EDTASM6309. It can be compiled using Roger Taylor's Portal-9 or RainbowIDE packages using the CCASM assembler.

The main file is LYRA.ASM which INCLUDEs the rest of the source code except HISTORY.ASM. There are a few choices to be made to select for Stock or Drivewire usage. Drivewire, if desired, requires setting flags in PLAY.ASM. Selecting HDBDOS1.1 or HDBDOS1.4 or later is done in LYRA.ASM.
Likewise you can select the Coco serial port or the CocoMIDI pack. This is done with a flag in PLAY.ASM.

You can read the history of my modifications to Lester's code in HISTORY.ASM.

Robert Gault
