clc
clear all
close all
load('process_and_measurement_noises.mat');
load('states_and_observations.mat');

%% part 0 model setup
T =0.1;
A = [1,0,T  ,0  ;
     0,1,0  ,T  ;
     0,0,0.9,0.4;
     0,0,-0.4,0.9;];
B = [T^2/2 ,   0;
       0   , T^2/2;
       T   ,   0;
       0   ,   T;];
C = [1,0,0,0;
     0,1,0,0;];
D = 1;

%% part 1  model validation
X_pre = X(:,1);
N = 50;
Y_estimate = outputUpdate(X_pre,V(:,1),C,D);

for i = 2:N+1
X_pre = stateUpdate(X_pre,U(:,i-1),A,B);

Y_estimate(:,i) = outputUpdate(X_pre,V(:,i),C,D);
end

validation_index = sum(abs(Y_estimate-Y));
if validation_index ==0
    disp("Part 1: The Y estimation matches Y from the other files exactly ")
else
    disp("Part 1: The Y estimation does not match Y from the other files exactly ")
end

%% part 2 Kalman filter formulation and validation
% Initialize x_initial and covariance matrix
mu = [5,5,1,1];
Sigma = [1,0,0  ,0;
         0,1,0  ,0;
         0,0,1/4,0;
         0,0,0,1/4;];     
Q = eye(2);
R = 0.01*eye(2);
P = Sigma;
N_kalman = 50;
N_MMSE = 50;
X_initial = mvnrnd(mu,Sigma)';

%% Part2.1
X_kalman_init = X_initial;
U_kalman = mvnrnd([0,0],Q,N_kalman)';
V_kalman = mvnrnd([0,0],R,N_kalman+1)';

X_temp = X_kalman_init;
Y_collect = outputUpdate(X_temp,V_kalman(:,1),C,D);
Y_true = outputUpdate(X_temp,V_kalman(:,1),C,0);
for i = 2:N_kalman+1
X_temp = stateUpdate(X_temp,U_kalman(:,i-1),A,B);

Y_collect(:,i) = outputUpdate(X_temp,V_kalman(:,i),C,D);
Y_true(:,i) = outputUpdate(X_temp,V_kalman(:,i),C,0);
end

m = X_kalman_init;

X_kalman(:,1) = X_kalman_init;
Y_estimate_kalman = outputUpdate(X_kalman,V_kalman(:,1),C,0);
for i = 2:N_kalman+1
    [m_pre,P_pre] = Prediction(A,m,P,B*Q*B');
    yk = Y_collect(:,i);
    [m,P_post] = Update(m_pre,yk,P_pre,C,R);
    X_kalman(:,i) = m;
    Y_estimate_kalman(:,i) = outputUpdate(m,V_kalman(:,i),C,0);
    P = P_post;
end

figure(1)
plot(Y_true(1,:),Y_true(2,:));
hold on
scatter(Y_collect(1,:),Y_collect(2,:));
figure(2)
scatter(Y_collect(1,:),Y_collect(2,:));
hold on
plot(Y_estimate_kalman(1,:),Y_estimate_kalman(2,:),'b-.');

%% Part 2.2
for i = 1:10
    X_MMSE(:,1,i) = X_initial;
    U_MMSE = U_kalman;
    V_MMSE = mvnrnd([0,0],R,N_MMSE+1)';
    
    X_pre =  X_initial;
    P_pre = Sigma;
    Y_MMSE_collect(:,1,i) = outputUpdate(X_pre,V_MMSE(:,1),C,D);
    P_MMSE(:,:,1,i) = P_pre;
    for j = 2:N_MMSE+1
        P_MMSE(:,:,j) = A*P_pre*A'+ B*Q*B';
        X_pre = stateUpdate(X_pre,U_MMSE(:,j-1),A,B);
        X_MMSE(:,j,i) = X_pre;
        Y_MMSE_collect(:,j,i) = outputUpdate(X_pre,V_MMSE(:,j),C,D);
    end
end

for j = 1:N_MMSE+1
part1 = mean(X_MMSE(:,j,:),3);
part2 = P_MMSE(:,:,j)*C'*inv(C*P_MMSE(:,:,j)*C'+ Q);
part3 = (Y_collect(:,j,:)-mean(Y_MMSE_collect(:,j,:),3));
X_MMSE_estimate(:,j) = part1+ part2*part3;
end
Y_MMSE_estimate = Y;
for j = 1:N_MMSE+1
    Y_MMSE_estimate(:,j) = outputUpdate(X_MMSE_estimate(:,j),V_kalman(:,j),C,0); 
end
figure(3)
scatter(Y_collect(1,:),Y_collect(2,:));
hold on
plot(Y_MMSE_estimate(1,:),Y_MMSE_estimate(2,:),'g-.');



%% function set


function [X_pre,P_pre] = Prediction(A,X,P,Q)
    X_pre = A*X;
    P_pre = A*P*A' + Q;
end

function [X_post,P_post] = Update(X_pre,yk,P_pre,H,R)
    v = yk - H*X_pre;
    S = H*P_pre*H' + R;
    K = P_pre*H'*(inv(S));
    X_post = X_pre +K*v;
    P_post = P_pre - K*S*K';
end


function X_update = stateUpdate(X,U,A,B)
    X_update = A*X + B*U;
end

function Y_update = outputUpdate(X,V,C,D) 
    Y_update = C*X +D*V;
end