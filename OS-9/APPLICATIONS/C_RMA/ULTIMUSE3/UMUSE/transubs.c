/* file TRANSUBS.C  Needed to dodge RLink bug *//* 93/4/20 Now holds many Fran subrs for blockmen() */#include "wmuse.h"#include "vmem.h"#include "wcodes.h"#include "windows.h"#define NL '\n'/* format strings for Fran'ing thru the pipe */extern direct char    *pct2, *pct3, *pct4, *pct5, *pct5, *pct6, *pct7,    *pctn1, *pctn2, *pctn3, *pctn4;extern direct sexy     nparts, nstaves, keysig, curcurse;extern STAFF staves[NSTAVES];extern PART  parts[NPARTS + 1]; /* Parts are ORG 1, not 0! *//* Botnotes are White keys above 16' C==01.  Mid C ==22. */extern CLEF  clefs[];extern int     (*pprintf)();extern void    (*pflush)();/* Parnasian interface to Staff; given Part No., returns the other items *//* This is a Stripped-down version of partstaff() for transpose only! *//* NOTE: Some very terse, compact, intellectual C programming*    has been unraveled in this version to avoid an RLink bug!*    WHAT?  A linker bug?  Yes.  Ask someone from Haiti. */sexy transtaff(prt, lownote, hilo)     /* add transposing data later */  sexy  prt;        /* INput; rest are OUTputs: */  sexy  *lownote;   /* clef.bnote */  sexy  *hilo;      /* indicators */{     sexy      istaff;     Reg PART  *ptptr;     if((prt < 1) || (prt > nparts)) {          prt = nparts;      }/*   *hilo = (ptptr = parts + prt) -> philo; */     ptptr = parts + prt;     *hilo = ptptr->philo;/* Next stmt poisons RLink, even by itself */     istaff = ptptr -> pstaff;/* So can this one, all by itself */     *lownote = clefs[(staves + istaff) ->clef_no] . bnote;/* Later get transposing-instrument clef goodies */     return(istaff);} /* transtaff() *//* Convert ONE hex-digit lower-case char to an integer.*  We permit hex digits greater than 'f', on purpose.*  Returns zero for invalid char.*/#define TOPHEX 'g'  /* Max "hex" char allowed (g == 16.) */short hexc2i(c)  char c;{     c -= '0';     if((c >= 0) && (c <= 9))          return(c);     c -= ('a' - '0');     if( (c >= 0) && (c <= (TOPHEX - 'a')) )          return(c + 10);     return(0);} /* hexc2i() *//*** Put up "Patience, this takes time" msg window ***/patience() {     (*pprintf)(pct2, PATI, NL);     (*pflush)();}/*** Close window ***/wkill() {     (*pprintf)(pct2, OWEN, NL);}text() {     (*pprintf)(pctn1, HIDV);}void dialogue(big)    /* Open a small Double window */  bool    big;{     wcreate(14, 110, 50, big ? 5 : 2, TRUE, WSDOUBLE);}/* Set or reset Grafix Cursor Type, and update global curcurse.* Best done when no cursor is showing.*/void curset(curtype)  sexy    curtype;{     curcurse = curtype;     (*pprintf)(pctn2, SCUR, curtype);}/*** Make Fran print one of the stock menus *//* DO NOT take out the trailing '\n' w/out changing Fran's end */void menu(code)  sexy    code;{     (*pprintf)(pctn2, MENU, code);     (*pflush)();     /* no extra bytes, in case of menu args */}/*** Open a Pat & Vanna overlay window ***/wcreate(leftcol, topy, colswide, rowshigh, dosave, style)  sexy    leftcol, topy, colswide, rowshigh, style;  bool    dosave;{     (*pprintf)(pct7, OWST, leftcol, topy, colswide, rowshigh, dosave, style);     (*pflush)();}/* eof transubs.c */