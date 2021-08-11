classdef HyEQsolverTest < matlab.unittest.TestCase
    
    methods (Test)
     
        function testDefaultPriorityIsJumps(testCase)
            f = @(x) 1e5; % This shouldn't be used.
            g = @(x) 0; 
            C = @(x) 1;
            D = @(x) 1;
            x0 = 1;
            tspan = [0, 100];
            jspan = [1, 100];
            [t, ~, ~] = HyEQsolver(f, g, C, D, x0, tspan, jspan); % "rule" not specified.
            
            testCase.assertEqual(t(end), 0)
        end

        function testContinuousTimeConstantWhenPriorityIsJumps(testCase)
            f = @(x) 1e5; % This shouldn't be used.
            g = @(x) 0; 
            C = @(x) 1;
            D = @(x) 1;
            x0 = 1;
            tspan = [0, 100];
            jspan = [1, 100];
            rule = 1; % jump priority
            [t, ~, x] = HyEQsolver(f, g, C, D, x0, tspan, jspan, rule);
            
            testCase.assertEqual(t(end), 0) % This assertion is OK
            testCase.assertEqual(x(end), g(x(1))) % This assertion is OK
        end

        function testDiscreteTimeConstantWhenPriorityIsFlows(testCase)
            f = @(x) 0;
            g = @(x) 23; % This shouldn't be used.
            C = @(x) 1;
            D = @(x) 1;
            x0 = 1;
            tspan = [0, 100];
            jspan = [1, 100];
            rule = 2; % flow priority
            [~, j, x] = HyEQsolver(f, g, C, D, x0, tspan, jspan, rule);
            
            % A spurious jump appears to occur before the last entry.
            testCase.assertEqual(j(end-1), 1) % This assertion is OK
            testCase.assertEqual(j(end), 1) % This assertion fails

            % Because f(x) = 0, the value of x should be constant, but it 
            % is actually is reset to 0. 
            testCase.assertEqual(x(end-1), x(1)) % This assertion is OK
            testCase.assertEqual(x(end), x(1)) % This assertion is OK
        end

        function testNonAutonomous(testCase)
            f = @(t, j, x) x^2;
            g = @(t, j, x) 0;
            C = @(t, j, x) 1;
            D = @(t, j, x) 1;
            x0 = 1;
            tspan = [0, 100];
            jspan = [1, 100];
            rule = 2; % flow priority
            [~, j, ~] = HyEQsolver(f, g, C, D, x0, tspan, jspan, rule);
            
            testCase.assertEqual(j(end-1), 1) % This assertion is OK
        end

        function testFlowPriorityFromBoundaryOfC(testCase)
            x0 = 1.5;
            tspan = [0, 5];
            jspan = [0, 5];
            rule = 2;
            f = @(x) x;
            g = @(x) 0;
            C = @(x) x <= 1.5;
            D = @(x) 1;
            [t, j, x] = HyEQsolver(f, g, C, D, x0, tspan, jspan, rule);
            
            sol = HybridSolution.fromLegacyData(t, j, x, f, g, C, D, tspan, jspan);
            
            testCase.assertLessThanOrEqual(x, 1.500001)
        end

        function testBouncingBallStaysAboveGround(testCase)
            bounce_coeff = 0.9;
            gravity = 9.8;

            tspan = [0, 100];
            jspan = [0, 1000];
            x0 = [1e-32; 0];
            f = @(x)[x(2); -gravity];
            g = @(x)[x(1); -bounce_coeff*x(2)];
            C = @(x) x(1) >= 0 || x(2) >= 0;
            D = @(x) x(1) <= 0 && x(2) <= 0;
            [t, j, x] = HyEQsolver(f, g, C, D, ...
                                x0, tspan, jspan, 1, odeset(), [], [],"silent");

            sol = HybridSolution.fromLegacyData(t, j, x, f, g, C, D, tspan, jspan);
%             plot_ndx = 200:206;
%             figure(1)
%             clf
%             subplot(3, 1, 1)
%             plot(plot_ndx, sol.D_vals(plot_ndx,:), 'b*')
%             hold on
%             plot(plot_ndx, sol.C_vals(plot_ndx,:), 'sr')
%             legend("D", "C")
%             subplot(3, 1, 2)
%             plot(plot_ndx, sol.t(plot_ndx), "r")
%             subplot(3, 1, 3)
%             plot(plot_ndx, sol.j(plot_ndx), "b")
%             
%             figure(2)
%             plotflows(sol)
            
            verifyHybridSolutionDomain(sol.t, sol.j, sol.C_vals, sol.D_vals)
            testCase.assertGreaterThanOrEqual(x(:, 1), -1e-7)
        end

        function testValidityOfHybridSolutionDomain(testCase)
            f = @(x)[x(2); -9.8];
            g = @(x)[x(1); -0.9*x(2)];
            C = @(x) 1;
            D = @(x) x(1) <= 0 && x(2) <= 0;
            tspan = [0, 10];
            jspan = [0, 10];
            x0 = [1; 0];
            verifySolver(f, g, C, D, x0, tspan, jspan)
        end
        
        function test3ArgFunctions(testCase)
            f = @(x, t, j) 0.2*(x + 2*t + 3*j); % 
            g = @(x, t, j) 0.1*(x + 2*t + 3*j);
            C = @(x, t, j) norm(x) + j + t <= 2;
            D = @(x, t, j) norm(x) + j + t >= 2;
            tspan = [0, 10];
            jspan = [0, 10];
            x0 = [1; 0];
            verifySolver(f, g, C, D, x0, tspan, jspan)
        end
        
        function test2ArgFunctions(testCase)
            f = @(x, t) 0.2*(x + 2*t);
            g = @(x, t) 0.1*(x + 2*t);
            C = @(x, t) norm(x) + t <= 2;
            D = @(x, t) norm(x) + t >= 2;
            tspan = [0, 10];
            jspan = [0, 10];
            x0 = [1; 0];
            verifySolver(f, g, C, D, x0, tspan, jspan)
        end
        
        function test1ArgFunctions(testCase)
            f = @(x) x;
            g = @(x) 0.1*x;
            C = @(x) norm(x) <= 2;
            D = @(x) norm(x) >= 2;
            tspan = [0, 10];
            jspan = [0, 10];
            x0 = [1; 0];
            verifySolver(f, g, C, D, x0, tspan, jspan)
        end
    end
    
end

function verifySolver(f, g, C, D, x0, tspan, jspan, priority)
if ~exist("priority", "var")
    priority = HybridPriority.default();
end
% We enforce a small maximum step so that a first-order approximation of
% dxdt is close to f(x), allowing us to verify they are almost equal.
options = odeset("MaxStep", 0.01); 
[t, j, x] = HyEQsolver(f, g, C, D, x0, tspan, jspan, priority, options);
sol = HybridSolution.fromLegacyData(t, j, x, f, g, C, D, tspan, jspan);
verifyHybridSolutionDomain(sol.t, sol.j, sol.C_vals, sol.D_vals)
checkHybridSolution(sol, priority)
end


