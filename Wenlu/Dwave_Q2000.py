import networkx as nx
import numpy as np
from collections import defaultdict
import matplotlib.pyplot as plt
import random
import warnings
warnings.filterwarnings("ignore")
import time
import csv

def Create_channel(N,Channel_upperbound,option = "general",initial_length = 1):
    '''
    options:
        general:
            Random wire length from 0 to N virtual machines
        same, initial_length:
            Same wire length from 0 to N virtual machines. 
            If no specific details the progra will assume all items are 1
            The length cannot be 0 or the network will not take it as a normal edge.
    '''
    Channel_link = np.random.randint(Channel_upperbound,size=(N+1, N+1),) +1
    Channel_link = Channel_link - np.diag(np.diag(Channel_link)) + self_looped*np.eye(N+1,N+1)
    if option == "general":
        Channel_link[:,0] = 0
    elif option == 'same':
        Channel_link[0,:] = initial_length
        Channel_link[:,0] = 0
    else:
        print("Oops!  That was no valid option.  Try again...")
    
    return Channel_link

def Data_Queue(I,J,Data_upperbound):
    Data_Queue = np.random.randint(Data_upperbound,size=(I, J))+1
    return Data_Queue

def Data_Queue_type(I,J,K):
    Data_type_Queue = np.array([np.array(np.random.choice(K, J, replace = False)) for i in range(I)], dtype="object")+1
    return Data_type_Queue

def VM_Data_type_gen(I,K,N):
    flag = True
    while flag:
        type_selected = np.random.randint(1,K)
        VM_Data_type = np.sort(np.array([np.array(np.random.choice(K, type_selected, replace = False)) for i in range(N)])) + 1
        uniques = np.unique(VM_Data_type)
        flag = (len(uniques)<K)
    return VM_Data_type

def VM_Data_processing_speed(Processing_upperbound, VM_Data_type, K):
    N = len(VM_Data_type)
    VM_Data_speed_preset = np.array([np.array(np.random.choice(Processing_upperbound, K, replace = False)) for i in range(N)]) + 1
    VM_Data_speed_bolean = np.zeros((N,K))
    for row in range(N):
        VM_Data_speed_bolean[row,VM_Data_type[row,:]-1] = 1

    VM_Data_speed = VM_Data_speed_bolean * VM_Data_speed_preset
    return VM_Data_speed

def VM_Data_processing_time(Data_Queue,Data_type_Queue , VM_Data_speed):
    #
    I,J = np.shape(Data_Queue)
    N = len(VM_Data_speed)
    
    #
    General_Processing_time = np.ceil(np.kron(Data_Queue,1./VM_Data_speed))
    Processing_time_alt=np.ceil(np.reshape(General_Processing_time,(I,N,J,K)))
    Processing_time_final = 1./np.zeros((I,J,N))
    
    for i in range(I):
        for j in range(J):
            function_type = Data_type_Queue[i,j]-1

            Processing_time_final[i,j] = Processing_time_alt[i,:,j,function_type]
    
    return Processing_time_final

def Channel_Data_transmission_time(Data_Queue , Channel_link):
    #N' = N+1 contain initial node
    I,J = np.shape(Data_Queue)
    N_prime = len(Channel_link)
    
    Transmission_time = np.ceil(np.kron(Data_Queue,1./Channel_link))
    Transmission_time = np.reshape(Transmission_time,(I,N_prime,J,N_prime))
    
    return Transmission_time

def Draw_network(Channel_link):
    G = nx.from_numpy_matrix(Channel_link,create_using=nx.DiGraph(directed=True))
    edge_label = {}
    for j, edge in enumerate(G.edges()):
        #edge_label.update({(edge[0],edge[1]): "<"+ str(Channel_link[edge[0]+1,edge[1]+1])+ "|" +str(Channel_link_[edge[1]+1,edge[0]+1])+">" })
        #print(edge)
        if edge[1] > edge[0]:
            edge_label.update({(edge[0],edge[1]): "<" + str(int(Channel_link[edge[0],edge[1]])) + "|" })
        else:
            edge_label.update({(edge[0],edge[1]): "|" + str(int(Channel_link[edge[0],edge[1]])) + ">" })    
        pos = nx.circular_layout(G)
    #graph = nx.draw(G,pos,with_labels = True, connectionstyle='arc3, rad = 0.1')
    graph = nx.draw(G,pos,with_labels = True)
    graph = nx.draw_networkx_edge_labels(G,pos,edge_labels = edge_label,label_pos = 0.8)

def show_graph(matrix):
    matfig = plt.figure(figsize=(9,9)) 
    plt.matshow(matrix,fignum=matfig.number)
    plt.colorbar()
    plt.show()   

def show_relation(Final_map):
    #matfig = plt.figure(figsize=(Final_map.shape[0],Final_map.shape[1]))
    matfig = plt.figure(figsize=(9,9))
    plt.matshow(Final_map,cmap=plt.cm.binary,fignum=matfig.number)
    ax = plt.gca()
    #plt.matshow(Final_map,cmap=plt.cm.binary)
    plt.ylabel('Source node index')
    plt.xlabel('To node index')
    plt.title ("Direction map visualization")

    # Major ticks
    ax.set_xticks(np.arange(0, Final_map.shape[0], step=1))
    ax.set_yticks(np.arange(0, Final_map.shape[0], step=1))

    # Labels for major ticks
    ax.set_xticklabels(np.arange(0, Final_map.shape[0], step=1))
    ax.set_yticklabels(np.arange(0, Final_map.shape[0], step=1))

    # Minor ticks
    ax.set_xticks(np.arange(0.5, Final_map.shape[0]+0.5, step=1), minor=True)
    ax.set_yticks(np.arange(0.5, Final_map.shape[0]+0.5, step=1), minor=True)

    # Gridlines based on minor ticks
    ax.grid(which='minor', color='r', linestyle='-', linewidth=1)

    plt.show()

def Make_dictionary(I,J,N,T_max):
    position_dictionary = {}
    # set-up a dictionary
    Total = 0
    # w input
    for i in range(I):
        for j in range(J):
            for m in range(N):
                for n in range(N):
                    for t in range(T_max):

                        multiplier = np.array([i,j,m,n,t])
                        unit = np.array([J*T_max*N**2,T_max*N**2,T_max*N,T_max,1])
                        #print(np.dot(multiplier,unit))
                        position_dictionary["w_%d%d%d%d%d"%(i,j,m,n,t)] = int(np.dot(multiplier,unit))
    Num_of_w = len(position_dictionary) - Total
    Total = len(position_dictionary)


    # v input
    for i in range(I):
        for j in range(J):
            for m in range(N):
                for n in range(N):
                    for t in range(T_max):

                        multiplier = np.array([i,j,m,n,t])
                        unit = np.array([J*T_max*N**2,T_max*N**2,T_max*N,T_max,1])
                        #print(np.dot(multiplier,unit))
                        position_dictionary["v_%d%d%d%d%d"%(i,j,m,n,t)] = int(np.dot(multiplier,unit)) + Total

    Num_of_v = len(position_dictionary) - Total
    Total = len(position_dictionary)                    


    # y input
    for i in range(I):
        for j in range(J):
            for m in range(N):
                for t in range(T_max):
                    multiplier = np.array([i,j,m,t])
                    unit = np.array([J*T_max*N,T_max*N,T_max,1])
                    #print(np.dot(multiplier,unit))
                    position_dictionary["y_%d%d%d%d"%(i,j,m,t)] = int(np.dot(multiplier,unit)) + Total
    Num_of_y = len(position_dictionary) - Total
    Total = len(position_dictionary)                

    # z input
    for i in range(I):
        for j in range(J):
            for m in range(N):
                for t in range(T_max):
                    multiplier = np.array([i,j,m,t]) 
                    unit = np.array([J*T_max*N,T_max*N,T_max,1])
                    #print(np.dot(multiplier,unit))
                    position_dictionary["z_%d%d%d%d"%(i,j,m,t)] = int(np.dot(multiplier,unit)) + Total
    Num_of_z = len(position_dictionary) - Total
    Total = len(position_dictionary)   
    return position_dictionary, Total

def little_greedy_algorithm(VM_DP_time,modified_Transmission_time,I,J,N):
    Total_time = modified_Transmission_time
    for i in range(I):
        for j in range(J):
            for n in range(N):
                Total_time[i,:,j,n] += VM_DP_time[i,j,n]
                
    answer = np.sum(np.min(Total_time,(1,3)))
    return int(answer)

N = 2
#M = 5
I = 2
J = 2
K = 3
Channel_upperbound = 35
Data_upperbound = 20
Processing_upperbound = 35
self_looped = 100

Channel_link = Create_channel(N,Channel_upperbound,option = "same",initial_length = 1)

Data_input = Data_Queue(I,J,Data_upperbound)
Data_input_type = Data_Queue_type(I,J,K)
VM_type = VM_Data_type_gen(I,K,N)
VM_speed = VM_Data_processing_speed(Processing_upperbound, VM_type, K)

VM_DP_time = VM_Data_processing_time(Data_input, Data_input_type , VM_speed)

Transmission_time = Channel_Data_transmission_time(Data_input , Channel_link)

modified_VM_DP_time = VM_DP_time
modified_VM_DP_time[np.isinf(modified_VM_DP_time)] = 0
T_max_DP = np.sum(np.max(modified_VM_DP_time[:,:,:],2))

modified_Transmission_time = Transmission_time[:,1:,:,1:]
modified_Transmission_time[np.isinf(modified_Transmission_time)] = 0  #可不做（只要左，上需要从除去inf，除非不是全连接图）

T_max_DT = np.sum(np.max(modified_Transmission_time,(1,3)))

T_max = int(T_max_DP + T_max_DT )

initial_Transmission_time = Transmission_time[:,1:,:,1:]
T_max = little_greedy_algorithm(VM_DP_time,initial_Transmission_time,I,J,N)

position_dictionary, Total = Make_dictionary(I,J,N,T_max)
QUBO_init = np.zeros((Total, Total))

#Obj QUBO dont flatten yet
w = np.zeros((I,J,N,N,T_max))
w[:,J-1,:,:,:] = 1
print()
QUBO_0 = np.zeros_like(QUBO_init)
QUBO_0[:len(w.flatten()),:len(w.flatten())] = np.diag(w.flatten())

#C1
P1 = np.ones((I,J))
QUBO_1 = np.zeros_like(QUBO_init)
for i in range(I):
    for j in range(J):
        V_ij_k, _ = np.where(VM_type == Data_input_type[i,j])
        index_matched = [];
        for machine in V_ij_k:
            for t in range(T_max):
                index_matched.append(position_dictionary['z_%d%d%d%d'%(i,j,machine,t)])
        #print(index_matched)
        z_matched = np.zeros(Total)
        z_matched[np.array(index_matched)] = 1
        QUBO_1 += P1[i,j]*np.outer(z_matched,z_matched)


#C2
P2 = np.ones((I,J))
QUBO_2 = np.zeros_like(QUBO_0)

#print(P2)
for i in range(I):
    for j in range(J):
        w = np.zeros((I,J,N,N,T_max))
        w[i,j,:,:,:] = 1    
        QUBO_2[:len(w.flatten()),:len(w.flatten())] += P2[i,j]*np.outer(w.flatten(),w.flatten())

P3 = np.ones((I,J))
QUBO_3 = np.zeros_like(QUBO_0)

#print(P3)
for i in range(I):
    for j in range(J-1):
        
        w = np.zeros((I,J,N,N,T_max))
        V_ij_k, _ = np.where(VM_type == Data_input_type[i,j])
        V_ijplus1_k, _ = np.where(VM_type == Data_input_type[i,j+1])
        for m in V_ij_k:
            for n in V_ijplus1_k:
                w[i,j,m,n,:] = 1    
        QUBO_3[:len(w.flatten()),:len(w.flatten())] += P3[i,j]*np.outer(w.flatten(),w.flatten())

#C4
P4 = np.ones((N,T_max))
QUBO_4 = np.zeros_like(QUBO_init)
for m in range(N):
    for t in range(T_max):
        index_matched = []
        for i in range(I):
            for j in range(J):
                index_matched.append(position_dictionary['y_%d%d%d%d'%(i,j,m,t)])
        #print(index_matched)
        y_matched = np.zeros(Total)
        y_matched[np.array(index_matched)] = 1
        #print(np.sum(y_matched))
        QUBO_4 += P4[m,t]*(np.outer(y_matched,y_matched)-np.diag(y_matched))

#C6 这个M 有限制？
P6 = np.ones((I,J,N))
QUBO_6 = np.zeros_like(QUBO_init)
for i in range(I):
    for j in range(J-1):
        for m in range(N):
            index_matched = []
            for t in range(T_max):
                index_matched.append(position_dictionary['y_%d%d%d%d'%(i,j,m,t)])
        #print(index_matched)
            y_matched = np.zeros(Total)
            y_matched[np.array(index_matched)] = 1
            QUBO_6 += P6[i,j,m]*(modified_VM_DP_time[i,j,m] * (np.outer(y_matched,y_matched)-np.diag(y_matched))+np.diag(y_matched) )

#C9
P9 = np.ones((N,N,T_max))
QUBO_9 = np.zeros_like(QUBO_init)
for m in range(N):
    for n in range(N):
        for t in range(T_max):
            index_matched_term1 = []
            index_matched_term2 = []
            for i in range(I):
                for j in range(J):
                    index_matched_term1.append(position_dictionary['v_%d%d%d%d%d'%(i,j,m,n,t)])
                    index_matched_term2.append(position_dictionary['v_%d%d%d%d%d'%(i,j,n,m,t)])
            # record them down to 2 vectors
            v_matched = np.zeros(Total)
            v_matched[np.array(index_matched_term1)] = 1
            v_matched[np.array(index_matched_term2)] = 1
            # Part1
            QUBO_9 += P9[m,n,t]*(np.outer(v_matched,v_matched)-np.diag(v_matched))

#C11 这个M 有限制？
P11 = np.ones((I,J,N,N))
QUBO_11 = np.zeros_like(QUBO_init)
for i in range(I):
    for j in range(J-1):
        for m in range(N):
            for n in range(N):
                index_matched = []
                for t in range(T_max):
                    index_matched.append(position_dictionary['v_%d%d%d%d%d'%(i,j,m,n,t)])
                #print(index_matched)
                v_matched = np.zeros(Total)
                v_matched[np.array(index_matched)] = 1
                QUBO_11 += P11[i,j,m,n]*(modified_Transmission_time[i,m,j,n] * (np.outer(v_matched,v_matched)-np.diag(v_matched))+np.diag(v_matched) )


QUBO = np.zeros_like(QUBO_init)
QUBO = QUBO_0 + QUBO_1 + QUBO_2 + QUBO_3 + QUBO_4 + QUBO_6 + QUBO_9 + QUBO_11 
position_dictionary, Total = Make_dictionary(I,J,N,T_max)
QUBO_init = np.zeros((Total, Total))
with open('data.csv', 'w') as f:
    for key in position_dictionary.keys():
        f.write("%s, %s\n" % (key, position_dictionary[key]))
Total = len(position_dictionary)

## Single Slack Variable part
#C5
constraint = 5
P5 = np.ones((I,J,N,T_max))
for i in range(I):
    for j in range(J-1):
        for m in range(N):
            for t in range(T_max):
            
                index_matched_y = []
                index_matched_y.append(position_dictionary['y_%d%d%d%d'%(i,j,m,t)])
                
                index_matched_w = []
                V_ijplus1_k, _ = np.where(VM_type == Data_input_type[i,j+1])
                for n in V_ijplus1_k:
                    for t in range(T_max):
                        index_matched_w.append(position_dictionary['w_%d%d%d%d%d'%(i,j,m,n,t)])
                
                #slack var
                #print(np.shape(QUBO))
                position_dictionary["s_%d_%d%d%d%d"%(constraint,i,j,m,t)] = Total
                Total += 1
                QUBO = np.pad(QUBO, [(0, 1), (0, 1)], mode='constant', constant_values = 0)
                #print(np.shape(QUBO))
                #
                
                #print(len(position_dictionary))
                var_matched = np.zeros(Total)
                var_matched[index_matched_y] = 1
                var_matched[index_matched_w] = -1
                var_matched[-1] = 1
                QUBO += P5[i,j,m,t]*np.outer(var_matched,var_matched)

## Single Slack Variable part
#C8
constraint = 8
P8 = np.ones((I,J,N,T_max))
for i in range(I):
    for j in range(J):
        for m in range(N):
            for t in range(T_max):
                index_matched_y = []
                index_matched_y.append(position_dictionary['y_%d%d%d%d'%(i,j,m,t)])                
                
                alpha = 0
                index_matched_z = []
                for alpha in range(1,int(modified_VM_DP_time[i,j,m])+1):
                    index_matched_z.append(position_dictionary['z_%d%d%d%d'%(i,j,m,max(t-alpha+1,0))])
                
                #slack var
                #print(np.shape(QUBO))
                if (alpha <= 0):
                    continue
                else:    
                    position_dictionary["s_%d_%d%d%d%d"%(constraint,i,j,m,t)] = Total
                    Total += 1
                    QUBO = np.pad(QUBO, [(0, 1), (0, 1)], mode='constant', constant_values = 0)
                    #print(np.shape(QUBO))
                    #
                
                    #print(len(position_dictionary))
                    var_matched = np.zeros(Total)
                    var_matched[index_matched_y] = -1
                    var_matched[np.unique(index_matched_z)] = 1
                    var_matched[-1] = 1
                    QUBO += P8[i,j,m,t]*np.outer(var_matched,var_matched)

## Single Slack Variable part
#C13
constraint = 13
P13 = np.ones((I,J,N,N,T_max))
for i in range(I):
    for j in range(J):
        for m in range(N):
            for n in range(N):
                for t in range(T_max):
                    index_matched_v = []
                    index_matched_v.append(position_dictionary['v_%d%d%d%d%d'%(i,j,m,n,t)])                
                    
                    alpha = 0
                    index_matched_w = []
                    for alpha in range(1,int(modified_Transmission_time[i,m,j,n])+1):
                        index_matched_w.append(position_dictionary['w_%d%d%d%d%d'%(i,j,m,n,max(t-alpha+1,0))])

                    #slack var
                    #print(np.shape(QUBO))
                    if (alpha <= 0):
                        continue
                    else:    
                        position_dictionary["s_%d_%d%d%d%d%d"%(constraint,i,j,m,n,t)] = Total
                        Total += 1
                        QUBO = np.pad(QUBO, [(0, 1), (0, 1)], mode='constant', constant_values = 0)
                        #print(np.shape(QUBO))
                        #

                        #print(len(position_dictionary))
                        var_matched = np.zeros(Total)
                        var_matched[index_matched_v] = -1
                        var_matched[np.unique(index_matched_w)] = 1
                        var_matched[-1] = 1
                        QUBO += P13[i,j,m,n,t]*np.outer(var_matched,var_matched)

## Double Slack Variable part
#C7
constraint = 7
P7 = np.ones((I,J,N,N,T_max,T_max))
for i in range(I):
    for j in range(J):
        for m in range(N):
            for n in range(N):
                for t in range(1,T_max):
                    for beta in range(T_max-t):
                        index_matched_w = position_dictionary['w_%d%d%d%d%d'%(i,j,m,n,t+beta)]
                        index_matched_y1 = position_dictionary['y_%d%d%d%d'%(i,j,m,t-1)]
                        index_matched_y2 = position_dictionary['y_%d%d%d%d'%(i,j,m,t)]
                        index_matched_z = position_dictionary['z_%d%d%d%d'%(i,j,m,t)]
                        
                        position_dictionary["s_%d_%d%d%d%d%d"%(constraint,i,j,m,n,t)] = Total
                        Total += 2
                        QUBO = np.pad(QUBO, [(0, 2), (0, 2)], mode='constant', constant_values = 0)
                        
                        var_matched = np.zeros(Total)
                        var_matched[index_matched_w] = 1
                        var_matched[index_matched_y1] = -1
                        var_matched[index_matched_y2] = 1
                        var_matched[index_matched_z] = -1
                        var_matched[-2] = 1
                        var_matched[-1] = 2
                        
                        QUBO += P7[i,j,m,n,t,beta]*np.outer(var_matched,var_matched)

## Double Slack Variable part
#C12
constraint = 12
P12 = np.ones((I,J,N,N,T_max,T_max))
for i in range(I):
    for j in range(J):
        for m in range(N):
            for n in range(N):
                for t in range(1,T_max):
                    for beta in range(T_max-t):
                        index_matched_z = position_dictionary['z_%d%d%d%d'%(i,j,m,t+beta)]
                        index_matched_v1 = position_dictionary['v_%d%d%d%d%d'%(i,j,m,n,t-1)]
                        index_matched_v2 = position_dictionary['v_%d%d%d%d%d'%(i,j,m,n,t)]
                        index_matched_w = position_dictionary['w_%d%d%d%d%d'%(i,j,m,n,t)]
                        
                        position_dictionary["s_%d_%d%d%d%d%d"%(constraint,i,j,m,n,t)] = Total
                        Total += 2
                        QUBO = np.pad(QUBO, [(0, 2), (0, 2)], mode='constant', constant_values = 0)
                        
                        var_matched = np.zeros(Total)
                        var_matched[index_matched_z] = 1
                        var_matched[index_matched_v1] = -1
                        var_matched[index_matched_v2] = 1
                        var_matched[index_matched_w] = -1
                        var_matched[-2] = 1
                        var_matched[-1] = 2
                        
                        QUBO += P12[i,j,m,n,t,beta]*np.outer(var_matched,var_matched)

from collections import defaultdict

from dwave.system.samplers import DWaveSampler
from dwave.system.composites import EmbeddingComposite
import networkx as nx
import numpy as np

import matplotlib
matplotlib.use("agg")
from matplotlib import pyplot as plt

#from dwave.system import LeapHybridSampler


QUBO_dictionary = defaultdict(int)
for i in range(width):
    for j in range(height):
        QUBO_dictionary[(i,j)] = QUBO[i,j]

# Select a solver
#sampler = LeapHybridSampler()



# ------- Run our QUBO on the QPU -------
# Set up QPU parameters
chainstrength = 8
numruns = 3  #Max =1e4 , a Complex problem needs more numruns 

#response = sampler.sample_qubo(QUBO)

sampler = EmbeddingComposite(DWaveSampler(solver={'topology__type': 'chimera'}))
response = sampler.sample_qubo(QUBO_dictionary, chain_strength=chainstrength, num_reads=numruns)

## Retrieve QPU timing data
print(response.info["timing"]) 

## Retrieve Energy data  
energies = iter(response.data())

print('-' * 60)
print('{:>15s}{:>15s}{:^15s}{:^15s}'.format('Set 0','Set 1','Energy','Cut Size'))
print('-' * 60)
for rank, line in enumerate(response):
    # 2.
    S0_alt = ""
    for k,v in line.items():
        S0_alt += str(v)
    #print(type(v)) 
    E = next(energies).energy
  
    # 2. Binary representation: Example 5 vertices: '11000' --> -15 15
    print('{:>15s} --> {:^15s}{:^15s}'.format(str(rank),str(E),str(int(-1*E))))
    
    # only show lowest x(x = 20) enegy values and their combinations.
    if rank > 20:
        break