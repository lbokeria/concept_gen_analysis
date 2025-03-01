function [out_params,fval] = est_learning_rate(ptp_data,params,plotEstimation)
    
    options = optimset('PlotFcns',@optimplotfval);    
    
    % fminsearch will find the best gamma
    if plotEstimation
        [out_params,fval] = fminsearch(@fit_learning,params,options);
    else
        [out_params,fval] = fminsearch(@fit_learning,params);
    end
    % A nested function, so that the @mink_distance could also take in
    % extra acrguments (diag, side1, and side2) from the parent function
    % @find_min_gamma
    function sse = fit_learning(x)
       
        trials = 1:length(ptp_data);
        
        % Are we optimizing both c and offset or just one?
        if length(params) == 1
            % So we are optimizing only learning rate, 1st parameter
            offset = 0.5;
            
            y_hat = (1 - offset * exp(-x * (trials - 1)))';
        else
            % For optimize both rate and offset
            y_hat = (1 - x(2) * exp(-x(1) * (trials - 1)))';
            
        end
        
        sse = nansum(abs(ptp_data - y_hat).^2);
        
    end

end