classdef HybridArc
% Solution to a hybrid dynamical system, with additional information.
%
% See also: HybridSystem, HybridPlotBuilder, hybrid.TerminationCause.
%
% Written by Paul K. Wintz, Hybrid Systems Laboratory, UC Santa Cruz.
% © 2021.

    properties(SetAccess = immutable)
        % A column vector containing the continuous time value for each entry in the solution.
        t % double (:, 1)

        % A column vector containing the discrete time value for each entry in the solution.
        j % double (:, 1)

        % An array containing the state vector for each entry in the solution.
        % Each row i of x contains the transposed state vector at the ith
        % timestep.
        x % double (:, :)

        % The duration of each interval of flow.
        flow_lengths % double (:, 1)

        % The continuous time of each jump (column vector).
        jump_times % double (:, 1)

        % The duration (in ordinary time) of the shortest interval of flow.
        shortest_flow_length % double

        % The cumulative duration of all intervals of flow.
        total_flow_length % double

        % The number of jumps in the solution.
        jump_count % integer
    end

    properties(SetAccess = immutable, Hidden)
        % Column vector containing a 1 at each entry where a jump starts and 0 otherwise.
        is_jump_start
    end

    methods
        function this = HybridArc(t, j, x)
            % Construct a HybridArc object.
            %
            % Input arguments:
            % 1) t: a column vector containing the continuous time at each time step.
            % 2) j: a column vector containing the discrete time at each time step.
            % 3) x: an array where each row contains the transpose of the state
            % vector at that time step.

            checkVectorSizes(t, j, x);
            assert(isnumeric(t))
            assert(isnumeric(j))
            assert(isnumeric(x))
            this.t = t;
            this.j = j;
            this.x = x;
            if isempty(t)
                this.jump_times = [];
                this.is_jump_start = [];
                this.total_flow_length = 0;
                this.jump_count = 0;
                this.flow_lengths = [];
                this.shortest_flow_length = 0;
            else
                [this.jump_times, ~, ~, this.is_jump_start] = hybrid.internal.jumpTimes(t, j);
                this.total_flow_length = t(end) - t(1);
                this.jump_count = length(this.jump_times);
                this.flow_lengths = hybrid.internal.flowLengths(t, j);
                this.shortest_flow_length = min(this.flow_lengths);
            end
        end

        function transformed_arc = transform(this, f)
            % Transform the values of x by the function f(x).
            x_transformed = this.evaluateFunction(f);
            transformed_arc = HybridArc(this.t, this.j, x_transformed);
        end

        function sliced_arc = slice(this, ndxs)
            % Create a new HybridArc with only the selected component indicies.
            x_sliced = this.x(:, ndxs);
            sliced_arc = HybridArc(this.t, this.j, x_sliced);
        end

        function restricted_sol = restrictT(this, tspan)
            assert(isnumeric(tspan), 'tspan must be numeric')
            assert(all(size(tspan) == [1 2]), 'tspan must be a 1x2 array.')
            ndxs_in_span = this.t >= tspan(1) & this.t <= tspan(2);

            restricted_sol = HybridArc(this.t(ndxs_in_span), ...
                                            this.j(ndxs_in_span), ...
                                            this.x(ndxs_in_span, :));
        end

        function restricted_sol = restrictJ(this, jspan)
            assert(isnumeric(jspan), 'jspan must be numeric')
            if isscalar(jspan)
                jspan = [jspan jspan];
            end
            assert(all(size(jspan) == [1 2]), 'jspan must be a 1x2 array.')
            ndxs_in_span = this.j >= jspan(1) & this.j <= jspan(2);

            restricted_sol = HybridArc(this.t(ndxs_in_span), ...
                                        this.j(ndxs_in_span), ...
                                        this.x(ndxs_in_span, :));
        end

        function len = length(this)
            % Get the number of time-steps in this HybridSolution.
            if isscalar(this)
                len = numel(this.t);
            else
                builtin('length', this);
            end
        end

        function plot(this, varargin)
            % Deprecated: Do not use.
            HybridPlotBuilder.plot(this)
        end

        function plotFlows(this, varargin)
            % Shortcut for HybridPlotBuilder.plotFlows function with automatic formatting based on the number of state components.
            %
            % See also: HybridPlotBuilder.plotFlows.
            this.plotByFnc('plotFlows', varargin{:})
        end

        function plotJumps(this, varargin)
            % Shortcut for HybridPlotBuilder.plotJumps function with automatic formatting based on the number of state components.
            %
            % See also: HybridPlotBuilder.plotJumps.
            this.plotByFnc('plotJumps', varargin{:})
        end

        function plotHybrid(this, varargin)
            % Shortcut for HybridPlotBuilder.plotHybrid function with automatic formatting based on the number of state components.
            %
            % See also: HybridPlotBuilder.plotHybrid.
            this.plotByFnc('plotHybrid', varargin{:})
        end

        function plotPhase(this, varargin)
            % Shortcut for HybridPlotBuilder.plotPhase function.
            %
            % See also: HybridPlotBuilder.plotPhase.
            this.plotByFnc('plotPhase', varargin{:})
        end

        // function splitTimes(this) //takes this.t and splits into sections based on this.jump_times
        //   this.times_per_jump = [];
        //   start_row = 1;
        //   for jump_idx = 1:length(this.jump_times) //jump index
        //     column = 1;
        //     for time_idx = start_row:length(this.t) //time index
        //       if this.t(time_idx,1) < this.jump_times(jump_idx,1) // if time less than jump point
        //         this.times_per_jump(jump_idx, column) = this.t(time_idx, 1); //add time to section of data before that jump
        //         column = column + 1;
        //         start_row = start_row + 1
        //       else
        //         break
        //   //add times after last jump
        //   last_col = 1;
        //   last_row = length(this.jump_times) + 1;
        //   while start_row <= length(this.t)
        //     this.times_per_jump(last_row, last_col) = this.t(start_row, 1);
        //     start_row = start_row + 1;
        //     last_col = last_col + 1;
        // end
        //
        // function decimate(this)
        //   this.decimated_times = [];
        //   this.decimated_x = [];
        //   for row = 1:size(this.times_per_jump, 1)
        //     r = 10 //TODO: find better reduction factor, possibly fomula
        //     x = this.times_per_jump(row, :);
        //     decimated_times(row, :) = decimate(x, r);
        //
        //   col = 1;
        //   for row = 1:size(this.decimated_times, 1)
        //     for col = 1:size(this.decimated_times, 2)
        //       this.decimated_x(row, )
        //
        // end
        //
        // function interpolate(this)
        //   this.splitTimes();
        //   this.decimate();
        //   for row = 1:size(this.decimated_times, 1)
        //     xq = this.decimated_times;
        //     V = interp1(, this.x)
        // end

        function interpolate(this)
          interpolated_x = []
          for jump = 0: size(this.jump_times)
            t_at_jump = t(:, j == jump)
            x_at_jump = x(:, j == jump)
            t_grid_at_jump = t_grid((t_grid >= t_at_jump(1,1)) & (t_grid <= t_at_jump(size(t), 1)))
            interp_x_at_jump = interp1(t_at_jump, x_at_jump, t_grid_at_jump)

            interpolated_x = [interpolated_x, interp_x_at_jump]

          if t_grid >= t_at_jump(size(t), 1)
            interp_rest_of_t = interp1(t_at_jump, x_at_jump, t_grid)  //not sure if this is how to do rest of t grid or not


          end
        end


    end

    methods(Access = private)
        function plotByFnc(this, plt_fnc, varargin)
            % Shortcut for HybridPlotBuilder.plot function.
            [~, x_ndxs] = hybrid.internal.convert_varargin_to_solution_obj([{this}, varargin(:)']);
            MAX_COMPONENTS_FOR_SUBPLOTS = 4;
            if length(x_ndxs) <= MAX_COMPONENTS_FOR_SUBPLOTS
                HybridPlotBuilder()...
                    .subplots('on')...
                    .(plt_fnc)(this, varargin{:});
            else
                legend_labels = num2cell(x_ndxs);
                legend_labels = cellfun(@(n) {sprintf('$x_{%d}$', n)},legend_labels);
                HybridPlotBuilder()...
                    .subplots('off')...
                    .color('matlab')...
                    .legend(legend_labels)...
                    .(plt_fnc)(this, varargin{:});
            end
        end
    end

    methods(Hidden)
        function plotflows(varargin)
            warning('Please use the plotFlows function instead of plotflows.')
            this.plotFlows(varargin{:});
        end

        function plotjumps(varargin)
            warning('Please use the plotJumps function instead of plotjumps.')
            this.plotJumps(varargin{:});
        end

        function plotHybridArc(varargin)
            warning('Please use the plotHybrid function instead of plotHybridArc.')
            this.plotHybrid(varargin{:});
        end
    end

    methods

        function out = evaluateFunction(this, func_hand, time_indices)
            % Evaluate a function at each point along the solution.
            % The function handle 'func_hand' is evaluated with the
            % arguments of the state 'x', continuous time 't' (optional),
            % and discrete time 'j' (optional). This function returns an
            % array with length equal to the length of 't' (or
            % 'time_indices', if provided). Each row of the output array
            % contains the vector returned by 'func_hand' at the
            % corresponding entry in this HybridSolution.
            %
            % The argument 'func_hand' must be a function handle
            % that has the input arguments "x", "x, t", or "x, t, j", and
            % returns a column vector of fixed length.
            % The argument "time_indices" is optional. If supplied, the
            % function is evaluated only at the indices specificed and the
            % "out" vector matches the legnth of "time_indices."
            assert(isa(func_hand, 'function_handle'), ...
                'The ''func_hand'' argument must be a function_handle. Instead it was %s.', class(func_hand))

            if ~exist('indices', 'var')
                time_indices = 1:length(this.t);
            end

            if isempty(time_indices)
                out = [];
                return
            end

            assert(length(time_indices) <= length(this.t), ...
                'The length of time_indices (%d) is greater than the length of this solution (%d).', ...
                length(time_indices), length(this.t))

            ndx0 = time_indices(1);
            val0 = evaluate_function(func_hand, this.x(ndx0, :)', this.t(ndx0), this.j(ndx0))';
            assert(isvector(val0), 'Function handle does not return a vector')

            out = NaN(length(time_indices), length(val0));

            for k=time_indices
                out(k, :) = evaluate_function(func_hand, this.x(k, :)', this.t(k), this.j(k))';
            end
        end
    end
end

%%%% Local functions %%%%

function val_end = evaluate_function(fh, x, t, j)
switch nargin(fh)
    case 1
        val_end = fh(x);
    case 2
        val_end = fh(x, t);
    case 3
        val_end = fh(x, t, j);
    otherwise
        error('Function handle must have 1, 2, or 3 arguments. Instead %s had %d.',...
            func2str(fh), nargin(fh))
end
end

function checkVectorSizes(t, j, x)
    if size(j, 2) ~= 1
        e = MException('HybridSolution:WrongShape', ...
            'The vector j must be a column vector. Instead its shape was %s.', ...
            mat2str(size(j)));
        throwAsCaller(e);
    end
    if size(t, 1) ~= size(j, 1)
        e = MException('HybridSolution:WrongShape', ...
            'The length(t)=%d and length(j)=%d must match.', ...
            size(t, 1), size(j, 1));
        throwAsCaller(e);
    end
    if size(t, 1) ~= size(x, 1)
        e = MException('HybridSolution:WrongShape', ...
            'The length(t)=%d and length(x)=%d must match.', ...
            size(t, 1), size(x, 1));
        throwAsCaller(e);
    end
end
