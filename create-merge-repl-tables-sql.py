#!/bin/python3

import os
import sys
import re

all_worker_remote_tables = sys.argv[1]
all_repl_tables = sys.argv[2]

tbl_files = [f for f in os.listdir(all_worker_remote_tables) if os.path.isfile(os.path.join(all_worker_remote_tables, f))]
repl_tbl_files = [f for f in os.listdir(all_repl_tables) if os.path.isfile(os.path.join(all_repl_tables, f))]

# num of workers should equal size of remote folder
worker_num = len(tbl_files)

strlist = []

# assume each file shares the same replica or not
tab_f = repl_tbl_files[0]
replicated_tabs = []
with open(all_repl_tables + "/" + tab_f, 'r') as f:
    for line in f.readlines():
        replicated_tabs.append(line.strip())
replicated_tabs = set(replicated_tabs)

# assume each file shares the same replica or not
sql_f = tbl_files[0]
with open(all_worker_remote_tables + "/" + sql_f, 'r') as f:
    for line in f.readlines():
        match = re.match(r"CREATE REMOTE TABLE (.*)_.* (\(.*\)) on .*;", line)
        if match:
            name = match.group(1)
            schema = match.group(2)
            if name in replicated_tabs:
                # add to file as replica (keep track of name, and schema)
                strlist.append("CREATE REPLICA TABLE {} {};".format(name, schema))
                for i in range(1, worker_num + 1):
                    strlist.append("ALTER TABLE {} ADD TABLE {};".format(name, name + "_{}".format(i)))
            else:
                # add to file as merge table (again also need name, schema)
                strlist.append("CREATE MERGE TABLE {} {};".format(name, schema))
                for i in range(1, worker_num + 1):
                    strlist.append("ALTER TABLE {} ADD TABLE {};".format(name, name + "_{}".format(i)))
        else:
            print("Something went wrong")
            sys.exit(1)

for item in strlist:
    print(item)
