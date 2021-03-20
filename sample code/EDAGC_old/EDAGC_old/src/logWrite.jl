using DelimitedFiles
using MathOptFormat


function output(outputpath,filename, data)
    open(string(outputpath,filename),"w") do io
    
        writedlm(io, [data], "\n")
    
        close(io) 
    end
    println(string("write to ", filename,".txt end"))
end

function outputMatrix(outputpath,filename, data)
    open(string(outputpath,filename),"w") do io
    
        writedlm(io, data)
    
        close(io) 
    end
    println(string("write to ", filename," end"))
end

function testoutput(outputpath,psData,psRes,Bsparse, SFmatrix, bus2Genres)
    
    for key in ["Line","Bus","GenRes", "Load"]
        output(outputpath,key,psRes[key])
    end
    for item in [("Bsparse",Bsparse), ("SFmatrix",SFmatrix),("bus2Genres",bus2Genres)]
        outputMatrix(outputpath,item[1],item[2])
    end
    
end

function wrtieOptModel(optModel)
    println("Print Opt Model ing.....")
    lp_file = MathOptFormat.LP.Model()
    MOI.copy_to(lp_file,backend(model))
    MOI.write_to_file(lp_file,"myModel.lp")
    println("End Opt Model formualtion write")
end 