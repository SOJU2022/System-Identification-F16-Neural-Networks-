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
epochs = 10; 
goal = 100;  % Desired performance reached > stops training
min_grad = 1e-10; % training stops when gradient below value
mu = 1e22; % Learning rate parameters
mu_dec = 0.1;
mu_inc = 1.1;
mu_max = 1e10;

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
trainParam.predata = []; % prep data before putting into network
trainParam.postdata = []; % prep output data to use for analytics

%%% Full Structure
RBF_struct = trainParam; % full neural network network structure 
Data_struct = struct('X', X, 'X_train', X_train, 'X_test', X_test, 'X_val', X_val, ...
    'Y', Y, 'Y_train', Y_train, 'Y_test', Y_test, 'Y_val', Y_val); % IO data points in struct type

%%
%%% 2. IO mapping - Simulating network output 
yRBF_NN = simNet_RBF(RBF_struct, Data_struct);

%%% 3. Results
% plot_RBF_lingress

%% Test environment

%%% Data basic preprocessing using normalization to scale X and Y. 
[output, Xtrain_norm, Ytrain_norm] = predata_norm(RBF_struct, Data_struct.X_train, Data_struct.Y_train); 

switch RBF_struct.trainAlg
    case 'levenmarq'

        %%% Learning algorithm: adaptive learning rate: Levenberg-Marquardt
        
        %%% Initialization of parameters
        Et = zeros(RBF_struct.epochs, 1); % Cost Function Et 
        MSE = zeros(RBF_struct.epochs, size(Data_struct.X, 2)); % MSE for each dataset per epoch
        
        %%% Get centroids for RBF
        [idx, centroid] = kmeans(Xtrain_norm, RBF_struct.N_hidden); % get clustered neuron centroid locations
        output.centers = centroid;
        
        %%% stop loop conditions
        early_stop = 0;
        
        %%% Looping through epochs 
        
        for epochs = 1:RBF_struct.epochs
            %%% Feedforward to obtain MSE for backpropagation process
            
            % Step 1. First a foward computation step to compute v and y
            Y_est_train = output_sim(output, Xtrain_norm);
            
            % Then the output errors are compute ek
            error = MSE_output(Ytrain_norm, Y_est_train);
            
            %%% Compute cost function value Et per epoch
            Et(epochs) = error;
            
            % Finally the cost function dependencies on the weights are
            % propogataed from right to left with starting point Et
            
           
            %%% Obtain weight update: w_t1 = wt-(J'*J+mu*I)^-1*J'*e
            
            % Compute the Jacobian Matrix J 
            % [J, err] = calc_J(output, Xtrain_norm, Ytrain_norm);
            %%% Parameter setups
N_meas = size(Xtrain_norm, 1); % number of measurement points
N_input = size(Xtrain_norm, 2); % number of input vars

%%% FeedForward process 
[Y_est, phi_j, vj, R] = output_sim(output, Xtrain_norm);

%%% Start backpropagation process 
% 1. Compute dependencies wrt network outputs yk
err_k = Ytrain_norm-Y_est;
dE_dy_k = err_k*-1; 

% 2. Compute dependencies wrt output layer input vk
dy_dvk = 1; % linear activation function

% 3. Compute dependencies wrt hidden layer weights
dvk_dWjk = phi_j; % output of the hidden layer yj
dE_dWjk = dE_dy_k .* dy_dvk .* dvk_dWjk;

% 4. Compute dependencies wrt hidden layer activation function output yj
dvk_dyj = output.Wjk;
% dE_dyj = dE_dy_k .* dy_dvk .* dvk_dyj;

% 5. Compute dependencies wrt hidden layer activation function output yj
% wrt hidden layer inputs vj

dphi_j_dvj = -phi_j; 

% 6. Compute dependencies wrt input weights
dvj_dWij = R.^2; % equal to yi - output of the input layer 

% Complete Partial Derivatives
for i = 1:N_input
    dE_dWij(:,:,i) = dE_dy_k .* dy_dvk .* dvk_dyj' .* dphi_j_dvj .* dvj_dWij(:,:,i);
end

%%% Compute full Jacobian matrix
J = [reshape(dE_dWij, [N_meas, output.N_input*output.N_hidden]) dE_dWjk];
err = 0.5 * (Ytrain_norm-Y_est).^2; 
            
            % Compute Hessian matrix transposed(J)*J
            H = J'*J; 
            
            % Reshape weights into an one-liner
            wt = reshape([RBF_struct.Wij' RBF_struct.Wjk], 1, RBF_struct.N_weights);
            
            % From weight update w_t1 equation
            w_t1 = wt - ((H + RBF_struct.mu * eye(size(H))) \ (J' * err))'; % check if ' is needed
            
            % Updated Weights
            w_t1_update = reshape(w_t1, RBF_struct.N_hidden, RBF_struct.N_input + RBF_struct.N_output);
            output.Wij = w_t1_update(:, 1:RBF_struct.N_input)';
            output.Wjk = w_t1_update(:, end);
            
            % Get the error output using the updated weights
            Ytrain_update = output_sim(output, Xtrain_norm);
            err_update = MSE_output(Ytrain_norm, Ytrain_update);
            
            %%% Apply adaptive learning rate algo based on updated error
            while err_update > err
                % if updated error is bigger than previous error - increase
                % learning rate
                RBF_struct.mu = RBF_struct.mu * RBF_struct.mu_inc;
                
                % Weight update given new learning rate
                w_t1 = wt - ((H + RBF_struct.mu * eye(size(H))) \ (J' * err))';
                w_t1_update = reshape(w_t1, RBF_struct.N_hidden, RBF_struct.N_input + RBF_struct.N_output);
                output.Wij = w_t1_update(:, 1:RBF_struct.N_input)';
                output.Wjk = w_t1_update(:, end);
                
                % Get new updated error for new weights
                Ytrain_update = output_sim(output, Xtrain_norm);
                err_update = MSE_output(Ytrain_norm, Ytrain_update);
            end
            
            output.Wij = w_t1_update(:, 1:RBF_struct.N_input)';
            output.Wjk = w_t1_update(:, end);
            
            %%% Get results for each dataset
            
            %%% Normalization preprocessing
[output, X_norm] = predata_norm(output, Data_struct.X_train);

%%% Obtain vj - function from input to hidden
% Squared Distance 
R(:,:,1) = (X_norm(:,1) - output.centers(:,1)').^2;
R(:,:,2) = (X_norm(:,2) - output.centers(:,2)').^2;
R(:,:,3) = (X_norm(:,3) - output.centers(:,3)').^2;

vj = output.Wij(1,:).* R(:,:,1) + output.Wij(2,:).* R(:,:,2) + ...
    output.Wij(3,:).* R(:,:,3);

%%% Use the RBF activation function to get output of the hidden layer
phi_j = exp(-vj);

%%% Use output of the hidden layer to get vk (function of Wjk and output of
%%% hidden layer). In equation form: vk = sum_j(ajk * phi_j)
vk = phi_j * output.Wjk;

%%% Output layer neuron Y (purelin transfer function)
Y_est_norm = vk;

%%% Reverse normalization for Y_est_norm output
Y_est = mapminmax('reverse', Y_est_norm', output.postdata);
Y_est = Y_est'; 

            [Y_est_train, phi_j_train, vj_train, R_train] = output_sim_linreg(output, Data_struct.X_train);
            [Y_est_test, phi_j_test, vj_test, R_test] = output_sim_linreg(output, Data_struct.X_test);
            [Y_est_val, phi_j_val, vj_val, R_val] = output_sim_linreg(output, Data_struct.X_val);
            
            %%% MSE
            MSE(epochs, 1) = MSE_output(Data_struct.Y_train, Y_est_train); 
            MSE(epochs, 2) = MSE_output(Data_struct.Y_test, Y_est_test); 
            MSE(epochs, 3) = MSE_output(Data_struct.Y_val, Y_est_val); 
            
            %%% Determine requirements to stop the loop
            [stop, early_stop, output] = stop_condition(RBF_struct, epochs, Et, MSE, early_stop);
                
            if stop
                break
            end  
            
        end
end

%% Test environment for linregress

%%% Data basic preprocessing using normalization to scale X and Y. 
[output, Xtrain_norm, Ytrain_norm] = predata_norm(RBF_struct, Data_struct.X_train, Data_struct.Y_train); 

switch RBF_struct.trainAlg
    
    case 'linregress' 
        
        [idx, centroid] = kmeans(Xtrain_norm, RBF_struct.N_hidden); % get clustered neuron centroid locations
        output.centers = centroid;
       
        %%% Input Layer - obtain Vj struct from input layer
        vj = calc_vj(output, Xtrain_norm);
        
        %%% Activitation function given by phi_j(vj) = a*exp(-vj) 
        phi_j = exp(-vj); 
        output.Wjk = pinv(phi_j) * Ytrain_norm; % get the hidden-output layer weights
        
        %%% Get estimated struct for each dataset using obtained Wjk
        [Y_est_train, phi_j_train, vj_train, R_train] = output_sim(output, Data_struct.X_train);
        [Y_est_test, phi_j_test, vj_test, R_test] = output_sim(output, Data_struct.X_test);
        [Y_est_val, phi_j_val, vj_val, R_val] = output_sim(output, Data_struct.X_val);
        
        %%% Obtain the model error using MSE between measured Y set and
        %%% Y_est 
        output.results.MSE_train = MSE_output(Data_struct.Y_train, Y_est_train); 
        output.results.MSE_test = MSE_output(Data_struct.Y_test, Y_est_test); 
        output.results.MSE_val = MSE_output(Data_struct.Y_val, Y_est_val); 
end