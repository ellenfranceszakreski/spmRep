function Inputs = Level2v1_con_000x_Inputs(con_000x)
% Level2
AnalysisDir='/data/scratch/zakell/fmri_oct2019'; % make sure this is correct
% check inputs
assert(~isempty(regexp(con_000x,'^con_\d{3}$','once')),'Invalid con_000x.');
% get group data
ds = importdata(fullfile(AnalysisDir,'Data/AllSubjects.mat'));
% mak contrast image names (e.g. .../Input/sub10/con_0001.nii)
ds.con_000x = strcat(AnalysisDir,'/Input/', ds.subx,'/',con_000x, '.nii');
% exclude rows where subjects have no con_000x.nii images
con000x_exists_ind=false(size(ds,1),1);
for n=1:size(ds,1)
    con000x_exists_ind(n) = exist(ds.con_000x{n}, 'file') == 2;
end; clear n
assert(any(con000x_exists_ind),'Could not find contrast images');
ds = ds(con000x_exists_ind, :);
clear con000x_exists_ind

% design directory
Level2Dir=fullfile(AnalysisDir,'Level2v1',con_000x);
if exist(Level2Dir,'dir')~=7
    mkdir(Level2Dir);
elseif ~isempty(ls(Level2Dir))
    delete(fullfile(Level2Dir,'*')); % delete old files
end
Inputs = cell(1,1);
I = 0;
I=I+1;Inputs{1,I} = {Level2Dir}; % matlabbatch{1}.spm.stats.factorial_design.dir directory to save SPM.mat, and level2 output files (e.g. con_0001.nii, spmT_0001.nii, etc.)
% factorial design
I=I+1;Inputs{1,I} = 'ela'; % matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).name 
I=I+1;Inputs{1,I} = 2;    % matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(1).levels 

I=I+1;Inputs{1,I} = 'cue'; % matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).name 
I=I+1;Inputs{1,I} = 2;    % matlabbatch{1}.spm.stats.factorial_design.des.fd.fact(2).levels

I=I+1;Inputs{1,I} = [1,1];
I=I+1;Inputs{1,I} = subfun_index('low','control');

I=I+1;Inputs{1,I} = [1,2];
I=I+1;Inputs{1,I} = subfun_index('low','mortality');

I=I+1;Inputs{1,I} = [2,1];
I=I+1;Inputs{1,I} = subfun_index('high','control');

I=I+1;Inputs{1,I} = [2,2];
I=I+1;Inputs{1,I} = subfun_index('high','mortality');
clear ds

    function [con_000xs, ind] = subfun_index(ela,cue)
        ind= strcmp(ds.ela,ela) & strcmp(ds.cue,cue);
        con_000xs = ds.con_000x(ind);
    end

end