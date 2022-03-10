% Project: Simulation of a hybrid system (Analog-to-digital converter)
% Description: initialization ADC
                                                                 
% Initial conditions (bouncing ball)
x0bb = [1;0];   
% Initial conditions (ACD)
tau0 = 0;
x0ADC = [x0bb;tau0];             

% Constants (ACD)
Ts = 0.1;

% physical variables (bouncing ball)
global gamma lambda
gamma = -9.81;  % gravity constant
lambda = 0.8;   % restitution coefficent

% simulation horizon                                                    
T = 10;                                                                 
J = 100;                                                                 
                                                                        
% Rule for jumps                                                        
% rule = 1 -> priority for jumps                                        
% rule = 2 -> priority for flows                                        
% rule = 3 -> no priority, random selection when simultaneous conditions
rule = 1;                                                               
                                                                        
% Solver tolerances
RelTol = 1e-6;
MaxStep = 1e-3;