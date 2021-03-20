#=
Build the dual problem
=#

using JuMP
#=
Define dual decision variables for optimization model
=#
function addOptVar(optModel,psRes)
    dimofModel = psRes["dimOfMd"]
    nG = dimofModel.nG
    nL = dimofModel.nL
    nT = dimofModel.agcT 

    Gen = psRes["GenRes"]
    # ecnomic dispatch variables
    pgRef = @variable(optModel, pG[iG = 1:nG], (start = Gen[iG].pG0))
    srgRef = @variable(optModel, srG[iG = 1:nG], (start = 0))
    regupRef = @variable(optModel, regUP[iG = 1:nG], (start = 0))
    regdnRef = @variable(optModel, regDN[iG = 1:nG], (start = 0))

    #AGC variables
    deltaPGgvRef = @variable(optModel, deltaPGgv[iG = 1:nG, iT = 1:nT])
    deltaPGmRef = @variable(optModel, deltaPGm[iG = 1:nG, iT = 1:nT])
    deltafrqcRef = @variable(optModel, deltafrqc[iT = 1:nT])

    optDecVars = Dict{String, Any}([("pgRef",pgRef), ("srgRef", srgRef), ("regupRef",regupRef),
     ("regdnRef",regdnRef), ("deltaPGgvRef",deltaPGgvRef), ("deltaPGmRef",deltaPGmRef), ("deltafrqcRef",deltafrqcRef)])
    return optDecVars
end

function addOptDualVar(subDualModel,psRes)

    #add resource constratins dual variables
    capacityDualRef = @variable(subDualModel, capacityConsDualVars[iG = 1:nG], (start = 0))
    pminDualRef = @variable(subDualModel, pminConsDualVars[iG = 1:nG], (start = 0))
    regUpDualRef = @variable(subDualModel, regUpConsDualVars[iG = 1:nG], (start = 0))
    regDNDualRef = @variable(subDualModel, regDNConsDualVars[iG = 1:nG], (start = 0))
    spinDualRef = @variable(subDualModel, spinConsDualVars[iG = 1:nG], (start = 0))
    
    #add system level constratins dual variables 
    pbalanceDualRef = @variable(subDualModel, pbalanceConsDualVar)
    sysRegUpDualRef = @variable(subDualModel, sysRegUpConsDualVar)
    sysRegDNDualRef = @variable(subDualModel, sysRegDNConsDualVar)
    sysSpinDualRef = @variable(subDualModel, sysSpinConsDualVar)

    linecapacityLeftDualRef = @variable(subDualModel, linecapLeftDualVar[iL = 1:nL])
    linecapacityrightDualRef = @variable(subDualModel, linecaprightDualVar[iL = 1:nL])
    

end 

#=
Define objective function
=#
function defineObjFun(optModel, optDecVars, psRes)
    
    Gen = psRes["GenRes"]
    pG = optDecVars["pgRef"]
    nG = psRes["dimOfMd"].nG

    @objective(optModel, Min,
			sum(
					+ Gen[iG].cost_B * pG[iG] 		# One Linear Term
			for iG = 1:nG)
		)

end



function addResConstraints(optModel,optDecVars, psRes)

    nG = psRes["dimOfMd"].nG

    pG = optDecVars["pgRef"]
    regUP = optDecVars["regupRef"]
    regDN = optDecVars["regdnRef"]
    srG = optDecVars["srgRef"]


    Gen = psRes["GenRes"]


    #Upper bound
    @constraint(optModel,capacityCons[iG = 1:nG], pG[iG] + regUP[iG] + srG[iG] - Gen[iG].p_max <= 0)
    #Lower bound
    @constraint(optModel, pminCons[iG = 1:nG], Gen[iG].p_min - pG[iG] + regDN[iG] <= 0)
    #Reg Up/Down 
    @constraint(optModel, regUpCons[iG = 1:nG], regUP[iG] - Gen[iG].RegU <= 0)
    @constraint(optModel, regDNCons[iG = 1:nG], regDN[iG] - Gen[iG].RegD <= 0)
    #Spin bound
    @constraint(optModel, spinCons[iG = 1:nG], srG[iG] - Gen[iG].SR <= 0)
end 

function addSystemLevelConstraints(optModel,optDecVars, psRes)
    #=
    System Level Constraints 
    =#
    dimofModel = psRes["dimOfMd"]
 
    nG = dimofModel.nG
    nL = dimofModel.nL
    nB = dimofModel.nB

    pG = optDecVars["pgRef"]
    regUP = optDecVars["regupRef"]
    regDN = optDecVars["regdnRef"]
    srG = optDecVars["srgRef"]


    Gen = psRes["GenRes"]
    Bus = psRes["Bus"]
    Line = psRes["Line"]
    sysReq = psRes["sysReq"]

    SFmatrix = psRes["SFmatrix"]
    bus2Units = psRes["bus2Genres"]
    
    
    # power balance
    @constraint(optModel, pbalanceCons, sum(pG[iG] for iG = 1:nG) - sysReq.pLoad == 0.0)
    # regulation requirment
    @constraint(optModel, systemRegulationUPCons,  sysReq.regulationReq - sum(regUP[iG] for iG = 1:nG) <= 0.0)
    @constraint(optModel, systemRequlationDNCons,  sysReq.regulationReq - sum(regDN[iG] for iG = 1:nG) <= 0.0)

    # spin reserve requirment
    @constraint(optModel, systemSpingReqCons,  sysReq.spinReq - sum(srG[iG] for iG = 1:nG) <= 0.0)
    
    # power flow constraints

    @constraint(optModel, transmissionlineLeftCapacity[iL = 1:nL], sum(SFmatrix[iL,iB]*(sum(pG[iG] for iG in bus2Units[iB]) - Bus[iB].p_load) for iB = 1:nB ) <= Line[iL].p_max)
  

    @constraint(optModel, transmissionlineRightCapacity[iL = 1:nL], -sum(SFmatrix[iL,iB]*(sum(pG[iG] for iG in bus2Units[iB]) - Bus[iB].p_load) for iB = 1:nB ) <= Line[iL].p_max)



end 




function addAGCConstriants(optModel,optDecVars, psRes)
     #=
    AGC Constraints 
    =#
    agcT = psRes["dimOfMd"].agcT
    nG = psRes["dimOfMd"].nG
    nL = psRes["dimOfMd"].nL

    sysReq = psRes["sysReq"]
    Gen = psRes["GenRes"]
    deltaLoad = psRes["agcLoad"]
    

    deltaPGm = optDecVars["deltaPGmRef"]
    deltaPGgv = optDecVars["deltaPGgvRef"]
    deltafrqc = optDecVars["deltafrqcRef"]

    # generator level AGC constraints 
    
    # generator ramping up/down 
    @constraint(optModel, rampingDownCons[iG = 1:nG, iT = 2:agcT],  deltaPGm[iG,iT-1] - deltaPGm[iG,iT] <= Gen[iG].RD)
    @constraint(optModel, rampingUpCons[iG = 1:nG, iT = 2:agcT], deltaPGm[iG,iT] - deltaPGm[iG,iT-1] <= Gen[iG].RU)
    @constraint(optModel, primemoverCons[iG = 1:nG, iT = 2:agcT], deltaPGm[iG,iT] == sum( deltaPGm[iG, iT - 1] *Gen[jG].pm2pm for jG = 1:nG) + deltafrqc[iT-1] * sysReq.frq2P + deltaPGgv[iG,iT-1] * Gen[iG].gv2pm)
    # governor regulation up/down
    @constraint(optModel, regUPCons[iG = 1:nG, iT = 1:agcT],  deltaPGgv[iG,iT]  <= Gen[iG].RU)
    @constraint(optModel, regDownCons[iG = 1:nG, iT = 1:agcT],   - Gen[iG].RD <= deltaPGgv[iG,iT] )
    # governor output and system frequency
    @constraint(optModel, governorFrequencyCons[iG = 1:nG, iT = 2:agcT], deltaPGgv[iG,iT] - deltaPGgv[iG,iT-1] == Gen[iG].frq2gv * deltafrqc[iT-1])


    # System level frequency constraints
    @constraint(optModel, frequencyUBCons[ iT = 1:agcT], deltafrqc[iT] <= sysReq.maxFrequency)
    @constraint(optModel, frequencyLBCons[ iT = 1:agcT], -deltafrqc[iT] <= sysReq.maxFrequency)
    @constraint(optModel, frequencyChange[iT = 2:agcT], deltafrqc[iT] == sysReq.frq2frq * deltafrqc[iT-1] + sum(deltaPGm[iT - 1] * Gen[jG].pm2frq for jG = 1:nG) + sysReq.ld2frq * deltaLoad[iT-1].pload )
  

end 


#=
Define constraints for optimization model
=#

function addOptConstraints(optModel,optDecVars, psRes)
    println("rescons")
    addResConstraints(optModel,optDecVars, psRes)
    println("syscons")
    addSystemLevelConstraints(optModel,optDecVars, psRes)
    println("agccons")
    addAGCConstriants(optModel,optDecVars, psRes)
end


function buildOptModel(optModel,psRes)
    println("start build opt modcel")
    optDecVars = addOptVar(optModel, psRes)
    println("decvar")
    defineObjFun(optModel,optDecVars, psRes)
    println("define objc")
    addOptConstraints(optModel,optDecVars, psRes)
end