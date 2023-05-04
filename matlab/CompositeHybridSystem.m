classdef CompositeHybridSystem < HybridSystem
% This class models a hybrid system with one or more subsystem.
% 
% The subsystems are provided as instances of
% HybridSubsystem with inputs generated by feedback functions
% stored in kappa_C and kappa_D. The kappa_C feedbacks are used during
% flows and the kappa_D feedbacks are used at jumps.
%
% Let N be the number of subsystems.
% The state for the composite system consists of 
%     [x1; x2; ...; xN; j1; j2; ...; jN] 
% where x1 is the state vector for the first subsystem, x2 is the state
% vector for the second subsystem, etc., and j1 is the discrete time for
% the first subsystem, j2 is the discrete time for the second subsystem,
% and so on. (The subsystems can jump separately of each other, so each has
% its own discrete time).
% 
% See also: HybridSystem, HybridSubsystem, CompositeHybridSolution, 
% <a href="matlab:hybrid.internal.openHelp('CompositeHybridSystem_demo')">Demo: Create and Simulate Multiple Interlinked Hybrid Systems</a>.
% 
% Added in HyEQ Toolbox version 3.0.

% Written by Paul K. Wintz, Hybrid Systems Laboratory, UC Santa Cruz (©2022). 
    properties(SetAccess = immutable)
        subsystems % hybrid.internal.SubsystemList; 

        % Number of subsystems
        subsys_count;
    end
    
    properties(GetAccess = private, SetAccess = immutable, Hidden) 
        % The following properties are private because they might change in
        % future implementations. 
        
        % Indicies within the composite state of each subsystem's state 
        x_indices % cell (:, :) 
        % Index within the composite state of subsystem1's discrete time.
        j_index % integer array (:, 1) 
    end
    
    properties(Access = private)
        % Feedback function for each subsystem during flows. 
        % Each entry must be set to a function handle with a signiture
        % matching one of the following signitures:
        %    u = kappa_C(x1, x2, ..., xN)
        %    u = kappa_C(x1, x2, ..., xN, t)
        %    u = kappa_C(x1, x2, ..., xN, t, j)
        % where N is the number of subsystems.
        kappa_C
        
        % Feedback functions for each subsystem at jumps.
        % Each entry must be set to a function handle with a signiture
        % matching one of the following signitures:
        %    u = kappa_D(x1, x2, ..., xN)
        %    u = kappa_D(x1, x2, ..., xN, t)
        %    u = kappa_D(x1, x2, ..., xN, t, j)
        % where N is the number of subsystems.
        kappa_D
       
        flow_outputs
        jump_outputs
        
        sorted_names_flows
        sorted_names_jumps
    end
    
    methods
        function obj = CompositeHybridSystem(varargin) 
           % Constructor
           obj = obj@HybridSystem();
           subsystems = hybrid.internal.SubsystemList(varargin{:});
           obj.subsystems = subsystems;
           subsys_count = length(subsystems);
           obj.subsys_count = subsys_count;
           ndx = 1; % Start index for ith subsystem state variable.
           for i = 1:subsys_count
               ss = subsystems.get(i) ;
               ss_n = ss.state_dimension;
               obj.x_indices{i} = uint32(ndx : (ndx + ss_n - 1));
               
               % We use a listener to update the list of outputs each time the
               % output of a subsystem changes. (Requires "SetObservable"
               % attribute to be added to 'output' property in HybridSubsystem.) 
               % addlistener(ss, 'output', 'PostSet', @obj.updateOutputsList);
               
               assert(~isempty(ss_n), 'State dimension for subsystem %d has not been set', i);
               ndx = ndx + ss_n;
           end
           for i = 1:subsys_count
              obj.j_index(i) = ndx;
              ndx = ndx + 1;
           end
           obj.state_dimension = ndx-1;
           
           obj.kappa_C = generate_default_feedbacks(subsystems);
           obj.kappa_D = generate_default_feedbacks(subsystems);
           
%            obj.updateOutputsList()

            for i = 1:obj.subsys_count
               obj.flow_outputs{i} = obj.subsystems.get(i).flows_output_fnc;
               obj.jump_outputs{i} = obj.subsystems.get(i).jumps_output_fnc;
            end
            obj.updateEvaluationOrder();
        end
        
        function setFlowInput(this, subsys_id, kappa_C)
            % Set the input function during flows for the given subsystem.
            % 'subsys_id' can be the index of the subsystem, the subsystem
            % object itself, or subsystem names (if names were passed to the
            % constructor).
            % 
            % See also: setInput, setJumpInput, getFlowInput.
            ndx = this.subsystems.getIndex(subsys_id);
            this.check_feedback(kappa_C)
            warn_if_input_dim_zero(this, ndx, 'setFlowInput')
            this.kappa_C{ndx} = kappa_C;
        end
        
        function kappa_C = getFlowInput(this, subsys_id)
            % Get the input function during flows for the given subsystem.
            % 'subsys_id' can be the index of the subsystem, the subsystem
            % object itself, or subsystem names (if names were passed to the
            % constructor).
            %
            % See also: setFlowInput.
            ndx = this.subsystems.getIndex(subsys_id);
            kappa_C = this.kappa_C{ndx};
        end
    
        function setJumpInput(this, subsys_id, kappa_D)
            % Set the input function at jumps for the given subsystem.
            % 'subsys_id' can be the index of the subsystem, the subsystem
            % object itself, or subsystem names (if names were passed to the
            % constructor).
            %
            % See also: setInput, setFlowInput, getJumpInput.
            ndx = this.subsystems.getIndex(subsys_id);
            warn_if_input_dim_zero(this, ndx, 'setJumpInput')
            this.check_feedback(kappa_D)
            this.kappa_D{ndx} = kappa_D;
        end
        
        function kappa_D = getJumpInput(this, subsys_id)
            % Get the input function at jumps for the given subsystem.
            % 'subsys_id' can be the index of the subsystem, the subsystem
            % object itself, or subsystem names (if names were passed to the
            % constructor).
            %
            % See also: setJumpInput.
            ndx = this.subsystems.getIndex(subsys_id);
            kappa_D = this.kappa_D{ndx};
        end
    
        function setInput(this, subsys_id, kappa)
            % Set the input function during jumps and flows for the given subsystem.
            % 'subsys_id' can be the index of the subsystem, the subsystem
            % object itself, or subsystem names (if names were passed to the
            % constructor).
            %
            % See also: setFlowInput, setJumpInput.
            ndx = this.subsystems.getIndex(subsys_id);
            warn_if_input_dim_zero(this, ndx, 'setInput')
            this.check_feedback(kappa)
            this.kappa_C{ndx} = kappa;
            this.kappa_D{ndx} = kappa;
        end
        
        function disp(this)
            % Print information about the composite system and its subsystems to the terminal.
            
            % We use the following pipe characters to draw the subsystem tree. 
            % (The unicode characters are not rendered correctly on some
            % older versions of MATLAB. Open in R2021a or later to view the
            % following table). 
            % Unicode value | Unicode character
            %          9500 |         ├
            %          9474 |         |
            %          9492 |         └
            disp(strcat(class(this), ':'))
            subsys_prefix = char(9500); % i.e. '├'
            prop_prefix = char(9474); % i.e. '|'
            for i = 1:this.subsys_count
                if i == this.subsys_count
                    subsys_prefix = char(9492); % i.e. '└'
                    prop_prefix = ' ';
                end
                ss = this.subsystems.get(i);
                if this.subsystems.has_names
                    name = this.subsystems.getName(i);
                    fprintf('%s Subsystem %d: ''%s'' (%s)\n', subsys_prefix, i, name, class(ss))
                else
                    fprintf('%s Subsystem %d: (%s)\n', subsys_prefix, i, class(ss))
                end
                if isequal(this.kappa_C{i}, this.kappa_D{i})
                    fprintf('%s \t\t       Input: %s\n', prop_prefix, func2str(this.kappa_D{i}))
                else
                    fprintf('%s \t\t  Flow input: %s\n', prop_prefix, func2str(this.kappa_C{i}))
                    fprintf('%s \t\t  Jump input: %s\n', prop_prefix, func2str(this.kappa_D{i}))
                end

                if isequal(ss.flows_output_fnc, ss.jumps_output_fnc)
                    fprintf('%s \t\t      Output: y%d=%s\n', prop_prefix, i, func2str(ss.flows_output_fnc))
                else
                    fprintf('%s \t\t Flow output: y%d=%s\n', prop_prefix, i, func2str(ss.flows_output_fnc))
                    fprintf('%s \t\t Jump output: y%d=%s\n', prop_prefix, i, func2str(ss.jumps_output_fnc))
                end
                fprintf('%s \t\t Dimensions: ', prop_prefix)
                fprintf('State=%d, Input=%d, Output=%d\n', ...
                    ss.state_dimension, ss.input_dimension, ss.output_dimension)
            end
        end
    end
    
    methods(Sealed)
        
        function xdot = flowMap(this, x, t) 
            % Flow map for the composite system. 
            
            [xs, js] = this.split(x);
            % We set xdot to zeros and then fill in the entries
            % corresponding to the state of each subsystem and leave zero
            % the entries corresponding to the j-values.  
            xdot = zeros(this.state_dimension, 1); 
            us = hybrid.internal.evaluateInOrder(this.sorted_names_flows, ...
                                        this.kappa_C, this.flow_outputs, xs, t, js);
            for i=1:length(this.subsystems)
               ss = this.subsystems.get(i);
               u = us{i};
               j = js(i);
               assert_control_length(length(u), ss.input_dimension, i)
               xdot_ss = ss.flowMap(xs{i}, u, t, j);
               assert_state_length(size(xdot_ss, 1), ss.state_dimension, i)
               if ~iscolumn(xdot_ss) && ~isempty(xdot_ss)
                   error('xdot was not a column vector.')
               end
               xdot(this.x_indices{i}) = xdot_ss;
            end
        end 

        function xplus = jumpMap(this, x, t) 
            % Jump map for the composite system.
            [xs, js] = this.split(x);
            xplus = NaN(this.state_dimension, 1);
            us = hybrid.internal.evaluateInOrder(this.sorted_names_jumps, ...
                                        this.kappa_D, this.jump_outputs, xs, t, js);
            for i=1:length(this.subsystems)
               ss = this.subsystems.get(i);
               u = us{i};
               j = js(i);
               assert_control_length(length(u), ss.input_dimension, i)
               D = ss.jumpSetIndicator(xs{i}, u, t, js(i));
               if ~isscalar(D)
                   error('CompositeHybridSystem:InvalidFunction', ...
                       'The jump set indicator function for system %d returned an array.', i)
               end
               if D
                   xplus_i = ss.jumpMap(xs{i}, u, t, j);
                   jplus_i = j + 1;
               else
                   xplus_i = xs{i};
                   jplus_i = j;
               end
               assert_state_length(length(xplus_i), ss.state_dimension, i)
               xplus(this.x_indices{i}) = xplus_i;
               xplus(this.j_index(i)) = jplus_i;
            end
        end

        function C = flowSetIndicator(this, x, t) 
            % Flow set indicator for the composite system.
            
            % The system can only flow if both subsystems are in their
            % repsective flow sets (priority is honored, if the composite
            % state is in (C union D)).
            C = true; 
            [xs, js] = this.split(x);
            us = hybrid.internal.evaluateInOrder(this.sorted_names_flows, ...
                                        this.kappa_C, this.flow_outputs, xs, t, js);
            for i=1:length(this.subsystems)
               ss = this.subsystems.get(i);
               u = us{i};
               j = js(i);
               assert_control_length(length(u), ss.input_dimension, i)
               C = ss.flowSetIndicator(xs{i}, u, t, j);
               if ~isscalar(C)
                   error('CompositeHybridSystem:InvalidFunction', ...
                       'The flow set indicator function for system %d returned a nonscalar value.', i)
               end
               if ~C
                   % If any of the subsystems are not in their flow set,
                   % then the composite system does not flow.
                   break;
               end
            end
        end

        function D = jumpSetIndicator(this, x, t)
            % Jump set indicator for the composite system.
            D = false; 
            [xs, js] = this.split(x);
            us = hybrid.internal.evaluateInOrder(this.sorted_names_jumps, ...
                                        this.kappa_D, this.jump_outputs, xs, t, js);
            for i=1:length(this.subsystems)
               ss = this.subsystems.get(i);
               u = us{i};
               j = js(i);
               assert_control_length(length(u), ss.input_dimension, i)
               D = ss.jumpSetIndicator(xs{i}, u, t, j);
               if ~isscalar(D)
                   error('CompositeHybridSystem:InvalidFunction', ...
                       'The jump set indicator function for system %d returned a nonscalar value.', i)
               end
               if D
                   % If any of the subsystems are in their jump set,
                   % then the composite system jumps.
                   break;
               end
            end
        end
    end

    methods
        
        function sol = solve(this, x0_cells, tspan, jspan, varargin)
            % Compute the solution to the composite system with the
            % initial states of each subsystem given in a cell array {x0_1,
            % x0_2, ..., x0_N}. See documentation of HybridSystem.solve for 
            % explanation of tspan, jspan, and config.
            %
            % See also: HybridSystem.solve.
            
            % We concatenate the subsystem states and inital j-value to create 
            % the composite state. (The subsystems can jump at separate times, 
            % so track the jumps for each in the last components of the 
            % composite state).
            if ~iscell(x0_cells)
                e = MException('CompositeHybridSystem:InitialStateNotCell', ...
                    'Initial states xs_0 was a %s instead of a cell array.', ...
                    class(x0_cells));
                throwAsCaller(e);
            end
            
            if length(x0_cells) ~= this.subsys_count
                e = MException('CompositeHybridSystem:WrongNumberOfInitialStates', ...
                    'Wrong number of initial states. Expected=%d, actual=%d', ...
                    this.subsys_count, length(x0_cells));
                throwAsCaller(e);
            end

            % Check the initial condition for each subsystem.
            for i=1:this.subsys_count
                % Check dimension
                ss_dim = this.subsystems.get(i).state_dimension;
                if any((size(x0_cells{i}) ~= [ss_dim, 1])) && ~(ss_dim == 0 && size(x0_cells{i}, 1) == 0)
                    e = MException('CompositeHybridSystem:WrongNumberOfInitialStates', '%s',...
                        sprintf('Mismatched initial state size. System %d has state dimension %d ', i, ss_dim), ...
                        sprintf('but the initial value had shape %s.', mat2str(size(x0_cells{i}))));
                    throwAsCaller(e);
                end

                % Check not infinity
                if any(isinf(x0_cells{i}))
                    e = MException('CompositeHybridSystem:WrongNumberOfInitialStates', ...
                        'Initial state for system %d has a infinite value: %s.', i, mat2str(x0_cells{i}));
                    throwAsCaller(e);
                end 

                % Check not NaN
                if any(isnan(x0_cells{i}))
                    e = MException('CompositeHybridSystem:WrongNumberOfInitialStates', ...
                        'Initial state for system %d has a NaN value: %s.', i, mat2str(x0_cells{i}));
                    throwAsCaller(e);
                end 
            end
            x0_cells = cat(1, x0_cells{:});
            js_0 = jspan(1)*ones(length(this.subsystems), 1);
            
            x0 = [x0_cells; js_0];
                   
            % Update the evaluation order in case any inputs have been changed
            % since this was constructed or the last time 'solve' was called.
            this.updateEvaluationOrder();
            sol = this.solve@HybridSystem(x0, tspan, jspan, varargin{:});

            if sol.solver_config.hybrid_priority == hybrid.Priority.FLOW
                msg = {'Using CompositeHybridSystems with FLOW priority is not reccomended. '
                    'When two subsystems are in their respective jump sets and one of them leaves '
                    'its flow set, then the state of both will jump, violating flow priority.'};
                warning('CompositeHybridSystem:FlowPriorityNotSupported', '%s', msg{:})
            end
        end
    end
    
    methods(Access = protected, Hidden)
        function sol = wrap_solution(this, t, j, x, tspan, jspan, solver_config)
            import hybrid.internal.*
            % Create the HybridSolution object for the composite system.
            sol = this.wrap_solution@HybridSystem(t, j, x, tspan, jspan, solver_config);
            
            total_jump_count = j(end) - j(1);
            
            [xs_all, js_all] = this.split_many(x);
            us_jump = {};
            us_flow = {};
            flow_ys = {};
            jump_ys = {};
            % Compute the input values
            for k = 1:length(t)
                js = [];
                xs = {};
                for i = 1:this.subsys_count
                    xs{end+1} = xs_all(k, this.x_indices{i})'; %#ok<AGROW>
                    js(end+1) = js_all(k, i); %#ok<AGROW>
                end
                [us_jump{k}, jump_ys{k}] = evaluateInOrder(this.sorted_names_jumps, ...
                    this.kappa_D, this.jump_outputs, xs, t(k), js); %#ok<AGROW>
                [us_flow{k}, flow_ys{k}] = evaluateInOrder(this.sorted_names_flows, ...
                    this.kappa_C, this.flow_outputs, xs, t(k), js); %#ok<AGROW>
            end
            for i = 1:this.subsys_count
                ss = this.subsystems.get(i);
                ss_j = js_all(:, i);
                ss_x = xs_all(:, this.x_indices{i});
                ss_u = NaN(length(t), ss.input_dimension);
                ss_y = NaN(length(t), ss.output_dimension);
                
                % Create arrays is_a_ss1_jump_index and is_a_ss2_jump_index,
                % which contain ones at entry where a jump occured in the
                % corresponding system.
                [~, ~, ~, is_jump] = hybrid.internal.jumpTimes(t, ss_j);
                
                for k = 1:length(t)
                    if is_jump(k)
                        us_k_jump = us_jump{k};
                        ss_u(k, :) = us_k_jump{i}';
                        ys_all_at_k = jump_ys{k};
                    else % is flow
                        us_k_flow = us_flow{k};
                        ss_u(k, :) = us_k_flow{i}';
                        ys_all_at_k = flow_ys{k};
                    end
                    ss_y(k, :) = ys_all_at_k{i};
                end
                
                % In order to find the hybrid.TerminationCause for the subsystem
                % solutions, we need to adjust jspan for each so that we only count
                % jumps in the appropriate subystem. To this end, we calculate the
                % number of jumps in each subsystem. The results
                % are subtracted from the end of jspan to create jspan1 and
                % jspan2.
                ss_jump_count = ss_j(end) - ss_j(1);
                others_jump_count = total_jump_count - ss_jump_count;
                ss_jspan = [jspan(1), jspan(end) - others_jump_count];
                ss_sols{i} = ss.wrap_solution(t, ss_j, ss_x, ss_u, ss_y, tspan, ss_jspan); %#ok<AGROW>
            end
            sol = CompositeHybridSolution(sol, ss_sols, tspan, jspan, this.subsystems);
        end
    end

    methods(Access = private)
        
        function updateEvaluationOrder(this)
            import hybrid.internal.*
            this.sorted_names_flows = sortInputAndOutputFunctionNames(this.kappa_C, this.flow_outputs);
            this.sorted_names_jumps = sortInputAndOutputFunctionNames(this.kappa_D, this.jump_outputs);
        end
        
        function [xs, js] = split(this, x)
            % Split a full state vector into a cell array containing
            % the subsystem state vectors, and a numeric array containing
            % the subsystem discrete time-values. 
            
            % We found that this function had the largest impact on the
            % runtime of computing solutions, so we have taken pains to
            % optimize it. 
            
            % Save the "indexs" to local variables to speed up reading them.
            x_ndxs = this.x_indices;
            j_ndxs = this.j_index;
            N = length(x_ndxs);
            
            % Preallocating xs and js cut down the total time to execute
            % split() by 30%, in one test.
            xs = cell(N, 1);
            js = NaN(N, 1);
            for i = 1:N
                xs{i} = x(x_ndxs{i});
                js(i) = x(j_ndxs(i));
            end
        end
        
        function [xs, js] = split_many(this, x)
            % SPLIT_MANY
            ndxs = cell2mat(this.x_indices);
            x_cols = max(ndxs) - min(ndxs) + 1;
            j_cols = length(this.x_indices);
            rows = size(x, 1);
            xs = NaN(rows, x_cols);
            js = NaN(rows, j_cols);
            for i = 1:this.subsys_count
                xs(:, this.x_indices{i}) = x(:, this.x_indices{i});
                js(:, i) = x(:, this.j_index(i));
            end
        end
        
        function check_feedback(this, kappa)
            nargs = nargin(kappa);
            is_wrong_nargs = nargs > this.subsys_count + 2;
            if is_wrong_nargs
               e = MException('CompositeHybridSystem:WrongNumberInputArgs', ...
                   'Wrong number of input arguments. Expected=%d, %d, or %d, actual=%d.',...
                   this.subsys_count, this.subsys_count + 1, this.subsys_count + 2, nargs);
               throwAsCaller(e);
            end
        end
    end
end
        
% function check_output(h)
% nargs = nargin(h);
% is_wrong_nargs = nargs > 3 || nargs < 1;
% if is_wrong_nargs
%     e = MException('CompositeHybridSystem:OutputWrongNumberArgsIn', ...
%         'Given output function has wrong number of arguments. Expected=1, 2, or 3, actual=%d.',...
%         nargs);
%     throwAsCaller(e);
% end
% end

function kappas = generate_default_feedbacks(subsystems)
sys_count = length(subsystems);
kappas = cell(sys_count, 1);
if sys_count == 0
    args_fmt = '';
else
    args_fmt = [repmat('~,', 1, sys_count), '~'];
end
feedback_arguments_string = sprintf(args_fmt, 1:sys_count);
for i = 1:sys_count
    ss = subsystems.get(i);
    n = ss.input_dimension;
    kappa_eval_string = sprintf(['kappas{i} = @(',feedback_arguments_string,') zeros(%d, 1);'], n);
    eval(kappa_eval_string);
end

end

function assert_control_length(u_length, subsys_input_dimension, sys_ndx)
if ~(u_length == subsys_input_dimension)
    err_id = 'CompositeHybridSystem:DoesNotMatchInputDimension';
    msg = sprintf('Input vector ''u'' does not match input dimension for system %d. Expected=%d, actual=%d.', ...
        sys_ndx, subsys_input_dimension, u_length);
    throwAsCaller(MException(err_id,msg))
end
end

function assert_state_length(x_length, subsys_state_dimension, sys_ndx)
if ~(x_length == subsys_state_dimension)
    err_id = 'CompositeHybridSystem:DoesNotMatchStateDimension';
    msg = sprintf('State vector ''x'' does not match state dimension for system %d. Expected=%d, actual=%d.', ...
        sys_ndx, subsys_state_dimension, x_length);
    throwAsCaller(MException(err_id,msg))    
end
end

function warn_if_input_dim_zero(this, ndx, function_name)
if this.subsystems.get(ndx).input_dimension == 0
    warning('CompositeHybridSystem:SystemHasNoInputs', ...
        '%s was called for subsystem %d, but this system does not have input.', ...
        function_name, ndx)
end
end