function sys = HybridSystem(f, g, C, D)
% HybridSystem Create a HybridSystem object from the give data. 
sys = hybrid.internal.EZHybridSystem(f, g, C, D); 
end