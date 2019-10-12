#!/bin/sh
# source submit_to_qbatch.sh <JobName> (use source)
# make sure you log in to ssh -Y zakell@cicw01
# tip: to make job directory call ../Scripts/make_cicjobs.sh <JobName>

AnalysisDir=/data/scratch/zakell/fmri_oct2019 #<- make sure this is correct!

# check input
if [ "$#" -ne 1 ]; then
  	echo "error: incorrect number of inputs. Specify name of directory to make inside cicjobs directory"
    echo "usage: source submit_to_qbatch.sh <JobName>"
  	exit 1
fi
JobName="$1"
# ensure JobName is not ""
if [ ${#JobName} -eq 0 ]; then
	echo "error: Invalid JobName. JobName must have at least 1 character."
	exit 2
fi
# check for bad characters (i.e. not letters, numbers or underscores)
if [ `echo "$JobName" | grep -Eo [^0-9a-zA-Z_] | wc -l` -ne 0  ]; then
	echo "error: Invalid JobName. JobName must contain only letters, numbers or underscores"
	exit 2
fi

# recommended to check job list first
cicjobDir=$AnalysisDir/cicjobs/$JobName
if test -d $cicjobDir
then
	echo "Found job directory at: "$cicjobDir
else
	echo "error: Invalid job directory "$cicjobDir
  echo "to make job directory call ../Scripts/make_cicjobs.sh "$JobName
	exit 2
fi

# job list and jobs should be in this directory
cd $cicjobDir

# load modules
source $AnalysisDir/Scripts/load_modules.sh # use source to load modules

# call qbatch
echo "when ready call"
echo "qbatch --options '-l matlab=1' --options ' -R y' --ppj 6 "$cicjobDir/cicjoblist

## done
unset JobName cicjobDir AnalysisDir
### DONE
