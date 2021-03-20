# get optimal model solutions
using JuMP

function writeOptSolutions(OptModel, OptDecVars)
    heading = zeros(nG)
    @assert nG >= 3
    heading[1] = nG
    heading[2] = nT
    heading[3] = objective_value(OptModel)
    res = [transpose(heading);transpose(JuMP.value.(pG));transpose(JuMP.value.(yG));transpose(JuMP.value.(uG));transpose(JuMP.value.(vG))]
    writedlm(string("./",CaseName,"/",CaseName,".result"), (x->round.(x; digits = 3)).(res) );
end 