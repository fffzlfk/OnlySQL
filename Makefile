EXE : lex
	g++ lex.yy.c y.tab.c operate.cc -o onlysql

lex : onlysql.l yacc
	lex onlysql.l

yacc : 
	yacc -vdty onlysql.y

clean :
	rm lex.yy.c  y.tab.c y.output y.tab.h onlysql