%% Draft script to analyze study 2 data

% This script will try to fit a learning curve to each participants data.
% It will load the long form data table of all participant data and 
% use fminsearch to find the best fit of the model to data, using
% least squares error.

% It will record the output in the results_table_all_ptp_analyzed.mat and the
% long_form_data_all_ptp_analyzed.mat

%% Global parameters
clear; close all;

dbstop if error;

% Check you're in the right directory 
home = pwd;
   
[~,name,~] = fileparts(home);

if ~strcmp('concept_gen_analysis',name)
    error('please change working directory to ./con_learn/concept_gen_analysis/');
end

addpath(genpath(home));

%% Data parameters 
saveLongFormFiles     = 1;
saveResultsTableFiles = 1;
plotFMSEstimation     = 0;

%% Load the data for all ptps:
[long_form_data_all_ptp,results_table_all_ptp,...
    ~, ~] = ...
    load_all_participant_files(home);

nPtp = height(results_table_all_ptp);

%% First, remove the redundant empty columns
long_form_data_all_ptp = removevars(long_form_data_all_ptp,...
    {'learning_rate_intercept','learning_rate_exponent'});

results_table_all_ptp = removevars(results_table_all_ptp,...
    {'learning_rate_intercept','learning_rate_exponent'});


%% Now, for each ptp, for each phase, fit the model.

%% Start the loop

% Create the fields to hold the data
results_table_all_ptp.phase_1_learning_rate_exp = NaN(nPtp,1);
results_table_all_ptp.phase_2_learning_rate_exp = NaN(nPtp,1);
results_table_all_ptp.phase_1_learning_rate_int = NaN(nPtp,1);
results_table_all_ptp.phase_2_learning_rate_int = NaN(nPtp,1);
results_table_all_ptp.phase_1_learning_rate_sse = NaN(nPtp,1);
results_table_all_ptp.phase_2_learning_rate_sse = NaN(nPtp,1);

long_form_data_all_ptp.learning_rate_exp = NaN(height(long_form_data_all_ptp),1);
long_form_data_all_ptp.learning_rate_int = NaN(height(long_form_data_all_ptp),1);
long_form_data_all_ptp.learning_rate_sse = NaN(height(long_form_data_all_ptp),1);

for iPtp = 1:nPtp
    
    % Name of current participant
%     iPtp
    curr_ptp = results_table_all_ptp.ptp{iPtp};
    
    curr_congruency = results_table_all_ptp.congruency(iPtp);
    
    for iPhase = 1:2
        
        %% Get data for this ptp for this phase, minus practice trials
        idx_ptp      = strcmp(long_form_data_all_ptp.ptp,curr_ptp);
        idx_phase    = long_form_data_all_ptp.phase == iPhase;
        % Find practice trials
        idx_practice = long_form_data_all_ptp.session == -1;
        idx_wanted   = idx_ptp & idx_phase & ~idx_practice;
        
        % Some participants failed QC, so had no phase 2. Skip the loop for
        % them.
        if nnz(idx_wanted) == 0
            continue
        end
        
        curr_data    = long_form_data_all_ptp(idx_wanted,:);
        
        % Get the actual performance, correct/incorrect on each trial.
        % NaN means missed trials.
        y            = curr_data.correct;
        n_trials     = length(y);
            
        %% Calculate the intercept and learning rate using fminsearch
        
        % Starting value for c0
        c0         = 0.1;
        intercept0 = 0.5;
        % Optimize with respect to c
        params = c0;
        [fms_est_c_fixed_intercept,...
            fms_est_c_fixed_intercept_sse] = est_learning_rate(y,params,plotFMSEstimation);
        
        % Record everything in the results table
        results_table_all_ptp.(...
            ['phase_' int2str(iPhase) '_learning_rate_exp'])(iPtp) = ...
            fms_est_c_fixed_intercept;
        results_table_all_ptp.(...
            ['phase_' int2str(iPhase) '_learning_rate_int'])(iPtp) = ...
            intercept0;
        results_table_all_ptp.(...
            ['phase_' int2str(iPhase) '_learning_rate_sse'])(iPtp) = ...
            fms_est_c_fixed_intercept_sse;        
        
        % Also record in the long_form_data
        idx_long_form_row = long_form_data_all_ptp.phase == iPhase & ...
            strcmp(long_form_data_all_ptp.ptp,curr_ptp);
        
        long_form_data_all_ptp.learning_rate_exp(idx_long_form_row) = fms_est_c_fixed_intercept;
        long_form_data_all_ptp.learning_rate_int(idx_long_form_row) = intercept0;
        long_form_data_all_ptp.learning_rate_sse(idx_long_form_row) = fms_est_c_fixed_intercept_sse;
        
    end % Phase
end % iPtp

%% Now, calculate differences between phase 1 and phase 2 for each dep var

% For learning rate
results_table_all_ptp.phase_2_min_phase_1_learning_rate_exp = ...
    results_table_all_ptp.phase_2_learning_rate_exp - ...
    results_table_all_ptp.phase_1_learning_rate_exp;

% For ses 1 and 2 performance
results_table_all_ptp.phase_2_min_phase_1_ses_1_2_perf = ...
    results_table_all_ptp.phase_2_ses_1_2_perf - ...
    results_table_all_ptp.phase_1_ses_1_2_perf;

%% Save these as new files
if saveLongFormFiles 
    save(fullfile(home,'results','analysis',...
        'long_form_data_all_ptp_analyzed.mat'),'long_form_data_all_ptp');
end

if saveResultsTableFiles
    save(fullfile(home,'results','analysis',...
        'results_table_all_ptp_analyzed.mat'),'results_table_all_ptp');   
end