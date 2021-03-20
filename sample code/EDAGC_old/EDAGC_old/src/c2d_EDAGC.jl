#create discretized model
#clear;clc;
using LinearAlgebra
using ControlSystems
ngen=3; # number of generators
R=0.05; #droop characteristic
M=10; #inertial constant
DD=1; #load damping factor
r=R*ones(ngen,1);
#%-----------------------------------------------------
TG=0.04; #governor time constant: default 0.04, new: 0.08
TT=0.5; #turbine time constant: default 0.5, new: 0.4


A1 = Matrix{Int64}(I,ngen,ngen)
A1=-1/TT * A1;
A2=-1/TT./r;
A3=1/M*ones(1,ngen);
A4=-DD/M;

Amatrix=[A1 A2;A3 A4];



B4=-1/M;
B1 = 1/TT*ones(ngen+1)
B1[ngen+1] = B4
Bmatrix = Diagonal(B1)
Cmatrix = zeros(ngen+1)
Cmatrix[ngen+1] = 1/R + DD
Dmatrix = zeros(ngen+1)
sys = ss(Amatrix,Bmatrix,Cmatrix,Dmatrix);
#sysd = c2d(sys,0.1);

#=

Cmatrix=[zeros(1,ngen) 1/R+DD];
Dmatrix=[zeros(1,ngen) 0];

sys = ss(Amatrix,Bmatrix,Cmatrix,Dmatrix);
sysd = c2d(sys,0.1);
ad = sysd.A;
bd = sysd.B;
=#