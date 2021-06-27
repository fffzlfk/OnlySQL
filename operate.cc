#include "operate.h"
#include <cassert>
#include <cstring>
#include <fstream>
#include <iostream>
#include <sstream>
#include <sys/stat.h>
#include <sys/types.h>
#include <vector>
#include <list>
#include <unordered_set>
#include <unistd.h>
using namespace std;

string DbName;

void show_dbs() {
    ifstream in("./DB/db.dat", ios::in | ios::binary);
    list<string> dbs;
    string name;
    while (in >> name) {
        dbs.push_back(name);
    }
    puts("--------------");
    for (auto &&e : dbs) {
        printf("%10s\n", e.c_str());
        puts("--------------");
    }
    in.close();
}

void create_db(struct values value) {
    ifstream in("./DB/db.dat", ios::in | ios::binary);
    ofstream out("./DB/db.dat", ios::out | ios::app);
    string dbname(value.name);
    string name;
    while (in >> name) {
        if (name == dbname) {
            cout << "database has existed!" << endl;
            in.close();
            return;
        }
    }
    out << dbname << endl;
    out.close();
    cout << dbname << endl;
    string path = "./DB/" + dbname;
    int isCreate =
        mkdir(path.c_str(), S_IRUSR | S_IWUSR | S_IXUSR | S_IRWXG | S_IRWXO);
    if (!isCreate)
        printf("create path:%s\n", path.c_str());
    else
        printf("create path failed! error code : %s \n", isCreate, path);
    printf("Successfully run, create database %s\n", dbname.c_str());
}

void use_db(char *name) {
    string path = "./DB/db.dat";
    ifstream in(path);
    DbName = string(name);
    if (!in.is_open()) {
        printf("database %s doesn't exist\n", name);
        return;
    }
    printf("Successfully run, use database %s\n", name);
}

void drop_db(char *dbname) {
    ifstream in("./DB/db.dat", ios::in | ios::binary);
    list<string> dbs;
    string name;
    auto ok = false;
    while (in >> name) {
        if (name == string(dbname)) {
            ok = true;
            continue;
        }
        dbs.push_back(name);
    }
    if (!ok) {
        printf("database %s doesn't exist\n", dbname);
        return;
    }
    ofstream out("./DB/db.dat", ios::out | ios::trunc);
    for (auto &&e : dbs) {
        out << e << endl;
    }
    out.close();
    auto path = "./DB/" + string(dbname);
    rmdir(path.c_str());
    printf("Successfully run, drop table %s\n", dbname);
}

void show_tables() {
    if (DbName == "") {
        cout << "doesn't use database!" << endl;
        return;
    }
    string path = "./DB/" + DbName + "/sys.dat";

    unordered_set<string> st;
    ifstream in(path);
    string str;
    while (getline(in, str)) {
        istringstream ss(str);
        string name;
        ss >> name;
        st.insert(name);
    }

    puts("--------------");
    for (auto &&e : st) {
        printf("%10s\n", e.c_str());
        puts("--------------");
    }

    in.close();
}

void create_table(char *table_name, struct col_info_t *cols) {
    if (DbName == "") {
        cout << "doesn't use database!" << endl;
        return;
    }
    ofstream out("./DB/" + DbName + "/sys.dat", ios::app);
    while (cols) {
        out << table_name << " " << cols->col_name << " " << cols->col_type;
        if (cols->col_type == 3) {
            out << " " << cols->length << endl;
        } else {
            out << endl;
        }
        cols = cols->next;
    }
    printf("Successfully run, create a table");
    out.close();
}

void calculate(struct calvalue_t* cal) {
	if (cal->valuetype == 3) {
		calculate(cal->rightcal);
		if (cal->leftcal) {
			calculate(cal->leftcal);
		}
		if (cal->leftcal) {
			auto left = cal->leftcal, right = cal->rightcal;
			if (left->valuetype == 1 && right->valuetype == 1) {
				cal->valuetype = 1;
				switch (cal->caltype) {
				case 1: cal->intnum = left->intnum + right->intnum; break;
				case 2: cal->intnum = left->intnum - right->intnum; break;
				case 3:	cal->intnum = left->intnum * right->intnum; break;
				case 4:	cal->intnum = left->intnum / right->intnum; break;
				default:
					break;
				}
			} else if (left->valuetype == 1) {
				cal->valuetype = 2;
				switch (cal->caltype) {
				case 1: cal->doublenum = left->intnum + right->doublenum; break;
				case 2: cal->doublenum = left->intnum - right->doublenum; break;
				case 4:	cal->doublenum = left->intnum / right->doublenum; break;
				case 3:	cal->doublenum = left->intnum * right->doublenum; break;
				default:
					break;
				}
			}
			else if (right->valuetype == 1) {
				cal->valuetype = 2;
				switch (cal->caltype) {
				case 1: cal->doublenum = left->doublenum + right->intnum; break;
				case 2: cal->doublenum = left->doublenum - right->intnum; break;
				case 4:	cal->doublenum = left->doublenum / right->intnum; break;
				case 3:	cal->doublenum = left->doublenum * right->intnum; break;
				default:
					break;
				}
			} else {
				cal->valuetype = 2;
				switch (cal->caltype) {
				case 1: cal->doublenum = left->doublenum + right->doublenum; break;
				case 2: cal->doublenum = left->doublenum - right->doublenum; break;
				case 4:	cal->doublenum = left->doublenum / right->doublenum; break;
				case 3:	cal->doublenum = left->doublenum * right->doublenum; break;
				default:
					break;
				}
			}
		} else {
			if (cal->rightcal->valuetype == 1) {
				cal->valuetype = 1;
				cal->intnum = -cal->rightcal->intnum;
			}
			else {
				cal->valuetype = 2;
				cal->doublenum = -cal->rightcal->doublenum;
			}
		}
	}
	return;
}

void insert_into(char *table_name, struct insert_value_t* insert_value) {
    if (DbName == "") {
        cout << "doesn't use database!" << endl;
        return;
    }
    string path = "./DB/" + DbName + "/sys.dat";

    ifstream in(path);
    string str;
    bool flag = false;
    while (getline(in, str)) {
        if (str.find(string(table_name)) != string::npos) {
            flag = true;
            break;
        }
    }
    if (!flag) {
        cout << "table: " << table_name << " doesn't exists!" << endl;
        return;
    }

    path = "./DB/" + DbName + "/" + string(table_name) + ".txt";
    ofstream out(path, ios::app);
    auto cnt = 0;
    while (insert_value) {
        out << insert_value->data << " ";
        insert_value = insert_value->next;
        cnt++;
    }
    out << endl;
    printf("Successfully run, insert %d rows\n", cnt);
    out.close();
}

void select_sql(char *table_name) {
    if (DbName == "") {
        cout << "doesn't use database!" << endl;
        return;
    }
    string path = "./DB/" + DbName + "/sys.dat";
    ifstream in(path);

    string str;
    list<string> cols;
    auto ok = false;
    while (getline(in, str)) {
        istringstream ss(str);
        string col;
        ss >> col;
        if (col != string(table_name)) continue;
        ok = true;
        ss >> col;
        cols.push_back(col);
    }
    if (!ok) {
        cout << "table: " << table_name << " doesn't exists!" << endl;
        return;
    }
    
    for (auto &&i : cols) {
        printf("%-10s\t", i.c_str());
    }
    puts("\n---------------------------------------");

    int cnt = 0;
    path = "./DB/" + DbName + "/" + string(table_name) +".txt";
    in = ifstream(path);
    while (getline(in, str)) {
        istringstream ss(str);
        string col;
        while (ss >> col) {
            printf("%-10s\t", col.c_str());
        }
        cnt++;
        puts("");
    }
    printf("Successfully run, query %d rows\n", cnt);
    in.close();
}