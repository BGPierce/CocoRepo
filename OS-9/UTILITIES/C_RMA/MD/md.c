/* * md.c * * For Color Computer III, OS-9 Level II * * Shows module directory with color codes in overlay window * With command line argument option to highlight module name * * Original version: 1.0, April 13, 1991 - T. Birt *              rev. 1.1, April 18       - change flash rate *              rev. 1.2, April 21       - show module from argument * * Many thanx to Brian Rhoden, Pat Meara, Brian Steward and Eugene Anderson * */#include <ctype.h>#include <os9.h>#include <stdio.h>#define STDIN 0#define STDOUT 1#define STDERR 2char FColor[] = {0x1b, 0x32},        BColor[] = {0x1b, 0x33},      white[] = {0},   blue[] = {1},  black[] = {2}, green[] = {3},        red[] = {4}, yellow[] = {5}, violet[] = {6},  cyan[] = {7},   flash_on[] = {0x1f, 0x24}, flash_rev_off[] = {0x1f, 0x25, 0x1f, 0x21},     rev_on[] = {0x1f, 0x20}, *timer_low, *timer_high;struct Module_Directory       {          int MPDAT,              MBSiz,              MPtr,              Link;       } MDirBuf[0x100];main(argc, argv)int argc;char *argv[];{     struct registers reg;     char *helpmsg = "Use md in 80 column hardware window.\n",          MBuf[30], module_name[30], storeg_a, storeg_b;     int i, j = 0, k, reg_d, buf_ptr, MDir_start, MDir_length,         adios(), horiz, vert, type, MDB_addr = MDirBuf, MB_addr = MBuf;     _gs_styp(STDOUT, &type);     _gs_scsz(STDOUT, &horiz, &vert);     if (type != 2)     {          writeln(STDERR, helpmsg, strlen(helpmsg));          exit(0);     }     ow_on(horiz, vert);     timer_low = 0xff94;     timer_high = 0xff95;     header();     intercept(adios);     setbuf(stdout, NULL);     reg.rg_x = MDB_addr;     _os9(F_GMODDR, &reg);     MDir_start = reg.rg_u;     MDir_length = (reg.rg_y - reg.rg_x) / 8;     color(BColor, black);     for (i = 0; MDir_length > i; i++)          if (MDirBuf[i].MPDAT)          {               for (k = 0; k < 30; k++)                    module_name[k] = '\0';               reg_d = MDirBuf[i].MPDAT + MDB_addr - MDir_start;               storeg_a = reg_d / 0x100;               storeg_b = reg_d & 0xff;               reg.rg_a = storeg_a;               reg.rg_b = storeg_b;               reg.rg_x = MDirBuf[i].MPtr;               reg.rg_y = 7;               reg.rg_u = MB_addr;               _os9(F_CPYMEM, &reg);               switch (MBuf[6] & 0xf0)               {                    case 0x10:                         color(FColor, cyan);                         break;                    case 0x20:                         color(FColor, red);                         break;                    case 0x40:                         color(FColor, green);                         break;                    case 0xc0:                         color(FColor, violet);                         break;                    case 0xd0:                         color(FColor, white);                         break;                    case 0xe0:                         write(STDOUT, flash_on, 2);                         color(FColor, green);                         break;                    case 0xf0:                         color(FColor, yellow);                         break;                    default:                         color(FColor, blue);               }               reg.rg_a = storeg_a;               reg.rg_b = storeg_b;               reg.rg_x = MDirBuf[i].MPtr + MBuf[4] * 0x100 + (MBuf[5] & 0xff);               reg.rg_y = 0x20;               reg.rg_u = MB_addr;               _os9(F_CPYMEM, &reg);               buf_ptr = 0;               do {                    module_name[buf_ptr] = toascii(MBuf[buf_ptr]);               } while (isprint(MBuf[buf_ptr++]));               if (argc > 1)                    if (strucmp(module_name, argv[1], strlen(argv[1])) == 0)                         write(STDOUT, rev_on, 2);               write(STDOUT, module_name, strlen(module_name));               write(STDOUT, flash_rev_off, 4);               while (buf_ptr++ < 11 && j < 61)                    write(STDOUT, " ", 1);               j += buf_ptr;               if (j > 72 || strlen(module_name) > 10)               {                    writeln(STDOUT, "\n", 1);                    j = 0;               }          }     footer();     adios();}color(dim, scr_color)char *dim, *scr_color;{     write(STDOUT, dim, 2);     write(STDOUT, scr_color, 1);}ow_on(x, y)int x, y;{     static char s[] = {0x1b, 0x22, 1, 0, 0}, cur_off[] = {5, 0x20};     char xy[2];     xy[0] = x;     xy[1] = y;     write(STDOUT, s, 5);     write(STDOUT, xy, 2);     write(STDOUT, cyan, 1);     write(STDOUT, black, 1);     write(STDOUT, cur_off, 2);}adios(){     static char ow_off[] = {0x1b, 0x23}, cur_on[] = {5, 0x21};     *timer_low = *timer_high = 0x17;     write(STDOUT, ow_off, 2);     write(STDOUT, cur_on, 2);     exit(0);}header(){     static char *mod = "Module: ", *sys = "System ",                 *dvr = "Driver ", *des = "Descriptor ",                  *mgr = "Manager ", *usr = "User defined\n",                 *sub = "Subroutine ", *pgm = "Program ", *dat = "Data ";     *timer_low = 0;     *timer_high = 1;     write(STDOUT, mod, strlen(mod));     color(FColor, violet);     write(STDOUT, sys, strlen(sys));     write(STDOUT, flash_on, 2);     color(FColor, green);     write(STDOUT, dvr, strlen(dvr));     write(STDOUT, flash_rev_off, 4);     color(FColor, yellow);     write(STDOUT, des, strlen(des));     color(FColor, white);     write(STDOUT, mgr, strlen(mgr));     color(FColor, red);     write(STDOUT, sub, strlen(sub));     color(FColor, cyan);     write(STDOUT, pgm, strlen(pgm));     color(FColor, green);     write(STDOUT, dat, strlen(dat));     color(FColor, blue);     writeln(STDOUT, usr, strlen(usr));     writeln(STDOUT, "\n", 1);}footer(){     static char *prompt = "                      Depress a key to quit";     char c;     color(FColor, cyan);     writeln(STDOUT, "\n", 1);     writeln(STDOUT, "\n", 1);     write(STDOUT, prompt, strlen(prompt));     read(STDIN, &c, 1);}