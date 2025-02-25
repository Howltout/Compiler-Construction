%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

void yyerror(const char *s);
int yylex(void);  // Lex function

typedef enum { INT_TYPE, FLOAT_TYPE, CHAR_TYPE } DataType;

typedef struct {
    char *name;
    DataType type;
    union {
        int ival;
        float fval;
        char cval;
    } value;
} Symbol;

Symbol symbol_table[100];
int symbol_count = 0;

// Symbol Table Functions
int get_variable_value(char *name, DataType type);
void set_variable_value(char *name, DataType type, int ival, float fval, char cval);

// Code Optimization Structures
typedef enum { OP_ADD, OP_SUB, OP_MUL, OP_DIV, OP_ASSIGN } OperationType;

typedef struct {
    OperationType op;
    char *var_name;
    union {
        int ival;
        float fval;
        char cval;
    } value;
} IRInstruction;

IRInstruction ir_code[100];
int ir_count = 0;

// Intermediate Code Generation Functions
void add_ir(OperationType op, char *var_name, int ival, float fval, char cval);
void optimize_ir();
void generate_code();
%}

%union {
    int ival;
    float fval;
    char cval;
    char *id;
}

%token <ival> NUMBER
%token <fval> FLOAT_NUMBER
%token <cval> CHAR
%token <id> IDENTIFIER
%token INT PRINT ASSIGN SEMICOLON LPAREN RPAREN PLUS MINUS MUL DIV EQ IF ELSE LBRACE RBRACE FLOAT CHAR FOR

%type <ival> expression term factor
%type <id> identifier statement
%type <fval> float_expression float_term float_factor
%type <cval> char_expression

%%

program:
    statements
;

statements:
    statements statement
  | statement
;

statement:
    declaration
  | assignment
  | print_statement
  | if_else_statement
  | for_loop
;

declaration:
    INT IDENTIFIER SEMICOLON {
        set_variable_value($2, INT_TYPE, 0, 0.0f, '\0');
    }
  | FLOAT IDENTIFIER SEMICOLON {
        set_variable_value($2, FLOAT_TYPE, 0, 0.0f, '\0');
    }
  | CHAR IDENTIFIER SEMICOLON {
        set_variable_value($2, CHAR_TYPE, 0, 0.0f, '\0');
    }
;

assignment:
    IDENTIFIER ASSIGN expression SEMICOLON {
        set_variable_value($1, INT_TYPE, $3, 0.0f, '\0');
        add_ir(OP_ASSIGN, $1, $3, 0.0f, '\0');
    }
  | IDENTIFIER ASSIGN float_expression SEMICOLON {
        set_variable_value($1, FLOAT_TYPE, 0, $3, '\0');
        add_ir(OP_ASSIGN, $1, 0, $3, '\0');
    }
  | IDENTIFIER ASSIGN char_expression SEMICOLON {
        set_variable_value($1, CHAR_TYPE, 0, 0.0f, $3);
        add_ir(OP_ASSIGN, $1, 0, 0.0f, $3);
    }
;

print_statement:
    PRINT IDENTIFIER SEMICOLON {
        printf("Print: %s = %d\n", $2, get_variable_value($2, INT_TYPE));
    }
;

if_else_statement:
    IF LPAREN expression RPAREN statement ELSE statement {
        if ($3) {
            $$ = $5;
        } else {
            $$ = $7;
        }
    }
;

for_loop:
    FOR LPAREN assignment expression SEMICOLON expression RPAREN statement {
        for ($3; $5; $7) {
            $$ = $9;
        }
    }
;

expression:
    expression PLUS term  { $$ = $1 + $3; add_ir(OP_ADD, NULL, $1 + $3, 0.0f, '\0'); }
  | expression MINUS term { $$ = $1 - $3; add_ir(OP_SUB, NULL, $1 - $3, 0.0f, '\0'); }
  | term                  { $$ = $1; }
;

term:
    term MUL factor { $$ = $1 * $3; add_ir(OP_MUL, NULL, $1 * $3, 0.0f, '\0'); }
  | term DIV factor { $$ = $1 / $3; add_ir(OP_DIV, NULL, $1 / $3, 0.0f, '\0'); }
  | factor          { $$ = $1; }
;

factor:
    NUMBER               { $$ = $1; add_ir(OP_ASSIGN, NULL, $1, 0.0f, '\0'); }
  | IDENTIFIER           { $$ = get_variable_value($1, INT_TYPE); }
  | LPAREN expression RPAREN { $$ = $2; }
;

float_expression:
    float_expression PLUS float_term { $$ = $1 + $3; }
  | float_expression MINUS float_term { $$ = $1 - $3; }
  | float_term { $$ = $1; }
;

float_term:
    float_term MUL float_factor { $$ = $1 * $3; }
  | float_term DIV float_factor { $$ = $1 / $3; }
  | float_factor { $$ = $1; }
;

float_factor:
    FLOAT_NUMBER { $$ = $1; }
  | IDENTIFIER { $$ = get_variable_value($1, FLOAT_TYPE); }
  | LPAREN float_expression RPAREN { $$ = $2; }
;

char_expression:
    CHAR { $$ = $1; }
  | IDENTIFIER { $$ = get_variable_value($1, CHAR_TYPE); }
;

identifier:
    IDENTIFIER { $$ = $1; }
;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(void) {
    printf("Enter your code:\n");
    yyparse();
    optimize_ir();
    generate_code();
    return 0;
}

// Symbol Table Management
int get_variable_value(char *name, DataType type) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            if (symbol_table[i].type == type) {
                return symbol_table[i].value.ival;
            }
        }
    }
    printf("Error: Undefined variable %s\n", name);
    exit(1);
}

void set_variable_value(char *name, DataType type, int ival, float fval, char cval) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            symbol_table[i].value.ival = ival;
            return;
        }
    }
    symbol_table[symbol_count].name = strdup(name);
    symbol_table[symbol_count].type = type;
    symbol_table[symbol_count].value.ival = ival;
    symbol_count++;
}

// IR Generation & Optimization
void add_ir(OperationType op, char *var_name, int ival, float fval, char cval) {
    ir_code[ir_count++] = (IRInstruction) { op, var_name, { .ival = ival } };
}

void optimize_ir() {
    // Example: Remove redundant assignments
    for (int i = 1; i < ir_count; i++) {
        if (ir_code[i].op == OP_ASSIGN && ir_code[i].var_name == ir_code[i - 1].var_name) {
            ir_code[i - 1].op = OP_ASSIGN;
        }
    }
}

void generate_code() {
    printf("\nGenerated Code:\n");
    for (int i = 0; i < ir_count; i++) {
        printf("OPERATION: %d, VALUE: %d\n", ir_code[i].op, ir_code[i].value.ival);
    }
}
