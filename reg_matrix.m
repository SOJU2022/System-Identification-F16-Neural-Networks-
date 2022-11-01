function set_Ax = reg_matrix(X, polynomial_order)

%{
    Defines the regression matrix A(x) for a given polynomial order
%}

X_states = size(X, 2); % number of measurement states
exp_order = zeros(1, X_states); % define exponential orders for each measurement given X measurement states

%%% Loop through polynomial order and assign exponential values for each measurement N
for M = 1:polynomial_order
        exp_order = [exp_order; exp_matrix(X_states, polynomial_order)];

end

    function  exp_output = exp_matrix(states, order)
    
    %{
        Create a matrix that includes all possible exponential combination given a certain polynomial order
    %}

    if states <= 1
        exp_output = polynomial_order;
    else
        exp_output = zeros(0, states);

        % Loop through all the remaining orders
        for i = order:-1:0
            recursive = exp_matrix(states-1, order-i);
            exp_output = [exp_output; i * ones(size(recursive,1), 1), recursive];
        end
    end
    
    end % end nested func

set_Ax = x2fx(X, exp_order); % x2fx function to assemble Ax given order of the regression model
end % end parent func

