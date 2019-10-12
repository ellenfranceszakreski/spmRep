% code to add to Scripts to set up parallel cluster on CIC (add code before running analysis)
AnalysisDir='/data/scratch/zakell/fmri_oct2018'; % <- make sure this is correct
number_of_cores=12;
d=tempname();% temporary directory
mkdir(d);
cluster = parallel.cluster.Local('JobStorageLocation',d,'NumWorkers',number_of_cores);
matlabpool(cluster, number_of_cores);
% add paths
addpath(fullfile('"$AnalysisDir"','Scripts'));
addpath(genpath(fullfile(spm('dir'),'config')));
% add analysis code below for this subject/run
