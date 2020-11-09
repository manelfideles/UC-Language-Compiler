%{
        #include <stdlib.h>
        #include <stdio.h>
        #include <string.h>
        #include "y.tab.h"

        int yylex();
        int yyerror(char *msg);


%}

%union {
    char* str_value;
    // node_ptr
}

%token<str_value> MINUS PLUS MUL DIV MOD BITWISEAND BITWISEOR BITWISEXOR AND NOT OR EQ NE LE GE LT GT CHAR INT SHORT DOUBLE VOID IF ELSE WHILE RETURN ASSIGN COMMA LBRACE RBRACE LPAR RPAR SEMI
%token<str_value> ID CHRLIT INTLIT REALLIT

    /* prioridade mais alta em baixo, mais baixa em cima */
%left COMMA
%right ASSIGN
%left OR
%left AND
%left BITWISEOR
%left BITWISEXOR
%left BITWISEAND
%left EQ NE
%left GE GT LE LT
%left PLUS MINUS
%left MUL DIV MOD
%right NOT
%left RPAR
%right LPAR
%right ELSE

%%

FunctionsAndDeclarations: %empty
                        | FunctionDefinition FunctionsAndDeclarations
                        | FunctionDeclaration FunctionsAndDeclarations
                        | Declaration FunctionsAndDeclarations
                        ;

FunctionDefinition: Typespec FunctionDeclarator FunctionBody
                  ;

FunctionBody:   LBRACE DeclarationsAndStatements RBRACE
            |   LBRACE RBRACE
            ;

DeclarationsAndStatements: Statement DeclarationsAndStatements
                         | Declaration DeclarationsAndStatements
                         | Statement
                         | Declaration
                         ;

FunctionDeclaration:    Typespec FunctionDeclarator SEMI
                   ;

FunctionDeclarator: ID LPAR ParameterList RPAR
                  ;

ParameterList:  ParameterDeclaration
             |  COMMA ParameterList
             ;

ParameterDeclaration: Typespec
                    | Typespec ID
                    ;

Declaration:    Typespec Declarator Declaration SEMI
           |    COMMA Declarator
           ;

Declarator:  ID
          |  ID ASSIGN Expr
          ;

Statement:   Expr SEMI
         |   SEMI
         |   LBRACE Statement RBRACE
         |   IF LPAR Expr RPAR Statement
         |   IF LPAR Expr RPAR Statement ELSE Statement
         |   WHILE LPAR Expr RPAR Statement
         |   RETURN Expr SEMI
         |   RETURN SEMI
         ;

Assignment: ID ASSIGN Expr
          ;

FunctionCall: ID LPAR ArgumentsInFunction RPAR
            ;

ArgumentsInFunction: %empty
                   | Expr
                   | COMMA Expr
                   ;

ExprAux: Expr
       | Assignment
       ;

Expr:  FunctionCall
    |  Assignment
    |  Expr MUL Expr
    |  Expr DIV Expr
    |  Expr PLUS Expr
    |  Expr MINUS Expr
    |  Expr MOD Expr
    |  Expr AND Expr
    |  Expr OR Expr
    |  Expr BITWISEAND Expr
    |  Expr BITWISEOR Expr
    |  Expr BITWISEXOR Expr
    |  Expr EQ Expr
    |  Expr NE Expr
    |  Expr GE Expr
    |  Expr GT Expr
    |  Expr LE Expr
    |  Expr LT Expr
    |  Expr COMMA Expr
    |  NOT Expr
    |  PLUS Expr %prec NOT
    |  MINUS Expr %prec NOT
    |  LPAR ExprAux RPAR
    |  ID
    |  INTLIT
    |  CHRLIT
    |  REALLIT
    ;

Typespec: CHAR
        | INT
        | SHORT
        | DOUBLE
        | VOID
        ;


%%

int yyerror(char *msg) {
    printf("%s\n", msg);
    return 1;
}