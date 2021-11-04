
homedir = char(java.lang.System.getProperty('user.home'));
proj_root = fullfile(homedir, 'code', 'hybrid-toolbox');

if ~isempty(which('HyEQsolver'))
    warning('A version of the toolbox is already setup.')
    return
end

toolbox_dirs = {...
    fullfile(proj_root, 'CommonFiles', 'lite'), ...
    fullfile(proj_root, 'CommonFiles', 'plottingFunctions'), ...
    fullfile(proj_root, 'CommonFiles', 'simulinkBased','Library2014b')};
dev_dirs = {fullfile(proj_root, 'doc'), ...
    fullfile(proj_root, 'CommonFiles', 'lite'), ...
    fullfile(proj_root, 'helpFiles', 'Matlab_Publish', 'MatlabScripts', 'v3.0')};

% Setup path
addpath(toolbox_dirs{:}) 
addpath(dev_dirs{:}) 

disp('hybrid-toolbox development path configured.')