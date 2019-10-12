#!/bin/sh
# make_cicjobs.sh <JobName> <MakeJobCommand> <MakeInputCommand> <optional subjects .txt file>
# make CIC job for each subject that involves running an SPM matlabbatch to spm_jobman. (exit 0 if successful)
# Inputs
# 1 JobName: name of job (should be valid matlab variable name)
# 2 MakeJobCommand string for assigning variable to jobs can be function or script e.g. {'/data/scratch/zakell/fmri_oct2019/Script.m'}
# 3 MakeInputCommand string for assigning variable to Input
# (matlab will add the Scripts path before calling MakeJobCommand, MakeInputCommand)
# if MakeJobCommand, MakeInputCommand should not input any variables other than variable subx
# e.g.  make_job_fcn(subx)
# 4 optional subjects .txt file
# if subject list not specified default is .../Scripts/subjects.txt
# Examples
# e.g. make_cicjobs.sh prepro "{/data/scratch/zakell/fmri_oct2019/prepro.m}" "{}" these_subjects.txt
# e.g. make_cicjobs.sh PrePro2 "make_matlabbatch(subx)" "{}" these_subjects.txt # make_matlabbatch should be .m in Scripts dir
# e.g. make_cicjobs.sh prepro "{/data/scratch/zakell/fmri_oct2019/prepro.m}" "make_input(subx)" (uses default subject list)

AnalysisDir=/data/scratch/zakell/fmri_oct2019  # <- make sure this is correct
## check dirs
test ! -d $AnalysisDir/cicjobs && mkdir $AnalysisDir/cicjobs 
## check inputs
# number of inputs--------
if [ "$#" -ne 3 ] && [ "$#" -ne 4 ]
	echo "error: incorrect number of inputs."
	echo "usage: ./make_cicjobs.sh <JobName> <MakeJobCommand> <MakeInputCommand> <optional subjects .txt file>"
	echo "e.g. ./make_cicjobs.sh prepro \"{/data/scratch/zakell/fmri_oct2019/Scripts/prepro.m}\" \"{}\" /data/scratch/zakell/fmri_oct2019/Scripts/these_subjects.txt"
	exit 1
fi
# JobName--------
JobName=$1
if [ ${#JobName} -eq 0 ]; then
	echo "error: Invalid JobName. JobName must have at least 1 character."
	exit 2
elif [ `echo "$JobName" | grep -Eo [^0-9a-zA-Z_] | wc -l` -ne 0  ]; then
	# check for bad characters in job name (bad characters are neither letters, numbers or underscores)
	echo "error: Invalid JobName. JobName must contain only letters, numbers or underscores"
	exit 3
fi
echo "JobName = "$JobName
# MakeJobCommand--------
MakeJobCommand=$2
if [ ${#MakeJobCommand} -eq 0 ]; then
	echo "error: Invalid MakeJobCommand. MakeJobCommand must have at least 1 character."
	exit 4
fi
echo "MakeJobCommand = $MakeJobCommand"
# MakeInputCommand--------
MakeInputCommand=$3
if [ ${#MakeInputCommand} -eq 0 ]; then
	echo "error: Invalid MakeInputCommand. MakeInputCommand must have at least 1 character."
	exit 5
fi
echo "MakeInputCommand = $MakeInputCommand"
# subjects--------
if [ "$#" -eq 3 ]; then # 3 inputs
	SubjectsFile=$AnalysisDir/subjects.txt #default subject list
elif [ "$#" -eq 4 ]; then
	SubjectsFile=$4
	if [ ${#SubjectsFile} -eq 0 ]; then
		echo "error: Invalid SubjectsFile. SubjectsFile must have at least 1 character."
		exit 6
	fi
fi
if [ ! -f "$SubjectsFile" ]; then
	printf "error: Invalid subject list. Could not find\n\t%s" $SubjectsFile
	exit 7
elif [ `cat "$SubjectsFile" | wc -l` -eq 0 ]; then
	echo "error: Invalid SubjectsFile. SubjectsFile must have at least one subject."
fi
echo "SubjectsFile = "$SubjectsFile
printf "\n%d subjects\n" `cat $SubjectsFile | wc -l`
# done checking input

## set up cicjob Dir
cicjobDir=$AnalysisDir/cicjobs/$JobName
# remove old directory if it exists
test -d $cicjobDir && rm -r $cicjobDir

## job list
cicjoblistFile=$cicjobDir/cicjoblist
touch $cicjoblistFile

## make job for each subject
for subx in `cat $SubjectsFile`
do
	subxJobFile=$cicjobDir/$subx"_job.m"
	touch $subxJobFile
	# add date
	now=$(date)
	printf "%% %s\n" "now" > $subxJobFile
	# code for setting up cluster
	echo "% set up cluster" >> $subxJobFile
	echo "number_of_cores=12;" >> $subxJobFile
	printf "d=tempname();%% get temporary directory location\nd=tempdir();\nmkdir(d);\n" >> $subxJobFile
	echo "cluster = parallel.cluster.Local('JobStorageLocation',d,'NumWorkers',number_of_cores);" >> $subxJobFile
	echo "matlabpool(cluster, number_of_cores);"  >> $subxJobFile
	# add paths
	echo "addpath(fullfile('"$AnalysisDir"','Scripts'));" >> $subxJobFile 
    echo "addpath(genpath(fullfile(spm('dir'),'config')));" >> $subxJobFile
    # make jobs and inputs
    echo "subx = '"$subx"';" >> $subxJobFile
    echo "jobs = "$MakeJobCommand";" >> $subxJobFile
    echo "inputs = "$MakeInputCommand";" >> $subxJobFile
    echo "assert(iscell(jobs),'jobs must be cell.');">> $subxJobFile
    echo "assert(iscell(inputs),'inputs must be cell.');">> $subxJobFile # inputs can be empty
    # spm
    echo "spm('defaults','FMRI');" >> $subxJobFile
    echo "spm_jobman(jobs, inputs{:});" >> $subxJobFile
    # save job done file
    echo "save('"$AnalysisDir"/Input/"$subx"/"$JobName"_done.mat', 'jobs', 'inputs', '-mat');" >> $subxJobFile
	printf "%% DONE" >> $subxJobFile
	# add to job list
	echo "matlab -nodesktop -nodisplay -nosplash -r \"run('"$subxJobFile"')\"" >> $cicjoblistFile
	# done
	echo "done "$subxJobFile
done
# make test job list based on last subject
touch $cicjobDir/test_cicjoblist
echo "matlab -nodesktop -nodisplay -nosplash -r \"run('"$subxJobFile"')\"" >> $cicjobDir/test_cicjoblist

# done
printf "\nDone making jobs. Find jobs at\n\t%s\n" $cicjobDir
printf "When ready, call\n.%s/Scripts/submit_to_qbatch.sh %s\n" $AnalysisDir $JobName

exit 0
### DONE
