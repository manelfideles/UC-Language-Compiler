%{
        #include <stdlib.h>
        #include <stdio.h>
        #include <string.h>
        #include "functions.h"
        #include "y.tab.h"
        #define MAXSTRINGLEN 300

        int yylex();
        int yyerror(const char *s);

        NodePtr* program;
    

        // FLags de erros lexicais sintáticos e imprimir árvore
        int e1, e2, t;

        // para imprimir as produções
        int debug = 0;

        //string de intlit reallit chrlit id
        char string[MAXSTRINGLEN];

%}

%union {
    char* str_value;
    char* id_value;
    int lin;
    int col;
    struct node *node;
}

%token<str_value> MINUS PLUS MUL DIV MOD BITWISEAND BITWISEOR BITWISEXOR AND NOT OR EQ NE LE GE LT GT CHAR INT SHORT DOUBLE VOID IF ELSE WHILE RETURN ASSIGN COMMA LBRACE RBRACE LPAR RPAR SEMI RESERVED
%token<str_value> ID CHRLIT INTLIT REALLIT
%type<node> Program FunctionsAndDeclarations FunctionDefinition FunctionBody DeclarationsAndStatements FunctionDeclaration FunctionDeclarator ParameterList ParameterDeclaration Declaration DeclarationAux Declarator Statement StatementList FunctionCall ArgList FuncCallArgList Expr Typespec IdToken StatementError

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
Program: FunctionsAndDeclarations {
                                    if($1) {
                                        program = createNode("Program",yyval.lin,yyval.col);
                                        $$ = program = appendNode(program, $1);
                                    }
                                    else {$$ = NULL; t = 1;}
                                  }
       ;
FunctionsAndDeclarations: FunctionDefinition FunctionsAndDeclarations   {
                                                                            if(debug) printf("FunctionsAndDeclarations: FunctionDefinition\n");
                                                                            if($2) {
                                                                                $1->next = $2;
                                                                                $$ = $1;
                                                                            }
                                                                            else {$$ = $1;}
                                                                        }
                        | FunctionDeclaration FunctionsAndDeclarations  {
                                                                            if(debug) printf("FunctionsAndDeclarations: FunctionDeclaration\n");
                                                                            if($2) {
                                                                                $1->next = $2;
                                                                                $$ = $1;
                                                                            }
                                                                            else {$$ = $1;}
                                                                        }
                        | Declaration FunctionsAndDeclarations          {
                                                                            if(debug) printf("FunctionsAndDeclarations: Declaration\n");
                                                                            if($1) {
                                                                                if($2) {
                                                                                    NodePtr* tmp = $1;
                                                                                    while(tmp->next) tmp = tmp->next;
                                                                                    tmp->next = $2;
                                                                                }
                                                                                $$ = $1;
                                                                            }
                                                                            else {$$ = $2;}
                                                                        }
                        | FunctionDefinition                            {$$ = $1;}
                        | FunctionDeclaration                           {$$ = $1;}
                        | Declaration                                   {$$ = $1;}
                        ;

FunctionDefinition: Typespec FunctionDeclarator FunctionBody {
                                                                if(debug) printf("Function Definition: Typespec FunctionDeclarator FunctionBody\n");
                                                                struct node* tmp = $2;
                                                                while(tmp->next) tmp = tmp->next;
                                                                $1->next = $2; tmp->next = $3;
                                                                $$ = appendNode(createNode("FuncDefinition",yyval.lin,yyval.col), $1);
                                                             }
                  ;

FunctionBody:   LBRACE DeclarationsAndStatements RBRACE {
                                                            if(debug) printf("FunctionBody: {DeclarationsAndStatements}\n");
                                                            $$ = appendNode(createNode("FuncBody",yyval.lin,yyval.col), $2);
                                                        }
            |   LBRACE RBRACE                           {$$ = appendNode(createNode("FuncBody",yyval.lin,yyval.col), NULL);}
            ;

DeclarationsAndStatements: DeclarationsAndStatements Statement      {
                                                                        if($1) {
                                                                            if($2) {
                                                                                struct node* tmp = $1;
                                                                                while(tmp->next) tmp = tmp->next;
                                                                                tmp->next = $2;
                                                                            }
                                                                            $$ = $1;
                                                                        }
                                                                        else if($2) {$$ = $2;}
                                                                        else {$$ = NULL;}
                                                                    }
                         | DeclarationsAndStatements Declaration    {
                                                                        if($1) {
                                                                            if($2) {
                                                                                struct node* tmp = $1;
                                                                                while(tmp->next) tmp = tmp->next;
                                                                                tmp->next = $2;
                                                                            }
                                                                            $$ = $1;
                                                                        }
                                                                        else if($2) {$$ = $2;}
                                                                        else {$$ = NULL;}
                                                                    }
                         | Declaration                              {$$ = $1;}
                         | Statement                                {$$ = $1;}
                         ;

FunctionDeclaration:  Typespec FunctionDeclarator SEMI {
                                                            if(debug) printf("FunctionDeclaration: Typespec Function Declarator SEMI\n");
                                                            $1->next = $2;
                                                            $$ = appendNode(createNode("FuncDeclaration",yyval.lin,yyval.col), $1);
                                                            //printNode($$);
                                                       }
                   ;

FunctionDeclarator: IdToken LPAR ParameterList RPAR  {
                                                    if(debug) printf("FunctionDeclarator: ID (ParameterList)\n");
                                                    struct node* paramlist = createNode("ParamList",yyval.lin,yyval.col);
                                                    paramlist = appendNode(paramlist, $3);
                                                    $1->next = paramlist;
                                                    $$ = $1;
                                                }
                  ;

ParameterList: ParameterDeclaration                   {
                                                        if(debug) printf("Parameter List: Parameter Declaration\n");
                                                        $$ = appendNode(createNode("ParamDeclaration",yyval.lin,yyval.col), $1);
                                                      }
             | ParameterList COMMA ParameterDeclaration {
                                                            struct node* tmp = $1;
                                                            while(tmp->next != NULL) tmp = tmp->next;
                                                            tmp->next = appendNode(createNode("ParamDeclaration",yyval.lin,yyval.col), $3);
                                                            $$ = $1;
                                                        }
             ;
ParameterDeclaration: Typespec      {
                                        if(debug) printf("ParameterDeclaration: TypeSpec ParameterDeclarationAux\n");
                                        $$ = $1;
                                        //printNode($$);
                                    }
                    | Typespec IdToken   {
                                        if(debug) printf("ParameterDeclaration: TypeSpec ID ParameterDeclarationAux\n");
                                        $1->next = $2;
                                        $$ = $1;
                                    }
                    ;

Declaration: Typespec DeclarationAux SEMI {
                                            if(debug) printf("Declaration: TypeSpec Declarator DeclarationAux SEMI\n");
                                            if($2) {
                                                struct node* tmp = $2;
                                                while(tmp) {
                                                    // criar nó typespec
                                                    struct node* typespec = createNode($1->type,yyval.lin,yyval.col);
                                                    // bebés = os filhos de tmp
                                                    struct node* babies = tmp->children;
                                                    // tmp->children = nó typespec
                                                    tmp->children = typespec;
                                                    // nó typespec->next = bebés
                                                    typespec->next = babies;
                                                    tmp = tmp->next;
                                                }
                                            }
                                            $$ = $2;
                                          }
            | error SEMI                  {$$ = NULL; t = 1; /*printf("Declaration -> error SEMI\n");*/}
           ;
DeclarationAux: DeclarationAux COMMA Declarator  {
                                                    if(debug) printf("DeclarationAux: COMMA Declarator DeclarationAux\n");
                                                    //ll de declarators
                                                    if($1) {
                                                        struct node* tmp = $1;
                                                        while(tmp->next) tmp = tmp->next;
                                                        if($3) tmp->next = appendNode(createNode("Declaration",yyval.lin,yyval.col), $3);
                                                        $$ = $1;
                                                    }
                                                    else if($3) {$$ = $3;}
                                                    else {$$ = NULL;}
                                                }
              | Declarator                      {
                                                    if(debug) printf("DeclarationAux: EMPTY\n");
                                                    if($1) {
                                                        struct node* dec = createNode("Declaration",yyval.lin,yyval.col);
                                                        $$ = appendNode(dec, $1);
                                                    }
                                                    else {$$ = NULL;}
                                                }
              ;

Declarator:  IdToken             {$$ = $1;}
          |  IdToken ASSIGN Expr {$1->next = $3; $$ = $1;}
          ;

Statement:   LBRACE StatementList RBRACE                {
                                                            if(debug) printf("Statement: LBRACE Statement RBRACE \n");
                                                            // criar statlist
                                                            $$ = $2;
                                                            if($2 && $2->next) {
                                                                struct node* statlist = createNode("StatList",yyval.lin,yyval.col);
                                                                statlist = appendNode(statlist, $2);
                                                                $$ = statlist;
                                                            }
                                                        }
         |   ArgList SEMI                               {$$ = $1;}
         |   SEMI                                       {$$ = NULL;}
         |   IF LPAR ArgList RPAR StatementError %prec ELSE     {
                                                            struct node* if_aux = createNode("If",yyval.lin,yyval.col);
                                                            struct node* tmp = $3;
                                                            while(tmp->next != NULL) {tmp = tmp->next;}
                                                            if($5 == NULL) {tmp->next = createNode("Null",yyval.lin,yyval.col); tmp->next->next = createNode("Null",yyval.lin,yyval.col);}
                                                            else {tmp->next = $5; $5->next = createNode("Null",yyval.lin,yyval.col);}
                                                            $$ = appendNode(if_aux, $3);
                                                        }
         |   IF LPAR ArgList RPAR StatementError ELSE StatementError {   
                                                            struct node* if_aux = createNode("If",yyval.lin,yyval.col);
                                                            struct node* tmp = $3;
                                                            while(tmp->next != NULL) {tmp = tmp->next;}


                                                            if($5 && !$7) {
                                                                struct node* tmp1 = $5;
                                                                int k = 0;
                                                                if(tmp1->next) k++;
                                                                if(k == 0) {tmp->next = $5; $5->next = createNode("Null",yyval.lin,yyval.col);}
                                                                else {
                                                                    struct node* statlist = createNode("StatList",yyval.lin,yyval.col);
                                                                    statlist->next = createNode("Null",yyval.lin,yyval.col);
                                                                    tmp->next = appendNode(statlist, $5);
                                                                }
                                                            }

                                                            else if(!$5 && $7) {
                                                                struct node* aux = $7;
                                                                int i = 0;
                                                                if(aux->next != NULL) i++;
                                                                if(i == 0){
                                                                    struct node* null = createNode("Null",yyval.lin,yyval.col);
                                                                    tmp->next = null;
                                                                    null->next = $7;
                                                                }
                                                                else {
                                                                    struct node* null = createNode("Null",yyval.lin,yyval.col);
                                                                    tmp->next = null;
                                                                    struct node* statlist2 = createNode("StatList",yyval.lin,yyval.col);
                                                                    null->next = appendNode(statlist2, $7);
                                                                }
                                                            }

                                                            else if($5 && $7) {
                                                                //printf("%s --- %s\n", $5->type, $7->type);
                                                                struct node* tmp2 = $5;
                                                                struct node* statlist = NULL;
                                                                struct node* tmp3 = $7;
                                                                struct node* statlist2 = NULL;
                                                                int i = 0; 
                                                                if(tmp2->next != NULL) {i++;}
                                                                if(i == 0){tmp->next = $5;}
                                                                else {
                                                                    statlist = appendNode(createNode("StatList",yyval.lin,yyval.col), $5);
                                                                    tmp->next = statlist;
                                                                }

                                                                int j = 0;
                                                                if(tmp3->next != NULL) j++;
                                                                if(j == 0) {
                                                                    if(statlist) statlist->next = $7;
                                                                    else {$5->next = $7;}
                                                                }
                                                                else {
                                                                    statlist2 = appendNode(createNode("StatList",yyval.lin,yyval.col), $7);
                                                                    if(statlist) statlist->next = statlist2;
                                                                    else {$5->next = statlist2;}
                                                                }
                                                            }

                                                            else {
                                                                struct node* A = createNode("Null",yyval.lin,yyval.col);
                                                                struct node* B = createNode("Null",yyval.lin,yyval.col);
                                                                tmp->next = A;
                                                                A->next = B;
                                                            }

                                                            if_aux = appendNode(if_aux, $3);
                                                            $$ = if_aux;
                                                        }
         |   WHILE LPAR ArgList RPAR StatementError        {   
                                                            struct node* while_token = createNode("While",yyval.lin,yyval.col);
                                                            struct node* tmp = $3;

                                                            while(tmp->next != NULL) tmp = tmp->next;
                                                            if($5) tmp->next = $5;
                                                            else tmp->next = createNode("Null",yyval.lin,yyval.col);

                                                            while_token = appendNode(while_token, $3);
                                                            $$ = while_token;
                                                        }
         |   RETURN ArgList SEMI                        {$$ = appendNode(createNode("Return",yyval.lin,yyval.col), $2);}
         |   RETURN SEMI                                {$$ = appendNode(createNode("Return",yyval.lin,yyval.col), createNode("Null",yyval.lin,yyval.col));}
         |   LBRACE error RBRACE                        {$$ = NULL; t = 1;}
         |   LBRACE RBRACE                              {$$ = NULL;}
         ;
StatementList: StatementError StatementList  {
                                                if($1) {
                                                    if($2) {
                                                        struct node* tmp = $1;
                                                        while(tmp->next) tmp = tmp->next;
                                                        tmp->next = $2;
                                                    }
                                                    $$ = $1;
                                                }
                                                else $$ = $2;
                                             }
             | StatementError                {$$ = $1;}
            ;
StatementError: Statement   {$$ = $1;}
              | error SEMI  {$$ = NULL; t = 1; /*printf("Statement -> error SEMI\n");*/}
              ;
ArgList: Expr                               {$1->flag=1; $$ = $1;}
       | ArgList COMMA Expr                 {
                                                if(debug) printf("Expr: Expr COMMA Expr\n");
                                                struct node* aux = createNode("Comma",yyval.lin,yyval.col);
                                                $1->flag=1;
                                                $3->flag=1;
                                                aux = appendNode(aux, $3);
                                                $$ = appendNode(aux, $1);
                                            }
       ;

FuncCallArgList: Expr                       {$$ = $1;}
               | FuncCallArgList COMMA Expr {
                                                if($1) {
                                                    struct node* tmp = $1;
                                                    while(tmp->next) tmp = tmp->next;
                                                    if($2) tmp->next = $3;
                                                    $$ = $1;
                                                }
                                                else if ($2) {$$ = $3;}
                                                else {$$ = NULL;}
                                                
                                            }
               ;

FunctionCall: IdToken LPAR FuncCallArgList RPAR {
                                                    if(debug) printf("FunctionCall: ID LPAR ArgumentsInFunction RPAR\n");
                                                    struct node* call = createNode("Call",yyval.lin,yyval.col);
                                                    $1->next = $3;
                                                    $1->flag = 1;
                                                    NodePtr* aux= $3;
                                                    while(aux){
                                                        aux->flag=1;
                                                        aux=aux->next;
                                                    }
                                                    call = appendNode(call, $1);
                                                    $$ = call;
                                                    //printNode($$);
                                                }
            | IdToken LPAR RPAR                 {$1->flag=1; $$ = appendNode(createNode("Call",yyval.lin,yyval.col), $1);}
            | IdToken LPAR error RPAR           {$$ = NULL; t = 1;}
            ;
Expr:  Expr ASSIGN Expr        {
                                    if(debug) printf("Assignment: ID ASSIGN Expr\n");
                                    struct node* store = createNode("Store",yyval.lin,yyval.col);
                                    $1->flag=1;
                                    $3->flag=1;
                                    store = appendNode(store, $3);
                                    $$ = appendNode(store, $1);
                                    //printNode($$); printNode($$->children); printNode($$->children->next);
                               }
    |  Expr MUL Expr           {
                                if(debug) printf("Expr: Expr OR Expr\n");
                                struct node* aux = createNode("Mul",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  Expr DIV Expr           {
                                if(debug) printf("Expr: Expr OR Expr\n");
                                struct node* aux = createNode("Div",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  Expr PLUS Expr          {
                                if(debug) printf("Expr: Expr OR Expr\n");
                                struct node* aux = createNode("Add",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  Expr MINUS Expr         {
                                if(debug) printf("Expr: Expr OR Expr\n");
                                struct node* aux = createNode("Sub",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  Expr MOD Expr           {
                                if(debug) printf("Expr: Expr OR Expr\n");
                                struct node* aux = createNode("Mod",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  Expr AND Expr           {
                                if(debug) printf("Expr: Expr OR Expr\n");
                                struct node* aux = createNode("And",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  Expr OR Expr            {
                                if(debug) printf("Expr: Expr OR Expr\n");
                                struct node* aux = createNode("Or",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  Expr BITWISEAND Expr    {
                                if(debug) printf("Expr: Expr BITWISEAND Expr\n");
                                struct node* aux = createNode("BitWiseAnd",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  Expr BITWISEOR Expr     {
                                if(debug) printf("Expr: Expr BITWISEOR Expr\n");
                                struct node* aux = createNode("BitWiseOr",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  Expr BITWISEXOR Expr    {
                                if(debug) printf("Expr: Expr BITWISEXOR Expr\n");
                                struct node* aux = createNode("BitWiseXor",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  Expr EQ Expr            {
                                if(debug) printf("Expr: Expr EQ Expr\n");
                                struct node* aux = createNode("Eq",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  Expr NE Expr            {
                                if(debug) printf("Expr: Expr NE Expr\n");
                                struct node* aux = createNode("Ne",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  Expr GE Expr            {
                                if(debug) printf("Expr: Expr GE Expr\n");
                                struct node* aux = createNode("Ge",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  Expr GT Expr            {
                                if(debug) printf("Expr: Expr GT Expr\n");
                                struct node* aux = createNode("Gt",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  Expr LE Expr            {
                                if(debug) printf("Expr: Expr LE Expr\n");
                                struct node* aux = createNode("Le",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  Expr LT Expr            {
                                if(debug) printf("Expr: Expr LT Expr\n");
                                struct node* aux = createNode("Lt",yyval.lin,yyval.col);
                                $1->flag=1;
                                $3->flag=1;
                                aux = appendNode(aux, $3);
                                $$ = appendNode(aux, $1);
                               }
    |  NOT Expr                {
                                if(debug) printf("Expr: NOT Expr\n");
                                $2->flag=1;
                                $$ = appendNode(createNode("Not",yyval.lin,yyval.col), $2);
                               }
    |  PLUS Expr %prec NOT     {
                                if(debug) printf("Expr: PLUS Expr NOT\n");
                                $2->flag=1;
                                $$ = appendNode(createNode("Plus",yyval.lin,yyval.col), $2);
                               }
    |  MINUS Expr %prec NOT    {
                                if(debug) printf("Expr: MINUS Expr NOT\n");
                                $2->flag=1;
                                $$ = appendNode(createNode("Minus",yyval.lin,yyval.col), $2);
                               }
    |  FunctionCall            {$$ = $1;}
    |  LPAR ArgList RPAR       {
                                if(debug) printf("Expr: LPAR Expr RPAR\n");
                                $$ = $2;
                               }
    |  LPAR error RPAR         {$$ = NULL; t = 1;}
    |  IdToken                 {
                                if(debug) printf("Expr: ID\n");
                                $$ = $1;
                               }
    |  INTLIT                  {
                                if(debug) printf("Expr: INTLIT\n");
                                strcpy(string, "");
                                sprintf(string, "IntLit(%s)", yyval.str_value);
                                $$ = createNode(strdup(string),yyval.lin,yyval.col);
                               }
    |  CHRLIT                  {
                                if(debug) printf("Expr: CHRLIT\n");
                                sprintf(string, "ChrLit(%s)", yyval.str_value);
                                $$ = createNode(strdup(string),yyval.lin,yyval.col);
                               }
    |  REALLIT                  {
                                if(debug) printf("Expr: REALLIT\n");
                                sprintf(string, "RealLit(%s)", yyval.str_value);
                                $$ = createNode(strdup(string),yyval.lin,yyval.col);
                               }
    ;

Typespec: CHAR      {$$ = createNode("Char",yyval.lin,yyval.col);}
        | INT       {$$ = createNode("Int",yyval.lin,yyval.col);}
        | SHORT     {$$ = createNode("Short",yyval.lin,yyval.col);}
        | DOUBLE    {$$ = createNode("Double",yyval.lin,yyval.col);}
        | VOID      {$$ = createNode("Void",yyval.lin,yyval.col);}
        ;
IdToken:  ID        {strcpy(string, ""); sprintf(string, "Id(%s)", yyval.id_value); $$ = createNode(strdup(string),yyval.lin,yyval.col);}

%%