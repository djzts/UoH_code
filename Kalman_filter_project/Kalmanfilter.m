%% part 3 Kalman filter 
clc
clear all
close all

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

%% loop
n = 5000;
mu = [5,5,1,1];
Sigma = [1,0,0  ,0;
         0,1,0  ,0;
         0,0,1/4,0;
         0,0,0,1/4;];     
Q = eye(2);
R = 0.01*eye(2);
P = Sigma;
N_kalman = 50;
 for j = 1:5000
    % Initialize x_initial and covariance matrix
    X_initial = mvnrnd(mu,Sigma)';
    X_kalman_init = X_initial;
    U(j,:,:) = mvnrnd([0,0],Q,N_kalman)';
    V(j,:,:) = mvnrnd([0,0],R,N_kalman+1)';

    X(j,:,1) = X_kalman_init;
    Y(j,:,1) = outputUpdate(X(j,:,1)',V(j,:,1)',C,D);

    for i = 2:N_kalman+1
    X(j,:,i) = stateUpdate(X(j,:,i-1)',U(j,:,i-1)',A,B);
    Y(j,:,i) = outputUpdate(X(j,:,i)',V(j,:,i)',C,D);
    end

    Xhat_k_k(j,:,1) = X_kalman_init; %#ok<SAGROW>
    Xhat_kplus1_k(j,:,1) = X_kalman_init; %#ok<SAGROW>
    
    Y_estimate_kalman(j,:,1) = outputUpdate(Xhat_k_k(j,:,1)',V(j,:,1)',C,0*R); %#ok<SAGROW>
    for i = 2 : N_kalman+1
        [Xhat_kplus1_k(j,:,i),P_pre] = Prediction(A, Xhat_k_k(j,:,i-1)',P,B*Q*B');
        [Xhat_k_k(j,:,i),P_post] = Update(Xhat_kplus1_k(j,:,i)',Y(j,:,i)',P_pre,C,R);
        temp = outputUpdate(Xhat_k_k(j,:,i)',V(j,:,i)',C,0*R);
        Y_estimate_kalman(j,:,i) = temp;
        P = P_post;
    end
    
 end

save('U.mat','U');
save('V.mat','V');
save('Xhat_k_k.mat','Xhat_k_k')
save('Xhat_kplus1_k.mat','Xhat_kplus1_k')
save('Y.mat','Y');
save('X.mat','X');

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