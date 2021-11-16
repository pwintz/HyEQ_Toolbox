classdef HybridSolution < HybridArc
% Solution to a hybrid dynamical system, with additional information. 
%
% See also: HybridSystem, HybridPlotBuilder, hybrid.TerminationCause.
%
% Written by Paul K. Wintz, Hybrid Systems Laboratory, UC Santa Cruz. 
% © 2021. 
    
    properties(SetAccess = immutable)        
        % Initial state vector (column vector).
        x0
        
        % Final state vector (column vector).
        xf
        
        % The reason the simulation terminated.
        % The value of termination_cause is set to one of the the enumeration
        % values in hybrid.TerminationCause.
        termination_cause % hybrid.TerminationCause
    end
    
    properties(SetAccess = immutable, Hidden)
        solver_config
    end

    properties(GetAccess = protected, SetAccess = immutable, Hidden)
        system;
        C_end;
        D_end;
    end
    
    methods
        function this = HybridSolution(t, j, x, C, D, tspan, jspan, solver_config)
            % Construct a HybridSolution object. 
            %
            % Input arguments:
            % 1) t: a column vector containing the continuous time at each time step.
            % 2) j: a column vector containing the discrete time at each time step.
            % 3) x: an array where each row contains the transpose of the state
            % vector at that time step.
            % 4) C: flow set indicator. Given as one of the following:
            %   * a column vector containing the value at each time step.
            %   * a scalar containing the value at only the last time step, or
            %   * a function handle.
            % 5) D: jump set indicator. Given as one of the following:
            %   * a column vector containing the value at each time step.
            %   * a scalar containing the value at only the last time step, or
            %   * a function handle.
            % 6) tspan: a 2x1 array containing the continuous time
            % span.
            % 7) jspan: a 2x1 array containing the continuous time
            % span.
            % 8) solver_config: the HybridSolverConfig object used when the
            % solution was generated.
            % 
            % Arguments 4 through 7 are used to determine the termination cause.
            
            narginchk(7, 8);
            if isempty(t)
                e = MException('HybridSolution:EmptySolution', 't was empty.');
                throwAsCaller(e);
            end
            this = this@HybridArc(t, j, x);

            this.x0 = x(1,:)';
            this.xf = x(end,:)';
            
            assert(t(1) == tspan(1), 't(1)=%f does equal the start of tspan=%s', t(1), mat2str(tspan))
            assert(j(1) == jspan(1), 'j(1)=%d does equal the start of jspan=%s', j(1), mat2str(jspan))

            if isa(C, 'function_handle')
                C = evaluate_function(C, x(end,:)', t(end), j(end));
            end
            if isa(D, 'function_handle')
                D = evaluate_function(D, x(end,:)', t(end), j(end));
            end

            this.C_end = C(end);
            this.D_end = D(end);

            this.termination_cause = hybrid.TerminationCause.getCause(...
                this.t, this.j, this.x, C, D, tspan, jspan);

            if exist('solver_config', 'var')
                this.solver_config = solver_config.copy();
            else
                this.solver_config = [];
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
