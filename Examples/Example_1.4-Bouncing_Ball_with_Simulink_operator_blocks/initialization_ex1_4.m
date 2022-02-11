% Initialization script for bouncing ball example with Simulink operator blocks.
                                                       
% Initial conditions                                                    
x0 = [1; 0];                                                             
                 
% Physical variables
gamma = -9.81;   % gravity constant
lambda = 0.8;    % restitution coefficient

% Simulation horizon                                                    
T = 10;                                                                 
J = 20;                                                                 

% Set the behavior of solutions when the state is in the intersection of
% the flow and jump sets.                                                       
% rule = 1 -> priority for jumps                                        
% rule = 2 -> priority for flows                                        
% rule = 3 -> no priority, random selection when simultaneous conditions
rule = 1;                                                               
                                                                        
%solver tolerances
RelTol = 1e-8;
MaxStep = 0.01;