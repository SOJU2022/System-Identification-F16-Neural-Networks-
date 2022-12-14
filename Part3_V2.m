%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AE4320 System Identification of Aerospace Vehicles 21/22
% Assignment: Neural Networks
% 
% Part 3 Code: Radial Basis Function Neural Network
% Date: 28 OCT 2022
% Creator: J. Huang | 4159772
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all; clear; clc
plot = 0; save_fig = 0;

%% Load Dataset
%%% Split data into training, validation and testing data
load('Datafile/F16reconstructed', 'Z_k1k', 'Cm') % obtain reconstructed data from part 2
X = Z_k1k'; 
Y = Cm';
N = size(X, 1); % number of measurements

%%% Ratio split of data
train_r = 0.6; % Training ratio
test_r = 0.25;
val_r = 0.15; 
data_ordering = randperm(N); % randomly ordering the data to avoid bias

X = X(data_ordering, :); % apply new orderly data X
Y = Y(data_ordering, :); % and to Y

%%% Get randomly ordered splitted data for both X & Y
[X_train, X_test, X_val, Y_train, Y_test, Y_val] = update_data(X, Y, train_r, test_r, val_r, N);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Implementation of Radial Basis Function Neural Network
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% 1. Create RBF Neural Network Struct. Template 

%%% Object input parameters field (see appendix D of assignment)
% Fixed fields
RBF_net.name = 'rbf';
RBF_net.trainFunc = {'radbas', 'purelin'}; % Activation function per layer
RBF_net.trainAlg = {'lm'}; % training algorithm 

% Layer parameters 
RBF_net.N_input = 3; % alpha, beta, V
RBF_net.N_hidden = 50; % number of neurons
RBF_net.N_output = 1; % Cm

% Initialization of weights parameters
RBF_net.N_Wij = RBF_net.N_input * RBF_net.N_hidden;
RBF_net.N_Wjk = RBF_net.N_hidden;
RBF_net.N_weights = RBF_net.N_hidden * (RBF_net.N_input + RBF_net.N_output); % total weights
RBF_net.Wij = randn(RBF_net.N_input, RBF_net.N_hidden); % Weights ij from input to hidden assuming 1 hidden layer
RBF_net.Wjk = randn(RBF_net.N_hidden, RBF_net.N_output); % Weights jk from hidden to output 
input_range = [-ones(RBF_net.N_input, 1), ones(RBF_net.N_input, 1)]; % bound to input space

% Other parameters 
RBF_net.epochs = 1000; 
RBF_net.goal = 1e-6;  % Desired performance reached 
RBF_net.min_grad = 1e-10; % training stops when gradient below value
RBF_net.mu = 0.001; % Learning rate parameters
RBF_net.mu_dec = 0.1;
RBF_net.mu_inc = 10;
RBF_net.mu_max = 1e10;

%%% Adding empty fields for data processing
RBF_net.predata = []; % prep data before putting into network
RBF_net.postdata = []; % prep output data to use for analytics

%%% Put data into struct type
Data_net = struct('X', X, 'X_train', X_train, 'X_test', X_test, 'X_val', X_val, ...
    'Y', Y, 'Y_train', Y_train, 'Y_test', Y_test, 'Y_val', Y_val); % IO data points in struct type
%%
%%% 2. IO mapping - Simulating network output 
yRBF_NN = simNet_RBF(RBF_net, Data_net);

%%% 3. Results
plot_RBF_lingress


