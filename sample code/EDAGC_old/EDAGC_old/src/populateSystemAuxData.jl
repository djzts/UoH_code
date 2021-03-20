#=
Populate power system matrix data:
Bmatrix, Shift Factor Matrix
=#
using SparseArrays
# Y-matrix
function populateBfull(line, nB)
    nL = size(line,1)
    Bfull = zeros(nB,nB)

    for iL in 1:nL
        i = line[iL].to # to
        j = line[iL].from # from
        y = 1.0/line[iL].x
        Bfull[i,j] -= y # Just in case we have double circuit lines
        Bfull[j,i] -= y
        Bfull[i,i] += y
        Bfull[j,j] += y
    end
    Bsparse = sparse(Bfull)
    return Bsparse, Bfull    
end


function populateShiftFactor(Bfull, line)
    
    #=
    #-------------------------------------------
    shift factor calculation 
    Calculate Shift Factor Based on B Matrix
    Refer to : Transimission - Constrainted unit commitment based on Benders Decomposition; Haili Ma  and M Shahidehpour
    #-------------------------------------------
    =#
    nL = size(line,1)
    nB = size(Bfull,1)
    Bsub = Bfull[2:nB,2:nB]



    invB = zeros(nB,nB)
    invBsub = inv(Bsub)
    invB[2:nB,2:nB] = invBsub


    ## ShifFactor 
    SFmatrix = zeros(nL,nB)

    for iL = 1:nL
        i = line[iL].to # to
        j = line[iL].from # from 
        reactance = line[iL].x
        for iB = 1:nB
            SFmatrix[iL,iB] = (invB[j,iB] - invB[i,iB])/reactance
        end
    end

    return SFmatrix
end


function getBus2Genresource(bus, genResource)
    # build the bus--> generator relationship
 
    nB = size(bus,1)
    nG = size(genResource,1)
    bus2Genres = Dict(bus[iB].index => []    for iB = 1:nB)

    for iG = 1:nG
        push!(bus2Genres[genResource[iG].bus],iG)
    end

    return bus2Genres
end


function getSystemAuxData(psRes)
    #=
    Popualte B matrix, Spare B matrix, Shift factor Matrix, Bus Mapping to Generation resources
    =#
    line = psRes["Line"]
    bus = psRes["Bus"]
    genResource =  psRes["GenRes"]
    nB = size(bus,1)
    Bsparse, Bfull  = populateBfull(line,nB)

    SFmatrix = populateShiftFactor(Bfull, line)
    
    bus2Genres = getBus2Genresource(bus, genResource)
    
    psRes["Bsparse"] = Bsparse
    psRes["SFmatrix"] = SFmatrix
    psRes["bus2Genres"] = bus2Genres
end