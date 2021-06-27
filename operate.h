struct values {
    char *name;
    int intnum;
    double doublenum;
    int length;
};


struct col_info_t {
    char *col_name;
    int name_length;
    int col_type; // 1: int, 2: double, 3: CHAR
    int length;
    struct col_info_t *next;
};

struct col_type_t {
    int col_type; // 1: int, 2: double, 3: CHAR
    int length;
};

// insert

struct calvalue_t {
	//valuetype: 1是int，2是double，3是表达式（如 1+2）；
	int valuetype;
	int intnum;
	double doublenum;
	struct calvalue_t* leftcal;
	//caltype: 1是+，2是-，3是*，4是/
	int caltype;
	struct calvalue_t* rightcal;
};

struct insert_value_t {
    char *data;
    struct insert_value_t *next;
};

void show_dbs();

void show_tables();

void create_db(struct values value);

void use_db(char *dbname);

void drop_db(char *dbname);

void create_table(char *table_name, struct col_info_t* cols);

void calculate(struct calvalue_t* cal);

void insert_into(char *table_name, struct insert_value_t* insert_value);

void select_sql(char *);
