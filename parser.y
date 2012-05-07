/*
 * This file is part of flex.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the University nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE.
 */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <errno.h>
/* #include "config.h" */

#define YYERROR_VERBOSE 1       /* For debugging.   */
/* #define YYPARSE_PARAM scanner  */ /* For pure bison parser. */
/* #define YYLEX_PARAM   scanner  */ /* For reentrant flex. */


int yyerror(char* msg);
extern int yylex();
extern FILE *yyin;
extern FILE *yyout;

char FileName[256];
FILE *outfile;

char BadFileName[256];
FILE *badStatements;
char inputName[256];
char *tmp;
char *badRec;

#define MAX_LINES 100
#define MAX_LINE_LENGTH 1000
char savebuf[MAX_LINES][MAX_LINE_LENGTH]; /* buffer to hold current statement */
char line[MAX_LINE_LENGTH];
int currLine = 0;
int pagesInStatement = 0;

void startOfAddress(void);
void endAddress(void);
void printStatement(void);
void save_line(char *);

 /* flags for command line options */
static int output_flag = 0;
static int help_flag = 0;
%}

%union {
	char *string;
}

%token <string> BARCODE
%token <string> DATE
%token <string> PAGENUM
%token <string> VALUE
%token <string> ACCT
%token <string> ADDRESS
%token <string> INFO

%type <string> dh h1 bc ad h2 pb tr td f1 f2

%debug 
%%

statements : statement '\n'
	       | statement '\n' statements
		   ;

statement  : dh '\n' h1 '\n' { startOfAddress(); } addressBlock '\n' statement 
		   | h2 '\n' pb '\n' statement
		   | h2 '\n' statement
		   | tr '\n' statement 
		   | td { 
			 	tmp = strdup(line);
				strcpy(line, "td\t");
				strcat(line, tmp);
				free(tmp); 
		   		save_line(line); 
			} '\n' statement 
		   | f1 '\n' f2  { printStatement(); }
		   ;

addressBlock : bc ad { endAddress(); 
			 	tmp = strdup(line);
				strcpy(line, "ad");
				strcat(line, tmp);
				free(tmp);
				badRec = strstr(line, "HOLD STATEMENT");
				if (badRec) {
					yyout = badStatements;
				}
				badRec = strstr(line, "INSUFFICIENT ADDRESS");
				if (badRec) {
					yyout = badStatements;
				}
				save_line(line);
				}
			 | ad { endAddress(); 
			 	tmp = strdup(line);
				strcpy(line, "ad\t");
				strcat(line, tmp);
				free(tmp); 
				badRec = strstr(line, "HOLD STATEMENT");
				if (badRec) {
					yyout = badStatements;
				}
				badRec = strstr(line, "INSUFFICIENT ADDRESS");
				if (badRec) {
					yyout = badStatements;
				}
				save_line(line);
				}
			 ;

dh     : DATE '\t' PAGENUM { sprintf(line, "dh\t%s\t%s", $1, $3); 
	   		pagesInStatement += 1;
			if (pagesInStatement > 1) {
				save_line("np");
			}
			save_line(line);
			}
	   ;

h1     : VALUE '\t' DATE '\t' VALUE '\t' VALUE '\t' VALUE '\t' VALUE { 
	   			sprintf(line, "h1\t%s\t%s\t%s\t%s\t%s\t%s", $1, $3, $5, $7, $9, $11); save_line(line); }
	   ;

bc     : BARCODE { sprintf(line, "bc\t%s", $1); save_line(line); }
	   ;

ad     : ADDRESS  { sprintf(line, "%s", $1); }
	   | ADDRESS ad { tmp = strdup(line); strcpy(line, $1); strcat(line, tmp); free(tmp); }
	   ;

h2     : VALUE '\t' DATE '\t' VALUE '\t' VALUE '\t' DATE '\t' VALUE { 
	   			sprintf(line, "h2\t%s\t%s\t%s\t%s\t%s\t%s", $1, $3, $5, $7, $9, $11); save_line(line); }
       | VALUE '\t' DATE '\t' VALUE '\t' INFO '\t' DATE '\t' VALUE { 
	   			sprintf(line, "h2\t%s\t%s\t%s\t%s\t%s\t%s", $1, $3, $5, $7, $9, $11); save_line(line); }
	   ;

pb     : DATE '\t' INFO '\t' VALUE { sprintf(line, "pb\t%s\t%s\t%s", $1, $3, $5); save_line(line); }
	   ;

tr     : DATE '\t' INFO '\t' VALUE '\t' VALUE { 
	   			sprintf(line, "tr\t%s\t%s\t%s\t%s", $1, $3, $5, $7); save_line(line); }
       | DATE '\t' VALUE '\t' INFO '\t' VALUE '\t' VALUE { 
	   			sprintf(line, "tr\t%s\t%s\t%s\t%s\t%s", $1, $3, $5, $7, $9); save_line(line); }
	   ;

td     : INFO { sprintf(line, "td\t%s", $1); }
	   | td '\t' INFO { sprintf(line, "%s\t%s", $1, $3); }
	   | td '\t' DATE { sprintf(line, "%s\t%s", $1, $3); }
	   | td '\t' VALUE { sprintf(line, "%s\t%s", $1, $3); }
	   ;

f1     : VALUE '\t' VALUE '\t' VALUE '\t' VALUE '\t' VALUE '\t' VALUE { 
	   			sprintf(line, "f1\t%s\t%s\t%s\t%s\t%s\t%s", $1, $3, $5, $7, $9, $11); save_line(line); }
	   ;

f2     : VALUE '\t' VALUE '\t' VALUE '\t' VALUE { sprintf(line, "f2\t%s\t%s\t%s\t%s", $1, $3, $5, $7); save_line(line); }
	   ;

%%

	/**************************************************** 
		start of code section
	
	
	*****************************************************/

int yyerror(char* msg) {
    fprintf(stderr,"%s\n",msg);
    return 0;
}

void printStatement() {
	int i;
	for(i = 0; i < currLine; i++) {
		if (i == 0) { 
			fprintf(yyout, "%s\t%d\r\n", savebuf[i], pagesInStatement);
		}
		else {
			fprintf(yyout, "%s\r\n", savebuf[i]);
		}
	}
	currLine = 0;
	pagesInStatement = 0;
	yyout = outfile;
}

void save_line(char *s) {
	strcpy(savebuf[currLine], s);
	currLine += 1;
}


int main(int argc, char **argv);

int main (argc,argv)
int argc;
char **argv;
{
	/****************************************************
		The main method drives the program. It gets the filename from the
		command line, and opens the initial files to write to. Then it calls the lexer.
		After the lexer returns, the main method finishes out the report file,
		closes all of the open files, and prints out to the command line to let the
		user know it is finished.
	****************************************************/

    int c;
	yydebug = 0;
    
	/* the gnu getopt library is used to parse the command line for flags
	   afterwards, the final option is assumed to be the input file */
	
	while (1) {
        static struct option long_options[] = {
            /* These options set a flag. */
            {"help",   no_argument,     &help_flag, 1},
            /* These options don't set a flag. We distinguish them by their indices. */
			
			{"useStdOut", no_argument,       0, 'o'},
            {0, 0, 0, 0}
        };
           /* getopt_long stores the option index here. */
        int option_index = 0;
        c = getopt_long (argc, argv, "hod",
            long_options, &option_index);
    
		/* Detect the end of the options. */
        if (c == -1)
            break;
			
        switch (c) {
            case 0:
               /* If this option set a flag, do nothing else now. */
               if (long_options[option_index].flag != 0)
                 break;
               printf ("option %s", long_options[option_index].name);
               if (optarg)
                 printf (" with arg %s", optarg);
               printf ("\n");
               break;
     
	 		case 'h':
				help_flag = 1;
				break;

			case 'd':
               yydebug = 1;
               break;

			case 'o':
               output_flag = 1;
               break;
          
            case '?':
               /* getopt_long already printed an error message. */
               break;
     
            default:
               abort ();
            }
	}

	if (help_flag == 1) {
		printf("proper syntax is: cleaner [OPTIONS]... INFILE OUTFILE\n");
		printf("Strips non printable chars from input, adds line breaks on esc fs gs and us\n\n");
		printf("Option list: \n");
		printf("-o    					sets output to stdout\n");
		printf("--help       			print help to screen\n");
		printf("\n");
		printf("If infile is left out, then stdin is used for input.\n");
		printf("If outfile is a filename, then that file is used.\n");
		printf("If there is no outfile, then infile-EDIT is used.\n");
		printf("There cannot be an outfile without an infile.\n");
		return 0;
	}
	
	/* get the filename off the command line and redirect it to input
	   if there is no filename then use stdin */
	
	
	if (optind < argc) {
		FILE *file;
		
		file = fopen(argv[optind], "rb");
		if (!file) {
			fprintf (stderr, "%s: Couldn't open file %s; %s\n", argv[0], argv[optind], strerror (errno));
			exit(errno);
		}
		yyin = file;
		strcpy(inputName, argv[optind]);
	}
	else {
		printf("no input file set, using stdin. Press ctrl-c to quit");
		yyin = stdin;
		strcpy(inputName, "\b\b\b\b\bagainst stdin");
	}
	
	/* increment current place in argument list */
	optind++;
	

	/********************************************
		if no input name, then output set to stdout
		if no output name then copy input name and add -EDIT.csv
		otherwise use output name
		
	*********************************************/
	if (optind > argc) {
		outfile = stdout;
		badStatements = stderr;
	}	
	else if (output_flag == 1) {
		outfile = stdout;
		badStatements = stderr;
	}
	else if (optind < argc){
		outfile = fopen(argv[optind], "wb");
		if (!outfile) {
				fprintf (stderr, "%s: Couldn't open file %s; %s\n", argv[0], argv[optind], strerror (errno));
				exit(errno);
			}

		strncpy(BadFileName, argv[optind], strlen(argv[optind])-4);
		FileName[strlen(argv[optind])-4] = '\0';
		strcat(BadFileName, "-BadStatements.dat");
		badStatements = fopen(BadFileName, "wb");
		if (!badStatements) {
				fprintf (stderr, "%s: Couldn't open file %s; %s\n", argv[0], BadFileName, strerror (errno));
				exit(errno);
			}
	}
	else {
		strncpy(FileName, argv[optind-1], strlen(argv[optind-1])-4);
		FileName[strlen(argv[optind-1])-4] = '\0';
		strcat(FileName, "-EDIT.dat");
		outfile = fopen(FileName, "wb");
		if (!outfile) {
				fprintf (stderr, "%s: Couldn't open file %s; %s\n", argv[0], FileName, strerror (errno));
				exit(errno);
			}

		strncpy(BadFileName, argv[optind-1], strlen(argv[optind-1])-4);
		FileName[strlen(argv[optind-1])-4] = '\0';
		strcat(BadFileName, "-BadStatements.dat");
		badStatements = fopen(BadFileName, "wb");
		if (!badStatements) {
				fprintf (stderr, "%s: Couldn't open file %s; %s\n", argv[0], BadFileName, strerror (errno));
				exit(errno);
			}
	}
	
	yyout = outfile;
	fprintf(yyout, "header\tfield2\tfield3\tfield4\tfield5\tfield6\tfield7\tfield8\tfield9\tfield10\tfield11\tfield12\tfield13\tfield14\tfield15\r\n");
	yyparse();
	if (output_flag == 0) {
		fclose(yyout);
		fclose(badStatements);
	}
	printf("Flex program finished running file %s\n", inputName);
    return 0;
}

