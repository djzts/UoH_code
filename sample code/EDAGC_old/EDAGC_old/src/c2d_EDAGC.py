#create discretized model
#clear;clc;
import json
from control.matlab import *
import numpy as np

ngen=3 # number of generators
R=0.05 #droop characteristic
M=10 #inertial constant
DD=1 #load damping factor
KI = 0.3
detaT = 0.1 # time step
r=R*np.ones(ngen+1)

TG=0.04 #governor time constant: default 0.04, new: 0.08
TT=0.5 #turbine time constant: default 0.5, new: 0.4

Amatrix = -1/TT * np.eye(ngen+1, dtype=int) #A
Amatrix[:, ngen] = -1/TT /r  #A2


print("====")
A3 = 1/M*np.ones(ngen+1) # A3 
A3[ngen] = -DD/M #A4
Amatrix[ngen] = A3


B4=-1/M
B1 = 1/TT* np. ones(ngen+1)
B1[ngen] = B4
Bmatrix = np.diag(B1)
Cmatrix = np.zeros(ngen+1)
Cmatrix[ngen] = 1/R + DD
Dmatrix = np.zeros(ngen+1)

sys = ss(Amatrix,Bmatrix,Cmatrix,Dmatrix)
sysd = c2d(sys,detaT)
ad = sysd.A
bd = sysd.B 
cd = sysd.C

data = {}
data["A"] = ad.tolist()
data["B"] = bd.tolist() 
data["beta"] = cd[-1,-1] * KI * detaT

with open('IIT6.AGCdata', 'w') as outfile:
    json.dump(data, outfile)


"""
A1=-1/TT*eye(ngen);
A2=-1/TT./r;
A3=1/M*ones(1,ngen);
A4=-DD/M;

Amatrix=[A1 A2;A3 A4];
B1=1/TT*eye(ngen);
B4=-1/M;
Bmatrix=blkdiag(B1,B4);
Cmatrix=[zeros(1,ngen) 1/R+DD];
Dmatrix=[zeros(1,ngen) 0];

sys = ss(Amatrix,Bmatrix,Cmatrix,Dmatrix);
sysd = c2d(sys,0.1);
ad = sysd.A;
bd = sysd.B;
"""