function [net, X_norm, varargout] = predata_norm(net, X, varargin)

%{
    Function to preprocess the data for either input data X and output data
    Y based on normalization techniques (mapminmax function in matlab).
    > varargin collects all input from that point onwards
%}

%%% Pre data settings availability
if isempty(net.predata) 
    [X_norm, net.predata] = mapminmax(X'); % put data in range [-1, 1]
    X_norm = X_norm';
else
    X_norm = mapminmax('apply', X', net.predata); % apply pre data settings if available
    X_norm = X_norm';
end

%%% Post data setting availability
if ~isempty(varargin)
    if isempty(net.postdata)
        [Y_norm, net.postdata] = mapminmax(varargin{1}'); 
        varargout{1} = Y_norm';
    else
        Y_norm = mapminmax('apply', varargin{1}', net.postdata);
        varargout{1} = Y_norm'; 
    end
end
