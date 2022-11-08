function output = simNet_RBF(struct, data)

%{
    Function that trains the neural network based on several activation
    functions:
    > Linear Regression (linregress)
    > Levenberg-Marquardt (lm)
%}

output = struct; % same structure but output updated in training simulation

%%% Data basic preprocessing using normalization to scale X and Y. 
[X_norm, output.preprocess] = mapminmax(data.X_train'); % scale within [-1, 1] which is the default mapping
X_norm = X_norm'; % transpose back

[Y_norm, output.postprocess] = mapminmax(data.Y_train');
Y_norm = Y_norm';


% %%% Choose and Start Training Algorithm
switch struct.trainAlg
    case 'linregress' 
        
        [idx, centroid] = kmeans(X_norm, struct.N_hidden); % get clustered neuron centroid locations
        output.centers = centroid;
       
        %%% Input Layer - obtain Vj output from input layer
        vj = calc_vj(output, X_norm);
        
        %%% Activitation function given by phi_j(vj) = a*exp(-vj) 
        phi_j = exp(-vj); 
        
        output.Wjk = pinv(phi_j) * Y_norm; % get the output layer weights
        
        %%% Get estimated output for each dataset using obtained Wjk
        Y_est_train = output_sim(output, data.X_train);
        Y_est_test = output_sim(output, data.X_test);
        Y_est_val = output_sim(output, data.X_val);
        
        %%% Obtain the model error using MSE between measured Y set and
        %%% Y_est 
        output.results.MSE_train = MSE_output(data.Y_train, Y_est_train); 
        output.results.MSE_test = MSE_output(data.Y_test, Y_est_test); 
        output.results.MSE_val = MSE_output(data.Y_val, Y_est_val); 
end