%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AE4320 System Identification of Aerospace Vehicles 21/22
% Assignment: Neural Networks
% 
% Part 2 Code: State & Parameter Estimation
% Date: 28 OCT 2022
% Creator: J. Huang | 4159772
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all 
clear
clc

app_chart = 0;
save_fig = 0;

%% Load Data
load_f16data2022

% Tranposed data
Cm = Cm'; Zk = Z_k'; Uk = U_k'; % measurement dataset

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Start of State Estimation using IEKF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%{  
    Part 2.1 - General overview of f16 state and output system eqs
    1) System State Equation: xdot(t) = f(x(t), u(t), t)
        > State Vector: x(t) = [u v w C_alpha_up]
        > Input Vector: u(t) = [udot, vdot, wdot]
    
    2) Measurement (Output) Equation: z(t) = h(x(t), u(t), t)
        > Output vector: z(t) = [alpha_m beta_m V_m]
        > Additional + [v_alpha v_beta v_V] as white noise 
%}

%%% Parameters

%%% states + input
states = 4; % u, w, v, C_alpha_up
input = 3; % udot, wdot, vdot

%%% Time data
N = size(Zk, 2)-1; % Number of sampling data
tstart = 0;
dt = 0.01; % sampling rate
tend = dt*(N); % usually equal to N, but takes longer to load
tspan = tstart:dt:tend; % tspan needed for numerical integration later

%%% Process(w) + Sensor(v) Noise Statistics 
Ew = zeros(1, states); % Expectation Process Noise
sigma_w = [1e-3 1e-3 1e-3 0]; % std. dev. 
Q = diag(sigma_w.^2); % E(w*wT)

Ev = zeros(1, input);  % Expectation White Noise
sigma_v = [0.035 0.013 0.110]; 
R = diag(sigma_v.^2); % E(v*vT)

%% Nonlinear System Analysis + IEKF (Part 2.3)
%%% Check if observability matrix is full ranked in order to apply KF
observ_check

%%% Apply IEKF
[X_est_k1k1, Z_k1k_biased, IEKF_count] = func_IEKF(Uk, Zk, dt, sigma_w, sigma_v);

%% Reconstruction of alpha_true using upwash bias (Part 2.4)

%%% Apply correction to measured alpha with upwash bias to get true alpha
Z_k1k = Z_k1k_biased;
Z_k1k(1,:) = Z_k1k(1,:) ./ (1 + X_est_k1k1(4,:)); % adjust alpha outcome with bias term

%%% Save Data for further use
save('Datafile/F16reconstructed', 'Z_k1k', 'Cm')

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Implementation OLS estimator for simple polynomial F16 model structure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% 1. Measurement Data Formulation and Data Model Reconstruction 

X = Z_k1k'; % mx1 state vector - reconstructed Z
Y = Cm'; % Nx1 measurement vector
polynomial_order = 5; % adjustable based on fitting

%%% 2. Identify Linear Regression Model Structure + Parameter Definitions
%%%  Linear-in-the-parameter polynomial model y=Ax*theta

% Regression Matrix Ax 
Ax = reg_matrix(X, polynomial_order); 

%%% 3. Formulate the Least Square Estimator 
theta_OLS = pinv(Ax)*Y; % OLS equation from slide

Y_est = Ax*theta_OLS; % estimated Y using estimated thetas

% chart_OLS(X, Y, Y_est, save_fig, 'OLS'); 

%% Part 2.6-2.8: Model Validation 
%%% 2.6 - Parameters
order_iter = 15; % iterative order to check fit
X_val = [alpha_val beta_val]; % validation dataset
Y_val = Cm_val;

%%% Obtain MSE for increasing order 
MSE_meas = MSE_model(X, Y, order_iter); % Applied on measurement dataset
MSE_val = MSE_model(X_val, Y_val, order_iter);

chart_MSE(MSE_meas, MSE_val, order_iter)

%% 2.7 Model-Error Validation

%{
    Performs a model-error based validation to check whether 
    the OLS estimator satifisfies the BLUE (Best Linear Unbiased Estimator) estimator requirements:
    
    Requirement 1: E{residual_err} = 0 (zero-mean white noise)
    Requirement 2: Able to predict noise sensitivity or variability of OLS
    estimator using a certain confidence interval where the noise takes
    place most of the time. 
%}

%%% Use the optimal model order to obtain Y_optimal
[M, I] = min(MSE_meas); % M is the value, I is the optimal index/order
optim_order = I; 
Ax_optim = reg_matrix(X, optim_order); % redo OLS process
theta_OLS_optim = pinv(Ax_optim)*Y;
Y_est_optim = Ax_optim*theta_OLS_optim;

%%% Calculate residuals of using optimal model order
eps_optim = Y_est_optim - Y;

%%% calculate confidence range of 95% for this optimal residual
[eps_corr, conf_range, lags] = model_err_val(eps_optim);

chart_mod_err_val % Chart conclusion for requirements 1 & 2 

%%% Statistical-Error Validation


%% Plots

%%% Get charts
if (app_chart)
    chart_IEKF % Part 2.4
    chart_OLS(X, Y, Y_est, save_fig, 'OLS'); % Part 2.5 
end



