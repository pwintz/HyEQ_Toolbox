classdef CompositeHybridSystemTest < matlab.unittest.TestCase
    
    methods (Test)
       
        function testTwo1x1Subsystems(testCase)
            import hybrid.tests.internal.*
                           % Size of: (u, x, y)
            sub1 = MockHybridSubsystem(1, 1, 1);
            sub2 = MockHybridSubsystem(1, 1, 1);
            sys = CompositeHybridSystem(sub1, sub2);
            sys.setFlowInput(sub1, @(y1, y2, t, j) 4);
            sys.setFlowInput(sub2, @(y1, y2, t, j) 4);
            tspan = [0, 10];
            jspan = [0, 10];
            sol = sys.solve({1, 2}, tspan, jspan);
            testCase.assertLength(sol.subsys_sols, 2)
            testCase.assertLength(sol.x(1, :), 2+2);
        end
       
        function testThreeSubsystemsOfDifferentSizes(testCase)
            import hybrid.tests.internal.*
                           % Size of: (u, x, y)
            sub1 = MockHybridSubsystem(1, 1, 2);
            sub2 = MockHybridSubsystem(2, 1, 3);
            sub3 = MockHybridSubsystem(3, 1, 1);
            sys = CompositeHybridSystem(sub1, sub2, sub3);
            sys.setFlowInput(sub1, @(y1, y2, y3, t, j) 4);
            sys.setFlowInput(sub2, @(y1, y2, y3, t, j) ones(2, 1));
            sys.setFlowInput(sub3, @(y1, y2, y3, t, j) 3*ones(3, 1));
            sys.setJumpInput(sub1, @(y1, y2, y3, t, j) 4);
            sys.setJumpInput(sub2, @(y1, y2, y3, t, j) ones(2, 1));
            sys.setJumpInput(sub3, @(y1, y2, y3, t, j) 3*ones(3, 1));
            tspan = [0, 10];
            jspan = [0, 10];
            sol = sys.solve({1, 2, 3}, tspan, jspan);
            testCase.assertLength(sol.subsys_sols, 3)
            testCase.assertLength(sol.x(1, :), ...
                sub1.state_dimension+sub2.state_dimension+sub3.state_dimension+3);
        end
       
        function testJumpsWhenAnySubsystemInJumpSet(testCase)
            import hybrid.tests.internal.*
                           % Size of: (u, x, y)
            sub1 = MockHybridSubsystem(1, 1, 1);
            sub2 = MockHybridSubsystem(1, 1, 1);
            sys = CompositeHybridSystem(sub1, sub2);
            sub1.D_indicator = @(x, u, t, j) t >= j + 1;
            sub2.D_indicator = @(x, u, t, j) 0;
            tspan = [0, 10];
            jspan = [0, 2];
            sol = sys.solve({0, 0}, tspan, jspan);
            testCase.assertEqual(sol.jump_times, [1; 2], 'AbsTol', 1e-6)
            testCase.assertEqual(sol.subsys_sols{1}.jump_times, [1; 2], 'AbsTol', 1e-6)
            testCase.assertEmpty(sol.subsys_sols{2}.jump_times)
        end
       
        function testAllSubsystemsJumpWhenAllInJumpSet(testCase)
            import hybrid.tests.internal.*
                           % Size of: (u, x, y)
            sub1 = MockHybridSubsystem(1, 1, 1);
            sub2 = MockHybridSubsystem(1, 1, 1);
            sys = CompositeHybridSystem(sub1, sub2);
            sub1.D_indicator = @(x, u, t, j) t >= j + 1;
            sub2.D_indicator = @(x, u, t, j) t >= j + 1;
            tspan = [0, 10];
            jspan = [0,  2];
            sol = sys.solve({0, 0}, tspan, jspan);
            
            expected_jumps = [1; 2];
            testCase.assertEqual(sol.jump_times, expected_jumps, 'AbsTol', 1e-6)
            testCase.assertEqual(sol.subsys_sols{1}.jump_times, expected_jumps, 'AbsTol', 1e-6)
            testCase.assertEqual(sol.subsys_sols{2}.jump_times, expected_jumps, 'AbsTol', 1e-6)
        end
        
        function testFlowPriorityWarning(testCase)
            import hybrid.tests.internal.*
                          % Size of: (u, x, y)
            sub = MockHybridSubsystem(1, 1, 1);
            sys = CompositeHybridSystem(sub);
            tspan = [0, 10];
            jspan = [0,  2];
            config = HybridSolverConfig("silent").flowPriority();
            testCase.verifyWarning(@() sys.solve({0}, tspan, jspan, config), ...
                "CompositeHybridSystem:FlowPriorityNotSupported")
        end
        
%         % This test is disabled because it is testing unsupported
%         % functionallity, namely using flow priority with
%         CompositeHybridSystem, and turning off warnings was causing the
%         testFlowPriorityWarning test to fail intermittently.
%         function testFlowsWhenAllSubsystemsInFlowSetAndFlowPriority(testCase)
%                            % Size of: (u, x, y)
%             sub1 = MockHybridSubsystem(1, 1, 1);
%             sub2 = MockHybridSubsystem(1, 1, 1);
%             sys = CompositeHybridSystem(sub1, sub2);
%             sub1.D_indicator = @(x, u, t, j) 1;
%             sub2.D_indicator = @(x, u, t, j) 1;
%             tspan = [0, 10];
%             jspan = [0,  2];
%             warning('off',"CompositeHybridSystem:FlowPriorityNotSupported")
%             config = HybridSolverConfig("silent").flowPriority();
%             sol = sys.solve({0, 0}, tspan, jspan, config);
%             testCase.assertEmpty(sol.jump_times)
%             testCase.assertEqual(sol.t(end), tspan(end), 'AbsTol', 1e-6)
%             warning('on',"CompositeHybridSystem:FlowPriorityNotSupported")
%         end
        
        function testJumpsWhenAnySubsystemsNotInFlowSetAndFlowPriority(testCase)
            import hybrid.tests.internal.*
            % This test case fails because CompositeHybridSystem cannot
            % correctly handle flow priority when one subsystem is in C \ D
            % and another is in C \cap D.
            assumeFail(testCase)
                           % Size of: (u, x, y)
            sub1 = MockHybridSubsystem(1, 1, 1);
            sub2 = MockHybridSubsystem(1, 1, 1);
            sys = CompositeHybridSystem(sub1, sub2);
            sub1.C_indicator = @(x, u, t, j) t <= 2.0 + 100*j;
            tspan = [0, 10];
            jspan = [0,  2];
            config = HybridSolverConfig("silent").flowPriority();
            sol = sys.solve({0, 0}, tspan, jspan, config);
            expected_jumps = 2.0;
            testCase.assertEqual(sol.jump_times, expected_jumps, 'AbsTol', 1e-6)
            testCase.assertEqual(sol.subsys_sols{1}.jump_times, expected_jumps, 'AbsTol', 1e-6)
            testCase.assertEmpty(sol.subsys_sols{2}.jump_times) % Fails
        end
        
        function testWrongNumberOfInitialStates(testCase)
            import hybrid.tests.internal.*
                          % Size of: (u, x, y)
            sub = MockHybridSubsystem(1, 1, 1);
            sys = CompositeHybridSystem(sub);
            tspan = [0, 10];
            jspan = [0,  2];
            config = HybridSolverConfig("silent");
            testCase.verifyError(@() sys.solve({1, 2, 3}, tspan, jspan, config), ...
                "CompositeHybridSystem:WrongNumberOfInitialStates");
        end
        
        function testInitialStatesWrongSize(testCase)
            import hybrid.tests.internal.*
                           % Size of: (u, x, y)
            sub1 = MockHybridSubsystem(1, 1, 1);
            sub2 = MockHybridSubsystem(1, 1, 1);
            sys = CompositeHybridSystem(sub1, sub2);
            tspan = [0, 10];
            jspan = [0,  2];
            config = HybridSolverConfig("silent");
            testCase.verifyError(@() sys.solve({1, [1; 2]}, tspan, jspan, config), ...
                "CompositeHybridSystem:WrongNumberOfInitialStates");            
        end
        
        function testInitialStatesNotCellArray(testCase)
            import hybrid.tests.internal.*
                                  % Size of: (u, x, y)
            sub = MockHybridSubsystem(1, 1, 1);
            sys = CompositeHybridSystem(sub);
            tspan = [0, 10];
            jspan = [0,  2];
            config = HybridSolverConfig("silent");
            testCase.verifyError(@() sys.solve([1, 2, 3], tspan, jspan, config), ...
                "CompositeHybridSystem:InitialStateNotCell");    
        end
        
        function testNumberOfContinuousInputArguments(testCase)
            import hybrid.tests.internal.*
            % i.e. @(y1, y2, t, j) instead of @(y1, y2, y3, t, j).
                           % Size of: (u, x, y)
            sub1 = MockHybridSubsystem(1, 1, 1);
            sub2 = MockHybridSubsystem(1, 1, 1);
            sys = CompositeHybridSystem(sub1, sub2);
            testCase.verifyError(@() sys.setFlowInput(1, @(y1) y1), ...
                "CompositeHybridSystem:WrongNumberInputArgs")
            sys.setFlowInput(1, @(y1, y2) y1)
            sys.setFlowInput(1, @(y1, y2, t) y1)
            sys.setFlowInput(1, @(y1, y2, t, j) y1)
            testCase.verifyError(@() sys.setFlowInput(1, @(y1, y2, t, j, extra) y1), ...
                "CompositeHybridSystem:WrongNumberInputArgs")
        end
        
        function testInputOutVectorWrongSize(testCase)
            import hybrid.tests.internal.*
            sub = MockHybridSubsystem(1, 1, 1);
            sys = CompositeHybridSystem(sub);
            sys.setFlowInput(1, @(x1, t, j) zeros(2, 1));
            testCase.verifyError(@() sys.solve({1}, [0, 10], [0, 10]), ...
               "CompositeHybridSystem:DoesNotMatchInputDimension");
        end
        
        function testWarningWhenSetInputForSystemWithNoInputs(testCase)
            import hybrid.tests.internal.*
            sub = MockHybridSubsystem(0, 1, 1);
            sys = CompositeHybridSystem(sub);
            testCase.verifyWarning(@() sys.setFlowInput(1, @(x1, t, j) []), ...
               "CompositeHybridSystem:SystemHasNoInputs");
            testCase.verifyWarning(@() sys.setJumpInput(1, @(x1, t, j) []), ...
               "CompositeHybridSystem:SystemHasNoInputs");
            testCase.verifyWarning(@() sys.setInput(1, @(x1, t, j) []), ...
               "CompositeHybridSystem:SystemHasNoInputs");
        end
        
    end

end