#=
Populate Power System Basic Data 
=#
include("baseStructs.jl")

function populateBus(busData)::Array{BUS}
    nB = size(busData,1)
    bus = Array{BUS}(undef,nB)
    for iB in 1:nB
        bus[iB] = BUS(busData[iB,:]);
    end
    iSlack = findfirst(iB -> bus[iB].mode == 3, 1:nB);
    @assert iSlack != 0
    return bus
end

function populateLine(lineData)::Array{LINE}
    nL = size(lineData,1);
    line = Array{LINE}(undef,nL);
    for iL in 1:nL
        line[iL] = LINE(lineData[iL,:]);
    end
    return line
end

function populateGenResource(generatorData)::Array{GEN}
    nG = size(generatorData,1);
    gen = Array{GEN}(undef,nG);
    for iG in 1:nG
        gen[iG] = GEN(generatorData[iG,:]);
    end
    return gen 
end



function populateLoad(loadData)::Array{LOAD}
    nT = size(loadData,1); # Zero is included
    load = Array{LOAD}(undef, nT);
    for iT in 1:nT
        load[iT] = LOAD(loadData[iT,:]);
    end
    return load 
end

function populateAGCLoad(AGCLoadData)
    nT = size(AGCLoadData,1);
    AGCLoad = Array{AGCLOAD}(undef, nT);
    for iT in 1:nT
        AGCLoad[iT] = AGCLOAD(AGCLoadData[iT,:]);
    end
    return AGCLoad 

end 


function populateSystemReq(busData)
    
    pLoad = sum(busData[row,6] for row = 1: size(busData,1))
    regReq = 0.01 * pLoad
    spin   = 0.03 * pLoad
    nonSpin = 0.06 * pLoad
    sysReq = SYSTEMREQ([pLoad, regReq, spin, nonSpin])
    return sysReq
end 

function populateDimofModel(busData,lineData,generatorData,loadData,AGCLoadData)
    dim = [size(item,1) for item in [busData, lineData,generatorData, loadData, AGCLoadData]]
   
    dimofModel = DIMModel(dim)
   
    return dimofModel

end



function getPSBasic(psData)
    # populate system basic data for bus, generation resources, transmission lines , system load, ancillary service, AGCload 
    # populate the load ratio depending on the time interval
   
    busData = psData["Bus"]
    lineData = psData["Line"]
    generatorData = psData["Generator"]
    loadData = psData["Load"]
    AGCLoadData = psData["AGCLoad"]
    
    busVec = populateBus(busData)
    lineVec = populateLine(lineData)
    genResVec = populateGenResource(generatorData)
    loadVec = populateLoad(loadData)
    dimofModel = populateDimofModel(busData,lineData,generatorData,loadData, AGCLoadData)
    sysReq = populateSystemReq(busData)
 
    agcLoad = populateAGCLoad(AGCLoadData)
    psRes = Dict([("Bus",busVec), ("GenRes", genResVec), ("Line", lineVec), ("Load", loadVec),
     ("dimOfMd", dimofModel), ("sysReq", sysReq), ("agcLoad", agcLoad)])
    return psRes

end
