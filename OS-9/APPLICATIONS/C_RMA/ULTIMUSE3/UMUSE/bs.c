/* file ~VM640/BSUBS.C   -5-   Various routines for UltiMuse:* cod2raw(), next(), find(), remove(), enter(), makroom(),  barenum(),* fulltime(), figurst(),* & many other odd jobs utilities.* 960303 Place() family --> BPL.C; Marker-insert to BM.C*/#include "wmuse.h"#include "keys.h"   /* for find() */#include <stdio.h>#include "vmem.h"#include "wmenu.h"#include "macros.h"#include "cursors.h"/* None of these arrays is R/O: */extern STAFF staves[NSTAVES];extern PART  parts[NPARTS + 1]; /* Parts are ORG 1, not 0! *//* This IS Read-Only! */extern CLEF  clefs[];extern direct short     xyoff, nparts,     numer, denom, nbars, nstaves;extern direct Index      lftind, ritind;extern Index   lastclik;extern STAFF   staves[];extern ubyte   grafxes[], grafyes[], chans[];extern direct bool     rfr_rep, rfr_scr, aborted, pitcarry;extern sexy     pickpart;extern bool    /* Filters -- not direct */     pickrest, picknote, pickplus, pickflag,     pickupper, picklower, pickmid;extern direct Deltime     dendur;extern direct sexy     curcurse;extern short durtable[4];extern bool    partens[];/* Some exter fncs, some pre-decs: */bool      mouce(), anybar(), place(), markin(), doit();Time      fulltime(), figurst();Index     finder(), enter(), next(), pnext();Deltime   cod2raw();bool ispwexpr(slt)  sexy    slt;{     return( (slt==INSTR) || (slt==LEVEL) || (slt==MCHOP)       || (slt==IPEVT) || (slt==TPEVT) );}/********** Convert dur & durmod codes to raw durations, using small table.* Raw durations of Breve: straight, dotted, double-dot, triplet.*/Deltime cod2raw(cdur, cdurmod)  sexy    cdur, cdurmod;      /* cdur==0-7, cdurmod==0-3 */{     return(durtable[cdurmod] >> cdur);}/********* Two fcns;* Find the next event of same Part as the one indexed (or part given);* return its index or BADIX (-1 ) if failure (out of events)*/Index pnext(ind, part)   /* skips ind, starts looking at ind+1 */  Index   ind;  sexy    part;{     Reg EVENT *ep;     if(ind >= nevents)          return(BADIX);     for(ep = i2p(ind + 1); curind < nevents; ep = plusplus() )          if(part == ep->part)               return(curind);     return(BADIX);}Index next(ind)  Index   ind;{     return(pnext(ind, i2p(ind)->part));}/* Given Y, find what staff (if any) mouse is in, 0 -- (nstaves-1)*  If none, return nstaves. */sexy findstaff(y)  int     y;{     int  s, staffy;     for(s = 0; s < nstaves; s++) {          staffy = Ystaff(s);      /* bottom line */          if( (y >= staffy-2) && (y <= (staffy + 18)) )               break;     }     return(s);} /* findstaff() */ /******* * Find event (if any) under Mouse Cursor. * Return index of selected note, if any; else return BADIX (-1). * Returns 1st item found, as sorted in Events[]. * 88/3/20 Extended to return 2nd, 3rd, or 4th choice *   if SHIFT and/or CTRL keys held, to help with overlapping items. *   Always returns last item found, if any.*/#define LTOL 4      /* Tolerance to Left of note */#define RTOL 12     /* and to Right */#define VTOL 3      /* and above & below (was 4) */Index find(mx, my, keybits, lib)  short   mx, my;   /* mouse cursor coords */  ubyte   keybits;  bool    lib;      /* be tolerant in Y-axis */{     Index     thisind,               fromind,               lastgood;     lastgood = BADIX;           /* in case nothing found */     fromind = lftind;        /* left border of screen */     keybits &= (SHIFT | CTRL);     for( ; keybits >= 0; keybits--) {          thisind = finder(mx, my, fromind, lib);          if(thisind < 0)               break;          fromind = (lastgood = thisind) + 1;     }     if(lastgood != BADIX)          lastclik = lastgood;     /* save the spot for KPedit */     return(lastgood);} /* find() *//* The real work of the Finder system */Index finder(mx, my, stind, lib)  sexy    mx, my;   /* mouse cursor loca */  Index   stind;    /* start from here */  bool    lib;      /* be tolerant in Y-axis */{     sexy      dx, dy, y, yfudge=0;     sexy      s, hilo;     Index     mind;     sexy      type;     Reg EVENT *ep;     for(ep = i2p(mind = stind); curind <= ritind;  ep = plusplus() ) {          dx = (8 * grafxes[curind - xyoff]) - mx;          if(dx <= -RTOL)     /* not near cursor yet */               continue;          if(dx >= LTOL)      /* past cursor, fail */               return(BADIX);/* DX is within limits.  Try DY: *//* Inclusions (except Partwise) need special Y tests */          type = ep->show.INCTYPE;     /* also slot for notes/rests */          if( !ep->part && !ispwexpr(type))          {      /* All-parts items must be in top margin of screen */               if(  (type==NUTEMPO) || (type==GENVOL) || (type==CLOCKON)                 || (type==CRESC)   || (type==ACCEL) || (type==ACCENT)                 || (type==ISEVT) || (type==TSEVT) || (type==LABEL) )               {                    if(my >= (SCORTOP - 9) )                         return(curind);               }     /* Some inclusions appear in every staff */               else            /* Must be within a staff */                    if( (s = findstaff(my)) < nstaves)                         return(curind);          } /* non-partwise Inclusions */          else {          /* Notes/rests & partwise inclusions */               dy = (grafyes[curind - xyoff] & 255) - my;               if( !lib)                    yfudge = 0;               else if(ep->part && (type==REST))                    yfudge = (ep->show.dur==1) ? 3 : 1;               else if( !ep->part && ispwexpr(type))                    yfudge = 2;               dy += yfudge;               if( (dy==0) || (lib && (dy < VTOL) && (dy > -VTOL)) ) {                    if( !ep->part)                         return(curind);     /* Good note/rest, but does it pass new Filter?  95/5/30 */     /* Cheat by knowing INCTYPE == slot field */                    hilo = parts[ep->part].philo;                    if(                      ( !pickpart || (pickpart == ep->part))                      &&                      ( ((type==REST) && pickrest)                        || ((type !=REST)&& picknote) )                      &&                      ( ((hilo & NOFLAG) && pickplus)                        || ( !(hilo & NOFLAG) && pickflag) )                      &&                      (    ((hilo & UPPER) && pickupper)                        || ((hilo & LOWER) && picklower)                        || ( !(hilo & (UPPER | LOWER)) && pickmid)                      )                      )                         return(curind);                    }          } /* note/rest | partwise expr */     } /* for *//* Fell thru loop; tried entire screen; fail */     return(BADIX);} /* finder() *//********** Remove the indexed event from the array and downshift from above*  to fill in the gap.  Return the given index, or BADIX if invalid.* Uses lots of "private" knowledge of Virt Mem paging system!* Many "cheats" done here; DO NOT TRY AT HOME!*/Index remove(ind)  Index   ind;{     EVENT     carryout, carryin;     EVENT     *topevp;     int       page, rpage, toppage;     Reg EVENT *evp;     if((ind < 0) || (ind >= nevents))          return(BADIX);      /* slot was invalid */     nevents--;     evp = i2p(ind);     rpage = curpage;    /* page of removed event *//* Bubble down in-use portion of TOP page first, saving its 1st event */     topevp = i2p(nevents);    /* last event */     toppage = curpage;/* Special case if all action is on top page, leave early */     if(toppage == rpage) {          evsdn1(evp, (char *)topevp - (char *)evp );          return(ind);     }/* Nope, bubble all of top page into carry */     strevent(&carryout, database);     /* top page is curpage */     evsdn1(database, (char *)topevp - (char *)database );/* Bubble down each fully-used intermediate page, with "carry" into top */     for(page = toppage - 1; page > rpage; page--) {          pswap(page);          strevent(&carryin, &carryout);          strevent(&carryout, database);          evsdn1(database, (PNEVENTS-1)*SEVENT );          strevent(curptop, &carryin);     }/* Finally, bubble down upper part of page where removal was done */     evp = i2p(ind);     /* repeat for safety, or just pswap(rpage) */     evsdn1(evp, (char *)curptop - (char *)evp );     strevent(curptop, &carryout);          giveback();    /* 1 in 1020 odds we'll get lucky */     return(ind);} /* remove() *//********** Given an index, make room in that slot by bubbling* rest of array up.  Return index's EVENT *PTR.* Uses internal knowledge and tricks.* Auto'ly creates new page if needed.*/EVENT *makroom(ind)      /* yes, EVENT * */  Index   ind;{     EVENT     carryin, carryout, *topevp;     Etime     st;     sexy      inspage, toppage, page;     Reg EVENT *evp;     if(ind < 0)          ind = 0;     if(ind > nevents)         /* More than 1 beyond current end */          ind = nevents;     if(nevents >= NEVENTS)          return(NULL);   /* no can do *//* 1 in 1020 times, the following will create a new page */     if( !(topevp = i2p(nevents)))   /* just beyond current score */          return(NULL);  /* out of pages */     toppage = curpage;/* Bubble up upper portion of inspage, the page taking the insertion */     evp = i2p(ind);     inspage = curpage;/* Special case if insert is on top page; leave work early */     if(inspage == toppage) {          evsup1(evp, (char *)topevp - (char *)evp );     }/* Nope, bubble up inspage (lowest page involved) */     else {          strevent(&carryout, curptop);          evsup1(evp, (char *)curptop - (char *)evp );     /* Bubble up all intermediate pages, if any */          for(page = inspage + 1; page < toppage; page++) {               pswap(page);               strevent(&carryin, &carryout);               strevent(&carryout, curptop);               evsup1(database, (PNEVENTS-1)*SEVENT );               strevent(database, &carryin);          }     /* Bubble up in-use portion of top page */          topevp = i2p(nevents);        /* again for safety */          evsup1(database, (char *)topevp - (char *)database);          strevent(database, &carryout);     }/* Inserted item normally inherits startime of slot's previous occupant.*  Many callers exploit this fact.*  But if new item is very last event, inherits garbage*    from brand-new slot.  So take startime from previous last event.*/     if(ind == nevents) {        /* (old nevents) at very end */          st = (Etime) figurst(nevents - 1);          i2p(nevents)->startime = st;  /* in case figurst() pswapped */     }     nevents++;     return(i2p(ind));}/************* Given Index, find full Long time */Time fulltime(ix)  Index   ix;{     Time      fullval;  /* Long */     Etime     lastime;     Reg EVENT *evp;     evp = i2p(ix);     *((Etime *)&fullval+1) = lastime = evp->startime;     *((short *)&fullval) = 0;     for( ; curind >= 0; evp = decdec()) {   /* Does NOT check index 0 */          if(evp->startime > lastime) {     /* rollover */               (*((short *) &fullval))++;          }          lastime = evp->startime;     }     i2p(ix);            /* restore for careless callers */     return(fullval);} /* fulltime() *//********  Figure the startime of the event that would follow the*  given event.  Use to get startimes for events (usually*  inclusions) inserted at the very end of score,*  which inherit garbage instead of previous occupant's "warm bed" startime.*  Works anywhere in events[] though.*/Time figurst(ind)  Index   ind;{     Reg EVENT *evp;     Time      st;     if(ind < 0)          return(0);     st = fulltime(ind);     evp = i2p(ind);     /* for self and maybe a careless caller */     if(evp->part)       /* Note/Rest, so it occupies Time */          st += (Time) cod2raw(evp->show.dur, evp->show.durmod);     return(st);}/******************************* Find proper time slot to insert a new event, and make room;*   return index of the new slot.  Push up rest of array.* Also sorts by Part, so Barlines etc. come first.* Finally breaks ties using 'myslot' INCTYPE info,*   so in Chords the lowest note comes first, etc.* 90/3/4 DOES insert time, voice, and myslot.* 91/9/8 Inclusions can skip over Markers* Returns index of BADIX (not FALSE) if no more room.*/Index enter(instime, voice, myslot)  Time    instime;  /* 32-bit Fulltime! */  sexy    voice;    /* i.e., part */  sexy    myslot;   /* usually INCTYPE */  {     Index     s;     Time      tyme;     Etime     lastime, thistime;     Reg EVENT *ep;/* Find event whose startime >= instime *//* Loop exits with curind == nevents if not satisfied */     tyme = 0L;     lastime = 0;     for(ep = i2p(0);  curind < nevents;  ep = plusplus() ) {          thistime = ep->startime;          if(thistime < lastime)   /* UNSIGNED comparison */               (*((short *)&tyme))++;    /* Rollover */          *((Etime *)&tyme + 1) = lastime = thistime;          if(instime > tyme)  /* not there yet */               continue;          if(instime < tyme)  /* just passed it, good */               break;     /* instime == tyme; break tie */          if(voice < ep->part)               break;          if( (voice == ep->part) && (myslot < ep->show.INCTYPE)            && (ep->show.INCTYPE != LMARK) && (ep->show.INCTYPE != RMARK) )               break;    /* else keep looping */     }/* Open slot at curind by bubbling rest of array up *//* Also does room-test and nevents++ */     if(!(ep = makroom(s = curind)))    /* makroom is (EVENT *) */          return(BADIX);     ep->part = voice;     ep->startime = (Etime)instime;     ep->show.slot = myslot;     return(s);} /* enter() *//* Check score for validity.  All sorts of tests can be run.*  For now, just check for negative or backwards-moving startimes.*  Returns after first error, so needn't BREAK Umuse.*/bool audit() {     Reg EVENT *evp;     Etime     last, new;     Deltime   temp;     last = 0;     for(evp = i2p(0); curind < nevents; evp = plusplus() ) {          new = evp->startime;          if( (Deltime)(temp = new - last) < 0) {               alert("\007Audit: Index has Bad Startime, after\n",                 3, curind, new, last);               return(FALSE);          }          else               last = new;     }     return(TRUE);} /* audit() *//*****************************  Re-number barlines from the start to finish.   87/6/5*  First barline is #1 unless 1st bar is "pickups",*  then barline is #0.*  Consecutive barlines/inclusions with no difference*    in startime are given the same number.*/void barenum(doit)  bool    doit;     /* rewrite .barnums; else just count */{     short     barno;     Etime     lastime, thistime;     Reg EVENT *evp;/* Don't count a "pickup" measure as a full bar; call it #0.*  Find inital value for barno; -1 or 0 (for 0 or 1);*  is 2nd barline late enuf to end a full measure?*/     for(evp = i2p(1); curind < nevents; evp = plusplus() )          if(anybar(evp))               break;     findts(curind);        /* Get *initial* time sig! */     barno = (evp->startime >= (Etime)(numer * dendur));/* OK, Renumber them all */     lastime = 0;     for(evp = i2p(0); curind < nevents; evp = plusplus() ) {          if(anybar(evp)) {               thistime = evp->startime;               barno += (thistime != lastime);               if(doit)                    EvBarNo(evp) = barno;               lastime = thistime;      /* used it up */          }     }     nbars = barno - 1;     /* update global info */     /* audit();  /* TEMPORARY for testing from keyboard */}/* Search backwards from start of play for time sig;*  put it in globals numer & denom.*  Call timesig() to update tripler.*  If no timesig found, just leave globals as-are.*  Also called from barenum() in bs.c*/void findts(ind)  Index   ind;      /* first event played */{     register EVENT *eptr;     for(eptr = i2p(ind); curind >= 0; eptr = decdec() ) {          if( !(eptr->part) && (eptr->show.INCTYPE == TIMESIG)) {               numer = eptr->show.TSNUMER;               denom = eptr->show.TSDENOM;               break;          }     }     timesig();} /* findts() *//* Parnasian interface; given Part No., returns the other items */sexy partstaff(part, sty, lownote, hilo)    /* Returns staff # */  sexy  part;       /* INput; rest are OUTputs: */  short *sty;       /* staffY */  sexy  *lownote;   /* clef.bnote */  sexy  *hilo;      /* indicators */{    sexy            istaff;    register STAFF  *stptr;    if((part < 1) || (part > nparts)) {        alert("Partstaff: Bad Part=",1, part);        part = nparts;     }    istaff = parts[part].pstaff;    *hilo =  parts[part].philo;    *sty =  (stptr = staves + istaff) -> staffY;    *lownote = clefs[stptr->clef_no].bnote;    return(istaff);}/* eof ~Vm640/BSUBS.C */