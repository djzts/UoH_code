#=
Build Optimization Model
=#
using JuMP
#=
Define decision variables for optimization model
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




function addAGCConstriants(optModel,optDecVars, psRes, agcData)
     #=
    AGC Constraints 
    =#
    agcT = psRes["dimOfMd"].agcT
    nG = psRes["dimOfMd"].nG
    nL = psRes["dimOfMd"].nL

    sysReq = psRes["sysReq"]
    Gen = psRes["GenRes"]
    deltaLoad = psRes["agcLoad"]

    regUP = optDecVars["regupRef"]
    regDN = optDecVars["regdnRef"]
    srG = optDecVars["srgRef"]

    deltaPGm = optDecVars["deltaPGmRef"]
    deltaPGgv = optDecVars["deltaPGgvRef"]
    deltafrqc = optDecVars["deltafrqcRef"]
    agc_Amatrix = agcData["A"]  # p1, p2 ... Pn , freq 
    agc_Bmatrix = agcData["B"]  #p1, p2, ...pn, load 
    # generator level AGC constraints 
    frq2gv = agcData["beta"]
    
    println(agc_Amatrix)

    println(agc_Bmatrix)

    println(frq2gv)
    println(deltaLoad)
    # generator ramping up/down 
    @constraint(optModel, rampingDownCons[iG = 1:nG, iT = 2:agcT],  deltaPGm[iG,iT-1] - deltaPGm[iG,iT] <= Gen[iG].RD)
    @constraint(optModel, rampingUpCons[iG = 1:nG, iT = 2:agcT], deltaPGm[iG,iT] - deltaPGm[iG,iT-1] <= Gen[iG].RU)
    
    @constraint(optModel, primemoverCons[iG = 1:nG, iT = 2:agcT], deltaPGm[iG,iT]  == sum(deltaPGm[jG,iT - 1] * agc_Amatrix[iG][jG] for jG = 1:nG) 
    + agc_Amatrix[iG][nG+1] * deltafrqc[iT-1] + sum(deltaPGgv[jG,iT - 1] * agc_Bmatrix[iG][jG] for jG = 1:nG) + agc_Bmatrix[iG][nG+1]* deltaLoad[iT-1].pload)
      
  
    # governor regulation up/down
    @constraint(optModel, regUPCons[iG = 1:nG, iT = 1:agcT],  deltaPGgv[iG,iT]  <= regUP[iG])
    @constraint(optModel, regDownCons[iG = 1:nG, iT = 1:agcT],   - regDN[iG] <= deltaPGgv[iG,iT] )
    # governor output and system frequency

    # governor output and ACE which equal to beta * frequency change 
    @constraint(optModel, governorFrequencyCons[iG = 1:nG, iT = 2:agcT], deltaPGgv[iG,iT] - deltaPGgv[iG,iT-1] == frq2gv * deltafrqc[iT-1])

   
    # System level frequency constraints
    @constraint(optModel, frequencyUBCons[ iT = 1:agcT], deltafrqc[iT] <= sysReq.maxFrequency)
    @constraint(optModel, frequencyLBCons[ iT = 1:agcT], -deltafrqc[iT] <= sysReq.maxFrequency)
    @constraint(optModel, frequencyChange[iT = 2:agcT], deltafrqc[iT] ==  sum(deltaPGm[jG,iT - 1] * agc_Amatrix[nG+1][jG] for jG = 1:nG) 
    + agc_Amatrix[nG+1][nG+1] * deltafrqc[iT-1] + sum(deltaPGgv[jG,iT - 1] * agc_Bmatrix[nG+1][jG] for jG = 1:nG) + agc_Bmatrix[nG+1][nG+1]* deltaLoad[iT-1].pload)
  

    
end 


#=
Define constraints for optimization model
=#

function addOptConstraints(optModel,optDecVars, psRes, agcData)
    
    addResConstraints(optModel,optDecVars, psRes)
  
    addSystemLevelConstraints(optModel,optDecVars, psRes)
  
    addAGCConstriants(optModel,optDecVars, psRes, agcData)
end


function buildOptModel(optModel,psRes, agcData)
    println("start build opt modcel")
    optDecVars = addOptVar(optModel, psRes)
    println("decvar")
    defineObjFun(optModel,optDecVars, psRes)
    println("define objc")
    addOptConstraints(optModel,optDecVars, psRes, agcData)
end