% Postprocessing script for the estimation over network 2 example

solz = HybridArc(tz, jz, z); %#ok<IJCL> (suppress a warning about 'jz')
solhatz = HybridArc(thatz, jhatz, hatz); %#ok<IJCL> (suppress a warning about 'jhatz')


% plot solution
figure(1) 
clf
hpb = HybridPlotBuilder().subplots('on').color('matlab');
hpb.legend('System state $x_1$','System state $x_2$',...
    'System state $x_3$','System state $x_4$')...
    .plotFlows(solz) 
hold on
hpb.legend('Estimation $\hat{x}_1$',...
    'Estimation $\hat{x}_2$','Estimation $\hat{x}_3$',...
    'Estimation $\hat{x}_4$').plotFlows(solhatz.slice(1:4)) 
 
%The following plot depicts the hybrid arc for the first state of the estimator in hybrid time. 
figure(2)
clf
hpb = HybridPlotBuilder();
hpb.label('$\hat{x}_1$').plotHybrid(solhatz.slice(1))  
grid on
view(37.5, 30)

 