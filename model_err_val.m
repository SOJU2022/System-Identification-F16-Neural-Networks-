function [eps_corr, conf_range] = model_err_val(X, Y)

%{
    Function that performs a model-error based validation to check whether 
    the OLS estimator satifisfies the BLUE (Best Linear Unbiased Estimator) estimator requirements:
    
    Requirement 1: E{residual_err} = 0 (zero-mean white noise)
    Requirement 2: Able to predict noise sensitivity or variability of OLS
    estimator using a certain confidence interval where the noise takes
    place most of the time. 
%}



end
