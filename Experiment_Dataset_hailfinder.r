directory = "./" # directory
data = "hailfinder" # dataset 
N = 1000 # number of instances

library(bnlearn)
bn.fit = load(paste(directory, data, "/D_", data, ".rda", sep=""))
for (num in 1:5) {
    samples = rbn(bn, n=N)
    df <- data.frame(samples)
    write.csv(df, file=paste(directory, data, "/D_", data, "_", as.character(N), "_", as.character(num), ".csv", sep=""), row.names=FALSE)
}