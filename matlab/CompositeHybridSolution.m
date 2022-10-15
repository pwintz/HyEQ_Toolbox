classdef CompositeHybridSolution < HybridSolution
% A solution to a composite hybrid system.
%
% See also: HybridArc, HybridSolution, CompositeHybridSystem, HybridSubsystemSolution.
% 
% Added in HyEQ Toolbox version 3.0.

% Written by Paul K. Wintz, Hybrid Systems Laboratory, UC Santa Cruz (©2022). 
    properties(SetAccess = immutable)
        % Number of subsystem solutions.
        subsys_count 
    end

    properties(SetAccess = immutable, Hidden)
        subsystem_solutions 
    end
    
    properties(GetAccess=private, SetAccess=immutable)
        subsystems % hybrid.internal.SubsystemList
    end
    
    methods
        function this = CompositeHybridSolution(composite_solution, ...
                subsystem_solutions, tspan, jspan, subsystems)
            % Constructor for CompositeHybridSolution.
            cs = composite_solution;
            this = this@HybridSolution(cs.t, cs.j, cs.x, cs.C_end, cs.D_end, tspan, jspan, cs.solver_config);
            this.subsystem_solutions = subsystem_solutions;
            this.subsys_count = length(subsystem_solutions);
            this.subsystems = subsystems;
        end



        function restricted_sol = restrictT(this, tspan)
            % Restrict the domain in ordinary time to the interval 'tspan'.
            % 'tspan' must be a 2x1 array of real numbers. 
            % 
            % See also: HybridArc/restrictJ
            assert(isnumeric(tspan), 'tspan must be numeric')
            assert(all(size(tspan) == [1 2]), 'tspan must be a 1x2 array.')
            ndxs_in_span = this.t >= tspan(1) & this.t <= tspan(2);

            restricted_sol = HybridArc(this.t(ndxs_in_span), ...
                                            this.j(ndxs_in_span), ...
                                            this.x(ndxs_in_span, :));
        end

        function restricted_sol = restrictJ(this, jspan)
            % Restrict the domain in discrete time to the interval 'jspan'.
            % 'jspan' must be either a 2x1 array of integers or a single integer. 
            % 
            % See also: HybridArc/restrictT
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
    end

    methods(Hidden)
        function out = subsref(this,s)
            % Redefine the behavior of parentheses (such as 'sol(1)') to reference subsystem solutions.
            switch s(1).type
                case '()'
                    if length(s) == 1
                        if isscalar(this)
                            ndx = this.subsystems.getIndex(s.subs{1});
                            out = this.subsystem_solutions{ndx};
                        else
                            % If 'this' is an array, then we use the built-in
                            % referencing. 
                            out = builtin('subsref',this,s);
                        end
                    else
                        % Call subsref recursively using only the first entry
                        % of 's' to get the subsystem solution.
                        subsol = subsref(this, s(1));
                        try
                            % Reference properties on the subsystem solution.
                            out = builtin('subsref', subsol, s(2:end));
                        catch e
                            throw(e);
                        end
                    end
                case '.'
                    % Use default behavior.
                    out = builtin('subsref',this,s);
                    % Add throwAsCaller.
                case '{}'
                    % Brace indexing is not supported.
                    % (This does not prevent accessing elements of a cell array
                    % that contains CompositeHybridSolutions.)
                    error('CompositeHybridSolution:subsref',...
                        'Brace indexing is not supported on CompositeHybridSolution objects.')
            end
        end
            
        function n = numArgumentsFromSubscript(obj,s,indexingContext) %#ok<INUSD> 
            % Subscripts always return a single (possibly array) object.
            n = 1;
        end
        
        function ndx = end(this,k,n_ndxs)
           % Define per this Stackoverflow answer: https://stackoverflow.com/a/29378151/6651650
           % k is the index in the expression using the end syntax
           % n_ndxs is the total number of indices in the expression

           if isscalar(this)
               assert(n_ndxs == 1, 'Using multiple indexes (i.e., ''sol(end, 1)'') is not supported on CompositeHybridSolution objects.');
               ndx = length(this.subsystem_solutions);
           else
               % Handle the case where 'this' is an array.
               ndx = builtin('end',this,k,n_ndxs);
           end
        end
    end
end

