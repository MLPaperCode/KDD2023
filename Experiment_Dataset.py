directory = "./" # directory
data = "alarm" # dataset
N = 1000 # number of instances

from pgmpy.readwrite import BIFReader
from pgmpy.models import BayesianModel 
from pgmpy.sampling import BayesianModelSampling
reader = BIFReader(directory + data + "/D_" + data + ".bif")
model = reader.get_model()
BN = BayesianModel(model.edges)
for node in model.nodes:
    BN.add_node(node)
for cpd in model.get_cpds():
    prob = cpd.get_values()
    for j in range(prob.shape[1]):
        prob[:, j] /= sum(prob[:, j]) 
    BN.add_cpds(cpd)
BMS = BayesianModelSampling(BN)
for num in range(5):
    D = BMS.forward_sample(size=N)
    D.to_csv(directory + data + "/D_" + data + "_" + str(N) + "_" + str(num + 1) + ".csv", index=False)