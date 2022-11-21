%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AE4320 System Identification of Aerospace Vehicles 21/22
% Assignment: Neural Networks
% 
% Part 4 Code: FeedForward Neural Network
% Date: 15 NOV 2022
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
% Implementation of FeedForward Neural Network
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% 1. Create FF Neural Network Struct. Template 

%%% Object input parameters field (see appendix D of assignment)
% Fixed fields
FF_net.name = 'feedforward';
FF_net.trainFunc = {'tansig', 'purelin'}; % Activation function per layer
FF_net.trainAlg = {'lg'}; % training algorithm 

% Layer parameters 
FF_net.N_input = 3; % alpha, beta, V
FF_net.N_hidden = 50; % number of neurons
FF_net.N_output = 1; % Cm

% Initialization of weights parameters
FF_net.b_ij = ones(FF_net.N_hidden, FF_net.N_input); % input bias weights
FF_net.b_jk = ones(FF_net.N_output, 1); % output bias weights
FF_net.N_Wij = FF_net.N_input * FF_net.N_hidden;
FF_net.N_Wjk = FF_net.N_hidden;
FF_net.N_weights = FF_net.N_hidden * (FF_net.N_input + FF_net.N_output); % total weights
FF_net.Wij = randn(FF_net.N_input, FF_net.N_hidden); % Weights ij from input to hidden assuming 1 hidden layer
FF_net.Wjk = randn(FF_net.N_hidden, FF_net.N_output); % Weights jk from hidden to output 
input_range = [-ones(FF_net.N_input, 1), ones(FF_net.N_input, 1)]; % bound to input space

% Other parameters 
FF_net.epochs = 100; 
FF_net.goal = 1e-6;  % Desired performance reached 
FF_net.min_grad = 1e-10; % training stops when gradient below value
FF_net.mu = 0.001; % Learning rate parameters
FF_net.mu_dec = 0.1;
FF_net.mu_inc = 10;
FF_net.mu_max = 1e10;

%%% Adding empty fields for data processing
FF_net.predata = []; % prep data before putting into network
FF_net.postdata = []; % prep output data to use for analytics

%%% Put data into struct type
Data_net = struct('X', X, 'X_train', X_train, 'X_test', X_test, 'X_val', X_val, ...
    'Y', Y, 'Y_train', Y_train, 'Y_test', Y_test, 'Y_val', Y_val); % IO data points in struct type
%%
%%% 2. IO mapping - Simulating network output 
yFF_NN = simNet_FF(FF_net, Data_net);

%%% 3. Results
plot_FF_lingress
