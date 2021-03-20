#=
ED AGC Main

# Developed by Lei Fan
=#
using DelimitedFiles
 
include("readDatafromDB.jl")
include("populateSystemBasicData.jl")
include("populateSystemAuxData.jl")
include("logWrite.jl")
include("optEngine.jl")

 
function main()
    println("Start Main")
    inputpath = "../data"
    outputpath = "../output/"
    caseName = "IIT6"
    psData, agcData = readDatafromDB(inputpath,caseName)
    psRes = getPSBasic(psData)
    getSystemAuxData(psRes)
    optEngine(psRes,agcData)

    Bsparse = psRes["Bsparse"]
    SFmatrix = psRes["SFmatrix"]
    bus2Genres = psRes["bus2Genres"]
    testoutput(outputpath,psData,psRes,Bsparse, SFmatrix, bus2Genres)
    println("end Main")
end

main()
exit()