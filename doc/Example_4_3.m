%% Example 4.3: Zero-order Hold in Simulink
% A zero-order hold (ZOH) converts a digital signal at its input into an analog signal at
% its output. Its output is updated at discrete time instants, typically
% periodically, and held constant in between updates, until new information
% is available at the next sampling time.
% In this example, a ZOH model is modeled in Simulink as a hybrid system 
% with an input, where the input is the signal to sample.
% 
% Click
% <matlab:hybrid.open({'CPS_examples','ZOH'},'ZOH_example.slx') here> 
% to change your working directory to the ZOH folder and open the
% Simulink model. 
%% Mathematical Model
% 
% The ZOH system is modeled as a hybrid system
% with the following data: 
% 
% $$\begin{array}{ll}
% f(q,u):=\left[\begin{array}{c}
%   0 \\
%   0 \\
%   1
%  \end{array}\right],
%    & C := \{ (x,u) \mid \tau\in [0, T^{*}_{s}] \} \\ \\
% g(x,u):= \left[ \begin{array}{c} 
%                    u \\ 
%                    0
%                \end{array}\right],
%    & D: = \{ (x,u) \mid \tau_{s} \geq T^{*}_{s}\}
% \end{array}$$
%
% $$
%   y = h(x) := x
% $$
%
% 
% where the input and the state are given by $u \in \mathbf{R}^{2}$, and $x = (m_{s}, \tau_{s})\in \mathbf{R}\times \mathbf{R}^{2}$, respectively.
%% Steps to Run Model
% 
% The following procedure is used to simulate this example using the model in the file |ZOH_example.slx|:
% 
% * Navigate to the directory <matlab:hybrid.open({'CPS_examples','ZOH'}) Examples/CPS_examples/ZOH>
% (clicking this link changes your working directory).
% * Open
% <matlab:hybrid.open({'CPS_examples','ZOH'},'ZOH_example.slx') |ZOH_example.slx|> 
% in Simulink (clicking this link changes your working directory and opens the model).   
% * Double-click the block labeled _Double Click to Initialize_.
% * To start the simulation, click the _run_ button or select |Simulation>Run|.
% * Once the simulation finishes, click the block labeled _Double Click to Plot
% Solutions_. Several plots of the computed solution will open.
% 

% Change working directory to the example folder.
wd_before = hybrid.open({'CPS_examples','ZOH'});

% Run the initialization script.
initialization_exZOHV01

% Run the Simulink model.
sim('ZOH_example')

% Convert the values t, j, and x output by the simulation into a HybridArc object.
sol = HybridArc(t, j, x); %#ok<IJCL> (suppress a warning about 'j')

% Convert the values t, j, and the input to ZOH x1 into a HybridArc object.
sol_1 = HybridArc(t1, j1, x1);

%% Simulink Model
% The following diagram shows the Simulink model of the ZOH. The
% contents of the blocks *flow map* |f|, *flow set* |C|, etc., are shown below. 
% When the Simulink model is open, the blocks can be viewed and modified by
% double clicking on them.

% Open subsystem "ZOH" in ZOH_example.slx. A screenshot of the subsystem will be
% automatically included in the published document.
open_system('ZOH_example')

%%
% The Simulink blocks for the hybrid system in this example are included below.
%
% *flow map* |f| *block*
% 
% <include>src/Matlab2tex_ZOH/f.m</include>
%
% *flow set* |C| *block*
% 
% <include>src/Matlab2tex_ZOH/C.m</include>
%
% *jump map* |g| *block*
% 
% <include>src/Matlab2tex_ZOH/g.m</include>
%
% *jump set* |D| *block*
% 
% <include>src/Matlab2tex_ZOH/D.m</include>

%% Example Output
% In this example, the signal to process is the state of the bouncing ball system 
% in <matlab:showdemo('Example_1_3') Example 1.3> with the input chosen 
% to be constant, equal to $0.2$.
% The initial state of the bouncing ball system is $[1, 0]^\top$. The solution to
% the ZOH system from $x(0,0)=[1, 0, 0]^\top$ and with |T=10|, |J=100|, |rule=1| shows
% the output signal after the ZOH process.

clf
hb = HybridPlotBuilder().subplots('on');
hold on
hb.legend('ZOH input', 'ZOH input')...
.color('green')...
.plotFlows(sol_input);
hb.legend('ZOH output', 'ZOH output')...
.flowColor('blue')...
.jumpColor('red')...
.plotFlows(sol_zoh.slice(1:2));

%% Modifying the Model
% * The _Embedded MATLAB function blocks_ |f, C, g, D| are edited by
%   double-clicking on the block and editing the script. In each embedded function
%   block, parameters must be added as inputs and defined as parameters by
%   selecting |Tools>Edit Data/Ports|, and setting the scope to |Parameter|. 
% * In the initialization script |initialization_exZOHV01.m|, 
%   the flow time and jump horizons, |T| and |J| are defined as well as the
%   initial conditions for the state vector, $x_0$, and input vector, $u_0$, and
%   a rule for jumps, |rule|.
% * The simulation stop time and other simulation parameters are set to the
%   values defined in |initialization_exZOHV01.m| by selecting |Simulation>Configuration
%   Parameters>Solver| and inputting |T|, |RelTol|, |MaxStep|, etc..  

%% 

% Clean up. It's important to include an empty line before this comment so it's
% not included in the HTML. 

% Close the Simulink file.
close_system 

% Restore previous working directory.
cd(wd_before) 
