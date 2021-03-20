#=
Load data from database
=#
using DelimitedFiles
using JSON 
function readJSON(filePath, caseName)
    dict2 = Dict()
    open(string(filePath,"/",caseName,"/",caseName,".AGCData"), "r") do f
        dicttxt = read(f, String)  # file information to string
        dict2=JSON.parse(dicttxt)  # parse and transform data
    end
    return dict2
end 

function readDatafromDB(filePath::String, caseName::String)
    mBus = readdlm(string(filePath,"/",caseName,"/",caseName,".bus"), comments=true, comment_char='#');
    mLine = readdlm(string(filePath,"/",caseName,"/",caseName,".branch"), comments=true, comment_char='#');
    mGen = readdlm(string(filePath,"/",caseName,"/",caseName,".gen"), comments=true, comment_char='#');
    mLoad = readdlm(string(filePath,"/",caseName,"/",caseName,".time"), comments=true, comment_char='#');
    mAGCLoad = readdlm(string(filePath,"/",caseName,"/",caseName,".agcLoad"), comments=true, comment_char='#');
    agcData = readJSON(filePath, caseName)
    return Dict([("Bus",mBus),("Line",mLine),("Generator",mGen),("Load",mLoad),("AGCLoad", mAGCLoad)]), agcData
 
end

#=

inputpath = "../data"
outputpath = "../output/"
caseName = "IIT6"

agcData = readJSON(inputpath, caseName)
println(agcData)
=#

