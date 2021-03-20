# Copyright 2019 D-Wave Systems, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ------ Import necessary packages ----
from collections import defaultdict

from dwave.system.samplers import DWaveSampler
from dwave.system.composites import EmbeddingComposite
import networkx as nx
import numpy as np

import matplotlib
matplotlib.use("agg")
from matplotlib import pyplot as plt

# setup a random symmetric 2D matrix with 0 diag (a point won't connect it self)
def Make_Question(n):
    G_ori = np.around(np.random.rand(n, n),decimals=3)
    G_final = G_ori - np.diag(np.diag(G_ori))
    Question =  (G_final + G_final.T)/2
    return Question
# ------- Set up our graph -------

# Create empty graph
G = nx.Graph()

# Another way to add edge purely by hand to the graph (also adds nodes)
# G.add_edges_from([(1,2),(1,3),(2,4),(3,4),(3,5),(4,5)])

# Claim the number Vertices  
# (Max number of vertices is between 135 to 149)
n = 135

#conver the symmetric matrix into an upper triangler matrix (Optional)
Question = np.triu(np.array(Make_Question(n)), k=1)

#Show how many vertices
print(n)

# Convert the 2D N*N matrix into a netgraph without weight: 
# output only has the relationship between vertices. 
G = nx.from_numpy_matrix(Question, create_using=nx.MultiGraph)

# ------- Set up our QUBO dictionary -------

# Initialize our Q matrix
Q = defaultdict(int)

# Show graph's edges
# print(G.edges)

# Update Q matrix for every edge in the graph and every weight in our question
for i, j in G.edges():
    Q[(i,i)]+= -1 * Question[i,j]
    Q[(j,j)]+= -1 * Question[i,j]
    Q[(i,j)]+=  2 * Question[i,j]

# ------- Run our QUBO on the QPU -------
# Set up QPU parameters
chainstrength = 8
numruns = 10000  #Max =1e4 , a Complex problem needs more numruns 

# Run the QUBO on the solver from your config file
sampler = EmbeddingComposite(DWaveSampler())
response = sampler.sample_qubo(Q, chain_strength=chainstrength, num_reads=numruns)

## Retrieve QPU timing data
print(response.info["timing"]) 

## Retrieve Energy data  
energies = iter(response.data())

# ------- Print results to user -------
print('-' * 60)
print('{:>15s}{:>15s}{:^15s}{:^15s}'.format('Set 0','Set 1','Energy','Cut Size'))
print('-' * 60)
for rank, line in enumerate(response):
    # 1.
    # S0 = [k for k,v in line.items() if v == 0]
    # S1 = [k for k,v in line.items() if v == 1]
    # 
    # Vertices representation: Example 5 vertices: [0,1][2,3,4] -15 15
    # print('{:>15s}{:>15s}{:^15s}{:^15s}'.format(str(S0),str(S1),str(E),str(int(-1*E))))
    
    
    # 2.
    S0_alt = ""
    for k,v in line.items():
        S0_alt += str(v)
    #print(type(v)) 
    E = next(energies).energy
  
    # 2. Binary representation: Example 5 vertices: '11000' --> -15 15
    print('{:>15s} --> {:^15s}{:^15s}'.format(str(S0_alt),str(E),str(int(-1*E))))
    
    # only show lowest x(x = 20) enegy values and their combinations.
    if rank > 20:
        break

# ------- Display results to user -------
# Grab best result
# Note: "best" result is the result with the lowest energy
# Note2: the look up table (lut) is a dictionary, where the key is the node index
#   and the value is the set label. For example, lut[5] = 1, indicates that
#   node 5 is in set 1 (S1).
lut = response.first.sample

# Interpret best result in terms of nodes and edges
S0 = [node for node in G.nodes() if not lut[node]]
S1 = [node for node in G.nodes() if lut[node]]
cut_edges = [(u, v) for u, v in G.edges() if lut[u]!=lut[v]]
uncut_edges = [(u, v) for u, v in G.edges() if lut[u]==lut[v]]

# Display best result
pos = nx.spring_layout(G)
nx.draw_networkx_nodes(G, pos, nodelist=S0, node_color='r')
nx.draw_networkx_nodes(G, pos, nodelist=S1, node_color='c')
nx.draw_networkx_edges(G, pos, edgelist=cut_edges, style='dashdot', alpha=0.5, width=3)
nx.draw_networkx_edges(G, pos, edgelist=uncut_edges, style='solid', width=3)
nx.draw_networkx_labels(G, pos)

filename = "maxcut_plot.png"
plt.savefig(filename, bbox_inches='tight')
print("\nYour plot is saved to {}".format(filename))
