directory = "./" # directory
data = "alarm" # dataset
N = 1000 # number of instances
m = 3 # maximum size of parent set

import pandas as pd 
import json
for num in range(5):    
    U_list = pd.read_csv(directory + data + "/U_" + data + "_" + str(N) + "_" + str(m) + "_" + str(num + 1) + ".csv")    
    H_list = pd.read_csv(directory + data + "/H_" + data + "_" + str(N) + "_" + str(m) + "_" + str(num + 1) + ".csv")    
    A_list = pd.read_csv(directory + data + "/A_" + data + "_" + str(N) + "_" + str(m) + "_" + str(num + 1) + ".csv")    
    C_list = pd.read_csv(directory + data + "/C_" + data + "_" + str(N) + "_" + str(m) + "_" + str(num + 1) + ".csv")    
    H = [{"c": float(H_list.iloc[i, 2]), "p": [int(H_list.iloc[i, 0]), int(H_list.iloc[i, 1])]} for i in range(len(H_list))]
    A = [{"c": float(A_list.iloc[i, 2]), "p": [int(A_list.iloc[i, 0]), int(A_list.iloc[i, 1])]} for i in range(len(A_list))]
    C = [{"c": int(C_list.iloc[i, 2]), "p": [int(C_list.iloc[i, 0]), int(C_list.iloc[i, 1])]} for i in range(len(C_list))]
    B = []
    for i in range(len(U_list.columns) - 2):
        U_list_ = U_list[U_list['i'] == i + 1]
        if len(U_list_) > 2:
            B += [{'terms': [{"c": float(1), "p": [int(h + 1), int(h + 1)]} for h in list(U_list_.index)] + [{"c": float(-2), "p": []}]}]
    with open(directory + data + "/DA_H_" + data + "_" + str(N) + "_" + str(m) + "_" + str(num + 1) + ".json", 'w') as f:
        json.dump({'binary_polynomial': {'terms': H}}, f)
    with open(directory + data + "/DA_A_" + data + "_" + str(N) + "_" + str(m) + "_" + str(num + 1) + ".json", 'w') as f:
        json.dump({'binary_polynomial': {'terms': A}}, f)
    with open(directory + data + "/DA_C_" + data + "_" + str(N) + "_" + str(m) + "_" + str(num + 1) + ".json", 'w') as f:
        json.dump({'penalty_binary_polynomial': {'terms': C}}, f)
    with open(directory + data + "/DA_B_" + data + "_" + str(N) + "_" + str(m) + "_" + str(num + 1) + ".json", 'w') as f:
        json.dump({"inequalities": B}, f)