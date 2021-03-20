#=
Basic structures
=#

## Constant
const baseMVA = 100.0;
const baseHZ = 60;
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
    RegU:: Float64
    RegD :: Float64
    SR ::   Float64
    frq2gv :: Float64
    gv2pm::Float64
    pm2frq :: Float64
    pm2pm :: Float64
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
		b.RU        = a[15]/(baseMVA*60)
		b.RD        = a[16]/(baseMVA*60)
		b.SU        = b.p_min;
        b.SD        = b.p_min;
        b.RegU      = b.RU * 5
        b.RegD      = b.RD * 5
        b.SR        = b.RU * 10
		b.TU        = max( 0, ( b.min_up - max(b.T0,0) ) * b.yG0 )
        b.TD        = max( 0, ( b.min_down + min(b.T0,0) ) * (1-b.yG0) )
        return b
    end
end

mutable struct LOAD
	index::UInt16
	load_ratio::Float64
	# Add them here, if there are more time-dependent input data
	function LOAD(a::Array)
		b = new()
		b.index = a[1];
		b.load_ratio = a[2];
		return b
	end
end


mutable struct AGCLOAD
	index::Int64
	pload::Float64
	# Add them here, if there are more time-dependent input data
	function AGCLOAD(a::Array)
		b = new()
		b.index = a[1];
		b.pload = a[2]/baseMVA;
		return b
	end
end


mutable struct SYSTEMREQ
    pLoad::Float64
    spinReq::Float64
    nonSpinReq::Float64
    regulationReq::Float64
    maxFrequency::Float64
    frq2P:: Float64
    frq2frq :: Float64
    ld2frq :: Float64
    # add system data here
    function SYSTEMREQ(a::Array)
        sysreq = new()
        sysreq.pLoad = a[1]/baseMVA
        sysreq.regulationReq = a[2] /baseMVA
        sysreq.spinReq = a[3] /baseMVA
        sysreq.nonSpinReq = a[4] /baseMVA
        sysreq.maxFrequency = 0.06/baseHZ #0.018/baseHZ
        return sysreq
    end 
end 


mutable struct DIMModel
    nB :: Int64
    nL :: Int64
    nG :: Int64
    nT :: Int64
    agcT :: Int64
    function DIMModel(a::Array)
        dimofModel = new()
        dimofModel.nB = a[1]
        dimofModel.nL = a[2]
        dimofModel.nG = a[3]
        dimofModel.nT = a[4]
        dimofModel.agcT = a[5]
        return dimofModel
    end 
end