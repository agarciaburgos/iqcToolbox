classdef PerformanceStable < Performance
%% PERFORMANCESTABLE class to indicate that IQC analysis is only to check %
% robust stability. This extends the base class Performance.
%
%   extended methods:
%     PerformanceStable() :: Constructor
%     disp(this_perf) :: Display method
%     matchHorizonPeriod(this_perf, horizon_period) :: Matches performance properties to new horizon_period
%     performanceToMultiplier(this_perf) :: Generate multiplier from performance

%%
%  Copyright (c) 2021 Massachusetts Institute of Technology 
%  SPDX-License-Identifier: GPL-2.0
%%

methods
    
function this_perf = PerformanceStable(horizon_period)
%% PERFORMANCESTABLE constructor
%
%  p = PerformanceStable(horizon_period) 
%  p = PerformanceStable() assumes horizon_period == [0, 1]
%
%  See also PerformanceStable, Performance.Performance

    % Defining defaults for missing arguments
    switch nargin
        case 0
            horizon_period = [0, 1];
    end
    total_time = sum(horizon_period);
    chans = repmat({0}, 1, total_time);
    
    % Calling Performance constructor
    this_perf@Performance('stability', chans, chans, horizon_period);
    this_perf = matchHorizonPeriod(this_perf);
end

function disp(this_perf)
%% DISP function for PerformanceStable object
%
%  disp(perf_l2_obj) (e.g., disp(PerformanceStable('p')) )
%
%  Variables:
%  ---------
%     Input:
%       this_perf : PerformanceStable object     
%
%  See also Ulft.disp, SequencePerformance.disp, Performance.disp

    disp@Performance(this_perf, 'stability')
end

function this_perf = matchHorizonPeriod(this_perf, new_horizon_period)
%% MATCHHORIZONPERIOD function to ensure properties of PerformanceStable
%  object match its own horizon_period, or a new_horizon_period
%
%  this_perf = matchHorizonPeriod(this_perf, new_horizon_period) will change the horizon_period of this_perf
%  this_perf = matchHorizonPeriod(this_perf) leaves this_perf unchanged
%
%  Variables:
%  ---------
%     Input:
%       this_perf : PerformanceStable object
%       new_horizon_period : 1 x 2 array of naturals :: [horizon, period] (in timesteps) of new sequence
%     Output:
%        this_perf : PerformanceStable object
%
%  See also PerformanceStable.

if nargin == 1
% Ensuring that this_perf.horizon_period matches with other properties 
% of this_perf

    % Assumes properties are a mix of sequences of length 1 or
    % horizon_period
    total_time = sum(this_perf.horizon_period);
    if length(this_perf.chan_out) ~= total_time
        assert(length(this_perf.chan_out) == 1,...
               'PerformanceStable:matchHorizonPeriod',...
               'output channels of %s is not compatible w/ horizon_period',...
               this_perf.name);
        this_perf.chan_out = repmat(this_perf.chan_out, 1, total_time);
    end
    if length(this_perf.chan_in) ~= total_time
        assert(length(this_perf.chan_in) == 1,...
               'PerformanceStable:matchHorizonPeriod',...
               'input channels of %s is not compatible w/ horizon_period',...
               this_perf.name);
        this_perf.chan_in = repmat(this_perf.chan_in, 1, total_time);
    end
else
% Changing this_perf.horizon_period and other properties of this_perf to
% a new horizon_period

    [indices, new_horizon_period] = ...
        makeNewIndices(this_perf.horizon_period, new_horizon_period);

    % Set properties according to indices
    this_perf.chan_out        = this_perf.chan_out(indices);
    this_perf.chan_in         = this_perf.chan_in(indices);
    this_perf.horizon_period  = new_horizon_period;
    
    this_perf = matchHorizonPeriod(this_perf);
end
end

function multiplier = performanceToMultiplier(performance, varargin)            %#ok<INUSD,VANUS,STOUT>
%% PERFORMANCETOMULTIPLIER function to generate a multiplier from this object. 
%
%  multiplier = performanceToMultiplier(this_perf)
%
%  Variables:
%  ---------
%     Input:
%       this_perf : PerformanceStable object
%     Output:
%       multiplier : MultiplierStable object
%
%  See also PerformanceStable

error('PerformanceStable:performanceToMultiplier',...
      ['There is no multiplier associated with PerformanceStable. ',...
       'This method should never be called'])
end

function mod_lft_handle = modifyLft(this_perf)                                  %#ok<MANU>
    %% MODIFYLFT method for creating a modified LFT for IQC analysis.
    %  this method should be extended for any subclass of Performance whereby IQC
    %  analysis is conducted on an analyzable, but different LFT (see, for
    %  example, PerformanceStable). The output argument is a function handles 
    %  for modifying the LFT given the current LFT. This handle is used in the
    %  sub-function iqcAnalysis/modifyLft.
    %
    %    mod_lft_handle = modifyLft(this_perf)
    %
    %    Variables:
    %    ---------
    %      Input:
    %         this_perf : PerformanceStable object
    %      Output:
    %         modifyLft : function_handle :: function to transform original LFT
    %
    %    See also iqcAnalysis.modifyLft, PerformanceStable.modifyLft
    
    function lft_new = modifyLftByPerformanceStability(lft_in)
        total_time = sum(lft_in.horizon_period);
        [b, c, d] = deal(cell(1, total_time));
        for i = 1:total_time
            b{i} = zeros(size(lft_in.a{i}, 1), 0);
            c{i} = zeros(0, size(lft_in.a{i}, 2));
            d{i} = [];
        end
        lft_new = Ulft(lft_in.a, b, c, d, lft_in.delta,...
                       'horizon_period', lft_in.horizon_period,...
                       'disturbance', SequenceDisturbance(),...
                       'performance', SequencePerformance());
    end
    mod_lft_handle = @modifyLftByPerformanceStability;
end
end
end

%%  CHANGELOG
% Feb. 16, 2021: Added after v0.6.0 - Micah Fry (micah.fry@ll.mit.edu)
