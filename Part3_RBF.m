%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AE4320 System Identification of Aerospace Vehicles 21/22
% Assignment: Neural Networks
% 
% Part 3 Code: Radial Basis Funcion Neural Network
% Date: 28 OCT 2022
% Creator: J. Huang | 4159772
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all 
clear
clc

app_chart = 0;
save_fig = 0;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Implementation of Radial Basis Function Neural Network
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Neural Network Struct. Template 
%%% Use objects for struct template due to high amount of parameters

%%% Object input parameters field (see appendix D of assignment)
% Fixed fields
network_type = 'rbf';
actFunc_hidden = {'radbas'}; % Radial Basis Func
actFunc_output = {'purelin'}; % Linear Regression for input & output
trainAlg = {'trainlm'}; % training algorithm 

% Layer parameters
N_input = 3; % alpha, beta, V
N_hidden = 50;
N_output = 1; % Cm

input_range = [-ones(N_input, 1), ones(N_input, 1)]; % bounds on input space

% Structure containing fields used during training
train_type = 'linregress';
epochs = 0; 
goal = 0;  % Desired performance reached > stops training
min_grad = 1e-10; % training stops when gradient below value

% Learning parameters
mu = 0; 
mu_dec = 0;
mu_inc = 0;
mu_max = 0;

% Training parameter struct
trainParam = struct('train_type', train_type, 'epochs', epochs, 'goal', goal, ...
            'min_grad', min_grad, 'mu', mu, 'mu_dec', mu_dec, 'mu_inc', mu_inc, 'mu_max', mu_max);

% Other parameter struct
networkParam = struct('network_type', network_type, 'actFunc_hidden', actFunc_hidden, ...
    'actFunc_output', actFunc_output, 'trainAlg', trainAlg);

layerParam = struct('N_input', N_input, 'N_hidden', N_hidden, 'N_output', N_output, ...
    'input_range', input_range);

% Nest structures into one structure
f_train = fieldnames(trainParam);
for i = 1:length(f_train)
    networkParam.(f_train{i}) = trainParam.(f_train{i});
end

f_network = fieldnames(networkParam);
for i = 1:length(f_network)
    layerParam.(f_network{i}) = networkParam.(f_network{i});
end

RBF_struct = layerParam; % full neural network network structure 

%%% IO mapping - Simulating network output 
yRBF_NN = simNet_RBF(RBF_struct);

%%% Simulation Network Functions

%%% Training

%%% Results

