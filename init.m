
%% Description
%
% This file initializes the directory of the rdp dsp code. After init all
% necessary folders are added to the path and you can run the main method.
% Make sure you stay in the parent folder of everything, otherwise the
% iqtools won't be found.
%
% Author: Max Basler - 19.07.2024

[scriptdir, ] = fileparts(mfilename('fullpath'));

dirlist_recursive = {'code', 'iqtools'};

for k=1:length(dirlist_recursive)
    addpath(genpath([scriptdir filesep dirlist_recursive{k}]));
end

clear scriptdir k dirlist_recursive