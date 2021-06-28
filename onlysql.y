%{
	#include <stdio.h>
	#include "operate.h"
	#include <string.h>
	#include <string>
	using namespace std;
	extern int yylex(void);
	int yyerror(const char * msg);
%}

%union {
	struct values value;

	// create table
	struct col_info_t * _colinfo;
	struct col_type_t _coltype;

	struct calvalue_t * _calvalue;
	struct insert_value_t * _insert_value;
}

%token CREATE USE SELECT INSERT UPDATE FROM WHERE INTO VALUES SET DATABASE TABLE DELETE DROP SHOW DATABASES TABLES
%token INT DOUBLE CHAR
%token ',' ';' '(' ')' '.'
%token <value> ID STRING INTNUMBER DOUBLENUMBER
%token '<' '>'
%token QUIT
%left OR
%left AND
%left '+' '-'
%left '*' '/' '%'
%left '!'


%type <value> dbname

// create table
%type <_colinfo> col cols
%type <value> colname
%type <_coltype> coltype
%type <value> tablename

// insert into
%type <_calvalue> cal
%type <_insert_value> value values valuesargs
%%

statements		:	statement 				{return 0;}		
				|	statements statement 	{return 0;}
				;

statement		:	createdb
				|	usedb
				|	showdbs
				|	showtables
				|	dropdb
				|	createsql
				|	insertsql
				|	selectsql
				|	updatesql						{printf("UPDATE\n");}
				|	deletesql						{printf("DELETE\n");}
				| 	QUIT							{puts("BYE..."); exit(0);}
				;


createdb		:	CREATE DATABASE dbname ';' {create_db($3);}
				;

usedb			:	USE DATABASE dbname ';' {use_db($3.name);}
				|	USE dbname ';' 			{use_db($2.name);}
				;
				
dbname			:	ID {	   
							$$.length = $1.length;
							$$.name = new char[$1.length+1];
							strcpy($$.name,$1.name);}
				;

showdbs			: 	SHOW DATABASES	';'			{show_dbs();};

dropdb			:	DROP DATABASE dbname ';'	{drop_db($3.name);}

showtables		:	SHOW TABLES	';'				{show_tables();};


createsql		:	CREATE TABLE tablename '(' cols ')' ';' { create_table($3.name, $5); }
				;

tablename		:	ID { $$.length = $1.length;
						 $$.name = new char[$1.length+1];
						 strcpy($$.name,$1.name);}
				;

cols			:	cols ',' col { $$ = $1; while($1->next!=NULL)$1 = $1->next; $1->next = $3;}
				|	col { $$ = $1; }
				;

col				:	colname coltype {
	$$ = new struct col_info_t;
	$$->col_name = new char[$1.length+1];
	$$->name_length = $1.length;
	strcpy($$->col_name, $1.name);
	$$->col_type = $2.col_type;
	$$->length = $2.length;
	$$->next = nullptr;
};

colname			:	ID {
							$$.length = $1.length;
							$$.name = new char[$1.length+1];
							strcpy($$.name,$1.name);
};
				
coltype			:	INT { $$.col_type = 1; }
				|	DOUBLE {{ $$.col_type = 2; }}
				|	CHAR'('INTNUMBER')' {{ $$.col_type = 3; $$.length = $3.intnum; }}
				;

selectsql		:	select';'
				;

select			:	SELECT tablecolconf FROM tables whereconf
				|	SELECT tablecolconf FROM tables
				| 	SELECT '*' FROM tablename { select_sql($4.name); }
				;
				
tablecolconf	:	tablecols
				;
				
tablecols		:	tablecol
				|	tablecols ',' tablecol
				;

tablecol		:	colname
				|	tablename '.' colname
				|	STRING
				;

tables			:	tablename
				|	tables ',' tablename
				;
				
whereconf		:	WHERE conditions
				;

conditions		:	condition
				|	conditions AND	conditions
				|	conditions OR	conditions
				|	'('conditions')'
				;
				
condition		:	comparator comp_op comparator
				;

comparator		:	cal
				|	tablecol
				;

comp_op			:	'<'
				|	'>'
				|	'<''='
				|	'>''='
				|	'='
				|	'!''='
				;
				
insertsql		:	INSERT INTO tablename insertcolname valuesargs ';'
				|	INSERT INTO	tablename valuesargs ';' { insert_into($3.name, $4); }
				;

insertcolname	:	'('colnames')'
				;
				
colnames		:	colnames ',' colname
				|	colname
				;

valuesargs		:	VALUES'('values')'  { $$ = $3; }
				;

values			:	value 				{$$ = $1; }

				|	values ',' value	{ 	$$ = $1;
										 	while ($1->next) { $1 = $1->next; }
										 	$1->next = $3;
										}
				;

value			:	STRING {$$ = new struct insert_value_t;
							$$->data = new char[$1.length+1];
							$1.name[strlen($1.name)-1] = '\0';
							strcpy($$->data, $1.name+1); 
							$$->next = nullptr; }

				|	cal		{
							 calculate($1);
							 $$ = new struct insert_value_t;
							 if ($1->valuetype == 1) {
								 $$->data = new char[to_string($1->intnum).length()+1];
								 strcpy($$->data, (char*)to_string($1->intnum).c_str());
							 } else if ($1->valuetype == 2) {
								 $$->data = new char[to_string($1->doublenum).length()+1];
								 strcpy($$->data, (char*)to_string($1->doublenum).c_str());
							 }
							 $$->next = nullptr;
							}
				;

cal 			:	cal '+' cal {   $$ = new struct calvalue_t;
				  					$$->valuetype = 3;
				                    $$->caltype = 1;
				  					$$->leftcal = $1;
				  					$$->rightcal = $3;}

				|	cal '-' cal { 	$$ = new struct calvalue_t;
				  				  	$$->valuetype = 3;
				  					$$->caltype = 2;
				  					$$->leftcal = $1;
				  					$$->rightcal = $3;}
									  
				|	cal '*' cal {	$$ = new struct calvalue_t;
				  					$$->valuetype = 3;
				  					$$->caltype = 3;
				  					$$->leftcal = $1;
				  					$$->rightcal = $3;}

				|	cal '/' cal {	$$ = new struct calvalue_t;
				  					$$->valuetype = 3;
				  					$$->caltype = 4;
                  					$$->leftcal = $1;
				 					$$->rightcal = $3;}
				|	'-'cal		{	$$ = new struct calvalue_t;
                  					$$->valuetype = 3;
				  					$$->caltype = 2;
				  					$$->leftcal = NULL;
				  					$$->rightcal = $2;}

				|	'('cal')'	{	$$ = $2;}

				|	INTNUMBER	{ 	$$ = new struct calvalue_t;
                   					$$->valuetype = 1;
				   					$$->leftcal = NULL;
				   					$$->rightcal = NULL;
				   					$$->intnum = $1.intnum;}
		
				|	DOUBLENUMBER {	$$ = new struct calvalue_t;
                   					$$->valuetype = 2;
				   					$$->leftcal = NULL;
				   					$$->rightcal = NULL;
				   					$$->doublenum = $1.doublenum; }
				;
				
updatesql		:	UPDATE tablename SET setconfs whereconf';'
				|	UPDATE tablename SET setconfs';'
				;

setconfs		:	setconf
				|	setconfs ',' setconf
				;
				
setconf			:	colname '=' value
				;

deletesql		:	DELETE FROM tablename whereconf';'
				|	DELETE FROM tablename';'
				;

%%

int main() {
    const char *wel =
        " .d88b.  d8b   db db      db    db .d8888.  .d88b.  db      \n"
        ".8P  Y8. 888o  88 88      `8b  d8' 88'  YP .8P  Y8. 88      \n"
        "88    88 88V8o 88 88       `8bd8'  `8bo.   88    88 88      \n"
        "88    88 88 V8o88 88         88      `Y8b. 88    88 88      \n"
        "`8b  d8' 88  V888 88booo.    88    db   8D `8P  d8' 88booo. \n"
        " `Y88P'  VP   V8P Y88888P    YP    `8888Y'  `Y88'Y8 Y88888P \n";
    puts(wel);
	printf("fffzlfk> ");
    while (1) {
        yyparse();
		printf("\nfffzlfk> ");
    }
    return 0;
}

int yyerror(const char *msg) {
    printf("syntax error !");
    return -1;
}