/* ~Vm640/VERSION.H  88/12/15* See ARCH/Version.h for revision history.* Version = 2-bits Level, 3-bits Score, 3-bits Revision* Level -- radical, like 640 screen, windows, 32000 notes, etc.* Score -- older scores are invalid.* Revision -- new features, cleaned up code, etc.*/#define UMLEVEL     9/* 7 == Shareware, or something beyond Northern Xposure *//* 8 == Beaming, more Printer options *//* 9 == KeyPad editor, deferred TimeSigs, etc. */#define SCLEVEL     11/* Score level: 8=Beta Clefs, 9=Events, 10=Accents, Labels;*  11==extra Instrs and Title lines*/#define RVLEVEL     2    /* 7.11.2 SHAREWARE screen */#define RVSUBLET    'A'  /* Sub-revision letter code *//* 9.11.1A Fixed '+' cursor; back to old midi clock reader. 9.11.1B Hght-compensation for rests, etc. in finder() and kpcurse().9.11.1C Main screen has more KB accels |& and they all refresh Rep.9.11.2  Click scroll bar for fast viewport jump 02/02/209.11.2A Guard against short INS files 02/9/16*//* eof ~Vm640/version.h */