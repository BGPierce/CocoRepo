/* ~WM640/FSYS.C  -10B--    OS-9 system calls and related functions*  Yes this is newer than "Fran's" in ../VFE.*  No Col-X conversion needed.Contents:     vdgalloc();     vdgshow(screen)     vdgfree(screen)     seeregs(r) struct registers *r;*//* #define INKEY */#include <os9.h>#include <sgstat.h>#include <stdio.h>#include "../wmuse.h"#ifdef OLDVDG/************* "VDG" Screen calls.  See L2 Manual 8-142~145 *****/ubyte     *vdgalloc()    /* Allocate & return location of a VDG page */{     struct registers regs;     int  screen;     regs.rg_a = 1;               /* path = stdout */     regs.rg_b = 0x8B;            /* SS.AScrn */     regs.rg_x = 0;               /* 640 Mono */     if(_os9(I_SETSTT, &regs))    /* -1 ==> failed */          return(NULL);     else if( (screen = regs.rg_y) > 1) {    /* >3 for general use */          printf("\007VDGAlloc: Already screen #%d.\n", screen);          return(NULL);     }     return(regs.rg_x);  /* Success */}vdgshow(screen)  short screen;     /* 1--3, or 0 to revert to Text */{     struct registers regs;     regs.rg_a = 1;     regs.rg_b = 0x8C;        /* SS.DScrn */     regs.rg_y = screen;     _os9(I_SETSTT, &regs);}vdgfree(screen)  short screen;     /* Don't use invalid screen #s here */{     struct registers regs;     regs.rg_a = 1;     regs.rg_b = 0x8D;   /* SS.FScrn */     regs.rg_y = screen;     _os9(I_SETSTT, &regs);}     /* End of VDG package */#endif/* Inkey() used only by printer dump() abort *//* INKEY$ fcn to safely test for and read a char. * Returns '\0' if none there. */char inkey() {    char c;/*  fflush(stdout);        /* needed before raw I/O */    if( getstat(1, 0))        return('\0');      /* no char ready */    read(0, &c, 1);    return(c);}#ifdef seethemseeregs(r) struct registers *r;{     printf("CC=%02x, A|B=%02x|%02x, DP=%02x\n", r->rg_cc,          r->rg_a, r->rg_b, r->rg_dp);     printf("X=%04x, Y=%04x, U=%04x\n",r->rg_x,       r->rg_y,r->rg_u);}#endif/* eof ~WM640/fsys.c */