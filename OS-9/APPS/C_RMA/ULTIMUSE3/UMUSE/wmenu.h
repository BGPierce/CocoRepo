/* file ~Wm640/WMENU.H *//* MENU-related constants *//* 88/9/19  Extended for pretty main screen (Sex Sells) *//* 88/11/07 Converted for Col-X's;*    any names ending in P but not TOP are in Pixels, rest Columns.*  96/2/18  Toolbox stuff went to tools.h.*//* Main score region */#define SCORLEFT    1    /* Left margin for border */#define SCORIGHT    79#define SCORTOP     (191-MENBARHGT) /* for Pulldown Menus Bar */#define SCORBOT     (SCROLTOP+1)    /* for now *//* Main Menu-Bar region */#define MENBARHGT   7#define MENLEFT   5      /* Menu Bar left margin, in Columns */#define MENWID    7      /* Menu Bar max word length, Columns *//* Main Scrollbar region */#define SCROLHGT    8    /* was 9 so hardcopy wud have bottom line */#define SCROLBOT    0#define SCROLTOP    (SCROLBOT+SCROLHGT-1)#define LBARP     38     /* Pixels, Left "<-" dividing line */#define RBARP     600    /* Pixels */#define SCROLLWP (RBARP - LBARP)     /* Width of scroll bar space *//* eof wmenu.h */