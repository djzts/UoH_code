#@time

import Pkg; 
Pkg.add("JuMP")
Pkg.add("GLPK")
Pkg.add("MathOptFormat")
ENV["CPLEX_STUDIO_BINARIES"] = "F:/AppStore/Research/cplex/bin/x64_win64"
Pkg.add("CPLEX")
Pkg.build("CPLEX")
using JuMP
using GLPK     ##改成 cplex julia add cplex let julia know  environment of cplex
using DelimitedFiles
using SparseArrays
using MathOptFormat
using JuMP, CPLEX
## Input
const CaseName = "IIT6";
#const CaseName = "IEEE14";
#const CaseName = "IEEE118";

## Constant
const baseMVA = 100.0;

## mutable structs
mutable struct BUS
    index::UInt16
    mode::UInt8
    name::String
    voltage::Float64
    angle::Float64
    p_gen::Float64
    q_gen::Float64
    q_min::Float64
    q_max::Float64
    p_load::Float64
    q_load::Float64
    g_shunt::Float64
    b_shunt::Float64
    b_shunt_min::Float64
    b_shunt_max::Float64
    b_dispatch::Bool
    area::UInt16
    function BUS(a::Array)
        b = new();
        b.index       = a[1]
        b.mode        = a[2]
        b.name        = a[3]
        b.voltage     = a[4]
        b.angle       = a[5]
        b.p_gen       = a[6]/baseMVA
        b.q_gen       = a[7]/baseMVA
        b.q_min       = a[8]/baseMVA
        b.q_max       = a[9]/baseMVA
        b.p_load      = a[10]/baseMVA
        b.q_load      = a[11]/baseMVA
        b.g_shunt     = a[12]
        b.b_shunt     = a[13]
        b.b_shunt_min = a[14]
        b.b_shunt_max = a[15]
        b.b_dispatch  = a[16]
        b.area        = a[17]
        return b
    end
end

mutable struct LINE
	index::UInt16
	from::UInt16
	to::UInt16
	mode::UInt8
	r::Float64
	x::Float64
	c::Float64
	tap::Float64
	tap_min::Float64
	tap_max::Float64
	shf0::Float64
	shf_min::Float64
	shf_max::Float64
	p_max::Float64
    function LINE(a::Array)
        b = new();
        b.index   = a[1]
        b.from    = a[2]
        b.to      = a[3]
        b.mode    = a[4]
        b.r       = a[5]
        b.x       = a[6]
        b.c       = a[7]
        b.tap     = a[8]
        b.tap_min = a[9]
        b.tap_max = a[10]
        b.shf0    = a[11]
        b.shf_min = a[12]
        b.shf_max = a[13]
		b.p_max   = a[14]/baseMVA
        return b
    end
end

mutable struct GEN
	index::UInt16
	bus::UInt16
	p_max::Float64
	p_min::Float64
	cost_A::Float64
	cost_B::Float64
	cost_C::Float64
	min_up::UInt16
	min_down::UInt16
	cost_up::Float64
	cost_down::Float64
	pG0::Float64
	yG0::Bool
	T0::Int16
	RU::Float64
	RD::Float64
	SU::Float64
	SD::Float64
	TU::UInt16
	TD::UInt16
	function GEN(a::Array)
        b = new();
        b.index     = a[1]
        b.bus       = a[2]
        b.p_max     = a[3]/baseMVA
        b.p_min     = a[4]/baseMVA
        b.cost_A    = a[5]*baseMVA^2
        b.cost_B    = a[6]*baseMVA
        b.cost_C    = a[7]
        b.min_up    = a[8]
        b.min_down  = a[9]
        b.cost_up   = a[10]
        b.cost_down = a[11]
        b.pG0       = a[12]/baseMVA
        b.yG0       = a[13]
		b.T0        = a[14]
		b.RU        = a[15]/baseMVA
		b.RD        = a[16]/baseMVA
		b.SU        = b.p_min;
		b.SD        = b.p_min;
		b.TU        = max( 0, ( b.min_up - max(b.T0,0) ) * b.yG0 )
		b.TD        = max( 0, ( b.min_down + min(b.T0,0) ) * (1-b.yG0) )
        return b
    end
end

mutable struct TIME
	index::UInt16
	load_ratio::Float64
	# Add them here, if there are more time-dependent input data
	function TIME(a::Array)
		b = new()
		b.index = a[1];
		b.load_ratio = a[2];
		return b
	end
end

println("Star Data Population")
## Read file
# Bus
mBus = readdlm(string("./",CaseName,"/",CaseName,".bus"), comments=true, comment_char='#');
const nB = size(mBus,1);
Bus = Array{BUS}(undef,nB);
iSlack = 0
for iB in 1:nB
    #push!(Bus, BUS(mBus[iB,:]));
    Bus[iB] = BUS(mBus[iB,:]);
end
iSlack = findfirst(iB -> Bus[iB].mode == 3, 1:nB);
@assert iSlack != 0
# Line
mLine = readdlm(string("./",CaseName,"/",CaseName,".branch"), comments=true, comment_char='#');
const nL = size(mLine,1);
Line = Array{LINE}(undef,nL);
for iL in 1:nL
    Line[iL] = LINE(mLine[iL,:]);
end
# Gen
mGen = readdlm(string("./",CaseName,"/",CaseName,".gen"), comments=true, comment_char='#');
const nG = size(mGen,1);
Gen = Array{GEN}(undef,nG);
for iG in 1:nG
    Gen[iG] = GEN(mGen[iG,:]);
end
# Time
mTime = readdlm(string("./",CaseName,"/",CaseName,".time"), comments=true, comment_char='#');
const nT = size(mTime,1); # Zero is included
Time = Array{TIME}(undef, nT);
for iT in 1:nT
    Time[iT] = TIME(mTime[iT,:]);
end

## Y-Matrix
Bfull = zeros(nB,nB)
for l in Line
	i = l.to
	j = l.from
	y = 1.0/l.x
	Bfull[i,j] -= y # Just in case we have double circuit lines
	Bfull[j,i] -= y
	Bfull[i,i] += y
	Bfull[j,j] += y
end
B = sparse(Bfull)
println("data population finished")
## Formulation
#m = Model()
println("Star Model Population")
#m = Model(with_optimizer(CPLEX.Optimizer))
m = Model(CPLEX.Optimizer)
#set_optimizer_attribute(m, "CPX_PARAM_EPINT", 5e-4)
# Variables
@variables m begin
	theta[iB = 1:nB, iT = 1:nT],   (start = Bus[iB].angle/180*pi, lower_bound = -pi, upper_bound = pi)
	pG[iG = 1:nG, iT = 1:nT],      (start = Gen[iG].pG0)
	yG[iG = 1:nG, iT = 1:nT],      (Bin, start = Gen[iG].yG0)
	uG[iG = 1:nG, iT = 1:nT],      (Bin, start = 0)
	vG[iG = 1:nG, iT = 1:nT],      (Bin, start = 0)
end
# Fixing Variables
@constraint(m, Fix_Slack[iT = 1:nT], theta[iSlack, iT] == 0.0)
@constraint(m, Fix_yG[iG = 1:nG, iT = 1:(max(Gen[iG].TU, Gen[iG].TD) + 1)], yG[iG, iT] == Gen[iG].yG0)
@constraint(m, Fix_uG[iG = 1:nG, iT = 1:(max(Gen[iG].TU, Gen[iG].TD) + 1)], uG[iG, iT] == 0)
@constraint(m, Fix_vG[iG = 1:nG, iT = 1:(max(Gen[iG].TU, Gen[iG].TD) + 1)], vG[iG, iT] == 0)

#Objective Function
@objective(m, Min,
			sum(
				sum(
					+ Gen[iG].cost_up * uG[iG,iT]		# Cold Startup
					+ Gen[iG].cost_down * vG[iG,iT]		# Shutdown
					+ Gen[iG].cost_B * pG[iG,iT] 		# One Linear Term
				for iT = 1:nT)
			for iG = 1:nG)
		)

#Constraints
@constraint(m, C21[iG = 1:nG, iT = 1:nT], uG[iG,iT] + vG[iG,iT] <= 1)

@constraint(m, C22[iG = 1:nG, iT = 2:nT], yG[iG,iT] - yG[iG,iT-1] == uG[iG,iT] - vG[iG,iT])

@constraint(m, C23[iG = 1:nG, iT = Gen[iG].min_up:nT],   sum(uG[iG,iTT] for iTT = (iT-Gen[iG].min_up+1):iT) - yG[iG,iT] <= 0)

@constraint(m, C24[iG = 1:nG, iT = Gen[iG].min_down:nT], sum(vG[iG,iTT] for iTT = (iT-Gen[iG].min_down+1):iT) <= 1 - yG[iG,iT])

@constraint(m, C25a[iG = 1:nG, iT = 1:nT], Gen[iG].p_min*yG[iG,iT] <= pG[iG,iT])

@constraint(m, C25b[iG = 1:nG, iT = 1:nT], pG[iG,iT] <= Gen[iG].p_max*yG[iG,iT])

@constraint(m, C2627a[iG = 1:nG, iT = 2:nT], -(Gen[iG].RD*yG[iG,iT] + Gen[iG].SD*vG[iG,iT]) <= pG[iG,iT] - pG[iG,iT-1])

@constraint(m, C2627b[iG = 1:nG, iT = 2:nT], pG[iG,iT] - pG[iG,iT-1] <= Gen[iG].RU*yG[iG,iT] + Gen[iG].SU*uG[iG,iT])

@constraint(m, PowerF[iB = 1:nB, iT = 1:nT],
	  sum(pG[iG,iT] for iG = suml(iGG -> Gen[iGG].bus==iB, 1:nG))
	- Bus[iB].p_load * Time[iT].load_ratio
	- sum(B.nzval[idx] * theta[B.rowval[idx],iT] for idx in B.colptr[iB]:(B.colptr[iB+1]-1))
     == 0.0 )
     
@constraint(m, LineF1[iL = 1:nL, iT = 1:nT], -Line[iL].p_max <= (theta[Line[iL].from, iT] - theta[Line[iL].to, iT]) / Line[iL].x)

@constraint(m, LineF2[iL = 1:nL, iT = 1:nT], (theta[Line[iL].from, iT] - theta[Line[iL].to, iT]) / Line[iL].x <= Line[iL].p_max)

# TODO: Reserve related constraints are omitted here for the time being. GG
#       incl. C28, C29, C32, C33

#@elapsed

#@time
println("Call Solver")
status = optimize!(m)
println(" Solver Finished")
#@elapsed

#write lp Model

println("Print Model ing.....")
lp_file = MathOptFormat.LP.Model()
MOI.copy_to(lp_file,backend(m))
MOI.write_to_file(lp_file,"myModel.lp")

# Write Results
heading = zeros(nG)
@assert nG >= 3
heading[1] = nG
heading[2] = nT
heading[3] = objective_value(m)
res = [transpose(heading);transpose(JuMP.value.(pG));transpose(JuMP.value.(yG));transpose(JuMP.value.(uG));transpose(JuMP.value.(vG))]
writedlm(string("./",CaseName,"/",CaseName,".result"), (x->round.(x; digits = 3)).(res) );
