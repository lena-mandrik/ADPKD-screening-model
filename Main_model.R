source("R files/Load.Data.R")
source("R files/Set.Params.R")
source("R files/pop.func.R")
source("R files/NHD.R")
source("R files/Outcomes.R")

# Set the seed before any random number is used. `seed` is defined in the Rmd
if (exists("seed")) set.seed(seed)

# Generate all parameter sets
# This function only generates parameters from Parameters file
Param_sets <- f.generate_parameters(Parameters, N.sets)

# Additional parameters
p.Dial.Death <- f.Param.Dial(par.Dialysis.by.age, Death.All.cause, Death.HR, Param_sets, p.set,
                             deterministic = TRUE)

#Set costs and QALYs discount weights
v.dwc <- 1 / (1 + d.c) ^ (0:(t.horizon))   # calculate the cost discount weight based on the discount rate d.c
v.dwe <- 1 / (1 + d.e) ^ (0:(t.horizon))   # calculate the QALY discount weight based on the discount rate d.e
