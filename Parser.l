%{
#include "parser.tab.h"  // Include the Bison header
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}

%%

[ \t\n]+                 { /* Ignore whitespace */ }
"int"                    { return INT; }
"float"                  { return FLOAT; }
"char"                   { return CHAR; }
"print"                  { return PRINT; }
"if"                     { return IF; }
"else"                   { return ELSE; }
"for"                    { return FOR; }

[0-9]+\.[0-9]+           { yylval.fval = atof(yytext); return FLOAT_NUMBER; }  // Match floating-point numbers
[0-9]+                   { yylval.ival = atoi(yytext); return NUMBER; }        // Match integers
\'[a-zA-Z]\'             { yylval.cval = yytext[1]; return CHAR_LITERAL; }     // Match single character literals

[a-zA-Z_][a-zA-Z0-9_]*   { yylval.id = strdup(yytext); return IDENTIFIER; }    // Match variable names

"="                      { return ASSIGN; }
";"                      { return SEMICOLON; }
"("                      { return LPAREN; }
")"                      { return RPAREN; }
"{"                      { return LBRACE; }
"}"                      { return RBRACE; }
"+"                      { return PLUS; }
"-"                      { return MINUS; }
"*"                      { return MUL; }
"/"                      { return DIV; }
"=="                     { return EQ; }

.                        { printf("Unknown token: %s\n", yytext); exit(1); }  // Catch invalid tokens

%%

int yywrap(void) {
    return 1;  // End of file
}
