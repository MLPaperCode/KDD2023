directory = "./" # directory
data = "alarm" # dataset
N = 1000 # number of instances
m = 3 # maximum size of parent set

import pandas as pd
for num in range(5):
    with open(directory + data + '/IP_' + data + '_' + str(N) + "_" + str(m) + "_" + str(num + 1) + '.dat.3.jkl', 'w') as f:
        D = pd.read_csv(directory + data + '/W_' + data + '_' + str(N) + "_" + str(m) + "_" + str(num + 1) + '.csv')
        D = D.sort_values(by="score", ascending=True)
        col = list(D.columns[1:-1])
        f.write(str(len(col)) + '\n') 
        for i in range(len(col)):
            D_ = D[D['i'] == (i + 1)].reset_index()[['i'] + col + ['score']]
            f.write(col[i] + ' ' + str(len(D_)) + '\n')
            for j in range(len(D_)):
                CPS = [col[k] for k in range(len(col)) if D_.iloc[j, k + 1] == 1]
                line = str(D_.iloc[j,-1]) + ' ' + str(len(CPS))
                for CP in CPS:
                    line += ' ' + CP
                f.write(line + '\n')