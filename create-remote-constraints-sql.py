#!/bin/python3

import os
import sys
import re

# order to construct merge/replica tables
# determined by sketching graph where leaf nodes are the tables with the foreign key
# build everything from leaf node towards root
construct_order = ["region", "nation", "customer", "supplier", "part", "orders", "partsupp", "lineitem"]

# all remote tbls w/ their schema
all_worker_remote_tbls = sys.argv[1]
# all remote tbls that are replicas of one another
all_repl_tbls = sys.argv[2]
# file holding list of ipaddresses
ipaddr_f = sys.argv[3]
# ip address to generate sql file for
target_ip = sys.argv[4]

tbl_files = [f for f in os.listdir(all_worker_remote_tbls) if os.path.isfile(os.path.join(all_worker_remote_tbls, f))]
repl_tbl_files = [f for f in os.listdir(all_repl_tbls) if os.path.isfile(os.path.join(all_repl_tbls, f))]

# num of workers should equal size of remote folder
worker_num = len(tbl_files)

strlist = []

ip_addrs = []
with open(ipaddr_f, 'r') as f:
    for line in f:
        ip_addrs.append(line.strip())
follower_num = int(ip_addrs.index(target_ip)) + 1

## GET A SET OF REPLICA TABLES

# assume each file shares the same replica or not
repl_tbl_f = repl_tbl_files[0]
replicated_tbls = []
with open(all_repl_tbls + "/" + repl_tbl_f, 'r') as f:
    for line in f.readlines():
        replicated_tbls.append(line.strip())
replicated_tbls = set(replicated_tbls)

## GET METADATA FOR EACH TABLE

# name -> (schema <str>, merge or replica <str>)
metadata = {}
db_name = ""
port_num = ""

# assume each file shares the same set of remote tables
remote_sql_f = tbl_files[0]
with open(all_worker_remote_tbls + "/" + remote_sql_f, 'r') as f:
    for line in f.readlines():
        match = re.match(r"CREATE REMOTE TABLE (.*)_.* \((.*)\) on .*:(.*)/(.*)';", line)
        if match:
            name = match.group(1)
            schema = match.group(2)
            port_num = match.group(3)
            db_name = match.group(4)
            metadata[name] = (schema, "REPLICA" if name in replicated_tbls else "MERGE")
        else:
            print("ERROR: Something went wrong")
            sys.exit(1)

# return (list_prim_keys, list_foreign)
def get_alter(name):
    if name == "region":
        return ("r_regionkey", [])
    elif name == "nation":
        return ("n_nationkey", [("n_regionkey", "region")])
    elif name == "part":
        return ("p_partkey", [])
    elif name == "supplier":
        return ("s_suppkey", [("s_nationkey", "nation")])
    elif name == "customer":
        return ("c_custkey", [("c_nationkey", "nation")])
    elif name == "orders":
        return ("o_orderkey", [("o_custkey", "customer")])
    elif name == "partsupp":
        return ("ps_partkey,ps_suppkey", [("ps_suppkey", "supplier"), ("ps_partkey", "part")])
    elif name == "lineitem":
        return ("l_orderkey,l_linenumber", [("l_orderkey", "orders"), ("l_partkey,l_suppkey", "partsupp")])

# 1. Add primary key and foreign key for each tbl shard
# 2. Create overall tbl with same primary/foreign key
# 3. Add all shards to the tbl
for tbl in construct_order:
    name = tbl
    schema = metadata[tbl][0]
    typ = metadata[tbl][1]

    alter_meta = get_alter(name)
    primary_key = alter_meta[0]
    foreign_keytbl_list = alter_meta[1]

    # create remote tables
    #for idx, ip_addr in zip(range(1, worker_num + 1), ip_addrs):
    #    if ip_addr != target_ip:
    #        strlist.append("CREATE REMOTE TABLE {}_{} ({}) on 'mapi:monetdb://{}:{}/{}';".format(
    #            name,
    #            idx,
    #            schema,
    #            ip_addr,
    #            port_num,
    #            db_name))

    #        strlist.append("ALTER TABLE {}_{} ADD CONSTRAINT {}_pk_{} PRIMARY KEY ({});".format(
    #            name,
    #            idx,
    #            name,
    #            idx,
    #            primary_key))

    #    #for cnt, foreign_keytbl in enumerate(foreign_keytbl_list):
    #    #    strlist.append("ALTER TABLE {}_{} ADD CONSTRAINT {}_fk_{}_{} FOREIGN KEY ({}) references {};".format(
    #    #        name,
    #    #        idx,
    #    #        name,
    #    #        idx,
    #    #        cnt,
    #    #        foreign_keytbl[0],
    #    #        foreign_keytbl[1]))

    ## create merge/replica table def
    #strlist.append("CREATE {} TABLE {} ({});".format(
    #    typ,
    #    name,
    #    schema))

    #strlist.append("ALTER TABLE {} ADD CONSTRAINT {}_pk PRIMARY KEY ({});".format(
    #    name,
    #    name,
    #    primary_key))

    for cnt, foreign_keytbl in enumerate(foreign_keytbl_list):
        strlist.append("ALTER TABLE {} ADD CONSTRAINT {}_fk_{} FOREIGN KEY ({}) references {};".format(
            name + f"_{follower_num}",
            name + f"_{follower_num}",
            cnt,
            foreign_keytbl[0],
            foreign_keytbl[1] + f"_{follower_num}"))

    # add shards to table
    #for idx in range(1, worker_num + 1):
    #    strlist.append("ALTER TABLE {} ADD TABLE {}_{};".format(name, name, idx))

for item in strlist:
    print(item)
