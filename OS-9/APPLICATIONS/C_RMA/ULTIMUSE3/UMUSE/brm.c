/* file BRM/RANDMEN.C    --4A--*  Random and Options Menus; Preferences Init file*/#define PREFFILE     "/DD/SYS/UM3.Init"/* #define ZBUG 1      /* secret debugger */#include <stdio.h>#include "wmuse.h"#include "mencodes.h"#include "screen.h"#include "windows.h"#include "wcodes.h"#include "cursors.h"#include "vmem.h"#include "macros.h"#include "soowee.h"char *index(), keymouse(), *gets(), i2hexc();sexy hexc2i();int  read(), write();void waitmouse();extern direct char *pct2, *pct7;/* Many of these are just for report() which is currently in titles.c */extern direct Index    godotind, undind, lftind, ritind, gbarind, gind;extern direct int     xyoff;extern direct short     xgoal, numer, denom, nbars;extern direct bool     compact, rfr_scr, rfr_bar, pldebug, sticky, doesff, automarg,     hires, left, midiser, midipak, readonly, pitcarry, snap,     beam, thick, halfstaf;extern EVENT     undevent, zevent;extern direct sexy     forergb, backrgb,     nparts, nstaves,     curcurse,     broke,     velo,          /* MIDI note attack velocity */     transp,        /* # semitones to shift play */     secmin;        /* Global inverse tempo */extern direct ubyte     printype;extern sexy    pickpart;extern bool    /* Filters; NOT direct! */     pickrest, picknote, pickplus, pickflag,     pickupper, picklower, pickmid;extern ubyte     levels[], grafxes[], grafyes[];extern char     filename[];extern PART    parts[];bool inrect(), yesno(), newrgb();       /* pre-decl */void undebug(), filtmen(), fltprtmen(); /* pre-decl *//* Demo/Test routine to connect all the note bodies*  of each Part with nearly-horizontal lines,*  to test KWindows Line syscall, preparatory to Beaming */partline(dorests)  bool dorests; {     int       prt, lastx, lasty;     int       x, y;     Reg EVENT *evp;          setfore(1);    /* else Kev draws bkgrnd lines! */     for(prt = 1; prt <= nparts; prt++) {          lastx = lasty = 0;            for(evp = i2p(lftind); curind <= ritind; evp = plusplus() ) {               if(evp->part != prt)                    continue;               if( !dorests && (evp->show.slot == REST))                    continue;               x = grafxes[curind - xyoff] << 3;               y = grafyes[curind - xyoff] & 255;               if(lastx > 0)                    line(lastx + 12, lasty, x - 2, y);               lastx = x;     lasty = y;          }     }} /* partline() *//* Inclusive within-rectangle test */bool inrect(qx,qy, x1,y1, x2,y2)  sexy    qx,qy, x1,y1, x2,y2;{     return((qx>=x1) && (qx<=x2) && (qy>=y1) && (qy<=y2));}/* Fcn to return a char, either typed or moused on a PushButton Menu.*  If clicked off menu, return \n but no mouse x,y data. */char menukey(chars, lcol, cwid, topy, boty)  char    *chars;   /* string of char-per-menu-button */  int     lcol, cwid, topy, boty;  /* menu coords & size */{     int  mx, my, i;     char ch;     ch = keymouse(&mx, &my);     if(ch)          return(ch);     mx >>= 3;/*     if(mx < lcol)           mx = lcol - 1;     if(mx > (lcol + cwid))          mx = lcol + cwid + 1;     if(my > topy)          my = topy + 1;     if(my < boty)          my = boty - 1;*/     if(inrect(mx,my, lcol,boty, lcol+cwid-1, topy))     {          i = (topy - TVBORD - my) / PB_VPITCH;          return( chars[i] );     }     else          return('\n');       /* Off menu */} /* menukey() */randmen(given)   char    given;{    char buff[BUFFSIZE];     int  n, oldcurse;     Reg EVENT *ep;     oldcurse = curcurse;     curset(CBUTTON);/* Big Loop:  Clear given to recycle; leave non-null to exit */     do {                if(!given) {               menu(MEN_RAND);     /* show the Push_Button Menu, */               given = menukey("pwksnufh9?rq",                  RAND_LCOL, RAND_CWID, RAND_TOPY, RAND_BOTY);               wkill();            /*   and remove the Menu. */          }          switch(given)          {/* QUIT now handled by BREAK interrupt routine *//* If this returns at all, keep going! */          case 'q':               breaker(2);    /* Fake a BREAK */               break;          case 'r':               if( !yesno("\n Restart Umuse? ")) {                    break;               }               return(TRUE);   /* makes main() restart */          case 'f':          case 'F':      /* from main score screen */          case '#':      /* ditto */               filtmen();               break;          case 'h':               Showall('p');               break;          case 'k':               Kpmain(); /* keypad editor */               break;          case 'L': /* connect part notes, skipping rests */          case 'R': /* include rests */               partline(given == 'R');               break;          case '9':          case ':':               /* text(); */               wcreate(1, HM1-1, 78, 25, FALSE, WSDOUBLE);               printf("\n(ENTER blank line to leave OS-9)\n\n");               for(;;) {                    printf("OS9: ");                    if( ! *gets(buff))                         break;                    if(n = system(buff))                         printf("ERROR %3d.\n", n & 255);               }               wkill();  /* grafix(); */               rfr_bar = rfr_scr = 1;               break;          case '?':          case '/':               report();               break;          case 'p':        /* Play whole piece */          case 'w':        /* Play from left edge of Window */               if(pldebug) {                    text();                    printf("\014 Hit BREAK to stop,\n or ^C to stop and go there.\n");               }               play( (given == 'w') ? lftind : 0, nevents - 1);               if(rfr_scr)         /* ^C, back to score NOW! */                    wkill();  /* grafix(); */               else if(pldebug) {  /* Done or BREAK-- let study trace */                    putchar('\n');                    hitenter();                    wkill();  /* grafix(); */                    /* given = '\0';    /* force Randmenu recycle */               }               break;          case 3:   /* BREAK and CTR-C after Play */          case 5:               break;    /* no beeps */          case 'u':        /* Undo 'X' deletion; upgraded 96-2-19 */               if(undind >=0) {          /* Was a Flagship note, just changed?  Yes, "n = ". */                    if( (n = undevent.part) && !(parts[n].philo & NOFLAG) )                         ep = i2p(undind);                    else      /* Was truly deleted; re-insert */                         ep = makroom(undind);                    strevent(ep, &undevent);                    undind = -1;           /* use it up */                    rfr_scr = TRUE;               }               else {                    alert("\nToo late!\n", 0);               }               break;          case 's':               rfr_scr = rfr_bar = TRUE;               break;          case 'n':        /* Re-Number barlines */               barenum(rfr_scr = TRUE);               break;          case '\n':     /* menukey() returns ENTER as-is */               break;#ifdef ZBUG/* Undocumented DeBugger */          case 'D':               undebug();               break;#endif/* Not-yet-implemented features */          case 'v':               alert("Not yet.\n", 0);          /* fall thru */          default:       /* Razz & recycle */               bell();               given = '\0';  /* make it read a new one */          } /* switch */     /* "breaks" above come here */     } while( !given);/*   waitmouse(); */     curset(oldcurse);     return(FALSE);      /* TRUE wud restart Umuse */} /* randmen() *//* Finder-Filter (Pick-options) Menu 95/5/30 */void filtmen() {     char     buff[BUFFSIZE];     char     ch;     sexy     n, oldcurse;     oldcurse = curcurse;     curset(CBUTTON);     for( ; ;) {          menu(MEN_FILT);          printf("%d%d%d%d%d%d%d%d",            picknote, pickrest, !!pickpart + 1, pickflag, pickplus,            pickupper, pickmid, picklower);          ch = menukey(" enraofc uml",            FILT_LCOL, FILT_CWID, FILT_TOPY, FILT_BOTY);          wkill();          switch(ch)          {          case '\n':               curset(oldcurse);               return;          case 'e': /* Everything */               pickpart = 0;               picknote = pickrest = pickflag = pickplus                 = pickupper = pickmid = picklower = TRUE;               break;     /* Keep at least one of pickrest or picknote TRUE */          case 'n':     /* Notes OK */               if(picknote) {                    picknote = FALSE;                    pickrest = TRUE;               }               else                    picknote = TRUE;                    break;                    case 'r':     /* Rests */               if(pickrest) {                    picknote = TRUE;                    pickrest = FALSE;               }               else                    pickrest = TRUE;               break;          case 'a':     /* All parts active */               pickpart = 0;               break;          case 'o':     /* Only One part OK */               fltprtmen();     /* may set pickpart global */               break;     /* Keep at least one of the next two turned on */          case 'f':     /* Flagship parts OK */               pickplus |= !(pickflag = !pickflag);               break;                    case 'p':     /* Plus-parts OK */          case 'c':     /* aka Clones */          case '+':          case '=':     /* small '+' */               pickflag |= !(pickplus = !pickplus);               break;          case 'u':               pickupper = !pickupper;               break;          case 'm':               pickmid = !pickmid;               break;          case 'l':               picklower = !picklower;               break;          default:               bell();          }     }} /* filtmen() */void fltprtmen() {     char     buff[2];     sexy     oldcurse;     char     ch;     oldcurse = curcurse;     curset(CBUTTON);     menu(MEN_FPART);     if( (ch = i2hexc(pickpart)) >= 'A')          ch += ('a' - 'A');          /* force lower case, range 0, 1 - 16 */     putchar(ch);   /* ?? Need \n or \0 after?? */     ch = menukey("123456789abcdefg",       FPART_LCOL, FPART_CWID, FPART_TOPY, FPART_BOTY);     wkill();     if(ch != '\n') {          pickpart = hexc2i(ch);     }} /* fltprtmen() */void optmen(given)  char    given;{     int  n, oldcurse;     oldcurse = curcurse;     curset(CBUTTON);/* Clear given to recycle; leave non-null to exit */     do {          if( !given) {               menu(MEN_OPTIONS);               printf("%d%d%d%d%d%d%d%d%d%d",                 pitcarry, snap, sticky, halfstaf, compact,                beam, thick, pldebug, hires, left);               given = menukey("naisgcbtpdhlfr?\n",                  OPTS_LCOL, OPTS_CWID, OPTS_TOPY, OPTS_BOTY);               wkill();          }          switch(given) {          case '\n':               break;    /* and return */          case 'g': /* Gray (halftone) staves */               halfstaf = !halfstaf;               goto rfrl;          case 'b':               beam = !beam;               goto rfrl;          case 't':               if(thick = !thick)  /* '=' */                    beam = TRUE;               goto rfrl;          case 'n':      /* Note-carryover mode */               pitcarry = !pitcarry;               given = '\0';  /* recycle */               break;          case 'a': /* snAp magnetic cursors */               snap = !snap;               given = '\0';               break;          case 'i': /* stIcky Instr cursors */               sticky = !sticky;               given = '\0';               break;          case 'p': /* Printer type */               printset();               break;/*  Fore & Background Palette setters */          case 's': /* Screen colors */               rgbmen();               given = '\0';  /* recycle */               break;          case 'f':      /* File away the user's preferences */          case 'r':      /* Restore modes from file */               prefio(given);               break;          case 'c':               compact = !compact;rfrl:          rfr_scr = TRUE;               given = '\0';  /* recycle on Bool boxes */               break;          case 'd': /* Debug (trace) play */               pldebug = !pldebug;               given = '\0';               break;          case 'l': /* Left mouse port */               left = !left;               setmouse();               given = '\0';               break;          case 'h': /* Hi Res mouse */               hires = !hires;               setmouse();               given = '\0';               break;          case '?':          case '/':               report();               break;          default:               bell();          case 'o':      /* 1st call, no beep */               given = '\0';  /* recycle */          } /* switch */     } while( !given);     curset(oldcurse);} /* optmen() *//* Get printer model from user.  Called from dump() outside too */void printset() {     int  oldcurse;     char given;     oldcurse = curcurse;     /* for calls from outside opts menu */     curset(CBUTTON);     for(;;) {      /* Recycle on new printer or error */          menu(MEN_PRTR);          printf("%c%d%d", '1' + printype, doesff, automarg);          given = menukey("\n01234567ft\n",            PRTR_LCOL, PRTR_CWID, PRTR_TOPY, PRTR_BOTY);          wkill();          if((given >= '0') && (given <= '7')) {               printype = given - '0';               if((printype <=3) || (printype==7)) /* Tandy, Gemini */                    doesff = automarg = FALSE;               else                    doesff = TRUE;          }          else if(given == '\n')        /* leave happy */               break;          else if(given=='f')               doesff = !doesff;          else if(given=='t')               automarg = !automarg;          else               bell();   /* error */     }     curset(oldcurse);} /* printset() *//* Read/Write user's preferences to/from file */prefio(what)  char    what;     /* 'r' or 'f' */{     int       chan;     Reg int   (*disk)();     if(what == 'f') {   /* File (write) user prefs */          disk = write;          if((chan = creat(PREFFILE, 0x0B)) < 2) {               alert("\007 Can't create file!");               return;          }     }     else {              /* Restore (read) from file */          disk = read;          if((chan = open(PREFFILE, 1)) < 2)               return;   /* Don't complain */     }/* No. of bytes must match bdp.c !!!*  Don't try computing it with difference between pointers;*    Microware has a C Compiler Bug for all occasions! */     (*disk)(chan, &forergb, 25);  /* was 20 97/4/3 */     if(what == 'r') {          pal(1, forergb);          pal(0, backrgb);          setmouse();     }     close(chan);}/* Menu to show, get, and set Fore & Back palettes.*  If you set back==fore and blank out screen,*    just ENTER or click way off to exit & restore old colors. */rgbmen() {     sexy oldcurse, foretemp, backtemp, *other;     bool infore = TRUE;     char *letters, *cp, ch = '\0';     Reg sexy  *ground;     letters = "bgrBGR";     oldcurse = curcurse;     curset(CBUTTON);     foretemp = forergb;     backtemp = backrgb;     do {      /* while ch != 0 */          if(infore) {               ground = &foretemp;               other = &backtemp;          }          else {               ground = &backtemp;               other = &foretemp;          }          menu(MEN_CLRS);/* Translate RGB bitmap into bool button boxes */          printf(pct7, '0'+2-infore,            '0'+(*ground & 4), '0'+(*ground & 32), '0'+(*ground & 2),            '0'+(*ground & 16), '0'+(*ground & 1), '0'+(*ground & 8));          ch = menukey("zofarRgGbB\n", CLRS_LCOL, CLRS_CWID,            CLRS_TOPY, CLRS_BOTY);          wkill();          switch(ch) {          case 'k':          case 'o':     /* OK, exit and Keep new colors */               forergb = foretemp;               backrgb = backtemp;               ch = 0;               break;          case '\n':     /* Exit but reject changes, keep old colors */               ch = 0;               pal(1, forergb);               pal(0, backrgb);               break;          case 'f': /* Foreground radio slider */               infore = TRUE;               break;          case 'a': /* bAckground radio slider */               infore = FALSE;               break;          default:  /* Try for a rRgGbB */               if( (cp = index(letters, ch)) ) {                    *ground ^= (1 << (cp - letters));               }               else                    bell();   /* bad char */               pal(infore, *ground);          }                    } while(ch);     curset(oldcurse);} /* rgbmen() *//* Fcn to make text windows into mousable menus,*  with arrow cursor except Inverts "hot" text.*  Multiple columns, and upper part of menu can be "cold."*  Returns 0 if clicked outside hot area (if permitted),*    else row*ncols + col, where row is ORG 0 & col is ORG 1.*  But if a char is typed, returns MINUS the char (yeah, weird).*/#define Tinvert(x,y) Invert(x, y-1, x+colwid-2, y+5)int textmenu(leftxc, topy, colwid, ncols, topline, nlines, outok)  int     topy;     /* same as for wcreate() */  sexy    leftxc,   /* ditto */          colwid,   /* chars width of ONE COLUMN (newspaper-wise) */          ncols,    /* # of columns, usually 1, 2, or 3 */          topline,  /* index of 1st "hot" line, from 0 */                    /* == no. of upper cold/dead lines to skip */          nlines;   /* no. of hot lines */  bool    outok;    /* Exit if clicked outside hot area of window */{     sexy savecurse,          mxc, ritxc, row, retval,          linex, oldlinex,    /* left char of text line */          colind;   /* 0, 1, or 2 */     int  mx, oldmx, boty, my, oldmy,          liney, oldliney;    /* Ruler Line (near bottom) of text line */     bool fire, inside;     savecurse = curcurse;/* Special test for Instrmen() */     if((curcurse !=CXOUT) && (curcurse !=CPARTCOPY) && (curcurse !=CPARTFULL))          curset(CARROW);/*   mouce(&oldmx, &oldmy); */     oldmx = oldmy = 0;     waitmouse();   /* no args */     cursor(oldmx, oldmy);    /* draw, to get erased entering loop *//* Figure bounds of "hot" rectangle */     topy -= topline * 7 + 4; /* was 2 */     boty = topy - 7 * nlines + 2; /* was 4 */     ritxc = leftxc + ncols * colwid - 2;     oldliney = -1;     /* assume outside for now */     retval = 0;/* Main Loop */     for(; ; ) {     /* Read mouse */          fire = kmouse(&mx, &my);          mxc = mx >> 3;          if(inside = inrect(mxc, my, leftxc, boty, ritxc, topy)) {     /* Figure line and column for later use */               row = (topy - my) / 7;               liney = topy - 7 * row - 5; /* Quantized *//*             if(liney < 0)  liney = 0; */               colind = (mxc - leftxc) / colwid;               linex = leftxc + colind * colwid;          }     /* If pressed, break loop or hang */          if(fire) {               if(fire > 0) { /* typed char, not button */                    retval = -fire;     /* return negative chars */                    break;               }               if(inside || outok)                    break;               else {                    waitmouse();   /* freezes cursor */                    continue;               }          }     /* No button.  Any motion?  else continue */          if((mx == oldmx) && (my == oldmy))               continue;          cursor(oldmx, oldmy);          cursor(oldmx=mx, oldmy=my);     /* Mouse now inside or outside hot area? */          if( !inside) {      /* Now outside */               if(oldliney >= 0) {     /* But was inside */                    Tinvert(oldlinex, oldliney);  /* de-invert old */                    oldliney = -1;      /* Mark specially as outside */               }          }          else {    /* now inside */     /* Skip unless Line & column different (or was outside?) */               if((liney==oldliney) && (linex==oldlinex))                    continue;               if(oldliney >= 0)   /* Not just arrived from outside */                    Tinvert(oldlinex, oldliney);          /* Invert latest inside and update */               Tinvert(linex, liney);   /* Macro, no old=new jazz! */               oldliney = liney;               oldlinex = linex;          } /* if now inside */     } /* main loop *//* Fired or typed.  Inside or out? */     cursor(oldmx, oldmy);    /* erase? */     curset(savecurse);     if(inside) {          if(oldliney >= 0)               Tinvert(oldlinex, oldliney);  /* de-invert */          if( !retval)               retval = row * ncols + colind + 1;     }     /* Outside.  Know it's OK to quit */     return(retval);     /* Zero, unless a char was typed */} /* textmenu() */#ifdef ZBUG/*  All commands followed by ENTER:* On entry, index is init'ed to godotind,*   so use G search menu to find interestin' stuff!* Use '.' to reverse-assign current to godotind.* i NUMBER is Index; display that event* ENTER alone means Index++* -  means Index--* *  means Index = nevents-1* v  dump VirtMem variables*/undebug() {     char      buff[33];     Index     ind;     register EVENT *evp;     text();     ind = godotind;     for(;;) {          if(ind > nevents-1)               ind = nevents-1;          else if(ind < 0)               ind = 0;          evp = i2p(ind);          printf(" Index %d, Part %d, Stime %u.\n",            ind, evp->part, evp->startime);          printf("   Dur Mod Slot Pit Art\n");          printf("   %3d %3d %3d  %3d %3d\n",            evp->show.dur, evp->show.durmod, evp->show.slot,            evp->show.pitmod, evp->show.artic);          printf(":");   flush();          gets(buff);          switch( *buff) {          case 'q':               wkill();               return;          case '\n':          case '\0':               ind++;               break;          case '-':               ind--;               break;          case '*':               ind = nevents - 1;               break;          case '.':               godotind = ind;               break;          case 'i':          case 'n':               ind = atoi(buff + 1);               break;          case 'v':               printf("Pg %d, CrInd %d, DtBs $%04x\n",                 curpage, curind, (unsigned)database);               printf("CrEvp $%04x, CrTop $%04x, NMP %d.\n",                 curevp, curptop, nmpages);               break;/* Later add zappers to patch */          default:               bell();                   } /* switch */     } /* for */} /* undebug */#endif/* eof brm/randmen.c */