directory = "./" # directory
data = "alarm" # dataset
N = 1000 # number of instances
m = 3 # maximum size of parent set
running_time = 600 # running time [s]
version = 'v4' # version

import pandas as pd 
import json
import networkx as nx
from DA import DA3Solver
from info import get_info
rest_url, access_key, proxies = get_info(version)
def to_set(A):
    return set([h for h, a in enumerate(A) if a > 0])
headers = {'content-type': 'application/json'}
DA3 = DA3Solver(running_time, rest_url, access_key, version, proxies, headers)
score_list = []
for num in range(5):
    A_list = pd.read_csv(directory + data + "/A_" + data + "_" + str(N) + "_" + str(m) + "_" + str(num + 1) + ".csv")     
    U_list = pd.read_csv(directory + data + "/U_" + data + "_" + str(N) + "_" + str(m) + "_" + str(num + 1) + ".csv")    
    with open(directory + data + "/DA_A_" + data + "_" + str(N) + "_" + str(m) + "_" + str(num + 1) + ".json") as f:
        request = json.loads(f.read())
    with open(directory + data + "/DA_B_" + data + "_" + str(N) + "_" + str(m) + "_" + str(num + 1) + ".json") as f:
        request.update(json.loads(f.read()))
    with open(directory + data + "/DA_C_" + data + "_" + str(N) + "_" + str(m) + "_" + str(num + 1) + ".json") as f:
        request.update(json.loads(f.read()))
    response = DA3.minimize(request)
    for r in response._solution_histogram:
        res = r.configuration
        break    
    n = len(U_list.columns) - 2
    for i in range(n):
        count = 0
        for h in range(len(U_list)):
            if (res[str(h + 1)] == True) and (U_list.iloc[h, 0] == i + 1):
                count += 1
        if count > 2:
            print("Constraint Error")    
    edges = []
    for h in range(len(U_list)): 
        if res[str(h + 1)] == True:
            for i in range(n): 
                if U_list.iloc[h, i + 1] == 1:
                    edges += [(i + 1, U_list.iloc[h, 0])]
    edges = list(set(edges))
    G = nx.DiGraph(edges)        
    if nx.is_directed_acyclic_graph(G) == False:          
        print("Constraint Error")    
    score = 0.0
    for h in range(len(A_list)):
        if (res[str(A_list.iloc[h, 0])] == True) and (res[str(A_list.iloc[h, 1])] == True):
            score -= A_list.iloc[h, 2]    
    print("score:", score)    
    score_list += [[score]]
    graph = pd.DataFrame([[e[0], e[1]] for e in edges])
    graph.columns = ["parent", "child"]
    graph = graph.astype('int64')
    graph.to_csv(directory + data + "/Graph_DA_" + version + "_" + str(running_time) + "_" + data + "_" + str(N) + "_" + str(m) + "_" + str(num + 1) + ".csv", index=False)    
score_list = pd.DataFrame(score_list)
score_list.columns = ["score"]
score_list.to_csv(directory + data + "/Score_DA_" + version + "_" + str(running_time) + "_" + data + "_" + str(N) + "_" + str(m) + ".csv", index=False)