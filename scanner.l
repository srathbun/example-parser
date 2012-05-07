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

 	/************************************************** 
		start of definitions section
		
	***************************************************/
 
%{
/* A template scanner file to build "scanner.c". */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "parser.h"

/* put your variables here */

%}


%option 8bit 
%option nounput nomain noyywrap 
%option warn

DATE    [0-9]{1,2}\/[0-9]{1,2}\/[0-9]{1,4}
PAGENUM PAGE[ ]+[0-9]+
VALUE   [0-9,.%CR]+
ACCT    [0-9]+
BARCODE [FTAD]{50,74}
INFO    [a-zA-Z()/#]+([a-zA-Z0-9()/#-]+|[ \t][a-zA-Z()/#-]+)+

%x startAddress

%%
	/************************************************ 
		start of rules section

	*************************************************/


	/* Address Block Rules */
<startAddress>^[ \t]+    { }
<startAddress>[FTAD]{50,74} {  yylval.string = strdup(yytext); return BARCODE; }
<startAddress>[0-9]{24,35}[ \t]+\/BC\* {  yylval.string = strdup(yytext); return BARCODE; }
<startAddress>[0-9]+[ \t]+{DATE}   { yyless(0); BEGIN INITIAL; return '\n'; }
<startAddress>[^\r\n]+[0-9]{5}-[0-9]{4}$   { BEGIN INITIAL; yylval.string = strdup(yytext); return ADDRESS; }
<startAddress>[^\r\n]+[0-9]{5}$       { BEGIN INITIAL; yylval.string = strdup(yytext); return ADDRESS; }
<startAddress>[^ \t\r\n]+  { yylval.string = strdup(yytext); return ADDRESS; }
<startAddress>[ \t]+ { yylval.string = strdup(yytext); return ADDRESS; }
<startAddress>\r?\n      { yylval.string = strdup("\t"); return ADDRESS; }

	/* INITIAL Rules */
^[ \t]+    { }

{DATE}    {  yylval.string = strdup(yytext); return DATE; }
{PAGENUM} {  yylval.string = strdup(yytext); return PAGENUM; }
{VALUE}   {  yylval.string = strdup(yytext); return VALUE; }
{INFO}    {  yylval.string = strdup(yytext); return INFO; }
[ \t]+    {  return '\t'; }

.  { fprintf(stderr, "PROBLEM: %s\n", yytext); }
\r?\n { return '\n'; }

%%

void endAddress() {
	BEGIN(INITIAL);
}

void startOfAddress() {
	BEGIN(startAddress); 
}
