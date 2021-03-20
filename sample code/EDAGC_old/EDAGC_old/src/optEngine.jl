#=
Optimization Engine for ED-AGC
=#
using GLPK
using  CPLEX 

using MathOptFormat
include("buildOptModel.jl")



function optEngine(psRes, agcData)
    #optModel = Model(with_optimizer(GLPK.Optimizer, msg_lev = GLPK.MSG_ALL, mip_gap=5e-4))

    
    optModel = Model(with_optimizer(CPLEX.Optimizer))
    set_parameter(optModel, "CPXPARAM_MIP_Tolerances_AbsMIPGap", 1e-3)
    println("Build Optmization Model")
    buildOptModel(optModel, psRes,agcData)
    println("Call Solver")
    status = optimize!(optModel)

    println(" Solver Finished")
    printModel = 1
    if printModel == 1
        println("Print Model ing.....")
        lp_file = MathOptFormat.LP.Model()
        MOI.copy_to(lp_file,backend(optModel))
        MOI.write_to_file(lp_file,"myModel.lp")
    end 

end 