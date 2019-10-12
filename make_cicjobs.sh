#!/bin/sh
# make_cicjobs.sh <subx_or_subx_runx> <JobName> <MakeJobCommand> <MakeInputCommand> <optional subjects .txt file>
# make CIC job for each subject that involves running an SPM matlabbatch to spm_jobman. (exit 0 if successful)
# Inputs
# 1 JobName: name of job (should be valid matlab variable name)
# 2 subx_or_subx_runx either subx or subx_runx (subx_runx separates runs)
# 2 MakeJobCommand string for assigning variable to jobs can be function or script e.g. {'/data/scratch/zakell/fmri_oct2019/Script.m'}
# 3 MakeInputCommand string for assigning variable to Input
# (matlab will add the Scripts path before calling MakeJobCommand, MakeInputCommand)
# if MakeJobCommand, MakeInputCommand should not input any variables other than variable subx
# e.g.  make_job_fcn(subx)
# 4 optional subjects .txt file
# if subject list not specified default is .../Scripts/subjects.txt
# Examples
# e.g. make_cicjobs.sh subx prepro "{/data/scratch/zakell/fmri_oct2019/prepro.m}" "{}" these_subjects.txt
# e.g. make_cicjobs.sh subx_runx Smooth06 "make_matlabbatch(subx)" "{}" these_subjects.txt # make_matlabbatch should be .m in Scripts dir
# e.g. make_cicjobs.sh subx prepro "{/data/scratch/zakell/fmri_oct2019/prepro.m}" "make_input(subx)" (uses default subject list)

AnalysisDir=/data/scratch/zakell/fmri_oct2019  # <- make sure this is correct

## check inputs
# number of inputs--------
if [ "$#" -ne 4 ] && [ "$#" -ne 5 ]; then
	echo "error: incorrect number of inputs."
	echo "usage: ./make_cicjobs.sh  <subx_or_subx_runx> <JobName> <MakeJobCommand> <MakeInputCommand> <optional subjects .txt file>"
	echo "e.g. ./make_cicjobs.sh subx prepro \"{/data/scratch/zakell/fmri_oct2019/Scripts/prepro.m}\" \"{}\" /data/scratch/zakell/fmri_oct2019/Scripts/these_subjects.txt"
	exit 1
fi
# SeparateRuns--------
if [ "$1" = "subx" ]; then
	SeparateRuns=false;
elif [ "$1" = "subx_runx" ]; then
	SeparateRuns=true;
else
	echo "error: input 1 must be either subx or subx_runx"
	exit 2
fi
# JobName--------
JobName=$2
if [ ${#JobName} -eq 0 ]; then
	echo "error: Invalid JobName. JobName must have at least 1 character."
	exit 3
elif [ `echo "$JobName" | grep -Eo [^0-9a-zA-Z_] | wc -l` -ne 0  ]; then
	# check for bad characters in job name (bad characters are neither letters, numbers or underscores)
	echo "error: Invalid JobName. JobName must contain only letters, numbers or underscores"
	exit 4
fi
echo "JobName = "$JobName
# MakeJobCommand--------
MakeJobCommand=$3
if [ ${#MakeJobCommand} -eq 0 ]; then
	echo "error: Invalid MakeJobCommand. MakeJobCommand must have at least 1 character."
	exit 5
fi
echo "MakeJobCommand = $MakeJobCommand"
# MakeInputCommand--------
MakeInputCommand=$4
if [ ${#MakeInputCommand} -eq 0 ]; then
	echo "error: Invalid MakeInputCommand. MakeInputCommand must have at least 1 character."
	exit 6
fi
echo "MakeInputCommand = $MakeInputCommand"
# subjects--------
if [ "$#" -eq 4 ]; then # 3 inputs
	SubjectsFile=$AnalysisDir/Scripts/subjects.txt #default subject list
elif [ "$#" -eq 5 ]; then
	SubjectsFile=$5
	if [ ${#SubjectsFile} -eq 0 ]; then
		echo "error: Invalid SubjectsFile. SubjectsFile must have at least 1 character."
		exit 7
	fi
fi
if [ ! -f "$SubjectsFile" ]; then
	printf "error: Invalid subject list. Could not find\n\t%s\n" $SubjectsFile
	exit 8
elif [ `cat "$SubjectsFile" | wc -l` -eq 0 ]; then
	echo "error: Invalid SubjectsFile. SubjectsFile must have at least one subject."
	exit 9
fi
echo "SubjectsFile = "$SubjectsFile
printf "\n%d subjects\n" `cat $SubjectsFile | wc -l`
# done checking input

## set up cicjob Dir
## check dirs
test ! -d $AnalysisDir/cicjobs && mkdir $AnalysisDir/cicjobs 
cicjobDir=$AnalysisDir/cicjobs/$JobName
# remove old directory if it exists
test -d $cicjobDir && rm -r $cicjobDir
# remake direcory
mkdir $cicjobDir
## job list
cicjoblistFile=$cicjobDir/cicjoblist
touch $cicjoblistFile

## ----functions----
subfun_before_defining_subx_runx () {
	# do before defining subx (and runx if applicable) 
	JobFile=$1
	touch $JobFile
	now=$(date)
	printf "%% %s\n" "$now" > $JobFile
	echo "% set up cluster" >> $JobFile
	echo "number_of_cores=12;" >> $JobFile
	printf "d=tempname();%% get temporary directory location\nd=tempdir();\nmkdir(d);\n" >> $JobFile
	echo "cluster = parallel.cluster.Local('JobStorageLocation',d,'NumWorkers',number_of_cores);" >> $JobFile
	echo "matlabpool(cluster, number_of_cores);"  >> $JobFile
	# add paths
	echo "AnalysisDir='"$AnalysisDir"';" >> $JobFile 
	echo "addpath(fullfile('AnalysisDir','Scripts'));" >> $JobFile 
    	echo "addpath(genpath(fullfile(spm('dir'),'config')));" >> $JobFile
}
subfun_after_defining_subx_runx () {
	# do after defining subx (and runx if applicable)
	JobFile=$1
	DoneFile=$2
	echo "jobs = "$MakeJobCommand";" >> $JobFile
    	echo "inputs = "$MakeInputCommand";" >> $JobFile
	echo "assert(iscell(jobs),'jobs must be cell.');">> $JobFile
	echo "assert(iscell(inputs),'inputs must be cell.');">> $JobFile # inputs can be empty
	# spm
	echo "spm('defaults','FMRI');" >> $JobFile
	echo "spm_jobman(jobs, inputs{:});" >> $JobFile
	echo "save('"$DoneFile"', 'jobs', 'inputs', '-mat');" >> $JobFile
	# add to job list
	echo "matlab -nodesktop -nodisplay -nosplash -r \"run('"$JobFile"')\"" >> $cicjoblistFile
    	echo "done "$JobFile
}
# -----------------
## make jobs
if [ $SeparateRuns ]; then
	for subx in `cat $SubjectsFile`; do
		subx_JobFile=$cicjobDir/$subx"_job.m"
		subfun_before_defining_subx_runx $subx_JobFile
		echo "subx = '"$subx"';" >> $subx_JobFile
		subfun_after_defining_subx_runx $subx_JobFile
	done
	LastJob=$subx_JobFile
else
	for subx in `cat $SubjectsFile`; do
		for r in {1..3}; do
			runx="run"$r
			subx_runx_JobFile=$cicjobDir/$subx"_"$runx"_job.m"
			echo "subx = '"$subx"';" >> $subx_runx_JobFile
			echo "runx = '"$runx"';" >> $subx_runx_JobFile
			subfun_after_defining_subx_runx $subx_runx_JobFile
		done
	done
	LastJob=$subx_runx_JobFile
fi
## make test job list based on last subject
touch $cicjobDir/test_cicjoblist
echo "matlab -nodesktop -nodisplay -nosplash -r \"run('"$LastJob"')\"" >> $cicjobDir/test_cicjoblist

# done
printf "\nDone making jobs. Go to Jobs\n\tcd %s\n" $cicjobDir
printf "When ready, call\n.%s/Scripts/submit_to_qbatch.sh %s\n" $AnalysisDir $JobName
###



