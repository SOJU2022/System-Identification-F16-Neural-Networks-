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

%% Dataset 
%%% Split data into training, validation and testing data
load('Datafile/F16reconstructed', 'Z_k1k', 'Cm') % obtain reconstructed data from part 2
X = Z_k1k'; 
Y = Cm';
N_meas = size(X, 1); % number of measurements

%%% Ratio split of data
train_r = 0.6; % Training ratio
test_r = 0.25;
val_r = 0.15; 

%%% Get Data with split ratio + random ordering
data_ordering = randperm(N_meas); % randomly ordering the data to avoid bias

X = X(data_ordering, :); % apply new orderly data X
Y = Y(data_ordering, :); % and to Y

%%% Get randomly ordered splitted data for both X & Y
[X_train, X_test, X_val, Y_train, Y_test, Y_val] = update_data(X, Y, train_r, test_r, val_r, N_meas);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Implementation of Radial Basis Function Neural Network
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% 1. Create Neural Network Struct. Template 

%%% Object input parameters field (see appendix D of assignment)
% Fixed fields
network_type = 'rbf';
actFunc_hidden = {'radbas'}; % Radial Basis Func for part 3
actFunc_output = {'purelin'}; % Linear Regression for output
trainAlg = {'linregress'}; % training algorithm 

% Layer parameters 
N_input = 3; % alpha, beta, V
N_hidden = 50;
N_output = 1; % Cm

% Initialization of Weights 
N_weights = N_hidden * (N_input + N_output); % total weights
Wij = randn(N_input, N_hidden); % Weights ij from input to hidden assuming 1 hidden layer
Wjk = randn(N_hidden, N_output); % Weights jk from hidden to output 
input_range = [-ones(N_input, 1), ones(N_input, 1)]; % bound to input space

% Other parameters under trainParam
epochs = 0; 
goal = 0;  % Desired performance reached > stops training
min_grad = 1e-10; % training stops when gradient below value
mu = 0; % Learning rate parameters
mu_dec = 0;
mu_inc = 0;
mu_max = 0;

% Network parameter struct
networkParam = struct('network_type', network_type, 'actFunc_hidden', actFunc_hidden, ...
    'actFunc_output', actFunc_output, 'trainAlg', trainAlg);

layerParam = struct('N_input', N_input, 'N_hidden', N_hidden, 'N_output', N_output, ...
    'N_weights', N_weights, 'Wij', Wij, 'Wjk', Wjk, 'input_range', input_range);

% Training parameter struct
trainParam = struct('epochs', epochs, 'goal', goal, ...
            'min_grad', min_grad, 'mu', mu, 'mu_dec', mu_dec, 'mu_inc', mu_inc, 'mu_max', mu_max);

% Nesting structures into one single structure
f_network = fieldnames(networkParam);
for i = 1:length(f_network)
    layerParam.(f_network{i}) = networkParam.(f_network{i});
end

f_layer = fieldnames(layerParam);
for i = 1:length(f_layer)
    trainParam.(f_layer{i}) = layerParam.(f_layer{i});
end

%%% Adding empty fields into main struct
trainParam.centers = []; % center weights
trainParam.results = []; % results
trainParam.preprocess = struct(); % preprocessing data
trainParam.postprocess = struct(); % postprocessing data

%%% Full Structure
RBF_struct = trainParam; % full neural network network structure 
Data_struct = struct('X', X, 'X_train', X_train, 'X_test', X_test, 'X_val', X_val, ...
    'Y', Y, 'Y_train', Y_train, 'Y_test', Y_test, 'Y_val', Y_val); % IO data points in struct type

%%
%%% 2. IO mapping - Simulating network output 
yRBF_NN = simNet_RBF(RBF_struct, Data_struct);

%%% 3. Results
% plot_RBF_lingress