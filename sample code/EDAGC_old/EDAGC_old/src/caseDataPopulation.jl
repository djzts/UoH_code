#=
Case Data Population
=#
using Random, Distributions

include("logWrite.jl")

function generateAGCRandLoad(filePath,fileName)
    nT = Int(60 * 5 / 4)
    mu = 0
    std = 1
    deltaLoad = rand(Normal(mu,std),nT)
    index = [item for item = 1:nT]
    
    outdata = [index deltaLoad]

    outputMatrix(filePath,fileName, outdata)
end

filePath = "../data/"
fileName = "agcLoad"
caseName = "IIT6"
generateAGCRandLoad(string(filePath,caseName,"/"),string(caseName,".",fileName))
