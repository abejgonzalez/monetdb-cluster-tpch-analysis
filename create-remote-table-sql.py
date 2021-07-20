#!/bin/python3

import os
import sys

output_table_dir = sys.argv[1]
remote_table_file_sql = sys.argv[2]
scale_factor = sys.argv[3]
port = sys.argv[4]
worker_num = sys.argv[5]
host = sys.argv[6]

only_tbl_files = [f for f in os.listdir(output_table_dir) if os.path.isfile(os.path.join(output_table_dir, f))]

dbname = "SF-{}".format(scale_factor)

def create_remote_sql(name):
    if name.endswith(".tbl"):
        table = name[0:-4]
        table = table + "_{}".format(worker_num)
    else:
        table = name.replace(".tbl.", "_")

    schema = ""
    if "nation" in name:
        schema = "( N_NATIONKEY INTEGER NOT NULL, N_NAME CHAR(25) NOT NULL, N_REGIONKEY INTEGER NOT NULL, N_COMMENT VARCHAR(152))"
    elif "region" in name:
        schema = "( R_REGIONKEY INTEGER NOT NULL, R_NAME CHAR(25) NOT NULL, R_COMMENT VARCHAR(152))"
    elif "part" in name:
        schema = "( P_PARTKEY INTEGER NOT NULL, P_NAME VARCHAR(55) NOT NULL, P_MFGR CHAR(25) NOT NULL, P_BRAND CHAR(10) NOT NULL, P_TYPE VARCHAR(25) NOT NULL, P_SIZE INTEGER NOT NULL, P_CONTAINER CHAR(10) NOT NULL, P_RETAILPRICE DECIMAL(15,2) NOT NULL, P_COMMENT VARCHAR(23) NOT NULL )"
    elif "supplier" in name:
        schema = "( S_SUPPKEY INTEGER NOT NULL, S_NAME CHAR(25) NOT NULL, S_ADDRESS VARCHAR(40) NOT NULL, S_NATIONKEY INTEGER NOT NULL, S_PHONE CHAR(15) NOT NULL, S_ACCTBAL DECIMAL(15,2) NOT NULL, S_COMMENT VARCHAR(101) NOT NULL)"
    elif "partsupp" in name:
        schema = "( PS_PARTKEY INTEGER NOT NULL, PS_SUPPKEY INTEGER NOT NULL, PS_AVAILQTY INTEGER NOT NULL, PS_SUPPLYCOST DECIMAL(15,2)  NOT NULL, PS_COMMENT VARCHAR(199) NOT NULL )"
    elif "customer" in name:
        schema = "( C_CUSTKEY INTEGER NOT NULL, C_NAME VARCHAR(25) NOT NULL, C_ADDRESS VARCHAR(40) NOT NULL, C_NATIONKEY INTEGER NOT NULL, C_PHONE CHAR(15) NOT NULL, C_ACCTBAL DECIMAL(15,2) NOT NULL, C_MKTSEGMENT CHAR(10) NOT NULL, C_COMMENT VARCHAR(117) NOT NULL)"
    elif "orders" in name:
        schema = "( O_ORDERKEY BIGINT NOT NULL, O_CUSTKEY INTEGER NOT NULL, O_ORDERSTATUS CHAR(1) NOT NULL, O_TOTALPRICE DECIMAL(15,2) NOT NULL, O_ORDERDATE DATE NOT NULL, O_ORDERPRIORITY  CHAR(15) NOT NULL, O_CLERK CHAR(15) NOT NULL, O_SHIPPRIORITY INTEGER NOT NULL, O_COMMENT VARCHAR(79) NOT NULL)"
    elif "lineitem" in name:
        schema = "( L_ORDERKEY BIGINT NOT NULL, L_PARTKEY INTEGER NOT NULL, L_SUPPKEY INTEGER NOT NULL, L_LINENUMBER INTEGER NOT NULL, L_QUANTITY DECIMAL(15,2) NOT NULL, L_EXTENDEDPRICE  DECIMAL(15,2) NOT NULL, L_DISCOUNT DECIMAL(15,2) NOT NULL, L_TAX DECIMAL(15,2) NOT NULL, L_RETURNFLAG CHAR(1) NOT NULL, L_LINESTATUS CHAR(1) NOT NULL, L_SHIPDATE DATE NOT NULL, L_COMMITDATE DATE NOT NULL, L_RECEIPTDATE DATE NOT NULL, L_SHIPINSTRUCT CHAR(25) NOT NULL, L_SHIPMODE CHAR(10) NOT NULL, L_COMMENT VARCHAR(44) NOT NULL)"
    else:
        sys.exit(1)

    return "CREATE REMOTE TABLE {} {} on \'mapi:monetdb://{}:{}/{}\';".format(
            table,
            schema,
            host,
            port,
            dbname)

with open(remote_table_file_sql, "w") as f:
    for sql_f in only_tbl_files:
        remote_sql_str = create_remote_sql(sql_f)
        f.write(remote_sql_str)
        f.write("\n")

