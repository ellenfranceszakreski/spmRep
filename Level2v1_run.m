% Level2vx
Level2vx = 'Level2v1';
AnalysisDir='/data/scratch/zakell/fmri_oct2019';
subx_to_exclude = {'sub21','sub22'}

addpath(fullfile(AnalysisDir,'Scripts'));
addpath(genpath(fullfile(spm('dir'),'config')))

con_000xs={'con_0001','con_0002'};
nrun = numel(con_000xs);

jobs = {fullfile(AnalysisDir, 'Scripts', [Level2vx,'_matlabbatch.m'])};
jobs = repmat(jobs, 1, nrun);
inputs = cell(13, nrun);
for crun=1:nrun
  inputs(1:13,crun) = Level2v1_con_000x_Inputs(AnalysisDir, con_000xs{crun}, subx_to_exclude); 
end

spm('defaults','FMRI');
spm_jobman('run', jobs, inputs{:});
% done
