/* file JINIT.C   -13-    User's initializations** Version = 2-bits Level, 3-bits Score, 3-bits Revision* Level -- radical, like 640 screen.* Score -- older scores are invalid, tho probably compatible.* Revision -- new features, cleaned up code, etc.*/#include <stdio.h>#include <modes.h>#include "jmuse.h"#include "version.h"extern direct EVENT     *curevp,       /* current event pointer */     *curptop;      /* highest event ptr possible on current page */extern direct int     bwchan,        /* Buffer window I/O channel */     group;         /* buffer group, usually our PID */extern direct Index     curind;        /* current index */extern direct ubyte     *database;     /* Bottom of current page (1st byte's addr) */extern direct sexy     curpage,       /* current page no. */     nmpages;       /* how many pages are in memory */EVENT     *i2p(), *plusplus(), *decdec();/* None of these arrays is R/O: */extern STAFF staves[NSTAVES];extern PART  parts[NPARTS + 1]; /* Parts are ORG 1, not 0! *//* This IS Read-Only! */extern CLEF  clefs[];extern sexy    instvals[NINSTRS];extern char    instnams[NINSTRS][10];extern char    filename[SFILENAME];extern ubyte   chans[NPARTS + 1],               levels[NLEVELS];extern direct Index     nevents;extern direct short    nparts, nstaves,    nbars, nzones;extern direct sexy    numer, denom, keysig, secmin, transp, velo;extern direct Time     length;extern direct Deltime    dendur, zonedur, tdur;extern NOTE    rep, qnote, qrest;extern direct bool    hires,    tripper, midiser, midipak, mididev, instren, clocken;bool      diskio();      /* pre-dec */char      *instrg();/********** Prompt user and initialize the basics */uinit() {/* Prefer Serial for external release */     midiser = instren = clocken = TRUE;     midipak = mididev = FALSE;     bwchan = 1;     /* StdOut */     group = getpid();     nevents = 0;     secmin = 60;     transp = 0;} /* uinit() *//* Process time signature as given in numer and denom; * return judgment of its legality, and set values of * dendur, nzones (old nbeats), zonedur, and tripper. * Tripper is TRUE iff 6/8, etc. * All communication is via Global variables -- sorry!*/bool timesig(){     switch(denom) {     case 2:  tdur = 2;   break;     case 4:  tdur = 3;   break;     case 8:  tdur = 4;   break;     case 16: tdur = 5;   break;     default: return(FALSE);  /* Invalid denom */     }     tripper = (tdur >= 4) & (numer > 3) & !(numer % 3);     zonedur = dendur = 192 / denom;#ifdef ZONES     nzones = numer;     if(tripper) {          zonedur *= 3;          nzones /= 3;     }#endif     return(TRUE);   /* Valid denom */}/*****************************  Count number of barlines from the start to finish.   87/6/5*  First barline is #1 unless 1st bar is "pickups",*  then barline is #0.*  Consecutive barlines/inclusions with no intervening*    "meat" (notes/rests) are given the same number.*  (Newer main version uses delta-time rather than meat test.)*/void barenum(){     short          barno, meat;     register EVENT *evp;/* Don't count a "pickup" measure as a full bar; call it #0.*  Find inital value for barno; -1 or 0 (for 0 or 1);*  is 2nd barline late enuf to end a full measure?*/     for(evp = i2p(1); curind < nevents; evp = plusplus() ) {          if((evp->part==0) && (evp->show.INCTYPE <= FINE))               break;     }     barno = (evp->startime >= numer * dendur) ? 0 : -1;/* OK, Renumber them all */     meat = 1;     for(evp = i2p(0); curind < nevents; evp = plusplus()) {/* printf("Barenum: CurInd=%d, evp=%04x\n", curind, evp); */          if(evp->part ==0) {               if(evp->show.INCTYPE <= FINE) {    /* Barline */                    barno += meat;                    meat = 0;      /* used it up */               }          }          else      /* playable "meat" note/rest */               meat = 1;     }     nbars = barno - 1;     /* update global info */}/* eof JINIT.C */