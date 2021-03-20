#@time
import Pkg; 
Pkg.add("JuMP")
Pkg.add("GLPK")
Pkg.add("MathOptFormat")
using JuMP
using GLPK     ##改成 cplex julia add cplex let julia know  environment of cplex
using DelimitedFiles
using SparseArrays
using MathOptFormat

#math arangement




m = Model(with_optimizer(GLPK.Optimizer, msg_lev = GLPK.MSG_ALL, mip_gap=5e-4))
# Variables
@variables m begin
	P_g[iG = 1:nG,iN = 1:nN], base_name="decision variable",   
    P_sd[iS = 1:nS, iN = 1:nN], base_name="decision variable" # 词典

    P_sc[iS = 1:nS, iN = 1:nN], 
    PWN[iN = 1:nN],      
    PWC[iN = 1:nN], base_name="decision variable"
    PD[iN = 1:nN],
    PLS[iN = 1:nN], base_name="decision variable"  
    P_g[iG = 1:nG],
    PMAX_g[iG = 1:nG],
    NUP_g[iG = 1:nG,iN = 1:nN],
    dPMAX_L,
    HMAX_L,
    f0,
    R[iN = 1:nN],
    R_g[iG = 1:nG,iN = 1:nN],   
    R_s[iS = 1:nS, iN = 1:nN],




end

##

# Objective Function
# sum of operation cost of thermal unit g at node n + value of lost load * load shed at node n
@objective(m, Min,
            sum(PI[iN] * sum(C_g[iG,iN] for iT = 1:nN) + dtao[iN] * cLS * PLS(iN)		# 
			for iN = 1:nN)
        )
 
#Constraints
@constraint(m, A2[iG = 1:nG,iS = 1:nS, iT = 1:nN], 
        sum(P_sd[iS,iN] - P_sc[iS,iN]for iS = 1:nS) + PWN[iN] - PWC[iN] 
        == PD[iN]-PLS[iN])

@constraint(m, A3[iT = 1:nN], 
        (sum(H_g[iG] * P_gMAX[iG]* N_gup[iG,iN] for iT = 1:nN) - dP_LMAX * H_LMAX)/f0
        == H[iN])

@constraint(m, A4[iG = 1:nG,iS = 1:nS, iT = 1:nN], 
        sum(R_g[iG,iN] for iT = 1:nN) + sum(R_s[iS,iN] for iT = 1:nN)
        == R[iN])
