%{
#include <stdio.h>
#include "operate.h"
#include "y.tab.h"

%}

%option caseless


create create
drop drop
table table
database database
use use
select select
insert insert
delete delete
update update
from from
where where
into into
values values
set set
int int
double double
char char
and and
or or
show show
databases databases
tables tables




digit [0-9]


character [A-Za-z]


int_digits {digit}+


double_digits {digit}+((\.{digit}+)?(([eE][+-]?)?{digit}+)?)

variality ({character}|_)({character}|_|{digit})*


string \"(\\.|[^"\\])*\"

quit quit

%%

{create}		{return CREATE;}
{drop}			{return DROP;}
{table}			{return TABLE;}
{database}		{return DATABASE;}
{use}			{return USE;}
{select}		{return SELECT;}
{insert}		{return INSERT;}
{delete}		{return DELETE;}
{update}		{return UPDATE;}
{from}			{return FROM;}
{where}			{return WHERE;}
{into}			{return INTO;}
{values}		{return	VALUES;}
{set}			{return SET;}
{int}			{return INT;}
{double}		{return DOUBLE;}
{char}			{return CHAR;}
{and}			{return AND;}
{or}			{return OR;}
{show}			{return SHOW;}
{databases}		{return DATABASES;}
{tables}		{return TABLES;}

{quit} {
	return QUIT;
}

{variality} {
	yylval.value.name = new char[strlen(yytext)+1];
	yylval.value.length = strlen(yytext)+1;
	strcpy(yylval.value.name,yytext);
	return ID; }

{string} { yylval.value.length = strlen(yytext)+1;
    yylval.value.name = new char[strlen(yytext)+1];
    strcpy(yylval.value.name, yytext);
    return STRING; }

[-+*/{}(),=;.] { return yytext[0]; }

{int_digits} {  yylval.value.length = 4;
    			yylval.value.intnum = atoi(yytext);
    			return INTNUMBER; }

{double_digits} {   yylval.value.length = 8;
    				yylval.value.doublenum = atof(yytext);
   					return DOUBLENUMBER;}

# {return 0;}


[ \n\t]+

%%

int yywrap() {
	return 1;
}