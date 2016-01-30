/* ~VM640/STAVESUBS.C  All the random subrs for Staves module *//* #include <stdio.h> */#include "wmuse.h"#include "wcodes.h"#include "wmenu.h"#include "windows.h"#include "cursors.h"#include "vmem.h"#include "fcnptrs.h"#define NL     '\n'extern PART         parts[];extern STAFF        staves[];extern CLEF         clefs[];extern ubyte        chans[];extern direct char  *pct2, *pct3, *pct4, *pct5, *pct6, *pct7,     *pctn1, *pctn2, *pctn3, *pctn4;/* extern direct ubyte arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8; */extern direct sexy     keysig, numer, denom,     nstaves, nparts, curcurse;extern char pfdat1[];extern bool partens[NPARTS+1];void stavedum() {   /* Just to link in pfdat stuff */     Reg char *junk;     junk = pfdat1;}/* *********** Functions ******* */bool ispwexpr(slt)  sexy    slt;{     return( (slt==INSTR) || (slt==LEVEL) || (slt==MCHOP)       || (slt==IPEVT) || (slt==TPEVT) );} /* NOTE: Gobar could use this now! 90/9/9 *//* Convert ONE hex-digit lower-case char to an integer.*  We permit hex digits greater than 'f', on purpose.*  Returns zero for invalid char.*/#define TOPHEX 'g'  /* Max "hex" char allowed (g == 16.) */int hexc2i(c)  char c;{     c -= '0';     if((c >= 0) && (c <= 9))          return(c);     c -= ('a' - '0');     if( (c >= 0) && (c <= (TOPHEX - 'a')) )          return(c + 10);     return(0);} /* hexc2i() *//* Inverse of above; no hard limit */char i2hexc(i)  int     i;{/*   i &= 31;       /* super-MPARTS */     return(i + ((i <= 9) ? '0' : ('A'-10)) );}bool pforget(p)     /* Returns rfr_lay TRUE iff users goes thru with it */  sexy    p;   /* Part number to forget */{     char buff[41];     strcpy(buff, "Forgetting Part X.  Sure?");     *(buff + 16) = i2hexc(p);     if((*pyesno)(buff)) {          patience();          tacet(0, nevents - 1, p, TRUE, FALSE);          fgpart(p);/* Bubble down parts[] from N+1 to nparts; nparts-- */          strdn(parts + p, parts + p + 1,            (nparts - p) * sizeof(PART) );          strdn(partens + p, partens + p + 1, nparts - p);          strdn(chans + p, chans + p + 1, nparts - p);          nparts--;          dfalprts(p, nparts);/* Decrement part #s of all events >= that part */          decprt(p);          wkill();  /* patience */          return(TRUE);     }     else {    /* User Quail'ed out */          return(FALSE);     }} /* pforget() *//* Update a "hilo" field to match Cursor Type & staff position */sexy newhilo(hilo, ct, cy, sty)  sexy    hilo, ct;  int     cy, sty;  /* Cursor and Staff */{     sexy ph;     int  dy;     ph = hilo & ~(UPPER | LOWER | NOFLAG | PERC); /* clear 'em */     dy = cy - sty - 8;     ph |= (dy > 3) ? UPPER : ( (dy < -3) ? LOWER : SOLO);     if((ct==CPITNF) || (ct==CPERCNF))          ph |= NOFLAG;     if((ct == CPERC) || (ct == CPERCNF))          ph |= PERC;     return(ph);}/* Inverse of above -- given hilo, return matching note_cursor type */sexy ph2curse(ph)  sexy    ph;{     if(ph & PERC)          return( (ph & NOFLAG) ? CPERCNF : CPERC);     else          return( (ph & NOFLAG) ? CPITNF : CPIT);}#define RMAX   127/* Find note (slot) ranges for all parts.  Send to Fran as*  two bursts, of nparts maxes and nparts mins, plus newline. */void range(lind, rind)  Index   lind, rind;{     byte mins[NPARTS+2], maxes[NPARTS+1];   /* signed */     sexy p, s, min, max;     Reg EVENT *evp;     for(p = NPARTS+1; --p; ) {          mins[p] = RMAX;          maxes[p] = -RMAX;     }     for(evp = i2p(lind); curind < rind; evp = plusplus() ) {          if( !(p = evp->part) || (p > nparts))               continue;          if( (s = evp->show.slot) == REST)               continue;          if(s > maxes[p])               maxes[p] = s;          if(s < mins[p])     /* no 'else'! */               mins[p] = s;     }/* In case of tacet part */     for(p = NPARTS+1; --p; ) {          if(maxes[p] == -RMAX)               maxes[p] = REST;     }/* Got 'em; report in grafix form */     showlay(TRUE, TRUE);     /* DON'T flush tween this and writes */     (*powrite)(maxes + 1, nparts);     mins[nparts + 1] = NL;     (*powrite)(mins + 1, nparts + 1);} /* range() *//* Wait for mouse to be released.  No-op if not being held. */void waitmouse() {  int     x, y;     /* dummies */     while((*pmouce)(&x, &y))          tsleep(4);}/* Adjust Y-spacings for various numbers of staves.*  Later fix this to consider  # parts on each staff, etc. */void styinit() {    sexy       n, dy;    Reg STAFF  *stptr;    dy = (SCORTOP-SCORBOT-(nstaves < 4 ? 20 : 0)) / (nstaves + 1);    for(n=0, stptr=staves; n < nstaves; n++)        (stptr++)->staffY = (SCORTOP - 8) - (n + 1) * dy;} /* styinit() *//* Parnasian interface; given Part No., returns the other items *//* Stripped down for staves -- no lownote needed */sexy partstaff(part, sty, /* lownote, */ hilo)    /* Returns staff # */  sexy  part;       /* INput; rest are OUTputs: */  short *sty;       /* staffY */  sexy  *hilo;      /* indicators */{    sexy       istaff;    Reg PART   *ptptr;    if((part < 1) || (part > nparts))        part = nparts;     *hilo =  (ptptr = parts + part) -> philo;    *sty =  (staves + (istaff = ptptr->pstaff)) -> staffY;    return(istaff);}/* Inclusive within-rectangle test */bool inrect(qx,qy, x1,y1, x2,y2)  sexy    qx,qy, x1,y1, x2,y2;{     return((qx>=x1) && (qx<=x2) && (qy>=y1) && (qy<=y2));}/******** Fran cmd package *****//*** Open a Pat & Vanna overlay window ***/wcreate(leftcol, topy, colswide, rowshigh, dosave, style)  sexy    leftcol, topy, colswide, rowshigh, style;  bool    dosave;{     (*pprintf)(pct7, OWST, leftcol, topy, colswide, rowshigh, dosave, style);     (*pflush)();}void dialogue(big)    /* Open a small Double window */  bool    big;{     wcreate(14, 110, 50, big ? 5 : 2, TRUE, WSDOUBLE);}void bell() {  /* putc(7, stderr)  Known to work! */     char c;     c = 7;     write(2, &c, 1);}/*** Put up "Patience, this takes time" msg window ***/patience() {     (*pprintf)(pctn1, PATI);     (*pflush)();}/*** Close window ***/wkill() {     (*pprintf)(pctn1, OWEN);}/************************* Set or reset Cursor Type, and update global curcurse.* Best done when no cursor is showing.*/void curset(curtype)  sexy    curtype;{     curcurse = curtype;     (*pprintf)(pctn2, SCUR, curtype);}/******************************************************** cursor()    Graphics cursor for ultimuse mouce* Each call either draws or erases the cursor.* Very 1st call should NOT be to erase, else get patch of*   garbage on screen!*/void cursor(x,y)  int     x;   /* yes, Pixels! */  sexy    y;{/* Let Fran tune it up, but avoid wrap-around of Y */     if(y < 0)          y = 0;     (*pprintf)(pctn4, DCUR, *((char *) &x), x, y);} /* end cursor() *//*** Make Fran print one of the stock menus */void menu(which)  sexy    which;{     (*pprintf)(pctn2, MENU, which);}/* Refresh the layout display (NOT the palettes, menus, etc. */void showlay(exlay, range)  bool    exlay,    /* if existing layout, not setup */          range;    /* if hi & lo note bytes are to follow */{     (*pprintf)(pctn3, SLAY, exlay, range);}void storf(stafnum, color)  sexy    stafnum, color;{     (*pprintf)(pctn3, DRSH, stafnum, color);}dfstaff(st, clefnum, y)  sexy    st, clefnum, y;{     (*pprintf)(pct4, DEFS, st, clefnum, y);}fgstaff(st)  sexy    st;{     (*pprintf)(pct2, UDFS, st);}void dfpart(p, s, hilo, noflags, norests, maxchord)  sexy    p, s, hilo, maxchord;  bool    noflags, norests;{     (*pprintf)(pct7, DEFP, p, s, hilo, noflags, norests, maxchord);}void fgpart(p)  sexy    p;{     (*pprintf)(pct2, UDFP, p);}/* Tell Fran about all "new" parts in range given */dfalprts(from, to)  sexy    from, to;{     sexy p, s, sty, hilo, lownote;     for(p = from; p <= to; p++) {          s = partstaff(p, &sty, /* &lownote, */ &hilo);          dfpart(p, s, hilo, F, F, 0);     }}/* Likewise tell about staves in range */void dfalstvs(from, to)  sexy    from, to;{     sexy s;     for(s = from; s <= to; s++)          dfstaff(s, staves[s].clef_no, staves[s].staffY);}/* Update Fran's Key and Time Sigs AT BEGINNING of piece.*  Stops on 1st note/rest encountered, so later Sigs don't count. *//* 94/8/7 Fixed to, preserve current numer & denom if no TIMESIG found. */void dfsigs() {     Reg EVENT *ep;     keysig = 0;     for(ep = i2p(0); curind < nevents; ep = plusplus() ) {          if(ep->part)               break;          if(ep->show.INCTYPE == KEYSIG)               keysig = ep->show.KSN;          if(ep->show.INCTYPE == TIMESIG) {               numer = ep->show.TSNUMER;               denom = ep->show.TSDENOM;          }     }     (*pprintf)(pct2, SKS, keysig);     (*pprintf)(pct3, STS, numer, denom);}/* Tests for any type of Barline; == testbar(evp, FALSE) */bool anybar(evp)  EVENT *evp;{    return( (!evp->part) && (evp->show.INCTYPE <= FINE) );}/* Fix (transpose) a Part's .slots when its Clef is changed. */void fixslot(partn, oldclef, newclef)  sexy partn, oldclef, newclef;{     short diff;     if((oldclef==4) || (newclef==4))   /* Don't move to/from Perc staff */          return;     diff = clefs[oldclef].bnote - clefs[newclef].bnote;     if( !diff)          return;             /* save user's time */     (*ptranprt)(partn, diff, 0, nevents - 1);}/* tranpart() moved to bt.c *//****** Fcns to clear bars or bars of rests out of parts,* refill them later, join events *//* Simple re-init'er (inverse of tacet() ).*  Refills with largest rests possible between bars.*/void refill(start, end, partno)  Index   start, end;  sexy    partno;{     ubyte     durtemp, drmodtmp;     Index     ind, lind, tind;     bool      found;     Time      lst, now;     Deltime   dst;     Reg EVENT *evp;/* Find 1st barline on or after given 'start' */     for(evp = i2p(start); curind <= end; evp = plusplus() )          if(anybar(evp))               break;     ind = curind;/* Main loop.  Each cycle assumes events[ind]==barline. */     while(TRUE) {          lst = (*pfulltime)(ind);   /* of starting barline */          lind = ind++;          /* save starting barline */          found = FALSE;          for(evp = i2p(ind); curind <= end;  evp = plusplus() ) {               if(anybar(evp))                    break;    /* found next barline */               if(evp->part == partno)                     found = TRUE;      /* don't break; find barline */          }          if(curind > end)       /* never reached next barline */               return;          ind = curind;       /* save the next barline *//* If given partno no exist within bar, fill in rest(s).*  Fixed to go other direction, as it always shuda!*  Since regen() outputs smallest rests first,*    now sweeps from right to left. */          if( !found) {     /* Time between barline just found and previous barline */               if( !(dst = evp->startime - (Etime)lst))                    continue;      /* No meat between the bars */               (*pparse)(dst, 0, 0, REST);               do {                    dst = (*pregen)(&durtemp, &drmodtmp, TRUE);                    now = lst + (Time)dst;                    evp = i2p(tind = (*penter)(now, partno, REST));                    if(tind < 0) {                         (*palert)(" Not all bars ReFilled.", 0);                         tacet(lind,ind,partno,FALSE,FALSE); /* Undo this bar */                         return;                    }          /* enter() above did part, startime, and show.slot */                    evp->show.dur = durtemp;                    evp->show.durmod = drmodtmp;                    evp->show.artic = NORMAL;     /* 90/10/3+ */                    end++;    ind++;    /* moving targets */               } while(dst >0);          }     }} /* refill *//* Fcn to clear out, for a part, just those whole bars that are all rests,*  or all whole bars if 'clear' is set.*/void tacet(start, end, partno, clear, norests)  Index   start, end;  sexy    partno;   /* just the one part */  bool    clear,    /* include notes & small rests too; overrides norests */          norests;  /* delete all rests, period! */{     Index     tind;     bool      unrest;   /* means notes found within bar */     Reg EVENT *evp;/* 96/2/19 Special code for norests, no clear Instrs, vols, etc. */     if(norests && !clear) {          for(evp = i2p(start); curind <= end; ) {               if((evp->part == partno) && (evp->show.slot==REST)) {                    (*premove)(tind = curind);                    evp = i2p(tind);    /* restore after remove() */                    end--;              /* moving target */               }               else                    evp = plusplus();          }          return;     } /* end "norests" code *//* Find 1st barline including or after given start */     for(evp = i2p(start); curind <= end; evp = plusplus() )          if(anybar(evp))               break;/* Main Bar loop.  Each cycle assumes curind --> barline. */     while(TRUE) {          evp = plusplus();   /* step off starting barline */          tind = curind;      /* save 1st event after barline */          unrest = FALSE;/* Test for rests-only and find end of this bar */          for( ; curind <= end;  evp = plusplus()) {               if(anybar(evp))                    break;    /* found next barline */               if( (evp->part == partno) && (evp->show.slot != REST))                    unrest = TRUE;      /* don't break; find barline */          }          if(curind > end)       /* never reached next barline */               return;/* Clear this bar if no notes or 'clear' */          if(clear || !unrest) {               for(evp = i2p(tind); !anybar(evp); )               {                    if( (evp->part == partno)                       || (clear && !evp->part && (evp->show.PARTNO==partno)                        && ispwexpr(evp->show.INCTYPE) ) )                    {                         (*premove)(tind = curind);                         evp = i2p(tind);     /* restore after remove() */                         end--;         /* moving target */                    }                    else                         evp = plusplus();               }          }     } /* while */} /* tacet *//* Decrement all part #s above given #, including exprs for those #s */void decprt(p)  sexy p;{     sexy      pno;     Reg EVENT *evp;     for(evp = i2p(0); curind < nevents; evp = plusplus() )     {          pno = evp->part;          if(pno >= p)               evp->part--;          else if( !pno && ispwexpr(evp->show.INCTYPE)            && (evp->show.PARTNO >= p) )               evp->show.PARTNO--;     }} /* decprt() *//* eof ~Vm640/StaveSubs.c */