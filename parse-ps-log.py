#!/bin/python3

# Parse a pystethoscope log given the following fields
#   thread, module, function, state, usec

import json
import os
import sys
from collections import defaultdict

file_name = sys.argv[1]

# categorizations
def classify_function(module_name, function_name):
    combo_tuple = (module_name, function_name)
    if (module_name == "aggr" or
        module_name == "group" or
        "hash" in function_name or #hashing
        combo_tuple == ("mkey", "rotate") or
        combo_tuple == ("algebra", "groupby") or
        combo_tuple == ("bat", "setHash")):
        return "aggregate"
    elif (module_name == "batcalc" or # misc comp
        module_name == "calc" or
        module_name == "pcre" or #regex
        combo_tuple == ("str", "replace") or #regex
        combo_tuple == ("batpcre", "replace") or #regex
        combo_tuple == ("batpcre", "replace_first") or #regex
        combo_tuple == ("algebra", "like") or #regex
        combo_tuple == ("algebra", "not_like") or #regex
        combo_tuple == ("batalgebra", "like") or #regex
        combo_tuple == ("batalgebra", "not_like") or #regex
        module_name == "txtsim" or #textstuff
        module_name == "mmath" or
        combo_tuple == ("algebra", "crossproduct") or
        combo_tuple == ("bat", "isaKey") or
        module_name == "batmmath" or
        module_name == "batstr"):
        return "compute"
    elif (combo_tuple == ("algebra", "thetaselect") or
        combo_tuple == ("algebra", "likeselect") or #regex
        combo_tuple == ("algebra", "select") or
        combo_tuple == ("algebra", "selectNotNil") or
        combo_tuple == ("algebra", "unique")):
        return "filter"
    elif (module_name == "algebra" and "join" in function_name):
        return "join"
    elif (combo_tuple == ("mat", "new") or
        combo_tuple == ("bat", "pack") or
        combo_tuple == ("mat", "pack") or
        combo_tuple == ("mat", "packIncrement") or
        combo_tuple == ("algebra", "firstn") or#limit
        combo_tuple == ("algebra", "difference") or
        combo_tuple == ("algebra", "intersect") or
        combo_tuple == ("bat", "append") or
        combo_tuple == ("bat", "replace") or
        combo_tuple == ("bat", "mirror") or
        combo_tuple == ("bat", "delete") or
        combo_tuple == ("bat", "densebat") or
        combo_tuple == ("bat", "mergecand") or
        combo_tuple == ("bat", "intersectcand") or
        combo_tuple == ("bat", "diffcand")):
        return "materialize"
    elif (combo_tuple == ("algebra", "projectionpath") or
        combo_tuple == ("algebra", "projection") or
        combo_tuple == ("algebra", "project") or
        combo_tuple == ("algebra", "slice") or
        combo_tuple == ("algebra", "subslice")):
        return "project"
    elif (combo_tuple == ("algebra", "sort") or
        combo_tuple == ("bat", "isSorted") or
        combo_tuple == ("bat", "isSortedReverse")):
        return "sort"

    return "other"

output_json_arr = []

with open(file_name) as f:
    for line in f:
        json_statement = json.loads(line)

        # parse the line and only keep if the state is "done"
        if json_statement["state"] == "done":

            # put data into a new array
            output_json_arr.append(json_statement) # ideally trimmed or tuple

# start to bucket things based on area
mod_func_usec_dict = defaultdict(int)
for json in output_json_arr:
    mod_func_usec_dict[(json.get("module"), json.get("function"))] += json.get("usec")

#for json in output_json_arr:
#    if json.get("module") == "remote" and json.get("function") == "exec":
#        # then the remote execution is the arg 2/3
#        args = json.get("args")
#        rem_module = args[2].get("value")
#        rem_func = args[3].get("value")
#        print("remote.exec: {}.{}".format(rem_module, rem_func))
#        for arg in args:
#            print("  {}".format(arg.get("value")))
#    elif json.get("module") == "remote" and json.get("function") == "register":
#        args = json.get("args")
#        rem_module = args[2].get("value")
#        rem_func = args[3].get("value")
#        print("remote.register: {}.{}".format(rem_module, rem_func))
#    #elif json.get("module") == "user":
#    #    print(json)
#    elif json.get("module") == "remote" and json.get("function") == "get":
#        print(json)

#print(mod_func_usec_dict)

#sys.exit(1)

del mod_func_usec_dict[(None, None)]
del mod_func_usec_dict[("user", "main")]

cat_usec_dict = defaultdict(int)
for i in mod_func_usec_dict.items():
    module = i[0][0]
    function = i[0][1]
    category = classify_function(module, function)
    cat_usec_dict[category] += i[1]
    print("{}.{} -> {} = {} usec".format(module, function, category, i[1]))

print("Total usec: {}".format(cat_usec_dict))

total = 0
for i in cat_usec_dict.items():
    total += i[1]

pct = {}
for i in cat_usec_dict.items():
    pct[i[0]] = i[1] * 100 / total

print("Percentage: {}".format(pct))
