/*Title: bcs - Binary to C Source translatorPurpose: To read in a binary file and output a C source         compatible data table to be #include(d) into         your C project.26SEP92 Daniel S. Hauck*/#include <stdio.h>char *docs[]= {  "bcs - Binary to C Source translator",  "",  "Usage:",  "      bcs <binary> <output> <label>",  "Where:",  "      \"binary\" is the binary input file",  "      \"output\" is the output source code file",  "      \"label\"  is the name the data will assume",  0 };FILE *outfile;main(argc,argv)int argc;char *argv[];{     setbuf(stderr,256);     if(argc==4) {       fprintf(stderr,"binary file: %s\n",*++argv);       if(freopen(*argv,"r",stdin)==NULL) {         fprintf(stderr,"can't open file: %s\n",*argv);         exit(errno);       }       fprintf(stderr,"output file: %s\n",*++argv);       if((outfile=fopen(*argv,"a"))==NULL) {         fprintf(stderr,"can't open file: %s\n",*argv);         exit(errno);       }       process(*++argv);       fclose(outfile);       exit(0);     } else       usage();}process(blknam)char *blknam;{     int szin;     char buffer[10];     fprintf(outfile,"\nchar %s\[\]=\{\n",blknam);     while(!feof(stdin)) {       szin=fread(buffer,sizeof(char),10,stdin);       fprintf(outfile,"     ");       putline(szin,buffer);       fprintf(outfile,"\n");     }     fprintf(outfile,"     0x00\};\n");}putline(length,buffer)int length;char *buffer;{     register int idx;     char cnvt[5];     for(idx=0; idx<length; idx++) {       sprintf(cnvt,"%04x",buffer[idx]);       fprintf(outfile,"0x%s, ",&cnvt[2]);     }}usage(){     register char **dp;     for(dp=docs; *dp; dp++)       fprintf(stderr,"%s\n",*dp);     exit(0);}